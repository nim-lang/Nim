import macros

# Ensure that `isNil` works in the typed macro context when pass procs.

type
  O = object
    fn: proc(i: int): int

var o: O

macro typedBug(expr: typed) =
  doAssert expr[1] != nil
  doAssert not expr[1].isNil

typedBug(o.fn)