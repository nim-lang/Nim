discard """
  file: "trecincb.nim"
  line: 9
  errormsgpeg: " 'recursive dependency: \\'' @ 'trecincb.nim\\'' "
"""
# Test recursive includes


include trecincb

echo "trecinb"
