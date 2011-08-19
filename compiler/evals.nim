#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
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
  msgs, os, condsyms, idents, renderer, types, passes, semfold, transf

type 
  PStackFrame* = ref TStackFrame
  TStackFrame*{.final.} = object 
    mapping*: TIdNodeTable    # mapping from symbols to nodes
    prc*: PSym                # current prc; proc that is evaluated
    call*: PNode
    next*: PStackFrame        # for stacking
    params*: TNodeSeq         # parameters passed to the proc
  
  TEvalContext* = object of passes.TPassContext
    module*: PSym
    tos*: PStackFrame         # top of stack
    lastException*: PNode
    optEval*: bool            # evaluation done for optimization purposes
  
  PEvalContext* = ref TEvalContext

  TEvalFlag = enum 
    efNone, efLValue
  TEvalFlags = set[TEvalFlag]

const
  evalMaxIterations = 500_000 # max iterations of all loops
  evalMaxRecDepth = 10_000    # max recursion depth for evaluation

# Much better: use a timeout! -> Wether code compiles depends on the machine
# the compiler runs on then! Bad idea!

proc newStackFrame*(): PStackFrame = 
  new(result)
  initIdNodeTable(result.mapping)
  result.params = @[]

proc newEvalContext*(module: PSym, filename: string, 
                     optEval: bool): PEvalContext = 
  new(result)
  result.module = module
  result.optEval = optEval

proc pushStackFrame*(c: PEvalContext, t: PStackFrame) {.inline.} = 
  t.next = c.tos
  c.tos = t

proc popStackFrame*(c: PEvalContext) {.inline.} = 
  if (c.tos == nil): InternalError("popStackFrame")
  c.tos = c.tos.next

proc evalAux(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode

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

proc stackTrace(c: PEvalContext, n: PNode, msg: TMsgKind, arg = "") = 
  MsgWriteln("stack trace: (most recent call last)")
  stackTraceAux(c.tos)
  Fatal(n.info, msg, arg)

proc isSpecial(n: PNode): bool {.inline.} = 
  result = (n.kind == nkExceptBranch) 
  # or (n.kind == nkEmpty)
  # XXX this does not work yet! Better to compile too much than to compile to
  # few programs

proc myreset(n: PNode) {.inline.} =
  when defined(system.reset): reset(n[])

proc evalIf(c: PEvalContext, n: PNode): PNode = 
  var i = 0
  var length = sonsLen(n)
  while (i < length) and (sonsLen(n.sons[i]) >= 2): 
    result = evalAux(c, n.sons[i].sons[0], {})
    if isSpecial(result): return 
    if (result.kind == nkIntLit) and (result.intVal != 0): 
      return evalAux(c, n.sons[i].sons[1], {})
    inc(i)
  if (i < length) and (sonsLen(n.sons[i]) < 2): 
    result = evalAux(c, n.sons[i].sons[0], {})
  else: 
    result = emptyNode
  
proc evalCase(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[0], {})
  if isSpecial(result): return 
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
    result = evalAux(c, n.sons[0], {})
    if isSpecial(result): return 
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
      stackTrace(c, n, errTooManyIterations)
      break 

proc evalBlock(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {})
  if result.kind == nkBreakStmt: 
    if result.sons[0] != nil: 
      assert(result.sons[0].kind == nkSym)
      if n.sons[0].kind != nkEmpty: 
        assert(n.sons[0].kind == nkSym)
        if result.sons[0].sym.id == n.sons[0].sym.id: result = emptyNode
    else: 
      result = emptyNode      # consume ``break`` token
  
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
            if exc.typ.id == n.sons[i].sons[j].typ.id: 
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
  var t = skipTypes(typ, abstractRange)
  result = emptyNode
  case t.kind
  of tyBool, tyEnum, tyChar, tyInt..tyInt64: 
    result = newNodeIT(nkIntLit, info, t)
  of tyFloat..tyFloat128: 
    result = newNodeIt(nkFloatLit, info, t)
  of tyVar, tyPointer, tyPtr, tyRef, tyCString, tySequence, tyString, tyExpr, 
     tyStmt, tyTypeDesc, tyProc:
    result = newNodeIT(nkNilLit, info, t)
  of tyObject: 
    result = newNodeIT(nkPar, info, t)
    getNullValueAux(t.n, result)
  of tyArray, tyArrayConstr: 
    result = newNodeIT(nkBracket, info, t)
    for i in countup(0, int(lengthOrd(t)) - 1): 
      addSon(result, getNullValue(elemType(t), info))
  of tyTuple: 
    result = newNodeIT(nkPar, info, t)
    for i in countup(0, sonsLen(t) - 1): 
      var p = newNodeIT(nkExprColonExpr, info, t.sons[i])
      var field = if t.n != nil: t.n.sons[i].sym else: newSym(
        skField, getIdent(":tmp" & $i), t.owner)
      addSon(p, newSymNode(field, info))
      addSon(p, getNullValue(t.sons[i], info))
      addSon(result, p)
  of tySet:
    result = newNodeIT(nkCurly, info, t)    
  else: InternalError("getNullValue: " & $t.kind)
  
proc evalVar(c: PEvalContext, n: PNode): PNode = 
  for i in countup(0, sonsLen(n) - 1): 
    var a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    assert(a.kind == nkIdentDefs)
    assert(a.sons[0].kind == nkSym)
    var v = a.sons[0].sym
    if a.sons[2].kind != nkEmpty: 
      result = evalAux(c, a.sons[2], {})
      if isSpecial(result): return 
    else: 
      result = getNullValue(a.sons[0].typ, a.sons[0].info)
    IdNodeTablePut(c.tos.mapping, v, result)
  result = emptyNode

proc evalCall(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[0], {})
  if isSpecial(result): return 
  var prc = result
  # bind the actual params to the local parameter of a new binding
  var d = newStackFrame()
  d.call = n
  if prc.kind == nkSym: 
    d.prc = prc.sym
    if not (prc.sym.kind in {skProc, skConverter}): 
      InternalError(n.info, "evalCall")
  setlen(d.params, sonsLen(n))
  for i in countup(1, sonsLen(n) - 1): 
    result = evalAux(c, n.sons[i], {})
    if isSpecial(result): return 
    d.params[i] = result
  if n.typ != nil: d.params[0] = getNullValue(n.typ, n.info)
  pushStackFrame(c, d)
  result = evalAux(c, prc, {})
  if result.kind == nkExceptBranch: return 
  if n.typ != nil: result = d.params[0]
  popStackFrame(c)

proc aliasNeeded(n: PNode, flags: TEvalFlags): bool = 
  result = efLValue in flags or n.typ == nil or 
    n.typ.kind in {tyExpr, tyStmt, tyTypeDesc}

proc evalVariable(c: PStackFrame, sym: PSym, flags: TEvalFlags): PNode = 
  # We need to return a node to the actual value,
  # which can be modified.
  var x = c
  while x != nil: 
    if sym.kind == skResult:
      result = x.params[0]
      if result == nil: result = emptyNode
      return
    result = IdNodeTableGet(x.mapping, sym)
    if result != nil and not aliasNeeded(result, flags): 
      result = copyTree(result)
    if result != nil: return 
    x = x.next
  result = emptyNode

proc evalArrayAccess(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode = 
  result = evalAux(c, n.sons[0], flags)
  if isSpecial(result): return 
  var x = result
  result = evalAux(c, n.sons[1], {})
  if isSpecial(result): return 
  var idx = getOrdValue(result)
  result = emptyNode
  case x.kind
  of nkPar: 
    if (idx >= 0) and (idx < sonsLen(x)): 
      result = x.sons[int(idx)]
      if result.kind == nkExprColonExpr: result = result.sons[1]
    else: stackTrace(c, n, errIndexOutOfBounds)
    if not aliasNeeded(result, flags): result = copyTree(result)
  of nkBracket, nkMetaNode: 
    if (idx >= 0) and (idx < sonsLen(x)): result = x.sons[int(idx)]
    else: stackTrace(c, n, errIndexOutOfBounds)
    if not aliasNeeded(result, flags): result = copyTree(result)
  of nkStrLit..nkTripleStrLit: 
    if efLValue in flags: 
      InternalError(n.info, "cannot evaluate write access to char")
    result = newNodeIT(nkCharLit, x.info, getSysType(tyChar))
    if (idx >= 0) and (idx < len(x.strVal)): 
      result.intVal = ord(x.strVal[int(idx) + 0])
    elif idx == len(x.strVal): 
      nil
    else: 
      stackTrace(c, n, errIndexOutOfBounds)
  else: stackTrace(c, n, errNilAccess)
  
proc evalFieldAccess(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode = 
  # a real field access; proc calls have already been transformed
  # XXX: field checks!
  result = evalAux(c, n.sons[0], flags)
  if isSpecial(result): return 
  var x = result
  if x.kind != nkPar: InternalError(n.info, "evalFieldAccess")
  var field = n.sons[1].sym
  for i in countup(0, sonsLen(x) - 1): 
    var it = x.sons[i]
    if it.kind != nkExprColonExpr: 
      InternalError(it.info, "evalFieldAccess")
    if it.sons[0].sym.name.id == field.name.id: 
      result = x.sons[i].sons[1]
      if not aliasNeeded(result, flags): result = copyTree(result)
      return
  stackTrace(c, n, errFieldXNotFound, field.name.s)
  result = emptyNode

proc evalAsgn(c: PEvalContext, n: PNode): PNode = 
  var a = n.sons[0]
  if a.kind == nkBracketExpr and a.sons[0].typ.kind in {tyString, tyCString}: 
    result = evalAux(c, a.sons[0], {efLValue})
    if isSpecial(result): return 
    var x = result
    result = evalAux(c, a.sons[1], {})
    if isSpecial(result): return 
    var idx = getOrdValue(result)

    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return
    if result.kind != nkCharLit: InternalError(n.info, "no character")

    if (idx >= 0) and (idx < len(x.strVal)): 
      x.strVal[int(idx)] = chr(int(result.intVal))
    else: 
      stackTrace(c, n, errIndexOutOfBounds)
  else:
    result = evalAux(c, n.sons[0], {efLValue})
    if isSpecial(result): return 
    var x = result
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    myreset(x)
    x.kind = result.kind
    x.typ = result.typ
    case x.kind
    of nkCharLit..nkInt64Lit: x.intVal = result.intVal
    of nkFloatLit..nkFloat64Lit: x.floatVal = result.floatVal
    of nkStrLit..nkTripleStrLit: x.strVal = result.strVal
    else:
      if not (x.kind in {nkEmpty..nkNilLit}): 
        discardSons(x)
        for i in countup(0, sonsLen(result) - 1): addSon(x, result.sons[i])
  result = emptyNode
  assert result.kind == nkEmpty

proc evalSwap(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[0], {efLValue})
  if isSpecial(result): return 
  var x = result
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  if (x.kind != result.kind): 
    stackTrace(c, n, errCannotInterpretNodeX, $n.kind)
  else: 
    case x.kind
    of nkCharLit..nkInt64Lit: 
      var tmpi = x.intVal
      x.intVal = result.intVal
      result.intVal = tmpi
    of nkFloatLit..nkFloat64Lit: 
      var tmpf = x.floatVal
      x.floatVal = result.floatVal
      result.floatVal = tmpf
    of nkStrLit..nkTripleStrLit: 
      var tmps = x.strVal
      x.strVal = result.strVal
      result.strVal = tmps
    else: 
      var tmpn = copyTree(x)
      discardSons(x)
      for i in countup(0, sonsLen(result) - 1): addSon(x, result.sons[i])
      discardSons(result)
      for i in countup(0, sonsLen(tmpn) - 1): addSon(result, tmpn.sons[i])
  result = emptyNode

proc evalSym(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode = 
  case n.sym.kind
  of skProc, skConverter, skMacro: result = n.sym.ast.sons[codePos]
  of skVar, skForVar, skTemp, skResult: 
    result = evalVariable(c.tos, n.sym, flags)
  of skParam: 
    # XXX what about LValue?
    result = c.tos.params[n.sym.position + 1]
  of skConst: result = n.sym.ast
  of skEnumField: result = newIntNodeT(n.sym.position, n)
  else: 
    stackTrace(c, n, errCannotInterpretNodeX, $n.sym.kind)
    result = emptyNode
  if result == nil: stackTrace(c, n, errCannotInterpretNodeX, n.sym.name.s)
  
proc evalIncDec(c: PEvalContext, n: PNode, sign: biggestInt): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = result
  case a.kind
  of nkCharLit..nkInt64Lit: a.intval = a.intVal + sign * getOrdValue(b)
  else: internalError(n.info, "evalIncDec")
  result = emptyNode

proc getStrValue(n: PNode): string = 
  case n.kind
  of nkStrLit..nkTripleStrLit: result = n.strVal
  else: 
    InternalError(n.info, "getStrValue")
    result = ""

proc evalEcho(c: PEvalContext, n: PNode): PNode = 
  for i in countup(1, sonsLen(n) - 1): 
    result = evalAux(c, n.sons[i], {})
    if isSpecial(result): return 
    Write(stdout, getStrValue(result))
  writeln(stdout, "")
  result = emptyNode

proc evalExit(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {})
  if isSpecial(result): return 
  Message(n.info, hintQuitCalled)
  quit(int(getOrdValue(result)))

proc evalOr(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {})
  if isSpecial(result): return 
  if result.kind != nkIntLit: InternalError(n.info, "evalOr")
  if result.intVal == 0: result = evalAux(c, n.sons[2], {})
  
proc evalAnd(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {})
  if isSpecial(result): return 
  if result.kind != nkIntLit: InternalError(n.info, "evalAnd")
  if result.intVal != 0: result = evalAux(c, n.sons[2], {})
  
proc evalNoOpt(c: PEvalContext, n: PNode): PNode = 
  result = newNodeI(nkExceptBranch, n.info) 
  # creating a nkExceptBranch without sons 
  # means that it could not be evaluated
  
proc evalNew(c: PEvalContext, n: PNode): PNode = 
  if c.optEval: return evalNoOpt(c, n)
  # we ignore the finalizer for now and most likely forever :-)
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  var t = skipTypes(n.sons[1].typ, abstractVar)
  if a.kind == nkEmpty: InternalError(n.info, "first parameter is empty")
  myreset(a)
  a.kind = nkRefTy
  a.info = n.info
  a.typ = t
  a.sons = nil
  addSon(a, getNullValue(t.sons[0], n.info))
  result = emptyNode

proc evalDeref(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode = 
  result = evalAux(c, n.sons[0], {efLValue})
  if isSpecial(result): return 
  case result.kind
  of nkNilLit: stackTrace(c, n, errNilAccess)
  of nkRefTy: 
    # XXX efLValue?
    result = result.sons[0]
  else: InternalError(n.info, "evalDeref " & $result.kind)
  
proc evalAddr(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode = 
  result = evalAux(c, n.sons[0], {efLValue})
  if isSpecial(result): return 
  var a = result
  var t = newType(tyPtr, c.module)
  addSon(t, a.typ)
  result = newNodeIT(nkRefTy, n.info, t)
  addSon(result, a)

proc evalConv(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return
  var a = result
  result = foldConv(n, a)
  if result == nil: 
    # foldConv() cannot deal with everything that we want to do here:
    result = a

proc evalCheckedFieldAccess(c: PEvalContext, n: PNode, 
                            flags: TEvalFlags): PNode = 
  result = evalAux(c, n.sons[0], flags)

proc evalUpConv(c: PEvalContext, n: PNode, flags: TEvalFlags): PNode = 
  result = evalAux(c, n.sons[0], flags)
  if isSpecial(result): return 
  var dest = skipTypes(n.typ, abstractPtrs)
  var src = skipTypes(result.typ, abstractPtrs)
  if inheritanceDiff(src, dest) > 0: 
    stackTrace(c, n, errInvalidConversionFromTypeX, typeToString(src))
  
proc evalRangeChck(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[0], {})
  if isSpecial(result): return 
  var x = result
  result = evalAux(c, n.sons[1], {})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = result
  if leValueConv(a, x) and leValueConv(x, b): 
    result = x                # a <= x and x <= b
    result.typ = n.typ
  else: 
    stackTrace(c, n, errGenerated, msgKindToString(errIllegalConvFromXtoY) % [
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
    stackTrace(c, n, errExceptionAlreadyHandled)
    result = newNodeIT(nkExceptBranch, n.info, nil)
    addSon(result, ast.emptyNode)

proc evalReturn(c: PEvalContext, n: PNode): PNode = 
  if n.sons[0].kind != nkEmpty: 
    result = evalAsgn(c, n.sons[0])
    if isSpecial(result): return 
  result = newNodeIT(nkReturnToken, n.info, nil)

proc evalProc(c: PEvalContext, n: PNode): PNode = 
  if n.sons[genericParamsPos].kind == nkEmpty: 
    if (resultPos < sonsLen(n)) and (n.sons[resultPos].kind != nkEmpty): 
      var v = n.sons[resultPos].sym
      result = getNullValue(v.typ, n.info)
      IdNodeTablePut(c.tos.mapping, v, result)
      result = evalAux(c, n.sons[codePos], {})
      if result.kind == nkReturnToken: 
        result = IdNodeTableGet(c.tos.mapping, v)
    else:
      result = evalAux(c, n.sons[codePos], {})
      if result.kind == nkReturnToken: 
        result = emptyNode
  else: 
    result = emptyNode
  
proc evalHigh(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {})
  if isSpecial(result): return 
  case skipTypes(n.sons[1].typ, abstractVar).kind
  of tyOpenArray, tySequence: result = newIntNodeT(sonsLen(result), n)
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
  if a.kind != nkBracket: InternalError(n.info, "evalSetLengthSeq")
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

proc evalAssert(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {})
  if isSpecial(result): return 
  if getOrdValue(result) != 0: result = emptyNode
  else: stackTrace(c, n, errAssertionFailed)
  
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
  else: InternalError(n.info, "evalAppendStrCh")
  result = emptyNode

proc evalConStrStr(c: PEvalContext, n: PNode): PNode = 
  # we cannot use ``evalOp`` for this as we can here have more than 2 arguments
  var a = newNodeIT(nkStrLit, n.info, n.typ)
  a.strVal = ""
  for i in countup(1, sonsLen(n) - 1): 
    result = evalAux(c, n.sons[i], {})
    if isSpecial(result): return 
    a.strVal.add(getStrValue(result))
  result = a

proc evalAppendStrStr(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = result
  case a.kind
  of nkStrLit..nkTripleStrLit: a.strVal = a.strVal & getStrValue(b)
  else: InternalError(n.info, "evalAppendStrStr")
  result = emptyNode

proc evalAppendSeqElem(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {efLValue})
  if isSpecial(result): return 
  var a = result
  result = evalAux(c, n.sons[2], {})
  if isSpecial(result): return 
  var b = result
  if a.kind == nkBracket: addSon(a, copyTree(b))
  else: InternalError(n.info, "evalAppendSeqElem")
  result = emptyNode

proc evalRepr(c: PEvalContext, n: PNode): PNode = 
  result = evalAux(c, n.sons[1], {})
  if isSpecial(result): return 
  result = newStrNodeT(renderTree(result, {renderNoComments}), n)

proc isEmpty(n: PNode): bool = 
  result = (n != nil) and (n.kind == nkEmpty)

proc evalMagicOrCall(c: PEvalContext, n: PNode): PNode = 
  var m = getMagic(n)
  case m
  of mNone: result = evalCall(c, n)
  of mOf: result = evalOf(c, n)
  of mSizeOf: internalError(n.info, "sizeof() should have been evaluated")
  of mHigh: result = evalHigh(c, n)
  of mAssert: result = evalAssert(c, n)
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
      stackTrace(c, n, errIndexOutOfBounds)
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
      stackTrace(c, n, errIndexOutOfBounds)
    result = emptyNode
  of mNAdd: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    addSon(a, result)
    result = emptyNode
  of mNAddMultiple: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    for i in countup(0, sonsLen(result) - 1): addSon(a, result.sons[i])
    result = emptyNode
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
    else: InternalError(n.info, "no int value")
  of mNFloatVal: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var a = result
    result = newNodeIT(nkFloatLit, n.info, n.typ)
    case a.kind
    of nkFloatLit..nkFloat64Lit: result.floatVal = a.floatVal
    else: InternalError(n.info, "no float value")
  of mNSymbol: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    if result.kind != nkSym: InternalError(n.info, "no symbol")
  of mNIdent: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    if result.kind != nkIdent: InternalError(n.info, "no symbol")
  of mNGetType: result = evalAux(c, n.sons[1], {})
  of mNStrVal: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    var a = result
    result = newNodeIT(nkStrLit, n.info, n.typ)
    case a.kind
    of nkStrLit..nkTripleStrLit: result.strVal = a.strVal
    else: InternalError(n.info, "no string value")
  of mNSetIntVal: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {})
    if isSpecial(result): return 
    a.intVal = result.intVal  # XXX: exception handling?
    result = emptyNode
  of mNSetFloatVal: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {})
    if isSpecial(result): return 
    a.floatVal = result.floatVal # XXX: exception handling?
    result = emptyNode
  of mNSetSymbol: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    a.sym = result.sym        # XXX: exception handling?
    result = emptyNode
  of mNSetIdent: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    a.ident = result.ident    # XXX: exception handling?
    result = emptyNode
  of mNSetType: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {efLValue})
    if isSpecial(result): return 
    a.typ = result.typ        # XXX: exception handling?
    result = emptyNode
  of mNSetStrVal: 
    result = evalAux(c, n.sons[1], {efLValue})
    if isSpecial(result): return 
    var a = result
    result = evalAux(c, n.sons[2], {})
    if isSpecial(result): return 
    a.strVal = result.strVal  # XXX: exception handling?
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
  of mStrToIdent: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    if not (result.kind in {nkStrLit..nkTripleStrLit}): 
      InternalError(n.info, "no string node")
    var a = result
    result = newNodeIT(nkIdent, n.info, n.typ)
    result.ident = getIdent(a.strVal)
  of mIdentToStr: 
    result = evalAux(c, n.sons[1], {})
    if isSpecial(result): return 
    if result.kind != nkIdent: InternalError(n.info, "no ident node")
    var a = result
    result = newNodeIT(nkStrLit, n.info, n.typ)
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
    stackTrace(c, n, errUser, getStrValue(result))
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
  if gNestedEvals <= 0: stackTrace(c, n, errTooManyIterations)
  case n.kind                 # atoms:
  of nkEmpty: result = n
  of nkSym: result = evalSym(c, n, flags)
  of nkType..nkNilLit: result = copyNode(n) # end of atoms
  of nkCall, nkHiddenCallConv, nkMacroStmt, nkCommand, nkCallStrLit: 
    result = evalMagicOrCall(c, n)
  of nkCurly, nkBracket, nkRange: 
    # flags need to be passed here for mNAddMultiple :-(
    # XXX this is not correct in every case!
    var a = copyNode(n)
    for i in countup(0, sonsLen(n) - 1): 
      result = evalAux(c, n.sons[i], flags)
      if isSpecial(result): return 
      addSon(a, result)
    result = a
  of nkPar: 
    var a = copyTree(n)
    for i in countup(0, sonsLen(n) - 1): 
      var it = n.sons[i]
      if it.kind == nkExprEqExpr:
        result = evalAux(c, it.sons[1], flags)
        if isSpecial(result): return 
        a.sons[i].sons[1] = result
      else:
        result = evalAux(c, it, flags)
        if isSpecial(result): return 
        a.sons[i] = result
    result = a
  of nkBracketExpr: result = evalArrayAccess(c, n, flags)
  of nkDotExpr: result = evalFieldAccess(c, n, flags)
  of nkDerefExpr, nkHiddenDeref: result = evalDeref(c, n, flags)
  of nkAddr, nkHiddenAddr: result = evalAddr(c, n, flags)
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: result = evalConv(c, n)
  of nkAsgn, nkFastAsgn: result = evalAsgn(c, n)
  of nkWhenStmt, nkIfStmt, nkIfExpr: result = evalIf(c, n)
  of nkWhileStmt: result = evalWhile(c, n)
  of nkCaseStmt: result = evalCase(c, n)
  of nkVarSection: result = evalVar(c, n)
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
  of nkIdentDefs, nkCast, nkYieldStmt, nkAsmStmt, nkForStmt, nkPragmaExpr, 
     nkLambda, nkContinueStmt, nkIdent: 
    stackTrace(c, n, errCannotInterpretNodeX, $n.kind)
  else: InternalError(n.info, "evalAux: " & $n.kind)
  if result == nil: 
    InternalError(n.info, "evalAux: returned nil " & $n.kind)
  inc(gNestedEvals)

proc eval*(c: PEvalContext, n: PNode): PNode = 
  ## eval never returns nil! This simplifies the code a lot and
  ## makes it faster too.
  var n = transform(c.module, n)
  gWhileCounter = evalMaxIterations
  gNestedEvals = evalMaxRecDepth
  result = evalAux(c, n, {})
  if (result.kind == nkExceptBranch) and (sonsLen(result) >= 1): 
    stackTrace(c, n, errUnhandledExceptionX, typeToString(result.typ))

proc evalConstExpr*(module: PSym, e: PNode): PNode = 
  var p = newEvalContext(module, "", true)
  var s = newStackFrame()
  s.call = e
  pushStackFrame(p, s)
  result = eval(p, e)
  if result != nil and result.kind == nkExceptBranch: result = nil
  popStackFrame(p)

proc myOpen(module: PSym, filename: string): PPassContext = 
  var c = newEvalContext(module, filename, false)
  pushStackFrame(c, newStackFrame())
  result = c

proc myProcess(c: PPassContext, n: PNode): PNode = 
  result = eval(PEvalContext(c), n)

proc evalPass*(): TPass = 
  initPass(result)
  result.open = myOpen
  result.close = myProcess
  result.process = myProcess

