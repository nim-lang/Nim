discard """
  file: "ttypedesc_as_genericparam1.nim"
  line: 7
  errormsg: "type mismatch: got (typedesc[int])"
"""
# bug #3079, #1146
echo repr(int)
