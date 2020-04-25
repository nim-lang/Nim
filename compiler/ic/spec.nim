## This module implements the new compilation cache.
import

  ".." / [ ast, cgendata, sighashes, modulegraphs, ropes ]

import

  std / [ os, tables ]

type
  CacheStrategy* {.pure.} = enum
    Reads       = "📖"
    Writes      = "✒️"
    Immutable   = "🔏"

  CacheableObject* = PSym or PNode or PType

  CacheUnitKind* = enum Symbol, Node, Type

  # the in-memory representation of a cachable unit of backend codegen
  CacheUnit*[T: CacheableObject] = object
    strategy*: set[CacheStrategy]
    kind*: CacheUnitKind
    node*: T                     # the node itself
    snippets*: SnippetTable      # snippets for this node
    transforms*: TransformTable  # transforms for this node
    graph*: ModuleGraph          # the original module graph
    modules*: BModuleList        # modules being built by the backend
    origin*: BModule             # presumed original module

  # the in-memory representation of the database record
  Snippet* = object
    signature*: SigHash       # we use the signature to associate the node
    module*: BModule          # the module to which the snippet applies
    section*: TCFileSection   # the section of the module in which to write
    code*: Rope               # the raw backend code itself, eg. C/JS/etc.

  SnippetTable* = OrderedTable[SigHash, Snippet]
  Snippets* = seq[Snippet]

proc ultimateOwner*(p: PSym): PSym =
  if p == nil or p.owner == nil or p.kind in {skModule, skPackage}:
    result = p
  else:
    result = p.owner.ultimateOwner

proc ultimateOwner*(p: PType): PSym =
  if p == nil or p.sym == nil:
    assert false
    result = nil
  else:
    result = p.sym.ultimateOwner

when false:
  template kind[T](tree: TreeNode[T]): CacheUnitKind =
    when T is PNode:
      Node
    elif T is PType:
      Type
    elif T is PSym:
      Symbol
    else:
      {.fatal: "undefined cache unit kind for tree node".}

const
  nimIcAudit = when not defined(release): true else: false
when nimIcAudit:
  import audit
  export audit

proc `$`*(m: BModule): string =
  result = $m.module.id & ".." & splitFile(m.cfilename.string).name
