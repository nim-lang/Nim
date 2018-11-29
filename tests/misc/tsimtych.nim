discard """
  errormsg: "type mismatch: got <bool> but expected \'string\'"
  file: "tsimtych.nim"
  line: 10
"""
# Test 2
# Simple type checking

var a: string
a = false #ERROR
