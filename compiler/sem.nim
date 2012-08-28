#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
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
  semthreads, intsets, transf, evals, idgen, aliases, cgmeth, lambdalifting,
  evaltempl

proc semPass*(): TPass
# implementation

type 
  TExprFlag = enum 
    efLValue, efWantIterator, efInTypeof
  TExprFlags = set[TExprFlag]

proc semExpr(c: PContext, n: PNode, flags: TExprFlags = {}): PNode
proc semExprWithType(c: PContext, n: PNode, flags: TExprFlags = {}): PNode
proc fitNode(c: PContext, formal: PType, arg: PNode): PNode
proc semLambda(c: PContext, n: PNode): PNode
proc semTypeNode(c: PContext, n: PNode, prev: PType): PType
proc semStmt(c: PContext, n: PNode): PNode
proc semParamList(c: PContext, n, genericParams: PNode, s: PSym)
proc addParams(c: PContext, n: PNode, kind: TSymKind)
proc addResult(c: PContext, t: PType, info: TLineInfo, owner: TSymKind)
proc addResultNode(c: PContext, n: PNode)
proc instGenericContainer(c: PContext, n: PNode, header: PType): PType

proc typeMismatch(n: PNode, formal, actual: PType) = 
  if formal.kind != tyError and actual.kind != tyError: 
    LocalError(n.Info, errGenerated, msgKindToString(errTypeMismatch) &
        typeToString(actual) & ") " &
        `%`(msgKindToString(errButExpectedX), [typeToString(formal)]))

proc fitNode(c: PContext, formal: PType, arg: PNode): PNode = 
  result = IndexTypesMatch(c, formal, arg.typ, arg)
  if result == nil:
    typeMismatch(arg, formal, arg.typ)
    # error correction:
    result = copyNode(arg)
    result.typ = formal

proc isTopLevel(c: PContext): bool {.inline.} = 
  result = c.tab.tos <= 2

proc newSymS(kind: TSymKind, n: PNode, c: PContext): PSym = 
  result = newSym(kind, considerAcc(n), getCurrOwner(), n.info)

proc newSymG*(kind: TSymKind, n: PNode, c: PContext): PSym =
  # like newSymS, but considers gensym'ed symbols
  if n.kind == nkSym: 
    result = n.sym
    InternalAssert sfGenSym in result.flags
    InternalAssert result.kind == kind
  else:
    result = newSym(kind, considerAcc(n), getCurrOwner(), n.info)

proc semIdentVis(c: PContext, kind: TSymKind, n: PNode,
                 allowed: TSymFlags): PSym
  # identifier with visability
proc semIdentWithPragma(c: PContext, kind: TSymKind, n: PNode, 
                        allowed: TSymFlags): PSym
proc semStmtScope(c: PContext, n: PNode): PNode

proc ParamsTypeCheck(c: PContext, typ: PType) {.inline.} =
  if not typeAllowed(typ, skConst):
    LocalError(typ.n.info, errXisNoType, typeToString(typ))

proc expectMacroOrTemplateCall(c: PContext, n: PNode): PSym

proc semTemplateExpr(c: PContext, n: PNode, s: PSym, semCheck = true): PNode

proc semMacroExpr(c: PContext, n, nOrig: PNode, sym: PSym, 
                  semCheck: bool = true): PNode

proc semWhen(c: PContext, n: PNode, semCheck: bool = true): PNode

proc evalTypedExpr(c: PContext, e: PNode): PNode =
  result = getConstExpr(c.module, e)
  if result == nil:
    result = evalConstExpr(c.module, e)
    if result == nil or result.kind == nkEmpty:
      LocalError(e.info, errConstExprExpected)
      # error correction:
      result = e

proc semConstExpr(c: PContext, n: PNode): PNode =
  var e = semExprWithType(c, n)
  if e == nil:
    LocalError(n.info, errConstExprExpected)
    return n
  result = evalTypedExpr(c, e)

include seminst, semcall

proc semAfterMacroCall(c: PContext, n: PNode, s: PSym): PNode = 
  inc(evalTemplateCounter)
  if evalTemplateCounter > 100:
    GlobalError(s.info, errTemplateInstantiationTooNested)

  result = n
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
    result.typ = semTypeNode(c, result, nil)
  else:
    result = semExpr(c, result)
    result = fitNode(c, s.typ.sons[0], result)
    #GlobalError(s.info, errInvalidParamKindX, typeToString(s.typ.sons[0]))
  dec(evalTemplateCounter)

proc semMacroExpr(c: PContext, n, nOrig: PNode, sym: PSym, 
                  semCheck: bool = true): PNode = 
  markUsed(n, sym)
  if sym == c.p.owner:
    GlobalError(n.info, errRecursiveDependencyX, sym.name.s)
  if c.evalContext == nil:
    c.evalContext = newEvalContext(c.module, "", emStatic)
  result = evalMacroCall(c.evalContext, n, nOrig, sym)
  if semCheck: result = semAfterMacroCall(c, result, sym)

proc forceBool(c: PContext, n: PNode): PNode = 
  result = fitNode(c, getSysType(tyBool), n)
  if result == nil: result = n

proc semConstBoolExpr(c: PContext, n: PNode): PNode = 
  let nn = semExprWithType(c, n)
  result = fitNode(c, getSysType(tyBool), nn)
  if result == nil:
    LocalError(n.info, errConstExprExpected)
    return nn
  result = getConstExpr(c.module, result)
  if result == nil: 
    LocalError(n.info, errConstExprExpected)
    result = nn

include semtypes, semtempl, semexprs, semgnrc, semstmts

proc addCodeForGenerics(c: PContext, n: PNode) = 
  for i in countup(c.generics.lastGenericIdx, Len(c.generics.generics) - 1):
    var prc = c.generics.generics[i].instSym
    if prc.kind in {skProc, skMethod, skConverter} and prc.magic == mNone: 
      if prc.ast == nil or prc.ast.sons[bodyPos] == nil: 
        InternalError(prc.info, "no code for " & prc.name.s)
      else:
        addSon(n, prc.ast)
  c.generics.lastGenericIdx = Len(c.generics.generics)

proc semExprNoFlags(c: PContext, n: PNode): PNode {.procvar.} = 
  result = semExpr(c, n, {})

proc myOpen(module: PSym, filename: string): PPassContext = 
  var c = newContext(module, filename)
  if c.p != nil: InternalError(module.info, "sem.myOpen")
  c.semConstExpr = semConstExpr
  c.semExpr = semExprNoFlags
  c.semConstBoolExpr = semConstBoolExpr
  c.semOverloadedCall = semOverloadedCall
  pushProcCon(c, module)
  pushOwner(c.module)
  openScope(c.tab)            # scope for imported symbols
  SymTabAdd(c.tab, module)    # a module knows itself
  if sfSystemModule in module.flags: 
    magicsys.SystemModule = module # set global variable!
    InitSystem(c.tab)         # currently does nothing
  else: 
    SymTabAdd(c.tab, magicsys.SystemModule) # import the "System" identifier
    importAllSymbols(c, magicsys.SystemModule)
  openScope(c.tab)            # scope for the module's symbols  
  result = c

proc myOpenCached(module: PSym, filename: string, 
                  rd: PRodReader): PPassContext = 
  result = myOpen(module, filename)
  for m in items(rd.methods): methodDef(m, true)

proc SemStmtAndGenerateGenerics(c: PContext, n: PNode): PNode = 
  result = semStmt(c, n)
  # BUGFIX: process newly generated generics here, not at the end!
  if c.generics.lastGenericIdx < Len(c.generics.generics):
    var a = newNodeI(nkStmtList, n.info)
    addCodeForGenerics(c, a)
    if sonsLen(a) > 0: 
      # a generic has been added to `a`:
      if result.kind != nkEmpty: addSon(a, result)
      result = a
  result = transformStmt(c.module, result)

proc RecoverContext(c: PContext) = 
  # clean up in case of a semantic error: We clean up the stacks, etc. This is
  # faster than wrapping every stack operation in a 'try finally' block and 
  # requires far less code.
  while c.tab.tos-1 > ModuleTablePos: rawCloseScope(c.tab)
  while getCurrOwner().kind != skModule: popOwner()
  while c.p != nil and c.p.owner.kind != skModule: c.p = c.p.next

proc myProcess(context: PPassContext, n: PNode): PNode = 
  var c = PContext(context)    
  # no need for an expensive 'try' if we stop after the first error anyway:
  if msgs.gErrorMax <= 1:
    result = SemStmtAndGenerateGenerics(c, n)
  else:
    let oldContextLen = msgs.getInfoContextLen()
    try:
      result = SemStmtAndGenerateGenerics(c, n)
    except ERecoverableError:
      RecoverContext(c)
      result = ast.emptyNode
      msgs.setInfoContextLen(oldContextLen)
      if gCmd == cmdIdeTools: findSuggest(c, n)
  
proc checkThreads(c: PContext) =
  if not needsGlobalAnalysis(): return
  for i in 0 .. c.threadEntries.len-1:
    semthreads.AnalyseThreadProc(c.threadEntries[i])
  
proc myClose(context: PPassContext, n: PNode): PNode = 
  var c = PContext(context)
  closeScope(c.tab)         # close module's scope
  rawCloseScope(c.tab)      # imported symbols; don't check for unused ones!
  result = newNode(nkStmtList)
  if n != nil:
    InternalError(n.info, "n is not nil") #result := n;
  addCodeForGenerics(c, result)
  if c.module.ast != nil:
    result.add(c.module.ast)
  checkThreads(c)
  popOwner()
  popProcCon(c)

proc semPass(): TPass = 
  initPass(result)
  result.open = myOpen
  result.openCached = myOpenCached
  result.close = myClose
  result.process = myProcess
