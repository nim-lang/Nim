#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Dead code analysis over per-module NIF files — a port of Nimony's
## `hexer/dce1.nim`/`dce2.nim` ideas onto the `nifcore` API.
##
## Per module we collect, in a single token walk over its `.nif` file:
## - `roots`: symbols that are alive by construction — anything referenced
##   from top-level init code (every module's init proc is always emitted),
##   plus flag-based entry points (see below)
## - `uses`: edges `definition -> symbols referenced inside its body`
##
## A global mark&sweep over the union of all modules' graphs then yields the
## set of live symbols.
##
## The NIF files contain *semchecked* (unlowered) AST, so uses that only
## materialize during the backend's lowering passes are invisible to the
## token walk. Those are covered by conservative roots instead:
## - registered hooks and `$enum` procs (the `(rep* "key" sym)` entries):
##   `injectdestructors` and magic lowering insert calls to them at codegen
## - `{.compilerproc.}` symbols: requested by name via `cgsym`
## - `{.exportc.}` symbols, methods and dispatchers: external entry points
##   resp. reachable through dynamic dispatch only
##
## In the current single-process backend the result is consumed as a skip
## filter for the eagerly generated top-level routine listing
## (`ccgstmts.genStmts`); cgen's demand-driven `genProc` remains in place,
## so an analysis miss can only cost code size, never correctness. The same
## analysis is the building block for per-module incremental codegen later,
## where it has to stand on its own.

import std / [tables, sets, os, assertions]
from std / strutils import rfind
import "../dist/nimony/src/lib" / nifcoreparse
import ast, options, pathutils
import ic / enum2nif

type
  DceContext = object
    pool: Pool      # shared literal pool: same name <=> same SymId everywhere
    tags: TagPool   # shared tag pool: tag ids fixed by the registrations below
    uses: Table[SymId, HashSet[SymId]]
    roots: HashSet[SymId]
    stmtsTag, sdefTag, implTag, replayTag, importTag, includeTag: TagId
    methodKindTag: TagId
    hookTags: HashSet[TagId]
    routineKindTags: HashSet[TagId]
    offers: HashSet[SymId]  # generic routine instances defined by the modules
    broken: bool    # a module failed to parse; the result must not be used

  DceStats* = object
    instances*: int        ## routine instance definitions across all modules
    uniqueInstances*: int  ## distinct instantiation keys (name.disamb)
      ## `instances - uniqueInstances` = definitions a merge step would drop

const
  NoSym = SymId(0) # pool ids start at 1

proc symIdAt(c: Cursor): SymId {.inline.} =
  # Every symbol in our NIFs is written with its `.disamb.modulesuffix`, so
  # the name is always longer than nifcore's 3-byte inline-string cutoff and
  # lands in the (shared) pool: pool ids are stable identities across all
  # modules' token buffers.
  assert not isInlineLit(c), "unexpectedly short NIF symbol name"
  SymId(combinedPayload(c) shr 1)

proc recordUse(ctx: var DceContext; sym, owner: SymId) =
  if owner == NoSym:
    ctx.roots.incl sym
  else:
    ctx.uses.mgetOrPut(owner, initHashSet[SymId]()).incl sym

proc walkDef(ctx: var DceContext; c: var Cursor; owner: SymId; declarative: bool)

proc walk(ctx: var DceContext; c: var Cursor; owner: SymId; declarative: bool) =
  ## Generic walk. `owner == NoSym and not declarative` is init-code context:
  ## symbol uses become roots. With an owner they become `uses` edges. In
  ## declarative context (the listing after the `(implementation)` marker)
  ## bare uses record nothing — only definitions found inside contribute.
  case c.kind
  of TagLit:
    if c.cursorTagId == ctx.sdefTag:
      walkDef(ctx, c, owner, declarative)
    else:
      c.loopInto:
        walk(ctx, c, owner, declarative)
  of Symbol:
    if not declarative:
      recordUse(ctx, symIdAt(c), owner)
    inc c
  else:
    skip c

proc walkDef(ctx: var DceContext; c: var Cursor; owner: SymId; declarative: bool) =
  # Layout (ast2nif.writeSymDef):
  #   (sd SymbolDef <x|.> (symkind ...) magic flags options offset ...)
  # NB: no `return` inside `into` — it would skip the cursor rescoping.
  c.into:
    if c.kind == SymbolDef:
      let self = symIdAt(c)
      # An sdef is emitted at the symbol's *first reference*; in use
      # positions that reference counts like a plain symbol use.
      if not declarative:
        recordUse(ctx, self, owner)
      inc c
      if c.hasMore: skip c          # export marker: "x" or dot
      var rooted = false
      var isRoutine = false
      if c.hasMore and c.kind == TagLit: # symbol kind tree
        if c.cursorTagId == ctx.methodKindTag:
          rooted = true               # reachable via dynamic dispatch
        isRoutine = c.cursorTagId in ctx.routineKindTags
        c.loopInto:
          walk(ctx, c, self, false)   # guard sym/bitsize for vars
      if c.hasMore: skip c          # magic: ident or dot
      if c.hasMore:                 # flags: ident or dot
        if c.kind == Ident:
          let fl = parse(TSymFlag, strVal(c))
          if sfExportc in fl or sfCompilerProc in fl or sfDispatcher in fl:
            rooted = true
          if isRoutine and sfFromGeneric in fl:
            ctx.offers.incl self
        skip c
      if rooted: ctx.roots.incl self
      # rest: options, offset, position, lib, type, owner, ast, loc,
      # constraint, instantiatedFrom — all walked as the definition's body
      while c.hasMore:
        walk(ctx, c, self, false)
    else:
      # malformed sdef; consume defensively
      while c.hasMore:
        walk(ctx, c, owner, declarative)

proc rootHookSyms(ctx: var DceContext; c: var Cursor) =
  # (repdestroy "typekey" hookSym) and friends
  c.loopInto:
    if c.kind == Symbol:
      ctx.roots.incl symIdAt(c)
      inc c
    else:
      skip c

proc analyzeNifFile(ctx: var DceContext; filename: string;
                    imports: var seq[string]) =
  if not fileExists(filename):
    ctx.broken = true
    return
  var buf = parseFromFile(filename, 1000, ctx.pool, ctx.tags)
  var c = beginRead(buf)
  if c.kind == TagLit and c.cursorTagId == ctx.stmtsTag:
    var declarative = false
    c.loopInto:
      case c.kind
      of TagLit:
        let tag = c.cursorTagId
        if tag == ctx.implTag:
          # marks the start of the declarative listing (routines, type
          # sections, consts); everything before it is init code
          declarative = true
          skip c
        elif tag == ctx.importTag:
          # (import . . "modsuffix") — the analysis discovers the module
          # closure itself; the backend's own module list omits modules that
          # are only reached through system or through demand-driven codegen
          c.loopInto:
            if c.kind == StrLit:
              imports.add strVal(c)
              inc c
            else:
              skip c
        elif tag == ctx.replayTag or tag == ctx.includeTag:
          skip c                    # compile directives and include info
        elif tag in ctx.hookTags:
          rootHookSyms(ctx, c)
        elif tag == ctx.sdefTag:
          # a definition listed at section level (globals before the marker,
          # announced hooks after it): a declaration, not a use
          walkDef(ctx, c, NoSym, true)
        else:
          walk(ctx, c, NoSym, declarative)
      of Symbol:
        inc c                       # bare re-listing of a written definition
      else:
        skip c                      # the stmts wrapper's flag/type dots
  else:
    ctx.broken = true
  endRead(c)

proc markLive(ctx: DceContext): HashSet[SymId] =
  result = initHashSet[SymId]()
  var work = newSeqOfCap[SymId](ctx.roots.len)
  for r in ctx.roots: work.add r
  while work.len > 0:
    let s = work.pop()
    if not result.containsOrIncl(s):
      if ctx.uses.hasKey(s):
        for dep in ctx.uses[s]:
          if dep notin result:
            work.add dep

proc computeLiveSymbols*(conf: ConfigRef; seedFiles: openArray[string];
                         live: var HashSet[string]; stats: var DceStats;
                         nifDeps: var Table[string, seq[string]]): bool =
  ## Global liveness over a program's NIF modules: the seeds plus the
  ## transitive closure of their `(import ...)` entries. On success fills
  ## `live` with the NIF names (`name.disamb.modsuffix`) of every reachable
  ## symbol and returns true. Returns false when any module could not be
  ## analyzed — the caller must then treat everything as live.
  ## `nifDeps` receives the import graph over NIF file paths — the full
  ## closure including the modules the backend's own module list omits;
  ## the artifact-reuse decision needs it for transitive invalidation.
  var ctx = DceContext(pool: newPool(), tags: newTagPool())
  ctx.stmtsTag = ctx.tags.registerTag("stmts")
  ctx.sdefTag = ctx.tags.registerTag("sd")
  ctx.implTag = ctx.tags.registerTag("implementation")
  ctx.replayTag = ctx.tags.registerTag("replay")
  ctx.importTag = ctx.tags.registerTag("import")
  ctx.includeTag = ctx.tags.registerTag("include")
  ctx.methodKindTag = ctx.tags.registerTag("method")
  for t in ["repdestroy", "repcopy", "repwasmoved", "repdup", "repsink",
            "reptrace", "repdeepcopy", "repenumtostr"]:
    ctx.hookTags.incl ctx.tags.registerTag(t)
  for t in ["proc", "func", "iterator", "converter", "method"]:
    ctx.routineKindTags.incl ctx.tags.registerTag(t)
  var queue = newSeq[string](seedFiles.len)
  for i in 0..<seedFiles.len: queue[i] = seedFiles[i]
  var seen = initHashSet[string]()
  var i = 0
  while i < queue.len:
    let f = queue[i]
    inc i
    if seen.containsOrIncl(f): continue
    var imports: seq[string] = @[]
    analyzeNifFile(ctx, f, imports)
    if ctx.broken: return false
    if conf != nil:
      var depFiles = newSeqOfCap[string](imports.len)
      for suffix in imports:
        let depFile = toGeneratedFile(conf, AbsoluteFile(suffix), ".nif").string
        depFiles.add depFile
        queue.add depFile
      nifDeps[f] = depFiles
  let liveIds = markLive(ctx)
  live = initHashSet[string](liveIds.len)
  for s in liveIds:
    live.incl ctx.pool.syms[s]
  # Instance duplication stats: with content-derived instance disambs the
  # NIF name minus the module suffix is the instantiation key, so the same
  # instantiation made by several modules counts as one unique instance.
  stats = DceStats(instances: ctx.offers.len)
  var uniq = initHashSet[string]()
  for s in ctx.offers:
    let name = ctx.pool.syms[s]
    let suffixStart = rfind(name, '.')
    uniq.incl(if suffixStart >= 0: name[0..<suffixStart] else: name)
  stats.uniqueInstances = uniq.len
  result = true
