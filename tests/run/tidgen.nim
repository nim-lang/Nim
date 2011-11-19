discard """
  output: "3 4"
"""

import macros

# Test compile-time state in same module

var gid = 3

macro genId(invokation: expr): expr =
  result = newIntLitNode(gid)
  inc gid

proc Id1(): int = return genId()
proc Id2(): int = return genId()

echo Id1(), " ", Id2()

