discard """
  errormsg: "'repr' doesn't support 'void' type"
  line: 9
"""

# bug #2879

var s: seq[int]
echo repr(s.new_seq(3))
