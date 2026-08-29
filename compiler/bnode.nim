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
## `Cursor` is a copyable position in a token buffer, so a child is reached by
## `firstSon` plus one `skip` per preceding sibling — and `skip` steps over a
## whole subtree. Reading child `i` is therefore O(size of children 0..<i):
##
## * `firstSon` / `secondSon` / `son(n, k)` with small constant `k` — cheap, and
##   how nearly all structural access in the cgen files now reads.
## * `for x in sons(n)` / `sonsFrom(n, k)` / `sonsButLast(n, k)`, and the
##   index-yielding `isons` / `isonsButLast` — one linear pass. ALWAYS use these
##   for a loop: `for i in 0..<n.len: n[i]` is O(n^2) once `BNode` is a `Cursor`.
##   A loop that stops at a computed position walks forward and breaks
##   (`for i, it in isons(n): if i >= casePos: break`) rather than counting up to
##   the bound.
## * `lastSon(n)` — O(len). Fine once, a trap inside a loop.
## * `len(n)` — O(len) on a `Cursor`, which has to count. Do not put it in a loop
##   condition; use `sons`/`sonsFrom`, or `hasSons` for an emptiness test.
##
## The cgen files hold to one invariant, which is what makes the eventual flip
## mechanical: NO `[]` ON A `PNode` OUTSIDE OF TREE CONSTRUCTION. Every read is
## `firstSon`/`secondSon`/`lastSon`/`son(n, k)` or one of the iterators; the
## remaining subscripts are writes that build a fresh `nkProcDef`
## (`theProc[namePos] = ...`), which a `Cursor` backend will not do at all, and
## accesses to a `PType`, a `string`, a `seq` or a `Table`, none of which are
## `BNode`s. `PType` is the trap to watch for: `ast.sons(t: PType)` is a `proc`
## returning `var TTypeSeq`, NOT the iterator of the same name, so `t[i]` there
## means something else entirely. The `firstSon`/`secondSon`/`lastSon`/`son`
## family is defined for `PNode` only, so a mistaken base does not compile.

import ast, lineinfos

when defined(newIcBackend):
  import "../dist/nimony/src/lib" / nifcursors
  # Imported only under the define: `cgen` is compiled during the koch
  # bootstrap, where the nimony libs are unavailable (`ast2nif` is guarded the
  # same way).

  type BNode* = Cursor

  # Migrated one accessor per step. Until then the `{.error.}` stubs make
  # flipping the define report the exact missing piece AT ITS CALL SITE, rather
  # than collapsing into a cascade of unrelated type errors.
  proc kind*(n: BNode): TNodeKind {.error:
    "BNode.kind: not implemented for Cursor yet — map the tag id to TNodeKind. " &
    "`ic/enum2nif.parse(TNodeKind, string)` is the reverse of `toNifTag`, but a " &
    "per-call string compare is too slow here: build a tag-id -> TNodeKind table once.".} = discard
  proc len*(n: BNode): int {.error: "BNode.len: not implemented for Cursor yet (counts children; prefer sons/hasSons)".} = discard
  proc safeLen*(n: BNode): int {.error: "BNode.safeLen: not implemented for Cursor yet".} = discard
  proc son*(n: BNode; i: int): BNode {.error: "BNode.son: not implemented for Cursor yet (firstSon + i skips)".} = discard
  proc firstSon*(n: BNode): BNode {.error: "BNode.firstSon: not implemented for Cursor yet".} = discard
  proc secondSon*(n: BNode): BNode {.error: "BNode.secondSon: not implemented for Cursor yet".} = discard
  proc lastSon*(n: BNode): BNode {.error: "BNode.lastSon: not implemented for Cursor yet (O(len))".} = discard
  proc hasSons*(n: BNode): bool {.error: "BNode.hasSons: not implemented for Cursor yet".} = discard
  proc sym*(n: BNode): PSym {.error: "BNode.sym: not implemented for Cursor yet".} = discard
  proc typ*(n: BNode): PType {.error: "BNode.typ: not implemented for Cursor yet".} = discard
  proc info*(n: BNode): TLineInfo {.error: "BNode.info: not implemented for Cursor yet".} = discard
  iterator sons*(n: BNode): BNode {.error: "BNode.sons: not implemented for Cursor yet".} = discard
  iterator sonsFrom*(n: BNode; start: int): BNode {.error: "BNode.sonsFrom: not implemented for Cursor yet".} = discard
  iterator sonsButLast*(n: BNode; count = 1): BNode {.error: "BNode.sonsButLast: not implemented for Cursor yet (one pass with `count` nodes of lookahead)".} = discard
  iterator isons*(n: BNode; start = 0): tuple[i: int, n: BNode] {.error: "BNode.isons: not implemented for Cursor yet".} = discard
  iterator isonsButLast*(n: BNode; count = 1): tuple[i: int, n: BNode] {.error: "BNode.isonsButLast: not implemented for Cursor yet".} = discard
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
