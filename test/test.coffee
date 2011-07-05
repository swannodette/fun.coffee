nu = require("nodeunit")
fun = require("../src/fun.coffee")

{inc, dec} = fun

exports.testInc = (test) ->
  test.ok true, fun.inc 1 is 2
  test.done()

exports.testDec = (test) ->
  test.ok true, fun.dec 2 is 1
  test.done()


