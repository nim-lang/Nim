import sequtils

# any
var
  numbers = @[1, 4, 5, 8, 9, 7, 4]
  len0seq : seq[int] = @[]
doAssert any(numbers, proc (x: int): bool = return x > 8) == true
doAssert any(numbers, proc (x: int): bool = return x > 9) == false
doAssert any(len0seq, proc (x: int): bool = return true) == false

# anyIt
numbers = @[1, 4, 5, 8, 9, 7, 4]
len0seq = @[]
doAssert anyIt(numbers, it > 8) == true
doAssert anyIt(numbers, it > 9) == false
doAssert anyIt(len0seq, true) == false

# all
numbers = @[1, 4, 5, 8, 9, 7, 4]
len0seq = @[]
doAssert all(numbers, proc (x: int): bool = return x < 10) == true
doAssert all(numbers, proc (x: int): bool = return x < 9) == false
doAssert all(len0seq, proc (x: int): bool = return false) == true

# allIt
numbers = @[1, 4, 5, 8, 9, 7, 4]
len0seq = @[]
doAssert allIt(numbers, it < 10) == true
doAssert allIt(numbers, it < 9) == false
doAssert allIt(len0seq, false) == true
