discard """
  errormsg: "duplicate case label"
  line: 13
"""

type
  TE = enum A, B, C, D

var
  e: TE

case e
of A..D, B..C:
  echo "redundant"
else: nil
