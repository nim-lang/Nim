discard """
msg: '''1'''
"""

var list {.compileTime.} = newSeq[int]()  

macro test*(): stmt {.immediate.} =  
  list.add(1)
  for c in list.mitems:
    echo c

test()