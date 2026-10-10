discard """
  errormsg: "type mismatch"
"""

# issue #16726
# the code below should give a clean CT error, not an internal error
import std/jsffi
let a = toJs(3)
let b = a.toJs(int)
