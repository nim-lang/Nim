import
  macros,
  "../config"

type
  TV2*[T:SomeNumber=TR] = array[0..1, T]
  TV3*[T:SomeNumber=TR] = array[0..2, T]
  TV4*[T:SomeNumber=TR] = array[0..3, T]
  TVT*[T:SomeNumber=TR] = TV2|TV3|TV4
  #TV2* = array[0..1, TR]
  #TV3* = array[0..2, TR]
  #TV4* = array[0..3, TR]

# TODO: Change to TVT when compiler issue is resolved.
proc `$`*[T](o: TV2[T]): string =
  result = "("
  for i in 0 ..< o.len:
    result &= $o[0]
    if i != o.len - 1:
      result &= ", "

  result & ")"

proc newV2T*[T](x, y: T=0): TV2[T] =
  [x, y]

proc newV2*(x, y: TR=0.0): TV2[TR] =
  [x, y]

proc newV2xy*(xy: TR): TV2[TR] =
  [xy, xy]

proc x*[T](o: TV2[T]): T =
  o[0]

proc y*[T](o: TV2[T]): T =
  o[1]

proc `*`*(lhs: TV2[TR], rhs: TV2[TR]): TV2[TR] =
  [(lhs.x * rhs.x).TR, (lhs.y * rhs.y).TR]

proc `+`*(lhs: TV2[TR], rhs: TV2[TR]): TV2[TR] =
  [(lhs.x + rhs.x).TR, (lhs.y + rhs.y).TR]

#proc dotProduct[T](a: TVT[T], b: TVT[T]): T =
#  for i in 0 .. a.len - 1:
#    result += a[i] * b[i]

proc dot[T](a, b: TV2[T]): T =
  for i in 0 ..< a.len:
    result += a[i] * b[i]

assert dot(newV2(), newV2()) == 0.0
assert dot(newV2(2, 3), newV2(6, 7)) == 33.0
assert dot([2.0, 3.0], [6.0, 7.0]) == 33.0
