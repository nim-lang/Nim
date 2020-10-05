discard """
  nimout: '''##[ValueError, Gen[string]]##'''
"""

import macros
import std / effecttraits

type
  Gen[T] = object of CatchableError
    x: T

macro m(call: typed): untyped =
  echo "##", repr getRaisesList(call), "##"
  result = call

proc r(inp: int) =
  if inp == 0:
    raise newException(ValueError, "bah")
  elif inp == 1:
    raise newException(Gen[string], "bahB")

m r(2)
