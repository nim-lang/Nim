# Part 2 of circular dependency test
# This module imports circular_a, creating the cycle

import circular_a  # This creates A -> B -> A cycle

type
  ModuleB* = object
    name*: string
    aRef*: ModuleA  # References ModuleA, which references ModuleB

proc createB*(): ModuleB =
  result.name = "B"
  result.aRef = createA()  # Calls back into circular_a

# EXPECTED IMPROVED ERROR:
# Error:[E0017]: undeclared identifier: 'ModuleA'
#
# This identifier is unavailable due to a circular module dependency
#
# note: circular import chain detected:
#   circular_a.nim imports circular_b.nim
#   circular_b.nim imports circular_a.nim
#
# help: break the circular dependency by:
#   - moving shared types to a separate module
#   - using forward declarations
#   - restructuring the module hierarchy
#
# Example solution:
#   Create circular_types.nim with shared type definitions
#   Have both circular_a and circular_b import circular_types
