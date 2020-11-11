
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
  elif n.kind in {nnkAsgn, nnkExprEqExpr}:
    var field = n[0]
    if n[0].kind == nnkDotExpr and n[0][0].eqIdent("_"):
      # handle _.field = ...
      field = n[0][1]
    result = newDotExpr(arg0, field).newAssignment n[1]
  else:
    # handle e.g. 'x.dup(sort)'
    result = newNimNode(nnkCall, n)
    result.add n
    result.add arg0

proc underscoredCalls*(result, calls, arg0: NimNode) =
  expectKind calls, {nnkArgList, nnkStmtList, nnkStmtListExpr}

  for call in calls:
    if call.kind in {nnkStmtList, nnkStmtListExpr}:
      underscoredCalls(result, call, arg0)
    else:
      result.add underscoredCall(call, arg0)
