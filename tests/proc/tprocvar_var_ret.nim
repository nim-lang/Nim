discard """
  targets: "c cpp"
"""

proc testVarRet(x: var int): var int = x

proc testProcTypeParam(prc: proc (x: var int): var int {.nimcall.}) =
  var x = 123
  prc(x) = 321
  doAssert x == 321
  var y = 456
  prc(x) = prc(y)
  doAssert x == 456 and y == 456

testProcTypeParam(testVarRet)

var pVarRet = testVarRet
var testVar = 1234
pVarRet(testVar) = 5678
doAssert testVar == 5678

proc testVarRetStr(x: var string): var string = x

proc testProcTypeParamStr(prc: proc (x: var string): var string {.nimcall.}) =
  var x = "foo"
  prc(x) = "bar"
  doAssert x == "bar"
  var y = "baz"
  prc(x) = prc(y)
  doAssert x == "baz" and y == "baz"

testProcTypeParamStr(testVarRetStr)

var pVarRetStr = testVarRetStr
var testVarStr = "abc"
pVarRetStr(testVarStr) = "def"
doAssert testVarStr == "def"

type
  FooObj = object
    x, y: int

proc testVarRetObj(x: var FooObj): var FooObj = x

proc testProcTypeParamObj(prc: proc (x: var FooObj): var FooObj {.nimcall.}) =
  var x = FooObj(x: 111, y: 222)
  prc(x) = FooObj(x: 333, y: 444)
  doAssert x == FooObj(x: 333, y: 444)

testProcTypeParamObj(testVarRetObj)

var pVarRetObj = testVarRetObj
var testVarObj = FooObj(x: 10, y: 20)
pVarRetObj(testVarObj) = FooObj(x: 30, y: 40)
doAssert testVarObj == FooObj(x: 30, y: 40)
