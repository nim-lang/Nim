discard """
  matrix: "--gc:refc; --gc:arc"
  output: "abc: @[(kind: A, x: 0)]"
"""

import std/tables

type E = enum
  A, B

type O = object
  case kind: E
  of A:
    x: int
  of B:
    y: int 

proc someTable(): Table[string, seq[O]] =
  result = initTable[string, seq[O]]()
  result["abc"] = @[O(kind: A)]

const t = someTable()

for k, v in t:
  echo k, ": ", v
