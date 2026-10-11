discard """
  output: "ok"
"""

# bug #4084: generic type constraints and instantiated signatures
type
  Image[T] = object
    data: seq[T]
  Image2[T: int32|int64] = object
    data: seq[T]

proc newImage[T: int32|int64](w, h: int): ref Image[T] =
  new(result)
  result.data = newSeq[T](w * h)

proc newImage2[T](w, h: int): ref Image2[T] =
  new(result)
  result.data = newSeq[T](w * h)

proc newImage3[T: int32|int64](w, h: int): ref Image2[T] =
  new(result)
  result.data = newSeq[T](w * h)

doAssert not compiles(newImage[string](320, 200))
doAssert not compiles(newImage2[string](320, 200))
doAssert newImage2[int64](2, 2).data.len == 4
doAssert newImage3[int32](3, 2).data.len == 6
echo "ok"
