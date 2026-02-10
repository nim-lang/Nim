# Section: Addressable conversion between distinct static parameters (#22523).

from std/typetraits import distinctBase

type
  V[p: static int] = distinct int
  D[p: static int] = distinct int
  T = V[1]

proc f(y: var T) = discard

var a: D[0]

static:
  # Section: Distinct base resolution is consistent across static parameters.
  doAssert distinctBase(T) is distinctBase(D[0])
  doAssert distinctBase(T) is int
  doAssert distinctBase(D[0]) is int
  doAssert T(a) is T

# Section: Conversions through pointers and casts remain valid.
f(cast[ptr T](addr a)[])
f(T(a))
