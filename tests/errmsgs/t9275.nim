discard """
  errormsg: "an 'UncheckedArray' field must be the last field of an object"
  line: 17
"""

# bug #9275: an `UncheckedArray` field must be in tail position
type
  Foo = object
    x: UncheckedArray[byte]
  D = enum
    A, B
  Bar = object
    case k: D
    of A: x: UncheckedArray[byte]
    of B: discard
  Baz = object
    x: UncheckedArray[char]
    y: int
  Imported {.importc: "struct imported", nodecl.} = object
    x: UncheckedArray[char]
    y: int
