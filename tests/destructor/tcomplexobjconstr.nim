discard """
  output: "true"
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
assert x of MyObject2
assert x.subobj of MyObject1
assert x.more[2] of MyObject1
assert x.more[2] of RootObj

var y: MyObject2
assert y of MyObject2
assert y.subobj of MyObject1
assert y.more[2] of MyObject1
assert y.more[2] of RootObj

echo "true"
