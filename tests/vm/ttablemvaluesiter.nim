discard """
msg: '''1'''
"""

import tables, macros

var registry {.compileTime.} = initTable[int, int]()

macro test*(): stmt {.immediate.} =  
  registry.add(1, 1)
  for c in registry.mvalues():
    echo c

test()