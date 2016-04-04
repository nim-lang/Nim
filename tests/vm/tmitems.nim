discard """
  msg: '''13'''
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
