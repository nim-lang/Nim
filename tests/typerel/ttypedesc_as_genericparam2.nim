discard """
  line: 9
  errormsg: "type mismatch: got (empty)"
"""

# bug #2879

var s: seq[int]
echo repr(s.new_seq(3))
