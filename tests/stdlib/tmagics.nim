import std/magics
import macros

proc t1(): string =
  result = getProcname()

doAssert t1() == "t1"

proc yui(): bool =
  when getProcname() == "yui":
    result = true

doAssert yui()

proc `hello nim`(): string =
  result = getProcname()

doAssert `hello nim`() == "hellonim"

proc `hello+nim`(): string =
  result = getProcname()

doAssert `hello+nim`() == "hello+nim"

proc initName(): string =
  result = getProcname()

doAssert initName() == "initName"

func t2(): string =
  result = getProcname()

doAssert t2() == "t2"

macro t3(): string =
  let name = getProcname()
  result = quote do:
    `name`

doAssert t3() == "t3"

proc hello[T](x: T): string =
  result = getProcname()

doAssert hello(123) == "hello"
