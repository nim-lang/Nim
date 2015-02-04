discard """
  file: "trawstr.nim"
  line: 10
  errormsg: "closing \" expected"
"""
# Test the new raw strings:

const
  xxx = r"This is a raw string!"
  yyy = "This not\" #ERROR


