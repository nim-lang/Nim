#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The compiler's `.bif` loader: `bif.load`, except that a file's names stay
## in the mapping until they are read.
##
## `bif.load` borrows the token block from the mapping but copies every string,
## symbol and filename out of it into the buffer's pools. A backend process
## opens ~800 `.bif` files and reads names from a fraction of them: on
## nimbus-eth2 that was 2.9M strings, 222MB, 41% of the process's heap
## (`--mm:refc -d:nimTypeNames`). `load` here gives each pool its ids — an
## empty entry per name, so the ids line up with the token stream — and keeps
## per pool where each name's bytes sit in the mapping (`LazyNames`). A name
## is copied into the pool the first time it is read, and a lookup BY VALUE
## hashes and compares the mapped bytes, so nothing is copied to be found.
##
## The pools are nifcore's, and nifcore's own `symName(c)`, `strVal(c)`,
## `poolSym`, `poolStr` and `lineInfoFile(c)` read a pool's entry directly:
## they answer "" for a name that has not been read yet. So a module that
## reads a loaded buffer imports nifcore `except` those five and uses the
## accessors here, which spell the same; importing both makes every call
## ambiguous, so the two cannot be mixed by accident. Nothing interns INTO a
## loaded pool — a loaded buffer is read-only — and nothing may: nifcore's
## `getOrIncl` would build its reverse index over the empty entries.
##
## `-d:icEagerPools` makes `load` the plain `bif.load`, for an A/B; the
## accessors work on an eager pool as they do on any other.

import std / [assertions, hashes, tables, varints]
import "../dist/nimony/src/lib" / [bitabs, lineinfos, vfs]
import "../dist/nimony/src/lib/nifcore" except symName, strVal, poolSym, poolStr, lineInfoFile
from "../dist/nimony/src/lib" / bif import BifModule, IndexEntry, IndexVis

type
  LazyNames = object
    ## One pool's names, still in the mapped file: per id the offset of the
    ## entry's length prefix. The mapping is left in place for the buffer's
    ## lifetime already (`adoptForeignTokens`); this borrows it the same way.
    base: ptr UncheckedArray[char]
    size: int
    offs: seq[uint32]
    keys: seq[uint32]
      ## Reverse index over the mapped bytes, built by the first lookup by
      ## value; `0` is a free slot. A pool nobody looks a name up in never
      ## pays for one.
  LazyPool = ref object
    strings, syms, filenames: LazyNames

proc hash(p: Pool): Hash = hash(cast[pointer](p))

var lazyPools: Table[Pool, LazyPool]
  ## The pools `load` filled, by identity. The table holds the pool, so its
  ## address cannot be reused for another one.

proc lazyOf(p: Pool): LazyPool {.inline.} = lazyPools.getOrDefault(p)

# ── names in the mapping ──────────────────────────────────────────────────

proc bytes(L: LazyNames; idx: int): (int, int) =
  ## Start and length in the mapping of the name with index `idx`.
  let off = int L.offs[idx]
  var n = 0'u64
  let used = readVu64(toOpenArray(cast[ptr UncheckedArray[byte]](L.base),
                                  off, min(off + maxVarIntLen, L.size) - 1), n)
  result = (off + used, int n)

proc fill[Id](t: var BiTable[Id, string]; L: LazyNames; id: Id) =
  ## Copy `id`'s name out of the mapping into `t`.
  let idx = int(uint32(id)) - 1
  if idx < L.offs.len:
    let (start, n) = bytes(L, idx)
    if n > 0:
      var s = newString(n)
      copyMem(addr s[0], addr L.base[start], n)
      t[id] = s

proc index(L: var LazyNames) =
  ## Build `keys`: open addressing, at most half full.
  var cap = 16
  while cap < L.offs.len * 2: cap = cap * 2
  L.keys = newSeq[uint32](cap)
  let mask = cap - 1
  for i in 0 ..< L.offs.len:
    let (start, n) = bytes(L, i)
    var h = hash(toOpenArray(L.base, start, start + n - 1)) and mask
    while L.keys[h] != 0'u32: h = (h + 1) and mask
    L.keys[h] = uint32(i + 1)

proc find(L: var LazyNames; name: string): uint32 =
  ## The id of `name` among the names in the mapping, or 0.
  result = 0'u32
  if L.offs.len == 0: return
  if L.keys.len == 0: index(L)
  let mask = L.keys.len - 1
  var h = hash(toOpenArray(name, 0, name.high)) and mask
  while true:
    let id = L.keys[h]
    if id == 0'u32: return 0'u32
    let (start, n) = bytes(L, int(id) - 1)
    if n == name.len and (n == 0 or equalMem(unsafeAddr name[0], addr L.base[start], n)):
      return id
    h = (h + 1) and mask

# ── reading a name ────────────────────────────────────────────────────────
# Each accessor reads the pool's entry, and only when that is empty asks
# whether the pool is one of ours and copies the name in; a name already read
# costs what it costs nifcore.

proc poolSym*(p: Pool; id: SymId): string =
  ## `nifcore.poolSym`, for a pool whose names may still be in the file.
  result = p.syms[id]
  if result.len == 0:
    let L = lazyOf(p)
    if L != nil:
      fill(p.syms, L.syms, id)
      result = p.syms[id]

proc poolStr*(p: Pool; id: StrId): string =
  ## `nifcore.poolStr`, for a pool whose names may still be in the file.
  result = p.strings[id]
  if result.len == 0:
    let L = lazyOf(p)
    if L != nil:
      fill(p.strings, L.strings, id)
      result = p.strings[id]

proc poolFile*(p: Pool; id: FileId): string =
  ## The filename `id` of `p`, for a pool whose names may still be in the file.
  result = p.filenames[id]
  if result.len == 0:
    let L = lazyOf(p)
    if L != nil:
      fill(p.filenames, L.filenames, id)
      result = p.filenames[id]

proc symName*(c: Cursor): string =
  ## `nifcore.symName`, for a buffer whose pool may still hold the name in
  ## the file. An inline name lives in the token and touches no pool.
  if isInlineLit(c): nifcore.symName(c)
  else:
    let p = nifcore.pool(c)
    poolSym(p, nifcore.symId(c, p))

proc strVal*(c: Cursor): string =
  ## `nifcore.strVal`, for a buffer whose pool may still hold the string in
  ## the file.
  if isInlineLit(c): nifcore.strVal(c)
  else:
    let p = nifcore.pool(c)
    poolStr(p, nifcore.strId(c, p))

proc lineInfoFile*(c: Cursor): string =
  ## `nifcore.lineInfoFile`, for a buffer whose pool may still hold the
  ## filename in the file.
  let li = rawLineInfo(c)
  let p = nifcore.pool(c)
  if li.file.isValid and p != nil: poolFile(p, li.file) else: ""

proc findSym*(p: Pool; name: string): SymId =
  ## `getKeyId(p.syms, name)`, for a pool whose names may still be in the
  ## file: the lookup hashes and compares the mapped bytes, and builds its
  ## index on the first lookup INTO THIS POOL.
  let L = lazyOf(p)
  if L != nil:
    result = SymId find(L.syms, name)
  else:
    ensureIndexed(p.syms)
    result = getKeyId(p.syms, name)

# ── loading ───────────────────────────────────────────────────────────────
# Mirrors `bif.load` byte for byte — the header, the pad before the token
# block, the pools in id order, the index — so the two must agree on the
# format; `bif.Version` bumps show up here as a "bad magic".

const
  Magic = ['N', 'I', 'F', 'B', 'I', 'N', '\0', '\5']

type
  Reader = object
    base: ptr UncheckedArray[char]
    pos, size: int

proc rU64(r: var Reader): uint64 =
  assert r.pos + 8 <= r.size, "bif: truncated header"
  result = cast[ptr uint64](addr r.base[r.pos])[]
  r.pos += 8

proc rVarint(r: var Reader): uint64 =
  assert r.pos + 1 <= r.size, "bif: truncated varint"
  result = 0'u64
  r.pos += readVu64(toOpenArray(cast[ptr UncheckedArray[byte]](r.base),
                                r.pos, min(r.pos + maxVarIntLen, r.size) - 1), result)

proc rStr(r: var Reader): string =
  let n = int rVarint(r)
  assert r.pos + n <= r.size, "bif: truncated string"
  result = newString(n)
  if n > 0: copyMem(addr result[0], addr r.base[r.pos], n)
  r.pos += n

proc rNames[Id](r: var Reader; t: var BiTable[Id, string]; n: int): LazyNames =
  ## Give `t` an empty entry for each of the next `n` names, and record where
  ## each name is.
  result = LazyNames(base: r.base, size: r.size, offs: newSeqOfCap[uint32](n))
  for _ in 1 .. n:
    result.offs.add uint32(r.pos)
    let len = int rVarint(r)
    assert r.pos + len <= r.size, "bif: truncated string"
    r.pos += len
    discard t.addOrdered("")

proc load*(filename: string): BifModule =
  ## `bif.load`, with the string, symbol and filename pools left in the
  ## mapping. Tags are few and always read, and stay eager.
  when defined(icEagerPools):
    result = bif.load(filename)
  else:
    let blob = vfsOpenMmap(filename)      # left mapped for the buffer's lifetime
    var r = Reader(base: cast[ptr UncheckedArray[char]](blob.data), pos: 0, size: blob.size)
    assert r.size >= Magic.len, "bif: file too small"
    for i in 0 ..< Magic.len:
      if r.base[i] != Magic[i]:
        quit "bif: bad magic / incompatible format: " & filename
    assert r.size <= int(high(uint32)), "bif: file too large: " & filename
    r.pos = Magic.len
    discard rU64(r)                       # indexOffset; a full load reaches it linearly
    let tokenCount = int rVarint(r)
    let nTags      = int rVarint(r)
    let nStrings   = int rVarint(r)
    let nSyms      = int rVarint(r)
    let nFiles     = int rVarint(r)
    # the pad that keeps the borrowed token block `NifToken`-aligned
    let a = sizeof(NifToken)
    r.pos += (a - (r.pos and (a - 1))) and (a - 1)
    let tokenBytes = tokenCount * sizeof(NifToken)
    assert r.pos + tokenBytes <= r.size, "bif: truncated token block"
    result = BifModule(buf: adoptForeignTokens(addr r.base[r.pos], tokenCount))
    r.pos += tokenBytes
    for _ in 1 .. nTags: discard result.buf.tags.tags.addOrdered(rStr(r))
    let lazy = LazyPool()
    lazy.strings = rNames(r, result.buf.pool.strings, nStrings)
    lazy.syms = rNames(r, result.buf.pool.syms, nSyms)
    lazy.filenames = rNames(r, result.buf.pool.filenames, nFiles)
    lazyPools[result.buf.pool] = lazy
    let nIndex = int rVarint(r)
    result.index = newSeq[IndexEntry](nIndex)
    for i in 0 ..< nIndex:
      let sym = SymId rVarint(r)
      let pos = int32(rVarint(r))
      let v = int rVarint(r)
      result.index[i] = IndexEntry(sym: sym, pos: pos, vis: IndexVis(v))
