discard """
  errormsg: "cannot instantiate 'GenericParentType' inside of type defintion : 'GenericChildType'"
  line: 8
"""

type
  GenericParentType[T] = ref object of RootObj
  GenericChildType[T] = ref object of GenericParentType # missing the [T]
    val: T

var instance : GenericChildType[int] = nil
