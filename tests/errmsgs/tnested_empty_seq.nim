discard """
  errormsg: "invalid type: 'empty' in this context: 'array[0..0, tuple of (string, seq[empty])]' for var"
  line: 8
"""

# bug #3948

var headers=[("headers", @[])]
