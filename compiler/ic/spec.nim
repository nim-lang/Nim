## This module implements the new compilation cache.
import

  ".." / [ ast, cgendata, sighashes, modulegraphs, ropes, somenode ]

include

  # so we can see the icCache
  ".." / pcontext

import

  std / [ os, tables, deques ]

type
  CacheStrategy* = enum
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
  nimIcAudit* = when not defined(release): true else: false
when nimIcAudit:
  import audit
  export audit

proc isSealed*(c: PContext): bool = c.icSealed

proc isValid(c: PContext; n: SomeNode): bool  =
  assert c.module != nil
  if c.module != nil:
    assert not n.isNil
    let
      m = getModule(n)
    if m == nil:
      assert false, $n.kind & " node lacks module"
    else:
      if c.module == getModule(n):
        result = n.isValid

proc addIcCache*(c: PContext; p: PNode | PSym | PType) =
  ## add the given node to the context's cache
  let
    value = newSomeNode(p)
  assert c.isValid(value)
  c.icCache.addLast value

iterator consumer*(c: PContext): SomeNode =
  assert not c.isSealed
  if c.isSealed:
    raise newException(Defect, "context already sealed")
  c.icSealed = true
  while not c.icCache.isEmpty:
    yield c.icCache.popFirst

proc `$`*(m: BModule): string =
  result = $m.module.id & ".." & splitFile(m.cfilename.string).name
