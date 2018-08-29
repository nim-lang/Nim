discard """
  output: "1"
"""

proc foo[T](bar: proc (x, y: T): int = system.cmp, baz: int) =
  echo "1"

proc foo[T](bar: proc (x, y: T): int = system.cmp) =
  echo "2"

foo[int](baz = 5)
