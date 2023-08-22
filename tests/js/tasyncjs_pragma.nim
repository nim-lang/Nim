discard """
  output: '''
0
t
'''
"""

# xxx merge into tasyncjs.nim

import asyncjs, macros

macro f*(a: untyped): untyped =
  assert a.kind == nnkProcDef
  result = nnkProcDef.newTree(a.name, a[1], a[2], a.params, a.pragma, a[5], nnkStmtList.newTree())
  let call = quote:
    echo 0
  result.body.add(call)
  for child in a.body:
    result.body.add(child)
  #echo result.body.repr

proc t* {.async, f.} =
  echo "t"

proc t0* {.async.} =
  await t()

discard t0()

