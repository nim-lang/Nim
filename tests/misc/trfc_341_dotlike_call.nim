discard """
nimout: '''
ArgList
  Ident "foo"
  Call
    Ident "bar"
    IntLit 1
ArgList
  Ident "foo"
  Call
    Ident "bar"
    IntLit 1
'''
"""

import std/macros
macro `?`(a: varargs[untyped]): untyped =
  echo a.treerepr

foo?bar(1)

macro `.?`(a: varargs[untyped]): untyped =
  echo a.treerepr

foo.?bar(1)

static: doAssert defined(nimPreviewDotLikeOps)

iterator `.++`[T](a: T, b: T): T =
  ## Increment each output by 2
  var res: T = a
  while res <= b:
    yield res
    inc res
    inc res

var collector: seq[int] = @[]
for i in 0 .++ 8:
  collector.add i

doAssert collector == @[0, 2, 4, 6, 8]
