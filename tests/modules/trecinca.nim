discard """
  file: "trecincb.nim"
  line: 9
  errormsg: "recursive dependency: 'trecincb.nim'"
"""
# Test recursive includes

include trecincb

echo "trecina"


