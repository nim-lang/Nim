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
import ic / replayer

proc loadModuleDependencies(g: ModuleGraph; mainFileIdx: FileIndex;
                            nifFiles: var seq[string]): seq[PrecompiledModule] =
  ## Traverse the module dependency graph using a stack.
  ## Returns all modules that need code generation, in dependency order.
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
      let precomp = moduleFromNifFile(g, fileIdx, {LoadFullAst})
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

proc enforceDefRetention(g: ModuleGraph; mainPos: int;
                         reusedHeads: var Table[int, CnifHeads];
                         fileCandidates: var seq[tuple[cname: string, heads: CnifHeads]];
                         staleArtifacts: seq[string];
                         loadedArtifacts: seq[tuple[pos: int, artifact: string]];
                         icDebug: bool) =
  ## The backend def-migration check ("previously defined, still referenced").
  ##
  ## A definition can live in a TU other than its symbol's home module:
  ## redirected defs, shared `_i<hash>` instances, demand-generated hooks.
  ## When that TU regenerates and the demand chain that put the definition
  ## there does not re-arise (its demanders sit in reused TUs now), the
  ## definition vanishes while the reused TUs still call it — a guaranteed
  ## link error that only a cold rebuild heals.
  ##
  ## For every definition in a regenerating TU's *previous* artifact that
  ## some reused TU references (its `cref` head) and that no reused TU
  ## defines, the recorded NIF name is resolved against the current sem
  ## state and the symbol is re-demanded into the TU the definition lived
  ## in (`icPreserveDefs`, consumed by `generateCodeForModule`). When the
  ## symbol no longer exists — only possible with an incoherent cache,
  ## e.g. mixed compiler generations or renamed RTTI — the referencing TUs
  ## lose their reuse instead and regenerate; their old definitions then
  ## become sources for the same check, hence the fixpoint loop.
  if mainPos < 0: return
  # Sources: the previous artifacts of every TU that regenerates this run.
  # `ownTU` marks sources whose module runs full codegen this run (loaded
  # backend modules): only those re-emit their global variables and their
  # live top-level listing by themselves. Definitions in stale unclaimed
  # artifacts have no TU of their own; the main module (always regenerated)
  # hosts their re-demands.
  var sources: seq[tuple[target: int, ownTU: bool, heads: CnifHeads]] = @[]
  for la in loadedArtifacts:
    if la.pos notin g.icReusedModules:
      let h = readCnifHeads(la.artifact)
      if h.valid: sources.add (la.pos, true, h)
  for a in staleArtifacts:
    let h = readCnifHeads(a)
    if h.valid: sources.add (mainPos, false, h)
  if sources.len == 0: return

  while true:
    # what the surviving reused TUs define and reference
    var cachedDefs = initHashSet[string]()
    template addDefs(h: CnifHeads) =
      for d in h.cdefs: cachedDefs.incl d.cname
      for d in h.cdata: cachedDefs.incl d.cname
    for h in reusedHeads.values: addDefs(h)
    for fc in fileCandidates: addDefs(fc.heads)
    # referencing TUs per name: loaded modules by position, file-level
    # TUs by -(index+1)
    var refdBy = initTable[string, seq[int]]()
    for pos, h in reusedHeads.pairs:
      for r in h.crefs: refdBy.mgetOrPut(r, @[]).add pos
    for i, fc in fileCandidates.pairs:
      for r in fc.heads.crefs: refdBy.mgetOrPut(r, @[]).add -(i+1)

    # modules whose TU runs full codegen this run: definitions they still
    # own are re-emitted with them (globals through the serialized var
    # sections unconditionally, live routines through the top-level listing)
    var regenSuffixes = initHashSet[string]()
    for src in sources.items:
      if src.ownTU:
        let base = extractFilename(src.heads.semmedNif)
        if base.len > 4: regenSuffixes.incl base[0..^5] # strip ".nif"

    # Every definition of a regenerating TU's previous artifact must stay
    # defined ("previously defined => still defined"): references to it can
    # be invisible (compilerproc/exportc names are not cnif-marked), so the
    # preserve decision must NOT depend on the cref index — that one only
    # targets the un-reuse fallback. Demand-side dedup (`declaredThings`,
    # the cached/claim shortcuts) makes redundant re-demands cheap.
    clear g.icPreserveDefs
    var unreuse = initHashSet[int]()
    for src in sources.items:
      template check(defseq) =
        for d in defseq:
          if d.cname notin cachedDefs:
            var sym: PSym = nil
            if d.nifname.len > 0:
              sym = resolveGlobalSym(ast.program, d.nifname)
            # NB: reading `sym.kind` forces the lazy stub, so the kind is real
            var action = 0 # un-reuse any visibly referencing TUs
            if sym != nil:
              if sym.kind in routineKinds or sym.kind == skConst:
                # routine and const definitions exist only by demand (the
                # serialized top level holds just the eager init statements,
                # not a proc listing!), and reused TUs never demand — so
                # every definition of the previous artifact whose symbol
                # still exists is re-demanded explicitly
                action = 2
              elif sym.kind in {skVar, skLet} and
                  parseSymName(d.nifname).module in regenSuffixes:
                action = 1 # globals are re-emitted with their module's
                           # eager top-level statements
            case action
            of 1: discard
            of 2:
              g.icPreserveDefs.mgetOrPut(src.target, @[]).add sym
              if icDebug:
                stderr.writeLine "[icRetain] preserve " & d.cname
            else:
              if d.cname in refdBy:
                for tu in refdBy[d.cname]: unreuse.incl tu
                if icDebug:
                  stderr.writeLine "[icRetain] cannot re-demand " & d.cname &
                    " (nif: " & d.nifname & "); un-reusing referencing TUs"
              # no visible references and no symbol to re-demand: a deleted
              # definition; invisible (unmarked) references would stem from
              # exportc-style names whose callers re-sem on deletion anyway
      check(src.heads.cdefs)
      check(src.heads.cdata)
    if unreuse.len == 0: break
    # un-reused TUs regenerate; their previous definitions become sources
    # for the next round
    var dropFile: seq[int] = @[]
    for tu in unreuse.items:
      if tu >= 0:
        if tu in reusedHeads:
          g.icReusedModules.excl tu
          g.icReusedMeta.del tu
          sources.add (tu, true, reusedHeads[tu])
          reusedHeads.del tu
      else:
        dropFile.add -(tu+1)
    sort dropFile
    for j in countdown(dropFile.high, 0):
      # an un-reused file-level TU has no backend module: only demand-driven
      # codegen recreates its content, so its definitions are re-demanded
      # through the main module (ownTU = false)
      sources.add (mainPos, false, fileCandidates[dropFile[j]].heads)
      fileCandidates.delete dropFile[j]

proc computeModuleReuse(g: ModuleGraph; modules: seq[PrecompiledModule];
                        precompSys: PrecompiledModule;
                        nifDeps: Table[string, seq[string]]) =
  ## Decides which modules' cached translation units can be reused: codegen
  ## is skipped for them and their `.c`/`.o`/artifact files are used as is.
  ##
  ## A module is reusable when the newest semmed NIF in its transitive
  ## import closure is older than its `.c.nif` artifact — so neither the
  ## module itself nor anything that can influence its generated C (type
  ## layouts of dependencies in particular) has changed — and the cached
  ## artifact, `.c` and `.o` files are all present. The main module is
  ## always regenerated: it carries NimMain's init-call list and the method
  ## dispatchers, which depend on the whole program.
  ##
  ## A regenerated module may still demand entities that live in a reused
  ## TU: definitions already inside the cached TU become prototypes (see
  ## `genProcLvl3`/`genTypeInfo*` and the artifact's cdef/cdata heads),
  ## fresh demands are redirected into the demanding TU
  ## (`redirectToLiveModule`).
  if not g.icDceEnabled or isDefined(g.config, "icNoReuse") or
      g.config.hcrOn or g.config.symbolFiles != disabledSf:
    return
  let icDebug = isDefined(g.config, "icTimings")
  # newest mtime in every NIF file's transitive import closure, via
  # fixpoint iteration (the import graph can contain cycles). The implicit
  # system import is not part of the NIF import lists, so system counts as
  # a dependency of every module.
  let systemNif = toNifFilename(g.config, g.config.m.systemFileIdx)
  var maxTime = initTable[string, Time]()
  for f in nifDeps.keys:
    maxTime[f] = getLastModificationTime(f)
  var changed = true
  while changed:
    changed = false
    for f, deps in nifDeps:
      var newest = maxTime[f]
      if systemNif in maxTime and maxTime[systemNif] > newest and f != systemNif:
        newest = maxTime[systemNif]
      for d in deps:
        if d in maxTime and maxTime[d] > newest: newest = maxTime[d]
      if newest > maxTime[f]:
        maxTime[f] = newest
        changed = true

  # Fine-grained reuse gate, mirroring the m-step's cookie gating: a TU's
  # generated C depends on its own semmed NIF, on every direct import's
  # *interface* (type layouts, signatures, const values, inline-semantics
  # bodies — all hashed into the `.iface.nif` cookie, whose hash chains the
  # direct deps' cookies and is therefore transitively sensitive), on the
  # implicit system import, and on the *implementations* of the modules
  # whose routine bodies the TU physically embeds (redirected defs, shared
  # instances, hooks — recorded in the artifact's cdeps head, gated on
  # `.impl.nif`). The cookie sidecars are written OnlyIfChanged by the
  # m-step, so a body-only edit in a leaf module leaves every dependent's
  # iface input untouched and only the edited module's TU regenerates.
  # When a sidecar is missing (`-d:icNoIfaceGate` m-runs, foreign caches)
  # the gate falls back to the transitive NIF-mtime closure; `-d:icCoarseReuse`
  # forces that fallback.
  let coarseReuse = isDefined(g.config, "icCoarseReuse")
  var inputTimes = initTable[string, Time]()
  proc sidecarOf(nifFile, kind: string): string =
    nifFile[0..^5] & "." & kind & ".nif" # "<dir>/<suffix>.nif" -> "<dir>/<suffix>.<kind>.nif"
  proc staleVsArtifact(nifFile: string; artTime: Time; heads: CnifHeads): string =
    ## Empty when every input is older than the artifact, else the reason.
    if nifFile notin inputTimes:
      inputTimes[nifFile] = getLastModificationTime(nifFile)
    if inputTimes[nifFile] > artTime:
      return "semmed NIF newer than artifact"
    var missingSidecar = coarseReuse
    if not missingSidecar:
      block fine:
        var inputs = @[sidecarOf(systemNif, "iface")]
        for dep in nifDeps.getOrDefault(nifFile):
          inputs.add sidecarOf(dep, "iface")
        for s in heads.cdeps:
          inputs.add getNimcacheDir(g.config).string / s & ".impl.nif"
        for inp in inputs:
          if inp notin inputTimes:
            if fileExists(inp):
              inputTimes[inp] = getLastModificationTime(inp)
            else:
              missingSidecar = true
              break fine
          if inputTimes[inp] > artTime:
            return "cookie newer than artifact: " & inp
        return ""
    if maxTime.getOrDefault(nifFile, artTime) > artTime:
      return "dependency closure newer than artifact (coarse)"
    return ""

  let bl = BModuleList(g.backend)
  var handledArtifacts = initHashSet[string]()
  var loadedArtifacts: seq[tuple[pos: int, artifact: string]] = @[]
  var reusedHeads = initTable[int, CnifHeads]() # loaded reused modules
  var mainPos = -1
  for i in 0..modules.len:
    let pm = if i < modules.len: modules[i] else: precompSys
    if pm.module == nil: continue
    let pos = pm.module.position
    let bmod = bl.mods[pos]
    if bmod == nil: continue
    let artifact = getCFile(bmod).string & ".nif"
    # claimed by a loaded module — regenerated or reused, but never
    # eligible for the file-level reuse below
    handledArtifacts.incl artifact
    loadedArtifacts.add (pos, artifact)
    if sfMainModule in pm.module.flags:
      mainPos = pos
      continue
    let nifFile = toNifFilename(g.config, FileIndex pos)
    template reject(reason: string) =
      if icDebug:
        stderr.writeLine "[icReuse] regen " & cachedModuleSuffix(g.config, FileIndex pos) &
          ": " & reason
      continue
    if nifFile notin maxTime: reject("not in dce closure: " & nifFile)
    let cfile = getCFile(bmod)
    let obj = completeCfilePath(g.config, toObjFile(g.config, cfile))
    if not fileExists(artifact): reject("no artifact " & artifact)
    if not fileExists(cfile.string): reject("no C file")
    if not fileExists(obj.string): reject("no object file")
    let heads = readCnifHeads(artifact)
    if not heads.valid: reject("artifact has no meta head")
    let staleReason = staleVsArtifact(nifFile, getLastModificationTime(artifact), heads)
    if staleReason.len > 0: reject(staleReason)
    g.icReusedModules.incl pos
    g.icReusedMeta[pos] = (heads.initRequired, heads.datInitRequired)
    reusedHeads[pos] = heads

  # Translation units of modules the backend module list does not even
  # contain (reached only through system's imports or demand-driven
  # codegen): their artifacts are self-describing, so they can be reused
  # purely at the file level. When one of them is stale, its import
  # closure is stale too, so every TU that could reference it regenerates
  # and demand recreates the definitions.
  var fileCandidates: seq[tuple[cname: string, heads: CnifHeads]] = @[]
  var staleArtifacts: seq[string] = @[]
  for artifact in walkFiles(getNimcacheDir(g.config).string / "*.c.nif"):
    if artifact in handledArtifacts: continue
    let heads = readCnifHeads(artifact)
    if not heads.valid or heads.semmedNif.len == 0 or heads.moduleBase.len == 0:
      continue
    if heads.semmedNif notin maxTime:
      # not part of this program anymore (e.g. a removed module), but its
      # definitions may still be referenced by reused TUs
      staleArtifacts.add artifact
      continue
    let cname = artifact[0..^5] # strip ".nif"
    let obj = completeCfilePath(g.config, toObjFile(g.config, AbsoluteFile cname))
    if not (fileExists(cname) and fileExists(obj.string)) or
        staleVsArtifact(heads.semmedNif,
                        getLastModificationTime(artifact), heads).len > 0:
      staleArtifacts.add artifact
      continue
    fileCandidates.add (cname, heads)

  if not isDefined(g.config, "icNoRetain"):
    enforceDefRetention(g, mainPos, reusedHeads, fileCandidates, staleArtifacts,
                        loadedArtifacts, icDebug)

  # The cached-definition sets and the file-level reuse list reflect the
  # TUs that survived the retention check.
  for heads in reusedHeads.values:
    for d in heads.cdefs: g.icCachedCDefs.incl d.cname
    for d in heads.cdata: g.icCachedDataDefs.incl d.cname
  for fc in fileCandidates:
    g.icFileReused.add (fc.cname, fc.heads.moduleBase,
                        fc.heads.initRequired, fc.heads.datInitRequired)
    g.icFileReusedCnames.incl fc.cname
    for d in fc.heads.cdefs: g.icCachedCDefs.incl d.cname
    for d in fc.heads.cdata: g.icCachedDataDefs.incl d.cname
  if icDebug and g.icFileReused.len > 0:
    stderr.writeLine "[icReuse] file-level reused TUs: " & $g.icFileReused.len

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
  true

proc finishModule(g: ModuleGraph; bmod: BModule) =
  # Finalize the module (this adds it to modulesClosed)
  # Create an empty stmt list as the init body - genInitCode in writeModule will set it up properly
  let initStmt = newNode(nkStmtList)
  finalCodegenActions(g, bmod, initStmt)

  # Dispatcher definitions live in the main TU only: their bodies enumerate
  # the whole program's method set, so a copy inside a reusable TU would go
  # stale when a method is added in an unrelated module (genProcLvl3 routes
  # demand-driven dispatcher definitions to main the same way). Main is
  # finished last, after all method registrations have been replayed.
  if sfMainModule in bmod.module.flags:
    for disp in getDispatchers(g):
      if not containsOrIncl(bmod.declaredThings, disp.id):
        genProcLvl3(bmod, disp)

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

  # Definitions this TU embedded in the previous run that reused TUs still
  # reference must keep being emitted (see `enforceDefRetention`).
  if g.icPreserveDefs.hasKey(moduleId):
    for sym in g.icPreserveDefs[moduleId]:
      requestAnyDef(bmod, sym)

proc generateCode*(g: ModuleGraph; mainFileIdx: FileIndex) =
  ## Main entry point for NIF-based C code generation.
  ## Traverses the module dependency graph and generates C code.

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

  # Decide which modules' cached translation units can be reused
  computeModuleReuse(g, modules, precompSys, nifDeps)
  phaseDone "reuse (" & $g.icReusedModules.len & " modules reused)"

  template generateOrReuse(precomp: PrecompiledModule) =
    if precomp.module.position in g.icReusedModules:
      # no code generation, but the recorded compile/link directives
      # (passl/passc/...) still apply to this build
      replayBackendActions(g, precomp.module, precomp.topLevel)
    else:
      generateCodeForModule(g, precomp)

  # System module is generated first if it exists
  if precompSys.module != nil:
    generateOrReuse(precompSys)

  # Track which modules have been processed to avoid duplicates
  var processed = initIntSet()
  if precompSys.module != nil:
    processed.incl precompSys.module.position

  # Generate code for all modules (skip system since it's already processed)
  for m in modules:
    if not processed.containsOrIncl(m.module.position):
      generateOrReuse(m)
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
