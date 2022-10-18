discard """
  targets: "cpp"
  matrix: "--gc:orc"
"""

import std/options

# bug #18410
type
  O = object of RootObj
   val: pointer

proc p(): Option[O] = none(O)

doAssert $p() == "none(O)"

# bug #17351
type
  Foo = object of RootObj
  Foo2 = object of Foo
  Bar = object
    x: Foo2

var b = Bar()
discard b
