
type
  Foo* = object
    fooa, foob: int

proc createFoo*(a, b: int): Foo = Foo(fooa: a, foob: b)

template geta*(f: Foo): untyped = f.fooa
