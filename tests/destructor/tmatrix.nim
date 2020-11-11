discard """
  output: '''after 2 2
after 2 2
after 2 2
after 2 2'''
"""
# bug #9263
type
  Matrix* = object
    # Array for internal storage of elements.
    data: ptr UncheckedArray[float]
    # Row and column dimensions.
    m*, n*: int

var
  allocCount, deallocCount: int

proc `=destroy`*(m: var Matrix) =
  if m.data != nil:
    dealloc(m.data)
    deallocCount.inc
    m.data = nil
    m.m = 0
    m.n = 0

proc `=sink`*(a: var Matrix; b: Matrix) =
  if a.data != nil and a.data != b.data:
    dealloc(a.data)
    deallocCount.inc
  a.data = b.data
  a.m = b.m
  a.n = b.n

proc `=`*(a: var Matrix; b: Matrix) =
  if a.data != nil and a.data != b.data:
    dealloc(a.data)
    deallocCount.inc
    a.data = nil
  a.m = b.m
  a.n = b.n
  if b.data != nil:
    a.data = cast[type(a.data)](alloc(a.m * a.n * sizeof(float)))
    allocCount.inc
    copyMem(a.data, b.data, b.m * b.n * sizeof(float))

proc matrix*(m, n: int, s: float): Matrix =
  ## Construct an m-by-n constant matrix.
  result.m = m
  result.n = n
  result.data = cast[type(result.data)](alloc(m * n * sizeof(float)))
  allocCount.inc
  for i in 0 ..< m * n:
    result.data[i] = s

proc len(m: Matrix): int = m.n * m.m

proc `[]`*(m: Matrix, i, j: int): float {.inline.} =
  ## Get a single element.
  m.data[i * m.n + j]

proc `[]`*(m: var Matrix, i, j: int): var float {.inline.} =
  ## Get a single element.
  m.data[i * m.n + j]

proc `[]=`*(m: var Matrix, i, j: int, s: float) =
  ## Set a single element.
  m.data[i * m.n + j] = s

proc `-`*(m: sink Matrix): Matrix =
  ## Unary minus
  result = m
  for i in 0 ..< result.m:
    for j in 0 ..< result.n:
      result[i, j] = -result[i, j]

proc `+`*(a: sink Matrix; b: Matrix): Matrix =
  ## ``C = A + B``
  doAssert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
  doAssert(a.len == b.len) # non destructive use before sink is ok
  result = a
  for i in 0 ..< result.m:
    for j in 0 ..< result.n:
      result[i, j] = result[i, j] + b[i, j]

proc `-`*(a: sink Matrix; b: Matrix): Matrix =
  ## ``C = A - B``
  assert(b.m == a.m and b.n == a.n, "Matrix dimensions must agree.")
  doAssert(a.len == b.len) # non destructive use before sink is ok
  result = a
  for i in 0 ..< result.m:
    for j in 0 ..< result.n:
      result[i, j] = a[i, j] - b[i, j]

proc info =
  echo "after ", allocCount, " ", deallocCount
  allocCount = 0
  deallocCount = 0

proc copy(a: Matrix): Matrix = a

proc test1 =
  var a = matrix(5, 5, 1.0)
  var b = copy a
  var c = a + b

proc test2 =
  var a = matrix(5, 5, 1.0)
  var b = copy a
  var c = -a

proc test3 =
  var a = matrix(5, 5, 1.0)
  var b = matrix(5, 5, 2.0)
  #    a = a - b
  b = -b + a

proc test4 =
  # bug #9294
  var a = matrix(5, 5, 1.0)
  a = -a + a

test1()
info()

test2()
info()

test3()
info()

test4()
info()
