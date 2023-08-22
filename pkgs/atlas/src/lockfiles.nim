#
#           Atlas Package Cloner
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Lockfile implementation.

import std / [sequtils, strutils, algorithm, tables, os, json, jsonutils, sha1]
import context, gitops, osutils, traversal, compilerversions, nameresolver, parse_requires

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

proc newLockFile(): LockFile =
  result = LockFile(items: initOrderedTable[string, LockFileEntry](),
    hostOS: system.hostOS, hostCPU: system.hostCPU,
    nimVersion: detectNimVersion(),
    gccVersion: detectGccVersion(),
    clangVersion: detectClangVersion())

type
  NimbleLockFileEntry* = object
    version*: string
    vcsRevision*: string
    url*: string
    downloadMethod*: string
    dependencies*: seq[string]
    checksums*: Table[string, string]

  NimbleLockFile* = object # serialized as JSON
    packages*: OrderedTable[string, NimbleLockFileEntry]
    version*: int

proc newNimbleLockFile(): NimbleLockFile =
  let tbl = initOrderedTable[string, NimbleLockFileEntry]()
  result = NimbleLockFile(version: 1,
                          packages: tbl)

proc write(lock: NimbleLockFile; lockFilePath: string) =
  writeFile lockFilePath, toJson(lock).pretty

proc genLockEntry(c: var AtlasContext;
                  lf: var NimbleLockFile;
                  pkg: Package,
                  cfg: CfgPath,
                  version: string,
                  deps: HashSet[PackageName]) =
  let url = getRemoteUrl()
  let commit = getCurrentCommit()
  let name = pkg.name.string
  infoNow c, pkg, "calculating nimble checksum"
  let chk = c.nimbleChecksum(pkg, cfg)
  lf.packages[name] = NimbleLockFileEntry(
    version: version,
    vcsRevision: commit,
    url: $url,
    downloadMethod: "git",
    dependencies: deps.mapIt(it.string),
    checksums: {"sha1": chk}.toTable
  )

const
  NimCfg = "nim.cfg"

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

proc pinProject*(c: var AtlasContext; lockFilePath: string, exportNimble = false) =
  ## Pin project using deps starting from the current project directory. 
  ##
  ##
  var lf = newLockFile()
  let startPkg = resolvePackage(c, "file://" & c.currentDir)
  var g = createGraph(c, startPkg)

  # only used for exporting nimble locks
  var nlf = newNimbleLockFile()
  var nimbleDeps = newTable[PackageName, HashSet[PackageName]]()
  var cfgs = newTable[PackageName, CfgPath]()

  info c, startPkg, "pinning lockfile: " & lockFilePath
  var i = 0
  while i < g.nodes.len:
    let w = g.nodes[i]

    info c, w.pkg, "pinning: " & $w.pkg

    if not w.pkg.exists:
      error c, w.pkg, "dependency does not exist"
    else:
      # assume this is the selected version, it might get overwritten later:
      selectNode c, g, w
      let cfgPath = collectNewDeps(c, g, i, w)
      cfgs[w.pkg.name] = cfgPath
    inc i

  if c.errors == 0:
    # topo-sort:
    for i in countdown(g.nodes.len-1, 1):
      if g.nodes[i].active:
        let w = g.nodes[i]
        let dir = w.pkg.path.string
        tryWithDir c, dir:
          genLockEntry c, lf, dir.relativePath(c.currentDir, '/')

          if exportNimble:
            for nx in g.nodes: # expensive, but eh
              if nx.active and i in nx.parents:
                nimbleDeps.mgetOrPut(w.pkg.name,
                                    initHashSet[PackageName]()).incl(nx.pkg.name)
            trace c, w.pkg, "exporting nimble " & w.pkg.name.string
            let name = w.pkg.name
            let deps = nimbleDeps.getOrDefault(name)
            let info = extractRequiresInfo(w.pkg.nimble.string)
            genLockEntry c, nlf, w.pkg, cfgs[name], info.version, deps

    let nimcfgPath = c.currentDir / NimCfg
    if fileExists(nimcfgPath):
      lf.nimcfg = readFile(nimcfgPath)

    let nimblePath = startPkg.nimble.string
    if nimblePath.len() > 0 and nimblePath.fileExists():
      lf.nimbleFile = LockedNimbleFile(
        filename: c.currentDir.lastPathComponent & ".nimble",
        content: readFile(nimblePath))

    if not exportNimble:
      write lf, lockFilePath
    else:
      write nlf, lockFilePath

proc compareVersion(c: var AtlasContext; key, wanted, got: string) =
  if wanted != got:
    warn c, toRepo(key), "environment mismatch: " &
      " versions differ: previously used: " & wanted & " but now at: " & got

proc convertNimbleLock*(c: var AtlasContext; nimblePath: string): LockFile =
  ## converts nimble lock file into a Atlas lockfile
  ## 
  let jsonAsStr = readFile(nimblePath)
  let jsonTree = parseJson(jsonAsStr)

  if jsonTree.getOrDefault("version") == nil or
      "packages" notin jsonTree:
    error c, toRepo(nimblePath), "invalid nimble lockfile"
    return

  result = newLockFile()
  for (name, info) in jsonTree["packages"].pairs:
    if name == "nim":
      result.nimVersion = info["version"].getStr
      continue
    # lookup package using url
    let pkg = c.resolvePackage(info["url"].getStr)
    info c, toRepo(name), " imported "
    let dir = c.depsDir / pkg.repo.string
    result.items[name] = LockFileEntry(
      dir: dir.relativePath(c.projectDir),
      url: $pkg.url,
      commit: info["vcsRevision"].getStr,
    )


proc convertAndSaveNimbleLock*(c: var AtlasContext; nimblePath, lockFilePath: string) =
  ## convert and save a nimble.lock into an Atlast lockfile
  let lf = convertNimbleLock(c, nimblePath)
  write lf, lockFilePath

proc listChanged*(c: var AtlasContext; lockFilePath: string) =
  ## replays the given lockfile by cloning and updating all the deps
  ## 
  ## this also includes updating the nim.cfg and nimble file as well
  ## if they're included in the lockfile
  ## 
  let lf = if lockFilePath == "nimble.lock": convertNimbleLock(c, lockFilePath)
           else: readLockFile(lockFilePath)

  let base = splitPath(lockFilePath).head

  # update the the dependencies
  for _, v in pairs(lf.items):
    let dir = base / v.dir
    if not dirExists(dir):
      warn c, toRepo(dir), "repo missing!"
      continue
    withDir c, dir:
      let url = $getRemoteUrl()
      if v.url != url:
        warn c, toRepo(v.dir), "remote URL has been changed;" &
                                  " found: " & url &
                                  " lockfile has: " & v.url
      
      let commit = gitops.getCurrentCommit()
      if commit != v.commit:
        let pkg = c.resolvePackage("file://" & dir)
        c.resolveNimble(pkg)
        let info = extractRequiresInfo(c, pkg.nimble)
        warn c, toRepo(dir), "commit differs;" &
                                            " found: " & commit &
                                            " (" & info.version & ")" &
                                            " lockfile has: " & v.commit

  if lf.hostOS == system.hostOS and lf.hostCPU == system.hostCPU:
    compareVersion c, "nim", lf.nimVersion, detectNimVersion()
    compareVersion c, "gcc", lf.gccVersion, detectGccVersion()
    compareVersion c, "clang", lf.clangVersion, detectClangVersion()

proc replay*(c: var AtlasContext; lockFilePath: string): tuple[hasCfg: bool] =
  ## replays the given lockfile by cloning and updating all the deps
  ## 
  ## this also includes updating the nim.cfg and nimble file as well
  ## if they're included in the lockfile
  ## 
  let lf = if lockFilePath == "nimble.lock": convertNimbleLock(c, lockFilePath)
           else: readLockFile(lockFilePath)

  let base = splitPath(lockFilePath).head
  # update the nim.cfg file
  if lf.nimcfg.len > 0:
    writeFile(base / NimCfg, lf.nimcfg)
    result.hasCfg = true
  # update the nimble file
  if lf.nimbleFile.filename.len > 0:
    writeFile(base / lf.nimbleFile.filename, lf.nimbleFile.content)
  # update the the dependencies
  for _, v in pairs(lf.items):
    let dir = base / v.dir
    if not dirExists(dir):
      let (status, err) = c.cloneUrl(getUrl v.url, dir, false)
      if status != Ok:
        error c, toRepo(lockFilePath), err
        continue
    withDir c, dir:
      let url = $getRemoteUrl()
      if $v.url.getUrl() != url:
        error c, toRepo(v.dir), "remote URL has been compromised: got: " &
            url & " but wanted: " & v.url
      checkoutGitCommit(c, toRepo(dir), v.commit)

  if lf.hostOS == system.hostOS and lf.hostCPU == system.hostCPU:
    compareVersion c, "nim", lf.nimVersion, detectNimVersion()
    compareVersion c, "gcc", lf.gccVersion, detectGccVersion()
    compareVersion c, "clang", lf.clangVersion, detectClangVersion()
