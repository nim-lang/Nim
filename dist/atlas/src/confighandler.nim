#
#           Atlas Package Cloner
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Configuration handling.

import std / [strutils, os, streams, parsecfg]
import context, osutils

proc parseOverridesFile(c: var AtlasContext; filename: string) =
  const Separator = " -> "
  let path = c.workspace / filename
  var f: File
  if open(f, path):
    c.flags.incl UsesOverrides
    try:
      var lineCount = 1
      for line in lines(path):
        let splitPos = line.find(Separator)
        if splitPos >= 0 and line[0] != '#':
          let key = line.substr(0, splitPos-1)
          let val = line.substr(splitPos+len(Separator))
          if key.len == 0 or val.len == 0:
            error c, toName(path), "key/value must not be empty"
          let err = c.overrides.addPattern(key, val)
          if err.len > 0:
            error c, toName(path), "(" & $lineCount & "): " & err
        else:
          discard "ignore the line"
        inc lineCount
    finally:
      close f
  else:
    error c, toName(path), "cannot open: " & path

proc readPluginsDir(c: var AtlasContext; dir: string) =
  for k, f in walkDir(c.workspace / dir):
    if k == pcFile and f.endsWith(".nims"):
      extractPluginInfo f, c.plugins

proc readConfig*(c: var AtlasContext) =
  let configFile = c.workspace / AtlasWorkspace
  var f = newFileStream(configFile, fmRead)
  if f == nil:
    error c, toName(configFile), "cannot open: " & configFile
    return
  var p: CfgParser
  open(p, f, configFile)
  while true:
    var e = next(p)
    case e.kind
    of cfgEof: break
    of cfgSectionStart:
      discard "who cares about sections"
    of cfgKeyValuePair:
      case e.key.normalize
      of "deps":
        c.depsDir = absoluteDepsDir(c.workspace, e.value)
      of "overrides":
        parseOverridesFile(c, e.value)
      of "resolver":
        try:
          c.defaultAlgo = parseEnum[ResolutionAlgorithm](e.value)
        except ValueError:
          warn c, toName(configFile), "ignored unknown resolver: " & e.key
      of "plugins":
        readPluginsDir(c, e.value)
      else:
        warn c, toName(configFile), "ignored unknown setting: " & e.key
    of cfgOption:
      discard "who cares about options"
    of cfgError:
      error c, toName(configFile), e.msg
  close(p)
