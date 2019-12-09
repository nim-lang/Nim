discard """
  errormsg: "closing \" expected"
  file: "trawstr.nim"
  line: 10
"""
# Test the new raw strings:

const
  xxx = r"This is a raw string!"
  yyy = "This not\" #ERROR
