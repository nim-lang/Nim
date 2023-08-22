
discard """
  errormsg: "func keyword is not allowed in type descriptions, use proc with {.noSideEffect.} pragma instead"
"""

type
  MyObject = object
    fn: func(a: int): int

proc myproc(a: int): int =
  echo "bla"
  result = a

var x = MyObject(fn: myproc)