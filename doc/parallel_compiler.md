# A concurrent compiler: routine bodies as the unit of parallelism

Status: PLAN (2026-09-01). Written against branch `araq-ic-fixes3` @ `b2ecde1f2`.
Companion to `doc/ic.md` (the IC design this sits on top of). Line numbers below
are from that commit; the measurements are from a 32-core machine.

## 0. Goal, and the constraints that shape it

The goal (Araq, 2026-09-01):

> Every toplevel statement can be semchecked independently and we extract the
> parallelism of the problem within a module, not due to the poor shape of the
> import graph. We still seek to avoid recompiles for modules that did not change
> so this sits on top of IC. To simplify the problem somewhat we only run
> semchecking of proc bodies in parallel. But we also want to run the
> transformations and C code generation after the semcheck of a proc body so that
> all phases of the compiler benefit. We can build upon `--mm:atomicArc` and the
> latest allocator bugfixes. We need to give the `PContext` a reader/writer-lock
> scheme.

Restated as constraints on the design:

1. **Unit of work = one routine body**, carried through sem → `sempass2` →
   `transf`/`injectdestructors` → C codegen without leaving the worker. Top-level
   statements (types, signatures, globals, `static`, imports) stay sequential in
   source order.
2. **IC stays the caching layer.** Unchanged modules are not recompiled; the
   artifacts (`.s.bif`, `.t.bif`, `.c.nif`, cookies) keep their meaning.
3. **Byte-identical output regardless of scheduling.** This is not a nicety: IC
   cookies, the `merge` stage's name-keyed dedup, and the `koch bootic` fixed
   point all assume the output of a module is a pure function of its inputs. Any
   scheduling-dependent bit in a `.s.bif` is a spurious re-sem of every importer;
   any scheduling-dependent bit in a `.c` is a spurious re-link.
4. `--mm:atomicArc --threads:on` for the compiler binary, `PContext` split into a
   shared part under a reader/writer lock and a worker-private part.

Section 1 shows what the parallelism is worth. Section 2 is the architecture.
Section 3 is the `PContext` split. Section 4 is the catalogue of gotchas found
in the code, each with the answer the design gives it. Section 5 is the staged
roadmap with its validation gates. Section 6 lists open questions.

## 1. What the numbers say

Instrumentation: a temporary `tSemBody`/`tSemModule` pair in `semProcAux` and
`processPipelineModule` (outermost activation only, so nested routines count
towards their top-level owner), on top of `-d:icBNodeProf`. Not committed.

### 1.1 Classic whole-program build of the compiler (`nim c --compileOnly compiler/nim.nim`, 244 modules)

| phase | ms | share |
|---|---:|---:|
| whole process | 5391 | 100% |
| sem of top-level routine bodies (incl. `trackProc`, nested routines, instances made inside them) | 3409 | 63% |
| `transformBody`+`injectDestructorCalls` (cgen `tTransform`) | 552 | 10% |
| `genProcBody` (cgen `tGenBody`) | 504 | 9% |
| everything else: parse, imports, header sem, type decls, C text assembly | ~930 | 17% |

7590 top-level bodies; the **largest single body is 72 ms**. So the
parallelisable part is ~83% of the frontend and the critical path *inside* a
module is negligible — the whole-program serial remainder is ~1 s.

### 1.2 Per-module, under IC (`nim m` processes, `--ic:on`)

| program | `nim m` procs | Σ process | Σ body sem | share | Σ write `.s.bif` | Σ load | largest body |
|---|---:|---:|---:|---:|---:|---:|---:|
| compiler (244 modules) | 244 | 15.2 s | 6.33 s | 42% | 2.73 s | 0.98 s | 105 ms (`vm`) |
| Atlas (181 modules) | 181 | 8.1 s | 3.36 s | 41% | 1.59 s | 0.48 s | 33 ms |

The biggest modules:

| module | process | body sem | max body | #bodies |
|---|---:|---:|---:|---:|
| `cgen` | 938 | 553 | 13 | 590 |
| `sem` | 892 | 546 | 18 | 473 |
| `ast` | 529 | 298 | 12 | 466 |
| `jsgen` | 288 | 151 | 15 | 124 |
| `vm` | 281 | 165 | 105 | 65 |

Inside one `nim m` process, bodies are only ~42% of the time; the other 58% is
process start, loading the import closure, header sem and writing the `.s.bif`.
Amdahl: perfect body parallelism gives a `nim m` process **1.5–2.6×**, no more.

### 1.3 Where the real win is: decoupling headers from bodies across modules

The cold-build analysis (`doc/ic.md`, "Where a cold build's time is") found the
import DAG of Atlas is 37 levels deep with a ~19-link chain of 1–4-wide levels,
so `nifmake` reaches an average concurrency of 2.1 on 32 cores. Along that
chain, measured per module:

| module | process | header-only sem | body sem |
|---|---:|---:|---:|
| `system` (group) | 248 | 73 | 175 |
| `ast` (compiler SCC) | 507 | 223 | 284 |
| `context` … `atlas` (12 Atlas modules) | 1391 | 446 | 632 |
| **chain total** | **2146** | **742** | **1091** |

An importer's *header* pass needs only the exporter's *header* (signatures,
types, templates, macros). Bodies are needed only by other bodies (effects,
inline iterators, compile-time calls). So if the dependency unit is the module
header and the scheduling unit is the body, the critical path of the Atlas cold
build drops from "2.1 s of processes in a chain, ×2 for per-process reload" to
~0.75 s of header sem, with every body of every module in one shared pool. That
is the design that lets "the parallelism cancel the bookkeeping"; body-level
parallelism *within* a `nim m` process alone does not.

### 1.4 `--mm:atomicArc` is affordable

Built with `--threads:on --mm:atomicArc` (note: `compiler/nim.cfg:22` sets
`threads:off`, and `lib/system/arc.nim:82` only uses atomic RC when
`hasThreadSupport`, so `--mm:atomicArc` *without* `--threads:on` silently
compiles the non-atomic branch — the first measurement of this session did
exactly that and showed a bogus 0%):

| compiler binary | frontend of `compiler/nim.nim` | max RSS |
|---|---:|---:|
| orc, threads:on | 5.20 s | 528 MB |
| atomicArc, threads:on | 5.71 s (**+10%**) | 466 MB (−12%) |

C output byte-identical. `TNode`/`TSym`/`TType`/`TScope`/`ModuleGraph` are
already `{.acyclic.}` (`astdef.nim:599,710,782,695`, `modulegraphs.nim:62`), so
orc never collected AST cycles anyway; atomicArc loses nothing there. Two
threads is already a net win over the 10%.

## 2. Architecture

### 2.1 Two passes per module

**Header pass** (sequential, source order, on the module's "header thread"):
everything `semStmt` does today *except* the body of a non-generic routine.
`semProcAux` (`semstmts.nim:2432`) runs up to and including
`setEffectsForProcType` (`:2566`), forward-declaration reconciliation
(`:2591-2650`) and `addInterfaceOverloadableSymAt` (`:2553`); then instead of
`semProcBody` (`:2708`) it enqueues a `BodyTask`. Generic routines still run
`semGenericStmt` (`:2724`) in the header pass — it is cheap and its result is
part of the interface. Macros, templates, `{.compileTime.}` routines and
`converter`s keep their bodies in the header pass: the VM needs them, and they
are part of what importers see.

**Body pass**: a pool of workers drains `BodyTask`s. One task = sem body →
`hloBody` → `trackProc` → `transformBody` → `injectDestructorCalls` → cgen
fragment. Tasks are dispatched in *ordinal* order (§2.3) — this is what makes the
waiting rules deadlock-free.

Modules are processed as today (import → recurse), but a module's importers only
wait for its *header pass*; its bodies keep running in the pool. The module's
`.s.bif` and `.t.bif` are written when its last body finishes (a per-module
countdown latch), so IC artifacts are unchanged in content.

Under `--ic:on` this collapses `nim m` + `lower` + `cg` of a module into one
process: the body task already produces the transformed body and the C
fragment. The nifmake graph then has one rule per module plus `merge`/`emit`/
`link`, and the ~400 backend closure loads that the cold-build analysis found go
away. `doc/ic.md`'s five stages become three; see §5, stage 6.

### 2.2 The task record

```nim
type
  BodyTask = object
    key: UnitKey           # canonical, scheduling-independent (§2.3)
    owner: PSym            # the routine; its ast[bodyPos] is still the parsed body
    module: PSym
    visibleUpTo: int32     # idgen.symId at the declaration point (§2.4)
    importsVisible: int32  # index into c.imports at the declaration point
    options: TOptions      # c.config.options at the declaration point
    notes: TNoteKinds      # c.config.notes / warningAsErrors
    features: set[Feature]
    optionStack: seq[POptionEntry]  # copy; {.push.} inside the body pops into it
    msgContext: seq[...]   # instantiation context to replay in messages
    state: Atomic[TaskState]        # NotStarted, Running, Done
    thread: int32                   # who is Running it (for the deadlock argument)
```

Everything a body sem reads from `PContext` that is *positional* is captured
here at enqueue time, which is exactly the list `tryExpr` snapshots today
(`semexprs.nim:2470-2525`) plus the option stack.

### 2.3 Units, canonical keys, and the one rule that keeps it deadlock-free

Not only top-level bodies are "units": generic *instances* (`generateInstance`,
`seminst.nim:487`), lifted *hooks* (`liftdestructors.produceSym`, `:1318`), and
inferred lambdas are bodies too, and today they are produced inline by whichever
body first needed them. Every unit gets a **canonical key** that does not depend
on who triggered it:

| unit | key |
|---|---|
| top-level body | `(module, ordinal)` — position of the definition in the header pass |
| generic instance | `(module of the generic, ordinal of the generic, hash of the bound args)` |
| type-bound hook | `(module of the type, ordinal of the type, op)` — i.e. the existing `setHookDisamb` content key (`modulegraphs.nim:666`) |
| lambda / nested routine | inside its enclosing unit, no key of its own |

**The rule.** A unit may *block* on (or run inline) only units with a *smaller*
key. A unit with a larger key is "not yet processed" — exactly what today's
sequential compiler sees for a routine defined later in the file, and the code
already has a path for it: `sempass2.isForwardedProc`/`propagateEffects`
(`sempass2.nim:731,753-768`) assumes the worst. Because a thread's stack of
nested units is strictly decreasing and every wait targets a still-smaller key,
a wait-for cycle would need a strictly decreasing chain of keys around a loop:
impossible. No deadlock detector is needed.

The rule reproduces today's semantics in the common case (callee declared
earlier ⇒ precise effects; forward-declared ⇒ pessimistic) and makes the rare
case (mutual recursion between instances, hooks that lift hooks) deterministic
instead of nesting-order-dependent. The only situation in which a *larger*-key
unit is demanded from a smaller one is a `mixin`-bound generic declared after
the caller (§4.10); there the caller must not run it inline — it gets the
signature (which never needs the body) and pessimistic effects, and the instance
body becomes a task of its own.

### 2.4 Declare-before-use on a scope that is complete

When body tasks run, the module's top-level scope already contains *every*
top-level symbol, including ones declared after the routine. Nim requires
declare-before-use, and overload resolution must not see later overloads, so
lookups filter. There is no declaration-order field on `TSym` (`position`,
`offset`, `disamb` are all overloaded — `astdef.nim:744-754`), but there does
not need to be one: **`itemId.item` is today a per-module monotone creation
counter** (`ast.nim:560`, `newSym` `:802`), and body-minted ids will live in
disjoint high arenas (§4.2). So a task records `visibleUpTo = idgen.symId` at
its declaration and `lookups.nim` (`searchInScopes :205`, `initOverloadIter
:~680`, `someSymFromImportTable :192`) skips a symbol of *this* module whose
`item` is a header-pass id greater than `visibleUpTo`. Imports declared later
in the file are skipped the same way (`ImportedModule` gets a `visibleFrom`
index; `c.imports` is append-only). Cost: one compare per candidate.

### 2.5 The per-body pipeline and its outputs

```
sem body            → owner.ast[bodyPos]      (private to the unit)
hloBody             → needs c.patterns read-only (§4.1)
trackProc           → publishes effects on owner.typ.n[0] (§4.4), waits per §2.3
transformBody       → owner.transformedBody (publish-once, §4.3)
injectDestructorCalls
cgen fragment       → one `cdef`-framed chunk per routine + a request list (§4.5)
```

The fragment is exactly what `cgen.nim:1786-1797` emits today (a `\4 name …\5`
framed body), produced by a worker-local `BModule` shadow whose section buffers
start empty. Type declarations, string literals, RTTI and prototypes that the
routine needs are generated into the shadow's own sections and *deduplicated by
name at module close*, in canonical fragment order — the same name-keyed,
order-insensitive mechanism the IC `merge` stage already applies across TUs
(`cnif.nim:489-587`, owner = lexicographic minimum of claimants). The raw-text
sections (`cfsTypes`, `cfsStrData`, `cfsVars`, `cfsProcHeaders`) are today *not*
`cdef`-framed and are guarded only by per-module `IntSet`s; they get framing
(§4.5).

Anything that must reach *module* level — `{.global.}` initialisation
(`ccgstmts.nim:374`), threadvar fields (`ccgthreadvars.nim:34`), `{.header.}`
includes (`cgen.nim:324`), `globalDestructors` (`injectdestructors.nim:601`),
`procGlobals` (`:1010`), forwarded procs (`cgen.nim:64`) — is recorded as a
request on the fragment and applied at module close in key order. Requests, not
mutations.

### 2.6 Determinism rules, collected

1. Tasks are dispatched and their outputs merged in key order.
2. Ids and `disamb`s minted inside a unit come from an arena derived from the
   unit's key, never from a shared counter (§4.2).
3. A unit reads another unit's body-derived facts (effects, `transformedBody`,
   inferred `auto` type) only after its `Done` (acquire), and only if its key is
   smaller; otherwise it takes the "not yet processed" path.
4. Messages are buffered per task and flushed in key order; the first error is
   the smallest-key error among tasks that had been dispatched (§4.8).
5. Every shared table that bodies append to becomes per-task and is merged in
   key order (`c.generics`, `opsLog`, `globalDestructors`, `procGlobals`,
   `sideEffects`, `nifExpansions`, `icImplDeps`, `nifReplayActions`).
6. The reference implementation is the *same code with one worker* (stage 1 of
   §5). Parallel output must be byte-identical to it, and it must be
   byte-identical to today's compiler on `koch bootic` plus the external
   packages, with the deltas of §4.10 reviewed and enumerated.

## 3. The `PContext` split and the reader/writer lock

`TContext` (`semdata.nim:105-209`) has three kinds of fields, and the survey
classified all of them:

**(a) Positional — become worker-private (`SemWorker`)**: `currentScope`, `p`,
`instCounter`, `inGenericContext`, `inStaticContext`, `inUnrolledContext`,
`compilesContextId`, `inGenericInst`, `matchedConcept`, `inTypeContext`,
`inConceptDecl`, `inTypeofContext`, `inUncheckedAssignSection`,
`inParallelStmt`, `isAmbiguous` (the "little hack" written and read across call
boundaries, `semexprs.nim:182-244`), `recursiveDep`, `friendModules` (a stack,
`sem.nim:509,564`), `lastTLineInfo`, `optionStack`, `features`, plus the
graph-level `owners` stack (`semdata.nim:271-283` — `getCurrOwner` reads
`c.graph.owners[^1]`; it moves into the worker) and the per-worker parts of
`ConfigRef` (§4.1).

**(b) Module-shared, read-only once the header pass is done**: `module`,
`moduleScope`, `topLevelScope`, `imports`, `importTable`, `cache`, `graph`,
`voidType`, `signatures`, the hook `proc` fields, `converters`, `patterns`,
`pureEnumFields`, `userPragmas`, `libs`, `includedFiles`.

**(c) Module-shared and mutated from bodies**: `generics` (+`lastGenericIdx`),
`templInstCounter`, `sideEffects`, `unusedImports` (deleted from by
`markOwnerModuleAsUsed`, `suggest.nim:697`), `intTypeCache`, `nilTypeCache`,
`shadowDiscardedDefs`, `realizedDefs`/`hasSymRedefs`, `forward*Updates`, and —
rarely, but legally — the (b) tables: `{.pragma.}` inside a body
(`pragmas.nim:721`), `{.dynlib.}` on a nested routine (`:323`), a routine with
a `{.pattern.}` at any nesting (`semstmts.nim:2745`), `include` inside a body
(`semexprs.nim:3674` has the check commented out), `import` inside `compiles()`
inside a body (`:3664` permits it), and `errorSym` adding to `moduleScope`
(`lookups.nim:310`).

The lock scheme:

```nim
type
  SemShared = object          # one per module
    lock: RwLock              # guards the (b) tables and topLevelScope
    ...(b) fields...
    generics: Lock + seq      # or per-task and merged; see §2.6 rule 5
    templInstCounter: Atomic[int]
    intTypeCache / nilTypeCache: lock-free after pre-warming (§4.3)
  SemWorker = ref object      # one per thread, cheap to create per task
    shared: ptr SemShared
    ...(a) fields...
    config: WorkerConfig      # options/notes/msgContext/error counters/msg buffer
    idgen: IdGenerator        # arena for the current unit
```

- **Readers**: every body task holds the read lock for the duration of a
  lookup/overload-resolution sequence (not for the whole body — `compiles()`
  needs to upgrade, see next point).
- **Writers**: the header pass takes the write lock around each top-level
  insertion when it overlaps with body tasks (stage 4); the rare (c)-mutations of
  (b) tables from a body take the write lock; nothing else does.
- No upgrade: a body that must write releases its read lock, takes the write
  lock, and re-validates. The (b) tables are append-only during the body pass,
  so re-validation is "look again".
- Lock order, always acquired in this order and never held across a §2.3 wait:
  `SemShared.lock` → graph table locks (`procInstCache`, `typeInstCache`,
  `attachedOps`, `instDisambs`, `sysTypes`, `compilerprocs`) → `IdentCache`
  lock → loader locks (`program`, pools) → VM ownership (§4.6). A §2.3 wait is
  only entered with no lock held; `trackProc` and `transformBody`, where waits
  happen, never hold one.

In stage 1–3 of §5 the header pass finishes before any body starts, so the
write lock is uncontended and the reader/writer machinery is only exercised by
the rare in-body writers — the scheme is introduced early but stressed late.

## 4. Gotchas found in the code, and what the design does with each

### 4.1 Stacks on shared objects (save/restore-around-a-region idioms)

The compiler's positional state is a set of stacks that live on objects every
worker would share:

| what | where | fix |
|---|---|---|
| owner stack | `c.graph.owners`, `semdata.nim:271-283` | move to `SemWorker` |
| scope chain | `c.currentScope`, `lookups.nim:75-88`; reset wholesale by `generateInstance` `seminst.nim:487` and `recoverContext` `sem.nim:911` | per worker; the chain's tail (`topLevelScope`) is shared read-only |
| option stack ↔ `c.config.options/notes/warningAsErrors`, `c.features` | `pushOptionEntry`/`popOptionEntry` `semdata.nim:344-361`; `rawCloseScope` truncates it `lookups.nim:82`; `{.checks:off.}` in a body writes `c.config.options` directly `pragmas.nim:1189`; `processNote` writes `c.config.notes` `:386`; `enterPragmaBlock` `semstmts.nim:2914`; `semNimvmBranch` `semexprs.nim:2710` | `options`, `notes`, `warningAsErrors`, `features` move into `WorkerConfig`; `s.options = c.config.options` at declaration (`semstmts.nim:2471`) already snapshots per routine |
| message context | `c.config.m.msgContext`, pushed from `seminst`, `semtypinst`, `sigmatch`, `transf.nim:941` | per worker |
| `errorOutputs` gag in `tryExpr` | `semexprs.nim:2492` sets `c.config.m.errorOutputs = {}` **globally** | per worker |
| `errorCounter`/`errorMax` rollback in `tryExpr` | `:2476-2477, 2521` | per-worker counters, aggregated atomically |
| `c.generics` rollback in `tryExpr` | `:2490, 2500, 2511` | `generics` becomes per-task (rollback is then local); merged in key order |
| `hlo.applyPatterns` nils entries of the shared `c.patterns` and restores them | `hlo.nim:53, 62` | per-worker copy of the pattern list (it is small) |
| `friendModules` push/pop | `sem.nim:509,564`, `seminst.nim:484,592` | per worker |
| `recoverContext` | `sem.nim:911-915` | per-task exception boundary resets the worker |

### 4.2 Counters: identity that must not depend on scheduling

- **`IdGenerator`** (`ast.nim:527-534`, "unfortunately, we really need the
  'shared mutable' aspect here"): `symId`, `typeId`, and `disambTable` are
  read-modify-written by every `newSym`/`newType`/`copySym`/`copyType` — from
  sem, `sempass2` (`markGcUnsafe` mints a sym, `:346`), transf (`newTemp`,
  `newLabel`), lambdalifting, closureiters, liftdestructors, injectdestructors.
  Under IC `nextSymId` also consults the loader (`nextBackendSymItem(program,…)`,
  `:566`).
  **Fix: arenas.** A unit's `IdGenerator` is a private object whose `symId`/
  `typeId` start at `base(key)` and whose `disambTable` is private and seeded
  from `base(key)`. For top-level bodies `base = headerEnd + ordinal * 2^18`
  (8192 bodies × 262 144 ids per module; overflow is a hard error in stage 2,
  and the fallback is "compile this module with one worker"). For instances and
  hooks, whose keys are hashes, the *in-memory* `itemId` base is allocated
  first-come (ids are not serialized — see next bullet) but the `disamb` seed is
  the content hash with `instDisambs`-style probing, which is what
  `setInstanceDisamb`/`setHookDisamb` already do for the unit's own symbol
  (`modulegraphs.nim:623-690`).
- **What is serialized.** The `.s.bif` writer never writes `itemId.item` for
  ordinary symbols — names are `name.<disamb>[.module]` (`ast2nif.nim:334-380`,
  rationale `mangleutils.nim:72-78`); C names use `disamb` too
  (`mangleProcNameExt`). So per-unit `disamb` seeding is what makes both
  artifacts scheduling-independent. The two leftovers that *do* write raw
  `itemId.item` are anonymous `tyProc`s and nominal types (`ast2nif.nim:805,
  833-847`); types declared inside a body (`type T = object` in a proc) must
  therefore get a unit-relative name (`<owner NIF name>.T.<n>`), which is the
  same shape `sharedInstanceCName` already uses.
- `c.templInstCounter` (`semdata.nim:125`, `inc instID[]` `evaltempl.nim:229`)
  is the *only* source of gensym uniqueness (`` name`gensym<N> ``,
  `evaltempl.nim:72`). Fix: `instID` becomes part of the unit arena
  (`base(key) + local`), so gensym names are canonical too.
- `c.compilesContextIdGenerator` (`semexprs.nim:2482`): per worker with disjoint
  ranges.
- `conf.evalTemplateCounter`/`evalMacroCounter` (`evaltempl.nim:190`,
  `vm.nim:2589`): recursion-depth guards → per worker.
- cgen `m.labels` (`cgendata.nim:188`, `getTempName` `cgen.nim:565`) numbers
  string literals, `Nim_OfCheck_CACHE`s and const temporaries first-come, and
  `m.dataCache` (`ccgliterals.nim:60`) stores that number as the literal's C
  name. Fix: literal names become content-addressed (`TM<hashOwner>_<hash of
  the literal>`, collision-probed at module close) and per-proc temporaries use
  `p.labels`, which is already per-`BProc`.
- `m.g.mangledPrcs` (`ccgtypes.nim:69`, Itanium mode) and `m.sigConflicts`
  (HCR only) are first-come; both are off in the default configuration and
  stay unsupported in parallel mode until someone needs them.

### 4.3 Reads that mutate (lazy initialisation on the read path)

These are the ones that break the "readers only need the read lock"
assumption:

| site | what it does | fix |
|---|---|---|
| every `PSym`/`PType` accessor, `ast.nim:60-470`: `if s.state == Partial: loadSym(s)` | a *read* of a loaded symbol deserialises it through `var program {.threadvar.}` (`ast.nim:33`) — empty in a worker | `program` becomes a shared object with its own lock; `loadSym` does `CAS(state, Partial → Loading)`, fills, then publishes `Complete` with a release store; losers spin on `Loading`. The `Sealed → Complete` downgrade in `unsealForTransform` (`ast.nim:80-86`) is the same shape |
| lazy bodies: `len`/`sons`/`items` call `forceLazyBodyHook` (`astdef.nim:924-963`), whose implementation clears `nfLazyBody` *before* filling (`ast2nif.nim:3551-3566`), through the `loaderCtx` threadvar (`:2489`) and a `pendingBodies` table keyed by node *address* | a second reader between the clear and the fill sees an empty body | fill first, clear the flag last (release); `pendingBodies.pop` under the loader lock; `loaderCtx` shared |
| `gconfig {.threadvar.}` doc-comment side table keyed by node address (`ast.nim:470-508`) | comments set on one thread are invisible on another | shared table under a lock; it is only used by docgen |
| `IdentCache.getIdent` (`idents.nim:68-95`) does move-to-front on *hit* | mutation on every lookup, from everywhere (`lookups.nim:37`, `evaltempl.nim:72`, …) | drop move-to-front; bucket insertion under a lock; lookups lock-free (buckets are a fixed array, chains are append-at-head with release) |
| `getSysType` fills `g.sysTypes[kind]` (`magicsys.nim:75`); `getIntLitType` fills `c.intTypeCache` (`semdata.nim:216-229`) on every small literal; `getNilType`; `getCompilerProc` falls through to `loadCompilerProc` (`magicsys.nim:113-120`) | lazy shared fills on the hottest paths | pre-warm all `sysTypes` and the small-int cache after the system module loads; `compilerprocs` filled under the graph lock (loads are rare after warm-up) |
| `ensureHiddenIface` (`modulegraphs.nim:264-281`) | builds an iface's hidden half on first touch; the code already warns that loading can grow `g.ifaces` under a `var` alias | build under the loader lock; `g.ifaces` becomes a stable-address container |
| `transformBody` sentinel (`transf.nim:1388`): `prc.transformedBody = newNode(nkEmpty)` as a recursion guard, cleared to `nil` at `:1433` unless cached | two threads transforming the same inline iterator both proceed; one's `nil` clobbers the other's cache | `transformedBody` is publish-once per unit (§2.3): the owner unit writes it, readers wait for `Done`. The `nkEmpty` guard stays for genuine recursion within one thread |
| `getClosureIterResult` installs a `:result` sym on first call (`lambdalifting.nim:152-159`) | lazy shared mutation | done in the header pass for closure iterators |
| `getTypeName` memoises into `typ.loc.snippet` (`ccgtypes.nim:203-205`) | value-stable, idempotent | make the store atomic; benign otherwise |
| `computeSize` writes `t.size`/`t.align` and a transient `szIllegalRecursion` marker (`sizealignoffsetimpl.nim:229`) | a visible intermediate state | compute into locals, publish `size`/`align` with one store; the marker becomes a thread-local visited set |
| `nifpools.pool`/`globalTags` (`nifpools.nim:65,76`), `nifstreams.lineMan`/`globalFloats` (`:68,139`), `nifcore.fallbackPool` (`:445`), `ast2nif.topTagPool`/`topTagCache` (`:4047`) | process-global interning; `getOrIncl` at load time, index reads afterwards | `RwLock` on the pools; loads (writes) happen on the header thread at import time, workers only read by index. `topTagCache` becomes a proper per-pool field |

### 4.4 Writes to *other* units' symbols and types

The AST is a shared mutable graph, not data. What body sem and the later passes
write onto symbols/types they do not own:

| write | where | fix |
|---|---|---|
| callee effect list `typ.n[0]`: `rawInitEffects` does `newSeq(effects.sons, effectListLen)` (`sempass2.nim:1877`), then `effects[exceptionEffects] = …` (`:1967-1994`); callers iterate that seq (`trackCall` `:1234-1270`, `mergeRaises` `:567`) and the "already computed?" test is `effects.len == effectListLen` (`:1917`) | a **direct data race** between caller and callee | the callee builds the effect list in a fresh node and publishes it with one pointer store after `Done`; callers never touch `typ.n[0]` of a unit that is not `Done` — they use the §2.3 rule (`Done` + smaller key ⇒ read; else pessimistic). The in-tree hook bail-out at `:1256-1266` ("has no effect list yet") is the same hazard papered over today |
| inferred flags on the routine/type at the end of `trackProc`: `sfNeverRaises` (`:1935`), `tfGcSafe`/`tfNoSideEffect` (`:2019-2021`), `sfInjectDestructors` accumulated *mid-walk* on `tracked.owner` (`:153,1453`), `gcUnsafetyReason` | callers read `tfNoSideEffect notin op.flags` (`:1131`, `:767`) | same publish-after-`Done` rule; and the inference is order-dependent *in strength* today (a caller analysed before its callee is silently marked side-effecting) — the key rule makes the strength deterministic |
| `set` flags are read-modify-write on a 64-bit word: `incl(s.flagsImpl, sfUsed)` (`suggest.nim:709`), `sfAddrTaken` (`semdata.nim:744-757`), `tfHasAsgn`/`tfCheckedForDestructor`/`tfGenericHasDestructor` (`liftdestructors.nim:1466-1517`), `tfVarIsPtr` (`semexprs.nim:2207`) | a lost update between two workers drops a flag — `sfUsed` lost is a spurious hint, `tfHasAsgn` lost is wrong code | `atomicIncl`/`atomicExcl` templates (fetch-or/and) for `flags` of `PSym`/`PType`/`PNode`; a grep-driven pass over `incl(.*flagsImpl` (145 sites outside `ast.nim`). Landed in stage 0 behind `-d:nimParallelSem`. Note the headroom: `TSymFlags` is 63 of 64 bits — one spare — and the 65th symbol flag would make the set a 9-byte array and the fetch-or impossible; `astdef.nim` asserts the width |
| forward-declaration reconciliation rewrites the *proto* symbol: `proto.flags`, `.info`, `.options`, `.ast = n` and splices proto's param/pragma nodes into `n` (`semstmts.nim:2593-2648`) | the proto is exactly what other bodies resolve calls against | header-pass only (bodies never declare top-level routines); in stage 4 (overlap) the reconciliation is done under the write lock and `proto.ast` is published last |
| `auto` return type resolved *inside* `semProcBody` by writing the owner's `PType` (`semexprs.nim:2184-2202`, iterators `:2246`); method dispatchers patched (`semstmts.nim:2814-2820`) | a caller matching against `auto` observes a torn signature | no cross-unit exposure: `auto` is forbidden in forward declarations (`semstmts.nim:2736`) and a routine must be declared before use, so only the routine's own body (same unit) can see its unresolved `auto`. Inferred lambdas (`semInferredLambda`, `:2076`, called from `sigmatch.nim:2541`) live inside the caller's unit. Dispatcher patching is header-pass |
| lambdalifting rewrites the routine's calling convention (`lambdalifting.nim:326`, `propagateClosure` `:889`), appends the hidden `:envP` param to `typ.n` (`:174-183`), grows env object types with new fields (`:520`, `closureiters.nim:208`), flips `Sealed → Complete` (`unsealForTransform`), and sets `sfInjectDestructors` on foreign syms (`:227`) | signature grows while another unit's cgen reads `typ.n` | all of these concern *nested* routines and env types, which are owned by the enclosing unit — except `propagateClosure` up an owner chain that crosses units (a nested proc capturing from its top-level owner is still the same unit; top-level procs are never closures, `semstmts.nim:2752`). Asserted, not locked |
| `liftdestructors`: `tfCheckedForDestructor` check-then-set (`:1464-1466`), prototype pre-registration via `setAttachedOp` (`:1494-1499`, `setAttachedOpPartial` `:1348`), `g.canonTypes[h] = skipped` (`:1478`), and `setAttachedOp` itself writes three tables and patches `opsLog` in place (`modulegraphs.nim:418-468`) | two workers lift `=destroy` for the same type ⇒ two hook symbols, and the second `setAttachedOp` rewrites the log entry | a hook is a unit (§2.3): claim `(type, op)` in `attachedOps` under the graph lock; the claimant produces the body (from its content-keyed arena), the loser uses the claimant's symbol — which is all it needs, hook effects are declarative (`sfNeverRaises`, `:1385`). Emission order is by key, not `opsLog` order |
| `sigmatch` writes `formal.ast.typ = errorType(c)` on the **callee's** default-param node on a mismatch (`sigmatch.nim:3169`) and truncates shared `inferredTypes` (`:3186`) | writes into another routine's signature | stop writing: the error marking is a side channel for a message that can be raised locally; the copy at `:3172` is already what gets spliced |
| `recomputeFieldPositions` renumbers `obj.sym.position` of an instantiated object (`semtypinst.nim:875-891`) | type instances are shared across units | done once when the instance is created, under the `typeInstCache` lock, before publication |
| cgen `loc` writes on shared symbols: `fillProcLoc` (`cgen.nim:1054`), `fillParamName` on *another* routine's params while generating its prototype (`ccgtypes.nim:139`, from `genProcHeader`), `genVarPrototype` naming another module's global (`cgen.nim:2016`), `assignGlobalVar` (`:970`), `prc.infoImpl = tmpInfo` (`:1720`, "IC: spurious write"); every one goes through `backendEnsureMutable`, which may *load* the symbol (§4.3) | names are pure functions of the symbol (`fillBackendName` `ccgtypes.nim:129`, `fillParamName` positional) so the *values* agree | compute-once with a CAS on `loc.snippet` (all writers produce the same string); drop the `infoImpl` write; `loc.k/storage/flags` become a per-`BModule`-shadow side table — this is the same conclusion the PType read-side audit reached (codegen bookkeeping needs side tables, not accessor swaps) |
| `sfCompileTime` set on `tracked.owner` mid-walk under IC (`sempass2.nim:1216`) | flag on the unit's own owner | fine, own unit |

### 4.5 Shared containers appended to from bodies

Every one of these becomes per-task and is merged in key order at module close,
or is protected by a lock when it is a genuine cache:

| container | writer | kind |
|---|---|---|
| `c.generics` | `seminst.nim:558` | per task; merge in key order (this fixes instance *emission* order, which is C output order) |
| `g.procInstCache`, `g.typeInstCache` | `semdata.nim:667-671` | lock + claim; an instance is a unit |
| `g.attachedOps`/`loadedOps`/`opsLog` | `modulegraphs.nim:418-476` | lock + claim; `opsLog` order replaced by key order |
| `g.instDisambs` | `modulegraphs.nim:655` | lock; probing stays first-come on *collision only* (already accepted) |
| `g.globalDestructors`, `g.procGlobals` | `injectdestructors.nim:601,1010`; drained by `cgen.nim:3086,2945` | per task → fragment requests; applied in key order (destructor order of `{.global.}`s must be deterministic) |
| `c.sideEffects` (`Table[int, seq[…]]`) | `sempass2.nim:363` | per task; `listSideEffects` (`:404`) reads callees' shards after their `Done` |
| `c.unusedImports.del` / `sfUsed` | `suggest.nim:697-711` | `sfUsed` atomic; the unused-import report waits for the module's latch |
| `c.userPragmas`, `c.libs`, `c.patterns`, `c.includedFiles`, `c.imports` (in `compiles()`), `moduleScope` (`errorSym`) | `pragmas.nim:721,323`, `semstmts.nim:2745`, `:1907`, `importer.nim:188`, `lookups.nim:310` | write lock (rare) |
| `g.nifExpansions`, `g.icImplDeps`, `g.nifReplayActions`, `g.cacheSeqs/Tables/Counters` | `semdata.nim:681`, `modulegraphs.nim:929,497`, `vm.nim:2284-2349` | per task, merged in key order — **these are IC replay logs; their order is artifact content** |
| `c.forwardTypeUpdates`/`forwardFieldUpdates`/… | `semtypes.nim:70-1866` | local type sections inside bodies: per task |
| `g.enumToStringProcs`, `g.methodsPerGenericType`, `g.methods`… | `semtypes.nim:226`, `semstmts.nim:2419`, `seminst.nim:469` | lock; `finishMethod` from an instance is the one body-reachable method writer |
| `m.g.forwardedProcs` (LIFO, `cgen.nim:64,3199`), `m.g.typeInfoMarker*` (`ccgtypes.nim:2112,2222`), `m.g.nimtv` (`ccgthreadvars.nim:34`), `m.headerFiles`, `m.preInitProc`/`initProc` (`ccgstmts.nim:374`), `m.typeCache`/`forwTypeCache`/`declaredThings`/`declaredProtos`/`dataCache`/`typeStack`/`icDataDefs` | per-`BModule` state written from arbitrary procs' codegen | worker-local `BModule` shadow per fragment; module-level effects become fragment requests; the raw-text sections get `cdef` framing so the module-close merge can dedup them by name exactly like the cross-TU merge does |

### 4.6 The VM singleton

`g.vm` is one `PCtx` per graph (`modulegraphs.nim:127`, "unfortunately the 'vm'
state is shared project-wise"); `setupGlobalCtx`/`refresh` (`vm.nim:2469`,
`vmdef.nim:312-318`) overwrite `c.module`, `c.prc`, `c.idgen`, `c.callDepth`
in place; `evalMacroCall` (`:2584-2645`) hand-rolls dynamic scoping of `c.mode`,
`c.callsite`, `c.templInstCounter`; `c.code`/`c.globals`/`c.procToCodePos` are
append-only project-wide, and `vmgen.genProc` calls `transformBody` on ordinary
runtime procs with `{useCache}` (`vmgen.nim:2518`), which is what
`g.inVMTransform`/`vmTransfIdgen` (`transf.nim:1396-1401`) exist to contain.
Compile-time globals get `s.position` written by `vmgen` (`:1776,1788,2088`).

Design, in two steps:

1. **One VM, one owner at a time.** A worker acquires *VM ownership* (a mutex)
   for the duration of one evaluation (`evalMacroCall`, `evalConstExpr`,
   `evalStaticStmt`), with the session fields saved/restored at the boundary as
   `evalMacroCall` already does. `c.idgen` is the calling unit's arena.
   `c.code`/`c.globals` stay append-only and shared. This alone serialises all
   macro expansion, which is acceptable for stage 3 — bodies spend most of their
   time outside the VM.
2. **Never wait while owning the VM.** A VM session may discover it needs a
   body of the current module: `vmgen.genProc` of a callee (`static: foo()`,
   `const x = foo()`), or `getImpl`/`getImplTransformed` (`vm.nim:1330-1372`).
   By §2.3 that body has a smaller key; if it is `NotStarted` it runs inline (no
   VM needed to *start* it — but its own `const`s need the VM: re-entrant
   ownership by the same thread is fine). If it is `Running` on another thread,
   waiting with the VM owned deadlocks as soon as that thread needs the VM. Two
   answers, cheapest first:
   - at `vmgen` time nothing has executed yet: the session aborts cleanly
     (`c.code.setLen`, `procToCodePos` rollback), releases the VM, waits for the
     unit, and restarts the evaluation. Restartable because the calling unit's
     side effects so far are all per-task (§2.6 rule 5) and its arena is
     re-minted identically;
   - `getImpl` mid-execution cannot restart. Its target is either a *smaller*
     key that is `Done` (the normal case: the macro asks about an earlier
     proc), or `Running` — then the session **hands the VM over**: the waiting
     thread's execution state is on its own stack (`rawExecute` locals), the
     session fields are saved, the mutex is released for the duration of the
     wait and re-taken after. `c.code` growth by the other thread is safe for
     index-based access. This needs an audit of which `PCtx` fields are
     session state; it is the hardest single item in this plan, and it can be
     deferred behind a "no parallel bodies in modules that `getImpl` their own
     routines from inside proc bodies" diagnostic until then.

Semantics that *cannot* be preserved: mutation order of compile-time globals and
of `CacheSeq`/`CacheTable` (`vm.nim:2284-2349`) by macros invoked from
different bodies. Today it is source order; under parallel bodies it is
scheduling order. `--ic:on` already breaks the same assumption across modules
(only changed modules re-run their macros), so the policy is the IC one:
macro cache mutations are replayed per unit in key order for *artifact*
purposes (`vmstateDiff`, `macrocacheimpl.nim:13`), and the live VM state seen by
a later macro is not guaranteed to reflect earlier-in-source bodies.

### 4.7 The remaining process globals

Full inventory in the survey; the ones that are written during compilation and
are not covered above: `nifcBackendActive` (`astdef.nim:20`, set once per
stage — fine), `canonTypeIds`/`canonClaims`/`canonSigOwners` (`ast2nif.nim:643-
661`, writer-side, module close is sequential — fine), `evalffi.packRecCheck`
(`:185`, a re-entrancy counter → per worker), `debuginfo.gDebugInfo`
(`--debuginfo` only → lock), `icprof` accumulators (→ per worker, summed at
exit). `msgs.nim`, `options.nim`, `idents.nim`, `magicsys.nim`, `semdata.nim`,
`sem.nim`, `vm*.nim`, `cgen.nim`, `modulegraphs.nim` have **no** module-level
`var`s — their state is all in `ConfigRef`/`ModuleGraph`/`IdentCache`, which
is why the split of §3 is tractable.

### 4.8 Messages and I/O

`msgWriteln`/`msgWrite`/`styledMsgWriteln` (`msgs.nim:343-427`) write to
stdout/stderr and `flushFile` per message; `handleError` bumps
`conf.errorCounter` and `quit`s or raises at `errorMax` (`:455-475`);
`liMessage` temporarily overwrites `conf.m.errorOutputs` for fatal messages
(`:563-566`) and lazily fills `fileInfos[].lines` for source excerpts
(`:505-540`, `hintSource`).

Design: `WorkerConfig` owns the counters and a message buffer; `liMessage`
appends. Buffers flush in key order at task `Done`. `errorMax` handling: on any
error a global stop flag stops *dispatch*; tasks with smaller keys than the
failing one are already running (dispatch is in key order) and are allowed to
finish, so the first flushed error is deterministic and testament's `errormsg`
checks keep working. `fileInfos[].lines` is filled under a lock (it is only
touched when a message with `hintSource` is *rendered*, which happens at flush
on the header thread). `lastMsgWasDot` (`:409`) goes with the buffer.

### 4.9 The memory model, concretely

- `compiler/nim.cfg:22` `threads:off` must become `on`. Consequences: (1)
  `--mm:atomicArc` becomes actually atomic (§1.4); (2) `warningAsError
  [GcUnsafe2]` (`compiler/nim.cfg`) turns every global access from a
  `{.gcsafe.}` context into an error — the survey found `{.cast(gcsafe).}` in
  `ast2nif.nim:3578` and the `forceLazyBodyHook` signature already carries
  `gcsafe`; the task runner is the one place that legitimately needs the cast,
  and the pools/`program` globals will be reached through it; (3) the
  allocator switches to per-thread heaps with cross-thread frees — AST nodes
  minted by a worker die on the header thread and vice versa, which is exactly
  the remote-free path the recent `MemRegion` pooling fixed. `-d:useMalloc`
  stays the A/B control.
- Under atomicArc a `ref` *field assignment* is not atomic (load old, store
  new, dec old). Two writers of the same field, or a reader of a field being
  reassigned, is memory-unsafe — not merely racy. Hence "publish-once with one
  store" everywhere in §4.3/§4.4, and no in-place `sons.add` on shared nodes.
- `seq` growth on shared nodes (`newSeq(effects.sons, …)`, `typ.n.add param`,
  `m.astImpl.add(n)` in `appendToModule` `ast.nim:847`) is the same hazard;
  every one listed above is moved to a fresh node + single pointer store.
- Exceptions cross no thread boundary: each task has a `try` at its boundary
  (`ERecoverableError`, `ESuggestDone`) that resets the worker, records the
  error in the buffer, and marks the unit `Done` (with the error) so waiters
  proceed.

### 4.10 Order dependencies that are *semantics*, and what changes

The design preserves today's results except in these enumerated cases, which
stage 1 (sequential deferred bodies) surfaces as a reviewable diff before any
thread exists:

1. **Effect/side-effect inference strength for callees defined later** —
   unchanged (pessimistic, as today). For instances and hooks the tie-break is
   now the canonical key instead of nesting order.
2. **Inline iterator callers** need the iterator's *transformed* body
   (`transf.nim:812,940`). Same-module iterators are declared before use ⇒
   smaller key ⇒ the caller waits. Cross-module ⇒ loaded ⇒ `Done`.
3. **Instantiation context.** `generateInstance` resets `currentScope` to the
   module's top-level scope *as it is at the instantiation point*
   (`seminst.nim:487`), so a `mixin`-bound symbol in a generic body sees
   whatever the first instantiator's position saw — already fragile, and
   scheduling-dependent under parallel bodies. New rule: an instance is bound
   against the *complete* top-level scope of the instantiating module (the
   §2.4 filter is off inside instantiation). Strictly more programs compile;
   overload choice can differ only when a later-declared better overload
   exists, and cross-module instantiation already behaves this way. The
   instance's key uses the generic's declaration ordinal (§2.3), so a
   `mixin`-bound generic declared *after* the caller is the one case where a
   unit needs a larger key: signature-only, pessimistic effects, own task.
4. **`include` inside a body**, **`import` inside `compiles()` inside a body**:
   legal today, supported via the write lock, not parallel-friendly; a hint.
5. **Compile-time global / `CacheSeq` mutation order** across bodies: the IC
   policy (§4.6).
6. **`{.push.}` without `{.pop.}` inside a body** leaks into following
   top-level statements today (`rawCloseScope` only truncates on scope close);
   with per-task option state it no longer leaks. Arguably a bug fix; listed
   because it is observable.
7. **Hint/warning order** becomes key order instead of emission order; the
   `XDeclaredButNotUsed`/`UnusedImport` reports run after the module latch.

## 5. Roadmap and validation gates

The bar for every stage is the IC one from `doc/ic.md`: `koch boot` and
`koch bootic` byte-identical fixed points, `tests/ic` and the external package
set, plus for stages ≥ 4 a **scheduling grinder**: `-d:nimParallelGrind`
randomises dispatch order and worker count and asserts that `.s.bif`, `.t.bif`
and `.c` outputs are identical across runs (the metamorphic IC harness in
`tests/ic` is the template).

**Stage 0 — foundations (no behaviour change). DONE (2026-09-04).**
`threads:on` in `compiler/nim.cfg`; `koch boot --mm:atomicArc` green and
byte-identical; the `atomicIncl` templates; an `RwLock` + task queue + latch in
a new `compiler/concurrency.nim` (no external package: `std/locks` +
`std/atomics` suffice); `ProfSlot`s for body sem kept (`tSemBody`,
`tSemModule`) so §1 can be re-measured at every stage.

What landed, and the two things it settled:

* `compiler/concurrency.nim`, with no compiler imports (like `icprof`), so
  `ast` can use it. Every primitive has a real `--threads:off` implementation
  rather than a stub, because nimsuggest and the bootstrap stage still build
  that way and "one worker" is a correct implementation of all of them.
  `TaskQueue` is a min-heap on the unit key, not a FIFO: §2.6 rule 1 is a
  property of the queue, not of the code that uses it.
  `tests/compiler/tconcurrency.nim` covers all three columns
  (`--threads:on`, `--threads:on --mm:atomicArc`, `--threads:off`); without a
  user in the compiler nothing would otherwise compile this module.
* `atomicIncl`/`atomicExcl` are wired into `ast`'s `incl`/`excl` accessors
  behind `-d:nimParallelSem`, off by default — the chokepoint is real, but a
  locked read-modify-write on every flag set is not worth paying for while the
  compiler is single-threaded. Both builds produce byte-identical C.
  **Constraint found: `TSymFlags` holds 63 of the 64 flags that fit in a
  one-word set** (`TTypeFlags` 48, `TNodeFlags` 29), i.e. exactly one spare
  slot. Measured, not assumed: `set` of a 64-value enum is 8 bytes, of a
  65-value enum 9 — a byte array, which has no fetch-or. `astdef.nim` now
  asserts `sizeof(TSymFlags) <= 8` with that reason, so the 65th flag is a
  compile error naming the design it breaks instead of an
  `{.error: "flag set wider than a machine word".}` from inside a template.
* `threads:on` costs nothing observable: `koch boot -d:release` reaches its
  fixed point, and the C output of the whole compiler (217 files) is identical
  whether the host compiler was built `threads:off`, `threads:on`, or
  `--mm:atomicArc --threads:on`. The GcUnsafe2-as-error worry of §4.9 did not
  materialise for the compiler as it stands; the one place that needs
  `{.cast(gcsafe).}` so far is a task runner reaching a shared queue, which
  the test already demonstrates.
* §1.1 re-measured with the committed slots (`-d:icBNodeProf`, target
  `compiler/nim.nim -d:release`): 7661 top-level bodies, `SemBody` 3890 ms of
  a 6070 ms process (**64%**), largest single body **86 ms**. That is §1.1's
  63% / 72 ms on a different day, so the premise holds and the numbers are now
  reproducible from a committed build rather than a scratch patch.

**Stage 1 — deferred bodies, one worker. LANDED behind `--deferBodies:on`
(2026-09-04), not yet green.** `semProcAux` enqueues; the queue is drained
*inline in key order* at module close, before `closePContext`. The
`visibleUpTo` filter (§2.4) goes in here and must keep every declare-before-use
test failing as before. Instances, hooks and inferred lambdas keep running
inline (their keys are recorded but not yet enforced). This stage flushes out
every order dependency of §4.10 with zero threads: the diff against today's
compiler on `koch bootic` + the external packages is the review artifact.
Expected: nearly empty.

Landed so far: the `BodyTask` record of §2.2, the enqueue/drain, and the
on-demand path. `--deferBodies:on` is off by default and the default build is
byte-identical, so this is a reviewable A/B rather than a change of behaviour.
`visibleUpTo` is NOT in yet — a deferred body currently sees the whole
top-level scope, which is §4.10.3's rule applied to every unit rather than only
to instantiation, and is one source of the diff below.

Status: `koch boot -d:release --deferBodies:on` reaches its fixed point, and a
compiler *built* that way emits C byte-identical to a normally built one over
all 217 modules — so the order change does not change what the compiler
computes, only what it names things. `tests/compiler` and `tests/template`
compiled with the switch match the default. `tests/async` does not (below).

The diff, measured on `compiler/nim.nim`: 106 of 217 `.c` differ, 37 of them
after normalising the `_u<n>__` suffix away. So two thirds of the diff is
`disamb` renaming — §4.2 exactly, and what stage 2 exists to make canonical.
The residue is type-bound hooks and inline procs materialising in a different
module, which is §4.5's "instance emission order is C output order".

Three order dependencies found, each fixed here:

1. **An importee needs the importer's units.** `system` imports `std/syncio`
   from its own last statements and syncio's routines call system's, so
   draining only at module close left syncio inferring `RootEffect` for every
   call into system. Fixed by draining before a statement that starts another
   module's pass; in practice imports sit at the top and this drains nothing.
2. **An on-demand unit must not overtake smaller keys.** `asyncdispatch`'s
   `{.async.}` machinery transforms `runOnce` (declared at the bottom) during
   the header pass; running that unit alone tracked it before
   `processCallbacksAndTimers` 1100 lines above, which then had no effect list,
   so `runOnce` was inferred GC-unsafe against its own `{.gcsafe.}` forward
   declaration. A demand now runs every smaller key first — which is what §2.3
   says a unit may block on, and what a body semmed at its declaration point
   sees today.
3. **The VM must never meet a pending unit** (§4.6 step 2). `vmgen` reaches
   `transformBody` from inside a session, so answering a demand there runs sem
   and a nested VM session on the graph's single `PCtx`: `tests/compiler` dies
   with a `TFullReg` `FieldDefect`. Draining at `vm.setupGlobalCtx` does not
   work — it is reached from inside generic instantiations and template
   expansions, where running a unit corrupts the instantiation. What does work
   is flushing at a top-level STATEMENT boundary: a run of declarations defers
   as a batch and a `const`, `static:`, `var` initialiser or plain expression
   ends one. Modules are long runs of routine definitions, so little is lost,
   and this is the restriction §4.6 allows in place of VM handoff.

Open, and the reason this is not the default: `tests/async` still fails with
`'runOnce' is not GC-safe as it calls 'processCallbacksAndTimers'`, and with it
`tests/ic/tmeta_async`. Finding (2) fixed the demand path but not this, so the
remaining cause is elsewhere in the same file — the next thing to chase.

**Stage 2 — canonical identity.** Unit arenas for `IdGenerator`, `disambTable`
and `templInstCounter`; unit-relative names for body-local nominal types and
anonymous proc types in `ast2nif`; content-addressed string literal names in
`ccgliterals`. Still one worker. Gate: byte-identical `.s.bif`/`.c` to stage 1
*except* the renamed entities, reviewed; and the chain-batching prerequisite
from the cold-build analysis ("process-independent serialized ids") falls out of
this stage for free.

**Stage 3 — worker-private state.** The §3 split; `WorkerConfig`; per-task
containers of §4.5 with key-ordered merge; `hlo` pattern copy; message
buffering; `program`/pools/`IdentCache` locking; `sysTypes` pre-warm;
publish-once for effects, `transformedBody`, lazy bodies and `loadSym`; VM
ownership step 1. Still one worker, but the code is now shaped for N. Gate:
byte-identical to stage 2.

**Stage 4 — parallel sem.** Workers drain the queue; `trackProc` waits per
§2.3; the header pass of a module still completes before its bodies start (so
the write lock is uncontended). transf/cgen still run sequentially after the
module latch. Gate: grinder + the full bar. Measure: `nim m` of `cgen`/`sem`
should drop from ~0.9 s to ~0.5 s; the compiler's classic build from 5.4 s to
~3 s.

**Stage 5 — the whole pipeline in the task.** `transformBody` +
`injectDestructorCalls` + cgen fragment per task; `BModule` shadow; `cdef`
framing for the raw-text sections; module-close merge reusing `cnif.nim`'s
name-keyed dedup; fragment requests for module-level effects; hook units;
instance units with their own tasks when demanded across the key order. Gate:
grinder; `.c` byte-identical to stage 4 *modulo the section order*, which is
the one output change this stage makes and which the merge's canonical order
fixes once.

**Stage 6 — IC integration.** `nim m` writes `.s.bif`, `.t.bif` and the
`.c.nif` fragment file in one process; `lower` and `cg` stages fold into it;
`deps.nim` emits one rule per module plus `merge`/`emit`/`link`; nifmake's
ready-queue scheduling (from the cold-build analysis) so a module's rule fires
the moment its imports' *headers* are done — which requires splitting the
per-module artifact into a header part (`.s.bif` interface) written at the end
of the header pass and an implementation part written at the latch, so that
importers can start before this module's bodies finish. That split is the
cross-process form of §1.3 and is what turns the Atlas chain into ~0.75 s.
Gate: `koch bootic` fixed point, Atlas/Nimbus cold and warm timings.

**Stage 7 — overlap header pass and bodies** (the reader/writer lock under
contention), VM ownership step 2 (handoff). Optional; measure first.

## 6. Open questions

1. **Thread count and placement.** One global pool sized to the machine, with
   the header threads of the modules being compiled as the producers? Or one
   pool per `nim m` process under IC (stage 4–5), which wastes cores on the
   chain? Stage 6 answers this structurally; until then a per-process pool.
2. **Arena width.** 2^18 ids per unit and 8192 units per module are guesses;
   `system.nim` has 1161 bodies, `cgen` 590. A module that overflows either
   falls back to one worker — acceptable, or should the item id widen to 64
   bits (it is packed with the module id into an `int` in `itemids.nim:92`)?
3. **`getImpl` on a `Running` unit** (§4.6 step 2): implement handoff, or
   forbid parallel bodies in modules that do it? A survey of the external
   packages for `getImpl` inside proc bodies of the same module would settle
   it.
4. **Instantiation visibility** (§4.10.3): is "complete top-level scope" the
   rule you want, or should instantiation from a body keep the body's
   `visibleUpTo` and accept that the *first* instantiator's key decides? The
   latter is what today does, and it is only deterministic under the key
   ordering if the instance is *always* created by its lowest-key requester,
   which requires creating instances lazily after all bodies have been semmed
   — a much bigger change to `sigmatch`.
5. **`nimsuggest` / `nim check` / `nim doc` / JS** stay on the one-worker path;
   is that acceptable for `nim check` (it is where most latency complaints come
   from)? The header/body split helps `check` even sequentially: errors in
   bodies are found per body, so `--errorMax` can stop earlier.
