discard """
  file: "tparameterizedparent3.nim"
  line: 13
  errormsg: "redefinition of 'color'"
"""
# bug #5264
type
  FruitBase = object of RootObj
    color: int

  Apple[T] = object of T
    width: int
    color: int

var x: Apple[FruitBase]
