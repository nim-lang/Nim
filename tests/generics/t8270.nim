discard """
  errormsg: "cannot instantiate: \'T\'"
  line: 6
"""

proc m[T](x: T): int = discard
echo [m]
