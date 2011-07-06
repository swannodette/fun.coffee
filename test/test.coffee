nu = require("nodeunit")
fun = require("../src/fun.coffee")


{inc, dec, sum, even, odd, identity} = fun

exports.testInc = (test) ->
  test.ok inc 1 is 2
  test.done()

exports.testDec = (test) ->
  test.ok dec 2 is 1
  test.done()

exports.testSum = (test) ->
  test.ok (sum 4, 5) is 9
  test.done()

exports.testEven = (test) ->
  test.ok (even 2) is true
  test.done()

exports.testOdd = (test) ->
  test.ok (odd 3) is true
  test.done()

exports.testIdentity = (test) ->
  test.ok (identity 1) is 1
  test.done()


{toFn, get, getIn, accsr, mesg} = fun

exports.testToFn1 = (test) ->
  o = [1,2,3]
  test.ok toFn(o)(2) is 3
  test.done()

exports.testToFn2 = (test) ->
  o = {foo: "bar"}
  test.ok toFn(o)("foo") is "bar"
  test.done()

exports.testGet1 = (test) ->
  o = {foo: "bar"}
  test.ok (get o, "foo") is "bar"
  test.done()

exports.testGet2 = (test) ->
  o = [1,2,3]
  test.ok (get o, 2) is 3
  test.done()

exports.testGetIn = (test) ->
  o = [1,2,{foo:"bar"}]
  test.ok (getIn o, [2, "foo", 2]) is "r"
  test.done()

exports.testAccsr = (test) ->
  a = [1,2,3]
  test.ok (accsr 2, a) is 3
  test.done()

exports.testMesg = (test) ->
  o = {foo: (a, b) -> a + b}
  m = mesg "foo", 1, 2
  test.ok (m o) is 3
  test.done()


{flip, apply, call, partial} = fun

exports.testFlip = (test) ->
  f = (a, b) -> a + b
  test.ok ((flip f) "foo", "bar") is "barfoo"
  test.done()

exports.testApply = (test) ->
  f = (a, b) -> a + b
  test.ok (apply f, [1,2]) is 3
  test.done()

exports.testCall = (test) ->
  f = (a, b) -> a + b
  test.ok (call f, 1, 2) is 3
  test.done()

exports.testPartial = (test) ->
  f = (a, b) -> a + b
  test.ok ((partial f, 1) 2) is 3
  test.done()


{equals, keys, vals} = fun

exports.testKeys = (test) ->
  o = {foo:"bar", baz:"woz"}
  test.ok equals keys(o), ["foo", "baz"]
  test.done()

exports.testVals = (test) ->
  o = {foo:"bar", baz:"woz"}
  test.ok equals vals(o), ["bar", "woz"]
  test.done()


{arity, dispatch, extendfn} = fun

exports.testArity = (test) ->
  f = arity
    0: -> 0
    1: -> 1
    2: -> 2
    default: -> "default"
  test.ok f() is 0
  test.ok f(1) is 1
  test.ok f(1,2) is 2
  test.ok f(1,2,3,4) is "default"
  test.done()

exports.testDispatch = (test) ->
  d = (a) ->
    if a is 0
      "foo"
    else if a is 1
      "bar"
  f = dispatch d,
    foo: -> "wow"
    bar: -> "pow"
    default: -> "default"
  test.ok f(0) is "wow"
  test.ok f(1) is "pow"
  test.ok f("yuk") is "default"
  test.done()

exports.testExtendfn = (test) ->
  d = (a) -> a.name
  f = dispatch d,
    foo: -> "original"
  extendfn f, {bar: -> "extended"}
  test.ok f({name:"bar"}) is "extended"
  test.done()


{merge, mergeWith} = fun

exports.testMerge = (test) ->
  o1 = {foo: "bar0"}
  o2 = {foo: "bar1", baz: "woz0"}
  test.ok equals (merge o1, o2), {foo:"bar1", baz:"woz0"}
  test.done()

exports.testMergeWith = (test) ->
  o1 = {foo: [1,2], bar: [5,6]}
  o2 = {foo: [3,4], bar: [7,8]}
  f = (a, b) -> a.concat b
  test.ok equals (mergeWith f, o1, o2), {foo:[1,2,3,4],bar:[5,6,7,8]}
  test.done()


{groupBy, strictMap, strictReduce, strictFilter, strictPartition} = fun
{strictSome, strictAny, strictEvery} = fun

exports.testGroupBy = (test) ->
  a = [0..10]
  f = (a) -> if even a then "even" else "odd"
  test.ok equals groupBy(f, a), {even:[0,2,4,6,8,10], odd:[1,3,5,7,9]}
  test.done()

exports.strictMap = (test) ->
  a = [0..10]
  test.ok equals strictMap(inc, a), [1..11]
  test.done()

exports.strictReduce = (test) ->
  a = [0..10]
  test.ok strictReduce(sum, a) is 55
  test.done()

exports.strictFilter = (test) ->
  a = [0..10]
  test.ok equals strictFilter(odd, a), [1,3,5,7,9]
  test.done()

exports.strictPartition = (test) ->
  a = [1..10]
  test.ok equals strictPartition(2, a), [[1,2],[3,4],[5,6],[7,8],[9,10]]
  test.done()

exports.strictSome1 = (test) ->
  a = [false, false, false, false, "foo", false, false, false, false]
  test.ok strictSome(identity, a) is "foo"
  test.done()

exports.strictSome2 = (test) ->
  a = [false, false, false, false, false, false, false, false, false]
  test.ok strictSome(identity, a) is false
  test.done()

exports.strictAny = (test) ->
  a = [false, false, false, false, "foo", false, false, false, false]
  test.ok strictAny(identity, a) is true
  test.done()

exports.strictEvery1 = (test) ->
  a = [true, true, true, true, true, true, true, true, true]
  test.ok strictEvery(identity, a)
  test.done()

exports.strictEvery1 = (test) ->
  a = [true, true, true, true, false, true, true, true, true]
  test.ok strictEvery(identity, a) is false
  test.done()


{take, toLazy, toArray} = fun

exports.testRoundtripLazy = (test) ->
  a = [0..10]
  b = toLazy a
  c = toArray b
  test.ok equals a, c
  test.done()


{range, repeat, repeatedly, cycle, lazyConcat} = fun

exports.testRange = (test) ->
  a = [1..9]
  r = range 1, 10
  test.ok equals a, r
  test.done()

exports.testRepeat = (test) ->
  a = repeat 5, 1
  test.ok equals a, [1,1,1,1,1]
  test.done()

exports.testRepeatedly = (test) ->
  a = repeatedly 5, -> 1
  test.ok equals a, [1,1,1,1,1]
  test.done()

exports.testCycle = (test) ->
  a = [1,2,3]
  s = take 9, cycle a
  test.ok equals s, [1,2,3,1,2,3,1,2,3]
  test.done()
