discard """
  errormsg: "cannot instantiate: 'A[T]'; the object's generic parameters cannot be inferred and must be explicitly given"
"""
type A[T] = object
var a = A()