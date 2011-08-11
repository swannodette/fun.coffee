arity = (arities) ->
  (args...) ->
    f = arities[args.length]
    if not f
      f = arities["default"]
    if not f
      throw Error "No dispatch for arity #{args.length}"
    f.apply null, args

dispatch = (dfn, table) ->
  f = (args...) ->
        f =  table[dfn.apply(null, args)]
        if not f
          f = table["default"]
        if not f
          throw Error "No dispatch for arguments #{args}"
        f.apply null, args
  f._table = table
  f._dfn = dfn
  f

type = arity
  0: -> throw new Error("Not enough arguments to type")
  1: (a) ->
    if typeof a != 'string' and a.length
      'Array'
    else
      a.constructor.name or a.constructor._name
  2: (a, b) ->
    if typeof a != 'string' and a.length
      aname = 'Array'
    else
      aname = a.constructor.name or a.constructor._name
    if typeof a != 'string' and b.length
      bname = 'Array'
    else
      bname = b.constructor.name or b.constructor._name
    "#{aname}:#{bname}"

seqType = arity
  0: -> throw new Error("Not enough arguments to seqType")
  1: -> throw new Error("Not enough arguments to seqType")
  2: (f, s) ->
    if typeof a != 'string' and s.length
      'Array'
    else
      s.constructor.name or s.constructor._name
  default: (f, _, s) ->
    if typeof a != 'string' and s.length
      'Array'
    else
      s.constructor.name or s.constructor._name

eq = (a, b) -> a is b

inc = (x) -> x + 1

dec = (x) -> x - 1

sum = (a, b) -> a + b

even = (x) -> x % 2 is 0

odd = (x) -> x % 2 is 1

identity = (x) -> x

toFn = (obj) -> (p) -> obj[p]

get = (coll, x) -> if coll then coll[x] else null

getIn = (x, keys) -> reduce get, x, keys

accsr = (x, coll) -> coll[x]

mesg = (sel, args...) -> (o) -> o[sel].apply o, args

flip = (f) -> (a, b) -> f b, a

clone = (array) -> x for x in array

apply = dispatch seqType,
  Array: arity
    0: -> throw new Error("Not enough arguments to apply")
    1: -> throw new Error("Not enough arguments to apply")
    2: (f, args) ->
      f.apply null, args
    3: (f, arg, args) ->
      args = clone args
      args.unshift arg
      f.apply null, args
  LazySeq: arity
    0: -> throw new Error("Not enough arguments to apply")
    1: -> throw new Error("Not enough arguments to apply")
    2: (f, args) ->
      f.apply null, toArray args
    3: (f, arg, args) ->
      args = toArray args
      args.unshift arg
      f.apply null, args

call = (f, args...) -> f.apply null, args

partial = (f, rest1...) -> (rest2...) -> f.apply null, rest1.concat rest2

array = (args...)-> x for x in args

keys = (o) -> k for k, v of o

vals = (o) -> v for k, v of o

extendfn = (gfn, exts) ->
  for t, f of exts
    gfn._table[t] = f

merge = arity
  0: -> null
  1: (a) -> a
  2: (a, b) ->
    r = {}
    for k, v of a
      r[k] = v
    for k, v of b
      r[k] = v
    r
  default: (ms...) ->
    reduce merge, ms

mergeWith = arity
  0: -> throw new Error("Not enough arguments to mergeWith")
  1: -> throw new Error("Not enough arguments to mergeWith")
  2: (f, a) -> a
  3: (f, a, b) ->
    r = {}
    for k, v of a
      r[k] = v
    for k, v of b
      r[k] = f r[k], v
    r
  default: (f, ms...) ->
    reduce (partial mergeWith, f) , ms

# ==============================================================================
# Strict Sequences

groupBy = (pred, coll) ->
  r = {}
  for x in coll
    v = pred x
    r[v] ||= []
    r[v].push x
  r

strictMap = (f, colls...) ->
  if colls.length is 1
    f x for x, i in colls[0]
  else
    first = colls[0]
    for _, i in first
      f.apply null, x[i] for x in colls

strictMapIndexed = (f, coll) ->
  f(x, i) for x, i in colls[0]

strictReduce = arity
  0: -> throw new Error("Not enough arguments to strictReduce")
  1: -> throw new Error("Not enough arguments to strictReduce")
  2: (f, coll) -> strictReduce f, coll[0], coll[1..]
  3: (f, acc, coll) ->
    for x in coll
      acc = f(acc, x)
    acc

strictFilter = (pred, coll) ->
  x for x in coll when pred(x)

strictPartition = (n, coll, pad) ->
  r = []
  last = null
  while coll.length > 0
    last = coll[0..n-1]
    r.push last
    if pad and last.length < n
      last[n] = null
    coll = coll[n..]
  r

strictSome = (pred, coll) ->
  for x in coll
    if pred x
      return x
  false

strictAny = (pred, coll) ->
  strictSome(pred, coll) and true

strictEvery = (pred, coll) ->
  for x in coll
    if not pred x
      return false
  true

# ==============================================================================
# Sequences

empty = dispatch type,
  Array: (coll) -> coll.length is 0
  LazySeq: (coll) -> coll

seq = dispatch type,
  Array: (coll) -> if empty coll then null else coll
  LazySeq: identity
  Object: (o) -> toLazy([k, v] for k, v of o)

# ==============================================================================
# Lazy Sequences

class LazySeq
  constructor: (@head, @tail) ->
  first: -> @head
  rest: -> if @tail then @tail() else null

lazyseq = (h, t) -> new LazySeq h, t

toLazy = dispatch type,
  Array: (coll) ->
    if coll.length is 0
      return null
    else
      h = coll[0]
      lazyseq h, -> toLazy coll[1..]
  LazySeq: identity

toArray = dispatch type,
  Array: identity
  LazySeq: (s) ->
    acc = []
    while s
      acc.push first s
      s = rest s
    acc

range = arity
  0: -> throw new Error("Not enough arguments to range")
  1: (end) -> range 0, end
  2: (start, end) ->
    if start is end
      null
    else
      lazyseq start, -> range inc(start), end

repeat = arity
  0: -> throw new Error("Not enough arguments to repeat")
  1: (x) ->
    lazyseq x, -> repeat x
  2: (n, x) ->
    take n, repeat x

repeatedly = arity
  0: -> throw new Error("Not enough arguments to repeatedly")
  1: (f) -> lazyseq f(), -> repeatedly f
  2: (n, f) -> take n, repeatedly f

cycle = (coll) ->
  cyclefn = (i) ->
    i = i % coll.length
    lazyseq coll[i], -> cyclefn i+1
  cyclefn 0

lazyConcat = (a, b) ->
  if a is null
    b
  else
    lazyseq first(a), -> lazyConcat rest(a), b

lazyPartition = (n, s, pad) ->
    p = take n, s
    r = drop n, s
    if r is null
      c = count p
      if c < n and pad
        p = concat p, take(n-c, pad)
      lazyseq p, null
    else
      lazyseq p, -> lazyPartition n, r, pad

drop = arity
  0: -> throw new Error("Not enough arguments to drop")
  1: (s) -> drop 1, s
  2: (n, s) ->
    if s is null
      null
    else if n is 0
      s
    else
      drop n-1, s.rest()

take = (n, s) ->
  if n is 0 or s is null
    null
  else
    lazyseq first(s), -> take n-1, rest(s)

last = (s) ->
  c = null
  while s
    c = first s
    s = rest s
  c

lazyMap = arity
  0: -> throw new Error("Not enough arguments to lazyMap")
  1: -> throw new Error("Not enough arguments to lazyMap")
  2: (f, coll) ->
    if coll is null
      null
    else
      lazyseq f(first(coll)), -> lazyMap f, rest(coll)
  default: (f, colls...) ->
    if not every ((coll) -> (seq(coll) != null)), colls
      null
    else
      lazyseq apply(f, (map first, colls)), -> apply lazyMap, f, (map rest, colls)

lazyMapIndexed = arity
  0: -> throw new Error("Not enough arguments to lazyMapIndexed")
  1: -> throw new Error("Not enough arguments to lazyMapIndexed")
  2: (f, s) -> lazyMapIndex f, s, 0
  3: (f, s, i) ->
    lazyseq f(first(s), i), -> lazyMapIndexed f, rest(s), i+1

lazyReduce = arity
  0: -> throw new Error("Not enough arguments to lazyReduce")
  1: -> throw new Error("Not enough arguments to lazyReduce")
  2: (f, s) -> lazyReduce f, first(s), rest(s)
  3: (f, acc, s) ->
    while s
      acc = f acc, first s
      s = rest s
    acc

lazyFilter = (pred, s) ->
  if s
    h = first s
    if pred h
      lazyseq h, -> lazyFilter pred, rest s
    else
      lazyFilter pred, rest s
  else
    null

lazySome = (pred, s) ->
  while s
    h = first s
    if pred h
      return h
    s = rest s
  false

lazyAny = (pred, s) ->
  lazySome(pred, s) and true

lazyEvery = (pred, s) ->
  while s
    h = first s
    if not pred h
      return false
    s = rest s
  true

# ==============================================================================
# Equality

objectEquals = (a, b) ->
  for k, v of a
    if not b.hasOwnProperty(k) or not equals v, b[k]
      return false
  true

arrayEquals = (a, b) ->
  if a and not b
    false
  else if not a and b
    false
  else if not a and not b
    true
  else if not (a.length is b.length)
    false
  else
    for x, i in a
      if not equals x, b[i]
        return false
  true

lazySeqEquals = (a, b) ->
  if a and not b
    false
  else if not a and b
    false
  else if not a and not b
    true
  else
    ah = first a
    bh = first b
    if not equals ah, bh
      false
    else
      lazySeqEquals a.rest(), b.rest()

arrayLazySeqEquals = (a, b) ->
  lazySeqEquals toLazy(a), b

# ==============================================================================
# Generic

count = dispatch type,
  Array: (array) -> array.length
  LazySeq: (seq) -> reduce inc, 0, seq

first = dispatch type,
  Array: (array) -> if array and array.length > 0 then array[0] else null
  LazySeq: (seq) -> if seq then seq.first() else null

rest = dispatch type,
  Array: (array) -> if array.length > 1 then array[1..] else null
  LazySeq: (seq) -> seq.rest()

nth = dispatch type,
  Array: (array, n) -> array[n]
  LazySeq: (seq, n) -> first drop n, seq

map = dispatch seqType,
  Array: strictMap
  LazySeq: lazyMap

mapIndexed = dispatch seqType,
  Array: strictMapIndexed
  LazySeq: lazyMapIndexed

filter = dispatch seqType,
  Array: strictFilter
  LazySeq: lazyFilter

reduce = dispatch seqType,
  Array: strictReduce
  LazySeq: lazyReduce

concat = dispatch seqType,
  Array: Array.prototype.concat
  LazySeq: lazyConcat

partition = dispatch seqType,
  Array: strictPartition
  LazySeq: lazyPartition

some = dispatch seqType,
  Array: strictSome
  LazySeq: lazySome

any = dispatch seqType,
  Array: strictAny
  LazySeq: lazyAny

every = dispatch seqType,
  Array: strictEvery
  LazySeq: lazyEvery

equals = dispatch type,
  "Object:Object": objectEquals
  "Array:Array": arrayEquals
  "LazySeq:LazySeq": lazySeqEquals
  "Array:LazySeq": arrayLazySeqEquals
  "LazySeq:Array": (a, b) -> arrayLazySeqEquals(b, a)
  default: (a, b) -> a is b

# ==============================================================================
# Exports

toExport =
  arity: arity
  dispatch: dispatch
  type: type
  seqType: seqType
  eq: eq
  inc: inc
  dec: dec
  sum: sum
  even: even
  odd: odd
  identity: identity
  toFn: toFn
  get: get
  getIn: getIn
  accsr: accsr
  mesg: mesg
  keys: keys
  vals: vals
  flip: flip
  apply: apply
  call: call
  partial: partial
  array: array
  extendfn: extendfn
  merge: merge
  mergeWith: mergeWith
  groupBy: groupBy
  strictMap: strictMap
  strictMapIndexed: strictMapIndexed
  strictReduce: strictReduce
  strictFilter: strictFilter
  strictPartition: strictPartition
  strictSome: strictSome
  strictAny: strictAny
  strictEvery: strictEvery
  partition: partition
  seq: seq
  LazySeq: LazySeq
  lazyseq: lazyseq
  toLazy: toLazy
  toArray: toArray
  repeat: repeat
  repeatedly: repeatedly
  cycle: cycle
  lazyConcat: lazyConcat
  lazyPartition: lazyPartition
  drop: drop
  take: take
  lazyMap: lazyMap
  lazyMapIndexed: lazyMapIndexed
  lazyReduce: lazyReduce
  lazyFilter: lazyFilter
  lazySome: lazySome
  lazyAny: lazyAny
  lazyEvery: lazyEvery
  range: range
  last: last
  count: count
  first: first
  rest: rest
  nth: nth
  map: map
  mapIndexed: mapIndexed
  filter: filter
  reduce: reduce
  concat: concat
  some: some
  any: any
  every: every
  equals: equals
  empty: empty

if exports?
  for n, f of toExport
    exports[n] = f

if window?
  window.Fun = {}
  for n, f of toExport
    window.Fun[n] = f
