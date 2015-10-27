discard """
  line: 9
  errormsg: "'repr' doesn't support 'void' type"
"""

# bug #2879

var s: seq[int]
echo repr(s.new_seq(3))
