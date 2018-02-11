discard """
  file: "tsimtych.nim"
  line: 10
  errormsg: "type mismatch: got <bool> but expected \'string\'"
"""
# Test 2
# Simple type checking

var a: string
a = false #ERROR


