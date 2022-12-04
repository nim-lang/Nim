discard """
  action: compile
"""

import std/macros

macro matchMe(x: typed): untyped =
  discard x.getTypeImpl

type
  ElementRT = object
  Element[Z] = ElementRT # this version is needed, even though we don't use it

let ar = ElementRT()
matchMe(ar)
