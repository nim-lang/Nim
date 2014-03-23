discard """
  msg: '''2
3
4:2
  '''
"""

# bug #404

import macros, tables

var ZOOT{.compileTime.} = initTable[int, int](2)
var iii {.compiletime.} = 1

macro x:stmt=
  zoot[iii] = iii*2
  inc iii
  echo iii

x
x


macro tupleUnpack: stmt =
  var (y,z) = (4, 2)
  echo y, ":", z

tupleUnpack

