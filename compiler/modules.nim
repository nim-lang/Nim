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
  ast, astalgo, magicsys, msgs, options, idents, lexer, passes, syntaxes,
  llstream, modulegraphs, lineinfos, pathutils, tables

import std/[os, strutils, hashes]

proc resetSystemArtifacts*(g: ModuleGraph) =
  magicsys.resetSysTypes(g)

template getModuleIdent(graph: ModuleGraph, filename: AbsoluteFile): PIdent =
  getIdent(graph.cache, splitFile(filename).name)

template packageId(): untyped {.dirty.} = ItemId(module: PackageModuleId, item: int32(fileIdx))

proc getPackage(graph: ModuleGraph; fileIdx: FileIndex): PSym =
  ## returns package symbol (skPackage) for yet to be defined module for fileIdx
  let filename = AbsoluteFile toFullPath(graph.config, fileIdx)
  let name = getModuleIdent(graph, filename)
  let info = newLineInfo(fileIdx, 1, 1)
  let
    pck = getPackageName(graph.config, filename.string)
    pck2 = if pck.len > 0: pck else: "unknown"
    pack = getIdent(graph.cache, pck2)
  result = strTableGet(graph.packageSyms, pack)
  if result == nil:
    result = newSym(skPackage, getIdent(graph.cache, pck2), packageId(),
                    nil, info)
  else:
    let existing = getExport(graph, result, name)
    if existing != nil and existing.info.fileIndex != info.fileIndex:
      # produce a fake Nimble package to resolve conflicts
      let pck3 = fakePackageName(graph.config, filename)
      # this makes the new package's owner be the original package
      result = newSym(skPackage, getIdent(graph.cache, pck3), packageId(),
                      result, info)
  initExports(graph, result)
  strTableAdd(graph.packageSyms, result)

type
  SubType = enum                ## tokens we use for rodfile pathsubs
    stCache = "nimcache"
    #stConfig = "config"        # i don't want to pass a config directory
    stNimbleDir = "nimbledir"
    stNimblePath = "nimblepath"
    stProjectDir = "projectdir"
    stProjectPath = "projectpath"
    stLib = "lib"
    stNim = "nim"
    stHome = "home"

iterator pathSubsFor(config: ConfigRef; sub: SubType): AbsoluteDir =
  ## a convenience to work around the compiler's broken pathSubs
  let pattern = "$" & $sub
  if sub notin {stNimbleDir, stNimblePath}:
    # if we don't need to handle a nimbledir or nimblepath, it's one and done
    yield config.pathSubs(pattern, "").toAbsoluteDir
  else:
    for path in config.nimbleSubs(pattern):
      yield path.toAbsoluteDir

iterator pathSubstitutions*(config: ConfigRef; path: AbsoluteFile): string =
  ## compute the possible path substitions, including the original path
  for sub in SubType.items:
    for attempt in pathSubsFor(config, sub):
      if not attempt.isEmpty and not isRootDir($attempt):
        if startsWith($path, $attempt):
          # it's okay if paths that we yield here don't end in a DirSep
          yield replace($path, $attempt, "$" & $sub)
  # finally, yield the original path
  yield $path

proc moduleId(config: ConfigRef; fn: AbsoluteFile): int32 =
  ## compute stable module identifier by pathsub'ing filename
  for path in pathSubstitutions(config, fn):
    return int32(hash(path) and int32.high)
  internalError(config, "unable to determine module id")

proc newModule(graph: ModuleGraph; fileIdx: FileIndex): PSym =
  let filename = AbsoluteFile toFullPath(graph.config, fileIdx)
  let moduleId = moduleId(graph.config, filename)
  # We cannot call ``newSym`` here, because we have to circumvent the ID
  # mechanism, which we do in order to assign each module a persistent ID.
  result = PSym(kind: skModule, name: getModuleIdent(graph, filename),
                itemId: ItemId(module: moduleId, item: 0'i32),
                position: int fileIdx, info: newLineInfo(fileIdx, 1, 1))
  if not isNimIdentifier(result.name.s):
    rawMessage(graph.config, errGenerated, "invalid module name: " & result.name.s)

  # due to the addition of exports, we setup the module's iface before
  # we determine which package to assign as the owner
  registerModule(graph, result)

  # XXX: this should arguably move into the module registration
  result.owner = getPackage(graph, FileIndex result.position)
  addExport(graph, result.owner, result)     # add module to package exports

proc compileModule*(graph: ModuleGraph; fileIdx: FileIndex; flags: TSymFlags): PSym =
  var flags = flags
  if fileIdx == graph.config.projectMainIdx2: flags.incl sfMainModule
  result = graph.getModule(fileIdx)

  template processModuleAux =
    var s: PLLStream
    if sfMainModule in flags:
      if graph.config.projectIsStdin: s = stdin.llStreamOpen
      elif graph.config.projectIsCmd: s = llStreamOpen(graph.config.cmdInput)
    discard processModule(graph, result, idGeneratorFromModule(result), s)

  if result == nil:
    let filename = AbsoluteFile toFullPath(graph.config, fileIdx)
    result = newModule(graph, fileIdx)
    result.flags.incl flags
    processModuleAux()
  elif graph.isDirty(result):
    result.flags.excl sfDirty
    clearExports(graph, result)
    result.ast = nil
    processModuleAux()
    graph.markClientsDirty(fileIdx)

proc importModule*(graph: ModuleGraph; s: PSym, fileIdx: FileIndex): PSym =
  # this is called by the semantic checking phase
  assert graph.config != nil
  result = compileModule(graph, fileIdx, {})
  graph.addDep(s, fileIdx)
  # keep track of import relationships
  if graph.config.hcrOn:
    graph.importDeps.mgetOrPut(FileIndex(s.position), @[]).add(fileIdx)
  #if sfSystemModule in result.flags:
  #  localError(result.info, errAttemptToRedefine, result.name.s)
  # restore the notes for outer module:
  graph.config.notes =
    if s.getnimblePkgId == graph.config.mainPackageId or isDefined(graph.config, "booting"): graph.config.mainPackageNotes
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
    fatal(conf, newLineInfo(conf, AbsoluteFile(commandLineDesc), 1, 1), errGenerated,
        "command expects a filename")
  conf.projectMainIdx = fileInfoIdx(conf, addFileExt(conf.projectFull, NimExt))

proc compileProject*(graph: ModuleGraph; projectFileIdx = InvalidFileIdx) =
  connectCallbacks(graph)
  let conf = graph.config
  wantMainModule(conf)
  let systemFileIdx = fileInfoIdx(conf, conf.libpath / RelativeFile"system.nim")
  let projectFile = if projectFileIdx == InvalidFileIdx: conf.projectMainIdx else: projectFileIdx
  conf.projectMainIdx2 = projectFile

  let packSym = getPackage(graph, projectFile)
  graph.config.mainPackageId = packSym.getnimblePkgId
  graph.importStack.add projectFile

  if projectFile == systemFileIdx:
    discard graph.compileModule(projectFile, {sfMainModule, sfSystemModule})
  else:
    graph.compileSystemModule()
    discard graph.compileModule(projectFile, {sfMainModule})

template makeModule*(graph: ModuleGraph; filename: AbsoluteFile): PSym =
  newModule(graph, fileInfoIdx(graph.config, filename))

template makeModule*(graph: ModuleGraph; filename: string): PSym =
  makeModule(graph, AbsoluteFile filename)

template makeStdinModule*(graph: ModuleGraph): PSym =
  makeModule(graph, AbsoluteFile"stdin")
