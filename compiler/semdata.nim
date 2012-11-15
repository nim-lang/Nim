#
#
#           The Nimrod Compiler
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
  magicsys, nversion, nimsets, parser, times, passes, rodread, evals

type 
  TOptionEntry* = object of lists.TListEntry # entries to put on a
                                             # stack for pragma parsing
    options*: TOptions
    defaultCC*: TCallingConvention
    dynlib*: PLib
    Notes*: TNoteKinds
    otherPragmas*: PNode      # every pragma can be pushed

  POptionEntry* = ref TOptionEntry
  PProcCon* = ref TProcCon
  TProcCon*{.final.} = object # procedure context; also used for top-level
                              # statements
    owner*: PSym              # the symbol this context belongs to
    resultSym*: PSym          # the result symbol (if we are in a proc)
    nestedLoopCounter*: int   # whether we are in a loop or not
    nestedBlockCounter*: int  # whether we are in a block or not
    InTryStmt*: int           # whether we are in a try statement; works also
                              # in standalone ``except`` and ``finally``
    next*: PProcCon           # used for stacking procedure contexts
  
  TInstantiatedSymbol* {.final.} = object
    genericSym*, instSym*: PSym
    concreteTypes*: seq[PType]
  
  # If we generate an instance of a generic, we'd like to re-use that
  # instance if possible across module boundaries. However, this is not
  # possible if the compilation cache is enabled. So we give up then and use
  # the caching of generics only per module, not per project.
  TGenericsCache* {.final.} = object
    InstTypes*: TIdTable # map PType to PType
    generics*: seq[TInstantiatedSymbol] # a list of the things to compile
    lastGenericIdx*: int      # used for the generics stack
  
  PGenericsCache* = ref TGenericsCache
  PContext* = ref TContext
  TContext* = object of TPassContext # a context represents a module
    module*: PSym              # the module sym belonging to the context
    p*: PProcCon               # procedure context
    generics*: PGenericsCache  # may point to a global or module-local structure
    friendModule*: PSym        # current friend module; may access private data;
                               # this is used so that generic instantiations
                               # can access private object fields
    InstCounter*: int          # to prevent endless instantiations
   
    threadEntries*: TSymSeq    # list of thread entries to check
    tab*: TSymTab              # each module has its own symbol table
    AmbiguousSymbols*: TIntSet # ids of all ambiguous symbols (cannot
                               # store this info in the syms themselves!)
    InGenericContext*: int     # > 0 if we are in a generic type
    InUnrolledContext*: int    # > 0 if we are unrolling a loop
    InCompilesContext*: int    # > 0 if we are in a ``compiles`` magic
    InGenericInst*: int        # > 0 if we are instantiating a generic
    converters*: TSymSeq       # sequence of converters
    patterns*: TSymSeq         # sequence of pattern matchers
    optionStack*: TLinkedList
    symMapping*: TIdTable      # every gensym'ed symbol needs to be mapped
                               # to some new symbol in a generic instantiation
    libs*: TLinkedList         # all libs used by this module
    semConstExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.} # for the pragmas
    semExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.}      # for the pragmas
    semConstBoolExpr*: proc (c: PContext, n: PNode): PNode {.nimcall.} # XXX bite the bullet
    semOverloadedCall*: proc (c: PContext, n, nOrig: PNode,
                              filter: TSymKinds): PNode {.nimcall.}
    semTypeNode*: proc(c: PContext, n: PNode, prev: PType): PType {.nimcall.}
    includedFiles*: TIntSet    # used to detect recursive include files
    userPragmas*: TStrTable
    evalContext*: PEvalContext
    UnknownIdents*: TIntSet    # ids of all unknown identifiers to prevent
                               # naming it multiple times

var
  gGenericsCache: PGenericsCache # save for modularity

proc filename*(c: PContext): string =
  # the module's filename
  return c.module.filename

proc newGenericsCache*(): PGenericsCache =
  new(result)
  initIdTable(result.InstTypes)
  result.generics = @[]

proc newContext*(module: PSym): PContext

proc lastOptionEntry*(c: PContext): POptionEntry
proc newOptionEntry*(): POptionEntry
proc newLib*(kind: TLibKind): PLib
proc addToLib*(lib: PLib, sym: PSym)
proc makePtrType*(c: PContext, baseType: PType): PType
proc makeVarType*(c: PContext, baseType: PType): PType
proc newTypeS*(kind: TTypeKind, c: PContext): PType
proc fillTypeS*(dest: PType, kind: TTypeKind, c: PContext)

# owner handling:
proc getCurrOwner*(): PSym
proc PushOwner*(owner: PSym)
proc PopOwner*()
# implementation

var gOwners*: seq[PSym] = @[]

proc getCurrOwner(): PSym = 
  # owner stack (used for initializing the
  # owner field of syms)
  # the documentation comment always gets
  # assigned to the current owner
  # BUGFIX: global array is needed!
  result = gOwners[high(gOwners)]

proc PushOwner(owner: PSym) = 
  add(gOwners, owner)

proc PopOwner() = 
  var length = len(gOwners)
  if length > 0: setlen(gOwners, length - 1)
  else: InternalError("popOwner")

proc lastOptionEntry(c: PContext): POptionEntry = 
  result = POptionEntry(c.optionStack.tail)

proc pushProcCon*(c: PContext, owner: PSym) {.inline.} = 
  if owner == nil: 
    InternalError("owner is nil")
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
  InitSymTab(result.tab)
  result.AmbiguousSymbols = initIntset()
  initLinkedList(result.optionStack)
  initLinkedList(result.libs)
  append(result.optionStack, newOptionEntry())
  result.module = module
  result.friendModule = module
  result.threadEntries = @[]
  result.converters = @[]
  result.patterns = @[]
  result.includedFiles = initIntSet()
  initStrTable(result.userPragmas)
  if optSymbolFiles notin gGlobalOptions:
    # re-usage of generic instantiations across module boundaries is
    # very nice for code size:
    if gGenericsCache == nil: gGenericsCache = newGenericsCache()
    result.generics = gGenericsCache
  else:
    # we have to give up and use a per-module cache for generic instantiations:
    result.generics = newGenericsCache()
    assert gGenericsCache == nil
  result.UnknownIdents = initIntSet()

proc inclSym(sq: var TSymSeq, s: PSym) =
  var L = len(sq)
  for i in countup(0, L - 1): 
    if sq[i].id == s.id: return 
  setlen(sq, L + 1)
  sq[L] = s

proc addConverter*(c: PContext, conv: PSym) =
  inclSym(c.converters, conv)

proc addPattern*(c: PContext, p: PSym) =
  inclSym(c.patterns, p)

proc newLib(kind: TLibKind): PLib = 
  new(result)
  result.kind = kind          #initObjectSet(result.syms)
  
proc addToLib(lib: PLib, sym: PSym) = 
  #ObjectSetIncl(lib.syms, sym);
  if sym.annex != nil: LocalError(sym.info, errInvalidPragma)
  sym.annex = lib

proc makePtrType(c: PContext, baseType: PType): PType = 
  result = newTypeS(tyPtr, c)
  addSonSkipIntLit(result, baseType.AssertNotNil)

proc makeVarType(c: PContext, baseType: PType): PType = 
  result = newTypeS(tyVar, c)
  addSonSkipIntLit(result, baseType.AssertNotNil)

proc makeTypeDesc*(c: PContext, typ: PType): PType =
  result = newTypeS(tyTypeDesc, c)
  result.addSonSkipIntLit(typ.AssertNotNil)

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

proc makeRangeType*(c: PContext, first, last: biggestInt, 
                    info: TLineInfo): PType = 
  var n = newNodeI(nkRange, info)
  addSon(n, newIntNode(nkIntLit, first))
  addSon(n, newIntNode(nkIntLit, last))
  result = newTypeS(tyRange, c)
  result.n = n
  rawAddSon(result, getSysType(tyInt)) # basetype of range

proc markIndirect*(c: PContext, s: PSym) {.inline.} =
  if s.kind in {skProc, skConverter, skMethod, skIterator}:
    incl(s.flags, sfAddrTaken)
    # XXX add to 'c' for global analysis

proc illFormedAst*(n: PNode) = 
  GlobalError(n.info, errIllFormedAstX, renderTree(n, {renderNoComments}))

proc checkSonsLen*(n: PNode, length: int) = 
  if sonsLen(n) != length: illFormedAst(n)
  
proc checkMinSonsLen*(n: PNode, length: int) = 
  if sonsLen(n) < length: illFormedAst(n)

