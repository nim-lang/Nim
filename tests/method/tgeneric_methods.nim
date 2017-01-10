discard """
  output: "wow2"
"""
type
  First[T] = ref object of RootObj
    value: T

  Second[T] = ref object of First[T]
    value2: T

method wow[T](y: int; x: First[T]) {.base.} =
  echo "wow1"

method wow[T](y: int; x: Second[T]) =
  echo "wow2"

var
  x: Second[int]
new(x)

proc takeFirst(x: First[int]) =
  wow(2, x)

takeFirst(x)
