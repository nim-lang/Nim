# Tests the object implementation

type
  TPoint2d {.inheritable.} = object
    x, y: int

  TPoint3d = object of TPoint2d
    z: int # added a field

proc getPoint( p: var TPoint2d) =
  {.breakpoint.}
  writeln(stdout, p.x)

var
  p: TPoint3d

TPoint2d(p).x = 34
p.y = 98
p.z = 343

getPoint(p)
