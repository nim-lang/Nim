discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
tsumtype_shared: OK
'''
"""

# ported from Nimony's tests/nimony/object/tsumtype_shared.nim


type
  Shape = object
    x, y: float
    color: int
    case
    of Circle:
      radius: float
    of Rectangle:
      width, height: float
    of Triangle:
      x2, y2, x3, y3: float

let c: Shape = Circle(x: 1.0, y: 2.0, color: 0xFF0000, radius: 5.0)
assert c.x == 1.0
assert c.y == 2.0
assert c.color == 0xFF0000
{.cast(uncheckedAccess).}:
  assert c.radius == 5.0

let r: Shape = Rectangle(x: 0.0, y: 0.0, color: 0x00FF00, width: 10.0, height: 20.0)
assert r.x == 0.0
{.cast(uncheckedAccess).}:
  assert r.width == 10.0
  assert r.height == 20.0

let t: Shape = Triangle(x: 0.0, y: 0.0, color: 0x0000FF, x2: 3.0, y2: 0.0, x3: 0.0, y3: 4.0)
assert t.color == 0x0000FF
{.cast(uncheckedAccess).}:
  assert t.x2 == 3.0
  assert t.y3 == 4.0

proc area(s: Shape): float =
  case s
  of Circle(radius):
    result = 3.14159 * radius * radius
  of Rectangle(width, height):
    result = width * height
  of Triangle(x2, y2, x3, y3):
    let ax = s.x
    let ay = s.y
    result = 0.5 * ((x2 - ax) * (y3 - ay) - (x3 - ax) * (y2 - ay))
    if result < 0.0: result = -result

assert area(r) == 200.0

proc kindName(s: Shape): string =
  case s
  of Circle(radius):
    result = "circle"
  of Rectangle(width, height):
    result = "rect"
  of Triangle(x2, y2, x3, y3):
    result = "triangle"

assert kindName(c) == "circle"
assert kindName(r) == "rect"
assert kindName(t) == "triangle"

assert c.x == 1.0
assert r.color == 0x00FF00

echo "tsumtype_shared: OK"
