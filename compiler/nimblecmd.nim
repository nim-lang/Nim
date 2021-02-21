#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements some helper procs for Nimble (Nim's package manager) support.

import parseutils, strutils, strtabs, os, options, msgs, sequtils,
  lineinfos, pathutils

proc addPath*(conf: ConfigRef; path: AbsoluteDir, info: TLineInfo) =
  if not conf.searchPaths.contains(path):
    conf.searchPaths.insert(path, 0)

type
  Version* = distinct string

proc `$`*(ver: Version): string {.borrow.}

proc newVersion*(ver: string): Version =
  doAssert(ver.len == 0 or ver[0] in {'#', '\0'} + Digits,
           "Wrong version: " & ver)
  return Version(ver)

proc isSpecial(ver: Version): bool =
  return ($ver).len > 0 and ($ver)[0] == '#'

proc isValidVersion(v: string): bool =
  if v.len > 0:
    if v[0] in {'#'} + Digits: return true

proc `<`*(ver: Version, ver2: Version): bool =
  ## This is synced from Nimble's version module.

  # Handling for special versions such as "#head" or "#branch".
  if ver.isSpecial or ver2.isSpecial:
    if ver2.isSpecial and ($ver2).normalize == "#head":
      return ($ver).normalize != "#head"

    if not ver2.isSpecial:
      # `#aa111 < 1.1`
      return ($ver).normalize != "#head"

  # Handling for normal versions such as "0.1.0" or "1.0".
  var sVer = string(ver).split('.')
  var sVer2 = string(ver2).split('.')
  for i in 0..<max(sVer.len, sVer2.len):
    var sVerI = 0
    if i < sVer.len:
      discard parseInt(sVer[i], sVerI)
    var sVerI2 = 0
    if i < sVer2.len:
      discard parseInt(sVer2[i], sVerI2)
    if sVerI < sVerI2:
      return true
    elif sVerI == sVerI2:
      discard
    else:
      return false

proc getPathVersion*(p: string): tuple[name, version: string] =
  ## Splits path ``p`` in the format ``/home/user/.nimble/pkgs/package-0.1``
  ## into ``(/home/user/.nimble/pkgs/package, 0.1)``
  result.name = ""
  result.version = ""

  const specialSeparator = "-#"
  let last = p.rfind(p.lastPathPart) # the index where the last path part begins
  var sepIdx = p.find(specialSeparator, start = last)
  if sepIdx == -1:
    sepIdx = p.rfind('-', start = last)

  if sepIdx == -1:
    result.name = p
    return

  for i in sepIdx..<p.len:
    if p[i] in {DirSep, AltSep}:
      result.name = p
      return

  result.name = p[0..sepIdx - 1]
  result.version = p.substr(sepIdx + 1)

proc addPackage(conf: ConfigRef; packages: StringTableRef, p: string; info: TLineInfo) =
  let (name, ver) = getPathVersion(p)
  if isValidVersion(ver):
    let version = newVersion(ver)
    if packages.getOrDefault(name).newVersion < version or
      (not packages.hasKey(name)):
      packages[name] = $version
  else:
    localError(conf, info, "invalid package name: " & p)

iterator chosen(packages: StringTableRef): string =
  for key, val in pairs(packages):
    let res = if val.len == 0: key else: key & '-' & val
    yield res

proc addNimblePath(conf: ConfigRef; p: string, info: TLineInfo) =
  var path = p
  let nimbleLinks = toSeq(walkPattern(p / "*.nimble-link"))
  if nimbleLinks.len > 0:
    # If the user has more than one .nimble-link file then... we just ignore it.
    # Spec for these files is available in Nimble's readme:
    # https://github.com/nim-lang/nimble#nimble-link
    let nimbleLinkLines = readFile(nimbleLinks[0]).splitLines()
    path = nimbleLinkLines[1]
    if not path.isAbsolute():
      path = p / path

  if not contains(conf.searchPaths, AbsoluteDir path):
    message(conf, info, hintPath, path)
    conf.lazyPaths.insert(AbsoluteDir path, 0)

proc addPathRec(conf: ConfigRef; dir: string, info: TLineInfo) =
  var packages = newStringTable(modeStyleInsensitive)
  var pos = dir.len-1
  if dir[pos] in {DirSep, AltSep}: inc(pos)
  for k,p in os.walkDir(dir):
    if k == pcDir and p[pos] != '.':
      addPackage(conf, packages, p, info)
  for p in packages.chosen:
    addNimblePath(conf, p, info)

proc nimblePath*(conf: ConfigRef; path: AbsoluteDir, info: TLineInfo) =
  addPathRec(conf, path.string, info)
  addNimblePath(conf, path.string, info)
  let i = conf.nimblePaths.find(path)
  if i != -1:
    conf.nimblePaths.delete(i)
  conf.nimblePaths.insert(path, 0)
