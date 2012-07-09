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

  POptionEntry* = ref TOptionEntry
  PProcCon* = ref TProcCon
  TProcCon*{.final.} = object # procedure context; also used for top-level
                              # statements
    owner*: PSym              # the symbol this context belongs to
    resultSym*: PSym          # the result symbol (if we are in a proc)
    nestedLoopCounter*: int   # whether we are in a loop or not
    nestedBlockCounter*: int  # whether we are in a block or not
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
    InGenericContext*: int     # > 0 if we are in a generic
    InUnrolledContext*: int    # > 0 if we are unrolling a loop
    converters*: TSymSeq       # sequence of converters
    optionStack*: TLinkedList
    libs*: TLinkedList         # all libs used by this module
    semConstExpr*: proc (c: PContext, n: PNode): PNode # for the pragmas
    semExpr*: proc (c: PContext, n: PNode): PNode      # for the pragmas
    semConstBoolExpr*: proc (c: PContext, n: PNode): PNode # XXX bite the bullet
    includedFiles*: TIntSet    # used to detect recursive include files
    filename*: string          # the module's filename
    userPragmas*: TStrTable
    evalContext*: PEvalContext

var
  gGenericsCache: PGenericsCache # save for modularity

proc newGenericsCache: PGenericsCache =
  new(result)
  initIdTable(result.InstTypes)
  result.generics = @[]

proc newContext*(module: PSym, nimfile: string): PContext

proc lastOptionEntry*(c: PContext): POptionEntry
proc newOptionEntry*(): POptionEntry
proc addConverter*(c: PContext, conv: PSym)
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

var gOwners: seq[PSym] = @[]

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
  if (length <= 0): InternalError("popOwner")
  setlen(gOwners, length - 1)

proc lastOptionEntry(c: PContext): POptionEntry = 
  result = POptionEntry(c.optionStack.tail)

proc pushProcCon*(c: PContext, owner: PSym) {.inline.} = 
  if owner == nil: InternalError("owner is nil")
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

proc newContext(module: PSym, nimfile: string): PContext = 
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
  result.filename = nimfile
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

proc addConverter(c: PContext, conv: PSym) = 
  var L = len(c.converters)
  for i in countup(0, L - 1): 
    if c.converters[i].id == conv.id: return 
  setlen(c.converters, L + 1)
  c.converters[L] = conv

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
  
proc markUsed*(n: PNode, s: PSym) = 
  incl(s.flags, sfUsed)
  if {sfDeprecated, sfError} * s.flags != {}:
    if sfDeprecated in s.flags: Message(n.info, warnDeprecated, s.name.s)
    if sfError in s.flags: LocalError(n.info, errWrongSymbolX, s.name.s)

proc markIndirect*(c: PContext, s: PSym) =
  if s.kind in {skProc, skConverter, skMethod, skIterator}:
    incl(s.flags, sfAddrTaken)
    # XXX add to 'c' for global analysis

proc useSym*(sym: PSym): PNode =
  result = newSymNode(sym)
  markUsed(result, sym)

proc illFormedAst*(n: PNode) = 
  GlobalError(n.info, errIllFormedAstX, renderTree(n, {renderNoComments}))

proc checkSonsLen*(n: PNode, length: int) = 
  if sonsLen(n) != length: illFormedAst(n)
  
proc checkMinSonsLen*(n: PNode, length: int) = 
  if sonsLen(n) < length: illFormedAst(n)

