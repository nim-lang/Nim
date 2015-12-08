discard """
  file: "tnolen.nim"
  line: 9
  errormsg: "type mismatch: got (int literal(3))"
"""

# please finally disallow Len(3)

echo len(3)

