discard """
  errormsg: "cannot instantiate: 'A[T]'; Maybe generic arguments are missing?"
"""
type A[T] = object
var a = A()