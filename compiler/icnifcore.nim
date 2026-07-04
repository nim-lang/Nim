#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## nifcore-based IC serialization helpers — Stage 1 of porting the IC backend
## from the old `nifstreams`/`nifcursors` NIF stack to `nifcore` (see
## `doc/ic_nifcore_port.md`).
##
## It hosts:
## * the process-wide shared `Pool`/`TagPool` that stands in for the old global
##   `nifstreams.pool`,
## * `writeFileStable`, the content-stable file writer mirroring
##   `nifcursors.writeFile(..., OnlyIfChanged)`,
## * the first ported writer (`writeSemDeps`), used as the migration spike.
##
## No `nifstreams`/`nifcursors` types cross this module's boundary: callers pass
## plain Nim values (config, ids, string lists), so it can coexist with the
## still-old-API `ast2nif.nim` during the migration.

import std / [syncio, algorithm]
from std / os import removeFile, moveFile
import options, pathutils, typekeys
import "../dist/nimony/src/lib" / [nifcore, nifcoreparse, nifreader, bif]

# One shared literals pool + tag pool for the whole process — the nifcore
# analogue of the old global `nifstreams.pool`. A single shared pool keeps
# string/symbol/file ids stable across every TokenBuf the IC backend builds,
# preserving the old global-pool semantics during the migration. (Stage 6 may
# move to fresh per-file pools for bif's fast path; see doc/ic_nifcore_port.md.)
let icPool* = newPool()
let icTags* = newTagPool()

proc createIcBuf*(cap = 16): TokenBuf {.inline.} =
  ## A `TokenBuf` bound to the shared IC pools.
  createTokenBuf(cap, icPool, icTags)

proc tagId*(s: string): TagId {.inline.} =
  ## Intern a tag name in the shared tag pool.
  icTags.registerTag(s)

type
  IcBuilder* = object
    ## A thin nifcore `TokenBuf` builder whose surface is *primitive types only*
    ## (strings/ints/floats). It lets the still-old-API `ast2nif.nim` drive a
    ## nifcore buffer without any nifcore type crossing the module boundary —
    ## the bridge that routes IC output onto the nifcore serializer (Stage 2).
    buf*: TokenBuf

proc newIcBuilder*(cap = 16): IcBuilder = IcBuilder(buf: createIcBuf(cap))

proc openTag*(b: var IcBuilder; tag: string) {.inline.} = b.buf.openTag(tagId(tag))
proc closeTag*(b: var IcBuilder) {.inline.} = b.buf.closeTag()
proc addSymUse*(b: var IcBuilder; s: string) {.inline.} = b.buf.addSymUse(s)
proc addSymDef*(b: var IcBuilder; s: string) {.inline.} = b.buf.addSymDef(s)
proc addIdent*(b: var IcBuilder; s: string) {.inline.} = b.buf.addIdent(s)
proc addStrLit*(b: var IcBuilder; s: string) {.inline.} = b.buf.addStrLit(s)
proc addIntLit*(b: var IcBuilder; v: int64) {.inline.} = b.buf.addIntLit(v)
proc addUIntLit*(b: var IcBuilder; v: uint64) {.inline.} = b.buf.addUIntLit(v)
proc addFloatLit*(b: var IcBuilder; v: float64) {.inline.} = b.buf.addFloatLit(v)
proc addCharLit*(b: var IcBuilder; c: char) {.inline.} = b.buf.addCharLit(c)
proc addDotToken*(b: var IcBuilder) {.inline.} = b.buf.addDotToken()

proc lineInfo*(b: var IcBuilder; file: string; line, col: int32; comment = "") =
  ## Attach line info (+ optional `#comment#`) to the head just emitted. No-op
  ## when `file` is empty (matches the old "emit only when info is valid").
  ## Strings are interned in the shared pools; the file/comment ids reproduce
  ## the old `pool.files`/`pool.strings` entries by string value.
  if file.len == 0: return
  let fid = icPool.filenames.getOrIncl(file)
  let cid = if comment.len > 0: icPool.strings.getOrIncl(comment) else: StrId(0)
  b.buf.appendLineInfo(fid, line, col, cid)

proc writeFileStable*(b: var TokenBuf; path: string; onlyIfChanged = false) =
  ## Serialize `b` to canonical module NIF text and write it. Mirrors
  ## `nifcursors.writeFile`: the module suffix is derived from `path`
  ## (`"." & extractModuleSuffix`), and `onlyIfChanged` skips the write when the
  ## on-disk bytes already match — the content-stability nifmake's incremental
  ## rebuild depends on.
  let content = toModuleString(b, "." & extractModuleSuffix(path))
  if onlyIfChanged:
    let existing =
      try: readFile(path)
      except CatchableError: ""
    if existing == content: return
  writeFile(path, content)

proc writeStable*(b: var IcBuilder; path: string; onlyIfChanged = false) {.inline.} =
  writeFileStable(b.buf, path, onlyIfChanged)

proc cursorPool*(c: Cursor): Pool {.inline.} = nifcore.pool(c)
  ## The literals pool the cursor's buffer was built against. `ast2nif.nim`
  ## imports `nifcore` with `except pool` (to keep nifstreams' global `pool`
  ## var the writer uses), so the reader reaches a cursor's pool through here —
  ## needed once `bif`-loaded buffers carry their OWN fresh pool rather than the
  ## shared `icPool`.

proc freshModuleCopy(b: var IcBuilder): TokenBuf =
  ## Re-home `b.buf` into a PRIVATE, module-local pool via `addSubtree` (which
  ## re-interns only the literals/tags this buffer actually uses). `b.buf` is bound
  ## to the process-wide shared `icPool`/`icTags`; storing it directly would embed
  ## the WHOLE shared pool (correct but huge — see `bif.storeToFile`). The copy's
  ## fresh-pool reload reproduces ids verbatim (the bif fresh-pool INVARIANT).
  result = createTokenBuf(b.buf.len, newPool(), newTagPool())
  var c = b.buf.beginRead()
  while c.hasMore:
    addSubtree(result, c)
    skip c

proc storeBif*(b: var IcBuilder; path: string; dottedSuffix: string) =
  ## Persist the buffer as a compact, self-contained binary NIF (`.bif`).
  var fresh = freshModuleCopy(b)
  bif.store(fresh, path, dottedSuffix)

proc storeBifStable*(b: var IcBuilder; path: string; dottedSuffix: string) =
  ## Content-stable `bif` write — the binary analogue of `writeFileStable`'s
  ## `onlyIfChanged`: only replace `path` when the encoded bytes differ, so an
  ## unchanged sidecar keeps its mtime and nifmake prunes the dependent rebuild
  ## cascade. Used for the iface/impl cookies + dep sidecars whose byte-stability
  ## gates incremental builds. (bif encoding is deterministic for a given buffer
  ## under fresh pools, so equal content ⇒ equal bytes.)
  var fresh = freshModuleCopy(b)
  let tmp = path & ".tmp"
  bif.store(fresh, tmp, dottedSuffix)
  let newBytes = readFile(tmp)
  let oldBytes =
    try: readFile(path)
    except CatchableError: ""
  if newBytes == oldBytes:
    removeFile(tmp)
  else:
    moveFile(tmp, path)

# --- subtree splicing (shared pool, so a raw subtree copy is exact) ----------

proc addAll*(dest: var IcBuilder; src: var IcBuilder) =
  ## Append every top-level subtree of `src` into `dest` — the nifcore analogue
  ## of the old `dest.add wholeBuffer` splice.
  var c = src.buf.beginRead()
  while c.hasMore:
    addSubtree(dest.buf, c)
    skip c

proc addStmtsBody*(dest: var IcBuilder; src: var IcBuilder) =
  ## Append the BODY of a `(stmts . . <body> )` builder into `dest`, dropping the
  ## wrapper tag and its two leading dot slots (flags/type) — the nifcore
  ## analogue of the old `for i in 3 ..< content.len-1: dest.add content[i]`.
  var c = src.buf.beginRead()   # at (stmts
  c.into:
    skip c   # flags dot
    skip c   # type dot
    while c.hasMore:
      addSubtree(dest.buf, c)
      skip c

# --- cookie input: a line-info-free logical token list of the module ---------
# The cookie hashers (ast2nif) need a flat, ParRi-bearing, index-addressable
# view of the serialized module. nifcore has no ParRi kind and variable-width
# tokens, so we flatten the buffer here (in the clean nifcore world) into a
# neutral `CookieTok` list — no nifcore type crosses into ast2nif.

type
  CookieKind* = enum
    ckParLe, ckParRi, ckSym, ckSymDef, ckIdent, ckStr, ckInt, ckUInt, ckFloat, ckChar, ckDot
  CookieTok* = object
    kind*: CookieKind
    tag*: string       # ckParLe
    name*: string      # ckSym / ckSymDef
    sym*: uint32       # ckSym / ckSymDef id (identity key)
    str*: string       # ckIdent / ckStr
    ival*: int64
    uval*: uint64
    fval*: float64
    cval*: uint32

proc flattenGo(c: var Cursor; b: TokenBuf; acc: var seq[CookieTok]) =
  while c.hasMore:
    case c.kind
    of TagLit:
      acc.add CookieTok(kind: ckParLe, tag: b.tags.tagName(c.cursorTagId))
      c.into:
        flattenGo(c, b, acc)
      acc.add CookieTok(kind: ckParRi)
    of Symbol:
      acc.add CookieTok(kind: ckSym, name: symName(c, b.pool), sym: uint32(symId(c, b.pool)))
      skip c
    of SymbolDef:
      acc.add CookieTok(kind: ckSymDef, name: symName(c, b.pool), sym: uint32(symId(c, b.pool)))
      skip c
    of Ident:
      acc.add CookieTok(kind: ckIdent, str: strVal(c, b.pool)); skip c
    of StrLit:
      acc.add CookieTok(kind: ckStr, str: strVal(c, b.pool)); skip c
    of IntLit:
      acc.add CookieTok(kind: ckInt, ival: intVal(c)); skip c
    of UIntLit:
      acc.add CookieTok(kind: ckUInt, uval: uintVal(c)); skip c
    of FloatLit:
      acc.add CookieTok(kind: ckFloat, fval: floatVal(c)); skip c
    of CharLit:
      acc.add CookieTok(kind: ckChar, cval: uint32(ord(charLit(c)))); skip c
    of DotToken:
      acc.add CookieTok(kind: ckDot); skip c
    else:
      skip c   # LineInfoLit / ExtendedSuffix ride on heads, never standalone

proc flattenForCookie*(b: var IcBuilder): seq[CookieTok] =
  ## Flatten the nifcore module buffer to the cookie hashers' flat token list.
  result = newSeqOfCap[CookieTok](b.buf.len)
  var cur = b.buf.beginRead()
  flattenGo(cur, b.buf, result)

proc collectBifStrLits*(path: string): seq[string] =
  ## Read a small `(tag "s" "s" …)` bif sidecar (`semdeps`/`edges`) and return every
  ## string literal it holds, in order — the binary analogue of the old nifstreams
  ## scan that collected `StrLit`s. Keeps nifcore types out of `deps.nim`, which
  ## only needs the recorded string list.
  ##
  ## Uses `loadFromFile` (a full read into owned memory) rather than the mmap-backed
  ## `bif.load`, then CLOSES the handle. `bif.load` intentionally leaves the mapping
  ## resident for the process lifetime; for the `nim ic` driver that reads these
  ## sidecars while `nim m` children rewrite them, a lingering read mapping is a
  ## Windows sharing violation: the child's `open(path, fmWrite)` fails with
  ## `IOError: cannot open`. These sidecars are tiny, so the zero-copy mmap buys
  ## nothing here anyway.
  result = @[]
  var f = open(path, fmRead)
  var m = bif.loadFromFile(f)
  close(f)
  var c = m.buf.beginRead()
  while c.hasMore:
    if c.kind == StrLit: result.add strVal(c)
    inc c

proc writeSemDeps*(config: ConfigRef; thisModule: int32; importPaths: seq[string]) =
  ## Stage 1 spike: the nifcore port of `ast2nif.writeSemDeps`. Serializes the
  ## module's resolved direct imports as `(semdeps "path" ...)`. Byte-identical
  ## to the old writer (verified), so `nim ic` build graphs are unaffected.
  let selfSuffix = modname(thisModule, config)
  var paths = importPaths
  sort paths
  var dest = newIcBuilder(4 + 2*paths.len)
  dest.openTag "semdeps"
  for p in paths:
    dest.addStrLit p
  dest.closeTag()
  let path = toGeneratedFile(config, AbsoluteFile(selfSuffix), ".s.deps.bif").string
  storeBifStable(dest, path, "." & extractModuleSuffix(path))
