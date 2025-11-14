# Test case: Circular dependency detection
# WHY IT MATTERS: Circular dependencies are one of the most confusing
# compilation errors for developers. The new error messages will:
# 1. Clearly explain the circular chain
# 2. Show the exact import path
# 3. Suggest concrete solutions

import circular_b

type
  ModuleA* = object
    name*: string
    bRef*: ModuleB  # This creates a circular dependency

proc createA*(): ModuleA =
  result.name = "A"
  result.bRef = createB()  # Calls into circular_b
