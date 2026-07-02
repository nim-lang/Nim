#
#
#           The Nim Compiler
#        (c) Copyright 2025 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## NIF-based C/C++ code generator backend.
##
## This module implements C code generation from precompiled NIF files.
## It traverses the module dependency graph starting from the main module
## and generates C code for all reachable modules.
##
## Usage:
##   1. Compile modules to NIF: nim m mymodule.nim
##   2. Generate C from NIF: nim nifc myproject.nim

import std/[intsets, tables, sets, os, algorithm, syncio, times, strutils]

when defined(nimPreviewSlimSystem):
  import std/assertions

import ast, options, lineinfos, modulegraphs, cgendata, cgen,
  pathutils, extccomp, msgs, modulepaths, idents, types, ast2nif, typekeys,
  cnif, icmodnames
from cgmeth import generateIfMethodDispatchers
from transf import transformBody
from injectdestructors import injectDestructorCalls
import ic / replayer

proc systemNifSuffix(conf: ConfigRef): string =
  ## The system module's NIF suffix, derived from `system.nim`'s path EXACTLY as
  ## the frontend derives it (deps.nim's `toPair` on `libpath/system.nim`), so the
  ## backend loads the very `.s.bif` the frontend wrote. It must NOT be a constant:
  ## `moduleSuffix` (icmodnames) now hashes the absolute path, so the system suffix
  ## is install-dependent (was hardcoded `sysma2dyk`, valid only for the old
  ## relative-path scheme where `system.nim` always relativized to `system.nim`).
  moduleSuffix((conf.libpath / RelativeFile"system.nim").string,
               cast[seq[string]](conf.searchPaths))

proc loadModuleDependencies(g: ModuleGraph; mainFileIdx: FileIndex;
                            nifFiles: var seq[string];
                            depFlags: set[LoadFlag] = {LoadFullAst}): seq[PrecompiledModule] =
  ## Traverse the module dependency graph using a stack.
  ## Returns all modules that need code generation, in dependency order.
  ##
  ## The main module is always loaded with its full AST (it is the codegen
  ## target). `depFlags` governs the rest: the whole-program backend needs every
  ## module's full AST (it generates code for all of them), but a per-module
  ## stage codegens only one target, so it loads the others interface-only
  ## (`depFlags = {}`) — the interface, hooks, methods and the `(replay ...)`
  ## directives are loaded regardless of `LoadFullAst`, and demanded bodies are
  ## fetched lazily from the kept-open stream, so the per-module proc-body ASTs
  ## (the bulk of the memory) are never materialized for non-targets.
  # The main module is loaded by its SOURCE FileIndex, but its serialized
  # symbols carry the module's NIF suffix. Pre-alias the suffix to the source
  # index so that `registerNifSuffix` does not allocate a second FileIndex for
  # the same module, which would split its codegen across two C translation
  # units (top-level globals in one, procs in the other → undeclared symbols).
  g.config.m.filenameToIndexTbl[cachedModuleSuffix(g.config, mainFileIdx)] = mainFileIdx
  let mainModule = moduleFromNifFile(g, mainFileIdx, {LoadFullAst})
  nifFiles.add toNifFilename(g.config, mainFileIdx)

  var stack: seq[ModuleSuffix] = @[]
  result = @[]

  if mainModule.module != nil:
    incl mainModule.module.flagsImpl, sfMainModule
    for dep in mainModule.deps:
      stack.add dep

  var visited = initHashSet[string]()

  while stack.len > 0:
    let suffix = stack.pop()

    if not visited.containsOrIncl(suffix.string):
      var isKnownFile = false
      let fileIdx = g.config.registerNifSuffix(suffix.string, isKnownFile)
      let precomp = moduleFromNifFile(g, fileIdx, depFlags)
      if precomp.module != nil:
        result.add precomp
        nifFiles.add toNifFilename(g.config, fileIdx)
        for dep in precomp.deps:
          if not visited.contains(dep.string):
            stack.add dep
      else:
        assert false, "Recompiling module is not implemented."

  if mainModule.module != nil:
    result.add mainModule

proc setupNifBackendModule(g: ModuleGraph; module: PSym): BModule =
  ## Set up a BModule for code generation from a NIF module.
  if g.backend == nil:
    g.backend = cgendata.newModuleList(g)
  result = cgen.newModule(BModuleList(g.backend), module, g.config, idGeneratorForBackend(module))

proc isMetaIter(t: PType, closure: RootRef): bool =
  # openArray/varargs hooks are sem bookkeeping: no real flow ever demands
  # them, and generating one pollutes the TU's type cache with a struct
  # descriptor for what must remain a (ptr, len) parameter expansion
  t.kind in tyMetaTypes + {tyTyped, tyUntyped, tyNone, tyVarargs, tyOpenArray}

proc finishModule(g: ModuleGraph; bmod: BModule) =
  # Finalize the module (this adds it to modulesClosed)
  # Create an empty stmt list as the init body - genInitCode in writeModule will set it up properly
  let initStmt = newNode(nkStmtList)
  finalCodegenActions(g, bmod, initStmt)

  # NB: the method dispatchers are emitted in `emitMethodDispatchers`,
  # between the module loop and this finish loop: their bodies demand the
  # method definitions, which can in turn demand definitions from modules
  # the backend never loaded — and a TU demand-created during the LAST
  # finishModule call would miss `modulesClosed` and never be written.

proc emitMethodDispatchers(g: ModuleGraph) =
  ## Synthesizes the method dispatcher bodies from the replayed dispatch
  ## buckets (`registerLoadedMethod`) and emits their definitions into the
  ## main TU. Main is regenerated on every run, so a dispatcher — whose
  ## body enumerates the whole program's method set — can never go stale
  ## inside a cached TU; cross-TU callers prototype it (see genProcLvl3).
  let bl = BModuleList(g.backend)
  var mainMod: BModule = nil
  for m in bl.mods:
    if m != nil and m.module != nil and sfMainModule in m.module.flags:
      mainMod = m
      break
  if mainMod == nil: return
  generateIfMethodDispatchers(g, mainMod.idgen)
  for disp in getDispatchers(g):
    if not containsOrIncl(mainMod.declaredThings, disp.id):
      genProcLvl3(mainMod, disp)

proc signatureHasMetaType(t: PType; depth: int = 0): bool =
  ## Whether a routine signature mentions a compile-time/meta element type
  ## (`typed`/`untyped` — e.g. `echo`'s `varargs[typed]` — typedesc, static,
  ## generic param). Such routines are expanded at their call sites and never
  ## emitted standalone, so the per-module owned-routine seeding must skip them
  ## (`getTypeDescAux(tyTyped)` otherwise). `tfHasMeta` alone misses the varargs
  ## element case, hence the explicit scan.
  result = false
  if t == nil or depth > 8: return false
  if t.kind == tyGenericBody:
    # The uninstantiated template carried as a `tyGenericInst`'s first child
    # always mentions its `tyGenericParam` placeholders, but the instance
    # itself is fully concrete (e.g. `var CountTable[SigHash]`). Descending
    # here would wrongly flag every routine with a generic-instance parameter
    # as meta and drop it from the owned-routine seeding -> undefined symbols
    # at link (its only definer never emits it).
    return false
  if t.kind == tyStatic:
    # A RESOLVED static value (the `256` in `MDigest[256]`, the `N` in
    # `HashList[T, N]`, …) is carried as a `tyStatic` node inside the otherwise
    # fully-concrete `tyGenericInst`, but it is NOT meta: the routine is a normal
    # runtime routine the owner must emit. Only an UNRESOLVED `static T` parameter
    # (no bound value, `t.n == nil`) is meta. Without this, every routine whose
    # signature touches a `static`-parameterized generic instance (the bulk of
    # the SSZ/`MDigest` API) is dropped from the owned-routine seeding and ends up
    # an undefined reference at link (mirrors the tyGenericBody case above).
    return t.n == nil
  if t.kind in {tyTyped, tyUntyped, tyTypeDesc, tyGenericParam,
                tyAnything, tyFromExpr, tyError}:
    return true
  for k in t.kids:
    if signatureHasMetaType(k, depth + 1): return true

proc ownsRuntimeRoutine(s: PSym; modPos: int): bool =
  ## A concrete, non-generic, runtime routine with a real body, OWNED by the
  ## module at `modPos`. Shared by the `cg` stage's owned-routine seeding (so a
  ## routine called only from other modules is still emitted by somebody) and
  ## the `lower` stage's owned-routine enumeration, so both stages see exactly
  ## the same set. The exclusions:
  ## - nested/closure procs (owner is a proc, not a module): emitted via their
  ##   enclosing routine's lambda-lifting, never standalone;
  ## - generic instances (`sfFromGeneric`): emitted by demand, deduped by merge;
  ## - `importc`/`compileTime`/`error`/forward sentinels and meta signatures:
  ##   not real codegen targets.
  ## - method DISPATCHERS (`sfDispatcher`): their bodies are (re)synthesized into
  ##   the main TU by `emitMethodDispatchers`/`generateIfMethodDispatchers`, never
  ##   per module. A dispatcher is a `copySym` clone of the method that shares the
  ##   method's body sub-tree (incl. its closure iterator); transforming it here
  ##   would lambda-lift that SHARED iterator a SECOND time under a different owner
  ##   identity, baking a conflicting `up` field → "up references do not agree"
  ##   (the divergence is impossible in non-IC, where the dispatcher body is empty
  ##   at lift time). So a dispatcher is never an owned runtime routine.
  ## A `{.closure.}` iterator IS a standalone runtime routine (unlike an inline
  ## iterator, which is expanded at each call site) and must be emitted by its
  ## owner — else a cross-module `for` over it links to nothing.
  ##
  ## Generic INSTANCES (`sfFromGeneric`) are NEVER an owned runtime routine — not
  ## in `cg` and not in the `lower` stage. They are demanded by the backend's
  ## emit-everywhere path and deduped by `merge` (content C name); the frontend
  ## materialises them through the `(offer)` mechanism. The `lower` stage must
  ## not transform an instance: a not-fully-concrete instance (a closure factory
  ## over a `static` param, or a `$`/`=` op instance whose body resolves only at
  ## its further-specialised use sites) still carries unresolved overload choices
  ## and crashes `transformBody` (empty-`namePos` lambda, nil-typed const-fold).
  s.itemId.module == modPos and
  (s.kind in {skProc, skFunc, skConverter, skMethod} or
   (s.kind == skIterator and s.typ != nil and s.typ.callConv == ccClosure)) and
  s.skipGenericOwner != nil and s.skipGenericOwner.kind == skModule and
  s.magic == mNone and
  sfFromGeneric notin s.flags and
  sfDispatcher notin s.flags and
  {sfForward, sfImportc, sfCompileTime, sfError} * s.flags == {} and
  s.typ != nil and not signatureHasMetaType(s.typ) and
  s.ast != nil and s.ast.safeLen > bodyPos and
  s.ast[genericParamsPos].kind == nkEmpty
  # NOTE: an `nkEmpty` body is NOT a disqualifier. A concrete, owned, non-
  # forward/-importc/-magic routine whose body folds to nothing is still a real
  # definition the owner must emit (`void f(void){}`), exactly as whole-program
  # cgen does — else a cross-module caller links to nothing. This bites e.g.
  # Nimbus' `extras.incInternalErrors`, a plain `proc` whose sole statement is a
  # metrics-counter `.inc()` that the `metrics` library expands to a no-op when
  # the importing tool (ncli) builds with `-u:metrics`; the body is then a bare
  # `nkEmpty`, but `state_transition_epoch` still calls it. Forward declarations
  # (the other empty-body case) carry `sfForward` and are excluded above.

proc generateCodeForModule(g: ModuleGraph; precomp: PrecompiledModule) =
  ## Generate C code for a single module.
  let moduleId = precomp.module.position
  var bmod = BModuleList(g.backend).mods[moduleId]
  if bmod == nil:
    bmod = setupNifBackendModule(g, precomp.module)

  # Apply the module's recorded C compile/link directives (passl/passc/...)
  # before generating code: the link step needs them (e.g. math's -lm).
  replayBackendActions(g, precomp.module, precomp.topLevel)

  # Generate code for the module's top-level statements
  if precomp.topLevel != nil:
    cgen.genTopLevelStmt(bmod, precomp.topLevel)

  # Per-module backend: emit the bodies of the routines this module OWNS, not
  # only the ones its top-level happens to demand. Procs are serialized as lazy
  # `(sd ...)` defs (never as `nkProcDef` statements), so `genTopLevelStmt` never
  # reaches them; a routine called only from *other* modules would otherwise be
  # emitted by nobody, because every module now merely prototypes its foreign
  # callees instead of funnelling their bodies (see `cgen.emitsBodyInThisModule`).
  # The merge stage's DCE drops whatever turns out globally dead.
  if g.config.cmd == cmdNifC and g.config.icBackendStage == "cg":
    let modPos = precomp.module.position
    for s in moduleSymbolStubs(ast.program, FileIndex modPos):
      if ownsRuntimeRoutine(s, modPos):
        requestProcDef(bmod, s)

proc loadBackendModules(g: ModuleGraph; mainFileIdx: FileIndex):
    tuple[modules: seq[PrecompiledModule], precompSys: PrecompiledModule,
          nifFiles: seq[string]] =
  ## Shared by the per-module `cg` and `emit` stages: load system + the main
  ## module's whole import closure and set up a `BModule` for each, so every
  ## type/symbol resolves and `getCFile` yields the same path both stages use.
  ## The main module is loaded by its source index (its NIF suffix is aliased to
  ## it in `loadModuleDependencies`), so it gets exactly one `BModule`.
  ##
  ## Only the main module — the codegen target of the stages that use this — is
  ## loaded with its full AST; every other module is loaded interface-only so
  ## the whole program's proc bodies are not materialized into this process (that
  ## was ~1.8 GB for the compiler's main `cg`). The `link` stage codegens nothing
  ## and only needs each module's `(replay ...)` directives, which load anyway.
  resetForBackend(g)
  var isKnownFile = false
  let systemFileIdx = registerNifSuffix(g.config, systemNifSuffix(g.config), isKnownFile)
  g.config.m.systemFileIdx = systemFileIdx
  var precompSys = moduleFromNifFile(g, systemFileIdx, {AlwaysLoadInterface})
  g.systemModule = precompSys.module
  if precompSys.module != nil:
    # The precompiled-load path does not restore `sfSystemModule` (mirror of the
    # `sfMainModule` re-add above). `registerReusedModuleToMain` keys on it to put
    # the system module's init right after its datInit AND to emit
    # `initStackBottomWith` into `mainDatInit` — so that the main thread's stack
    # bottom is set before any module's init runs. Without the flag the system
    # init is mis-routed into the regular `otherModsInit` bucket and
    # `initStackBottomWith` is never registered, so a GC cycle during a module's
    # init (under refc) scans the stack with a nil bottom and crashes.
    incl precompSys.module.flagsImpl, sfSystemModule
  var nifFiles: seq[string] = @[toNifFilename(g.config, systemFileIdx)]
  var modules = loadModuleDependencies(g, mainFileIdx, nifFiles, depFlags = {})
  # loadModuleDependencies traverses the project's import closure and stops at
  # system. The whole-program backend then demand-loads system's own closure
  # (locks, allocators, threads, …) during codegen; the per-module backend
  # instead makes every one of those a first-class cg/emit target, so load that
  # closure here too — otherwise `findTargetModule` cannot resolve their suffix.
  block:
    var visited = initHashSet[string]()
    visited.incl systemNifSuffix(g.config)
    for m in modules:
      visited.incl cachedModuleSuffix(g.config, FileIndex m.module.position)
    var stack: seq[ModuleSuffix] = @[]
    if precompSys.module != nil:
      for dep in precompSys.deps: stack.add dep
    while stack.len > 0:
      let suffix = stack.pop()
      if not visited.containsOrIncl(suffix.string):
        var isKnown = false
        let fileIdx = registerNifSuffix(g.config, suffix.string, isKnown)
        let precomp = moduleFromNifFile(g, fileIdx, {})
        if precomp.module != nil:
          modules.add precomp
          nifFiles.add toNifFilename(g.config, fileIdx)
          for dep in precomp.deps: stack.add dep
  flushMethodReplays(g)
  for m in modules:
    discard setupNifBackendModule(g, m.module)
  if precompSys.module != nil:
    discard setupNifBackendModule(g, precompSys.module)
  result = (modules, precompSys, nifFiles)

proc loadDepClosure(g: ModuleGraph; targetSuffix: string):
    tuple[modules: seq[PrecompiledModule], precompSys: PrecompiledModule,
          target: PrecompiledModule] =
  ## Per-module `cg`/`emit` for a NON-main target: load system + the target
  ## module + the target's transitive import closure ONLY — not the whole
  ## program. This is the "process the one file it is passed" model (à la
  ## Nimony's `hexer c file.nif`): the foreign symbols the target's codegen
  ## demands are loaded lazily by `ast2nif.moduleId`, which opens any referenced
  ## module's NIF index on first touch, so a body in a not-loaded module still
  ## resolves. The closure is loaded as full `BModule`s only so that the
  ## incidental `g.mods[pos]` accesses during codegen resolve; system's own
  ## internal closure (allocators, locks, …) is included because a target's
  ## emit-everywhere codegen can demand those without importing them directly.
  ##
  ## The whole program is no longer loaded in this process, which is what bounds
  ## per-process memory under nifmake's parallel fan-out (the main module's `cg`,
  ## which still loads everything for NimMain's init list and the method
  ## dispatchers, runs essentially alone since every other `.c.nif` precedes it).
  resetForBackend(g)
  var isKnownFile = false
  let systemFileIdx = registerNifSuffix(g.config, systemNifSuffix(g.config), isKnownFile)
  g.config.m.systemFileIdx = systemFileIdx
  let precompSys = moduleFromNifFile(g, systemFileIdx, {AlwaysLoadInterface})
  g.systemModule = precompSys.module

  var modules: seq[PrecompiledModule] = @[]
  var visited = initHashSet[string]()
  visited.incl systemNifSuffix(g.config)

  # Only the target is codegen'd, so only it needs its full AST; the closure is
  # loaded interface-only (demanded bodies come lazily from the kept-open
  # streams), which is what keeps a per-module process light under parallel fan-out.
  var isKnown = false
  let targetIdx = registerNifSuffix(g.config, targetSuffix, isKnown)
  let target = moduleFromNifFile(g, targetIdx, {LoadFullAst})
  visited.incl targetSuffix

  var stack: seq[ModuleSuffix] = @[]
  if target.module != nil:
    modules.add target
    for dep in target.deps: stack.add dep
  if precompSys.module != nil:
    for dep in precompSys.deps: stack.add dep
  while stack.len > 0:
    let suffix = stack.pop()
    if not visited.containsOrIncl(suffix.string):
      var isKnown2 = false
      let fileIdx = registerNifSuffix(g.config, suffix.string, isKnown2)
      let precomp = moduleFromNifFile(g, fileIdx, {})
      if precomp.module != nil:
        modules.add precomp
        for dep in precomp.deps: stack.add dep
  flushMethodReplays(g)
  for m in modules:
    discard setupNifBackendModule(g, m.module)
  if precompSys.module != nil:
    discard setupNifBackendModule(g, precompSys.module)
  result = (modules, precompSys, target)

proc findTargetModule(g: ModuleGraph; modules: seq[PrecompiledModule];
                      precompSys: PrecompiledModule; suffix: string): PrecompiledModule =
  ## The loaded module whose NIF suffix is `suffix` (the `--icBackendModule`
  ## value), or a nil module if none matches.
  result = PrecompiledModule(module: nil)
  for m in modules:
    if cachedModuleSuffix(g.config, FileIndex m.module.position) == suffix:
      return m
  if precompSys.module != nil and
      cachedModuleSuffix(g.config, FileIndex precompSys.module.position) == suffix:
    return precompSys

proc setNestedClosureBodies(g: ModuleGraph; idgen: IdGenerator; n: PNode;
                            owner: PSym; seen: var IntSet) =
  ## A closure routine nested in `owner` (the `:anonymous` proc lambda-lifting
  ## minted, plus any deeper nesting) gets its captured-var→env rewrite produced
  ## as part of the OWNER's `transformBody`. The nested proc is a module-indexed
  ## sym whose `.s.nif` sdef carries its PRE-lift body, so without help the whole
  ## module re-serializer would write that pre-lift body and cg would lose the
  ## capture mapping (it accesses `x` directly instead of `ClE_0->x0`). Walk the
  ## owner's transformed body and cache each nested closure's transformed body on
  ## its sym so `writeSymDef` serializes the lifted body into the routine's
  ## 2-way-body slot.
  if n == nil: return
  if n.kind == nkSym:
    let s = n.sym
    if s != nil and s.kind in routineKinds and s != owner and
        s.skipGenericOwner != nil and s.skipGenericOwner.kind != skModule and
        not seen.containsOrIncl(s.id):
      # Covers ALL nested routines, not only ccClosure ones. A NIMCALL nested proc
      # the async transform mints (e.g. workNimAsyncContinue) already has its
      # lifted body set by the OWNER's transformBody, but it is NOT in the owned
      # loop (owner is a proc, not the module). Without injecting it HERE it is
      # serialized transform-only; cg loads it (wasLoaded) and skips injection, so
      # a closure-env store stays a raw field assign with no incref -> the env is
      # freed before the async callback runs -> "yielded nil". `seen` (shared
      # across the owned loop) injects each routine exactly once.
      if s.ast != nil and getBody(g, s).kind != nkEmpty:
        # Only ccClosure routines are safe to `transformBody` standalone here; a
        # nimcall nested proc already has its lifted body from the owner's lift,
        # and transforming an arbitrary nested routine with no cached body crashes
        # (not in a standalone-transformable state).
        let weTransformed = s.transformedBody == nil and
                            s.typ != nil and s.typ.callConv == ccClosure
        if weTransformed:
          s.transformedBody = transformBody(g, idgen, s, {})
        if s.transformedBody != nil:
          # Inject destructors so cg loads a fully-lowered body and never rebuilds
          # (mirrors non-IC, which injects every nested proc separately). The
          # importer `n2` skField collision this used to trigger is fixed at the
          # NIF-naming layer (toNifSymName gives derived env fields a unique
          # disamb), so injecting ccClosure nested procs here is safe.
          if sfInjectDestructors in s.flags:
            s.transformedBody = injectDestructorCalls(g, idgen, s, s.transformedBody)
          setNestedClosureBodies(g, idgen, s.transformedBody, s, seen)
  else:
    for i in 0 ..< n.safeLen:
      setNestedClosureBodies(g, idgen, n[i], owner, seen)

proc reownFromTwin(n: PNode; twin, s: PSym) =
  ## Re-own to `s` every entity the frontend attributed to `s`'s forward-decl
  ## `twin` (found via the result's owner). lambda-lifting compares owners by
  ## reference, so a twin-owned `result` is rejected as `illegalCapture`
  ## ("'result' ... cannot be captured") and, once that is fixed, twin-owned
  ## locals go missing from `s`'s env ("environment misses: ..."). Both are
  ## pervasive on chronos `{.async.}` methods. Re-owning to `s` matches the
  ## single-sym non-IC case. `twin` is ONE specific sym, so only THIS routine's
  ## result-twin-owned entities match — re-owning entities of OTHER same-name
  ## twins proved too blunt (it disrupts env construction and reintroduces the
  ## very capture errors it should fix). `n.sym != s` guards self-ownership.
  if n == nil: return
  if n.kind == nkSym and n.sym != nil and n.sym != s and n.sym.owner == twin:
    setOwner(n.sym, s)
  for i in 0 ..< n.safeLen:
    reownFromTwin(n[i], twin, s)

proc generateLowerStage(g: ModuleGraph; mainFileIdx: FileIndex) =
  ## Per-module backend lowering (`--icBackendStage:lower --icBackendModule:<suffix>`):
  ## enumerate the routines this module OWNS and write them to `<module>.t.nif`.
  ## Eventually this transforms each owned routine once, in the owner's id space,
  ## so `cg` reads the result instead of re-deriving it (re-derivation per
  ## parallel `cg` process is the root of the closure-`:env` identity drift).
  ## Runs per module in parallel on the shallow backend dep-graph — NOT folded
  ## into the dense, mostly-serial sem stage.
  ##
  ## gate `newSymNode`'s lazy-type marking to the backend (see astdef) — the
  ## transform builds sym nodes off not-yet-typed stubs, exactly as the `cg`
  ## stage does.
  nifcBackendActive = true
  let mainSuffix = cachedModuleSuffix(g.config, mainFileIdx)
  let targetIsMain = g.config.icBackendModule.len == 0 or
                     g.config.icBackendModule == mainSuffix
  var modules: seq[PrecompiledModule]
  var precompSys: PrecompiledModule
  var target: PrecompiledModule
  if targetIsMain:
    var nifFiles: seq[string]
    (modules, precompSys, nifFiles) = loadBackendModules(g, mainFileIdx)
    if modules.len == 0:
      rawMessage(g.config, errGenerated,
        "Cannot load NIF file for main module: " & toFullPath(g.config, mainFileIdx))
      return
    target = findTargetModule(g, modules, precompSys, g.config.icBackendModule)
  else:
    (modules, precompSys, target) = loadDepClosure(g, g.config.icBackendModule)
  if target.module == nil:
    rawMessage(g.config, errGenerated,
      "per-module lowering: module not found for suffix: " & g.config.icBackendModule)
    return
  let modPos = target.module.position
  let tb = BModuleList(g.backend).mods[modPos]
  if tb == nil:
    rawMessage(g.config, errGenerated,
      "per-module lowering: no backend module for suffix: " & g.config.icBackendModule)
    return
  # Transform every owned routine ONCE in this single process's id space and
  # re-serialize the ENTIRE module as a proper indexed NIF (`writeLoweredModule`)
  # with the transformed bodies baked into the routine `(sd)` entries. `cg` loads
  # it through the normal module loader, so nested procs (incl. async state
  # machines) arrive as real defs with their lifted bodies — no re-derivation.
  # This single-writer-per-owner is what keeps closure-`:env` identity stable
  # across the parallel `cg` processes (re-derivation per process was the root of
  # the `:env` identity drift). `transformBody` with flags {} mirrors the cg call
  # (cgen.nim); `injectDestructorCalls` is NOT run here — it stays in `cg` on the
  # loaded body.
  #
  # `transformBody`/lambda-lifting LIFTS the closure env's type-bound ops
  # (`=destroy` etc.) into `g.opsLog`; snapshot its length so we serialize exactly
  # the ops THIS stage created (not those loaded from `.s.nif`).
  let opsLogStart = g.opsLog.len
  # Shared across the owned loop so a nested routine reachable from more than one
  # owner is transformed + destructor-injected EXACTLY once (double injection
  # would emit two `=destroy`/`=copy` runs).
  var seenNested = initIntSet()
  for s in moduleSymbolStubs(ast.program, FileIndex modPos):
    if ownsRuntimeRoutine(s, modPos):
      # REUSE path (`icReuseSemLowering` ON): a routine already transformed during
      # sem (CT eval / macro / VM transform) carries its lowered body in the
      # `.s.nif` slot (loaded into `transformedBody`) — don't re-transform it.
      # Default OFF: the slot is never loaded (see loadSymFromCursor), so
      # `transformedBody` is nil here and we always re-derive below. See
      # doc/ic_backend_simplify.md §6a/§6b.
      if icReuseSemLowering(g.config) and s.transformedBody != nil: continue
      # A routine serialized as a forward-decl + impl pair (writeSymDef's
      # "separate forward declaration and implementation") loads as TWO syms; the
      # impl `s` we transform here can carry body entities (`result`, locals,
      # nested routines) owned by its fwd-decl TWIN, not by `s`. lambda-lifting
      # compares owners by reference → `illegalCapture` rejects a twin-owned
      # `result` and the lifting pass can't find twin-owned locals in `s`'s env.
      # Pervasive on chronos `{.async.}` methods. Re-own them to `s`, matching the
      # single-sym non-IC case. Backend-only, so frontend effect/exception
      # inference is untouched.
      if s.ast != nil and s.ast.len > resultPos and
          s.ast[resultPos].kind == nkSym and s.ast[resultPos].sym.owner != s:
        reownFromTwin(s.ast, s.ast[resultPos].sym.owner, s)
      # Retain the transformed body on the sym so `writeSymDef` serializes it in
      # the routine's `(sd)` 2-way-body slot.
      s.transformedBody = transformBody(g, tb.idgen, s, {})
      # Run the destructor injection HERE so the `.t.bif` body is FULLY lowered:
      # `injectDestructorCalls` is demand-driven (it decides where destructors go
      # by move analysis) and LIFTS the type-bound ops it needs (e.g. a nested
      # closure env's `=destroy`) into `g.opsLog` — which the `hooks` collection
      # below then serializes. Done in `cg` instead, those ops were lifted per-cg
      # process, owned by nobody, and emitted as a prototype-only → undefined at
      # link (the `eqdestroy__c<n>` gap). cg must NOT re-inject a loaded body
      # (see genProcLvl3's `wasLoaded` gate) so this stays the single injection.
      if sfInjectDestructors in s.flags:
        s.transformedBody = injectDestructorCalls(g, tb.idgen, s, s.transformedBody)
      # Cache the lifted+injected body on nested ccClosure routines too, so a
      # module-indexed nested closure serializes its lifted (capture-rewritten,
      # destructor-injected) body.
      setNestedClosureBodies(g, tb.idgen, s.transformedBody, s, seenNested)
  # Collect the hooks this stage lifted, and transform each hook ROUTINE's body
  # too (it is itself lowered into NIFC). The hooks' `(sd)` + transformed body go
  # into the `.t.nif`; `cg` re-attaches them so `injectDestructorCalls` resolves
  # the loaded env's `=destroy`. Iterate to a fixpoint: a hook body can lift
  # further hooks (a field's `=destroy`).
  var hooks: seq[LogEntry] = @[]
  var i = opsLogStart
  while i < g.opsLog.len:
    let e = g.opsLog[i]
    if e.kind == HookEntry and e.sym != nil and e.sym.kind in routineKinds and
        e.sym.transformedBody == nil:
      hooks.add e
      # Transform the hook routine's body and cache it on the sym so `writeSymDef`
      # serializes it in the hook's `(sd)` transformed-body slot (`transformBody
      # {}` returns the body but does not cache it). Inject the hook's own
      # destructors here too (it can destroy fields/temporaries) so cg loads a
      # fully-lowered hook and never re-injects.
      e.sym.transformedBody = transformBody(g, tb.idgen, e.sym, {})
      if sfInjectDestructors in e.sym.flags:
        e.sym.transformedBody = injectDestructorCalls(g, tb.idgen, e.sym, e.sym.transformedBody)
    inc i
  # Re-serialize the whole module to its suffix-based `.t.nif` (the path
  # `toNifFilename` resolves for the cg/emit stages). `writeLoweredModule` seals
  # routines itself.
  let suffix = cachedModuleSuffix(g.config, FileIndex modPos)
  let wholeArtifact = toGeneratedFile(g.config, AbsoluteFile(suffix), ".t.bif").string
  writeLoweredModule(ast.program, g.config, target, hooks, wholeArtifact)
  if isDefined(g.config, "icDceCheck"):
    stderr.writeLine "[icLower] " & extractFilename(wholeArtifact) & " " &
      $hooks.len & " hooks"

proc visitDep(suffix: string;
              suffixToMod: Table[string, PrecompiledModule];
              visited: var HashSet[string]; bl: BModuleList;
              ordered: var seq[BModule]) =
  ## Post-order DFS over a module's import closure used to reconstruct the
  ## dependency (init) order: a dependency's init must be registered before its
  ## importer's. Appends each reachable non-main module's `BModule` to `ordered`.
  if visited.containsOrIncl(suffix): return
  let pm = suffixToMod.getOrDefault(suffix)
  if pm.module == nil: return
  for dep in pm.deps: # dependencies first (post-order)
    visitDep(dep.string, suffixToMod, visited, bl, ordered)
  if sfMainModule notin pm.module.flags:
    let bm = bl.mods[pm.module.position]
    if bm != nil: ordered.add bm

proc generateCgStage(g: ModuleGraph; mainFileIdx: FileIndex) =
  ## Per-module backend codegen (`--icBackendStage:cg --icBackendModule:<suffix>`):
  ## generate C for the single module named by `icBackendModule` and write only
  ## its `.c.nif` artifact (no merge, no `.c` render, no cc/link — those are
  ## separate nifmake rules).
  ##
  ## `findPendingModule` routes every demand into the target (emit-everywhere).
  ##
  ## A NON-main target loads only its own import closure (`loadDepClosure`); the
  ## whole program is no longer pulled into every parallel `cg` process. The main
  ## module still loads everything (`loadBackendModules`) because NimMain's init
  ## list and the method dispatchers are whole-program; its `cg` runs essentially
  ## alone (every other `.c.nif` precedes it), so it does not contend for memory.
  # gate `newSymNode`'s lazy-type marking to this stage only (see astdef)
  nifcBackendActive = true
  let mainSuffix = cachedModuleSuffix(g.config, mainFileIdx)
  let targetIsMain = g.config.icBackendModule.len == 0 or
                     g.config.icBackendModule == mainSuffix
  var modules: seq[PrecompiledModule]
  var precompSys: PrecompiledModule
  var target: PrecompiledModule
  if targetIsMain:
    var nifFiles: seq[string]
    (modules, precompSys, nifFiles) = loadBackendModules(g, mainFileIdx)
    if modules.len == 0:
      rawMessage(g.config, errGenerated,
        "Cannot load NIF file for main module: " & toFullPath(g.config, mainFileIdx))
      return
    # No whole-program DCE here: each module emits the routines it owns and the
    # MERGE stage recomputes the one program-wide live set across all `.c.nif`s.
    # Running a whole-program liveness pass over all ~260 NIFs in the main `cg`
    # would cost ~900 MB for a result the merge stage throws away.
    target = findTargetModule(g, modules, precompSys, g.config.icBackendModule)
  else:
    # No whole-program load, hence no whole-program DCE: the target emits its
    # full demanded closure and the merge stage drops what is globally dead.
    (modules, precompSys, target) = loadDepClosure(g, g.config.icBackendModule)
  if target.module == nil:
    rawMessage(g.config, errGenerated,
      "per-module codegen: module not found for suffix: " & g.config.icBackendModule)
    return

  # The `lower` stage already wrote each module's transformed bodies + lifted
  # hooks into its `.t.nif`, which the loaders above read directly (toNifFilename
  # resolves the `.t.nif`); transformed bodies arrive via loadSymFromCursor and
  # lifted hooks via moduleFromNifFile's registerLoadedHooks. Nothing to apply.
  generateCodeForModule(g, target)
  let bl = BModuleList(g.backend)
  # The main module also owns the whole-program method dispatchers + NimMain.
  if sfMainModule in target.module.flags:
    emitMethodDispatchers(g)
    # NimMain (generated when the main module is finished) must call every other
    # module's init/datInit. Those translation units are produced by their own
    # `cg` processes, so the calls are registered here from each `.c.nif` meta
    # head — which is why the main module's `cg` runs last, after every other
    # `.c.nif` exists. Modules without init code (no `.c.nif`) register nothing.
    #
    # The registration order IS the runtime init order, and it must be the
    # DEPENDENCY (post-order) order: an imported module's init has to run before
    # its importer's. The whole-program backend gets this for free — it iterates
    # `modulesClosed`, built in module-FINISH order (a post-order DFS over
    # imports). Iterating `bl.mods` by position is WRONG: an importer gets a
    # LOWER position than the modules it imports (its file is registered before
    # its `import` statements are processed), so position order runs importers
    # before their dependencies. That left chronicles' `topics_registry` — whose
    # init sets `mainThreadId` — running AFTER a module that calls `registerTopic`
    # from its own init, tripping the `getThreadId() == mainThreadId` assert at
    # startup. So reconstruct the post-order DFS over the import closure here.
    #
    # NOTE: this is deliberately a SEPARATE traversal rather than reusing the
    # module LOAD order — the per-module backend's C emit is sensitive to load
    # order (it determines the main TU's header composition), so the loader must
    # keep its existing order and the init order is derived independently here.
    var suffixToMod = initTable[string, PrecompiledModule]()
    for pm in modules:
      if pm.module != nil:
        suffixToMod[cachedModuleSuffix(g.config, FileIndex pm.module.position)] = pm
    if precompSys.module != nil:
      suffixToMod[cachedModuleSuffix(g.config, FileIndex precompSys.module.position)] = precompSys
    var visited = initHashSet[string]()
    var ordered: seq[BModule] = @[]
    # System (and its include/import closure) must initialize FIRST: its init
    # runs `initGC()` (top-level code in `threadimpl`, included into system),
    # and every other module's init may allocate — an allocation before the GC
    # heap is set up triggers a collection over an uninitialized region and
    # crashes (e.g. nim-metrics' `newRegistry` in its init). System is the
    # IMPLICIT universal import and appears in no module's explicit `deps`, so a
    # DFS rooted at main never reaches it; seed the traversal from system first.
    if precompSys.module != nil:
      visitDep(cachedModuleSuffix(g.config, FileIndex precompSys.module.position),
               suffixToMod, visited, bl, ordered)
    # Then order the whole import closure rooted at the main module; main itself
    # is excluded above (its init body becomes NimMain).
    for pm in modules:
      if pm.module != nil and sfMainModule in pm.module.flags:
        visitDep(cachedModuleSuffix(g.config, FileIndex pm.module.position),
                 suffixToMod, visited, bl, ordered)
    # Defensive: any loaded module not reachable from main's import closure
    # (demand-loaded system internals) keeps its init registered, appended last
    # — nothing imports it, so its relative order does not matter.
    for m in bl.mods:
      if m != nil and sfMainModule notin m.module.flags:
        let suffix = cachedModuleSuffix(g.config, FileIndex m.module.position)
        if not visited.containsOrIncl(suffix):
          ordered.add m
    for m in ordered:
      let heads = readCnifHeads(getCFile(m).string & ".nif")
      registerReusedModuleToMain(bl, m, heads.initRequired, heads.datInitRequired)
  let tb = bl.mods[target.module.position]
  if tb != nil:
    finishModule(g, tb)

  # Writes only the target's `.c.nif` (every other loaded module's TU is empty,
  # so `cgenWriteModules` emits no artifact for it). cc/link are NOT run here.
  cgenWriteModules(g.backend, g.config)

  # Always leave a `.c.nif` for the target, even when the module has no code
  # (a leaf library whose procs all emit into their users): the per-module
  # nifmake graph declares one `.c.nif` output per `cg` rule, so a missing one
  # would re-fire the rule forever. An empty artifact renders to an empty `.c`.
  if tb != nil:
    let artifact = getCFile(tb).string & ".nif"
    if not fileExists(artifact):
      writeCnifArtifact("", artifact,
        semmedNif = toNifFilename(g.config, FileIndex target.module.position),
        moduleBase = $getSomeNameForModule(tb))

proc generateMergeStage(g: ModuleGraph) =
  ## Per-module backend merge (`--icBackendStage:merge`): a pure artifact
  ## operation, no module graph loaded. Reads every `.c.nif` the `cg` stages
  ## wrote, computes the global live set and — for each `'u'`-flagged unique
  ## definition that several `cg` processes emitted (emit-everywhere) — the one
  ## artifact allowed to embed its body, and writes the decision the `emit`
  ## stages consume — the cross-process replacement for what used to be
  ## in-process first-claimant/DCE coordination.
  let nimcache = getNimcacheDir(g.config).string
  var files: seq[string] = @[]
  for artifact in walkFiles(nimcache / "*.c.nif"):
    files.add artifact
  sort files
  let decision = computeMergeDecision(files)
  if decision.broken:
    rawMessage(g.config, errGenerated,
      "per-module backend merge: a .c.nif artifact is missing or unparsable")
    return
  writeMergeDecision(nimcache / MergeDecisionFile, decision)
  if isDefined(g.config, "icDceCheck"):
    stderr.writeLine "[icMerge] artifacts: " & $files.len &
      " live: " & $decision.live.len & " defs: " & $decision.defs &
      " liveDefs: " & $decision.liveDefs & " owned: " & $decision.owners.len

proc generateEmitStage(g: ModuleGraph; mainFileIdx: FileIndex) =
  ## Per-module backend emit (`--icBackendStage:emit --icBackendModule:<suffix>`):
  ## render the target module's final `.c` from its `.c.nif` and the merge
  ## decision. Loads the target the same way `cg` does so `getCFile` returns the
  ## identical path `cg` wrote to (the main module's source-vs-suffix aliasing in
  ## particular); no codegen runs. A non-main target loads only its own closure
  ## (`loadDepClosure`) so emit, like `cg`, stays bounded under parallel fan-out.
  let mainSuffix = cachedModuleSuffix(g.config, mainFileIdx)
  let targetIsMain = g.config.icBackendModule.len == 0 or
                     g.config.icBackendModule == mainSuffix
  var modules: seq[PrecompiledModule]
  var precompSys: PrecompiledModule
  var target: PrecompiledModule
  if targetIsMain:
    var nifFiles: seq[string]
    (modules, precompSys, nifFiles) = loadBackendModules(g, mainFileIdx)
    if modules.len == 0:
      rawMessage(g.config, errGenerated,
        "Cannot load NIF file for main module: " & toFullPath(g.config, mainFileIdx))
      return
    target = findTargetModule(g, modules, precompSys, g.config.icBackendModule)
  else:
    (modules, precompSys, target) = loadDepClosure(g, g.config.icBackendModule)
  if target.module == nil:
    rawMessage(g.config, errGenerated,
      "per-module emit: module not found for suffix: " & g.config.icBackendModule)
    return
  let decision = readMergeDecision(getNimcacheDir(g.config).string / MergeDecisionFile)
  if decision.broken:
    rawMessage(g.config, errGenerated,
      "per-module emit: missing or unparsable merge decision " & MergeDecisionFile)
    return
  let bmod = BModuleList(g.backend).mods[target.module.position]
  let cfile = getCFile(bmod).string
  let artifact = cfile & ".nif"
  var dropped = 0
  let code = renderCFromArtifact(artifact, decision, extractFilename(artifact), dropped)
  # Write the `.c` content-stably. `merge` re-runs on any edit and bumps the
  # decision file's mtime, so nifmake re-fires every `emit` (the filter is cheap);
  # but the FILTERED output is usually byte-identical for modules unaffected by
  # the edit. Rewriting it unconditionally would bump every `.c`'s mtime and make
  # `callCCompiler` recompile every `.o`. Writing only on a real change preserves
  # the mtime, so the C compiler recompiles exactly the modules whose `.c` changed
  # — the same DCE model as Nimony's. Safe here (unlike a content-stable merge
  # decision): a `.c` is a per-module LEAF consumed only by the C compiler's own
  # up-to-date check, not a shared prerequisite in nifmake's mtime ordering.
  if not fileExists(cfile) or readFile(cfile) != code:
    writeFile(cfile, code)
  if isDefined(g.config, "icDceCheck"):
    stderr.writeLine "[icEmit] " & extractFilename(cfile) & " dropped " &
      $dropped & " bodies (" & $code.len & " bytes)"

proc generateLinkStage(g: ModuleGraph; mainFileIdx: FileIndex) =
  ## Per-module backend link (`--icBackendStage:link`): the `emit` stages have
  ## written every module's `.c`; register them and run the C compiler + linker
  ## once via `extccomp.callCCompiler` (which parallelizes the per-file cc and
  ## skips up-to-date objects itself). No codegen runs — the graph is loaded only
  ## so `getCFile` yields each module's emitted `.c` path.
  let (modules, precompSys, _) = loadBackendModules(g, mainFileIdx)
  if modules.len == 0:
    rawMessage(g.config, errGenerated,
      "Cannot load NIF file for main module: " & toFullPath(g.config, mainFileIdx))
    return
  # The per-module `cg` processes each collect their module's C compile/link
  # directives (`{.passL: "-lm".}` etc.) via `replayBackendActions`, but those
  # live in the cg process and never reach this separate link process. Re-collect
  # every loaded module's directives here so the final `callCCompiler` sees them
  # (without this, math's `-lm` is lost → undefined `floor`/`pow`/… at link).
  for m in modules:
    replayBackendActions(g, m.module, m.topLevel)
  if precompSys.module != nil:
    replayBackendActions(g, precompSys.module, precompSys.topLevel)
  let bl = BModuleList(g.backend)
  var addedCFiles = initHashSet[string]()
  for m in bl.mods:
    if m != nil:
      let cfile = getCFile(m)
      # Only modules that are their own cg/emit target produced a `.c`; the rest
      # (extra members of system's closure that no build rule targets) had their
      # code emit-everywhere'd into the targets, so they have no file to compile.
      if not fileExists(cfile.string): continue
      addedCFiles.incl extractFilename(cfile.string)
      var cf = Cfile(nimname: m.module.name.s, cname: cfile,
                     obj: completeCfilePath(g.config, toObjFile(g.config, cfile)),
                     flags: {})
      # `addExternalFileToCompile` (not `addFileToCompile`) gates each `.c` on its
      # SHA1 footprint: an unchanged `.c` keeps its `.o` and is flagged Cached, so
      # `callCCompiler` skips its compile but still links the existing object. This
      # is what makes a localized edit recompile only the handful of `.c`s the
      # `emit` stage actually rewrote, instead of every object every time — the
      # final piece of per-module backend incrementality after the merge barrier.
      addExternalFileToCompile(g.config, cf)
  # deps.nim's static scanner can keep a CONDITIONALLY-imported module as a build
  # node (e.g. `net`'s `when defineSsl: import openssl`, or a `when defined(os)`
  # import) that the NIF-`deps` walk above never reaches because the condition is
  # off. Such a node still emitted a `.c`, and it can OWN a live generic instance
  # that a REACHABLE module reuses (openssl owns `toHex[uint8]`, reused by
  # `strutils.escape`) — so its body must be at link or that reference is
  # undefined. Link every emitted `.c` the merge decision says OWNS a LIVE symbol;
  # a node that owns nothing live (a Windows-only winsock node on Linux) is
  # correctly skipped.
  block:
    let nimcache = getNimcacheDir(g.config).string
    let decision = readMergeDecision(nimcache / MergeDecisionFile)
    if not decision.broken:
      var liveOwners = initHashSet[string]()
      for cname, owner in decision.owners:
        if owner.endsWith(".c.nif") and cname in decision.live:
          liveOwners.incl owner
      for owner in liveOwners:
        let cbase = owner[0 ..< owner.len - ".nif".len]  # "@m….nim.c.nif" -> ".c"
        if addedCFiles.containsOrIncl(cbase): continue
        let cfile = AbsoluteFile(nimcache / cbase)
        if not fileExists(cfile.string): continue
        var cf = Cfile(nimname: cbase, cname: cfile,
                       obj: completeCfilePath(g.config, toObjFile(g.config, cfile)),
                       flags: {})
        addExternalFileToCompile(g.config, cf)
  if g.config.cmd != cmdTcc:
    extccomp.callCCompiler(g.config)

proc generateCode*(g: ModuleGraph; mainFileIdx: FileIndex) =
  ## Main entry point for NIF-based C code generation.
  ## Traverses the module dependency graph and generates C code.
  if g.config.icBackendStage == "lower":
    generateLowerStage(g, mainFileIdx)
    return
  elif g.config.icBackendStage == "cg":
    generateCgStage(g, mainFileIdx)
    return
  elif g.config.icBackendStage == "merge":
    generateMergeStage(g)
    return
  elif g.config.icBackendStage == "emit":
    generateEmitStage(g, mainFileIdx)
    return
  elif g.config.icBackendStage == "link":
    generateLinkStage(g, mainFileIdx)
    return
  else:
    rawMessage(g.config, errGenerated,
      "the per-module NIF backend requires --icBackendStage:lower|cg|merge|emit|link")
