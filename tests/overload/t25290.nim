proc temp(one: int, two: int, three: int)  =
  discard

template temp(body: untyped): untyped =
  body

temp:
  proc a(tp: int) =
    discard

proc mixedTemp(x: int) =
  discard

proc mixedTemp(x: bool) =
  discard

template mixedTemp(body: untyped): untyped =
  body

# The `bool` proc should win here so `xx` survives
mixedTemp (let xx = 1; true)
discard xx

proc sinkTemp(x: int) =
  discard

template sinkTemp(body: untyped): untyped =
  discard

# Here the template should win here so `let xy` is sunk into template as AST
sinkTemp (let xy = "template"; xy)

when declared(xy):
  {.error: "xy leaked from failed proc candidate".}
