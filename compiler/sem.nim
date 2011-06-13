#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the semantic checking pass.

import
  strutils, hashes, lists, options, lexer, ast, astalgo, trees, treetab, 
  wordrecg, ropes, msgs, os, condsyms, idents, renderer, types, platform, math, 
  magicsys, parser, nversion, nimsets, semdata, evals, semfold, importer, 
  procfind, lookups, rodread, pragmas, passes, semtypinst, sigmatch, suggest,
  semthreads

proc semPass*(): TPass
# implementation

proc isTopLevel(c: PContext): bool {.inline.} = 
  result = c.tab.tos <= 2

proc newSymS(kind: TSymKind, n: PNode, c: PContext): PSym = 
  result = newSym(kind, considerAcc(n), getCurrOwner())
  result.info = n.info
  
proc semIdentVis(c: PContext, kind: TSymKind, n: PNode,
                 allowed: TSymFlags): PSym
  # identifier with visability
proc semIdentWithPragma(c: PContext, kind: TSymKind, n: PNode, 
                        allowed: TSymFlags): PSym
proc semStmtScope(c: PContext, n: PNode): PNode

type 
  TExprFlag = enum 
    efAllowType, efLValue, efWantIterator
  TExprFlags = set[TExprFlag]

proc semExpr(c: PContext, n: PNode, flags: TExprFlags = {}): PNode
proc semExprWithType(c: PContext, n: PNode, flags: TExprFlags = {}): PNode
proc fitNode(c: PContext, formal: PType, arg: PNode): PNode
proc semLambda(c: PContext, n: PNode): PNode
proc semTypeNode(c: PContext, n: PNode, prev: PType): PType
proc semStmt(c: PContext, n: PNode): PNode
proc semParamList(c: PContext, n, genericParams: PNode, s: PSym)
proc addParams(c: PContext, n: PNode)
proc addResult(c: PContext, t: PType, info: TLineInfo)
proc addResultNode(c: PContext, n: PNode)
proc instGenericContainer(c: PContext, n: PNode, header: PType): PType

proc semConstExpr(c: PContext, n: PNode): PNode = 
  result = semExprWithType(c, n)
  if result == nil: 
    GlobalError(n.info, errConstExprExpected)
    return 
  result = getConstExpr(c.module, result)
  if result == nil: GlobalError(n.info, errConstExprExpected)
  
proc semAndEvalConstExpr(c: PContext, n: PNode): PNode = 
  var e = semExprWithType(c, n)
  if e == nil: 
    GlobalError(n.info, errConstExprExpected)
    return nil
  result = getConstExpr(c.module, e)
  if result == nil: 
    #writeln(output, renderTree(n));
    result = evalConstExpr(c.module, e)
    if result == nil or result.kind == nkEmpty: 
      GlobalError(n.info, errConstExprExpected)
  
proc semAfterMacroCall(c: PContext, n: PNode, s: PSym): PNode = 
  result = n
  case s.typ.sons[0].kind
  of tyExpr: 
    # BUGFIX: we cannot expect a type here, because module aliases would not 
    # work then (see the ``tmodulealias`` test)
    result = semExpr(c, result) # semExprWithType(c, result)
  of tyStmt: result = semStmt(c, result)
  of tyTypeDesc: result.typ = semTypeNode(c, result, nil)
  else: GlobalError(s.info, errInvalidParamKindX, typeToString(s.typ.sons[0]))
  
include "semtempl.nim"

proc semMacroExpr(c: PContext, n: PNode, sym: PSym, 
                  semCheck: bool = true): PNode = 
  inc(evalTemplateCounter)
  if evalTemplateCounter > 100: 
    GlobalError(n.info, errTemplateInstantiationTooNested)
  markUsed(n, sym)
  var p = newEvalContext(c.module, "", false)
  var s = newStackFrame()
  s.call = n
  setlen(s.params, 2)
  s.params[0] = newNodeIT(nkNilLit, n.info, sym.typ.sons[0])
  s.params[1] = n
  pushStackFrame(p, s)
  discard eval(p, sym.ast.sons[codePos])
  result = s.params[0]
  popStackFrame(p)
  if cyclicTree(result): GlobalError(n.info, errCyclicTree)
  if semCheck: result = semAfterMacroCall(c, result, sym)
  dec(evalTemplateCounter)

include seminst, semcall
  
proc typeMismatch(n: PNode, formal, actual: PType) = 
  GlobalError(n.Info, errGenerated, msgKindToString(errTypeMismatch) &
      typeToString(actual) & ") " &
      `%`(msgKindToString(errButExpectedX), [typeToString(formal)]))

proc fitNode(c: PContext, formal: PType, arg: PNode): PNode = 
  result = IndexTypesMatch(c, formal, arg.typ, arg)
  if result == nil:
    #debug(arg)
    typeMismatch(arg, formal, arg.typ)

proc forceBool(c: PContext, n: PNode): PNode = 
  result = fitNode(c, getSysType(tyBool), n)
  if result == nil: result = n

proc semConstBoolExpr(c: PContext, n: PNode): PNode = 
  result = fitNode(c, getSysType(tyBool), semExprWithType(c, n))
  if result == nil: 
    GlobalError(n.info, errConstExprExpected)
    return 
  result = getConstExpr(c.module, result)
  if result == nil: GlobalError(n.info, errConstExprExpected)

include semtypes, semexprs, semgnrc, semstmts

proc addCodeForGenerics(c: PContext, n: PNode) = 
  for i in countup(c.lastGenericIdx, sonsLen(c.generics) - 1): 
    var it = c.generics.sons[i].sons[1]
    if it.kind != nkSym: InternalError("addCodeForGenerics")
    var prc = it.sym
    if (prc.kind in {skProc, skMethod, skConverter}) and (prc.magic == mNone): 
      if (prc.ast == nil) or (prc.ast.sons[codePos] == nil): 
        InternalError(prc.info, "no code for " & prc.name.s)
      addSon(n, prc.ast)
  c.lastGenericIdx = sonsLen(c.generics)

proc semExprNoFlags(c: PContext, n: PNode): PNode = 
  result = semExpr(c, n, {})

proc myOpen(module: PSym, filename: string): PPassContext = 
  var c = newContext(module, filename)
  if (c.p != nil): InternalError(module.info, "sem.myOpen")
  c.semConstExpr = semConstExpr
  c.semExpr = semExprNoFlags
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
  var c = PContext(myOpen(module, filename))
  c.fromCache = true
  result = c

proc SemStmtAndGenerateGenerics(c: PContext, n: PNode): PNode = 
  result = semStmt(c, n)
  # BUGFIX: process newly generated generics here, not at the end!
  if sonsLen(c.generics) > 0: 
    var a = newNodeI(nkStmtList, n.info)
    addCodeForGenerics(c, a)
    if sonsLen(a) > 0: 
      # a generic has been added to `a`:
      if result.kind != nkEmpty: addSon(a, result)
      result = a

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
    try:
      result = SemStmtAndGenerateGenerics(c, n)
    except ERecoverableError:
      RecoverContext(c)
      result = ast.emptyNode
  
proc checkThreads(c: PContext) =
  for i in 0 .. c.threadEntries.len-1:
    semthreads.AnalyseThread(c.threadEntries[i])
  
proc myClose(context: PPassContext, n: PNode): PNode = 
  var c = PContext(context)
  closeScope(c.tab)           # close module's scope
  rawCloseScope(c.tab)        # imported symbols; don't check for unused ones!
  if n == nil: 
    result = newNode(nkStmtList)
  else: 
    InternalError(n.info, "n is not nil") #result := n;
  addCodeForGenerics(c, result)
  checkThreads(c)
  popOwner()
  popProcCon(c)

proc semPass(): TPass = 
  initPass(result)
  result.open = myOpen
  result.openCached = myOpenCached
  result.close = myClose
  result.process = myProcess
