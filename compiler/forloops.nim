#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements for loop detection for better C code generation.

import ast, astalgo

const
  someCmp = {mEqI, mEqI64, mEqF64, mEqEnum, mEqCh, mEqB, mEqRef, mEqProc,
    mEqUntracedRef, mLeI, mLeI64, mLeF64, mLeU, mLeU64, mLeEnum,
    mLeCh, mLeB, mLePtr, mLtI, mLtI64, mLtF64, mLtU, mLtU64, mLtEnum, 
    mLtCh, mLtB, mLtPtr}

proc isCounter(s: PSym): bool {.inline.} =
  s.kind in {skResult, skVar, skLet, skTemp} and 
  {sfGlobal, sfAddrTaken} * s.flags == {}

proc isCall(n: PNode): bool {.inline.} =
  n.kind in nkCallKinds and n[0].kind == nkSym

proc fromSystem(op: PSym): bool = sfSystemModule in getModule(op).flags

proc getCounter(lastStmt: PNode): PSym =
  if lastStmt.isCall:
    let op = lastStmt.sym
    if op.magic in {mDec, mInc} or 
        ((op.name.s == "+=" or op.name.s == "-=") and op.fromSystem):
      if op[1].kind == nkSym and isCounter(op[1].sym):
        result = op[1].sym

proc counterInTree(n, loop: PNode; counter: PSym): bool =
  # prune the search tree: within the loop the counter may be used:
  if n == loop: return
  case n.kind
  of nkSym:
    if n.sym == counter: return true
  of nkVarSection, nkLetSection:
    # definitions are fine!
    for it in n:
      if counterInTree(it.lastSon): return true
  else:
    for i in 0 .. <safeLen(n):
      if counterInTree(n[i], loop, counter): return true

proc copyExcept(n: PNode, x, dest: PNode) =
  if x == n: return
  if n.kind in {nkStmtList, nkStmtListExpr}:
    for i in 0 .. <n.len: copyExcept(n[i], x, dest)
  else:
    dest.add n

type
  ForLoop* = object
    counter*: PSym
    init*, cond*, increment*, body*: PNode

proc extractForLoop*(loop, fullTree: PNode): ForLoop =
  ## returns 'counter == nil' if the while loop 'n' is not a for loop:
  assert loop.kind == nkWhileStmt
  let cond == loop[0]

  if not cond.isCall: return
  if cond[0].sym.magic notin someCmp: return
  
  var lastStmt = loop[1]
  while lastStmt.kind in {nkStmtList, nkStmtListExpr}:
    lastStmt = lastStmt.lastSon

  let counter = getCounter(lastStmt)
  if counter.isNil or counter.ast.isNil: return

  template `=~`(a, b): expr = a.kind == nkSym and a.sym == b
  
  if cond[1] =~ counter or cond[2] =~ counter:
    # ok, now check 'counter' is not used *after* the loop
    if counterInTree(fullTree, loop, counter): return
    # ok, success, fill in the fields:
    result.counter = counter
    result.init = counter.ast
    result.cond = cond
    result.increment = lastStmt
    result.body = newNodeI(nkStmtList, loop[1].info)
    copyExcept(loop[1], lastStmt, result.body)
