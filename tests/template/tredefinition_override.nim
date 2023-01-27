{.push warningAsError[ImplicitTemplateRedefinition]: on.}

doAssert not (compiles do:
  template foo(): int = 1
  template foo(): int = 2)
doAssert (compiles do:
  template foo(): int = 1
  template foo(): int {.redefine.} = 2)
doAssert not (compiles do:
  block:
    template foo() =
      template bar: string {.gensym.} = "a"
      template bar: string {.gensym.} = "b"
    foo())
doAssert (compiles do:
  block:
    template foo() =
      template bar: string {.gensym.} = "a"
      template bar: string {.gensym, redefine.} = "b"
    foo())

block:
  template foo(): int = 1
  template foo(): int {.redefine.} = 2
  doAssert foo() == 2
block:
  template foo(): string =
    template bar: string {.gensym.} = "a"
    template bar: string {.gensym, redefine.} = "b"
    bar()
  doAssert foo() == "b"

{.pop.}
