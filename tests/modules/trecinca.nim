discard """
  file: "trecincb.nim"
  # Note: file must be "trecinab.nim"
  line: 7
  errormsg: "recursive dependency:"
"""
# Test recursive includes

include trecincb

echo "trecina"
