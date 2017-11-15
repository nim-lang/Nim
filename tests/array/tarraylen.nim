discard """
  output: ""
"""
var a: array[0, int]
doAssert a.len == 0
doAssert array[0..0, int].len == 1
doAssert array[0..0, int]([1]).len == 1
doAssert array[1..1, int].len == 1
doAssert array[1..1, int]([1]).len == 1
doAssert array[2, int].len == 2
doAssert array[2, int]([1, 2]).len == 2
doAssert array[1..3, int].len == 3
doAssert array[1..3, int]([1, 2, 3]).len == 3
doAssert array[0..2, int].len == 3
doAssert array[0..2, int]([1, 2, 3]).len == 3
doAssert array[-2 .. -2, int].len == 1
doAssert([1, 2, 3].len == 3)
doAssert([42].len == 1)