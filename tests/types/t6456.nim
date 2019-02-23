discard """
  errormsg: "type \'ptr void\' is not allowed"
  line: 6
"""

proc foo(x: ptr void) =
  discard
