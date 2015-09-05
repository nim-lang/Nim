discard """
  line: 13
  errormsg: "duplicate case label"
"""

type
  TE = enum A, B, C, D

var
  e: TE

case e
of A..D, B..C:
  echo "redundant"
else: nil
