#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the canonalization for the various caching mechanisms.

import

  msgs, options, ast, renderer, idents, astalgo, btrees, magicsys,
  extccomp, treetab, condsyms, nversion, pathutils, cgendata, trees, ndi,
  sighashes, modulegraphs, idgen, lineinfos, incremental, types, ccgutils,
  ropes

import

  std / [ strformat, os, db_sqlite, intsets, tables, strutils, sequtils,
  hashes, macros ]

import sets except rightSize

export nimIncremental

{.experimental: "codeReordering".}

import # ic imports

  ic / [ spec, backend, frontend, store, utils, merge ]

# true when an audit is available
export
  nimIcAudit
when nimIcAudit:
  export hash

export
#  isSealed,
  addIcCache

# backend API
export

  getSetConflict, rawNewModule, getTempName, makeTempName, idOrSig,
  performCaching,
  rejected, `$`,
  reject, # used in an exported template
  setLocation, setLocationRope,
  inclLocationFlags, exclLocationFlags

# merging
export

  genSectionStart, genSectionEnd,
  genMergeInfo, mergeRequired, mergeFiles

# frontend API
export

  seal, loadNode, loadModuleSym, registerModule, setupModuleCache

## TODO:
## - Add some backend logic dealing with generics.
## - Dependency computation should use *signature* hashes in order to
##   avoid recompiling dependent modules.
## - Patch the rest of the compiler to do lazy loading of proc bodies.
## - Serialize the AST in a smarter way (avoid storing some ASTs twice!)

template db(): DbConn = g.incr.db
template config(): ConfigRef = cache.modules.config

# idea for testing all this logic: *Always* load the AST from the DB, whether
# we already have it in RAM or not!

when false:
  proc newTreeNode*[T: CacheableObject](node: var T;
                                        strategy = {Reads, Immutable}):
                                        TreeNode =
    assert node != nil
    result.strategy = {Writes}
    result.node = node
    when T is PNode:
      result.kind = CacheUnitKind.Node
    elif T is PSym:
      result.kind = CacheUnitKind.Symbol
    elif T is PType:
      result.kind = CacheUnitKind.Type
    else:
      {.fatal: "unsupported node type".}

  proc write[T: CacheableObject](g: ModuleGraph; tree: var TreeNode[T]) =
    assert Writes in tree.strategy
    if not Writes in tree.trategy:
      raise newException(Defect, "attempt to write unwritable tree node")
    case tree.kind
    of Node:
      g.storeNode(tree.node)
    of Symbol:
      g.storeSym(tree.node)
    of Type:
      g.storeType(tree.node)
    tree.seal

  proc setLocation*[T: PSym or PType](context: PContext; node: T; loc: TLoc) =
    if tree.sealed:
      raise newException(Defect, "tree is sealed")
    tree.setLocation(node, loc)
