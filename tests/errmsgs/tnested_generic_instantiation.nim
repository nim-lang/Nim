discard """
errormsg: "generic instantiation too nested"
file: "system.nim"
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
