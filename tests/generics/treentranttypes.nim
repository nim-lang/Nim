discard """
output: '''
(10, ("test", 1.2))
3x3 Matrix [[0.0, 2.0, 3.0], [2.0, 0.0, 5.0], [2.0, 0.0, 5.0]]
2x3 Matrix [[0.0, 2.0, 3.0], [2.0, 0.0, 5.0]]
2x3 Literal [[0.0, 2.0, 3.0], [2.0, 0.0, 5.0]]
2x3 Matrix [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
2x2 ArrayArray[[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
2x3 ArrayVector[[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
2x3 VectorVector [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
2x3 VectorArray [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]]
@[1, 2]
@[1, 2]
@[1, 2]@[3, 4]
@[1, 2]@[3, 4]
'''
"""

# https://github.com/nim-lang/Nim/issues/5962

type
  ArrayLike[A, B] = (A, B)
  VectorLike*[SIZE, T] = ArrayLike[SIZE, T]
  MatrixLike*[M, N, T] = VectorLike[M, VectorLike[N, T]]

proc tupleTest =
  let m: MatrixLike[int, string, float] = (10, ("test", 1.2))
  echo m

tupleTest()

type
  Vector*[K: static[int], T] =
    array[K, T]

  Matrix*[M: static[int]; N: static[int]; T] =
    Vector[M, Vector[N, T]]

proc arrayTest =
  # every kind of square matrix works just fine
  let mat_good: Matrix[3, 3, float] = [[0.0, 2.0, 3.0],
                                       [2.0, 0.0, 5.0],
                                       [2.0, 0.0, 5.0]]
  echo "3x3 Matrix ", repr(mat_good)

  # this does not work with explicit type signature (the matrix seems to always think it is NxN instead)
  let mat_fail: Matrix[2, 3, float] = [[0.0, 2.0, 3.0],
                                       [2.0, 0.0, 5.0]]
  echo "2x3 Matrix ", repr(mat_fail)

  # this literal seems to work just fine
  let mat_also_good = [[0.0, 2.0, 3.0],
                       [2.0, 0.0, 5.0]]

  echo "2x3 Literal ", repr(mat_also_good)

  # but making a named type out of this leads to pretty nasty runtime behavior
  var mat_fail_runtime: Matrix[2, 3, float]
  echo "2x3 Matrix ", repr(mat_fail_runtime)

  # cutting out the matrix type middle man seems to solve our problem
  var mat_ok_runtime: array[2, array[3, float]]
  echo "2x2 ArrayArray", repr(mat_ok_runtime)

  # this is fine too
  var mat_ok_runtime_2: array[2, Vector[3, float]]
  echo "2x3 ArrayVector", repr(mat_ok_runtime_2)

  # here we are in trouble again
  var mat_fail_runtime_2: Vector[2, Vector[3, float]]
  echo "2x3 VectorVector ", repr(mat_fail_runtime_2)

  # and here we are fine again
  var mat_ok_runtime_3: Vector[2, array[3, float]]
  echo "2x3 VectorArray ", repr(mat_ok_runtime_3)

arrayTest()

# https://github.com/nim-lang/Nim/issues/5756

type
  Vec*[N : static[int]] = object
    arr*: array[N, int32]

  Mat*[M,N: static[int]] = object
    arr*: array[M, Vec[N]]

proc vec2*(x,y:int32) : Vec[2] =
  result.arr = [x,y]

proc mat2*(a,b: Vec[2]): Mat[2,2] =
  result.arr = [a,b]

const a = vec2(1,2)
echo @(a.arr)
let x = a
echo @(x.arr)

const b = mat2(vec2(1, 2), vec2(3, 4))
echo @(b.arr[0].arr), @(b.arr[1].arr)
let y = b
echo @(y.arr[0].arr), @(y.arr[1].arr)

