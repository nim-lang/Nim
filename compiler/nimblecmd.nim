#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements some helper procs for Nimble (Nim's package manager) support.

import parseutils, strutils, strtabs, os, options, msgs, sequtils

proc addPath*(path: string, info: TLineInfo) =
  if not options.searchPaths.contains(path):
    options.searchPaths.insert(path, 0)

type
  Version* = distinct string

proc `$`*(ver: Version): string {.borrow.}

proc newVersion*(ver: string): Version =
  doAssert(ver.len == 0 or ver[0] in {'#', '\0'} + Digits,
           "Wrong version: " & ver)
  return Version(ver)

proc isSpecial(ver: Version): bool =
  return ($ver).len > 0 and ($ver)[0] == '#'

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
  for i in 0..max(sVer.len, sVer2.len)-1:
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
  var sepIdx = p.find(specialSeparator)
  if sepIdx == -1:
    sepIdx = p.rfind('-')

  if sepIdx == -1:
    result.name = p
    return

  result.name = p[0 .. sepIdx - 1]
  result.version = p.substr(sepIdx + 1)

proc addPackage(packages: StringTableRef, p: string) =
  let (name, ver) = getPathVersion(p)
  let version = newVersion(ver)
  if packages.getOrDefault(name).newVersion < version or
     (not packages.hasKey(name)):
    packages[name] = $version

iterator chosen(packages: StringTableRef): string =
  for key, val in pairs(packages):
    let res = if val.len == 0: key else: key & '-' & val
    yield res

proc addNimblePath(p: string, info: TLineInfo) =
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

  if not contains(options.searchPaths, path):
    message(info, hintPath, path)
    options.lazyPaths.insert(path, 0)

proc addPathRec(dir: string, info: TLineInfo) =
  var packages = newStringTable(modeStyleInsensitive)
  var pos = dir.len-1
  if dir[pos] in {DirSep, AltSep}: inc(pos)
  for k,p in os.walkDir(dir):
    if k == pcDir and p[pos] != '.':
      addPackage(packages, p)
  for p in packages.chosen:
    addNimblePath(p, info)

proc nimblePath*(path: string, info: TLineInfo) =
  addPathRec(path, info)
  addNimblePath(path, info)

when isMainModule:
  proc v(s: string): Version = s.newVersion
  # #head is special in the sense that it's assumed to always be newest.
  doAssert v"1.0" < v"#head"
  doAssert v"1.0" < v"1.1"
  doAssert v"1.0.1" < v"1.1"
  doAssert v"1" < v"1.1"
  doAssert v"#aaaqwe" < v"1.1" # We cannot assume that a branch is newer.
  doAssert v"#a111" < v"#head"

  var rr = newStringTable()
  addPackage rr, "irc-#a111"
  addPackage rr, "irc-#head"
  addPackage rr, "irc-0.1.0"
  addPackage rr, "irc"
  addPackage rr, "another"
  addPackage rr, "another-0.1"

  addPackage rr, "ab-0.1.3"
  addPackage rr, "ab-0.1"
  addPackage rr, "justone"

  doAssert toSeq(rr.chosen) ==
    @["irc-#head", "another-0.1", "ab-0.1.3", "justone"]

