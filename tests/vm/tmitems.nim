discard """
  msg: '''13'''
  output: '''3
3
3'''
"""
# bug #3731
var list {.compileTime.} = newSeq[int]()

macro calc*(): stmt {.immediate.} =
  list.add(1)
  for c in list.mitems:
    c = 13

  for c in list:
    echo c

calc()

# bug #3859
import macros
macro m: stmt =
  var s = newseq[NimNode](3)
  # var s: array[3,NimNode]                 # not working either
  for i in 0..<s.len: s[i] = newLit(3)    # works
  #for x in s.mitems: x = newLit(3)
  result = newStmtList()
  for i in s:
    result.add newCall(bindsym"echo", i)

m()
