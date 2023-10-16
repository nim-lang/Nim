## This module implements a generic `$` operator to convert objects to strings.

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
