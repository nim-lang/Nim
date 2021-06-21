import std/intsets

proc test1*[]() =
  let a = initIntSet()
  doAssert len(a) == 0

proc test2*[]() =
  var a = initIntSet()
  var b = initIntSet()
  a.incl b
