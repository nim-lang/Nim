discard """
  targets: "c cpp"
  matrix: "--mm:refc; --mm:arc"
"""

import base64, complex, sequtils, math, sugar

type

  FP = float
  T = object
    index: int
    arg: FP
    val: Complex[FP]
  M = object
    alpha, beta: FP

func a(s: openArray[T], model: M): seq[T] =
  let f = (tn: int) => model.alpha + FP(tn) * model.beta;
  return mapIt s:
    block:
      let s = it.val * rect(1.0, - f(it.index))
      T(index: it.index, arg: phase(s), val: s)

proc b(): float64 =
  var s = toSeq(0..10).mapIt(T(index: it, arg: 1.0, val: complex.complex(1.0)))
  discard a(s, M(alpha: 1, beta: 1))
  return 1.0

func cc(str: cstring, offset: ptr[cdouble]): cint {.exportc.} =
  offset[] = b()
  return 0

static:
  echo b()
