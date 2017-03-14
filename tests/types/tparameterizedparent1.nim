discard """
  file: "tparameterizedparent1.nim"
  line: 14
  errormsg: "inheritance only works with non-final objects"
"""
# bug #5264
type
  FruitBase = object
    color: int

  Apple[T] = object of T
    width: int

var x: Apple[FruitBase]
