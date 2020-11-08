discard """
  output: "3"
"""
import math

proc FibonacciA(n: int): int64 =
  var fn = float64(n)
  var p: float64 = (1.0 + sqrt(5.0)) / 2.0
  var q: float64 = 1.0 / p
  return int64((pow(p, fn) + pow(q, fn)) / sqrt(5.0))

echo FibonacciA(4) #OUT 3
