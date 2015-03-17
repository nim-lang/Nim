import  macros

from uri import `/`

macro test*(a: stmt): stmt {.immediate.} =
  var nodes: tuple[a, b: int]
  nodes.a = 4
  nodes[1] = 45

  type
    TTypeEx = object
      x, y: int
      case b: bool
      of false: nil
      of true: z: float

  var t: TTypeEx
  t.b = true
  t.z = 4.5

test:
  "hi"

