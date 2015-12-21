discard """
  line: 9
  errormsg: "closing \" expected"
"""
# Test the new raw strings:

const
  xxx = r"This is a raw string!"
  yyy = "This not\" #ERROR
