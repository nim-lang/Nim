type
  TestInt = int
  TestEnum = enum
    X
    Y
  TestDistinct = distinct int

  TestObject = object
    x*: int
    y: int

  TestObject2* = object
    x: TestObject

  TestRefInt = ref int
  TestPtrInt = ptr int

  TestRefObj = ref object
    x: int

  TestPtrObj = ptr object
    x: int

var x: TestInt
var testEnum: TestEnum
var testEnum1 = X
var testDistinct: TestDistinct
var testObject: TestObject
var testObject2*: TestObject2

var testRefInt: TestRefInt = nil
var testRefInt2: ref int = nil
var testPtrInt: TestPtrInt = nil
var testPtrInt2: ptr int = nil
var testRefObj: TestRefObj = nil
var testPtrObj: TestPtrObj = nil
