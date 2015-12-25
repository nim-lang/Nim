discard """
  line: "8,19"
  errormsg: '''type mismatch: got'''
"""
import rationals
var
  # this fails - no floats as num or den
  r = initRational(1.0'f, 1.0'f)
