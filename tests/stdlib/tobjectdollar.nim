discard """
  matrix: "-d:nimPreviewSlimSystem"
"""

import std/assertions

type Foo = object
  a, b: int

let x = Foo(a: 23, b: 45)
doAssert not compiles($x)
import std/objectdollar
doAssert compiles($x)
doAssert $x == "(a: 23, b: 45)"
