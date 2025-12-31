#
#
#           The Nim Compiler
#        (c) Copyright 2025 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Generate a .build.nif file for nifmake from a Nim project.
## This enables incremental and parallel compilation using the `m` switch.

import std / [os, tables, sets, times, osproc, strutils]
import options, msgs, lineinfos

import "../dist/nimony/src/lib" / [nifstreams, nifcursors, bitabs, nifreader, nifbuilder]
import "../dist/nimony/src/gear2" / modnames

type
  FilePair = object
    nimFile: string
    modname: string

  Node = ref object
    files: seq[FilePair]  # main file + includes
    deps: seq[int]        # indices into DepContext.nodes
    id: int

  DepContext = object
    config: ConfigRef
    nifler: string
    nodes: seq[Node]
    processedModules: Table[string, int]  # modname -> node index
    includeStack: seq[string]

proc toPair(c: DepContext; f: string): FilePair =
  FilePair(nimFile: f, modname: moduleSuffix(f, cast[seq[string]](c.config.searchPaths)))

proc depsFile(c: DepContext; f: FilePair): string =
  getNimcacheDir(c.config).string / f.modname & ".deps.nif"

proc parsedFile(c: DepContext; f: FilePair): string =
  getNimcacheDir(c.config).string / f.modname & ".p.nif"

proc semmedFile(c: DepContext; f: FilePair): string =
  getNimcacheDir(c.config).string / f.modname & ".nif"

proc findNifler(): string =
  # Look for nifler in common locations
  result = findExe("nifler")
  if result.len == 0:
    # Try relative to nim executable
    let nimDir = getAppDir()
    result = nimDir / "nifler"
    if not fileExists(result):
      result = nimDir / ".." / "nimony" / "bin" / "nifler"
      if not fileExists(result):
        result = ""

proc runNifler(c: DepContext; nimFile: string): bool =
  ## Run nifler deps on a file if needed. Returns true on success.
  let pair = c.toPair(nimFile)
  let depsPath = c.depsFile(pair)

  # Check if deps file is up-to-date
  if fileExists(depsPath) and fileExists(nimFile):
    if getLastModificationTime(depsPath) > getLastModificationTime(nimFile):
      return true  # Already up-to-date

  # Create output directory if needed
  createDir(parentDir(depsPath))

  # Run nifler deps
  let cmd = quoteShell(c.nifler) & " deps " & quoteShell(nimFile) & " " & quoteShell(depsPath)
  let exitCode = execShellCmd(cmd)
  result = exitCode == 0

proc resolveFile(c: DepContext; origin, toResolve: string): string =
  ## Resolve an import path relative to origin file
  # Handle std/ prefix
  var path = toResolve
  if path.startsWith("std/"):
    path = path.substr(4)

  # Try relative to origin first
  let originDir = parentDir(origin)
  result = originDir / path.addFileExt("nim")
  if fileExists(result):
    return result

  # Try search paths
  for searchPath in c.config.searchPaths:
    result = searchPath.string / path.addFileExt("nim")
    if fileExists(result):
      return result

  result = ""

proc traverseDeps(c: var DepContext; pair: FilePair; current: Node)

proc processInclude(c: var DepContext; includePath: string; current: Node) =
  let resolved = resolveFile(c, current.files[current.files.len - 1].nimFile, includePath)
  if resolved.len == 0 or not fileExists(resolved):
    return

  # Check for recursive includes
  for s in c.includeStack:
    if s == resolved:
      return  # Skip recursive include

  c.includeStack.add resolved
  current.files.add c.toPair(resolved)
  traverseDeps(c, c.toPair(resolved), current)
  discard c.includeStack.pop()

proc processImport(c: var DepContext; importPath: string; current: Node) =
  let resolved = resolveFile(c, current.files[0].nimFile, importPath)
  if resolved.len == 0 or not fileExists(resolved):
    return

  let pair = c.toPair(resolved)
  let existingIdx = c.processedModules.getOrDefault(pair.modname, -1)

  if existingIdx == -1:
    # New module - create node and process it
    let newNode = Node(files: @[pair], id: c.nodes.len)
    current.deps.add newNode.id
    c.processedModules[pair.modname] = newNode.id
    c.nodes.add newNode
    traverseDeps(c, pair, newNode)
  else:
    # Already processed - just add dependency
    if existingIdx notin current.deps:
      current.deps.add existingIdx

proc readDepsFile(c: var DepContext; pair: FilePair; current: Node) =
  ## Read a .deps.nif file and process imports/includes
  let depsPath = c.depsFile(pair)
  if not fileExists(depsPath):
    return

  var s = nifstreams.open(depsPath)
  defer: nifstreams.close(s)
  discard processDirectives(s.r)

  var t = next(s)
  if t.kind != ParLe:
    return

  # Skip to content (past stmts tag)
  t = next(s)

  while t.kind != EofToken:
    if t.kind == ParLe:
      let tag = pool.tags[t.tagId]
      case tag
      of "import", "fromimport":
        # Read import path
        t = next(s)
        # Check for "when" marker (conditional import)
        if t.kind == Ident and pool.strings[t.litId] == "when":
          t = next(s)  # skip it, still process the import
        # Handle path expression (could be ident, string, or infix like std/foo)
        var importPath = ""
        if t.kind == Ident:
          importPath = pool.strings[t.litId]
        elif t.kind == StringLit:
          importPath = pool.strings[t.litId]
        elif t.kind == ParLe and pool.tags[t.tagId] == "infix":
          # Handle std / foo style imports
          t = next(s)  # skip infix tag
          if t.kind == Ident:  # operator (/)
            t = next(s)
          if t.kind == Ident:  # first part (std)
            importPath = pool.strings[t.litId]
            t = next(s)
          if t.kind == Ident:  # second part (foo)
            importPath = importPath & "/" & pool.strings[t.litId]
        if importPath.len > 0:
          processImport(c, importPath, current)
        # Skip to end of import node
        var depth = 1
        while depth > 0:
          t = next(s)
          if t.kind == ParLe: inc depth
          elif t.kind == ParRi: dec depth
      of "include":
        # Read include path
        t = next(s)
        if t.kind == Ident and pool.strings[t.litId] == "when":
          t = next(s)  # skip conditional marker
        var includePath = ""
        if t.kind == Ident:
          includePath = pool.strings[t.litId]
        elif t.kind == StringLit:
          includePath = pool.strings[t.litId]
        if includePath.len > 0:
          processInclude(c, includePath, current)
        # Skip to end
        var depth = 1
        while depth > 0:
          t = next(s)
          if t.kind == ParLe: inc depth
          elif t.kind == ParRi: dec depth
      else:
        # Skip unknown node
        var depth = 1
        while depth > 0:
          t = next(s)
          if t.kind == ParLe: inc depth
          elif t.kind == ParRi: dec depth
    t = next(s)

proc traverseDeps(c: var DepContext; pair: FilePair; current: Node) =
  ## Process a module: run nifler and read deps
  if not runNifler(c, pair.nimFile):
    rawMessage(c.config, errGenerated, "nifler failed for: " & pair.nimFile)
    return
  readDepsFile(c, pair, current)

proc generateBuildFile(c: DepContext): string =
  ## Generate the .build.nif file for nifmake
  result = getNimcacheDir(c.config).string / c.nodes[0].files[0].modname & ".build.nif"

  var b = nifbuilder.open(result)
  defer: b.close()

  b.addHeader("nim deps", "nifmake")
  b.addTree "stmts"

  # Define nifler command
  b.addTree "cmd"
  b.addSymbolDef "nifler"
  b.addStrLit c.nifler
  b.addStrLit "parse"
  b.addStrLit "--deps"
  b.addTree "input"
  b.endTree()
  b.addTree "output"
  b.endTree()
  b.endTree()

  # Define nim m command
  b.addTree "cmd"
  b.addSymbolDef "nim_m"
  b.addStrLit getAppFilename()
  b.addStrLit "m"
  # Add search paths
  for p in c.config.searchPaths:
    b.addStrLit "--path:" & p.string
  b.addTree "input"
  b.addIntLit 0
  b.endTree()
  b.endTree()

  # Build rules for parsing (nifler)
  var seenFiles = initHashSet[string]()
  for node in c.nodes:
    for pair in node.files:
      let parsed = c.parsedFile(pair)
      if not seenFiles.containsOrIncl(parsed):
        b.addTree "do"
        b.addIdent "nifler"
        b.addTree "input"
        b.addStrLit pair.nimFile
        b.endTree()
        b.addTree "output"
        b.addStrLit parsed
        b.endTree()
        b.addTree "output"
        b.addStrLit c.depsFile(pair)
        b.endTree()
        b.endTree()

  # Build rules for semantic checking (nim m)
  for i in countdown(c.nodes.len - 1, 0):
    let node = c.nodes[i]
    let pair = node.files[0]
    b.addTree "do"
    b.addIdent "nim_m"
    # Input: all parsed files for this module
    for f in node.files:
      b.addTree "input"
      b.addStrLit c.parsedFile(f)
      b.endTree()
    # Also depend on semmed files of dependencies
    for depIdx in node.deps:
      b.addTree "input"
      b.addStrLit c.semmedFile(c.nodes[depIdx].files[0])
      b.endTree()
    # Output: semmed file
    b.addTree "output"
    b.addStrLit c.semmedFile(pair)
    b.endTree()
    b.addTree "args"
    b.addStrLit pair.nimFile
    b.endTree()
    b.endTree()

  b.endTree()  # stmts

proc commandDeps*(conf: ConfigRef) =
  ## Main entry point for `nim deps`
  when not defined(nimKochBootstrap):
    let nifler = findNifler()
    if nifler.len == 0:
      rawMessage(conf, errGenerated, "nifler tool not found. Install nimony or add nifler to PATH.")
      return

    let projectFile = conf.projectFull.string
    if not fileExists(projectFile):
      rawMessage(conf, errGenerated, "project file not found: " & projectFile)
      return

    # Create nimcache directory
    createDir(getNimcacheDir(conf).string)

    var c = DepContext(
      config: conf,
      nifler: nifler,
      nodes: @[],
      processedModules: initTable[string, int](),
      includeStack: @[]
    )

    # Create root node for main project file
    let rootPair = c.toPair(projectFile)
    let rootNode = Node(files: @[rootPair], id: 0)
    c.nodes.add rootNode
    c.processedModules[rootPair.modname] = 0

    # Process dependencies
    traverseDeps(c, rootPair, rootNode)

    # Generate build file
    let buildFile = generateBuildFile(c)
    rawMessage(conf, hintSuccess, "generated: " & buildFile)
    rawMessage(conf, hintSuccess, "run: nifmake run " & buildFile)
  else:
    rawMessage(conf, errGenerated, "nim deps not available in bootstrap build")
