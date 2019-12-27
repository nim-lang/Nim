discard """
  nimout: '''initApple
deinitApple
Coral
enum
  redCoral, blackCoral'''
  output: '''TFoo
TBar'''
"""

# bug #1319

import macros

type
  TTextKind = enum
    TFoo, TBar

macro test: untyped =
  var x = @[TFoo, TBar]
  result = newStmtList()
  for i in x:
    result.add newCall(newIdentNode("echo"),
      case i
      of TFoo:
        bindSym("TFoo")
      of TBar:
        bindSym("TBar"))

test()

# issue 7827, bindSym power up
{.experimental: "dynamicBindSym".}
type
  Apple = ref object
    name: string
    color: int
    weight: int

proc initApple(name: string): Apple =
  discard

proc deinitApple(x: Apple) =
  discard

macro wrapObject(obj: typed, n: varargs[untyped]): untyped =
  let m = n[0]
  for x in m:
    var z = bindSym x
    echo z.repr

wrapObject(Apple):
  initApple
  deinitApple

type
  Coral = enum
    redCoral
    blackCoral

macro mixer(): untyped =
  let m = "Co" & "ral"
  let x = bindSym(m)
  echo x.repr
  echo getType(x).repr

mixer()
