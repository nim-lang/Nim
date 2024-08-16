discard """
  matrix: "--mm:refc"
  errormsg: "type mismatch: got <typedesc[int]>"
  line: 7
"""
# bug #3079, #1146
echo repr(int)