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

flip = (f) -> (a, b) -> f b, a

apply = (f, args) -> f.apply null, args

call = (f, args...) -> f.apply null, args

partial = (f, rest1...) -> (rest2...) -> f.apply null, rest1.concat rest2

arity = (arities) ->
  (args...) ->
    arities[args.length or 'default'].apply null, args

dispatch = (dfn, table) ->
  f = (args...) -> table[dfn.apply(null, args) or 'default'].apply null, args
  f._table = table
  f

extendfn = (gfn, exts) ->
  for t, f of exts
    gfn._table[t] = f

# ==============================================================================
# Strict Sequences

strictMap = (f, colls...) ->
  if colls.length is 1
    f x for x, i in colls[0]
  else
    first = colls[0]
    for _, i in first
      f.apply null, x[i] for x in colls

strictReduce = arity
  2: (f, coll) -> strictReduce f, coll[0], coll[1..]
  3: (f, acc, coll) ->
    for x, i in coll
      acc = f(acc, x)
    acc

strictFilter = (pred, coll) ->
  x for x in coll when pred(x)

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
  lazyseq h, -> lazy coll[1..]

toArray = (s) ->
  acc = []
  while s
    acc.push s.first()
    s = s.rest()
  acc

integers = arity
  0: -> integers 0
  1: (x) ->
    new LazySeq x, -> integers x+1

fib = ->
  fibSeq = (a, b) -> lazyseq a, -> fibSeq b, a+b
  fibSeq 0, 1

range = arity
  1: (end) -> range 0, end
  2: (start, end) ->
    if start is end
      null
    else
      lazyseq start, -> range inc(start), end

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

# ==============================================================================
# Generic

seqType = arity
  2: (f, s) ->
    s.constructor.name
  default: (f, _, s) ->
    seqType f, s

map = dispatch seqType,
  Array: strictMap
  LazySeq: lazyMap

filter = dispatch seqType,
  Array: strictFilter
  LazySeq: lazyFilter

reduce = dispatch seqType,
  Array: strictReduce
  LazySeq: lazyReduce

# ==============================================================================
# Exports

toExport =
  inc: inc
  dec: dec
  sum: sum
  even: even
  odd: odd
  identity: identity
  toFn: toFn
  get: get
  getIn: getIn
  flip: flip
  apply: apply
  call: call
  partial: partial
  arity: arity
  dispatch: dispatch
  extendfn: extendfn
  strictMap: strictMap
  strictRduce: strictReduce
  strictFilter: strictFilter
  LazySeq: LazySeq
  lazyseq: lazyseq
  toLazy: toLazy
  toArray: toArray
  take: take
  lazyMap: lazyMap
  lazyReduce: lazyReduce
  lazyFilter: lazyFilter
  integers: integers
  range: range
  fib: fib
  last: last
  seqType: seqType
  map: map
  filter: filter
  reduce: reduce

if exports?
  for n, f of toExport
    exports[n] = f
else
  this.net = {} if not this.net?
  this.net.dnolen = {} if not this.net.dnolen?
  this.net.dnolen.fun = {} if not this.net.dnolen.fun?
  for n, f of toExport
    this.net.dnolen.fun[n] = f
