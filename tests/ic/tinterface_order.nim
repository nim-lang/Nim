discard """
  description: "Ordered interfaces preserve public, private, and re-exported overloads"
"""

#? metamorphic

#!FILE definitions.nim
import std/macros

macro declareOverloads(): untyped =
  result = newStmtList()
  for i in 0 ..< 64:
    result.add parseStmt("type Tag" & $i & "* = distinct int")
    result.add parseStmt("proc select*(x: Tag" & $i & "): int = " & $i)
    result.add parseStmt("proc secret(x: Tag" & $i & "): int = " & $i)

declareOverloads()

#!FILE reexports.nim
import definitions as renamed
import definitions as second
export renamed, second

#!FILE main.nim
import std/macros
import definitions {.all.}
import reexports

macro order(symbols: typed): untyped =
  var names = ""
  doAssert symbols.len == 64
  for candidate in symbols:
    names.add candidate.getImpl.params[1][^2].repr & " "
  result = newLit(names)

echo order(bindSym("select", brForceOpen))
echo order(bindSym("secret", brForceOpen))
doAssert reexports.renamed.select(Tag12(0)) == 12
doAssert reexports.second.select(Tag13(0)) == 13

# The first warm build records newly discovered compile-time body dependencies.
#!STEP
#!STEP
#!STEP noop

#!FILE reexports.nim
import definitions as renamed
import definitions as second
export renamed, second
proc another*(): int = 42

#!STEP
