#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Packed AST representation, mostly based on a seq of nodes.
## For IC support. Far future: Rewrite the compiler passes to
## use this representation directly in all the transformations,
## it is superior.

import std / [hashes, tables]
import bitabs
import ".." / [ast, lineinfos, options, pathutils]

const
  localNamePos* = 0
  localExportMarkerPos* = 1
  localPragmaPos* = 2
  localTypePos* = 3
  localValuePos* = 4

  typeNamePos* = 0
  typeExportMarkerPos* = 1
  typeGenericParamsPos* = 2
  typePragmaPos* = 3
  typeBodyPos* = 4

  routineNamePos* = 0
  routineExportMarkerPos* = 1
  routinePatternPos* = 2
  routineGenericParamsPos* = 3
  routineParamsPos* = 4
  routineResultPos* = 5
  routinePragmasPos* = 6
  routineBodyPos* = 7

const
  nkModuleRef = nkNone # pair of (ModuleId, SymId)

type
  SymId* = distinct int32
  TypeId* = distinct int32
  ModuleId* = distinct int32
  NodePos* = distinct int

  Sym* = object
    kind*: TSymKind
    name*: LitId
    typeId*: TypeId
    flags*: set[TSymFlag]
    magic*: TMagic
    info*: TLineInfo # redundant
    ast*: NodePos

  PackedType* = object
    kind*: TTypeKind
    nodekind*: TNodeKind
    flags*: set[TTypeFlag]
    operand*: int32
    nodeflags*: TNodeFlags
    info*: TLineInfo
    sym*: (ModuleId, SymId) # external refs are possible!

  Node* = object     # 20 bytes
    kind*: TNodeKind
    flags*: TNodeFlags
    operand*: int32  # for kind in {nkSym, nkSymDef}: SymId
                     # for kind in {nkStrLit, nkIdent, nkNumberLit}: LitId
                     # for kind in nkInt32Lit: direct value
                     # for non-atom kinds: the number of nodes (for easy skipping)
    typeId*: TypeId
    info*: TLineInfo

  ModulePhase* = enum
    preLookup, lookedUpTopLevelStmts

  Module* = object
    name*: string
    file*: AbsoluteFile
    ast*: Tree
    phase*: ModulePhase
    iface*: Table[string, seq[SymId]] # 'seq' because of overloading

  Program* = ref object
    modules*: seq[Module]

  Shared* = ref object # shared between different versions of 'Module'.
                       # (though there is always exactly one valid
                       # version of a module)
    syms*: seq[Sym]
    types*: seq[seq[Node]]
    strings*: BiTable[string] # we could share these between modules.
    integers*: BiTable[BiggestInt]
    floats*: BiTable[BiggestFloat]
    config*: ConfigRef
    #thisModule*: ModuleId
    #program*: Program

  Tree* = object ## usually represents a full Nim module
    nodes*: seq[Node]
    toPosition*: Table[SymId, NodePos]
    sh*: Shared

proc `==`*(a, b: SymId): bool {.borrow.}
proc hash*(a: SymId): Hash {.borrow.}

proc `==`*(a, b: NodePos): bool {.borrow.}
proc `==`*(a, b: TypeId): bool {.borrow.}
proc `==`*(a, b: ModuleId): bool {.borrow.}

proc declareSym*(tree: var Tree; kind: TSymKind;
                 name: LitId; info: TLineInfo): SymId =
  result = SymId(tree.sh.syms.len)
  tree.sh.syms.add Sym(kind: kind, name: name, flags: {}, magic: mNone, info: info)

proc newTreeFrom*(old: Tree): Tree =
  result.nodes = @[]
  result.sh = old.sh

proc litIdFromName*(tree: Tree; name: string): LitId =
  result = tree.sh.strings.getOrIncl(name)

proc add*(tree: var Tree; kind: TNodeKind; token: string; info: TLineInfo) =
  tree.nodes.add Node(kind: kind, operand: int32 getOrIncl(tree.sh.strings, token), info: info)

proc add*(tree: var Tree; kind: TNodeKind; info: TLineInfo) =
  tree.nodes.add Node(kind: kind, operand: 0, info: info)

proc throwAwayLastNode*(tree: var Tree) =
  tree.nodes.setLen(tree.nodes.len-1)

proc addIdent*(tree: var Tree; s: LitId; info: TLineInfo) =
  tree.nodes.add Node(kind: nkIdent, operand: int32(s), info: info)

proc addSym*(tree: var Tree; s: SymId; info: TLineInfo) =
  tree.nodes.add Node(kind: nkSym, operand: int32(s), info: info)

proc addModuleId*(tree: var Tree; s: ModuleId; info: TLineInfo) =
  tree.nodes.add Node(kind: nkInt32Lit, operand: int32(s), info: info)

proc addSymDef*(tree: var Tree; s: SymId; info: TLineInfo) =
  tree.nodes.add Node(kind: nkSym, operand: int32(s), info: info)

proc isAtom*(tree: Tree; pos: int): bool {.inline.} = tree.nodes[pos].kind <= nkNilLit

proc copyTree*(dest: var Tree; tree: Tree; n: NodePos) =
  # and this is why the IR is superior. We can copy subtrees
  # via a linear scan.
  let pos = n.int
  let L = if isAtom(tree, pos): 1 else: tree.nodes[pos].operand
  let d = dest.nodes.len
  dest.nodes.setLen(d + L)
  for i in 0..<L:
    dest.nodes[d+i] = tree.nodes[pos+i]

proc copySym*(dest: var Tree; tree: Tree; s: SymId): SymId =
  result = SymId(dest.sh.syms.len)
  assert int(s) < tree.sh.syms.len
  let oldSym = tree.sh.syms[s.int]
  dest.sh.syms.add oldSym

type
  PatchPos = distinct int

when false:
  proc prepare*(tree: var Tree; kind: TNodeKind; info: TLineInfo): PatchPos =
    result = PatchPos tree.nodes.len
    tree.nodes.add Node(kind: kind, operand: 0, info: info)

proc prepare*(tree: var Tree; kind: TNodeKind; flags: TNodeFlags; typeId: TypeId; info: TLineInfo): PatchPos =
  result = PatchPos tree.nodes.len
  tree.nodes.add Node(kind: kind, flags: flags, operand: 0, typeId: typeId, info: info)

proc prepare*(dest: var Tree; source: Tree; sourcePos: NodePos): PatchPos =
  result = PatchPos dest.nodes.len
  dest.nodes.add source.nodes[sourcePos.int]

proc patch*(tree: var Tree; pos: PatchPos) =
  let pos = pos.int
  assert tree.nodes[pos].kind > nkNilLit
  let distance = int32(tree.nodes.len - pos)
  tree.nodes[pos].operand = distance

proc len*(tree: Tree): int {.inline.} = tree.nodes.len

proc `[]`*(tree: Tree; i: int): lent Node {.inline.} = tree.nodes[i]

proc nextChild(tree: Tree; pos: var int) {.inline.} =
  if tree.nodes[pos].kind > nkNilLit:
    assert tree.nodes[pos].operand > 0
    inc pos, tree.nodes[pos].operand
  else:
    inc pos

iterator sonsReadonly*(tree: Tree; n: NodePos): NodePos =
  var pos = n.int
  assert tree.nodes[pos].kind > nkNilLit
  let last = pos + tree.nodes[pos].operand
  inc pos
  while pos < last:
    yield NodePos pos
    nextChild tree, pos

iterator sons*(dest: var Tree; tree: Tree; n: NodePos): NodePos =
  let patchPos = prepare(dest, tree, n)
  for x in sonsReadonly(tree, n): yield x
  patch dest, patchPos

iterator isons*(dest: var Tree; tree: Tree; n: NodePos): (int, NodePos) =
  var i = 0
  for ch0 in sons(dest, tree, n):
    yield (i, ch0)
    inc i

iterator sonsFrom1*(tree: Tree; n: NodePos): NodePos =
  var pos = n.int
  assert tree.nodes[pos].kind > nkNilLit
  let last = pos + tree.nodes[pos].operand
  inc pos
  if pos < last:
    nextChild tree, pos
  while pos < last:
    yield NodePos pos
    nextChild tree, pos

iterator sonsWithoutLast2*(tree: Tree; n: NodePos): NodePos =
  var count = 0
  for child in sonsReadonly(tree, n):
    inc count
  var pos = n.int
  assert tree.nodes[pos].kind > nkNilLit
  let last = pos + tree.nodes[pos].operand
  inc pos
  while pos < last and count > 2:
    yield NodePos pos
    dec count
    nextChild tree, pos

proc parentImpl(tree: Tree; n: NodePos): NodePos =
  # finding the parent of a node is rather easy:
  var pos = n.int - 1
  while pos >= 0 and isAtom(tree, pos) or (pos + tree.nodes[pos].operand - 1 < n.int):
    dec pos
  assert pos >= 0, "node has no parent"
  result = NodePos(pos)

template parent*(n: NodePos): NodePos = parentImpl(tree, n)

proc hasXsons*(tree: Tree; n: NodePos; x: int): bool =
  var count = 0
  if tree.nodes[n.int].kind > nkNilLit:
    for child in sonsReadonly(tree, n): inc count
  result = count == x

proc hasAtLeastXsons*(tree: Tree; n: NodePos; x: int): bool =
  if tree.nodes[n.int].kind > nkNilLit:
    var count = 0
    for child in sonsReadonly(tree, n):
      inc count
      if count >= x: return true
  return false

proc firstSon*(tree: Tree; n: NodePos): NodePos {.inline.} = NodePos(n.int+1)
proc kind*(tree: Tree; n: NodePos): TNodeKind {.inline.} = tree.nodes[n.int].kind
proc litId*(tree: Tree; n: NodePos): LitId {.inline.} = LitId tree.nodes[n.int].operand
proc info*(tree: Tree; n: NodePos): TLineInfo {.inline.} = tree.nodes[n.int].info

proc span(tree: Tree; pos: int): int {.inline.} =
  if isAtom(tree, pos): 1 else: tree.nodes[pos].operand

proc sons2*(tree: Tree; n: NodePos): (NodePos, NodePos) =
  assert(not isAtom(tree, n.int))
  let a = n.int+1
  let b = a + span(tree, a)
  result = (NodePos a, NodePos b)

proc sons3*(tree: Tree; n: NodePos): (NodePos, NodePos, NodePos) =
  assert(not isAtom(tree, n.int))
  let a = n.int+1
  let b = a + span(tree, a)
  let c = b + span(tree, b)
  result = (NodePos a, NodePos b, NodePos c)

proc ithSon*(tree: Tree; n: NodePos; i: int): NodePos =
  if tree.nodes[n.int].kind > nkNilLit:
    var count = 0
    for child in sonsReadonly(tree, n):
      if count == i: return child
      inc count
  assert false, "node has no i-th child"

proc `@`*(tree: Tree; lit: LitId): lent string {.inline.} = tree.sh.strings[lit]

template kind*(n: NodePos): TNodeKind = tree.nodes[n.int].kind
template info*(n: NodePos): TLineInfo = tree.nodes[n.int].info
template litId*(n: NodePos): LitId = LitId tree.nodes[n.int].operand

template symId*(n: NodePos): SymId = SymId tree.nodes[n.int].operand

proc firstSon*(n: NodePos): NodePos {.inline.} = NodePos(n.int+1)

proc strLit*(tree: Tree; n: NodePos): lent string =
  assert n.kind == nkStrLit
  result = tree.sh.strings[LitId tree.nodes[n.int].operand]

proc strVal*(tree: Tree; n: NodePos): string =
  assert n.kind == nkStrLit
  result = tree.sh.strings[LitId tree.nodes[n.int].operand]
  #result = cookedStrLit(raw)

proc filenameVal*(tree: Tree; n: NodePos): string =
  case n.kind
  of nkStrLit:
    result = strVal(tree, n)
  of nkIdent:
    result = tree.sh.strings[n.litId]
  of nkSym:
    result = tree.sh.strings[tree.sh.syms[int n.symId].name]
  else:
    result = ""

proc identAsStr*(tree: Tree; n: NodePos): lent string =
  assert n.kind == nkIdent
  result = tree.sh.strings[LitId tree.nodes[n.int].operand]

const
  externIntLit* = {nkCharLit,
    nkIntLit,
    nkInt8Lit,
    nkInt16Lit,
    nkInt64Lit,
    nkUIntLit,
    nkUInt8Lit,
    nkUInt16Lit,
    nkUInt32Lit,
    nkUInt64Lit} # nkInt32Lit is missing by design!

  externSIntLit* = {nkIntLit, nkInt8Lit, nkInt16Lit, nkInt64Lit}
  externUIntLit* = {nkUIntLit, nkUInt8Lit, nkUInt16Lit, nkUInt32Lit, nkUInt64Lit}
  directIntLit* = nkInt32Lit

proc toString*(tree: Tree; n: NodePos; nesting: int; result: var string) =
  let pos = n.int
  if result.len > 0 and result[^1] notin {' ', '\n'}:
    result.add ' '

  result.add $tree[pos].kind
  case tree.nodes[pos].kind
  of nkNone, nkEmpty, nkNilLit, nkType: discard
  of nkIdent, nkStrLit..nkTripleStrLit:
    result.add " "
    result.add tree.sh.strings[LitId tree.nodes[pos].operand]
  of nkSym:
    result.add " "
    result.add tree.sh.strings[tree.sh.syms[tree.nodes[pos].operand].name]
  of directIntLit:
    result.add " "
    result.addInt tree.nodes[pos].operand
  of externSIntLit:
    result.add " "
    result.addInt tree.sh.integers[LitId tree.nodes[pos].operand]
  of externUIntLit:
    result.add " "
    result.add $cast[uint64](tree.sh.integers[LitId tree.nodes[pos].operand])
  else:
    result.add "(\n"
    for i in 1..(nesting+1)*2: result.add ' '
    for child in sonsReadonly(tree, n):
      toString(tree, child, nesting + 1, result)
    result.add "\n"
    for i in 1..nesting*2: result.add ' '
    result.add ")"
    #for i in 1..nesting*2: result.add ' '


proc toString*(tree: Tree; n: NodePos): string =
  result = ""
  toString(tree, n, 0, result)

proc debug*(tree: Tree) =
  stdout.write toString(tree, NodePos 0)

proc identIdImpl(tree: Tree; n: NodePos): LitId =
  if n.kind == nkIdent:
    result = n.litId
  elif n.kind == nkSym:
    result = tree.sh.syms[int n.symId].name
  else:
    result = LitId(0)

template identId*(n: NodePos): LitId = identIdImpl(tree, n)

template copyInto*(dest, n, body) =
  let patchPos = prepare(dest, tree, n)
  body
  patch dest, patchPos

template copyIntoKind*(dest, kind, info, body) =
  let patchPos = prepare(dest, kind, info)
  body
  patch dest, patchPos

proc hasPragma*(tree: Tree; n: NodePos; pragma: string): bool =
  let litId = tree.sh.strings.getKeyId(pragma)
  if litId == LitId(0):
    return false
  assert n.kind == nkPragma
  for ch0 in sonsReadonly(tree, n):
    if ch0.kind == nkExprColonExpr:
      if ch0.firstSon.identId == litId:
        return true
    elif ch0.identId == litId:
      return true

when false:
  proc produceError*(dest: var Tree; tree: Tree; n: NodePos; msg: string) =
    let patchPos = prepare(dest, nkError, n.info)
    dest.add nkStrLit, msg, n.info
    copyTree(dest, tree, n)
    patch dest, patchPos
