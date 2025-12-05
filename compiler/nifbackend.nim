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

when defined(nimKochBootstrap):
  # During bootstrap, NIF functionality is not available
  import ".." / [ast, options, lineinfos, modulegraphs, pathutils, msgs]

  proc generateCode*(g: ModuleGraph; mainFileIdx: FileIndex) =
    rawMessage(g.config, errGenerated,
      "NIF backend not available during bootstrap build")

else:
  import std/[intsets, tables, sets, os]

  when defined(nimPreviewSlimSystem):
    import std/assertions

  import ast, options, lineinfos, modulegraphs, cgendata, cgen,
    pathutils, extccomp, msgs, modulepaths, idents, types, ast2nif

  proc loadModuleDependencies(g: ModuleGraph; mainFileIdx: FileIndex): seq[PSym] =
    ## Traverse the module dependency graph using a stack.
    ## Returns all modules that need code generation, in dependency order.
    var visited = initIntSet()
    var stack: seq[FileIndex] = @[mainFileIdx]
    var modules: seq[PSym] = @[]
    var cachedModules: seq[FileIndex] = @[]

    while stack.len > 0:
      let fileIdx = stack.pop()

      if visited.containsOrIncl(int(fileIdx)):
        continue

      # Load module from NIF
      let module = moduleFromNifFile(g, fileIdx, cachedModules)
      if module == nil:
        continue

      modules.add module

      # Add dependencies to stack (they come from cachedModules)
      for dep in cachedModules:
        if not visited.contains(int(dep)):
          stack.add dep
      cachedModules.setLen(0)

    result = modules

  proc setupNifBackendModule(g: ModuleGraph; module: PSym): BModule =
    ## Set up a BModule for code generation from a NIF module.
    if g.backend == nil:
      g.backend = cgendata.newModuleList(g)
    result = cgen.newModule(BModuleList(g.backend), module, g.config)

  proc generateCodeForModule(g: ModuleGraph; module: PSym) =
    ## Generate C code for a single module.
    let moduleId = module.position
    var bmod = BModuleList(g.backend).modules[moduleId]
    if bmod == nil:
      bmod = setupNifBackendModule(g, module)

    # Generate code for the module's top-level statements
    if module.ast != nil:
      cgen.genTopLevelStmt(bmod, module.ast)

    # Finalize the module
    finalCodegenActions(g, bmod, newNodeI(nkStmtList, module.info))

    # Generate dispatcher methods
    for disp in getDispatchers(g):
      genProcAux(bmod, disp)

  proc generateCode*(g: ModuleGraph; mainFileIdx: FileIndex) =
    ## Main entry point for NIF-based C code generation.
    ## Traverses the module dependency graph and generates C code.

    # Reset backend state
    resetForBackend(g)

    # Load all modules in dependency order using stack traversal
    let modules = loadModuleDependencies(g, mainFileIdx)
    if modules.len == 0:
      rawMessage(g.config, errGenerated,
        "Cannot load NIF file for main module: " & toFullPath(g.config, mainFileIdx))
      return

    # Set up backend modules
    for module in modules:
      discard setupNifBackendModule(g, module)

    # Generate code for all modules except main (main goes last)
    let mainModule = g.getModule(mainFileIdx)
    for module in modules:
      if module != mainModule:
        generateCodeForModule(g, module)

    # Generate main module last (so all init procs are registered)
    if mainModule != nil:
      generateCodeForModule(g, mainModule)

    # Write C files
    if g.backend != nil:
      cgenWriteModules(g.backend, g.config)

    # Run C compiler
    if g.config.cmd != cmdTcc:
      extccomp.callCCompiler(g.config)
      if not g.config.hcrOn:
        extccomp.writeJsonBuildInstructions(g.config, g.cachedFiles)
