# bug #2266

import macros

proc impl(op: static[int]) = echo "impl 1 called"
proc impl(op: static[int], init: int) = echo "impl 2 called"

macro wrapper2: stmt = newCall(bindSym"impl", newLit(0), newLit(0))

wrapper2() # Code generation for this fails.
