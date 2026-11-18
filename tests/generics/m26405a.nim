proc verifyObj*[T]() =
  type L = object
    x: T
  var l = L(x: T(1.5))
  echo l.x

proc verifyDistinct*[T](t: typedesc[T]) =
  type D = distinct T
  discard D(default(T))

proc verifyStatic*[N: static int]() =
  type Arr = object
    data: array[N, int]
  var r = new Arr
  for i in 0 ..< N:
    r.data[i] = i + 1
  echo r.data
