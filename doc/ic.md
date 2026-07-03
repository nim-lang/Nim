======================================
  Incremental Compilation (IC)
======================================

The ``nim ic`` command provides incremental compilation for Nim projects. It
decomposes compilation into per-module steps whose results are cached as NIF
files, and uses the external ``nifmake`` build tool to re-run only the steps
whose inputs changed.

This document describes **how `nim ic` works today**, including the edge cases
that shaped the current design. The per-module backend rewrite that earlier
editions of this document listed as a *Plan* has **landed**: the whole-program,
reuse/redirect/def-retention backend is gone and codegen is now a set of
`nifmake`-driven per-module rules (see *The backend*).

Overview
========

The pipeline has two halves driven by one process (`nim ic`, `commandIc` in
``compiler/deps.nim``) that constructs a dependency graph, writes a build file,
and hands it to ``nifmake``:

1. **Frontend** — per module:
   - ``nifler parse --deps`` turns ``.nim`` source into a parsed NIF
     (``.p.nif``) plus a static dependency list (``.deps.nif``).
   - ``nim m`` (the *semantic* step, `cmdM`) reads the parsed NIF + the
     precompiled NIFs of the module's imports, type-checks, and writes the
     **semmed NIF** (``.nif``) plus invalidation sidecars (see *Cookies*).
2. **Backend** — ``nim nifc`` (`cmdNifC`, ``compiler/nifbackend.nim``) reads the
   semmed NIFs, generates C, compiles and links.

``nifmake`` orders the steps by their input/output files: every `nim m` runs
before the `nim nifc` step that consumes its NIF, and a step re-fires only when
one of its inputs is newer than its outputs. The driver invokes ``nifmake run
--parallel`` by default, so independent steps at the same DAG depth fan out
across cores; pass ``-d:icNoParallel`` to serialize (readable child output when
debugging a build).

Artifacts (the NIF zoo)
=======================

Per module ``<suffix>`` (a content hash of the path; see *NIF symbols* below),
under the nimcache directory:

| File | Producer | Purpose |
| ---- | -------- | ------- |
| ``<s>.p.nif`` | nifler | parsed AST (syntactic) |
| ``<s>.deps.nif`` | nifler | **static** import list (syntactic `import`s) |
| ``<s>.s.deps.nif`` | `nim m` | **real** post-sem imports (incl. macro-generated); see *Discovery* |
| ``<s>.nif`` | `nim m` | semmed module (symbols resolved, typed) |
| ``<s>.iface.nif`` | `nim m` | **iface cookie**: hash of the importer-visible surface |
| ``<s>.impl.nif`` | `nim m` | **impl cookie**: hash of the entire content (bodies included) |
| ``<s>.edges.nif`` | `nim m` | **NeedsImpl edges**: modules whose bodies this sem consumed |
| ``<s>.c.nif`` | `nim nifc` | the C text as a NIF, with def/ref markers for DCE & dedup |
| ``ic_config.cfg.nif`` | driver | precompiled config replayed by every child (`icconfig.nim`) |
| ``ic.version`` | driver | format stamp; a mismatch wipes the cache (`icFormatVersion`) |

NIF symbols and ownership
=========================

(See ``../nifspec/doc/nif-spec.md``.) A global symbol is
``<ident>.<disamb>.<moduleSuffix>``. For a **generic instantiation** the
`<disamb>` is not a counter but a *content hash* — `setInstanceDisamb`
(``modulegraphs.nim``) MD5s the generic's identity plus the `typeKey` of every
concrete type argument, masks it to 30 bits and tags it with `InstanceDisambBit`.
So the only part of the name that varies between two modules making the **same**
instantiation (`seq[Foo]`) is the `<moduleSuffix>`. Two consequences drive the
backend:

- **Instance names are content-addressed**: the same instantiation produced in
  different modules yields the *same* `<ident>.<disamb>`, so a deterministic dedup
  is possible by the *module-suffix-stripped* name. The cross-TU C name
  (`ccgtypes.sharedInstanceCName`) and the **merge** stage's live-set/owner
  decision (`nifbackend.computeMergeDecision`) both key on this stripped form.
- **The suffix names a mint-site owner.** The `<moduleSuffix>` is the module
  *that minted the instance* (the instantiation site), so the same instance has a
  different full name in each module that makes it. Because every `cg` process
  emits the instances it demands (*emit-everywhere*), the same definition can be
  produced by several translation units; the **merge** stage then deterministically
  picks the single artifact allowed to embed each body (smallest claimant), which
  is the cross-process replacement for the old in-process single-writer machinery.

The driver: graph construction (`commandIc`)
============================================

1. Stamp/​wipe the cache by ``icFormatVersion``.
2. Seed the graph with the root module and **`system.nim`**. `system`'s entire
   import closure is folded into one node (one `nim m` invocation) — see
   *single-writer* below.
3. ``traverseDeps`` runs ``nifler`` per module and reads ``.deps.nif`` to add
   import edges.
4. **SCC grouping**: strongly-connected import cycles are collapsed (Tarjan).
   A singleton compiles as ``nim m <mod>``; a cycle compiles as one
   ``nim m <rep> --icGroup:<member>…`` that builds every member *from source* in
   one process (resolving the recursion in memory) and writes each member's NIF.
   Only edges *leaving* the component become build-graph inputs.
5. **Discovery fixpoint**: write the build file, run ``nifmake``; if it fails,
   re-derive the graph from every module's ``.s.deps.nif`` (adding nodes/edges
   for imports the static scanner missed), and retry. See *Discovery*.
6. The backend step (`nim nifc`) depends on every module's semmed NIF, so
   ``nifmake`` runs it last.

Invalidation: the cookie system
================================

A dependent must re-sem only when a dependency's relevant surface changed. Two
hashes per module (``ast2nif.nim``):

- **iface cookie** (``.iface.nif``): hashes only the *importer-visible* surface —
  exported declarations' **signatures** (for *all* routine kinds: plain procs,
  templates, macros, generics, `inline` procs alike), full content for
  consts/types, plus import/export/replay/hook records. Routine **bodies are
  excluded.** It also chains in the iface cookies of its own dependencies, so a
  surface change anywhere in the import closure propagates. A `nim m` rule for a
  module depends on its dependencies' iface cookies, so a body-only edit moves no
  iface cookie and stops the re-sem cascade.
- **impl cookie** (``.impl.nif``): hashes the *entire* serialized content (private
  defs and bodies included), with the module's own iface mixed in.

**NeedsImpl edges** (``.edges.nif``): if a module *consumed another module's body*
during sem — a macro expansion, a generic instantiation, a `getImpl`, or a
compile-time call run in the VM — it records a strong edge. The dependent is then
gated on that dependency's **impl** cookie instead of its iface cookie, so e.g.
`const x = dep.foo()` re-sems when `foo`'s body changes. Recording sites:
`semExprs.semTemplateExpr` (templates), `seminst.generateInstance` (generics),
`vmgen.genProc` (VM/macros/CT procs), `vm.opcGetImpl` (`getImpl`). Inline
iterators and `inline` procs are *not* tracked — they are inlined at codegen,
where the backend's NIF-mtime invalidation re-codegens their users.

Discovery of macro-generated imports
====================================

The static scanner only sees syntactic `import`s. A macro can synthesize one
(chronicles does `parseStmt("import chronicles/textlines")` driven by the
`chronicles_sinks` define). Such an import is invisible until sem runs the macro.
Each `nim m` records the imports it *actually* resolved (via the
``semdata.addImportFileDep`` hook → ``graph.importDeps`` → ``ast2nif.writeSemDeps``)
into ``<s>.s.deps.nif``; a child that fails on a not-yet-built import flushes it
before erroring. The driver re-derives the graph from those sidecars — adding the
missing node + the importer→import edge — and reruns to a fixpoint. (This replaced
an earlier `icmissing.txt` side channel.)

The backend: per-module `nifc` stages
=====================================

Codegen is no longer one whole-program process. ``nim nifc`` (`cmdNifC`,
``compiler/nifbackend.nim``) is invoked once per **stage** via
``--icBackendStage:<stage>``; `commandIc` emits these as ordinary `nifmake` rules
so "which TUs rebuild" is just "which rules `nifmake` re-fires from input mtimes"
— exactly as the frontend already works. There are four stages:

1. **`cg`** (``--icBackendStage:cg --icBackendModule:<suffix>``) — generate C for
   the *single* named module and write only its ``<s>.c.nif`` artifact. A non-main
   target loads only its own import closure (`loadDepClosure`), so the whole
   program is **not** pulled into every parallel `cg` process. Codegen is still
   demand-driven and **emit-everywhere**: a `cg` process emits every entity it
   demands (generic instances, hooks, RTTI), referencing nothing `extern`-only.
   There is no whole-program DCE here — a liveness pass over all ~260 NIFs would
   cost ~900 MB for a result the merge stage recomputes anyway. The **main**
   module's `cg` is special: it loads everything (`loadBackendModules`), emits the
   whole-program method dispatchers and `NimMain`, and registers every other
   module's init/datInit from the `.c.nif` meta heads — so it runs *last*, after
   every other ``.c.nif`` exists. Every `cg` rule always leaves a ``.c.nif`` (empty
   if the module owns no code) so its nifmake output exists and the rule settles.
2. **`merge`** (``--icBackendStage:merge``) — a pure artifact pass, *no module
   graph loaded*. Reads every ``.c.nif``, computes the one program-wide live set
   and, for each unique definition that several `cg` processes emitted, the single
   artifact allowed to embed its body; writes that to a merge-decision file
   (`computeMergeDecision` / `writeMergeDecision`). This is the cross-process
   replacement for the old in-process first-claimant + DCE coordination.
3. **`emit`** (``--icBackendStage:emit --icBackendModule:<suffix>``) — render the
   target module's final ``.c`` from its ``.c.nif`` and the merge decision
   (`renderCFromArtifact`, dropping globally-dead and non-owned bodies). No codegen
   runs; the target is loaded only so `getCFile` yields the path `cg` wrote.
4. **`link`** (``--icBackendStage:link``) — register every module's emitted ``.c``
   and run `extccomp.callCCompiler` once (it parallelizes per-file cc and skips
   up-to-date objects). Per-module C compile/link directives (`{.passL.}` etc.) are
   re-collected here via `replayBackendActions`, since the `cg` processes that
   originally saw them are separate processes (without this, e.g. `math`'s `-lm`
   would be lost → undefined `floor`/`pow` at link).

Because each stage is a `nifmake` rule keyed on file mtimes, a body-only edit to
one module re-fires that module's `cg`+`emit` (and the `merge`/`link`), not the
whole program — and an unchanged module's `cg` does not run at all.

Edge cases (and why the machinery exists)
=========================================

- **Single-writer.** Instance type-ids are minted in process-local order, so if
  two `nim m` processes both write a module's NIF (e.g. a stdlib module pulled
  into `system`'s from-source closure *and* given its own rule), the second
  overwrites with different ids and every module checked against the first carries
  dangling refs ("symbol has no offset"). Fixed by folding `system`'s closure into
  one SCC and by **forwarding the project's defines** to every child so their
  `when` bodies (hence import sets and NIF contents) match the scanner's.
- **`when … else: import`.** nifler emits `else`-branch imports unguarded, so a
  dead `else: import` would be scheduled. The compiler's own sources were rewritten
  to explicit negated `when`s; the vendored nifler later learned to negate prior
  conditions for the `else`.
- **`nil` sons of loaded ASTs.** NIF dot-tokens load as `nil` where from-source
  ASTs have `nkEmpty`; several passes gained `nil` guards.
- **Sealed loaded types.** Loaded types are `Sealed`; sem/transform mutate via
  `unsealForTransform`/`exactReplica(idgen)` (the latter mints a fresh `uniqueId`
  so serialized replicas don't collapse).
- **Methods/RTTI ownership.** RTTI and type-bound hooks are emit-everywhere at
  `cg` and deduplicated by the `merge` stage, like generic instances; the main
  module's `cg` owns the whole-program method dispatchers.
- **Config cost.** Each child re-parsing `nim.cfg` + re-running `config.nims` in
  the VM was ~80 ms; replaced by a precompiled `ic_config.cfg.nif` replayed in
  `loadConfigs` (`compiler/icconfig.nim`).
- **`koch bootic`** bootstraps the compiler through `nim ic` (a 3-iteration
  fixed-point check). It writes its binary to ``bin/nim_ic`` and never clobbers
  ``bin/nim``.

Resolved by the rewrite
-----------------------

The whole-program backend's hand-rolled mini-`nifmake` — `computeModuleReuse`,
`enforceDefRetention`, `redirectToLiveModule`, the cached-defs/claim bookkeeping
and the standalone `dce.nim` — **is gone**. Reuse is now just per-rule `nifmake`
mtime checks, and the single-writer decision is the `merge` stage. The old
**cross-mm / `--force` `var not init`** hazard dissolved with it: every codegen
rule's config (including `--mm`) is a declared `nifmake` input, so a stale-config
TU is simply rebuilt rather than mixed in. `koch bootic` is green under both `orc`
and `--mm:refc`.

Known residual hack
-------------------

- `deps.runNifler` still uses `setLastModificationTime` to mark its scan
  up-to-date and deletes a stale parsed file to coordinate with the nifmake nifler
  rule — the driver duplicating nifmake's freshness logic. It is explicitly
  flagged in the source and folds away with a full frontend/nifler split.

Status and performance
======================

`nim ic` self-builds the compiler (`koch bootic`'s byte-identical fixed-point
check) under both `orc` and `--mm:refc`, and passes the external-package CI set.

Cold full bootstrap on a 32-core box (`-d:release`, **no edits** — IC's worst
case, since incremental reuse is not exercised):

| | wall | notes |
| - | ---- | ----- |
| `koch boot` (classic) | ~1m00s | reference |
| `koch bootic` (`nim ic`) | ~1m39s | **~1.66×** |

This is down from ~7.5× in the whole-program-backend era. IC does modestly more
aggregate work (more processes, NIF re-parsing of imports per process), but on a
many-core box that overhead is absorbed by the parallel `nim m`/`nifc` fan-out,
and the C compile+link floor is shared with the classic backend. On few-core
machines the cold gap is correspondingly wider — IC trades single-build latency
for incremental latency.

The cold number is the *least* favourable comparison: it pays IC's full per-process
overhead while using none of its incremental machinery. **Warm rebuilds — the
actual point of IC — recompile only the modules whose inputs changed** (a body-only
edit re-fires one module's `cg`+`emit`, not the program), so an edit-driven rebuild
is a small fraction of either full build.

The strategic direction (decided 2026-06-13) is to make this NIF backend
(`cmdNifC`) the **default** code generator. The per-module pipeline above is the
realization of that direction; remaining work is *promotion + deletion* of the
classic path, not new machinery.

Design notes and open decisions
===============================

The per-module backend (above) mirrors Nimony's ``src/nimony/deps.nim``: the
backend stopped re-implementing `nifmake`; each stage is a build rule, so reuse is
just mtime checks and the merge stage is the only cross-module coordination.

Settled vs. open:

- **Ownership.** Emittable entities (generic instances, type-bound hooks, RTTI,
  lifted procs) are emit-everywhere at `cg` time and deduplicated at `merge` time
  (smallest claimant owns each unique body). The earlier idea of a *static*
  per-suffix owner computed before codegen was not needed — content-addressed names
  make the merge decision deterministic. The precise owner *rule* (minting module
  vs. root-type's module) can still be tuned where it would force a downstream
  package to own stdlib code.
- **Remaining cleanup.** The `runNifler` `setLastModificationTime` coordination
  (above) folds away with a full frontend/nifler split; dead `when` imports could
  also be pruned during the `.s.deps` re-derivation.

Validation bar (held on every change): `koch bootic` must reach its byte-identical
fixed point, and binary size must not regress (DCE parity), across the
external-package CI set.

Further possible improvements
=============================

A warm-edit profiling pass (2026-07-02, self-compiling the compiler into a
dedicated `--nimcache`, editing one private proc body — `internalErrorImpl` — in
the hub module `compiler/msgs.nim`) surfaced where a **hub-module** warm rebuild
actually spends its time. The result refines the "a body-only edit re-fires one
module" claim above: that holds for the *backend*, but the *frontend* can still
cascade.

Measured: no-op `0.05s`; hub body edit `~15s`, split **~13s frontend / ~1.6s
backend**. Editing a body in a leaf (few importers) is fast; editing a body in a
widely-imported module is not, and the cost is almost entirely frontend re-sem.

- **Frontend over-invalidation (the dominant hub-edit cost).** Editing *any* body
  in a module — even a private routine that is only ever *called* — flips that
  module's whole-module **impl cookie** (`writeImplCookie` hashes the entire
  serialized module). Every module carrying a **NeedsImpl** edge on it then
  re-sems, even though the symbol it actually consumed is unchanged (e.g. a
  dependent that expanded the `internalError` *template* needs the template body,
  which is untouched; it does **not** need `internalErrorImpl`'s body). In the
  msgs edit this re-fires **57** `nim m` processes. A `.s.bif` mtime diff *hides*
  this — `.s.bif` is content-stable, so a re-semmed-but-identical module keeps its
  timestamp; count actual `nim m` PIDs to see the fan-out.

  The precise fix is **per-symbol NeedsImpl gating**: record which *symbols'*
  bodies a dependent consumed (the recording site `modulegraphs.recordIcImplDep`
  already receives the `PSym`; it currently coarsens to `module(s.itemId)`) and
  gate the dependent
  on only those. The obstacle is that `nifmake` gates on file mtimes, so
  per-symbol granularity needs either many cookie files or a bucketing scheme, and
  "which bodies are compile-time-consumable" is entangled with `getImpl` and the
  CT call graph (a macro that runs a private helper at CT *does* consume its body).
  A conservative narrowing — keep template/generic/macro/`sfCompileTime` bodies
  (plus `getImpl` targets) in the impl cookie but drop ordinary runtime routine
  bodies — captures the common "edit a private implementation proc" case, at the
  cost of proving the exclusion is complete.

- **Serial re-sem chains.** The 57 re-sems above run essentially **one at a time**
  despite `--parallel`, because the core modules they belong to form a deep import
  *chain* and `nifmake`'s depth-barriered scheduler runs one depth level at a time
  (≈1 node per level). This is independent of the invalidation problem: even
  perfect per-symbol precision leaves a serial tail whenever the re-sem set is a
  chain. Mitigations live in the scheduler (content-stability already stops the
  cascade at one level, but does not flatten the chain).

- **Emit stage need not load the module graph (done).** `generateEmitStage` used
  to `loadDepClosure`/`loadBackendModules` — materializing a module's whole
  transitive import closure as `BModule`s — solely to reach `getCFile(bmod)` for
  the output path. `renderCFromArtifact` is pure text filtering over the `.c.nif`
  plus the merge decision; it needs none of that. Deriving the `.c` path directly
  from the suffix (the same pure computation `deps.backendCFile` uses to *declare*
  the stage's output) lets an `emit` process load nothing. Under the
  fire-all-every-edit `emit` barrier (see below) this halved backend CPU
  (user-time `51s → 24s` on the msgs edit); wall-clock barely moved because the
  frontend dominates, but the reduced CPU/RAM contention matters when an editor is
  running alongside. `koch ic` stays byte-identical.

- **Do NOT make the merge decision content-stable.** A tempting frontend to the
  above: `emit` re-fires for *every* live module whenever `merge` rewrites the
  decision file's mtime (deliberate — a decision change must re-render every `.c`
  consistently). Writing the decision `OnlyIfChanged` (with a stamp output so the
  `merge` rule is not perpetually stale) makes a warm no-op instant, but a real
  edit then fires `emit` only for the modules whose `.c.nif` changed — and that
  produces **multiple-definition link errors** even when the decision is
  byte-identical. Fire-all `emit` is a correctness invariant, not just insurance
  (see the comment at `generateEmitStage`): partial `emit` leaves inconsistent
  ownership across the `.c` set. This path was tried and reverted; do not retry.

Code, logic & debugging
========================

Core modules:
- **`compiler/deps.nim`** — graph construction, SCC grouping, discovery fixpoint,
  build-file generation; `commandIc`.
- **`compiler/ast2nif.nim`** — AST↔NIF, the cookie hashes (`cookieSd`,
  `writeIfaceCookie`, `writeImplCookie`, `writeEdgesFile`, `writeSemDeps`).
- **`compiler/nifbackend.nim`** — the per-module backend stages (`generateCgStage`,
  `generateMergeStage`, `generateEmitStage`, `generateLinkStage`).
- **`compiler/cnif.nim`** — `.c.nif` artifact read/write, `computeMergeDecision`,
  `renderCFromArtifact`.
- **`compiler/icconfig.nim`** — precompiled config.
- **`compiler/pipelines.nim`** / **`modulegraphs.nim`** — pipeline integration and
  the graph state (`importDeps`, `icImplDeps`, `icCnifFiles`, `instDisambs`, …).

Manual workflow:
- Frontend a module: ``nim m --nimcache:nifcache path/to/mod.nim`` (writes
  ``.nif`` + cookies + ``.s.deps``).
- Backend is stage-based (a bare ``nim nifc main.nim`` errors — there is no
  whole-program fallback). The exact per-stage commands `nifmake` runs are in the
  ``*.backend.build.nif`` build file; rerun one directly against an existing cache,
  e.g. ``nim nifc --nimcache:nifcache --icBackendStage:cg --icBackendModule:<suffix> main.nim``
  to regenerate one module's ``.c.nif``, then ``--icBackendStage:merge`` /
  ``:emit`` / ``:link``.
- NIF and ``.c.nif`` files are text — open/grep them directly; ``diff`` two
  successive ``.nif`` to see why a module rebuilt.
- Force a re-sem: delete the module's ``.nif`` and rerun `nim m`.
- A stale-cache crash after editing the serialization layout means bumping
  ``icFormatVersion`` (`compiler/options.nim`).

See also
========

- NIF format spec: [nifspec/doc/nif-spec.md](../nifspec/doc/nif-spec.md)
- NIFC (C-like target) spec: dist/nimony/doc/nifc-spec.md
