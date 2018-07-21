discard """
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

# ------------------------------------------
# bug #7875
type
  Granula = object
    color: int
  MyType[T] = object
    sub: T

macro foobar(): untyped =
  let sym1 = bindSym("Granula")
  let sym2 = bindSym("float32")
  result = quote do:
    var mysym1: MyType[`sym1`]
    var mysym2: MyType[`sym2`]
    doAssert type(mysym1.sub) is Granula
    doAssert type(mysym2.sub) is float32

foobar()
