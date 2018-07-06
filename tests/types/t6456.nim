discard """
  line: 6
  errormsg: "type \'ptr void\' is not allowed"
"""

proc foo(x: ptr void) =
  discard
