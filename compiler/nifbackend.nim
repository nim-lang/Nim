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
  pathutils, extccomp, msgs, modulepaths, idents, types, ast2nif, typekeys, dce,
  cnif
from cgmeth import generateIfMethodDispatchers
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

proc eagerHookCandidate(sym: PSym): bool =
  ## Announced hooks that can actually be code-generated: generic hook
  ## announcements and meta-typed ones (`varargs[typed]` etc.) are replay
  ## information for sem, not code.
  let typ = sym.typ
  if typ == nil or containsGenericType(typ): return false
  if typ.n == nil: return false
  for i in 1..<typ.n.len:
    let pt = typ.n[i].typ
    if pt == nil: return false
    if iterOverType(pt, isMetaIter, nil): return false
  # a `=dup` of an imported type returns it by value; for "lying" importc
  # typedefs like `jmp_buf` (declared as `object`, really a C array) that
  # signature does not compile. Demand-driven codegen never demands such
  # sem-bookkeeping hooks (under refc nothing dups a `C_JmpBuf`), and no
  # working artifact can call one — its prototype would be the same
  # invalid C — so they are safe to skip.
  let ret = typ.returnType
  if ret != nil:
    let r = ret.skipTypes({tyGenericInst, tyAlias, tySink, tyDistinct})
    if r.sym != nil and sfImportc in r.sym.flags: return false
  true

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
      if s.itemId.module == modPos and
         s.kind in {skProc, skFunc, skConverter, skMethod} and
         # Only MODULE-level routines: a nested/closure proc (its owner is a
         # proc) captures its enclosing scope and cannot be emitted standalone —
         # the captured params have no loc → `expr: param not init`. Nested procs
         # are emitted via their enclosing routine's lambda-lifting, so seeding
         # the enclosing (module-level) routine already covers them.
         s.skipGenericOwner != nil and s.skipGenericOwner.kind == skModule and
         s.magic == mNone and
         # Skip generic instances: they have no single owning-module top-level
         # and are emitted by demand (emit-everywhere, deduped by the merge
         # stage). An instance has an empty `genericParamsPos` just like a plain
         # concrete proc, so only `sfFromGeneric` tells them apart; seeding one
         # would force standalone codegen of an instance body whose `when T is X`
         # branches were never folded for this path → `genMagicExpr: mIs`.
         sfFromGeneric notin s.flags and
         # Every other routine the module owns must be emitted here, exported or
         # not: a non-exported helper is still reached from another module when a
         # `template`/inline routine expands at a call site there (e.g. msgs'
         # `internalErrorImpl` behind the `internalError` template), and that
         # caller now only prototypes it. `{.error.}`/`compileTime` sentinels and
         # bodyless forward decls are not real codegen targets.
         {sfForward, sfImportc, sfCompileTime, sfError} * s.flags == {} and
         s.typ != nil and not signatureHasMetaType(s.typ) and
         s.ast != nil and s.ast.safeLen > bodyPos and
         s.ast[genericParamsPos].kind == nkEmpty and
         s.ast[bodyPos].kind != nkEmpty:
        # a concrete, non-generic, runtime routine with a real body, owned here
        requestProcDef(bmod, s)

  # The hooks and `$enum` procs this module announces are liveness roots:
  # a cached TU from a previous run may call them without any demand
  # arising in this run (the demanding instance body sits inside a reused
  # TU). Demand them unconditionally so a regenerated TU never *loses*
  # definitions that cached TUs link against.
  if g.icDceEnabled and not isDefined(g.config, "icNoReuse"):
    for op in precomp.logOps:
      if op.kind in {HookEntry, EnumToStrEntry} and op.sym != nil and
          eagerHookCandidate(op.sym):
        when defined(icDbg):
          stderr.writeLine "[icHook] " & $op.kind & " " & op.sym.name.s &
            " typ: " & typeToString(op.sym.typ) & " in " & precomp.module.name.s
        requestProcDef(bmod, op.sym)

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
    # No whole-program DCE here, exactly as for a non-main target: `icDceEnabled`
    # stays false so each module emits the routines it owns and the MERGE stage
    # recomputes the one program-wide live set across all `.c.nif`s. Running
    # `computeLiveSymbols` over all ~260 NIFs in the main `cg` cost ~900 MB for a
    # result the merge stage throws away — pure redundancy now that the funnel is
    # gone (the main module no longer emits its transitive closure's bodies).
    target = findTargetModule(g, modules, precompSys, g.config.icBackendModule)
  else:
    # No whole-program load, hence no whole-program DCE: `icDceEnabled` stays
    # false, so `icDceLive` keeps every top-level routine and the target emits
    # its full demanded closure. The merge stage drops what is globally dead.
    (modules, precompSys, target) = loadDepClosure(g, g.config.icBackendModule)
  if target.module == nil:
    rawMessage(g.config, errGenerated,
      "per-module codegen: module not found for suffix: " & g.config.icBackendModule)
    return

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
  if g.config.icBackendStage == "cg":
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
  elif g.config.icBackendStage.len > 0:
    rawMessage(g.config, errGenerated,
      "per-module backend stage not implemented yet: " & g.config.icBackendStage)
    return

  # Phase timing, enabled with `-d:icTimings` on the nifc command line.
  let icTimings = isDefined(g.config, "icTimings")
  var phaseStart = epochTime()
  template phaseDone(name: string) =
    if icTimings:
      let now = epochTime()
      stderr.writeLine "[icTime] " & name & ": " &
        formatFloat(now - phaseStart, ffDecimal, 2) & "s"
      phaseStart = now

  # Reset backend state
  resetForBackend(g)

  var isKnownFile = false
  let systemFileIdx = registerNifSuffix(g.config, "sysma2dyk", isKnownFile)
  g.config.m.systemFileIdx = systemFileIdx
  #msgs.fileInfoIdx(g.config,
  #    g.config.libpath / RelativeFile"system.nim")

  # Load system module first - it's always needed and contains essential hooks
  var precompSys = PrecompiledModule(module: nil)
  precompSys = moduleFromNifFile(g, systemFileIdx, {LoadFullAst, AlwaysLoadInterface})
  g.systemModule = precompSys.module

  # Load all modules in dependency order using stack traversal
  # This must happen BEFORE any code generation so that hooks are loaded into loadedOps
  var nifFiles: seq[string] = @[toNifFilename(g.config, systemFileIdx)]
  let modules = loadModuleDependencies(g, mainFileIdx, nifFiles)
  # build the method dispatch buckets now that every module is loaded
  flushMethodReplays(g)
  phaseDone "load (" & $ (modules.len + 1) & " modules)"
  if modules.len == 0:
    rawMessage(g.config, errGenerated,
      "Cannot load NIF file for main module: " & toFullPath(g.config, mainFileIdx))
    return

  # Compute the global live set so that the top-level routine listing can be
  # filtered (see `ccgstmts.genStmts`). On analysis failure everything stays
  # alive — demand-driven `genProc` makes this a size optimization only.
  var dceStats = DceStats()
  var nifDeps = initTable[string, seq[string]]()
  if not isDefined(g.config, "icNoDce"):
    g.icDceEnabled = computeLiveSymbols(g.config, nifFiles, g.icLiveNames,
                                        dceStats, nifDeps)
  phaseDone "dce"

  # Set up backend modules for all modules that need code generation
  for m in modules:
    discard setupNifBackendModule(g, m.module)
  if precompSys.module != nil:
    discard setupNifBackendModule(g, precompSys.module)

  # System module is generated first if it exists
  if precompSys.module != nil:
    generateCodeForModule(g, precompSys)

  # Track which modules have been processed to avoid duplicates
  var processed = initIntSet()
  if precompSys.module != nil:
    processed.incl precompSys.module.position

  # Generate code for all modules (skip system since it's already processed)
  for m in modules:
    if not processed.containsOrIncl(m.module.position):
      generateCodeForModule(g, m)

  emitMethodDispatchers(g)
  phaseDone "cgen"

  # during code generation of `main.nim` we can trigger the code generation
  # of symbols in different modules so we need to finish these modules
  # here later, after the above loop!
  # Important: The main module must be finished LAST so that all other modules
  # have registered their init procs before genMainProc uses them.
  var mainModule: BModule = nil
  for m in BModuleList(g.backend).mods:
    if m != nil:
      assert m.module != nil
      if sfMainModule in m.module.flags:
        mainModule = m
      else:
        finishModule g, m
  if mainModule != nil:
    finishModule g, mainModule
  phaseDone "finish"

  if g.icDceEnabled and isDefined(g.config, "icDceCheck"):
    var misses: seq[string] = @[]
    for n in g.icDceMisses: misses.add n
    sort misses
    for n in misses:
      stderr.writeLine "[icDce] MISS (generated on demand, not marked live): " & n
    stderr.writeLine "[icDce] live: " & $g.icLiveNames.len & " misses: " & $misses.len &
      " modules: " & $nifFiles.len
    stderr.writeLine "[icDce] instances: " & $dceStats.instances &
      " unique: " & $dceStats.uniqueInstances &
      " mergeable: " & $(dceStats.instances - dceStats.uniqueInstances)

  # Write C files
  cgenWriteModules(g.backend, g.config)
  phaseDone "write"

  if isDefined(g.config, "icDceCheck") and g.icCnifFiles.len > 0:
    stderr.writeLine "[icDceC] cdefs: " & $g.icCDefs & " live: " & $g.icCLiveDefs &
      " dropped: " & $g.icCDropped

  # Run C compiler
  if g.config.cmd != cmdTcc:
    extccomp.callCCompiler(g.config)
    phaseDone "cc+link"
    if not g.config.hcrOn:
      extccomp.writeJsonBuildInstructions(g.config, g.cachedFiles)
