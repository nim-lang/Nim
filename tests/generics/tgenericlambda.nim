discard """
  output: "10\n10"
"""

proc test(x: proc (a, b: int): int) =
  echo x(5, 5)

test(proc (a, b): auto = a + b)

test do (a, b) -> auto: a + b
