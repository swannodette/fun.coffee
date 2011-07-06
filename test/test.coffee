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


{keys, vals} = fun

# exports.testKeys = (test) ->
#   o = {foo:"bar", baz:"woz"}
#   test.ok (keys o) equals