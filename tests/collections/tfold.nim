import sequtils

# foldl tests
var
  numbers = @[5, 9, 11]
  addition = foldl(numbers, a + b)
  subtraction = foldl(numbers, a - b)
  multiplication = foldl(numbers, a * b)
  words = @["nim", "is", "cool"]
  concatenation = foldl(words, a & b)
doAssert addition == 25, "Addition is (((5)+9)+11)"
doAssert subtraction == -15, "Subtraction is (((5)-9)-11)"
doAssert multiplication == 495, "Multiplication is (((5)*9)*11)"
doAssert concatenation == "nimiscool"

# foldr tests
numbers = @[5, 9, 11]
addition = foldr(numbers, a + b)
subtraction = foldr(numbers, a - b)
multiplication = foldr(numbers, a * b)
words = @["nim", "is", "cool"]
concatenation = foldr(words, a & b)
doAssert addition == 25, "Addition is (5+(9+(11)))"
doAssert subtraction == 7, "Subtraction is (5-(9-(11)))"
doAssert multiplication == 495, "Multiplication is (5*(9*(11)))"
doAssert concatenation == "nimiscool"
