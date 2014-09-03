discard """
  msg: '''2
3
4:2
Got Hi
Got Hey'''
"""

# bug #404

import macros, tables, strtabs

var ZOOT{.compileTime.} = initTable[int, int](2)
var iii {.compiletime.} = 1

macro zoo:stmt=
  ZOOT[iii] = iii*2
  inc iii
  echo iii

zoo
zoo


macro tupleUnpack: stmt =
  var (y,z) = (4, 2)
  echo y, ":", z

tupleUnpack

# bug #903

var x {.compileTime.}: StringTableRef

macro addStuff(stuff, body: expr): stmt {.immediate.} =
  result = newNimNode(nnkStmtList)

  if x.isNil:
    x = newStringTable(modeStyleInsensitive)
  x[$stuff] = ""

macro dump(): stmt =
  result = newNimNode(nnkStmtList)
  for y in x.keys: echo "Got ", y

addStuff("Hey"): echo "Hey"
addStuff("Hi"): echo "Hi"
dump()

