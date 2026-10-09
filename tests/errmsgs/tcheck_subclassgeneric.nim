discard """
  cmd: "nim check $file"
  action: "reject"
  errormsg: "cannot instantiate: 'GenericParentType[T]'; Maybe generic arguments are missing?"
"""

# `nim check` used to crash on this after the first error
type
  GenericParentType[T] = ref object of RootObj
  GenericChildType[T] = ref object of GenericParentType # missing the [T]
    val: T

var instance : GenericChildType[int] = nil
