discard """
  output: '''
range[0 .. 100]
array[0 .. 100, int]
'''
"""

import macros

type
  Foo1 = range[0 .. 100]
  Foo2 = array[0 .. 100, int]

macro get(T: typedesc): untyped =
  # Get the X out of typedesc[X]
  let tmp = getTypeImpl(T)
  result = newStrLitNode(getTypeImpl(tmp[1]).repr)

echo Foo1.get
echo Foo2.get
