discard """
nimout: '''
0
1
StmtList
  Ident "c"
'''
"""

# bug #19460

import macros

macro test(body: varargs[untyped]): untyped =
  var tmpidx = 0
  var tmp = body[tmpidx]

  proc next =
    tmpidx += 1
    tmp = body[tmpidx] # LINE1

  echo tmpidx
  next()
  echo tmpidx
  #tmp = body[tmpidx] # LINE2

  echo tmp.treeRepr

  result = nnkEmpty.newNimNode()

test a(b):
  c
