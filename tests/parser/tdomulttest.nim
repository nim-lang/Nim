discard """
  output: "555\ntest\nmulti lines\n99999999\nend"
"""

proc foo(bar, baz: proc (x: int): int) =
  echo bar(555)
  echo baz(99999999)

foo do (x: int) -> int:
  return x

do (x: int) -> int:
  echo("test")
  echo("multi lines")
  return x

echo("end")
