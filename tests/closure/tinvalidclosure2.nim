discard """
  errormsg: "illegal capture 'A'"
  line: 10
"""

proc outer() =
  var A: int

  proc ugh[T](x: T) {.cdecl.} =
    echo "ugha", A, x

  ugh[int](12)

outer()
