discard """
  nimout: '''
  [true, true, true, true, true, true, true]
  '''
"""

import macros

macro m(u:untyped):untyped =
  echo:
    [ hasArgOfName((params u),"s"),
      hasArgOfName((params u),"i"),
      hasArgOfName((params u),"j"),
      hasArgOfName((params u),"k"),
      hasArgOfName((params u),"b"),
      hasArgOfName((params u),"xs"),
      hasArgOfName((params u),"ys"),
    ]

proc p(s:string; i,j,k:int; b:bool; xs,ys:seq[int] = @[]) {.m.} = discard
