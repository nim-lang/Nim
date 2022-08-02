discard """
  nimout: '''initApple
deinitApple
Coral
enum
  redCoral, blackCoral
proc (x: int; y: float): int
proc (x: int; y: float): int'''
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
  let x = dynamicBindSym(m)
  echo x.repr
  echo getType(x).repr

mixer()

# #11496
proc foo(x: int; y: float): int = x

macro macroA(call: untyped): untyped =
  let
    name = call.findChild(it.kind == nnkIdent).strVal
    inst = name.dynamicBindSym().getTypeInst()
  echo inst.repr

macro macroB(call: untyped): untyped =
  let inst = call.findChild(it.kind == nnkIdent).strVal.dynamicBindSym().getTypeInst()
  echo inst.repr

macroA(foo(2, 2'f))
macroB(foo(2, 2'f))
