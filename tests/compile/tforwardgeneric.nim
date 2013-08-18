discard """
  output: "1.1000000000000001e+00 11"
  ccodecheck: "!@'ClEnv'"
"""

proc p[T](a, b: T): T

echo p(0.9, 0.1), " ", p(9, 1)

proc p[T](a, b: T): T =
  let c = b
  result = a + b + c

