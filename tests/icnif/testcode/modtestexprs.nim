type
  FooEnum = enum
    X,
    Y,
    Z

var enumTest = X
enumTest = Y
assert enumTest == Y

var enumSet = {X, Y}
enumSet.incl Z

var intArray = [1, 1 + 1, 1 * 2, 0]
intArray[3] = intArray[1] + intArray[0] * intArray[2]
var strArray = ["foo", "ba" & "r", ""]
strArray[2] = $(intArray[2])
var floatArray = [intArray[0].float, 1.0, 0.0]
floatArray[2] = floatArray[0] + floatArray[1]
var intSeq = @[3, 2]
intSeq.add 1

var tup1 = (foo: "Foo", bar: 123)
tup1.foo = "Bar"
tup1.bar = 321
tup1[0] = "Baz"
assert tup1 is (string, int)
let (tup1foo, tup1bar) = tup1
let (_, tup1bar2) = tup1
let (tup1foo2, _) = tup1

var testAddr: int
var testPtr = addr testAddr
testPtr[] = 123

var testAddr2: array[2, int]
var testPtr2: ptr int
testPtr2 = addr testAddr2[0]
var testPointer: pointer = testPtr2
testPtr2 = cast[ptr int](testPointer)

var stmtListExpr = (echo "foo"; "stmtListExpr")
var cond1 = true
var testIfExpr = if cond1: 1 else: -1
const TestWhenExpr = when sizeof(int) == 8: 1 else: -1
var cond2: FooEnum = X
var testCaseExpr = case cond2
  of X:
    1
  of Y:
    2
  else:
    3

var testBlockExpr = block:
  var a = "test"
  a

var testTryExpr = try:
    if cond1:
      222
    else:
      raise newException(CatchableError, "test")
  except CatchableError:
    -123

var testTryExpr2 = try:
    if cond1:
      333
    else:
      raise newException(CatchableError, "test")
  except CatchableError as e:
    echo e.msg
    -1234
  finally:
    echo "finally"

proc getNum(a: int): int = a
echo static(getNum(123))
