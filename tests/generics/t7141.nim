discard """
  action: "reject"
  line: 7
  errormsg: "cannot instantiate: \'T\'"
"""

proc foo[T](x: T) =
  discard

var fun = if true: foo else: foo
