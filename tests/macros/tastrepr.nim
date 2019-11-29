discard """
output: '''
var data = @["one", "two"]
for (i, d) = in pairs(data):
  echo [d]
'''
"""

import macros

macro foobar(arg: typed) =
  result = newCall(ident"echo", newLit(arg.repr))

foobar:
  var data = @["one", "two"]
  for (i, d) in data.pairs:
    echo d
