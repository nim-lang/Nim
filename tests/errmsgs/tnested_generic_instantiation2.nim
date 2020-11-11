discard """
action: compile
"""

#[
bug #4766
see also: tnested_generic_instantiation.nim
]#

proc toString*[T](x: T) =
  for name, value in fieldPairs(x):
    when compiles(toString(value)):
      discard
    toString(value)

type
  Plain = ref object
    discard

  Wrapped[T] = object
    value: T

converter toWrapped[T](value: T): Wrapped[T] =
  Wrapped[T](value: value)

let result = Plain()
toString(result)
