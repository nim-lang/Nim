discard """
  line: 6
  errormsg: "cannot instantiate: \'T\'"
"""

proc m[T](x: T): int = discard
echo [m]
