#
#           Atlas Package Cloner
#        (c) Copyright 2023 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Helpers for the graph traversal.

import std / [strutils, os]
import context, osutils, gitops, nameresolver

proc createGraph*(c: var AtlasContext; start: string, url: PackageUrl): DepGraph =
  result = DepGraph(nodes: @[Dependency(name: toName(start),
                                        url: url,
                                        commit: "",
                                        self: 0,
                                        algo: c.defaultAlgo)])
  result.byName.mgetOrPut(toName(start), @[]).add 0

proc selectNode*(c: var AtlasContext; g: var DepGraph; w: Dependency) =
  # all other nodes of the same project name are not active
  for e in items g.byName[w.name]:
    g.nodes[e].active = e == w.self
  if w.status != Ok:
    g.nodes[w.self].active = false

proc addUnique*[T](s: var seq[T]; elem: sink T) =
  if not s.contains(elem): s.add elem

proc addUniqueDep(c: var AtlasContext; g: var DepGraph; parent: int;
                  pkg: PackageUrl; query: VersionInterval) =
  let commit = versionKey(query)
  let oldErrors = c.errors
  let url = pkg
  let name = pkg.toName
  if oldErrors != c.errors:
    warn c, toName(pkg), "cannot resolve package name"
  else:
    let key = url / commit
    if g.processed.hasKey($key):
      g.nodes[g.processed[$key]].parents.addUnique parent
    else:
      let self = g.nodes.len
      g.byName.mgetOrPut(name, @[]).add self
      g.processed[$key] = self
      g.nodes.add Dependency(name: name, url: url, commit: commit,
                             self: self,
                             query: query,
                             parents: @[parent],
                             algo: c.defaultAlgo)

proc rememberNimVersion(g: var DepGraph; q: VersionInterval) =
  let v = extractGeQuery(q)
  if v != Version"" and v > g.bestNimVersion: g.bestNimVersion = v

proc extractRequiresInfo*(c: var AtlasContext; nimbleFile: string): NimbleFileInfo =
  result = extractRequiresInfo(nimbleFile)
  when ProduceTest:
    echo "nimble ", nimbleFile, " info ", result

proc collectDeps*(c: var AtlasContext; g: var DepGraph; parent: int;
                 dep: Dependency; nimbleFile: string): CfgPath =
  # If there is a .nimble file, return the dependency path & srcDir
  # else return "".
  assert nimbleFile != ""
  let nimbleInfo = extractRequiresInfo(c, nimbleFile)
  if dep.self >= 0 and dep.self < g.nodes.len:
    g.nodes[dep.self].hasInstallHooks = nimbleInfo.hasInstallHooks
  for r in nimbleInfo.requires:
    var i = 0
    while i < r.len and r[i] notin {'#', '<', '=', '>'} + Whitespace: inc i
    let pkgName = r.substr(0, i-1)
    var err = pkgName.len == 0
    let pkgUrl = c.resolveUrl(pkgName)
    let query = parseVersionInterval(r, i, err)
    if err:
      error c, toName(nimbleFile), "invalid 'requires' syntax: " & r
    else:
      if cmpIgnoreCase(pkgName, "nim") != 0:
        c.addUniqueDep g, parent, pkgUrl, query
      else:
        rememberNimVersion g, query
  result = CfgPath(toDestDir(dep.name) / nimbleInfo.srcDir)

proc collectNewDeps*(c: var AtlasContext; g: var DepGraph; parent: int;
                    dep: Dependency): CfgPath =
  let nimbleFile = findNimbleFile(c, dep)
  if nimbleFile != "":
    result = collectDeps(c, g, parent, dep, nimbleFile)
  else:
    result = CfgPath toDestDir(dep.name)
