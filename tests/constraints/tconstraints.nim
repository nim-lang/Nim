discard """
  errormsg: "type mismatch: got <int literal(232)>"
  line: 16
"""

proc myGenericProc[T: object|tuple|ptr|ref|distinct](x: T): string =
  result = $x

type
  TMyObj = tuple[x, y: int]

var
  x: TMyObj

assert myGenericProc(x) == "(x: 0, y: 0)"
assert myGenericProc(232) == "232"
