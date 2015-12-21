discard """
  line: 10
  errormsg: "illegal capture 'A'"
"""

proc outer() =
  var A: int

  proc ugh[T](x: T) {.cdecl.} =
    echo "ugha", A, x

  ugh[int](12)

outer()
