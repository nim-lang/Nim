import std/tables

##[
This testcase checks that a borrowed mgetOrPut keeps working through nested
distinct table wrappers.
]##

type
  Level2 = Table[string, seq[string]]
  Level1 = distinct Table[string, Level2]

proc mgetOrPut(t: var Level1; key: string; val: Level2): var Level2 {.borrow, noinit.}

# Section: Borrowed `mgetOrPut` allows nested table updates.
block:
  var nested = Level1(initTable[string, Level2]())
  var level1 = nested.mgetOrPut(
    "key1",
    Level2(initTable[string, seq[string]]())
  )
  level1.mgetOrPut("key2", @["1", "2", "3"]) = @["1", "2", "3"]
  doAssert level1.mgetOrPut("key2", @[]) == @["1", "2", "3"]
