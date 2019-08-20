#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements helpers for the macro cache.

import lineinfos, ast, modulegraphs, vmdef

proc recordInc*(c: PCtx; info: TLineInfo; key: string; by: BiggestInt) =
  var recorded = newNodeI(nkCommentStmt, info)
  recorded.add newStrNode("inc", info)
  recorded.add newStrNode(key, info)
  recorded.add newIntNode(nkIntLit, by)
  c.graph.recordStmt(c.graph, c.module, recorded)

proc recordPut*(c: PCtx; info: TLineInfo; key: string; k: string; val: PNode) =
  var recorded = newNodeI(nkCommentStmt, info)
  recorded.add newStrNode("put", info)
  recorded.add newStrNode(key, info)
  recorded.add newStrNode(k, info)
  recorded.add copyTree(val)
  c.graph.recordStmt(c.graph, c.module, recorded)

proc recordAdd*(c: PCtx; info: TLineInfo; key: string; val: PNode) =
  var recorded = newNodeI(nkCommentStmt, info)
  recorded.add newStrNode("add", info)
  recorded.add newStrNode(key, info)
  recorded.add copyTree(val)
  c.graph.recordStmt(c.graph, c.module, recorded)

proc recordIncl*(c: PCtx; info: TLineInfo; key: string; val: PNode) =
  var recorded = newNodeI(nkCommentStmt, info)
  recorded.add newStrNode("incl", info)
  recorded.add newStrNode(key, info)
  recorded.add copyTree(val)
  c.graph.recordStmt(c.graph, c.module, recorded)
