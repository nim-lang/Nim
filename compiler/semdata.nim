#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains the data structures for the semantic checking phase.

import
  strutils, intsets, options, lexer, ast, astalgo, trees, treetab,
  wordrecg,
  ropes, msgs, platform, os, condsyms, idents, renderer, types, extccomp, math,
  magicsys, nversion, nimsets, parser, times, passes, vmdef,
  modulegraphs, lineinfos

type
  TOptionEntry* = object      # entries to put on a stack for pragma parsing
    options*: TOptions
    defaultCC*: TCallingConvention
    dynlib*: PLib
    notes*: TNoteKinds
    features*: set[Feature]
    otherPragmas*: PNode      # every pragma can be pushed

  POptionEntry* = ref TOptionEntry
  PProcCon* = ref TProcCon
  TProcCon* = object          # procedure context; also used for top-level
                              # statements
    owner*: PSym              # the symbol this context belongs to
    resultSym*: PSym          # the result symbol (if we are in a proc)
    selfSym*: PSym            # the 'self' symbol (if available)
    nestedLoopCounter*: int   # whether we are in a loop or not
    nestedBlockCounter*: int  # whether we are in a block or not
    inTryStmt*: int           # whether we are in a try statement; works also
                              # in standalone ``except`` and ``finally``
    next*: PProcCon           # used for stacking procedure contexts
    wasForwarded*: bool       # whether the current proc has a separate header
    mappingExists*: bool
    mapping*: TIdTable

  TMatchedConcept* = object
    candidateType*: PType
    prev*: ptr TMatchedConcept
    depth*: int

  TInstantiationPair* = object
    genericSym*: PSym
    inst*: PInstantiation

  TExprFlag* = enum
    efLValue, efWantIterator, efInTypeof,
    efNeedStatic,
      # Use this in contexts where a static value is mandatory
    efPreferStatic,
      # Use this in contexts where a static value could bring more
      # information, but it's not strictly mandatory. This may become
      # the default with implicit statics in the future.
    efPreferNilResult,
      # Use this if you want a certain result (e.g. static value),
      # but you don't want to trigger a hard error. For example,
      # you may be in position to supply a better error message
      # to the user.
    efWantStmt, efAllowStmt, efDetermineType, efExplain,
    efAllowDestructor, efWantValue, efOperand, efNoSemCheck,
    efNoEvaluateGeneric, efInCall, efFromHlo,
    efNoUndeclared
      # Use this if undeclared identifiers should not raise an error during
      # overload resolution.

  TExprFlags* = set[TExprFlag]

  PContext* = ref TContext
  TContext* = object of TPassContext # a context represents a module
    enforceVoidContext*: PType
    module*: PSym              # the module sym belonging to the context
    currentScope*: PScope      # current scope
    importTable*: PScope       # scope for all imported symbols
    topLevelScope*: PScope     # scope for all top-level symbols
    p*: PProcCon               # procedure context
    matchedConcept*: ptr TMatchedConcept # the current concept being matched
    friendModules*: seq[PSym]  # friend modules; may access private data;
                               # this is used so that generic instantiations
                               # can access private object fields
    instCounter*: int          # to prevent endless instantiations

    ambiguousSymbols*: IntSet  # ids of all ambiguous symbols (cannot
                               # store this info in the syms themselves!)
    inGenericContext*: int     # > 0 if we are in a generic type
    inStaticContext*: int      # > 0 if we are inside a static: block
    inUnrolledContext*: int    # > 0 if we are unrolling a loop
    compilesContextId*: int    # > 0 if we are in a ``compiles`` magic
    compilesContextIdGenerator*: int
    inGenericInst*: int        # > 0 if we are instantiating a generic
    converters*: seq[PSym]
    patterns*: seq[PSym]       # sequence of pattern matchers
    optionStack*: seq[POptionEntry]
    symMapping*: TIdTable      # every gensym'ed symbol needs to be mapped
                               # to some new symbol in a generic instantiation
    libs*: seq[PLib]           # all libs used by this module
    semConstExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.} # for the pragmas
    semExpr*: proc (c: PContext, n: PNode, flags: TExprFlags = {}): PNode {.nimcall.}
    semTryExpr*: proc (c: PContext, n: PNode, flags: TExprFlags = {}): PNode {.nimcall.}
    semTryConstExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.}
    semOperand*: proc (c: PContext, n: PNode, flags: TExprFlags = {}): PNode {.nimcall.}
    semConstBoolExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.} # XXX bite the bullet
    semOverloadedCall*: proc (c: PContext, n, nOrig: PNode,
                              filter: TSymKinds, flags: TExprFlags): PNode {.nimcall.}
    semTypeNode*: proc(c: PContext, n: PNode, prev: PType): PType {.nimcall.}
    semInferredLambda*: proc(c: PContext, pt: TIdTable, n: PNode): PNode
    semGenerateInstance*: proc (c: PContext, fn: PSym, pt: TIdTable,
                                info: TLineInfo): PSym
    includedFiles*: IntSet    # used to detect recursive include files
    pureEnumFields*: TStrTable   # pure enum fields that can be used unambiguously
    userPragmas*: TStrTable
    evalContext*: PEvalContext
    unknownIdents*: IntSet     # ids of all unknown identifiers to prevent
                               # naming it multiple times
    generics*: seq[TInstantiationPair] # pending list of instantiated generics to compile
    topStmts*: int # counts the number of encountered top level statements
    lastGenericIdx*: int      # used for the generics stack
    hloLoopDetector*: int     # used to prevent endless loops in the HLO
    inParallelStmt*: int
    instTypeBoundOp*: proc (c: PContext; dc: PSym; t: PType; info: TLineInfo;
                            op: TTypeAttachedOp; col: int): PSym {.nimcall.}
    selfName*: PIdent
    cache*: IdentCache
    graph*: ModuleGraph
    signatures*: TStrTable
    recursiveDep*: string
    suggestionsMade*: bool
    features*: set[Feature]
    inTypeContext*: int
    typesWithOps*: seq[(PType, PType)] #\
      # We need to instantiate the type bound ops lazily after
      # the generic type has been constructed completely. See
      # tests/destructor/topttree.nim for an example that
      # would otherwise fail.

template config*(c: PContext): ConfigRef = c.graph.config

proc makeInstPair*(s: PSym, inst: PInstantiation): TInstantiationPair =
  result.genericSym = s
  result.inst = inst

proc filename*(c: PContext): string =
  # the module's filename
  return toFilename(c.config, FileIndex c.module.position)

proc scopeDepth*(c: PContext): int {.inline.} =
  result = if c.currentScope != nil: c.currentScope.depthLevel
           else: 0

proc getCurrOwner*(c: PContext): PSym =
  # owner stack (used for initializing the
  # owner field of syms)
  # the documentation comment always gets
  # assigned to the current owner
  result = c.graph.owners[^1]

proc pushOwner*(c: PContext; owner: PSym) =
  add(c.graph.owners, owner)

proc popOwner*(c: PContext) =
  var length = len(c.graph.owners)
  if length > 0: setLen(c.graph.owners, length - 1)
  else: internalError(c.config, "popOwner")

proc lastOptionEntry*(c: PContext): POptionEntry =
  result = c.optionStack[^1]

proc popProcCon*(c: PContext) {.inline.} = c.p = c.p.next

proc put*(p: PProcCon; key, val: PSym) =
  if not p.mappingExists:
    initIdTable(p.mapping)
    p.mappingExists = true
  #echo "put into table ", key.info
  p.mapping.idTablePut(key, val)

proc get*(p: PProcCon; key: PSym): PSym =
  if not p.mappingExists: return nil
  result = PSym(p.mapping.idTableGet(key))

proc getGenSym*(c: PContext; s: PSym): PSym =
  if sfGenSym notin s.flags: return s
  var it = c.p
  while it != nil:
    result = get(it, s)
    if result != nil:
      #echo "got from table ", result.name.s, " ", result.info
      return result
    it = it.next
  result = s

proc considerGenSyms*(c: PContext; n: PNode) =
  if n.kind == nkSym:
    let s = getGenSym(c, n.sym)
    if n.sym != s:
      n.sym = s
  else:
    for i in 0..<n.safeLen:
      considerGenSyms(c, n.sons[i])

proc newOptionEntry*(conf: ConfigRef): POptionEntry =
  new(result)
  result.options = conf.options
  result.defaultCC = ccDefault
  result.dynlib = nil
  result.notes = conf.notes

proc newContext*(graph: ModuleGraph; module: PSym): PContext =
  new(result)
  result.enforceVoidContext = PType(kind: tyTyped)
  result.ambiguousSymbols = initIntSet()
  result.optionStack = @[]
  result.libs = @[]
  result.optionStack.add(newOptionEntry(graph.config))
  result.module = module
  result.friendModules = @[module]
  result.converters = @[]
  result.patterns = @[]
  result.includedFiles = initIntSet()
  initStrTable(result.pureEnumFields)
  initStrTable(result.userPragmas)
  result.generics = @[]
  result.unknownIdents = initIntSet()
  result.cache = graph.cache
  result.graph = graph
  initStrTable(result.signatures)
  result.typesWithOps = @[]
  result.features = graph.config.features

proc inclSym(sq: var seq[PSym], s: PSym) =
  var L = len(sq)
  for i in 0 ..< L:
    if sq[i].id == s.id: return
  setLen(sq, L + 1)
  sq[L] = s

proc addConverter*(c: PContext, conv: PSym) =
  inclSym(c.converters, conv)

proc addPattern*(c: PContext, p: PSym) =
  inclSym(c.patterns, p)

proc newLib*(kind: TLibKind): PLib =
  new(result)
  result.kind = kind          #initObjectSet(result.syms)

proc addToLib*(lib: PLib, sym: PSym) =
  #if sym.annex != nil and not isGenericRoutine(sym):
  #  LocalError(sym.info, errInvalidPragma)
  sym.annex = lib

proc newTypeS*(kind: TTypeKind, c: PContext): PType =
  result = newType(kind, getCurrOwner(c))

proc makePtrType*(c: PContext, baseType: PType): PType =
  result = newTypeS(tyPtr, c)
  addSonSkipIntLit(result, baseType)

proc makeTypeWithModifier*(c: PContext,
                           modifier: TTypeKind,
                           baseType: PType): PType =
  assert modifier in {tyVar, tyLent, tyPtr, tyRef, tyStatic, tyTypeDesc}

  if modifier in {tyVar, tyLent, tyTypeDesc} and baseType.kind == modifier:
    result = baseType
  else:
    result = newTypeS(modifier, c)
    addSonSkipIntLit(result, baseType)

proc makeVarType*(c: PContext, baseType: PType; kind = tyVar): PType =
  if baseType.kind == kind:
    result = baseType
  else:
    result = newTypeS(kind, c)
    addSonSkipIntLit(result, baseType)

proc makeVarType*(owner: PSym, baseType: PType; kind = tyVar): PType =
  if baseType.kind == kind:
    result = baseType
  else:
    result = newType(kind, owner)
    addSonSkipIntLit(result, baseType)

proc makeTypeDesc*(c: PContext, typ: PType): PType =
  if typ.kind == tyTypeDesc:
    result = typ
  else:
    result = newTypeS(tyTypeDesc, c)
    incl result.flags, tfCheckedForDestructor
    result.addSonSkipIntLit(typ)

proc makeTypeSymNode*(c: PContext, typ: PType, info: TLineInfo): PNode =
  let typedesc = newTypeS(tyTypeDesc, c)
  incl typedesc.flags, tfCheckedForDestructor
  typedesc.addSonSkipIntLit(assertNotNil(c.config, typ))
  let sym = newSym(skType, c.cache.idAnon, getCurrOwner(c), info,
                   c.config.options).linkTo(typedesc)
  return newSymNode(sym, info)

proc makeTypeFromExpr*(c: PContext, n: PNode): PType =
  result = newTypeS(tyFromExpr, c)
  assert n != nil
  result.n = n

proc newTypeWithSons*(owner: PSym, kind: TTypeKind, sons: seq[PType]): PType =
  result = newType(kind, owner)
  result.sons = sons

proc newTypeWithSons*(c: PContext, kind: TTypeKind,
                      sons: seq[PType]): PType =
  result = newType(kind, getCurrOwner(c))
  result.sons = sons

proc makeStaticExpr*(c: PContext, n: PNode): PNode =
  result = newNodeI(nkStaticExpr, n.info)
  result.sons = @[n]
  result.typ = if n.typ != nil and n.typ.kind == tyStatic: n.typ
               else: newTypeWithSons(c, tyStatic, @[n.typ])

proc makeAndType*(c: PContext, t1, t2: PType): PType =
  result = newTypeS(tyAnd, c)
  result.sons = @[t1, t2]
  propagateToOwner(result, t1)
  propagateToOwner(result, t2)
  result.flags.incl((t1.flags + t2.flags) * {tfHasStatic})
  result.flags.incl tfHasMeta

proc makeOrType*(c: PContext, t1, t2: PType): PType =
  result = newTypeS(tyOr, c)
  if t1.kind != tyOr and t2.kind != tyOr:
    result.sons = @[t1, t2]
  else:
    template addOr(t1) =
      if t1.kind == tyOr:
        for x in t1.sons: result.rawAddSon x
      else:
        result.rawAddSon t1
    addOr(t1)
    addOr(t2)
  propagateToOwner(result, t1)
  propagateToOwner(result, t2)
  result.flags.incl((t1.flags + t2.flags) * {tfHasStatic})
  result.flags.incl tfHasMeta

proc makeNotType*(c: PContext, t1: PType): PType =
  result = newTypeS(tyNot, c)
  result.sons = @[t1]
  propagateToOwner(result, t1)
  result.flags.incl(t1.flags * {tfHasStatic})
  result.flags.incl tfHasMeta

proc nMinusOne(c: PContext; n: PNode): PNode =
  result = newNode(nkCall, n.info, @[
    newSymNode(getSysMagic(c.graph, n.info, "pred", mPred)), n])

# Remember to fix the procs below this one when you make changes!
proc makeRangeWithStaticExpr*(c: PContext, n: PNode): PType =
  let intType = getSysType(c.graph, n.info, tyInt)
  result = newTypeS(tyRange, c)
  result.sons = @[intType]
  if n.typ != nil and n.typ.n == nil:
    result.flags.incl tfUnresolved
  result.n = newNode(nkRange, n.info, @[
    newIntTypeNode(nkIntLit, 0, intType),
    makeStaticExpr(c, nMinusOne(c, n))])

template rangeHasUnresolvedStatic*(t: PType): bool =
  tfUnresolved in t.flags

proc errorType*(c: PContext): PType =
  ## creates a type representing an error state
  result = newTypeS(tyError, c)
  result.flags.incl tfCheckedForDestructor

proc errorNode*(c: PContext, n: PNode): PNode =
  result = newNodeI(nkEmpty, n.info)
  result.typ = errorType(c)

proc fillTypeS*(dest: PType, kind: TTypeKind, c: PContext) =
  dest.kind = kind
  dest.owner = getCurrOwner(c)
  dest.size = - 1

proc makeRangeType*(c: PContext; first, last: BiggestInt;
                    info: TLineInfo; intType: PType = nil): PType =
  let intType = if intType != nil: intType else: getSysType(c.graph, info, tyInt)
  var n = newNodeI(nkRange, info)
  addSon(n, newIntTypeNode(nkIntLit, first, intType))
  addSon(n, newIntTypeNode(nkIntLit, last, intType))
  result = newTypeS(tyRange, c)
  result.n = n
  addSonSkipIntLit(result, intType) # basetype of range

proc markIndirect*(c: PContext, s: PSym) {.inline.} =
  if s.kind in {skProc, skFunc, skConverter, skMethod, skIterator}:
    incl(s.flags, sfAddrTaken)
    # XXX add to 'c' for global analysis

proc illFormedAst*(n: PNode; conf: ConfigRef) =
  globalError(conf, n.info, errIllFormedAstX, renderTree(n, {renderNoComments}))

proc illFormedAstLocal*(n: PNode; conf: ConfigRef) =
  localError(conf, n.info, errIllFormedAstX, renderTree(n, {renderNoComments}))

proc checkSonsLen*(n: PNode, length: int; conf: ConfigRef) =
  if sonsLen(n) != length: illFormedAst(n, conf)

proc checkMinSonsLen*(n: PNode, length: int; conf: ConfigRef) =
  if sonsLen(n) < length: illFormedAst(n, conf)

proc isTopLevel*(c: PContext): bool {.inline.} =
  result = c.currentScope.depthLevel <= 2
