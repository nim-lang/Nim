import unittest
import algorithm

suite "product":
  test "empty input":
    check product[int](newSeq[seq[int]]()) == newSeq[seq[int]]()
  test "bit more empty input":
    check product[int](@[newSeq[int](), @[], @[]]) == newSeq[seq[int]]()
  test "a simple case of one element":
    check product(@[@[1,2]]) == @[@[1,2]]
  test "two elements":
    check product(@[@[1,2], @[3,4]]) == @[@[2,4],@[1,4],@[2,3],@[1,3]]
  test "three elements":
    check product(@[@[1,2], @[3,4], @[5,6]]) == @[@[2,4,6],@[1,4,6],@[2,3,6],@[1,3,6], @[2,4,5],@[1,4,5],@[2,3,5],@[1,3,5]]
