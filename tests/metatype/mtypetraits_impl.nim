{.used.}

import std/typetraits
import mtypetraits_types
import ttypetraits

proc callbackFun(a: pointer, id: TypeId): string {.exportc.} =
  case id
  of getTypeid(Foo1): $("custom1", cast[Foo1](a))
  of getTypeid(Foo2): $("custom2", cast[Foo2](a))
  of getTypeid(Foo3): $("custom3", cast[Foo3](a))
  else:
    doAssert false, $id
    ""
