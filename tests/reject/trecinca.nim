discard """
  file: "trecinca.nim"
  line: 8
  errormsg: "recursive dependency: \'tests/reject/trecincb.nim\'"
"""
# Test recursive includes

include trecincb #ERROR_MSG recursive dependency: 'tests/trecincb.nim'

echo "trecina"


