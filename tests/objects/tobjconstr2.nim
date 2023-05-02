discard """
  output: '''42
Foo'''
"""

type TFoo{.exportc.} = object
 x:int

var s{.exportc.}: seq[TFoo] = @[]

s.add TFoo(x: 42)

echo s[0].x


# bug #563
type
  Foo {.inheritable.} =
    object
      x: int

  Bar =
    object of Foo
      y: int

var a = Bar(y: 100, x: 200) # works
var b = Bar(x: 100, y: 200) # used to fail

# bug 1275

type
  Graphic = object of RootObj
    case kind: range[0..1]
    of 0:
      radius: float
    of 1:
      size: tuple[w, h: float]

var d = Graphic(kind: 1, size: (12.9, 6.9))

# bug #1274
type
  K = enum Koo, Kar
  Graphic2 = object of RootObj
    case kind: K
    of Koo:
      radius: float
    of Kar:
      size: tuple[w, h: float]

type NamedGraphic = object of Graphic2
  name: string

var ngr = NamedGraphic(kind: Koo, radius: 6.9, name: "Foo")
echo ngr.name

GC_fullCollect()
