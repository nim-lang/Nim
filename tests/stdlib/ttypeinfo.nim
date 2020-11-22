import typeinfo

type
  TE = enum
    blah, blah2

  TestObj = object
    test, asd: int
    case test2: TE
    of blah:
      help: string
    else:
      nil


var test = @[0,1,2,3,4]
var x = toAny(test)
var y = 78
x[4] = toAny(y)
assert x[2].getInt == 2

var test2: tuple[name: string, s: int] = ("test", 56)
var x2 = toAny(test2)
var i = 0
for n, a in fields(x2):
  case i
  of 0: assert n == "Field0" and $a.kind == "akString"
  of 1: assert n == "Field1" and $a.kind == "akInt"
  else: assert false
  inc i

var test3: TestObj
test3.test = 42
test3 = TestObj(test2: blah2)
var x3 = toAny(test3)
i = 0
for n, a in fields(x3):
  case i
  of 0: assert n == "test" and $a.kind == "akInt"
  of 1: assert n == "asd" and $a.kind == "akInt"
  of 2: assert n == "test2" and $a.kind == "akEnum"
  else: assert false
  inc i

var test4: ref string
new(test4)
test4[] = "test"
var x4 = toAny(test4)
assert($x4[].kind() == "akString")

block:
  # gimme a new scope dammit
  var myarr: array[0..4, array[0..4, string]] = [
    ["test", "1", "2", "3", "4"], ["test", "1", "2", "3", "4"],
    ["test", "1", "2", "3", "4"], ["test", "1", "2", "3", "4"],
    ["test", "1", "2", "3", "4"]]
  var m = toAny(myArr)
  for i in 0 .. m.len-1:
    for j in 0 .. m[i].len-1:
      doAssert getString(m[i][j]) == myArr[i][j]
