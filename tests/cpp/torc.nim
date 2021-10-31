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