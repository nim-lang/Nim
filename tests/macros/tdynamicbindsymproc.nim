discard """
  nimout: '''initApple
deinitApple
Coral
enum
  redCoral, blackCoral
proc (x: int; y: float): int'''
"""

# mirrored with tbindsym.nim 

import macros

# issue 7827, bindSym power up
type
  Apple = ref object
    name: string
    color: int
    weight: int

proc initApple(name: string): Apple =
  discard

proc deinitApple(x: Apple) =
  discard

static:
  doAssert not (compiles do:
    macro wrapObject(obj: typed, n: varargs[untyped]): untyped =
      let m = n[0]
      for x in m:
        var z = dynamicBindSym x
        echo z.repr)

{.experimental: "dynamicBindSymProc".}

macro wrapObject(obj: typed, n: varargs[untyped]): untyped =
  let m = n[0]
  for x in m:
    var z = dynamicBindSym x
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

block: # #11496
  proc foo(x: int; y: float): int = x

  macro macroA(call: untyped): untyped =
    let
      name = call.findChild(it.kind == nnkIdent).strVal
      inst = name.dynamicBindSym().getTypeInst()
    echo inst.repr

  #macro macroB(call: untyped): untyped =
  #  let inst = call.findChild(it.kind == nnkIdent).strVal.#,dynamicBindSym().getTypeInst()
  #  echo inst.repr

  macroA(foo(2, 2'f))
  #macroB(foo(2, 2'f))
