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

  AliveContext* = object
    stack: seq[(int, NodePos)]
    decoder: PackedDecoder
    thisModule: int
    alive: MarkedAlive

proc isExportedToC(c: var AliveContext; g: PackedModuleGraph; symId: int32): bool =
  let symPtr = addr g[c.thisModule].fromDisk.sh.syms[symId]
  let flags = symPtr.flags
  # due to a bug/limitation in the lambda lifting, unused inner procs
  # are not transformed correctly; issue (#411). However, the whole purpose here
  # is to eliminate unused procs. So there is no special logic required for this case.
  if sfCompileTime notin flags:
    if ({sfExportc, sfCompilerProc} * flags == {sfExportc}) or
        (symPtr.kind == skMethod):
      result = true
      # XXX: This used to be a condition to:
      #  (sfExportc in prc.flags and lfExportLib in prc.loc.flags) or

template isNotGeneric(n: NodePos): bool = ithSon(tree, n, genericParamsPos).kind == nkEmpty

proc followLater(c: var AliveContext; g: PackedModuleGraph; module: int; item: int32) =
  if not c.alive[module].containsOrIncl(item):
    let body = g[module].fromDisk.sh.syms[item].ast
    if body != emptyNodeId:
      c.stack.add((module, NodePos(body)))

proc aliveCode(c: var AliveContext; g: PackedModuleGraph; tree: PackedTree; n: NodePos) =
  case n.kind
  of nkNone..pred(nkSym), succ(nkSym)..nkNilLit:
    discard "ignore non-sym atoms"
  of nkSym:
    # This symbol is alive and everything its body references.
    followLater(c, g, c.thisModule, n.operand)
  of nkModuleRef:
    let (n1, n2) = sons2(tree, n)
    assert n1.kind == nkInt32Lit
    assert n2.kind == nkInt32Lit
    let m = n1.litId
    let item = n2.operand
    let otherModule = toFileIndexCached(c.decoder, g, c.thisModule, m).int
    followLater(c, g, otherModule, item)
  of nkMacroDef, nkTemplateDef, nkTypeSection, nkTypeOfExpr,
     nkCommentStmt, nkIteratorDef, nkIncludeStmt,
     nkImportStmt, nkImportExceptStmt, nkExportStmt, nkExportExceptStmt,
     nkFromStmt, nkStaticStmt:
    discard
  of nkVarSection, nkLetSection, nkConstSection:
    discard
  of nkProcDef, nkConverterDef, nkMethodDef, nkLambda, nkDo, nkFuncDef:
    if n.firstSon.kind == nkSym and isNotGeneric(n):
      if isExportedToC(c, g, n.firstSon.operand):
        let item = n.operand
        # This symbol is alive and everything its body references.
        followLater(c, g, c.thisModule, item)
  else:
    for son in sonsReadonly(tree, n):
      aliveCode(c, g, tree, son)

proc followNow(c: var AliveContext; g: PackedModuleGraph) =
  while c.stack.len > 0:
    let (modId, ast) = c.stack.pop()
    c.thisModule = modId
    aliveCode(c, g, g[modId].fromDisk.bodies, ast)

proc computeAliveSyms*(g: PackedModuleGraph; conf: ConfigRef): AliveContext =
  result = AliveContext(stack: @[], decoder: PackedDecoder(config: conf),
                       thisModule: -1, alive: newSeq[IntSet](g.len))
  for i in countdown(high(g), 0):
    if g[i].status != undefined:
      result.thisModule = i
      var p = 0
      while p < g[i].fromDisk.topLevel.len:
        aliveCode(result, g, g[i].fromDisk.topLevel, NodePos p)
        let s = span(g[i].fromDisk.topLevel, p)
        inc p, s
  followNow(result, g)

proc isAlive*(a: AliveContext; module: int, item: int32): bool =
  result = a.alive[module].contains(item)

