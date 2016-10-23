discard """
  output: "10\n10\n1\n2\n3\n15"
"""

proc test(x: proc (a, b: int): int) =
  echo x(5, 5)

test(proc (a, b: auto): auto = a + b)

test do (a, b: auto) -> auto: a + b

proc foreach[T](s: seq[T], body: proc(x: T)) =
  for e in s:
    body(e)

foreach(@[1,2,3]) do (x: auto):
  echo x

proc foo =
  let x = proc (a, b: int): auto = a + b
  echo x(5, 10)

foo()
