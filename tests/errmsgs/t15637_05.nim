discard """
  action: reject
"""

# issue #15637

import std/macros

macro foo(x: typed): untyped =
  result = newStmtList()
  result.add x
  result.add x

proc bar =
  foo:
    var a = 1

bar()
