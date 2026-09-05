# `NIM_IC_BNODE_GRIND` target

Input for the differential oracle in `compiler/cgen.nim` (`grindBNode`), which
runs every codegen proc that has moved to `AnyNode` over BOTH the `.bif` cursor
and the materialised `PNode` for the same body and requires the same answer.

    nim c -d:newIcBackend -o:bin/nim_grind compiler/nim.nim
    NIM_IC_BNODE_GRIND=1 bin/nim_grind c --ic:on --nimcache:/tmp/ncgrind \
      tools/icgrind/grindme.nim

A disagreement is an `internalError` naming the proc, the path within the body
and both answers. Each backend process reports its coverage on exit:

    BNODEGRIND navHits=… navFallbacks=… navRegistered=… graded=… skipDecl=… skipTyp=…

`graded` is what the number "0 disagreements" is worth. The two skip counts are
printed beside it on purpose, so a run that grades nothing cannot be mistaken
for a run that grades everything.

## What this target is for

The oracle grades whatever the dependency closure contains, so most of its
coverage comes from the standard library for free. This target exists for the
shapes the stdlib closure does NOT produce often enough to exercise both
answers of a predicate — a `case` branch wider than `RangeExpandLimit`, a set
literal narrow enough for `fewCmps` to prefer comparisons, an `openArray`
parameter (the one shape `reifiedOpenArray` answers `false` for).

## Two things that silently produce no coverage

Both were found by counting, after adding shapes here that turned out never to
be graded at all:

1. **The main module's routines are never graded.** They are built in-process
   and never arrive as a deferred body. Anything worth grading has to live in
   `grindlib.nim`, not in `grindme.nim`.

2. **Only `nkStmtList` bodies are deferred**, so only those can be graded — see
   the placeholder site in `ast2nif.loadRoutine`. A one-line
   `proc f(x: int): int = case x ...` has an `nkAsgn` body, is loaded eagerly,
   and is invisible to the oracle. Every routine here opens with a statement for
   that reason. Measured on this target: 782 of 1434 bodies reach the grinder.

## Known coverage gap

`isConstClosure` is graded but only ever on its `false` side: a const closure
(`nkClosure(<routine sym>, nil)`) does not appear in any graded body of this
closure — the whole run contains exactly one `nkClosure` node, the real closure
in `adder`. Adding a shape here that produces one would be worth doing.
