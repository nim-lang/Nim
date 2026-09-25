## nifstreams — the classic NIF streaming surface, used ONLY by this compiler's
## IC modules: ast2nif, deps, modulegraphs and pipelines import it and must keep
## compiling unchanged across nimony's own refactorings.
##
## It used to live in `dist/nimony/src/lib`, which is where the rest of the NIF
## stack still is. It does not belong there: nimony's own code imports nifpools
## (via nifprelude) and is under standing orders never to import this file, so
## nothing over there ever exercised it — which is exactly how it came to hand
## out `TagLit` where every caller here tests for `ParLe` (see `next`), silently
## emptying the IC build graph. A compatibility shim with exactly one consumer
## belongs in the consumer's repo, where its tests run and its contract is
## somebody's problem.
##
## Everything it adapts (`nifpools`, `nifreader`, `lineinfos`) still comes from
## `dist/nimony`; only the adapter moved.
##
## Everything here is an honest adapter, not a fake:
## * Floats get a REAL interning pool: `pool.floats.getOrIncl` returns a
##   `FloatId` index, `floatToken` packs it into a genuine `FloatLit` NifToken
##   (transit-only: it must never enter a TokenBuf, whose float encoding is
##   inline multi-token), and `pool.floats[t.floatId]` decodes it — lossless.
## * `Stream`/`next` wrap the textual nifreader; the unified NifKind has real
##   `ParLe`/`ParRi`/`EofToken` members, so structural scanners (deps.nim)
##   see the exact classic kinds. Ident/StringLit/Symbol payloads are interned
##   into the global `pool`, so `pool.strings[t.litId]` works as before.
##   Number tokens keep their KIND only (a 4-byte token cannot always carry
##   the value); classic scanners never read those payloads.

import std / tables
import "../dist/nimony/src/lib" / nifpools
# `except`: the frontend went all-NifLineInfo; the classic side keeps speaking
# PackedLineInfo, so nifpools' same-name/same-params variants must not leak
# through (`info(n: NifToken)` differs only in return type, `NoLineInfo` is a
# same-name const of a different type — either would be ambiguous or wrong for
# ast2nif). The classic replacements are defined below / come from lineinfos.
# `tagId` is excluded for a different reason: nifpools decodes the 9-bit field
# of a real `TagLit`, but this surface hands out `ParLe` tokens whose tag id
# fills the whole 28-bit payload (see `next`), so the decode below is the only
# correct one here. The name accessors are excluded because a `.bif`-loaded
# buffer's pool keeps its names in the mapped file until they are read, which
# nifcore's accessors do not know; `icbif` provides them under the same names.
export nifpools except info, NoLineInfo, tagId, symName, strVal, poolSym, poolStr, lineInfoFile
import "../dist/nimony/src/lib" / lineinfos
export lineinfos

from "../dist/nimony/src/lib" / nifreader import Reader, ExpandedToken, decodeStr

# ── Classic names the Nim compiler side still uses ───────────────────────

type
  PackedToken* = NifToken           ## ast2nif still says PackedToken

# Raw payload decodes, sound ONLY on this surface. Every token here comes from
# `next` or the classic `symToken`/`strToken`/`identToken` constructors, which
# intern EVERY literal — including names of at most `StrInlineMaxLen` bytes,
# which the nifcore builders would instead store inside the token. On such an
# inline token the payload is packed bytes, not an id, so nifpools (nimony's own
# surface, where buffers come from the builders) deliberately has no equivalent:
# there it must go through a `Cursor`, which handles both encodings.
proc tagId*(n: NifToken): TagId {.inline.} = TagId(uoperand(n))
  ## Classic `ParLe` tokens (see `next`) keep the tag id in the full 28-bit
  ## payload rather than in `TagLit`'s 9-bit field: `globalTags` already holds
  ## 355 tags before the Nim compiler registers its own dialect, so a 512-tag
  ## ceiling is not a ceiling this surface can live under.
proc litId*(n: NifToken): StrId {.inline.} = StrId(uoperand(n) shr 1)
proc symId*(n: NifToken): SymId {.inline.} = SymId(uoperand(n) shr 1)
proc litId*(c: Cursor): StrId {.inline.} = strId(c)
proc firstSon*(n: Cursor): Cursor {.inline.} = childCursor(n)

var lineMan*: LineInfoManager
  ## The classic packed line-info side channel (`pool.man`). Frontend code no
  ## longer uses it — it lives here purely for ast2nif's writer, which packs
  ## `TLineInfo` into `PackedLineInfo` and unpacks on emit.

template files*(p: Pool): untyped = p.filenames
template tags*(p: Pool): untyped = globalTags.tags
template man*(p: Pool): untyped = lineMan

proc info*(n: NifToken): PackedLineInfo {.inline.} = lineinfos.NoLineInfo
  ## Classic tokens carried their line info inline; a bare 4-byte nifcore
  ## token cannot, so reading it back yields `NoLineInfo` (ast2nif's
  ## `emitInfo(t.info)` then emits nothing — matching the writer, which
  ## attaches real positions at the builder level instead).

proc info*(c: Cursor): PackedLineInfo {.inline.} =
  ## Classic packed view of a cursor's line info (ast2nif shadows this with
  ## its own NifLineInfo template; kept for any other classic reader).
  let li = rawLineInfo(c)
  if li.file.isValid: pack(lineMan, li.file, li.line, li.col)
  else: lineinfos.NoLineInfo

type
  IntId*   = distinct int64         ## value carriers (nifcore stores inline)
  UIntId*  = distinct uint64

  ## Identity proxies: the id already carries the value, `[]` returns it.
  IntegersProxy*  = object
  UIntegersProxy* = object

func `==`*(a, b: IntId): bool {.borrow.}
func `==`*(a, b: UIntId): bool {.borrow.}

template integers*(p: Pool): IntegersProxy = IntegersProxy()
template uintegers*(p: Pool): UIntegersProxy = UIntegersProxy()

template `[]`*(x: IntegersProxy; id: IntId): int64 = int64(id)
template `[]`*(x: UIntegersProxy; id: UIntId): uint64 = uint64(id)

# nifcore stores integers inline: the "id" is the value itself.
template getOrIncl*(x: IntegersProxy; v: int64): IntId = IntId(v)
template getOrIncl*(x: UIntegersProxy; v: uint64): UIntId = UIntId(v)

proc intId*(n: NifToken): IntId {.inline.} = IntId(n.soperand)
proc uintId*(n: NifToken): UIntId {.inline.} = UIntId(uoperand(n))
proc intId*(c: Cursor): IntId {.inline.} = IntId(intVal(c))
proc uintId*(c: Cursor): UIntId {.inline.} = UIntId(uintVal(c))

proc addIntLit*(dest: var TokenBuf; id: IntId; info: PackedLineInfo) =
  addIntLit(dest, int64(id))
  if info.isValid:
    let u = unpack(lineMan, info)
    appendLineInfo(dest, u.file, u.line, u.col)

# Classic single-token constructors with a (dropped) line-info argument.
proc strToken*(s: StrId; info: PackedLineInfo): NifToken {.inline.} = strLitToken(s)
proc symToken*(id: SymId; info: PackedLineInfo): NifToken {.inline.} = symToken(id)
proc identToken*(id: StrId; info: PackedLineInfo): NifToken {.inline.} = identToken(id)
proc dotToken*(info: PackedLineInfo): NifToken {.inline.} = dotToken()
proc charToken*(ch: char; info: PackedLineInfo): NifToken {.inline.} = charToken(ch)

# ── Classic interned float literals (ast2nif) ────────────────────────────

type
  FloatId* = distinct uint32   ## 1-based index into the global float pool
  FloatPool* = object
    values: seq[float64]
    lookup: Table[uint64, uint32]   # bit pattern -> 1-based id

func `==`*(a, b: FloatId): bool {.borrow.}

var globalFloats*: FloatPool

template floats*(p: Pool): var FloatPool = globalFloats

proc getOrIncl*(fp: var FloatPool; v: float64): FloatId =
  let bits = cast[uint64](v)
  let existing = fp.lookup.getOrDefault(bits, 0'u32)
  if existing != 0'u32:
    result = FloatId(existing)
  else:
    fp.values.add v
    let id = uint32(fp.values.len)
    fp.lookup[bits] = id
    result = FloatId(id)

proc `[]`*(fp: FloatPool; id: FloatId): float64 {.inline.} =
  fp.values[int(uint32(id)) - 1]

proc floatToken*(id: FloatId; info: PackedLineInfo): NifToken {.inline.} =
  ## Transit-only token: carries the pool index so the receiver can decode it
  ## via `pool.floats[t.floatId]`. It must never be appended to a TokenBuf
  ## (nifcore stores floats inline as a multi-token encoding); the line info
  ## is dropped like in the other classic token constructors.
  NifToken((uint32(id) shl KindBits) or uint32(FloatLit))

proc floatId*(n: NifToken): FloatId {.inline.} = FloatId(uoperand(n))

# ── Classic streaming text reader (deps.nim) ─────────────────────────────

type
  Stream* = object
    r*: Reader

proc parLeToken*(t: TagId): NifToken {.inline.} =
  ## The classic surface's opening-tag token: kind `ParLe`, tag id in the
  ## payload. Transit-only, like `floatToken` — a `ParLe` never appears in a
  ## binary token stream, so this must not be appended to a TokenBuf.
  NifToken((uint32(t) shl KindBits) or uint32(ParLe))

proc open*(filename: string): Stream =
  Stream(r: nifreader.open(filename))

proc close*(s: var Stream) =
  nifreader.close(s.r)

proc next*(s: var Stream): NifToken =
  ## One classic packed token per call. Pool-referencing kinds are interned
  ## into the global `pool`/`globalTags`, so `.litId`/`.tagId` accessors and
  ## `pool.strings[...]`/`pool.tags[...]` lookups behave exactly as classic
  ## nifstreams did. Kinds without a pool payload come back kind-only.
  var t = default(ExpandedToken)
  nifreader.next(s.r, t)
  case t.tk
  of ParLe:
    # NOT `tagLitToken`: that would set the kind to `TagLit`, and every classic
    # structural scanner tests for `ParLe` (deps.nim walks the import graph that
    # way). Emitting `TagLit` here made every one of those tests silently fail —
    # the scanner saw an unknown token, skipped the subtree, and the Nim
    # compiler's IC build graph came out missing most of its edges.
    result = parLeToken(registerTag(globalTags, decodeStr(s.r, t)))
  of Ident:
    result = identToken(pool.strings.getOrIncl(decodeStr(s.r, t)))
  of StrLit:
    result = strLitToken(pool.strings.getOrIncl(decodeStr(s.r, t)))
  of Symbol:
    result = symToken(pool.syms.getOrIncl(decodeStr(s.r, t)))
  of SymbolDef:
    result = symdefToken(pool.syms.getOrIncl(decodeStr(s.r, t)))
  else:
    # ParRi/EofToken/DotToken/CharLit/numbers: correct kind, no payload.
    result = NifToken(uint32(t.tk))

when isMainModule:
  # `nim c -r compiler/nifstreams.nim`.
  #
  # The promise this checks: structural scanners see the CLASSIC kinds. Nim's deps.nim walks
  # the import graph by testing `t.kind == ParLe` and then reading
  # `pool.tags[t.tagId]`. Hand out nifcore's own `TagLit` instead and every one
  # of those tests falls through silently — the scanner treats the opener as an
  # unknown token, skips the subtree, and Nim's IC build graph comes out missing
  # most of its edges while each individual file still "parses" fine.
  import std / [os, syncio]
  from "../dist/nimony/src/lib" / nifreader import processDirectives
  from std / assertions import assert

  let f = getTempDir() / "nifstreams_selftest.nif"
  syncio.writeFile f, "(.nif27)\n(stmts (import (infix / std (bracket os osproc))) (x \"s\" y))\n"

  var kinds: seq[NifKind] = @[]
  var tagNames: seq[string] = @[]
  var lits: seq[string] = @[]
  var s = nifstreams.open(f)
  discard processDirectives(s.r)
  while true:
    let t = next(s)
    if t.kind == EofToken: break
    kinds.add t.kind
    case t.kind
    of ParLe: tagNames.add pool.tags[t.tagId]
    of Ident, StrLit: lits.add pool.strings[t.litId]
    else: discard
  nifstreams.close(s)
  removeFile f

  assert tagNames == @["stmts", "import", "infix", "bracket", "x"], $tagNames
  assert lits == @["/", "std", "os", "osproc", "s", "y"], $lits
  assert ParRi in kinds, "closers must stay classic too"
  assert TagLit notin kinds, "an opener must arrive as ParLe, not TagLit"
  echo "success"
