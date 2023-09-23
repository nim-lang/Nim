# foo0 has 0 overloads

template myTemplate0*(): string =
  foo0(bar)

# foo1 has 1 overload

proc foo1(arg: int): string =
  "foo1 bad"

template myTemplate1*(): string =
  foo1(bar)

# foo2 has 2 overloads

proc foo2(arg: int): string =
  "foo2 bad 1"

proc foo2(arg: string): string =
  "foo2 bad 2"

template myTemplate2*(): string =
  foo2(bar)

proc overloadToPrefer(x: int): int = x + 1

template singleOverload*: untyped =
  (overloadToPrefer(123), overloadToPrefer("abc"))
