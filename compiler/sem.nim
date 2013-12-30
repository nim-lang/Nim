#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the semantic checking pass.

import
  ast, strutils, hashes, lists, options, lexer, astalgo, trees, treetab,
  wordrecg, ropes, msgs, os, condsyms, idents, renderer, types, platform, math,
  magicsys, parser, nversion, nimsets, semfold, importer,
  procfind, lookups, rodread, pragmas, passes, semdata, semtypinst, sigmatch,
  semthreads, intsets, transf, vmdef, vm, idgen, aliases, cgmeth, lambdalifting,
  evaltempl, patterns, parampatterns, sempass2, pretty

# implementation

proc semExpr(c: PContext, n: PNode, flags: TExprFlags = {}): PNode {.procvar.}
proc semExprWithType(c: PContext, n: PNode, flags: TExprFlags = {}): PNode {.
  procvar.}
proc semExprNoType(c: PContext, n: PNode): PNode
proc semExprNoDeref(c: PContext, n: PNode, flags: TExprFlags = {}): PNode
proc semProcBody(c: PContext, n: PNode): PNode

proc fitNode(c: PContext, formal: PType, arg: PNode): PNode
proc changeType(n: PNode, newType: PType, check: bool)

proc semLambda(c: PContext, n: PNode, flags: TExprFlags): PNode
proc semTypeNode(c: PContext, n: PNode, prev: PType): PType
proc semStmt(c: PContext, n: PNode): PNode
proc semParamList(c: PContext, n, genericParams: PNode, s: PSym)
proc addParams(c: PContext, n: PNode, kind: TSymKind)
proc maybeAddResult(c: PContext, s: PSym, n: PNode)
proc instGenericContainer(c: PContext, n: PNode, header: PType): PType
proc tryExpr(c: PContext, n: PNode,
             flags: TExprFlags = {}, bufferErrors = false): PNode
proc fixImmediateParams(n: PNode): PNode
proc activate(c: PContext, n: PNode)
proc semQuoteAst(c: PContext, n: PNode): PNode
proc finishMethod(c: PContext, s: PSym)

proc indexTypesMatch(c: PContext, f, a: PType, arg: PNode): PNode

proc typeMismatch(n: PNode, formal, actual: PType) = 
  if formal.kind != tyError and actual.kind != tyError: 
    localError(n.info, errGenerated, msgKindToString(errTypeMismatch) &
        typeToString(actual) & ") " &
        `%`(msgKindToString(errButExpectedX), [typeToString(formal)]))

proc fitNode(c: PContext, formal: PType, arg: PNode): PNode =
  if arg.typ.isNil:
    localError(arg.info, errExprXHasNoType,
               renderTree(arg, {renderNoComments}))
    # error correction:
    result = copyNode(arg)
    result.typ = formal
  else:
    result = indexTypesMatch(c, formal, arg.typ, arg)
    if result == nil:
      typeMismatch(arg, formal, arg.typ)
      # error correction:
      result = copyTree(arg)
      result.typ = formal

var commonTypeBegin = PType(kind: tyExpr)

proc commonType*(x, y: PType): PType =
  # new type relation that is used for array constructors,
  # if expressions, etc.:
  if x == nil: return x
  if y == nil: return y
  var a = skipTypes(x, {tyGenericInst})
  var b = skipTypes(y, {tyGenericInst})
  result = x
  if a.kind in {tyExpr, tyNil}: result = y
  elif b.kind in {tyExpr, tyNil}: result = x
  elif a.kind == tyStmt: result = a
  elif b.kind == tyStmt: result = b
  elif a.kind == tyTypeDesc:
    # turn any concrete typedesc into the abstract typedesc type
    if a.sons == nil: result = a
    else: result = newType(tyTypeDesc, a.owner)
  elif b.kind in {tyArray, tyArrayConstr, tySet, tySequence} and 
      a.kind == b.kind:
    # check for seq[empty] vs. seq[int]
    let idx = ord(b.kind in {tyArray, tyArrayConstr})
    if a.sons[idx].kind == tyEmpty: return y
    #elif b.sons[idx].kind == tyEmpty: return x
  elif a.kind == tyRange and b.kind == tyRange:
    # consider:  (range[0..3], range[0..4]) here. We should make that
    # range[0..4]. But then why is (range[0..4], 6) not range[0..6]?
    # But then why is (2,4) not range[2..4]? But I think this would break
    # too much code. So ... it's the same range or the base type. This means
    #  type(if b: 0 else 1) == int and not range[0..1]. For now. In the long
    # run people expect ranges to work properly within a tuple.
    if not sameType(a, b):
      result = skipTypes(a, {tyRange}).skipIntLit
    when false:
      if a.kind != tyRange and b.kind == tyRange:
        # XXX This really needs a better solution, but a proper fix now breaks
        # code.
        result = a #.skipIntLit
      elif a.kind == tyRange and b.kind != tyRange:
        result = b #.skipIntLit
      elif a.kind in IntegralTypes and a.n != nil:
        result = a #.skipIntLit
  else:
    var k = tyNone
    if a.kind in {tyRef, tyPtr}:
      k = a.kind
      if b.kind != a.kind: return x
      a = a.sons[0]
      b = b.sons[0]
    if a.kind == tyObject and b.kind == tyObject:
      result = commonSuperclass(a, b)
      # this will trigger an error later:
      if result.isNil: return x
      if k != tyNone:
        let r = result
        result = newType(k, r.owner)
        result.addSonSkipIntLit(r)

proc isTopLevel(c: PContext): bool {.inline.} = 
  result = c.currentScope.depthLevel <= 2

proc newSymS(kind: TSymKind, n: PNode, c: PContext): PSym = 
  result = newSym(kind, considerAcc(n), getCurrOwner(), n.info)

proc newSymG*(kind: TSymKind, n: PNode, c: PContext): PSym =
  # like newSymS, but considers gensym'ed symbols
  if n.kind == nkSym:
    result = n.sym
    internalAssert sfGenSym in result.flags
    internalAssert result.kind == kind
  else:
    result = newSym(kind, considerAcc(n), getCurrOwner(), n.info)

proc semIdentVis(c: PContext, kind: TSymKind, n: PNode,
                 allowed: TSymFlags): PSym
  # identifier with visability
proc semIdentWithPragma(c: PContext, kind: TSymKind, n: PNode, 
                        allowed: TSymFlags): PSym
proc semStmtScope(c: PContext, n: PNode): PNode

proc paramsTypeCheck(c: PContext, typ: PType) {.inline.} =
  if not typeAllowed(typ, skConst):
    localError(typ.n.info, errXisNoType, typeToString(typ))

proc expectMacroOrTemplateCall(c: PContext, n: PNode): PSym
proc semTemplateExpr(c: PContext, n: PNode, s: PSym, semCheck = true): PNode
proc semDirectOp(c: PContext, n: PNode, flags: TExprFlags): PNode
proc semWhen(c: PContext, n: PNode, semCheck: bool = true): PNode
proc isOpImpl(c: PContext, n: PNode): PNode
proc semMacroExpr(c: PContext, n, nOrig: PNode, sym: PSym,
                  semCheck: bool = true): PNode

proc symFromType(t: PType, info: TLineInfo): PSym =
  if t.sym != nil: return t.sym
  result = newSym(skType, getIdent"AnonType", t.owner, info)
  result.flags.incl sfAnon
  result.typ = t

proc symNodeFromType(c: PContext, t: PType, info: TLineInfo): PNode =
  result = newSymNode(symFromType(t, info), info)
  result.typ = makeTypeDesc(c, t)

when false:
  proc createEvalContext(c: PContext, mode: TEvalMode): PEvalContext =
    result = newEvalContext(c.module, mode)
    result.getType = proc (n: PNode): PNode =
      result = tryExpr(c, n)
      if result == nil:
        result = newSymNode(errorSym(c, n))
      elif result.typ == nil:
        result = newSymNode(getSysSym"void")
      else:
        result.typ = makeTypeDesc(c, result.typ)
    
    result.handleIsOperator = proc (n: PNode): PNode =
      result = isOpImpl(c, n)

proc fixupTypeAfterEval(c: PContext, evaluated, eOrig: PNode): PNode =
  # recompute the types as 'eval' isn't guaranteed to construct types nor
  # that the types are sound:
  result = semExprWithType(c, evaluated)
  #result = fitNode(c, e.typ, result) inlined with special case:
  let arg = result
  result = indexTypesMatch(c, eOrig.typ, arg.typ, arg)
  if result == nil:
    result = arg
    # for 'tcnstseq' we support [] to become 'seq'
    if eOrig.typ.skipTypes(abstractInst).kind == tySequence and 
       arg.typ.skipTypes(abstractInst).kind == tyArrayConstr:
      arg.typ = eOrig.typ

proc tryConstExpr(c: PContext, n: PNode): PNode =
  var e = semExprWithType(c, n)
  if e == nil: return

  result = getConstExpr(c.module, e)
  if result != nil: return

  try:
    result = evalConstExpr(c.module, e)
    if result == nil or result.kind == nkEmpty:
      return nil

    result = fixupTypeAfterEval(c, result, e)
  except:
    return nil

proc semConstExpr(c: PContext, n: PNode): PNode =
  var e = semExprWithType(c, n)
  if e == nil:
    localError(n.info, errConstExprExpected)
    return n
  result = getConstExpr(c.module, e)
  if result == nil:
    result = evalConstExpr(c.module, e)
    if result == nil or result.kind == nkEmpty:
      if e.info != n.info:
        pushInfoContext(n.info)
        localError(e.info, errConstExprExpected)
        popInfoContext()
      else:
        localError(e.info, errConstExprExpected)
      # error correction:
      result = e
    else:
      result = fixupTypeAfterEval(c, result, e)

include hlo, seminst, semcall

proc semAfterMacroCall(c: PContext, n: PNode, s: PSym): PNode = 
  inc(evalTemplateCounter)
  if evalTemplateCounter > 100:
    globalError(s.info, errTemplateInstantiationTooNested)
  let oldFriend = c.friendModule
  c.friendModule = s.owner.getModule

  result = n
  if s.typ.sons[0] == nil:
    result = semStmt(c, result)
  else:
    case s.typ.sons[0].kind
    of tyExpr:
      # BUGFIX: we cannot expect a type here, because module aliases would not 
      # work then (see the ``tmodulealias`` test)
      # semExprWithType(c, result)
      result = semExpr(c, result)
    of tyStmt:
      result = semStmt(c, result)
    of tyTypeDesc:
      if n.kind == nkStmtList: result.kind = nkStmtListType
      var typ = semTypeNode(c, result, nil)
      result.typ = makeTypeDesc(c, typ)
      #result = symNodeFromType(c, typ, n.info)
    else:
      result = semExpr(c, result)
      result = fitNode(c, s.typ.sons[0], result)
      #GlobalError(s.info, errInvalidParamKindX, typeToString(s.typ.sons[0]))
  dec(evalTemplateCounter)
  c.friendModule = oldFriend

proc semMacroExpr(c: PContext, n, nOrig: PNode, sym: PSym, 
                  semCheck: bool = true): PNode = 
  markUsed(n, sym)
  if sym == c.p.owner:
    globalError(n.info, errRecursiveDependencyX, sym.name.s)

  #if c.evalContext == nil:
  #  c.evalContext = c.createEvalContext(emStatic)

  result = evalMacroCall(c.module, n, nOrig, sym)
  if semCheck: result = semAfterMacroCall(c, result, sym)

proc forceBool(c: PContext, n: PNode): PNode = 
  result = fitNode(c, getSysType(tyBool), n)
  if result == nil: result = n

proc semConstBoolExpr(c: PContext, n: PNode): PNode = 
  let nn = semExprWithType(c, n)
  result = fitNode(c, getSysType(tyBool), nn)
  if result == nil:
    localError(n.info, errConstExprExpected)
    return nn
  result = getConstExpr(c.module, result)
  if result == nil: 
    localError(n.info, errConstExprExpected)
    result = nn

include semtypes, semtempl, semgnrc, semstmts, semexprs

proc addCodeForGenerics(c: PContext, n: PNode) =
  for i in countup(c.lastGenericIdx, c.generics.len - 1):
    var prc = c.generics[i].inst.sym
    if prc.kind in {skProc, skMethod, skConverter} and prc.magic == mNone:
      if prc.ast == nil or prc.ast.sons[bodyPos] == nil:
        internalError(prc.info, "no code for " & prc.name.s)
      else:
        addSon(n, prc.ast)
  c.lastGenericIdx = c.generics.len

proc myOpen(module: PSym): PPassContext =
  var c = newContext(module)
  if c.p != nil: internalError(module.info, "sem.myOpen")
  c.semConstExpr = semConstExpr
  c.semExpr = semExpr
  c.semTryExpr = tryExpr
  c.semTryConstExpr = tryConstExpr
  c.semOperand = semOperand
  c.semConstBoolExpr = semConstBoolExpr
  c.semOverloadedCall = semOverloadedCall
  c.semTypeNode = semTypeNode
  pushProcCon(c, module)
  pushOwner(c.module)
  c.importTable = openScope(c)
  c.importTable.addSym(module) # a module knows itself
  if sfSystemModule in module.flags: 
    magicsys.systemModule = module # set global variable!
  else: 
    c.importTable.addSym magicsys.systemModule # import the "System" identifier
    importAllSymbols(c, magicsys.systemModule)
  c.topLevelScope = openScope(c)
  result = c

proc myOpenCached(module: PSym, rd: PRodReader): PPassContext =
  result = myOpen(module)
  for m in items(rd.methods): methodDef(m, true)

proc semStmtAndGenerateGenerics(c: PContext, n: PNode): PNode = 
  result = semStmt(c, n)
  # BUGFIX: process newly generated generics here, not at the end!
  if c.lastGenericIdx < c.generics.len:
    var a = newNodeI(nkStmtList, n.info)
    addCodeForGenerics(c, a)
    if sonsLen(a) > 0: 
      # a generic has been added to `a`:
      if result.kind != nkEmpty: addSon(a, result)
      result = a
  result = hloStmt(c, result)
  if gCmd == cmdInteractive and not isEmptyType(result.typ):
    result = buildEchoStmt(c, result)
  result = transformStmt(c.module, result)
    
proc recoverContext(c: PContext) = 
  # clean up in case of a semantic error: We clean up the stacks, etc. This is
  # faster than wrapping every stack operation in a 'try finally' block and 
  # requires far less code.
  c.currentScope = c.topLevelScope
  while getCurrOwner().kind != skModule: popOwner()
  while c.p != nil and c.p.owner.kind != skModule: c.p = c.p.next

proc myProcess(context: PPassContext, n: PNode): PNode = 
  var c = PContext(context)    
  # no need for an expensive 'try' if we stop after the first error anyway:
  if msgs.gErrorMax <= 1:
    result = semStmtAndGenerateGenerics(c, n)
  else:
    let oldContextLen = msgs.getInfoContextLen()
    let oldInGenericInst = c.inGenericInst
    try:
      result = semStmtAndGenerateGenerics(c, n)
    except ERecoverableError, ESuggestDone:
      recoverContext(c)
      c.inGenericInst = oldInGenericInst
      msgs.setInfoContextLen(oldContextLen)
      if getCurrentException() of ESuggestDone: result = nil
      else: result = ast.emptyNode
      #if gCmd == cmdIdeTools: findSuggest(c, n)
  
proc checkThreads(c: PContext) =
  if not needsGlobalAnalysis(): return
  for i in 0 .. c.threadEntries.len-1:
    semthreads.analyseThreadProc(c.threadEntries[i])
  
proc myClose(context: PPassContext, n: PNode): PNode = 
  var c = PContext(context)
  closeScope(c)         # close module's scope
  rawCloseScope(c)      # imported symbols; don't check for unused ones!
  result = newNode(nkStmtList)
  if n != nil:
    internalError(n.info, "n is not nil") #result := n;
  addCodeForGenerics(c, result)
  if c.module.ast != nil:
    result.add(c.module.ast)
  checkThreads(c)
  popOwner()
  popProcCon(c)

const semPass* = makePass(myOpen, myOpenCached, myProcess, myClose)

