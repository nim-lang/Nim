import std/tables

import ast
import cgendata
import modulegraphs
import ropes
import sighashes

type
  SnippetTable* = Table[SigHash, Snippet]
  Snippets* = seq[Snippet]

  # the in-memory representation of a cachable unit of backend codegen
  CacheUnit*[T] = object
    node*: T                  # the node itself
    snippets*: SnippetTable   # snippets for this node
    graph*: ModuleGraph       # the module graph, for convenience
    modules*: BModuleList     # modules being built by the backend

  # the in-memory representation of the database record
  Snippet* = object
    signature*: SigHash       # we use the signature to associate the node
    module*: BModule          # the module to which the snippet applies
    section*: TCFileSection   # the section of the module in which to write
    code*: Rope               # the raw backend code itself, eg. C/JS/etc.

  # deprecated but we cannot say so due to nim bug
  SnippetMark* = object
    lengths*: array[TCFileSection, int]
    node*: PSym

proc newCacheUnit*[T](modules: BModuleList; node: T): CacheUnit[T] =
  result = CacheUnit[T](node: node, modules: modules, graph: modules.graph)
  let
    size = rightSize(TCFileSection.high.ord)
  result.modules = newModuleList(modules.graph)
  result.snippets = initTable[SigHash, Snippet](size)

# the snippet's module is not necessarily the same as the symbol!
proc newSnippet*[T](node: T; module: BModule; sect: TCFileSection): Snippet =
  result = Snippet(signature: node.sigHash, module: module, section: sect)

proc findModule(list: BModuleList; child: BModule): BModule =
  block found:
    for m in list.modules.items:
      if m.module != nil and m.module.id == child.module.id:
        result = m
        break found
    raise newException(Defect, "unable to find module " & $child.module.id)

proc merge(parent, child: BModule) =
  for section, rope in child.s.pairs:
    parent.s[section].add rope

proc mergeInto*(cache: CacheUnit; module: BModule) =
  for m in cache.modules.modules.items:
    var
      parent = module.g.findModule(m)
    merge(parent, m)
