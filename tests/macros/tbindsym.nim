discard """
  output: '''TFoo
TBar'''
"""

# bug #1319

import macros

type
  TTextKind = enum
    TFoo, TBar

macro test: stmt =
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
