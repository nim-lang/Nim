discard """
  output: '''m[0][0] = 1.0
m[0][0] = 2.0'''
"""
# bug #4653
type
  Vector = ref array[2, float64]
  Matrix = ref array[2, Vector]

proc newVector(): Vector =
  new(result)

proc newMatrix(): Matrix =
  new(result)
  for ix in 0 .. 1:
    result[ix] = newVector()

let m = newMatrix()

m[0][0] = 1.0
echo "m[0][0] = ", m[0][0]

GC_fullCollect()

m[0][0] = 2.0
echo "m[0][0] = ", m[0][0]
