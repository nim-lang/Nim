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

import std/[intsets, tables, sets, os]

when defined(nimPreviewSlimSystem):
  import std/assertions

import ast, options, lineinfos, modulegraphs, cgendata, cgen,
  pathutils, extccomp, msgs, modulepaths, idents, types, ast2nif
import ic / replayer

proc loadModuleDependencies(g: ModuleGraph; mainFileIdx: FileIndex): seq[PrecompiledModule] =
  ## Traverse the module dependency graph using a stack.
  ## Returns all modules that need code generation, in dependency order.
  let mainModule = moduleFromNifFile(g, mainFileIdx, {LoadFullAst})

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

proc generateCode*(g: ModuleGraph; mainFileIdx: FileIndex) =
  ## Main entry point for NIF-based C code generation.
  ## Traverses the module dependency graph and generates C code.

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
  let modules = loadModuleDependencies(g, mainFileIdx)
  if modules.len == 0:
    rawMessage(g.config, errGenerated,
      "Cannot load NIF file for main module: " & toFullPath(g.config, mainFileIdx))
    return

  # Set up backend modules for all modules that need code generation
  for m in modules:
    discard setupNifBackendModule(g, m.module)

  # Also ensure system module is set up and generated first if it exists
  if precompSys.module != nil:
    discard setupNifBackendModule(g, precompSys.module)
    generateCodeForModule(g, precompSys)

  # Track which modules have been processed to avoid duplicates
  var processed = initIntSet()
  if precompSys.module != nil:
    processed.incl precompSys.module.position

  # Generate code for all modules (skip system since it's already processed)
  for m in modules:
    if not processed.containsOrIncl(m.module.position):
      generateCodeForModule(g, m)

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

  # Write C files
  cgenWriteModules(g.backend, g.config)

  # Run C compiler
  if g.config.cmd != cmdTcc:
    extccomp.callCCompiler(g.config)
    if not g.config.hcrOn:
      extccomp.writeJsonBuildInstructions(g.config, g.cachedFiles)
