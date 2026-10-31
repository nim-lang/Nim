discard """
  action: "run"
"""

# A generic alias bound where all of the concept's procs are visible must
# stay usable from a module that only imports the alias. The use site must
# not have to import the module that provides the concept's fallback procs.

import concept_alias_scope_index

proc ident[T](x: T): T = x

discard ident(MyAlias())

# Already concrete types in generic signatures need no new constraint lookup.
proc concrete[T](x: T, y: MyAlias): MyAlias = y
discard concrete(1, MyAlias())

# Wrappers around an inferred type preserve its original validation as well.
proc wrapped[T](x: seq[T]): seq[T] = x
discard wrapped(@[MyAlias()])
proc byVar[T](x: var T) = discard
var value = MyAlias()
byVar(value)

# Void erasure must not change which original parameter is inspected.
proc afterVoid[A, B](a: A, b: B): B = b
discard afterVoid[void, MyAlias](MyAlias())

# A new type application still needs its concept implementations in scope.
proc makeIndex[K](): MyIndex[K] = discard
doAssert not compiles(makeIndex[int]())

# An unconstrained alias must not bypass that lookup for a new application.
type IndirectIndex[K] = MyIndex[K]
proc makeIndirectIndex[K](): IndirectIndex[K] = discard
doAssert not compiles(makeIndirectIndex[int]())
