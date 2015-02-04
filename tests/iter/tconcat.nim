discard """
  output: '''DabcD'''
"""

proc toIter*[T](s: Slice[T]): iterator: T =
  iterator it: T {.closure.} =
    for x in s.a..s.b:
      yield x
  return it

iterator concat*[T](its: varargs[T, toIter]): auto =
  for i in its:
    for x in i():
      yield x

for i in concat(1..4, 20..23):
  echo i
