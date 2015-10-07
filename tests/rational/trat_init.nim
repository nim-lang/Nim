discard """
  file: "trat_init.nim"
  exitcode: "1"
"""
import rationals
var
  z = Rational[int](num: 0, den: 1)
  o = initRational(num=1, den=1)
  a = initRational(1, 2)
  r = initRational(1, 0)  # this fails - no zero denominator
