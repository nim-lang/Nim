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

proc reopen*(t: PType): TypeBuilder {.inline.} =
  ## Reopens an existing type purely to *transform* its sons in place (see
  ## `setSon`), without adding fresh ones -- so no `idgen` is needed. This is the
  ## "mutable staging buffer" seam for son-replacement: today it is in-place
  ## mutation of `t`; under NIF `reopen` thaws `t`'s sealed cursor into a mutable
  ## buffer, `setSon` rewrites a token, and the buffer is re-sealed. Distinct from
  ## the id-minting `reopen(t, idgen)` used to (re)build a forward type's body.
  TypeBuilder(t: t, idgen: nil)

proc setSon*(b: var TypeBuilder; i: int; son: PType) {.inline.} =
  ## Replaces son `i` of a reopened type -- the in-place transform seam. Mirrors
  ## the old `PType.[]=` (via `ast.replaceSon`), including the `tyProc` return/
  ## param slot handling. Distinct from `add` (append a new son) and from the
  ## whole-list `ast.setSon(dest, son)`. Under NIF this is a token rewrite in the
  ## buffer thawed by `reopen`.
  replaceSon(b.t, i, son)

proc setSon*(b: var TypeBuilder; i: BackwardsIndex; son: PType) {.inline.} =
  replaceSon(b.t, i, son)

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

type
  TypePairBuilder* = object
    ## The *deferred* construction seam: like `TypeBuilder`, but its identity is
    ## published -- cached, stashed for a later pass, or handed to a recursive
    ## sem call -- *before* its body is finished. Recursive generic
    ## instantiation needs the in-progress instance to be findable under its
    ## name while its sons are still being appended; `TypeBuilder` cannot model
    ## that because `finish` is the seal point and nothing may be appended after
    ## it. `TypePairBuilder` can, because the thing it hands out early is a
    ## `TypePair` -- an (identity, tree) pair -- and early consumers take only
    ## its `id`.
    ##
    ## Contract: whatever observes `pair` before `finishPair` must rely on
    ## `pair.id` (the name) alone -- never the son count or son contents of the
    ## still-open `decl`. Today `decl` is the growing `PType` and `decl.itemId
    ## == id`, so this holds trivially; under NIF `id` is a `SymId` valid the
    ## instant the shell exists and `decl` is the open `TokenBuf`, sealed into a
    ## read-only cursor by `finishPair`.
    t: PType
    idgen {.cursor.}: IdGenerator

proc openPair*(kind: TTypeKind; idgen: IdGenerator; owner: PSym;
               son: sink PType = nil): TypePairBuilder {.inline.} =
  ## Mints the shell (optionally with `son0` already set -- e.g. the generic
  ## head for `tyGenericInst`). Mirrors `newType(kind, idgen, owner, son)`. The
  ## `pair` is publishable the moment this returns.
  TypePairBuilder(t: newType(kind, idgen, owner, son), idgen: idgen)

proc reopenPair*(t: PType; idgen: IdGenerator): TypePairBuilder {.inline.} =
  ## Continues building an *existing* (forward-declared / partial) type as a
  ## deferred pair, preserving its identity. The deferred analogue of
  ## `reopen(t, idgen)`; its `pair` is publishable immediately.
  TypePairBuilder(t: t, idgen: idgen)

proc pair*(b: TypePairBuilder): TypePair {.inline.} =
  ## The publishable (identity, tree) handle -- cache it / stash it / thread it
  ## through recursive sem *before* the body is complete. Only `pair.id` may be
  ## relied upon by those early consumers.
  typePair(b.t)

proc add*(b: var TypePairBuilder; son: PType) {.inline.} =
  addSonSkipIntLit(b.t, son, b.idgen)

proc addRaw*(b: var TypePairBuilder; son: PType; propagateHasAsgn = true) {.inline.} =
  ## Appends a son verbatim while the body is open. Mirrors `rawAddSon` -- the
  ## incremental-append step of the deferred build.
  rawAddSon(b.t, son, propagateHasAsgn)

proc setSon*(b: var TypePairBuilder; i: int; son: PType) {.inline.} =
  replaceSon(b.t, i, son)

proc setN*(b: var TypePairBuilder; n: PNode) {.inline.} =
  b.t.n = n

proc addRecField*(b: var TypePairBuilder; fieldNode: PNode) {.inline.} =
  ## Appends a field entry to the type's record list (`.n`), the way tuple /
  ## object / proc bodies grow their `nkRecList` / `nkFormalParams`. Mirrors
  ## `t.n.add fieldNode`, and pairs with `add`/`addRaw` for the parallel son.
  b.t.n.add fieldNode

proc flags*(b: TypePairBuilder): TTypeFlags {.inline.} =
  ## Reads the shell's current flags (they may have accumulated via `addRaw`'s
  ## propagation since the last `setFlags`).
  b.t.flags

proc setFlags*(b: var TypePairBuilder; flags: TTypeFlags) {.inline.} =
  b.t.flags = flags

proc incl*(b: var TypePairBuilder; flag: TTypeFlag) {.inline.} =
  b.t.incl flag

proc finishPair*(b: sink TypePairBuilder): TypePair {.inline.} =
  ## Seals the deferred build. Today returns the pair unchanged; under NIF this
  ## is `beginRead` -- the open `TokenBuf` becomes a read-only cursor, still
  ## reachable through `pair.id`, so recursive references bound to the name now
  ## resolve to the sealed tree.
  typePair(b.t)
