discard """
  file: "tinvalidclosure2.nim"
  line: 11
  errormsg: "illegal capture 'A'"
"""

proc outer() =
  var A: int

  proc ugh[T](x: T) {.cdecl.} =
    echo "ugha", A, x

  ugh[int](12)

outer()
