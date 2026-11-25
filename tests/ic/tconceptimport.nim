discard """
output: '''ok
var'''
"""

# Concept requirements live in the concept type's NIF body. Keep their AST
# structure when loading the concept in another module so concept matching can
# see and compare those requirements.
import mconceptsize

static:
  doAssert uint8 is Sized

echo "ok"

# bug #26740: ranking `f(t: C)` against `f(t: var C)` binds the concept's
# candidate slot to the concept itself; `typeKey` then recursed endlessly.
type C = concept type T
  sizeof(T)

proc f(t: C) = echo "plain"
proc f(t: var C) = echo "var"

var a = 1
f(a)
