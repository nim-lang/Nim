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

import std / [os, tables, sets, times, osproc]
import options, msgs, lineinfos, pathutils

import "../dist/nimony/src/lib" / [nifstreams, bitabs, nifreader, nifbuilder]
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
    systemNodeId: int  # ID of the system.nim node

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
  let nimDir = getAppDir()
  result = nimDir / "nifler"
  if not fileExists(result):
    result = findExe("nifler")

proc findNifmake(): string =
  # Look for nifmake in common locations
  # Try relative to nim executable
  let nimDir = getAppDir()
  result = nimDir / "nifmake"
  if not fileExists(result):
    result = findExe("nifmake")

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

proc resolveImport(c: DepContext; origin, toResolve: string): string =
  ## Resolve an import path using the compiler's normal module lookup rules.
  result = findModule(c.config, toResolve, origin).string

proc resolveInclude(c: DepContext; origin, toResolve: string): string =
  ## Resolve an include path relative to the including file or the search paths.
  let originDir = parentDir(origin)
  result = originDir / toResolve.addFileExt("nim")
  if fileExists(result):
    return result

  for searchPath in c.config.searchPaths:
    result = searchPath.string / toResolve.addFileExt("nim")
    if fileExists(result):
      return result

  result = ""

proc traverseDeps(c: var DepContext; pair: FilePair; current: Node)

proc processInclude(c: var DepContext; includePath: string; current: Node) =
  let resolved = resolveInclude(c, current.files[current.files.len - 1].nimFile, includePath)
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
  let resolved = resolveImport(c, current.files[0].nimFile, importPath)
  if resolved.len == 0 or not fileExists(resolved):
    return

  let pair = c.toPair(resolved)
  let existingIdx = c.processedModules.getOrDefault(pair.modname, -1)

  if existingIdx == -1:
    # New module - create node and process it
    let newNode = Node(files: @[pair], id: c.nodes.len)
    current.deps.add newNode.id
    # Every module depends on system.nim
    if c.systemNodeId >= 0:
      newNode.deps.add c.systemNodeId
    c.processedModules[pair.modname] = newNode.id
    c.nodes.add newNode
    traverseDeps(c, pair, newNode)
  else:
    # Already processed - just add dependency
    if existingIdx notin current.deps:
      current.deps.add existingIdx

proc skipSubtree(s: var Stream; first: PackedToken) =
  ## Consume tokens until the ParLe at `first` is balanced. Caller has
  ## already obtained `first`.
  if first.kind != ParLe: return
  var depth = 1
  while depth > 0:
    let t = next(s)
    if t.kind == ParLe: inc depth
    elif t.kind == ParRi: dec depth
    elif t.kind == EofToken: return

proc evalCondExpr(c: DepContext; s: var Stream): bool =
  ## Read exactly one condition expression from `s` and return its truth
  ## value. Consumes tokens whether the expression is recognised or not so
  ## the caller stays in sync. Recognises `defined(IDENT)`, the boolean
  ## operators `not`/`and`/`or`, and the literals `true`/`false`. Anything
  ## else (e.g. a call to an arbitrary proc) is treated as `true` — the
  ## conservative direction, since a false negative here drops a real
  ## dependency from the build graph.
  let t = next(s)
  case t.kind
  of Ident:
    case pool.strings[t.litId]
    of "true": result = true
    of "false": result = false
    else: result = true
  of ParLe:
    let tag = pool.tags[t.tagId]
    case tag
    of "call", "cmd", "callstrlit", "infix", "prefix":
      # First child is the head (function/operator name).
      let head = next(s)
      var name = ""
      if head.kind == Ident: name = pool.strings[head.litId]
      case name
      of "defined":
        let arg = next(s)
        var sym = ""
        if arg.kind == Ident: sym = pool.strings[arg.litId]
        result = sym.len > 0 and isDefined(c.config, sym)
      of "not":
        result = not evalCondExpr(c, s)
      of "and":
        result = evalCondExpr(c, s)
        if result: result = evalCondExpr(c, s)
        else: skipSubtree(s, next(s))
      of "or":
        result = evalCondExpr(c, s)
        if not result: result = evalCondExpr(c, s)
        else: skipSubtree(s, next(s))
      else:
        result = true
      # Drain whatever remains until the matching ParRi.
      var depth = 1
      while depth > 0:
        let n = next(s)
        if n.kind == ParLe: inc depth
        elif n.kind == ParRi: dec depth
        elif n.kind == EofToken: return
    of "not":
      result = not evalCondExpr(c, s)
      var depth = 1
      while depth > 0:
        let n = next(s)
        if n.kind == ParLe: inc depth
        elif n.kind == ParRi: dec depth
        elif n.kind == EofToken: return
    of "and":
      result = evalCondExpr(c, s)
      if result: result = evalCondExpr(c, s)
      else: skipSubtree(s, next(s))
      # consume closing ParRi
      var depth = 1
      while depth > 0:
        let n = next(s)
        if n.kind == ParLe: inc depth
        elif n.kind == ParRi: dec depth
        elif n.kind == EofToken: return
    of "or":
      result = evalCondExpr(c, s)
      if not result: result = evalCondExpr(c, s)
      else: skipSubtree(s, next(s))
      var depth = 1
      while depth > 0:
        let n = next(s)
        if n.kind == ParLe: inc depth
        elif n.kind == ParRi: dec depth
        elif n.kind == EofToken: return
    else:
      skipSubtree(s, t)
      result = true
  else:
    result = true

proc whenMarkerHolds(c: DepContext; s: var Stream): bool =
  ## Caller has just consumed the `(when` ParLe. Read children until the
  ## matching `)`, AND-ing each evaluated condition.
  result = true
  while true:
    # peek by reading; if it's ParRi, we're done
    let t = next(s)
    if t.kind == ParRi: return
    if t.kind == EofToken: return
    if t.kind == ParLe:
      # Re-feed by manually evaluating the subtree starting at `t`.
      # evalCondExpr expects to read its own opener, so handle it directly.
      let tag = pool.tags[t.tagId]
      case tag
      of "call", "cmd", "callstrlit", "infix", "prefix":
        let head = next(s)
        var name = ""
        if head.kind == Ident: name = pool.strings[head.litId]
        var ok = true
        case name
        of "defined":
          let arg = next(s)
          var sym = ""
          if arg.kind == Ident: sym = pool.strings[arg.litId]
          ok = sym.len > 0 and isDefined(c.config, sym)
        of "not":
          ok = not evalCondExpr(c, s)
        of "and":
          ok = evalCondExpr(c, s)
          if ok: ok = evalCondExpr(c, s)
        of "or":
          ok = evalCondExpr(c, s)
          if not ok: ok = evalCondExpr(c, s)
        else:
          ok = true
        # finish the subtree
        var depth = 1
        while depth > 0:
          let n = next(s)
          if n.kind == ParLe: inc depth
          elif n.kind == ParRi: dec depth
          elif n.kind == EofToken: return
        if not ok: result = false
      of "not", "and", "or":
        # Re-emit a synthetic dispatch: rewrap by descending.
        var ok = true
        case tag
        of "not":
          ok = not evalCondExpr(c, s)
        of "and":
          ok = evalCondExpr(c, s)
          if ok: ok = evalCondExpr(c, s)
        of "or":
          ok = evalCondExpr(c, s)
          if not ok: ok = evalCondExpr(c, s)
        else: discard
        var depth = 1
        while depth > 0:
          let n = next(s)
          if n.kind == ParLe: inc depth
          elif n.kind == ParRi: dec depth
          elif n.kind == EofToken: return
        if not ok: result = false
      else:
        # Unknown — treat as true and skip.
        skipSubtree(s, t)
    elif t.kind == Ident:
      let v = pool.strings[t.litId]
      if v == "false": result = false
      # else (true / unknown ident): keep result

proc parseImportPath(s: var Stream; t: var PackedToken): seq[string] =
  ## Parse an import path expression and return the list of module paths it
  ## refers to. Handles plain idents (`foo`), string literals, `std/foo`
  ## infixes (including nested ones like `std/private/since`) and bracketed
  ## groups like `std/[bitops, fenv]` which expand to several imports.
  ## On entry `t` is the first token of the expression; on exit `t` is the
  ## token immediately following the whole expression.
  result = @[]
  case t.kind
  of Ident:
    result.add pool.strings[t.litId]
    t = next(s)
  of StringLit:
    result.add pool.strings[t.litId]
    t = next(s)
  of ParLe:
    let tag = pool.tags[t.tagId]
    if tag == "infix":
      t = next(s)                      # skip 'infix' tag
      if t.kind == Ident: t = next(s)  # skip the operator (`/`)
      let left = parseImportPath(s, t)
      let right = parseImportPath(s, t)
      let prefix = if left.len == 1: left[0] else: ""
      for r in right:
        if prefix.len > 0: result.add prefix & "/" & r
        else: result.add r
      if t.kind == ParRi: t = next(s)  # skip closing ')'
    elif tag == "bracket":
      t = next(s)                      # skip 'bracket' tag
      while t.kind != ParRi and t.kind != EofToken:
        result.add parseImportPath(s, t)
      if t.kind == ParRi: t = next(s)  # skip closing ')'
    else:
      # Unknown subtree: skip it entirely.
      var depth = 1
      t = next(s)
      while depth > 0 and t.kind != EofToken:
        if t.kind == ParLe: inc depth
        elif t.kind == ParRi: dec depth
        if depth == 0: break
        t = next(s)
      if t.kind == ParRi: t = next(s)
  else:
    t = next(s)

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
      of "import", "fromimport", "include":
        # Read first child. May be a `(when COND...)` marker — parse and
        # evaluate; if the condition is statically false, skip the import
        # entirely. Otherwise advance past the marker and parse the path.
        t = next(s)
        var live = true
        if t.kind == ParLe and pool.tags[t.tagId] == "when":
          # whenMarkerHolds consumes everything up to and including the
          # closing `)` of the `(when ...)` subtree.
          live = whenMarkerHolds(c, s)
          t = next(s)
        if not live:
          # Drain the rest of this import/include node.
          var depth = 1
          while depth > 0:
            let n = next(s)
            if n.kind == ParLe: inc depth
            elif n.kind == ParRi: dec depth
            elif n.kind == EofToken: break
          t = next(s)
          continue
        # Process the path expression(s). Each path supports plain idents,
        # string literals, `std/foo` infixes (possibly nested, e.g.
        # `std/private/since`) and bracketed groups like `std/[bitops, fenv]`
        # that expand to several imports. A plain `import a, b, c` lists several
        # modules as siblings; a `fromimport` has a single path followed by the
        # imported symbol list, which must not be treated as modules.
        if tag == "fromimport":
          for importPath in parseImportPath(s, t):
            if importPath.len > 0:
              processImport(c, importPath, current)
        else:
          while t.kind != ParRi and t.kind != EofToken:
            for importPath in parseImportPath(s, t):
              if importPath.len > 0:
                if tag == "include":
                  processInclude(c, importPath, current)
                else:
                  processImport(c, importPath, current)
        # Drain any remaining tokens of this node (e.g. the symbol list of a
        # `fromimport`), up to and including the node's closing ')'.
        var depth = 1
        while depth > 0 and t.kind != EofToken:
          if t.kind == ParLe: inc depth
          elif t.kind == ParRi: dec depth
          if depth == 0: break
          t = next(s)
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
  let nimcache = getNimcacheDir(c.config).string
  createDir(nimcache)
  result = nimcache / c.nodes[0].files[0].modname & ".build.nif"

  var b = nifbuilder.open(result)
  defer: b.close()

  b.addHeader("nim ic", "nifmake")
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
  b.addStrLit "--nimcache:" & nimcache
  # Add search paths
  for p in c.config.searchPaths:
    b.addStrLit "--path:" & p.string
  b.addTree "args"
  b.endTree()
  b.withTree "input":
    b.addIntLit 0  # main parsed file
  b.endTree()

  # Define nim nifc command
  b.addTree "cmd"
  b.addSymbolDef "nim_nifc"
  b.addStrLit getAppFilename()
  b.addStrLit "nifc"
  b.addStrLit "--nimcache:" & nimcache
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
    b.withTree "input":
      b.addStrLit node.files[0].nimFile
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
    b.endTree()

  # Final compilation step: generate executable from main module
  let mainNif = c.nodes[0].files[0].nimFile
  let exeFile = changeFileExt(c.nodes[0].files[0].nimFile, ExeExt)
  b.addTree "do"
  b.addIdent "nim_nifc"
  # Input: .nim file (expanded as argument)
  b.addTree "input"
  b.addStrLit mainNif
  b.endTree()
  # Also depend on the semmed .nif files of the main module and all its
  # dependencies. nifmake's topological sort orders nodes by depth; without
  # these inputs the nim_nifc node sits at depth 1 (no recognized inputs)
  # alongside the nifler nodes and runs *before* the nim_m steps that
  # produce the .nif files it needs to read.
  for node in c.nodes:
    b.addTree "input"
    b.addStrLit c.semmedFile(node.files[0])
    b.endTree()
  b.addTree "output"
  b.addStrLit exeFile
  b.endTree()
  b.endTree()

  b.endTree()  # stmts

proc commandIc*(conf: ConfigRef) =
  ## Main entry point for `nim ic`
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
      includeStack: @[],
      systemNodeId: -1
    )

    # Create root node for main project file
    let rootPair = c.toPair(projectFile)
    let rootNode = Node(files: @[rootPair], id: 0)
    c.nodes.add rootNode
    c.processedModules[rootPair.modname] = 0

    # model the system.nim dependency:
    let sysNode = Node(files: @[toPair(c, (conf.libpath / RelativeFile"system.nim").string)], id: 1)
    c.nodes.add sysNode
    c.systemNodeId = sysNode.id
    rootNode.deps.add sysNode.id

    # Process dependencies
    traverseDeps(c, rootPair, rootNode)

    # Generate build file
    let buildFile = generateBuildFile(c)
    rawMessage(conf, hintSuccess, "generated: " & buildFile)

    # Automatically run nifmake
    let nifmake = findNifmake()
    if nifmake.len == 0:
      rawMessage(conf, hintSuccess, "run: nifmake run " & buildFile)
    else:
      let cmd = quoteShell(nifmake) & " run " & quoteShell(buildFile)
      rawMessage(conf, hintExecuting, cmd)
      let exitCode = execShellCmd(cmd)
      if exitCode != 0:
        rawMessage(conf, errGenerated, "nifmake failed with exit code: " & $exitCode)
  else:
    rawMessage(conf, errGenerated, "nim ic not available in bootstrap build")
