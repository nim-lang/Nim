discard """
  errormsg: "cannot instantiate: \'T\'"
  line: 6
"""

proc foo[T](x: T) =
  discard

var fun = if true: foo else: foo
