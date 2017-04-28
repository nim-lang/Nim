type
  BaseObj = object of RootObj
  DerivedObj = object of BaseObj

  Container[T] = object

proc doSomething(c: Container[BaseObj or DerivedObj]) = discard

var t: Container[DerivedObj]
doSomething t

