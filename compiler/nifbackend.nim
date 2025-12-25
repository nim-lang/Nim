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

proc loadModuleDependencies(g: ModuleGraph; mainFileIdx: FileIndex): seq[PSym] =
  ## Traverse the module dependency graph using a stack.
  ## Returns all modules that need code generation, in dependency order.
  let precomp = moduleFromNifFile(g, mainFileIdx, loadFullAst=true)

  var stack: seq[ModuleSuffix] = @[]
  result = @[]

  if precomp.module != nil:
    result.add precomp.module
    incl precomp.module.flagsImpl, sfMainModule
    for dep in precomp.deps:
      stack.add dep

  var visited = initHashSet[string]()

  while stack.len > 0:
    let suffix = stack.pop()

    if not visited.containsOrIncl(suffix.string):
      let fileIdx = msgs.fileInfoIdx(g.config, AbsoluteFile suffix.string)
      let precomp = moduleFromNifFile(g, fileIdx, loadFullAst=true)
      if precomp.module != nil:
        result.add precomp.module
        for dep in precomp.deps:
          if not visited.contains(dep.string):
            stack.add dep

proc setupNifBackendModule(g: ModuleGraph; module: PSym): BModule =
  ## Set up a BModule for code generation from a NIF module.
  if g.backend == nil:
    g.backend = cgendata.newModuleList(g)
  result = cgen.newModule(BModuleList(g.backend), module, g.config, idGeneratorFromModule(module))

proc finishModule(g: ModuleGraph; bmod: BModule) =
  # Finalize the module (this adds it to modulesClosed)
  # Create an empty stmt list as the init body - genInitCode in writeModule will set it up properly
  let initStmt = newNode(nkStmtList)
  finalCodegenActions(g, bmod, initStmt)

  # Generate dispatcher methods
  for disp in getDispatchers(g):
    genProcLvl3(bmod, disp)

proc generateCodeForModule(g: ModuleGraph; module: PSym) =
  ## Generate C code for a single module.
  let moduleId = module.position
  var bmod = BModuleList(g.backend).modules[moduleId]
  if bmod == nil:
    bmod = setupNifBackendModule(g, module)

  # Generate code for the module's top-level statements
  if module.ast != nil:
    cgen.genTopLevelStmt(bmod, module.ast)

  finishModule(g, bmod)

proc generateCode*(g: ModuleGraph; mainFileIdx: FileIndex) =
  ## Main entry point for NIF-based C code generation.
  ## Traverses the module dependency graph and generates C code.

  # Reset backend state
  resetForBackend(g)

  # Load system module first - it's always needed and contains essential hooks
  if g.config.m.systemFileIdx != InvalidFileIdx:
    let precomp = moduleFromNifFile(g, g.config.m.systemFileIdx)
    g.systemModule = precomp.module

  # Load all modules in dependency order using stack traversal
  # This must happen BEFORE any code generation so that hooks are loaded into loadedOps
  let modules = loadModuleDependencies(g, mainFileIdx)
  if modules.len == 0:
    rawMessage(g.config, errGenerated,
      "Cannot load NIF file for main module: " & toFullPath(g.config, mainFileIdx))
    return

  # Set up backend modules for all modules that need code generation
  for module in modules:
    discard setupNifBackendModule(g, module)

  # Also ensure system module is set up and generated first if it exists
  if g.systemModule != nil:
    let systemBmod = BModuleList(g.backend).modules[g.systemModule.position]
    if systemBmod == nil:
      discard setupNifBackendModule(g, g.systemModule)
    generateCodeForModule(g, g.systemModule)

  # Generate code for all modules except main (main goes last)
  # This ensures all modules are added to modulesClosed

  for module in modules:
    if module != g.systemModule:
      generateCodeForModule(g, module)

  for m in BModuleList(g.backend).modules:
    if m != nil:
      assert m.module != nil
      if sfMainModule notin m.module.flags:
        finishModule g, m

  # Write C files
  if g.backend != nil:
    cgenWriteModules(g.backend, g.config)

  # Run C compiler
  if g.config.cmd != cmdTcc:
    extccomp.callCCompiler(g.config)
    if not g.config.hcrOn:
      extccomp.writeJsonBuildInstructions(g.config, g.cachedFiles)
