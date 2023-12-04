#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# abstract syntax tree + symbol table

import
  lineinfos, options, idents, int128, wordrecg, nodes, nimtypes

import std/[tables, hashes]
from std/strutils import toLowerAscii

when defined(nimPreviewSlimSystem):
  import std/assertions

export int128

export PSym, PType, TType, PNode, TNodeKind, TNodeFlag, TSymFlag

var
  eqTypeFlags* = {tfIterator, tfNotNil, tfVarIsPtr, tfGcSafe, tfNoSideEffect, tfIsOutParam}
    ## type flags that are essential for type equality.
    ## This is now a variable because for emulation of version:1.0 we
    ## might exclude {tfGcSafe, tfNoSideEffect}.

type
  TPair* = object
    key*, val*: RootRef

  TPairSeq* = seq[TPair]

  TIdPair* = object
    key*: PIdObj
    val*: RootRef

  TIdPairSeq* = seq[TIdPair]
  TIdTable* = object # the same as table[PIdent] of PObject
    counter*: int
    data*: TIdPairSeq

  TIdNodePair* = object
    key*: PIdObj
    val*: PNode

  TIdNodePairSeq* = seq[TIdNodePair]
  TIdNodeTable* = object # the same as table[PIdObj] of PNode
    counter*: int
    data*: TIdNodePairSeq

  TNodePair* = object
    h*: Hash                 # because it is expensive to compute!
    key*: PNode
    val*: int

  TNodePairSeq* = seq[TNodePair]
  TNodeTable* = object # the same as table[PNode] of int;
                                # nodes are compared by structure!
    counter*: int
    data*: TNodePairSeq

  TObjectSeq* = seq[RootRef]
  TObjectSet* = object
    counter*: int
    data*: TObjectSeq

  TImplication* = enum
    impUnknown, impNo, impYes

template nodeId(n: PNode): int = cast[int](n)

type Gconfig = object
  # we put comments in a side channel to avoid increasing `sizeof(TNode)`, which
  # reduces memory usage given that `PNode` is the most allocated type by far.
  comments: Table[int, string] # nodeId => comment
  useIc*: bool

var gconfig {.threadvar.}: Gconfig

proc setUseIc*(useIc: bool) = gconfig.useIc = useIc

proc comment*(n: PNode): string =
  if nfHasComment in n.flags and not gconfig.useIc:
    # IC doesn't track comments, see `packed_ast`, so this could fail
    result = gconfig.comments[n.nodeId]
  else:
    result = ""

proc `comment=`*(n: PNode, a: string) =
  let id = n.nodeId
  if a.len > 0:
    # if needed, we could periodically cleanup gconfig.comments when its size increases,
    # to ensure only live nodes (and with nfHasComment) have an entry in gconfig.comments;
    # for compiling compiler, the waste is very small:
    # num calls to newNodeImpl: 14984160 (num of PNode allocations)
    # size of gconfig.comments: 33585
    # num of nodes with comments that were deleted and hence wasted: 3081
    n.flags.incl nfHasComment
    gconfig.comments[id] = a
  elif nfHasComment in n.flags:
    n.flags.excl nfHasComment
    gconfig.comments.del(id)

# BUGFIX: a module is overloadable so that a proc can have the
# same name as an imported module. This is necessary because of
# the poor naming choices in the standard library.

const
  OverloadableSyms* = {skProc, skFunc, skMethod, skIterator,
    skConverter, skModule, skTemplate, skMacro, skEnumField}

  GenericTypes* = {tyGenericInvocation, tyGenericBody,
    tyGenericParam}

  StructuralEquivTypes* = {tyNil, tyTuple, tyArray,
    tySet, tyRange, tyPtr, tyRef, tyVar, tyLent, tySequence, tyProc, tyOpenArray,
    tyVarargs}

  ConcreteTypes* = { # types of the expr that may occur in::
                                 # var x = expr
    tyBool, tyChar, tyEnum, tyArray, tyObject,
    tySet, tyTuple, tyRange, tyPtr, tyRef, tyVar, tyLent, tySequence, tyProc,
    tyPointer,
    tyOpenArray, tyString, tyCstring, tyInt..tyInt64, tyFloat..tyFloat128,
    tyUInt..tyUInt64}
  IntegralTypes* = {tyBool, tyChar, tyEnum, tyInt..tyInt64,
    tyFloat..tyFloat128, tyUInt..tyUInt64} # weird name because it contains tyFloat
  ConstantDataTypes* = {tyArray, tySet,
                                    tyTuple, tySequence}
  NilableTypes* = {tyPointer, tyCstring, tyRef, tyPtr,
    tyProc, tyError} # TODO
  PtrLikeKinds* = {tyPointer, tyPtr} # for VM
  PersistentNodeFlags* = {nfBase2, nfBase8, nfBase16,
                          nfDotSetter, nfDotField,
                          nfIsRef, nfIsPtr, nfPreventCg, nfLL,
                          nfFromTemplate, nfDefaultRefsParam,
                          nfExecuteOnReload, nfLastRead,
                          nfFirstWrite, nfSkipFieldChecking}
  namePos* = 0
  patternPos* = 1    # empty except for term rewriting macros
  genericParamsPos* = 2
  paramsPos* = 3
  pragmasPos* = 4
  miscPos* = 5  # used for undocumented and hacky stuff
  bodyPos* = 6       # position of body; use rodread.getBody() instead!
  resultPos* = 7
  dispatcherPos* = 8

  nfAllFieldsSet* = nfBase2

  nkCallKinds* = {nkCall, nkInfix, nkPrefix, nkPostfix,
                  nkCommand, nkCallStrLit, nkHiddenCallConv}
  nkIdentKinds* = {nkIdent, nkSym, nkAccQuoted, nkOpenSymChoice,
                   nkClosedSymChoice}

  nkPragmaCallKinds* = {nkExprColonExpr, nkCall, nkCallStrLit}
  nkLiterals* = {nkCharLit..nkTripleStrLit}
  nkFloatLiterals* = {nkFloatLit..nkFloat128Lit}
  nkLambdaKinds* = {nkLambda, nkDo}
  declarativeDefs* = {nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef}
  routineDefs* = declarativeDefs + {nkMacroDef, nkTemplateDef}
  procDefs* = nkLambdaKinds + declarativeDefs
  callableDefs* = nkLambdaKinds + routineDefs

  nkSymChoices* = {nkClosedSymChoice, nkOpenSymChoice}
  nkStrKinds* = {nkStrLit..nkTripleStrLit}

  skLocalVars* = {skVar, skLet, skForVar, skParam, skResult}
  skProcKinds* = {skProc, skFunc, skTemplate, skMacro, skIterator,
                  skMethod, skConverter}

  defaultSize = -1
  defaultAlignment = -1
  defaultOffset* = -1

proc getPIdent*(a: PNode): PIdent {.inline.} =
  ## Returns underlying `PIdent` for `{nkSym, nkIdent}`, or `nil`.
  case a.kind
  of nkSym: a.sym.name
  of nkIdent: a.ident
  of nkOpenSymChoice, nkClosedSymChoice: a.sons[0].sym.name
  else: nil

const
  moduleShift = when defined(cpu32): 20 else: 24

template id*(a: PIdObj): int =
  let x = a
  (x.itemId.module.int shl moduleShift) + x.itemId.item.int

type
  IdGenerator* = ref object # unfortunately, we really need the 'shared mutable' aspect here.
    module*: int32
    symId*: int32
    typeId*: int32
    sealed*: bool
    disambTable*: CountTable[PIdent]

const
  PackageModuleId* = -3'i32

proc idGeneratorFromModule*(m: PSym): IdGenerator =
  assert m.kind == skModule
  result = IdGenerator(module: m.itemId.module, symId: m.itemId.item, typeId: 0, disambTable: initCountTable[PIdent]())

proc idGeneratorForPackage*(nextIdWillBe: int32): IdGenerator =
  result = IdGenerator(module: PackageModuleId, symId: nextIdWillBe - 1'i32, typeId: 0, disambTable: initCountTable[PIdent]())

proc nextSymId(x: IdGenerator): ItemId {.inline.} =
  assert(not x.sealed)
  inc x.symId
  result = ItemId(module: x.module, item: x.symId)

proc nextTypeId*(x: IdGenerator): ItemId {.inline.} =
  assert(not x.sealed)
  inc x.typeId
  result = ItemId(module: x.module, item: x.typeId)

when false:
  proc nextId*(x: IdGenerator): ItemId {.inline.} =
    inc x.item
    result = x[]

when false:
  proc storeBack*(dest: var IdGenerator; src: IdGenerator) {.inline.} =
    assert dest.ItemId.module == src.ItemId.module
    if dest.ItemId.item > src.ItemId.item:
      echo dest.ItemId.item, " ", src.ItemId.item, " ", src.ItemId.module
    assert dest.ItemId.item <= src.ItemId.item
    dest = src

var ggDebug* {.deprecated.}: bool ## convenience switch for trying out things

proc isCallExpr*(n: PNode): bool =
  result = n.kind in nkCallKinds

proc discardSons*(father: PNode)

proc len*(n: PNode): int {.inline.} =
  result = n.sons.len

proc safeLen*(n: PNode): int {.inline.} =
  ## works even for leaves.
  if n.kind in {nkNone..nkNilLit}: result = 0
  else: result = n.len

proc safeArrLen*(n: PNode): int {.inline.} =
  ## works for array-like objects (strings passed as openArray in VM).
  if n.kind in {nkStrLit..nkTripleStrLit}: result = n.strVal.len
  elif n.kind in {nkNone..nkFloat128Lit}: result = 0
  else: result = n.len

proc add*(father, son: PNode) =
  assert son != nil
  father.sons.add(son)

proc addAllowNil*(father, son: PNode) {.inline.} =
  father.sons.add(son)

template `[]`*(n: PNode, i: int): PNode = n.sons[i]
template `[]=`*(n: PNode, i: int; x: PNode) = n.sons[i] = x

template `[]`*(n: PNode, i: BackwardsIndex): PNode = n[n.len - i.int]
template `[]=`*(n: PNode, i: BackwardsIndex; x: PNode) = n[n.len - i.int] = x

proc getDeclPragma*(n: PNode): PNode =
  ## return the `nkPragma` node for declaration `n`, or `nil` if no pragma was found.
  ## Currently only supports routineDefs + {nkTypeDef}.
  case n.kind
  of routineDefs:
    if n[pragmasPos].kind != nkEmpty: result = n[pragmasPos]
    else: result = nil
  of nkTypeDef:
    #[
    type F3*{.deprecated: "x3".} = int

    TypeSection
      TypeDef
        PragmaExpr
          Postfix
            Ident "*"
            Ident "F3"
          Pragma
            ExprColonExpr
              Ident "deprecated"
              StrLit "x3"
        Empty
        Ident "int"
    ]#
    if n[0].kind == nkPragmaExpr:
      result = n[0][1]
    else:
      result = nil
  else:
    # support as needed for `nkIdentDefs` etc.
    result = nil
  if result != nil:
    assert result.kind == nkPragma, $(result.kind, n.kind)

proc extractPragma*(s: PSym): PNode =
  ## gets the pragma node of routine/type/var/let/const symbol `s`
  if s.kind in routineKinds:
    result = s.ast[pragmasPos]
  elif s.kind in {skType, skVar, skLet, skConst}:
    if s.ast != nil and s.ast.len > 0:
      if s.ast[0].kind == nkPragmaExpr and s.ast[0].len > 1:
        # s.ast = nkTypedef / nkPragmaExpr / [nkSym, nkPragma]
        result = s.ast[0][1]
      else:
        result = nil
    else:
      result = nil
  else:
    result = nil
  assert result == nil or result.kind == nkPragma

proc skipPragmaExpr*(n: PNode): PNode =
  ## if pragma expr, give the node the pragmas are applied to,
  ## otherwise give node itself
  if n.kind == nkPragmaExpr:
    result = n[0]
  else:
    result = n

proc setInfoRecursive*(n: PNode, info: TLineInfo) =
  ## set line info recursively
  if n != nil:
    for i in 0..<n.safeLen: setInfoRecursive(n[i], info)
    n.info = info

when defined(useNodeIds):
  const nodeIdToDebug* = -1 # 2322968
  var gNodeId: int

template setIdMaybe() =
  when defined(useNodeIds):
    result.id = gNodeId
    if result.id == nodeIdToDebug:
      echo "KIND ", result.kind
      writeStackTrace()
    inc gNodeId

proc newNode*(kind: TNodeKind): PNode =
  ## new node with unknown line info, no type, and no children
  result = PNode(kind: kind, info: unknownLineInfo)
  setIdMaybe()

proc newNodeI*(kind: TNodeKind, info: TLineInfo): PNode =
  ## new node with line info, no type, and no children
  result = PNode(kind: kind, info: info)
  setIdMaybe()

proc newNodeI*(kind: TNodeKind, info: TLineInfo, children: int): PNode =
  ## new node with line info, type, and children
  result = PNode(kind: kind, info: info)
  if children > 0:
    newSeq(result.sons, children)
  setIdMaybe()

proc newNodeIT*(kind: TNodeKind, info: TLineInfo, typ: PType): PNode =
  ## new node with line info, type, and no children
  result = newNode(kind)
  result.info = info
  result.typ = typ

proc newTree*(kind: TNodeKind; children: varargs[PNode]): PNode =
  result = newNode(kind)
  if children.len > 0:
    result.info = children[0].info
  result.sons = @children

proc newTreeI*(kind: TNodeKind; info: TLineInfo; children: varargs[PNode]): PNode =
  result = newNodeI(kind, info)
  if children.len > 0:
    result.info = children[0].info
  result.sons = @children

proc newTreeIT*(kind: TNodeKind; info: TLineInfo; typ: PType; children: varargs[PNode]): PNode =
  result = newNodeIT(kind, info, typ)
  if children.len > 0:
    result.info = children[0].info
  result.sons = @children

template previouslyInferred*(t: PType): PType =
  if t.sons.len > 1: t.lastSon else: nil

when false:
  import tables, strutils
  var x: CountTable[string]

  addQuitProc proc () {.noconv.} =
    for k, v in pairs(x):
      echo k
      echo v

proc newSym*(symKind: TSymKind, name: PIdent, idgen: IdGenerator; owner: PSym,
             info: TLineInfo; options: TOptions = {}): PSym =
  # generates a symbol and initializes the hash field too
  assert not name.isNil
  let id = nextSymId idgen
  result = PSym(name: name, kind: symKind, flags: {}, info: info, itemId: id,
                options: options, owner: owner, offset: defaultOffset,
                disamb: getOrDefault(idgen.disambTable, name).int32)
  idgen.disambTable.inc name
  when false:
    if id.module == 48 and id.item == 39:
      writeStackTrace()
      echo "kind ", symKind, " ", name.s
      if owner != nil: echo owner.name.s

proc astdef*(s: PSym): PNode =
  # get only the definition (initializer) portion of the ast
  if s.ast != nil and s.ast.kind in {nkIdentDefs, nkConstDef}:
    s.ast[2]
  else:
    s.ast

proc isMetaType*(g: TypeGraph; t: PType): bool =
  if g[t].kind in tyMetaTypes:
    result = true
  elif g[t].kind == tyStatic:
    result = g.n.getOrDefault(t) == nil
  else:
    result = tfHasMeta in g.flags.getOrDefault(t)

proc isUnresolvedStatic*(g: TypeGraph; t: PType): bool =
  result = g[t].kind == tyStatic and g.n.getOrDefault(t) == nil

proc linkTo*(g: var TypeGraph; t: PType; s: PSym): PType {.discardable.} =
  g.prepareExt(t).sym = s # t.sym = s
  s.typ = t
  result = t

proc linkTo*(g: var TypeGraph; s: PSym; t: PType): PSym {.discardable.} =
  g.prepareExt(t).sym = s
  s.typ = t
  result = s

template fileIdx*(c: PSym): FileIndex =
  # XXX: this should be used only on module symbols
  c.position.FileIndex

template filename*(c: PSym): string =
  # XXX: this should be used only on module symbols
  c.position.FileIndex.toFilename

proc appendToModule*(m: PSym, n: PNode) =
  ## The compiler will use this internally to add nodes that will be
  ## appended to the module after the sem pass
  if m.ast == nil:
    m.ast = newNode(nkStmtList)
    m.ast.sons = @[n]
  else:
    assert m.ast.kind == nkStmtList
    m.ast.sons.add(n)

const                         # for all kind of hash tables:
  GrowthFactor* = 2           # must be power of 2, > 0
  StartSize* = 8              # must be power of 2, > 0

proc copyStrTable*(dest: var TStrTable, src: TStrTable) =
  dest.counter = src.counter
  setLen(dest.data, src.data.len)
  for i in 0..high(src.data): dest.data[i] = src.data[i]

proc copyIdTable*(dest: var TIdTable, src: TIdTable) =
  dest.counter = src.counter
  newSeq(dest.data, src.data.len)
  for i in 0..high(src.data): dest.data[i] = src.data[i]

proc copyObjectSet*(dest: var TObjectSet, src: TObjectSet) =
  dest.counter = src.counter
  setLen(dest.data, src.data.len)
  for i in 0..high(src.data): dest.data[i] = src.data[i]

proc discardSons*(father: PNode) =
  father.sons = @[]

proc withInfo*(n: PNode, info: TLineInfo): PNode =
  n.info = info
  return n

proc newIdentNode*(ident: PIdent, info: TLineInfo): PNode =
  result = newNode(nkIdent)
  result.ident = ident
  result.info = info

proc newSymNode*(sym: PSym): PNode =
  result = newNode(nkSym)
  result.sym = sym
  result.typ = sym.typ
  result.info = sym.info

proc newSymNode*(sym: PSym, info: TLineInfo): PNode =
  result = newNode(nkSym)
  result.sym = sym
  result.typ = sym.typ
  result.info = info

proc newIntNode*(kind: TNodeKind, intVal: BiggestInt): PNode =
  result = newNode(kind)
  result.intVal = intVal

proc newIntNode*(kind: TNodeKind, intVal: Int128): PNode =
  result = newNode(kind)
  result.intVal = castToInt64(intVal)

proc lastSon*(n: PNode): PNode = n.sons[^1]

proc skipTypes*(g: TypeGraph; t: PType; kinds: set[TTypeKind]): PType =
  ## Used throughout the compiler code to test whether a type tree contains or
  ## doesn't contain a specific type/types - it is often the case that only the
  ## last child nodes of a type tree need to be searched. This is a really hot
  ## path within the compiler!
  result = t
  while g[result].kind in kinds: result = firstSon(result)

proc newIntTypeNode*(g: TypeGraph; intVal: BiggestInt, typ: PType): PNode =
  let kind = g[skipTypes(g, typ, abstractVarRange)].kind
  case kind
  of tyInt:     result = newNode(nkIntLit)
  of tyInt8:    result = newNode(nkInt8Lit)
  of tyInt16:   result = newNode(nkInt16Lit)
  of tyInt32:   result = newNode(nkInt32Lit)
  of tyInt64:   result = newNode(nkInt64Lit)
  of tyChar:    result = newNode(nkCharLit)
  of tyUInt:    result = newNode(nkUIntLit)
  of tyUInt8:   result = newNode(nkUInt8Lit)
  of tyUInt16:  result = newNode(nkUInt16Lit)
  of tyUInt32:  result = newNode(nkUInt32Lit)
  of tyUInt64:  result = newNode(nkUInt64Lit)
  of tyBool, tyEnum:
    # XXX: does this really need to be the kind nkIntLit?
    result = newNode(nkIntLit)
  of tyStatic: # that's a pre-existing bug, will fix in another PR
    result = newNode(nkIntLit)
  else: raiseAssert $kind
  result.intVal = intVal
  result.typ = typ

proc newIntTypeNode*(g: TypeGraph; intVal: Int128, typ: PType): PNode =
  # XXX: introduce range check
  newIntTypeNode(g, castToInt64(intVal), typ)

proc newFloatNode*(kind: TNodeKind, floatVal: BiggestFloat): PNode =
  result = newNode(kind)
  result.floatVal = floatVal

proc newStrNode*(kind: TNodeKind, strVal: string): PNode =
  result = newNode(kind)
  result.strVal = strVal

proc newStrNode*(strVal: string; info: TLineInfo): PNode =
  result = newNodeI(nkStrLit, info)
  result.strVal = strVal

proc newProcNode*(kind: TNodeKind, info: TLineInfo, body: PNode,
                 params,
                 name, pattern, genericParams,
                 pragmas, exceptions: PNode): PNode =
  result = newNodeI(kind, info)
  result.sons = @[name, pattern, genericParams, params,
                  pragmas, exceptions, body]

const
  AttachedOpToStr*: array[TTypeAttachedOp, string] = [
    "=wasMoved", "=destroy", "=copy", "=dup", "=sink", "=trace", "=deepcopy"]

proc `$`*(s: PSym): string =
  if s != nil:
    result = s.name.s & "@" & $s.id
  else:
    result = "<nil>"

when false:
  iterator items*(t: PType): PType =
    for i in 0..<t.sons.len: yield t.sons[i]

  iterator pairs*(n: PType): tuple[i: int, n: PType] =
    for i in 0..<n.sons.len: yield (i, n.sons[i])

  proc newType*(kind: TTypeKind, idgen: IdGenerator; owner: PSym, sons: seq[PType] = @[]): PType =
    let id = nextTypeId idgen
    result = PType(kind: kind, owner: owner, size: defaultSize,
                  align: defaultAlignment, itemId: id,
                  uniqueId: id, sons: sons)
    when false:
      if result.itemId.module == 55 and result.itemId.item == 2:
        echo "KNID ", kind
        writeStackTrace()

  template newType*(kind: TTypeKind, id: IdGenerator; owner: PSym, parent: PType): PType =
    newType(kind, id, owner, parent.sons)

  proc setSons*(dest: PType; sons: seq[PType]) {.inline.} = dest.sons = sons

  proc addSon*(father, son: PType) =
    # todo fixme: in IC, `son` might be nil
    father.sons.add(son)

  proc newSons*(father: PNode; length: int) =
    setLen(father.sons, length)

  proc assignType*(dest, src: PType) =
    dest.kind = src.kind
    dest.flags = src.flags
    dest.callConv = src.callConv
    dest.n = src.n
    dest.size = src.size
    dest.align = src.align
    # this fixes 'type TLock = TSysLock':
    if src.sym != nil:
      if dest.sym != nil:
        dest.sym.flags.incl src.sym.flags-{sfUsed, sfExported}
        if dest.sym.annex == nil: dest.sym.annex = src.sym.annex
        mergeLoc(dest.sym.loc, src.sym.loc)
      else:
        dest.sym = src.sym
    newSons(dest, src.len)
    for i in 0..<src.len: dest[i] = src[i]

  proc copyType*(t: PType, idgen: IdGenerator, owner: PSym): PType =
    result = newType(t.kind, idgen, owner)
    assignType(result, t)
    result.sym = t.sym          # backend-info should not be copied

  proc exactReplica*(t: PType): PType =
    result = PType(kind: t.kind, owner: t.owner, size: defaultSize,
                  align: defaultAlignment, itemId: t.itemId,
                  uniqueId: t.uniqueId)
    assignType(result, t)
    result.sym = t.sym          # backend-info should not be copied

proc mergeLoc(a: var TLoc, b: TLoc) =
  if a.k == low(typeof(a.k)): a.k = b.k
  if a.storage == low(typeof(a.storage)): a.storage = b.storage
  a.flags.incl b.flags
  if a.lode == nil: a.lode = b.lode
  if a.r == "": a.r = b.r

proc copySym*(s: PSym; idgen: IdGenerator): PSym =
  result = newSym(s.kind, s.name, idgen, s.owner, s.info, s.options)
  #result.ast = nil            # BUGFIX; was: s.ast which made problems
  result.typ = s.typ
  result.flags = s.flags
  result.magic = s.magic
  result.options = s.options
  result.position = s.position
  result.loc = s.loc
  result.annex = s.annex      # BUGFIX
  result.constraint = s.constraint
  if result.kind in {skVar, skLet, skField}:
    result.guard = s.guard
    result.bitsize = s.bitsize
    result.alignment = s.alignment

proc createModuleAlias*(s: PSym, idgen: IdGenerator, newIdent: PIdent, info: TLineInfo;
                        options: TOptions): PSym =
  result = newSym(s.kind, newIdent, idgen, s.owner, info, options)
  # keep ID!
  result.ast = s.ast
  #result.id = s.id # XXX figure out what to do with the ID.
  result.flags = s.flags
  result.options = s.options
  result.position = s.position
  result.loc = s.loc
  result.annex = s.annex

proc initStrTable*(): TStrTable =
  result = TStrTable(counter: 0)
  newSeq(result.data, StartSize)

proc initIdTable*(): TIdTable =
  result = TIdTable(counter: 0)
  newSeq(result.data, StartSize)

proc resetIdTable*(x: var TIdTable) =
  x.counter = 0
  # clear and set to old initial size:
  setLen(x.data, 0)
  setLen(x.data, StartSize)

proc initObjectSet*(): TObjectSet =
  result = TObjectSet(counter: 0)
  newSeq(result.data, StartSize)

proc initIdNodeTable*(): TIdNodeTable =
  result = TIdNodeTable(counter: 0)
  newSeq(result.data, StartSize)

proc initNodeTable*(): TNodeTable =
  result = TNodeTable(counter: 0)
  newSeq(result.data, StartSize)

proc skipTypes*(g: TypeGraph; t: PType; kinds: set[TTypeKind]; maxIters: int): PType =
  result = t
  var i = maxIters
  while g[result].kind in kinds:
    result = firstSon(result)
    dec i
    if i == 0: return VoidId

when false:
  proc skipTypesOrNil*(g: TypeGraph; t: PType; kinds: set[TTypeKind]): PType =
    ## same as skipTypes but handles 'nil'
    result = t
    while g[result].kind in kinds:
      if result.len == 0: return VoidId
      result = firstSon(result)

proc isGCedMem*(g: TypeGraph; t: PType): bool {.inline.} =
  result = g[t].kind in {tyString, tyRef, tySequence} or
           g[t].kind == tyProc and g.callConv.getOrDefault(t) == ccClosure

proc propagateToOwner*(g: var TypeGraph; owner, elem: PType; propagateHasAsgn = true) =
  let ef = g.flags.getOrDefault(elem)
  g.prepareFlags(owner).incl(ef * {tfHasMeta, tfTriggersCompileTime})
  if tfNotNil in ef:
    if g[owner].kind in {tyGenericInst, tyGenericBody, tyGenericInvocation}:
      g.flags[owner].incl tfNotNil

  if g.isMetaType(elem):
    g.flags[owner].incl tfHasMeta

  let mask = ef * {tfHasAsgn, tfHasOwned}
  if mask != {} and propagateHasAsgn:
    let o2 = g.skipTypes(owner, {tyGenericInst, tyAlias, tySink})
    if g[o2].kind in {tyTuple, tyObject, tyArray,
                     tySequence, tySet, tyDistinct}:
      g.prepareFlags(o2).incl mask
      g.flags[owner].incl mask

  if g[owner].kind notin {tyProc, tyGenericInst, tyGenericBody,
                          tyGenericInvocation, tyPtr}:
    let elemB = g.skipTypes(elem, {tyGenericInst, tyAlias, tySink})
    if g.isGCedMem(elemB) or tfHasGCedMem in g.flags.getOrDefault(elemB):
      # for simplicity, we propagate this flag even to generics. We then
      # ensure this doesn't bite us in sempass2.
      g.flags[owner].incl tfHasGCedMem

when false:
  proc rawAddSon*(father, son: PType; propagateHasAsgn = true) =
    father.sons.add(son)
    if not son.isNil: propagateToOwner(father, son, propagateHasAsgn)

  proc rawAddSonNoPropagationOfTypeFlags*(father, son: PType) =
    father.sons.add(son)

proc addSonNilAllowed*(father, son: PNode) =
  father.sons.add(son)

proc delSon*(father: PNode; idx: int) =
  if father.len == 0: return
  for i in idx..<father.len - 1: father[i] = father[i + 1]
  father.sons.setLen(father.len - 1)

proc copyNode*(src: PNode): PNode =
  # does not copy its sons!
  if src == nil:
    return nil
  result = newNode(src.kind)
  result.info = src.info
  result.typ = src.typ
  result.flags = src.flags * PersistentNodeFlags
  result.comment = src.comment
  when defined(useNodeIds):
    if result.id == nodeIdToDebug:
      echo "COMES FROM ", src.id
  case src.kind
  of nkCharLit..nkUInt64Lit: result.intVal = src.intVal
  of nkFloatLiterals: result.floatVal = src.floatVal
  of nkSym: result.sym = src.sym
  of nkIdent: result.ident = src.ident
  of nkStrLit..nkTripleStrLit: result.strVal = src.strVal
  else: discard
  when defined(nimsuggest):
    result.endInfo = src.endInfo

template transitionNodeKindCommon(k: TNodeKind) =
  let obj {.inject.} = n[]
  n[] = TNode(kind: k, typ: obj.typ, info: obj.info, flags: obj.flags)
  # n.comment = obj.comment # shouldn't be needed, the address doesnt' change
  when defined(useNodeIds):
    n.id = obj.id

proc transitionSonsKind*(n: PNode, kind: range[nkComesFrom..nkTupleConstr]) =
  transitionNodeKindCommon(kind)
  n.sons = obj.sons

proc transitionIntKind*(n: PNode, kind: range[nkCharLit..nkUInt64Lit]) =
  transitionNodeKindCommon(kind)
  n.intVal = obj.intVal

proc transitionIntToFloatKind*(n: PNode, kind: range[nkFloatLit..nkFloat128Lit]) =
  transitionNodeKindCommon(kind)
  n.floatVal = BiggestFloat(obj.intVal)

proc transitionNoneToSym*(n: PNode) =
  transitionNodeKindCommon(nkSym)

template transitionSymKindCommon*(k: TSymKind) =
  let obj {.inject.} = s[]
  s[] = TSym(kind: k, itemId: obj.itemId, magic: obj.magic, typ: obj.typ, name: obj.name,
             info: obj.info, owner: obj.owner, flags: obj.flags, ast: obj.ast,
             options: obj.options, position: obj.position, offset: obj.offset,
             loc: obj.loc, annex: obj.annex, constraint: obj.constraint)
  when hasFFI:
    s.cname = obj.cname
  when defined(nimsuggest):
    s.allUsages = obj.allUsages

proc transitionGenericParamToType*(s: PSym) =
  transitionSymKindCommon(skType)

proc transitionRoutineSymKind*(s: PSym, kind: range[skProc..skTemplate]) =
  transitionSymKindCommon(kind)
  s.gcUnsafetyReason = obj.gcUnsafetyReason
  s.transformedBody = obj.transformedBody

proc transitionToLet*(s: PSym) =
  transitionSymKindCommon(skLet)
  s.guard = obj.guard
  s.bitsize = obj.bitsize
  s.alignment = obj.alignment

template copyNodeImpl(dst, src, processSonsStmt) =
  if src == nil: return
  dst = newNode(src.kind)
  dst.info = src.info
  when defined(nimsuggest):
    result.endInfo = src.endInfo
  dst.typ = src.typ
  dst.flags = src.flags * PersistentNodeFlags
  dst.comment = src.comment
  when defined(useNodeIds):
    if dst.id == nodeIdToDebug:
      echo "COMES FROM ", src.id
  case src.kind
  of nkCharLit..nkUInt64Lit: dst.intVal = src.intVal
  of nkFloatLiterals: dst.floatVal = src.floatVal
  of nkSym: dst.sym = src.sym
  of nkIdent: dst.ident = src.ident
  of nkStrLit..nkTripleStrLit: dst.strVal = src.strVal
  else: processSonsStmt

proc shallowCopy*(src: PNode): PNode =
  # does not copy its sons, but provides space for them:
  copyNodeImpl(result, src):
    newSeq(result.sons, src.len)

proc copyTree*(src: PNode): PNode =
  # copy a whole syntax tree; performs deep copying
  copyNodeImpl(result, src):
    newSeq(result.sons, src.len)
    for i in 0..<src.len:
      result[i] = copyTree(src[i])

proc copyTreeWithoutNode*(src, skippedNode: PNode): PNode =
  copyNodeImpl(result, src):
    result.sons = newSeqOfCap[PNode](src.len)
    for n in src.sons:
      if n != skippedNode:
        result.sons.add copyTreeWithoutNode(n, skippedNode)

proc hasSonWith*(n: PNode, kind: TNodeKind): bool =
  for i in 0..<n.len:
    if n[i].kind == kind:
      return true
  result = false

proc hasNilSon*(n: PNode): bool =
  for i in 0..<n.safeLen:
    if n[i] == nil:
      return true
    elif hasNilSon(n[i]):
      return true
  result = false

proc containsNode*(n: PNode, kinds: TNodeKinds): bool =
  result = false
  if n == nil: return
  case n.kind
  of nkEmpty..nkNilLit: result = n.kind in kinds
  else:
    for i in 0..<n.len:
      if n.kind in kinds or containsNode(n[i], kinds): return true

proc hasSubnodeWith*(n: PNode, kind: TNodeKind): bool =
  case n.kind
  of nkEmpty..nkNilLit, nkFormalParams: result = n.kind == kind
  else:
    for i in 0..<n.len:
      if (n[i].kind == kind) or hasSubnodeWith(n[i], kind):
        return true
    result = false

proc getInt*(a: PNode): Int128 =
  case a.kind
  of nkCharLit, nkUIntLit..nkUInt64Lit:
    result = toInt128(cast[uint64](a.intVal))
  of nkInt8Lit..nkInt64Lit:
    result = toInt128(a.intVal)
  of nkIntLit:
    # XXX: enable this assert
    # assert a.typ.kind notin {tyChar, tyUint..tyUInt64}
    result = toInt128(a.intVal)
  else:
    raiseRecoverableError("cannot extract number from invalid AST node")

proc getInt64*(a: PNode): int64 {.deprecated: "use getInt".} =
  case a.kind
  of nkCharLit, nkUIntLit..nkUInt64Lit, nkIntLit..nkInt64Lit:
    result = a.intVal
  else:
    raiseRecoverableError("cannot extract number from invalid AST node")

proc getFloat*(a: PNode): BiggestFloat =
  case a.kind
  of nkFloatLiterals: result = a.floatVal
  of nkCharLit, nkUIntLit..nkUInt64Lit, nkIntLit..nkInt64Lit:
    result = BiggestFloat a.intVal
  else:
    raiseRecoverableError("cannot extract number from invalid AST node")
    #doAssert false, "getFloat"
    #internalError(a.info, "getFloat")
    #result = 0.0

proc getStr*(a: PNode): string =
  case a.kind
  of nkStrLit..nkTripleStrLit: result = a.strVal
  of nkNilLit:
    # let's hope this fixes more problems than it creates:
    result = ""
  else:
    raiseRecoverableError("cannot extract string from invalid AST node")
    #doAssert false, "getStr"
    #internalError(a.info, "getStr")
    #result = ""

proc getStrOrChar*(a: PNode): string =
  case a.kind
  of nkStrLit..nkTripleStrLit: result = a.strVal
  of nkCharLit..nkUInt64Lit: result = $chr(int(a.intVal))
  else:
    raiseRecoverableError("cannot extract string from invalid AST node")
    #doAssert false, "getStrOrChar"
    #internalError(a.info, "getStrOrChar")
    #result = ""

proc isGenericParams*(n: PNode): bool {.inline.} =
  ## used to judge whether a node is generic params.
  n != nil and n.kind == nkGenericParams

proc isGenericRoutine*(n: PNode): bool  {.inline.} =
  n != nil and n.kind in callableDefs and n[genericParamsPos].isGenericParams

proc isGenericRoutineStrict*(s: PSym): bool {.inline.} =
  ## determines if this symbol represents a generic routine
  ## the unusual name is so it doesn't collide and eventually replaces
  ## `isGenericRoutine`
  s.kind in skProcKinds and s.ast.isGenericRoutine

proc isGenericRoutine*(s: PSym): bool {.inline.} =
  ## determines if this symbol represents a generic routine or an instance of
  ## one. This should be renamed accordingly and `isGenericRoutineStrict`
  ## should take this name instead.
  ##
  ## Warning/XXX: Unfortunately, it considers a proc kind symbol flagged with
  ## sfFromGeneric as a generic routine. Instead this should likely not be the
  ## case and the concepts should be teased apart:
  ## - generic definition
  ## - generic instance
  ## - either generic definition or instance
  s.kind in skProcKinds and (sfFromGeneric in s.flags or
                             s.ast.isGenericRoutine)

proc skipGenericOwner*(s: PSym): PSym =
  ## Generic instantiations are owned by their originating generic
  ## symbol. This proc skips such owners and goes straight to the owner
  ## of the generic itself (the module or the enclosing proc).
  result = if s.kind in skProcKinds and sfFromGeneric in s.flags and s.owner.kind != skModule:
             s.owner.owner
           else:
             s.owner

proc originatingModule*(s: PSym): PSym =
  result = s.owner
  while result.kind != skModule: result = result.owner

proc isRoutine*(s: PSym): bool {.inline.} =
  result = s.kind in skProcKinds

proc isCompileTimeProc*(s: PSym): bool {.inline.} =
  result = s.kind == skMacro or
           s.kind in {skProc, skFunc} and sfCompileTime in s.flags

proc hasPattern*(s: PSym): bool {.inline.} =
  result = isRoutine(s) and s.ast[patternPos].kind != nkEmpty

iterator items*(n: PNode): PNode =
  for i in 0..<n.safeLen: yield n[i]

iterator pairs*(n: PNode): tuple[i: int, n: PNode] =
  for i in 0..<n.safeLen: yield (i, n[i])

proc isAtom*(n: PNode): bool {.inline.} =
  result = n.kind >= nkNone and n.kind <= nkNilLit

proc isEmptyType*(g: TypeGraph; t: PType): bool {.inline.} =
  ## 'void' and 'typed' types are often equivalent to 'nil' these days:
  result = g[t].kind in {tyVoid, tyTyped}

proc makeStmtList*(n: PNode): PNode =
  if n.kind == nkStmtList:
    result = n
  else:
    result = newNodeI(nkStmtList, n.info)
    result.add n

proc skipStmtList*(n: PNode): PNode =
  if n.kind in {nkStmtList, nkStmtListExpr}:
    for i in 0..<n.len-1:
      if n[i].kind notin {nkEmpty, nkCommentStmt}: return n
    result = n.lastSon
  else:
    result = n

proc toVar*(g: var TypeGraph; typ: PType; kind: TTypeKind; idgen: IdGenerator): PType =
  ## If ``typ`` is not a tyVar then it is converted into a `var <typ>` and
  ## returned. Otherwise ``typ`` is simply returned as-is.
  result = typ
  if g[typ].kind != kind:
    result = wrapType(g, typ, kind)

proc toRef*(g: var TypeGraph; typ: PType; idgen: IdGenerator): PType =
  ## If ``typ`` is a tyObject then it is converted into a `ref <typ>` and
  ## returned. Otherwise ``typ`` is simply returned as-is.
  result = typ
  if g[g.skipTypes(typ, {tyAlias, tyGenericInst})].kind == tyObject:
    result = wrapType(g, typ, tyRef)

proc toObject*(g: TypeGraph; typ: PType): PType =
  ## If ``typ`` is a tyRef then its immediate son is returned (which in many
  ## cases should be a ``tyObject``).
  ## Otherwise ``typ`` is simply returned as-is.
  let t = g.skipTypes(typ, {tyAlias, tyGenericInst})
  if g[t].kind == tyRef: t.firstSon
  else: typ

proc toObjectFromRefPtrGeneric*(g: TypeGraph; typ: PType): PType =
  #[
  See also `toObject`.
  Finds the underlying `object`, even in cases like these:
  type
    B[T] = object f0: int
    A1[T] = ref B[T]
    A2[T] = ref object f1: int
    A3 = ref object f2: int
    A4 = object f3: int
  ]#
  result = typ
  while true:
    case g[result].kind
    of tyGenericBody, tyRef, tyPtr, tyGenericInst, tyGenericInvocation, tyAlias:
      result = result.firstSon
      # automatic dereferencing is deep, refs #18298.
    else: break
  # result does not have to be object type

proc isImportedException*(g: TypeGraph; t: PType; conf: ConfigRef): bool =
  if conf.exc != excCpp:
    return false

  let base = g.skipTypes(t, {tyAlias, tyPtr, tyDistinct, tyGenericInst})

  let basesym = g.ext.getOrDefault(base).sym
  result = basesym != nil and {sfCompileToCpp, sfImportc} * basesym.flags != {}

proc isInfixAs*(n: PNode): bool =
  return n.kind == nkInfix and n[0].kind == nkIdent and n[0].ident.id == ord(wAs)

proc skipColon*(n: PNode): PNode =
  result = n
  if n.kind == nkExprColonExpr:
    result = n[1]

proc findUnresolvedStatic*(g: TypeGraph; n: PNode): PNode =
  if n.kind == nkSym and g[n.typ].kind == tyStatic and g.n.getOrDefault(n.typ) == nil:
    return n
  if g[n.typ].kind == tyTypeDesc:
    let t = skipTypes(g, n.typ, {tyTypeDesc})
    if g[t].kind == tyGenericParam and g.hasNoSons(t):
      return n
  for son in n:
    let n = g.findUnresolvedStatic(son)
    if n != nil: return n
  return nil

when false:
  proc containsNil*(n: PNode): bool =
    # only for debugging
    if n.isNil: return true
    for i in 0..<n.safeLen:
      if n[i].containsNil: return true

template hasDestructor*(g: TypeGraph; t: PType): bool =
  {tfHasAsgn, tfHasOwned} * g.flags.getOrDefault(t) != {}

template incompleteType*(g: TypeGraph; t: PType): bool =
  let tsym = g.ext.getOrDefault(t).sym
  tsym != nil and {sfForward, sfNoForward} * tsym.flags == {sfForward}

template typeCompleted*(s: PSym) =
  incl s.flags, sfNoForward

template detailedInfo*(sym: PSym): string =
  sym.name.s

proc isInlineIterator*(g: TypeGraph; typ: PType): bool {.inline.} =
  g[typ].kind == tyProc and tfIterator in g.flags.getOrDefault(typ) and g.callConv.getOrDefault(typ) != ccClosure

proc isIterator*(g: TypeGraph; typ: PType): bool {.inline.} =
  g[typ].kind == tyProc and tfIterator in g.flags.getOrDefault(typ)

proc isClosureIterator*(g: TypeGraph; typ: PType): bool {.inline.} =
  g[typ].kind == tyProc and tfIterator in g.flags.getOrDefault(typ) and g.callConv.getOrDefault(typ) == ccClosure

proc isClosure*(g: TypeGraph; typ: PType): bool {.inline.} =
  g[typ].kind == tyProc and g.callConv.getOrDefault(typ) == ccClosure

proc isNimcall*(g: TypeGraph; s: PSym): bool {.inline.} =
  g.callConv.getOrDefault(s.typ) == ccNimCall

proc isExplicitCallConv*(g: TypeGraph; s: PSym): bool {.inline.} =
  tfExplicitCallConv in g.flags.getOrDefault(s.typ)

proc isSinkParam*(g: TypeGraph; s: PSym): bool {.inline.} =
  s.kind == skParam and (g[s.typ].kind == tySink or g.flags.getOrDefault(s.typ).contains(tfHasOwned))

proc isSinkType*(g: TypeGraph; t: PType): bool {.inline.} =
  g[t].kind == tySink or g.flags.getOrDefault(t).contains(tfHasOwned)

when false:
  proc newProcType*(info: TLineInfo; idgen: IdGenerator; owner: PSym): PType =
    result = newType(tyProc, idgen, owner)
    result.n = newNodeI(nkFormalParams, info)
    rawAddSon(result, nil) # return type
    # result.n[0] used to be `nkType`, but now it's `nkEffectList` because
    # the effects are now stored in there too ... this is a bit hacky, but as
    # usual we desperately try to save memory:
    result.n.add newNodeI(nkEffectList, info)

  proc addParam*(procType: PType; param: PSym) =
    param.position = procType.len-1
    procType.n.add newSymNode(param)
    rawAddSon(procType, param.typ)

const magicsThatCanRaise = {
  mNone, mSlurp, mStaticExec, mParseExprToAst, mParseStmtToAst, mEcho}

proc canRaiseConservative*(fn: PNode): bool =
  if fn.kind == nkSym and fn.sym.magic notin magicsThatCanRaise:
    result = false
  else:
    result = true

proc canRaise*(g: TypeGraph; fn: PNode): bool =
  if fn.kind == nkSym and (fn.sym.magic notin magicsThatCanRaise or
      {sfImportc, sfInfixCall} * fn.sym.flags == {sfImportc} or
      sfGeneratedOp in fn.sym.flags):
    result = false
  elif fn.kind == nkSym and fn.sym.magic == mEcho:
    result = true
  else:
    # TODO check for n having sons? or just return false for now if not
    let n = g.n.getOrDefault(fn.typ)
    if n != nil and n[0].kind == nkSym:
      result = false
    else:
      result = n != nil and ((n[0].len < effectListLen) or
        (n[0][exceptionEffects] != nil and
        n[0][exceptionEffects].safeLen > 0))

proc toHumanStrImpl[T](kind: T, num: static int): string =
  result = $kind
  result = result[num..^1]
  result[0] = result[0].toLowerAscii

proc toHumanStr*(kind: TSymKind): string =
  ## strips leading `sk`
  result = toHumanStrImpl(kind, 2)

proc toHumanStr*(kind: TTypeKind): string =
  ## strips leading `tk`
  result = toHumanStrImpl(kind, 2)

proc skipHiddenAddr*(n: PNode): PNode {.inline.} =
  (if n.kind == nkHiddenAddr: n[0] else: n)

proc isNewStyleConcept*(n: PNode): bool {.inline.} =
  assert n.kind == nkTypeClassTy
  result = n[0].kind == nkEmpty

proc isOutParam*(g: TypeGraph; t: PType): bool {.inline.} = tfIsOutParam in g.flags.getOrDefault(t)

const
  nodesToIgnoreSet* = {nkNone..pred(nkSym), succ(nkSym)..nkNilLit,
    nkTypeSection, nkProcDef, nkConverterDef,
    nkMethodDef, nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo,
    nkFuncDef, nkConstSection, nkConstDef, nkIncludeStmt, nkImportStmt,
    nkExportStmt, nkPragma, nkCommentStmt, nkBreakState,
    nkTypeOfExpr, nkMixinStmt, nkBindStmt}

proc isTrue*(n: PNode): bool =
  n.kind == nkSym and n.sym.kind == skEnumField and n.sym.position != 0 or
    n.kind == nkIntLit and n.intVal != 0
