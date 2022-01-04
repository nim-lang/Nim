discard """
  output: '''11
22
33
3
2
3
3
15
(oa: [1, 3, 4])'''
  targets: "c cpp"
"""

{.experimental: "views".}

proc take(a: openArray[int]) =
  echo a.len

proc main(s: seq[int]) =
  var x: openArray[int] = s
  for i in 0 .. high(x):
    echo x[i]
  take(x)

  take(x.toOpenArray(0, 1))
  let y = x
  take y
  take x

main(@[11, 22, 33])

var x: int

proc foo(x: var int): var int =
  once: x = 42
  return x

var y: var int = foo(x)
y = 15
echo foo(x)
# bug #16132

# bug #18690

type
  F = object
    oa: openArray[int]

let s1 = @[1,3,4,5,6]
var test = F(oa: toOpenArray(s1, 0, 2))
echo test

type
  Foo = object
    x: string
    y: seq[int]
    data: array[10000, byte]

  View[T] = object
    x: lent T

proc mainB =
  let f = Foo(y: @[1, 2, 3])
  let foo = View[Foo](x: f)
  assert foo.x.x == ""
  assert foo.x.y == @[1, 2, 3]

mainB()
