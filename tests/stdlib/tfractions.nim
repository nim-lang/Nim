import fractions
import unittest

suite "fractions":
  test "greatest common divisor":
    check:
      gcd(15, 18) == 3
      gcd(0, 0) == 0
      gcd(-3, 3) == 3

  test "fractions reduced on creation":
    check:
      newFraction(10, -8).numerator == 5
      newFraction(10, -8).denominator == -4

  test "adding fractions":
    check:
      newFraction(2, 3) + newFraction(1, 3) == newFraction(3, 3)
      newFraction(2, 3) + newFraction(1, 6) == newFraction(5, 6)

  test "subtracting fractions":
    check:
      newFraction(2, 3) - newFraction(1, 3) == newFraction(1, 3)
      newFraction(2, 3) - newFraction(1, 6) == newFraction(1, 2)

  test "multiplying fractions":
    check:
      newFraction(2, 3) * newFraction(1, 3) == newFraction(2, 9)
      newFraction(2, 3) * newFraction(1, 6) == newFraction(1, 9)

  test "dividing fractions":
    check:
      newFraction(2, 3) / newFraction(1, 3) == newFraction(2, 1)
      newFraction(2, 3) / newFraction(1, 6) == newFraction(4, 1)

  test "modulo of fractions":
    check:
      newFraction(2, 3) mod newFraction(1, 3) == newFraction(0, 1)
      newFraction(2, 3) mod newFraction(1, 6) == newFraction(0, 1)
      newFraction(2, 3) mod newFraction(3, 6) == newFraction(1, 6)
