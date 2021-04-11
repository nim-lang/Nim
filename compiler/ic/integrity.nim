#
#
#           The Nim Compiler
#        (c) Copyright 2021 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Integrity checking for a set of .rod files.
## The set must cover a complete Nim project.

import std / intsets
import ".." / [ast, modulegraphs]
import packed_ast, bitabs, ic

type
  CheckedContext = object
    g: ModuleGraph
    thisModule: int
    checkedSyms: IntSet
    checkedTypes: IntSet

proc checkLocalSym(c: var CheckedContext; item: int32) =
  discard "to implement"

proc checkForeignSym(c: var CheckedContext; m: LitId; item: int32) =
  discard "to implement"

proc checkNode(c: var CheckedContext; tree: PackedTree; n: NodePos) =
  case n.kind
  of nkEmpty, nkNilLit, nkType, nkNilRodNode:
    discard
  of nkIdent:
    assert c.g.packed[c.thisModule].fromDisk.sh.strings.hasLitId n.litId
  of nkSym:
    checkLocalSym(c, tree.nodes[n.int].operand)
  of directIntLit:
    discard
  of externIntLit:
    assert c.g.packed[c.thisModule].fromDisk.sh.integers.hasLitId n.litId
  of nkStrLit..nkTripleStrLit:
    assert c.g.packed[c.thisModule].fromDisk.sh.strings.hasLitId n.litId
  of nkFloatLit..nkFloat128Lit:
    assert c.g.packed[c.thisModule].fromDisk.sh.floats.hasLitId n.litId
  of nkModuleRef:
    let (n1, n2) = sons2(tree, n)
    assert n1.kind == nkInt32Lit
    assert n2.kind == nkInt32Lit
    checkForeignSym(c, n1.litId, tree.nodes[n2.int].operand)
  else:
    for n0 in sonsReadonly(tree, n):
      checkNode(c, tree, n0)

proc checkTree(c: var CheckedContext; t: PackedTree) =
  for p in allNodes(t): checkNode(c, t, p)

proc checkModule(c: var CheckedContext; m: PackedModule) =
  # We check that:
  # - Every type references existing types and symbols.
  # - Every symbol references existing types and symbols.
  # - Every tree node references existing types and symbols.
  checkTree c, m.toReplay
  checkTree c, m.topLevel

proc checkIntegrity*(g: ModuleGraph) =
  var c = CheckedContext(g: g)
  for i in 0..high(g.packed):
    # case statement here to enforce exhaustive checks.
    case g.packed[i].status
    of undefined:
      discard "nothing to do"
    of loading:
      assert false, "cannot check integrity: Module still loading"
    of stored, storing, outdated, loaded:
      c.thisModule = i
      checkModule(c, g.packed[i].fromDisk)

