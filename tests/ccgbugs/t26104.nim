discard """
  action: compile
  ccodeCheck: "@'f_.*((*Result).f)' .*"
"""

# bug #26104: a compile-time-only `typeof` argument was treated as a runtime
# alias of the result field, forcing an unnecessarily large temporary and copy.
type
  B = array[131072, byte]
  Y = object
    f: B

proc fill(_: type B): B = discard
proc make(): Y = result.f = fill(typeof(result.f))

discard make()
