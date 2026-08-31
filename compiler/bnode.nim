#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## `BNode` — the backend's node type, and the seam for running codegen off a
## `.bif` `Cursor` instead of a deserialized `PNode` tree.
##
## A stage's cost tracks the size of the dependency CLOSURE it loads, not the
## module it compiles. That is why this seam exists — but WHERE the closure's
## cost sits has since been measured, and it is not where the seam can reach.
## On a cold `--ic:on` build of a 68-module target (10.1s wall, `-d:icBNodeProf`,
## `-d:icNoParallel`), summed over all 177 backend processes:
##
##     loadDepClosure   3306ms     of which  moduleId        1285ms
##                                           processTopLevel 1516ms
##                                           interface tbls  1323ms
##     genProcBody       333ms
##     handOffBody        60ms   <- the bridge encode
##     transformBody      28ms
##
## So reading a routine body off a cursor instead of a tree is DONE and free —
## `genProcBody` costs the same either way (see "WHAT IT COSTS" below) — but
## finishing the job, i.e. reading a `.t.bif` body directly and never
## materialising the `PNode`, can only win back the `handOffBody` +
## `transformBody` line: under 1% of the build. The 41% is in getting the
## closure's INTERFACE into memory, which no amount of body-reading touches.
## (Skipping the interface tables for dep-of-a-dep loads was tried as the
## obvious lever and returns ~200ms, not enough to justify a name that silently
## fails to resolve; see `SkipInterfaceTables`, which stays restricted to
## `loadTransitiveHooks`.)
##
## Anyone about to spend a week on the remaining blockers below — `TLoc.lode`
## above all — should weigh them against that budget first.
##
## With `-d:newIcBackend` `BNode` is a `distinct Cursor`; without it a plain
## `PNode`, which is what every build does today. Codegen migrates to the
## vocabulary below one area at a time and the compiler keeps building
## throughout, because on the `PNode` side the vocabulary is what `ast`/`astdef`
## already provide — `kind`, `len`, `safeLen`, `sym`, `typ`, `info`, `firstSon`,
## `secondSon`, `lastSon` and the `sons`/`isons`/`sonsFrom`/`sonsButLast`/
## `isonsButLast` iterators all exist. This module does not redefine those for
## `PNode`; it adds only what the AST lacks (`son`, `hasSons`, `isNilNode`) and
## supplies the whole vocabulary on the `Cursor` side.
##
## THE NODE ENCODING. This is the part that a "a `Cursor` is just a tree
## position" reading gets wrong, and getting it wrong is silent. `ast2nif`'s
## writer emits every node through `withNode`, which is
##
##     (<kind-tag> <flags> <type> <child 0> <child 1> ...)
##
## so a node's own flags and its `typ` occupy the FIRST TWO raw children and the
## AST's child 0 is the THIRD. `nifcore.childCursor` — and `ast2nif`'s own
## `firstSon(n: Cursor)`, which is a RAW structural accessor used to reach the
## name inside an `(sd ...)`/`(td ...)` — return the flags slot, not child 0.
## Every accessor below therefore steps over that two-token prefix. The
## exceptions are exactly:
##
## * `(none)` and a type-less `(empty)`, written bare with NO prefix and no
##   children — so "zero raw children" means "no prefix", never "prefix but no
##   AST children", which is what makes the two cases distinguishable at all;
## * an `nkSym`, which is not a `TagLit` node: it is a bare `Symbol` token, or
##   `(ht <type> <sym>)` when the node's type differs from the symbol's, or
##   `(nflags <flags> <symnode>)` when persisted node flags need saying, or an
##   `(sd <name> ...)` definition;
## * a nil child, written as a `DotToken` — `isNilNode` is the `n == nil` of the
##   `PNode` world, which has no `Cursor` counterpart.
##
## `len` follows `safeLen`'s rule and answers 0 for `nkNone..nkNilLit`: the
## payload token of an `nkIntLit`/`nkStrLit`/`nkIdent` sits where a child would,
## and is not one.
##
## `BNode` is DISTINCT from `Cursor` for that same reason. The two accessor sets
## are both spelled `firstSon` and differ by two positions, so a raw structural
## cursor reaching a call site that wants AST children must not silently
## typecheck — and the distinction also keeps `ast2nif.firstSon(n: Cursor)` from
## colliding with this module's.
##
## THE COST MODEL DIFFERS from a `PNode`'s, and that is what the vocabulary is
## shaped around. A `Cursor` is a position in a token stream, and a child is
## reached by stepping over each preceding sibling. Stepping is cheap — a
## `TagLit` token stores the width of its whole subtree, so `nifcore.skip` is a
## single pointer add regardless of how big that subtree is — but there is no
## random access and no way to walk backwards:
##
## * `firstSon` / `secondSon` / `son(n, k)` — O(k) in the NUMBER of preceding
##   siblings, not in their size. Cheap for the small constant `k` that nearly
##   all structural access in the cgen files uses.
## * `for x in sons(n)` / `sonsFrom(n, k)` / `sonsButLast(n, k)`, and the
##   index-yielding `isons` / `isonsButLast` — one pass. ALWAYS use these for a
##   loop: `for i in 0..<n.len: n[i]` is O(children^2). A loop that stops at a
##   computed position walks forward and breaks
##   (`for i, it in isons(n): if i >= casePos: break`) rather than counting up
##   to the bound.
## * `lastSon(n)` — O(len), because nothing points backwards. Fine once, a trap
##   inside a loop; `sonsButLast` is the loop form.
## * `len(n)` — O(len) too: it counts. Do not put it in a loop condition; use
##   the iterators, or `hasSons` for an emptiness test.
##
## `kind` is the one accessor whose cost is not structural. A `.bif` carries its
## OWN tag pool, so a tag id means nothing outside the file it came from and
## there can be no process-global id -> `TNodeKind` table; the answer is
## memoized per pool instead, and the memo is dropped when the pool changes.
##
## WHAT IT COSTS, AND HOW TO MEASURE IT. Cursor-driven generation is now the
## same speed as tree-driven: summed over the 2420 routines of a 68-module
## target, `genProcBody` takes 369ms off a cursor and 366ms off a `PNode`. It
## did not start there — it was 1877ms, 5.1x — and the whole difference was ONE
## accessor, so the tools are worth keeping:
##
## * `-d:icBNodeProf` counts every accessor and times the phases (`handOffBody`,
##   `genProcBody`, the analyses, and `sym`/`typ`/`info`/`origin`), plus the
##   COARSE phases that say where a process's time goes when none of those
##   account for it: `Stage` (the whole stage body, so `Process - Stage` is
##   startup: exec, runtime init, config replay, graph setup) and the per-stage
##   slots `LowerOwned`/`LowerHooks`/`LowerWrite` and
##   `CgGen`/`CgInit`/`CgFinish`/`CgWrite`. Each process appends a line to
##   `$NIM_IC_BNODE_PROF` tagged `stage=<name>`, so a parallel build still
##   produces attributable output.
##
##   Read the tag. A `nim m` process arms the profiler through ast2nif but never
##   enters a backend stage, so without splitting on `stage=` those 180-odd
##   frontend runs land in the "startup" column and invent an enormous phantom
##   cost. Atlas at batch size 16, serially, is where that shows: 180 frontend
##   processes are 9.9s, and the 28 backend ones are 6.8s of which 6.7s is
##   inside the stage bodies — `.t.bif` writing 1.68s and cg's demand-driven
##   generation 1.91s are the two largest single items.
##
##   The frontend splits (same run, `Stage`/`WriteNif` + the loading slots):
##
##       startup (exec+runtime+config)    0.17s    2%
##       loading imported `.s.bif`        4.57s   46%
##       writing this module's `.s.bif`   1.84s   18%
##       sem + parse                      3.41s   34%
##
##   So two thirds of the frontend is artifact I/O, not compilation. Within the
##   loading, `interfHidden` is 1.05s of it: 1.70M hidden-symbol stubs against
##   0.29M exported ones, built by every `nim m` for every module it imports.
##   That table is reached ONLY through `modulegraphs.interfSelect` when
##   `optImportHidden` is set, which happens in exactly one place — an
##   `import x {.all.}`. Skipping it outright (measured with a probe, not a
##   guess) takes `InterfTables` 1161ms -> 80ms, the frontend 9.98s -> 8.93s and
##   the whole Atlas build 22.19s -> 20.47s. Doing it CORRECTLY means populating
##   the table lazily on first `interfSelect(true)` rather than deciding
##   up front — a macro-generated `{.all.}` import cannot be seen syntactically,
##   and guessing wrong loses symbols silently.
##
##   That conversion is DONE (`modulegraphs.ensureHiddenIface` +
##   `ast2nif.buildHiddenInterface`), and the thing that made it hard is worth
##   knowing: a module has TWO FileIndexes. `registerNifSuffix` keys
##   `filenameToIndexTbl` by the NIF SUFFIX and mints a `fikNifModule` entry,
##   while the graph indexes `g.ifaces` by the module's `fikSource` file.
##   `DecodeContext.mods` is keyed by the former. Asking it with the latter
##   misses every single time, silently, and `import x {.all.}` then reports
##   "undeclared identifier" for a symbol that is right there. So the lazy
##   builder takes a SUFFIX, not a FileIndex. Two further conditions are also
##   load-bearing: clear the pending flag only when the build SUCCEEDS (an
##   import whose `.s.bif` does not exist yet must be retried, not written off),
##   and build into a LOCAL table before assigning it back (loading symbols can
##   grow `g.ifaces`, which would leave a `var` alias into it dangling).
##   `tests/ic/timporthidden.nim` is what says all of this still holds.
## * `-d:icBridgeOnly` builds the buffer but generates off the tree, which
##   separates the ENCODER's cost from the READER's. Encoding is free — it does
##   not show in wall time at all.
##
## Three plausible suspects were measured and were all wrong. They are recorded
## so nobody re-guesses them: the tag-name string compares in `typ`/`flags`
## (worth 0.3% of the build); `Cursor`'s reference-counting lifetime hooks,
## which really do run 6M times on that target but cost 60ms of 1900ms; and the
## structural accessors as a whole — `kind`, `son` and the iterators together
## are 32ms of 1877ms.
##
## The cost was `info`: 259k calls at 5.2us each, because resolving a token's
## `FileId` copied a path out of the buffer's filename pool and hashed it, every
## single time. `ast2nif.oldLineInfo` memoizes that per pool now. That also
## halved the cold `--ic:on` build for BOTH representations, because the decoder
## was paying the same price on every node it loaded — so the accessor that
## looked like the cursor path's problem was really the whole IC pipeline's.
##
## RESOLUTION CONTEXT. `sym`, `typ` and `info` cannot be answered by the cursor
## alone: a `Symbol` token holds only a NAME, a type slot only a type's name,
## and a packed line info a `FileId` in the `.bif`'s own filename pool. All
## three need the decoder's state, and the decision recorded here is that they
## take it from AMBIENT STATE rather than from a parameter:
##
## * the `DecodeContext` is the process-wide `ast.program`, which already exists
##   and is already what `ast.loadSym`/`loadType` resolve through;
## * the per-body half is a `bodynav.BodyNav` on a STACK, pushed by
##   `withBodyScope` for the span of one routine body. It has to be a stack and
##   not a single slot because generating one routine can pull in another
##   (`genProcNoForward`) before the first is finished.
##
## Threading a `DecodeContext` parameter through the ~230 `PNode`-taking procs
## in the cgen files instead would be exactly the churn the `BNode` seam exists
## to avoid, and codegen is already single-threaded within a stage process
## (`--icBackendStage:cg --icBackendModule:X` compiles one module per process).
##
## The nav is not merely a renamed snapshot: it is a SCOPE CHAIN THE TRAVERSAL
## MAINTAINS (`openScope` / `closeScope` / `registerDefHere`), ported from
## Nimony's `typenav`, so a reader descending a body always has exactly the
## definitions it has already walked past and nothing is copied ahead of time.
## `bodynav`'s module doc has the measurement that says how much of a live
## problem the old snapshot was — the honest answer is "none yet" — and why the
## mechanism is still the right shape. `sym` goes through it; `typ` does not,
## because `ast2nif` already materialises types lazily from the module's type
## index and a frame has nothing to add.
##
## HOW THIS IS VERIFIED. Two oracles, neither of them a hand-written
## expectation:
##
## * the `isMainModule` self-test at the bottom of this file checks the
##   accessors against the raw token stream of real `.bif` files. Necessary but
##   NOT sufficient, and the reason is worth remembering: a vocabulary that is
##   uniformly wrong — every accessor off by the same two positions — satisfies
##   every accessor-against-accessor check there is. This test passed 5.2M
##   assertions on exactly that wrong model.
## * `cgen.grindBNode` (opt-in, `NIM_IC_BNODE_GRIND=1` on an `--ic:on` build)
##   walks the cursor and the materialised `PNode` for the SAME body in
##   LOCKSTEP and requires `kind`, `len`, `info`, `flags`, the literal payloads,
##   `sym` and `typ` to agree at every node of every routine body in the
##   dependency closure — and, separately, requires each migrated `AnyNode` proc
##   to return the same answer for the whole body. The `PNode` is the oracle, so
##   it compares everything rather than what someone thought to check. That walk
##   also DRIVES the nav — it opens a scope per node and offers each child to
##   `registerDefHere` before descending — so what is graded is the vocabulary as
##   a cursor-native pass would actually use it, not a random-access shortcut.
##
## The second oracle is what found the `typ` bug (a bare `Symbol` answered `nil`
## where `ast.typ` falls back to the symbol's type — which silently turns
## `canRaise` into "cannot raise" and drops the goto-exception check after a
## call) and the `.sons` bug named below. A clean run means nothing until you
## have broken an accessor on purpose and watched the grinder fire.
##
## The cgen files hold to one invariant, which is what makes the eventual flip
## mechanical: NO `[]` AND NO `.sons` ON A `PNode` OUTSIDE OF TREE
## CONSTRUCTION. `.sons` is not merely the un-portable spelling of the walk: it
## is the raw FIELD, so it bypasses the `len` hook that materializes a deferred
## `nfLazyBody` body, and `for x in n.sons` over a routine body that is still a
## placeholder silently visits NOTHING. `for x in sons(n)` goes through
## `safeLen` and materializes. (This is not hypothetical — it is what the
## differential grinder in `cgen.grindBNode` reported the first time it ran, and
## it had been sitting in `containsResult` itself.) Every read is
## `firstSon`/`secondSon`/`lastSon`/`son(n, k)` or one of the iterators; the
## remaining subscripts are writes that build a fresh `nkProcDef`
## (`theProc[namePos] = ...`), which a `Cursor` backend will not do at all, and
## accesses to a `PType`, a `string`, a `seq` or a `Table`, none of which are
## `BNode`s.
##
## A `PType` has its own vocabulary and its own reason for preferring it: `t[0]`
## is the return type, the base class, the index type or the generic head
## depending on the kind, and `ast.sons(t: PType)` is a `proc` returning the raw
## seq — NOT the iterator of the same name — which for a `tyProc` does not hold
## the parameters at all. Reach for `returnType` / `baseClass` / `elementType` /
## `genericHead` and the `kids` / `ikids` / `paramTypes` / `signature`
## iterators, which name the child and go through `[]`.
##
## WHAT RUNS ON A CURSOR, AND WHAT STILL DOES NOT. `expr` and the ~160 emitters
## under it read the routine body through a cursor: `cgen.genProcBody` is handed
## `BNode(bodyBuf.rootCursor)` and the whole generator follows. It had to land in
## one step — `expr` dispatches to all of them — and what made that possible
## without changing `TLoc` was `nodebridge`'s ORIGIN TRACKING: a cursor can name
## the `PNode` it was encoded from, so `TLoc.lode` stays a `PNode` holding the
## same object a tree-driven build would have stored, and the identity
## comparisons already in the backend keep meaning what they meant.
##
## `origin` is also how the generator's own REWRITES survive. It does mutate in
## places (`mAppendSeqElem`, `mNewSeq`, `genSetLengthSeq`, `genWasMoved`,
## `genArrToSeq` replace a child or a type in place; `genEnumToStr`, `mAsgn` and
## `spawn` build fresh trees), and those run on the origin. Where the mutation is
## then read back, generation continues on the origin too — the buffer does not
## see the write, so a cursor would keep reading the slot as encoded. That is the
## one hazard to remember when migrating anything else that writes.
##
## What is left is not a backlog, it is named blockers, each recorded at its own
## site:
##
## * A type's RECORD TREE is not a body. `asgnComplexity`,
##   `isEmptyCaseObjectBranch`, `containsOpaqueImportcFieldAux`,
##   `genRecordFieldsAux`, `fillResult` and the type-section walkers read
##   `PType.n`, which stays a `PNode` by design (see the `BType` note below).
##   They are not migration candidates at all.
## * RETURNS A NODE OR NIL — `ccgutils.getPragmaStmt`. `.bif` spells a missing
##   child as a `DotToken` INSIDE a tree; there is no nil token to hand back as a
##   return value and a `Cursor` is not nilable. The fix is to split the
##   predicate out, as `stmtsContainPragma` does. The same reason keeps the
##   assignment DESTINATION a `PNode` throughout the call family (`genCall`
##   passes nil), along with `check`, `exvar`, `stepNode` and a try's `fin`.
## * WRITES TO THE NODE — `cgen.easyResultAsgn` sets `nfPreventCg`. Unlike the
##   generator's rewrites it cannot use `origin`, because it runs BEFORE the
##   handoff and the buffer is a snapshot taken after it.
## * THE ALIAS FAMILY stays on `PNode`, and NOT for the reason first recorded
##   here. Field identity is exact on a bridged buffer (see `sym` below), so that
##   is no longer what blocks it — but every call site passes `d.lode` as one
##   operand, and that is a `PNode`, so a generic `isPartOf` would still be
##   handed a `PNode` on one side and buy nothing. It moves when `TLoc.lode`
##   does, not before.
## * MIXED REPRESENTATION — `potentialAlias` and `getPotentialReads` build and
##   consume a `seq[PNode]` alongside the node, so both sides would have to be
##   the same spelling. `genParams` materialises its arguments as origins for
##   exactly this reason.
##
## There is deliberately no `BType` alongside `BNode`. Types stay `PType`s even
## under `newIcBackend` — `typ` below returns one — because the backend asks
## them semantic questions (`skipTypes`, `getSize`, `lengthOrd`, the record
## walk over `t.n`) that a raw cursor cannot answer. `ast2nif` already
## materializes them lazily from the module's type index, which is the seam
## that matters on that side.

import ast, lineinfos, idents

# Re-exported so `cgen`, which includes the `ccg*` files, gets the
# instrumentation along with the seam.
import icprof
export icprof

when defined(newIcBackend):
  when defined(nimPreviewSlimSystem):
    import std / assertions   # only this branch asserts
  import "../dist/nimony/src/lib/nifcore" except pool
  import ic / enum2nif
  import ast2nif, icnifcore, bodynav
  export ast2nif.BodyScope
  export bodynav
  # Imported only under the define: `cgen` is compiled during the koch
  # bootstrap, where the nimony libs are unavailable (`ast2nif` is guarded the
  # same way). `nifcore` — NOT `nifcursors` — is the reader half of NIF: `bif`
  # loads a `.bif` into a `nifcore.TokenBuf`, and `ast2nif` decodes it with a
  # `nifcore.Cursor`. `nifcursors` is the writer/builder cursor over
  # `PackedToken`s and is a different type entirely.

  type BNode* = distinct Cursor
    ## A cursor at an AST NODE, as distinct from a raw structural cursor: see
    ## "THE NODE ENCODING" above. The conversion is deliberately not implicit.

  template raw*(n: BNode): Cursor = Cursor(n)
    ## Escape hatch to the underlying structural cursor. Only this module and
    ## the decoder should need it.

  proc toBNode*(c: Cursor): BNode {.inline.} = BNode(c)
    ## A raw cursor known to sit on an AST node — e.g. the body cursor
    ## `ast2nif.lazyBodyCursor` hands back.

  # `nifcore` also has a `kind(c: Cursor): NifKind` — the TOKEN kind (TagLit,
  # SymUse, IntLit, ...). It and `kind(n: BNode): TNodeKind` below differ only
  # in return type, which Nim cannot overload on, so inside this module the
  # nifcore one is always spelled `nifcore.kind`. Modules that import `bnode`
  # do not import `nifcore`, so they see only the `TNodeKind` one.

  const
    LeafKinds* = {nkNone..nkNilLit}
      ## Exactly `astdef.safeLen`'s set: these have no children, and any token
      ## sitting after their flags/type prefix is a PAYLOAD (an int, a string,
      ## an ident), not a child.

  type
    SpecialTag = enum
      ## The wrapper tags that are not AST kinds. `typ` and `hasExplicitNilType`
      ## have to tell them apart, and did it by comparing the tag NAME on every
      ## call — 197k string compares on a 68-module build. They are resolved
      ## once per tag id instead, in the same miss path that resolves the kind.
      stOther, stHiddenType, stSymDef, stSymNodeFlags, stBridgeSym

    TagInfo = object
      kind: int16      ## `TNodeKind` ordinal, -1 while unresolved
      special: SpecialTag

  var tagCachePool: TagPool = nil
  var tagCache: seq[TagInfo] = @[]
    ## `TagId -> (TNodeKind, SpecialTag)` for ONE tag pool. Not a process-global
    ## table: a `.bif` carries its OWN tag pool, so ids only mean anything
    ## relative to the pool the cursor came from. Codegen works through one
    ## module at a time, so a single-entry memo is enough; a pool switch drops
    ## it. `tagCachePool` holds a REFERENCE rather than a raw pointer: that is
    ## what keeps the pool alive, so a freed pool cannot be replaced by a new
    ## one at the same address and silently answer from the wrong tag table.

  proc tagInfoAt(c: Cursor): TagInfo =
    ## Memoized decode of the tag at `c`. The miss path is the only place that
    ## touches a tag NAME: `parse` is a compare against ~180 strings, and the
    ## wrapper tags need four more, so both answers are cached together.
    prof pTagKindHit
    let pool {.cursor.} = c.tags
    if pool != tagCachePool:
      tagCachePool = pool
      tagCache = @[]
    let id = int(uint32(cursorTagId(c)))
    if id >= tagCache.len:
      let oldLen = tagCache.len
      tagCache.setLen(id + 1)
      for i in oldLen ..< tagCache.len: tagCache[i] = TagInfo(kind: -1'i16)
    if tagCache[id].kind < 0:
      prof pTagKindMiss
      let name = pool.tagName(cursorTagId(c))
      let sp = if name == hiddenTypeTagName: stHiddenType
               elif name == symDefTagName: stSymDef
               elif name == symNodeFlagsTagName: stSymNodeFlags
               elif name == bridgeSymTagName: stBridgeSym
               else: stOther
      let k = if sp != stOther: nkSym else: parse(TNodeKind, name)
      tagCache[id] = TagInfo(kind: int16(ord(k)), special: sp)
    result = tagCache[id]

  proc tagKind(c: Cursor): TNodeKind {.inline.} =
    ## The `TNodeKind` a `.bif` TAG encodes — the inverse of `toNifTag`, which
    ## is what wrote it (`ast2nif`: `pool.tags.getOrIncl(toNifTag(n.kind))`).
    ## The wrapper tags that encode an `nkSym` are folded in; `parse` answers
    ## `nkNone` for them (and for every non-AST tag, such as the module-level
    ## `(unusedid ...)`).
    TNodeKind(tagInfoAt(c).kind)

  proc kind*(n: BNode): TNodeKind =
    ## The node kind. A bare `Symbol`/`SymbolDef` token IS an `nkSym` node — it
    ## is how the common symbol use is written — and a `DotToken` is the nil
    ## child, which has no kind at all and answers `nkNone`; test it with
    ## `isNilNode` rather than comparing kinds.
    prof pKind
    result =
      case nifcore.kind(n.raw)
      of TagLit: tagKind(n.raw)
      of Symbol, SymbolDef: nkSym
      else: nkNone

  proc isNilNode*(n: BNode): bool {.inline.} =
    ## The `n == nil` of the `PNode` world: `ast2nif` writes a nil child as a
    ## `DotToken`, and a cursor is never itself nil.
    nifcore.kind(n.raw) == DotToken

  proc hasPrefix(c: Cursor): bool {.inline.} =
    ## Whether this `TagLit` carries the `withNode` flags/type prefix. `(none)`
    ## and a type-less `(empty)` are written bare, and they are the only nodes
    ## with zero raw children, so the test is exact.
    cursorJump(c) > 0

  proc astChildren(n: BNode): Cursor =
    ## A cursor at AST child 0, or an exhausted cursor when there is none.
    ## Steps over the two-token flags/type prefix; see "THE NODE ENCODING".
    prof pAstChildren
    result = childCursor(n.raw)
    if result.hasMore: skip result   # flags
    if result.hasMore: skip result   # type

  template walkChildren(n: BNode; c, body: untyped) =
    ## Shared guard for every child accessor: only a `TagLit` node that is not a
    ## leaf kind has children at all.
    if nifcore.kind(n.raw) == TagLit and kind(n) notin LeafKinds:
      var c = astChildren(n)
      body

  proc hasSons*(n: BNode): bool =
    walkChildren(n, c):
      return c.hasMore
    result = false

  proc son*(n: BNode; i: int): BNode =
    ## Child `i`. O(i) — `skip` is a single pointer add, because a `TagLit`
    ## token carries the width of its whole subtree.
    prof pSon
    prof(pSkip, i)
    walkChildren(n, c):
      for _ in 0 ..< i:
        doAssert c.hasMore, "son: index out of range"
        skip c
      doAssert c.hasMore, "son: index out of range"
      return BNode(c)
    raiseAssert "son: node has no children"

  proc firstSon*(n: BNode): BNode {.inline.} = son(n, 0)
  proc secondSon*(n: BNode): BNode {.inline.} = son(n, 1)

  proc len*(n: BNode): int =
    ## Counts the children — O(len). Never put this in a loop condition; the
    ## iterators below and `hasSons` exist so it is not needed there. Follows
    ## `safeLen`: a leaf kind answers 0 even though its payload token is there.
    prof pLen
    result = 0
    walkChildren(n, c):
      while c.hasMore:
        inc result
        skip c

  proc safeLen*(n: BNode): int {.inline.} = len(n)
    ## Same as `len`: `len` already answers 0 for a leaf, so the `PNode`
    ## distinction (`len` faults on a literal, `safeLen` does not) has nothing
    ## to guard here.

  proc lastSon*(n: BNode): BNode =
    ## O(len) — the token stream has no back pointer. Fine once per node, a
    ## trap inside a loop; `sonsButLast` is the loop form.
    prof pLastSon
    walkChildren(n, c):
      while c.hasMore:
        result = BNode(c)
        skip c
      return result
    raiseAssert "lastSon: node has no children"

  iterator sons*(n: BNode): BNode =
    walkChildren(n, c):
      while c.hasMore:
        prof pIterYield
        yield BNode(c)
        skip c

  iterator sonsFrom*(n: BNode; start: int): BNode =
    walkChildren(n, c):
      for _ in 0 ..< start:
        if not c.hasMore: break
        skip c
      while c.hasMore:
        yield BNode(c)
        skip c

  iterator isons*(n: BNode; start = 0): tuple[i: int, n: BNode] =
    walkChildren(n, c):
      var i = 0
      while i < start and c.hasMore:
        skip c
        inc i
      while c.hasMore:
        yield (i, BNode(c))
        skip c
        inc i

  iterator sonsButLast*(n: BNode; count = 1): BNode =
    ## One pass with `count` nodes of lookahead — the token stream cannot be
    ## walked backwards, so the tail is held back instead of subtracted.
    walkChildren(n, c):
      var pending: seq[Cursor] = @[]
      while c.hasMore:
        pending.add c
        skip c
        if pending.len > count:
          yield BNode(pending[0])
          pending.delete(0)

  iterator isonsButLast*(n: BNode; count = 1): tuple[i: int, n: BNode] =
    walkChildren(n, c):
      var pending: seq[Cursor] = @[]
      var i = 0
      while c.hasMore:
        pending.add c
        skip c
        if pending.len > count:
          yield (i, BNode(pending[0]))
          inc i
          pending.delete(0)

  # ---- resolution: the three that need more than the cursor -----------------

  var navStack {.threadvar.}: seq[BodyNav]
    ## Stack, not a single slot: generating one routine can pull in another
    ## before the first is finished. See "RESOLUTION CONTEXT" above.

  proc pushBodyNav*(nav: sink BodyNav) =
    navStack.add nav

  proc popBodyNav*(): BodyNav {.discardable.} =
    doAssert navStack.len > 0, "popBodyNav without a matching push"
    result = navStack.pop()

  template withBodyScope*(scope: BodyScope; body: untyped) =
    ## Runs `body` with a fresh `BodyNav` over `scope` current, so `sym`/`typ`
    ## inside it resolve the body's names. Pops even if `body` raises, because a
    ## codegen error is reported and compilation continues.
    pushBodyNav(initBodyNav(scope))
    try:
      body
    finally:
      popBodyNav()

  template withBridge*(tables: BridgeTables; body: untyped) =
    ## Read a bridged buffer: the nav resolves `(bsym …)` / `(btyp …)` straight
    ## out of `tables`. `base` stays empty on purpose — a bridged buffer names
    ## nothing, so there is nothing for the decoder to resolve, and leaving a
    ## fallback in place would turn a corrupt index into a confusing name
    ## lookup instead of the assertion it should be.
    pushBodyNav(initBridgeNav(tables))
    try:
      body
    finally:
      popBodyNav()

  proc currentNav*(): ptr BodyNav =
    ## The nav for the body being read. A `ptr` because the accessors below
    ## MUTATE it (the frame cache), and because copying a nav per access would
    ## defeat the point. Valid only until the next push — nothing between taking
    ## it and using it pushes, and nothing may: `symAt` bottoms out in the
    ## decoder, which never re-enters codegen.
    doAssert navStack.len > 0,
      "BNode.sym/typ outside withBodyScope: a Symbol token is a NAME and needs " &
      "the owning module plus the body's scope to resolve"
    result = addr navStack[^1]

  proc openScope*(kind = nsBlock) {.inline.} = openScope(currentNav()[], kind)
  proc closeScope*() {.inline.} = closeScope(currentNav()[])
  proc registerDefs*(n: BNode) {.inline.} = registerDefs(currentNav()[], n.raw)
  proc registerDefHere*(n: BNode) {.inline.} =
    discard registerDefHere(currentNav()[], n.raw)
  proc navStats*(): tuple[hits, fallbacks, registered: int] =
    let nav = currentNav()
    result = (nav.hits, nav.fallbacks, nav.registered)

  template withNodeScope*(kind: NavScopeKind; body: untyped) =
    ## The traversal-side half of the nav: a walk brackets each scope-bearing
    ## construct with this, and the definitions it passes are registered as it
    ## goes. See `bodynav`.
    openScope(kind)
    try:
      body
    finally:
      closeScope()

  proc sym*(n: BNode): PSym =
    ## The `PSym` an `nkSym` node names, resolved through the current nav: its
    ## scope chain first, the decoder second. The wrapper forms
    ## (`(nflags <flags> <symnode>)`, `(ht <type> <symnode>)`) are peeled by
    ## `bodynav.symToken`, beside the code that derives the lookup key from them,
    ## so the two cannot drift apart.
    ##
    ## NOT IDEMPOTENT FOR OBJECT FIELDS, and anything built on this accessor has
    ## to know it. Two calls on the SAME token yield two different `skField`
    ## `PSym`s with consecutive item ids: field uses deliberately bypass the
    ## nav's memo and go to `loadFieldStub`, which mints per use because two
    ## distinct fields can share a name AND a position across types, so one
    ## shared stub would mistype one of them (see `bodynav`). For every other
    ## symbol kind the answer is stable — the nav memoises it — and `cgen`'s
    ## grinder asserts that for the non-field case at every node.
    ##
    ## The consequence is not theoretical. A proc that reads a field sym twice
    ## and compares IDENTITY is correct on a `PNode` and wrong on a FILE-BACKED
    ## cursor: `aliases.isPartOf` does exactly that (`a[1].sym.id != b[1].sym.id`,
    ## to decide whether two accessor chains touch the same field).
    ##
    ## A BRIDGED buffer does not have this problem — `nodebridge` hands back the
    ## object it was given, and the grinder asserts idempotence for fields there
    ## while excluding them here. So field identity is no longer what keeps the
    ## alias family on `PNode`; see the note in the module header for what does.
    ## What codegen actually consumes for a field is the
    ## name it re-navigates the reclist with (`lookupFieldAgain`) plus, for
    ## tuples, the position — which is also the tolerance the grinder applies —
    ## so the fix for the FILE path is either to compare fields that way or to
    ## give a field token a stable identity. The latter needs the token's own
    ## position as a key,
    ## and `nifcore.Cursor` keeps that pointer private, so it is not something
    ## this module can do alone.
    prof pSym
    timed tSym:
      result = symAt(currentNav()[], n.raw)

  proc symTyp(n: BNode): PType =
    ## The type of the symbol a sym-shaped node names, or nil.
    let s = sym(n)
    result = if s == nil: nil else: s.typ

  proc typ*(n: BNode): PType =
    ## The node's type, INCLUDING the lazy fallback `ast.typ` performs.
    ##
    ## A sym node whose node type equals its symbol's is written as a bare
    ## `Symbol` with no type slot at all (`writeSymNode`), and the `PNode`
    ## loader marks such a node `nfLazyType` so `ast.typ` answers `n.sym.typ`.
    ## Answering `nil` here instead is not a *smaller* answer, it is a DIFFERENT
    ## one, and silently: `ast.canRaise` asks `fn.typ.kind == tyProc` about a
    ## call's callee, so a nil type turns "this call can raise" into "it cannot"
    ## and the goto-exception check after the call is dropped. The
    ## `.bif`-vs-`PNode` grinder found exactly that.
    prof pTyp
    icProfStart(tTyp)
    defer: icProfStop(tTyp)
    let c = n.raw
    case nifcore.kind(c)
    of Symbol, SymbolDef:
      result = symTyp(n)
    of DotToken:
      result = nil
    of TagLit:
      prof pTypTagLit
      case tagInfoAt(c).special
      of stHiddenType:
        # `(ht <type> <sym>)`: the node type is spelled out because it differed
        # from the symbol's at write time.
        result = typeAt(currentNav()[], childCursor(c))
        # A nil here is `(ht . <sym>)`, an EXPLICITLY nil node type, and it is
        # answered as nil — the writer only emits the wrapper when the node's
        # type differed from its symbol's, so nil means the node really had
        # none. Do NOT fall back to `sym.typ`: a type symbol used as a value
        # (`newException(KeyError, ...)`) is exactly this shape, and giving it
        # the symbol's type makes sem read the typedesc as an expression of the
        # type it denotes. That was tried, and it broke `--ic:on` compilation of
        # anything instantiating `tables.[]`.
        #
        # `ast.typ` may still answer `sym.typ` here, because the loader's
        # `nfLazyType` marking depends on whether the symbol happened to be
        # loaded already (see `ast2nif`). That is a pre-existing load-order
        # dependence in the AST, not a disagreement this side can resolve, and
        # the grinder excludes this shape for that reason.
      of stSymNodeFlags:
        var inner = childCursor(c)
        skip inner
        result = typ(BNode(inner))
      of stSymDef, stBridgeSym:
        # A bare `(bsym …)` is the bridge's spelling of a bare `Symbol`, so it
        # answers the same thing: the symbol's own type. The bridge encoder
        # always wraps a sym node in `(ht …)`, so this is the belt to that
        # braces rather than a path it relies on.
        result = symTyp(n)
      of stOther:
        if not hasPrefix(c):
          result = nil
        else:
          var t = childCursor(c)
          skip t                  # the flags slot
          result = typeAt(currentNav()[], t)
    else:
      result = nil

  proc hasExplicitNilType*(n: BNode): bool =
    ## Whether this is the `(ht . <sym>)` shape — a sym node the writer gave an
    ## EXPLICITLY nil type — after peeling any `(nflags ...)` wrapper, which is
    ## how it usually arrives. See `typ` for why nil is the faithful answer and
    ## why `ast.typ` may nonetheless say otherwise.
    prof pNilType
    var c = n.raw
    while nifcore.kind(c) == TagLit:
      case tagInfoAt(c).special
      of stSymNodeFlags:
        var inner = childCursor(c)
        skip inner              # the node flags
        c = inner
      of stHiddenType:
        return nifcore.kind(childCursor(c)) == DotToken
      else:
        return false
    result = false

  proc rawDesc*(n: BNode): string =
    ## What the token stream literally says here — the NIF token kind and, for a
    ## tag, its name. Diagnostics only: the vocabulary above is the interface,
    ## this is the thing it is an interface TO, and a disagreement between the
    ## two spellings is almost always explained by the raw shape.
    let c = n.raw
    result = $nifcore.kind(c)
    case nifcore.kind(c)
    of TagLit: result.add "/" & c.tags.tagName(cursorTagId(c))
    of Symbol, SymbolDef: result.add "/" & symName(c)
    else: discard

  # ---- leaf payloads --------------------------------------------------------
  #
  # A literal is `(<kind> <flags> <type> <atom>)`: the value is the single token
  # after the prefix. These are the accessors `ccgexprs` reaches for on nearly
  # every expression node, so nothing in the expression codegen can migrate
  # until they exist.

  proc origin*(n: BNode): PNode =
    ## The `PNode` this cursor was encoded from, when it is reading a bridged
    ## buffer. This is what lets a cursor-driven generator keep filling
    ## `TLoc.lode` with a `PNode`: the answer is the SAME OBJECT the encoder was
    ## handed, so the identity comparisons the backend already does still hold.
    ##
    ## A node head on a bridged buffer always has an origin, so a miss is a bug
    ## rather than a shrug — most likely a cursor that is not at a node head.
    ## Reading a FILE-backed body has no origins at all and answers nil, which is
    ## correct: there is no `PNode` those tokens came from.
    prof pOrigin
    icProfStart(tOrigin)
    let b = currentNav().bridge
    if b == nil: return nil
    result = originAt(b, n.raw)
    icProfStop(tOrigin)
    doAssert result != nil or nifcore.kind(n.raw) == DotToken,
      "bridged node has no origin: " & rawDesc(n)

  template origin*(n: PNode): PNode = n
    ## The `PNode` spelling, so `AnyNode` code can ask for an origin without
    ## caring which representation it holds.

  proc atom(n: BNode): Cursor {.inline.} =
    ## The payload token of a leaf node.
    result = astChildren(n)

  proc intVal*(n: BNode): BiggestInt =
    let c = atom(n)
    case nifcore.kind(c)
    of IntLit: result = BiggestInt(nifcore.intVal(c))
    of UIntLit: result = cast[BiggestInt](nifcore.uintVal(c))
    of CharLit: result = BiggestInt(ord(charLit(c)))
    else: raiseAssert "intVal on " & rawDesc(n)

  proc floatVal*(n: BNode): BiggestFloat =
    let c = atom(n)
    doAssert nifcore.kind(c) == FloatLit, "floatVal on " & rawDesc(n)
    result = BiggestFloat(nifcore.floatVal(c))

  proc strVal*(n: BNode): string =
    let c = atom(n)
    doAssert nifcore.kind(c) == StrLit, "strVal on " & rawDesc(n)
    result = nifcore.strVal(c)

  proc ident*(n: BNode): PIdent =
    let c = atom(n)
    doAssert nifcore.kind(c) == Ident, "ident on " & rawDesc(n)
    result = identFromCursor(program, c)

  proc flags*(n: BNode): TNodeFlags =
    ## The node's own flags, MINUS the two the `PNode` side owns rather than the
    ## file: `nfHasComment` is never written (comment text lives in a process-
    ## local side channel) and `nfLazyType` is a marker the loader adds to say
    ## "ask the symbol for my type" — which is what `typ` above does here
    ## unconditionally, so on a cursor the flag has nothing to mark.
    let c = n.raw
    case nifcore.kind(c)
    of TagLit:
      case tagInfoAt(c).special
      of stSymNodeFlags:
        # `(nflags <flags> <symuse>)`: the wrapper carries the flags the bare
        # `Symbol` token had nowhere to put.
        var inner = childCursor(c)
        result = nodeFlagsFromCursor(inner)
        skip inner
        result = result + flags(BNode(inner))
      of stHiddenType, stSymDef, stBridgeSym:
        result = {}
      of stOther:
        if not hasPrefix(c):
          result = {}
        else:
          result = nodeFlagsFromCursor(childCursor(c))
    else:
      result = {}

  proc lazyBodyBNode*(node: PNode; scope: var BodyScope; body: var BNode): bool =
    ## The cursor for a routine body that is still a deferred `nfLazyBody`
    ## placeholder, plus the scope its names resolve in. This is where a `BNode`
    ## comes FROM: until codegen is driven off `.bif` cursors end to end, it is
    ## the only supply, and it is what lets a migrated proc be run against the
    ## `PNode` proc it replaces on the same input. Non-destructive — the
    ## placeholder is still materializable afterwards.
    var c: Cursor = default(Cursor)
    result = lazyBodyCursor(program, node, scope, c)
    if result: body = BNode(c)

  proc info*(n: BNode): TLineInfo =
    ## No body scope needed: the packed line info resolves through the
    ## `.bif`'s own filename pool plus the `ConfigRef`.
    prof pInfo
    timed tInfo:
      result = lineInfoFromCursor(program, n.raw)

  proc isAtom*(n: BNode): bool {.inline.} =
    ## `ast.isAtom`, which is a pure `kind` test and so needs nothing from the
    ## body scope. It exists here only because `ast.isAtom` is typed `PNode`;
    ## the predicate itself is the same one.
    result = n.kind >= nkNone and n.kind <= nkNilLit

  # ---- predicates shared with the `PNode` spelling ---------------------------
  #
  # `ast.canRaise` / `ast.canRaiseConservative` only ever look at a node's
  # `kind`, `sym` and `typ`, all three of which this module now answers off a
  # `Cursor`. They cannot be written as `AnyNode` procs in `ast.nim` because
  # `BNode` is defined HERE and this module imports `ast`; so `ast.nim` keeps
  # the body in a template and these two instantiate it. There is no second
  # copy of the logic — change the template and both spellings change.

  proc getInt*(n: BNode): Int128 = getIntImpl(n)

  proc skipHiddenAddr*(n: BNode): BNode {.inline.} = skipHiddenAddrImpl(n)

  proc isInfixAs*(n: BNode): bool = isInfixAsImpl(n)

  proc getStr*(n: BNode): string = getStrImpl(n)

  proc skipPragmaExpr*(n: BNode): BNode {.inline.} =
    ## The `BNode` spelling of `ast.skipPragmaExpr`.
    (if n.kind == nkPragmaExpr: n.firstSon else: n)

  proc canRaiseConservative*(fn: BNode): bool = canRaiseConservativeImpl(fn)

  proc canRaise*(fn: BNode): bool = canRaiseImpl(fn)

  # ---- mixed-mode plumbing --------------------------------------------------
  #
  # `son` and `hasSons` are the two vocabulary members the AST does not already
  # have, so during the migration they must exist for BOTH node types: the cgen
  # files are full of call sites that read a `PSym.ast`, a `PType.n` or a
  # freshly built tree, and those stay `PNode`s no matter how far codegen has
  # moved. Without these the define does not compile at all and no proc can be
  # migrated incrementally.

  template son*(n: PNode; i: int): PNode = n[i]
  template hasSons*(n: PNode): bool = n.safeLen > 0
  template isNilNode*(n: PNode): bool = n == nil

  type AnyNode* = PNode | BNode
    ## The migration vehicle. A proc written against the vocabulary and typed
    ## `AnyNode` serves BOTH representations from one body, which means it can
    ## be migrated without a flag day and — more usefully — that the two
    ## instantiations can be run against each other on real input.

else:
  type BNode* = PNode
  type AnyNode* = PNode

  # Only the three the AST does not already have. Everything else in the
  # vocabulary is `ast`/`astdef`'s own `PNode` API — see the module doc.
  template origin*(n: BNode): BNode = n
    ## No bridge in this build: a node IS its own origin.

  template son*(n: BNode; i: int): BNode =
    ## Named indexed access. Exists so a call site states "child i" in a form
    ## that survives `BNode` becoming a `Cursor`; keep `i` small and constant.
    n[i]

  template hasSons*(n: BNode): bool =
    ## Emptiness test that does not compute a length — `len` counts on a
    ## `Cursor`.
    n.safeLen > 0

  template isNilNode*(n: BNode): bool =
    ## `n == nil`, in the form that survives the flip: a `Cursor` is never nil,
    ## and a nil child is a `DotToken` in the token stream.
    n == nil

when isMainModule and defined(newIcBackend):
  ## Self-test for the `Cursor` half. The backend still runs on `PNode`s, so
  ## these accessors have no call sites that a normal build type-checks, let
  ## alone executes. Run it against real `.bif` files:
  ##
  ##   nim c -d:newIcBackend compiler/bnode.nim
  ##   ./compiler/bnode <nimcache>/*.bif
  ##
  ## Pass SEVERAL files — each `.bif` carries its own tag pool, so one file
  ## alone cannot catch a `kind` cache that fails to notice the pool changed.
  ##
  ## What this checks that the previous version could not: the accessors agree
  ## with the ENCODING, not merely with each other. Checking `sons` against
  ## `len` and `firstSon` is satisfied just as well by a vocabulary that is
  ## uniformly off by two — which is what it was, and this is what caught it.
  ##
  ## `sym`/`typ` are NOT exercised here: they resolve through `ast.program` and
  ## a `BodyScope`, i.e. a live compiler, so their checks belong to the backend
  ## and not to a standalone binary. What IS checked is every shape assumption
  ## they rest on — that `(ht ...)`/`(nflags ...)` have exactly two raw children
  ## with the symbol second, and that `(sd ...)` opens with a `SymbolDef`.
  import std / [os, syncio, assertions]
  from "../dist/nimony/src/lib" / bif import load, BifModule

  var nodes = 0
  var checks = 0
  var astNodes = 0

  proc walk(c: Cursor; base: TokenBuf) =
    inc nodes
    let n = BNode(c)
    template pos(x: Cursor): int = cursorToPosition(base, x)

    # Every RAW child, which is what the traversal follows: the AST model below
    # deliberately does not see the module-level metadata tags, and a walk that
    # only followed `sons` would never reach most of the file.
    var rawKids: seq[Cursor] = @[]
    if nifcore.kind(c) == TagLit:
      var ch = childCursor(c)
      while ch.hasMore:
        rawKids.add ch
        skip ch

    doAssert isNilNode(n) == (nifcore.kind(c) == DotToken), "isNilNode"
    inc checks

    if nifcore.kind(c) in {Symbol, SymbolDef}:
      doAssert kind(n) == nkSym, "a Symbol token is an nkSym node"
      doAssert not hasSons(n), "a Symbol node has no children"
      doAssert len(n) == 0, "a Symbol node has length 0"
      inc checks, 3

    if nifcore.kind(c) == TagLit:
      let k = kind(n)
      let name = c.tags.tagName(cursorTagId(c))

      # The encoding invariants the whole vocabulary rests on.
      if name == symDefTagName:
        doAssert k == nkSym, "(sd ...) is an nkSym node"
        doAssert rawKids.len > 0 and nifcore.kind(rawKids[0]) == SymbolDef,
          "(sd ...) opens with a SymbolDef"
        inc checks, 2
      elif name == symNodeFlagsTagName or name == hiddenTypeTagName:
        doAssert k == nkSym, name & " wraps an nkSym"
        doAssert rawKids.len == 2, name & " is exactly (payload, symnode)"
        doAssert nifcore.kind(rawKids[1]) in {Symbol, SymbolDef, TagLit},
          name & "'s second child is the symbol"
        inc checks, 3
      elif k != nkNone:
        # A real AST node written through `withNode`: either bare (no prefix and
        # no children) or prefix + children. "Exactly one raw child" is
        # impossible, and that is what pins the prefix down.
        doAssert rawKids.len != 1,
          "AST node " & name & " has a flags/type prefix or nothing at all"
        inc checks
        if rawKids.len == 0:
          doAssert not hasSons(n), "bare " & name & " has no children"
          doAssert len(n) == 0, "bare " & name & " has length 0"
          inc checks, 2
        else:
          inc astNodes
          let want =
            if k in LeafKinds: newSeq[int]()
            else: (block:
              var s: seq[int] = @[]
              for i in 2 ..< rawKids.len: s.add pos(rawKids[i])
              s)

          var listed: seq[int] = @[]
          for ch in sons(n): listed.add pos(ch.raw)
          doAssert listed == want,
            "sons of " & name & " must start AFTER the flags/type prefix"
          doAssert listed.len == len(n), "sons/len disagree"
          doAssert (listed.len > 0) == hasSons(n), "hasSons/len disagree"
          inc checks, 3

          if listed.len > 0:
            doAssert pos(firstSon(n).raw) == listed[0], "firstSon"
            doAssert pos(lastSon(n).raw) == listed[^1], "lastSon"
            inc checks, 2
          if listed.len > 1:
            doAssert pos(secondSon(n).raw) == listed[1], "secondSon"
            inc checks
          for i in 0 ..< listed.len:
            doAssert pos(son(n, i).raw) == listed[i], "son " & $i
          inc checks, listed.len

          for start in 0 .. min(3, listed.len):
            var got: seq[int] = @[]
            for ch in sonsFrom(n, start): got.add pos(ch.raw)
            doAssert got == listed[start .. ^1], "sonsFrom " & $start
            var gotI: seq[int] = @[]
            for i, ch in isons(n, start):
              doAssert i == start + gotI.len, "isons index"
              gotI.add pos(ch.raw)
            doAssert gotI == listed[start .. ^1], "isons " & $start
            inc checks, 2

          for count in 1 .. 2:
            let wantB = if listed.len > count: listed[0 ..< listed.len - count]
                        else: newSeq[int]()
            var got: seq[int] = @[]
            for ch in sonsButLast(n, count): got.add pos(ch.raw)
            doAssert got == wantB, "sonsButLast " & $count
            var gotI: seq[int] = @[]
            for i, ch in isonsButLast(n, count):
              doAssert i == gotI.len, "isonsButLast index"
              gotI.add pos(ch.raw)
            doAssert gotI == wantB, "isonsButLast " & $count
            inc checks, 2

      # `kind` against an uncached lookup — this is what catches a stale cache
      # when the tag pool changes from one file to the next.
      let direct =
        if name == hiddenTypeTagName or name == symDefTagName or
           name == symNodeFlagsTagName: nkSym
        else: parse(TNodeKind, name)
      doAssert k == direct, "kind"
      inc checks

    for ch in rawKids: walk(ch, base)

  let files = commandLineParams()
  if files.len == 0:
    quit "usage: bnode <file.bif> [more.bif ...]"
  for f in files:
    var m = bif.load(f)
    var c = beginRead(m.buf)
    walk(c, m.buf)
    endRead c
  echo "bnode: files=", files.len, " nodes=", nodes, " astNodes=", astNodes,
       " checks=", checks, " OK"
