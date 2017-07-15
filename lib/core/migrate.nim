#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements transformations for easy conversions to newer Nim
## versions.

import macros

proc strAlgoBody(n, res: NimNode; firstAsgn: var bool): NimNode =
  case n.kind
  of nnkAsgn, nnkFastAsgn:
    if n[0].kind == nnkIdent and eqIdent(n[0], "result"):
      let a = if n[1].kind in {nnkStrLit..nnkTripleStrLit}:
                newCall("mstring", n[1])
              else:
                n[1]
      if firstAsgn:
        firstAsgn = false
        return newVarStmt(res, a)
      else:
        return newAssignment(res, a)
  of nnkIdent:
    if eqIdent(n, "result"): return res
    if eqIdent(n, "result0"): firstAsgn = false
  else: discard
  result = copyNimNode(n)
  for i in 0..<n.len:
    result.add strAlgoBody(n[i], res, firstAsgn)

macro strBuilder*(n: untyped): untyped =
  when defined(nimImmutableStrings):
    let res = ident"result0"
    result = copyNimNode(n)
    for i in 0..<n.len:
      if i == 6:
        var firstAsgn = true
        var b = strAlgoBody(n[i], res, firstAsgn)
        expectKind b, nnkStmtList
        b.add newAssignment(ident"result", newCall("$", res))
        result.add b
      else:
        result.add n[i]
  else:
    result = n
  when defined(debugStrBuilder):
    echo repr result

macro strBody*(n: untyped): untyped =
  when defined(nimImmutableStrings):
    var firstAsgn = true
    let res = ident"result0"
    var b = strAlgoBody(n, res, firstAsgn)
    expectKind b, nnkStmtList
    b.add newAssignment(ident"result", newCall("$", res))
    result = b
  else:
    result = n
  when defined(debugStrBuilder):
    echo repr result
