discard """
  errormsg: "recursive dependency: 'trecincb.nim'"
  file: "trecincb.nim"
  line: 9
"""
# Test recursive includes

include trecincb

echo "trecina"
