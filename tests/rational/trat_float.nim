discard """
  errormsg: '''type mismatch: got'''
  file: "trat_float.nim"
  line: "9,19"
"""
import rationals
var
  # this fails - no floats as num or den
  r = initRational(1.0'f, 1.0'f)
