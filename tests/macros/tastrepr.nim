discard """
output: '''

var data = @[(1, "one"), (2, "two")]
for (i, d) in pairs(data):
  discard
for i, d in pairs(data):
  discard
for i, (x, y) in pairs(data):
  discard
var (a, b) = (1, 2)

var data = @[(1, "one"), (2, "two")]
for (i, d) in pairs(data):
  discard
for i, d in pairs(data):
  discard
for i, (x, y) in pairs(data):
  discard
var (a, b) = (1, 2)
'''
"""

import macros

macro echoTypedRepr(arg: typed) =
  result = newCall(ident"echo", newLit(arg.repr))

macro echoUntypedRepr(arg: untyped) =
  result = newCall(ident"echo", newLit(arg.repr))

template echoTypedAndUntypedRepr(arg: untyped) =
  echoTypedRepr(arg)
  echoUntypedRepr(arg)

echoTypedAndUntypedRepr:
  var data = @[(1,"one"), (2,"two")]
  for (i, d) in pairs(data):
    discard
  for i, d in pairs(data):
    discard
  for i, (x,y) in pairs(data):
    discard
  var (a,b) = (1,2)
