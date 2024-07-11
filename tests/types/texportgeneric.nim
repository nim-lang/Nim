discard """
  errormsg: "{.exportc.} not allowed for generic types"
  line: 6
"""

type Struct[T] {.exportc.} = object
  a:int
  b: T