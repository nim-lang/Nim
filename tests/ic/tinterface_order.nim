discard """
  description: "Ordered interfaces preserve public, private, and re-exported overloads"
"""

#? metamorphic

#!FILE overloads.nim
import std/macros

macro declareOverloads*(count: static[int]; backwards: static[bool]): untyped =
  result = newStmtList()
  for index in 0 ..< count:
    let i = if backwards: count - index - 1 else: index
    result.add parseStmt("type Tag" & $i & "* = distinct int")
    result.add parseStmt("proc select*(x: Tag" & $i & "): int = " & $i)
    result.add parseStmt("proc secret(x: Tag" & $i & "): int = " & $i)

#!FILE definitions.nim
import overloads
declareOverloads(64, false)

#!FILE reexports.nim
import definitions as renamed
import definitions as second
export renamed, second

#!FILE chain.nim
import reexports
export reexports

#!FILE inspectorder.nim
import std/macros

macro order*(symbols: typed): untyped =
  var names = ""
  doAssert symbols.len in [33, 64, 65]
  for candidate in symbols:
    names.add candidate.getImpl.params[1][^2].repr & " "
  result = newLit(names)

#!FILE hiddenconsumer.nim
import std/macros
import definitions {.all.}
import inspectorder
echo order(bindSym("secret", brForceOpen))

#!FILE main.nim
import std/macros
import chain
import inspectorder
import hiddenconsumer

# Public lookup is reached solely through the re-exported interface.
echo order(bindSym("select", brForceOpen))
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

# Reorder the definitions without changing membership, then grow and shrink it.
#!FILE definitions.nim
import overloads
declareOverloads(64, true)

#!STEP

#!FILE definitions.nim
import overloads
declareOverloads(65, true)

#!STEP

#!FILE definitions.nim
import overloads
declareOverloads(33, false)

#!STEP

# Export/except follows the same ordered traversal, including through a chain.
#!FILE reexports.nim
import definitions as renamed
import definitions as second
export renamed except Tag0
export second except Tag0
proc another*(): int = 42

#!STEP
