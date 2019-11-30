discard """
output: '''
var data = @[(1, "one"), (2, "two")]
for (i, d) in pairs(data):
  echo [d]
for i, d in pairs(data):
  echo [d]
for i, (x, y) in pairs(data):
  echo [x, " -> ", y]
var (a, b) = (1, 2)
'''
"""

import macros

macro foobar(arg: typed) =
  result = newCall(ident"echo", newLit(arg.repr))

foobar:
  var data = @[(1,"one"), (2,"two")]
  for (i, d) in data.pairs:
    echo d
  for i, d in data.pairs:
    echo d
  for i, (x,y) in data.pairs:
    echo x, " -> ", y
  var (a,b) = (1,2)
