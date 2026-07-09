#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## NIF-based goto-definition / find-all-usages for `nim track`.
##
## This is the mainline-Nim port of nimony's `idetools.nim`. It answers a
## `--def:FILE,LINE,COL` / `--usages:FILE,LINE,COL` query by *scanning the
## `.s.bif` files* (binary NIF, see `dist/nimony/src/lib/bif.nim`) that the
## preceding `nim ic` frontend (`nim track`) emitted into the nimcache directory
## — NOT by re-running sem. NIF distinguishes a definition (`SymbolDef` token) from a use
## (`Symbol` token) syntactically, so goto-def / find-uses become plain token
## scans over type-checked NIF, which is more reliable than the classic PSym
## engine because generics and macros are type-checked in the NIF too.
##
## Two passes (mirroring nimony's `usages`):
##  1. Load the queried module's `.s.bif` and find the `Symbol`/`SymbolDef`
##     token whose line info + identifier length contains `conf.m.trackPos`.
##     That yields the mangled symbol NAME and whether it is global (>= 2 dots).
##  2. `--usages`: emit every `Symbol` (use) token; `--def`: every `SymbolDef`.
##     A global symbol is scanned across every module `.s.bif`; a local one only
##     within the queried module.
##
## IMPORTANT porting note: `bif.load` mints FRESH per-file pools, so a `SymId`
## from module A's buffer is meaningless in module B's. The cross-module match is
## therefore by the mangled NAME string, never by `SymId` (nimony can compare ids
## because it parses every text NIF into one shared global pool; we cannot).

import std / [os, strutils, sets]
import options, msgs, pathutils
import lineinfos as astli
import ast2nif   # toNifFilename
from deps import includerSbifs   # deps-guided include-file lookup
import "../dist/nimony/src/lib/nifcore"
from "../dist/nimony/src/lib" / bif import load, BifModule, containsSym

proc identLen(name: string): int =
  ## Length of the displayed identifier: the run before the first `.` of a
  ## mangled NIF name (`ident.disamb[.moduleSuffix]`). Bounds the column match.
  let d = name.find('.')
  result = if d < 0: name.len else: d

proc isGlobalName(name: string): bool =
  ## A global symbol carries `ident.disamb.moduleSuffix` (>= 2 dots); a local at
  ## most `ident.disamb` (<= 1 dot). `moduleSuffix` is a dot-free hash, so a raw
  ## dot count is equivalent to nifbuilder's suffix-compressed test for our use.
  var dots = 0
  for i in 1 ..< name.len:
    if name[i] == '.': inc dots
  result = dots >= 2

proc posMatch(c: Cursor; conf: ConfigRef; target: TLineInfo; tokenLen: int): bool =
  ## True when `target` (the queried position) falls within the identifier span
  ## of the Symbol/SymbolDef token at `c`. Mirrors nimony's `lineInfoMatch`; the
  ## filename is resolved through the loaded buffer's own pool (fresh per file),
  ## then mapped to a `FileIndex` exactly like `ast2nif.oldLineInfo`.
  let li = rawLineInfo(c)
  if not li.isValid: return false
  if li.line.int != target.line.int: return false
  let f = fileInfoIdx(conf, AbsoluteFile lineInfoFile(c))
  if f != target.fileIndex: return false
  if target.col.int < li.col.int: return false
  if target.col.int > li.col.int + tokenLen: return false
  result = true

const sep = '\t'

proc formatSuggest(s: Suggest): string =
  ## Reproduce `suggest.$Suggest` for the `ideDef`/`ideUse` sections without
  ## importing `suggest` (which would create an import cycle). Layout:
  ## `section⭾symkind⭾qualifiedPath⭾forth⭾filePath⭾line⭾column⭾⭾quality`.
  ## symkind is always `skUnknown` here — the raw NIF scan has no PSym to give a
  ## real kind (like nimony's `foundSymbol`, which leaves it empty).
  result = $s.section
  result.add sep
  result.add "skUnknown"
  result.add sep
  if s.qualifiedPath.len != 0:
    result.add s.qualifiedPath.join(".")
  result.add sep
  result.add s.forth
  result.add sep
  result.add s.filePath
  result.add sep
  result.add $s.line
  result.add sep
  result.add $s.column
  result.add sep            # empty doc field (docgen is off outside nimsuggest)
  if s.version == 0 or s.version == 3:
    result.add sep
    result.add $s.quality

proc emit(conf: ConfigRef; c: Cursor; section: IdeCmd; name: string;
          seen: var HashSet[string]) =
  ## Report one hit as a nimsuggest-compatible result (routed through the
  ## structured-output hook / `--stdout`). We only have the mangled name + line
  ## info from the raw NIF, so symkind/type are left empty — like nimony's
  ## `foundSymbol`. `seen` deduplicates: the same source location can back
  ## several NIF `Symbol` tokens (e.g. a call argument re-emitted in a lowered
  ## form), which must surface as one hit.
  let li = rawLineInfo(c)
  if not li.isValid: return
  let key = $section.int & ":" & lineInfoFile(c) & ":" & $li.line.int & ":" & $li.col.int
  if seen.containsOrIncl(key):
    return  # already reported this location for this section
  let s = Suggest(section: section,
                  qualifiedPath: @[name[0 ..< identLen(name)]],
                  filePath: lineInfoFile(c),
                  line: li.line.int,
                  column: li.col.int,
                  tokenLen: identLen(name),
                  forth: "",
                  symkind: 0'u8,
                  quality: 100,
                  version: conf.suggestVersion)
  if conf.suggestionResultHook != nil:
    conf.suggestionResultHook(s)
  else:
    conf.suggestWriteln(formatSuggest(s))

proc tokenSymId(c: Cursor): SymId {.inline.} =
  ## SymId (in the cursor's own per-file pool) of a `Symbol`/`SymbolDef` token,
  ## or `SymId(0)` for an inline-encoded one — which is never our search target:
  ## a mangled name (`ident.disamb.suffix`) is always longer than
  ## `StrInlineMaxLen`, so every occurrence of the symbol we look for is stored by
  ## pool id, decoded here with a shift and no string materialization.
  if isInlineLit(c): SymId(0) else: SymId(combinedPayload(c) shr 1)

template symMatches(c: Cursor): bool =
  ## True when the token at `c` is the searched symbol. The fast path is a pure
  ## integer compare against `targetSym` (the symbol's id in THIS module's pool,
  ## resolved once per file by the caller). `targetSym == 0` means the name is not
  ## representable as a pool id (a rare <=3-byte local): fall back to a string
  ## compare, correct for both inline and pooled encodings.
  (if targetSym != SymId(0): tokenSymId(c) == targetSym else: symName(c) == targetName)

proc scanUses(conf: ConfigRef; m: var BifModule; targetSym: SymId; targetName: string;
              seen: var HashSet[string]) =
  ## `--usages`: report every `Symbol` (use) occurrence with valid line info.
  if m.buf.len == 0: return
  var c = m.buf.beginRead()
  while c.hasMore:
    if c.kind == Symbol and symMatches(c) and rawLineInfo(c).isValid:
      emit(conf, c, ideUse, targetName, seen)
    inc c
  c.endRead()

proc scanDef(conf: ConfigRef; m: var BifModule; targetSym: SymId; targetName: string;
             seen: var HashSet[string]) =
  ## `--def`: report the declaration of the target symbol if this module owns it
  ## (has its `SymbolDef`). The `SymbolDef` token itself carries no line info; the
  ## declaration location lives on the *enclosing tag* (e.g. `(sd @file:line:col`,
  ## like `bif.buildIndex`'s `mostRecentTagPos`). When that tag has no line info
  ## either, fall back to the declaration-site `Symbol` occurrence — but only in
  ## the owning module, so a plain user of the symbol is never reported as a def.
  if m.buf.len == 0: return
  var c = m.buf.beginRead()
  var mostRecentTagPos = 0
  var sawDef = false
  var emitted = false
  var fallbackPos = -1
  while c.hasMore:
    case c.kind
    of TagLit:
      mostRecentTagPos = cursorToPosition(m.buf, c)
      inc c
    of SymbolDef:
      if symMatches(c):
        sawDef = true
        var tc = cursorAt(m.buf, mostRecentTagPos)
        if rawLineInfo(tc).isValid:
          emit(conf, tc, ideDef, targetName, seen)
          emitted = true
        tc.endRead()
      inc c
    of Symbol:
      if fallbackPos < 0 and symMatches(c) and rawLineInfo(c).isValid:
        fallbackPos = cursorToPosition(m.buf, c)
      inc c
    else:
      inc c
  c.endRead()
  if sawDef and not emitted and fallbackPos >= 0:
    var fc = cursorAt(m.buf, fallbackPos)
    emit(conf, fc, ideDef, targetName, seen)
    fc.endRead()

proc scanBuf(conf: ConfigRef; m: var BifModule; section: IdeCmd;
             targetSym: SymId; targetName: string; seen: var HashSet[string]) =
  ## Emit hits for the target symbol in `m` per the query kind. `ideDus`
  ## (`--defusages`) reports both the definition and every usage.
  if section in {ideDef, ideDus}:
    scanDef(conf, m, targetSym, targetName, seen)
  if section in {ideUse, ideDus}:
    scanUses(conf, m, targetSym, targetName, seen)

proc findPos(conf: ConfigRef; m: var BifModule; target: TLineInfo;
             foundName: var string): bool =
  ## Scan `m` for the `Symbol`/`SymbolDef` token covering the queried position
  ## `target` and set `foundName` to its mangled name. Returns true on a hit.
  if m.buf.len == 0: return false
  var c = m.buf.beginRead()
  result = false
  while c.hasMore:
    let k = c.kind
    if k == Symbol or k == SymbolDef:
      let nm = symName(c)
      if posMatch(c, conf, target, identLen(nm)):
        foundName = nm
        result = true
        break
    inc c
  c.endRead()

proc runIdeQuery*(conf: ConfigRef) =
  ## Entry point: called from `main.nim` after `commandCheck` when a
  ## `--def`/`--usages` query is active. Assumes the check just emitted the
  ## project's `.s.bif` files into `getNimcacheDir(conf)`.
  let section = conf.ideCmd
  if section notin {ideDef, ideUse, ideDus}: return
  let target = conf.m.trackPos
  if target.fileIndex.int32 < 0: return

  # Pass 1: position -> symbol. Try the queried file's own module bif first (the
  # fast path when the position is inside a real module). An include file has no
  # module bif of its own — its tokens live in the *including* module's bif with
  # include-file line info — so when the direct lookup misses, consult the
  # `.deps.nif` preludes (`includerSbifs`) to load only the module(s) that
  # include the queried file (directly or transitively), never every bif in the
  # nimcache. `ownerFile` is the bif that owns the hit.
  let modFile = toNifFilename(conf, target.fileIndex)
  var foundName = ""
  var ownerFile = ""
  if fileExists(modFile):
    var qm = load(modFile)
    if findPos(conf, qm, target, foundName):
      ownerFile = modFile
  if foundName.len == 0:
    for cand in includerSbifs(conf, toFullPath(conf, target.fileIndex).AbsoluteFile):
      if cand == modFile: continue
      var m = load(cand)
      if findPos(conf, m, target, foundName):
        ownerFile = cand
        break
  if foundName.len == 0: return

  # Pass 2: emit definition / usages. `seen` spans every module so a location is
  # reported once even when scanned across the whole nimcache.
  #
  # Cross-file matching is by SymId, not by decoding every token's name. Two
  # filters keep it cheap:
  #   1. `bif.containsSym` — a sym-table-only probe that reads just the small
  #      trailing pools, NOT the token block or any `BiTable`. A module that never
  #      references the symbol is rejected here without a full `load` (no pools
  #      built, no token block mapped) — so a query whose symbol lives in a few
  #      modules no longer pays to load the whole nimcache.
  #   2. For a module that does contain it, `bif.load` mints a fresh per-file pool,
  #      so the name is resolved to THIS file's SymId once via `getKeyId`; the scan
  #      then compares integer ids per token instead of materializing a string for
  #      each (see `symMatches`).
  var seen = initHashSet[string]()
  if isGlobalName(foundName):
    for f in walkFiles((getNimcacheDir(conf).string) / "*.s.bif"):
      if not containsSym(f, foundName): continue
      var m = load(f)
      let tid = m.buf.pool.syms.getKeyId(foundName)
      if tid != SymId(0):
        scanBuf(conf, m, section, tid, foundName, seen)
  else:
    # Local symbol: its mangled name is not unique across modules, so restrict
    # the scan to the module it lives in (the one that owns the queried position).
    var qm = load(ownerFile)
    let tid = qm.buf.pool.syms.getKeyId(foundName)
    scanBuf(conf, qm, section, tid, foundName, seen)
