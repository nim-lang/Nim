======================================
  Incremental Compilation (IC)
======================================

The ``nim ic`` command provides incremental compilation for Nim projects. It
decomposes compilation into per-module steps whose results are cached as NIF
files, and uses the external ``nifmake`` build tool to re-run only the steps
whose inputs changed.

This document describes **how `nim ic` works today**, including the edge cases
that shaped the current design, and ends with a **Plan** for the next backend
rewrite.

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
one of its inputs is newer than its outputs.

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
``<ident>.<disamb>.<moduleSuffix>`` or, for a generic instantiation,
``<ident>.<disamb>.<key>.<moduleSuffix>`` where ``key`` is the instantiation
encoded by the *NIF-trees-as-identifiers* scheme. Two consequences drive the
backend:

- **Instance names are content-addressed**: the same instantiation (`seq[Foo]`)
  produced in different modules yields the *same* `key`, so a deterministic
  dedup is possible *by name*.
- **The suffix names an owner module.** Today an instance's owner is the module
  whose process minted it (`itemId.module`), which is process-local mint order —
  the root of the *single-writer* hazard below.

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

The backend today: `commandNifC`
================================

The current backend is **whole-program and demand-driven**, run as one process
(``compiler/nifbackend.nim``):

1. Load `system` then **all** modules' semmed NIFs in dependency order
   (`loadModuleDependencies`), so all hooks/types are in memory.
2. **DCE**: `computeLiveSymbols` over all NIFs computes a global live set used to
   filter the top-level routine listing.
3. **`computeModuleReuse`**: decide which modules' cached translation units
   (``.c.nif``) can be reused — skip codegen for them and use their ``.c``/``.o``
   as is. The gate mirrors the m-step's cookie gating; a coarse fallback uses the
   transitive NIF-mtime closure (`-d:icCoarseReuse`).
4. **Codegen**: for each non-reused module, `generateCodeForModule` runs `cgen`.
   Codegen is **demand-driven**: emitting one module can *demand* entities
   (generic instances, type-bound hooks, RTTI) that belong to other modules; a
   demand whose home TU is reused is **redirected** into the demanding TU
   (`redirectToLiveModule`), and reused TUs' definitions become prototypes.
5. **`enforceDefRetention`**: an un-reuse cascade. If a regenerated module would
   stop emitting a definition that a still-reused TU references (the demand chain
   that placed it no longer arises), the referencing TUs lose their reuse and
   regenerate so the symbol does not vanish under them.
6. `emitMethodDispatchers`, then `finishModule` for every module (main module
   **last**, so init-proc registration is complete before `genMainProc`).
7. Emit ``.c``, then `extccomp.callCCompiler` + link.

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
- **Methods/RTTI ownership.** `genTypeInfoV1` already routes a type's RTTI to
  `t…itemId.module` when that module is open for codegen — an existing ownership
  notion the rewrite can generalize.
- **Config cost.** Each child re-parsing `nim.cfg` + re-running `config.nims` in
  the VM was ~80 ms; replaced by a precompiled `ic_config.cfg.nif` replayed in
  `loadConfigs` (`compiler/icconfig.nim`).
- **`koch bootic`** bootstraps the compiler through `nim ic` (a 3-iteration
  fixed-point check). It writes its binary to ``bin/nim_ic`` and never clobbers
  ``bin/nim``.

Known residual hacks (targets for the rewrite)
----------------------------------------------

- `deps.runNifler` uses `setLastModificationTime` to mark its scan up-to-date and
  deletes a stale parsed file to coordinate with the nifmake nifler rule — the
  driver duplicating nifmake's freshness logic.
- `computeModuleReuse` + `enforceDefRetention` + the redirect/cached-defs
  machinery is a hand-rolled mini-`nifmake` *inside* the backend process, needed
  only because one process reuses some TUs while regenerating others.

These are legacy artifacts of a code generator that predates IC, not intrinsic
requirements.

Plan: a nifmake-driven, per-module backend
==========================================

Goal: the backend stops re-implementing `nifmake`. Each module's codegen becomes
its own build rule, so "which TUs rebuild" is just "which rules `nifmake`
re-fires from input mtimes" — exactly as the frontend already works. The reuse /
def-retention / redirect machinery then dissolves.

Target build graph (mirrors Nimony's ``src/nimony/deps.nim``):

1. **Frontend split.** Generate a *frontend* build file (nifler + `nim m` rules),
   run `nifmake`, run the `.s.deps` discovery fixpoint. Then re-derive the graph
   from `.s.deps` (now complete; dead `when` imports can also be **pruned** here).
2. **Per-module codegen rule.** One ``nifc <mod>`` rule per module: inputs are the
   module's own ``.nif`` plus the ``.iface``/``.impl`` cookies of its
   dependencies; output is its ``<s>.c.nif``. The process loads `<mod>` + its
   import closure's NIFs (like `nim m`) and emits **only the entities it owns**,
   referencing everything else `extern`.
3. **Static ownership** replaces runtime redirect. Every emittable entity —
   generic instances, type-bound hooks, RTTI, lifted procs — gets a deterministic
   owner module *by symbol suffix*. Because instance names are content-addressed
   (``ident.disamb.key.owner``), the same instance demanded by several modules has
   one name and one owner, so there is exactly one writer and no link-time
   duplicate. (The precise owner rule — minting module vs. root-type's module — is
   the open design decision; start from `itemId.module` and adjust where it forces
   a downstream package to own stdlib code.)
4. **DCE as a rule.** A single rule reads all ``.c.nif``, computes the global live
   set, and (Nimony: ``.live.nif`` / per-module ``.dce.nif``) drives per-module
   ``.c`` emission filtered to live entities.
5. **Link rule.** Depends on every ``.o`` (each compiled by its own rule) and the
   DCE output; produces the executable.
6. **Deletions.** `computeModuleReuse`, `enforceDefRetention`,
   `redirectToLiveModule` and the cached-defs/claim bookkeeping go away. The
   ``setLastModificationTime`` coordination in `runNifler` goes away with the
   frontend split (the nifler rule owns parsed+deps; the driver's pre-scan only
   reads `.deps` to build the graph).

Validation bar: `koch bootic` must still reach its byte-identical fixed point, and
binary size must not regress (DCE parity), across the external-package CI set.

Code, logic & debugging
========================

Core modules:
- **`compiler/deps.nim`** — graph construction, SCC grouping, discovery fixpoint,
  build-file generation; `commandIc`.
- **`compiler/ast2nif.nim`** — AST↔NIF, the cookie hashes (`cookieSd`,
  `writeIfaceCookie`, `writeImplCookie`, `writeEdgesFile`, `writeSemDeps`).
- **`compiler/nifbackend.nim`** — the backend (`commandNifC`) and its reuse
  machinery.
- **`compiler/icconfig.nim`** — precompiled config.
- **`compiler/pipelines.nim`** / **`modulegraphs.nim`** — pipeline integration and
  the graph state (`importDeps`, `icImplDeps`, `icReusedModules`, …).

Manual workflow:
- Frontend a module: ``nim m --nimcache:nifcache path/to/mod.nim`` (writes
  ``.nif`` + cookies + ``.s.deps``).
- Backend: ``nim nifc --nimcache:nifcache main.nim``.
- NIF files are text — open/grep them directly; ``diff`` two successive ``.nif``
  to see why a module rebuilt.
- Force a re-sem: delete the module's ``.nif`` and rerun `nim m`.
- A stale-cache crash after editing the serialization layout means bumping
  ``icFormatVersion`` (`compiler/options.nim`).

See also
========

- NIF format spec: [nifspec/doc/nif-spec.md](../nifspec/doc/nif-spec.md)
- NIFC (C-like target) spec: dist/nimony/doc/nifc-spec.md
