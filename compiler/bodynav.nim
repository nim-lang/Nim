#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## `BodyNav` — a scope-chained navigator over a `.bif` routine body.
##
## Ported from Nimony's `nimony/typenav.nim` (`TypeCache` / `TypeScope`). The
## idea being stolen is not the type algebra — we do not need it, `typ` returns
## a fully materialized `PType` — but the SHAPE of the resolution context:
##
## * a chain of scope frames, each a small table, linked to its parent;
## * `openScope` / `closeScope` / `registerLocal`, called BY THE TRAVERSAL as it
##   descends and as it walks past each definition;
## * a lookup that consults the chain and, on a miss, falls through to the
##   module index (`typenav`'s `tryLoadSym`; here the decoder's own
##   `symFromCursor`).
##
## The consequence is the point: the scope is a PRODUCT OF THE WALK. Nothing is
## snapshotted, so nothing can be stale, and a reader that starts at the top of
## a body and descends always has exactly the definitions it has already passed.
##
## WHAT THIS REPLACES. `ast2nif.PendingBody` stashes `localSyms` — a COPY of the
## enclosing sym def's local symbols, taken when the body was deferred — and
## `bnode`'s `BodyScope` then copies it again. `materializeLazyBody` loads the
## body with its own `var pb`, so every definition the load creates lands in a
## table that is discarded on return. A cursor-side reader holding the earlier
## copy therefore cannot see them, and would mint its own `PSym` for the same
## name: two objects, one symbol.
##
## HOW BIG THAT PROBLEM ACTUALLY IS, measured rather than assumed. Build with
## `-d:icLocalSymStats` and every process reports its `localSyms` traffic on
## exit. Over a full `--ic:on` build of the standard-library closure (104
## backend processes):
##
##     localHit=0  fieldStub=2  miss=0  sdReg=5902  extractReg=45
##
## Definitions register constantly and NOT ONE use ever resolves through the
## table. The reason is `ast2nif.isLocalSym`, which returns a hardwired `false`:
## every symbol is emitted with a module suffix and resolves through the
## decoder's global `syms` memo, so both spellings get the same `PSym` whatever
## either one has cached. The 5902 registrations are object FIELDS, whose uses
## deliberately go to `loadFieldStub` instead.
##
## So the stale snapshot is a LATENT hazard, not a live bug, and this module is
## not a bug fix — it is the mechanism that keeps it latent once `isLocalSym`
## stops being `false`, or once a body-local name appears for any other reason.
## Said plainly so nobody has to re-derive it: today the nav changes no answers,
## and the grinder in `cgen` proves that by requiring the navigated symbol to be
## the same object the `PNode` loader produced, at every node of every body.
##
## It is not decorative either, and that also has a number. Over the same build,
## the grinder's traversal reports `navHits=42236 navFallbacks=12658
## navRegistered=311`: the chain answers 77% of lookups, and 311 definitions are
## registered by the walk rather than read from a table someone filled in
## earlier. Sabotaging the key (truncating it to three characters, so
## `c_fwrite` and `c_fflush` collide) makes the grinder fail on the first body
## it reaches — so a clean run means the resolution is right, not that the
## lookup never happened.
##
## FIELDS ARE NOT REGISTERED, and that is deliberate. `loadFieldStub` mints a
## fresh stub per use because two distinct fields can share a name (and a
## position) across types — `a.x` and `b.x` in one body are two different
## symbols. Caching a field by its bare name would hand the second use the first
## one's stub, and its type. The nav skips field names entirely and leaves that
## path exactly as it was.

import std / tables
import ast, ast2nif

when defined(nimPreviewSlimSystem):
  import std / assertions

import "../dist/nimony/src/lib/nifcore" except pool

type
  NavScopeKind* = enum
    nsBlock,                ## an ordinary nested scope
    nsRoutine               ## a routine boundary — see `crossedRoutines`

  NavScope {.acyclic.} = ref object
    locals: Table[string, PSym]
    parent: NavScope
    kind: NavScopeKind

  BridgeTables* = ref object
    ## The side tables of an IN-PROCESS bridged buffer (`nodebridge.nim`).
    ## A `.bif` names its symbols because the reader is a different process; a
    ## buffer built and read inside ONE process does not have to, and paying the
    ## name round trip anyway would be worse than pointless — it is what makes
    ## the file path unable to give a field a stable identity (`loadFieldStub`
    ## mints per use). Here a symbol reference is an index and resolution hands
    ## back the very same object, so `symAt` is exact and idempotent for every
    ## symbol kind, fields included.
    syms*: seq[PSym]
    types*: seq[PType]
    origins*: Table[int, PNode]
      ## Token position -> the `PNode` encoded there, so a cursor can name the
      ## node it came from. Lives here rather than in `BridgeBuf` because the
      ## lookup has to be reachable from wherever a location is built, which is
      ## everywhere in the generator — the same reason `syms` is here.
    buf*: ptr TokenBuf
      ## The buffer `origins` is keyed against; `cursorToPosition` needs it.
      ## Borrowed, not owned: it points into the `BridgeBuf` that a scoped
      ## `withBridge` is currently reading, and never outlives it.

  BodyNav* = object
    ## The resolution context for ONE routine body. `base` is what the decoder
    ## itself needs (the owning module plus a table `loadSymStub` can write
    ## into); the frame chain on top of it is this module's contribution.
    ##
    ## `bridge` is non-nil only while reading a bridged buffer. It is consulted
    ## FIRST and, when it answers, it answers exactly — there is no fallback,
    ## because a `(bsym …)` index that the tables cannot resolve is a corrupt
    ## buffer, not a cache miss.
    base*: BodyScope
    bridge*: BridgeTables
    current: NavScope
    hits*: int              ## resolved from the chain
    fallbacks*: int         ## resolved through the decoder
    registered*: int        ## definitions the walk registered

proc originAt*(t: BridgeTables; c: Cursor): PNode =
  ## The source node a cursor was encoded from, or nil when there is none (a
  ## `DotToken`, or a cursor that is not at a node head).
  if t == nil or t.buf == nil: return nil
  result = t.origins.getOrDefault(cursorToPosition(t.buf[], c), nil)

proc initBodyNav*(base: sink BodyScope): BodyNav =
  ## A nav over a body, seeded with whatever resolution context the decoder
  ## handed out. The root frame is a routine frame: a body IS one.
  result = BodyNav(base: base,
                   current: NavScope(locals: initTable[string, PSym](),
                                     parent: nil, kind: nsRoutine))

proc initBridgeNav*(tables: BridgeTables): BodyNav =
  ## A nav over an in-process bridged buffer. `base` stays empty — a bridged
  ## buffer names nothing, so there is nothing for the decoder to resolve — but
  ## the ROOT FRAME still has to exist: a walk brackets its descent with
  ## `openScope`/`closeScope`, and a nav without a root frame makes the first
  ## `closeScope` pop past the bottom.
  result = BodyNav(bridge: tables,
                   current: NavScope(locals: initTable[string, PSym](),
                                     parent: nil, kind: nsRoutine))

proc openScope*(nav: var BodyNav; kind = nsBlock) {.inline.} =
  nav.current = NavScope(locals: initTable[string, PSym](),
                         parent: nav.current, kind: kind)

proc closeScope*(nav: var BodyNav) {.inline.} =
  doAssert nav.current.parent != nil, "closeScope past the root frame"
  nav.current = nav.current.parent

template withScope*(nav: var BodyNav; kind: NavScopeKind; body: untyped) =
  openScope(nav, kind)
  try:
    body
  finally:
    closeScope(nav)

proc registerLocal*(nav: var BodyNav; name: string; s: PSym) {.inline.} =
  ## Record a definition the walk has just passed, in the innermost frame.
  nav.current.locals[name] = s
  inc nav.registered

proc lookupLocal*(nav: BodyNav; name: string): PSym =
  ## The chain only. `nil` when nothing in scope carries this name.
  var it {.cursor.} = nav.current
  while it != nil:
    let s = it.locals.getOrDefault(name)
    if s != nil: return s
    it = it.parent
  result = nil

proc crossedRoutines*(nav: BodyNav; name: string): int =
  ## How many routine frames separate the use from the definition — 0 when the
  ## definition is in the current routine. `typenav` computes the same thing as
  ## `LocalInfo.crossedProc`, and it is what tells a closure pass that a name is
  ## captured rather than local. Nothing consumes it here yet; it is the reason
  ## the frames carry a kind at all, and dropping the kind would make it
  ## unrecoverable later.
  var it {.cursor.} = nav.current
  var crossed = 0
  while it != nil:
    if it.locals.getOrDefault(name) != nil: return crossed
    if it.kind == nsRoutine: inc crossed
    it = it.parent
  result = -1

# ---------------------------------------------------------------------------
# Names
#
# A symbol reaches the reader in four shapes and they all NAME the same thing;
# `navName` is the one place that knows which token holds the name, so the
# lookup key is derived identically no matter which wrapper the writer chose.

proc navName*(n: Cursor): string =
  ## The NIF name a token denotes, or `""` when the token names no symbol.
  case nifcore.kind(n)
  of Symbol, SymbolDef:
    result = symName(n)
  of TagLit:
    let tag = n.tags.tagName(cursorTagId(n))
    if tag == symDefTagName:
      let name = childCursor(n)
      result = if nifcore.kind(name) in {Symbol, SymbolDef}: symName(name) else: ""
    elif tag == hiddenTypeTagName:
      # `(ht <type> <sym>)`
      var inner = childCursor(n)
      skip inner
      result = navName(inner)
    elif tag == symNodeFlagsTagName:
      # `(nflags <flags> <symnode>)`
      var inner = childCursor(n)
      skip inner
      result = navName(inner)
    else:
      result = ""
  else:
    result = ""

proc symToken*(n: Cursor): Cursor =
  ## The token that actually NAMES the symbol, with the wrappers stripped.
  ## `loadSymStub` accepts a `Symbol`, a `SymbolDef` or an `(sd ...)` and
  ## rejects everything else, so the `(ht ...)` / `(nflags ...)` forms have to be
  ## peeled here rather than at each call site — the same peeling `navName` does
  ## for the key, kept beside it so the two cannot drift apart.
  result = n
  while nifcore.kind(result) == TagLit:
    let tag = result.tags.tagName(cursorTagId(result))
    if tag == hiddenTypeTagName or tag == symNodeFlagsTagName:
      var inner = childCursor(result)
      skip inner            # the explicit type / the node flags
      result = inner
    else:
      break

proc cacheFrame(nav: var BodyNav): NavScope =
  ## Where a decoder-resolved name is remembered: the nearest ROUTINE frame.
  ## Not the innermost frame — a `.bif` name is unique within its module (see
  ## `isLocalSym`), so its meaning cannot change between frames, and caching it
  ## deeper would only throw it away sooner. Not the root either, so that a
  ## nested routine's names die with the nested routine.
  result = nav.current
  while result.kind != nsRoutine and result.parent != nil:
    result = result.parent

proc bridgeIndex(n: Cursor; tag: string): int =
  ## The `<intlit>` payload of a `(bsym …)` / `(btyp …)` token, or -1 when `n`
  ## is not that shape.
  result = -1
  if nifcore.kind(n) == TagLit and n.tags.tagName(cursorTagId(n)) == tag:
    let payload = childCursor(n)
    if nifcore.kind(payload) == IntLit:
      result = int(nifcore.intVal(payload))

proc symAt*(nav: var BodyNav; n: Cursor): PSym =
  ## The symbol a token names: the bridge first (exact), then the chain, then
  ## the decoder.
  if nav.bridge != nil:
    let idx = bridgeIndex(symToken(n), bridgeSymTagName)
    if idx >= 0:
      doAssert idx < nav.bridge.syms.len,
        "bridged sym index out of range: " & $idx
      inc nav.hits
      return nav.bridge.syms[idx]
  let name = navName(n)
  if name.len > 0:
    let cached = lookupLocal(nav, name)
    if cached != nil:
      inc nav.hits
      return cached
  inc nav.fallbacks
  result = symFromCursor(program, symToken(n), nav.base)
  if result != nil and name.len > 0 and not isFieldNifName(name):
    cacheFrame(nav).locals[name] = result

proc typeAt*(nav: var BodyNav; n: Cursor): PType =
  ## Types are not navigated: `ast2nif` already materializes them lazily from
  ## the module's type index, keyed by name, so there is no per-body state to
  ## keep and nothing a frame could cache that the decoder does not already.
  if nav.bridge != nil:
    if nifcore.kind(n) == DotToken: return nil
    let idx = bridgeIndex(n, bridgeTypeTagName)
    if idx >= 0:
      doAssert idx < nav.bridge.types.len,
        "bridged type index out of range: " & $idx
      return nav.bridge.types[idx]
  result = typeFromCursor(program, n, nav.base)

# ---------------------------------------------------------------------------
# Registration during a walk

proc registerDefHere*(nav: var BodyNav; n: Cursor): bool {.discardable.} =
  ## Register `n` if `n` ITSELF is a definition; do not descend. This is the
  ## incremental half: a walk calls it on each child before recursing into it,
  ## so a use can only resolve from the chain to a definition the walk has
  ## already passed. A use that precedes its definition simply misses and falls
  ## through to the decoder, which is the behaviour there was before — the nav
  ## degrades to the old path rather than answering wrongly.
  result = false
  if nifcore.kind(n) == TagLit and
     n.tags.tagName(cursorTagId(n)) == symDefTagName:
    let name = navName(n)
    if name.len > 0 and not isFieldNifName(name):
      let s = symFromCursor(program, n, nav.base)
      if s != nil:
        registerLocal(nav, name, s)
        result = true

proc registerDefs*(nav: var BodyNav; n: Cursor) =
  ## Register every definition in the SUBTREE at `n` — `typenav.registerLocals`
  ## with the recursion left in, because a Nim body puts `nkIdentDefs` under an
  ## `nkVarSection` under the statement list rather than declaring at one level.
  ##
  ## Call it on entering a scope to get the eager behaviour (every definition
  ## known before any use is resolved, which is what a RANDOM-ACCESS reader
  ## needs), or per statement to get the incremental one (only definitions
  ## already walked past are visible, which is what a real pass wants and what
  ## makes use-before-def detectable rather than silently working).
  if nifcore.kind(n) == TagLit and
     n.tags.tagName(cursorTagId(n)) == symDefTagName:
    let name = navName(n)
    if name.len > 0 and not isFieldNifName(name):
      let s = symFromCursor(program, n, nav.base)
      if s != nil: registerLocal(nav, name, s)  # `(sd ...)` needs no peeling
    return
  var c = childCursor(n)
  while c.hasMore:
    registerDefs(nav, c)
    skip c
