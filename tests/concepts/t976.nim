import macros

type
  int1 = distinct int
  int2 = distinct int

  int1g = concept x
    x is int1

  int2g = concept x
    x is int2

proc take[T: int1g](value: int1) =
  when T is int2:
    static: error("killed in take(int1)")

proc take[T: int2g](vale: int2) =
  when T is int1:
    static: error("killed in take(int2)")

var i1: int1 = 1.int1
var i2: int2 = 2.int2

take[int1](i1)
take[int2](i2)

template reject(e) =
  static: assert(not compiles(e))

reject take[string](i2)
reject take[int1](i2)

