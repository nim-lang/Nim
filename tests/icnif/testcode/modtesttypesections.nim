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

var x: TestInt
var testEnum: TestEnum
var testEnum1 = X
var testDistinct: TestDistinct
var testObject: TestObject
var testObject2*: TestObject2
