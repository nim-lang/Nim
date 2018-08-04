type
  Base[T] = ref object {.inheritable.}
    value*: T

  Derived[T] = ref object of Base[T]
    derivedValue*: T

proc makeDerived*[T](v: T): Derived[T] =
  new result
  result.value = v

proc setBaseValue*[T](a: Base[T], value: T) =
  a.value = value

