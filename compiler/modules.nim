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
  ast, astalgo, magicsys, securehash, rodread, msgs, cgendata, sigmatch, options,
  idents, os, lexer, idgen, passes, syntaxes, llstream, modulegraphs

when false:
  type
    TNeedRecompile* = enum Maybe, No, Yes, Probing, Recompiled
    THashStatus* = enum hashNotTaken, hashCached, hashHasChanged, hashNotChanged

    TModuleInMemory* = object
      hash*: SecureHash
      deps*: seq[int32] ## XXX: slurped files are currently not tracked

      needsRecompile*: TNeedRecompile
      hashStatus*: THashStatus

  var
    gCompiledModules: seq[PSym] = @[]
    gMemCacheData*: seq[TModuleInMemory] = @[]
      ## XXX: we should implement recycling of file IDs
      ## if the user keeps renaming modules, the file IDs will keep growing
    gFuzzyGraphChecking*: bool # nimsuggest uses this. XXX figure out why.

  proc hashChanged(fileIdx: int32): bool =
    internalAssert fileIdx >= 0 and fileIdx < gMemCacheData.len

    template updateStatus =
      gMemCacheData[fileIdx].hashStatus = if result: hashHasChanged
                                         else: hashNotChanged
      # echo "TESTING Hash: ", fileIdx.toFilename, " ", result

    case gMemCacheData[fileIdx].hashStatus
    of hashHasChanged:
      result = true
    of hashNotChanged:
      result = false
    of hashCached:
      let newHash = secureHashFile(fileIdx.toFullPath)
      result = newHash != gMemCacheData[fileIdx].hash
      gMemCacheData[fileIdx].hash = newHash
      updateStatus()
    of hashNotTaken:
      gMemCacheData[fileIdx].hash = secureHashFile(fileIdx.toFullPath)
      result = true
      updateStatus()

  proc doHash(fileIdx: int32) =
    if gMemCacheData[fileIdx].hashStatus == hashNotTaken:
      # echo "FIRST Hash: ", fileIdx.ToFilename
      gMemCacheData[fileIdx].hash = secureHashFile(fileIdx.toFullPath)

  proc resetModule*(fileIdx: int32) =
    # echo "HARD RESETTING ", fileIdx.toFilename
    if fileIdx <% gMemCacheData.len:
      gMemCacheData[fileIdx].needsRecompile = Yes
    if fileIdx <% gCompiledModules.len:
      gCompiledModules[fileIdx] = nil
    if fileIdx <% cgendata.gModules.len:
      cgendata.gModules[fileIdx] = nil

  proc resetModule*(module: PSym) =
    let conflict = getModule(module.position.int32)
    if conflict == nil: return
    doAssert conflict == module
    resetModule(module.position.int32)
    initStrTable(module.tab)

  proc resetAllModules* =
    for i in 0..gCompiledModules.high:
      if gCompiledModules[i] != nil:
        resetModule(i.int32)
    resetPackageCache()
    # for m in cgenModules(): echo "CGEN MODULE FOUND"

  proc resetAllModulesHard* =
    resetPackageCache()
    gCompiledModules.setLen 0
    gMemCacheData.setLen 0
    magicsys.resetSysTypes()
    # XXX
    #gOwners = @[]

  proc checkDepMem(fileIdx: int32): TNeedRecompile =
    template markDirty =
      resetModule(fileIdx)
      return Yes

    if gFuzzyGraphChecking:
      if gMemCacheData[fileIdx].needsRecompile != Maybe:
        return gMemCacheData[fileIdx].needsRecompile
    else:
      # cycle detection: We claim that a cycle does no harm.
      if gMemCacheData[fileIdx].needsRecompile == Probing:
        return No

    if optForceFullMake in gGlobalOptions or hashChanged(fileIdx):
      markDirty()

    if gMemCacheData[fileIdx].deps != nil:
      gMemCacheData[fileIdx].needsRecompile = Probing
      for dep in gMemCacheData[fileIdx].deps:
        let d = checkDepMem(dep)
        if d in {Yes, Recompiled}:
          # echo fileIdx.toFilename, " depends on ", dep.toFilename, " ", d
          markDirty()

    gMemCacheData[fileIdx].needsRecompile = No
    return No

proc resetSystemArtifacts*() =
  magicsys.resetSysTypes()

proc newModule(graph: ModuleGraph; fileIdx: int32): PSym =
  # We cannot call ``newSym`` here, because we have to circumvent the ID
  # mechanism, which we do in order to assign each module a persistent ID.
  new(result)
  result.id = - 1             # for better error checking
  result.kind = skModule
  let filename = fileIdx.toFullPath
  result.name = getIdent(splitFile(filename).name)
  if not isNimIdentifier(result.name.s):
    rawMessage(errInvalidModuleName, result.name.s)

  result.info = newLineInfo(fileIdx, 1, 1)
  let pack = getIdent(getPackageName(filename))
  var packSym = graph.packageSyms.strTableGet(pack)
  if packSym == nil:
    let pck = getPackageName(filename)
    let pck2 = if pck.len > 0: pck else: "unknown"
    packSym = newSym(skPackage, getIdent(pck2), nil, result.info)
    initStrTable(packSym.tab)
    graph.packageSyms.strTableAdd(packSym)

  result.owner = packSym
  result.position = fileIdx

  growCache graph.modules, fileIdx
  graph.modules[result.position] = result

  incl(result.flags, sfUsed)
  initStrTable(result.tab)
  strTableAdd(result.tab, result) # a module knows itself
  let existing = strTableGet(packSym.tab, result.name)
  if existing != nil and existing.info.fileIndex != result.info.fileIndex:
    localError(result.info, "module names need to be unique per Nimble package; module clashes with " & existing.info.fileIndex.toFullPath)
  # strTableIncl() for error corrections:
  discard strTableIncl(packSym.tab, result)

proc compileModule*(graph: ModuleGraph; fileIdx: int32; cache: IdentCache, flags: TSymFlags): PSym =
  result = graph.getModule(fileIdx)
  if result == nil:
    #growCache gMemCacheData, fileIdx
    #gMemCacheData[fileIdx].needsRecompile = Probing
    result = newModule(graph, fileIdx)
    var rd: PRodReader
    result.flags = result.flags + flags
    if sfMainModule in result.flags:
      gMainPackageId = result.owner.id

    if gCmd in {cmdCompileToC, cmdCompileToCpp, cmdCheck, cmdIdeTools}:
      rd = handleSymbolFile(result, cache)
      if result.id < 0:
        internalError("handleSymbolFile should have set the module's ID")
        return
    else:
      result.id = getID()
    discard processModule(graph, result,
      if sfMainModule in flags and gProjectIsStdin: stdin.llStreamOpen else: nil,
      rd, cache)
    #if optCaasEnabled in gGlobalOptions:
    #  gMemCacheData[fileIdx].needsRecompile = Recompiled
    #  if validFile: doHash fileIdx
  elif graph.isDirty(result):
    result.flags.excl sfDirty
    # reset module fields:
    initStrTable(result.tab)
    result.ast = nil
    discard processModule(graph, result,
      if sfMainModule in flags and gProjectIsStdin: stdin.llStreamOpen else: nil,
      nil, cache)
    graph.markClientsDirty(fileIdx)
    when false:
      if checkDepMem(fileIdx) == Yes:
        result = compileModule(fileIdx, cache, flags)
      else:
        result = gCompiledModules[fileIdx]

proc importModule*(graph: ModuleGraph; s: PSym, fileIdx: int32;
                   cache: IdentCache): PSym {.procvar.} =
  # this is called by the semantic checking phase
  result = compileModule(graph, fileIdx, cache, {})
  graph.addDep(s, fileIdx)
  #if sfSystemModule in result.flags:
  #  localError(result.info, errAttemptToRedefine, result.name.s)
  # restore the notes for outer module:
  gNotes = if s.owner.id == gMainPackageId: gMainPackageNotes
           else: ForeignPackageNotes

proc includeModule*(graph: ModuleGraph; s: PSym, fileIdx: int32;
                    cache: IdentCache): PNode {.procvar.} =
  result = syntaxes.parseFile(fileIdx, cache)
  graph.addDep(s, fileIdx)
  graph.addIncludeDep(s.position.int32, fileIdx)

proc compileSystemModule*(graph: ModuleGraph; cache: IdentCache) =
  if magicsys.systemModule == nil:
    systemFileIdx = fileInfoIdx(options.libpath/"system.nim")
    discard graph.compileModule(systemFileIdx, cache, {sfSystemModule})

proc wantMainModule* =
  if gProjectFull.len == 0:
    fatal(gCmdLineInfo, errCommandExpectsFilename)
  gProjectMainIdx = addFileExt(gProjectFull, NimExt).fileInfoIdx

passes.gIncludeFile = includeModule
passes.gImportModule = importModule

proc compileProject*(graph: ModuleGraph; cache: IdentCache;
                     projectFileIdx = -1'i32) =
  wantMainModule()
  let systemFileIdx = fileInfoIdx(options.libpath / "system.nim")
  let projectFile = if projectFileIdx < 0: gProjectMainIdx else: projectFileIdx
  if projectFile == systemFileIdx:
    discard graph.compileModule(projectFile, cache, {sfMainModule, sfSystemModule})
  else:
    graph.compileSystemModule(cache)
    discard graph.compileModule(projectFile, cache, {sfMainModule})

proc makeModule*(graph: ModuleGraph; filename: string): PSym =
  result = graph.newModule(fileInfoIdx filename)
  result.id = getID()

proc makeStdinModule*(graph: ModuleGraph): PSym = graph.makeModule"stdin"
