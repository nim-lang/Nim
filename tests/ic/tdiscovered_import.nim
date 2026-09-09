discard """
  description: '''IC: a macro-generated import stays in the graph across runs'''
"""

#? metamorphic

# The static scanner cannot see `parseStmt("import dyn")`. The discovery
# fixpoint recovers it — but only ran AFTER a failure, and the graph is
# re-derived statically on every run, so on a warm build the discovered module
# had no nifler/`nim m` rule at all: editing it changed nothing, forever.

#!FILE dyn.nim
proc hidden*(): string = "first"

#!FILE gen.nim
import std/macros

macro generatedImport(): untyped =
  parseStmt("import dyn")

generatedImport()

proc reveal*(): string = hidden()

#!FILE main.nim
import gen
echo reveal()
#!STEP expect: first

# the warm build must see this edit
#!FILE dyn.nim
proc hidden*(): string = "second"
#!STEP expect: second

# and again, to prove it is not a one-shot recovery
#!FILE dyn.nim
proc hidden*(): string = "third"
#!STEP expect: third
