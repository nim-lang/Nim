type
  ExampleArray[Size, T] = array[Size, T]

var integerArray: ExampleArray[32, int]  # Compiler crash!
doAssert integerArray.len == 32

const Size = 2
var integerArray2: ExampleArray[Size, int]
doAssert integerArray2.len == 2
