type
  Box* = object
    secret: int

proc newBox*(x: int): Box = Box(secret: x)

template genReader*(name: untyped) =
  proc name(b: Box): int = b.secret + later()
