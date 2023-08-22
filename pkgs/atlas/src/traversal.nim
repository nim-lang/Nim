#
#           Atlas Package Cloner
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Helpers for the graph traversal.

import std / [strutils, os, sha1, algorithm]
import context, nameresolver, gitops

proc createGraph*(c: var AtlasContext; start: Package): DepGraph =
  let dep = Dependency(pkg: start, commit: "",
                       self: 0, algo: c.defaultAlgo)
  result = DepGraph(nodes: @[dep])
  result.byName.mgetOrPut(start.name, @[]).add(0)

proc selectNode*(c: var AtlasContext; g: var DepGraph; w: Dependency) =
  # all other nodes of the same project name are not active
  for e in items g.byName[w.pkg.name]:
    g.nodes[e].active = e == w.self
  if w.status != Ok:
    g.nodes[w.self].active = false

proc addUnique*[T](s: var seq[T]; elem: sink T) =
  if not s.contains(elem): s.add elem

proc addUniqueDep(c: var AtlasContext; g: var DepGraph; parent: int;
                  pkg: Package, query: VersionInterval) =
  let commit = versionKey(query)
  let oldErrors = c.errors
  if oldErrors != c.errors:
    warn c, pkg, "cannot resolve package name"
  else:
    let key = pkg.url / commit
    if g.processed.hasKey($key):
      g.nodes[g.processed[$key]].parents.addUnique parent
    else:
      let self = g.nodes.len
      g.byName.mgetOrPut(pkg.name, @[]).add self
      g.processed[$key] = self
      g.nodes.add Dependency(pkg: pkg,
                             commit: commit,
                             self: self,
                             query: query,
                             parents: @[parent],
                             algo: c.defaultAlgo)

proc rememberNimVersion(g: var DepGraph; q: VersionInterval) =
  let v = extractGeQuery(q)
  if v != Version"" and v > g.bestNimVersion: g.bestNimVersion = v

proc extractRequiresInfo*(c: var AtlasContext; nimble: PackageNimble): NimbleFileInfo =
  result = extractRequiresInfo(nimble.string)
  when ProduceTest:
    echo "nimble ", nimbleFile, " info ", result

proc collectDeps*(
    c: var AtlasContext;
    g: var DepGraph,
    parent: int;
    dep: Dependency
): CfgPath =
  # If there is a .nimble file, return the dependency path & srcDir
  # else return "".
  let nimbleInfo = extractRequiresInfo(c, dep.pkg.nimble)
  if dep.self >= 0 and dep.self < g.nodes.len:
    g.nodes[dep.self].hasInstallHooks = nimbleInfo.hasInstallHooks

  for r in nimbleInfo.requires:
    var i = 0
    while i < r.len and r[i] notin {'#', '<', '=', '>'} + Whitespace: inc i
    let name = r.substr(0, i-1)
    let pkg = c.resolvePackage(name)
    debug c, dep.pkg, "collect deps: " & name & " pkg: " & $dep.pkg

    var err = pkg.name.string.len == 0
    if len($pkg.url) == 0:
      error c, pkg, "invalid pkgUrl in nimble file: " & name
      err = true
    
    let query = parseVersionInterval(r, i, err) # update err

    if err:
      error c, pkg, "invalid 'requires' syntax in nimble file: " & r
    else:
      if cmpIgnoreCase(pkg.name.string, "nim") != 0:
        c.addUniqueDep g, parent, pkg, query
      else:
        rememberNimVersion g, query
  result = CfgPath(toDestDir(dep.pkg).string / nimbleInfo.srcDir)

proc collectNewDeps*(
    c: var AtlasContext;
    g: var DepGraph;
    parent: int;
    dep: Dependency
): CfgPath =
  trace c, dep.pkg, "collecting dependencies"
  if dep.pkg.exists:
    let nimble = dep.pkg.nimble
    debug c, dep.pkg, "collecting deps: using nimble file: '" & nimble.string & "'"
    result = collectDeps(c, g, parent, dep)
  else:
    warn c, dep.pkg, "collecting deps: no nimble skipping deps'"
    result = CfgPath dep.pkg.path.string

proc updateSecureHash(
    checksum: var Sha1State,
    c: var AtlasContext;
    pkg: Package,
    name: string
) =
  let path = pkg.path.string / name
  if not path.fileExists(): return
  checksum.update(name)

  if symlinkExists(path):
    # checksum file path (?)
    try:
      let path = expandSymlink(path)
      checksum.update(path)
    except OSError:
      error c, pkg, "cannot follow symbolic link " & path
  else:
    # checksum file contents
    var file: File
    try:
      file = path.open(fmRead)
      const bufferSize = 8192
      var buffer = newString(bufferSize)
      while true:
        var bytesRead = readChars(file, buffer)
        if bytesRead == 0: break
        checksum.update(buffer.toOpenArray(0, bytesRead - 1))
    except IOError:
      error c, pkg, "error opening file " & path
    finally:
      file.close()

proc nimbleChecksum*(c: var AtlasContext, pkg: Package, cfg: CfgPath): string =
  ## calculate a nimble style checksum from a `CfgPath`.
  ##
  ## Useful for exporting a Nimble sync file.
  ##
  let res = c.listFiles(pkg)
  if res.isNone:
    error c, pkg, "couldn't list files"
  else:
    var files = res.get().sorted()
    var checksum = newSha1State()
    for file in files:
      checksum.updateSecureHash(c, pkg, file)
    result = toLowerAscii($SecureHash(checksum.finalize()))
