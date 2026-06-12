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

  let bl = BModuleList(g.backend)
  var handledArtifacts = initHashSet[string]()
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
    if sfMainModule in pm.module.flags: continue
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
    if maxTime[nifFile] > getLastModificationTime(artifact):
      reject("dependency closure newer than artifact")
    let heads = readCnifHeads(artifact)
    if not heads.valid: reject("artifact has no meta head")
    g.icReusedModules.incl pos
    g.icReusedMeta[pos] = (heads.initRequired, heads.datInitRequired)
    for d in heads.cdefs: g.icCachedCDefs.incl d
    for d in heads.cdata: g.icCachedDataDefs.incl d

  # Translation units of modules the backend module list does not even
  # contain (reached only through system's imports or demand-driven
  # codegen): their artifacts are self-describing, so they can be reused
  # purely at the file level. When one of them is stale, its import
  # closure is stale too, so every TU that could reference it regenerates
  # and demand recreates the definitions.
  for artifact in walkFiles(getNimcacheDir(g.config).string / "*.c.nif"):
    if artifact in handledArtifacts: continue
    let heads = readCnifHeads(artifact)
    if not heads.valid or heads.semmedNif.len == 0 or heads.moduleBase.len == 0:
      continue
    if heads.semmedNif notin maxTime:
      continue # not part of this program (e.g. a removed module)
    let cname = artifact[0..^5] # strip ".nif"
    let obj = completeCfilePath(g.config, toObjFile(g.config, AbsoluteFile cname))
    if not (fileExists(cname) and fileExists(obj.string)): continue
    if maxTime[heads.semmedNif] > getLastModificationTime(artifact):
      continue
    g.icFileReused.add (cname, heads.moduleBase,
                        heads.initRequired, heads.datInitRequired)
    g.icFileReusedCnames.incl cname
    for d in heads.cdefs: g.icCachedCDefs.incl d
    for d in heads.cdata: g.icCachedDataDefs.incl d
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

  # Generate dispatcher methods
  for disp in getDispatchers(g):
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
