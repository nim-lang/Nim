discard """
  file: "tparameterizedparent3.nim"
  line: 13
  errormsg: "attempt to redefine: 'color'"
"""
# bug #5264
type
  FruitBase = object of RootObj
    color: int

  Apple[T] = object of T
    width: int
    color: int

var x: Apple[FruitBase]
