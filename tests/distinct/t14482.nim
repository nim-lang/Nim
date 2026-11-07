discard """
  targets: "c cpp"
  output: '''
@[0, 2, 3]
2
'''
"""

# bug #14482: a conversion to a `var T` alias converts to `T`
type
  Bytes = seq[byte]
  RedBytes = distinct Bytes
  GreenBytes[T] = distinct Bytes

proc worksWithGreenBytes[T](data: var GreenBytes[T]) =
  Bytes(data)[0] = byte(0)

proc worksWithRedBytes(data: var RedBytes) =
  type GreenBytesVar = var GreenBytes[int]
  worksWithGreenBytes GreenBytesVar(data)

var x = RedBytes @[1.byte, 2, 3]
worksWithRedBytes x
echo Bytes(x)

type Foo = distinct int
var y = Foo(1)
type IntVar = var int
IntVar(y) += 1
echo int(y)
