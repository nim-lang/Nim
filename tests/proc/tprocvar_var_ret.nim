discard """
  targets: "c cpp"
"""

# Test 1: basic var return type passed as proc parameter
# See #25870, #25846
proc testVarRet(x: var int): var int = x

proc testProcTypeParam(prc: proc (x: var int): var int {.nimcall.}) =
  var x = 123
  prc(x) = 321
  doAssert x == 321

testProcTypeParam(testVarRet)

# Test 2: direct call
var v = 42
doAssert testVarRet(v) == 42
testVarRet(v) = 99
doAssert v == 99

# Test 3: assign proc to var
var pVarRet = testVarRet
var testVar = 1234
pVarRet(testVar) = 5678
doAssert testVar == 5678

# Test 4: var return with string
proc testVarRetStr(x: var string): var string = x

proc testProcTypeParamStr(prc: proc (x: var string): var string {.nimcall.}) =
  var x = "foo"
  prc(x) = "bar"
  doAssert x == "bar"

testProcTypeParamStr(testVarRetStr)

# Test 5: var return with object
type
  FooObj = object
    x, y: int

proc testVarRetObj(x: var FooObj): var FooObj = x

proc testProcTypeParamObj(prc: proc (x: var FooObj): var FooObj {.nimcall.}) =
  var x = FooObj(x: 111, y: 222)
  prc(x) = FooObj(x: 333, y: 444)
  doAssert x == FooObj(x: 333, y: 444)

testProcTypeParamObj(testVarRetObj)

# Test 6: chained var return through proc type param
proc testProcTypeParamChain(prc: proc (x: var int): var int {.nimcall.}) =
  var x = 100
  var y = 200
  prc(x) = prc(y)
  doAssert x == 200

testProcTypeParamChain(testVarRet)

echo "ok"
