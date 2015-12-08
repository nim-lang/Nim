discard """
  file: "tconstraints.nim"
"""

proc myGenericProc[T: object|tuple|int|ptr|ref|distinct](x: T): string =
  result = $x

type
  TMyObj = tuple[x, y: int]

var
  x: TMyObj

doAssert myGenericProc(232) == "232"
doAssert myGenericProc(x) == "(x: 0, y: 0)"
