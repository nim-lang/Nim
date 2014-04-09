# bug #1023

discard """
  output: "1 == 1"
"""

type Quadruple = tuple[a, b, c, d: int]

proc `+`(s, t: Quadruple): Quadruple =
  (a: s.a + t.a, b: s.b + t.b, c: s.c + t.c, d: s.d + t.d)

const
  A = (a: 0, b: -1, c: 0, d: 1)
  B = (a: 0, b: -2, c: 1, d: 0)
  C = A + B

echo C.d, " == ", (A+B).d
