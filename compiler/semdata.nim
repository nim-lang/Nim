#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains the data structures for the semantic checking phase.

import 
  strutils, lists, intsets, options, lexer, ast, astalgo, trees, treetab,
  wordrecg, 
  ropes, msgs, platform, os, condsyms, idents, renderer, types, extccomp, math, 
  magicsys, nversion, nimsets, parser, times, passes, rodread, vmdef

type 
  TOptionEntry* = object of lists.TListEntry # entries to put on a
                                             # stack for pragma parsing
    options*: TOptions
    defaultCC*: TCallingConvention
    dynlib*: PLib
    notes*: TNoteKinds
    otherPragmas*: PNode      # every pragma can be pushed

  POptionEntry* = ref TOptionEntry
  PProcCon* = ref TProcCon
  TProcCon*{.final.} = object # procedure context; also used for top-level
                              # statements
    owner*: PSym              # the symbol this context belongs to
    resultSym*: PSym          # the result symbol (if we are in a proc)
    nestedLoopCounter*: int   # whether we are in a loop or not
    nestedBlockCounter*: int  # whether we are in a block or not
    inTryStmt*: int           # whether we are in a try statement; works also
                              # in standalone ``except`` and ``finally``
    next*: PProcCon           # used for stacking procedure contexts
    wasForwarded*: bool       # whether the current proc has a separate header
  
  TInstantiationPair* = object
    genericSym*: PSym
    inst*: PInstantiation

  TExprFlag* = enum 
    efLValue, efWantIterator, efInTypeof, efWantStmt, efDetermineType,
    efAllowDestructor, efWantValue, efOperand, efNoSemCheck
  TExprFlags* = set[TExprFlag]

  PContext* = ref TContext
  TContext* = object of TPassContext # a context represents a module
    module*: PSym              # the module sym belonging to the context
    currentScope*: PScope      # current scope
    importTable*: PScope       # scope for all imported symbols
    topLevelScope*: PScope     # scope for all top-level symbols
    p*: PProcCon               # procedure context
    friendModules*: seq[PSym]  # friend modules; may access private data;
                               # this is used so that generic instantiations
                               # can access private object fields
    instCounter*: int          # to prevent endless instantiations
   
    ambiguousSymbols*: IntSet  # ids of all ambiguous symbols (cannot
                               # store this info in the syms themselves!)
    inTypeClass*: int          # > 0 if we are in a user-defined type class
    inGenericContext*: int     # > 0 if we are in a generic type
    inUnrolledContext*: int    # > 0 if we are unrolling a loop
    inCompilesContext*: int    # > 0 if we are in a ``compiles`` magic
    inGenericInst*: int        # > 0 if we are instantiating a generic
    converters*: TSymSeq       # sequence of converters
    patterns*: TSymSeq         # sequence of pattern matchers
    optionStack*: TLinkedList
    symMapping*: TIdTable      # every gensym'ed symbol needs to be mapped
                               # to some new symbol in a generic instantiation
    libs*: TLinkedList         # all libs used by this module
    semConstExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.} # for the pragmas
    semExpr*: proc (c: PContext, n: PNode, flags: TExprFlags = {}): PNode {.nimcall.}
    semTryExpr*: proc (c: PContext, n: PNode,flags: TExprFlags = {}): PNode {.nimcall.}
    semTryConstExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.}
    semOperand*: proc (c: PContext, n: PNode, flags: TExprFlags = {}): PNode {.nimcall.}
    semConstBoolExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.} # XXX bite the bullet
    semOverloadedCall*: proc (c: PContext, n, nOrig: PNode,
                              filter: TSymKinds): PNode {.nimcall.}
    semTypeNode*: proc(c: PContext, n: PNode, prev: PType): PType {.nimcall.}
    semInferredLambda*: proc(c: PContext, pt: TIdTable, n: PNode): PNode
    semGenerateInstance*: proc (c: PContext, fn: PSym, pt: TIdTable,
                                info: TLineInfo): PSym
    includedFiles*: IntSet    # used to detect recursive include files
    userPragmas*: TStrTable
    evalContext*: PEvalContext
    unknownIdents*: IntSet     # ids of all unknown identifiers to prevent
                               # naming it multiple times
    generics*: seq[TInstantiationPair] # pending list of instantiated generics to compile
    lastGenericIdx*: int      # used for the generics stack
    hloLoopDetector*: int     # used to prevent endless loops in the HLO
    inParallelStmt*: int
    instDeepCopy*: proc (c: PContext; dc: PSym; t: PType;
                         info: TLineInfo): PSym {.nimcall.}

   
proc makeInstPair*(s: PSym, inst: PInstantiation): TInstantiationPair =
  result.genericSym = s
  result.inst = inst

proc filename*(c: PContext): string =
  # the module's filename
  return c.module.filename

proc newContext*(module: PSym): PContext

proc lastOptionEntry*(c: PContext): POptionEntry
proc newOptionEntry*(): POptionEntry
proc newLib*(kind: TLibKind): PLib
proc addToLib*(lib: PLib, sym: PSym)
proc makePtrType*(c: PContext, baseType: PType): PType
proc makeVarType*(c: PContext, baseType: PType): PType
proc newTypeS*(kind: TTypeKind, c: PContext): PType
proc fillTypeS*(dest: PType, kind: TTypeKind, c: PContext)

proc scopeDepth*(c: PContext): int {.inline.} =
  result = if c.currentScope != nil: c.currentScope.depthLevel
           else: 0

# owner handling:
proc getCurrOwner*(): PSym
proc pushOwner*(owner: PSym)
proc popOwner*()
# implementation

var gOwners*: seq[PSym] = @[]

proc getCurrOwner(): PSym = 
  # owner stack (used for initializing the
  # owner field of syms)
  # the documentation comment always gets
  # assigned to the current owner
  # BUGFIX: global array is needed!
  result = gOwners[high(gOwners)]

proc pushOwner(owner: PSym) = 
  add(gOwners, owner)

proc popOwner() = 
  var length = len(gOwners)
  if length > 0: setLen(gOwners, length - 1)
  else: internalError("popOwner")

proc lastOptionEntry(c: PContext): POptionEntry = 
  result = POptionEntry(c.optionStack.tail)

proc pushProcCon*(c: PContext, owner: PSym) {.inline.} = 
  if owner == nil: 
    internalError("owner is nil")
    return
  var x: PProcCon
  new(x)
  x.owner = owner
  x.next = c.p
  c.p = x

proc popProcCon*(c: PContext) {.inline.} = c.p = c.p.next

proc newOptionEntry(): POptionEntry = 
  new(result)
  result.options = gOptions
  result.defaultCC = ccDefault
  result.dynlib = nil
  result.notes = gNotes

proc newContext(module: PSym): PContext =
  new(result)
  result.ambiguousSymbols = initIntSet()
  initLinkedList(result.optionStack)
  initLinkedList(result.libs)
  append(result.optionStack, newOptionEntry())
  result.module = module
  result.friendModules = @[module]
  result.converters = @[]
  result.patterns = @[]
  result.includedFiles = initIntSet()
  initStrTable(result.userPragmas)
  result.generics = @[]
  result.unknownIdents = initIntSet()

proc inclSym(sq: var TSymSeq, s: PSym) =
  var L = len(sq)
  for i in countup(0, L - 1): 
    if sq[i].id == s.id: return 
  setLen(sq, L + 1)
  sq[L] = s

proc addConverter*(c: PContext, conv: PSym) =
  inclSym(c.converters, conv)

proc addPattern*(c: PContext, p: PSym) =
  inclSym(c.patterns, p)

proc newLib(kind: TLibKind): PLib = 
  new(result)
  result.kind = kind          #initObjectSet(result.syms)
  
proc addToLib(lib: PLib, sym: PSym) =
  #if sym.annex != nil and not isGenericRoutine(sym):
  #  LocalError(sym.info, errInvalidPragma)
  sym.annex = lib

proc makePtrType(c: PContext, baseType: PType): PType = 
  result = newTypeS(tyPtr, c)
  addSonSkipIntLit(result, baseType.assertNotNil)

proc makeVarType(c: PContext, baseType: PType): PType = 
  result = newTypeS(tyVar, c)
  addSonSkipIntLit(result, baseType.assertNotNil)

proc makeTypeDesc*(c: PContext, typ: PType): PType =
  result = newTypeS(tyTypeDesc, c)
  result.addSonSkipIntLit(typ.assertNotNil)

proc makeTypeSymNode*(c: PContext, typ: PType, info: TLineInfo): PNode =
  let typedesc = makeTypeDesc(c, typ)
  let sym = newSym(skType, idAnon, getCurrOwner(), info).linkTo(typedesc)
  return newSymNode(sym, info)

proc makeTypeFromExpr*(c: PContext, n: PNode): PType =
  result = newTypeS(tyFromExpr, c)
  assert n != nil
  result.n = n

proc newTypeWithSons*(c: PContext, kind: TTypeKind,
                      sons: seq[PType]): PType =
  result = newType(kind, getCurrOwner())
  result.sons = sons

proc makeStaticExpr*(c: PContext, n: PNode): PNode =
  result = newNodeI(nkStaticExpr, n.info)
  result.sons = @[n]
  result.typ = newTypeWithSons(c, tyStatic, @[n.typ])

proc makeAndType*(c: PContext, t1, t2: PType): PType =
  result = newTypeS(tyAnd, c)
  result.sons = @[t1, t2]
  propagateToOwner(result, t1)
  propagateToOwner(result, t2)
  result.flags.incl((t1.flags + t2.flags) * {tfHasStatic})

proc makeOrType*(c: PContext, t1, t2: PType): PType =
  result = newTypeS(tyOr, c)
  result.sons = @[t1, t2]
  propagateToOwner(result, t1)
  propagateToOwner(result, t2)
  result.flags.incl((t1.flags + t2.flags) * {tfHasStatic})

proc makeNotType*(c: PContext, t1: PType): PType =
  result = newTypeS(tyNot, c)
  result.sons = @[t1]
  propagateToOwner(result, t1)
  result.flags.incl(t1.flags * {tfHasStatic})

proc nMinusOne*(n: PNode): PNode =
  result = newNode(nkCall, n.info, @[
    newSymNode(getSysMagic("<", mUnaryLt)),
    n])

# Remember to fix the procs below this one when you make changes!
proc makeRangeWithStaticExpr*(c: PContext, n: PNode): PType =
  let intType = getSysType(tyInt)
  result = newTypeS(tyRange, c)
  result.sons = @[intType]
  result.n = newNode(nkRange, n.info, @[
    newIntTypeNode(nkIntLit, 0, intType),
    makeStaticExpr(c, n.nMinusOne)])

template rangeHasStaticIf*(t: PType): bool =
  # this accepts the ranges's node
  t.n != nil and t.n.len > 1 and t.n[1].kind == nkStaticExpr

template getStaticTypeFromRange*(t: PType): PType =
  t.n[1][0][1].typ

proc newTypeS(kind: TTypeKind, c: PContext): PType =
  result = newType(kind, getCurrOwner())

proc errorType*(c: PContext): PType =
  ## creates a type representing an error state
  result = newTypeS(tyError, c)

proc errorNode*(c: PContext, n: PNode): PNode =
  result = newNodeI(nkEmpty, n.info)
  result.typ = errorType(c)

proc fillTypeS(dest: PType, kind: TTypeKind, c: PContext) = 
  dest.kind = kind
  dest.owner = getCurrOwner()
  dest.size = - 1

proc makeRangeType*(c: PContext; first, last: BiggestInt;
                    info: TLineInfo; intType = getSysType(tyInt)): PType =
  var n = newNodeI(nkRange, info)
  addSon(n, newIntTypeNode(nkIntLit, first, intType))
  addSon(n, newIntTypeNode(nkIntLit, last, intType))
  result = newTypeS(tyRange, c)
  result.n = n
  addSonSkipIntLit(result, intType) # basetype of range

proc markIndirect*(c: PContext, s: PSym) {.inline.} =
  if s.kind in {skProc, skConverter, skMethod, skIterator, skClosureIterator}:
    incl(s.flags, sfAddrTaken)
    # XXX add to 'c' for global analysis

proc illFormedAst*(n: PNode) =
  globalError(n.info, errIllFormedAstX, renderTree(n, {renderNoComments}))

proc illFormedAstLocal*(n: PNode) =
  localError(n.info, errIllFormedAstX, renderTree(n, {renderNoComments}))

proc checkSonsLen*(n: PNode, length: int) = 
  if sonsLen(n) != length: illFormedAst(n)
  
proc checkMinSonsLen*(n: PNode, length: int) = 
  if sonsLen(n) < length: illFormedAst(n)

proc isTopLevel*(c: PContext): bool {.inline.} = 
  result = c.currentScope.depthLevel <= 2

proc experimentalMode*(c: PContext): bool {.inline.} =
  result = gExperimentalMode or sfExperimental in c.module.flags
