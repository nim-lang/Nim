type
  TestInt = int
  TestEnum = enum
    X
    Y
  TestDistinct = distinct int

  TestObject = object
    x*: int
    y: int

var x: TestInt
var testEnum: TestEnum
var testEnum1 = X
var testDistinct: TestDistinct
var testObject: TestObject
