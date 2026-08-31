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
from std/sha1 import secureHash, `$`
import options, msgs, lineinfos, pathutils, condsyms,
  modulepaths, extccomp, cnif, platform

import nifstreams
import "../dist/nimony/src/lib" / [bitabs, nifreader, nifbuilder]
import icmodnames
import icnifcore
from ic/replayer import BackendActionsExt

type
  FilePair = object
    nimFile: string
    modname: string

  Node = ref object
    files: seq[FilePair]  # main file + includes
    deps: seq[int]        # indices into DepContext.nodes
    specDeps: seq[int]    # the subset of `deps` reached ONLY through a `when`
                          # condition the scanner could not evaluate
    missingImport: string # an `import` path this module's source names, under a
                          # `when` the scanner could not decide, that does not
                          # exist on disk (empty when all resolved)
    missingHardImport: string ## ditto but NOT under any undecidable `when`: the
                              ## real compile would reach this `import`, so it is
                              ## a genuine "cannot open file" error
    id: int

  DepContext = object
    config: ConfigRef
    nifler: string
    nodes: seq[Node]
    processedModules: Table[string, int]  # modname -> node index
    includeStack: seq[string]
    systemNodeId: int  # ID of the system.nim node
    implicitNodeIds: seq[int] # node IDs of `--import`ed modules (conf.implicitImports);
                              # every ordinary module implicitly imports these, so each
                              # gets a dependency edge on them, exactly like system.nim
    scanningMain: bool # currently scanning the project main module's deps;
                       # makes `when isMainModule` conditions evaluate true
                       # only there (every other module is imported)
    speculating: int   # nesting depth of `when` guards the scanner could not
                       # decide; every import edge added while this is > 0 is
                       # recorded as speculative (see pruneDeadSpeculative)

proc toPair(c: DepContext; f: string): FilePair =
  FilePair(nimFile: f, modname: moduleSuffix(f, cast[seq[string]](c.config.searchPaths)))

proc depsFile(c: DepContext; f: FilePair): string =
  getNimcacheDir(c.config).string / f.modname & ".deps.nif"

proc parsedFile(c: DepContext; f: FilePair): string =
  getNimcacheDir(c.config).string / f.modname & ".p.nif"

proc parsedDepsFile(c: DepContext; f: FilePair): string =
  ## The deps sidecar `nifler parse --deps <src> <out>.p.nif` actually writes: it
  ## appends `.deps.nif` to the OUTPUT path, giving `<mod>.p.deps.nif`. Not to be
  ## confused with `depsFile` (`<mod>.deps.nif`), which the driver's own
  ## `nifler deps` pre-scan writes.
  parsedFile(c, f).changeFileExt("") & ".deps.nif"

proc semmedFile(c: DepContext; f: FilePair): string =
  getNimcacheDir(c.config).string / f.modname & ".s.bif"

proc ifaceFile(c: DepContext; f: FilePair): string =
  ## Interface-cookie sidecar written by `nim m` (ast2nif.writeIfaceCookie,
  ## OnlyIfChanged). Dependents' nim_m rules use it as their input instead of
  ## the semmed NIF: a body-only change in a dependency then keeps the sidecar
  ## mtime and nifmake prunes the whole re-sem cascade behind it.
  getNimcacheDir(c.config).string / f.modname & ".iface.bif"

proc implFile(c: DepContext; suffix: string): string =
  ## Implementation-cookie sidecar (ast2nif.writeImplCookie): flips on ANY
  ## content change of the module (private bodies included; supersedes the
  ## iface cookie). Used as the edge for dependents that consumed the
  ## module's bodies at compile time (NeedsImpl edges).
  getNimcacheDir(c.config).string / suffix & ".impl.bif"

proc edgesFile(c: DepContext; f: FilePair): string =
  getNimcacheDir(c.config).string / f.modname & ".edges.bif"

proc readNeedsImpl(c: DepContext; f: FilePair): seq[string] =
  ## Reads the module's recorded NeedsImpl edge set (module suffixes whose
  ## bodies its last sem consumed at compile time). Missing file (never
  ## compiled yet) -> empty: the rule fires anyway on the first build and the
  ## recording exists from then on. Recordings are self-correcting with a
  ## one-run lag: whatever changes a module's consumption set is itself a
  ## gated input of its rule, so the rule re-fires and re-records.
  result = @[]
  if fileExists(c.edgesFile(f)):
    result = collectBifStrLits(c.edgesFile(f))

proc semDepsFile(c: DepContext; f: FilePair): string =
  getNimcacheDir(c.config).string / f.modname & ".s.deps.bif"

proc readSemDeps(c: DepContext; f: FilePair): seq[string] =
  ## The module's REAL direct imports (full source paths) as sem resolved them,
  ## including macro-generated imports the static scanner missed
  ## (ast2nif.writeSemDeps). Missing file (not yet semmed) -> empty.
  result = @[]
  if fileExists(c.semDepsFile(f)):
    result = collectBifStrLits(c.semDepsFile(f))

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

proc processInclude(c: var DepContext; includePath: string; current: Node; origin: string) =
  # `origin` = the file the `include` literally appears in (an included file's
  # own nested includes/imports must resolve relative to IT, not the importing
  # module's main file).
  let resolved = resolveInclude(c, origin, includePath)
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

proc getsImplicitImports(c: DepContext; nimFile: string): bool =
  ## Mirror the compiler's `belongsToStdlib` guard (pipelines.nim): `--import:X`
  ## (conf.implicitImports) is applied only to NON-stdlib modules. The scanner
  ## must agree, otherwise it edges a stdlib module → X that the compiler never
  ## actually creates, fabricating a cycle that folds X — and the modules X
  ## claims to produce — into the system SCC (whose `nim m` is driven from
  ## system.nim and never reaches them). Stdlib == under conf.libpath.
  not isRelativeTo(nimFile, c.config.libpath.string)

proc addDepEdge(c: DepContext; current: Node; depId: int) =
  ## Record `current -> depId`. While the scanner is inside a `when` guard it
  ## could not evaluate (`c.speculating > 0`) the edge is *speculative*: it may
  ## not exist in the real compile at all. An edge seen at least once outside
  ## such a guard is hard and stays hard.
  if depId notin current.deps: current.deps.add depId
  if c.speculating > 0:
    if depId notin current.specDeps: current.specDeps.add depId
  else:
    let i = current.specDeps.find(depId)
    if i >= 0: current.specDeps.delete i

proc processImport(c: var DepContext; importPath: string; current: Node; origin: string) =
  # `origin` = the file the `import` literally appears in. Crucial for imports
  # inside `include`d files: e.g. `system.nim` includes `system/excpt.nim`, which
  # does `import stacktraces` — that must resolve relative to `excpt.nim`
  # (lib/system/) → `lib/system/stacktraces.nim`, NOT relative to `system.nim`
  # (lib/) which has no `stacktraces.nim`. Resolving against the main file silently
  # dropped the `system → stacktraces` edge, so stacktraces was a separate SCC in
  # the static round and got re-grouped (and recompiled with divergent type ids)
  # only after the post-sem `.s.deps` revealed the edge.
  let resolved = resolveImport(c, origin, importPath)
  if resolved.len == 0 or not fileExists(resolved):
    # The module does not exist on disk. Silently ignoring this is right for the
    # scanner (the `import` may sit in a dead `when` branch and the real compile
    # never looks at it), but remember it: `pruneDeadSpeculative` uses it to tell
    # a module that is merely unused apart from one that cannot compile at all.
    if c.speculating > 0:
      if current.missingImport.len == 0: current.missingImport = importPath
    elif current.missingHardImport.len == 0:
      current.missingHardImport = importPath
    return

  let pair = c.toPair(resolved)
  let existingIdx = c.processedModules.getOrDefault(pair.modname, -1)

  if existingIdx == -1:
    # New module - create node and process it
    let newNode = Node(files: @[pair], id: c.nodes.len)
    addDepEdge(c, current, newNode.id)
    # Every module depends on system.nim
    if c.systemNodeId >= 0:
      newNode.deps.add c.systemNodeId
    # ... and on every `--import`ed module (conf.implicitImports), but only for
    # the non-stdlib modules the compiler actually applies implicit imports to
    # (see getsImplicitImports). A `--import`ed module is imported by its own
    # non-stdlib closure (which also gets these edges), so that cycle folds into
    # one small strongly-connected component (see computeSCCs) instead of being
    # smeared across system + stdlib.
    if getsImplicitImports(c, pair.nimFile):
      for impId in c.implicitNodeIds:
        if impId != newNode.id: newNode.deps.add impId
    c.processedModules[pair.modname] = newNode.id
    c.nodes.add newNode
    traverseDeps(c, pair, newNode)
  else:
    # Already processed - just add dependency
    addDepEdge(c, current, existingIdx)

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

type
  CondVal = enum
    ## Tri-state truth of a `when` condition as the static scanner sees it.
    ## `cvUnknown` is the crucial state: the scanner can't determine the value
    ## (an arbitrary call like `compiles`/`tryImport`, an unknown const ident,
    ## an unresolvable comparison). A dependency scanner must NEVER drop a real
    ## import, so callers treat `cvUnknown` as "keep the dependency". The bug
    ## this replaces: everything-unknown collapsed to `true`, and `not true`
    ## is `false`, so an `else:` branch (emitted as `when (not COND)`) silently
    ## dropped its imports (e.g. `when tryImport x: ... else: import x`, or
    ## system's `else: include excpt` hiding `import stacktraces`).
    cvFalse, cvTrue, cvUnknown

proc toCondVal(b: bool): CondVal = (if b: cvTrue else: cvFalse)

proc condNot(a: CondVal): CondVal =
  case a
  of cvFalse: cvTrue
  of cvTrue: cvFalse
  of cvUnknown: cvUnknown

proc condAnd(a, b: CondVal): CondVal =
  if a == cvFalse or b == cvFalse: cvFalse
  elif a == cvTrue and b == cvTrue: cvTrue
  else: cvUnknown

proc condOr(a, b: CondVal): CondVal =
  if a == cvTrue or b == cvTrue: cvTrue
  elif a == cvFalse and b == cvFalse: cvFalse
  else: cvUnknown

proc evalCondIdent(c: DepContext; v: string): CondVal =
  ## Truth value of a bare identifier appearing in a `when` condition. Unknown
  ## idents are `cvUnknown` (kept), not `true` — so `when not SOMEIDENT:` no
  ## longer drops its import.
  case v
  of "true": cvTrue
  of "false": cvFalse
  of "hasThreadSupport":
    # system.nim's `hasThreadSupport` is `compileOption("threads") and
    # not defined(nimscript)`; the conservative `true` would schedule the
    # threads-only modules (syslocks, threadtypes, sharedlist, locks)
    # whose NIFs a --threads:off compile never produces — nifmake then
    # sees missing outputs and re-runs the system rule (and everything
    # downstream) on every rerun.
    toCondVal(optThreads in c.config.globalOptions)
  of "usesDestructors":
    # system.nim's `usesDestructors = defined(gcDestructors) or
    # defined(gcHooks)`; guards mmdisp.nim's `include "system/gc"` whose
    # transitive imports (sharedlist, locks) an orc compile never produces.
    toCondVal(isDefined(c.config, "gcDestructors") or isDefined(c.config, "gcHooks"))
  of "isMainModule":
    # Only the project main module is compiled with `isMainModule` true; an
    # imported module's `when isMainModule` blocks are dead. The conservative
    # `true` would schedule main-only imports (e.g. parser.nim's
    # `tools/grammar_nanny`, a node that gets a cg rule but is never linked,
    # so the merge stage can pick it as a shared def's owner -> undefined
    # symbols at link).
    toCondVal(c.scanningMain)
  else: cvUnknown

proc constIdentValue(c: DepContext; ident: string): string =
  ## String value of a compile-time platform constant that appears in `when`
  ## guards, or "" when unknown. Mirrors the compiler's magics so the scanner
  ## evaluates e.g. `when hostOS == "standalone"` the SAME way the real compile
  ## does. Without this the comparison is "unknown" → the conservative `true`,
  ## which is WRONG once negated (`else:` branches emit `not (==)`), so a real
  ## conditional `include`/`import` is dropped (e.g. system's `else: include
  ## excpt`, hiding `import stacktraces`).
  # Must match the compiler's magics EXACTLY, incl. case: `hostOS`/`hostCPU` etc.
  # fold to the lower-cased platform name (see semfold.nim mHostOS/mHostCPU), and
  # user code compares against lower-case literals (`when hostOS == "linux"`).
  case ident
  of "hostOS": result = toLowerAscii(platform.OS[c.config.target.targetOS].name)
  of "hostCPU": result = toLowerAscii(platform.CPU[c.config.target.targetCPU].name)
  of "buildOS": result = toLowerAscii(platform.OS[c.config.target.hostOS].name)
  of "buildCPU": result = toLowerAscii(platform.CPU[c.config.target.hostCPU].name)
  else: result = ""

proc readOperandValue(c: DepContext; s: var Stream): string =
  ## Read one operand of an `==`/`!=` infix and return its string value (a string
  ## literal verbatim, a platform-constant ident resolved, anything else ""), fully
  ## consuming the operand (subtrees are skipped) so the caller stays in sync.
  let t = next(s)
  case t.kind
  of StringLit: result = pool.strings[t.litId]
  of Ident: result = constIdentValue(c, pool.strings[t.litId])
  of ParLe:
    result = ""
    skipSubtree(s, t)
  else: result = ""

proc evalCondCmp(c: DepContext; s: var Stream; isEq: bool): CondVal =
  ## Evaluate `a == b` / `a != b`. Both operands known → real result; otherwise
  ## `cvUnknown` (so a negated comparison keeps, not drops, the dependency).
  let v1 = readOperandValue(c, s)
  let v2 = readOperandValue(c, s)
  if v1.len > 0 and v2.len > 0:
    result = toCondVal((v1 == v2) == isEq)
  else:
    result = cvUnknown

proc evalCondExpr(c: DepContext; s: var Stream; t: PackedToken): CondVal

proc readCond(c: DepContext; s: var Stream): CondVal =
  ## Read one full condition subtree (its own opener included) and evaluate it.
  let t = next(s)
  evalCondExpr(c, s, t)

proc evalCondExpr(c: DepContext; s: var Stream; t: PackedToken): CondVal =
  ## Evaluate the condition whose opening token `t` has ALREADY been read,
  ## consuming the rest of the expression so the caller stays in sync.
  ## Recognises `defined(IDENT)`, `not`/`and`/`or`, `==`/`!=` and the literals
  ## `true`/`false`; everything else (an arbitrary call such as `compiles` /
  ## `tryImport`, an unknown const) is `cvUnknown`. Both negation-sensitive
  ## (`not cvUnknown == cvUnknown`) and short-circuit-free: `and`/`or` always
  ## read both operands so the stream stays in sync regardless of the result.
  case t.kind
  of Ident:
    result = evalCondIdent(c, pool.strings[t.litId])
  of ParLe:
    let tag = pool.tags[t.tagId]
    # For prefix/infix/call nodes the operator name is the first child; for a
    # bare `(not ...)`/`(and ...)`/`(or ...)`/`(par ...)` node the tag itself is
    # the operator and the operands follow directly.
    var name = tag
    case tag
    of "call", "cmd", "callstrlit", "infix", "prefix":
      let head = next(s)
      if head.kind == Ident: name = pool.strings[head.litId]
      else: name = ""
    else: discard
    case name
    of "defined":
      let arg = next(s)
      var sym = ""
      if arg.kind == Ident: sym = pool.strings[arg.litId]
      result = toCondVal(sym.len > 0 and isDefined(c.config, sym))
    of "not":
      result = condNot(readCond(c, s))
    of "and":
      let a = readCond(c, s)
      let b = readCond(c, s)
      result = condAnd(a, b)
    of "or":
      let a = readCond(c, s)
      let b = readCond(c, s)
      result = condOr(a, b)
    of "==", "!=":
      result = evalCondCmp(c, s, name == "==")
    of "par":
      # a parenthesised grouping such as `(defined(a) or defined(b))`.
      result = readCond(c, s)
    else:
      result = cvUnknown
    # Drain whatever remains until the matching ParRi.
    var depth = 1
    while depth > 0:
      let n = next(s)
      if n.kind == ParLe: inc depth
      elif n.kind == ParRi: dec depth
      elif n.kind == EofToken: return
  else:
    result = cvUnknown

proc whenMarkerHolds(c: DepContext; s: var Stream): CondVal =
  ## Caller has just consumed the `(when` ParLe. Read children until the
  ## matching `)`, AND-ing each evaluated condition. Returns the tri-state
  ## result; callers keep the dependency unless it is provably `cvFalse`.
  result = cvTrue
  while true:
    let t = next(s)
    if t.kind == ParRi: return
    if t.kind == EofToken: return
    result = condAnd(result, evalCondExpr(c, s, t))

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

  # `current.id == 0` is the project main (rootNode); restored on exit so the
  # flag is correct for each parent frame between its child recursions.
  let prevScanningMain = c.scanningMain
  c.scanningMain = current.id == 0
  defer: c.scanningMain = prevScanningMain

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
        var speculative = false
        if t.kind == ParLe and pool.tags[t.tagId] == "when":
          # whenMarkerHolds consumes everything up to and including the
          # closing `)` of the `(when ...)` subtree. Drop the import only when
          # the condition is PROVABLY false; a `cvUnknown` condition (e.g. an
          # `else:` branch guarded by `not <unevaluatable call>`, as in
          # `when tryImport x: ... else: import x`) keeps the dependency so the
          # static graph never misses a real import — but marks every edge it
          # creates speculative, so `pruneDeadSpeculative` can still drop a
          # subtree that provably cannot compile in this configuration.
          let cond = whenMarkerHolds(c, s)
          live = cond != cvFalse
          speculative = cond == cvUnknown
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
        if speculative: inc c.speculating
        if tag == "fromimport" or tag == "importexcept":
          # `from m import syms` / `import m except syms`: the first child is the
          # module path; the rest is the (in/ex)cluded symbol list, which must not
          # be treated as modules. Both still create a real dependency on `m`.
          for importPath in parseImportPath(s, t):
            if importPath.len > 0:
              processImport(c, importPath, current, pair.nimFile)
        else:
          while t.kind != ParRi and t.kind != EofToken:
            for importPath in parseImportPath(s, t):
              if importPath.len > 0:
                if tag == "include":
                  processInclude(c, importPath, current, pair.nimFile)
                else:
                  processImport(c, importPath, current, pair.nimFile)
        if speculative: dec c.speculating
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

proc collectIncludeNames(depsPath: string; names: var seq[string]) =
  ## Lightweight scan of a `.deps.nif` prelude: collect the raw path text of
  ## every entry inside an `(include ...)` node (idents like `semexprs`, string
  ## literals like `"system/mmdisp"`, and the leaves of `a/b` path infixes).
  ## Liberal by design — it also picks up entries under a statically-false
  ## `(when ...)`; that is harmless for the only caller (`includerSbifs`), whose
  ## over-collection just costs an extra, result-free bif scan downstream.
  if not fileExists(depsPath): return
  var s = nifstreams.open(depsPath)
  defer: nifstreams.close(s)
  discard processDirectives(s.r)
  var depth = 0
  var includeDepth = 0     # the `depth` at which the current `(include` opened; 0 = not inside one
  var t = next(s)
  while t.kind != EofToken:
    case t.kind
    of ParLe:
      inc depth
      if includeDepth == 0 and pool.tags[t.tagId] == "include":
        includeDepth = depth
    of ParRi:
      if includeDepth != 0 and depth == includeDepth:
        includeDepth = 0
      dec depth
    of Ident, StringLit:
      if includeDepth != 0:
        names.add pool.strings[t.litId]
    else: discard
    t = next(s)

proc entryStemBase(roots: seq[string]; name: string): (string, string) =
  ## Resolve include entry `name` to (deps-stem, base-name); ("","") if unfound.
  for r in roots:
    let p = r / name.addFileExt("nim")
    if fileExists(p):
      return (moduleSuffix(p, []), splitFile(p).name)
  result = ("", "")

proc includerSbifs*(conf: ConfigRef; targetFile: AbsoluteFile): seq[string] =
  ## For an include file `targetFile`, return the `.s.bif` paths of every module
  ## that includes it — directly OR transitively (following the include chain
  ## `module -> incA -> incB -> targetFile`). `nim track` uses this to avoid
  ## loading and scanning every module bif: an include file has no bif of its
  ## own, so its type-checked tokens live in the *including* module's bif. Only
  ## the small `.deps.nif` preludes are read here, never a `.s.bif`.
  const depsExt = ".deps.nif"
  let nc = getNimcacheDir(conf).string

  # Candidate roots for resolving an `(include X)` entry to a real file, so its
  # module suffix (== its own deps-file stem) can be computed. Include entries
  # carry any sub-path (`system/mmdisp`), so the file's *directory* roots suffice:
  # the target's own dir, the project dir, and the search paths cover the
  # compiler, the stdlib and typical single-tree projects.
  var roots: seq[string] = @[parentDir(targetFile.string)]
  if conf.projectPath.string.len > 0: roots.add conf.projectPath.string
  for sp in conf.searchPaths: roots.add sp.string

  # One pass over every prelude builds the reverse include graph, keyed by base
  # file name: `includedBy[b]` = deps stems whose owner directly `include`s a
  # file named `b`. `stemBase` maps an include-only file's deps stem back to its
  # own base name, so the walk can climb through nested includes.
  var includedBy = initTable[string, seq[string]]()
  var stemBase = initTable[string, string]()
  for depsPath in walkFiles(nc / "*" & depsExt):
    let base = extractFilename(depsPath)
    if base.endsWith(".p" & depsExt): continue   # `.p.deps.nif` twin
    let ownerStem = base[0 ..< base.len - depsExt.len]
    var names: seq[string] = @[]
    collectIncludeNames(depsPath, names)
    for n in names:
      let (childStem, childBase) = entryStemBase(roots, n)
      if childBase.len == 0: continue
      includedBy.mgetOrPut(childBase, @[]).add ownerStem
      stemBase[childStem] = childBase          # this child's stem -> its base name

  # Walk UP from the target: a deps stem that includes the current base name is
  # either a module (has a `.s.bif` -> collect it) or itself an include file
  # (recurse via its own base name).
  result = @[]
  var seenBase = initHashSet[string]()
  var work = @[splitFile(targetFile.string).name]
  while work.len > 0:
    let b = work.pop()
    if seenBase.containsOrIncl(b): continue
    for stem in includedBy.getOrDefault(b):
      let sbif = nc / stem & ".s.bif"
      if fileExists(sbif):
        if sbif notin result: result.add sbif   # module owner
      else:
        let ob = stemBase.getOrDefault(stem)     # include-only owner: climb higher
        if ob.len > 0: work.add ob

proc traverseDeps(c: var DepContext; pair: FilePair; current: Node) =
  ## Process a module: run nifler and read deps
  if not runNifler(c, pair.nimFile):
    rawMessage(c.config, errGenerated, "nifler failed for: " & pair.nimFile)
    return
  readDepsFile(c, pair, current)

proc pruneDeadSpeculative(c: var DepContext) =
  ## Drop modules that are reachable only through a `when` guard the scanner
  ## cannot evaluate AND that cannot possibly compile because they import a
  ## module which does not exist on disk.
  ##
  ## The motivating shape is the ordinary `{.strdefine.}` backend switch:
  ##
  ##   const figdrawTextBackend* {.strdefine.} = "pixie"
  ##   when figdrawTextBackend == "harfbuzzy":
  ##     import ./textrasters/glyphid_raster   # imports `pkg/harfbuzzy`
  ##
  ## The value of that const needs sem, so `evalCondCmp` answers `cvUnknown` and
  ## the conservative rule keeps the import — the right call for an edge, but it
  ## also gives `glyphid_raster` its own `nim m` rule. The classic compiler never
  ## looks at that file; IC compiles it, cannot find `pkg/harfbuzzy`, and the
  ## whole build dies on a package the user never installed because they never
  ## selected that backend.
  ##
  ## Dropping is safe: if the guard *was* live, the importer's own `nim m` fails
  ## on the missing NIF, records the import in its `.s.deps` sidecar, and the
  ## discovery fixpoint re-adds the node — this time reporting the honest
  ## `cannot open file: pkg/harfbuzzy/raw` instead of a cascade of
  ## `undeclared identifier` noise.
  let n = c.nodes.len
  if n == 0: return

  var roots = @[0]
  if c.systemNodeId >= 0: roots.add c.systemNodeId
  for i in c.implicitNodeIds: roots.add i

  # Reachability through NON-speculative edges only: these modules are compiled
  # for certain, so a missing import in them is a genuine user error to report.
  var hard = newSeq[bool](n)
  var stack = roots
  while stack.len > 0:
    let v = stack.pop()
    if hard[v]: continue
    hard[v] = true
    for d in c.nodes[v].deps:
      if d notin c.nodes[v].specDeps and not hard[d]: stack.add d

  # A module the real compile DOES reach, naming an import that is not on disk,
  # is a plain user error — and one nifmake cannot notice on its own: deleting
  # `effects.nim` moves no mtime, so the importer's `nim m` never re-fires and
  # `nim ic` happily relinked a stale binary while `nim c` said "cannot open
  # file". Report it here, where the graph scan is the only thing that looks at
  # import paths at all.
  var reported = false
  for i in 0 ..< n:
    if hard[i] and c.nodes[i].missingHardImport.len > 0:
      rawMessage(c.config, errGenerated,
        c.nodes[i].files[0].nimFile & ": cannot open file: " &
        c.nodes[i].missingHardImport)
      reported = true
  if reported: return

  var dead = newSeq[bool](n)
  var anyDead = false
  for i in 0 ..< n:
    if not hard[i] and c.nodes[i].missingImport.len > 0:
      dead[i] = true
      anyDead = true
  if not anyDead: return

  # Anything left reachable only through a dead node is dead too.
  var alive = newSeq[bool](n)
  stack = @[]
  for r in roots:
    if not dead[r]: stack.add r
  while stack.len > 0:
    let v = stack.pop()
    if alive[v]: continue
    alive[v] = true
    for d in c.nodes[v].deps:
      if not dead[d] and not alive[d]: stack.add d

  # Drop the scan artifacts of a module that just left the graph, so an
  # edit-accumulated cache does not differ from a clean one for no reason
  # (`tests/ic/tdead_when_import` pins that). Re-running nifler if it ever comes
  # back costs a single parse.
  #
  # But a FILE can belong to several nodes, and only the NODE is dead.
  # `lib/system/inclrtl.nim` is `include`d by dozens of live stdlib modules and
  # also sits in the file set of a dead-speculative one; a clean build therefore
  # has its `.p.nif`, and deleting it here does not tidy the cache, it corrupts
  # it. The consequences compound: the missing output re-fires that file's
  # `nifler` rule, which rewrites the parsed file with a fresh mtime, which
  # re-fires every `nim_m` rule listing it as an input — 16 full module re-sems
  # (system, os, times, strutils, macros, unicode, ...) on every warm build, for
  # ever, because the scanner is stateless and rediscovers the dead node each
  # run. Measured on a 219-module program: an 11 s NO-OP build. So delete only
  # what no live node claims.
  var liveFiles = initHashSet[string]()
  for i in 0 ..< n:
    if alive[i]:
      for f in c.nodes[i].files: liveFiles.incl f.nimFile

  var cascaded = 0
  for i in 0 ..< n:
    if not alive[i]:
      for f in c.nodes[i].files:
        if f.nimFile in liveFiles: continue
        removeFile(c.parsedFile(f))
        removeFile(c.depsFile(f))
        removeFile(c.parsedDepsFile(f))
      if c.nodes[i].missingImport.len > 0:
        rawMessage(c.config, hintSuccess,
          "ic: skipping " & c.nodes[i].files[0].nimFile &
          " (reached only under an undecidable `when`, and imports " &
          c.nodes[i].missingImport & ", which is not installed)")
      else:
        inc cascaded
  if cascaded > 0:
    rawMessage(c.config, hintSuccess,
      "ic: " & $cascaded & " further module(s) skipped, reachable only through those")

  # Compact `c.nodes`; node ids ARE indices everywhere, so remap them all.
  var remap = newSeq[int](n)
  var newNodes: seq[Node] = @[]
  for i in 0 ..< n:
    if alive[i]:
      remap[i] = newNodes.len
      newNodes.add c.nodes[i]
    else:
      remap[i] = -1
  proc remapped(remap: seq[int]; src: seq[int]): seq[int] =
    result = @[]
    for x in src:
      if remap[x] >= 0 and remap[x] notin result: result.add remap[x]
  for node in newNodes:
    node.id = remap[node.id]
    node.deps = remapped(remap, node.deps)
    node.specDeps = remapped(remap, node.specDeps)
  c.nodes = newNodes

  var pm = initTable[string, int]()
  for name, idx in c.processedModules:
    if idx >= 0 and idx < n and remap[idx] >= 0: pm[name] = remap[idx]
  c.processedModules = pm
  if c.systemNodeId >= 0: c.systemNodeId = remap[c.systemNodeId]
  c.implicitNodeIds = remapped(remap, c.implicitNodeIds)

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
  # The children are invoked as `nim m` / `nim nifc`, so the driver's own command
  # token (`c`, `cpp`, `ic`) is gone and with it the backend it selected. Name it
  # explicitly — `nim cpp --ic:on` must not have its stdlib sem'd and its TUs
  # emitted as C. The exception model rides along for the same reason: `nim cpp`
  # defaults to `--exceptions:cpp`, which changes both codegen and sem.
  if c.config.backend != backendInvalid:
    result.add "--backend:" & $c.config.backend
  if c.config.exc != excNone:
    result.add "--exceptions:" & (case c.config.exc
                                  of excGoto: "goto"
                                  of excCpp: "cpp"
                                  of excQuirky: "quirky"
                                  else: "setjmp")
  # method dispatch semantics must match across the child processes:
  # a child compiled without --multimethods:on builds different dispatch
  # buckets (and rejects calls as ambiguous that multi-dispatch accepts)
  if optMultiMethods in c.config.globalOptions:
    result.add "--multimethods:on"
  # Forward the debug-info switch: the cg children — not the driver — fill the
  # backend C names, and `--debugger:native` selects the Itanium mangling
  # scheme (ccgtypes.fillBackendName). A child without it would name routines
  # with the plain `_u<disamb>` scheme while a sibling that read the project's
  # config.nims (`--debugger:native`) used Itanium, so the same symbol's
  # definition and cross-module references would disagree at link.
  if optCDebug in c.config.globalOptions:
    result.add "--debugger:native"
  # the children compile each MODULE as their own project file, which makes
  # that module's package the "main package" and unfilters foreign-package
  # diagnostics — a vendored package's hintAsError/warningAsError promotions
  # then abort builds the whole-program compilation accepts. Forward the
  # real project so children filter diagnostics identically.
  result.add "--icproject:" & c.config.projectFull.string
  # Precompiled config: every child replays the one artifact produced (in a
  # separate `nim icconfig` process) and already replayed by the driver itself —
  # see `icconfig.ensureIcConfig`, run before the driver's own `loadConfigs`. So
  # `nim ic` is always governed by this single artifact, for speed and so the
  # driver and its children agree by construction. Forward the path the driver
  # replayed (`conf.icPreparsedConfig`); `commandIc` has already guaranteed it
  # exists, else it bailed.
  result.add "--icPreparsedConfig:" & c.config.icPreparsedConfig
  # Everything else the user typed on the `nim ic` command line. The children
  # replay the project's CONFIG FILES (ic_config.cfg.nif), never the driver's
  # argv, so a switch that exists only there — `--opt:speed`, `--panics:on`,
  # `--experimental:…`, `--passC:…` — silently did not reach them: `nim ic
  # --opt:speed` produced a byte-identical debug binary. Forward the switches
  # verbatim, minus the ones that MUST differ per child (the output/cache paths,
  # the command itself, and IC's own per-rule switches, which each rule sets).
  const notForwarded = [
    "nimcache", "out", "o", "outdir", "usenimcache", "run", "r",
    "incremental", "ic", "symbolfiles", "genbif",
    "icproject", "icpreparsedconfig", "icconfigout", "icgroup",
    "icbackendstage", "icbackendmodule", "ismainmodule",
    "help", "h", "fullhelp", "version", "v", "advanced"]
  for a in commandLineParams():
    if a.len < 2 or a[0] != '-': continue
    var i = 1
    if i < a.len and a[i] == '-': inc i
    var name = ""
    while i < a.len and a[i] notin {':', '='}:
      name.add a[i]
      inc i
    if normalize(name) notin notForwarded and a notin result:
      result.add a

proc configSignatureFile(c: DepContext; forwardedArgs: seq[string]): string =
  ## nifmake decides staleness from file mtimes alone — it never looks at a
  ## rule's command line. So changing `-d:someDefine`, `--mm:` or `--threads:`
  ## between two `nim ic` runs re-generated the build file with the new switches
  ## but re-fired nothing: the user got a silently stale binary built with the
  ## OLD configuration. Reify the configuration as a FILE and make every rule
  ## that consumes it an input, so a config change moves an mtime like any edit.
  ## Written `OnlyIfChanged` so a genuine no-op run stays a no-op.
  ##
  ## Deliberately EXCLUDES the two per-build path switches (`--icproject:`,
  ## `--icPreparsedConfig:`): they name where this build lives, not what it
  ## produces, so including them made the signature differ between two caches
  ## holding byte-identical artifacts — which defeats prefilling a test's cache
  ## from a shared warm one (every rule would re-fire on the rewritten
  ## signature). The precompiled config still counts, by CONTENT: a `nim.cfg`
  ## edit changes the artifact, hence the hash, hence every rule.
  result = getNimcacheDir(c.config).string / "ic_build_args.txt"
  var content = ""
  for p in c.config.searchPaths:
    content.add "--path:" & p.string & "\n"
  for a in forwardedArgs:
    if a.startsWith("--icproject:") or a.startsWith("--icPreparsedConfig:"):
      continue
    content.add a & "\n"
  if c.config.icPreparsedConfig.len > 0 and fileExists(c.config.icPreparsedConfig):
    # Hash the precompiled config MINUS its `(nimcache "...")` entry — the one
    # line in the artifact that records where this build's cache lives rather
    # than what the config says. Everything else is genuinely config-derived, so
    # two builds with the same `nim.cfg`/`config.nims` hash the same no matter
    # which directory they run in.
    var normalized = ""
    try:
      for line in lines(c.config.icPreparsedConfig):
        if "(nimcache " in line: continue
        normalized.add line
        normalized.add '\n'
    except IOError, OSError:
      normalized = c.config.icPreparsedConfig
    content.add "config:" & $secureHash(normalized) & "\n"
  if not fileExists(result) or readFile(result) != content:
    writeFile(result, content)

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
        # The deps sidecar this command really produces is `<mod>.p.deps.nif`,
        # not `<mod>.deps.nif` (which only the driver's `nifler deps` pre-scan
        # writes). Declaring the latter made the rule permanently stale — a
        # missing output is nifmake's strongest rebuild trigger — for every
        # module the pre-scan does not also cover.
        b.addTree "output"
        b.addStrLit c.parsedDepsFile(pair)
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
  let argsFile = configSignatureFile(c, forwardedArgs)
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
    # The configuration this child is invoked with (see configSignatureFile).
    b.addTree "input"
    b.addStrLit argsFile
    b.endTree()
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

proc backendCFile(c: DepContext; node: Node): string =
  ## The `.c` path the backend writes for `node`, computed exactly as
  ## `cgen.getCFile` does: `mangleModuleName` of the module's cfilename, which
  ## is the source path for the main module (registered at its source index) and
  ## the NIF suffix for every dependency (a `fikNifModule` whose `toFullPath` is
  ## the suffix). Lets nifmake declare a per-module output without loading any
  ## backend module.
  let cfilename =
    if node.id == 0: AbsoluteFile node.files[0].nimFile
    else: AbsoluteFile node.files[0].modname
  result = changeFileExt(completeCfilePath(c.config,
    mangleModuleName(c.config, cfilename).AbsoluteFile), icCFileExt(c.config)).string

proc computeLiveBackendNodes(c: DepContext): seq[bool] =
  ## Which nodes the backend must code-generate: the closure reachable from the
  ## program roots (main + `system` + `--import`ed modules) via the REAL,
  ## post-sem import edges (`.s.deps`).
  ##
  ## The static `.deps` scan over-approximates: it cannot evaluate guards like
  ## `when defined(windows)` or const-aliased ones (`when useWinVersion`, with
  ## `const useWinVersion = defined(windows) or defined(nimdoc)`), so it keeps
  ## the dead branch's import. e.g. on Linux `nativesockets`'s static deps list
  ## `winlean`; the discovery fixpoint only ever *adds* edges, never prunes, so
  ## `winlean` stays a node and got a full `lower`/`cg`/`emit`/link pipeline.
  ## That is harmless for sem (an extra `nim m`) but fatal for codegen:
  ## `winlean`'s `importc, header: "winsock2.h"` decls emit
  ## `#include "winsock2.h"` into a C file that cannot compile off-Windows.
  ## Sem's resolved import set (`.s.deps`) is the real program graph — the
  ## non-IC compiler would never touch `winlean` here — so restrict the backend
  ## to it. (`.s.deps` is the same data the discovery loop trusts; it is written
  ## for every sem'd module, including grouped SCC members.)
  result = newSeq[bool](c.nodes.len)
  var stack: seq[int] = @[0]            # main module
  if c.systemNodeId >= 0: stack.add c.systemNodeId
  for impId in c.implicitNodeIds: stack.add impId  # every module imports these
  while stack.len > 0:
    let ni = stack.pop()
    if ni < 0 or ni >= c.nodes.len or result[ni]: continue
    result[ni] = true
    for p in readSemDeps(c, c.nodes[ni].files[0]):
      let idx = c.processedModules.getOrDefault(c.toPair(p).modname, -1)
      if idx >= 0: stack.add idx

proc intDefine(conf: ConfigRef; name: string; fallback: int): int =
  ## `-d:<name>:N` as an int, or `fallback` when unset or unparsable.
  result = fallback
  if isDefined(conf, name):
    try: result = parseInt(conf.symbols[name])
    except ValueError: result = fallback

proc backendBatchSize(conf: ConfigRef; liveCount: int): int =
  ## How many modules share one backend process. 1 is the historical per-module
  ## fan-out; larger batches amortise the process floor and the dependency
  ## closure load (measured on a 67-module program: 7.6 ms of process startup
  ## and ~10 ms of closure loading per child, against 3.5 ms of actual codegen).
  ##
  ## `-d:icBatchSize:N` pins it. The default is 1 — the plumbing is in place but
  ## the policy is not yet validated. `-d:icBatchSize:0` means "one batch per
  ## job", which is the shape a tuned default will take: enough batches to keep
  ## every core busy and no more, since a batch beyond that only buys
  ## amortisation at the price of parallelism.
  if not isDefined(conf, "icBatchSize"): return 1
  result = intDefine(conf, "icBatchSize", 1)
  if result == 0:
    let jobs =
      if isDefined(conf, "icNoParallel"): 1
      elif isDefined(conf, "icJobs"): max(1, intDefine(conf, "icJobs", 1))
      elif conf.numberOfProcessors > 0: conf.numberOfProcessors
      else: 1
    result = (liveCount + jobs - 1) div jobs
  result = max(1, result)

proc emitBatches(c: DepContext; live: seq[bool];
                 shared: seq[seq[int]]): seq[seq[int]] =
  ## emit's partition. Unlike `lower`/`cg` it takes the MAIN module too and, by
  ## default, puts every live node in one batch: emit owns no decisions, so
  ## there is nothing for a grouping to get wrong (see the rule that uses this).
  ## An explicit `-d:icBatchSize` reuses the shared partition instead, plus main,
  ## so the fan-out remains available to compare against.
  if isDefined(c.config, "icBatchSize"):
    result = shared
    if live.len > 0 and live[0]: result.add @[0]
  else:
    var all: seq[int] = @[]
    for i in 0 ..< c.nodes.len:
      if live[i]: all.add i
    result = if all.len > 0: @[all] else: @[]

proc backendBatches(c: DepContext; live: seq[bool]): seq[seq[int]] =
  ## Partition the live non-main nodes into batches of node indices. The main
  ## module is never in one: it loads the whole program, so batching it with
  ## anything defeats the memory bound the per-module split exists to give.
  ##
  ## Contiguous runs of `c.nodes`, which is import-traversal order, so a batch's
  ## members tend to share dependencies and its union closure stays close to one
  ## member's. A smarter partition (by closure overlap, or by the dirty set on an
  ## incremental build) belongs here and nowhere else — every stage already takes
  ## whatever grouping this returns.
  var liveIdx: seq[int] = @[]
  for i in 0 ..< c.nodes.len:
    if live[i] and c.nodes[i].id != 0: liveIdx.add i
  let size = backendBatchSize(c.config, liveIdx.len)
  result = @[]
  var i = 0
  while i < liveIdx.len:
    var batch: seq[int] = @[]
    var j = i
    while j < liveIdx.len and batch.len < size:
      batch.add liveIdx[j]
      inc j
    result.add batch
    i = j

proc generateBackendBuildFile(c: DepContext; forwardedArgs: seq[string]): string =
  ## Per-module backend build file. One `nim_nifc` command template (the actual
  ## stage/module switches ride in each rule's `(args …)`), then the stages of
  ## the per-module backend as separate nifmake rules:
  ##   cg(per module) -> merge -> emit(per module) -> link
  ## Every module's semmed NIF is a leaf input (produced by the frontend run).
  ## `cg` emits a module's whole demanded closure into its `.c.nif`
  ## (emit-everywhere); `merge` picks one owner per duplicated definition across
  ## all `.c.nif`; `emit` renders each module's `.c` (dropping non-owned/dead
  ## bodies); `link` compiles and links every `.c` in one `callCCompiler`. The
  ## main module's `cg` depends on every other `.c.nif` because it reads their
  ## init/datInit meta heads to wire up NimMain, so it must run last.
  let nimcache = getNimcacheDir(c.config).string
  createDir(nimcache)
  result = nimcache / c.nodes[0].files[0].modname & ".backend.build.nif"

  let mainNif = c.nodes[0].files[0].nimFile
  # Honor `--out`/`--outdir`: `cmdIc`'s `setOutFile` populated `conf.outFile`
  # (the user's `--out`, or the default `<project><exeExt>`), so `absOutFile` is
  # the final link target — exactly what a whole-program `nim c` would produce.
  # The `link` child computes its own output from its project name, so the path
  # is also forwarded to it below.
  let exeFile = string(c.config.absOutFile)
  let mergeFile = nimcache / MergeDecisionFile

  # Per-node output paths.
  var cnifFiles = newSeq[string](c.nodes.len)
  var cFiles = newSeq[string](c.nodes.len)
  var tFiles = newSeq[string](c.nodes.len)
  # The `lower` stage writes a PROPER module NIF the cg/emit stages load via
  # `toNifFilename` (a `.s.bif` sibling), so its `.t.bif` lives at the suffix base
  # (mirroring `semmedFile`), not next to the throwaway `.c`.
  for i, node in c.nodes:
    cFiles[i] = backendCFile(c, node)
    cnifFiles[i] = cFiles[i] & ".nif"
    tFiles[i] = nimcache / node.files[0].modname & ".t.bif"

  # Only code-generate modules the real program actually reaches; statically
  # over-approximated nodes (e.g. `winlean` on Linux) are sem'd but not emitted.
  let live = computeLiveBackendNodes(c)
  # Drop a pruned node's stale backend artifacts: the `merge` stage globs
  # `*.c.nif` off disk (not the build-file inputs) and the `link` stage scans
  # the loaded closure's `.c`s, so a leftover `.c.nif`/`.c` from a run before
  # this module became unreachable (a prior over-approximated build, or an edit
  # that removed its last real importer) would still be merged/compiled —
  # reintroducing exactly the off-platform `#include` this prune avoids.
  var prunedStale = false
  for i in 0 ..< c.nodes.len:
    if not live[i]:
      # `fileExists` before remove so we only force a merge recompute (below)
      # when an artifact was actually present — i.e. a build where this module
      # WAS emitted, not the steady state where it never is.
      if fileExists(cnifFiles[i]) or fileExists(cFiles[i]): prunedStale = true
      removeFile(cnifFiles[i])
      removeFile(cFiles[i])
      removeFile(cFiles[i] & ".stamp")
      removeFile(cFiles[i] & BackendActionsExt)
  # The merge decision is a pure function of the set of `.c.nif`s present; if we
  # just removed an over-approximated module's artifacts, a decision computed
  # while they were present is stale — it can name a now-absent module as a
  # symbol's owner (`asyncdispatch` owning `NTIdomain` here), leaving that symbol
  # undefined at link. nifmake will not re-fire `merge` on its own: dropping an
  # input makes no remaining input newer than the output. Delete the decision so
  # the (now missing) output forces a recompute against the live `.c.nif` set.
  if prunedStale:
    removeFile(mergeFile)

  let argsFile = configSignatureFile(c, forwardedArgs)

  var b = nifbuilder.open(result)
  defer: b.close()

  b.addHeader("nim ic", "nifmake")
  b.addTree "stmts"

  # Command template: `nifc --nimcache … --path … <forwarded> <per-rule args>
  # <project>`. The trailing `(args)` is filled per rule with the stage and
  # module switches; `(input 0)` is the project file.
  b.addTree "cmd"
  b.addSymbolDef "nim_nifc"
  b.addStrLit getAppFilename()
  b.addStrLit "nifc"
  b.addStrLit "--nimcache:" & nimcache
  for p in c.config.searchPaths:
    b.addStrLit "--path:" & p.string
  for a in forwardedArgs:
    b.addStrLit a
  b.addTree "args"
  b.endTree()
  # The project file is a fixed command ARGUMENT, not a tracked input: backend
  # stages read NIFs (resolved by suffix), never the `.nim` source, so its
  # content cannot change any artifact. Passing it as `(input 0)` made its mtime
  # an input to every rule, so editing the main module's source re-fired the
  # whole backend.
  b.addStrLit mainNif
  b.endTree()

  template inputStr(s: string) =
    b.addTree "input"
    b.addStrLit s
    b.endTree()
  template outputStr(s: string) =
    b.addTree "output"
    b.addStrLit s
    b.endTree()

  # lower: one rule per module. Transforms (eventually) the routines the module
  # OWNS once, in the owner's id space, into `<module>.t.nif`, so the `cg` stage
  # reads them instead of re-deriving (which makes a closure `:env`'s identity
  # diverge across the parallel `cg` processes). Runs per module in parallel.
  #
  # Input is this module's OWN semmed NIF and nothing else. A module does NOT
  # depend on its importers, so listing every semmed NIF (or even the import
  # closure) was wrong: it made e.g. `strutils`'s rule depend on the `finish`
  # that imports it. nifmake handles the indirect dependency for free — the
  # frontend writes `.s.nif`s content-stably, so an interface change to a
  # dependency re-sems (and re-emits the `.s.nif` of) every transitive importer;
  # a module whose own `.s.nif` is unchanged genuinely needs no re-lowering.
  let batches = backendBatches(c, live)
  template suffixList(batch: seq[int]): string =
    var acc = ""
    for k, idx in batch:
      if k > 0: acc.add ","
      acc.add c.nodes[idx].files[0].modname
    acc

  for batch in batches:
    b.addTree "do"
    b.addIdent "nim_nifc"
    b.withTree "args":
      b.addStrLit "--icBackendStage:lower"
      b.addStrLit "--icBackendModules:" & suffixList(batch)
    for idx in batch:
      inputStr c.semmedFile(c.nodes[idx].files[0])
    inputStr argsFile
    for idx in batch:
      outputStr tFiles[idx]
    b.endTree()
  # The main module is its own rule in every stage: it loads the whole program.
  block:
    let i = 0
    if live[i]:
      b.addTree "do"
      b.addIdent "nim_nifc"
      b.withTree "args":
        b.addStrLit "--icBackendStage:lower"
        b.addStrLit "--icBackendModules:" & c.nodes[i].files[0].modname
      inputStr c.semmedFile(c.nodes[i].files[0])
      inputStr argsFile
      outputStr tFiles[i]
      b.endTree()

  # cg: one rule per module. Input is this module's OWN `.t.nif`. cg DOES read
  # its dependencies' `.t.nif`s at runtime (loadDepClosure), but ordering is
  # guaranteed by nifmake's depth-barriered scheduler: every `lower` is depth 1
  # (its `.s.nif` is a leaf) and every `cg` is depth 2, so all lowering finishes
  # before any cg starts — no need to list the closure for ordering. For
  # invalidation, a dependency's change reaches this module through its own
  # `.t.nif` (own `.s.nif` re-sem -> own `lower`); a foreign body this module
  # emit-everywhere'd but does not own is dropped by `emit` regardless, so a
  # stale copy here is harmless. The main module additionally depends on every
  # other `.c.nif` (it reads their init/datInit metas to wire up NimMain).
  for batch in batches:
    b.addTree "do"
    b.addIdent "nim_nifc"
    b.withTree "args":
      b.addStrLit "--icBackendStage:cg"
      b.addStrLit "--icBackendModules:" & suffixList(batch)
    for idx in batch:
      inputStr tFiles[idx]
    inputStr argsFile
    for idx in batch:
      outputStr cnifFiles[idx]
      # The module's C compile/link directives (`{.passL.}` etc.), recorded so
      # the `link` stage recovers them without loading the module graph. See
      # `replayer.writeBackendActions`.
      outputStr cFiles[idx] & BackendActionsExt
    b.endTree()
  block:
    let i = 0
    if live[i]:
      b.addTree "do"
      b.addIdent "nim_nifc"
      b.withTree "args":
        b.addStrLit "--icBackendStage:cg"
        b.addStrLit "--icBackendModules:" & c.nodes[i].files[0].modname
      inputStr tFiles[i]
      inputStr argsFile
      for j in 0 ..< c.nodes.len:
        if c.nodes[j].id != 0 and live[j]:
          inputStr cnifFiles[j]
      outputStr cnifFiles[i]
      outputStr cFiles[i] & BackendActionsExt
      b.endTree()

  # merge: read the live modules' `.c.nif`, write the ownership/liveness
  # decision. The list is handed over as a FILE (`LiveModulesFile`) because the
  # merge child is a separate process that never sees the build file: without it
  # merge globbed `*.c.nif` off the nimcache and so silently absorbed artifacts
  # belonging to some other program that shares the directory.
  let liveFile = nimcache / LiveModulesFile
  block:
    var manifest = ""
    for i in 0 ..< c.nodes.len:
      if live[i]:
        manifest.add cnifFiles[i]
        manifest.add "\n"
    # OnlyIfChanged: its mtime is a merge input, so rewriting it every run would
    # re-fire merge (and, through the decision, every `emit`) on a no-op build.
    if not fileExists(liveFile) or readFile(liveFile) != manifest:
      writeFile(liveFile, manifest)
  b.addTree "do"
  b.addIdent "nim_nifc"
  b.withTree "args":
    b.addStrLit "--icBackendStage:merge"
  for i in 0 ..< c.nodes.len:
    if live[i]: inputStr cnifFiles[i]
  inputStr liveFile
  outputStr mergeFile
  b.endTree()

  # emit: render each module's `.c` from its `.c.nif` + the merge decision.
  #
  # ONE rule for everything, main included. emit is a pure function of a
  # `.c.nif` and the merge decision — `renderCFromArtifact` filters text and
  # touches no AST, and the stage loads no module graph at all — so batching it
  # cannot change what it produces, and measurement agrees: 67 processes and one
  # process give byte-identical `.c`, in 0.502 s versus 0.041 s. What that buys
  # is not the cold build (where 0.5 s serial is ~0.05 s across cores) but the
  # fire-all: every `emit` re-fires whenever `merge` rewrites the decision, which
  # is every edit that reaches the backend. That now costs one process start.
  #
  # `-d:icBatchSize:N` still splits it, for A/B-ing against the fan-out.
  for batch in emitBatches(c, live, batches):
    b.addTree "do"
    b.addIdent "nim_nifc"
    b.withTree "args":
      b.addStrLit "--icBackendStage:emit"
      b.addStrLit "--icBackendModules:" & suffixList(batch)
    # Inputs: each member's OWN `.c.nif` and the global merge decision. emit
    # reads nothing else — it derives its output paths rather than loading a
    # module graph. (It still re-fires for every module whenever `merge` rewrites
    # the decision file; making that incremental is a separate concern — though
    # batching is what makes the re-fire cheap.)
    for idx in batch:
      inputStr cnifFiles[idx]
    inputStr mergeFile
    for idx in batch:
      outputStr cFiles[idx]
      # The freshness proof for this rule; see nifbackend.generateEmitStage. The
      # `.c` alone cannot serve: it is written OnlyIfChanged, so a rule that ran
      # and produced identical bytes looks exactly like a rule that never ran.
      outputStr cFiles[idx] & ".stamp"
    b.endTree()

  # link: compile + link every emitted `.c` in one process.
  b.addTree "do"
  b.addIdent "nim_nifc"
  b.withTree "args":
    b.addStrLit "--icBackendStage:link"
    # The link child is its own `cmdNifC` process whose project is the main
    # module, so it would default the binary to `<maindir>/<main><exeExt>`.
    # Forward the resolved target so it writes exactly `exeFile` (`--out`'s
    # path splits back into outDir+outFile in the child).
    b.addStrLit "--out:" & exeFile
  for i in 0 ..< c.nodes.len:
    if live[i]:
      inputStr cFiles[i]
      inputStr cFiles[i] & BackendActionsExt
  inputStr argsFile
  outputStr exeFile
  b.endTree()

  b.endTree()  # stmts

proc deriveFromSemDeps(c: var DepContext): bool =
  ## Fold every already-compiled module's `.s.deps` sidecar (its REAL post-sem
  ## imports, macro-generated ones included) back into the graph. Returns true
  ## if anything new was added.
  ##
  ## Run BEFORE the first nifmake pass as well as after a failure. The static
  ## scanner cannot see `parseStmt("import dyn")`, so on the run that first hits
  ## it the frontend fails, this recovers the node, and the retry succeeds. But
  ## the graph is rebuilt from scratch on every `nim ic`, so on the NEXT run the
  ## frontend succeeds on round one — with `dyn` absent from the graph again,
  ## hence with no nifler/`nim m` rule of its own and no edge into its importer.
  ## Editing `dyn.nim` then changed nothing at all: the build silently reused the
  ## `.s.bif` from the run that discovered it. Seeding from the sidecars makes
  ## the discovery stick across runs.
  ##
  ## The edges are recorded SPECULATIVELY: a sidecar says what the module
  ## imported the last time it was semmed, which is a statement about the past.
  ## Flip a `when`, or delete an `import`, and a module that is no longer reached
  ## would otherwise linger in the graph forever (and fail to build, if what it
  ## imports is gone). Marking the edge speculative lets `pruneDeadSpeculative`
  ## drop such a leftover, while a genuinely-needed macro import — which compiles
  ## fine — stays.
  result = false
  inc c.speculating
  defer: dec c.speculating
  let n0 = c.nodes.len  # snapshot: new nodes are traversed as they're added
  for ni in 0 ..< n0:
    for p in readSemDeps(c, c.nodes[ni].files[0]):
      let pair = c.toPair(p)
      var idx = c.processedModules.getOrDefault(pair.modname, -1)
      if idx == -1:
        if not fileExists(pair.nimFile): continue
        let newNode = Node(files: @[pair], id: c.nodes.len)
        if c.systemNodeId >= 0:
          newNode.deps.add c.systemNodeId
        if getsImplicitImports(c, pair.nimFile):
          for impId in c.implicitNodeIds:
            if impId != newNode.id: newNode.deps.add impId
        c.processedModules[pair.modname] = newNode.id
        c.nodes.add newNode
        idx = newNode.id
        traverseDeps(c, pair, newNode)
        result = true
      if idx != ni and idx notin c.nodes[ni].deps:
        addDepEdge(c, c.nodes[ni], idx)
        result = true

proc commandIc*(conf: ConfigRef; frontendOnly = false) =
  ## Main entry point for `nim ic`. With `frontendOnly` (used by `nim track` for
  ## IDE queries) it runs only Phase 1 — the incremental nifler + `nim m`
  ## frontend that writes every module's `.s.bif` — and skips the whole-program
  ## backend (`nim nifc` -> C -> link), which a goto-def / find-usages scan does
  ## not need.
  when not defined(nimKochBootstrap):
    let nifler = findNifler()
    if nifler.len == 0:
      rawMessage(conf, errGenerated, "nifler tool not found. Install nimony or add nifler to PATH.")
      return

    # Resolve the `.nim` source first, exactly like `wantMainModule`. Without
    # this, an extensionless project arg (`nim ic path/to/foo`) resolves to a
    # same-named sibling that already exists — e.g. the ELF a prior `nim c`
    # left behind — and nifler chokes on the binary (`invalid token \127`,
    # ELF magic). `addFileExt` only appends when there is no extension.
    conf.projectFull = addFileExt(conf.projectFull, NimExt)
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

    # Model `--import:X` switches (conf.implicitImports). Every ordinary module
    # is compiled with these implicitly imported, so each `nim m` child demands
    # the corresponding NIF. They are invisible to the static import scanner
    # (they come from config, not from `import` statements) and cannot be
    # discovered via `.s.deps` either: every module fails identically at import
    # resolution before recording anything, so there is no bootstrap. Seed them
    # up front like system.nim — create a node, traverse its closure, and record
    # its id so `processImport` adds the edge to every other module. (e.g. Nimbus
    # uses `--import:libbacktrace` together with `-d:nimStackTraceOverride`.)
    for imp in conf.implicitImports:
      let resolved = resolveImport(c, rootPair.nimFile, imp)
      if resolved.len == 0 or not fileExists(resolved): continue
      let impPair = toPair(c, resolved)
      if impPair.modname.len > 0 and impPair.modname notin c.processedModules:
        let impNode = Node(files: @[impPair], id: c.nodes.len)
        if c.systemNodeId >= 0: impNode.deps.add c.systemNodeId
        c.nodes.add impNode
        c.processedModules[impPair.modname] = impNode.id
        rootNode.deps.add impNode.id
        c.implicitNodeIds.add impNode.id
        traverseDeps(c, impPair, impNode)

    # Process dependencies
    traverseDeps(c, rootPair, rootNode)

    # Re-apply what earlier runs discovered post-sem (macro-generated imports),
    # so those modules keep their rules on a warm build instead of vanishing from
    # the graph until the next failure. No-op on a cold cache. Runs BEFORE the
    # prune so a sidecar entry that has since gone stale is prunable too.
    discard deriveFromSemDeps(c)

    # Modules that only a `when` the scanner cannot decide pulls in, and that
    # import something not installed, are dead in this configuration; scheduling
    # them would fail the build over code the classic compiler never reads.
    pruneDeadSpeculative(c)

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
    # The precompiled config drives every `nim m`/`nim nifc` child and the driver
    # itself (`ensureIcConfig` produced it and `loadConfigs` replayed it). If it
    # is not on disk something went wrong producing it — children would each
    # silently fall back to re-parsing the whole config chain — so refuse to
    # continue without it.
    if conf.icPreparsedConfig.len == 0 or not fileExists(conf.icPreparsedConfig):
      rawMessage(conf, errGenerated,
        "precompiled config missing: " & conf.icPreparsedConfig)
      return
    let nifmake = findNifmake()
    # Build the per-module rules concurrently: nifmake fans out all commands at
    # each DAG depth via execProcesses (defaults to all cores). Cold builds are
    # otherwise serial (one child at a time) and leave the machine idle. An
    # uncapped fan-out across many cores can exhaust RAM on a large project (each
    # `nim m`/`cg` child holds its own module graph), which nifmake's own `-j:N`
    # exists to bound. Concurrency is chosen (highest precedence first):
    #   * `-d:icNoParallel`      -> serial (readable, non-interleaved child output)
    #   * `-d:icJobs:N`          -> cap at N (legacy IC-tuning define)
    #   * `--parallelBuild:N`    -> cap at N (the standard Nim build-parallelism
    #                               flag; a no-op for `nim c` under IC, so we give
    #                               it meaning here — lets Nimbus devs pick their
    #                               own value without a `-d:` define)
    #   * otherwise              -> uncapped (all cores)
    let parallel =
      if isDefined(conf, "icNoParallel"): ""
      elif isDefined(conf, "icJobs"): " --parallel:" & conf.symbols["icJobs"]
      elif conf.numberOfProcessors > 0: " --parallel:" & $conf.numberOfProcessors
      else: " --parallel"

    # Phase 1 — frontend (nifler + `nim m`), run to a discovery fixpoint.
    var rounds = 0
    var frontendOk = false
    while true:
      let buildFile = generateFrontendBuildFile(c, forwardedArgs)
      rawMessage(conf, hintSuccess, "generated: " & buildFile)
      if nifmake.len == 0:
        rawMessage(conf, hintSuccess, "run:" & " nifmake run" & parallel & " " & buildFile)
        # without nifmake we can only print the manual commands; emit the
        # backend's too (best effort — discovery cannot run) and stop. An IDE
        # query (`frontendOnly`) needs no backend, so skip it there.
        if not frontendOnly:
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
        discovered = deriveFromSemDeps(c)
      if not discovered:
        # The children have already printed the real diagnostics. Adding an
        # `Error:` line of our own here made a build-system status the LAST error
        # in the stream, hiding the compiler's own message from anything that
        # reads the final error (testament's `errormsg:`, editors, CI log
        # scrapers) — every `reject`-style test under `nim ic` reported
        # "nifmake failed with exit code: 1" instead of what the compiler said.
        # The non-zero exit is what signals failure; this line is context.
        rawMessage(conf, hintExecuting,
          "nifmake reported failures (exit code " & $exitCode & ")")
        # Fail the run without printing an `Error:` of our own (see above): the
        # exit code is derived from `errorCounter`.
        inc conf.errorCounter
        break

    # Phase 2 — backend (whole-program `nim nifc`), run once over the now-final
    # graph. Kept a separate nifmake run so backend rebuilds are decided purely
    # by nifmake's input mtimes, independent of frontend discovery.
    # An IDE query (`frontendOnly`) stops after Phase 1: the `.s.bif` it scans
    # are all produced by the frontend; codegen + link would be wasted work.
    if frontendOk and not frontendOnly:
      let backendFile = generateBackendBuildFile(c, forwardedArgs)
      rawMessage(conf, hintSuccess, "generated: " & backendFile)
      let cmd = quoteShell(nifmake) & " run" & parallel & " " & quoteShell(backendFile)
      rawMessage(conf, hintExecuting, cmd)
      let exitCode = execShellCmd(cmd)
      if exitCode != 0:
        rawMessage(conf, hintExecuting,
          "nifmake reported backend failures (exit code " & $exitCode & ")")
        inc conf.errorCounter
  else:
    rawMessage(conf, errGenerated, "nim ic not available in bootstrap build")
