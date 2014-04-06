discard """
  output: '''success'''
"""

#bug #913

import macros

macro thirteen(args: varargs[expr]): expr = 
  result = newIntLitNode(13)

doAssert(13==thirteen([1,2])) # works
doAssert(13==thirteen(1,2)) # works

doAssert(13==thirteen(1,[2])) # does not work
doAssert(13==thirteen([1], 2)) # does not work

echo "success"
