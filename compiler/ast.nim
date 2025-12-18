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
  lineinfos, options, ropes, idents, int128, wordrecg

import std/[tables, hashes]
from std/strutils import toLowerAscii

when defined(nimPreviewSlimSystem):
  import std/assertions

export int128

import nodekinds
export nodekinds

import astdef
export astdef

when not defined(nimKochBootstrap):
  import ast2nif

template typ*(n: PNode): PType =
  n.typField

when not defined(nimKochBootstrap):
  var program* {.threadvar.}: DecodeContext

proc setupProgram*(config: ConfigRef; cache: IdentCache) =
  when not defined(nimKochBootstrap):
    program = createDecodeContext(config, cache)

template loadSym(s: PSym) =
  ## Loads a symbol from NIF file if it's in Partial state.
  when not defined(nimKochBootstrap):
    ast2nif.loadSym(program, s)

template loadType(t: PType) =
  ## Loads a type from NIF file if it's in Partial state.
  when not defined(nimKochBootstrap):
    ast2nif.loadType(program, t)

proc ensureMutable*(s: PSym) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)

proc ensureMutable*(t: PType) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)

proc backendEnsureMutable*(s: PSym) {.inline.} =
  #assert s.state != Sealed
  # ^ IC review this later
  if s.state == Partial: loadSym(s)

proc backendEnsureMutable*(t: PType) {.inline.} =
  #assert t.state != Sealed
  # ^ IC review this later
  if t.state == Partial: loadType(t)

proc owner*(s: PSym): PSym {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.ownerFieldImpl

proc owner*(s: PType): PSym {.inline.} =
  if s.state == Partial: loadType(s)
  result = s.ownerFieldImpl

proc setOwner*(s: PSym; owner: PSym) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.ownerFieldImpl = owner

proc setOwner*(s: PType; owner: PSym) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadType(s)
  s.ownerFieldImpl = owner

# Accessor procs for TSym fields
# Note: kind is kept as a direct field for case statement compatibility
# but we still provide an accessor that checks state
proc kind*(s: PSym): TSymKind {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.kindImpl

proc `kind=`*(s: PSym, val: TSymKind) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.kindImpl = val

proc gcUnsafetyReason*(s: PSym): PSym {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.gcUnsafetyReasonImpl

proc `gcUnsafetyReason=`*(s: PSym, val: PSym) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.gcUnsafetyReasonImpl = val

proc transformedBody*(s: PSym): PNode {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.transformedBodyImpl

proc `transformedBody=`*(s: PSym, val: PNode) {.inline.} =
  #assert s.state != Sealed
  # Make an exception here for this misfeature...
  if s.state == Partial: loadSym(s)
  s.transformedBodyImpl = val

proc closureBody*(s: PSym): PNode {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.closureBodyImpl

proc `closureBody=`*(s: PSym, val: PNode) {.inline.} =
  #assert s.state != Sealed
  # Make an exception here for this misfeature...
  if s.state == Partial: loadSym(s)
  s.closureBodyImpl = val

proc guard*(s: PSym): PSym {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.guardImpl

proc `guard=`*(s: PSym, val: PSym) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.guardImpl = val

proc bitsize*(s: PSym): int {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.bitsizeImpl

proc `bitsize=`*(s: PSym, val: int) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.bitsizeImpl = val

proc alignment*(s: PSym): int {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.alignmentImpl

proc `alignment=`*(s: PSym, val: int) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.alignmentImpl = val

proc magic*(s: PSym): TMagic {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.magicImpl

proc `magic=`*(s: PSym, val: TMagic) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.magicImpl = val

proc typ*(s: PSym): PType {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.typImpl

proc `typ=`*(s: PSym, val: PType) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.typImpl = val

proc info*(s: PSym): TLineInfo {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.infoImpl

proc `info=`*(s: PSym, val: TLineInfo) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.infoImpl = val

when defined(nimsuggest):
  proc endInfo*(s: PSym): TLineInfo {.inline.} =
    if s.state == Partial: loadSym(s)
    result = s.endInfoImpl

  proc `endInfo=`*(s: PSym, val: TLineInfo) {.inline.} =
    assert s.state != Sealed
    if s.state == Partial: loadSym(s)
    s.endInfoImpl = val

  proc hasUserSpecifiedType*(s: PSym): bool {.inline.} =
    if s.state == Partial: loadSym(s)
    result = s.hasUserSpecifiedTypeImpl

  proc `hasUserSpecifiedType=`*(s: PSym, val: bool) {.inline.} =
    assert s.state != Sealed
    if s.state == Partial: loadSym(s)
    s.hasUserSpecifiedTypeImpl = val

proc flags*(s: PSym): TSymFlags {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.flagsImpl

proc `flags=`*(s: PSym, val: TSymFlags) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.flagsImpl = val

proc ast*(s: PSym): PNode {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.astImpl

proc `ast=`*(s: PSym, val: PNode) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.astImpl = val

proc options*(s: PSym): TOptions {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.optionsImpl

proc `options=`*(s: PSym, val: TOptions) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.optionsImpl = val

proc position*(s: PSym): int {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.positionImpl

proc `position=`*(s: PSym, val: int) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.positionImpl = val

proc offset*(s: PSym): int32 {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.offsetImpl

proc `offset=`*(s: PSym, val: int32) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.offsetImpl = val

proc loc*(s: PSym): TLoc {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.locImpl

proc `loc=`*(s: PSym, val: TLoc) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.locImpl = val

proc annex*(s: PSym): PLib {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.annexImpl

proc `annex=`*(s: PSym, val: PLib) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.annexImpl = val

when hasFFI:
  proc cname*(s: PSym): string {.inline.} =
    if s.state == Partial: loadSym(s)
    result = s.cnameImpl

  proc `cname=`*(s: PSym, val: string) {.inline.} =
    assert s.state != Sealed
    if s.state == Partial: loadSym(s)
    s.cnameImpl = val

proc constraint*(s: PSym): PNode {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.constraintImpl

proc `constraint=`*(s: PSym, val: PNode) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.constraintImpl = val

proc instantiatedFrom*(s: PSym): PSym {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.instantiatedFromImpl

proc `instantiatedFrom=`*(s: PSym, val: PSym) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.instantiatedFromImpl = val

proc setSnippet*(s: PSym; val: sink string) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.locImpl.snippet = val

proc incl*(s: PSym; flag: TSymFlag) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.flagsImpl.incl(flag)

proc incl*(s: PSym; flags: set[TSymFlag]) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.flagsImpl.incl(flags)

proc incl*(s: PSym; flag: TLocFlag) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.locImpl.flags.incl(flag)

proc excl*(s: PSym; flag: TSymFlag) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.flagsImpl.excl(flag)

when defined(nimsuggest):
  proc allUsages*(s: PSym): var seq[TLineInfo] {.inline.} =
    if s.state == Partial: loadSym(s)
    result = s.allUsagesImpl

  proc `allUsages=`*(s: PSym, val: sink seq[TLineInfo]) {.inline.} =
    assert s.state != Sealed
    if s.state == Partial: loadSym(s)
    s.allUsagesImpl = val

# Accessor procs for TType fields
proc callConv*(t: PType): TCallingConvention {.inline.} =
  if t.state == Partial: loadType(t)
  result = t.callConvImpl

proc `callConv=`*(t: PType, val: TCallingConvention) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.callConvImpl = val

proc flags*(t: PType): TTypeFlags {.inline.} =
  if t.state == Partial: loadType(t)
  result = t.flagsImpl

proc `flags=`*(t: PType, val: TTypeFlags) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.flagsImpl = val

proc sons*(t: PType): var TTypeSeq {.inline.} =
  if t.state == Partial: loadType(t)
  result = t.sonsImpl

proc `sons=`*(t: PType, val: sink TTypeSeq) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.sonsImpl = val

proc n*(t: PType): PNode {.inline.} =
  if t.state == Partial: loadType(t)
  result = t.nImpl

proc `n=`*(t: PType, val: PNode) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.nImpl = val

proc sym*(t: PType): PSym {.inline.} =
  if t.state == Partial: loadType(t)
  result = t.symImpl

proc `sym=`*(t: PType, val: PSym) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.symImpl = val

proc size*(t: PType): BiggestInt {.inline.} =
  if t.state == Partial: loadType(t)
  result = t.sizeImpl

proc `size=`*(t: PType, val: BiggestInt) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.sizeImpl = val

proc align*(t: PType): int16 {.inline.} =
  if t.state == Partial: loadType(t)
  result = t.alignImpl

proc `align=`*(t: PType, val: int16) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.alignImpl = val

proc paddingAtEnd*(t: PType): int16 {.inline.} =
  if t.state == Partial: loadType(t)
  result = t.paddingAtEndImpl

proc `paddingAtEnd=`*(t: PType, val: int16) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.paddingAtEndImpl = val

proc loc*(t: PType): TLoc {.inline.} =
  if t.state == Partial: loadType(t)
  result = t.locImpl

proc `loc=`*(t: PType, val: TLoc) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.locImpl = val

proc typeInst*(t: PType): PType {.inline.} =
  if t.state == Partial: loadType(t)
  result = t.typeInstImpl

proc `typeInst=`*(t: PType, val: PType) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.typeInstImpl = val

proc incl*(t: PType; flag: TTypeFlag) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.flagsImpl.incl(flag)

proc incl*(t: PType; flags: set[TTypeFlag]) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.flagsImpl.incl(flags)

proc excl*(t: PType; flag: TTypeFlag) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.flagsImpl.excl(flag)

proc excl*(t: PType; flags: set[TTypeFlag]) {.inline.} =
  assert t.state != Sealed
  if t.state == Partial: loadType(t)
  t.flagsImpl.excl(flags)

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

proc getPIdent*(a: PNode): PIdent {.inline.} =
  ## Returns underlying `PIdent` for `{nkSym, nkIdent}`, or `nil`.
  case a.kind
  of nkSym: a.sym.name
  of nkIdent: a.ident
  of nkOpenSymChoice, nkClosedSymChoice, nkOpenSym: a.sons[0].sym.name
  else: nil

const
  moduleShift = when defined(cpu32): 20 else: 24

template toId*(a: ItemId): int =
  let x = a
  (x.module.int shl moduleShift) + x.item.int

template id*(a: PType | PSym): int = toId(a.itemId)

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

proc add*(father, son: PType) =
  assert son != nil
  father.sonsImpl.add son

proc addAllowNil*(father, son: PType) {.inline.} =
  father.sonsImpl.add son

template `[]`*(n: PType, i: int): PType =
  if n.state == Partial: loadType(n)
  n.sonsImpl[i]
template `[]=`*(n: PType, i: int; x: PType) =
  if n.state == Partial: loadType(n)
  n.sonsImpl[i] = x

template `[]`*(n: PType, i: BackwardsIndex): PType =
  if n.state == Partial: loadType(n)
  n[n.len - i.int]
template `[]=`*(n: PType, i: BackwardsIndex; x: PType) =
  if n.state == Partial: loadType(n)
  n[n.len - i.int] = x

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
  if s.kind in routineKinds: # bug #24167
    let astVal = s.ast
    if astVal != nil and astVal[pragmasPos] != nil and astVal[pragmasPos].kind != nkEmpty:
      result = astVal[pragmasPos]
    else:
      result = nil
  elif s.kind in {skType, skVar, skLet, skConst}:
    let astVal = s.ast
    if astVal != nil and astVal.len > 0:
      if astVal[0].kind == nkPragmaExpr and astVal[0].len > 1:
        # s.ast = nkTypedef / nkPragmaExpr / [nkSym, nkPragma]
        result = astVal[0][1]
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

proc newAtom*(ident: PIdent, info: TLineInfo): PNode =
  result = newNode(nkIdent, info)
  result.ident = ident

proc newAtom*(kind: TNodeKind, intVal: BiggestInt, info: TLineInfo): PNode =
  result = newNode(kind, info)
  result.intVal = intVal

proc newAtom*(kind: TNodeKind, floatVal: BiggestFloat, info: TLineInfo): PNode =
  result = newNode(kind, info)
  result.floatVal = floatVal

proc newAtom*(kind: TNodeKind; strVal: sink string; info: TLineInfo): PNode =
  result = newNode(kind, info)
  result.strVal = strVal

proc newTree*(kind: TNodeKind; info: TLineInfo; children: varargs[PNode]): PNode =
  result = newNodeI(kind, info)
  if children.len > 0:
    result.info = children[0].info
  result.sons = @children

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
  if t.sons.len > 1: t.last else: nil

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
  result = PSym(name: name, kindImpl: symKind, flagsImpl: {}, infoImpl: info, itemId: id,
                optionsImpl: options, ownerFieldImpl: owner, offsetImpl: defaultOffset,
                disamb: getOrDefault(idgen.disambTable, name).int32)
  idgen.disambTable.inc name
  when false:
    if id.module == 48 and id.item == 39:
      writeStackTrace()
      echo "kind ", symKind, " ", name.s
      if owner != nil: echo owner.name.s

proc astdef*(s: PSym): PNode =
  # get only the definition (initializer) portion of the ast
  let astVal = s.ast
  if astVal != nil and astVal.kind in {nkIdentDefs, nkConstDef}:
    astVal[2]
  else:
    astVal

proc isMetaType*(t: PType): bool =
  return t.kind in tyMetaTypes or
         (t.kind == tyStatic and t.n == nil) or
         tfHasMeta in t.flags

proc isUnresolvedStatic*(t: PType): bool =
  return t.kind == tyStatic and t.n == nil

proc linkTo*(t: PType, s: PSym): PType {.discardable.} =
  t.sym = s
  s.typImpl = t
  result = t

proc linkTo*(s: PSym, t: PType): PSym {.discardable.} =
  t.sym = s
  s.typImpl = t
  result = s

template fileIdx*(c: PSym): FileIndex =
  # XXX: this should be used only on module symbols
  c.position().FileIndex

template filename*(c: PSym): string =
  # XXX: this should be used only on module symbols
  c.position().FileIndex.toFilename

proc appendToModule*(m: PSym, n: PNode) =
  ## The compiler will use this internally to add nodes that will be
  ## appended to the module after the sem pass
  if m.astImpl == nil:
    m.astImpl = newNode(nkStmtList)
  else:
    assert m.astImpl.kind == nkStmtList
  m.astImpl.add(n)

proc copyStrTable*(dest: var TStrTable, src: TStrTable) =
  dest.counter = src.counter
  setLen(dest.data, src.data.len)
  for i in 0..high(src.data): dest.data[i] = src.data[i]

proc copyIdTable*[T](dest: var TIdTable[T], src: TIdTable[T]) =
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
  # XXX Dead code. Remove
  n.info = info
  return n

proc newSymNode*(sym: PSym): PNode =
  result = newNode(nkSym)
  result.sym = sym
  result.typ() = sym.typ
  result.info = sym.info

proc newOpenSym*(n: PNode): PNode {.inline.} =
  result = newTreeI(nkOpenSym, n.info, n)

proc newIntNode*(kind: TNodeKind, intVal: BiggestInt): PNode =
  result = newNode(kind)
  result.intVal = intVal

proc newIntNode*(kind: TNodeKind, intVal: Int128): PNode =
  result = newNode(kind)
  result.intVal = castToInt64(intVal)

proc lastSon*(n: PNode): PNode {.inline.} = n.sons[^1]
template setLastSon*(n: PNode, s: PNode) = n.sons[^1] = s

template firstSon*(n: PNode): PNode = n.sons[0]
template secondSon*(n: PNode): PNode = n.sons[1]

template hasSon*(n: PNode): bool = n.len > 0
template has2Sons*(n: PNode): bool = n.len > 1

proc replaceFirstSon*(n, newson: PNode) {.inline.} =
  n.sons[0] = newson

proc replaceSon*(n: PNode; i: int; newson: PNode) {.inline.} =
  n.sons[i] = newson

proc last*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[^1]

proc elementType*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[^1]

proc skipModifier*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[^1]

proc indexType*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[0]

proc baseClass*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[0]

proc base*(t: PType): PType {.inline.} =
  if t.state == Partial: loadType(t)
  result = t.sonsImpl[0]

proc returnType*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[0]

proc setReturnType*(n, r: PType) {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[0] = r

proc setIndexType*(n, idx: PType) {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[0] = idx

proc firstParamType*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[1]

proc firstGenericParam*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[1]

proc typeBodyImpl*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[^1]

proc genericHead*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[0]

proc skipTypes*(t: PType, kinds: TTypeKinds): PType =
  ## Used throughout the compiler code to test whether a type tree contains or
  ## doesn't contain a specific type/types - it is often the case that only the
  ## last child nodes of a type tree need to be searched. This is a really hot
  ## path within the compiler!
  result = t
  while result.kind in kinds: result = last(result)

proc newIntTypeNode*(intVal: BiggestInt, typ: PType): PNode =
  let kind = skipTypes(typ, abstractVarRange).kind
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
  result.typ() = typ

proc newIntTypeNode*(intVal: Int128, typ: PType): PNode =
  # XXX: introduce range check
  newIntTypeNode(castToInt64(intVal), typ)

proc newFloatNode*(kind: TNodeKind, floatVal: BiggestFloat): PNode =
  result = newNode(kind)
  result.floatVal = floatVal

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

proc len*(n: PType): int {.inline.} =
  result = n.sonsImpl.len

proc sameTupleLengths*(a, b: PType): bool {.inline.} =
  result = a.sonsImpl.len == b.sonsImpl.len

iterator tupleTypePairs*(a, b: PType): (int, PType, PType) =
  for i in 0 ..< a.len:
    yield (i, a[i], b[i])

iterator underspecifiedPairs*(a, b: PType; start = 0; without = 0): (PType, PType) =
  # XXX Figure out with what typekinds this is called.
  for i in start ..< min(a.len, b.len) + without:
    yield (a[i], b[i])

proc signatureLen*(t: PType): int {.inline.} =
  result = t.len

proc paramsLen*(t: PType): int {.inline.} =
  result = t.len - 1

proc genericParamsLen*(t: PType): int {.inline.} =
  assert t.kind == tyGenericInst
  result = t.len - 2 # without 'head' and 'body'

proc genericInvocationParamsLen*(t: PType): int {.inline.} =
  assert t.kind == tyGenericInvocation
  result = t.len - 1 # without 'head'

proc kidsLen*(t: PType): int {.inline.} =
  result = t.len

proc genericParamHasConstraints*(t: PType): bool {.inline.} = t.len > 0

proc hasElementType*(t: PType): bool {.inline.} = t.len > 0
proc isEmptyTupleType*(t: PType): bool {.inline.} = t.len == 0
proc isSingletonTupleType*(t: PType): bool {.inline.} = t.len == 1

proc genericConstraint*(t: PType): PType {.inline.} = t[0]

iterator genericInstParams*(t: PType): (bool, PType) =
  for i in 1..<t.len-1:
    yield (i!=1, t[i])

iterator genericInstParamPairs*(a, b: PType): (int, PType, PType) =
  for i in 1..<min(a.len, b.len)-1:
    yield (i-1, a[i], b[i])

iterator genericInvocationParams*(t: PType): (bool, PType) =
  for i in 1..<t.len:
    yield (i!=1, t[i])

iterator genericInvocationAndBodyElements*(a, b: PType): (PType, PType) =
  for i in 1..<a.len:
    yield (a[i], b[i-1])

iterator genericInvocationParamPairs*(a, b: PType): (bool, PType, PType) =
  for i in 1..<a.len:
    if i >= b.len:
      yield (false, nil, nil)
    else:
      yield (true, a[i], b[i])

iterator genericBodyParams*(t: PType): (int, PType) =
  for i in 0..<t.len-1:
    yield (i, t[i])

iterator userTypeClassInstParams*(t: PType): (bool, PType) =
  for i in 1..<t.len-1:
    yield (i!=1, t[i])

iterator ikids*(t: PType): (int, PType) =
  for i in 0..<t.len: yield (i, t[i])

const
  FirstParamAt* = 1
  FirstGenericParamAt* = 1

iterator paramTypes*(t: PType): (int, PType) =
  for i in FirstParamAt..<t.len: yield (i, t[i])

iterator paramTypePairs*(a, b: PType): (PType, PType) =
  for i in FirstParamAt..<a.len: yield (a[i], b[i])

template paramTypeToNodeIndex*(x: int): int = x

iterator kids*(t: PType): PType =
  for i in 0..<t.len: yield t[i]

iterator signature*(t: PType): PType =
  # yields return type + parameter types
  for i in 0..<t.len: yield t[i]

proc newType*(kind: TTypeKind; idgen: IdGenerator; owner: PSym; son: sink PType = nil): PType =
  let id = nextTypeId idgen
  result = PType(kind: kind, ownerFieldImpl: owner, sizeImpl: defaultSize,
                 alignImpl: defaultAlignment, itemId: id,
                 uniqueId: id, sonsImpl: @[])
  if son != nil:
    result.sonsImpl.add son
  when false:
    if result.itemId.module == 55 and result.itemId.item == 2:
      echo "KNID ", kind
      writeStackTrace()

proc setSons*(dest: PType; sons: sink seq[PType]) {.inline.} = dest.sonsImpl = sons
proc setSon*(dest: PType; son: sink PType) {.inline.} = dest.sonsImpl = @[son]
proc setSonsLen*(dest: PType; len: int) {.inline.} =
  setLen(dest.sonsImpl, len)

proc mergeLoc(a: var TLoc, b: TLoc) =
  if a.k == low(typeof(a.k)): a.k = b.k
  if a.storage == low(typeof(a.storage)): a.storage = b.storage
  a.flags.incl b.flags
  if a.lode == nil: a.lode = b.lode
  if a.snippet == "": a.snippet = b.snippet

proc newSons*(father: PNode, length: int) =
  setLen(father.sons, length)

proc newSons*(father: PType, length: int) =
  setLen(father.sonsImpl, length)

proc truncateInferredTypeCandidates*(t: PType) {.inline.} =
  assert t.kind == tyInferred
  if t.len > 1:
    setLen(t.sonsImpl, 1)

proc assignType*(dest, src: PType) =
  dest.kind = src.kind
  dest.flagsImpl = src.flags
  dest.callConvImpl = src.callConv
  dest.nImpl = src.n
  dest.sizeImpl = src.size
  dest.alignImpl = src.align
  # this fixes 'type TLock = TSysLock':
  if src.sym != nil:
    if dest.sym != nil:
      var destFlags = dest.sym.flags
      var srcFlags = src.sym.flags
      dest.sym.flagsImpl = destFlags + (srcFlags - {sfUsed, sfExported})
      if dest.sym.annex == nil: dest.sym.annexImpl = src.sym.annex
      mergeLoc(dest.sym.locImpl, src.sym.loc)
    else:
      dest.symImpl = src.sym
  newSons(dest, src.len)
  for i in 0..<src.len: dest[i] = src[i]

proc copyType*(t: PType, idgen: IdGenerator, owner: PSym): PType =
  result = newType(t.kind, idgen, owner)
  assignType(result, t)
  result.symImpl = t.sym          # backend-info should not be copied

proc exactReplica*(t: PType): PType =
  result = PType(kind: t.kind, ownerFieldImpl: t.owner, sizeImpl: defaultSize,
                 alignImpl: defaultAlignment, itemId: t.itemId,
                 uniqueId: t.uniqueId)
  assignType(result, t)
  result.symImpl = t.sym          # backend-info should not be copied

proc copySym*(s: PSym; idgen: IdGenerator): PSym =
  result = newSym(s.kind, s.name, idgen, s.owner, s.info, s.options)
  #result.astImpl = nil            # BUGFIX; was: s.ast which made problems
  result.typImpl = s.typ
  result.flagsImpl = s.flags
  result.magicImpl = s.magic
  result.optionsImpl = s.options
  result.positionImpl = s.position
  result.locImpl = s.loc
  result.annexImpl = s.annex      # BUGFIX
  result.constraintImpl = s.constraint
  if result.kind in {skVar, skLet, skField}:
    result.guardImpl = s.guard
    result.bitsizeImpl = s.bitsize
    result.alignmentImpl = s.alignment

proc createModuleAlias*(s: PSym, idgen: IdGenerator, newIdent: PIdent, info: TLineInfo;
                        options: TOptions): PSym =
  result = newSym(s.kind, newIdent, idgen, s.owner, info, options)
  # keep ID!
  result.astImpl = s.ast
  #result.id = s.id # XXX figure out what to do with the ID.
  result.flagsImpl = s.flags
  result.optionsImpl = s.options
  result.positionImpl = s.position
  result.locImpl = s.loc
  result.annexImpl = s.annex

proc initStrTable*(): TStrTable =
  result = TStrTable(counter: 0)
  newSeq(result.data, StartSize)

proc initIdTable*[T](): TIdTable[T] =
  result = TIdTable[T](counter: 0)
  newSeq(result.data, StartSize)

proc resetIdTable*[T](x: var TIdTable[T]) =
  x.counter = 0
  # clear and set to old initial size:
  setLen(x.data, 0)
  setLen(x.data, StartSize)

proc initObjectSet*(): TObjectSet =
  result = TObjectSet(counter: 0)
  newSeq(result.data, StartSize)

proc initNodeTable*(ignoreTypes=false): TNodeTable =
  result = TNodeTable(counter: 0, ignoreTypes: ignoreTypes)
  newSeq(result.data, StartSize)

proc skipTypes*(t: PType, kinds: TTypeKinds; maxIters: int): PType =
  result = t
  var i = maxIters
  while result.kind in kinds:
    result = last(result)
    dec i
    if i == 0: return nil

proc skipTypesOrNil*(t: PType, kinds: TTypeKinds): PType =
  ## same as skipTypes but handles 'nil'
  result = t
  while result != nil and result.kind in kinds:
    if result.sonsImpl.len == 0: return nil
    result = last(result)

proc isGCedMem*(t: PType): bool {.inline.} =
  result = t.kind in {tyString, tyRef, tySequence} or
           t.kind == tyProc and t.callConv == ccClosure

proc propagateToOwner*(owner, elem: PType; propagateHasAsgn = true) =
  owner.incl elem.flags * {tfHasMeta, tfTriggersCompileTime}
  if tfNotNil in elem.flags:
    if owner.kind in {tyGenericInst, tyGenericBody, tyGenericInvocation}:
      owner.incl tfNotNil

  if elem.isMetaType:
    owner.incl tfHasMeta

  let mask = elem.flags * {tfHasAsgn, tfHasOwned}
  if mask != {} and propagateHasAsgn:
    let o2 = owner.skipTypes({tyGenericInst, tyAlias, tySink})
    if o2.kind in {tyTuple, tyObject, tyArray,
                   tySequence, tyString, tySet, tyDistinct}:
      o2.incl mask
      owner.incl mask

  if owner.kind notin {tyProc, tyGenericInst, tyGenericBody,
                       tyGenericInvocation, tyPtr}:
    let elemB = elem.skipTypes({tyGenericInst, tyAlias, tySink})
    if elemB.isGCedMem or tfHasGCedMem in elemB.flags:
      # for simplicity, we propagate this flag even to generics. We then
      # ensure this doesn't bite us in sempass2.
      owner.incl tfHasGCedMem

proc rawAddSon*(father, son: PType; propagateHasAsgn = true) =
  ensureMutable father
  father.sonsImpl.add(son)
  if not son.isNil: propagateToOwner(father, son, propagateHasAsgn)

proc addSonNilAllowed*(father, son: PNode) =
  father.sons.add(son)

proc delSon*(father: PNode, idx: int) =
  if father.len == 0: return
  for i in idx..<father.len - 1: father[i] = father[i + 1]
  father.sons.setLen(father.len - 1)

proc copyNode*(src: PNode): PNode =
  # does not copy its sons!
  if src == nil:
    return nil
  result = newNode(src.kind)
  result.info = src.info
  result.typ() = src.typ
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

template transitionNodeKindCommon(k: TNodeKind) {.dirty.} =
  let obj {.inject.} = n[]
  n[] = TNode(kind: k, typField: n.typ, info: obj.info, flags: obj.flags)
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
  s[] = TSym(kindImpl: k, itemId: obj.itemId, magicImpl: obj.magicImpl, typImpl: obj.typImpl, name: obj.name,
             infoImpl: obj.infoImpl, ownerFieldImpl: obj.ownerFieldImpl, flagsImpl: obj.flagsImpl, astImpl: obj.astImpl,
             optionsImpl: obj.optionsImpl, positionImpl: obj.positionImpl, offsetImpl: obj.offsetImpl,
             locImpl: obj.locImpl, annexImpl: obj.annexImpl, constraintImpl: obj.constraintImpl)
  when hasFFI:
    s.cnameImpl = obj.cnameImpl
  when defined(nimsuggest):
    s.allUsagesImpl = obj.allUsagesImpl

proc transitionGenericParamToType*(s: PSym) =
  transitionSymKindCommon(skType)

proc transitionRoutineSymKind*(s: PSym, kind: range[skProc..skTemplate]) =
  transitionSymKindCommon(kind)
  s.gcUnsafetyReasonImpl = obj.gcUnsafetyReasonImpl
  s.transformedBodyImpl = obj.transformedBodyImpl

proc transitionToLet*(s: PSym) =
  transitionSymKindCommon(skLet)
  s.guardImpl = obj.guardImpl
  s.bitsizeImpl = obj.bitsizeImpl
  s.alignmentImpl = obj.alignmentImpl

template copyNodeImpl(dst, src, processSonsStmt) =
  if src == nil: return
  dst = newNode(src.kind)
  dst.info = src.info
  when defined(nimsuggest):
    result.endInfo = src.endInfo
  dst.typ() = src.typ
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
  result = if s.kind == skModule:
             s
           elif s.kind in skProcKinds and sfFromGeneric in s.flags and s.owner.kind != skModule:
             s.owner.owner
           else:
             s.owner

proc originatingModule*(s: PSym): PSym =
  result = s
  while result.kind != skModule: result = result.owner

proc isRoutine*(s: PSym): bool {.inline.} =
  result = s.kind in skProcKinds

proc isCompileTimeProc*(s: PSym): bool {.inline.} =
  result = s.kind == skMacro or
           s.kind in {skProc, skFunc} and sfCompileTime in s.flags

proc hasPattern*(s: PSym): bool {.inline.} =
  result = isRoutine(s) and s.ast[patternPos].kind != nkEmpty

iterator pairs*(n: PNode): tuple[i: int, n: PNode] =
  for i in 0..<n.safeLen: yield (i, n[i])

proc isAtom*(n: PNode): bool {.inline.} =
  result = n.kind >= nkNone and n.kind <= nkNilLit

proc isEmptyType*(t: PType): bool {.inline.} =
  ## 'void' and 'typed' types are often equivalent to 'nil' these days:
  result = t == nil or t.kind in {tyVoid, tyTyped}

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

proc toVar*(typ: PType; kind: TTypeKind; idgen: IdGenerator): PType =
  ## If ``typ`` is not a tyVar then it is converted into a `var <typ>` and
  ## returned. Otherwise ``typ`` is simply returned as-is.
  result = typ
  if typ.kind != kind:
    result = newType(kind, idgen, typ.owner, typ)

proc toRef*(typ: PType; idgen: IdGenerator): PType =
  ## If ``typ`` is a tyObject then it is converted into a `ref <typ>` and
  ## returned. Otherwise ``typ`` is simply returned as-is.
  result = typ
  if typ.skipTypes({tyAlias, tyGenericInst}).kind == tyObject:
    result = newType(tyRef, idgen, typ.owner, typ)

proc toObject*(typ: PType): PType =
  ## If ``typ`` is a tyRef then its immediate son is returned (which in many
  ## cases should be a ``tyObject``).
  ## Otherwise ``typ`` is simply returned as-is.
  let t = typ.skipTypes({tyAlias, tyGenericInst})
  if t.kind == tyRef: t.elementType
  else: typ

proc toObjectFromRefPtrGeneric*(typ: PType): PType =
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
    case result.kind
    of tyGenericBody: result = result.last
    of tyRef, tyPtr, tyGenericInst, tyGenericInvocation, tyAlias: result = result[0]
      # automatic dereferencing is deep, refs #18298.
    else: break
  # result does not have to be object type

proc isImportedException*(t: PType; conf: ConfigRef): bool =
  assert t != nil

  if conf.exc != excCpp:
    return false

  let base = t.skipTypes({tyAlias, tyPtr, tyDistinct, tyGenericInst})
  result = base.sym != nil and {sfCompileToCpp, sfImportc} * base.sym.flags != {}

proc isInfixAs*(n: PNode): bool =
  return n.kind == nkInfix and n[0].kind == nkIdent and n[0].ident.id == ord(wAs)

proc skipColon*(n: PNode): PNode =
  result = n
  if n.kind == nkExprColonExpr:
    result = n[1]

proc findUnresolvedStatic*(n: PNode): PNode =
  if n.kind == nkSym and n.typ != nil and n.typ.kind == tyStatic and n.typ.n == nil:
    return n
  if n.typ != nil and n.typ.kind == tyTypeDesc:
    let t = skipTypes(n.typ, {tyTypeDesc})
    if t.kind == tyGenericParam and not t.genericParamHasConstraints:
      return n
  for son in n:
    let n = son.findUnresolvedStatic
    if n != nil: return n

  return nil

when false:
  proc containsNil*(n: PNode): bool =
    # only for debugging
    if n.isNil: return true
    for i in 0..<n.safeLen:
      if n[i].containsNil: return true


template hasDestructor*(t: PType): bool = {tfHasAsgn, tfHasOwned} * t.flags != {}

template incompleteType*(t: PType): bool =
  t.sym != nil and {sfForward, sfNoForward} * t.sym.flags == {sfForward}

template typeCompleted*(s: PSym) =
  incl s, sfNoForward

template detailedInfo*(sym: PSym): string =
  sym.name.s

proc isInlineIterator*(typ: PType): bool {.inline.} =
  typ.kind == tyProc and tfIterator in typ.flags and typ.callConv != ccClosure

proc isIterator*(typ: PType): bool {.inline.} =
  typ.kind == tyProc and tfIterator in typ.flags

proc isClosureIterator*(typ: PType): bool {.inline.} =
  typ.kind == tyProc and tfIterator in typ.flags and typ.callConv == ccClosure

proc isClosure*(typ: PType): bool {.inline.} =
  typ.kind == tyProc and typ.callConv == ccClosure

proc isNimcall*(s: PSym): bool {.inline.} =
  s.typ.callConv == ccNimCall

proc isExplicitCallConv*(s: PSym): bool {.inline.} =
  tfExplicitCallConv in s.typ.flags

proc isSinkParam*(s: PSym): bool {.inline.} =
  s.kind == skParam and (s.typ.kind == tySink or tfHasOwned in s.typ.flags)

proc isSinkType*(t: PType): bool {.inline.} =
  t.kind == tySink or tfHasOwned in t.flags

proc newProcType*(info: TLineInfo; idgen: IdGenerator; owner: PSym): PType =
  result = newType(tyProc, idgen, owner)
  result.n = newNodeI(nkFormalParams, info)
  rawAddSon(result, nil) # return type
  # result.n[0] used to be `nkType`, but now it's `nkEffectList` because
  # the effects are now stored in there too ... this is a bit hacky, but as
  # usual we desperately try to save memory:
  result.n.add newNodeI(nkEffectList, info)

proc addParam*(procType: PType; param: PSym) =
  param.position = procType.sons.len-1
  procType.n.add newSymNode(param)
  rawAddSon(procType, param.typ)

const magicsThatCanRaise = {
  mNone, mSlurp, mStaticExec, mParseExprToAst, mParseStmtToAst, mEcho}

proc canRaiseConservative*(fn: PNode): bool =
  if fn.kind == nkSym and fn.sym.magic notin magicsThatCanRaise:
    result = false
  else:
    result = true

proc canRaise*(fn: PNode): bool =
  if fn.kind == nkSym and (fn.sym.magic notin magicsThatCanRaise or
      {sfImportc, sfInfixCall} * fn.sym.flags == {sfImportc} or
      sfGeneratedOp in fn.sym.flags):
    result = false
  elif fn.kind == nkSym and fn.sym.magic == mEcho:
    result = true
  elif fn.typ != nil and fn.typ.kind == tyProc and fn.typ.n != nil:
    # TODO check for n having sons? or just return false for now if not
    if fn.typ.n[0].kind == nkSym:
      result = false
    else:
      result = ((fn.typ.n[0].len < effectListLen) or
        (fn.typ.n[0][exceptionEffects] != nil and
        fn.typ.n[0][exceptionEffects].safeLen > 0))
  else:
    result = false

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

proc isOutParam*(t: PType): bool {.inline.} = tfIsOutParam in t.flags

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

type
  TypeMapping* = TIdTable[PType]
  SymMapping* = TIdTable[PSym]

template initSymMapping*(): SymMapping = initIdTable[PSym]()
template initTypeMapping*(): TypeMapping = initIdTable[PType]()
