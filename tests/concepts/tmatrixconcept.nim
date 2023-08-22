discard """
output: "0\n0\n0"
nimout: '''
R=3 C=3 TE=9 FF=14 FC=20 T=int
R=3 C=3 T=int
'''
"""

import typetraits

template ok(x) = assert x
template no(x) = assert(not x)

const C = 10

type
  Matrix[Rows, Cols, TotalElements, FromFoo, FromConst: static[int]; T] = concept m, var mvar, type M
    M.M == Rows
    Cols == M.N
    M.T is T

    m[int, int] is T
    mvar[int, int] = T

    FromConst == C * 2

    # more complicated static param inference cases
    m.data is array[TotalElements, T]
    m.foo(array[0..FromFoo, type m[int, 10]])

  MyMatrix[M, K: static[int]; T] = object
    data: array[M*K, T]

# adaptor for the concept's non-matching expectations
template N(M: type MyMatrix): untyped = M.K

proc `[]`(m: MyMatrix; r, c: int): m.T =
  m.data[r * m.K + c]

proc `[]=`(m: var MyMatrix; r, c: int, v: m.T) =
  m.data[r * m.K + c] = v

proc foo(x: MyMatrix, arr: array[15, x.T]) = discard

proc genericMatrixProc[R, C, TE, FF, FC, T](m: Matrix[R, C, TE, FF, FC, T]): T =
  static:
    echo "R=", R, " C=", C, " TE=", TE, " FF=", FF, " FC=", FC, " T=", T.name

  m[0, 0]

proc implicitMatrixProc(m: Matrix): m.T =
  static:
    echo "R=", m.Rows,
        " C=", m.Cols,
        # XXX: fix these
        #" TE=", m.TotalElements,
        #" FF=", m.FromFoo,
        #" FC=", m.FromConst,
        " T=", m.T.name

  m[0, 0]

proc myMatrixProc(x: MyMatrix): MyMatrix.T = genericMatrixProc(x)

var x: MyMatrix[3, 3, int]

static:
  # ok x is Matrix
  ok x is Matrix[3, 3, 9, 14, 20, int]

  no x is Matrix[3, 3, 8, 15, 20, int]
  no x is Matrix[3, 3, 9, 10, 20, int]
  no x is Matrix[3, 3, 9, 15, 21, int]
  no x is Matrix[3, 3, 9, 15, 20, float]
  no x is Matrix[4, 3, 9, 15, 20, int]
  no x is Matrix[3, 4, 9, 15, 20, int]

echo x.myMatrixProc
echo x.genericMatrixProc
echo x.implicitMatrixProc

