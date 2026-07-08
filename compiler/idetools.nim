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

import std / [os, strutils]
import options, msgs, pathutils
import lineinfos as astli
import ast2nif   # toNifFilename
import "../dist/nimony/src/lib/nifcore"
from "../dist/nimony/src/lib" / bif import load, BifModule

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

proc emit(conf: ConfigRef; c: Cursor; section: IdeCmd; name: string) =
  ## Report one hit as a nimsuggest-compatible result (routed through the
  ## structured-output hook / `--stdout`). We only have the mangled name + line
  ## info from the raw NIF, so symkind/type are left empty — like nimony's
  ## `foundSymbol`.
  let li = rawLineInfo(c)
  if not li.isValid: return
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

proc scanUses(conf: ConfigRef; m: var BifModule; targetName: string) =
  ## `--usages`: report every `Symbol` (use) occurrence with valid line info.
  if m.buf.len == 0: return
  var c = m.buf.beginRead()
  while c.hasMore:
    if c.kind == Symbol and symName(c) == targetName and rawLineInfo(c).isValid:
      emit(conf, c, ideUse, targetName)
    inc c
  c.endRead()

proc scanDef(conf: ConfigRef; m: var BifModule; targetName: string) =
  ## `--def`: report the declaration of `targetName` if this module owns it (has
  ## its `SymbolDef`). The `SymbolDef` token itself carries no line info; the
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
      if symName(c) == targetName:
        sawDef = true
        var tc = cursorAt(m.buf, mostRecentTagPos)
        if rawLineInfo(tc).isValid:
          emit(conf, tc, ideDef, targetName)
          emitted = true
        tc.endRead()
      inc c
    of Symbol:
      if fallbackPos < 0 and symName(c) == targetName and rawLineInfo(c).isValid:
        fallbackPos = cursorToPosition(m.buf, c)
      inc c
    else:
      inc c
  c.endRead()
  if sawDef and not emitted and fallbackPos >= 0:
    var fc = cursorAt(m.buf, fallbackPos)
    emit(conf, fc, ideDef, targetName)
    fc.endRead()

proc scanBuf(conf: ConfigRef; m: var BifModule; section: IdeCmd; targetName: string) =
  ## Emit hits for `targetName` in `m` per the query kind.
  if section == ideDef:
    scanDef(conf, m, targetName)
  else:
    scanUses(conf, m, targetName)

proc runIdeQuery*(conf: ConfigRef) =
  ## Entry point: called from `main.nim` after `commandCheck` when a
  ## `--def`/`--usages` query is active. Assumes the check just emitted the
  ## project's `.s.bif` files into `getNimcacheDir(conf)`.
  let section = conf.ideCmd
  if section notin {ideDef, ideUse}: return
  let target = conf.m.trackPos
  if target.fileIndex.int32 < 0: return

  # Pass 1: position -> symbol, in the queried module's own .s.bif.
  let modFile = toNifFilename(conf, target.fileIndex)
  if not fileExists(modFile): return
  var qm = load(modFile)
  var foundName = ""
  block find:
    if qm.buf.len == 0: break find
    var c = qm.buf.beginRead()
    while c.hasMore:
      let k = c.kind
      if k == Symbol or k == SymbolDef:
        let nm = symName(c)
        if posMatch(c, conf, target, identLen(nm)):
          foundName = nm
          break find
      inc c
    c.endRead()
  if foundName.len == 0: return

  # Pass 2: emit definition / usages.
  if isGlobalName(foundName):
    for f in walkFiles((getNimcacheDir(conf).string) / "*.s.bif"):
      var m = load(f)
      scanBuf(conf, m, section, foundName)
  else:
    # Local symbol: its mangled name is not unique across modules, so restrict
    # the scan to the module it lives in (the queried module).
    scanBuf(conf, qm, section, foundName)
