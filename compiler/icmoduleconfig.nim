#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this distribution.
#

## An active build still has its own complete, consistent set of semantic
## files. A new configuration can materialize a previously checked module (or
## import cycle) after replaying its config queries and checking the same
## dependency cookies used by the frontend build rules.
import "../dist/checksums/src/checksums" / sha1
import std/[algorithm, intsets, json, os, sets, strtabs, strutils, syncio, tables, times]
from std/compilesettings import SingleValueSetting, MultipleValueSetting
import options, pathutils, modulegraphs, typekeys, icmodnames
from icnifcore import configReadHash
from vm import querySettingImpl, querySettingSeqImpl

type
  Observation = object
    kind: ConfigReadKind
    name, origin, value: string
  Input = object
    name, digest: string
  Variant = object
    queries: seq[Observation]
    sources, dependencies, outputs: seq[Input]
    directory: string

proc members(conf: ConfigRef): seq[string] =
  result = @[]
  for path in conf.icGroup: result.add moduleSuffix(path, [])
  if result.len == 0: result.add moduleSuffix(conf.projectFull.string, [])
  result.sort()

proc groupDirectory(conf: ConfigRef): string =
  # Package membership controls which diagnostics are promoted to errors.
  # Two unrelated entry packages can still share a third-party module.
  var paths: seq[string] = @[]
  for path in conf.icGroup: paths.add path
  if paths.len == 0: paths.add conf.projectFull.string
  paths.sort()
  let mainPackage = conf.getPackageName(conf.icProject)
  var group = @[conf.projectFull.string, $conf.isMainModule]
  for path in paths:
    group.add path
    group.add conf.getNimbleFile(path)
    group.add $(conf.getPackageName(path) == mainPackage)
  conf.icVariants / $secureHash($group)

proc outputFiles(conf: ConfigRef; members: seq[string]): seq[string] =
  result = @[]
  let gates = not conf.isDefined("icNoIfaceGate")
  for suffix in members:
    result.add suffix & ".s.bif"
    result.add suffix & ".s.deps.bif"
    if gates:
      for ext in [".iface.bif", ".impl.bif", ".edges.bif"]: result.add suffix & ext

proc matches(conf: ConfigRef; q: Observation): bool =
  let value = case q.kind
    of crDefined: $conf.isDefined(q.name)
    of crValue:
      if not conf.symbols.hasKey(q.name): return false
      conf.symbols[q.name]
    of crModule, crFile, crSlurp: conf.resolveConfigPath((q.kind, q.name, q.origin))
    of crPathSub: conf.pathSubs(q.name, q.origin)
    of crRelativePath: conf.getRelativePathFromConfigPath(AbsoluteFile(q.name), q.origin == "true").string
    of crSetting:
      let n = parseInt(q.name)
      if n notin ord(low(SingleValueSetting))..ord(high(SingleValueSetting)): return false
      querySettingImpl(conf, n)
    of crSettingSeq:
      let n = parseInt(q.name)
      if n notin ord(low(MultipleValueSetting))..ord(high(MultipleValueSetting)): return false
      $querySettingSeqImpl(conf, n)
  result = value == q.value

proc digest(path: string): string = $secureHashFile(path)

proc dependencyFile(conf: ConfigRef; name: string): string =
  let i = name.find('.')
  if i <= 0 or name.extractFilename != name: return ""
  conf.semanticFile(name[0..<i], name[i..^1]).string

proc restore(conf: ConfigRef; manifest: string; outputs: seq[string]): bool =
  let bytes = readFile(manifest)
  let split = bytes.find('\n')
  if split != 40: return false
  let body = bytes[split+1..^1]
  if $secureHash(body) != bytes[0..<split]: return false
  let v = parseJson(body).to(Variant)
  if v.outputs.len != outputs.len or v.sources.len == 0: return false
  # findFile can promote a lazy path. Probe using the original lookup order
  # and restore it before another candidate or a real semantic pass.
  let savedPaths = conf.lazyPaths
  defer: conf.lazyPaths = savedPaths
  for q in v.queries:
    if not matches(conf, q): return false
  for f in v.sources:
    if digest(f.name) != f.digest: return false
  for f in v.dependencies:
    if digest(conf.dependencyFile(f.name)) != f.digest: return false
  let dest = conf.getNimcacheDir.string
  if v.directory == dest: return false
  # Hard-link immutable semantic BIFs into a cold backend view. For an
  # existing backend or a full-BIF dependency edge, a recovered output must
  # have a fresh timestamp so a newer consumer cannot silently stay stale.
  let linkBifs = not conf.isDefined("icNoIfaceGate") and
    not dirExists(conf.icSemDir.string.parentDir / "backend")
  # Stage and check every output before publishing the group.
  var staged: seq[string] = @[]
  defer:
    for f in staged: removeFile(f)
  for i, name in outputs:
    if v.outputs[i].name != name: return false
    let src = v.directory / name
    let tmp = dest / (name & ".reuse." & $getCurrentProcessId())
    staged.add tmp
    removeFile(tmp)
    if not linkBifs or not name.endsWith(".s.bif"):
      copyFile(src, tmp)
      setLastModificationTime(tmp, getTime())
    else:
      try: createHardlink(src, tmp)
      except OSError: copyFile(src, tmp)
    if digest(tmp) != v.outputs[i].digest: return false
  # outputs[0] was missing on entry. Install that BIF last so an interrupted
  # publication always leaves a missing rule output for the retry.
  for i in countdown(outputs.high, 0): moveFile(staged[i], dest / outputs[i])
  result = true

proc restoreModuleConfig*(conf: ConfigRef): bool =
  if conf.icVariants.len == 0 or optForceFullMake in conf.globalOptions: return false
  let group = members(conf)
  let outputs = outputFiles(conf, group)
  # An existing module scheduled by nifmake has changed inputs. Its ordinary
  # rebuild handles edits and refreshes the variant for its projected config.
  if fileExists(conf.getNimcacheDir.string / outputs[0]): return false
  for manifest in walkFiles(groupDirectory(conf) / "*.variant"):
    try:
      if restore(conf, manifest, outputs): return true
    except CatchableError:
      discard # incomplete, stale or removed candidates are cache misses
  result = false

proc publishModuleConfig*(graph: ModuleGraph) =
  let conf = graph.config
  let reads = conf.groupReads
  conf.groupReads = nil
  if reads == nil or reads.localOnly or conf.errorCounter != 0: return
  try:
    let group = members(conf)
    let dir = groupDirectory(conf)
    var v = Variant(directory: conf.getNimcacheDir.string)
    for query in reads.order:
      let value = reads.values[query]
      v.queries.add Observation(kind: query.kind, name: query.name,
                                origin: query.origin, value: value)
    for path, hash in conf.icSourceInputs:
      v.sources.add Input(name: path, digest: hash)
    var needsImpl = initHashSet[string]()
    for id in graph.icImplDeps: needsImpl.incl modname(id.int32, conf)
    for suffix in conf.icLoadedModules:
      if suffix in group: continue
      let ext = if conf.isDefined("icNoIfaceGate"): ".s.bif"
                elif suffix in needsImpl: ".impl.bif"
                else: ".iface.bif"
      let name = suffix & ext
      v.dependencies.add Input(name: name, digest: digest(conf.dependencyFile(name)))
    for name in outputFiles(conf, group):
      v.outputs.add Input(name: name, digest: digest(v.directory / name))
    createDir(dir)
    v.sources.sort(proc(a, b: Input): int = cmp(a.name, b.name))
    v.dependencies.sort(proc(a, b: Input): int = cmp(a.name, b.name))
    let file = dir / (configReadHash(reads) & ".variant")
    let tmp = file & ".tmp." & $getCurrentProcessId()
    try:
      let body = $(%v)
      let record = $secureHash(body) & "\n" & body
      if fileExists(file) and readFile(file) == record: return
      writeFile(tmp, record)
      moveFile(tmp, file)
    finally:
      removeFile(tmp)
  except CatchableError:
    discard # the active build can always use its ordinary artifacts
