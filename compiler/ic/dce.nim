#
#
#           The Nim Compiler
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Dead code elimination for IC.

import std / intsets
import ".." / [ast, options, lineinfos]

import packed_ast, to_packed_ast, bitabs

type
  MarkedAlive = seq[IntSet]

  AliveContext = object
    stack: seq[(int, int32)]
    config: ConfigRef
    thisModule: int
    alive: MarkedAlive
    g: ref PackedModuleGraph
    lastLit: LitId
    lastModule: int
    lastFile: FileIndex

proc toFileIndexCached(c: var AliveContext; thisModule: int; f: LitId): FileIndex =
  if c.lastLit == f and c.lastModule == thisModule:
    result = c.lastFile
  else:
    result = toFileIndex(f, c.g[thisModule].fromDisk, c.config)
    c.lastModule = thisModule
    c.lastLit = f
    c.lastFile = result

when false:
  proc moduleIndex*(c: var AliveContext; g: var PackedModuleGraph; thisModule: int;
                    s: PackedItemId): int32 {.inline.} =
    result = if s.module == LitId(0): thisModule.int32
            else: toFileIndexCached(c, thisModule, s.module).int32

proc isExportedToC(tree: PackedTree; n: NodePos): bool =
      var prc = n[namePos].sym
      # due to a bug/limitation in the lambda lifting, unused inner procs
      # are not transformed correctly. We work around this issue (#411) here
      # by ensuring it's no inner proc (owner is a module):
      if prc.skipGenericOwner.kind == skModule and sfCompileTime notin prc.flags:
        if ({sfExportc, sfCompilerProc} * prc.flags == {sfExportc}) or
            (sfExportc in prc.flags and lfExportLib in prc.loc.flags) or
            (prc.kind == skMethod):
          # Generate proc even if empty body, bugfix #11651.
          genProc(p.module, prc)

template isNotGeneric(n: NodePos): bool = ithSon(tree, n, genericParamsPos).kind == nkEmpty

proc aliveCode(tree: PackedTree; n: NodePos; c: var AliveContext) =
  case n.kind
  of nkNone..pred(nkSym), succ(nkSym)..nkNilLit:
    discard "ignore non-sym atoms"
  of nkSym:
    let item = n.operand
    # This symbol is alive and everything its body references.
    if not c.alive[c.thisModule].containsOrIncl(item):
      c.stack.add((c.thisModule, item))
  of nkModuleRef:
    let (n1, n2) = sons2(tree, n)
    assert n1.kind == nkInt32Lit
    assert n2.kind == nkInt32Lit
    let m = n1.litId
    let item = n2.operand

    let otherModule = toFileIndexCached(c, thisModule, m)
    if not c.alive[otherModule].containsOrIncl(item):
      c.stack.add((otherModule, item))

  of nkMacroDef, nkTemplateDef, nkTypeSection, nkTypeOfExpr,
     nkCommentStmt, nkIteratorDef, nkIncludeStmt,
     nkImportStmt, nkImportExceptStmt, nkExportStmt, nkExportExceptStmt,
     nkFromStmt, nkTemplateDef, nkMacroDef, nkStaticStmt:
    discard
  of nkVarSection, nkLetSection, nkConstSection:
    discard
  of nkProcDef, nkConverterDef, nkMethodDef, nkLambda, nkDo, nkFuncDef:
    if n.firstSon.kind == nkSym and isNotGeneric(n):
      if isExportedToC(tree, n.firstSon, alive):
        let item = n.operand
        # This symbol is alive and everything its body references.
        if not c.alive[c.thisModule].containsOrIncl(item):
          c.stack.add((c.thisModule, item))
  else:
    for son in sonsReadonly(tree, n):
      aliveCode(tree, son, alive)

proc aliveCode*(g: PackedModuleGraph; changedModule: int; conf: ConfigRef): MarkedAlive =
  ## Mark all symbols that are really used.
  var stack: seq[PackedItemId] = @[]


