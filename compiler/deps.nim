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

import std / [os, tables, sets, times, osproc, algorithm, strtabs, strutils, syncio]
import options, msgs, lineinfos, pathutils, condsyms, icconfig

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

proc ifaceFile(c: DepContext; f: FilePair): string =
  ## Interface-cookie sidecar written by `nim m` (ast2nif.writeIfaceCookie,
  ## OnlyIfChanged). Dependents' nim_m rules use it as their input instead of
  ## the semmed NIF: a body-only change in a dependency then keeps the sidecar
  ## mtime and nifmake prunes the whole re-sem cascade behind it.
  getNimcacheDir(c.config).string / f.modname & ".iface.nif"

proc implFile(c: DepContext; suffix: string): string =
  ## Implementation-cookie sidecar (ast2nif.writeImplCookie): flips on ANY
  ## content change of the module (private bodies included; supersedes the
  ## iface cookie). Used as the edge for dependents that consumed the
  ## module's bodies at compile time (NeedsImpl edges).
  getNimcacheDir(c.config).string / suffix & ".impl.nif"

proc edgesFile(c: DepContext; f: FilePair): string =
  getNimcacheDir(c.config).string / f.modname & ".edges.nif"

proc readNeedsImpl(c: DepContext; f: FilePair): seq[string] =
  ## Reads the module's recorded NeedsImpl edge set (module suffixes whose
  ## bodies its last sem consumed at compile time). Missing file (never
  ## compiled yet) -> empty: the rule fires anyway on the first build and the
  ## recording exists from then on. Recordings are self-correcting with a
  ## one-run lag: whatever changes a module's consumption set is itself a
  ## gated input of its rule, so the rule re-fires and re-records.
  result = @[]
  if fileExists(c.edgesFile(f)):
    var s = nifstreams.open(c.edgesFile(f))
    try:
      discard processDirectives(s.r)
      while true:
        let t = next(s)
        if t.kind == EofToken: break
        if t.kind == StringLit:
          result.add pool.strings[t.litId]
    finally:
      close s

proc semDepsFile(c: DepContext; f: FilePair): string =
  getNimcacheDir(c.config).string / f.modname & ".s.deps.nif"

proc readSemDeps(c: DepContext; f: FilePair): seq[string] =
  ## The module's REAL direct imports (full source paths) as sem resolved them,
  ## including macro-generated imports the static scanner missed
  ## (ast2nif.writeSemDeps). Missing file (not yet semmed) -> empty.
  result = @[]
  if fileExists(c.semDepsFile(f)):
    var s = nifstreams.open(c.semDepsFile(f))
    try:
      discard processDirectives(s.r)
      while true:
        let t = next(s)
        if t.kind == EofToken: break
        if t.kind == StringLit:
          result.add pool.strings[t.litId]
    finally:
      close s

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
  ## NOTE: the `setLastModificationTime` coordination below is a known hack; its
  ## clean removal lands with the Phase 2 frontend/backend split, which redefines
  ## this pre-scan's role. (A naive switch to keying on the parsed file produced
  ## a stale warm rebuild, so it's left intact until the restructure.)
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
  if result:
    # The build graph's `nifler parse --deps` rule outputs BOTH the parsed
    # file and the deps file. Refreshing the deps file here would MASK that
    # rule: nifmake's `needsRebuild` takes the freshest output as proof of
    # "ran since the inputs changed", so the rule never re-fires and the
    # parsed file goes stale. For an import-cycle group that loses the edit
    # entirely — a non-representative member's source is not a direct input
    # of the group's `nim_m` rule; its only build-graph connection is the
    # (now stale) parsed file. Drop a genuinely stale parsed file so the
    # nifler rule re-fires on the missing output.
    let parsedPath = c.parsedFile(pair)
    if fileExists(parsedPath) and
       getLastModificationTime(parsedPath) < getLastModificationTime(nimFile):
      removeFile(parsedPath)
    # nifler writes OnlyIfChanged: after an edit that leaves the import set
    # unchanged the deps file keeps its old mtime and would stay older than
    # the source forever, re-running this scan (and re-deleting the parsed
    # file) on every warm build. Bump it explicitly: it is the scan's own
    # up-to-date marker.
    if getLastModificationTime(depsPath) < getLastModificationTime(nimFile):
      setLastModificationTime(depsPath, getTime())

proc resolveImport(c: DepContext; origin, toResolve: string): string =
  ## Resolve an import path using the compiler's normal module lookup rules.
  var toResolve = toResolve
  if '$' in toResolve:
    # string-literal import paths support `$nim`-style substitutions
    # (see modulepaths.getModuleName)
    try:
      toResolve = pathSubs(c.config, toResolve, origin.splitFile().dir)
    except ValueError:
      discard
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

proc evalCondIdent(c: DepContext; v: string): bool =
  ## Truth value of a bare identifier appearing in a `when` condition.
  case v
  of "false": false
  of "hasThreadSupport":
    # system.nim's `hasThreadSupport` is `compileOption("threads") and
    # not defined(nimscript)`; the conservative `true` would schedule the
    # threads-only modules (syslocks, threadtypes, sharedlist, locks)
    # whose NIFs a --threads:off compile never produces — nifmake then
    # sees missing outputs and re-runs the system rule (and everything
    # downstream) on every rerun.
    optThreads in c.config.globalOptions
  of "usesDestructors":
    # system.nim's `usesDestructors = defined(gcDestructors) or
    # defined(gcHooks)`; guards mmdisp.nim's `include "system/gc"` whose
    # transitive imports (sharedlist, locks) an orc compile never produces.
    isDefined(c.config, "gcDestructors") or isDefined(c.config, "gcHooks")
  else: true

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
    result = evalCondIdent(c, pool.strings[t.litId])
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
    of "par":
      # a parenthesised grouping such as `(defined(a) or defined(b))`: evaluate
      # the inner expression. Without this, `par` fell through to the `else`
      # branch below and evaluated to `true`, which silently inverted conditions
      # like `not (defined(macosx) or defined(bsd))` and dropped real imports
      # (e.g. `cpuinfo`'s conditional `import std/posix`).
      result = evalCondExpr(c, s)
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
      if not evalCondIdent(c, pool.strings[t.litId]): result = false
      # a true / unknown ident keeps the current result

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
      var op = ""
      if t.kind == Ident:
        op = pool.strings[t.litId]
        t = next(s)
      let left = parseImportPath(s, t)
      let right = parseImportPath(s, t)
      if op == "as":
        # `import ../rlp/results as rlp_results`: the alias is not a path
        # component — treating `as` like `/` produced the garbage path
        # `../rlp/results/rlp_results`, silently dropping the dependency
        result = left
      else:
        let prefix = if left.len == 1: left[0] else: ""
        for r in right:
          if prefix.len > 0: result.add prefix & "/" & r
          else: result.add r
      if t.kind == ParRi: t = next(s)  # skip closing ')'
    elif tag == "prefix":
      # Relative import paths: `import ../dist/checksums/...` parses as
      # `(prefix ../ dist)` — a path-prefix operator (`../`, `./`) applied to
      # the first path component. Concatenate operator and operand verbatim;
      # `findModule` resolves the relative path against the importing module.
      t = next(s)                      # skip 'prefix' tag
      var op = ""
      if t.kind == Ident:
        op = pool.strings[t.litId]
        t = next(s)
      for r in parseImportPath(s, t):
        result.add op & r
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
      of "import", "fromimport", "importexcept", "include":
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
        if tag == "fromimport" or tag == "importexcept":
          # `from m import syms` / `import m except syms`: the first child is the
          # module path; the rest is the (in/ex)cluded symbol list, which must not
          # be treated as modules. Both still create a real dependency on `m`.
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

proc computeSCCs(c: DepContext): seq[seq[int]] =
  ## Tarjan's strongly-connected-components over the module dependency graph
  ## (`node.deps`). Each returned component is a list of node indices; a module
  ## that is not part of any import cycle yields a singleton component. Tarjan
  ## emits components in reverse-topological order (a component's external
  ## dependencies come out before it), which is exactly the order `nifmake`
  ## needs for the per-group `nim m` build rules.
  type Frame = object
    v, pi: int
  let n = c.nodes.len
  var index = newSeq[int](n)
  var lowlink = newSeq[int](n)
  var onStack = newSeq[bool](n)
  var visited = newSeq[bool](n)
  var stack: seq[int] = @[]
  var counter = 0
  result = @[]

  # Iterative Tarjan (explicit work stack) so a deep module-dependency chain
  # cannot overflow the call stack.
  for start in 0..<n:
    if visited[start]: continue
    var work = @[Frame(v: start, pi: 0)]
    while work.len > 0:
      let v = work[^1].v
      if work[^1].pi == 0:
        visited[v] = true
        index[v] = counter
        lowlink[v] = counter
        inc counter
        stack.add v
        onStack[v] = true
      if work[^1].pi < c.nodes[v].deps.len:
        let w = c.nodes[v].deps[work[^1].pi]
        inc work[^1].pi
        if not visited[w]:
          work.add Frame(v: w, pi: 0)
        elif onStack[w]:
          lowlink[v] = min(lowlink[v], index[w])
      else:
        if lowlink[v] == index[v]:
          var comp: seq[int] = @[]
          while true:
            let w = stack.pop()
            onStack[w] = false
            comp.add w
            if w == v: break
          result.add comp
        work.setLen work.len - 1
        if work.len > 0:
          lowlink[work[^1].v] = min(lowlink[work[^1].v], lowlink[v])

proc computeForwardedArgs(c: DepContext): seq[string] =
  ## Config/define forwarding shared by the frontend (`nim m`) and backend
  ## (`nim nifc`) child commands. Depends only on the driver's config, not on
  ## the dependency graph, so it is computed once per `nim ic` run (and also
  ## writes the precompiled-config artifact the children replay).
  ##
  # Forward the project's configuration to the per-module child processes.
  # Non-incremental compilation semchecks every module in one process with one
  # define set (the project's config files apply to the stdlib too); the IC
  # children compile with the *module* as their project file and would miss
  # e.g. compiler/nim.cfg's `define:nimPreviewSlimSystem`, so their `when`
  # bodies — and thus their import sets and NIF contents — would silently
  # diverge from the dependency graph computed here. Forward every define that
  # is not part of the compiler's built-in baseline, plus the threads switch.
  let nimcache = getNimcacheDir(c.config).string
  result = @[]
  let baseline = newStringTable(modeStyleInsensitive)
  initDefines(baseline)
  for k, v in pairs(c.config.symbols):
    if not baseline.hasKey(k) or baseline[k] != v:
      result.add "--define:" & k & (if v == "true": "" else: "=" & v)
  sort result
  result.add "--threads:" & (if optThreads in c.config.globalOptions: "on" else: "off")
  # Forward the memory-management mode too: the children would otherwise
  # compile with the default GC while the dependency graph here was computed
  # with the selected one (e.g. under --mm:refc the scanner keeps
  # system/gc's transitive imports but default-orc children never compile
  # them — phantom outputs that re-fire the build on every rerun).
  if c.config.selectedGC != gcUnselected:
    result.add "--mm:" & $c.config.selectedGC
  # method dispatch semantics must match across the child processes:
  # a child compiled without --multimethods:on builds different dispatch
  # buckets (and rejects calls as ambiguous that multi-dispatch accepts)
  if optMultiMethods in c.config.globalOptions:
    result.add "--multimethods:on"
  # the children compile each MODULE as their own project file, which makes
  # that module's package the "main package" and unfilters foreign-package
  # diagnostics — a vendored package's hintAsError/warningAsError promotions
  # then abort builds the whole-program compilation accepts. Forward the
  # real project so children filter diagnostics identically.
  result.add "--icproject:" & c.config.projectFull.string
  # Precompiled config: serialise the driver's config once and have every
  # child replay it instead of re-parsing the `nim.cfg` chain and re-running
  # `config.nims` in the VM. See compiler/icconfig.nim. `-d:icNoPreparsedConfig`
  # restores the old per-child config parsing (for bisecting a suspected
  # config-replay divergence without clearing caches).
  if not isDefined(c.config, "icNoPreparsedConfig"):
    let cfgArtifact = nimcache / "ic_config.cfg.nif"
    writeIcConfig(c.config, cfgArtifact)
    result.add "--icPreparsedConfig:" & cfgArtifact

proc generateFrontendBuildFile(c: DepContext; forwardedArgs: seq[string]): string =
  ## Frontend build file: the nifler (parse) and `nim m` (sem) rules only. The
  ## driver runs this to a discovery fixpoint; it produces every module's semmed
  ## NIF plus the cookie/edge sidecars that the backend build file then consumes.
  ## The backend step lives in its own nifmake run (generateBackendBuildFile) so
  ## that "which TUs rebuild" stays a pure nifmake mtime decision rather than
  ## something the driver interleaves with the `.s.deps` discovery loop. This
  ## split is also the scaffold for the per-module backend: once the backend is
  ## per-module, its rules slot into the backend file unchanged.
  let nimcache = getNimcacheDir(c.config).string
  createDir(nimcache)
  result = nimcache / c.nodes[0].files[0].modname & ".frontend.build.nif"

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
  for a in forwardedArgs:
    b.addStrLit a
  b.addTree "args"
  b.endTree()
  b.withTree "input":
    b.addIntLit 0  # main parsed file
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

  # Build rules for semantic checking (nim m).
  #
  # Modules are grouped into strongly-connected components: a module that is not
  # in an import cycle is its own singleton group and compiles in its own
  # `nim m <mod>` invocation as before. A cycle (A imports B, B imports A) cannot
  # be ordered for separate per-module compilation, so the whole component is
  # handed to a single `nim m` invocation: the first member is the project file,
  # every member is passed via `--icGroup:<path>` so the compiler compiles them
  # all from source in one process (resolving the recursion in-memory) and writes
  # a NIF for each. Only dependencies *outside* the component become build-graph
  # inputs — intra-component edges are produced by this very rule and listing
  # them would reintroduce the cycle nifmake just rejected.
  let sccs = computeSCCs(c)
  var sccOf = newSeq[int](c.nodes.len)
  for sccId, comp in sccs:
    for nodeIdx in comp: sccOf[nodeIdx] = sccId
  for comp in sccs:
    # Representative (project file for this invocation) = smallest node id, so a
    # component containing the root (node 0) is driven by the root.
    var members = comp
    members.sort()
    let repPair = c.nodes[members[0]].files[0]
    let isGroup = members.len > 1
    b.addTree "do"
    b.addIdent "nim_m"
    b.addTree "args"
    # The root module (node 0) is the program's real entry point; mark it so
    # `isMainModule` resolves to true only for it (every module otherwise gets
    # `sfMainModule` for NIF writing under `nim m`).
    if members[0] == 0:
      b.addStrLit "--isMainModule:on"
    # For a real cycle, tell the compiler which modules form the group so it
    # compiles them all from source and writes each one's NIF.
    if isGroup:
      for m in members:
        b.addStrLit "--icGroup:" & c.nodes[m].files[0].nimFile
    b.endTree()
    # Input 0 (the project file passed to `nim m`): the representative's .nim.
    b.withTree "input":
      b.addStrLit repPair.nimFile
    # All parsed files of every member (nifler outputs this group consumes).
    for m in members:
      for f in c.nodes[m].files:
        b.addTree "input"
        b.addStrLit c.parsedFile(f)
        b.endTree()
    # Depend on the dependencies *outside* this component — on their interface
    # COOKIE sidecars, not the semmed NIFs themselves: the sidecar's mtime only
    # moves when the dep's importer-visible surface (or, via hash chaining, any
    # surface in its import closure) changed, so body-only edits stop the
    # re-sem cascade right here. Dependencies whose BODIES the last sem of a
    # member consumed at compile time (the recorded NeedsImpl edge set) are
    # gated on their IMPL cookie instead, which flips on any content change:
    # `const x = dep.foo()` then re-sems when foo's body changes.
    # `-d:icNoIfaceGate` restores the old full-NIF edges.
    let ifaceGate = not isDefined(c.config, "icNoIfaceGate")
    var needsImpl = initHashSet[string]()
    if ifaceGate:
      # union over the members; restricted to the group's transitive dep
      # closure: a stale recording naming a module this group no longer
      # imports cannot be consumed anymore (and honoring it could even create
      # a build-graph cycle after refactorings).
      var reachable = initHashSet[string]()
      var stack: seq[int] = @[]
      for m in members:
        for depIdx in c.nodes[m].deps:
          if sccOf[depIdx] != sccOf[members[0]]: stack.add depIdx
      var visited = initHashSet[int]()
      while stack.len > 0:
        let n = stack.pop()
        if visited.containsOrIncl(n): continue
        reachable.incl c.nodes[n].files[0].modname
        for depIdx in c.nodes[n].deps: stack.add depIdx
      for m in members:
        for suffix in readNeedsImpl(c, c.nodes[m].files[0]):
          if suffix in reachable: needsImpl.incl suffix
    var seenDep = initHashSet[string]()
    var directDeps = initHashSet[string]()
    for m in members:
      for depIdx in c.nodes[m].deps:
        if sccOf[depIdx] == sccOf[m]: continue  # intra-component edge
        let depName = c.nodes[depIdx].files[0].modname
        directDeps.incl depName
        let depFile =
          if not ifaceGate: c.semmedFile(c.nodes[depIdx].files[0])
          elif depName in needsImpl: c.implFile(depName)
          else: c.ifaceFile(c.nodes[depIdx].files[0])
        if not seenDep.containsOrIncl(depFile):
          b.addTree "input"
          b.addStrLit depFile
          b.endTree()
    # NeedsImpl on modules that are not direct imports (bodies consumed via
    # re-exports or transitively, e.g. a macro's private helper two hops
    # away): additional impl-cookie inputs.
    if ifaceGate:
      var extra: seq[string] = @[]
      for suffix in needsImpl:
        if suffix notin directDeps: extra.add suffix
      sort extra
      for suffix in extra:
        b.addTree "input"
        b.addStrLit c.implFile(suffix)
        b.endTree()
    # Output: one semmed NIF (plus its cookie/edge sidecars) per member.
    for m in members:
      b.addTree "output"
      b.addStrLit c.semmedFile(c.nodes[m].files[0])
      b.endTree()
      if ifaceGate:
        b.addTree "output"
        b.addStrLit c.ifaceFile(c.nodes[m].files[0])
        b.endTree()
        b.addTree "output"
        b.addStrLit c.implFile(c.nodes[m].files[0].modname)
        b.endTree()
        b.addTree "output"
        b.addStrLit c.edgesFile(c.nodes[m].files[0])
        b.endTree()
    b.endTree()

  b.endTree()  # stmts

proc generateBackendBuildFile(c: DepContext; forwardedArgs: seq[string]): string =
  ## Backend build file: today a single whole-program `nim nifc` rule that reads
  ## every module's semmed NIF and emits/compiles/links the executable. The
  ## driver runs it once, after the frontend fixpoint (the semmed NIFs already
  ## exist on disk, so they enter this graph as leaf inputs with no producing
  ## rule, exactly like the nifler rules' source `.nim` inputs). The per-module
  ## backend rewrite replaces this one rule with per-module codegen + a DCE rule
  ## + a link rule; nothing else here changes.
  let nimcache = getNimcacheDir(c.config).string
  createDir(nimcache)
  result = nimcache / c.nodes[0].files[0].modname & ".backend.build.nif"

  var b = nifbuilder.open(result)
  defer: b.close()

  b.addHeader("nim ic", "nifmake")
  b.addTree "stmts"

  # Define nim nifc command
  b.addTree "cmd"
  b.addSymbolDef "nim_nifc"
  b.addStrLit getAppFilename()
  b.addStrLit "nifc"
  b.addStrLit "--nimcache:" & nimcache
  # Add search paths
  for p in c.config.searchPaths:
    b.addStrLit "--path:" & p.string
  for a in forwardedArgs:
    b.addStrLit a
  b.addTree "input"
  b.addIntLit 0
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

    # Create nimcache directory; start from a clean one when its format
    # stamp is absent or outdated (see `icFormatVersion`)
    let cacheDir = getNimcacheDir(conf).string
    createDir(cacheDir)
    let versionFile = cacheDir & "/ic.version"
    let stamp = if fileExists(versionFile): readFile(versionFile) else: ""
    if stamp != icFormatVersion:
      removeDir(cacheDir)
      createDir(cacheDir)
      writeFile(versionFile, icFormatVersion)

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
    let sysPair = toPair(c, (conf.libpath / RelativeFile"system.nim").string)
    if sysPair.modname != rootPair.modname:
      let sysNode = Node(files: @[sysPair], id: 1)
      c.nodes.add sysNode
      c.systemNodeId = sysNode.id
      rootNode.deps.add sysNode.id
      c.processedModules[sysPair.modname] = sysNode.id
      # Traverse system.nim's own dependency tree. `nim m system.nim` compiles
      # system's entire import closure from source in one process (none of it
      # can be precompiled: every module implicitly imports system) and writes
      # a NIF for each closure member. Every member also gets the implicit
      # dependency edge on system, so Tarjan folds the whole closure into
      # system's strongly-connected component and the build file contains a
      # single rule producing all of those NIFs. Without this traversal each
      # closure member that is also imported by an ordinary module got its own
      # `nim m` rule whose output silently OVERWROTE the system-written NIF
      # with freshly numbered type ids, leaving dangling type references (the
      # ids are baked into sysma2dyk.nif and into every module semchecked
      # against the first version) — "symbol has no offset" failures that
      # depended on nifmake's scheduling.
      traverseDeps(c, sysPair, sysNode)

    # Process dependencies
    traverseDeps(c, rootPair, rootNode)

    # Discovery via `.s.deps`: imports GENERATED by macros (chronicles builds
    # `import chronicles/textlines` via parseStmt from the chronicles_sinks
    # define) are invisible to the static scanner. Each `nim m` records the
    # imports it ACTUALLY resolved (static + macro-generated) into a
    # `.s.deps.nif` sidecar (ast2nif.writeSemDeps); a child that fails on a
    # not-yet-built import flushes it before erroring. We re-derive the graph
    # from those sidecars — adding any module the scanner missed, plus the edge
    # from its importer — and rerun; nifmake's mtime pruning keeps completed
    # work. A round that discovers nothing new but still fails is a real error.
    let forwardedArgs = computeForwardedArgs(c)
    let nifmake = findNifmake()
    # Build the per-module rules concurrently: nifmake fans out all commands at
    # each DAG depth via execProcesses (defaults to all cores). Cold builds are
    # otherwise serial (one child at a time) and leave the machine idle. Opt out
    # with `-d:icNoParallel` (e.g. for readable, non-interleaved child output
    # when debugging a build).
    let parallel = if isDefined(conf, "icNoParallel"): "" else: " --parallel"

    # Phase 1 — frontend (nifler + `nim m`), run to a discovery fixpoint.
    var rounds = 0
    var frontendOk = false
    while true:
      let buildFile = generateFrontendBuildFile(c, forwardedArgs)
      rawMessage(conf, hintSuccess, "generated: " & buildFile)
      if nifmake.len == 0:
        rawMessage(conf, hintSuccess, "run:" & " nifmake run" & parallel & " " & buildFile)
        # without nifmake we can only print the manual commands; emit the
        # backend's too (best effort — discovery cannot run) and stop.
        let backendFile = generateBackendBuildFile(c, forwardedArgs)
        rawMessage(conf, hintSuccess, "generated: " & backendFile)
        rawMessage(conf, hintSuccess, "run:" & " nifmake run" & parallel & " " & backendFile)
        return
      let cmd = quoteShell(nifmake) & " run" & parallel & " " & quoteShell(buildFile)
      rawMessage(conf, hintExecuting, cmd)
      let exitCode = execShellCmd(cmd)
      if exitCode == 0:
        frontendOk = true
        break

      # Re-derive from the post-sem deps of every node compiled so far. Imports
      # the static scanner missed become new nodes; the importer->import edge
      # the scanner could not see is added so the discovered module builds
      # first. (Static-import edges are already present, so `notin deps` skips
      # the redundant ones.)
      var discovered = false
      inc rounds
      if rounds <= 20:
        let n0 = c.nodes.len  # snapshot: new nodes are traversed as they're added
        for ni in 0 ..< n0:
          for p in readSemDeps(c, c.nodes[ni].files[0]):
            let pair = c.toPair(p)
            var idx = c.processedModules.getOrDefault(pair.modname, -1)
            if idx == -1:
              let newNode = Node(files: @[pair], id: c.nodes.len)
              if c.systemNodeId >= 0:
                newNode.deps.add c.systemNodeId
              c.processedModules[pair.modname] = newNode.id
              c.nodes.add newNode
              idx = newNode.id
              traverseDeps(c, pair, newNode)
              discovered = true
            if idx != ni and idx notin c.nodes[ni].deps:
              c.nodes[ni].deps.add idx
              discovered = true
      if not discovered:
        rawMessage(conf, errGenerated, "nifmake failed with exit code: " & $exitCode)
        break

    # Phase 2 — backend (whole-program `nim nifc`), run once over the now-final
    # graph. Kept a separate nifmake run so backend rebuilds are decided purely
    # by nifmake's input mtimes, independent of frontend discovery.
    if frontendOk:
      let backendFile = generateBackendBuildFile(c, forwardedArgs)
      rawMessage(conf, hintSuccess, "generated: " & backendFile)
      let cmd = quoteShell(nifmake) & " run" & parallel & " " & quoteShell(backendFile)
      rawMessage(conf, hintExecuting, cmd)
      let exitCode = execShellCmd(cmd)
      if exitCode != 0:
        rawMessage(conf, errGenerated, "nifmake (backend) failed with exit code: " & $exitCode)
  else:
    rawMessage(conf, errGenerated, "nim ic not available in bootstrap build")
