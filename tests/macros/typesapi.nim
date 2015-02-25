discard """
  nimout: '''proc (x: int): string => typeDesc[proc[string, int]]
proc (x: int): void => typeDesc[proc[void, int]]
proc (x: int) => typeDesc[proc[void, int]]'''
"""

#2211

import macros

macro showType(t:stmt): stmt =
  let ty = t.getType
  echo t.repr, " => ", ty.repr

showType(proc(x:int): string)
showType(proc(x:int): void)
showType(proc(x:int))
