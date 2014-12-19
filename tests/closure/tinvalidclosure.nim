discard """
  line: 12
  errormsg: "type mismatch: got (proc (int){.closure, gcsafe, locks: 0.})"
"""

proc ugh[T](x: T) {.closure.} =
  echo "ugha"


proc takeCdecl(p: proc (x: int) {.cdecl.}) = discard

takeCDecl(ugh[int])
