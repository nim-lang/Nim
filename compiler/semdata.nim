#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module contains the data structures for the semantic checking phase.

import 
  strutils, lists, options, lexer, ast, astalgo, trees, treetab, wordrecg, 
  ropes, msgs, platform, os, condsyms, idents, renderer, types, extccomp, math, 
  magicsys, nversion, nimsets, parser, times, passes, rodread

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
  
  PContext* = ref TContext
  TContext* = object of TPassContext # a context represents a module
    module*: PSym             # the module sym belonging to the context
    p*: PProcCon              # procedure context
    InstCounter*: int         # to prevent endless instantiations
    generics*: PNode          # a list of the things to compile; list of
                              # nkExprEqExpr nodes which contain the
                              # generic symbol and the instantiated symbol
    lastGenericIdx*: int      # used for the generics stack
    tab*: TSymTab             # each module has its own symbol table
    AmbiguousSymbols*: TIntSet # ids of all ambiguous symbols (cannot
                               # store this info in the syms themselves!)
    converters*: TSymSeq      # sequence of converters
    optionStack*: TLinkedList
    libs*: TLinkedList        # all libs used by this module
    fromCache*: bool          # is the module read from a cache?
    semConstExpr*: proc (c: PContext, n: PNode): PNode # for the pragmas
    semExpr*: proc (c: PContext, n: PNode): PNode      # for the pragmas
    includedFiles*: TIntSet   # used to detect recursive include files
    filename*: string         # the module's filename
    userPragmas*: TStrTable
  

var gInstTypes*: TIdTable # map PType to PType

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
proc makeRangeType*(c: PContext, first, last: biggestInt, info: TLineInfo): PType
  
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
  IntSetInit(result.AmbiguousSymbols)
  initLinkedList(result.optionStack)
  initLinkedList(result.libs)
  append(result.optionStack, newOptionEntry())
  result.module = module
  result.generics = newNode(nkStmtList)
  result.converters = @[]
  result.filename = nimfile
  IntSetInit(result.includedFiles)
  initStrTable(result.userPragmas)

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
  if (baseType == nil): InternalError("makePtrType")
  result = newTypeS(tyPtr, c)
  addSon(result, baseType)

proc makeVarType(c: PContext, baseType: PType): PType = 
  if (baseType == nil): InternalError("makeVarType")
  result = newTypeS(tyVar, c)
  addSon(result, baseType)

proc newTypeS(kind: TTypeKind, c: PContext): PType = 
  result = newType(kind, getCurrOwner())

proc fillTypeS(dest: PType, kind: TTypeKind, c: PContext) = 
  dest.kind = kind
  dest.owner = getCurrOwner()
  dest.size = - 1

proc makeRangeType(c: PContext, first, last: biggestInt, 
                   info: TLineInfo): PType = 
  var n = newNodeI(nkRange, info)
  addSon(n, newIntNode(nkIntLit, first))
  addSon(n, newIntNode(nkIntLit, last))
  result = newTypeS(tyRange, c)
  result.n = n
  addSon(result, getSysType(tyInt)) # basetype of range
  
proc markUsed*(n: PNode, s: PSym) = 
  incl(s.flags, sfUsed)
  if sfDeprecated in s.flags: Message(n.info, warnDeprecated, s.name.s)
  
proc illFormedAst*(n: PNode) = 
  GlobalError(n.info, errIllFormedAstX, renderTree(n, {renderNoComments}))

proc checkSonsLen*(n: PNode, length: int) = 
  if sonsLen(n) != length: illFormedAst(n)
  
proc checkMinSonsLen*(n: PNode, length: int) = 
  if sonsLen(n) < length: illFormedAst(n)
  
initIdTable(gInstTypes)
