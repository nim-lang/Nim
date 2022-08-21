discard """
  output: '''true
OK'''
  cmd: "nim c --gc:arc $file"
"""

# bug #12826

type
  MyObject1* = object of RootObj
    z*: string

  MyObject2* = object of RootObj
    x*: float
    name*: string
    subobj: MyObject1
    case flag*: bool
    of false:
      more: array[3, MyObject1]
    of true: y*: float

var x = new(MyObject2)
doAssert x of MyObject2
doAssert x.subobj of MyObject1
doAssert x.more[2] of MyObject1
doAssert x.more[2] of RootObj

var y: MyObject2
doAssert y of MyObject2
doAssert y.subobj of MyObject1
doAssert y.more[2] of MyObject1
doAssert y.more[2] of RootObj

echo "true"

# bug #12978
type
  Vector2* = object of RootObj
    x*, y*: float

type
  Vertex* = ref object
    point*: Vector2

proc newVertex*(p: Vector2): Vertex =
  return Vertex(point: p)

proc createVertex*(p: Vector2): Vertex =
  result = newVertex(p)

proc p =
  var x = Vector2(x: 1, y: 2)
  let other = createVertex(x)
  echo "OK"

p()
