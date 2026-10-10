discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
tsumtype_shared_after: OK
'''
"""

# ported from Nimony's tests/nimony/object/tsumtype_shared_after.nim


## Shared fields may appear after the sum-type `case` section (not only before).

type
  Thing = object
    case
    of Circle:
      radius: float
    of Rect:
      w, h: float
    tag: int
    lbl: string

let c: Thing = Circle(radius: 2.5, tag: 42, lbl: "c")
{.cast(uncheckedAccess).}:
  assert c.radius == 2.5
assert c.tag == 42
assert c.lbl == "c"

let r: Thing = Rect(w: 3.0, h: 4.0, tag: 0, lbl: "r")
{.cast(uncheckedAccess).}:
  assert r.w == 3.0
  assert r.h == 4.0
assert r.tag == 0
assert r.lbl == "r"

proc describe(t: Thing): string =
  case t
  of Circle(radius):
    result = "circle"
  of Rect(w, h):
    result = "rect"

assert describe(c) == "circle"
assert describe(r) == "rect"
{.cast(uncheckedAccess).}:
  assert c.radius == 2.5
  assert r.w == 3.0

echo "tsumtype_shared_after: OK"
