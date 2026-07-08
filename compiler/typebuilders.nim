#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## `TypeBuilder`: a small, TokenBuf-shaped surface for constructing a `PType`.
##
## The compiler builds types by creating a mutable `TType` and then poking its
## sons/flags/`n` field into place at various call sites. This module funnels
## that construction through a builder object instead:
##
## ```nim
##   var b = openType(kind, idgen, owner)   # or openType(c, kind) with a PContext
##   b.incl someFlag
##   b.add someSon                          # skip int-lit + propagate flags
##   b.setN someNode
##   result = finish b
## ```
##
## Today the backing store is a mutable `TType`, so `finish` simply returns it
## and there is no runtime cost. The point of routing construction through the
## builder is that the backing store can later become a nifcore `TokenBuf` --
## with `openType` becoming `openTag`, the `add*` family becoming token/subtree
## appends, and `finish` becoming `beginRead` yielding a read-only cursor --
## *without touching any call site*.
##
## Contract: fully configure the type between `openType` and `finish`, and treat
## the `finish` result as immutable. Types that need their identity before their
## body is complete (recursive / deferred object types, e.g. `semEnum` and
## object bodies) are out of scope and keep using the direct `newType` /
## `rawAddSon` API for now; they will be modeled via symbol indirection later.

import ast
from itemids import ItemId

type
  SymId* = ItemId
    ## The stable identity of a type. Today an `ItemId`; this alias marks every
    ## place that will migrate to a content-based nifcore `SymId` later (once
    ## stable, content-derived names land -- so generic instances dedup across
    ## modules and processes). Keeping the alias means that migration is a
    ## one-line change here rather than a churn across call sites.
  TypePair* = object
    ## A type as an (identity, tree) pair: `id` names it, `decl` is its tree.
    ## Today `decl.itemId == id`, so the pair is a thin, forward-looking handle
    ## -- the handle a *named* type's body uses to refer to itself (owner /
    ## recursive references). Its real payoff arrives when `decl` becomes a
    ## nameless `NifCursor` and those self/forward references go through `id`.
    id*: SymId
    decl*: PType

proc typePair*(t: PType): TypePair {.inline.} =
  TypePair(id: t.itemId, decl: t)

proc skipIntLit*(t: PType; id: IdGenerator): PType {.inline.} =
  if t.n != nil and t.kind in {tyInt, tyFloat}:
    result = copyType(t, id, t.owner)
    result.n = nil
  else:
    result = t

proc addSonSkipIntLit*(father, son: PType; id: IdGenerator) =
  let s = son.skipIntLit(id)
  father.add(s)
  propagateToOwner(father, s)

type
  TypeBuilder* = object
    t: PType
    idgen {.cursor.}: IdGenerator
      ## non-owning: the id generator outlives every builder (it lives for the
      ## whole compilation), so it must not be reference-counted here.

proc openType*(kind: TTypeKind; idgen: IdGenerator; owner: PSym): TypeBuilder {.inline.} =
  ## Begins a fresh type of the given `kind`. Mirrors `newType`.
  TypeBuilder(t: newType(kind, idgen, owner), idgen: idgen)

proc add*(b: var TypeBuilder; son: PType) {.inline.} =
  ## Adds a son, skipping an int-literal wrapper and propagating type flags to
  ## the owner. Mirrors `addSonSkipIntLit` -- the common case.
  addSonSkipIntLit(b.t, son, b.idgen)

proc addRaw*(b: var TypeBuilder; son: PType; propagateHasAsgn = true) {.inline.} =
  ## Adds a son verbatim (no int-lit skip) but still propagates type flags.
  ## Mirrors `rawAddSon`.
  rawAddSon(b.t, son, propagateHasAsgn)

proc addKeep*(b: var TypeBuilder; son: PType) {.inline.} =
  ## Adds a son verbatim: no int-lit skip and no flag propagation. Mirrors the
  ## `newType(..., son = x)` fast path -- including that a nil son is skipped
  ## (produces a childless type) rather than added.
  if son != nil: b.t.add son

proc reopen*(t: PType; idgen: IdGenerator): TypeBuilder {.inline.} =
  ## Continues building an *existing* type in place, preserving its identity
  ## (`itemId`). Used to bind a freshly-built structure onto the reserved name
  ## of a forward-declared / partial type -- the "distinguish name from tree"
  ## case: the name (`t`) stays, only its tree structure is (re)built.
  TypeBuilder(t: t, idgen: idgen)

proc setN*(b: var TypeBuilder; n: PNode) {.inline.} =
  b.t.n = n

proc setFlags*(b: var TypeBuilder; flags: TTypeFlags) {.inline.} =
  ## Replaces the whole flag set (assignment, not union). Mirrors `t.flags = x`.
  b.t.flags = flags

proc incl*(b: var TypeBuilder; flag: TTypeFlag) {.inline.} =
  b.t.incl flag

proc incl*(b: var TypeBuilder; flags: TTypeFlags) {.inline.} =
  b.t.incl flags

proc propagateFrom*(b: var TypeBuilder; son: PType; propagateHasAsgn = true) {.inline.} =
  ## Propagates a son type's properties (flags, owner) into the type under
  ## construction. Mirrors a bare `propagateToOwner(result, son)`.
  propagateToOwner(b.t, son, propagateHasAsgn)

proc setCallConv*(b: var TypeBuilder; cc: TCallingConvention) {.inline.} =
  b.t.callConv = cc

proc setSym*(b: var TypeBuilder; s: PSym) {.inline.} =
  b.t.sym = s

template finish*(b: TypeBuilder): PType =
  ## Hands out the constructed type. A template so it collapses to a bare field
  ## read with no call/move/destroy overhead over the old direct construction.
  ## Later this becomes `beginRead`, yielding a read-only cursor.
  b.t
