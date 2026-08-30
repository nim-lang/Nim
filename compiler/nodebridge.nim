#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## `PNode` <-> `TokenBuf`, in one process.
##
## WHY THIS EXISTS. The backend splits in two along a line that is not the one
## the migration to `BNode` was drawn along. Passes that REWRITE — transf,
## destructor injection, closure lifting, the tree the code generator builds as
## it goes — construct new nodes, and a `Cursor` is a read cursor into a shared
## token buffer, so they cannot be expressed against it and there is no reason
## to try. Passes that READ want the cursor. The bridge is the seam between
## them: a rewriting pass keeps producing a `PNode`, and anything that only
## reads gets a `TokenBuf`, from which a `Cursor` — and so a `BNode` — is a
## pointer.
##
## HOW IT DIFFERS FROM THE `.bif` FORMAT, and why that is the point. A `.bif`
## is read by a DIFFERENT PROCESS, so every symbol and type has to be written as
## a NAME the reader can look up again. A bridged buffer is read by the process
## that built it, so it does not: a symbol reference is `(bsym <idx>)`, an index
## into a side table holding the very `PSym` the encoder was handed, and the
## type slot is `(btyp <idx>)` the same way.
##
## Three consequences, and the middle one is the reason to prefer this over
## routing rewrites back through the file format:
##
## * It is LOSSLESS. No name mangling, no module index, no stubs, so nothing can
##   be lost or renamed on the way through. `toPNode(toTokenBuf(n))` is `n`
##   again, and `cgen`'s grinder checks the stronger property — that the cursor
##   answers identically to the ORIGINAL `PNode` at every node, with no
##   tolerated differences at all, unlike the file path which needs two.
## * `sym` IS IDEMPOTENT HERE, FIELDS INCLUDED. On the file path it is not, and
##   cannot be: a cross-context field reference has no index entry, so
##   `loadFieldStub` mints a fresh `skField` stub per use because two distinct
##   fields can share a name and a position across types. That is what blocks
##   `aliases.isPartOf` from moving to the seam (see `bnode.sym`). A bridged
##   buffer hands back the same object every time, so code that compares field
##   identity is correct on it.
## * It is cheap. No string formatting, no pool lookups for names, no index
##   seeks — the encoder is a tree walk and two `seq.add`s.
##
## WHAT IT IS NOT. The buffer is transient and process-local: `(bsym …)` means
## nothing without the tables beside it, so a bridged buffer must never be
## written to a file. The `.bif` writer in `ast2nif` is still the only thing
## that serializes, and it is a different job — it has to name things precisely
## because the reader cannot see this process's heap.
##
## USE:
##
##   var b = toTokenBuf(n, conf)
##   withBridge(b.tables):
##     let root = BNode(b.rootCursor)  # read it like any other `BNode`
##     ...
##   let back = toPNode(b)             # a fresh `PNode` tree, if a rewrite needs one
##
## `withBridge` and `BNode` live in `bnode.nim` and exist only under
## `-d:newIcBackend`; this module is below that seam and does not depend on it,
## so the encoder and the round trip are usable either way.

import std / tables

import ast, astdef, idents, options, msgs, lineinfos
import icnifcore, ast2nif
import ic / enum2nif

import "../dist/nimony/src/lib/nifcore" except pool

import bodynav

when defined(nimPreviewSlimSystem):
  import std / assertions

type
  BridgeBuf* = object
    ## An encoded tree plus everything needed to read it back. Not copyable —
    ## it owns a `TokenBuf`.
    bld*: IcBuilder
    tables*: BridgeTables
    conf: ConfigRef
    symIdx: Table[int, int]    ## PSym identity -> index into `tables.syms`
    typeIdx: Table[int, int]   ## PType identity -> index into `tables.types`
    origins: Table[int, PNode] ## token position -> the `PNode` encoded there

proc initBridgeBuf*(conf: ConfigRef; cap = 64): BridgeBuf =
  BridgeBuf(bld: newIcBuilder(cap), tables: BridgeTables(), conf: conf,
            symIdx: initTable[int, int](), typeIdx: initTable[int, int](),
            origins: initTable[int, PNode]())

# ---------------------------------------------------------------------------
# Encode
#
# The shape mirrors the `.bif` node encoding exactly — `(<kind> <flags> <type>
# <child|payload>…)` — so `bnode` reads a bridged buffer with the accessors it
# already has. Only the two leaves that would have been NAMES differ.

proc symIndex(b: var BridgeBuf; s: PSym): int =
  ## Symbols are deduplicated by identity, so the same `PSym` referenced twenty
  ## times costs one table slot and twenty equal indices — which is also what
  ## makes `sym` idempotent on the way back.
  let key = cast[int](s)
  result = b.symIdx.getOrDefault(key, -1)
  if result < 0:
    result = b.tables.syms.len
    b.tables.syms.add s
    b.symIdx[key] = result

proc typeIndex(b: var BridgeBuf; t: PType): int =
  let key = cast[int](t)
  result = b.typeIdx.getOrDefault(key, -1)
  if result < 0:
    result = b.tables.types.len
    b.tables.types.add t
    b.typeIdx[key] = result

proc emitInfo(b: var BridgeBuf; info: TLineInfo) =
  ## Line info goes through the SAME filename pool the `.bif` writer uses
  ## (`icPool.filenames`, keyed by full path), so `bnode.info` — which resolves
  ## through the decoder's `oldLineInfo` — needs no bridge-specific path.
  if info == unknownLineInfo: return
  b.bld.lineInfo(msgs.toFullPath(b.conf, info.fileIndex),
                 info.line.int32, info.col.int32)

proc emitFlags(b: var BridgeBuf; flags: TNodeFlags) =
  var asIdent = ""
  genFlags(flags, asIdent)
  if asIdent.len > 0: b.bld.addIdent asIdent
  else: b.bld.addDotToken()

proc emitTypeSlot(b: var BridgeBuf; t: PType) =
  if t == nil:
    b.bld.addDotToken()
  else:
    b.bld.openTag bridgeTypeTagName
    b.bld.addIntLit typeIndex(b, t).int64
    b.bld.closeTag()

proc encodeNode(b: var BridgeBuf; n: PNode)

proc encodeSym(b: var BridgeBuf; n: PNode) =
  ## `(nflags <flags> (ht <type> (bsym <idx>)))`, always the full chain.
  ##
  ## The wrappers are unconditional on purpose. The `.bif` writer emits them
  ## only when the node differs from its symbol, which is what creates the
  ## `(ht . <sym>)` shape whose nil is load-bearing and whose meaning depends on
  ## whether the symbol was loaded yet — a real ambiguity that cost a reverted
  ## commit on this branch. A bridge has no reason to inherit it: spelling the
  ## node's own type and flags out every time costs four tokens and makes the
  ## answer exact by construction.
  b.bld.openTag symNodeFlagsTagName
  b.emitInfo(n.info)
  b.emitFlags(n.flags)
  b.bld.openTag hiddenTypeTagName
  b.emitTypeSlot(n.typ)          # the LAZY-AWARE accessor: what `ast.typ` says
  b.bld.openTag bridgeSymTagName
  b.bld.addIntLit symIndex(b, n.sym).int64
  b.bld.closeTag()               # bsym
  b.bld.closeTag()               # ht
  b.bld.closeTag()               # nflags

proc encodeNode(b: var BridgeBuf; n: PNode) =
  if n == nil:
    # A nil child is a `DotToken` and has no origin: there is no node to
    # remember, and `originOf` answering nil for it is the right answer.
    b.bld.addDotToken()
    return
  # ORIGIN TRACKING. `len` is where this node's head token is about to land, and
  # `cursorToPosition` is its inverse — nifcore documents that index as a stable
  # key for exactly this. Recording it is what keeps `TLoc.lode` a `PNode`: a
  # cursor-driven generator can still put the ORIGINAL node in a location, so
  # the identity comparisons that already exist (`preventNrvo`'s `dest != le`,
  # `isPartOf(d.lode, …)`) keep meaning what they meant. Without this the
  # generator could not migrate without `TLoc` itself changing representation —
  # and `TLoc` lives in `astdef`, at the bottom of the module graph, so that
  # would push the seam far below the backend.
  b.origins[b.bld.buf.len] = n
  if n.kind == nkSym and n.sym != nil:
    encodeSym(b, n)
    return
  b.bld.openTag toNifTag(n.kind)
  b.emitInfo(n.info)
  b.emitFlags(n.flags)
  b.emitTypeSlot(n.typ)
  case n.kind
  of nkCharLit:
    b.bld.addCharLit char(n.intVal)
  of nkIntLit..nkInt64Lit:
    b.bld.addIntLit n.intVal
  of nkUIntLit..nkUInt64Lit:
    b.bld.addUIntLit cast[uint64](n.intVal)
  of nkFloatLit..nkFloat128Lit:
    b.bld.addFloatLit n.floatVal
  of nkStrLit..nkTripleStrLit:
    b.bld.addStrLit n.strVal
  of nkIdent:
    b.bld.addIdent n.ident.s
  of nkSym:
    # `n.sym == nil`, which `encodeSym` cannot express. It is a broken node
    # either way; encode it as a childless `nkSym` so the walk stays total.
    discard
  of nkNone, nkEmpty, nkNilLit, nkType, nkCommentStmt:
    discard
  else:
    for child in sons(n): encodeNode(b, child)
  b.bld.closeTag()

proc toTokenBuf*(n: PNode; conf: ConfigRef): BridgeBuf =
  ## Encode a whole tree. `n` is not modified and not retained: the buffer holds
  ## tokens, and the tables hold the `PSym`/`PType` objects the tree pointed at.
  result = initBridgeBuf(conf)
  encodeNode(result, n)

proc originOf*(b: var BridgeBuf; c: Cursor): PNode =
  ## The `PNode` that was encoded at `c`, or nil when `c` is a `DotToken` (a nil
  ## child) or does not point at a node head. Identity-preserving: this is the
  ## very object the encoder was handed, not a copy, which is the whole point.
  b.origins.getOrDefault(cursorToPosition(b.bld.buf, c), nil)

proc rootCursor*(b: var BridgeBuf): Cursor {.inline.} =
  ## A read cursor at the encoded root. `beginRead` asserts every tag was
  ## closed, so a mis-nested encode is caught here rather than as nonsense
  ## further along.
  beginRead(b.bld.buf)

# ---------------------------------------------------------------------------
# Decode
#
# The other direction, for a rewriting pass that has a cursor and needs a tree
# it can mutate. Deliberately NOT written against `bnode`: this module is below
# it (`bnode` reads through a nav, which is exactly the state a decoder should
# not need), and the shape is the encoder's, right here, so the two stay
# legible as a pair.

proc decodeNode(b: BridgeBuf; c: var Cursor): PNode

proc decodeTypeSlot(b: BridgeBuf; c: var Cursor): PType =
  if nifcore.kind(c) == DotToken:
    result = nil
    skip c
  else:
    doAssert nifcore.kind(c) == TagLit and
             c.tags.tagName(cursorTagId(c)) == bridgeTypeTagName,
             "bridge: type slot expected"
    let payload = childCursor(c)
    doAssert nifcore.kind(payload) == IntLit, "bridge: (btyp) payload expected"
    let idx = int(nifcore.intVal(payload))
    doAssert idx < b.tables.types.len, "bridge: type index out of range"
    result = b.tables.types[idx]
    skip c

proc decodeFlags(c: var Cursor): TNodeFlags =
  result = nodeFlagsFromCursor(c)
  skip c

proc decodeSym(b: BridgeBuf; c: var Cursor): PNode =
  ## Unwinds exactly what `encodeSym` wrote.
  var outer = childCursor(c)             # inside (nflags
  let flags = decodeFlags(outer)
  doAssert nifcore.kind(outer) == TagLit and
           outer.tags.tagName(cursorTagId(outer)) == hiddenTypeTagName,
           "bridge: (ht) expected inside (nflags)"
  var ht = childCursor(outer)            # inside (ht
  let typ = decodeTypeSlot(b, ht)
  doAssert nifcore.kind(ht) == TagLit and
           ht.tags.tagName(cursorTagId(ht)) == bridgeSymTagName,
           "bridge: (bsym) expected inside (ht)"
  let payload = childCursor(ht)
  doAssert nifcore.kind(payload) == IntLit, "bridge: (bsym) payload expected"
  let idx = int(nifcore.intVal(payload))
  doAssert idx < b.tables.syms.len, "bridge: sym index out of range"
  result = newSymNode(b.tables.syms[idx], lineInfoFromCursor(program, c))
  result.typField = typ
  result.flags = flags
  skip c

proc decodeNode(b: BridgeBuf; c: var Cursor): PNode =
  case nifcore.kind(c)
  of DotToken:
    result = nil
    skip c
  of TagLit:
    let tag = c.tags.tagName(cursorTagId(c))
    if tag == symNodeFlagsTagName:
      return decodeSym(b, c)
    let kind = parse(TNodeKind, tag)
    let info = lineInfoFromCursor(program, c)
    var inner = childCursor(c)
    let flags = decodeFlags(inner)
    let typ = decodeTypeSlot(b, inner)
    result = newNodeI(kind, info)
    result.flags = flags
    result.typField = typ
    case kind
    of nkCharLit..nkUInt64Lit:
      result.intVal =
        case nifcore.kind(inner)
        of CharLit: BiggestInt(ord(charLit(inner)))
        of UIntLit: cast[BiggestInt](nifcore.uintVal(inner))
        else: BiggestInt(nifcore.intVal(inner))
    of nkFloatLit..nkFloat128Lit:
      result.floatVal = nifcore.floatVal(inner)
    of nkStrLit..nkTripleStrLit:
      result.strVal = strVal(inner)
    of nkIdent:
      result.ident = identFromCursor(program, inner)
    else:
      while inner.hasMore:
        result.sons.add decodeNode(b, inner)
    skip c
  else:
    raiseAssert "bridge: unexpected token " & $nifcore.kind(c)

proc toPNode*(b: var BridgeBuf): PNode =
  ## The tree the buffer encodes, as fresh `PNode`s sharing the ORIGINAL
  ## `PSym`s and `PType`s. Round-tripping is therefore identity-preserving for
  ## symbols and types and structure-preserving for everything else, which is
  ## what a rewriting pass needs: it can rebuild a subtree without the symbols
  ## underneath it changing identity.
  var c = rootCursor(b)
  result = decodeNode(b, c)
