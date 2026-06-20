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
  cnif
from cgmeth import generateIfMethodDispatchers
from transf import transformBody
from lambdalifting import getEnvParam, addHiddenParam, paramName
import ic / replayer

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
  if t.kind in {tyTyped, tyUntyped, tyTypeDesc, tyStatic, tyGenericParam,
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
  ## A `{.closure.}` iterator IS a standalone runtime routine (unlike an inline
  ## iterator, which is expanded at each call site) and must be emitted by its
  ## owner — else a cross-module `for` over it links to nothing.
  s.itemId.module == modPos and
  (s.kind in {skProc, skFunc, skConverter, skMethod} or
   (s.kind == skIterator and s.typ != nil and s.typ.callConv == ccClosure)) and
  s.skipGenericOwner != nil and s.skipGenericOwner.kind == skModule and
  s.magic == mNone and
  sfFromGeneric notin s.flags and
  {sfForward, sfImportc, sfCompileTime, sfError} * s.flags == {} and
  s.typ != nil and not signatureHasMetaType(s.typ) and
  s.ast != nil and s.ast.safeLen > bodyPos and
  s.ast[genericParamsPos].kind == nkEmpty and
  s.ast[bodyPos].kind != nkEmpty

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
  let systemFileIdx = registerNifSuffix(g.config, "sysma2dyk", isKnownFile)
  g.config.m.systemFileIdx = systemFileIdx
  var precompSys = moduleFromNifFile(g, systemFileIdx, {AlwaysLoadInterface})
  g.systemModule = precompSys.module
  var nifFiles: seq[string] = @[toNifFilename(g.config, systemFileIdx)]
  var modules = loadModuleDependencies(g, mainFileIdx, nifFiles, depFlags = {})
  # loadModuleDependencies traverses the project's import closure and stops at
  # system. The whole-program backend then demand-loads system's own closure
  # (locks, allocators, threads, …) during codegen; the per-module backend
  # instead makes every one of those a first-class cg/emit target, so load that
  # closure here too — otherwise `findTargetModule` cannot resolve their suffix.
  block:
    var visited = initHashSet[string]()
    visited.incl "sysma2dyk"
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
  let systemFileIdx = registerNifSuffix(g.config, "sysma2dyk", isKnownFile)
  g.config.m.systemFileIdx = systemFileIdx
  let precompSys = moduleFromNifFile(g, systemFileIdx, {AlwaysLoadInterface})
  g.systemModule = precompSys.module

  var modules: seq[PrecompiledModule] = @[]
  var visited = initHashSet[string]()
  visited.incl "sysma2dyk"

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

proc findHiddenEnvParam(n: PNode; owner: PSym): PSym =
  ## Locate the hidden env param (`:envP`) that belongs to `owner` in its loaded
  ## transformed body, so it can be re-welded into `owner`'s signature. Matching
  ## by `owner` is essential: a body can ALSO reference a callee's `:envP` (a
  ## closure call passes the callee env), so the first `:envP` in DFS order is
  ## not necessarily this proc's own.
  if n == nil: return nil
  if n.kind == nkSym:
    if n.sym != nil and n.sym.kind == skParam and n.sym.name.s == paramName and
        n.sym.owner == owner:
      return n.sym
  else:
    for i in 0 ..< n.safeLen:
      let r = findHiddenEnvParam(n[i], owner)
      if r != nil: return r
  return nil

proc registerLoweredModule(g: ModuleGraph; m: PSym; applyBodies: bool) =
  ## Load module `m`'s `<m>.t.nif` and register its `lower`-stage output: its
  ## embedded index (so its closure-env `@bk` entities resolve) and its lifted
  ## type-bound ops (so any cg that DESTROYS one of `m`'s closures finds the env
  ## `=destroy` via getAttachedOp). For the cg TARGET (`applyBodies`), also set
  ## each owned routine's `transformedBody` so cg's `transformBody` short-circuits
  ## (transf.nim:1383) instead of re-deriving. `injectDestructorCalls` stays in cg.
  let modPos = m.position
  let bmod = BModuleList(g.backend).mods[modPos]
  if bmod == nil: return
  let artifact = getCFile(bmod).string & ".t.nif"
  if not fileExists(artifact): return
  let suffix = cachedModuleSuffix(g.config, FileIndex modPos)
  let (bodies, hooks) = loadLoweredBodies(ast.program, FileIndex modPos, suffix,
                                          artifact, loadBodies = applyBodies)
  registerLoadedHooks(g, hooks)
  if not applyBodies: return
  var byName = initTable[string, PSym]()
  for s in moduleSymbolStubs(ast.program, FileIndex modPos):
    # Owned routines AND nested closure routines (the `:anonymous` procs the
    # lower stage emits as their own entries) — both are index-resolvable syms
    # of this module whose transformed body the lower stage authored.
    if s.kind in routineKinds and s.itemId.module == modPos:
      byName[globalName(s, g.config)] = s
  for (name, body) in bodies:
    let s = byName.getOrDefault(name)
    # `.s.nif` wins: only fill from `.t.nif` if sem did not already transform it.
    if s != nil and body != nil and s.transformedBody == nil:
      s.transformedBody = body
      # Lambda-lift in the lower stage gave this proc a hidden `:envP` env param
      # (a captured-var closure env), but cg loaded the PRE-lift signature from
      # `.s.nif`. The transformed body references that `@bk` `:envP`; re-weld it
      # into the proc's params so genProc assigns it a loc (else "param not
      # init"). `transformBody` short-circuits on the cached body, skipping the
      # lift that normally adds it. This applies to BOTH a true `ccClosure` proc
      # (env arrives via the closure ABI `ClE_0`, needs `tfCapturesEnv`) and a
      # plain nested `nimcall` proc that merely captures (env is a regular last
      # param). Match the env param by owner — a body can also reference a
      # callee's `:envP`.
      if s.typ != nil and getEnvParam(s) == nil:
        let ep = findHiddenEnvParam(body, s)
        if ep != nil:
          # From-source, `ast[paramsPos]` and `typ.n` are the SAME node, but a
          # NIF-loaded routine has two distinct param nodes. genProc reads
          # `typ.n`, so unify them first — else addHiddenParam appends to
          # `ast[paramsPos]` and the env param never reaches genProc's loc setup.
          if s.typ.n != nil:
            s.ast[paramsPos] = s.typ.n
          addHiddenParam(s, ep)
          # The lower stage's lambda-lift converts EVERY captured nested proc to a
          # closure (collectNestedClosureBodies only emits `ccClosure` entries),
          # and the serialized call sites use the closure ABI. cg loaded the
          # pre-lift signature, which for a proc only ever CALLED (never used as a
          # value) is still `nimcall`. Re-apply the lift's `ccClosure` +
          # `tfCapturesEnv` so closureSetup maps the env param to `ClE_0` and the
          # calls match.
          s.typ.callConv = ccClosure
          incl(s.typ, {tfCapturesEnv})

proc applyLoweredBodies(g: ModuleGraph; modules: seq[PrecompiledModule];
                        precompSys: PrecompiledModule; target: PrecompiledModule) =
  ## Register every loaded module's `.t.nif` (env entities + lifted hooks),
  ## applying transformed bodies only for the cg target.
  if not icLoweredBodies(g.config): return  # Stage 0 (lazy): nothing to apply
  if precompSys.module != nil:
    registerLoweredModule(g, precompSys.module, applyBodies = false)
  for m in modules:
    if m.module != nil:
      registerLoweredModule(g, m.module,
        applyBodies = (m.module.position == target.module.position))

proc collectNestedClosureBodies(g: ModuleGraph; idgen: IdGenerator; n: PNode;
                                owner: PSym; seen: var IntSet;
                                entries: var seq[tuple[name: string; body: PNode]]) =
  ## A closure routine nested in `owner` (the `:anonymous` proc lambda-lifting
  ## minted, plus any deeper nesting) gets its captured-var→env rewrite produced
  ## as part of the OWNER's `transformBody`, but only the owner's body is emitted
  ## as a `(lowered)` entry. The nested proc itself IS index-resolvable (it has a
  ## `.s.nif` sdef from sem, with its PRE-lift body), so cg loads that and
  ## re-derives — and the capture mapping is gone (it accesses `x` directly
  ## instead of `ClE_0->x0`). Walk the transformed body and emit each nested
  ## closure routine's transformed body as its OWN `(lowered)` entry so
  ## applyLoweredBodies installs it and cg reuses it verbatim.
  if n == nil: return
  if n.kind == nkSym:
    let s = n.sym
    if s != nil and s.kind in routineKinds and s != owner and
        not seen.containsOrIncl(s.id):
      if s.ast != nil and getBody(g, s).kind != nkEmpty and
          s.typ != nil and s.typ.callConv == ccClosure:
        if s.transformedBody == nil:
          s.transformedBody = transformBody(g, idgen, s, {})
        entries.add (globalName(s, g.config), s.transformedBody)
        collectNestedClosureBodies(g, idgen, s.transformedBody, s, seen, entries)
  else:
    for i in 0 ..< n.safeLen:
      collectNestedClosureBodies(g, idgen, n[i], owner, seen, entries)

proc reownFromTwin(n: PNode; twin, s: PSym) =
  ## Re-own to `s` every entity the frontend wrongly attributed to `s`'s
  ## forward-decl `twin` (see the lower-stage loop). `twin` is one specific sym,
  ## so only the mis-owned entities of THIS routine match — nested routines and
  ## their own locals (owned by the nested routine, not `twin`) are untouched.
  if n == nil: return
  if n.kind == nkSym and n.sym != nil and n.sym.owner == twin:
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
  let artifact = getCFile(tb).string & ".t.nif"
  if icLoweredBodies(g.config):
    # STAGE 1 (DEFAULT; `-d:icNoLowerBodies` opts out): transform every owned routine
    # ONCE in this single process's id space and serialize the results, so `cg`
    # reads them instead of re-deriving (the single-writer-per-owner that keeps
    # closure-`:env` identity stable). `transformBody` with flags {} mirrors the
    # cg call (cgen.nim:1409); we keep only its return value (it clears
    # `transformedBody` for non-cached procs). `injectDestructorCalls` is NOT run
    # — it stays in `cg` on the loaded body.
    var entries: seq[tuple[name: string; body: PNode]] = @[]
    # `transformBody`/lambda-lifting LIFTS the closure env's type-bound ops
    # (`=destroy` etc.) into `g.opsLog`; snapshot its length so we can serialize
    # exactly the ops THIS stage created (not those loaded from `.s.nif`).
    let opsLogStart = g.opsLog.len
    for s in moduleSymbolStubs(ast.program, FileIndex modPos):
      if ownsRuntimeRoutine(s, modPos):
        # `.s.nif` wins: a routine already transformed during sem (CT eval /
        # macro / VM transform) carries its lowered body in the `.s.nif` slot —
        # don't re-transform it here, just leave its `.t.nif` entry empty.
        if s.transformedBody != nil: continue
        # A routine serialized as a forward-decl + impl pair (the writeSymDef
        # "separate forward declaration and implementation" design) loads as TWO
        # syms; the impl `s` we transform here can carry body entities (`result`,
        # locals, nested routines) owned by its fwd-decl TWIN, not by `s`.
        # lambda-lifting compares owners by reference: `detectCapturedVars`
        # rejects a twin-owned `result` as `illegalCapture` ("'result' ... cannot
        # be captured") and, once that is fixed, the lifting pass can't find a
        # twin-owned captured local in `s`'s env ("environment misses: ..."). Both
        # are pervasive on chronos `{.async.}` methods. Re-own every twin-attributed
        # entity to `s`, matching the single-sym non-IC case. The twin is a
        # specific sym (found via the result's owner), so only THIS routine's
        # mis-owned entities match. Backend-only (the lowered body is a `.t.nif`
        # artifact), so frontend effect/exception inference is untouched.
        if s.ast != nil and s.ast.len > resultPos and
            s.ast[resultPos].kind == nkSym and s.ast[resultPos].sym.owner != s:
          reownFromTwin(s.ast, s.ast[resultPos].sym.owner, s)
        let tbody = transformBody(g, tb.idgen, s, {})
        entries.add (globalName(s, g.config), tbody)
        var seenNested = initIntSet()
        collectNestedClosureBodies(g, tb.idgen, tbody, s, seenNested, entries)
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
        # Transform the hook routine's body and cache it on the sym so
        # `writeSymDef` serializes it in the hook's `(sd)` transformed-body slot
        # (`transformBody {}` returns the body but does not cache it).
        e.sym.transformedBody = transformBody(g, tb.idgen, e.sym, {})
      inc i
    # Seal the index-loaded entities so their references in the bodies serialize
    # as SymUses (resolved via the module index in cg), not duplicate defs.
    sealLoadedBackendEntities(ast.program)
    serializeLoweredBodies(g.config, modPos.int32, entries, hooks, artifact)
    if isDefined(g.config, "icDceCheck"):
      stderr.writeLine "[icLower] " & extractFilename(artifact) & " " &
        $entries.len & " routines transformed, " & $hooks.len & " hooks"
  else:
    # DEFAULT (Stage 0, byte-neutral): record one empty-marker per owned routine.
    # `cg` derives the transformed body itself, so output is unchanged; this only
    # exercises the artifact + scheduling the transform-move builds on.
    var names: seq[string] = @[]
    for s in moduleSymbolStubs(ast.program, FileIndex modPos):
      if ownsRuntimeRoutine(s, modPos):
        names.add globalName(s, g.config)
    writeLoweredArtifact(artifact, names)

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

  applyLoweredBodies(g, modules, precompSys, target)
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
    for m in bl.mods:
      if m != nil and sfMainModule notin m.module.flags:
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
  for m in bl.mods:
    if m != nil:
      let cfile = getCFile(m)
      # Only modules that are their own cg/emit target produced a `.c`; the rest
      # (extra members of system's closure that no build rule targets) had their
      # code emit-everywhere'd into the targets, so they have no file to compile.
      if not fileExists(cfile.string): continue
      var cf = Cfile(nimname: m.module.name.s, cname: cfile,
                     obj: completeCfilePath(g.config, toObjFile(g.config, cfile)),
                     flags: {})
      addFileToCompile(g.config, cf)
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
