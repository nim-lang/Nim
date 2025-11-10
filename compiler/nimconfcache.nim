import options, pathutils, condsyms
import std/[assertions, os, times]
from std/sequtils import addUnique
from std/strutils import parseEnum
import "../dist/nimony/src/lib" / [bitabs, lineinfos, nifreader, nifstreams, nifcursors]

proc toNifPath(p: AbsoluteDir|AbsoluteFile): string =
  result = relativePath(p.string, getCurrentDir(), '/')
  if p.string.len <= result.len:
    result = p.string

proc configToNif(conf: ConfigRef; dest: var TokenBuf) =
  dest.addStrLit conf.commandLine
  dest.buildTree pool.tags.getOrIncl("sources"), NoLineInfo:
    for f in conf.m.fileInfos:
      dest.addStrLit f.fullPath.toNifPath

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

proc sourcesChanged(conf: ConfigRef; n: var Cursor; modTime: Time): bool =
  assert pool.tags[n.tagId] == "config"
  inc n
  assert n.kind == StringLit
  let cmdline = pool.strings[n.litId]
  inc n
  if cmdline != conf.commandLine:
    #echo "commandLine is changed, dont use cache"
    result = true
  else:
    assert pool.tags[n.tagId] == "sources"
    inc n
    while n.kind != ParRi:
      assert n.kind == StringLit
      let dep = pool.strings[n.litId]
      inc n
      if not fileExists(dep):
        #echo dep, " is removed"
        return true
      elif getLastModificationTime(dep) >= modTime:
        #echo dep, " is changed"
        return true
    inc n
    #echo "commandLine is not changed"
    result = false

proc loadConfigsFromNif(config: ConfigRef; n: var Cursor) =
  assert pool.tags[n.tagId] == "options"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let opt = pool.strings[n.litId]
    inc n
    config.options.incl parseEnum[TOption](opt)
  inc n
  #echo config.options

  assert pool.tags[n.tagId] == "globalOptions"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let opt = pool.strings[n.litId]
    inc n
    config.globalOptions.incl parseEnum[TGlobalOption](opt)
  inc n
  #echo config.globalOptions

  assert pool.tags[n.tagId] == "defines"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let def = pool.strings[n.litId]
    inc n
    config.symbols.defineSymbol(def)
  inc n

  assert pool.tags[n.tagId] == "nimblepaths"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let p = pool.strings[n.litId]
    inc n
    config.nimblePaths.add p.toAbsoluteDir
  inc n
  #echo "config.nimblePaths"
  #echo config.nimblePaths

  assert pool.tags[n.tagId] == "paths"
  inc n
  while n.kind != ParRi:
    assert n.kind == StringLit
    let p = pool.strings[n.litId]
    inc n
    config.searchPaths.add p.toAbsoluteDir
  inc n
  #echo "config.searchPaths"
  #echo config.searchPaths

proc loadConfigsFromCache*(conf: ConfigRef): bool =
  if optCacheConfig in conf.globalOptions:
    let (dir, file) = conf.cfgCachePath()
    let path = dir / file
    if fileExists(path):
      let modTime = getLastModificationTime(path.string)
      var stream = nifstreams.open(path.string)
      discard processDirectives(stream.r)
      var buf = fromStream(stream)
      var n = beginRead(buf)
      result = not sourcesChanged(conf, n, modTime)
      if result:
        loadConfigsFromNif(conf, n)
      endRead(buf)
      stream.close
    else:
      result = false
  else:
    result = false

proc storeConfigs*(conf: ConfigRef) =
  if optCacheConfig in conf.globalOptions:
    let (dir, file) = conf.cfgCachePath()
    createDir(dir)
    var dest = createTokenBuf()
    dest.buildTree pool.tags.getOrIncl("config"), NoLineInfo:
      configToNif(conf, dest)
    writeFile dir / file, "(.nif24)\n" & toString(dest)
