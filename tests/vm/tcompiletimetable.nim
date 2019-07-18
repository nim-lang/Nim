discard """
  nimout: '''2
3
4:2
Got Hi
Got Hey'''
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

import std/hashes
block:
  # check CT vs RT produces same results for Table
  template callFun(T) =
    block:
      proc fun(): string =
        var t: Table[T, string]
        let n = 10
        for i in 0..<n:
          let i2 = when T.sizeof == type(i).sizeof: i else: i.int32
          let k = cast[T](i2)
            # cast intentional for regression testing,
            # producing small values
          doAssert k notin t
          t[k] = $(i, k)
          doAssert k in t
        $t
      const s1 = fun()
      let s2 = fun()
      # echo s1 # for debugging
      doAssert s1 == s2
      doAssert s1 == s2
      doAssert hash(0.0) == hash(-0.0)
  callFun(float)
  callFun(float32)
  callFun(int64)
