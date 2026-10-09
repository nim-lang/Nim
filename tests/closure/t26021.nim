discard """
  action: compile
"""

# bug #26021
import std/sugar

proc foo(a: int) =
  echo "Test"

proc outer() =
  let a = 5
  proc test(p: proc() = () => foo(a)) =
    p()
