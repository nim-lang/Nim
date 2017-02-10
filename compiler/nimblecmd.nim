#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Implements some helper procs for Nimble (Nim's package manager) support.

import parseutils, strutils, strtabs, os, options, msgs

proc addPath*(path: string, info: TLineInfo) =
  if not options.searchPaths.contains(path):
    options.searchPaths.insert(path, 0)

proc versionSplitPos(s: string): int =
  result = s.len-2
  while result > 1 and s[result] in {'0'..'9', '.'}: dec result
  if s[result] != '-': result = s.len

const
  latest = "head"

proc `<.`(a, b: string): bool =
  # wether a has a smaller version than b:
  if a == latest: return false
  var i = 0
  var j = 0
  var verA = 0
  var verB = 0
  while true:
    let ii = parseInt(a, verA, i)
    let jj = parseInt(b, verB, j)
    # if A has no number left, but B has, B is preferred:  0.8 vs 0.8.3
    if ii <= 0 or jj <= 0: return jj > 0
    if verA < verB: return true
    elif verA > verB: return false
    # else: same version number; continue:
    inc i, ii
    inc j, jj
    if a[i] == '.': inc i
    if b[j] == '.': inc j

proc addPackage(packages: StringTableRef, p: string) =
  let x = versionSplitPos(p)
  let name = p.substr(0, x-1)
  if x < p.len:
    let version = p.substr(x+1)
    if packages.getOrDefault(name) <. version:
      packages[name] = version
  else:
    packages[name] = latest

iterator chosen(packages: StringTableRef): string =
  for key, val in pairs(packages):
    let res = if val == latest: key else: key & '-' & val
    yield res

proc addNimblePath(p: string, info: TLineInfo) =
  if not contains(options.searchPaths, p):
    message(info, hintPath, p)
    options.lazyPaths.insert(p, 0)

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
