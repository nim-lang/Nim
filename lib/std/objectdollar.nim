import std/private/miscdollars

proc `$`*[T: object](x: T): string =
  ## Generic `$` operator for objects with similar output to
  ## `$` for named tuples.
  runnableExamples:
    type Foo = object
      a, b: int
    assert $(a: 23, b: 45) == "(a: 23, b: 45)"
  tupleObjectDollar(result, x)
