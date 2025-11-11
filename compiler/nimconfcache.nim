import options, pathutils, condsyms
import std/[assertions, os, sets, times]
from std/sequtils import addUnique
from std/strutils import parseEnum
import "../dist/nimony/src/lib" / [bitabs, lineinfos, nifreader, nifstreams, nifcursors]

proc toNifPath(p: AbsoluteDir|AbsoluteFile): string =
  result = relativePath(p.string, getCurrentDir(), '/')
  if p.string.len <= result.len:
    result = p.string

proc configToNif(conf: ConfigRef; dest: var TokenBuf) =
  # store data used to decide whether to use cache or eval config files
  dest.addStrLit conf.commandLine
  dest.buildTree pool.tags.getOrIncl("sources"), NoLineInfo:
    for f in conf.m.fileInfos:
      dest.addStrLit f.fullPath.toNifPath

  # store fields that can be changed on config files
  # see processSwitch proc in commands.nim
  #echo "conf.options"
  #echo conf.options
  dest.buildTree pool.tags.getOrIncl("options"), NoLineInfo:
    for opt in conf.options:
      dest.addStrLit $opt

  #echo "conf.globalOptions"
  #echo conf.globalOptions
  dest.buildTree pool.tags.getOrIncl("globalOptions"), NoLineInfo:
    for opt in conf.globalOptions:
      dest.addStrLit $opt

  #echo "conf.selectedGC"
  #echo conf.selectedGC
  dest.addStrLit $conf.selectedGC

  #echo "conf.exc"
  #echo conf.exc
  dest.addStrLit $conf.exc

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

  dest.buildTree pool.tags.getOrIncl("defines"), NoLineInfo:
    for def in definedSymbolNames(conf.symbols):
      dest.addStrLit def

  #echo "conf.nimblePaths"
  #echo conf.nimblePaths
  dest.buildTree pool.tags.getOrIncl("nimblepaths"), NoLineInfo:
    for p in conf.nimblePaths:
      dest.addStrLit p.toNifPath

  #echo "conf.searchPaths"
  #echo conf.searchPaths
  var paths: seq[string] = @[]
  for p in conf.searchPaths:
    paths.addUnique p.toNifPath
  dest.buildTree pool.tags.getOrIncl("paths"), NoLineInfo:
    for p in paths:
      dest.addStrLit p

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
  assert pool.tags[n.tagId] == "options"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let opt = pool.strings[n.litId]
    inc n
    conf.options.incl parseEnum[TOption](opt)
  inc n
  #echo conf.options

  assert pool.tags[n.tagId] == "globalOptions"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let opt = pool.strings[n.litId]
    inc n
    conf.globalOptions.incl parseEnum[TGlobalOption](opt)
  inc n
  #echo conf.globalOptions

  conf.selectedGC = parseEnum[TGCMode](pool.strings[n.litId])
  inc n
  #echo conf.selectedGC
  conf.exc = parseEnum[ExceptionSystem](pool.strings[n.litId])
  inc n
  #echo conf.exc
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

  assert pool.tags[n.tagId] == "defines"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let def = pool.strings[n.litId]
    inc n
    conf.symbols.defineSymbol(def)
  inc n

  assert pool.tags[n.tagId] == "nimblepaths"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let p = pool.strings[n.litId]
    inc n
    conf.nimblePaths.add p.toAbsoluteDir
  inc n
  #echo "conf.nimblePaths"
  #echo conf.nimblePaths

  assert pool.tags[n.tagId] == "paths"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let p = pool.strings[n.litId]
    inc n
    conf.searchPaths.add p.toAbsoluteDir
  inc n
  #echo "conf.searchPaths"
  #echo conf.searchPaths

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
