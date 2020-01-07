discard """
  errormsg: "recursive dependency: 'tests/modules/trecincb.nim'"
  file: "trecincb.nim"
  line: 9
"""
# Test recursive includes

include trecincb

echo "trecina"
