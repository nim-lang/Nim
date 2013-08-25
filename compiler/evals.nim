#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This file implements the evaluator for Nimrod code.
# The evaluator is very slow, but simple. Since this
# is used mainly for evaluating macros and some other
# stuff at compile time, performance is not that
# important.

import 
  strutils, magicsys, lists, options, ast, astalgo, trees, treetab, nimsets, 
  msgs, os, condsyms, idents, renderer, types, passes, semfold, transf, 
  parser, ropes, rodread, idgen, osproc, streams, evaltempl

when hasFFI:
  import evalffi

type 
  PStackFrame* = ref TStackFrame
  TStackFrame* = object
    prc: PSym                 # current prc; proc that is evaluated
    slots: TNodeSeq           # parameters passed to the proc + locals;
                              # parameters come first
    call: PNode
    next: PStackFrame         # for stacking
  
  TEvalMode* = enum           ## reason for evaluation
    emRepl,                   ## evaluate because in REPL mode
    emConst,                  ## evaluate for 'const' according to spec
    emOptimize,               ## evaluate for optimization purposes (same as
                              ## emConst?)
    emStatic                  ## evaluate for enforced compile time eval
                              ## ('static' context)

  TSandboxFlag* = enum        ## what the evaluation engine should allow
    allowCast,                ## allow unsafe language feature: 'cast'
    allowFFI,                 ## allow the FFI
    allowInfiniteLoops        ## allow endless loops
  TSandboxFlags* = set[TSandboxFlag]

  TEvalContext* = object of passes.TPassContext
    module*: PSym
    tos*: PStackFrame         # top of stack
    lastException*: PNode
    callsite: PNode           # for 'callsite' magic
    mode*: TEvalMode
    features: TSandboxFlags
    globals*: TIdNodeTable    # state of global vars
    getType*: proc(n: PNode): PNode {.closure.}
    handleIsOperator*: proc(n: PNode): PNode {.closure.}

  PEvalContext* = ref TEvalContext

  TEvalFlag = enum 
    efNone, efLValue
  TEvalFlags = set[TEvalFlag]

const
  evalMaxIterations = 500_000 # max iterations of all loops
  evalMaxRecDepth = 10_000    # max recursion depth for evaluation

# other idea: use a timeout! -> Wether code compiles depends on the machine
# the compiler runs on then! Bad idea!

proc newStackFrame*(): PStackFrame =
  new(result)
  result.slots = @[]

proc newEvalContext*(module: PSym, mode: TEvalMode): PEvalContext =
  new(result)
  result.module = module
  result.mode = mode
  result.features = {allowFFI}
  initIdNodeTable(result.globals)

proc pushStackFrame*(c: PEvalContext, t: PStackFrame) {.inline.} = 
  t.next = c.tos
  c.tos = t

proc popStackFrame*(c: PEvalContext) {.inline.} =
  if c.tos != nil: c.tos = c.tos.next
  else: InternalError("popStackFrame")

proc evalMacroCall*(c: PEvalContext, n, nOrig: PNode, sym: PSym): PNode
proc evalAux(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode

proc raiseCannotEval(c: PEvalContext, info: TLineInfo): PNode =
  result = newNodeI(nkExceptBranch, info)
  # creating a nkExceptBranch without sons 
  # means that it could not be evaluated

proc stackTraceAux(x: PStackFrame) =
  if x != nil:
    stackTraceAux(x.next)
    var info = if x.call != nil: x.call.info else: UnknownLineInfo()
    # we now use the same format as in system/except.nim
    var s = toFilename(info)
    var line = toLineNumber(info)
    if line > 0:
      add(s, '(')
      add(s, $line)
      add(s, ')')
    if x.prc != nil:
      for k in 1..max(1, 25-s.len): add(s, ' ')
      add(s, x.prc.name.s)
    MsgWriteln(s)

proc stackTrace(c: PEvalContext, info: TLineInfo, msg: TMsgKind, arg = "") = 
  MsgWriteln("stack trace: (most recent call last)")
  stackTraceAux(c.tos)
  LocalError(info, msg, arg)

template isSpecial(n: PNode): bool = n.kind == nkExceptBranch
template bailout() {.dirty.} =
  if isSpecial(result): return

template evalX(n, flags) {.dirty.} =
  result = evalAux(c, n, flags)
  bailout()

proc myreset(n: PNode) =
  when defined(system.reset): 
    var oldInfo = n.info
    reset(n[])
    n.info = oldInfo

proc evalIf(c: PEvalContext, n: PNode): PNode = 
  var i = 0
  var length = sonsLen(n)
  while (i < length) and (sonsLen(n.sons[i]) >= 2): 
    evalX(n.sons[i].sons[0], {})
    if result.kind == nkIntLit and result.intVal != 0:
      return evalAux(c, n.sons[i].sons[1], {})
    inc(i)
  if (i < length) and (sonsLen(n.sons[i]) < 2):
    result = evalAux(c, n.sons[i].sons[0], {})
  else:
    result = emptyNode
  
proc evalCase(c: PEvalContext, n: PNode): PNode = 
  evalX(n.sons[0], {})
  var res = result
  result = emptyNode
  for i in countup(1, sonsLen(n) - 1): 
    if n.sons[i].kind == nkOfBranch: 
      for j in countup(0, sonsLen(n.sons[i]) - 2): 
        if overlap(res, n.sons[i].sons[j]): 
          return evalAux(c, lastSon(n.sons[i]), {})
    else: 
      result = evalAux(c, lastSon(n.sons[i]), {})

var 
  gWhileCounter: int # Use a counter to prevent endless loops!
                     # We make this counter global, because otherwise
                     # nested loops could make the compiler extremely slow.
  gNestedEvals: int  # count the recursive calls to ``evalAux`` to prevent
                     # endless recursion

proc evalWhile(c: PEvalContext, n: PNode): PNode = 
  while true: 
    evalX(n.sons[0], {})
    if getOrdValue(result) == 0: break
    result = evalAux(c, n.sons[1], {})
    case result.kind
    of nkBreakStmt: 
      if result.sons[0].kind == nkEmpty: 
        result = emptyNode    # consume ``break`` token
      # Bugfix (see tmacro2): but break in any case!
      break 
    of nkExceptBranch, nkReturnToken: break 
    else: nil
    dec(gWhileCounter)
    if gWhileCounter <= 0:
      if allowInfiniteLoops in c.features:
        gWhileCounter = 0
      else:
        stackTrace(c, n.info, errTooManyIterations)
        break

proc evalBlock(c: PEvalContext, n: PNode): PNode =
  result = evalAux(c, n.sons[1], {})
  if result.kind == nkBreakStmt:
    if result.sons[0] != nil: 
      assert(result.sons[0].kind == nkSym)
      if n.sons[0].kind != nkEmpty: 
        assert(n.sons[0].kind == nkSym)
        if result.sons[0].sym.id == n.sons[0].sym.id: result = emptyNode
    # blocks can only be left with an explicit label now!
    #else: 
    #  result = emptyNode      # consume ``break`` token
  
proc evalFinally(c: PEvalContext, n, exc: PNode): PNode = 
  var finallyNode = lastSon(n)
  if finallyNode.kind == nkFinally: 
    result = evalAux(c, finallyNode, {})
    if result.kind != nkExceptBranch: result = exc
  else: 
    result = exc
  
proc evalTry(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[0], {})
  case result.kind
  of nkBreakStmt, nkReturnToken: 
    nil
  of nkExceptBranch: 
    if sonsLen(result) >= 1: 
      # creating a nkExceptBranch without sons means that it could not be
      # evaluated
      var exc = result
      var i = 1
      var length = sonsLen(n)
      while (i < length) and (n.sons[i].kind == nkExceptBranch): 
        var blen = sonsLen(n.sons[i])
        if blen == 1: 
          # general except section:
          result = evalAux(c, n.sons[i].sons[0], {})
          exc = result
          break 
        else: 
          for j in countup(0, blen - 2): 
            assert(n.sons[i].sons[j].kind == nkType)
            let a = exc.typ.skipTypes(abstractPtrs)
            let b = n.sons[i].sons[j].typ.skipTypes(abstractPtrs)
            if a == b: 
              result = evalAux(c, n.sons[i].sons[blen - 1], {})
              exc = result
              break 
        inc(i)
      result = evalFinally(c, n, exc)
  else: result = evalFinally(c, n, emptyNode)
  
proc getNullValue(typ: PType, info: TLineInfo): PNode
proc getNullValueAux(obj: PNode, result: PNode) = 
  case obj.kind
  of nkRecList:
    for i in countup(0, sonsLen(obj) - 1): getNullValueAux(obj.sons[i], result)
  of nkRecCase:
    getNullValueAux(obj.sons[0], result)
    for i in countup(1, sonsLen(obj) - 1): 
      getNullValueAux(lastSon(obj.sons[i]), result)
  of nkSym:
    var s = obj.sym
    var p = newNodeIT(nkExprColonExpr, result.info, s.typ)
    addSon(p, newSymNode(s, result.info))
    addSon(p, getNullValue(s.typ, result.info))
    addSon(result, p)
  else: InternalError(result.info, "getNullValueAux")
  
proc getNullValue(typ: PType, info: TLineInfo): PNode = 
  var t = skipTypes(typ, abstractRange-{tyTypeDesc})
  result = emptyNode
  case t.kind
  of tyBool, tyEnum, tyChar, tyInt..tyInt64: 
    result = newNodeIT(nkIntLit, info, t)
  of tyUInt..tyUInt64:
    result = newNodeIT(nkUIntLit, info, t)
  of tyFloat..tyFloat128: 
    result = newNodeIt(nkFloatLit, info, t)
  of tyVar, tyPointer, tyPtr, tyRef, tyCString, tySequence, tyString, tyExpr, 
     tyStmt, tyTypeDesc, tyProc:
    result = newNodeIT(nkNilLit, info, t)
  of tyObject: 
    result = newNodeIT(nkPar, info, t)
    getNullValueAux(t.n, result)
    # initialize inherited fields:
    var base = t.sons[0]
    while base != nil:
      getNullValueAux(skipTypes(base, skipPtrs).n, result)
      base = base.sons[0]
  of tyArray, tyArrayConstr: 
    result = newNodeIT(nkBracket, info, t)
    for i in countup(0, int(lengthOrd(t)) - 1): 
      addSon(result, getNullValue(elemType(t), info))
  of tyTuple:
    # XXX nkExprColonExpr is out of fashion ...
    result = newNodeIT(nkPar, info, t)
    for i in countup(0, sonsLen(t) - 1):
      var p = newNodeIT(nkExprColonExpr, info, t.sons[i])
      var field = if t.n != nil: t.n.sons[i].sym else: newSym(
        skField, getIdent(":tmp" & $i), t.owner, info)
      addSon(p, newSymNode(field, info))
      addSon(p, getNullValue(t.sons[i], info))
      addSon(result, p)
  of tySet:
    result = newNodeIT(nkCurly, info, t)    
  else: InternalError("getNullValue: " & $t.kind)
  
proc evalVarValue(c: PEvalContext, n: PNode): PNode =
  result = evalAux(c, n, {})
  if result.kind in {nkType..nkNilLit}: result = result.copyNode

proc allocSlot(c: PStackFrame; sym: PSym): int =
  result = sym.position + ord(sym.kind == skParam)
  if result == 0 and sym.kind != skResult:
    result = c.slots.len
    if result == 0: result = 1
    sym.position = result
  setLen(c.slots, max(result+1, c.slots.len))

proc setSlot(c: PStackFrame, sym: PSym, val: PNode) =
  assert sym.owner == c.prc
  let idx = allocSlot(c, sym)
  c.slots[idx] = val

proc setVar(c: PEvalContext, v: PSym, n: PNode) =
  if sfGlobal notin v.flags: setSlot(c.tos, v, n)
  else: IdNodeTablePut(c.globals, v, n)

proc evalVar(c: PEvalContext, n: PNode): PNode =
  for i in countup(0, sonsLen(n) - 1):
    let a = n.sons[i]
    if a.kind == nkCommentStmt: continue
    #assert(a.sons[0].kind == nkSym) can happen for transformed vars
    if a.kind == nkVarTuple:
      result = evalVarValue(c, a.lastSon)
      if result.kind in {nkType..nkNilLit}:
        result = result.copyNode
      bailout()
      if result.kind != nkPar:
        return raiseCannotEval(c, n.info)
      for i in 0 .. a.len-3:
        var v = a.sons[i].sym
        setVar(c, v, result.sons[i])
    else:
      if a.sons[2].kind != nkEmpty:
        result = evalVarValue(c, a.sons[2])
        bailout()
      else:
        result = getNullValue(a.sons[0].typ, a.sons[0].info)
      if a.sons[0].kind == nkSym:
        var v = a.sons[0].sym
        setVar(c, v, result)
      else:
        # assign to a.sons[0]:
        var x = result
        evalX(a.sons[0], {})
        myreset(x)
        x.kind = result.kind
        x.typ = result.typ
        case x.kind
        of nkCharLit..nkInt64Lit: x.intVal = result.intVal
        of nkFloatLit..nkFloat64Lit: x.floatVal = result.floatVal
        of nkStrLit..nkTripleStrLit: x.strVal = result.strVal
        of nkIdent: x.ident = result.ident
        of nkSym: x.sym = result.sym
        else:
          if x.kind notin {nkEmpty..nkNilLit}:
            discardSons(x)
            for j in countup(0, sonsLen(result) - 1): addSon(x, result.sons[j])
  result = emptyNode

proc aliasNeeded(n: PNode, flags: TEvalFlags): bool = 
  result = efLValue in flags or n.typ == nil or 
    n.typ.kind in {tyExpr, tyStmt, tyTypeDesc}

proc evalVariable(c: PStackFrame, sym: PSym, flags: TEvalFlags): PNode =
  # We need to return a node to the actual value,
  # which can be modified.
  assert sym.position != 0 or skResult == sym.kind
  var x = c
  while x != nil:
    if sym.owner == x.prc:
      result = x.slots[sym.position]
      assert result != nil
      if not aliasNeeded(result, flags):
        result = copyTree(result)
      return
    x = x.next
  #internalError(sym.info, "cannot eval " & sym.name.s & " " & $sym.position)
  result = raiseCannotEval(nil, sym.info)
  #result = emptyNode

proc evalGlobalVar(c: PEvalContext, s: PSym, flags: TEvalFlags): PNode =
  if sfCompileTime in s.flags or c.mode == emRepl:
    result = IdNodeTableGet(c.globals, s)
    if result != nil: 
      if not aliasNeeded(result, flags): 
        result = copyTree(result)
    else:
      when hasFFI:
        if sfImportc in s.flags and allowFFI in c.features:
          result = importcSymbol(s)
          IdNodeTablePut(c.globals, s, result)
          return result
      
      result = s.ast
      if result == nil or result.kind == nkEmpty:
        result = getNullValue(s.typ, s.info)
      else:
        result = evalAux(c, result, {})
        if isSpecial(result): return
      IdNodeTablePut(c.globals, s, result)
  else:
    result = raiseCannotEval(nil, s.info)

proc optBody(c: PEvalContext, s: PSym): PNode =
  result = s.getBody

proc evalCall(c: PEvalContext, n: PNode): PNode = 
  var d = newStackFrame()
  d.call = n
  var prc = n.sons[0]
  let isClosure = prc.kind == nkClosure
  setlen(d.slots, sonsLen(n) + ord(isClosure))
  if isClosure:
    #debug prc
    evalX(prc.sons[1], {efLValue})
    d.slots[sonsLen(n)] = result
    result = evalAux(c, prc.sons[0], {})
  else:
    result = evalAux(c, prc, {})

  if isSpecial(result): return 
  prc = result
  # bind the actual params to the local parameter of a new binding
  if prc.kind != nkSym: 
    InternalError(n.info, "evalCall " & n.renderTree)
    return
  d.prc = prc.sym
  if prc.sym.kind notin {skProc, skConverter, skMacro}:
    InternalError(n.info, "evalCall")
    return
  for i in countup(1, sonsLen(n) - 1): 
    evalX(n.sons[i], {})
    d.slots[i] = result
  if n.typ != nil: d.slots[0] = getNullValue(n.typ, n.info)
  
  when hasFFI:
    if sfImportc in prc.sym.flags and allowFFI in c.features:
      var newCall = newNodeI(nkCall, n.info, n.len)
      newCall.sons[0] = evalGlobalVar(c, prc.sym, {})
      for i in 1 .. <n.len:
        newCall.sons[i] = d.slots[i]
      return callForeignFunction(newCall)
  
  pushStackFrame(c, d)
  evalX(optBody(c, prc.sym), {})
  if n.typ != nil: result = d.slots[0]
  popStackFrame(c)

proc evalArrayAccess(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode = 
  evalX(n.sons[0], flags)
  var x = result
  evalX(n.sons[1], {})
  var idx = getOrdValue(result)
  result = emptyNode
  case x.kind
  of nkPar:
    if (idx >= 0) and (idx < sonsLen(x)): 
      result = x.sons[int(idx)]
      if result.kind == nkExprColonExpr: result = result.sons[1]
      if not aliasNeeded(result, flags): result = copyTree(result)
    else: 
      stackTrace(c, n.info, errIndexOutOfBounds)
  of nkBracket, nkMetaNode: 
    if (idx >= 0) and (idx < sonsLen(x)): 
      result = x.sons[int(idx)]
      if not aliasNeeded(result, flags): result = copyTree(result)
    else: 
      stackTrace(c, n.info, errIndexOutOfBounds)
  of nkStrLit..nkTripleStrLit:
    if efLValue in flags: return raiseCannotEval(c, n.info)
    result = newNodeIT(nkCharLit, x.info, getSysType(tyChar))
    if (idx >= 0) and (idx < len(x.strVal)): 
      result.intVal = ord(x.strVal[int(idx) + 0])
    elif idx == len(x.strVal): 
      nil
    else: 
      stackTrace(c, n.info, errIndexOutOfBounds)
  else: stackTrace(c, n.info, errNilAccess)
  
proc evalFieldAccess(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode =
  # a real field access; proc calls have already been transformed
  # XXX: field checks!
  evalX(n.sons[0], flags)
  var x = result
  if x.kind != nkPar: return raiseCannotEval(c, n.info)
  # this is performance critical:
  var field = n.sons[1].sym
  result = x.sons[field.position]
  if result.kind == nkExprColonExpr: result = result.sons[1]
  if not aliasNeeded(result, flags): result = copyTree(result)

proc evalAsgn(c: PEvalContext, n: PNode): PNode =
  var a = n.sons[0]
  if a.kind == nkBracketExpr and a.sons[0].typ.kind in {tyString, tyCString}: 
    evalX(a.sons[0], {efLValue})
    var x = result
    evalX(a.sons[1], {})
    var idx = getOrdValue(result)

    evalX(n.sons[1], {})
    if result.kind notin {nkIntLit, nkCharLit}: return c.raiseCannotEval(n.info)

    if idx >= 0 and idx < len(x.strVal):
      x.strVal[int(idx)] = chr(int(result.intVal))
    else:
      stackTrace(c, n.info, errIndexOutOfBounds)
  else:
    evalX(n.sons[0], {efLValue})
    var x = result
    evalX(n.sons[1], {})
    myreset(x)
    x.kind = result.kind
    x.typ = result.typ
    case x.kind
    of nkCharLit..nkInt64Lit: x.intVal = result.intVal
    of nkFloatLit..nkFloat64Lit: x.floatVal = result.floatVal
    of nkStrLit..nkTripleStrLit: x.strVal = result.strVal
    of nkIdent: x.ident = result.ident
    of nkSym: x.sym = result.sym
    else:
      if x.kind notin {nkEmpty..nkNilLit}:
        discardSons(x)
        for i in countup(0, sonsLen(result) - 1): addSon(x, result.sons[i])
  result = emptyNode
  assert result.kind == nkEmpty

proc evalSwap(c: PEvalContext, n: PNode): PNode = 
  evalX(n.sons[0], {efLValue})
  var x = result
  evalX(n.sons[1], {efLValue})
  if x.kind != result.kind: 
    stackTrace(c, n.info, errCannotInterpretNodeX, $n.kind)
  else:
    case x.kind
    of nkCharLit..nkInt64Lit: swap(x.intVal, result.intVal)
    of nkFloatLit..nkFloat64Lit: swap(x.floatVal, result.floatVal)
    of nkStrLit..nkTripleStrLit: swap(x.strVal, result.strVal)
    of nkIdent: swap(x.ident, result.ident)
    of nkSym: swap(x.sym, result.sym)    
    else: 
      var tmpn = copyTree(x)
      discardSons(x)
      for i in countup(0, sonsLen(result) - 1): addSon(x, result.sons[i])
      discardSons(result)
      for i in countup(0, sonsLen(tmpn) - 1): addSon(result, tmpn.sons[i])
  result = emptyNode
  
proc evalSym(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode = 
  var s = n.sym
  case s.kind
  of skProc, skConverter, skMacro, skType:
    result = n
    #result = s.getBody
  of skVar, skLet, skForVar, skTemp, skResult:
    if sfGlobal notin s.flags:
      result = evalVariable(c.tos, s, flags)
    else:
      result = evalGlobalVar(c, s, flags)
  of skParam:
    # XXX what about LValue?
    if s.position + 1 <% c.tos.slots.len:
      result = c.tos.slots[s.position + 1]
  of skConst: result = s.ast
  of skEnumField: result = newIntNodeT(s.position, n)
  else: result = nil
  let mask = if hasFFI and allowFFI in c.features: {sfForward}
             else: {sfImportc, sfForward}
  if result == nil or mask * s.flags != {}:
    result = raiseCannotEval(c, n.info)

proc evalIncDec(c: PEvalContext, n: PNode, sign: biggestInt): PNode = 
  evalX(n.sons[1], {efLValue})
  var a = result
  evalX(n.sons[2], {})
  var b = result
  case a.kind
  of nkCharLit..nkInt64Lit: a.intval = a.intVal + sign * getOrdValue(b)
  else: return raiseCannotEval(c, n.info)
  result = emptyNode

proc getStrValue(n: PNode): string = 
  case n.kind
  of nkStrLit..nkTripleStrLit: result = n.strVal
  else: 
    InternalError(n.info, "getStrValue")
    result = ""

proc evalEcho(c: PEvalContext, n: PNode): PNode = 
  for i in countup(1, sonsLen(n) - 1): 
    evalX(n.sons[i], {})
    Write(stdout, getStrValue(result))
  writeln(stdout, "")
  result = emptyNode

proc evalExit(c: PEvalContext, n: PNode): PNode = 
  if c.mode in {emRepl, emStatic}:
    evalX(n.sons[1], {})
    Message(n.info, hintQuitCalled)
    quit(int(getOrdValue(result)))
  else:
    result = raiseCannotEval(c, n.info)

proc evalOr(c: PEvalContext, n: PNode): PNode = 
  evalX(n.sons[1], {})
  if result.intVal == 0: result = evalAux(c, n.sons[2], {})
  
proc evalAnd(c: PEvalContext, n: PNode): PNode = 
  evalX(n.sons[1], {})
  if result.intVal != 0: result = evalAux(c, n.sons[2], {})
  
proc evalNew(c: PEvalContext, n: PNode): PNode = 
  #if c.mode == emOptimize: return raiseCannotEval(c, n.info)
  
  # we ignore the finalizer for now and most likely forever :-)
  evalX(n.sons[1], {efLValue})
  var a = result
  var t = skipTypes(n.sons[1].typ, abstractVar)
  if a.kind == nkEmpty: InternalError(n.info, "first parameter is empty")
  myreset(a)
  let u = getNullValue(t.sons[0], n.info)
  a.kind = u.kind
  a.typ = t
  shallowCopy(a.sons, u.sons)
  result = emptyNode
  when false:
    a.kind = nkRefTy
    a.info = n.info
    a.typ = t
    a.sons = nil
    addSon(a, getNullValue(t.sons[0], n.info))
    result = emptyNode

proc evalDeref(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode = 
  evalX(n.sons[0], {efLValue})
  case result.kind
  of nkNilLit: stackTrace(c, n.info, errNilAccess)
  of nkRefTy: 
    # XXX efLValue?
    result = result.sons[0]
  else:
    if skipTypes(n.sons[0].typ, abstractInst).kind != tyRef:
      result = raiseCannotEval(c, n.info)
  
proc evalAddr(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode = 
  evalX(n.sons[0], {efLValue})
  var a = result
  var t = newType(tyPtr, c.module)
  addSonSkipIntLit(t, a.typ)
  result = newNodeIT(nkRefTy, n.info, t)
  addSon(result, a)

proc evalConv(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return
  if result.typ != nil:
    var a = result
    result = foldConv(n, a)
    if result == nil: 
      # foldConv() cannot deal with everything that we want to do here:
      result = a

proc evalCast(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode =
  if allowCast in c.features:
    when hasFFI:
      result = evalAux(c, n.sons[1], {efLValue})
      if isSpecial(result): return
      InternalAssert result.typ != nil
      result = fficast(result, n.typ)
    else:
      result = evalConv(c, n)
  else:
    result = raiseCannotEval(c, n.info)

proc evalCheckedFieldAccess(c: PEvalContext, n: PNode, 
                            flags: TEvalFlags): PNode = 
  result = evalAux(c, n.sons[0], flags)

proc evalUpConv(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode = 
  result = evalAux(c, n.sons[0], flags)
  if isSpecial(result): return 
  var dest = skipTypes(n.typ, abstractPtrs)
  var src = skipTypes(result.typ, abstractPtrs)
  if inheritanceDiff(src, dest) > 0: 
    stackTrace(c, n.info, errInvalidConversionFromTypeX, typeToString(src))
  
proc evalRangeChck(c: PEvalContext, n: PNode): PNode = 
  evalX(n.sons[0], {})
  var x = result
  evalX(n.sons[1], {})
  var a = result
  evalX(n.sons[2], {})
  var b = result
  if leValueConv(a, x) and leValueConv(x, b): 
    result = x                # a <= x and x <= b
    result.typ = n.typ
  else: 
    stackTrace(c, n.info, errGenerated, 
      msgKindToString(errIllegalConvFromXtoY) % [
      typeToString(n.sons[0].typ), typeToString(n.typ)])
  
proc evalConvStrToCStr(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[0], {})
  if isSpecial(result): return 
  result.typ = n.typ

proc evalConvCStrToStr(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[0], {})
  if isSpecial(result): return 
  result.typ = n.typ

proc evalRaise(c: PEvalContext, n: PNode): PNode = 
  if c.mode in {emRepl, emStatic}:
    if n.sons[0].kind != nkEmpty: 
      result = evalAux(c, n.sons[0], {})
      if isSpecial(result): return 
      var a = result
      result = newNodeIT(nkExceptBranch, n.info, a.typ)
      addSon(result, a)
      c.lastException = result
    elif c.lastException != nil: 
      result = c.lastException
    else: 
      stackTrace(c, n.info, errExceptionAlreadyHandled)
      result = newNodeIT(nkExceptBranch, n.info, nil)
      addSon(result, ast.emptyNode)
  else:
    result = raiseCannotEval(c, n.info)

proc evalReturn(c: PEvalContext, n: PNode): PNode = 
  if n.sons[0].kind != nkEmpty: 
    result = evalAsgn(c, n.sons[0])
    if isSpecial(result): return 
  result = newNodeIT(nkReturnToken, n.info, nil)

proc evalProc(c: PEvalContext, n: PNode): PNode = 
  if n.sons[genericParamsPos].kind == nkEmpty: 
    var s = n.sons[namePos].sym
    if (resultPos < sonsLen(n)) and (n.sons[resultPos].kind != nkEmpty): 
      var v = n.sons[resultPos].sym
      result = getNullValue(v.typ, n.info)
      if c.tos.slots.len == 0: setLen(c.tos.slots, 1)
      c.tos.slots[0] = result
      #IdNodeTablePut(c.tos.mapping, v, result)
      result = evalAux(c, s.getBody, {})
      if result.kind == nkReturnToken:
        result = c.tos.slots[0]
    else:
      result = evalAux(c, s.getBody, {})
      if result.kind == nkReturnToken: 
        result = emptyNode
  else: 
    result = emptyNode
  
proc evalHigh(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {})
  if isSpecial(result): return 
  case skipTypes(n.sons[1].typ, abstractVar).kind
  of tyOpenArray, tySequence, tyVarargs: 
    result = newIntNodeT(sonsLen(result)-1, n)
  of tyString: result = newIntNodeT(len(result.strVal) - 1, n)
  else: InternalError(n.info, "evalHigh")

proc evalOf(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {})
  if isSpecial(result): return 
  result = newIntNodeT(ord(inheritanceDiff(result.typ, n.sons[2].typ) >= 0), n)

proc evalSetLengthStr(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = result
  case a.kind
  of nkStrLit..nkTripleStrLit: 
    var newLen = int(getOrdValue(b))
    setlen(a.strVal, newLen)
  else: InternalError(n.info, "evalSetLengthStr")
  result = emptyNode

proc evalSetLengthSeq(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = result
  if a.kind != nkBracket: 
    InternalError(n.info, "evalSetLengthSeq")
    return
  var newLen = int(getOrdValue(b))
  var oldLen = sonsLen(a)
  setlen(a.sons, newLen)
  for i in countup(oldLen, newLen - 1): 
    a.sons[i] = getNullValue(skipTypes(n.sons[1].typ, abstractVar), n.info)
  result = emptyNode

proc evalNewSeq(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = result
  var t = skipTypes(n.sons[1].typ, abstractVar)
  if a.kind == nkEmpty: InternalError(n.info, "first parameter is empty")
  myreset(a)
  a.kind = nkBracket
  a.info = n.info
  a.typ = t
  a.sons = nil
  var L = int(getOrdValue(b))
  newSeq(a.sons, L)
  for i in countup(0, L-1): 
    a.sons[i] = getNullValue(t.sons[0], n.info)
  result = emptyNode
 
proc evalIncl(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = result
  if not inSet(a, b): addSon(a, copyTree(b))
  result = emptyNode

proc evalExcl(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = newNodeIT(nkCurly, n.info, n.sons[1].typ)
  addSon(b, result)
  var r = diffSets(a, b)
  discardSons(a)
  for i in countup(0, sonsLen(r) - 1): addSon(a, r.sons[i])
  result = emptyNode

proc evalAppendStrCh(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = result
  case a.kind
  of nkStrLit..nkTripleStrLit: add(a.strVal, chr(int(getOrdValue(b))))
  else: return raiseCannotEval(c, n.info)
  result = emptyNode

proc evalConStrStr(c: PEvalContext, n: PNode): PNode = 
  # we cannot use ``evalOp`` for this as we can here have more than 2 arguments
  var a = newNodeIT(nkStrLit, n.info, n.typ)
  a.strVal = ""
  for i in countup(1, sonsLen(n) - 1): 
    result = evalAux(c, n.sons[i], {})
    if isSpecial(result): return 
    a.strVal.add(getStrOrChar(result))
  result = a

proc evalAppendStrStr(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = result
  case a.kind
  of nkStrLit..nkTripleStrLit: a.strVal = a.strVal & getStrOrChar(b)
  else: return raiseCannotEval(c, n.info)
  result = emptyNode

proc evalAppendSeqElem(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = result
  if a.kind == nkBracket: addSon(a, copyTree(b))
  else: return raiseCannotEval(c, n.info)
  result = emptyNode

proc evalRepr(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {})
  if isSpecial(result): return 
  result = newStrNodeT(renderTree(result, {renderNoComments}), n)

proc isEmpty(n: PNode): bool =
  result = n != nil and n.kind == nkEmpty

proc evalParseExpr(c: PEvalContext, n: PNode): PNode =
  var code = evalAux(c, n.sons[1], {})
  var ast = parseString(code.getStrValue, code.info.toFilename,
                        code.info.line.int)
  if sonsLen(ast) != 1:
    GlobalError(code.info, errExprExpected, "multiple statements")
  result = ast.sons[0]
  #result.typ = newType(tyExpr, c.module)

proc evalParseStmt(c: PEvalContext, n: PNode): PNode =
  var code = evalAux(c, n.sons[1], {})
  result = parseString(code.getStrValue, code.info.toFilename,
                       code.info.line.int)
  #result.typ = newType(tyStmt, c.module)
 
proc evalTypeTrait*(trait, operand: PNode, context: PSym): PNode =
  InternalAssert operand.kind == nkSym

  let typ = operand.sym.typ.skipTypes({tyTypeDesc})
  case trait.sym.name.s.normalize
  of "name":
    result = newStrNode(nkStrLit, typ.typeToString(preferName))
    result.typ = newType(tyString, context)
    result.info = trait.info
  else:
    internalAssert false

proc expectString(n: PNode) =
  if n.kind notin nkStrKinds:
    GlobalError(n.info, errStringLiteralExpected)

proc evalSlurp*(e: PNode, module: PSym): PNode =
  expectString(e)
  result = newNodeIT(nkStrLit, e.info, getSysType(tyString))
  try:
    var filename = e.strVal.FindFile
    result.strVal = readFile(filename)
    # we produce a fake include statement for every slurped filename, so that
    # the module dependencies are accurate:    
    appendToModule(module, newNode(nkIncludeStmt, e.info, @[
      newStrNode(nkStrLit, filename)]))
  except EIO:
    result.strVal = ""
    LocalError(e.info, errCannotOpenFile, e.strVal)

proc readOutput(p: PProcess): string =
  result = ""
  var output = p.outputStream
  discard p.waitForExit
  while not output.atEnd:
    result.add(output.readLine)

proc evalStaticExec*(cmd, input: PNode): PNode =
  expectString(cmd)
  var p = startCmd(cmd.strVal)
  if input != nil:
    expectString(input)
    p.inputStream.write(input.strVal)
    p.inputStream.close()
  result = newStrNode(nkStrLit, p.readOutput)
  result.typ = getSysType(tyString)
  result.info = cmd.info

proc evalExpandToAst(c: PEvalContext, original: PNode): PNode =
  var
    n = original.copyTree
    macroCall = n.sons[1]
    expandedSym = macroCall.sons[0].sym

  for i in countup(1, macroCall.sonsLen - 1):
    macroCall.sons[i] = evalAux(c, macroCall.sons[i], {})

  case expandedSym.kind
  of skTemplate:
    let genSymOwner = if c.tos != nil and c.tos.prc != nil:
                        c.tos.prc 
                      else:
                        c.module
    result = evalTemplate(macroCall, expandedSym, genSymOwner)
  of skMacro:
    # At this point macroCall.sons[0] is nkSym node.
    # To be completely compatible with normal macro invocation,
    # we want to replace it with nkIdent node featuring
    # the original unmangled macro name.
    macroCall.sons[0] = newIdentNode(expandedSym.name, expandedSym.info)
    result = evalMacroCall(c, macroCall, original, expandedSym)
  else:
    InternalError(macroCall.info,
      "ExpandToAst: expanded symbol is no macro or template")
    result = emptyNode

proc evalMagicOrCall(c: PEvalContext, n: PNode): PNode = 
  var m = getMagic(n)
  case m
  of mNone: result = evalCall(c, n)
  of mOf: result = evalOf(c, n)
  of mSizeOf: result = raiseCannotEval(c, n.info)
  of mHigh: result = evalHigh(c, n)
  of mExit: result = evalExit(c, n)
  of mNew, mNewFinalize: result = evalNew(c, n)
  of mNewSeq: result = evalNewSeq(c, n)
  of mSwap: result = evalSwap(c, n)
  of mInc: result = evalIncDec(c, n, 1)
  of ast.mDec: result = evalIncDec(c, n, - 1)
  of mEcho: result = evalEcho(c, n)
  of mSetLengthStr: result = evalSetLengthStr(c, n)
  of mSetLengthSeq: result = evalSetLengthSeq(c, n)
  of mIncl: result = evalIncl(c, n)
  of mExcl: result = evalExcl(c, n)
  of mAnd: result = evalAnd(c, n)
  of mOr: result = evalOr(c, n)
  of mAppendStrCh: result = evalAppendStrCh(c, n)
  of mAppendStrStr: result = evalAppendStrStr(c, n)
  of mAppendSeqElem: result = evalAppendSeqElem(c, n)
  of mParseExprToAst: result = evalParseExpr(c, n)
  of mParseStmtToAst: result = evalParseStmt(c, n)
  of mExpandToAst: result = evalExpandToAst(c, n)
  of mTypeTrait:
    let operand = evalAux(c, n.sons[1], {})
    result = evalTypeTrait(n[0], operand, c.module)
  of mIs:
    n.sons[1] = evalAux(c, n.sons[1], {})
    result = c.handleIsOperator(n)
  of mSlurp: result = evalSlurp(evalAux(c, n.sons[1], {}), c.module)
  of mStaticExec:
    let cmd = evalAux(c, n.sons[1], {})
    let input = if n.sonsLen == 3: evalAux(c, n.sons[2], {}) else: nil
    result = evalStaticExec(cmd, input)
  of mNLen:
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = newNodeIT(nkIntLit, n.info, n.typ)
    case a.kind
    of nkEmpty..nkNilLit: nil
    else: result.intVal = sonsLen(a)
  of mNChild:
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    var k = getOrdValue(result)
    if not (a.kind in {nkEmpty..nkNilLit}) and (k >= 0) and (k < sonsLen(a)): 
      result = a.sons[int(k)]
      if result == nil: result = newNode(nkEmpty)
    else: 
      stackTrace(c, n.info, errIndexOutOfBounds)
      result = emptyNode
  of mNSetChild: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    var b = result
    result = evalAux(c, n.sons[3], {efLValue})
    if isSpecial(result): return 
    var k = getOrdValue(b)
    if (k >= 0) and (k < sonsLen(a)) and not (a.kind in {nkEmpty..nkNilLit}): 
      a.sons[int(k)] = result
    else: 
      stackTrace(c, n.info, errIndexOutOfBounds)
    result = emptyNode
  of mNAdd: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    addSon(a, result)
    result = a
  of mNAddMultiple: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    for i in countup(0, sonsLen(result) - 1): addSon(a, result.sons[i])
    result = a
  of mNDel: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    var b = result
    result = evalAux(c, n.sons[3], {efLValue})
    if isSpecial(result): return 
    for i in countup(0, int(getOrdValue(result)) - 1): 
      delSon(a, int(getOrdValue(b)))
    result = emptyNode
  of mNKind: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var a = result
    result = newNodeIT(nkIntLit, n.info, n.typ)
    result.intVal = ord(a.kind)
  of mNIntVal: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var a = result
    result = newNodeIT(nkIntLit, n.info, n.typ)
    case a.kind
    of nkCharLit..nkInt64Lit: result.intVal = a.intVal
    else: stackTrace(c, n.info, errFieldXNotFound, "intVal")
  of mNFloatVal: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var a = result
    result = newNodeIT(nkFloatLit, n.info, n.typ)
    case a.kind
    of nkFloatLit..nkFloat64Lit: result.floatVal = a.floatVal
    else: stackTrace(c, n.info, errFieldXNotFound, "floatVal")
  of mNSymbol: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    if result.kind != nkSym: stackTrace(c, n.info, errFieldXNotFound, "symbol")
  of mNIdent: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    if result.kind != nkIdent: stackTrace(c, n.info, errFieldXNotFound, "ident")
  of mNGetType:
    var ast = evalAux(c, n.sons[1], {})
    InternalAssert c.getType != nil
    result = c.getType(ast)
  of mNStrVal: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var a = result
    result = newNodeIT(nkStrLit, n.info, n.typ)
    case a.kind
    of nkStrLit..nkTripleStrLit: result.strVal = a.strVal
    else: stackTrace(c, n.info, errFieldXNotFound, "strVal")
  of mNSetIntVal: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {})
    if isSpecial(result): return
    if a.kind in {nkCharLit..nkInt64Lit} and 
        result.kind in {nkCharLit..nkInt64Lit}:
      a.intVal = result.intVal
    else: 
      stackTrace(c, n.info, errFieldXNotFound, "intVal")
    result = emptyNode
  of mNSetFloatVal: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {})
    if isSpecial(result): return 
    if a.kind in {nkFloatLit..nkFloat64Lit} and
        result.kind in {nkFloatLit..nkFloat64Lit}:
      a.floatVal = result.floatVal
    else:
      stackTrace(c, n.info, errFieldXNotFound, "floatVal")
    result = emptyNode
  of mNSetSymbol: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    if a.kind == nkSym and result.kind == nkSym:
      a.sym = result.sym
    else:
      stackTrace(c, n.info, errFieldXNotFound, "symbol")
    result = emptyNode
  of mNSetIdent: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    if a.kind == nkIdent and result.kind == nkIdent:
      a.ident = result.ident
    else:
      stackTrace(c, n.info, errFieldXNotFound, "ident")
    result = emptyNode
  of mNSetType: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    InternalAssert result.kind == nkSym and result.sym.kind == skType
    a.typ = result.sym.typ
    result = emptyNode
  of mNSetStrVal:
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {})
    if isSpecial(result): return
    
    if a.kind in {nkStrLit..nkTripleStrLit} and
        result.kind in {nkStrLit..nkTripleStrLit}:
      a.strVal = result.strVal
    else: stackTrace(c, n.info, errFieldXNotFound, "strVal")
    result = emptyNode
  of mNNewNimNode: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var k = getOrdValue(result)
    result = evalAux(c, n.sons[2], {efLValue})
    if result.kind == nkExceptBranch: return 
    var a = result
    if k < 0 or k > ord(high(TNodeKind)): 
      internalError(n.info, "request to create a NimNode with invalid kind")
    result = newNodeI(TNodeKind(int(k)), 
      if a.kind == nkNilLit: n.info else: a.info)
  of mNCopyNimNode:
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    result = copyNode(result)
  of mNCopyNimTree: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    result = copyTree(result)
  of mNBindSym:
    # trivial implementation:
    result = n.sons[1]
  of mNGenSym:
    evalX(n.sons[1], {efLValue})
    let k = getOrdValue(result)
    evalX(n.sons[2], {efLValue})
    let b = result
    let name = if b.strVal.len == 0: ":tmp" else: b.strVal
    if k < 0 or k > ord(high(TSymKind)):
      internalError(n.info, "request to create a symbol with invalid kind")
    result = newSymNode(newSym(k.TSymKind, name.getIdent, c.module, n.info))
    incl(result.sym.flags, sfGenSym)
  of mStrToIdent: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    if not (result.kind in {nkStrLit..nkTripleStrLit}): 
      stackTrace(c, n.info, errFieldXNotFound, "strVal")
      return
    var a = result
    result = newNodeIT(nkIdent, n.info, n.typ)
    result.ident = getIdent(a.strVal)
  of mIdentToStr: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var a = result
    result = newNodeIT(nkStrLit, n.info, n.typ)
    if a.kind == nkSym:
      result.strVal = a.sym.name.s
    else:
      if a.kind != nkIdent: InternalError(n.info, "no ident node")
      result.strVal = a.ident.s
  of mEqIdent: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {})
    if isSpecial(result): return 
    var b = result
    result = newNodeIT(nkIntLit, n.info, n.typ)
    if (a.kind == nkIdent) and (b.kind == nkIdent): 
      if a.ident.id == b.ident.id: result.intVal = 1
  of mEqNimrodNode: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    var b = result
    result = newNodeIT(nkIntLit, n.info, n.typ)
    if (a == b) or
        (b.kind in {nkNilLit, nkEmpty}) and (a.kind in {nkNilLit, nkEmpty}): 
      result.intVal = 1
  of mNLineInfo:
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return
    result = newStrNodeT(result.info.toFileLineCol, n)
  of mNHint: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    Message(n.info, hintUser, getStrValue(result))
    result = emptyNode
  of mNWarning: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    Message(n.info, warnUser, getStrValue(result))
    result = emptyNode
  of mNError: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    stackTrace(c, n.info, errUser, getStrValue(result))
    result = emptyNode
  of mConStrStr: 
    result = evalConStrStr(c, n)
  of mRepr: 
    result = evalRepr(c, n)
  of mNewString: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var a = result
    result = newNodeIT(nkStrLit, n.info, n.typ)
    result.strVal = newString(int(getOrdValue(a)))
  of mNewStringOfCap:
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var a = result
    result = newNodeIT(nkStrLit, n.info, n.typ)
    result.strVal = newString(0)
  of mNCallSite:
    if c.callsite != nil: result = c.callsite
    else: stackTrace(c, n.info, errFieldXNotFound, "callsite")
  else:
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var a = result
    var b: PNode = nil
    var cc: PNode = nil
    if sonsLen(n) > 2: 
      result = evalAux(c, n.sons[2], {})
      if isSpecial(result): return 
      b = result
      if sonsLen(n) > 3: 
        result = evalAux(c, n.sons[3], {})
        if isSpecial(result): return 
        cc = result
    if isEmpty(a) or isEmpty(b) or isEmpty(cc): result = emptyNode
    else: result = evalOp(m, n, a, b, cc)

proc evalAux(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode =   
  result = emptyNode
  dec(gNestedEvals)
  if gNestedEvals <= 0: stackTrace(c, n.info, errTooManyIterations)
  case n.kind
  of nkSym: result = evalSym(c, n, flags)
  of nkType..nkNilLit:
    # nkStrLit is VERY common in the traces, so we should avoid
    # the 'copyNode' here.
    result = n #.copyNode
  of nkAsgn, nkFastAsgn: result = evalAsgn(c, n)
  of nkCommand..nkHiddenCallConv:
    result = evalMagicOrCall(c, n)
  of nkDotExpr: result = evalFieldAccess(c, n, flags)
  of nkBracketExpr:
    result = evalArrayAccess(c, n, flags)
  of nkDerefExpr, nkHiddenDeref: result = evalDeref(c, n, flags)
  of nkAddr, nkHiddenAddr: result = evalAddr(c, n, flags)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: result = evalConv(c, n)
  of nkCurly, nkBracket, nkRange:
    # flags need to be passed here for mNAddMultiple :-(
    # XXX this is not correct in every case!
    var a = copyNode(n)
    for i in countup(0, sonsLen(n) - 1): 
      result = evalAux(c, n.sons[i], flags)
      if isSpecial(result): return 
      addSon(a, result)
    result = a
  of nkPar, nkClosure: 
    var a = copyTree(n)
    for i in countup(0, sonsLen(n) - 1): 
      var it = n.sons[i]
      if it.kind == nkExprColonExpr:
        result = evalAux(c, it.sons[1], flags)
        if isSpecial(result): return 
        a.sons[i].sons[1] = result
      else:
        result = evalAux(c, it, flags)
        if isSpecial(result): return 
        a.sons[i] = result
    result = a
  of nkObjConstr:
    let t = skipTypes(n.typ, abstractInst)
    var a: PNode
    if t.kind == tyRef:
      result = newNodeIT(nkRefTy, n.info, t)
      a = getNullValue(t.sons[0], n.info)
      addSon(result, a)
    else:
      a = getNullValue(t, n.info)
      result = a
    for i in countup(1, sonsLen(n) - 1):
      let it = n.sons[i]
      if it.kind == nkExprColonExpr:
        let value = evalAux(c, it.sons[1], flags)
        if isSpecial(value): return value
        a.sons[it.sons[0].sym.position] = value
      else: return raiseCannotEval(c, n.info)
  of nkWhenStmt, nkIfStmt, nkIfExpr: result = evalIf(c, n)
  of nkWhileStmt: result = evalWhile(c, n)
  of nkCaseStmt: result = evalCase(c, n)
  of nkVarSection, nkLetSection: result = evalVar(c, n)
  of nkTryStmt: result = evalTry(c, n)
  of nkRaiseStmt: result = evalRaise(c, n)
  of nkReturnStmt: result = evalReturn(c, n)
  of nkBreakStmt, nkReturnToken: result = n
  of nkBlockExpr, nkBlockStmt: result = evalBlock(c, n)
  of nkDiscardStmt: result = evalAux(c, n.sons[0], {})
  of nkCheckedFieldExpr: result = evalCheckedFieldAccess(c, n, flags)
  of nkObjDownConv: result = evalAux(c, n.sons[0], flags)
  of nkObjUpConv: result = evalUpConv(c, n, flags)
  of nkChckRangeF, nkChckRange64, nkChckRange: result = evalRangeChck(c, n)
  of nkStringToCString: result = evalConvStrToCStr(c, n)
  of nkCStringToString: result = evalConvCStrToStr(c, n)
  of nkStmtListExpr, nkStmtList, nkModule: 
    for i in countup(0, sonsLen(n) - 1): 
      result = evalAux(c, n.sons[i], flags)
      case result.kind
      of nkExceptBranch, nkReturnToken, nkBreakStmt: break 
      else: nil
  of nkProcDef, nkMethodDef, nkMacroDef, nkCommentStmt, nkPragma,
     nkTypeSection, nkTemplateDef, nkConstSection, nkIteratorDef,
     nkConverterDef, nkIncludeStmt, nkImportStmt, nkFromStmt: 
    nil
  of nkMetaNode:
    result = copyTree(n.sons[0])
    result.typ = n.typ
  of nkPragmaBlock:
    result = evalAux(c, n.sons[1], flags)
  of nkCast:
    result = evalCast(c, n, flags)
  of nkIdentDefs, nkYieldStmt, nkAsmStmt, nkForStmt, nkPragmaExpr, 
     nkLambdaKinds, nkContinueStmt, nkIdent, nkParForStmt, nkBindStmt,
     nkClosedSymChoice, nkOpenSymChoice:
    result = raiseCannotEval(c, n.info)
  of nkRefTy:
    result = evalAux(c, n.sons[0], flags)
  of nkEmpty: 
    # nkEmpty occurs once in each trace that I looked at
    result = n
  else: InternalError(n.info, "evalAux: " & $n.kind)
  if result == nil:
    InternalError(n.info, "evalAux: returned nil " & $n.kind)
  inc(gNestedEvals)

proc tryEval(c: PEvalContext, n: PNode): PNode =
  #internalAssert nfTransf in n.flags
  var n = transformExpr(c.module, n)
  gWhileCounter = evalMaxIterations
  gNestedEvals = evalMaxRecDepth
  result = evalAux(c, n, {})
  
proc eval*(c: PEvalContext, n: PNode): PNode = 
  ## eval never returns nil! This simplifies the code a lot and
  ## makes it faster too.
  result = tryEval(c, n)
  if result.kind == nkExceptBranch:
    if sonsLen(result) >= 1: 
      stackTrace(c, n.info, errUnhandledExceptionX, typeToString(result.typ))
    else:
      stackTrace(c, result.info, errCannotInterpretNodeX, renderTree(n))

proc evalConstExprAux(module, prc: PSym, e: PNode, mode: TEvalMode): PNode = 
  var p = newEvalContext(module, mode)
  var s = newStackFrame()
  s.call = e
  s.prc = prc
  pushStackFrame(p, s)
  result = tryEval(p, e)
  if result != nil and result.kind == nkExceptBranch: result = nil
  popStackFrame(p)

proc evalConstExpr*(module: PSym, e: PNode): PNode = 
  result = evalConstExprAux(module, nil, e, emConst)

proc evalStaticExpr*(module: PSym, e: PNode, prc: PSym): PNode = 
  result = evalConstExprAux(module, prc, e, emStatic)

proc setupMacroParam(x: PNode): PNode =
  result = x
  if result.kind == nkHiddenStdConv: result = result.sons[1]

proc evalMacroCall(c: PEvalContext, n, nOrig: PNode, sym: PSym): PNode =
  # XXX GlobalError() is ugly here, but I don't know a better solution for now
  inc(evalTemplateCounter)
  if evalTemplateCounter > 100:
    GlobalError(n.info, errTemplateInstantiationTooNested)

  c.callsite = nOrig
  var s = newStackFrame()
  s.call = n
  s.prc = sym
  var L = n.safeLen
  if L == 0: L = 1
  setlen(s.slots, L)
  # return value:
  s.slots[0] = newNodeIT(nkNilLit, n.info, sym.typ.sons[0])
  # setup parameters:
  for i in 1 .. < L: s.slots[i] = setupMacroParam(n.sons[i])
  pushStackFrame(c, s)
  discard eval(c, optBody(c, sym))
  result = s.slots[0]
  popStackFrame(c)
  if cyclicTree(result): GlobalError(n.info, errCyclicTree)
  dec(evalTemplateCounter)
  c.callsite = nil

proc myOpen(module: PSym): PPassContext =
  var c = newEvalContext(module, emRepl)
  c.features = {allowCast, allowFFI, allowInfiniteLoops}
  pushStackFrame(c, newStackFrame())
  result = c

var oldErrorCount: int

proc myProcess(c: PPassContext, n: PNode): PNode =
  # don't eval errornous code:
  if oldErrorCount == msgs.gErrorCounter:
    result = eval(PEvalContext(c), n)
  else:
    result = n
  oldErrorCount = msgs.gErrorCounter

const evalPass* = makePass(myOpen, nil, myProcess, myProcess)

