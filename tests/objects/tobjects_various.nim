discard """
  output: '''
34
b
wohoo
baz
'''
"""


block tobject2:
  # Tests the object implementation
  type
    TPoint2d {.inheritable.} = object
      x, y: int
    TPoint3d = object of TPoint2d
      z: int # added a field

  proc getPoint( p: var TPoint2d) =
    {.breakpoint.}
    writeLine(stdout, p.x)

  var p: TPoint3d

  TPoint2d(p).x = 34
  p.y = 98
  p.z = 343

  getPoint(p)



block tofopr:
  type
    TMyType = object {.inheritable.}
      len: int
      data: string

    TOtherType = object of TMyType

  proc p(x: TMyType): bool =
    return x of TOtherType

  var
    m: TMyType
    n: TOtherType

  doAssert p(m) == false
  doAssert p(n)



block toop:
  type
    TA = object of RootObj
      x, y: int
    TB = object of TA
      z: int
    TC = object of TB
      whatever: string

  proc p(a: var TA) = echo "a"
  proc p(b: var TB) = echo "b"

  var c: TC
  p(c)



block tfefobjsyntax:
  type
    Foo = object
      a, b: int
      s: string
    FooBar = object of RootObj
      n, m: string
    Baz = object of FooBar

  proc invoke(a: ref Baz) =
    echo "baz"

  # check object construction:
  let x = (ref Foo)(a: 0, b: 45, s: "wohoo")
  echo x.s

  var y: ref FooBar = (ref Baz)(n: "n", m: "m")
  invoke((ref Baz)(y))
