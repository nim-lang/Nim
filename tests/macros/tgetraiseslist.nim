discard """
  nimout: '''##[ValueError, Gen[string]]##
%%[RootEffect]%%
true true'''
"""

import macros
import std / effecttraits

type
  Gen[T] = object of CatchableError
    x: T

macro m(call: typed): untyped =
  echo "##", repr getRaisesList(call[0]), "##"
  echo "%%", repr getTagsList(call[0]), "%%"
  echo isGcSafe(call[0]), " ", hasNoSideEffects(call[0])
  result = call

proc gutenTag() {.tags: RootEffect.} = discard

proc r(inp: int) =
  if inp == 0:
    raise newException(ValueError, "bah")
  elif inp == 1:
    raise newException(Gen[string], "bahB")
  gutenTag()

m r(2)
