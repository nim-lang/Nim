#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module implements the semantic checking pass.

import                        #var
                              #  point: array [0..3] of int;
  strutils, nhashes, lists, options, scanner, ast, astalgo, trees, treetab, 
  wordrecg, ropes, msgs, os, condsyms, idents, rnimsyn, types, platform, math, 
  magicsys, pnimsyn, nversion, nimsets, semdata, evals, semfold, importer, 
  procfind, lookups, rodread, pragmas, passes

proc semPass*(): TPass
# implementation

proc considerAcc(n: PNode): PIdent = 
  var x: PNode
  x = n
  if x.kind == nkAccQuoted: x = x.sons[0]
  case x.kind
  of nkIdent: result = x.ident
  of nkSym: result = x.sym.name
  else: 
    liMessage(n.info, errIdentifierExpected, renderTree(n))
    result = nil

proc isTopLevel(c: PContext): bool = 
  result = c.tab.tos <= 2

proc newSymS(kind: TSymKind, n: PNode, c: PContext): PSym = 
  result = newSym(kind, considerAcc(n), getCurrOwner())
  result.info = n.info

proc markUsed(n: PNode, s: PSym) = 
  incl(s.flags, sfUsed)
  if sfDeprecated in s.flags: liMessage(n.info, warnDeprecated, s.name.s)
  
proc semIdentVis(c: PContext, kind: TSymKind, n: PNode, allowed: TSymFlags): PSym
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
    liMessage(n.info, errConstExprExpected)
    return 
  result = getConstExpr(c.module, result)
  if result == nil: liMessage(n.info, errConstExprExpected)
  
proc semAndEvalConstExpr(c: PContext, n: PNode): PNode = 
  var e: PNode
  e = semExprWithType(c, n)
  if e == nil: 
    liMessage(n.info, errConstExprExpected)
    return nil
  result = getConstExpr(c.module, e)
  if result == nil: 
    #writeln(output, renderTree(n));
    result = evalConstExpr(c.module, e)
    if (result == nil) or (result.kind == nkEmpty): 
      liMessage(n.info, errConstExprExpected)
  
proc semAfterMacroCall(c: PContext, n: PNode, s: PSym): PNode = 
  result = n
  case s.typ.sons[0].kind
  of tyExpr: result = semExprWithType(c, result)
  of tyStmt: result = semStmt(c, result)
  of tyTypeDesc: result.typ = semTypeNode(c, result, nil)
  else: liMessage(s.info, errInvalidParamKindX, typeToString(s.typ.sons[0]))
  
include 
  "semtempl.nim"

proc semMacroExpr(c: PContext, n: PNode, sym: PSym, semCheck: bool = true): PNode = 
  var 
    p: PEvalContext
    s: PStackFrame
  inc(evalTemplateCounter)
  if evalTemplateCounter > 100: 
    liMessage(n.info, errTemplateInstantiationTooNested)
  markUsed(n, sym)
  p = newEvalContext(c.module, "", false)
  s = newStackFrame()
  s.call = n
  setlen(s.params, 2)
  s.params[0] = newNodeIT(nkNilLit, n.info, sym.typ.sons[0])
  s.params[1] = n
  pushStackFrame(p, s)
  discard eval(p, sym.ast.sons[codePos])
  result = s.params[0]
  popStackFrame(p)
  if cyclicTree(result): liMessage(n.info, errCyclicTree)
  if semCheck: result = semAfterMacroCall(c, result, sym)
  dec(evalTemplateCounter)

include 
  "seminst.nim"

include 
  "sigmatch.nim"

proc CheckBool(t: PNode) = 
  if (t.Typ == nil) or
      (skipTypes(t.Typ, {tyGenericInst, tyVar, tyOrdinal}).kind != tyBool): 
    liMessage(t.Info, errExprMustBeBool)
  
proc typeMismatch(n: PNode, formal, actual: PType) = 
  liMessage(n.Info, errGenerated, msgKindToString(errTypeMismatch) &
      typeToString(actual) & ") " &
      `%`(msgKindToString(errButExpectedX), [typeToString(formal)]))

include 
  "semtypes.nim"

include 
  "semexprs.nim"

include 
  "semgnrc.nim"

include 
  "semstmts.nim"

proc addCodeForGenerics(c: PContext, n: PNode) = 
  var 
    prc: PSym
    it: PNode
  for i in countup(c.lastGenericIdx, sonsLen(c.generics) - 1): 
    it = c.generics.sons[i].sons[1]
    if it.kind != nkSym: InternalError("addCodeForGenerics")
    prc = it.sym
    if (prc.kind in {skProc, skMethod, skConverter}) and (prc.magic == mNone): 
      if (prc.ast == nil) or (prc.ast.sons[codePos] == nil): 
        InternalError(prc.info, "no code for " & prc.name.s)
      addSon(n, prc.ast)
  c.lastGenericIdx = sonsLen(c.generics)

proc myOpen(module: PSym, filename: string): PPassContext = 
  var c: PContext
  c = newContext(module, filename)
  if (c.p != nil): InternalError(module.info, "sem.myOpen")
  c.semConstExpr = semConstExpr
  c.p = newProcCon(module)
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

proc myOpenCached(module: PSym, filename: string, rd: PRodReader): PPassContext = 
  var c: PContext
  c = PContext(myOpen(module, filename))
  c.fromCache = true
  result = c

proc myProcess(context: PPassContext, n: PNode): PNode = 
  var 
    c: PContext
    a: PNode
  result = nil
  c = PContext(context)
  result = semStmt(c, n)      # BUGFIX: process newly generated generics here, not at the end!
  if sonsLen(c.generics) > 0: 
    a = newNodeI(nkStmtList, n.info)
    addCodeForGenerics(c, a)
    if sonsLen(a) > 0: 
      # a generic has been added to `a`:
      addSonIfNotNil(a, result)
      result = a

proc myClose(context: PPassContext, n: PNode): PNode = 
  var c: PContext
  c = PContext(context)
  closeScope(c.tab)           # close module's scope
  rawCloseScope(c.tab)        # imported symbols; don't check for unused ones!
  if n == nil: 
    result = newNode(nkStmtList)
  else: 
    InternalError(n.info, "n is not nil") #result := n;
  addCodeForGenerics(c, result)
  popOwner()
  c.p = nil

proc semPass(): TPass = 
  initPass(result)
  result.open = myOpen
  result.openCached = myOpenCached
  result.close = myClose
  result.process = myProcess
