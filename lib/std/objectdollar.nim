when defined(nimHasSlimSystemWarnings):
  {.slimSystemModule.}

import std/private/miscdollars

proc `$`*[T: object](x: T): string =
  ## Generic `$` operator for objects with similar output to
  ## `$` for named tuples.
  runnableExamples:
    type Foo = object
      a, b: int
    let x = Foo(a: 23, b: 45)
    assert $x == "(a: 23, b: 45)"
  tupleObjectDollar(result, x)
