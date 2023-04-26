discard """
  disabled: true
"""

type
  Image[T: int32|int64] = object
    data: seq[T]

proc newImage[T](w, h: int): ref Image[T] =
  new(result)
  result.data = newSeq[T](w * h)

var i = newImage[string](320, 200)
