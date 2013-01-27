discard """
  output: "1.0000000000000000e+00 10"
  ccodecheck: "!@'ClEnv'"
"""

proc p[T](a, b: T): T

echo p(0.9, 0.1), " ", p(9, 1)

proc p[T](a, b: T): T =
  result  = a + b

