#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## implements the module handling

import
  ast, astalgo, magicsys, securehash, rodread, msgs, cgendata, sigmatch, options,
  idents, os, lexer, idgen, passes, syntaxes, llstream, tables, strutils

type
  TNeedRecompile* = enum Maybe, No, Yes, Probing, Recompiled
  THashStatus* = enum hashNotTaken, hashCached, hashHasChanged, hashNotChanged

  TModuleInMemory* = object
    compiledAt*: float
    hash*: SecureHash
    deps*: seq[int32] ## XXX: slurped files are currently not tracked
    needsRecompile*: TNeedRecompile
    hashStatus*: THashStatus

var
  gCompiledModules: seq[PSym] = @[]
  gMemCacheData*: seq[TModuleInMemory] = @[]
    ## XXX: we should implement recycling of file IDs
    ## if the user keeps renaming modules, the file IDs will keep growing

proc getModule*(fileIdx: int32): PSym =
  if fileIdx >= 0 and fileIdx < gCompiledModules.len:
    result = gCompiledModules[fileIdx]

template hash(x: PSym): expr =
  gMemCacheData[x.position].hash

proc hashChanged(fileIdx: int32): bool =
  internalAssert fileIdx >= 0 and fileIdx < gMemCacheData.len

  template updateStatus =
    gMemCacheData[fileIdx].hashStatus = if result: hashHasChanged
                                       else: hashNotChanged
    # echo "TESTING Hash: ", fileIdx.toFilename, " ", result

  case gMemCacheData[fileIdx].hashStatus:
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

proc addDep(x: PSym, dep: int32) =
  growCache gMemCacheData, dep
  gMemCacheData[x.position].deps.safeAdd(dep)

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

  when false:
    if gMemCacheData[fileIdx].needsRecompile != Maybe:
      return gMemCacheData[fileIdx].needsRecompile
  else:
    # cycle detection: We claim that a cycle does no harm.
    if gMemCacheData[fileIdx].needsRecompile == Probing:
      return No
      #return gMemCacheData[fileIdx].needsRecompile

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

proc newModule(fileIdx: int32): PSym =
  # We cannot call ``newSym`` here, because we have to circumvent the ID
  # mechanism, which we do in order to assign each module a persistent ID.
  new(result)
  result.id = - 1             # for better error checking
  result.kind = skModule
  let filename = fileIdx.toFullPath
  let name = splitFile(filename).name
  result.name = getIdent(name)
  if not isNimIdentifier(result.name.s):
    rawMessage(errInvalidModuleName, result.name.s)

  result.info = newLineInfo(fileIdx, 1, 1)
  let owner = getIdent(getPackageName(filename))
  result.owner = newSym(skPackage, owner, nil, result.info)
  result.position = fileIdx

  growCache gMemCacheData, fileIdx
  growCache gCompiledModules, fileIdx
  gCompiledModules[result.position] = result

  incl(result.flags, sfUsed)
  initStrTable(result.tab)
  strTableAdd(result.tab, result) # a module knows itself

  # Keep track of previously defined modules and their owners.
  # Reject this module if it conflicts with one already defined.
  # Such conflicts can be caused by misuse of the `--path` argument,
  # creating ambiguities in module name resolution.
  # For example, see issue #4485.
  var ownerInfo {.global.} =
    initTable[string, tuple[fileIdx: int32, owner: PIdent]]()
  if ownerInfo.hasKey(name):
    let (fileIdxInitial, ownerInitial) = ownerInfo[name]
    if ownerInitial == owner:
      const errFormatStr = "module $1/$2 is already defined in $3"
      localError(result.info,
        errFormatStr % [owner.s, name, fileIdxInitial.toFullPath])
  else:
    ownerInfo[name] = (fileIdx, owner)

proc compileModule*(fileIdx: int32, flags: TSymFlags): PSym =
  result = getModule(fileIdx)
  if result == nil:
    growCache gMemCacheData, fileIdx
    gMemCacheData[fileIdx].needsRecompile = Probing
    result = newModule(fileIdx)
    #var rd = handleSymbolFile(result)
    var rd: PRodReader
    result.flags = result.flags + flags
    if sfMainModule in result.flags:
      gMainPackageId = result.owner.id

    if gCmd in {cmdCompileToC, cmdCompileToCpp, cmdCheck, cmdIdeTools}:
      rd = handleSymbolFile(result)
      if result.id < 0:
        internalError("handleSymbolFile should have set the module\'s ID")
        return
    else:
      result.id = getID()
    if sfMainModule in flags and gProjectIsStdin:
      processModule(result, llStreamOpen(stdin), rd)
    else:
      processModule(result, nil, rd)
    if optCaasEnabled in gGlobalOptions:
      gMemCacheData[fileIdx].compiledAt = gLastCmdTime
      gMemCacheData[fileIdx].needsRecompile = Recompiled
      doHash fileIdx
  else:
    if checkDepMem(fileIdx) == Yes:
      result = compileModule(fileIdx, flags)
    else:
      result = gCompiledModules[fileIdx]

proc importModule*(s: PSym, fileIdx: int32): PSym {.procvar.} =
  # this is called by the semantic checking phase
  result = compileModule(fileIdx, {})
  if optCaasEnabled in gGlobalOptions: addDep(s, fileIdx)
  #if sfSystemModule in result.flags:
  #  localError(result.info, errAttemptToRedefine, result.name.s)
  # restore the notes for outer module:
  gNotes = if s.owner.id == gMainPackageId: gMainPackageNotes
           else: ForeignPackageNotes

proc includeModule*(s: PSym, fileIdx: int32): PNode {.procvar.} =
  result = syntaxes.parseFile(fileIdx)
  if optCaasEnabled in gGlobalOptions:
    growCache gMemCacheData, fileIdx
    addDep(s, fileIdx)
    doHash(fileIdx)

proc `==^`(a, b: string): bool =
  try:
    result = sameFile(a, b)
  except OSError:
    result = false

proc compileSystemModule* =
  if magicsys.systemModule == nil:
    systemFileIdx = fileInfoIdx(options.libpath/"system.nim")
    discard compileModule(systemFileIdx, {sfSystemModule})

proc wantMainModule* =
  if gProjectFull.len == 0:
    fatal(gCmdLineInfo, errCommandExpectsFilename)
  gProjectMainIdx = addFileExt(gProjectFull, NimExt).fileInfoIdx

passes.gIncludeFile = includeModule
passes.gImportModule = importModule

proc compileProject*(projectFileIdx = -1'i32) =
  wantMainModule()
  let systemFileIdx = fileInfoIdx(options.libpath / "system.nim")
  let projectFile = if projectFileIdx < 0: gProjectMainIdx else: projectFileIdx
  if projectFile == systemFileIdx:
    discard compileModule(projectFile, {sfMainModule, sfSystemModule})
  else:
    compileSystemModule()
    discard compileModule(projectFile, {sfMainModule})

proc makeModule*(filename: string): PSym =
  result = newModule(fileInfoIdx filename)
  result.id = getID()

proc makeStdinModule*(): PSym = makeModule"stdin"
