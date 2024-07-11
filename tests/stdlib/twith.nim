discard """
  matrix: "--mm:refc; --mm:orc"
"""

import std/with
import std/[assertions, formatfloat]

type
  Foo = object
    col, pos: string
    name: string

proc setColor(f: var Foo; r, g, b: int) = f.col = $(r, g, b)
proc setPosition(f: var Foo; x, y: float) = f.pos = $(x, y)

var f: Foo
with(f, setColor(2, 3, 4), setPosition(0.0, 1.0))
doAssert f.col == "(2, 3, 4)"
doAssert f.pos == "(0.0, 1.0)"

f = Foo()
with f:
  col = $(2, 3, 4)
  pos = $(0.0, 1.0)
  _.name = "bar"
doAssert f.col == "(2, 3, 4)"
doAssert f.pos == "(0.0, 1.0)"
doAssert f.name == "bar"

type
  Baz* = object
    a*, b*: int
  Bar* = object
    x*: int
    baz*: Baz

var bar: Bar
with bar:
  x = 1
  with baz:
    a = 2

doAssert bar.x == 1
doAssert bar.baz.a == 2
