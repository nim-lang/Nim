discard """
  errormsg: "a 'var ref' parameter cannot be refined to a subtype"
"""

# bug #14465
type Op = ref object of RootObj
type TApply = ref object of Op
type Shift = ref object of TApply

method foo(op: var Op) {.base.} = discard
method foo(op: var TApply) =
  var parent1=op.Op
  parent1.foo
method foo(op: var Shift) =
  var parent2=op.TApply
  parent2.foo
