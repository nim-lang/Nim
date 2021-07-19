type Foo1* = object
  x1*: int

type Foo2* = object
  x2*: int

import std/typetraits
proc callbackFun(a: pointer, id: TypeId): string {.importc.}

proc callbackFun*[T](a: T): string = callbackFun(cast[pointer](a), getTypeid(T))
