discard """
  action: reject
  nimout: '''
t9039.nim(22, 22) Error: type mismatch: got <array[0..2, int], int, array[0..1, int]>
but expression 'nesting + 1' is of type: int
'''
"""

# bug #9039; this used to hang in 0.19.0





# line 15
func default(T: typedesc[array]): T = discard
doAssert default(array[3, int]) == [0, 0, 0]
func shapeBad*[T: not char](s: openArray[T], rank: static[int], nesting = 0, parent_shape = default(array[rank, int])): array[rank, int] =
  result = parent_shape
  result[nesting] = s.len
  when (T is seq|array):
    result = shapeBad(s[0], nesting + 1, result)
let a1 = [1, 2, 3].shapeBad(rank = 1)
let a2 = [[1, 2, 3], [4, 5, 6]].shapeBad(rank = 2)
