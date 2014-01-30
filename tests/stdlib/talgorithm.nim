import unittest

suite "product":
  test "a simple case of one element":
    check product(@[@[1,2]]) == @[@[1,2]]
  test "two elements":
    check product(@[@[1,2], @[3,4]]) == @[@[2,4],@[1,4],@[2,3],@[1,3]]
  test "three elements":
    check product(@[@[1,2], @[3,4], @[5,6]]) == @[@[2,4,6],@[1,4,6],@[2,3,6],@[1,3,6], @[2,4,5],@[1,4,5],@[2,3,5],@[1,3,5]]
