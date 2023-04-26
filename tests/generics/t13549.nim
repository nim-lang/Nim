
proc foo[T](x: T):int = 1

proc foo[T: tuple](x: T):int = 2

doAssert foo((1, 2, 3)) == 2

type Obj = object
proc foo(x: object):int = 3
doAssert foo(Obj()) == 3
