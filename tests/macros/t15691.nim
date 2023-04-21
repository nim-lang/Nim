discard """
  action: compile
"""

import std/macros

macro simplifiedExpandMacros(body: typed): untyped =
  result = body

simplifiedExpandMacros:
  proc testProc() = discard

simplifiedExpandMacros:
  template testTemplate(): untyped = discard

# Error: illformed AST: macro testMacro(): untyped =
simplifiedExpandMacros:
  macro testMacro(): untyped = discard

# Error: illformed AST: converter testConverter(x: int): float =
simplifiedExpandMacros:
  converter testConverter(x: int): float = discard
