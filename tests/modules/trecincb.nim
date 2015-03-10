discard """
  file: "trecincb.nim"
  line: 9
  errormsg: "recursive dependency: 'tests/modules/trecincb.nim'"
"""
# Test recursive includes


include trecincb #ERROR_MSG recursive dependency: 'tests/modules/trecincb.nim'

echo "trecinb"


