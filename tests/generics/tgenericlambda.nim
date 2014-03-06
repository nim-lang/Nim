discard """
  output: "10\n10\n1\n2\n3"
"""

proc test(x: proc (a, b: int): int) =
  echo x(5, 5)

test(proc (a, b): auto = a + b)

test do (a, b) -> auto: a + b

proc foreach[T](s: seq[T], body: proc(x: T)) =
  for e in s:
    body(e)

foreach(@[1,2,3]) do (x):
  echo x

