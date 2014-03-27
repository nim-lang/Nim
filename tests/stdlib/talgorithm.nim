import algorithm

doAssert product[int](newSeq[seq[int]]()) == newSeq[seq[int]](), "empty input"
doAssert product[int](@[newSeq[int](), @[], @[]]) == newSeq[seq[int]](), "bit more empty input"
doAssert product(@[@[1,2]]) == @[@[1,2]], "a simple case of one element"
doAssert product(@[@[1,2], @[3,4]]) == @[@[2,4],@[1,4],@[2,3],@[1,3]], "two elements"
doAssert product(@[@[1,2], @[3,4], @[5,6]]) == @[@[2,4,6],@[1,4,6],@[2,3,6],@[1,3,6], @[2,4,5],@[1,4,5],@[2,3,5],@[1,3,5]], "three elements"
doAssert product(@[@[1,2], @[]]) == newSeq[seq[int]](), "two elements, but one empty"
doAssert lowerBound([1,2,4], 3, system.cmp[int]) == 2
doAssert lowerBound([1,2,2,3], 4, system.cmp[int]) == 4
doAssert lowerBound([1,2,3,10], 11) == 4