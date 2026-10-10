discard """
  cmd: "nim check $file"
  action: "reject"
  errormsg: "invalid type: 'empty' in this context: 'array[0..0, (string, seq[empty])]' for var"
"""

# `nim check` used to crash on this after the first error
# bug #3948

var headers=[("headers", @[])]
