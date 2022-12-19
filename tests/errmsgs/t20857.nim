
discard """
  matrix: "--gc:arc; --gc:orc"
  errormsg: "assignment of UncheckedArray is not supported with ARC/ORC"
"""

type
  Obj = object
    s: string
    case b: bool
    of false: discard
    of true:
      v: int
      a: UncheckedArray[char]

var o: ref Obj
new o
o[] = Obj()
