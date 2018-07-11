discard """
  output: "()"
"""

type
  Iterable[T] = concept x
    for elem in x:
      elem is T

proc max[A](iter: Iterable[A]): A = 
  discard

type
  MyType = object

echo max(@[MyType()])
