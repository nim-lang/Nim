discard """
  file: "tests/reject/trecincb.nim"
  line: 9
  errormsgpeg: " 'recursive dependency: \\'' @ 'trecincb.nim\\'' "
"""
# Test recursive includes

include trecincb

echo "trecina"
