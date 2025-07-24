type StringArray[N:int] = array[N, string]
let a = ["one", "two"]
doAssert a is StringArray
