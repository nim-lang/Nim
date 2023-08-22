#
#           Atlas Package Cloner
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Lockfile implementation.

import std / [strutils, tables, os, json, jsonutils]
import context, gitops, osutils, traversal, compilerversions

type
  LockFileEntry* = object
    dir*: string
    url*: string
    commit*: string

  LockedNimbleFile* = object
    filename*, content*: string

  LockFile* = object # serialized as JSON
    items*: OrderedTable[string, LockFileEntry]
    nimcfg*: string
    nimbleFile*: LockedNimbleFile
    hostOS*, hostCPU*: string
    nimVersion*, gccVersion*, clangVersion*: string

proc readLockFile(filename: string): LockFile =
  let jsonAsStr = readFile(filename)
  let jsonTree = parseJson(jsonAsStr)
  result = jsonTo(jsonTree, LockFile,
    Joptions(allowExtraKeys: true, allowMissingKeys: true))

proc write(lock: LockFile; lockFilePath: string) =
  writeFile lockFilePath, toJson(lock).pretty

proc genLockEntry(c: var AtlasContext; lf: var LockFile; dir: string) =
  let url = getRemoteUrl()
  let commit = getCurrentCommit()
  let name = dir.lastPathComponent
  lf.items[name] = LockFileEntry(dir: dir, url: $url, commit: commit)

proc genLockEntriesForDir(c: var AtlasContext; lf: var LockFile; dir: string) =
  for k, f in walkDir(dir):
    if k == pcDir and dirExists(f / ".git"):
      withDir c, f:
        genLockEntry c, lf, f.relativePath(dir, '/')

const
  NimCfg = "nim.cfg"

proc newLockFile(): LockFile =
  result = LockFile(items: initOrderedTable[string, LockFileEntry](),
    hostOS: system.hostOS, hostCPU: system.hostCPU,
    nimVersion: detectNimVersion(),
    gccVersion: detectGccVersion(),
    clangVersion: detectClangVersion())

proc pinWorkspace*(c: var AtlasContext; lockFilePath: string) =
  var lf = newLockFile()
  genLockEntriesForDir(c, lf, c.workspace)
  if c.workspace != c.depsDir and c.depsDir.len > 0:
    genLockEntriesForDir c, lf, c.depsDir

  let nimcfgPath = c.workspace / NimCfg
  if fileExists(nimcfgPath):
    lf.nimcfg = readFile(nimcfgPath)

  let nimblePath = c.workspace / c.workspace.lastPathComponent & ".nimble"
  if fileExists nimblePath:
    lf.nimbleFile = LockedNimbleFile(
      filename: c.workspace.lastPathComponent & ".nimble",
      content: readFile(nimblePath))

  write lf, lockFilePath

proc pinProject*(c: var AtlasContext; lockFilePath: string) =
  var lf = newLockFile()

  let start = c.currentDir.lastPathComponent
  let url = getRemoteUrl()
  var g = createGraph(c, start, url)

  var i = 0
  while i < g.nodes.len:
    let w = g.nodes[i]
    let destDir = toDestDir(w.name)

    let dir = selectDir(c.workspace / destDir, c.depsDir / destDir)
    if not dirExists(dir):
      error c, w.name, "dependency does not exist"
    else:
      # assume this is the selected version, it might get overwritten later:
      selectNode c, g, w
      discard collectNewDeps(c, g, i, w)
    inc i

  if c.errors == 0:
    # topo-sort:
    for i in countdown(g.nodes.len-1, 1):
      if g.nodes[i].active:
        let w = g.nodes[i]
        let destDir = toDestDir(w.name)
        let dir = selectDir(c.workspace / destDir, c.depsDir / destDir)
        tryWithDir dir:
          genLockEntry c, lf, dir.relativePath(c.currentDir, '/')

    let nimcfgPath = c.currentDir / NimCfg
    if fileExists(nimcfgPath):
      lf.nimcfg = readFile(nimcfgPath)

    let nimblePath = c.currentDir / c.currentDir.lastPathComponent & ".nimble"
    if fileExists nimblePath:
      lf.nimbleFile = LockedNimbleFile(
        filename: c.currentDir.lastPathComponent & ".nimble",
        content: readFile(nimblePath))

    write lf, lockFilePath

proc compareVersion(c: var AtlasContext; key, wanted, got: string) =
  if wanted != got:
    warn c, toName(key), "environment mismatch: " &
      " versions differ: previously used: " & wanted & " but now at: " & got

proc replay*(c: var AtlasContext; lockFilePath: string) =
  let lf = readLockFile(lockFilePath)
  let base = splitPath(lockFilePath).head
  if lf.nimcfg.len > 0:
    writeFile(base / NimCfg, lf.nimcfg)
  if lf.nimbleFile.filename.len > 0:
    writeFile(base / lf.nimbleFile.filename, lf.nimbleFile.content)
  for _, v in pairs(lf.items):
    let dir = base / v.dir
    if not dirExists(dir):
      let (status, err) = osutils.cloneUrl(getUrl v.url, dir, false)
      if status != Ok:
        error c, toName(lockFilePath), err
        continue
    withDir c, dir:
      let url = $getRemoteUrl()
      if v.url != url:
        error c, toName(v.dir), "remote URL has been compromised: got: " &
            url & " but wanted: " & v.url
      checkoutGitCommit(c, toName(dir), v.commit)

  if lf.hostOS == system.hostOS and lf.hostCPU == system.hostCPU:
    compareVersion c, "nim", lf.nimVersion, detectNimVersion()
    compareVersion c, "gcc", lf.gccVersion, detectGccVersion()
    compareVersion c, "clang", lf.clangVersion, detectClangVersion()
