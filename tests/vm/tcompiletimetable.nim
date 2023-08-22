discard """
  nimout: '''
2
3
4:2
Got Hi
Got Hey
'''
  output:'''
a
b
c
'''
"""

# bug #404

import macros, tables, strtabs

var ZOOT{.compileTime.} = initTable[int, int](2)
var iii {.compiletime.} = 1

macro zoo: untyped =
  ZOOT[iii] = iii*2
  inc iii
  echo iii

zoo
zoo


macro tupleUnpack: untyped =
  var (y,z) = (4, 2)
  echo y, ":", z

tupleUnpack

# bug #903

var x {.compileTime.}: StringTableRef

macro addStuff(stuff, body: untyped): untyped =
  result = newNimNode(nnkStmtList)

  if x.isNil:
    x = newStringTable(modeStyleInsensitive)
  x[$stuff] = ""

macro dump(): untyped =
  result = newNimNode(nnkStmtList)
  for y in x.keys: echo "Got ", y

addStuff("Hey"): echo "Hey"
addStuff("Hi"): echo "Hi"
dump()

# ensure .compileTime vars can be used at runtime:
import macros

var xzzzz {.compileTime.}: array[3, string] = ["a", "b", "c"]

for i in 0..high(xzzzz): echo xzzzz[i]
