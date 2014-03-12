discard """
  output: '''1
2
3
4
5
6
a
b
t
e
s
t
'''
"""

template accept(e: expr) =
  static: assert compiles(e)

template reject(e: expr) =
  static: assert(not compiles(e))

type
  Container[T] = generic C
    C.len is Ordinal
    items(c) is iterator
    for value in C:
      value.type is T

proc takesIntContainer(c: Container[int]) =
  for e in c: echo e

takesIntContainer(@[1, 2, 3])
reject takesIntContainer(@["x", "y"])

proc takesContainer(c: Container) =
  for e in c: echo e

takesContainer(@[4, 5, 6])
takesContainer(@["a", "b"])
takesContainer "test"
reject takesContainer(10)

