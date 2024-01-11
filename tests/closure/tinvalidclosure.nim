discard """
  errormsg: "type mismatch: got <proc (x: int){.nimcall, gcsafe, raises: <inferred> [].}>"
  line: 12
"""

proc ugh[T](x: T) {.nimcall.} =
  echo "ugha"


proc takeCdecl(p: proc (x: int) {.cdecl.}) = discard

takeCDecl(ugh[int])
