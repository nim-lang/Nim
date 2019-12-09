discard """
action: compile
"""

# bug #4766

type
  Plain = ref object
    discard

  Wrapped[T] = object
    value: T

converter toWrapped[T](value: T): Wrapped[T] =
  Wrapped[T](value: value)

let result = Plain()
discard $result

proc foo[T2](a: Wrapped[T2]) =
  # Error: generic instantiation too nested
  discard $a

foo(result)
