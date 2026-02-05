
type
  Foo[T] = object of T

template inheritanceCheck(a, b: untyped) =
  doAssert a is b
  doAssert b isnot a

inheritanceCheck Foo[RootObj], RootObj

inheritanceCheck Foo[Foo[RootObj]], RootObj
inheritanceCheck Foo[Foo[RootObj]], Foo[RootObj]

inheritanceCheck Foo[Foo[Foo[RootObj]]], RootObj
inheritanceCheck Foo[Foo[Foo[RootObj]]], Foo[RootObj]
inheritanceCheck Foo[Foo[Foo[RootObj]]], Foo[Foo[RootObj]]
