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

template accept(e) =
  static: assert compiles(e)

template reject(e) =
  static: assert(not compiles(e))

type
  Container[T] = concept c
    c.len is Ordinal
    items(c) is T
    for value in c:
      type(value) is T

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
