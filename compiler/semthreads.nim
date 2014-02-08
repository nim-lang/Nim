#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Semantic analysis that deals with threads: Possible race conditions should
## be reported some day.
##
## 
## ========================
## No heap sharing analysis
## ========================
##
## The only crucial operation that can violate the heap invariants is the
## write access. The analysis needs to distinguish between 'unknown', 'mine',
## and 'theirs' memory and pointers. Assignments 'whatever <- unknown' are 
## invalid, and so are 'theirs <- whatever' but not 'mine <- theirs'. Since
## strings and sequences are heap allocated they are affected too:
##
## .. code-block:: nimrod
##   proc p() = 
##     global = "alloc this string" # ugh!
##
## Thus the analysis is concerned with any type that contains a GC'ed
## reference...
## If the type system would distinguish between 'ref' and '!ref' and threads
## could not have '!ref' as input parameters the analysis could simply need to
## reject any write access to a global variable which contains GC'ed data.
## Thanks to the write barrier of the GC, this is exactly what needs to be
## done! Every write access to a global that contains GC'ed data needs to
## be prevented! Unfortunately '!ref' is not implemented yet...
##
## The assignment target is essential for the algorithm: only 
## write access to heap locations and global variables are critical and need
## to be checked. Access via 'var' parameters is no problem to analyse since
## we need the arguments' locations in the analysis.
##
## However, this is tricky: 
##  
##  var x = globalVar     # 'x' points to 'theirs'
##  while true:
##    globalVar = x       # NOT OK: 'theirs <- theirs' invalid due to
##                        # write barrier!
##    x = "new string"    # ugh: 'x is toUnknown'!
##
##  --> Solution: toUnknown is never allowed anywhere!
##
##
## Beware that the same proc might need to be
## analysed multiple times! Oh and watch out for recursion! Recursion is handled
## by a stack of symbols that we are processing, if we come back to the same
## symbol, we have to skip this check (assume no error in the recursive case).
## However this is wrong. We need to check for the particular combination
## of (procsym, threadOwner(arg1), threadOwner(arg2), ...)!

import
  ast, astalgo, strutils, hashes, options, msgs, idents, types, os,
  renderer, tables, rodread

type
  TThreadOwner = enum
    toUndefined, # not computed yet 
    toVoid,      # no return type
    toNil,       # cycle in computation or nil: can be overwritten
    toTheirs,    # some other heap
    toMine       # mine heap

  TCall = object {.pure.}
    callee: PSym              # what if callee is an indirect call?
    args: seq[TThreadOwner]

  PProcCtx = ref TProcCtx
  TProcCtx = object {.pure.}
    nxt: PProcCtx             # can be stacked
    mapping: tables.TTable[int, TThreadOwner] # int = symbol ID
    owner: PSym               # current owner

var
  computed = tables.initTable[TCall, TThreadOwner]()

proc hash(c: TCall): THash =
  result = hash(c.callee.id)
  for a in items(c.args): result = result !& hash(ord(a))
  result = !$result

proc `==`(a, b: TCall): bool =
  if a.callee != b.callee: return
  if a.args.len != b.args.len: return
  for i in 0..a.args.len-1:
    if a.args[i] != b.args[i]: return
  result = true

proc newProcCtx(owner: PSym): PProcCtx =
  assert owner != nil
  new(result)
  result.mapping = tables.initTable[int, TThreadOwner]()
  result.owner = owner

proc analyse(c: PProcCtx, n: PNode): TThreadOwner

proc analyseSym(c: PProcCtx, n: PNode): TThreadOwner =
  var v = n.sym
  result = c.mapping[v.id]
  if result != toUndefined: return
  case v.kind
  of skVar, skForVar, skLet, skResult:
    result = toNil
    if sfGlobal in v.flags:
      if sfThread in v.flags: 
        result = toMine 
      elif containsGarbageCollectedRef(v.typ):
        result = toTheirs
  of skTemp: result = toNil
  of skConst: result = toMine
  of skParam: 
    result = c.mapping[v.id]
    if result == toUndefined:
      internalError(n.info, "param not set: " & v.name.s)
  else:
    result = toNil
  c.mapping[v.id] = result

proc lvalueSym(n: PNode): PNode =
  result = n
  while result.kind in {nkDotExpr, nkCheckedFieldExpr,
                        nkBracketExpr, nkDerefExpr, nkHiddenDeref}:
    result = result.sons[0]

proc writeAccess(c: PProcCtx, n: PNode, owner: TThreadOwner) =
  if owner notin {toNil, toMine, toTheirs}:
    internalError(n.info, "writeAccess: " & $owner)
  var a = lvalueSym(n)
  if a.kind == nkSym: 
    var v = a.sym
    var lastOwner = analyseSym(c, a)
    case lastOwner
    of toNil:
      # fine, toNil can be overwritten
      var newOwner: TThreadOwner
      if sfGlobal in v.flags:
        newOwner = owner
      elif containsTyRef(v.typ):
        # ``var local = gNode`` --> ok, but ``local`` is theirs! 
        newOwner = owner
      else:
        # ``var local = gString`` --> string copy: ``local`` is mine! 
        newOwner = toMine
        # XXX BUG what if the tuple contains both ``tyRef`` and ``tyString``?
      c.mapping[v.id] = newOwner
    of toVoid, toUndefined: internalError(n.info, "writeAccess")
    of toTheirs: message(n.info, warnWriteToForeignHeap)
    of toMine:
      if lastOwner != owner and owner != toNil:
        message(n.info, warnDifferentHeaps)
  else:
    # we could not backtrack to a concrete symbol, but that's fine:
    var lastOwner = analyse(c, n)
    case lastOwner
    of toNil: discard # fine, toNil can be overwritten
    of toVoid, toUndefined: internalError(n.info, "writeAccess")
    of toTheirs: message(n.info, warnWriteToForeignHeap)
    of toMine:
      if lastOwner != owner and owner != toNil:
        message(n.info, warnDifferentHeaps)

proc analyseAssign(c: PProcCtx, le, ri: PNode) =
  var y = analyse(c, ri) # read access; ok
  writeAccess(c, le, y)

proc analyseAssign(c: PProcCtx, n: PNode) =
  analyseAssign(c, n.sons[0], n.sons[1])

proc analyseCall(c: PProcCtx, n: PNode): TThreadOwner =
  var prc = n[0].sym
  var newCtx = newProcCtx(prc)
  var call: TCall
  call.callee = prc
  newSeq(call.args, n.len-1)
  for i in 1..n.len-1:
    call.args[i-1] = analyse(c, n[i])
  if not computed.hasKey(call):
    computed[call] = toUndefined # we are computing it
    let prctyp = skipTypes(prc.typ, abstractInst).n
    for i in 1.. prctyp.len-1: 
      var formal = prctyp.sons[i].sym 
      newCtx.mapping[formal.id] = call.args[i-1]
    pushInfoContext(n.info)
    result = analyse(newCtx, prc.getBody)
    if prc.ast.sons[bodyPos].kind == nkEmpty and 
       {sfNoSideEffect, sfThread, sfImportc} * prc.flags == {}:
      message(n.info, warnAnalysisLoophole, renderTree(n))
      if result == toUndefined: result = toNil
    if prc.typ.sons[0] != nil:
      if prc.ast.len > resultPos:
        result = newCtx.mapping[prc.ast.sons[resultPos].sym.id]
        # if the proc body does not set 'result', nor 'return's something
        # explicitely, it returns a binary zero, so 'toNil' is correct:
        if result == toUndefined: result = toNil
      else:
        result = toNil
    else:
      result = toVoid
    computed[call] = result
    popInfoContext()
  else:
    result = computed[call]
    if result == toUndefined:
      # ugh, cycle! We are already computing it but don't know the
      # outcome yet...
      if prc.typ.sons[0] == nil: result = toVoid
      else: result = toNil

proc analyseVarTuple(c: PProcCtx, n: PNode) =
  if n.kind != nkVarTuple: internalError(n.info, "analyseVarTuple")
  var L = n.len
  for i in countup(0, L-3): analyseAssign(c, n.sons[i], n.sons[L-1])

proc analyseSingleVar(c: PProcCtx, a: PNode) =
  if a.sons[2].kind != nkEmpty: analyseAssign(c, a.sons[0], a.sons[2])

proc analyseVarSection(c: PProcCtx, n: PNode): TThreadOwner = 
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    if a.kind == nkIdentDefs: 
      #assert(a.sons[0].kind == nkSym); also valid for after
      # closure transformation:
      analyseSingleVar(c, a)
    else:
      analyseVarTuple(c, a)
  result = toVoid

proc analyseConstSection(c: PProcCtx, t: PNode): TThreadOwner =
  for i in countup(0, sonsLen(t) - 1): 
    var it = t.sons[i]
    if it.kind == nkCommentStmt: continue 
    if it.kind != nkConstDef: internalError(t.info, "analyseConstSection")
    if sfFakeConst in it.sons[0].sym.flags: analyseSingleVar(c, it)
  result = toVoid

template aggregateOwner(result, ana: expr) =
  var a = ana # eval once
  if result != a:
    if result == toNil: result = a
    elif a != toNil: message(n.info, warnDifferentHeaps)

proc analyseArgs(c: PProcCtx, n: PNode, start = 1) =
  for i in start..n.len-1: discard analyse(c, n[i])

proc analyseOp(c: PProcCtx, n: PNode): TThreadOwner =
  if n[0].kind != nkSym or n[0].sym.kind != skProc:
    if {tfNoSideEffect, tfThread} * n[0].typ.flags == {}:
      message(n.info, warnAnalysisLoophole, renderTree(n))
    result = toNil
  else:
    var prc = n[0].sym
    case prc.magic
    of mNone: 
      if sfSystemModule in prc.owner.flags:
        # System module proc does no harm :-)
        analyseArgs(c, n)
        if prc.typ.sons[0] == nil: result = toVoid
        else: result = toNil
      else:
        result = analyseCall(c, n)
    of mNew, mNewFinalize, mNewSeq, mSetLengthStr, mSetLengthSeq,
        mAppendSeqElem, mReset, mAppendStrCh, mAppendStrStr:
      writeAccess(c, n[1], toMine)
      result = toVoid
    of mSwap:
      var a = analyse(c, n[2])
      writeAccess(c, n[1], a)
      writeAccess(c, n[2], a)
      result = toVoid
    of mIntToStr, mInt64ToStr, mFloatToStr, mBoolToStr, mCharToStr, 
        mCStrToStr, mStrToStr, mEnumToStr,
        mConStrStr, mConArrArr, mConArrT, 
        mConTArr, mConTT, mSlice, 
        mRepr, mArrToSeq, mCopyStr, mCopyStrLast, 
        mNewString, mNewStringOfCap:
      analyseArgs(c, n)
      result = toMine
    else:
      # don't recurse, but check args:
      analyseArgs(c, n)
      if prc.typ.sons[0] == nil: result = toVoid
      else: result = toNil

proc analyse(c: PProcCtx, n: PNode): TThreadOwner =
  case n.kind
  of nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand,
     nkCallStrLit, nkHiddenCallConv:
    result = analyseOp(c, n)
  of nkAsgn, nkFastAsgn:
    analyseAssign(c, n)
    result = toVoid
  of nkSym: result = analyseSym(c, n)
  of nkEmpty, nkNone: result = toVoid
  of nkNilLit, nkCharLit..nkFloat64Lit: result = toNil
  of nkStrLit..nkTripleStrLit: result = toMine
  of nkDotExpr, nkBracketExpr, nkDerefExpr, nkHiddenDeref:
    # field access:
    # pointer deref or array access:
    result = analyse(c, n.sons[0])
  of nkBind: result = analyse(c, n.sons[0])
  of nkPar, nkCurly, nkBracket, nkRange:
    # container construction:
    result = toNil # nothing until later
    for i in 0..n.len-1: aggregateOwner(result, analyse(c, n[i]))
  of nkObjConstr:
    if n.typ != nil and containsGarbageCollectedRef(n.typ):
      result = toMine
    else:
      result = toNil # nothing until later
    for i in 1..n.len-1: aggregateOwner(result, analyse(c, n[i]))
  of nkAddr, nkHiddenAddr:
    var a = lvalueSym(n)
    if a.kind == nkSym:
      result = analyseSym(c, a)
      assert result in {toNil, toMine, toTheirs}
      if result == toNil:
        # assume toMine here for consistency:
        c.mapping[a.sym.id] = toMine
        result = toMine
    else:
      # should never really happen:
      result = analyse(c, n.sons[0])
  of nkIfExpr: 
    result = toNil
    for i in countup(0, sonsLen(n) - 1):
      var it = n.sons[i]
      if it.len == 2:
        discard analyse(c, it.sons[0])
        aggregateOwner(result, analyse(c, it.sons[1]))
      else:
        aggregateOwner(result, analyse(c, it.sons[0]))
  of nkStmtListExpr, nkBlockExpr:
    var n = if n.kind == nkBlockExpr: n.sons[1] else: n
    var L = sonsLen(n)
    for i in countup(0, L-2): discard analyse(c, n.sons[i])
    if L > 0: result = analyse(c, n.sons[L-1])
    else: result = toVoid
  of nkHiddenStdConv, nkHiddenSubConv, nkConv, nkCast: 
    result = analyse(c, n.sons[1])
  of nkStringToCString, nkCStringToString, nkChckRangeF, nkChckRange64,
     nkChckRange, nkCheckedFieldExpr, nkObjDownConv, 
     nkObjUpConv:
    result = analyse(c, n.sons[0])
  of nkRaiseStmt:
    var a = analyse(c, n.sons[0])
    if a != toMine: message(n.info, warnDifferentHeaps)
    result = toVoid
  of nkVarSection, nkLetSection: result = analyseVarSection(c, n)
  of nkConstSection: result = analyseConstSection(c, n)
  of nkTypeSection, nkCommentStmt: result = toVoid
  of nkIfStmt, nkWhileStmt, nkTryStmt, nkCaseStmt, nkStmtList, nkBlockStmt, 
     nkElifBranch, nkElse, nkExceptBranch, nkOfBranch:
    for i in 0 .. <n.len: discard analyse(c, n[i])
    result = toVoid
  of nkBreakStmt, nkContinueStmt: result = toVoid
  of nkReturnStmt, nkDiscardStmt: 
    if n.sons[0].kind != nkEmpty: result = analyse(c, n.sons[0])
    else: result = toVoid
  of nkLambdaKinds, nkClosure:
    result = toMine
  of nkAsmStmt, nkPragma, nkIteratorDef, nkProcDef, nkMethodDef,
     nkConverterDef, nkMacroDef, nkTemplateDef,
     nkGotoState, nkState, nkBreakState, nkType, nkIdent:
      result = toVoid
  of nkExprColonExpr:
    result = analyse(c, n.sons[1])
  else: internalError(n.info, "analysis not implemented for: " & $n.kind)

proc analyseThreadProc*(prc: PSym) =
  var c = newProcCtx(prc)
  var formals = skipTypes(prc.typ, abstractInst).n
  for i in 1 .. formals.len-1:
    var formal = formals.sons[i].sym 
    # the input is copied and belongs to the thread:
    c.mapping[formal.id] = toMine
  discard analyse(c, prc.getBody)

proc needsGlobalAnalysis*: bool =
  result = gGlobalOptions * {optThreads, optThreadAnalysis} == 
                            {optThreads, optThreadAnalysis}

