discard """
  cmd: "nim check $file"
  action: "reject"
  errormsg: "illegal recursion in type 'x'"
"""

# `nim check` used to crash on this after the first error
type x = distinct x
