discard """
  matrix: "--legacy:typedescFieldAccess"
  output: "4"
"""

type
  Foo[T] = object
    val: T

var x: Foo[int].val = 4
echo x
