discard """
  errormsg: "cannot instantiate: 'newImage[string]'"
  line: 16
"""

# bug #4084
type
  Image[T] = object
    data: seq[T]

proc newImage[T: int32|int64](w, h: int): ref Image[T] =
  new(result)
  result.data = newSeq[T](w * h)

var correct = newImage[int32](320, 200)
var wrong = newImage[string](320, 200)
