discard """
  output: '''(Field0: 1, Field1: 1)
(Field0: 2, Field1: 2)
(Field0: 3, Field1: 3)
'''
"""

iterator zip[T1, T2](a: openarray[T1], b: openarray[T2]): iterator() {.inline.} =
  let len = min(a.len, b.len)
  for i in 0..<len:
    echo (a[i], b[i])

proc foo(args: varargs[int]) =
  for i in zip(args,args):
    discard

foo(1,2,3)
