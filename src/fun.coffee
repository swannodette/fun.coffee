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

apply = (f, args) -> f.apply null, args

call = (f, args...) -> f.apply null, args

partial = (f, rest1...) -> (rest2...) -> f.apply null, rest1.concat rest2

keys = (o) -> k for k, v of o

vals = (o) -> v for k, v of o

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

type = arity
  1: (a) ->
     a.constructor.name or a.constructor._name
  2: (a, b) ->
     aname = a.constructor.name or a.constructor._name
     bname = b.constructor.name or b.constructor._name
     "#{aname}:#{bname}"

seq = dispatch type,
  Array: identity
  LazySeq: identity
  Object: (o) -> [k, v] for k, v of o

# ==============================================================================
# Lazy Sequences

class LazySeq
  constructor: (@head, @tail) ->
  first: -> @head
  rest: -> if @tail then @tail() else null

lazyseq = (h, t) -> new LazySeq h, t

toLazy = (coll) ->
  if coll.length is 0
    return null
  h = coll[0]
  lazyseq h, -> toLazy coll[1..]

toArray = (s) ->
  acc = []
  while s
    acc.push s.first()
    s = s.rest()
  acc

range = arity
  1: (end) -> range 0, end
  2: (start, end) ->
    if start is end
      null
    else
      lazyseq start, -> range inc(start), end

repeat = arity
  1: (x) -> lazyseq x, -> repeat x
  2: (n, x) -> take n, repeat x

repeatedly = arity
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
    lazyseq a.first(), -> lazyConcat a.rest(), b

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
    lazyseq s.first(), -> take dec(n), s.rest()

last = (s) ->
  c = null
  while s
    c = s.first()
    s = s.rest()
  c

lazyMap = (f, s) ->
  if s
    lazyseq f(s.first()), -> lazyMap f, s.rest()
  else
    null

lazyMapIndexed = arity
  2: (f, s) -> lazyMapIndex f, s, 0
  3: (f, s, i) ->
    lazyseq f(s.first(), i), -> lazyMapIndexed f, s.rest(), i+1

lazyReduce = arity
  2: (f, s) -> lazyReduce f, s.first(), s.rest()
  3: (f, acc, s) ->
    while s
      acc = f acc, s.first()
      s = s.rest()
    acc

lazyFilter = (pred, s) ->
  if s
    h = s.first()
    if pred h
      lazyseq h, -> lazyFilter pred, s.rest()
    else
      lazyFilter pred, s.rest()
  else
    null

lazySome = (pred, s) ->
  if s
    h = s.first()
    if pred h
      h
    else
      lazySome pred, s.rest()
  else
     false

lazyAny = (pred, s) ->
  lazySome(pred, s) and true

lazyEvery = (pred, s) ->
  if s
    h = s.first()
    if not pred h
      false
    else
      lazyEvery pred, s.rest()
  else
     true

# ==============================================================================
# Equality

objectEquals = (a, b) ->
  for k, v of a
    if not b.hasOwnProperty(k) or not equals v, b[k]
      return false
  true

arrayEquals = (a, b) ->
  if not (a.length is b.length)
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
    ah = a.first()
    bh = b.first()
    if not equals ah, bh
      false
    else
      lazySeqEquals a.rest(), b.rest()

arrayLazySeqEquals = (a, b) ->
  lazySeqEquals toLazy(a), b

# ==============================================================================
# Generic

type = (x) ->
  x.constructor.name or x.constructor._name

seqType = arity
  2: (f, s) ->
    s.constructor.name or s.constructor._name
  default: (f, _, s) ->
    s.constructor.name or s.constructor._name

count = dispatch type,
  Array: (array) -> array.length
  LazySeq: (seq) -> reduce inc, 0, seq

first = dispatch type,
  Array: (array) -> array[0]
  LazySeq: (seq) -> seq.first()

rest = dispatch type,
  Array: (array) -> array[1..]
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
  arity: arity
  dispatch: dispatch
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
  seqType: seqType
  count: count
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

if exports?
  for n, f of toExport
    exports[n] = f

if window?
  window.Fun = {}
  for n, f of toExport
    window.Fun[n] = f
