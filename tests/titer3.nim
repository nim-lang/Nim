# yield inside an iterator, but not in a loop:
iterator iter1(a: openArray[int]): int =
  yield a[0] #ERROR_MSG 'yield' only allowed in a loop of an iterator

var x = [[1, 2, 3], [4, 5, 6]]
for y in iter1(x[0]): write(stdout, $y)

