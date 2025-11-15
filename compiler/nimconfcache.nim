import options, pathutils, platform, condsyms
import std/[assertions, os, sets, strtabs, times]
from std/strutils import parseEnum
import "../dist/nimony/src/lib" / [bitabs, lineinfos, nifreader, nifstreams, nifcursors]

proc toNifPath(p: AbsoluteDir|AbsoluteFile): string =
  result = relativePath(p.string, getCurrentDir(), '/')
  if p.string.len <= result.len:
    result = p.string

template buildTree(dest: var TokenBuf; tag: string; body: untyped): untyped =
  buildTree(dest, pool.tags.getOrIncl(tag), NoLineInfo, body)

proc toNif(dest: var TokenBuf; tag: string; tab: StringTableRef) =
  dest.buildTree tag:
    for key, val in pairs(tab):
      dest.buildTree "kv":
        dest.addStrLit key
        dest.addStrLit val

proc toNif(dest: var TokenBuf; tag: string; strSeq: seq[string]) =
  dest.buildTree tag:
    for s in strSeq:
      dest.addStrLit s

proc toNif(dest: var TokenBuf; tag: string; absDirs: seq[AbsoluteDir]) =
  # remove duplicated paths without changing the order of paths
  var paths: seq[string] = @[]
  # use HashSet[string] to avoid O(n^2) computation
  var inPaths = initHashSet[string]()
  for p in absDirs:
    let p2 = toNifPath p
    if not inPaths.containsOrIncl(p2):
      paths.add p2
  dest.buildTree tag:
    for p in paths:
      dest.addStrLit p

proc expectTag(n: Cursor; tag: string) =
  assert pool.tags[n.tagId] == tag, "expected tag: " & tag & " but got: " & pool.tags[n.tagId]

proc fromNif[T: enum](result: var T; n: var Cursor) =
  result = parseEnum[T](pool.strings[n.litId])
  inc n

proc fromNif[T: enum](result: var set[T]; tag: string; n: var Cursor) =
  expectTag n, tag
  inc n
  # clear it so that it has the same value as it was stored to the cache.
  # some switches turn off options that were turned on when conf was initialized.
  result = {}
  assert n.kind in {StringLit, ParRi}
  while n.kind != ParRi:
    result.incl parseEnum[T](pool.strings[n.litId])
    inc n
  inc n

proc fromNif2[T: enum](result: var set[T]; tag: string; n: var Cursor) =
  # same to fromNif but works with enums `parseEnum` doesn't support.
  # e.g. TNoteKind
  expectTag n, tag
  inc n
  result = {}
  assert n.kind in {IntLit, ParRi}
  while n.kind != ParRi:
    result.incl pool.integers[n.intId].T
    inc n
  inc n

proc fromNif(result: StringTableRef; tag: string; n: var Cursor) =
  expectTag n, tag
  inc n
  result.clear
  assert n.kind in {ParLe, ParRi}
  while n.kind != ParRi:
    expectTag n, "kv"
    inc n
    assert n.kind == StringLit
    let key = pool.strings[n.litId]
    inc n
    let val = pool.strings[n.litId]
    inc n
    result[key] = val
    assert n.kind == ParRi
    inc n
  inc n

proc fromNif(result: var AbsoluteDir; n: var Cursor) =
  let d = pool.strings[n.litId]
  inc n
  result = if d.len > 0: d.toAbsoluteDir else: AbsoluteDir""

proc fromNif(result: var seq[string]; tag: string; n: var Cursor) =
  expectTag n, tag
  inc n
  result.setLen(0)
  assert n.kind in {StringLit, ParRi}
  while n.kind != ParRi:
    result.add pool.strings[n.litId]
    inc n
  inc n

proc fromNif(result: var seq[AbsoluteDir]; tag: string; n: var Cursor) =
  expectTag n, tag
  inc n
  result.setLen(0)
  assert n.kind in {StringLit, ParRi}
  while n.kind != ParRi:
    result.add pool.strings[n.litId].toAbsoluteDir
    inc n
  inc n

proc configToNif(conf: ConfigRef; dest: var TokenBuf) =
  # store data used to decide whether to use cache or eval config files
  dest.addStrLit conf.commandLine
  dest.buildTree "sources":
    for f in conf.m.fileInfos:
      dest.addStrLit f.fullPath.toNifPath

  # store fields that can be changed on config files
  # see processSwitch proc in commands.nim
  dest.addStrLit $conf.backend
  dest.addStrLit $conf.target.targetOS
  dest.addStrLit $conf.target.targetCPU

  #echo "conf.options"
  #echo conf.options
  dest.buildTree "options":
    for opt in conf.options:
      dest.addStrLit $opt

  #echo "conf.globalOptions"
  #echo conf.globalOptions
  dest.buildTree "globalOptions":
    for opt in conf.globalOptions:
      dest.addStrLit $opt

  dest.buildTree "macrosToExpand":
    for m in conf.macrosToExpand.keys:
      dest.addStrLit m

  dest.buildTree "arcToExpand":
    for a in conf.arcToExpand.keys:
      dest.addStrLit a

  dest.addStrLit $conf.filenameOption
  dest.addStrLit conf.unitSep

  #echo "conf.selectedGC"
  #echo conf.selectedGC
  dest.addStrLit $conf.selectedGC

  #echo "conf.exc"
  #echo conf.exc
  dest.addStrLit $conf.exc

  dest.addIntLit conf.hintProcessingDots.int

  #echo "conf.verbosity"
  #echo conf.verbosity
  dest.addIntLit conf.verbosity

  #echo "conf.numberOfProcessors"
  #echo conf.numberOfProcessors
  dest.addIntLit conf.numberOfProcessors

  #echo "conf.spellSuggestMax"
  #echo conf.spellSuggestMax
  dest.addIntLit conf.spellSuggestMax

  #echo "conf.nimbasePattern"
  #echo conf.nimbasePattern
  dest.addStrLit conf.nimbasePattern

  dest.buildTree "features":
    for f in conf.features:
      dest.addStrLit $f

  dest.buildTree "legacyFeatures":
    for f in conf.legacyFeatures:
      dest.addStrLit $f

  dest.addStrLit $conf.cCompiler

  # stores TNoteKind as int as parseEnum doesn't work
  dest.buildTree "modifiedyNotes":
    for n in conf.modifiedyNotes:
      dest.addIntLit n.ord
  dest.buildTree "foreignPackageNotes":
    for n in conf.foreignPackageNotes:
      dest.addIntLit n.ord
  dest.buildTree "notes":
    for n in conf.notes:
      dest.addIntLit n.ord
  dest.buildTree "warningAsErrors":
    for n in conf.warningAsErrors:
      dest.addIntLit n.ord
  dest.buildTree "mainPackageNotes":
    for n in conf.mainPackageNotes:
      dest.addIntLit n.ord

  dest.addIntLit conf.errorMax
  dest.addIntLit conf.maxLoopIterationsVM
  dest.addIntLit conf.maxCallDepthVM

  dest.toNif "configVars", conf.configVars

  dest.buildTree "defines":
    for def in definedSymbolNames(conf.symbols):
      dest.addStrLit def

  dest.toNif "nimblepaths", conf.nimblePaths
  dest.toNif "searchPaths", conf.searchPaths

  dest.addStrLit conf.outFile.string
  dest.addStrLit conf.outDir.toNifPath
  dest.addStrLit conf.prefixDir.toNifPath
  dest.addStrLit conf.libpath.toNifPath
  dest.addStrLit conf.nimcacheDir.toNifPath

  dest.buildTree "dllOverrides":
    for s in conf.dllOverrides.keys:
      dest.addStrLit s

  dest.toNif "moduleOverrides", conf.moduleOverrides

  dest.toNif "implicitImports", conf.implicitImports
  dest.toNif "implicitIncludes", conf.implicitIncludes

  dest.addStrLit conf.docSeeSrcUrl
  dest.addStrLit conf.docRoot
  dest.addStrLit conf.docCmd

  dest.buildTree "configFiles":
    for c in conf.configFiles:
      dest.addStrLit c.toNifPath

  dest.toNif "cIncludes", conf.cIncludes
  dest.toNif "cLibs", conf.cLibs
  dest.toNif "cLinkedLibs", conf.cLinkedLibs
  dest.toNif "externalToLink", conf.externalToLink
  dest.addStrLit conf.linkOptionsCmd
  dest.toNif "compileOptionsCmd", conf.compileOptionsCmd

proc cfgCachePath(conf: ConfigRef): (AbsoluteDir, RelativeFile) =
  (conf.projectPath / RelativeDir"nimcache", RelativeFile"cache.cfg.nif")

proc sourcesChanged(conf: ConfigRef; n: var Cursor; modTime: Time): HashSet[string] =
  result = initHashSet[string](8)
  assert pool.tags[n.tagId] == "config"
  inc n
  assert n.kind == StringLit
  let cmdline = pool.strings[n.litId]
  inc n
  if cmdline != conf.commandLine:
    #echo "commandLine is changed, dont use cache"
    discard
  else:
    assert pool.tags[n.tagId] == "sources"
    inc n
    while n.kind != ParRi:
      assert n.kind == StringLit
      let dep = pool.strings[n.litId]
      inc n
      if not fileExists(dep):
        #echo dep, " is removed"
        return default(typeof(result))
      elif getLastModificationTime(dep) >= modTime:
        #echo dep, " is changed"
        return default(typeof(result))
      else:
        result.incl dep.toAbsolute(getCurrentDir().AbsoluteDir).string
    inc n

proc loadConfigsFromNif(conf: ConfigRef; n: var Cursor) =
  fromNif conf.backend, n
  var targetOS = default(TSystemOS)
  var targetCPU = default(TSystemCPU)
  fromNif targetOS, n
  fromNif targetCPU, n
  conf.target.setTarget(targetOS, targetCPU)

  fromNif conf.options, "options", n
  fromNif conf.globalOptions, "globalOptions", n

  conf.macrosToExpand.clear
  expectTag n, "macrosToExpand"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let m = pool.strings[n.litId]
    inc n
    conf.macrosToExpand[m] = "T"
  inc n

  conf.arcToExpand.clear
  expectTag n, "arcToExpand"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let m = pool.strings[n.litId]
    inc n
    conf.arcToExpand[m] = "T"
  inc n

  fromNif conf.filenameOption, n
  conf.unitSep = pool.strings[n.litId]
  inc n

  fromNif conf.selectedGC, n
  fromNif conf.exc, n
  conf.hintProcessingDots = pool.integers[n.intId].bool
  inc n
  conf.verbosity = pool.integers[n.intId]
  inc n
  #echo conf.verbosity
  conf.numberOfProcessors = pool.integers[n.intId]
  inc n
  #echo conf.numberOfProcessors
  conf.spellSuggestMax = pool.integers[n.intId]
  inc n
  #echo conf.spellSuggestMax
  conf.nimbasePattern = pool.strings[n.litId]
  inc n
  #echo conf.nimbasePattern

  fromNif conf.features, "features", n
  fromNif conf.legacyFeatures, "legacyFeatures", n
  fromNif conf.cCompiler, n

  fromNif2 conf.modifiedyNotes, "modifiedyNotes", n
  fromNif2 conf.foreignPackageNotes, "foreignPackageNotes", n
  fromNif2 conf.notes, "notes", n
  fromNif2 conf.warningAsErrors, "warningAsErrors", n
  fromNif2 conf.mainPackageNotes, "mainPackageNotes", n

  conf.errorMax = pool.integers[n.intId]
  inc n
  conf.maxLoopIterationsVM = pool.integers[n.intId]
  inc n
  conf.maxCallDepthVM = pool.integers[n.intId]
  inc n

  fromNif conf.configVars, "configVars", n

  conf.symbols.clear
  expectTag n, "defines"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let def = pool.strings[n.litId]
    inc n
    conf.symbols.defineSymbol(def)
  inc n

  fromNif conf.nimblePaths, "nimblepaths", n
  fromNif conf.searchPaths, "searchPaths", n

  conf.outFile = pool.strings[n.litId].RelativeFile
  inc n
  fromNif conf.outDir, n
  fromNif conf.prefixDir, n
  fromNif conf.libpath, n
  fromNif conf.nimcacheDir, n

  expectTag n, "dllOverrides"
  inc n
  while n.kind != ParRi:
    conf.inclDynlibOverride(pool.strings[n.litId])
    inc n
  inc n
  fromNif conf.moduleOverrides, "moduleOverrides", n

  fromNif conf.implicitImports, "implicitImports", n
  fromNif conf.implicitIncludes, "implicitIncludes", n

  conf.docSeeSrcUrl = pool.strings[n.litId]
  inc n
  conf.docRoot = pool.strings[n.litId]
  inc n
  conf.docCmd = pool.strings[n.litId]
  inc n

  expectTag n, "configFiles"
  inc n
  while n.kind != ParRi:
    conf.configFiles.add pool.strings[n.litId].toAbsolute(getCurrentDir().AbsoluteDir)
    inc n
  inc n

  fromNif conf.cIncludes, "cIncludes", n
  fromNif conf.cLibs, "cLibs", n
  fromNif conf.cLinkedLibs, "cLinkedLibs", n
  fromNif conf.externalToLink, "externalToLink", n

  conf.linkOptionsCmd = pool.strings[n.litId]
  inc n

  fromNif conf.compileOptionsCmd, "compileOptionsCmd", n

proc sourceChanged*(conf: ConfigRef): HashSet[string] =
  result = HashSet[string]()
  let (dir, file) = conf.cfgCachePath()
  let path = dir / file
  if fileExists(path):
    let modTime = getLastModificationTime(path.string)
    var stream = nifstreams.open(path.string)
    discard processDirectives(stream.r)
    var buf = fromStream(stream)
    var n = beginRead(buf)
    result = sourcesChanged(conf, n, modTime)
    endRead(buf)
    stream.close

proc loadConfigsFromCache*(conf: ConfigRef) =
  let (dir, file) = conf.cfgCachePath()
  let path = dir / file
  var stream = nifstreams.open(path.string)
  discard processDirectives(stream.r)
  var buf = fromStream(stream)
  var n = beginRead(buf)
  inc n # skip config
  inc n # skip cmdline
  inc n # skip sources
  while n.kind != ParRi:
    inc n
  inc n
  loadConfigsFromNif(conf, n)
  endRead(buf)
  stream.close

proc storeConfigs*(conf: ConfigRef) =
  if optCacheConfig in conf.globalOptions:
    let (dir, file) = conf.cfgCachePath()
    createDir(dir)
    var dest = createTokenBuf()
    dest.buildTree pool.tags.getOrIncl("config"), NoLineInfo:
      configToNif(conf, dest)
    writeFile dir / file, "(.nif24)\n" & toString(dest)

when isMainModule:
  proc eqlKeys(x, y: StringTableRef): bool =
    for k, v in x:
      if k notin y:
        return false

    return true

  proc `==`(x, y: StringTableRef): bool =
    for k, v in x.pairs:
      if k notin y:
        return false
      elif y[k] != v:
        return false

    return true

  proc assertEq(x, y: ConfigRef) =
    template assertImpl(f: untyped) =
      assert x.f == y.f, $x.f & " / " & $y.f

    assertImpl backend
    assert x.target.targetOS == y.target.targetOS
    assert x.target.targetCPU == y.target.targetCPU
    assertImpl options
    assertImpl globalOptions
    assert eqlKeys(x.macrosToExpand, y.macrosToExpand)
    assert eqlKeys(x.arcToExpand, y.arcToExpand)
    assertImpl filenameOption
    assertImpl unitSep
    assertImpl selectedGC
    assertImpl exc
    assertImpl hintProcessingDots
    assertImpl verbosity
    assertImpl numberOfProcessors
    assertImpl spellSuggestMax
    assertImpl nimbasePattern
    assertImpl features
    assertImpl legacyFeatures
    assertImpl cCompiler
    assertImpl modifiedyNotes
    assertImpl foreignPackageNotes
    assertImpl notes
    assertImpl warningAsErrors
    assertImpl mainPackageNotes
    assertImpl errorMax
    assertImpl maxLoopIterationsVM
    assertImpl maxCallDepthVM
    assertImpl configVars
    assert eqlKeys(x.symbols, y.symbols)
    assertImpl nimblePaths
    assertImpl searchPaths
    assertImpl outFile
    assertImpl outDir
    assertImpl prefixDir
    assertImpl libpath
    assertImpl nimcacheDir
    assert eqlKeys(x.dllOverrides, y.dllOverrides)
    assertImpl moduleOverrides
    assertImpl implicitImports
    assertImpl implicitIncludes
    assertImpl docSeeSrcUrl
    assertImpl docRoot
    assertImpl docCmd
    assertImpl configFiles
    assertImpl cIncludes
    assertImpl cLibs
    assertImpl cLinkedLibs
    assertImpl externalToLink
    assertImpl linkOptionsCmd
    assertImpl compileOptionsCmd

  proc testConfig(conf1: ConfigRef) =
    var dest = createTokenBuf()
    dest.buildTree pool.tags.getOrIncl("config"), NoLineInfo:
      configToNif(conf1, dest)
    let cacheContent = "(.nif24)\n" & toString(dest)
    # writeFile "cachecfg.nif", cacheContent

    var stream = nifstreams.openFromBuffer(cacheContent)
    discard processDirectives(stream.r)
    var buf = fromStream(stream)
    var n = beginRead(buf)
    inc n # skip config
    inc n # skip cmdline
    inc n # skip sources
    while n.kind != ParRi:
      inc n
    inc n
    var conf2 = newConfigRef()
    loadConfigsFromNif(conf2, n)
    endRead(buf)

    assertEq(conf1, conf2)

  block:
    var conf = newConfigRef()
    testConfig conf

  block:
    var conf = newConfigRef()
    conf.backend = backendCpp
    conf.target.setTarget(osAny, cpuArm64)
    conf.options = {optObjCheck, optFieldCheck}
    conf.globalOptions = {gloptNone, optRun}
    conf.macrosToExpand["foomacro"] = "T"
    conf.macrosToExpand["barMacro"] = "T"
    conf.arcToExpand["fooarc"] = "T"
    conf.arcToExpand["barArc"] = "T"
    conf.filenameOption = foCanonical
    conf.unitSep = "\32"
    conf.selectedGC = gcArc
    conf.exc = excSetjmp
    conf.hintProcessingDots = false
    conf.verbosity = 3
    conf.numberOfProcessors = 123
    conf.spellSuggestMax = 456
    conf.nimbasePattern = "foo/nimbase.h"
    conf.features = {callOperator, dynamicBindSym}
    conf.legacyFeatures = {laxEffects, emitGenerics}
    conf.cCompiler = ccCLang
    conf.modifiedyNotes = {}
    conf.foreignPackageNotes = {}
    conf.notes = {}
    conf.warningAsErrors = {}
    conf.mainPackageNotes = {}
    conf.errorMax = 7
    conf.maxLoopIterationsVM = 1234
    conf.maxCallDepthVM = 111
    conf.setConfigVar("foo.bar", "baz")
    conf.setConfigVar("abc.def.ghi", "123")
    conf.setConfigVar(".", "")
    conf.symbols.initDefines()
    conf.symbols.defineSymbol("test")
    conf.nimblePaths = @[AbsoluteDir"/foo", AbsoluteDir"/lib/nimble"]
    conf.searchPaths = @[AbsoluteDir"/lib", AbsoluteDir"/user/lib"]
    conf.outFile = RelativeFile"foo"
    conf.outDir = AbsoluteDir"/foo/var"
    conf.prefixDir = AbsoluteDir"/home/foo/Nim"
    conf.libpath = AbsoluteDir"/home/foo/Nim/lib"
    conf.nimcacheDir = AbsoluteDir"/root/nimcache"
    conf.inclDynlibOverride("foolib")
    conf.inclDynlibOverride("libbar")
    conf.moduleOverrides["foo"] = "overridefoo"
    conf.moduleOverrides["bar"] = "overridebar"
    conf.implicitImports = @["foo", "bar"]
    conf.implicitIncludes = @["foo", "bar"]
    conf.docSeeSrcUrl = "doc see src url"
    conf.docRoot = "doc root"
    conf.docCmd = "doc command"
    conf.configFiles = @[AbsoluteFile"/foo/nim.cfg", AbsoluteFile"/bar/baz/config.nims"]
    conf.cIncludes = @[AbsoluteDir"/include", AbsoluteDir"/foo/bar"]
    conf.cLibs = @[AbsoluteDir"/lib", AbsoluteDir"/foo/bar"]
    conf.cLinkedLibs = @["foolib", "libbar"]
    conf.externalToLink = @["foo", "bar"]
    conf.linkOptionsCmd = "--foo -lbar"
    conf.compileOptionsCmd = @["-O3", "-g"]
    testConfig conf
