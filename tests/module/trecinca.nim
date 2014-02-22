discard """
  file: "tests/reject/trecincb.nim"
  line: 9
  errormsg: "recursive dependency: 'tests/module/trecincb.nim'"
"""
# Test recursive includes

include trecincb #ERROR_MSG recursive dependency: 'tests/trecincb.nim'

echo "trecina"


