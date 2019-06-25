type
  MyType = object

proc `=`(a: var MyType, b: MyType) =
  quit 0

var p,q: MyType

q = p

quit 1
