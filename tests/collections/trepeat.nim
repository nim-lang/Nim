import sequtils

# repeat tests
doAssert repeat(10, 5) == @[10, 10, 10, 10, 10]
doAssert repeat(@[1,2,3], 2) == @[@[1,2,3], @[1,2,3]]
