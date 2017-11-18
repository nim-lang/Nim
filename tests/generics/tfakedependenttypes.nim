discard """
output: '''
U[3]
U[(f: 3)]
U[[3]]
'''
"""

# https://github.com/nim-lang/Nim/issues/5106

import typetraits

block:
  type T = distinct int

  proc `+`(a, b: T): T =
    T(int(a) + int(b))

  type U[F: static[T]] = distinct int

  proc `+`[P1, P2: static[T]](a: U[P1], b: U[P2]): U[P1 + P2] =
    U[P1 + P2](int(a) + int(b))

  var a = U[T(1)](1)
  var b = U[T(2)](2)
  var c = a + b
  echo c.type.name
  
block:
  type T = object
    f: int

  proc `+`(a, b: T): T =
    T(f: a.f + b.f)

  type U[F: static[T]] = distinct int

  proc `+`[P1, P2: static[T]](a: U[P1], b: U[P2]): U[P1 + P2] =
    U[P1 + P2](int(a) + int(b))

  var a = U[T(f: 1)](1)
  var b = U[T(f: 2)](2)
  var c = a + b
  echo c.type.name

block:
  type T = distinct array[0..0, int]

  proc `+`(a, b: T): T =
    T([array[0..0, int](a)[0] + array[0..0, int](b)[0]])

  type U[F: static[T]] = distinct int

  proc `+`[P1, P2: static[T]](a: U[P1], b: U[P2]): U[P1 + P2] =
    U[P1 + P2](int(a) + int(b))

  var a = U[T([1])](1)
  var b = U[T([2])](2)
  var c = a + b
  echo c.type.name

