
#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This is an internal helper module. Do not use.

import macros

proc underscoredCall(n, arg0: NimNode): NimNode =
  proc underscorePos(n: NimNode): int =
    for i in 1 ..< n.len:
      if n[i].eqIdent("_"): return i
    return 0

  if n.kind in nnkCallKinds:
    result = copyNimNode(n)
    result.add n[0]

    let u = underscorePos(n)
    for i in 1..u-1: result.add n[i]
    result.add arg0
    for i in u+1..n.len-1: result.add n[i]
  else:
    # handle e.g. 'x.dup(sort)'
    result = newNimNode(nnkCall, n)
    result.add n
    result.add arg0

proc underscoredCalls*(result, calls, arg0: NimNode) =
  proc handleStmtList(result, n, arg0: NimNode) =
    for a in n:
      if a.kind in {nnkStmtList, nnkStmtListExpr}:
        handleStmtList(result, a, arg0)
      else:
        result.add underscoredCall(a, arg0)

  expectKind calls, nnkArgList
  if calls.len == 1 and calls[0].kind in {nnkStmtList, nnkStmtListExpr}:
    # the 'macro: body' syntax is used:
    handleStmtList(result, calls[0], arg0)
  else:
    for call in calls:
      result.add underscoredCall(call, arg0)
