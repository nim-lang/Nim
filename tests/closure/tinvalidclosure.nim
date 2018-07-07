discard """
  line: 12
  errormsg: "type mismatch: got <proc (x: int){.gcsafe, locks: 0.}>"
"""

proc ugh[T](x: T) {.nimcall.} =
  echo "ugha"


proc takeCdecl(p: proc (x: int) {.cdecl.}) = discard

takeCDecl(ugh[int])
