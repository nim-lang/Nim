discard """
  output: '''ok'''
"""
# bug #9864
import macros, tables

proc bar(shOpt: Table[string, int]) = discard

macro dispatchGen(): untyped =
  var shOpt = initTable[string, int]()
  shOpt["foo"] = 10
  result = quote do:
     bar(`shOpt`)

dispatchGen()

type
  Foo = object
    data: seq[int]

proc barB(a: Foo) = discard

proc shOptB(): auto =
  var shOpt: Foo
  shOpt.data.setLen 1 # fails
  shOpt

macro dispatchGenB(): untyped =
  var shOpt = shOptB() # fails

  result = quote do:
     barB(`shOpt`)

dispatchGenB()

echo "ok"
