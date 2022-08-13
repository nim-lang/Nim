doAssert not (compiles do:
  template foo(): int = 1
  template foo(): int = 2)
doAssert (compiles do:
  template foo(): int = 1
  template foo(): int {.override.} = 2)
template foo(): int = 1
template foo(): int {.override.} = 2
doAssert foo() == 2
