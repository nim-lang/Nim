#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The "cnif" artifact: the C code generator's output as a NIF file.
##
## This is deliberately *not* NIFC: the C text is kept verbatim (Nim's
## C-level machinery — exception handling in particular — is more refined
## than what NIFC models today; the gap can be closed incrementally later).
## The only structure the artifact adds is the part dead code elimination
## and generic-instance merging need:
##
## - raw C text as string literals
## - every *global* entity's C name as a `Symbol` token
## - every emitted proc definition as a `(cdef SymbolDef flags ...)` group
##
## The C generator marks names with control characters at the single place
## a global's C name is minted (`fillBackendName`) and emits a definition
## directive at the single place finished procs are appended; the marks then
## ride through all of the snippet composition untouched. This module turns
## the final marked module text into the `.c.nif` artifact and strips the
## marks for the actual `.c` output. Rendering C from the artifact is a
## plain token walk: string literals verbatim, symbols by name — which is
## also where a later merge step redirects losing generic instances.
##
## Marker scheme (cannot collide: C string literals escape control chars,
## and `\1`/`\31`/`\23` of cgen's postprocess directives are distinct):
##   \2 name \3                       a global's C name
##   \4 name \31 flags \31 nif \5     start of the definition of `name`;
##                                    `nif` is the defining symbol's NIF name
##                                    (empty for backend-minted symbols) so a
##                                    later run can re-demand the definition
##   \4 \5                            end of the definitions section

import std / [tables, sets, os, assertions, syncio, algorithm]
import "../dist/nimony/src/lib" / [nifbuilder, nifcoreparse]

const
  CnifSymStart* = '\2'
  CnifSymEnd* = '\3'
  CnifDefStart* = '\4'
  CnifDefSep* = '\31'   # same separator char as cgen's postprocess directives
  CnifDefEnd* = '\5'

proc markCName*(name: string): string {.inline.} =
  CnifSymStart & name & CnifSymEnd

proc hasCnifMarks*(s: string): bool =
  for c in s:
    if c in {CnifSymStart, CnifSymEnd, CnifDefStart}: return true
  false

proc stripCnifMarks*(s: string): string =
  ## Removes the symbol marks (keeping the names) and the definition
  ## directives (entirely) so the result is plain C.
  if not hasCnifMarks(s): return s
  result = newStringOfCap(s.len)
  var i = 0
  while i < s.len:
    case s[i]
    of CnifSymStart, CnifSymEnd:
      inc i
    of CnifDefStart:
      while i < s.len and s[i] != CnifDefEnd: inc i
      inc i # skip CnifDefEnd
    else:
      result.add s[i]
      inc i

const
  CnifVersion* = "4"
    ## Artifact format version, stored in the meta head. Artifacts written
    ## by an older compiler lack the NIF names and the cref group the
    ## def-retention check needs (v2), the cdeps group the fine-grained
    ## reuse gate needs (v3), or the type NIF names and cnif-marked extern
    ## RTTI references the typeinfo flavor of the def-retention check
    ## needs (v4); `readCnifHeads` reports them as invalid so their TUs
    ## simply regenerate once.

proc cnifDefDirective*(name, flags, nifName: string): string =
  CnifDefStart & name & CnifDefSep & flags & CnifDefSep & nifName & CnifDefEnd

proc cnifEndDefs*(): string =
  CnifDefStart & CnifDefEnd

proc writeCnifArtifact*(code: string; outfile: string;
                        initRequired = false; datInitRequired = false;
                        dataDefs: openArray[tuple[cname, nifname: string]] = [];
                        semmedNif = ""; moduleBase = "";
                        implDeps: openArray[string] = []) =
  ## Splits the marked module text into the `.c.nif` artifact.
  ## The artifact starts with a `(meta <flags> "semmedNif" "moduleBase"
  ## "version")` head — whether the module has an init/datInit proc
  ## ('i'/'d'), which semmed NIF it was generated from and the module's
  ## mangled base name (what `registerModuleToMain` and the reuse decision
  ## need when the TU is reused in a later run, possibly without the module
  ## ever being loaded again) — a `(cdata (SymbolDef StrLit)*)` group naming
  ## the data definitions (consts, globals, RTTI) the TU embeds together
  ## with their NIF names, a `(cref Ident*)` group naming every C name
  ## the TU references but does not define itself (what the def-retention
  ## check consults when some *other* TU regenerates), and a
  ## `(cdeps Ident*)` group naming the modules whose routine *bodies* this
  ## TU embeds (redirected defs, shared instances, hooks): the fine-grained
  ## reuse gate checks their `.impl.nif` cookies on top of the direct
  ## imports' `.iface.nif` cookies.
  # pre-pass: every marked name is a use, every definition directive (and
  # every data def) is a definition; external references = uses - defs
  var uses = initHashSet[string]()
  var defs = initHashSet[string]()
  block prePass:
    var i = 0
    while i < code.len:
      case code[i]
      of CnifSymStart:
        inc i
        var name = ""
        while i < code.len and code[i] != CnifSymEnd:
          name.add code[i]
          inc i
        inc i
        uses.incl name
      of CnifDefStart:
        inc i
        var payload = ""
        while i < code.len and code[i] != CnifDefEnd:
          payload.add code[i]
          inc i
        inc i
        let sep = find(payload, CnifDefSep)
        if sep > 0: defs.incl payload[0..<sep]
        elif payload.len > 0: defs.incl payload
      else:
        inc i
  for d in dataDefs: defs.incl d.cname
  var crefs: seq[string] = @[]
  for u in uses:
    if u notin defs: crefs.add u
  sort crefs

  var b = nifbuilder.open(outfile)
  b.withTree "stmts":
    b.withTree "meta":
      var metaFlags = ""
      if initRequired: metaFlags.add 'i'
      if datInitRequired: metaFlags.add 'd'
      if metaFlags.len > 0: b.addIdent metaFlags
      else: b.addEmpty
      b.addStrLit semmedNif
      b.addStrLit moduleBase
      b.addStrLit CnifVersion
    b.withTree "cdata":
      for d in dataDefs:
        b.addSymbolDef d.cname
        b.addStrLit d.nifname
    b.withTree "cref":
      for r in crefs:
        b.addIdent r
    b.withTree "cdeps":
      for s in implDeps:
        b.addIdent s
    var raw = ""
    var inDef = false
    template flushRaw() =
      if raw.len > 0:
        b.addStrLit raw
        raw.setLen 0
    var i = 0
    while i < code.len:
      case code[i]
      of CnifSymStart:
        flushRaw()
        inc i
        var name = ""
        while i < code.len and code[i] != CnifSymEnd:
          name.add code[i]
          inc i
        inc i # skip CnifSymEnd
        b.addSymbol name, ""
      of CnifDefStart:
        flushRaw()
        inc i
        var payload = ""
        while i < code.len and code[i] != CnifDefEnd:
          payload.add code[i]
          inc i
        inc i # skip CnifDefEnd
        if inDef:
          b.endTree()
          inDef = false
        if payload.len > 0:
          let sep = find(payload, CnifDefSep)
          let name = if sep >= 0: payload[0..<sep] else: payload
          var flags = if sep >= 0: payload[sep+1..^1] else: ""
          var nifName = ""
          let sep2 = find(flags, CnifDefSep)
          if sep2 >= 0:
            nifName = flags[sep2+1..^1]
            flags = flags[0..<sep2]
          b.addTree "cdef"
          b.addSymbolDef name
          if flags.len > 0: b.addIdent flags
          else: b.addEmpty
          b.addStrLit nifName
          inDef = true
      else:
        raw.add code[i]
        inc i
    flushRaw()
    if inDef:
      b.endTree()
  b.close()

proc renderMarkedC*(code: string; live: HashSet[string]; dropped: var int): string =
  ## Renders the final C text from the marked module text: symbol marks are
  ## removed (keeping the names — a later merge step substitutes them here),
  ## and definitions whose name is not in `live` are dropped entirely. Each
  ## definition is self-delimiting (genProcAux emits an end directive right
  ## after the proc's text), so text written by other emitters is never part
  ## of a definition's span and survives unconditionally.
  result = newStringOfCap(code.len)
  var i = 0
  while i < code.len:
    case code[i]
    of CnifSymStart, CnifSymEnd:
      inc i
    of CnifDefStart:
      var payload = ""
      inc i
      while i < code.len and code[i] != CnifDefEnd:
        payload.add code[i]
        inc i
      inc i # skip CnifDefEnd
      if payload.len > 0:
        let sep = find(payload, CnifDefSep)
        let name = if sep >= 0: payload[0..<sep] else: payload
        if name notin live:
          inc dropped
          # drop the definition's text: everything up to its end directive
          while i < code.len and code[i] != CnifDefStart: inc i
    else:
      result.add code[i]
      inc i

# ---- Liveness over the artifact -------------------------------------------

proc symOrIdentName(c: Cursor): string {.inline.} =
  if c.kind == Ident: strVal(c) else: symName(c)

type
  CnifHeads* = object
    ## The cheap-to-parse part of an artifact that a later run needs in
    ## order to reuse the TU without regenerating it.
    valid*: bool             ## file parsed, carries the meta head and has
                             ## the current format version
    initRequired*: bool
    datInitRequired*: bool
    semmedNif*: string       ## the semmed NIF this TU was generated from
    moduleBase*: string      ## the module's mangled base name
    cdefs*: seq[tuple[cname, nifname: string]] ## the proc definitions
    cdata*: seq[tuple[cname, nifname: string]] ## the data definitions
    crefs*: seq[string]      ## C names referenced but not defined here
    cdeps*: seq[string]      ## module suffixes whose routine bodies this
                             ## TU embeds (impl-cookie gated on reuse)

proc readCnifHeads*(f: string): CnifHeads =
  ## Reads `(meta ...)`, `(cdata ...)`, `(cref ...)` and the `(cdef ...)`
  ## head names from an artifact. Artifacts written by an older compiler
  ## (no meta head or a different format version) report `valid=false`.
  result = CnifHeads()
  if not fileExists(f): return
  var pool = newPool()
  var tags = newTagPool()
  let stmtsTag = tags.registerTag("stmts")
  let cdefTag = tags.registerTag("cdef")
  let cdataTag = tags.registerTag("cdata")
  let crefTag = tags.registerTag("cref")
  let cdepsTag = tags.registerTag("cdeps")
  let metaTag = tags.registerTag("meta")
  var buf = parseFromFile(f, 1000, pool, tags)
  var c = beginRead(buf)
  if c.kind != TagLit or c.cursorTagId != stmtsTag:
    endRead(c)
    return
  var version = ""
  var sawMeta = false
  c.loopInto:
    if c.kind == TagLit:
      if c.cursorTagId == metaTag:
        sawMeta = true
        var strIdx = 0
        c.loopInto:
          if c.kind == Ident:
            for ch in strVal(c):
              if ch == 'i': result.initRequired = true
              elif ch == 'd': result.datInitRequired = true
            inc c
          elif c.kind == StrLit:
            if strIdx == 0: result.semmedNif = strVal(c)
            elif strIdx == 1: result.moduleBase = strVal(c)
            elif strIdx == 2: version = strVal(c)
            inc strIdx
            inc c
          else:
            skip c
      elif c.cursorTagId == cdataTag:
        c.loopInto:
          if c.kind == SymbolDef:
            result.cdata.add (symName(c), "")
            inc c
          elif c.kind == StrLit:
            if result.cdata.len > 0:
              result.cdata[^1].nifname = strVal(c)
            inc c
          else:
            skip c
      elif c.cursorTagId == crefTag:
        c.loopInto:
          if c.kind in {Ident, Symbol, SymbolDef}:
            result.crefs.add symOrIdentName(c)
            inc c
          else:
            skip c
      elif c.cursorTagId == cdepsTag:
        c.loopInto:
          if c.kind in {Ident, Symbol, SymbolDef}:
            result.cdeps.add symOrIdentName(c)
            inc c
          else:
            skip c
      elif c.cursorTagId == cdefTag:
        # fixed head: SymbolDef, flags (Ident or empty), NIF name StrLit;
        # everything after that is the definition's body text
        var state = 0
        c.loopInto:
          if c.kind == SymbolDef:
            result.cdefs.add (symName(c), "")
            state = 1
            inc c
          elif state == 1: # the flags field
            state = 2
            skip c
          elif state == 2: # the NIF name
            if c.kind == StrLit and result.cdefs.len > 0:
              result.cdefs[^1].nifname = strVal(c)
            state = 3
            skip c
          else:
            skip c
      else:
        skip c
    else:
      skip c
  endRead(c)
  result.valid = sawMeta and version == CnifVersion

proc writeLoweredArtifact*(outfile: string; entries: openArray[string]) =
  ## The `.t.nif` "lowered" artifact: one `(lowered "<nifname>" <body>)` per
  ## routine the module OWNS, written by the per-module `lower` backend stage
  ## for the `cg` stage to read instead of re-deriving the transformed body
  ## (re-derivation in each parallel `cg` process is what makes a closure
  ## `:env`'s identity diverge across modules — see transf.transformBody).
  ##
  ## SKELETON: every body is the empty-marker `.` ("transformed body == sem
  ## body"), so `cg` falls back to its own `transformBody` and output stays
  ## byte-identical. The real transformed body fills this slot in a later step;
  ## the `.` then means "unchanged by lowering" (the dedup Araq sketched).
  var b = nifbuilder.open(outfile)
  b.withTree "stmts":
    for name in entries:
      b.withTree "lowered":
        b.addStrLit name
        b.addEmpty()
  b.close()

proc readLoweredArtifact*(f: string): seq[string] =
  ## The routine NIF names recorded in a `.t.nif`. (Bodies are not returned
  ## yet: the skeleton records only empty-markers; reading proves the artifact
  ## round-trips and that the `cg` rule depends on it.)
  result = @[]
  if not fileExists(f): return
  var pool = newPool()
  var tags = newTagPool()
  let stmtsTag = tags.registerTag("stmts")
  let loweredTag = tags.registerTag("lowered")
  var buf = parseFromFile(f, 1000, pool, tags)
  var c = beginRead(buf)
  if c.kind != TagLit or c.cursorTagId != stmtsTag:
    endRead(c)
    return
  c.loopInto:
    if c.kind == TagLit and c.cursorTagId == loweredTag:
      c.loopInto:
        if c.kind == StrLit:
          result.add strVal(c)
          inc c
        else:
          skip c
    else:
      skip c
  endRead(c)

type
  CnifLiveness* = object
    defs*: int      ## proc definitions emitted across all modules
    liveDefs*: int  ## of those, reachable from the roots
    live*: HashSet[string] ## live C names
    broken*: bool

proc computeLiveFromCArtifacts*(files: openArray[string]): CnifLiveness =
  ## dce1-style mark&sweep over the C-shaped artifacts: a `(cdef ...)`
  ## group is a definition (flags 'x'/'c'/'m' — exportc, compilerproc,
  ## method/dispatcher — make it a root), names at the top level (data,
  ## globals, init code) are roots, names inside a group are its uses.
  ## Because the artifact is *fully lowered* output, no conservative
  ## modelling is needed: every call the C code contains is a token here.
  ##
  ## NB: mangled C names contain no dots, so NIF's text reader classifies
  ## them as `Ident` rather than `Symbol`; the dialect therefore treats
  ## Ident tokens as name uses. Inside a `(cdef ...)` the flags ident is
  ## the one immediately following the SymbolDef; everything after is a use.
  result = CnifLiveness(live: initHashSet[string]())
  var pool = newPool()
  var tags = newTagPool()
  let stmtsTag = tags.registerTag("stmts")
  let cdefTag = tags.registerTag("cdef")
  let cdataTag = tags.registerTag("cdata")
  let crefTag = tags.registerTag("cref")
  let cdepsTag = tags.registerTag("cdeps")
  let metaTag = tags.registerTag("meta")
  var uses = initTable[string, HashSet[string]]()
  var roots = initHashSet[string]()
  var defs = initHashSet[string]()
  for f in files:
    if not fileExists(f):
      result.broken = true
      return
    var buf = parseFromFile(f, 1000, pool, tags)
    var c = beginRead(buf)
    if c.kind != TagLit or c.cursorTagId != stmtsTag:
      result.broken = true
      endRead(c)
      return
    c.loopInto:
      case c.kind
      of Symbol, Ident:
        roots.incl symOrIdentName(c)
        inc c
      of TagLit:
        if c.cursorTagId == metaTag or c.cursorTagId == cdataTag or
            c.cursorTagId == crefTag or c.cursorTagId == cdepsTag:
          # bookkeeping for TU reuse, irrelevant for liveness
          skip c
        elif c.cursorTagId == cdefTag:
          var owner = ""
          var flagsSeen = false
          c.loopInto:
            case c.kind
            of SymbolDef:
              owner = symName(c)
              defs.incl owner
              flagsSeen = false
              inc c
            of Symbol, Ident:
              let name = symOrIdentName(c)
              if not flagsSeen:
                # the flags field right after the SymbolDef
                flagsSeen = true
                for ch in name:
                  # 'd' marks a data definition (const/RTTI): never DCE'd, so it
                  # is a root whose body keeps its referenced procs live
                  if ch in {'x', 'c', 'm', 'd'}:
                    roots.incl owner
                    break
              else:
                uses.mgetOrPut(owner, initHashSet[string]()).incl name
              inc c
            of DotToken:
              flagsSeen = true # empty flags field
              inc c
            else:
              skip c
        else:
          c.loopInto:
            if c.kind in {Symbol, Ident}:
              roots.incl symOrIdentName(c)
              inc c
            else:
              skip c
      else:
        skip c
    endRead(c)
  # mark & sweep
  var work = newSeqOfCap[string](roots.len)
  for r in roots: work.add r
  while work.len > 0:
    let s = work.pop()
    if not result.live.containsOrIncl(s):
      if uses.hasKey(s):
        for dep in uses[s]:
          if dep notin result.live:
            work.add dep
  result.defs = defs.len
  for d in defs:
    if d in result.live: inc result.liveDefs

# ---- The merge stage: liveness + owner assignment -------------------------

type
  MergeDecision* = object
    ## What the per-module backend's `merge` stage computes from every
    ## module's `.c.nif` and what its `emit` stage consumes to render the
    ## final `.c` of one module.
    live*: HashSet[string]        ## globally reachable C names (dead cdefs
                                  ## are dropped from every module)
    owners*: Table[string, string] ## for each `'u'`-flagged (unique,
                                  ## externally-linked) definition, the single
                                  ## artifact base name allowed to embed its
                                  ## body; every other module prototypes it
    broken*: bool                 ## an artifact was missing or unparsable —
                                  ## the caller should fall back / regenerate
    defs*, liveDefs*: int

proc computeMergeDecision*(files: openArray[string]): MergeDecision =
  ## One pass over every `.c.nif`: the same mark&sweep as
  ## `computeLiveFromCArtifacts` plus, per definition, owner assignment.
  ##
  ## Each `cg` process emits the body of every definition it demands
  ## (emit-everywhere), so the same externally-linked definition appears in
  ## several artifacts. A `'u'` flag on the `(cdef ...)` marks those that need
  ## exactly one owner, assigned here across processes: the owner is the
  ## lexicographically smallest artifact that emits it — a pure function of the
  ## claimant set, hence stable across rebuilds. Definitions without `'u'`
  ## (inline procs, dispatchers) are `static`/main-only and emitted into every
  ## using TU, so they get no owner entry and are never deduplicated.
  result = MergeDecision(live: initHashSet[string](),
                         owners: initTable[string, string]())
  var pool = newPool()
  var tags = newTagPool()
  let stmtsTag = tags.registerTag("stmts")
  let cdefTag = tags.registerTag("cdef")
  let cdataTag = tags.registerTag("cdata")
  let crefTag = tags.registerTag("cref")
  let cdepsTag = tags.registerTag("cdeps")
  let metaTag = tags.registerTag("meta")
  var uses = initTable[string, HashSet[string]]()
  var roots = initHashSet[string]()
  var defs = initHashSet[string]()
  for f in files:
    if not fileExists(f):
      result.broken = true
      return
    let owner = extractFilename(f)
    var buf = parseFromFile(f, 1000, pool, tags)
    var c = beginRead(buf)
    if c.kind != TagLit or c.cursorTagId != stmtsTag:
      result.broken = true
      endRead(c)
      return
    c.loopInto:
      case c.kind
      of Symbol, Ident:
        roots.incl symOrIdentName(c)
        inc c
      of TagLit:
        if c.cursorTagId == metaTag or c.cursorTagId == cdataTag or
            c.cursorTagId == crefTag or c.cursorTagId == cdepsTag:
          skip c
        elif c.cursorTagId == cdefTag:
          var ownerName = ""
          var flagsSeen = false
          var needsOwner = false
          c.loopInto:
            case c.kind
            of SymbolDef:
              ownerName = symName(c)
              defs.incl ownerName
              flagsSeen = false
              inc c
            of Symbol, Ident:
              let name = symOrIdentName(c)
              if not flagsSeen:
                flagsSeen = true
                for ch in name:
                  if ch in {'x', 'c', 'm'}: roots.incl ownerName
                  # 'u' = unique proc (DCE'd), 'd' = data (never DCE'd, hence a
                  # root); both need a single owner across the emit-everywhere
                  # processes
                  elif ch == 'u': needsOwner = true
                  elif ch == 'd':
                    needsOwner = true
                    roots.incl ownerName
              else:
                uses.mgetOrPut(ownerName, initHashSet[string]()).incl name
              inc c
            of DotToken:
              flagsSeen = true # empty flags field
              inc c
            else:
              skip c
          if needsOwner and ownerName.len > 0:
            # smallest claimant wins; ties impossible (one entry per name)
            let prev = result.owners.getOrDefault(ownerName, "")
            if prev.len == 0 or owner < prev:
              result.owners[ownerName] = owner
        else:
          c.loopInto:
            if c.kind in {Symbol, Ident}:
              roots.incl symOrIdentName(c)
              inc c
            else:
              skip c
      else:
        skip c
    endRead(c)
  var work = newSeqOfCap[string](roots.len)
  for r in roots: work.add r
  while work.len > 0:
    let s = work.pop()
    if not result.live.containsOrIncl(s):
      if uses.hasKey(s):
        for dep in uses[s]:
          if dep notin result.live:
            work.add dep
  result.defs = defs.len
  for d in defs:
    if d in result.live: inc result.liveDefs

const MergeDecisionFile* = "ic.backend.merge.nif"
  ## Fixed name of the merge stage's output in the nimcache, read by `emit`.

proc writeMergeDecision*(outfile: string; d: MergeDecision) =
  ## Serializes the merge decision: `(merge (live Symbol*) (owners (own
  ## Symbol StrLit)*))`. C names are mangled (no dots) so they serialize as
  ## symbols; owner artifact base names go in string literals.
  var live: seq[string] = @[]
  for n in d.live: live.add n
  sort live
  var keys: seq[string] = @[]
  for k in d.owners.keys: keys.add k
  sort keys
  var b = nifbuilder.open(outfile)
  b.withTree "merge":
    b.withTree "live":
      for n in live: b.addSymbol n, ""
    b.withTree "owners":
      for k in keys:
        b.withTree "own":
          b.addSymbol k, ""
          b.addStrLit d.owners[k]
  b.close()

proc readMergeDecision*(f: string): MergeDecision =
  ## Reads back a `writeMergeDecision` file; `broken=true` if absent/unparsable.
  result = MergeDecision(live: initHashSet[string](),
                         owners: initTable[string, string]())
  if not fileExists(f):
    result.broken = true
    return
  var pool = newPool()
  var tags = newTagPool()
  let mergeTag = tags.registerTag("merge")
  let liveTag = tags.registerTag("live")
  let ownersTag = tags.registerTag("owners")
  let ownTag = tags.registerTag("own")
  var buf = parseFromFile(f, 1000, pool, tags)
  var c = beginRead(buf)
  if c.kind != TagLit or c.cursorTagId != mergeTag:
    result.broken = true
    endRead(c)
    return
  c.loopInto:
    if c.kind == TagLit and c.cursorTagId == liveTag:
      c.loopInto:
        if c.kind in {Symbol, Ident}:
          result.live.incl symOrIdentName(c)
          inc c
        else:
          skip c
    elif c.kind == TagLit and c.cursorTagId == ownersTag:
      c.loopInto:
        if c.kind == TagLit and c.cursorTagId == ownTag:
          var key = ""
          c.loopInto:
            if c.kind in {Symbol, Ident}:
              key = symOrIdentName(c)
              inc c
            elif c.kind == StrLit:
              if key.len > 0: result.owners[key] = strVal(c)
              inc c
            else:
              skip c
        else:
          skip c
    else:
      skip c
  endRead(c)

proc renderCFromArtifact*(artifact: string; d: MergeDecision; ownerId: string;
                          dropped: var int): string =
  ## The per-module backend's `emit` stage: render one module's final `.c` from
  ## its `.c.nif` and the merge decision. String literals are emitted verbatim,
  ## symbols by name; a `(cdef ...)` body is dropped when the name is dead, or
  ## when it is a `'u'` unique definition this module does not own. The body's
  ## prototype lives in the surrounding raw text (cgen emits a forward
  ## declaration for every *used* proc, independent of where the body lands), so
  ## a dropped body still leaves a valid declaration — no synthesis needed. The
  ## head groups (meta/cdata/cref/cdeps) carry no C text.
  result = ""
  if not fileExists(artifact): return
  var pool = newPool()
  var tags = newTagPool()
  let stmtsTag = tags.registerTag("stmts")
  let cdefTag = tags.registerTag("cdef")
  var buf = parseFromFile(artifact, 1000, pool, tags)
  var c = beginRead(buf)
  if c.kind != TagLit or c.cursorTagId != stmtsTag:
    endRead(c)
    return
  c.loopInto:
    case c.kind
    of StrLit:
      result.add strVal(c)
      inc c
    of Symbol, Ident:
      result.add symOrIdentName(c)
      inc c
    of TagLit:
      if c.cursorTagId == cdefTag:
        # fixed head: SymbolDef, flags (Ident or empty), nifname StrLit; the
        # rest is the definition's body text. `state` counts past the head.
        var name = ""
        var isUnique = false
        var isData = false
        var keep = true
        var state = 0
        c.loopInto:
          if state == 0 and c.kind == SymbolDef:
            name = symName(c)
            state = 1
            inc c
          elif state == 1: # the flags field (one token: Ident/Symbol or empty)
            if c.kind in {Ident, Symbol}:
              for ch in symOrIdentName(c):
                if ch == 'u': isUnique = true
                elif ch == 'd': isData = true
            state = 2
            inc c
          elif state == 2: # the NIF name (one StrLit) — decide keep here
            let owned = d.owners.getOrDefault(name, ownerId) == ownerId
            keep =
              if isData: owned                      # data: kept by its owner only
              elif isUnique: (name in d.live) and owned
              else: name in d.live                  # inline/dispatcher: per-TU
            if not keep: inc dropped
            state = 3
            inc c
          else: # body tokens
            if keep:
              if c.kind == StrLit: result.add strVal(c)
              elif c.kind in {Symbol, Ident}: result.add symOrIdentName(c)
            inc c
      else:
        # head groups (meta/cdata/cref/cdeps) carry no C text
        skip c
    else:
      inc c
  endRead(c)
