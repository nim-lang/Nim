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
## Building those trees is the bulk of the `lower` and `cg` stages: their cost
## tracks the size of the dependency CLOSURE a stage loads, not the module it
## compiles (measured: a 370-byte module costs 0.20s/0.16s in lower/cg, the main
## module 3.40s/3.16s, and the two are ~85% of the serial backend critical path).
##
## With `-d:newIcBackend` `BNode` is a `Cursor`; without it a plain `PNode`,
## which is what every build does today. Codegen migrates to the vocabulary
## below one area at a time and the compiler keeps building throughout, because
## on the `PNode` side the vocabulary is what `ast`/`astdef` already provide —
## `kind`, `len`, `safeLen`, `sym`, `typ`, `info`, `firstSon`, `secondSon`,
## `lastSon` and the `sons`/`isons`/`sonsFrom`/`sonsButLast`/`isonsButLast`
## iterators all exist. This module deliberately does NOT redefine them for
## `PNode`: an identical second overload would make every call site ambiguous.
## It adds only what the AST lacks (`son`, `hasSons`), and supplies the whole
## vocabulary on the `Cursor` side.
##
## THE COST MODEL DIFFERS, and that is what the vocabulary is shaped around. A
## `Cursor` is a position in a token stream, and a child is reached by stepping
## over each preceding sibling. Stepping is cheap — a `TagLit` token stores the
## width of its whole subtree, so `nifcore.skip` is a single pointer add
## regardless of how big that subtree is — but there is no random access and no
## way to walk backwards:
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
## `when isMainModule` at the bottom of this file checks that — run it over
## several `.bif` files at once, since one file alone cannot catch a memo that
## fails to notice the switch.
##
## The cgen files hold to one invariant, which is what makes the eventual flip
## mechanical: NO `[]` ON A `PNode` OUTSIDE OF TREE CONSTRUCTION. Every read is
## `firstSon`/`secondSon`/`lastSon`/`son(n, k)` or one of the iterators; the
## remaining subscripts are writes that build a fresh `nkProcDef`
## (`theProc[namePos] = ...`), which a `Cursor` backend will not do at all, and
## accesses to a `PType`, a `string`, a `seq` or a `Table`, none of which are
## `BNode`s. The `firstSon`/`secondSon`/`lastSon`/`son` family is defined for
## `PNode` only, so a mistaken base does not compile.
##
## A `PType` has its own vocabulary and its own reason for preferring it: `t[0]`
## is the return type, the base class, the index type or the generic head
## depending on the kind, and `ast.sons(t: PType)` is a `proc` returning the raw
## seq — NOT the iterator of the same name — which for a `tyProc` does not hold
## the parameters at all. Reach for `returnType` / `baseClass` / `elementType` /
## `genericHead` and the `kids` / `ikids` / `paramTypes` / `signature`
## iterators, which name the child and go through `[]`.
##
## There is deliberately no `BType` alongside `BNode`. Types stay `PType`s even
## under `newIcBackend` — `typ` below returns one — because the backend asks
## them semantic questions (`skipTypes`, `getSize`, `lengthOrd`, the record
## walk over `t.n`) that a raw cursor cannot answer. `ast2nif` already
## materializes them lazily from the module's type index, which is the seam
## that matters on that side.

import ast, lineinfos

when defined(newIcBackend):
  import "../dist/nimony/src/lib/nifcore" except pool
  import ic / enum2nif
  # Imported only under the define: `cgen` is compiled during the koch
  # bootstrap, where the nimony libs are unavailable (`ast2nif` is guarded the
  # same way). `nifcore` — NOT `nifcursors` — is the reader half of NIF: `bif`
  # loads a `.bif` into a `nifcore.TokenBuf`, and `ast2nif` decodes it with a
  # `nifcore.Cursor`. `nifcursors` is the writer/builder cursor over
  # `PackedToken`s and is a different type entirely.

  type BNode* = Cursor

  # `nifcore` also has a `kind(c: Cursor): NifKind` — the TOKEN kind (TagLit,
  # SymUse, IntLit, ...). It and `kind(n: BNode): TNodeKind` below differ only
  # in return type, which Nim cannot overload on, so inside this module the
  # nifcore one is always spelled `nifcore.kind`. Modules that import `bnode`
  # do not import `nifcore`, so they see only the `TNodeKind` one.

  var kindCachePool: TagPool = nil
  var kindCache: seq[int16] = @[]
    ## `TagId -> TNodeKind` for ONE tag pool, -1 where not yet resolved.
    ## Not a process-global table: a `.bif` carries its OWN tag pool, so ids
    ## only mean anything relative to the pool the cursor came from. Codegen
    ## works through one module at a time, so a single-entry memo is enough;
    ## a pool switch just drops the cache.

  proc kind*(n: BNode): TNodeKind =
    ## The `TNodeKind` a `.bif` tag encodes — the inverse of `toNifTag`, which
    ## is what wrote it (`ast2nif`: `pool.tags.getOrIncl(toNifTag(n.kind))`).
    ## `parse` is a compare against ~180 strings, far too much per node, so the
    ## answer is memoized per tag id.
    if nifcore.kind(n) != TagLit: return nkEmpty
    let pool = n.tags
    if pool != kindCachePool:
      kindCachePool = pool
      kindCache = @[]
    let id = int(uint32(cursorTagId(n)))
    if id >= kindCache.len:
      let oldLen = kindCache.len
      kindCache.setLen(id + 1)
      for i in oldLen ..< kindCache.len: kindCache[i] = -1'i16
    if kindCache[id] < 0:
      kindCache[id] = int16(ord(parse(TNodeKind, pool.tagName(cursorTagId(n)))))
    result = TNodeKind(kindCache[id])

  proc hasSons*(n: BNode): bool {.inline.} =
    nifcore.kind(n) == TagLit and n.cursorJump > 0

  proc firstSon*(n: BNode): BNode {.inline.} = childCursor(n)

  proc son*(n: BNode; i: int): BNode =
    ## Child `i`. O(i) — `skip` is a single pointer add, because a `TagLit`
    ## token carries the width of its whole subtree.
    result = childCursor(n)
    for _ in 0 ..< i: skip result

  proc secondSon*(n: BNode): BNode {.inline.} = son(n, 1)

  proc len*(n: BNode): int =
    ## Counts the children — O(len). Never put this in a loop condition; the
    ## iterators below and `hasSons` exist so it is not needed there.
    result = 0
    if nifcore.kind(n) != TagLit: return 0
    var c = childCursor(n)
    while c.hasMore:
      inc result
      skip c

  proc safeLen*(n: BNode): int {.inline.} = len(n)
    ## Same as `len`: a non-`TagLit` token has no children and answers 0, so the
    ## `PNode` distinction (`len` faults on a literal, `safeLen` does not) has
    ## nothing to guard here.

  proc lastSon*(n: BNode): BNode =
    ## O(len) — the token stream has no back pointer. Fine once per node, a
    ## trap inside a loop; `sonsButLast` is the loop form.
    var c = childCursor(n)
    while true:
      result = c
      skip c
      if not c.hasMore: break

  iterator sons*(n: BNode): BNode =
    if nifcore.kind(n) == TagLit:
      var c = childCursor(n)
      while c.hasMore:
        yield c
        skip c

  iterator sonsFrom*(n: BNode; start: int): BNode =
    if nifcore.kind(n) == TagLit:
      var c = childCursor(n)
      for _ in 0 ..< start:
        if not c.hasMore: break
        skip c
      while c.hasMore:
        yield c
        skip c

  iterator isons*(n: BNode; start = 0): tuple[i: int, n: BNode] =
    if nifcore.kind(n) == TagLit:
      var c = childCursor(n)
      var i = 0
      while i < start and c.hasMore:
        skip c
        inc i
      while c.hasMore:
        yield (i, c)
        skip c
        inc i

  iterator sonsButLast*(n: BNode; count = 1): BNode =
    ## One pass with `count` nodes of lookahead — the token stream cannot be
    ## walked backwards, so the tail is held back instead of subtracted.
    if nifcore.kind(n) == TagLit:
      var c = childCursor(n)
      var pending: seq[BNode] = @[]
      while c.hasMore:
        pending.add c
        skip c
        if pending.len > count:
          yield pending[0]
          pending.delete(0)

  iterator isonsButLast*(n: BNode; count = 1): tuple[i: int, n: BNode] =
    if nifcore.kind(n) == TagLit:
      var c = childCursor(n)
      var pending: seq[BNode] = @[]
      var i = 0
      while c.hasMore:
        pending.add c
        skip c
        if pending.len > count:
          yield (i, pending[0])
          inc i
          pending.delete(0)

  # The three that need MORE THAN THE CURSOR, which is the real boundary this
  # migration now sits at: none of them can stay a unary accessor.
  #
  # `sym`  — a `Symbol` token holds only a NAME. `ast2nif.loadSymStub` turns one
  #          into a `PSym` from a `DecodeContext` plus the OWNING MODULE's name
  #          plus that routine body's `localSyms` table, because a name with no
  #          module suffix is body-local and is not in any index.
  # `typ`  — same shape: `ast2nif.createTypeStub(c, symName(n))`, so also a
  #          `DecodeContext`.
  # `info` — `rawLineInfo(n)` gives a `NifLineInfo` whose `FileId` belongs to the
  #          `.bif`'s own pool; `ast2nif.oldLineInfo` maps it to a `TLineInfo`
  #          through a `LineInfoWriter`, which needs the `ConfigRef`.
  #
  # So the next step is not "implement these three" but deciding where codegen
  # gets that context from — a parameter, or module-global state for the span of
  # one module's `cg` stage, the way `ast2nif` already keeps its writer state.
  # Until then the `{.error.}` stubs report the exact missing piece AT ITS CALL
  # SITE rather than collapsing into a cascade of unrelated type errors.
  proc sym*(n: BNode): PSym {.error:
    "BNode.sym: needs a resolution context, not just the cursor — a Symbol " &
    "token is a NAME, and ast2nif.loadSymStub resolves it from a DecodeContext " &
    "plus the owning module plus the body's localSyms.".} = discard
  proc typ*(n: BNode): PType {.error:
    "BNode.typ: needs a resolution context — ast2nif.createTypeStub takes a " &
    "DecodeContext.".} = discard
  proc info*(n: BNode): TLineInfo {.error:
    "BNode.info: needs a resolution context — rawLineInfo(n) is a NifLineInfo " &
    "in the .bif's own file pool; ast2nif.oldLineInfo maps it through a " &
    "LineInfoWriter, which holds the ConfigRef.".} = discard

else:
  type BNode* = PNode

  # Only the two the AST does not already have. Everything else in the
  # vocabulary is `ast`/`astdef`'s own `PNode` API — see the module doc.
  template son*(n: BNode; i: int): BNode =
    ## Named indexed access. Exists so a call site states "child i" in a form
    ## that survives `BNode` becoming a `Cursor`; keep `i` small and constant.
    n[i]

  template hasSons*(n: BNode): bool =
    ## Emptiness test that does not compute a length — `len` counts on a
    ## `Cursor`.
    n.safeLen > 0

when isMainModule and defined(newIcBackend):
  ## Self-test for the `Cursor` half, which nothing else can reach yet: the
  ## backend still runs on `PNode`s, so these accessors have no call sites that
  ## a normal build type-checks, let alone executes. Run it against real `.bif`
  ## files:
  ##
  ##   nim c -d:newIcBackend compiler/bnode.nim
  ##   ./compiler/bnode <nimcache>/*.s.bif
  ##
  ## Pass SEVERAL files — each `.bif` carries its own tag pool, so one file
  ## alone cannot catch a `kind` cache that fails to notice the pool changed.
  import std / [os, syncio, assertions]
  from "../dist/nimony/src/lib" / bif import load, BifModule

  var nodes = 0
  var checks = 0

  proc walk(n: BNode; base: TokenBuf) =
    inc nodes
    if nifcore.kind(n) != TagLit: return
    template pos(c: BNode): int = cursorToPosition(base, c)

    var listed: seq[int] = @[]
    for ch in sons(n): listed.add pos(ch)
    doAssert listed.len == len(n), "sons/len disagree"
    doAssert (listed.len > 0) == hasSons(n), "hasSons/len disagree"
    inc checks, 2

    if listed.len > 0:
      doAssert pos(firstSon(n)) == listed[0], "firstSon"
      doAssert pos(lastSon(n)) == listed[^1], "lastSon"
      inc checks, 2
    if listed.len > 1:
      doAssert pos(secondSon(n)) == listed[1], "secondSon"
      inc checks
    for i in 0 ..< listed.len:
      doAssert pos(son(n, i)) == listed[i], "son " & $i
    inc checks, listed.len

    for start in 0 .. min(3, listed.len):
      var got: seq[int] = @[]
      for ch in sonsFrom(n, start): got.add pos(ch)
      doAssert got == listed[start .. ^1], "sonsFrom " & $start
      var gotI: seq[int] = @[]
      for i, ch in isons(n, start):
        doAssert i == start + gotI.len, "isons index"
        gotI.add pos(ch)
      doAssert gotI == listed[start .. ^1], "isons " & $start
      inc checks, 2

    for count in 1 .. 2:
      let want = if listed.len > count: listed[0 ..< listed.len - count]
                 else: newSeq[int]()
      var got: seq[int] = @[]
      for ch in sonsButLast(n, count): got.add pos(ch)
      doAssert got == want, "sonsButLast " & $count
      var gotI: seq[int] = @[]
      for i, ch in isonsButLast(n, count):
        doAssert i == gotI.len, "isonsButLast index"
        gotI.add pos(ch)
      doAssert gotI == want, "isonsButLast " & $count
      inc checks, 2

    # `kind` against an uncached lookup — this is what catches a stale cache
    # when the tag pool changes from one file to the next.
    doAssert kind(n) == parse(TNodeKind, n.tags.tagName(cursorTagId(n))), "kind"
    inc checks

    for ch in sons(n): walk(ch, base)

  let files = commandLineParams()
  if files.len == 0:
    quit "usage: bnode <file.bif> [more.bif ...]"
  for f in files:
    var m = bif.load(f)
    var c = beginRead(m.buf)
    walk(c, m.buf)
    endRead c
  echo "bnode: files=", files.len, " nodes=", nodes, " checks=", checks, " OK"
