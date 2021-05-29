#
#
#           The Nim Compiler
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Supports the "nim check --ic:on --defusages:FILE,LINE,COL"
## IDE-like features. It uses the set of .rod files to accomplish
## its task. The set must cover a complete Nim project.

import sets

from os import nil
from std/private/miscdollars import toLocation

import ".." / [ast, modulegraphs, msgs, options]
import packed_ast, bitabs, ic

type
  NavContext = object
    g: ModuleGraph
    thisModule: int32
    trackPos: PackedLineInfo
    alreadyEmitted: HashSet[string]
    outputSep: char # for easier testing, use short filenames and spaces instead of tabs.

proc isTracked(current, trackPos: PackedLineInfo, tokenLen: int): bool =
  if current.file == trackPos.file and current.line == trackPos.line:
    let col = trackPos.col
    if col >= current.col and col < current.col+tokenLen:
      return true

proc searchLocalSym(c: var NavContext; s: PackedSym; info: PackedLineInfo): bool =
  result = s.name != LitId(0) and
    isTracked(info, c.trackPos, c.g.packed[c.thisModule].fromDisk.strings[s.name].len)

proc searchForeignSym(c: var NavContext; s: ItemId; info: PackedLineInfo): bool =
  let name = c.g.packed[s.module].fromDisk.syms[s.item].name
  result = name != LitId(0) and
    isTracked(info, c.trackPos, c.g.packed[s.module].fromDisk.strings[name].len)

const
  EmptyItemId = ItemId(module: -1'i32, item: -1'i32)

proc search(c: var NavContext; tree: PackedTree): ItemId =
  # We use the linear representation here directly:
  for i in 0..high(tree.nodes):
    case tree.nodes[i].kind
    of nkSym:
      let item = tree.nodes[i].operand
      if searchLocalSym(c, c.g.packed[c.thisModule].fromDisk.syms[item], tree.nodes[i].info):
        return ItemId(module: c.thisModule, item: item)
    of nkModuleRef:
      if tree.nodes[i].info.line == c.trackPos.line and tree.nodes[i].info.file == c.trackPos.file:
        let (n1, n2) = sons2(tree, NodePos i)
        assert n1.kind == nkInt32Lit
        assert n2.kind == nkInt32Lit
        let pId = PackedItemId(module: n1.litId, item: tree.nodes[n2.int].operand)
        let itemId = translateId(pId, c.g.packed, c.thisModule, c.g.config)
        if searchForeignSym(c, itemId, tree.nodes[i].info):
          return itemId
    else: discard
  return EmptyItemId

proc isDecl(tree: PackedTree; n: NodePos): bool =
  # XXX This is not correct yet.
  const declarativeNodes = procDefs + {nkMacroDef, nkTemplateDef,
    nkLetSection, nkVarSection, nkUsingStmt, nkConstSection, nkTypeSection,
    nkIdentDefs, nkEnumTy, nkVarTuple}
  result = n.int >= 0 and tree[n.int].kind in declarativeNodes

proc usage(c: var NavContext; info: PackedLineInfo; isDecl: bool) =
  var m = ""
  var file = c.g.packed[c.thisModule].fromDisk.strings[info.file]
  if c.outputSep == ' ':
    file = os.extractFilename file
  toLocation(m, file, info.line.int, info.col.int + ColOffset)
  if not c.alreadyEmitted.containsOrIncl(m):
    msgWriteln c.g.config, (if isDecl: "def" else: "usage") & c.outputSep & m

proc list(c: var NavContext; tree: PackedTree; sym: ItemId) =
  for i in 0..high(tree.nodes):
    case tree.nodes[i].kind
    of nkSym:
      let item = tree.nodes[i].operand
      if sym.item == item and sym.module == c.thisModule:
        usage(c, tree.nodes[i].info, isDecl(tree, parent(NodePos i)))
    of nkModuleRef:
      let (n1, n2) = sons2(tree, NodePos i)
      assert n1.kind == nkInt32Lit
      assert n2.kind == nkInt32Lit
      let pId = PackedItemId(module: n1.litId, item: tree.nodes[n2.int].operand)
      let itemId = translateId(pId, c.g.packed, c.thisModule, c.g.config)
      if itemId.item == sym.item and sym.module == itemId.module:
        usage(c, tree.nodes[i].info, isDecl(tree, parent(NodePos i)))
    else: discard

proc searchForIncludeFile(g: ModuleGraph; fullPath: string): int =
  for i in 0..high(g.packed):
    for k in 1..high(g.packed[i].fromDisk.includes):
      # we start from 1 because the first "include" file is
      # the module's filename.
      if os.cmpPaths(g.packed[i].fromDisk.strings[g.packed[i].fromDisk.includes[k][0]], fullPath) == 0:
        return i
  return -1

proc nav(g: ModuleGraph) =
  # translate the track position to a packed position:
  let unpacked = g.config.m.trackPos
  var mid = unpacked.fileIndex.int

  let fullPath = toFullPath(g.config, unpacked.fileIndex)

  if g.packed[mid].status == undefined:
    # check if 'mid' is an include file of some other module:
    mid = searchForIncludeFile(g, fullPath)

  if mid < 0:
    localError(g.config, unpacked, "unknown file name: " & fullPath)
    return

  let fileId = g.packed[mid].fromDisk.strings.getKeyId(fullPath)

  if fileId == LitId(0):
    internalError(g.config, unpacked, "cannot find a valid file ID")
    return

  var c = NavContext(
    g: g,
    thisModule: int32 mid,
    trackPos: PackedLineInfo(line: unpacked.line, col: unpacked.col, file: fileId),
    outputSep: if isDefined(g.config, "nimIcNavigatorTests"): ' ' else: '\t'
  )
  var symId = search(c, g.packed[mid].fromDisk.topLevel)
  if symId == EmptyItemId:
    symId = search(c, g.packed[mid].fromDisk.bodies)

  if symId == EmptyItemId:
    localError(g.config, unpacked, "no symbol at this position")
    return

  for i in 0..high(g.packed):
    # case statement here to enforce exhaustive checks.
    case g.packed[i].status
    of undefined:
      discard "nothing to do"
    of loading:
      assert false, "cannot check integrity: Module still loading"
    of stored, storing, outdated, loaded:
      c.thisModule = int32 i
      list(c, g.packed[i].fromDisk.topLevel, symId)
      list(c, g.packed[i].fromDisk.bodies, symId)

proc navDefinition*(g: ModuleGraph) = nav(g)
proc navUsages*(g: ModuleGraph) = nav(g)
proc navDefusages*(g: ModuleGraph) = nav(g)

proc writeRodFiles*(g: ModuleGraph) =
  for i in 0..high(g.packed):
    case g.packed[i].status
    of undefined, loading, stored, loaded:
      discard "nothing to do"
    of storing, outdated:
      closeRodFile(g, g.packed[i].module)
