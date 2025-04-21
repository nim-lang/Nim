discard """
  errormsg: "illegal recursion in type 'seq[Shape[system.float32]]"
  line: 20
"""

# issue #24877

type
  ValT = float32|float64
  Square[T: ValT] = object
    inner: seq[Shape[T]]
  Circle[T: ValT] = object
    inner: seq[Shape[T]]

  InnerShapesProc[T: ValT] = proc(): seq[Shape[T]]
  Shape[T: ValT] = tuple[
    innerShapes: InnerShapesProc[T],
  ]

func newSquare[T: ValT](inner: seq[Shape[T]] = @[]): Square[T] =
  Square[T](inner: inner)

proc innerShapes[T: ValT](sq: Square[T]): seq[Shape[T]] = sq.inner
proc iInnerShapes[T: ValT](sq: Square[T]): InnerShapesProc[T] =
  proc(): seq[Shape[T]] = sq.innerShapes()

func toShape[T: ValT](sq: Square[T]): Shape[T] =
  (innerShapes: sq.iInnerShapes())

func newCircle[T: ValT](inner: seq[Shape[T]] = @[]): Circle[T] =
  Circle[T](inner: inner)

proc innerShapes[T: ValT](c: Circle[T]): seq[Shape[T]] = c.inner
proc iInnerShapes[T: ValT](c: Circle[T]): InnerShapesProc[T] =
  proc(): seq[Shape[T]] = c.innerShapes()

func toShape[T: ValT](c: Circle[T]): Shape[T] =
  (innerShapes: c.iInnerShapes())

const
  sq1 = newSquare[float32]()
  sq2 = newSquare[float32]()
  sq3 = newSquare[float64]()
  c1 = newCircle[float64](@[sq3])
  c2 = newCircle[float32](@[sq1, sq2])

let
  shapes32 = @[sq1.toShape, sq2.toShape, c2.toShape]
  shapes64 = @[sq3.toShape, c1.toShape]
