#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements the module handling, including the caching of modules.

import
  ast, astalgo, magicsys, msgs, options,
  idents, lexer, passes, syntaxes, llstream, modulegraphs,
  lineinfos, pathutils, tables, packages

import ic / replayer

proc resetSystemArtifacts*(g: ModuleGraph) =
  magicsys.resetSysTypes(g)

template getModuleIdent(graph: ModuleGraph, filename: AbsoluteFile): PIdent =
  getIdent(graph.cache, splitFile(filename).name)

proc partialInitModule(result: PSym; graph: ModuleGraph; fileIdx: FileIndex; filename: AbsoluteFile) =
  let packSym = getPackage(graph, fileIdx)
  result.owner = packSym
  result.position = int fileIdx

proc newModule(graph: ModuleGraph; fileIdx: FileIndex): PSym =
  let filename = AbsoluteFile toFullPath(graph.config, fileIdx)
  # We cannot call ``newSym`` here, because we have to circumvent the ID
  # mechanism, which we do in order to assign each module a persistent ID.
  result = PSym(kind: skModule, itemId: ItemId(module: int32(fileIdx), item: 0'i32),
                name: getModuleIdent(graph, filename),
                info: newLineInfo(fileIdx, 1, 1))
  if not isNimIdentifier(result.name.s):
    rawMessage(graph.config, errGenerated, "invalid module name: " & result.name.s)
  partialInitModule(result, graph, fileIdx, filename)
  graph.registerModule(result)

proc compileModule*(graph: ModuleGraph; fileIdx: FileIndex; flags: TSymFlags, fromModule: PSym = nil): PSym =
  var flags = flags
  if fileIdx == graph.config.projectMainIdx2: flags.incl sfMainModule
  result = graph.getModule(fileIdx)

  template processModuleAux(moduleStatus) =
    onProcessing(graph, fileIdx, moduleStatus, fromModule = fromModule)
    var s: PLLStream
    if sfMainModule in flags:
      if graph.config.projectIsStdin: s = stdin.llStreamOpen
      elif graph.config.projectIsCmd: s = llStreamOpen(graph.config.cmdInput)
    discard processModule(graph, result, idGeneratorFromModule(result), s)
  if result == nil:
    var cachedModules: seq[FileIndex]
    result = moduleFromRodFile(graph, fileIdx, cachedModules)
    let filename = AbsoluteFile toFullPath(graph.config, fileIdx)
    if result == nil:
      result = newModule(graph, fileIdx)
      result.flags.incl flags
      registerModule(graph, result)
      processModuleAux("import")
    else:
      if sfSystemModule in flags:
        graph.systemModule = result
      partialInitModule(result, graph, fileIdx, filename)
    for m in cachedModules:
      registerModuleById(graph, m)
      replayStateChanges(graph.packed[m.int].module, graph)
      replayGenericCacheInformation(graph, m.int)
  elif graph.isDirty(result):
    result.flags.excl sfDirty
    # reset module fields:
    initStrTables(graph, result)
    result.ast = nil
    processModuleAux("import(dirty)")
    graph.markClientsDirty(fileIdx)

proc importModule*(graph: ModuleGraph; s: PSym, fileIdx: FileIndex): PSym =
  # this is called by the semantic checking phase
  assert graph.config != nil
  result = compileModule(graph, fileIdx, {}, s)
  graph.addDep(s, fileIdx)
  # keep track of import relationships
  if graph.config.hcrOn:
    graph.importDeps.mgetOrPut(FileIndex(s.position), @[]).add(fileIdx)
  #if sfSystemModule in result.flags:
  #  localError(result.info, errAttemptToRedefine, result.name.s)
  # restore the notes for outer module:
  graph.config.notes =
    if graph.config.belongsToProjectPackage(s) or isDefined(graph.config, "booting"): graph.config.mainPackageNotes
    else: graph.config.foreignPackageNotes

proc includeModule*(graph: ModuleGraph; s: PSym, fileIdx: FileIndex): PNode =
  result = syntaxes.parseFile(fileIdx, graph.cache, graph.config)
  graph.addDep(s, fileIdx)
  graph.addIncludeDep(s.position.FileIndex, fileIdx)

proc connectCallbacks*(graph: ModuleGraph) =
  graph.includeFileCallback = includeModule
  graph.importModuleCallback = importModule

proc compileSystemModule*(graph: ModuleGraph) =
  if graph.systemModule == nil:
    connectCallbacks(graph)
    graph.config.m.systemFileIdx = fileInfoIdx(graph.config,
        graph.config.libpath / RelativeFile"system.nim")
    discard graph.compileModule(graph.config.m.systemFileIdx, {sfSystemModule})

proc wantMainModule*(conf: ConfigRef) =
  if conf.projectFull.isEmpty:
    fatal(conf, gCmdLineInfo, "command expects a filename")
  conf.projectMainIdx = fileInfoIdx(conf, addFileExt(conf.projectFull, NimExt))

proc compileProject*(graph: ModuleGraph; projectFileIdx = InvalidFileIdx) =
  connectCallbacks(graph)
  let conf = graph.config
  wantMainModule(conf)
  configComplete(graph)

  let systemFileIdx = fileInfoIdx(conf, conf.libpath / RelativeFile"system.nim")
  let projectFile = if projectFileIdx == InvalidFileIdx: conf.projectMainIdx else: projectFileIdx
  conf.projectMainIdx2 = projectFile

  let packSym = getPackage(graph, projectFile)
  graph.config.mainPackageId = packSym.getPackageId
  graph.importStack.add projectFile

  if projectFile == systemFileIdx:
    discard graph.compileModule(projectFile, {sfMainModule, sfSystemModule})
  else:
    graph.compileSystemModule()
    discard graph.compileModule(projectFile, {sfMainModule})

proc makeModule*(graph: ModuleGraph; filename: AbsoluteFile): PSym =
  result = graph.newModule(fileInfoIdx(graph.config, filename))
  registerModule(graph, result)

proc makeModule*(graph: ModuleGraph; filename: string): PSym =
  result = makeModule(graph, AbsoluteFile filename)

proc makeStdinModule*(graph: ModuleGraph): PSym = graph.makeModule(AbsoluteFile"stdin")
