discard """
  file: "tstaticvector.nim"
  output: '''0
0
2
100'''
"""

type
  RectArray*[R, C: static[int], T] = distinct array[R * C, T]

  StaticMatrix*[R, C: static[int], T] = object
    elements*: RectArray[R, C, T]

  StaticVector*[N: static[int], T] = StaticMatrix[N, 1, T]

proc foo*[N, T](a: StaticVector[N, T]): T = 0.T
proc foobar*[N, T](a, b: StaticVector[N, T]): T = 0.T


var a: StaticVector[3, int]

echo foo(a) # OK
echo foobar(a, a) # <--- hangs compiler

# bug #3112

type
  Vector[N: static[int]] = array[N, float64]
  TwoVectors[Na, Nb: static[int]] = tuple
    a: Vector[Na]
    b: Vector[Nb]

when isMainModule:
  var v: TwoVectors[2, 100]
  echo v[0].len
  echo v[1].len
  #let xx = 50
  v[1][50] = 0.0
