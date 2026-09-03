#
#
#           The Nim Compiler
#        (c) Copyright 2025 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## AST to NIF bridge.

import std / [assertions, tables, sets]
from std / strutils import startsWith, endsWith, contains
from std / os import fileExists, dirExists, walkFiles, existsEnv,
  commandLineParams, getCurrentProcessId
from std / exitprocs import addExitProc
from std / syncio import readFile, stderr, writeLine
from std / algorithm import sort
import "../dist/checksums/src/checksums" / sha1
import astdef, idents, msgs, options
import lineinfos as astli
import pathutils #, modulegraphs
import nifstreams
import "../dist/nimony/src/lib" / [bitabs, lineinfos,
  nifindexes, nifreader]
# Step 2b: the READER speaks nifcore; the WRITER keeps nifstreams (global `pool`,
# PackedToken/PackedLineInfo). nifstreams does NOT export Cursor/TokenBuf/NifKind,
# so those resolve unambiguously to nifcore. `except pool`: nifcore's
# `pool(c: Cursor)` accessor would shadow nifstreams' global `pool` var the writer
# uses; the reader reaches pools via `symName(c)`/`strVal(c)` etc.
import "../dist/nimony/src/lib/nifcore" except pool
from "../dist/nimony/src/lib" / bif import load, BifModule, IndexVis, ivHidden
import icmodnames
import "../dist/nimony/src/models" / nifindex_tags
import typekeys
import icnifcore
import ic / [enum2nif]
import icprof

const SysModuleSuffix* = "@sys"
const BackendLocalMarker* = "@bk"
  ## Suffix marker for a PROCESS-LOCAL backend-minted entity (a closure `:env`
  ## type/obj/field/hidden-param minted while the VM compiles a routine body to
  ## run a macro). Such entities have no stable cross-process identity, so each
  ## module that references one emits its OWN module-local def named
  ## `…<thisModuleSuffix>@bk` and the loader homes it to the reading module with
  ## a `backendItemId` (disjoint from real ids). See transf.transformBody.
  ## Reserved module-suffix sentinel for module-less magic singleton types — the
  ## `nil` type is created via `newSysType` with the graph idgen, whose `module`
  ## can be `-1` (e.g. during VM const-eval before a real module is current), so
  ## its `itemId.module` is unresolvable. Such a type has no fields and an
  ## identity that is fully captured by its kind, so we serialize it with this
  ## sentinel and reconstruct it on load (see `createTypeStub`) without ever
  ## touching a `.nif` file. A real `moduleSuffix` never starts with '@'.

proc typeToNifSym(typ: PType; config: ConfigRef): string =
  # NOTE: `itemId` is THE identity of a type and is unique per instance, so a
  # NIF type name is too. (A replica shares only `bindingId`, see ast.nim.)
  assert not typ.itemId.isBackendMinted
  result = "`t"
  result.addInt ord(typ.kind)
  result.add '.'
  result.addInt typ.itemId.item
  result.add '.'
  if typ.itemId.module < 0:
    result.add SysModuleSuffix
  else:
    result.add modname(typ.itemId.module, config)

proc icNifTypeName*(typ: PType; config: ConfigRef): string =
  ## The serialized NIF name of a type, recorded next to RTTI data
  ## definitions in the cnif artifact so a later run can re-demand the
  ## typeinfo when a reused TU still references it (the def-retention
  ## check). Backend-minted types have no NIF name.
  if typ != nil and not typ.itemId.isBackendMinted:
    result = typeToNifSym(typ, config)
  else:
    result = ""

proc toHookIndexEntry*(config: ConfigRef; typeId: ItemId; hookSym: PSym): HookIndexEntry =
  ## Converts a type ItemId and hook symbol to a HookIndexEntry for the NIF index.
  let typeSymName = "`t" & $typeId.item & "." & cachedModuleSuffix(config, typeId.module.FileIndex)
  let hookSymName = hookSym.name.s & "." & $hookSym.disamb & "." & cachedModuleSuffix(config, hookSym.itemId.module.FileIndex)
  let typSymId = pool.syms.getOrIncl(typeSymName)
  let hookSymId = pool.syms.getOrIncl(hookSymName)
  # Check if it's a generic hook (has non-empty generic params)
  let isGeneric = hookSym.astImpl != nil and hookSym.astImpl.len > genericParamsPos and
                  hookSym.astImpl[genericParamsPos].kind != nkEmpty
  result = HookIndexEntry(typ: typSymId, hook: hookSymId, isGeneric: isGeneric)

proc toConverterIndexEntry*(config: ConfigRef; converterSym: PSym): (nifstreams.SymId, nifstreams.SymId) =
  ## Converts a converter symbol to an index entry (destType, converterSym).
  ## Returns the destination type's SymId and the converter's SymId.
  # Get the return type of the converter (destination type)
  let retType = converterSym.typImpl
  if retType != nil and retType.sonsImpl.len > 0:
    let destType = retType.sonsImpl[0]  # Return type is first son
    if destType != nil:
      let destTypeSymName = "`t" & $destType.itemId.item & "." & cachedModuleSuffix(config, destType.itemId.module.FileIndex)
      let convSymName = converterSym.name.s & "." & $converterSym.disamb & "." & cachedModuleSuffix(config, converterSym.itemId.module.FileIndex)
      result = (pool.syms.getOrIncl(destTypeSymName), pool.syms.getOrIncl(convSymName))
      return
  # Fallback: return empty entry
  result = (nifstreams.SymId(0), nifstreams.SymId(0))

proc toMethodIndexEntry*(config: ConfigRef; methodSym: PSym; signature: string): (nifstreams.SymId, nifstreams.StrId) =
  ## Converts a method symbol/signature to a method index entry.
  let methodSymName = methodSym.name.s & "." & $methodSym.disamb & "." & cachedModuleSuffix(config, methodSym.itemId.module.FileIndex)
  result = (
    pool.syms.getOrIncl(methodSymName),
    pool.strings.getOrIncl(signature)
  )

proc toClassSymId*(config: ConfigRef; typeId: ItemId): nifstreams.SymId =
  ## Converts a type ItemId to its SymId for the class index.
  let typeSymName = "`t" & $typeId.item & "." & cachedModuleSuffix(config, typeId.module.FileIndex)
  result = pool.syms.getOrIncl(typeSymName)

# ---------------- Line info handling -----------------------------------------

type
  LineInfoWriter = object
    # `fileK`/`fileV` cache the most recently resolved (FileIndex -> FileId) pair,
    # faster than the hash table. `fileK` MUST be constructed at an invalid
    # sentinel (see `newLineInfoWriter`), never zero: `FileIndex(0)` is a real file
    # index, and `fileV` zero-inits to `FileId(0)` == `NoFile`, so a zero `fileK`
    # would make the first lookup of the module-at-index-0 falsely hit this cache
    # and return `NoFile` — silently dropping ALL of that module's line info.
    fileK: FileIndex
    fileV: FileId
    tab: Table[FileIndex, FileId]
    revTab: Table[FileId, FileIndex] # reverse mapping for oldLineInfo
    man: LineInfoManager
    config: ConfigRef
    # The READ direction's cache, which `revTab` cannot serve: `revTab` is keyed
    # by a `FileId` in the WRITER's global `pool.files`, while a decoded token's
    # `FileId` indexes the buffer's OWN filename pool. So the cache has to be
    # keyed by (pool, FileId), and it is a `seq` because `FileId`s are small and
    # dense within one pool. `readPool` holds a REFERENCE rather than a raw
    # pointer on purpose: it keeps the pool alive, so a freed pool cannot be
    # replaced by a new one at the same address and silently answer from the
    # wrong file table.
    readPool: Pool
    readTab: seq[FileIndex]

proc newLineInfoWriter(config: ConfigRef): LineInfoWriter =
  # `fileK` starts invalid so the one-entry cache never collides with a real
  # `FileIndex(0)` (see the type's doc comment).
  LineInfoWriter(config: config, fileK: astli.InvalidFileIdx)

proc get(w: var LineInfoWriter; key: FileIndex): FileId =
  if w.fileK == key:
    result = w.fileV
  else:
    if key in w.tab:
      result = w.tab[key]
      w.fileK = key
      w.fileV = result
    else:
      result = pool.files.getOrIncl(msgs.toFullPath(w.config, key))
      w.fileK = key
      w.fileV = result
      w.tab[key] = result
      w.revTab[result] = key

proc nifLineInfo(w: var LineInfoWriter; info: TLineInfo): PackedLineInfo =
  if info == unknownLineInfo:
    result = NoLineInfo
  else:
    let fid = get(w, info.fileIndex)
    # Must use pool.man since toString uses pool.man to unpack
    result = pack(pool.man, fid, info.line.int32, info.col)

proc nifLineInfoWithComment(w: var LineInfoWriter; info: TLineInfo; doc: string): PackedLineInfo =
  ## Like `nifLineInfo` but also attaches `doc` as a NIF `#…#` comment on the
  ## token. Used to carry `##` doc comments, which the AST serialization itself
  ## drops, across a NIF round-trip (the loader reads it back off the info).
  if doc.len == 0:
    result = nifLineInfo(w, info)
  else:
    let cid = pool.strings.getOrIncl(doc).uint32
    if info == unknownLineInfo:
      result = packWithComment(pool.man, NoFile, 0'i32, 0'i32, cid)
    else:
      let fid = get(w, info.fileIndex)
      result = packWithComment(pool.man, fid, info.line.int32, info.col, cid)

proc oldLineInfo(w: var LineInfoWriter; info: NifLineInfo; p: Pool): TLineInfo =
  ## Step 2b: the reader's line info arrives as a nifcore `NifLineInfo`; resolve
  ## it to a `TLineInfo`. `info.file` indexes the loaded buffer's OWN filename
  ## pool `p` (= `cursorPool(n)`), which is the shared `icPool` for a text-parsed
  ## module but a fresh per-file pool for a `bif`-loaded one.
  ##
  ## Memoized per pool. Resolving a name costs a string copy out of the pool
  ## plus a hash of a full path, and the generator asks for a node's line info
  ## on essentially every statement it emits — 259k times on a 68-module build,
  ## which was 1.36s of the 1.88s the cursor-driven generator spent.
  if info.file == NoFile:
    result = unknownLineInfo
  else:
    if p != w.readPool:
      w.readPool = p
      w.readTab = @[]
    let id = int(uint32(info.file))
    if id >= w.readTab.len:
      let oldLen = w.readTab.len
      w.readTab.setLen(id + 1)
      for i in oldLen ..< w.readTab.len: w.readTab[i] = astli.InvalidFileIdx
    if w.readTab[id] == astli.InvalidFileIdx:
      w.readTab[id] = msgs.fileInfoIdx(w.config, AbsoluteFile p.filenames[info.file])
    result = TLineInfo(line: info.line.uint16, col: info.col.int16,
                       fileIndex: w.readTab[id])


# ------------- Writer ---------------------------------------------------------------

#[

Strategy:

We produce NIF from the PNode structure as the single source of truth. NIF nodes can
however, refer to PSym and PType, these get NIF names. If the PSym/PType belongs to
the module that we are currently writing, we emit these fields as an inner NIF
structure via the special tags `sd` and `td`. In fact it is only these tags
that get the NIF `SymbolDef` kinds so that the lazy loading mechanism cannot
be confused.

We could also emit non-local symbols and types later as the index structure
will tell us the precise offsets anyway.

]#

const
  hiddenTypeTagName* = "ht"
  symDefTagName* = "sd"
  typeDefTagName* = "td"
  bindingIdTagName = "bid"

  bridgeSymTagName* = "bsym"
    ## `(bsym <intlit>)` — a symbol reference in the IN-PROCESS bridge format
    ## (`nodebridge.nim`), where the payload is an INDEX into the bridge's own
    ## `seq[PSym]` rather than a NIF name. Never written to a file: a `.bif` has
    ## to name symbols because the reader is a different process, but a bridged
    ## buffer is read by the process that built it, so it can hand back the very
    ## same `PSym` object. That is what makes the bridge lossless, and
    ## incidentally what makes `sym` idempotent for FIELDS on a bridged buffer —
    ## the file path cannot be, because `loadFieldStub` mints per use.
  bridgeTypeTagName* = "btyp"
    ## `(btyp <intlit>)` — the same for a node's type slot.

var
  sdefTag = registerTag(symDefTagName)
  tdefTag = registerTag(typeDefTagName)
  hiddenTypeTag = registerTag(hiddenTypeTagName)
  bindingIdTag = registerTag(bindingIdTagName)

type
  Writer = object
    deps: IcBuilder  # include&import deps
    infos: LineInfoWriter
    currentModule: int32
    decodedFileIndices: HashSet[FileIndex]
    locals: HashSet[ItemId]  # track proc-local symbols
    inProc: int
    writtenTypes: seq[PType]  # types sealed during a non-owning emit
    writtenSyms: seq[PSym]    # reset afterwards so their owner can keep using them
    writtenPackages: HashSet[string]
    depSuffixes: HashSet[string]  # module suffixes already emitted as `(import ...)` deps
    emittedBackendTypes: HashSet[(int32, int32)]  # backend-local types already def'd this
                         # module, keyed by (kind, item): the NIF name is `t<kind>.<item>.<mod>@bk`,
                         # so two `@bk` types sharing an item but differing in kind (e.g. `int`
                         # and `typedesc[int]`, both item 12) are DISTINCT defs — keying by item
                         # alone deduped the second to a dangling `SymUse` (`symbol has no offset`).
    emittedBackendSyms: HashSet[int32]   # backend-local sym items already def'd this module
    lowering: bool  # serializing the `lower` stage's whole-module `.t.nif`
    emittedFieldSyms: HashSet[ItemId]    # lowering: derived env-field syms already def'd
    inTypeReclist: int   # >0 while writing a type's OWN reclist: fields must be SELF-CONTAINED
                         # defs (the type can be seek-loaded in isolation), not entry-deduped uses
    emittedCanonTypes: Table[string, int32]  # canonical type name -> itemId.item of the def
    extraExports: HashSet[ItemId]  # symbols made importable by an explicit `export s`
                         # rather than by a `*` on the declaration; see
                         # `modulegraphs.reexportedLocalSyms`


when defined(icLocalSymStats):
  # TEMPORARY instrumentation: how is `localSyms` actually populated? The
  # snapshot-vs-shared-table question only matters if body-local NIF names exist
  # at all, and `isLocalSym` below returns a hardwired `false`.
  import std / exitprocs

  var lsLocalHit, lsFieldStub, lsMiss, lsSdReg, lsExtractReg: int
  addExitProc proc () =
    if lsLocalHit + lsFieldStub + lsMiss + lsSdReg + lsExtractReg > 0:
      stderr.writeLine "LOCALSYM localHit=" & $lsLocalHit &
        " fieldStub=" & $lsFieldStub & " miss=" & $lsMiss &
        " sdReg=" & $lsSdReg & " extractReg=" & $lsExtractReg

proc isLocalSym(sym: PSym): bool {.inline.} =
  ## Every symbol is emitted as a *global* (module-suffixed) name so that its
  ## `sdef` gets an index entry and is resolvable by index lookup even when
  ## referenced from a different index entry than the one that physically
  ## contains the definition. This matters for symbols shared across entries:
  ## generic params of a forward declaration vs its implementation, and proc-type
  ## params shared between an enclosing proc and a nested object's proc-type
  ## field. The per-module `disamb` counter keeps `name.disamb.module` unique, so
  ## globalising cannot cause clashes. This trades index size for correctness;
  ## size/speed can be optimised later.
  false

const
  FieldMarker = "`f"
    ## Appended to the ident of `skField` symbols in NIF names. Object fields are
    ## emitted as *local* symbols (NIF spec sense): `<ident>`f.<disamb>` with NO
    ## module suffix, so they get no index entry and are never registered in the
    ## global `c.syms` name table. A field reference is a leaf — its C member name
    ## is a deterministic function of `name.s` (`ccgtypes.mangleField`) and is
    ## struct-scoped, and the field's type already rides on the `PNode` — so there
    ## is nothing to resolve across modules: the use site just stubs a `skField`
    ## from the local name. This removes the whole foreign-suffix pollution class
    ## (a derived/captured env field minted under a foreign module suffix used to
    ## corrupt the loader's name→buffer seek). The `` `f `` marker keeps the field's
    ## local name in a namespace disjoint from proc-locals (backtick cannot appear
    ## in a Nim identifier), so a field use can never be misrouted to a same-named
    ## local var/param. Mirrors the `` `t `` (`typeToNifSym`) and `PkgMarker`
    ## namespaces.
  CursorFieldMarker = "`fc"
    ## `FieldMarker` for a field declared `{.cursor.}`. A field USE serializes as
    ## a bare `SymUse` — there is nowhere to put symbol flags — and the use-site
    ## stub `loadFieldStub` mints carries none, so `trees.isCursor` (which reads
    ## `sfCursor` off the field sym of an `nkDotExpr`) said "not a cursor" for
    ## every loaded field. `lists.DoublyLinkedNode.prev` then became a COUNTED
    ## reference: every node held its predecessor alive, no refcount ever hit
    ## zero, and a doubly linked list leaked its whole contents. Both the reclist
    ## def and every use derive their name from the same `PSym`, so marking the
    ## name keeps them in lockstep.
  PkgMarker = "`pkg"
    ## Appended to the ident of `skPackage` symbols in NIF names. A package sym
    ## has no module of its own: it is written once into every module NIF that
    ## references it, named with that module's suffix and its own (independent)
    ## disamb counter. Without the marker it can collide with a module-level
    ## symbol of the same name and disamb — e.g. extccomp's `compiler` template
    ## vs the `compiler` package — and the module sym's owner then resolves to
    ## the wrong symbol on load, producing a cyclic owner chain that hangs every
    ## owner-walk (sighashes.hashSym etc.). Backtick cannot appear in a Nim
    ## identifier, mirroring the "`t" namespace used by `typeToNifSym`.

proc toNifSymName(w: var Writer; sym: PSym): string =
  ## Generate NIF name for a symbol: local names are `ident.disamb`,
  ## global names are `ident.disamb.moduleSuffix`
  if sym.kindImpl == skField:
    # Object fields are LOCAL symbols (no module suffix, no index entry, not in the
    # global `c.syms`). See `FieldMarker`. The same `toNifSymName` call produces this
    # name at both the reclist def site and every use site (same `PSym`), so they
    # agree by construction; the loader recovers `name.s` and `mangleField` produces
    # the matching struct member name regardless of which module references it.
    result = sym.name.s
    result.add (if sfCursor in sym.flagsImpl: CursorFieldMarker else: FieldMarker)
    result.add '.'
    # Use the field's POSITION as the local name's numeric component: it is unique
    # within the owning type (so the local name is unambiguous there) AND it is what
    # tuple element access reads off a use-site field stub (`genRecordField`'s
    # tyTuple branch emits `Field$position`). Named-object field uses re-navigate by
    # name, so position is only load-bearing for tuples — but carrying it is free.
    result.addInt sym.positionImpl
    return
  if sym.itemId.isBackendMinted:
    # Process-local backend sym (closure env field / hidden `:env` param minted
    # during a VM transform): re-home to the current module with the `@bk`
    # marker so each referencing module self-contains it. See transformBody.
    #
    # The numeric name component comes from `astdef.backendMintedDisamb` — the
    # ONE definition of which integer identifies a backend-minted symbol, shared
    # with the two C-name manglers (`mangleProcNameExt`, `ccgutils.makeUnique`)
    # so the NIF name and the C name cannot disagree. `@bk` TYPES key off
    # `itemId.item` the same way (see `nifTypeName`). The loader copies this back
    # into `disamb` (sn.count), so `globalName` round-trips.
    result = sym.name.s
    result.add '.'
    result.addInt backendMintedDisamb(sym)
    result.add '.'
    result.add modname(w.currentModule, w.infos.config)
    result.add BackendLocalMarker
    return
  result = sym.name.s
  if sym.kindImpl == skPackage:
    result.add PkgMarker
  result.add '.'
  result.addInt sym.disamb
  if not isLocalSym(sym) and sym.itemId notin w.locals:
    # Global symbol: ident.disamb.moduleSuffix
    result.add '.'
    let module = if sym.kindImpl == skPackage: w.currentModule else: sym.itemId.module
    result.add modname(module, w.infos.config)


proc globalName*(sym: PSym; config: ConfigRef): string =
  result = sym.name.s
  if sym.kindImpl == skPackage:
    # stubs store the clean name; the NIF index is keyed by the marked one
    result.add PkgMarker
  result.add '.'
  result.addInt sym.disamb
  result.add '.'
  result.add modname(sym.itemId.module, config)
  # A loaded process-local backend sym keeps its `@bk` marker in the NIF name
  # (the index/`c.syms` tables are keyed by it); mirror toNifSymName so name-based
  # lookups via globalName don't miss (KeyError `:env.N.<mod>` without the marker).
  if sym.itemId.isBackendMinted:
    result.add BackendLocalMarker

type
  ParsedSymName* = object
    name*: string
    module*: string
    count*: int

proc parseSymName*(s: string): ParsedSymName =
  var i = s.len - 2
  while i > 0:
    if s[i] == '.':
      if s[i+1] in {'0'..'9'}:
        var count = ord(s[i+1]) - ord('0')
        var j = i+2
        while j < s.len and s[j] in {'0'..'9'}:
          count = count * 10 + ord(s[j]) - ord('0')
          inc j
        return ParsedSymName(name: substr(s, 0, i-1), module: "", count: count)
      else:
        let mend = s.high
        var b = i-1
        while b > 0 and s[b] != '.': dec b
        var j = b+1
        var count = 0
        while j < s.len and s[j] in {'0'..'9'}:
          count = count * 10 + ord(s[j]) - ord('0')
          inc j

        return ParsedSymName(name: substr(s, 0, b-1), module: substr(s, i+1, mend), count: count)
    dec i
  return ParsedSymName(name: s, module: "")

proc isFieldMarked(rawName: string): bool {.inline.} =
  rawName.endsWith(FieldMarker) or rawName.endsWith(CursorFieldMarker)

proc stripFieldMarker(rawName: string): string {.inline.} =
  if rawName.endsWith(CursorFieldMarker):
    rawName[0 ..< rawName.len - CursorFieldMarker.len]
  else:
    rawName[0 ..< rawName.len - FieldMarker.len]

proc isFieldNifName*(name: string): bool {.inline.} =
  ## True for an object field's local NIF name `<ident>`f.<disamb>` (see
  ## `FieldMarker`): no module suffix, marker on the ident.
  let sn = parseSymName(name)
  sn.module.len == 0 and isFieldMarked(sn.name)

proc stubKindAndName(cache: IdentCache; rawName: string): (TSymKind, PIdent) =
  ## The user-visible name of a symbol stub must NOT keep NIF-only name
  ## decorations: the `PkgMarker` of package symbols would otherwise leak into
  ## every reader of `name.s` that runs before the stub is fully loaded
  ## (e.g. vmgen's callback keys built from owner chains). The marker also
  ## tells us the symbol kind up front, which `globalName` uses to rebuild
  ## the marked NIF name for the index lookup.
  if rawName.endsWith(PkgMarker):
    (skPackage, cache.getIdent(rawName[0 ..< rawName.len - PkgMarker.len]))
  elif isFieldMarked(rawName):
    # Object field (local NIF symbol, see `FieldMarker`): strip the marker so the
    # backend mangles the clean field name, and record the kind so a use-site stub
    # is a real `skField` (cgen branches on it for `obj.field` access).
    (skField, cache.getIdent(stripFieldMarker(rawName)))
  else:
    (skStub, cache.getIdent(rawName))

# --- nifcore writer adapter -------------------------------------------------
# The `write*` procs build the module into an `IcBuilder` (nifcore). These give
# the IcBuilder the SAME call shapes the old `nifstreams` TokenBuf had (taking
# `nifstreams` TagId/SymId/PackedToken + a PackedLineInfo), so the writer bodies
# are unchanged apart from the `var TokenBuf` -> `var IcBuilder` parameter type.
# Line info is unpacked from the PackedLineInfo and re-emitted via
# `IcBuilder.lineInfo` (absolute file/line/col; nifcore makes it relative on
# serialization), exactly as the deleted `serializeViaNifcore` bridge did.

proc emitInfo(b: var IcBuilder; info: PackedLineInfo) {.inline.} =
  if info.isValid:
    let u = unpack(pool.man, info)
    let fname = if u.file.isValid: pool.files[u.file] else: ""
    let cstr = if u.comment != 0'u32: pool.strings[nifstreams.StrId(u.comment)] else: ""
    b.lineInfo(fname, u.line, u.col, cstr)

proc addParLe(b: var IcBuilder; tag: nifstreams.TagId; info = NoLineInfo) =
  b.openTag(pool.tags[tag]); b.emitInfo(info)
proc addParRi(b: var IcBuilder) {.inline.} = b.closeTag()
proc addSymDef(b: var IcBuilder; s: nifstreams.SymId; info = NoLineInfo) =
  b.addSymDef(pool.syms[s]); b.emitInfo(info)
proc addSymUse(b: var IcBuilder; s: nifstreams.SymId; info = NoLineInfo) =
  b.addSymUse(pool.syms[s]); b.emitInfo(info)

proc add(b: var IcBuilder; t: PackedToken) =
  ## Bridge a single old-API token constructor (symToken/strToken/floatToken/
  ## charToken) into the IcBuilder.
  case t.kind
  of DotToken:    b.addDotToken()
  of Ident:       b.addIdent(pool.strings[t.litId])
  of Symbol:      b.addSymUse(pool.syms[t.symId])
  of SymbolDef:   b.addSymDef(pool.syms[t.symId])
  of IntLit:      b.addIntLit(pool.integers[t.intId])
  of UIntLit:     b.addUIntLit(pool.uintegers[t.uintId])
  of FloatLit:    b.addFloatLit(pool.floats[t.floatId])
  of CharLit:     b.addCharLit(char(t.uoperand))
  of StringLit:   b.addStrLit(pool.strings[t.litId])
  else: discard
  if t.kind != ParRi: b.emitInfo(t.info)

template buildTree(dest: var IcBuilder; tag: nifstreams.TagId; body: untyped) =
  dest.addParLe tag
  body
  dest.addParRi

template buildTree(dest: var IcBuilder; tag: string; body: untyped) =
  dest.openTag tag
  body
  dest.closeTag()

template buildTree(dest: var IcBuilder; tag: nifstreams.TagId; info: PackedLineInfo; body: untyped) =
  dest.addParLe tag, info
  body
  dest.addParRi

proc writeFlags[E](dest: var IcBuilder; flags: set[E]) =
  var flagsAsIdent = ""
  genFlags(flags, flagsAsIdent)
  if flagsAsIdent.len > 0:
    dest.addIdent flagsAsIdent
  else:
    dest.addDotToken

proc trLineInfo(w: var Writer; info: TLineInfo): PackedLineInfo {.inline.} =
  result = nifLineInfo(w.infos, info)

proc writeNode(w: var Writer; dest: var IcBuilder; n: PNode; forAst = false)
proc writeType(w: var Writer; dest: var IcBuilder; typ: PType)
proc writeSym(w: var Writer; dest: var IcBuilder; sym: PSym)

func restoresWrittenState(config: ConfigRef): bool {.inline.} =
  config.ideActive or optGenBif in config.globalOptions

proc writeLoc(w: var Writer; dest: var IcBuilder; loc: TLoc) =
  dest.addIdent toNifTag(loc.k)
  dest.addIdent toNifTag(loc.storage)
  writeFlags(dest, loc.flags)  # TLocFlags
  dest.addStrLit loc.snippet

const
  CanonTypeKinds = {tyVar, tyLent, tySink, tyTuple, tyRef, tyPtr, tySequence,
                    tyOpenArray, tyVarargs, tySet, tyUncheckedArray, tyArray,
                    tyRange, tyProc}
    ## Anonymous types whose NIF name is derived from what they ARE -- their
    ## content, or for a routine's signature the routine -- rather than from
    ## `itemId.item`, the module-wide type-mint counter.
    ##
    ## The counter is assigned in sem order, so creating ONE extra type renumbers
    ## every type minted after it. Types declared in a `type` section are minted
    ## before any routine body, so they are stable; but the `var T` / `lent T` /
    ## tuple wrappers sem mints for routine signatures are not, and those are
    ## exactly what an importer references by name. Inserting a private proc at
    ## the top of `ast.nim` shifted 1362 of its 1800 type names by +1, which
    ## rewrote the `.s.bif` of 81 modules that had not changed at all.
    ##
    ## Restricted to anonymous wrappers on purpose. A nominal type must NOT be
    ## content-addressed: `exactReplica` deliberately mints a fresh `itemId`
    ## for a structurally identical copy so the two stay distinguishable, and
    ## collapsing them loses the flag or body difference they were split over.
    ##
    ## `tyProc` is in the set, but it never takes the content key: a proc type
    ## that is some routine's SIGNATURE is named after that routine (see
    ## `sigRoutineOf`), and any other proc type keeps its counter. Content-keying
    ## a signature is what "everything `writeTypeDef` serializes" gets wrong,
    ## because a signature's identity is not in its content at all -- it is in
    ## the PARAM SYMBOLS the routine's body refers to.
    ## Merging two signatures leaves the survivor's params in the loser's
    ## `typ.n`, its body then references params the C backend never declared, and
    ## codegen dies with "expr: param not init". Measured on a hello-world under
    ## `nim ic`: 238 proc-type merges, every single one a lifted `=sink` hook
    ## (`(dest: var T, src: T)`, two hooks minted for the same T, identical in
    ## everything `writeTypeDef` writes) -- so no amount of extra content in the
    ## key would ever have separated them.
    ##
    ## Effect on `msgs.nim`, the module the wrapper pass could not help: an
    ## insert at the top moved 259 of its 530 type names, 153 of them proc types.
    ## All 153 now hold still and 106 names move. What is left is other kinds
    ## still on the counter -- `tyInt`, `tyTypeDesc`, `tyDistinct` -- plus the
    ## content-named wrappers that cascade off them.

const
  CanonLitCopyKinds = {tyInt, tyFloat}
    ## Kinds that sem COPIES per module out of `system`, keeping the ORIGINAL's
    ## `sym`: the int literal types (`semdata.getIntLitType`,
    ## `semfold.getIntLitTypeG`) and the plain copies `magicsys.skipIntLit`
    ## makes of them when a literal type reaches a parameter. `tyFloat` is here
    ## because `skipIntLit` accepts it, not because anything mints one today --
    ## every one of the copies measured below is a `tyInt`. `getIntLitType` caches only the small values, so everything
    ## else mints a fresh type per occurrence: `nilcheck.nim` alone writes 132
    ## and the whole compiler writes 20107 -- 91% of every per-module copy in
    ## the build, and each one holds a mint-counter name that an insert
    ## anywhere above it shifts.
    ##
    ## They are the last mover that actually BREAKS a build rather than just
    ## churning bytes. Inserting a proc at the top of `nilcheck.nim` renamed one
    ## of them and `pipelines.t.bif` -- cached, not re-sem'd, because the iface
    ## cookie is order-insensitive since `fab55cff6` -- still pointed at the old
    ## name: `symbol has no offset: t31.4199.nilrwrcn11`. That reproduces on
    ## `2bed712f6` and not on `901ca7905`.
    ##
    ## Merging two of these is safe in a way merging a nominal type is not: the
    ## key carries the flags, the size and the literal in `n` -- everything
    ## `isIntLit` and `sameType` look at -- plus the `sym`, which is what keeps
    ## a copy of plain `int` apart from a copy of an int-shaped alias like
    ## posix's `Off`. Merging is in fact what `getIntLitType`'s own cache
    ## already does for the values it covers.
    ##
    ## The test is deliberately a MODULE comparison and not `sym.typ != typ`;
    ## the comment on `isCanonType` records what that cost. It also means a copy
    ## minted while compiling `system` itself is not covered -- sym and type
    ## agree on the module there -- which is fine: nothing above `system` can
    ## shift its counter.
    ##
    ## The OTHER copies are deliberately not here. 1375 are `tyObject` -- a
    ## generic instance's body -- and 184 `tySequence`, both nominal: their
    ## identity is the declaration, not the content, and collapsing two of them
    ## loses exactly what `exactReplica` exists to keep apart.

proc hasDerivedSize(typ: PType): bool {.inline.} =
  ## True for a type whose `size`/`align`/`paddingAtEnd` are a pure function of
  ## the structure that is serialized with it, so a consumer can recompute them
  ## and no measurement needs to cross the NIF boundary. That is every ANONYMOUS
  ## structural wrapper: `{.size.}`/`{.align.}` are pragmas on a type
  ## DECLARATION, so a type without a `sym` cannot carry one, and the remaining
  ## kinds (an object's field offsets, an enum's declared size) are excluded.
  typ.kind in CanonTypeKinds and typ.symImpl == nil

const CanonIdBias = 0x4000_0000'i32
  ## Canonical ids live above every mint counter so a content hash can never
  ## collide with the `itemId.item` of a same-kind type that kept its counter
  ## (a replica, or a wrapper whose son is backend-minted).

proc canonHash(s: string): int32 =
  ## FNV-1a, hand-rolled on purpose: this value goes into on-disk NIF names, so it
  ## must not change when the host `std/hashes` does -- a shifted hash would
  ## renumber every cached module the way the mint counter used to.
  var h = 0x811C9DC5'u32
  for ch in s:
    h = h xor uint32(ord(ch))
    h = h * 0x01000193'u32
  result = int32(h and 0x3FFF_FFFF'u32) or CanonIdBias

var canonTypeIds: Table[ItemId, int32]
  ## Memo for `canonicalTypeItem`, deliberately PROCESS-global rather than
  ## per-`Writer`. A type's mutable fields (its flag set, chiefly) can still be
  ## growing while an `--icGroup` cycle writes one member's NIF after another's,
  ## and the two writers must not disagree about its name. Pinning the id at its
  ## first computation makes the process self-consistent; across processes the
  ## question does not arise, since a consumer LOADS the id out of the name.

var canonClaims: Table[ItemId, string]
  ## `(module, canonical id) -> the key that minted it`, so a hash COLLISION
  ## cannot silently merge two unrelated types. `canonHash` has 30 usable bits;
  ## across a module's ~2000 types a birthday collision is unlikely but not
  ## negligible, and until now it would have been a miscompile rather than a
  ## wasted slot. A second, DIFFERENT key landing on a taken id falls back to
  ## `itemId.item`, which is safe for exactly the reason the re-entrancy guard
  ## below is: the mint counter is unique within the module, so nothing else can
  ## be wearing that name.

var canonSigOwners: Table[string, ItemId]
  ## `signature key -> the one PType allowed to wear it`. A signature name is an
  ## IDENTITY, not a digest: two `PType`s that agree on it are NOT
  ## interchangeable, so unlike a content key it must never be shared. A routine
  ## has one type at a time, yet `prc.typ` is REPLACED in places (a forward
  ## declaration adopting its prototype, `instantiateProcType` overwriting the
  ## signature it copied), and the previous occupant can still be reachable and
  ## still get written. The first claimant keeps the name; a later one keeps its
  ## counter.

proc canonicalTypeItem(w: var Writer; typ: PType): int32
proc nifTypeName(w: var Writer; typ: PType): string
proc addNodeKey(w: var Writer; key: var string; n: PNode)

proc claimCanonId(typ: PType; key: string; h: int32): int32 =
  ## Hand out `h` unless another key already holds it in this module.
  let slot = itemId(typ.itemId.module, h)
  canonClaims.withValue(slot, prev):
    return (if prev[] == key: h else: typ.itemId.item)
  do:
    canonClaims[slot] = key
    return h

proc sigRoutineOf(typ: PType): PSym =
  ## The routine whose signature `typ` is, or nil for a proc type that is merely
  ## a value's type (`var cb: proc (x: int)`).
  ##
  ## Every routine owns its own signature: sem does it through `getCurrOwner`,
  ## and so do the synthesizers -- generic instantiation
  ## (`seminst.instantiateProcType`), the lifted type-bound hooks, `$` for enums
  ## and the backend's rtti/globals procs. The `o.typ == typ` confirmation is
  ## what separates a routine's own signature from an anonymous proc type minted
  ## inside its body (same owner, different type).
  result = nil
  let o = typ.ownerFieldImpl
  if o != nil and o.kindImpl in routineKinds and o.typImpl == typ:
    result = o

proc isCanonType(w: Writer; typ: PType): bool =
  ## True only when the id must be OVERRIDDEN, i.e. for a wrapper minted in THIS
  ## process. Note what is deliberately absent: any test against
  ## `w.currentModule`. An `--icGroup` cycle compiles several modules from source
  ## in one process and writes a NIF for each, so while writing member A a type
  ## owned by member B is minted, not loaded -- keying on `currentModule` would
  ## have A reference `B`'s type by its mint counter while B's own NIF def'd it
  ## under the content id, leaving a dangling `symbol has no offset`.
  ##
  ## The three other cases need no override and are excluded here, each landing
  ## on `typeToNifSym`, which reproduces the owner's name byte for byte:
  ##  * loaded and content-named  -> `itemId.item` already IS the content id
  ##    (>= CanonIdBias), which is exactly what `typeToNifSym` prints;
  ##  * loaded `exactReplica`     -> `bindingId != itemId` marks it a replica,
  ##    which is never content-named (see CanonTypeKinds), so it keeps its counter;
  ##  * a `Partial` stub          -> its id is already final; for a wrapper the
  ##    `sonsImpl` test below rejects it, and a literal copy is decided purely
  ##    from the two module ids its NIF name already carries.
  ##
  ## Depends on nothing that changes during a write -- in particular not on
  ## `typ.state`, which flips to `Sealed` the moment the def is emitted -- so a
  ## type's def site and every reference to it agree.
  if typ.itemId.isBackendMinted or typ.itemId.item >= CanonIdBias or
      typ.bindingId != typ.itemId:   # a replica is never content-named
    result = false
  elif typ.kind in CanonTypeKinds:
    # An anonymous wrapper. A `sym` means the type was DECLARED and is nominal.
    result = typ.symImpl == nil and typ.sonsImpl.len > 0
  elif typ.kind in CanonLitCopyKinds:
    # A per-module literal copy: it wears `system.int`'s `sym` but was minted
    # into ANOTHER module's id space, so the sym and the type disagree about
    # which module they belong to. A declaration never does -- `type Off = int`
    # in posix owns both halves -- and neither does `system.int` itself.
    #
    # The obvious test, `typ.sym.typ != typ` ("the sym's own type is the
    # original, so this is a copy"), is wrong ACROSS THE NIF BOUNDARY and cost a
    # cold build: a loaded `Off` sym is a stub whose `typImpl` is still nil, so
    # posix named its `Off` by the counter while `os` read the same type as a
    # copy and referenced a content id posix never wrote -- `symbol has no
    # offset: t31.2136968888.pos7l6hwt`. Both halves of this test come off the
    # NIF name, so a consumer and the owner always agree.
    result = typ.symImpl != nil and
      typ.symImpl.itemId.module != typ.itemId.module
  else:
    result = false

proc addNodeKey(w: var Writer; key: var string; n: PNode) =
  ## Structural digest of a type's `n` node, for the kinds whose identity lives
  ## there: a `tyRange`'s bounds and a `tyProc`'s formal params. A symbol
  ## contributes its bare NAME -- never its NIF name, whose `disamb` is itself a
  ## mint counter and would defeat the whole point -- plus the NIF name of its
  ## TYPE. The type is not optional: a `tyProc`'s parameters live only here, not
  ## in `sonsImpl`, so hashing names alone collapsed a generic `==[Enum]` onto
  ## its own `FileInfoKind` instance (both have parameters `x`, `y` returning
  ## `bool`) and `n.kind == nkSym` stopped compiling.
  if n == nil:
    key.add '~'
    return
  key.add '('
  key.addInt ord(n.kind)
  case n.kind
  of nkCharLit..nkUInt64Lit:
    key.add ' '
    key.addInt n.intVal
  of nkFloatLit..nkFloat128Lit:
    key.add ' '
    key.add $cast[uint64](n.floatVal)
  of nkStrLit..nkTripleStrLit:
    key.add ' '
    key.add n.strVal
  of nkSym:
    key.add ' '
    if n.sym != nil:
      key.add n.sym.name.s
      key.add ':'
      if n.sym.typImpl != nil: key.add nifTypeName(w, n.sym.typImpl)
  of nkIdent:
    key.add ' '
    if n.ident != nil: key.add n.ident.s
  else:
    for i in 0 ..< n.len:
      addNodeKey(w, key, n[i])
  key.add ')'

proc canonicalTypeItem(w: var Writer; typ: PType): int32 =
  ## Stable id for a type that would otherwise wear the mint counter: its
  ## CONTENT for a wrapper or a literal copy, and for a proc type that is a
  ## routine's signature, the routine that owns it.
  ##
  ## SOUNDNESS RULE: the key must cover everything `writeTypeDef` serializes
  ## except the id itself, so that two types sharing a name would have been
  ## written identically anyway. Skimping on that is not a missed optimisation,
  ## it is a miscompile: a key over `eqTypeFlags` alone merged two proc types
  ## differing only in `tfUnresolved`, and `sizeof(uint64)` stopped resolving.
  ## The owner is in the key too, which keeps distinct-but-identical wrappers in
  ## different routines apart -- order-independence is the goal here, merging is
  ## not, and merging is where every bug in this scheme has come from.
  ##
  ## Son NIF NAMES are the right currency for the recursive part: they are what
  ## actually lands in the file, they are already stable for anything declared in
  ## a `type` section, and recursion bottoms out on nominal types, which keep
  ## their counter names.
  canonTypeIds.withValue(typ.itemId, cached):
    return cached[]
  # Re-entrancy guard: a son that leads back here sees the mint counter, and this
  # type still gets a deterministic (if less stable) id.
  canonTypeIds[typ.itemId] = typ.itemId.item

  # A routine's signature is named after the ROUTINE, not after its content.
  # Content cannot work here (see CanonTypeKinds): two `=sink` hooks for one type
  # agree in every serialized byte yet own different param symbols, and the
  # merged loser's body loses its parameters. The routine's own NIF name is both
  # unique -- a routine has one signature -- and stable, since `disamb` counts
  # per identifier rather than per module, which is the whole point. It is also
  # stable across a signature CHANGE: adding a parameter or an effect no longer
  # renames the type, so importers keep their references and only the iface
  # cookie (which reads the signature itself) notices.
  let sigRoutine = if typ.kind == tyProc: sigRoutineOf(typ) else: nil
  if sigRoutine != nil:
    var sigKey = "sig|"
    sigKey.add modname(typ.itemId.module, w.infos.config)
    sigKey.add '|'
    sigKey.add toNifSymName(w, sigRoutine)
    var taken = false
    canonSigOwners.withValue(sigKey, holder):
      taken = holder[] != typ.itemId
    do:
      canonSigOwners[sigKey] = typ.itemId
    if not taken:
      result = claimCanonId(typ, sigKey, canonHash(sigKey))
      canonTypeIds[typ.itemId] = result
      return result
    # Someone else is already this routine's signature; keep the mint counter.
    return typ.itemId.item
  elif typ.kind == tyProc:
    # An anonymous proc type -- a parameter's or a variable's `proc (x: int)`.
    # It keeps the mint counter, and `nifTypeName` then prints exactly what
    # `typeToNifSym` would. Content-keying it looked harmless and is not: the
    # `raises`/`tags` effects that separate two otherwise identical proc types
    # live as `nkType` nodes under `n[0]`'s `nkEffectList`, and `addNodeKey`
    # hashes a node's kind and children but never its TYPE, so every effect set
    # digests the same. Enabling it collapsed two `proc () {.closure.}` params in
    # `seqs_v2.yrcMutatorLock` and `tests/ic/tmeta_async` stopped compiling with
    # "type mismatch: got <proc (){.closure, gcsafe.}> but expected 'proc
    # (){.closure, gcsafe.}' .raise effects differ". Teaching `addNodeKey` about
    # node types would fix that particular merge, but there is nothing to win:
    # the churn this whole scheme exists to remove is in the SIGNATURES an
    # importer references, and those are handled above.
    return typ.itemId.item

  var key = newStringOfCap(96)
  key.addInt ord(typ.kind)
  key.add '|'
  for f in typ.flagsImpl:
    key.addInt ord(f)
    key.add ','
  key.add '|'
  key.addInt ord(typ.callConvImpl)
  key.add '|'
  # size/align/paddingAtEnd are deliberately ABSENT. They are filled in lazily,
  # so hashing them would make a type's NAME depend on whether anyone had asked
  # for its `sizeof` yet -- and they are not serialized for these kinds either
  # (see `hasDerivedSize` in writeTypeDef), so there is nothing to distinguish:
  # everything they are computed FROM is in this key already.
  if typ.typeInstImpl != nil: key.add nifTypeName(w, typ.typeInstImpl)
  # The `sym` is load-bearing for a literal copy and nil for every wrapper, so
  # adding it leaves the wrapper keys byte-identical. It has to be here: a copy
  # of plain `int` and a copy of an int-shaped alias such as posix's `Off` agree
  # on kind, flags and size, and the sym is all that tells them apart.
  if typ.symImpl != nil:
    key.add '$'
    key.add toNifSymName(w, typ.symImpl)
  if typ.ownerFieldImpl != nil:
    key.add '<'
    key.add toNifSymName(w, typ.ownerFieldImpl)
  for son in typ.sonsImpl:
    key.add '#'
    if son == nil: key.add '.'
    else: key.add nifTypeName(w, son)
  # `n` carries a tuple's field names, a range's bounds and a proc's formal
  # params -- all of them serialized, so all of them part of the key.
  addNodeKey(w, key, typ.nImpl)
  result = claimCanonId(typ, key, canonHash(key))
  when defined(icLitDbg):
    if typ.kind in CanonLitCopyKinds:
      stderr.writeLine "[litkey] cur=" & modname(w.currentModule, w.infos.config) &
        " idmod=" & modname(typ.itemId.module, w.infos.config) &
        " id=" & $typ.itemId.item & " state=" & $typ.state &
        " id=" & $result & " key=" & key
  canonTypeIds[typ.itemId] = result

proc nifTypeName(w: var Writer; typ: PType): string =
  ## NIF name of a type as written by THIS module. A process-local backend env
  ## type is re-homed to the current module with the `@bk` marker (see
  ## BackendLocalMarker); an anonymous wrapper this module OWNS is content-named
  ## (see CanonTypeKinds); everything else uses `typeToNifSym`.
  ##
  ## Only owned types are content-named, and that is enough: an importer holds
  ## the type as a stub built BY `tryCreateTypeStub` FROM this name, so its
  ## `itemId.item` already carries the content id and `typeToNifSym` reproduces
  ## the name without recomputing anything.
  if isCanonType(w, typ):
    result = "`t"
    result.addInt ord(typ.kind)
    result.add '.'
    result.addInt canonicalTypeItem(w, typ)
    result.add '.'
    result.add modname(typ.itemId.module, w.infos.config)
  elif typ.itemId.isBackendMinted:
    result = "`t"
    result.addInt ord(typ.kind)
    result.add '.'
    result.addInt typ.itemId.item
    result.add '.'
    result.add modname(w.currentModule, w.infos.config)
    result.add BackendLocalMarker
  else:
    result = typeToNifSym(typ, w.infos.config)

proc writeTypeDef(w: var Writer; dest: var IcBuilder; typ: PType) =
  dest.buildTree tdefTag:
    dest.addSymDef pool.syms.getOrIncl(nifTypeName(w, typ)), NoLineInfo
    dest.addDotToken # always private for the index generator

    #dest.addIdent toNifTag(typ.kind)
    writeFlags(dest, typ.flagsImpl)
    dest.addIdent toNifTag(typ.callConvImpl)
    if hasDerivedSize(typ):
      # Do not export a MEASUREMENT. `size`/`align`/`paddingAtEnd` are filled in
      # lazily by `computeSizeAlign`, so writing what this process happened to
      # have measured makes a module's bytes depend on WHEN some other module
      # asked for a `sizeof` -- churn for the interface cookie, and outright
      # non-determinism for a content-named type, whose def two writers may
      # reach in either order (that is what once cost `koch bootic` its fixed
      # point). For these kinds the values are derived from the structure that
      # is serialized anyway, so hand the consumer the unmeasured sentinel and
      # let it compute them exactly like it would for a from-source type.
      dest.addIntLit defaultSize
      dest.addIntLit defaultAlignment
      dest.addIntLit 0
    else:
      dest.addIntLit typ.sizeImpl
      dest.addIntLit typ.alignImpl
      dest.addIntLit typ.paddingAtEndImpl
    # `bindingId`, the generic binding-table key (see astdef.TType). It equals
    # `itemId` for everything except an `exactReplica`, and the loader rebuilds
    # `itemId` from the NIF name -- so for a content-named type this must be the
    # SAME id the name carries (`bindingId == itemId` is what made it eligible,
    # and writing the mint counter here would keep the byte churn the content
    # scheme exists to remove).
    # `bindingId` (see astdef.TType): the generic binding-table key. Only an
    # `exactReplica` has one that differs from its own `itemId`, and `itemId` is
    # exactly what the loader rebuilds from the type's NIF name -- so everything
    # else would only repeat what the name already says. Emit the node solely
    # when it carries information (18 of 11894 type defs in a `nim ic` build of
    # tests/ic/timp), TAGGED rather than positional: the interface cookie has to
    # drop this field (it is a module-wide mint counter, so hashing it made the
    # cookie depend on declaration ORDER -- one line added to ast.nim cost 98
    # re-sems), and a tag lets `hashRegion` skip it by name instead of counting
    # tokens into this tree and silently mis-skipping when the layout changes.
    if typ.bindingId == typ.itemId:
      dest.addDotToken
    else:
      dest.buildTree bindingIdTag:
        dest.addIntLit typ.bindingId.item
        # a replica of a FOREIGN type: the module half is not in the name either
        if typ.bindingId.module != typ.itemId.module and
            not typ.bindingId.isBackendMinted:
          dest.addStrLit modname(typ.bindingId.module, w.infos.config)

    writeType(w, dest, typ.typeInstImpl)
    #if typ.kind in {tyProc, tyIterator} and typ.nImpl != nil and typ.nImpl.kind != nkFormalParams:

    # The reclist holds this type's OWN fields. A type can be force-loaded by
    # name in isolation (cg seeks the `.t.nif`/`.s.nif` index entry), so its
    # fields must be DEFS here, not entry-deduped SymUses whose def lives
    # elsewhere in the `(lowered)` entry and is never read by the seek.
    #
    # `emittedFieldSyms` only guards against a field being def'd twice WITHIN one
    # reclist, so scope it per-reclist: a generic object and its instances SHARE one
    # field PSym (same itemId) yet each instance carries a DISTINCT field type (e.g.
    # `MDigest[256].data: array[32,byte]` vs `MDigest[384].data: array[48,byte]`), so
    # each reclist needs its OWN typed def. A Writer-global set deduped every instance
    # after the first to a typeless `SymUse` stub (nil typ/owner on load → crash in
    # destructor lifting). Field NIF names are local (no module suffix, not in the
    # global `c.syms`), so def'ing the same field in two reclists never collides.
    inc w.inTypeReclist
    let savedFieldSyms = move w.emittedFieldSyms
    writeNode(w, dest, typ.nImpl)
    w.emittedFieldSyms = savedFieldSyms
    dec w.inTypeReclist
    writeSym(w, dest, typ.ownerFieldImpl)
    writeSym(w, dest, typ.symImpl)

    # Write TLoc structure
    writeLoc w, dest, typ.locImpl
    # we store the type's elements here at the end so that
    # it is not ambiguous and saves space:
    for ch in typ.sonsImpl:
      writeType(w, dest, ch)


proc writeType(w: var Writer; dest: var IcBuilder; typ: PType) =
  if typ == nil:
    dest.addDotToken()
  elif typ.itemId.isBackendMinted:
    # Process-local closure env (see transf.transformBody): emit a MODULE-LOCAL
    # `@bk` def the first time it is reached in this module, reference it after.
    # Per-Writer dedup (NOT the shared `state`), since every referencing module
    # must emit its own copy.
    if not w.emittedBackendTypes.containsOrIncl((ord(typ.kind).int32, typ.itemId.item)):
      writeTypeDef(w, dest, typ)
    else:
      dest.addSymUse pool.syms.getOrIncl(nifTypeName(w, typ)), NoLineInfo
  elif typ.itemId.module == w.currentModule and typ.state == Complete and
       isCanonType(w, typ) and w.emittedCanonTypes.hasKey(nifTypeName(w, typ)):
    # A content-named wrapper whose name this module already def'd. Two distinct
    # `PType`s can share one content id -- sem mints a fresh `lent PNode` per
    # signature -- and they are interchangeable by construction (same kind, same
    # `sameType` flags, same sons), so the duplicate folds into a reference
    # rather than emitting a second def under a name that already has one.
    when defined(icCanonDbg):
      let cn = nifTypeName(w, typ)
      if w.emittedCanonTypes[cn] != typ.itemId.item:
        var sons = ""
        for so in typ.sonsImpl:
          sons.add (if so == nil: "." else: nifTypeName(w, so)) & " "
        stderr.writeLine "[canon-collide] " & cn & " kind=" & $typ.kind &
          " uidA=" & $w.emittedCanonTypes[cn] & " uidB=" & $typ.itemId.item &
          " flags=" & $typ.flagsImpl & " sons=" & sons &
          " owner=" & (if typ.ownerFieldImpl != nil: typ.ownerFieldImpl.name.s else: "-")
    dest.addSymUse pool.syms.getOrIncl(nifTypeName(w, typ)), NoLineInfo
  elif typ.itemId.module == w.currentModule and typ.state == Complete:
    # Ownership for serialization is `itemId.module`, the module that CREATED
    # the type: the NIF name (`typeToNifSym`) and the loader (`createTypeStub`)
    # both key off `itemId`. Never gate this on `bindingId`, which a replica
    # inherits from another module -- that filed defs in the wrong module (or
    # nowhere), leaving dangling references (`symbol has no offset` for a
    # `pointer` type whose id had drifted away).
    typ.state = Sealed
    if restoresWrittenState(w.infos.config): w.writtenTypes.add typ
    if isCanonType(w, typ): w.emittedCanonTypes[nifTypeName(w, typ)] = typ.itemId.item
    writeTypeDef(w, dest, typ)
  else:
    dest.addSymUse pool.syms.getOrIncl(nifTypeName(w, typ)), NoLineInfo

proc writeBool(dest: var IcBuilder; b: bool) =
  dest.buildTree (if b: "true" else: "false"):
    discard

proc writeLib(w: var Writer; dest: var IcBuilder; lib: PLib) =
  if lib == nil:
    dest.addDotToken()
  else:
    dest.buildTree toNifTag(lib.kind):
      dest.writeBool lib.generated
      dest.writeBool lib.isOverridden
      dest.addStrLit lib.name
      writeNode w, dest, lib.path

proc docOfSym(sym: PSym): string =
  ## The `##` doc comment documenting `sym`, if any (mirrors nifler's
  ## docCommentOf). The comment may sit on the decl node itself or as the first
  ## `nkCommentStmt` of a routine body. Carried separately on the sym def's NIF
  ## token because the AST serialization drops comments — nimsuggest needs it
  ## for "find definition" doc hovers.
  let n = sym.astImpl
  if n == nil or nodeCommentReader == nil: return ""
  let own = nodeCommentReader(n)
  if own.len > 0: return own
  if sym.kindImpl in routineKinds and n.safeLen > bodyPos:
    let body = n[bodyPos]
    if body != nil and body.kind == nkStmtList and body.len > 0 and
       body[0].kind == nkCommentStmt:
      return nodeCommentReader(body[0])
  return ""

proc writeSymDef(w: var Writer; dest: var IcBuilder; sym: PSym) =
  dest.addParLe sdefTag, nifLineInfoWithComment(w.infos, sym.infoImpl, docOfSym(sym))
  dest.addSymDef pool.syms.getOrIncl(w.toNifSymName(sym)), NoLineInfo
  # The `x` marker means "importable as a bare identifier into an importer's
  # scope". Object fields carry `sfExported` (so they are visible via `obj.field`
  # across modules) but must NOT become bare-importable: otherwise an exported
  # field name (e.g. `HSlice.a`, whose type is a generic param `T`) leaks into
  # module scope and a template's open/mixin symbol of the same name resolves to
  # the field instead of a local, producing "type mismatch: got 'T'". Fields are
  # still indexed (for `obj.field` resolution via the loaded object type); they
  # are merely not advertised as importable. Plain `skEnumField` stays importable
  # — enum values are legitimately usable as bare identifiers — but a field of a
  # `{.pure.}` enum is NOT: the source path keeps pure fields out of the importer
  # scope (`declarePureEnumField`), reachable only qualified or via the restricted
  # pure-enum mechanism (`importPureEnumFields`, fed by `ifaces[].pureEnums` which
  # a loaded module rebuilds from its `PureEnumEntry` log ops). Marking them
  # bare-importable made a loaded pure enum's fields leak into module scope
  # (`populateInterfaceTablesFromIndex` adds every `x`/Exported sym to `interf`),
  # e.g. nim-json-serialization's pure `JsonValueKind.Number` shadowing web3's
  # `Number = distinct uint64` so `uint64(x).Number` failed under `nim ic`
  # ("undeclared field 'Number'").
  let isPureEnumField = sym.kindImpl == skEnumField and sym.typImpl != nil and
    sym.typImpl.symImpl != nil and sfPure in sym.typImpl.symImpl.flagsImpl
  # `sfExported` is the declaration's `*`. An explicit `export s` makes a symbol
  # importable WITHOUT it (semExport -> reexportSym -> the interface table only),
  # so ask the interface as well or those symbols ship as non-importable and the
  # importer reports "undeclared identifier".
  if sym.kindImpl != skField and not isPureEnumField and
      ({sfExported, sfFromGeneric} * sym.flagsImpl == {sfExported} or
       sym.itemId in w.extraExports):
    dest.addIdent "x"
  else:
    dest.addDotToken
  # field `disamb` made part of the name, so do not store it here
  dest.buildTree sym.kindImpl.toNifTag:
    case sym.kindImpl
    of skLet, skVar, skField, skForVar:
      writeSym(w, dest, sym.guardImpl)
      dest.addIntLit sym.bitsizeImpl
      dest.addIntLit sym.alignmentImpl
    else:
      discard

  if sym.magicImpl == mNone:
    dest.addDotToken
  else:
    dest.addIdent toNifTag(sym.magicImpl)
  writeFlags(dest, sym.flagsImpl)
  writeFlags(dest, sym.optionsImpl)
  dest.addIntLit sym.offsetImpl

  if sym.kindImpl == skModule:
    dest.addDotToken() # position will be set by the loader!
  elif sym.kindImpl in {skVar, skLet, skForVar, skResult}:
    dest.addIntLit 0  # hack for the VM which uses this field to store information
  else:
    dest.addIntLit sym.positionImpl

  writeLib(w, dest, sym.annexImpl)

  # Generic params are written as *global* symbols (with a module suffix) so that
  # they get their own index entries and can be looked up lazily. This matters for
  # generic routines that have a separate forward declaration and implementation:
  # the two share the same generic param symbols, but each is serialized as its own
  # index entry. If the params were local, a reference from the implementation's
  # entry could not resolve the sdef emitted in the forward declaration's entry.
  writeType(w, dest, sym.typImpl)
  writeSym(w, dest, sym.ownerFieldImpl)
  # Store the AST for routine symbols and constants
  # Constants need their AST for astdef() to return the constant's value
  writeNode(w, dest, sym.astImpl, forAst = true)
  writeLoc w, dest, sym.locImpl
  writeNode(w, dest, sym.constraintImpl)
  writeSym(w, dest, sym.instantiatedFromImpl)
  # The TRANSFORMED body (ic_ideas.md 2-way body): a routine run at compile time
  # (macro / VM transform / `static`) already has its lowered body — closure
  # `:env` and all — computed during sem; serialize it so the backend reuses it
  # instead of re-deriving (the divergence behind the t17.275 env class). An
  # empty `.` here means "same as the semchecked body OR to be found in the
  # `.t.nif`" (the `lower` stage fills that gap). Non-routines / not-yet-
  # transformed routines write the empty marker. (`transformedBodyImpl` only
  # exists in the routine branch of the `TSym` variant.)
  if sym.kindImpl in routineKinds:
    writeNode(w, dest, sym.transformedBodyImpl)
  else:
    dest.addDotToken
  dest.addParRi


proc shouldWriteSymDef(w: var Writer; sym: PSym): bool {.inline.} =
  # Don't write module/package symbols - they don't have NIF files
  if sym.kindImpl == skPackage:
    return not w.writtenPackages.containsOrIncl(sym.name.s)
  # Already written - don't write again
  if sym.state == Sealed:
    return false
  # If the symbol belongs to current module and would be written WITHOUT module suffix
  # (due to being in w.locals or being in skLocalSymKinds), it MUST have an sdef.
  # Otherwise it gets written as a bare SymUse and can't be found when loading.
  if sym.itemId.module == w.currentModule:
    if sym.itemId in w.locals or isLocalSym(sym):
      return true  # Would be written without module suffix, needs sdef
    if sym.state == Complete:
      return true  # Normal case for global symbols
  return false

proc fieldDefHere(w: var Writer; sym: PSym): bool {.inline.} =
  ## An object field is a LOCAL symbol (see `FieldMarker`): it is DEF'd exactly once
  ## — inline in its owning type's reclist — and referenced as a bare `SymUse`
  ## everywhere else (resolved by the consumer re-navigating the object type by
  ## name; nothing else to recover). So write a def iff we are inside that reclist
  ## (`inTypeReclist > 0`); `emittedFieldSyms` guards against a field appearing
  ## twice in one reclist (e.g. a discriminant). Each type's reclist is thus
  ## self-contained, which is what a seek-load of a single `.t.bif` type entry needs.
  sym.kindImpl == skField and w.inTypeReclist > 0 and
    not w.emittedFieldSyms.containsOrIncl(sym.itemId)

proc writeSym(w: var Writer; dest: var IcBuilder; sym: PSym) =
  if sym == nil:
    dest.addDotToken()
  elif sym.kindImpl == skField:
    if fieldDefHere(w, sym):
      writeSymDef(w, dest, sym)
    else:
      dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), NoLineInfo
  elif sym.itemId.isBackendMinted:
    # Process-local backend sym (closure env field / hidden `:env` param): emit a
    # MODULE-LOCAL `@bk` def the first time, reference it after. Per-Writer dedup.
    if not w.emittedBackendSyms.containsOrIncl(sym.itemId.item):
      writeSymDef(w, dest, sym)
    else:
      dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), NoLineInfo
  elif shouldWriteSymDef(w, sym):
    sym.state = Sealed
    if restoresWrittenState(w.infos.config): w.writtenSyms.add sym
    writeSymDef(w, dest, sym)
  else:
    # NIF has direct support for symbol references so we don't need to use a tag here,
    # unlike what we do for types!
    dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), NoLineInfo

proc writeSymNode(w: var Writer; dest: var IcBuilder; n: PNode; sym: PSym) =
  if sym == nil:
    dest.addDotToken()
    return
  # Compare lazy-aware, not the raw field: a sym node loaded from a NIF carries
  # `typField == nil` plus `nfLazyType`, meaning "my type is the symbol's
  # type". Comparing `typField` directly would re-serialize such a node as
  # `(ht . sym)` — an explicitly nil node type — and the next loader gets a
  # nil-typed node *without* the lazy fallback (semfold & friends crash on
  # `n.typ == nil`). Only a genuinely nil node type keeps the explicit form.
  # (ast.nim's `typ` accessor is not importable here; replicate its fallback.
  # For a still-Partial sym `typImpl` is nil, which also compares equal below
  # and yields the plain SymUse form — exactly the lazy round-trip we want.)
  var nodeTyp = n.typField
  if nodeTyp == nil and nfLazyType in n.flags:
    nodeTyp = sym.typImpl
  # Backend-minted syms (process-local closure `:env` param/fields) are emitted
  # as MODULE-LOCAL `@bk` defs the first time reached this module (per-Writer
  # dedup shared with `writeSym`), regardless of module: their itemId.module is
  # the systemModule of `vmTransfIdgen`, so `shouldWriteSymDef` (which gates on
  # currentModule) would otherwise only ever emit a SymUse → dangling def.
  let isField = sym.kindImpl == skField
  let wantDef =
    if isField: fieldDefHere(w, sym)  # def only inside the owning reclist (see fieldDefHere)
    elif sym.itemId.isBackendMinted: not w.emittedBackendSyms.containsOrIncl(sym.itemId.item)
    else: shouldWriteSymDef(w, sym)
  if wantDef:
    if not sym.itemId.isBackendMinted and not isField: sym.state = Sealed
    if restoresWrittenState(w.infos.config): w.writtenSyms.add sym
    if nodeTyp != n.sym.typImpl:
      dest.buildTree hiddenTypeTag, trLineInfo(w, n.info):
        writeType(w, dest, nodeTyp)
        writeSymDef(w, dest, sym)
    else:
      writeSymDef(w, dest, sym)
  else:
    # NIF has direct support for symbol references so we don't need to use a tag here,
    # unlike what we do for types!
    let info = trLineInfo(w, n.info)
    # A field SymUse is a typeless leaf stub on load (its def lives in another seek),
    # so it cannot supply a lazy type — carry its type EXPLICITLY via the hidden-type
    # wrapper. `genFieldObjConstr`/object-init read `nField.typ` directly, so the node
    # must keep it. A field-use node often has a nil node-type (the type lives on the
    # sym), so fall back to the field sym's own type.
    if isField:
      let fieldTyp = if nodeTyp != nil: nodeTyp else: sym.typImpl
      dest.buildTree hiddenTypeTag, info:
        writeType(w, dest, fieldTyp)
        dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), info
    elif nodeTyp != n.sym.typImpl:
      dest.buildTree hiddenTypeTag, info:
        writeType(w, dest, nodeTyp)
        dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), info
    else:
      dest.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), info

proc writeNodeFlags(dest: var IcBuilder; flags: set[TNodeFlag]) {.inline.} =
  # Comment text is not stored in NIF; `nfHasComment` is process-local
  # (see `comment` in ast.nim). Emitting it made IC non-deterministic:
  # `copyTree` from a parsed generic kept the comment (`"sh"`) while
  # `copyTree` from a cache-loaded generic did not (`"s"`).
  writeFlags(dest, flags - {nfHasComment})

template withNode(w: var Writer; dest: var IcBuilder; n: PNode; body: untyped) =
  dest.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), trLineInfo(w, n.info)
  writeNodeFlags(dest, n.flags)
  writeType(w, dest, n.typField)
  body
  dest.addParRi

proc addLocalSym(w: var Writer; n: PNode) =
  ## Previously forced proc-local symbols to be written without a module suffix.
  ## All symbols are now emitted as global (see `isLocalSym`), so `w.locals` is
  ## intentionally left empty.
  discard

proc addLocalSyms(w: var Writer; n: PNode) =
  case n.kind
  of nkIdentDefs, nkVarTuple:
    # nkIdentDefs: [ident1, ident2, ..., type, default]
    # All children except the last two are identifiers
    for i in 0 ..< max(0, n.len - 2):
      addLocalSyms(w, n[i])
  of nkPostfix:
    addLocalSyms(w, n[1])
  of nkPragmaExpr:
    addLocalSyms(w, n[0])
  of nkSym:
    addLocalSym(w, n)
  else:
    discard

proc trInclude(w: var Writer; n: PNode) =
  w.deps.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), trLineInfo(w, n.info)
  w.deps.addDotToken # flags
  w.deps.addDotToken # type
  for child in n:
    assert child.kind == nkStrLit
    w.deps.addStrLit child.strVal  # raw string literal, no wrapper needed
  w.deps.addParRi

proc moduleSuffix(conf: ConfigRef; f: FileIndex): string =
  cachedModuleSuffix(conf, f)

proc trImport(w: var Writer; n: PNode) =
  for child in n:
    if child.kind == nkSym and child.sym.kindImpl == skModule:
      # a non-module sym appears for an `import v` inside an unexpanded
      # template body (e.g. stew/importops' `when compiles((; import v))`):
      # not a dependency edge, the import resolves at the expansion site
      w.deps.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), trLineInfo(w, n.info)
      w.deps.addDotToken # flags
      w.deps.addDotToken # type
      let s = child.sym
      let fp = moduleSuffix(w.infos.config, s.positionImpl.FileIndex)
      w.deps.addStrLit fp  # raw string literal, no wrapper needed
      w.deps.addParRi
      w.depSuffixes.incl fp

proc trExport(w: var Writer; n: PNode) =
  # Collect export information for the index
  # nkExportStmt children are nkSym nodes
  # When exporting a module (export dollars), the module symbol is a child
  # followed by all symbols from that module - we use empty set to mean "export all"
  # When exporting specific symbols (export foo, bar), we collect their names
  w.deps.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), trLineInfo(w, n.info)
  w.deps.addDotToken # flags
  w.deps.addDotToken # type
  for child in n:
    if child.kind == nkSym:
      let s = child.sym
      if s.kindImpl == skModule:
        discard "do not write module syms here"
      else:
        w.deps.addSymUse pool.syms.getOrIncl(w.toNifSymName(s)), NoLineInfo
  w.deps.addParRi

var replayTag = registerTag("replay")
var repConverterTag = registerTag("repconverter")
var repDestroyTag = registerTag("repdestroy")
var repWasMovedTag = registerTag("repwasmoved")
var repCopyTag = registerTag("repcopy")
var repSinkTag = registerTag("repsink")
var repDupTag = registerTag("repdup")
var repTraceTag = registerTag("reptrace")
var repDeepCopyTag = registerTag("repdeepcopy")
var repEnumToStrTag = registerTag("repenumtostr")
var repMethodTag = registerTag("repmethod")
var repPureEnumTag = registerTag("reppureenum")
var repCppMemberTag = registerTag("repcppmember")
#var repClassTag = registerTag("repclass")
var includeTag = registerTag("include")
var importTag = registerTag("import")
var implTag = registerTag("implementation")
var reexpModTag = registerTag("reexpmod")
var offerTag = registerTag("offer")
var typeOfferTag = registerTag("toffer")
var modulesrcTag = registerTag("modulesrc")
var expansionTag = registerTag("expansion")
# `(sig <symUse @src>)*` — signature occurrences (parameter names and the symbols
# in their type expressions). A semchecked routine's params are dropped from the
# serialized AST (`skipParams`) and reconstructed from `s.typ`, which holds the
# RESOLVED type — so the source parameter names and the written type names (e.g.
# an alias `Stream`, not `StreamObj`) carry no position in the module body. Like
# the `expansion` records, these are teed into the `deps` side-channel: the loader
# skips the tag, but `idetools` scans every Symbol token, so goto-def / find-usages
# work on signatures.
var sigTag = registerTag("sig")
# `(unusedid <int>)` — the module's first FREE itemId after the frontend
# (`.s.bif`) or the lower stage (`.t.bif`). The backend seeds its per-module
# sym/type counters here so freshly-minted backend ids (closure envs, RTTI
# hooks, temps) start ABOVE every loaded id — no `toId` collision is possible
# by construction (replaces relying on the `@bk` module-marker bit, which the
# loader dropped on type USES). Mirrors NIF's `.unusedname` directive.
var unusedIdTag = registerTag("unusedid")
# `(modflags <int>)` — the MODULE symbol's backend-relevant flags. Only
# `sfInjectDestructors` (bit 0) so far: sempass2 sets it on the module sym when
# the module's TOP-LEVEL statements need the destructor pass, and `cgen.
# genTopLevelStmt` gates `injectDestructorCalls` on it. `moduleFromNifFile`
# builds the module PSym from scratch, so without this record the flag was lost
# and a NIF-loaded module's top-level locals were never destroyed (`block: let
# h = openHandle()` leaked, silently and only under `nim ic`).
const ModFlagInjectDestructors* = 1'i32
var modFlagsTag = registerTag("modflags")

# `(nflags <ident> <symuse>)` — an `nkSym` NODE's own flags. A sym node is
# normally emitted as a bare NIF `SymUse` token, which has nowhere to put them,
# so every node flag on a sym use was silently dropped. Two of those flags are
# the frontend's move/first-write analysis results (`nfFirstWrite`, `nfLastRead`,
# both listed in `PersistentNodeFlags`) that `injectdestructors` reads in the
# backend: without them EVERY first assignment to a destructor-bearing local
# compiled as `=sink` (i.e. `=destroy` on still-zeroed memory, then a copy)
# instead of a plain construction, and no read was ever recognised as a move.
# Only wrap when there is something to say, so the common sym use stays a bare
# token.
const symNodeFlagsTagName* = "nflags"
var symNodeFlagsTag = registerTag(symNodeFlagsTagName)
const PersistedSymNodeFlags = PersistentNodeFlags - {nfLazyType, nfHasComment}

proc registerNifAstTags*() =
  ## (Re)registers ast2nif's NIF tags explicitly. The top-level `registerTag`
  ## initializers above depend on `nifstreams.pool` having been initialized
  ## FIRST (`pool = createLiterals(TagData)` in nifstreams' module init) — an
  ## inter-module init-order requirement. The IC-built compiler currently emits
  ## module init calls in a different order, so the initializers registered
  ## into a pool that was subsequently replaced: the tag ids then denoted
  ## builtin tags (`replay` came out as `deref`, `repdestroy` as `pat`, ...)
  ## and every written NIF was silently corrupted. Called from `nim.nim`
  ## before any command runs; idempotent (`getOrIncl` by name).
  sdefTag = registerTag(symDefTagName)
  tdefTag = registerTag(typeDefTagName)
  hiddenTypeTag = registerTag(hiddenTypeTagName)
  bindingIdTag = registerTag(bindingIdTagName)
  modFlagsTag = registerTag("modflags")
  symNodeFlagsTag = registerTag(symNodeFlagsTagName)
  replayTag = registerTag("replay")
  repConverterTag = registerTag("repconverter")
  repDestroyTag = registerTag("repdestroy")
  repWasMovedTag = registerTag("repwasmoved")
  repCopyTag = registerTag("repcopy")
  repSinkTag = registerTag("repsink")
  repDupTag = registerTag("repdup")
  repTraceTag = registerTag("reptrace")
  repDeepCopyTag = registerTag("repdeepcopy")
  repEnumToStrTag = registerTag("repenumtostr")
  repMethodTag = registerTag("repmethod")
  repPureEnumTag = registerTag("reppureenum")
  repCppMemberTag = registerTag("repcppmember")
  includeTag = registerTag("include")
  importTag = registerTag("import")
  implTag = registerTag("implementation")
  reexpModTag = registerTag("reexpmod")
  offerTag = registerTag("offer")
  typeOfferTag = registerTag("toffer")
  modulesrcTag = registerTag("modulesrc")
  expansionTag = registerTag("expansion")
  sigTag = registerTag("sig")

proc emitSigOccurrences(w: var Writer; n: PNode) =
  ## Record every `nkSym` in a routine-signature subtree (parameter names and the
  ## symbols inside their type expressions, incl. the return type) as a `(sig ...)`
  ## occurrence in the `deps` side-channel, carrying the SOURCE position. Called on
  ## the params AST that `skipParams` is about to drop, so tooling keeps a
  ## positioned token for each signature symbol without changing the module body
  ## the loader / backend actually consume.
  if n == nil: return
  if n.kind == nkSym:
    w.deps.addParLe sigTag, NoLineInfo
    w.deps.addSymUse pool.syms.getOrIncl(w.toNifSymName(n.sym)), trLineInfo(w, n.info)
    w.deps.addParRi
  else:
    for i in 0 ..< n.safeLen: emitSigOccurrences(w, n[i])

proc emitFwdDecl(w: var Writer; n: PNode; sym: PSym) =
  ## A routine's forward declaration (`proc foo(...)` with no body, later followed
  ## by `proc foo(...) = ...`) is a distinct top-level node, but the routine has a
  ## SINGLE `sdef`, emitted at the IMPLEMENTATION site (`sym.infoImpl`) — so the
  ## prototype's own position would otherwise vanish from the `.bif`. Tee it into
  ## the `deps` side-channel as a POSITIONED `(sig @proto <symDef>)`: the loader
  ## skips the `sig` tag (processTopLevel), but `idetools.scanDef` finds the
  ## `SymbolDef` and reports the enclosing tag's line info — so a `--def` on a
  ## forward-declared proc returns TWO results (prototype + implementation), which
  ## is desired. Safe against symbol resolution: the loader rebuilds its name->pos
  ## table from the CONTENT body (`buildPosIndex`, written after `deps`, last write
  ## wins) so the real `sdef` still resolves; the extra on-disk index entry has no
  ## resolution consumer. The prototype's signature symbols (param names and the
  ## symbols in their type expressions) are teed too, positioned at the prototype,
  ## exactly as `emitSigOccurrences` records them for the implementation.
  # The `SymbolDef` carries the prototype line info too (not just the enclosing
  # tag): `scanDef` reads the position from the tag, but pass-1 `findPos` matches
  # a token by its OWN line info, so this is what makes a query issued AT the
  # prototype position resolve the symbol.
  let protoInfo = trLineInfo(w, n[namePos].info)
  let sid = pool.syms.getOrIncl(w.toNifSymName(sym))
  w.deps.addParLe sigTag, protoInfo
  w.deps.addSymDef sid, protoInfo   # scanDef reports this as a def
  w.deps.addSymUse sid, protoInfo   # findPos (pass 1) / scanUses match a Symbol use
  w.deps.addParRi
  if sfFromGeneric notin sym.flagsImpl and paramsPos < n.safeLen:
    emitSigOccurrences(w, n[paramsPos])

proc writeNode(w: var Writer; dest: var IcBuilder; n: PNode; forAst = false) =
  if n == nil:
    dest.addDotToken
  else:
    if nfLazyBody in n.flags and forceLazyBodyHook != nil:
      # Materialize a deferred body before serializing so its real flags/typ and
      # children are written (never the empty `nfLazyBody` placeholder).
      forceLazyBodyHook(n)
    case n.kind
    of nkNone:
      assert n.typField == nil, "nkNone should not have a type"
      let info = trLineInfo(w, n.info)
      dest.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), info
      dest.addParRi
    of nkEmpty:
      if n.typField != nil:
        w.withNode dest, n:
          discard
      else:
        let info = trLineInfo(w, n.info)
        dest.addParLe pool.tags.getOrIncl(toNifTag(n.kind)), info
        dest.addParRi
    of nkIdent:
      # nkIdent uses flags and typ when it is a generic parameter
      w.withNode dest, n:
        dest.addIdent n.ident.s
    of nkSym:
      let persisted = n.flags * PersistedSymNodeFlags
      if persisted == {}:
        writeSymNode(w, dest, n, n.sym)
      else:
        dest.addParLe symNodeFlagsTag, trLineInfo(w, n.info)
        writeFlags(dest, persisted)
        writeSymNode(w, dest, n, n.sym)
        dest.addParRi
    of nkCharLit:
      w.withNode dest, n:
        dest.add charToken(n.intVal.char, NoLineInfo)
    of nkIntLit .. nkInt64Lit:
      w.withNode dest, n:
        dest.addIntLit n.intVal
    of nkUIntLit .. nkUInt64Lit:
      w.withNode dest, n:
        dest.addUIntLit cast[BiggestUInt](n.intVal)
    of nkFloatLit .. nkFloat128Lit:
      w.withNode dest, n:
        dest.add floatToken(pool.floats.getOrIncl(n.floatVal), NoLineInfo)
    of nkStrLit .. nkTripleStrLit:
      w.withNode dest, n:
        dest.addStrLit n.strVal
    of nkNilLit:
      w.withNode dest, n:
        discard
    of nkLetSection, nkVarSection, nkConstSection:
      # Track local variables declared in let/var sections
      w.withNode dest, n:
        for child in n:
          addLocalSyms w, child
          # Process the child node
          writeNode(w, dest, child, forAst)
    of nkForStmt:
      # Track for loop variable (first child is the loop variable)
      w.withNode dest, n:
        if n.len > 0:
          addLocalSyms(w, n[0])
        for i in 0 ..< n.len:
          writeNode(w, dest, n[i], forAst)
    of nkFormalParams:
      # Track parameters (first child is return type, rest are parameters)
      inc w.inProc
      w.withNode dest, n:
        for i in 0 ..< n.len:
          if i > 0:  # Skip return type
            addLocalSyms(w, n[i])
          writeNode(w, dest, n[i], forAst)
      dec w.inProc
    of nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef, nkMacroDef, nkTemplateDef:
      # For top-level named routines (not forAst), just write the symbol.
      # The full AST will be stored in the symbol's sdef.
      if not forAst and n[namePos].kind == nkSym:
        let s = n[namePos].sym
        writeSym(w, dest, s)
        # A forward declaration is a SECOND top-level node for `s` (body-less here;
        # the real body — and the lone sdef — lands at the implementation). Tee the
        # prototype's own position so goto-def / find-usages surface it as well.
        let impl = s.astImpl
        if n.safeLen > bodyPos and n[bodyPos].kind == nkEmpty and
           impl != nil and impl != n and
           impl.safeLen > bodyPos and impl[bodyPos].kind != nkEmpty:
          emitFwdDecl(w, n, s)
      else:
        # Writing AST inside sdef or anonymous proc: write full structure
        inc w.inProc
        var ast = n
        var skipParams = false
        if n[namePos].kind == nkSym:
          ast = n[namePos].sym.astImpl
          if ast == nil: ast = n
          else:
            # params can only be recovered from `sym.typ.n` if the routine
            # was actually semchecked. A routine nested in a TEMPLATE body
            # (e.g. faststreams' `proc consumer(bytesVar: openArray[byte])
            # {.gensym.}` inside `consumeOutputs`) has a sym but a nil type —
            # its params exist only in the AST; dropping them broke the
            # template-param substitution at expansion ("undeclared
            # identifier" for the injected name).
            skipParams = n[namePos].sym.typImpl != nil
        w.withNode dest, ast:
          for i in 0 ..< ast.len:
            if i == paramsPos and skipParams:
              # The dropped params still hold the source positions and the WRITTEN
              # type names (before alias/type resolution); tee them into the `deps`
              # side-channel for goto-def / find-usages (see `emitSigOccurrences`).
              # Skip generic INSTANCES: their param syms are instance-specific, and
              # the generic's own signature already records the source occurrences.
              if sfFromGeneric notin n[namePos].sym.flagsImpl:
                emitSigOccurrences(w, ast[i])
              # Parameters are redundant with s.typ.n (and re-emitting their syms
              # is dangerous for generic instances — we do not adapt the symbols
              # properly). Emit an `nkEmpty` placeholder rather than a dot token:
              # a dot loads back as a `nil` son, but ast children must be real
              # nodes — the loaded routine ast is walked by passes (lambdalifting,
              # liftdestructors, transf) that dereference `ast[paramsPos]`, and
              # `nkEmpty` is the canonical empty slot. The actual params are
              # recovered from `sym.typ.n` where needed.
              dest.addParLe pool.tags.getOrIncl(toNifTag(nkEmpty)), NoLineInfo
              dest.addParRi
            else:
              writeNode(w, dest, ast[i], forAst)
        dec w.inProc
    of nkLambda, nkDo:
      # Lambdas are expressions, always write full structure
      inc w.inProc
      var ast = n
      if n[namePos].kind == nkSym:
        ast = n[namePos].sym.astImpl
        if ast == nil: ast = n
      w.withNode dest, ast:
        for i in 0 ..< ast.len:
          writeNode(w, dest, ast[i], forAst)
      dec w.inProc
    of nkImportStmt:
      if w.inProc > 0:
        # An `import` inside a template/macro/proc body — e.g. stew/importops'
        # `tryImport`: `when compiles((; import v)): import v`. It is part of the
        # body AST and must be serialized as a real node so the template
        # re-expands it at each use site; it is NOT a module-level dependency
        # edge (the import resolves where the template expands, against that
        # module's deps). Diverting it to `w.deps` (the top-level path below)
        # dropped it entirely: its child is the unexpanded template parameter
        # `v`, not a module sym, so `trImport` wrote nothing and the body
        # round-tripped EMPTY — a NIF-loaded `tryImport` then imported nothing.
        w.withNode dest, n:
          for i in 0 ..< n.len:
            writeNode(w, dest, n[i], forAst)
      else:
        # top-level import: recorded as a dependency edge — `importer.nim` has
        # already transformed `n` to contain a list of module syms.
        trImport w, n
    of nkIncludeStmt:
      trInclude w, n
    of nkExportStmt, nkExportExceptStmt:
      # Note: nkExportExceptStmt is transformed to nkExportStmt by semExportExcept,
      # but we handle both just in case
      trExport w, n
    else:
      w.withNode dest, n:
        for i in 0 ..< n.len:
          writeNode(w, dest, n[i], forAst)

proc writeGlobal(w: var Writer; dest: var IcBuilder; n: PNode) =
  case n.kind
  of nkVarTuple:
    writeNode(w, dest, n)
  of nkIdentDefs, nkConstDef:
    # nkIdentDefs: [ident1, ident2, ..., type, default]
    # All children except the last two are identifiers
    for i in 0 ..< max(0, n.len - 2):
      writeGlobal(w, dest, n[i])
  of nkPostfix:
    writeGlobal(w, dest, n[1])
  of nkPragmaExpr:
    writeGlobal(w, dest, n[0])
  of nkSym:
    writeSym(w, dest, n.sym)
  else:
    discard

proc writeGlobals(w: var Writer; dest: var IcBuilder; n: PNode) =
  w.withNode dest, n:
    for child in n:
      writeGlobal(w, dest, child)

proc writeToplevelNode(w: var Writer; dest, bottom: var IcBuilder; n: PNode) =
  case n.kind
  of nkStmtList, nkStmtListExpr:
    for son in n: writeToplevelNode(w, dest, bottom, son)
  of nkEmpty:
    discard "ignore"
  of nkTypeSection, nkCommentStmt, nkMixinStmt, nkBindStmt, nkUsingStmt,
     nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef, nkMacroDef, nkTemplateDef:
    # We write purely declarative nodes at the bottom of the file
    writeNode(w, bottom, n)
  of nkPragma:
    # Top-level pragmas — chiefly `{.emit.}`, plus the `{.push/pop.}` that guard
    # its neighbours — must survive the backend reload so the `cg` stage re-runs
    # genPragma/genEmit. The bottom (implementation) section is reloaded lazily
    # BY SYMBOL INDEX, which a symbol-less pragma can never be on, so a pragma
    # written there is silently dropped on reload (e.g. a module-level `#include`
    # vanishes and the generated C fails to compile). The header init section is
    # replayed verbatim by `processTopLevel`, so write it there instead.
    writeNode(w, dest, n)
  of nkConstSection:
    writeGlobals(w, bottom, n)
  of nkLetSection, nkVarSection:
    writeGlobals(w, dest, n)
  else:
    writeNode w, dest, n

proc createStmtList(buf: var IcBuilder; info: PackedLineInfo) {.inline.} =
  buf.addParLe pool.tags.getOrIncl(toNifTag(nkStmtList)), info
  buf.addDotToken # flags
  buf.addDotToken # type

proc writeOp(w: var Writer; content: var IcBuilder; op: LogEntry) =
  case op.kind
  of HookEntry:
    case op.op
    of attachedDestructor:
      content.addParLe repDestroyTag, NoLineInfo
    of attachedAsgn:
      content.addParLe repCopyTag, NoLineInfo
    of attachedWasMoved:
      content.addParLe repWasMovedTag, NoLineInfo
    of attachedDup:
      content.addParLe repDupTag, NoLineInfo
    of attachedSink:
      content.addParLe repSinkTag, NoLineInfo
    of attachedTrace:
      content.addParLe repTraceTag, NoLineInfo
    of attachedDeepCopy:
      content.addParLe repDeepCopyTag, NoLineInfo
    content.add strToken(pool.strings.getOrIncl(op.key), NoLineInfo)
    content.add symToken(pool.syms.getOrIncl(w.toNifSymName(op.sym)), NoLineInfo)
    content.addParRi()
  of ConverterEntry:
    content.addParLe repConverterTag, NoLineInfo
    content.add strToken(pool.strings.getOrIncl(op.key), NoLineInfo)
    content.add symToken(pool.syms.getOrIncl(w.toNifSymName(op.sym)), NoLineInfo)
    content.addParRi()
  of MethodEntry:
    content.addParLe repMethodTag, NoLineInfo
    content.add strToken(pool.strings.getOrIncl(op.key), NoLineInfo)
    content.add symToken(pool.syms.getOrIncl(w.toNifSymName(op.sym)), NoLineInfo)
    content.addParRi()
  of EnumToStrEntry:
    content.addParLe repEnumToStrTag, NoLineInfo
    content.add strToken(pool.strings.getOrIncl(op.key), NoLineInfo)
    content.add symToken(pool.syms.getOrIncl(w.toNifSymName(op.sym)), NoLineInfo)
    content.addParRi()
  of PureEnumEntry:
    content.addParLe repPureEnumTag, NoLineInfo
    content.add strToken(pool.strings.getOrIncl(op.key), NoLineInfo)
    content.add symToken(pool.syms.getOrIncl(w.toNifSymName(op.sym)), NoLineInfo)
    content.addParRi()
  of CppMemberEntry:
    content.addParLe repCppMemberTag, NoLineInfo
    content.add strToken(pool.strings.getOrIncl(op.key), NoLineInfo)
    content.add symToken(pool.syms.getOrIncl(w.toNifSymName(op.sym)), NoLineInfo)
    content.addParRi()
  of GenericInstEntry:
    discard "will only be written later to ensure it is materialized"

# --------------------------- Interface cookie ---------------------------
#
# Port of Nimony's `processForChecksum` (dist/nimony/src/lib/nifindexes.nim):
# ONE checksum per module over the importer-visible surface, stored in a tiny
# `<suffix>.iface.nif` sidecar written OnlyIfChanged. deps.nim points the
# dependents' `nim_m` build edges at the sidecar instead of the bulky semmed
# NIF, so nifmake's mtime pruning stops the m-step cascade at the first
# module whose interface did not change.
#
# Hashed (importer-visible surface):
# - import/include/export entries, `(replay ...)` macro-cache actions and the
#   rep* hook/converter/enumtostr registrations (all eagerly consumed by every
#   importer's sem via processTopLevel/loadTransitiveHooks).
# - every EXPORTED `(sd ...)`: full content for consts/types/vars/lets; for
#   EVERY routine kind (plain procs, templates, macros, iterators, generics,
#   `inline` procs alike) only the SIGNATURE — the body is skipped. A routine
#   body is invisible to a dependent's SEM unless the dependent expands /
#   instantiates / VM-runs it, and each of those records a NeedsImpl (strong)
#   edge gating the dependent on this module's IMPL cookie instead (see
#   `cookieSd`). This keeps the iface cookie body-insensitive, so a body edit
#   re-sems only the modules that actually consumed that body — not every
#   importer (the old model folded inline-semantics bodies into the iface
#   cookie, re-semming all importers on any such body edit).
# - nothing else: private defs and top-level init code are invisible to
#   importers' sem (their effects on dependents' CODEGEN — and the codegen
#   effect of inline iterator/proc body edits — are covered by the nifc
#   backend's transitive NIF-mtime invalidation, which is unchanged).
#
# Token-content hashing only — line infos never enter the hash. Names DEFINED
# inside a hashed (sd) (params, locals, the embedded `(td `tK.item.mod)` defs)
# are replaced by per-sd ordinals and module-local `tK.item references are
# replaced by their structural td hash: both carry process-local mint counters
# that shift file-wide when an unrelated body creates a new type (measured:
# a single new instantiation renumbered every later signature), while
# dependents never reference them by name (verified over a full compiler
# cache: cross-module refs hit only top-level routine names).
#
# The cookie finally mixes in the DIRECT dependencies' sidecar contents
# ("hash chaining"): an interface change then propagates transitively
# level-by-level even when an intermediate module's own surface is unchanged
# (its sem still consumed the dep's surface, e.g. via the transitive hook
# replay). Chaining also guarantees a fired rule refreshes its sidecar mtime,
# which nifmake's max-output `needsRebuild` needs to not re-fire forever.
#
# The IMPL cookie (`<suffix>.impl.nif`) complements it: a line-info-free hash
# of the module's ENTIRE content with the iface cookie mixed in. Dependents
# that consumed this module's bodies at compile time (recorded in the
# `.edges.nif` sidecar; see `ModuleGraph.icImplDeps`) are gated on it instead.

type
  CookieCtx = object
    selfSuffix: string
    tdRanges: Table[uint32, int]   # td sym -> start of its first (td ...) tree
    memo: Table[uint32, string]    # td sym -> structural digest
    expanding: HashSet[uint32]     # cycle guard for recursive td expansion
    depSuffixes: seq[string]       # module suffixes of the direct imports

proc nextTree(flat: seq[CookieTok]; i: int): int =
  ## Index just past the atom or balanced subtree starting at `i`.
  result = i+1
  if flat[i].kind != ckParLe: return
  var nested = 0
  var j = i
  while j < flat.len:
    case flat[j].kind
    of ckParLe: inc nested
    of ckParRi:
      dec nested
      if nested == 0: return j+1
    else: discard
    inc j
  result = flat.len

proc updateAtom(s: var Sha1State; t: CookieTok) =
  # mirrors nimony's nifchecksums.update: token content only, no line infos
  case t.kind
  of ckParLe:
    s.update "("
    s.update t.tag
  of ckParRi: s.update ")"
  of ckIdent:
    s.update " "
    s.update t.str
  of ckStr:
    s.update " \""
    s.update t.str
  of ckInt:
    s.update " "
    s.update $t.ival
  of ckUInt:
    s.update " "
    s.update $t.uval
  of ckFloat:
    # hash the bit pattern, not a formatted float (no formatting variance)
    s.update " f"
    s.update $cast[uint64](t.fval)
  of ckChar:
    s.update " c"
    s.update $t.cval
  of ckDot: s.update "."
  of ckSym, ckSymDef: discard "handled by hashRegion"

proc isModuleLocalName(c: CookieCtx; name: string): bool =
  let sn = parseSymName(name)
  result = sn.module.len == 0 or sn.module == c.selfSuffix

proc hashRegion(s: var Sha1State; c: var CookieCtx; flat: seq[CookieTok];
                start, theEnd: int; skipFrom = -1; skipTo = -1;
                keepFirstDefLiteral = false)

proc expandTd(c: var CookieCtx; flat: seq[CookieTok]; name: uint32; nameStr: string): string =
  ## Structural digest of a module-local type def: hashes the `(td ...)` tree
  ## instead of the volatile `tK.item counter name. Memoized; cycles fall back
  ## to the literal name (sound — at worst a spurious cookie change).
  if c.memo.hasKey(name): return c.memo[name]
  if not c.tdRanges.hasKey(name) or c.expanding.contains(name):
    return nameStr
  c.expanding.incl name
  let start = c.tdRanges[name]
  var sub = newSha1State()
  hashRegion(sub, c, flat, start, nextTree(flat, start))
  result = "&" & $SecureHash(sub.finalize())
  c.expanding.excl name
  c.memo[name] = result

proc hashRegion(s: var Sha1State; c: var CookieCtx; flat: seq[CookieTok];
                start, theEnd: int; skipFrom = -1; skipTo = -1;
                keepFirstDefLiteral = false) =
  # pass 1: assign ordinals to every symbol DEFINED in the hashed region
  # (params, locals, embedded type defs). The region's own top-level name
  # (first SymbolDef) stays literal when requested — it is what importers
  # reference.
  var ords = initTable[uint32, int]()
  var first = keepFirstDefLiteral
  var i = start
  while i < theEnd:
    if i == skipFrom:
      i = skipTo
      continue
    if flat[i].kind == ckSymDef:
      let sym = flat[i].sym
      if first:
        first = false
      elif isModuleLocalName(c, flat[i].name) and not ords.hasKey(sym):
        ords[sym] = ords.len
    inc i
  # pass 2: hash
  first = keepFirstDefLiteral
  i = start
  while i < theEnd:
    if i == skipFrom:
      i = skipTo
      continue
    let t = flat[i]
    if t.kind == ckParLe and t.tag == bindingIdTagName:
      # A type's `bindingId` is a module-wide mint COUNTER: creating one extra
      # type renumbers every type minted after it, so hashing it made the
      # interface cookie depend on declaration ORDER -- inserting a private proc
      # at the top of a module changed the cookie of a module whose interface had
      # not changed and invalidated every importer (measured: 98 re-sems for one
      # line added to ast.nim). The type's real identity survives without it: its
      # structure is hashed here, and its nominal identity rides on `typ.symImpl`,
      # a literal cross-region name.
      s.update " #"   # placeholder: keeps the field's presence, drops its value
      i = nextTree(flat, i)
      continue
    if t.kind in {ckSym, ckSymDef}:
      let sym = t.sym
      let name = t.name
      s.update(if t.kind == ckSymDef: " :" else: " ")
      if t.kind == ckSymDef and first:
        first = false
        s.update name
      elif ords.hasKey(sym):
        s.update "%"
        s.update $ords[sym]
      elif name.startsWith("`t") and isModuleLocalName(c, name):
        s.update expandTd(c, flat, sym, name)
      else:
        s.update name
    else:
      updateAtom s, t
    inc i

proc cookieSd(s: var Sha1State; c: var CookieCtx; flat: seq[CookieTok]; start: int): int =
  ## Contributes one `(sd ...)` subtree to the cookie; returns the index past it.
  result = nextTree(flat, start)
  if flat[start+1].kind != ckSymDef: return
  let marker = flat[start+2]
  if not (marker.kind == ckIdent and marker.str == "x"):
    return # not importable -> invisible to dependents' sem (nimony parity)
  # field layout, see writeSymDef: kind magic flags options offset position
  # annex type owner ast loc constraint instantiatedFrom
  var fields: array[13, int] = default(array[13, int])
  var i = start + 3
  for f in 0 ..< 13:
    fields[f] = i
    i = nextTree(flat, i)
  var kind = skUnknown
  {.cast(uncheckedAssign).}:
    kind = parse(TSymKind, flat[fields[0]].tag)
  var skipFrom = -1
  var skipTo = -1
  if kind in routineKinds:
    # Routines contribute their SIGNATURE only to the iface cookie. A routine
    # body is invisible to a dependent's SEM unless the dependent expands,
    # instantiates, or VM-runs it — and each of those records a NeedsImpl
    # (strong) edge that gates the dependent on this module's IMPL cookie
    # instead (templates -> semTemplateExpr, generics -> generateInstance,
    # macros/compile-time procs -> the VM's genProc, getImpl -> opcGetImpl).
    # Inline iterators and `inline`-callconv procs are inlined at codegen; the
    # nifc backend's transitive NIF-mtime invalidation re-codegens their users.
    # So no routine body needs to live in the iface cookie.
    let ast = fields[9]
    if flat[ast].kind == ckParLe:
      # skip son `bodyPos` (6) of the routine ast tree; NOT the last element —
      # sem appends the result sym at `resultPos` (7) after the body.
      let astEnd = nextTree(flat, ast)
      var p = ast + 1 # the flags atom
      var ok = true
      for _ in 0 ..< 2 + bodyPos: # flags, type, sons 0..5
        p = nextTree(flat, p)
        if p >= astEnd - 1:
          ok = false
          break
      if ok:
        skipFrom = p
        skipTo = nextTree(flat, p)
        # Drop `resultPos` (son 7) as well -- sem appends it right after the
        # body, and it is a bare REFERENCE to the routine's `result` symbol
        # whose def lives inside the body we just skipped. Unresolvable to a
        # region ordinal, it hashes as the literal `result.<disamb>.<module>`,
        # and that disamb is a module-wide per-name counter that shifts when any
        # routine is inserted above this one. Nothing importer-visible is lost:
        # the return type is already carried by the routine's proc type.
        if skipTo < astEnd - 1:
          skipTo = nextTree(flat, skipTo)
  # non-routine kinds (consts carry their value, types their structure incl.
  # default field values): hash everything.
  #
  # One more thing comes off the end for routines: `writeSymDef` closes every
  # `sd` with the TRANSFORMED-body slot (a plain dot for non-routines), and for
  # a routine that slot holds a fully LOWERED body -- closure envs, `chckrange`,
  # inlined `instantiationInfo` tuples and with them SOURCE LINE NUMBERS. A
  # dependent's sem never reads it (the loader deliberately skips the slot under
  # `cmdM`: "a dependent needs no foreign lowered body"), so hashing it only made
  # the interface cookie shift whenever a line was inserted anywhere above the
  # routine. Stop the region before that slot and close the tree by hand.
  var theEnd = result
  if kind in routineKinds and i < result - 1:
    theEnd = i
  hashRegion(s, c, flat, start, theEnd, skipFrom, skipTo, keepFirstDefLiteral = true)
  if theEnd != result: s.update ")"

proc scanStmtsForCookie(s: var Sha1State; c: var CookieCtx; flat: seq[CookieTok]) =
  ## Walks the whole written module, hashing only the importer-visible pieces;
  ## unknown structure is descended into (var/let/type section wrappers,
  ## top-level code) but contributes nothing itself — nimony-style.
  let exportName = toNifTag(nkExportStmt)
  let exportExceptName = toNifTag(nkExportExceptStmt)
  var i = 0
  while i < flat.len:
    let t = flat[i]
    if t.kind == ckParLe:
      let tg = t.tag
      if tg == symDefTagName:
        i = cookieSd(s, c, flat, i)
      elif tg == "implementation":
        i = nextTree(flat, i)
      elif tg == "replay" or tg == "repconverter" or tg == "repdestroy" or
           tg == "repwasmoved" or tg == "repcopy" or tg == "repsink" or
           tg == "repdup" or tg == "reptrace" or tg == "repdeepcopy" or
           tg == "repenumtostr" or tg == "repmethod" or
           tg == exportName or tg == exportExceptName or tg == "include":
        let e = nextTree(flat, i)
        hashRegion(s, c, flat, i, e)
        i = e
      elif tg == "import":
        let e = nextTree(flat, i)
        hashRegion(s, c, flat, i, e)
        for j in i ..< e:
          if flat[j].kind == ckStr:
            let suffix = flat[j].str
            if suffix notin c.depSuffixes: c.depSuffixes.add suffix
        i = e
      else:
        inc i # descend without hashing
    else:
      inc i

proc icGroupSuffixes(config: ConfigRef): HashSet[string] =
  ## Module suffixes of the --icGroup cycle members compiled by this very
  ## process (their sidecars are being produced concurrently, so neither
  ## chaining nor edge recording may depend on them).
  result = initHashSet[string]()
  for p in config.icGroup:
    result.incl cachedModuleSuffix(config, fileInfoIdx(config, AbsoluteFile p))

proc writeCookieFile(config: ConfigRef; selfSuffix, tag, hex, ext: string) =
  # Binary NIF cookie `(tag "hex")`, content-stable so an unchanged hash keeps the
  # sidecar mtime (nifmake prunes the re-sem cascade behind it).
  var b = newIcBuilder(4)
  b.openTag tag
  b.addStrLit hex
  b.closeTag()
  let path = toGeneratedFile(config, AbsoluteFile(selfSuffix), ext).string
  storeBifStable(b, path, "." & extractModuleSuffix(path))

proc writeIfaceCookie(config: ConfigRef; thisModule: int32; flat: seq[CookieTok]): string =
  let selfSuffix = modname(thisModule, config)
  var c = CookieCtx(selfSuffix: selfSuffix)
  # pre-pass: first (td ...) occurrence per type name, wherever it is embedded
  var i = 0
  while i < flat.len:
    if flat[i].kind == ckParLe and flat[i].tag == typeDefTagName and i+1 < flat.len and
       flat[i+1].kind == ckSymDef:
      let nm = flat[i+1].sym
      if not c.tdRanges.hasKey(nm): c.tdRanges[nm] = i
    inc i
  var s = newSha1State()
  scanStmtsForCookie(s, c, flat)
  # chain the direct deps' cookies; co-members of an --icGroup cycle are
  # excluded (their sidecars are being produced by this very rule — chaining
  # them would make the hash depend on within-group write order).
  let groupSuffixes = icGroupSuffixes(config)
  for dep in c.depSuffixes:
    if dep == selfSuffix or dep in groupSuffixes: continue
    let depIface = toGeneratedFile(config, AbsoluteFile(dep), ".iface.bif").string
    s.update "|"
    s.update dep
    s.update ":"
    s.update(try: readFile(depIface) except IOError, OSError: "")
  result = $SecureHash(s.finalize())
  writeCookieFile(config, selfSuffix, "iface", result, ".iface.bif")

proc writeImplCookie(config: ConfigRef; thisModule: int32; flat: seq[CookieTok];
                     ifaceHex: string) =
  ## The implementation cookie: a line-info-free hash of the module's ENTIRE
  ## serialized content (private defs and routine bodies included), with the
  ## module's own iface cookie mixed in so impl sensitivity is a strict
  ## superset of iface sensitivity (incl. the chained dep ifaces — a NeedsImpl
  ## edge REPLACES the iface edge, it must not lose its triggers). Dependents
  ## that consumed this module's bodies at compile time are gated on this file
  ## instead of the iface cookie. Comment-only edits move neither cookie.
  ## No id normalization here: a counter shift implies some real content
  ## change elsewhere in the module, which flips the hash anyway — and any
  ## body change is exactly what NeedsImpl dependents must see.
  let selfSuffix = modname(thisModule, config)
  var s = newSha1State()
  for t in flat:
    if t.kind in {ckSym, ckSymDef}:
      s.update(if t.kind == ckSymDef: " :" else: " ")
      s.update t.name
    else:
      updateAtom s, t
  s.update "|iface:"
  s.update ifaceHex
  writeCookieFile(config, selfSuffix, "impl", $SecureHash(s.finalize()), ".impl.bif")

proc writeEdgesFile(config: ConfigRef; thisModule: int32; implDeps: seq[int]) =
  ## Records which modules' bodies this compilation consumed at compile time
  ## (`ModuleGraph.icImplDeps`): the NeedsImpl edge set. deps.nim reads this
  ## sidecar when regenerating the build file and gates this module on those
  ## dependencies' IMPL cookies instead of their iface cookies.
  let selfSuffix = modname(thisModule, config)
  let groupSuffixes = icGroupSuffixes(config)
  var suffixes: seq[string] = @[]
  for id in implDeps:
    if id == thisModule.int: continue
    let suffix = cachedModuleSuffix(config, FileIndex id)
    if suffix.len == 0 or suffix == selfSuffix or suffix in groupSuffixes:
      continue
    if suffix notin suffixes: suffixes.add suffix
  sort suffixes
  # Native nifcore writer (Stage 2): `(edges "suffix" ...)`, byte-identical.
  var b = newIcBuilder(4 + 2*suffixes.len)
  b.openTag "edges"
  for suffix in suffixes:
    b.addStrLit suffix
  b.closeTag()
  let path = toGeneratedFile(config, AbsoluteFile(selfSuffix), ".edges.bif").string
  # Deliberately ALWAYS written (unlike every other output of the nim_m rule):
  # nothing gates on this file's mtime — deps.nim only reads its content — so
  # it doubles as the rule's freshness stamp. nifmake's `needsRebuild` takes
  # the freshest output as proof of "ran since the inputs changed"; without an
  # always-written output a rule whose re-run produces only content-identical
  # (mtime-preserved) files would re-fire on every warm build (e.g. after an
  # edit was reverted). Nimony's analog is its always-written `.s.bif`.
  storeBif(b, path, "." & extractModuleSuffix(path))

proc writeSemDeps*(config: ConfigRef; thisModule: int32; importPaths: seq[string]) =
  ## The module's REAL direct imports as `nim m` sem resolved them — static
  ## plus any a macro generated — recorded as full source paths. `nim ic` reads
  ## this `.s.deps.nif` to re-derive the build graph: imports the static scanner
  ## missed become new nodes (replacing the old build-failure discovery loop),
  ## and `when false` imports the scanner over-included are pruned. Always
  ## written so it is current after every successful sem (like `.edges`).
  ##
  ## Ported to nifcore: delegates to `icnifcore.writeSemDeps` (Stage 1 of the
  ## NIF-stack migration; see doc/ic_nifcore_port.md). Output is byte-identical
  ## to the previous `nifstreams` writer.
  icnifcore.writeSemDeps(config, thisModule, importPaths)

proc writeNifModule*(config: ConfigRef; thisModule: int32; n: PNode;
                     opsLog: seq[LogEntry];
                     replayActions: seq[PNode] = @[];
                     implDeps: seq[int] = @[];
                     reexportedModules: seq[(string, string)] = @[];
                     genericOffers: seq[tuple[generic, inst: PSym;
                                              concreteTypes: seq[PType];
                                              genericParamsCount: int]] = @[];
                     typeOffers: seq[tuple[generic: PSym; inst: PType]] = @[];
                     resolvedImportDeps: seq[FileIndex] = @[];
                     firstUnusedId: int32 = 0;
                     expansions: seq[(PSym, TLineInfo)] = @[];
                     moduleFlags: int32 = 0;
                     extraExports: seq[ItemId] = @[]) =
  var w = Writer(infos: newLineInfoWriter(config), currentModule: thisModule)
  for id in extraExports: w.extraExports.incl id
  w.deps = newIcBuilder(64)
  var content = newIcBuilder(300)

  let rootInfo = trLineInfo(w, n.info)
  createStmtList(content, rootInfo)

  # Write replay actions first, wrapped in a (replay ...) node
  if replayActions.len > 0:
    content.addParLe replayTag, rootInfo
    for action in replayActions:
      writeNode(w, content, action)
    content.addParRi()
  # Only write ops that belong to this module
  for op in opsLog:
    if op.module == thisModule.int:
      writeOp(w, content, op)

  var bottom = newIcBuilder(300)
  w.writeToplevelNode content, bottom, n

  # Resolved import edges that left no syntactic `import` node in the top-level
  # AST: an import generated INSIDE a `when` condition (e.g. stew/importops'
  # `when tryImport x:` -> `when compiles((; import x)): import x`) really
  # imports `x` — `addImportFileDep` recorded the edge in `graph.importDeps` —
  # but the import node is folded away with the condition, so `trImport` never
  # saw it and the NIF `deps` section omitted it. The backend closure walk
  # (nifbackend.loadBackendModules) follows NIF `deps`, so without this edge a
  # template-imported module's `{.compile.}`/`{.passL.}` directives never replay
  # and its C/asm objects go unlinked (undefined `hashtree_hash`/`my_c_add` at
  # link). Emit any resolved edge not already written as a syntactic import.
  for f in resolvedImportDeps:
    let fp = moduleSuffix(config, f)
    if not w.depSuffixes.containsOrIncl(fp):
      w.deps.addParLe importTag, NoLineInfo
      w.deps.addDotToken # flags
      w.deps.addDotToken # type
      w.deps.addStrLit fp
      w.deps.addParRi

  # Re-exported MODULES (`import x; export x`): semExport puts only x's
  # member syms into the nkExportStmt; the module sym itself reaches the
  # exporter's interface via `reexportSym` and acts as a QUALIFIER there
  # (`asmm.x86.nd`). Serialize (name, suffix) pairs so the loader can
  # rebuild that part of the interface.
  for (mname, msuffix) in reexportedModules:
    w.deps.addParLe reexpModTag, NoLineInfo
    w.deps.addStrLit mname
    w.deps.addStrLit msuffix
    w.deps.addParRi

  # Generic-instance OFFERS: every generic instance this module created
  # (`getOrDefault[MultiCodec]`, …). A consumer that re-instantiates the same
  # generic must REUSE this instance instead of re-running `instantiateBody` in
  # its own module scope — which lacks symbols visible only at the generic's
  # definition site (e.g. a distinct type's `==` from the type's module), so
  # operator/mixin resolution would fail ("type mismatch" at `hashcommon.rawGet`).
  # The loader (modulegraphs.moduleFromNifFile) rebuilds `procInstCache` from
  # these so `genericCacheGet` hits and the wrong-scope re-instantiation is
  # skipped. Layout: (offer <genericSym> <instSym> <genericParamsCount> <type>...).
  for off in genericOffers:
    w.deps.addParLe offerTag, NoLineInfo
    w.deps.addSymUse pool.syms.getOrIncl(w.toNifSymName(off.generic)), NoLineInfo
    w.deps.addSymUse pool.syms.getOrIncl(w.toNifSymName(off.inst)), NoLineInfo
    w.deps.addIntLit off.genericParamsCount
    for ct in off.concreteTypes:
      # `nifTypeName`, NOT `typeToNifSym`: the def this offer has to resolve
      # against was emitted under the CANONICAL name, and `typeToNifSym` prints
      # the raw mint counter. The mismatch is silent -- the loader is
      # best-effort and just drops the offer -- so the consumer re-instantiates
      # the generic in its own scope and fails wherever that scope differs
      # (`tests/ic/ttransitiveoffer`: `TScopeSize` ambiguous between two
      # imports). `fromRaw(64)` reaches it through an `int` literal copy, but
      # every wrapper kind has been exposed to this since `2bed712f6`.
      w.deps.addSymUse pool.syms.getOrIncl(nifTypeName(w, ct)), NoLineInfo
    w.deps.addParRi
  # Record this module's own absolute source path. The NIF suffix is a hash of
  # the (relative) path (gear2/modnames.moduleSuffix) and is NOT reversible, so
  # the standalone include-graph scanner (`scanIncludeGraph`, used by nimsuggest
  # cold queries) needs the path written explicitly to map an included file back
  # to the *source* of its includer without loading the module.
  w.deps.addParLe modulesrcTag, NoLineInfo
  w.deps.addStrLit toFullPath(config, FileIndex(thisModule))
  w.deps.addParRi

  # Template/macro expansions leave no trace in the sem'checked AST, so record
  # each as `(expansion <symUse @call-site>)`: a `Symbol` use of the expanded
  # routine carrying the ORIGINAL call-site line info. The loader skips the tag
  # (processTopLevel), but `idetools` scans every `Symbol` token in the buffer,
  # so this restores "find usages / goto-def" for templates and macros.
  for (sym, info) in expansions:
    if sym == nil: continue
    w.deps.addParLe expansionTag, NoLineInfo
    w.deps.addSymUse pool.syms.getOrIncl(w.toNifSymName(sym)), trLineInfo(w, info)
    w.deps.addParRi

  # Generic TYPE-instance OFFERS: the `tyGenericInst` types this module created
  # (e.g. `HashArray[8192, Gwei]`). Non-IC keeps ONE such instance in the global
  # `typeInstCache`, so a structural bound computed at the first instantiation
  # site (e.g. an `array[…]` bound that depends on a `mixin`/`compiles()` whose
  # resolution differs by import scope) is frozen and reused everywhere. A
  # separate `nim m` process never repopulates `typeInstCache` from NIFs, so it
  # re-instantiates in its own scope and can compute a DIFFERENT bound (the SSZ
  # `dataPerChunk` divergence). The loader rebuilds `g.typeInstCache` from these
  # so `semtypinst.searchInstTypes` hits and reuses the baked instance.
  # Layout: (toffer <genericBodySym> <instType>).
  for off in typeOffers:
    # Carry the generic body sym and the instance type as STRING LITERALS, not
    # SymUse tokens: `addSymUse` rewrites a same-module reference into the NIF
    # "local form" (suffix stripped, resolved by the content loader against the
    # module being read), but this offer lives in the `deps` header and is read
    # by a CONSUMER with no such module context. The full names round-trip
    # verbatim as strings and `createTypeStub`/`resolveHookSym` resolve them
    # directly (cf. `loadImport`, which carries module suffixes the same way).
    w.deps.addParLe typeOfferTag, NoLineInfo
    w.deps.addStrLit w.toNifSymName(off.generic)
    w.deps.addStrLit nifTypeName(w, off.inst)   # canonical name, see above
    w.deps.addParRi

  # OWNER MUST EMIT: a type reachable only through an offered instance — the
  # `concreteTypes` of an offered proc instance (e.g. chronicles `writeValue[T]`,
  # where `T` is this module's own object type) or an offered generic type
  # instance — may never be reached by the normal top-level serialization above.
  # If this module OWNS such a type, force-emit its typedef so that a consumer
  # which reuses the offer can resolve the cross-module SymUse to it. Without this
  # the consumer writes `t<k>.<i>.<thisSuffix>` and the loader asserts
  # `symbol has no offset`. `writeType` emits the def (and recurses into owned
  # sons) only for an own, still-Complete type; an already-Sealed one is skipped.
  for off in genericOffers:
    for ct in off.concreteTypes:
      if ct != nil and ct.itemId.module == w.currentModule and ct.state == Complete:
        writeType(w, bottom, ct)
  for off in typeOffers:
    if off.inst != nil and off.inst.itemId.module == w.currentModule and
        off.inst.state == Complete:
      writeType(w, bottom, off.inst)

  # the implTag is used to tell the loader that the
  # bottom of the file is the implementation of the module:
  content.addParLe implTag, NoLineInfo
  content.addParRi()
  addAll(content, bottom)
  content.addParRi()

  let m = modname(w.currentModule, w.infos.config)
  let bifPath = completeGeneratedFilePath(config, AbsoluteFile(m).changeFileExt(".s.bif")).string

  var dest = newIcBuilder(600)
  createStmtList(dest, rootInfo)
  # First child: the backend id seed (see `(unusedid)` / readUnusedId).
  dest.addParLe unusedIdTag, NoLineInfo
  dest.addIntLit firstUnusedId.int64
  dest.addParRi()
  # The module symbol's backend-relevant flags (see `(modflags)`).
  dest.addParLe modFlagsTag, NoLineInfo
  dest.addIntLit moduleFlags.int64
  dest.addParRi()
  addAll(dest, w.deps)
  # do not write the (stmts .. ) wrapper:
  addStmtsBody(dest, content)

  # ensure the hooks we announced end up in the NIF file regardless of
  # whether they have been used:
  for op in opsLog:
    if op.module == thisModule.int:
      let s = op.sym
      if s.state != Sealed:
        s.state = Sealed
        if restoresWrittenState(config): w.writtenSyms.add s
        writeSymDef w, dest, s

  dest.addParRi()

  # Nimsuggest and normal code generation reuse these symbols/types as live,
  # mutable targets. Sealing is only needed for intra-emit dedup; once the NIF
  # is built, un-seal them. The guard stays in force for a real `nim m` build.
  if restoresWrittenState(config):
    for s in w.writtenSyms:
      if s.state == Sealed: s.state = Complete
    for t in w.writtenTypes:
      if t.state == Sealed: t.state = Complete

  # OnlyIfChanged keeps the mtime of content-identical rewrites: nifmake's
  # mtime-based `needsRebuild` then prunes the rebuild cascade level by
  # level, and the nifc backend can trust "semmed NIF older than the cnif
  # artifact" as an honest per-module unchanged stamp.
  # CONTENT-STABLE (`storeBifStable`, the bif analogue of the old text `.s.nif`'s
  # `OnlyIfChanged`): when `nim m` re-runs (e.g. it was scheduled because a sibling
  # input churned) but produces byte-identical sem output, the `.s.bif` mtime MUST
  # be preserved, else every dependent backend stage sees its input as "newer" and
  # rebuilds — with whatever compiler this run uses. In a self-rebuild (`bootic`)
  # that re-translates only SOME modules with the new compiler while others reuse
  # the prior compiler's artifacts → a MIXED binary that needs a 3rd fixed-point
  # iteration to wash out. The `nim m` rule still has its always-written run-marker:
  # the `.edges.bif` (writeEdgesFile), so a no-op re-run does not re-fire.
  # Step 3: emit the compact binary NIF as the SOLE on-disk module artifact (no
  # text `.s.nif` twin — writing two files per module only slows the build; debug
  # a `.bif` via `tools/bif2nif`). Re-homed into a private fresh pool
  # so the file holds only THIS module's literals.
  storeBifStable(dest, bifPath, "." & extractModuleSuffix(bifPath))
  if not isDefined(config, "icNoIfaceGate"):
    var flat = flattenForCookie(dest)
    let ifaceHex = writeIfaceCookie(config, thisModule, flat)
    writeImplCookie(config, thisModule, flat, ifaceHex)
    writeEdgesFile(config, thisModule, implDeps)

# --------------------------- Loader (lazy!) -----------------------------------------------

# Step 2b reader shims over nifcore cursors:
template info(n: Cursor): NifLineInfo = rawLineInfo(n)
  ## line info of the token at `n` (was the inline `n.info` of nifcursors).
template cursorTag(n: Cursor): string = n.tags.tagName(cursorTagId(n))
  ## tag name of the TagLit at `n` — for VALUE uses only (parse into an enum,
  ## error messages). For tag *checks* use `tagIs`. Resolved via the cursor's OWN
  ## tag pool (`n.tags`), not the shared `icTags`: a `bif`-loaded module carries a
  ## fresh per-file tag pool whose ids only line up with its own `tagName`.
template tagIs(n: Cursor; name: string): bool = n.tags.tagName(cursorTagId(n)) == name
  ## True iff `n`'s TagLit is the IC tag `name`. A string compare against the
  ## cursor's own tag pool — id comparison against a process-global cache is
  ## impossible once `bif` mints fresh per-file tag pools (ids are per-pool).

proc nodeKind(n: Cursor): TNodeKind {.inline.} =
  assert n.kind == TagLit
  parse(TNodeKind, cursorTag(n))

proc expect(n: Cursor; k: set[nifcore.NifKind]) =
  if n.kind notin k:
    when defined(debug):
      writeStackTrace()
    quit "[NIF decoder] expected: " & $k & " but got: " & $n.kind

proc expect(n: Cursor; k: nifcore.NifKind) {.inline.} =
  expect n, {k}

proc firstSon*(n: Cursor): Cursor {.inline.} =
  ## Non-consuming peek at the first child of a TagLit. The `inc` is on a copy,
  ## so it never advances the caller's cursor.
  result = n
  inc result

proc loadBool(n: var Cursor): bool =
  if n.kind == TagLit:
    result = tagIs(n, "true")
    n.into:
      discard
  else:
    raiseAssert "(true)/(false) expected"

type
  NifModule = ref object
    buf: TokenBuf      # the WHOLE module, parsed eagerly (Step 2: replaces the
                       # lazy byte-offset stream entirely — symbol/type loading
                       # AND the body reader now cursor over this resident buffer)
    symCounter: int32  # seeded from the file's `(unusedid)` so backend syms
                       # start above every frontend/lowered id (no collision)
    typeCounter: int32 # ditto for backend TYPES (closure envs etc.)
    index: Table[string, NifIndexEntry]  # name -> entry; `offset` is a TOKEN
                                         # position in `buf` (was a byte offset)
    suffix: string
    loweredPrimary: bool   # `buf` is the lowered `.t.bif` (cg/emit stage). The lower
                           # stage never changes type DEFINITIONS, so they are NOT
                           # carried in `.t.bif`; a type def not in `index` is read
                           # from the `.s.bif` companion below (loaded on demand).
    semBuf: TokenBuf       # the `.s.bif` (semchecked) buffer — TYPE-def fallback
    semIndex: Table[string, NifIndexEntry]
    semTried: bool         # `semBuf`/`semIndex` load attempted (idempotent)

  PendingBody = object
    ## A deferred routine body (bodyPos son). `cursor` points AT the body node in
    ## the module buffer (kept alive by the cursor's refcounted owner); `localSyms`
    ## is the snapshot of the enclosing sym def's local symbols so body-local
    ## references resolve to the SAME PSyms the signature already created.
    cursor: Cursor
    thisModule: string
    localSyms: Table[string, PSym]

  DecodeContext* = object
    infos: LineInfoWriter
    pendingBodies: Table[int, PendingBody]  # nodeId(placeholder) -> deferred body
    #moduleIds: Table[string, int32]
    types: Table[string, (PType, NifIndexEntry)]
    syms: Table[string, (PSym, NifIndexEntry)]
    mods: Table[FileIndex, NifModule]
    cache: IdentCache
    mainModuleSuffix: string
      ## Mangled module name of the module being compiled fresh (cmdM). Symbols
      ## belonging to it that are re-exported by a dependency must NOT be loaded
      ## as stubs, otherwise they collide with the freshly compiled originals.
    symLoads, typeLoads: CountTable[FileIndex]
      ## Diagnostics (opt-in via env `NIM_IC_LOADSTATS`): per OWNING-module count
      ## of stub materializations in THIS process. Quantifies the "every backend
      ## worker deserializes system.bif + a bunch of others" cost — breadth (how
      ## many syms) attributed to duplication axis (which shared module).

proc createDecodeContext*(config: ConfigRef; cache: IdentCache): DecodeContext =
  ## Supposed to be a global variable
  result = DecodeContext(infos: newLineInfoWriter(config), cache: cache)

var loadStatsInit {.threadvar.}: int          # 0=unknown 1=on 2=off
var statsCtxPtr {.threadvar.}: ptr DecodeContext
var loaderCtx {.threadvar.}: ptr DecodeContext  # the live `program`; for lazy-body
                                                # materialization off the len hook
var nodesDecoded {.threadvar.}: int           # all PNodes materialized this proc
var astFieldNodes {.threadvar.}: int          # subset: routine-body (s.ast) subtrees

proc dumpLoadStatsExit() {.noconv.} =
  if statsCtxPtr == nil: return
  let c = statsCtxPtr
  var merged = initTable[FileIndex, array[2, int]]()
  for m, cnt in c.symLoads.pairs: merged.mgetOrPut(m, [0, 0])[0] = cnt
  for m, cnt in c.typeLoads.pairs: merged.mgetOrPut(m, [0, 0])[1] = cnt
  var order: seq[FileIndex] = @[]
  var totS, totT: int = 0
  for m, a in merged:
    order.add m
    totS += a[0]; totT += a[1]
  sort(order, proc (a, b: FileIndex): int =
    (merged[b][0] + merged[b][1]) - (merged[a][0] + merged[a][1]))
  let params = commandLineParams()
  let target = if params.len > 0: params[^1] else: "?"
  stderr.writeLine "=== IC loadstats pid=" & $getCurrentProcessId() &
    " main=" & c.mainModuleSuffix & " target=" & target & " ==="
  stderr.writeLine "  TOTAL symLoads=" & $totS & " typeLoads=" & $totT &
    " modulesTouched=" & $order.len
  let pct = if nodesDecoded > 0: 100 * astFieldNodes div nodesDecoded else: 0
  stderr.writeLine "  PNODES decoded=" & $nodesDecoded & " routineBody=" &
    $astFieldNodes & " (" & $pct & "% deferrable via lazy PSym.ast)"
  for m in order:
    let a = merged[m]
    let name = if c.mods.hasKey(m): c.mods[m].suffix else: "?"
    stderr.writeLine "  " & $(a[0] + a[1]) & "\tsym=" & $a[0] & " typ=" & $a[1] &
      "\t" & name

proc recordLoad(c: var DecodeContext; m: FileIndex; isType: bool) =
  if loadStatsInit == 0:
    loadStatsInit = if existsEnv("NIM_IC_LOADSTATS"): 1 else: 2
    if loadStatsInit == 1:
      statsCtxPtr = addr c
      addExitProc(dumpLoadStatsExit)
  if loadStatsInit == 2: return
  if isType: c.typeLoads.inc(m) else: c.symLoads.inc(m)

proc nextBackendSymItem*(c: var DecodeContext; module: int32): int32 =
  ## Allocate the next backend-minted SYM item for `module` from the SAME
  ## per-module counter the loader uses when it re-homes `@bk` syms loaded from
  ## the module's `.t.bif` (loadSymStub/extractLocalSymsFromTree). The `lower`
  ## stage serializes its lifted hooks/temps as `@bk` syms, and cg mints MORE
  ## backend syms (RTTI destroy wrappers, ...) into the same module. Both are
  ## keyed by `.id` (= `toId(itemId)`) in `declaredThings`/`declaredProtos`, so
  ## if the two id producers (the loader's `symCounter` and cg's idgen) ran
  ## independently they could mint the same item: e.g. a `rttiDestroy` wrapper
  ## and the very `=destroy` hook it wraps both land on backend item 21 -> one
  ## masks the other in `declaredThings` -> the hook's body is never emitted ->
  ## "undefined reference" at link. Drawing every backend sym from this one
  ## counter keeps them disjoint. Returns -1 if the module is not loaded yet
  ## (then the caller falls back to the idgen's own counter — only reachable
  ## for sem-time `@bk` minting, whose module is never loaded in that process).
  let fi = module.FileIndex
  if not c.mods.hasKey(fi): return -1'i32
  let p = addr c.mods[fi].symCounter
  inc p[]
  result = p[]

proc nextBackendTypeItem*(c: var DecodeContext; module: int32): int32 =
  ## TYPE analogue of `nextBackendSymItem`: the `lower`/`cg` stages mint fresh
  ## backend TYPES (closure-env objects, ptr wrappers) whose itemId must not
  ## collide with the module's loaded types. Drawn from the per-module
  ## `typeCounter`, which `moduleId` seeds from the file's `(unusedid)` so the
  ## first minted type sits ABOVE every frontend/lowered type item. Returns -1
  ## if the module is not loaded (caller falls back to the idgen's own counter).
  let fi = module.FileIndex
  if not c.mods.hasKey(fi): return -1'i32
  let p = addr c.mods[fi].typeCounter
  inc p[]
  result = p[]

proc setMainModule*(c: var DecodeContext; fileIdx: FileIndex) =
  ## Records the module that is being compiled fresh so that re-exports of its
  ## own symbols by dependencies are not turned into duplicate stubs.
  c.mainModuleSuffix = modname(fileIdx.int, c.infos.config)

proc getMainModuleSuffix*(c: DecodeContext): string {.inline.} =
  c.mainModuleSuffix

proc loadedState(c: DecodeContext): ItemState {.inline.} =
  ## State to give a freshly loaded symbol or type. During the C code generation
  ## phase (`nim nifc`) the backend (lambda lifting, the transformer, etc.)
  ## legitimately mutates the loaded entities and never writes them back to a NIF,
  ## so they must be mutable (`Complete`). nimsuggest (`ideActive`) is the same
  ## case: it reuses loaded symbols as live query targets and mutates them during
  ## sem and suggestion bookkeeping (usage tracking, flags) without authoritatively
  ## writing those mutations back (its NIF emits are gated to non-dirty, error-free
  ## modules and re-serialize from the proper state). During a plain `nim m`
  ## semantic check a loaded entity belongs to an already-compiled dependency and
  ## must stay `Sealed` so accidental mutations are caught.
  if c.infos.config.cmd == cmdNifC or c.infos.config.ideActive: Complete else: Sealed

proc cursorFromIndexEntry(c: var DecodeContext; module: FileIndex; entry: NifIndexEntry): Cursor =
  ## Step 2a: O(1) cursor into the module's resident `buf` at the def's token
  ## position. No I/O, no per-symbol materialization — and, because each call
  ## returns an INDEPENDENT cursor, none of the old stream-cursor clobber hazards
  ## (the `jumpTo(saved)` save/restore dance) apply anymore.
  result = cursorAt(c.mods[module].buf, entry.offset)

type
  LoadFlag* = enum
    LoadFullAst, AlwaysLoadInterface
    SkipInterfaceTables
      ## Do not eagerly build the module's interface string tables. Set by
      ## `modulegraphs.loadTransitiveHooks`, which loads a module only to
      ## register its hooks / macro-cache replay / generic-instance offers and
      ## throws the tables away — the module is a dep-of-a-dep, not an import, so
      ## none of its symbols are visible to the module being semchecked.
      ##
      ## The eager pass calls `loadSymFromIndexEntry` for EVERY index entry, and
      ## its only other effect is pre-populating the name-keyed `c.syms` cache —
      ## which `resolveSym` fills lazily on a miss anyway, straight from the same
      ## index. So for these loads it is pure work: on a 219-module program a
      ## one-line edit paid it 209 times over.

proc isGlobalIndexSym(s, dottedSuffix: string): bool =
  ## Mirror of `nifbuilder.addSymbolDefRetIsGlobal` / `bif.isGlobalSymbol`: a sym
  ## gets an index entry when its name — with a self-module `dottedSuffix`
  ## compressed to one trailing dot — has >= 2 dots (counting from index 1).
  var lim = s.len
  if dottedSuffix.len > 0 and s.endsWith(dottedSuffix):
    lim = s.len - dottedSuffix.len + 1
  if lim > s.len: lim = s.len
  var dots = 0
  for i in 1 ..< lim:
    if s[i] == '.': inc dots
  dots >= 2

proc rescanPosIndex(buf: var TokenBuf; suffix: string): Table[string, NifIndexEntry] =
  ## VERIFICATION ONLY (`-d:icIndexCheck`): the old full-token-stream rescan,
  ## kept so `indexFromBif` can be graded against it over a whole real build.
  result = initTable[string, NifIndexEntry]()
  let dotted = "." & suffix
  if buf.len == 0: return
  var c = buf.beginRead()
  var mostRecentTagPos = 0
  while c.hasMore:
    case c.kind
    of TagLit:
      mostRecentTagPos = cursorToPosition(buf, c)
      inc c
    of SymbolDef:
      let nm = symName(c)
      let tagPos = mostRecentTagPos
      inc c
      if isGlobalIndexSym(nm, dotted):
        let vis = if c.hasMore and c.kind == DotToken: Hidden else: Exported
        result[nm] = NifIndexEntry(offset: tagPos, info: NoLineInfo, vis: vis)
    else:
      inc c

proc indexFromBif(m: BifModule): Table[string, NifIndexEntry] =
  ## The module's name -> token-position index, taken from the index the `.bif`
  ## ALREADY CARRIES rather than recomputed.
  ##
  ## `bif.store` builds that index in one forward traversal at write time
  ## (`bif.buildIndex`) and writes it into the file; `bif.load` reads it back as
  ## `BifModule.index`, with `pos` already a TOKEN index of the declaration's
  ## enclosing tag — the very thing this used to rescan the whole token stream
  ## to recompute, once per module per backend process. That rescan was 909ms of
  ## a 10.1s cold `--ic:on` build (`-d:icBNodeProf`, `tPosIndex`).
  ##
  ## The two agree by construction, and it is worth saying exactly why, because
  ## "the file has an index" would not be enough on its own: the writer filters
  ## with `bif.isGlobalSymbol(name, dottedSuffix)` and every `storeBif` call site
  ## passes `"." & extractModuleSuffix(path)`, which is the same `dottedSuffix`
  ## the reader would have formed — so the two filters select the same symbols,
  ## and the `vis` rule (a `DotToken` marker after the def means hidden) is the
  ## same test on the same token.
  result = initTable[string, NifIndexEntry](m.index.len)
  for e in m.index:
    result[poolSym(m.buf.pool, e.sym)] =
      NifIndexEntry(offset: int(e.pos), info: NoLineInfo,
                    vis: (if e.vis == ivHidden: Hidden else: Exported))

proc indexFromBif(m: var BifModule; suffix: string): Table[string, NifIndexEntry] =
  result = indexFromBif(m)
  when defined(icIndexCheck):
    let want = rescanPosIndex(m.buf, suffix)
    doAssert result.len == want.len,
      "index size differs for " & suffix & ": carried " & $result.len &
      " rescanned " & $want.len
    for k, v in want:
      let got = result.getOrDefault(k)
      doAssert got.offset == v.offset and got.vis == v.vis,
        "index entry differs for " & k & " in " & suffix

proc readUnusedId(buf: var TokenBuf): int32 =
  ## Find the module's `(unusedid <int>)` directive — emitted as the FIRST child
  ## of the top-level `(stmts ...)` by writeNifModule/writeLoweredModule — and
  ## return its value (the first free itemId). 0 if absent (older artifact: the
  ## backend then falls back to its own un-seeded counter, i.e. pre-`unusedid`
  ## behaviour).
  result = 0'i32
  if buf.len == 0: return
  var c = buf.beginRead()
  if c.kind != TagLit: return            # outermost (stmts ...)
  inc c                                  # descend into stmts body
  while c.hasMore:
    if c.kind == TagLit:
      if tagName(c.tags, c.cursorTagId) == "unusedid":
        inc c                            # into the unusedid body
        if c.hasMore and c.kind == IntLit:
          result = int32 intVal(c)
        return
      else:
        skip c                           # not it; skip this whole subtree
    else:
      inc c

proc moduleId(c: var DecodeContext; suffix: string; flags: set[LoadFlag] = {}): FileIndex =
  var isKnownFile = false
  result = c.infos.config.registerNifSuffix(suffix, isKnownFile)
  # Always load the module's index if it's not already in c.mods
  # This is needed when resolving symbols from modules that were registered elsewhere
  # but haven't had their NIF index loaded yet
  let hasEntry = c.mods.hasKey(result)
  if not hasEntry or AlwaysLoadInterface in flags:
    # Module artifacts are binary NIF (`.bif`). The `cg`/`emit` backend stages
    # load the LOWERED whole-module `.t.bif` (transformed bodies + lambda-lifted
    # signatures/entities baked in by the `lower` stage — see writeLoweredModule);
    # the `lower` stage and the frontend (`cmdM`) load the semchecked `.s.bif`.
    # This mirrors `toNifFilename` (kept in sync). `bif.load` mints FRESH per-file
    # pools, so the buffer's literals/tags resolve through its own
    # `cursorPool(n)`/`n.tags` (the reader is pool-agnostic); the token-position
    # index is taken from the one the file carries (`indexFromBif`).
    let conf = c.infos.config
    let useLowered = conf.cmd == cmdNifC and
                     (conf.icBackendStage == "cg" or conf.icBackendStage == "emit")
    var modFile = (getNimcacheDir(conf) / RelativeFile(suffix & ".t.bif")).string
    let lowered = useLowered and fileExists(modFile)
    if not lowered:
      modFile = (getNimcacheDir(conf) / RelativeFile(suffix & ".s.bif")).string
    if not fileExists(modFile):
      raiseAssert "NIF file not found for module suffix '" & suffix & "': " & modFile &
        ". This can happen when loading a module from NIF that references another module " &
        "whose NIF file hasn't been written yet."
    icProfStart(tBifLoad)
    var m = bif.load(modFile)
    icProfStop(tBifLoad)
    icProfStart(tPosIndex)
    let index = indexFromBif(m, suffix)
    icProfStop(tPosIndex)
    # Seed the backend id counters ABOVE every id the file already uses, so a
    # freshly-minted backend sym/type (closure env, RTTI hook, temp) can never
    # share a `toId` with a loaded one. See `readUnusedId` / `(unusedid)`.
    let seed = readUnusedId(m.buf)
    c.mods[result] = NifModule(buf: ensureMove m.buf, index: index, suffix: suffix,
                               symCounter: seed, typeCounter: seed,
                               loweredPrimary: lowered)

proc getOffset(c: var DecodeContext; module: FileIndex; nifName: string): NifIndexEntry =
  let ii = addr c.mods[module].index
  result = ii[].getOrDefault(nifName)
  if result.offset == 0:
    raiseAssert "symbol has no offset: " & nifName

proc ensureSemBuf(c: var DecodeContext; module: FileIndex) =
  ## Lazily load the module's `.s.bif` companion (`semBuf`/`semIndex`) for the TYPE
  ## fallback. Only meaningful when the primary `buf` is the lowered `.t.bif`, which
  ## omits frontend type defs (the lower stage never changes them). Idempotent.
  let m = c.mods[module]
  if m.semTried: return
  m.semTried = true
  let semFile = (getNimcacheDir(c.infos.config) / RelativeFile(m.suffix & ".s.bif")).string
  if not fileExists(semFile): return
  var sm = bif.load(semFile)
  m.semIndex = indexFromBif(sm, m.suffix)
  m.semBuf = ensureMove sm.buf

proc hasTypeOffset(c: var DecodeContext; module: FileIndex; nifName: string): bool =
  ## Does a TYPE def for `nifName` exist for `module` — in the primary buffer, or
  ## (lowered primary) the `.s.bif` companion?
  result = false
  let m = c.mods[module]
  if m.index.getOrDefault(nifName).offset != 0: return true
  if m.loweredPrimary:
    ensureSemBuf(c, module)
    result = m.semIndex.getOrDefault(nifName).offset != 0

proc typeCursor(c: var DecodeContext; module: FileIndex; nifName: string): Cursor =
  ## A cursor at a TYPE's `(td …)` def: the primary buffer if present (an `@bk`
  ## closure-env type minted by the lower stage, or any `.s.bif`-primary module),
  ## else the `.s.bif` companion (frontend type defs are NOT carried in `.t.bif`).
  let m = c.mods[module]
  let e = m.index.getOrDefault(nifName)
  if e.offset != 0:
    return cursorAt(m.buf, e.offset)
  if m.loweredPrimary:
    ensureSemBuf(c, module)
    let se = m.semIndex.getOrDefault(nifName)
    if se.offset != 0:
      return cursorAt(m.semBuf, se.offset)
  raiseAssert "symbol has no offset: " & nifName

proc loadNode(c: var DecodeContext; n: var Cursor; thisModule: string;
              localSyms: var Table[string, PSym]): PNode

proc loadSymFromCursor(c: var DecodeContext; s: PSym; n: var Cursor; thisModule: string;
                       localSyms: var Table[string, PSym])

proc reconstructSysType(c: var DecodeContext; name: string; k: int; itemVal: int32): PType =
  ## Rebuild a module-less magic singleton (see `SysModuleSuffix`) from its kind
  ## alone — it has no fields and no `.nif` to load. Cached in `c.types` so all
  ## references in this decode context share one instance.
  result = c.types.getOrDefault(name)[0]
  if result == nil:
    let id = itemId(-1'i32, itemVal)
    result = PType(itemId: id, bindingId: id, kind: TTypeKind(k), state: Complete)
    if TTypeKind(k) == tyNil:
      result.sizeImpl = c.infos.config.target.ptrSize
      result.alignImpl = int16 c.infos.config.target.ptrSize
    c.types[name] = (result, NifIndexEntry())

proc stripBkSuffix(rawMod: string): (bool, string) {.inline.} =
  ## Split a possibly-`@bk` (BackendLocalMarker) module suffix into
  ## `(isBackendMinted, realSuffix)`. See `toNifSymName`/`nifTypeName`.
  if rawMod.endsWith(BackendLocalMarker):
    (true, rawMod[0 ..< rawMod.len - BackendLocalMarker.len])
  else:
    (false, rawMod)

proc nextSymId(c: var DecodeContext; module: FileIndex; isBk: bool): ItemId =
  ## Mint the next per-module SYM id from `symCounter`: a `backendItemId` for a
  ## process-local `@bk` sym, else a plain loader `itemId`. Both draw from the one
  ## counter so loaded and cg-minted backend syms stay disjoint (see
  ## `nextBackendSymItem`). Types do NOT use this — they preserve the item parsed
  ## from their own name (see `tryCreateTypeStub`).
  let val = addr c.mods[module].symCounter
  inc val[]
  result = if isBk: backendItemId(module.int32, val[]) else: itemId(module.int32, val[])

proc mintSymId(c: var DecodeContext; rawMod: string): (FileIndex, ItemId) =
  ## Resolve a possibly-`@bk` module suffix to its FileIndex and mint a fresh sym
  ## id for it — the common case where the module is not needed before minting
  ## (see `stripBkSuffix`/`nextSymId`).
  let (isBk, realMod) = stripBkSuffix(rawMod)
  let module = moduleId(c, realMod)
  result = (module, c.nextSymId(module, isBk))

proc makePartialSymStub(c: var DecodeContext; symAsStr: string; sn: ParsedSymName;
                        id: ItemId; entry: NifIndexEntry): PSym =
  ## Create + cache (keyed by the NIF name) a `Partial` global-sym stub, lazily
  ## filled later by `loadSym` from `entry`. `stubKindAndName` strips NIF-only
  ## markers (e.g. a package's `PkgMarker`) so the backend mangles the clean name.
  let (stubKind, stubName) = stubKindAndName(c.cache, sn.name)
  result = PSym(itemId: id, kindImpl: stubKind, name: stubName,
                disamb: sn.count.int32, state: Partial)
  c.syms[symAsStr] = (result, entry)

proc tryCreateTypeStub(c: var DecodeContext; name: string): PType =
  ## Like `createTypeStub` but returns nil instead of raising when the type has
  ## no offset in its module index (used by the best-effort `(offer …)` loader).
  ## Step 2b: takes the sym NAME string (pool-agnostic) — the reader never juggles
  ## a nifcore/nifstreams `SymId`.
  if not name.startsWith("`t"): return nil
  result = c.types.getOrDefault(name)[0]
  if result == nil:
    var i = len("`t")
    var k = 0
    while i < name.len and name[i] in {'0'..'9'}:
      k = k * 10 + name[i].ord - ord('0')
      inc i
    if i < name.len and name[i] == '.': inc i
    var itemVal = 0'i32
    while i < name.len and name[i] in {'0'..'9'}:
      itemVal = itemVal * 10'i32 + int32(name[i].ord - ord('0'))
      inc i
    if i < name.len and name[i] == '.': inc i
    let suffix = name.substr(i)
    if suffix == SysModuleSuffix:
      return reconstructSysType(c, name, k, itemVal)
    let (isBk, realSuffix) = stripBkSuffix(suffix)
    let modIdx = moduleId(c, realSuffix).int32
    let id = if isBk: backendItemId(modIdx, itemVal) else: itemId(modIdx, itemVal)
    let modFi = id.module.FileIndex
    if not hasTypeOffset(c, modFi, name):
      return nil
    result = PType(itemId: id, bindingId: id, kind: TTypeKind(k), state: Partial)
    # `loadType` re-resolves the buffer via `typeCursor`, so the cached entry is a
    # don't-care for types — store the primary one if any (else a 0-offset stub).
    c.types[name] = (result, c.mods[modFi].index.getOrDefault(name))

proc createTypeStub(c: var DecodeContext; name: string): PType =
  ## As `tryCreateTypeStub`, but a missing index offset is a hard error (the
  ## caller demanded a definition that must exist).
  assert name.startsWith("`t")
  result = tryCreateTypeStub(c, name)
  if result == nil:
    raiseAssert "symbol has no offset: " & name

proc extractLocalSymsFromTree(c: var DecodeContext; n: var Cursor; thisModule: string;
                              localSyms: var Table[string, PSym]) =
  ## Scan a tree for local symbol definitions (sdef tags) and add them to localSyms.
  ## For local symbols, fully load them immediately since they have no index offsets.
  ## After this proc returns, n is positioned AFTER the tree.
  # Atoms (non-compound nodes): nothing to scan, just skip past them.
  if n.kind != TagLit:
    skip n
    return
  if tagIs(n, typeDefTagName):
    # A nested inline type owns its own field name-scope: its fields are object-LOCAL
    # symbols (`<ident>`f.<pos>`) that can collide name+position with a sibling/outer
    # type's field (e.g. astdef's `TLoc.flags` vs `TNode.flags`, both inline). Do NOT
    # pull them into this scope; `loadTypeFromCursor` loads each type's reclist in an
    # isolated `localSyms`.
    skip n
    return
  if tagIs(n, symDefTagName):
    # Found an sdef - check if it's a new local symbol.
    let name = n.firstSon
    expect name, SymbolDef
    let symName = symName(name)
    let sn = parseSymName(symName)
    if sn.module.len == 0 and symName notin localSyms:
      # Local symbol - create stub and immediately load it fully
      # since local symbols have no index offsets for lazy loading
      let module = moduleId(c, thisModule)
      let id = c.nextSymId(module, isBk = false)
      # `stubKindAndName` strips NIF-only markers (e.g. a field's `` `f ``) so the
      # backend mangles the clean name; `loadSymFromCursor` then fills the real kind.
      let (_, stubName) = stubKindAndName(c.cache, sn.name)
      let sym = PSym(itemId: id, kindImpl: skStub, name: stubName,
                    disamb: sn.count.int32, state: Complete)
      localSyms[symName] = sym
      when defined(icLocalSymStats): inc lsExtractReg
      # `loadSymFromCursor` enters the `(sd` and consumes the whole block,
      # leaving n positioned after the closing `)`.
      loadSymFromCursor(c, sym, n, thisModule, localSyms)
      sym.state = c.loadedState  # mark as fully loaded
      return
  # Otherwise descend into every child, scanning each for nested local sdefs.
  n.loopInto:
    extractLocalSymsFromTree(c, n, thisModule, localSyms)

proc loadTypeFromCursor(c: var DecodeContext; n: var Cursor; t: PType; localSyms: var Table[string, PSym])

proc loadTypeStub(c: var DecodeContext; n: var Cursor; localSyms: var Table[string, PSym]): PType =
  if n.kind == DotToken:
    result = nil
    skip n
  elif n.kind == Symbol:
    result = createTypeStub(c, symName(n))
    skip n
  elif n.kind == TagLit and tagIs(n, typeDefTagName):
    result = createTypeStub(c, symName(n.firstSon))
    if result.state == Partial:
      result.state = c.loadedState  # Mark as loaded to prevent loadType from re-loading with empty localSyms
      # A type's reclist is its own field name-scope: object-local field names
      # (`<ident>`f.<pos>`) can collide name+position with the enclosing scope's or a
      # sibling inline type's fields. Load it in an isolated `localSyms`.
      var typeLocalSyms = initTable[string, PSym]()
      loadTypeFromCursor(c, n, result, typeLocalSyms)
    else:
      skip n  # Type already loaded, skip over the td block
  else:
    raiseAssert "type expected but got " & $n.kind

proc loadFieldStub(c: var DecodeContext; symAsStr: string; thisModule: string;
                   localSyms: var Table[string, PSym]; typ: PType = nil): PSym =
  ## A cross-context object-field reference (see `FieldMarker`): its def lives in
  ## the owning type's reclist (a different seek, absent from this body's
  ## `localSyms`), and it has no module suffix / index entry. There is nothing to
  ## resolve — `cgen.genRecordField` re-navigates the object type's reclist by
  ## `name` (`lookupFieldAgain`/`lookupInRecord`), so the use-site field need only
  ## carry the clean field name (+ position for tuples, + type so a lower-stage
  ## transform that builds a fresh node off this sym still re-serializes a type).
  ## NOT shared across uses: each carries its own `typ`, and two distinct fields can
  ## share a local name+position (cross-type), so a shared stub would mistype one.
  let sn = parseSymName(symAsStr)
  let (stubKind, stubName) = stubKindAndName(c.cache, sn.name)
  let module = moduleId(c, thisModule)
  # `sn.count` is the field POSITION (see toNifSymName): tuple element access reads
  # it directly off this stub, so preserve it. Named-object uses re-navigate by name.
  result = PSym(itemId: c.nextSymId(module, isBk = false), kindImpl: stubKind,
                name: stubName, disamb: sn.count.int32, state: Complete)
  result.positionImpl = sn.count.int32
  # `{.cursor.}` rides in the marker (see `CursorFieldMarker`) because the move
  # optimizer reads it straight off the use site (`trees.isCursor`).
  if sn.name.endsWith(CursorFieldMarker): result.flagsImpl.incl sfCursor
  if typ != nil: result.typImpl = typ

proc loadSymStub(c: var DecodeContext; symAsStr: string; thisModule: string;
                 localSyms: var Table[string, PSym]): PSym =
  let sn = parseSymName(symAsStr)
  # For local symbols (no module suffix), they MUST be in localSyms.
  # Local symbols are not in the index - they're defined inline in the NIF file.
  # If not found, it's a bug in how we populate localSyms.
  if sn.module.len == 0:
    result = localSyms.getOrDefault(symAsStr)
    if result != nil:
      when defined(icLocalSymStats): inc lsLocalHit
      return result
    elif isFieldMarked(sn.name):
      when defined(icLocalSymStats): inc lsFieldStub
      # A cross-context object-field reference reaching a non-dotExpr slot (e.g. a
      # `{.guard.}` field, an owner): stub it like any other field use.
      return c.loadFieldStub(symAsStr, thisModule, localSyms)
    else:
      when defined(icLocalSymStats): inc lsMiss
      raiseAssert "local symbol '" & symAsStr & "' not found in localSyms."
  # Global symbol - look up in index for lazy loading
  result = c.syms.getOrDefault(symAsStr)[0]
  if result == nil:
    # A process-local backend sym (closure env field / `:env` param) is named
    # `…<thisModuleSuffix>@bk`: `mintSymId` homes it to that module with a
    # backendItemId so it stays disjoint from the loader's real id space.
    let (module, id) = c.mintSymId(sn.module)
    let offs = c.mods[module].index.getOrDefault(symAsStr)
    if offs.offset == 0:
      # Only module/package self-syms are never written as `(sd)` entries, so a
      # missing index offset means this is such a sym — typically the OWNER of an
      # `include`d symbol (`<module>.0.<suffix>`). Synthesize a resolvable
      # skModule stub (itemId item-0 = the module self-sym) instead of asserting
      # "symbol has no offset". `Complete` so accessors never try to lazy-load it.
      result = PSym(itemId: itemId(module.int32, 0'i32), kindImpl: skModule,
                    name: c.cache.getIdent(sn.name), disamb: sn.count.int32,
                    infoImpl: newLineInfo(module, 1, 1), state: Complete)
      c.syms[symAsStr] = (result, NifIndexEntry())
      return result
    result = c.makePartialSymStub(symAsStr, sn, id, offs)

proc loadSymStub(c: var DecodeContext; n: var Cursor; thisModule: string;
                 localSyms: var Table[string, PSym]): PSym =
  if n.kind == DotToken:
    result = nil
    skip n
  elif n.kind == Symbol:
    result = loadSymStub(c, symName(n), thisModule, localSyms)
    skip n
  elif n.kind == TagLit and tagIs(n, symDefTagName):
    let s = symName(n.firstSon)
    skip n
    result = loadSymStub(c, s, thisModule, localSyms)
  else:
    raiseAssert "sym expected but got " & $n.kind & (
      if n.kind == Ident: " '" & strVal(n) & "'" else: "")

proc isStub*(t: PType): bool {.inline.} = t.state == Partial
proc isStub*(s: PSym): bool {.inline.} = s.state == Partial

proc loadAtom[T](t: typedesc[set[T]]; n: var Cursor): set[T] =
  if n.kind == DotToken:
    result = {}
    skip n
  else:
    expect n, Ident
    result = parse(T, strVal(n))
    skip n

proc loadAtom[T: enum](t: typedesc[T]; n: var Cursor): T =
  if n.kind == DotToken:
    result = default(T)
    skip n
  else:
    expect n, Ident
    result = parse(T, strVal(n))
    skip n

proc loadAtom(t: typedesc[string]; n: var Cursor): string =
  expect n, StrLit
  result = strVal(n)
  skip n

proc loadAtom[T: int16|int32|int64](t: typedesc[T]; n: var Cursor): T =
  expect n, IntLit
  result = intVal(n).T
  skip n

template loadField(field) {.dirty.} =
  field = loadAtom(typeof(field), n)

proc loadLoc(c: var DecodeContext; n: var Cursor; loc: var TLoc) =
  loadField loc.k
  loadField loc.storage
  loadField loc.flags
  loadField loc.snippet

proc loadTypeFromCursor(c: var DecodeContext; n: var Cursor; t: PType; localSyms: var Table[string, PSym]) =
  expect n, TagLit
  if not tagIs(n, typeDefTagName):
    raiseAssert "(td) expected"

  var scanCursor = n  # copy cursor at start of type
  var typesModule = parseSymName(symName(n.firstSon)).module
  if typesModule.endsWith(BackendLocalMarker):
    # A backend-minted (`@bk`) type's name carries the marker in its module part;
    # strip it so the nested-local pre-scan resolves the real module, not a
    # nonexistent `<suffix>@bk.nif`.
    typesModule = typesModule[0 ..< typesModule.len - BackendLocalMarker.len]
  extractLocalSymsFromTree(c, scanCursor, typesModule, localSyms)

  n.into:  # enter (td, body consumes all children, closing ) is consumed by `into`
    expect n, SymbolDef
    # ignore the type's name, we have already used it to create this PType's itemId!
    skip n
    expect n, DotToken
    skip n
    #loadField t.kind
    loadField t.flagsImpl
    loadField t.callConvImpl
    loadField t.sizeImpl
    loadField t.alignImpl
    loadField t.paddingAtEndImpl
    if n.kind == DotToken:
      # no `(bid ...)`: not a replica, so the binding id is the type's own id,
      # which `createTypeStub` already took from the name
      skip n
    else:
      n.into:
        t.bindingId = itemId(t.bindingId.module, loadAtom(int32, n))
        # `hasMore` first: inside `into` the module half is optional, and asking
        # a spent cursor for its `kind` asserts
        if n.hasMore and n.kind == StrLit:
          # a replica of a foreign type: restore the module half too
          t.bindingId = itemId(int32(moduleId(c, strVal(n))), t.bindingId.item)
          skip n

    t.typeInstImpl = loadTypeStub(c, n, localSyms)
    t.nImpl = loadNode(c, n, typesModule, localSyms)
    t.ownerFieldImpl = loadSymStub(c, n, typesModule, localSyms)
    t.symImpl = loadSymStub(c, n, typesModule, localSyms)
    loadLoc c, n, t.locImpl

    while n.hasMore:
      t.sonsImpl.add loadTypeStub(c, n, localSyms)

proc loadType*(c: var DecodeContext; t: PType) =
  if t.state != Partial: return
  t.state = c.loadedState
  recordLoad(c, t.itemId.module.FileIndex, isType = true)
  # A backend-minted (`@bk`) closure-env type produced by the `lower` stage lives
  # ONLY in the `.t.nif` and is keyed by its `@bk` name (see nifTypeName), not the
  # canonical `typeToNifSym` (which asserts non-`@bk`). Reconstruct that name so a
  # Partial `@bk` stub that escaped the inline pre-scan can still be force-loaded.
  let typeName =
    if t.itemId.isBackendMinted:
      "`t" & $ord(t.kind) & "." & $t.itemId.item & "." &
        modname(t.itemId.module, c.infos.config) & BackendLocalMarker
    else:
      typeToNifSym(t, c.infos.config)
  # `itemId`, not `bindingId`: the name just built above is the type's own NIF
  # name, so it must be looked up in the module that owns that name.
  let modFi = t.itemId.module.FileIndex
  # `typeCursor` resolves to the primary `.t.bif` (`@bk` env types) or falls back to
  # the `.s.bif` companion (frontend type defs, which `.t.bif` no longer carries).
  var n = typeCursor(c, modFi, typeName)
  var localSyms = initTable[string, PSym]()
  loadTypeFromCursor(c, n, t, localSyms)

proc loadAnnex(c: var DecodeContext; n: var Cursor; thisModule: string; localSyms: var Table[string, PSym]): PLib =
  if n.kind == DotToken:
    result = nil
    skip n
  elif n.kind == TagLit:
    result = PLib(kind: parse(TLibKind, cursorTag(n)))
    n.into:
      result.generated = loadBool(n)
      result.isOverridden = loadBool(n)
      expect n, StrLit
      result.name = strVal(n)
      skip n
      result.path = loadNode(c, n, thisModule, localSyms)
  else:
    raiseAssert "`lib/annex` information expected"

proc loadSymFromCursor(c: var DecodeContext; s: PSym; n: var Cursor; thisModule: string;
                       localSyms: var Table[string, PSym]) =
  ## Loads a symbol definition. The cursor must be positioned AT the opening
  ## `(sd` TagLit; `into` consumes the whole sdef including its closing `)`.
  n.into:
    expect n, SymbolDef
    # ignore the symbol's name, we have already used it to create this PSym instance!
    skip n
    if n.kind == Ident:
      if strVal(n) == "x":
        s.flagsImpl.incl sfExported
        skip n
      else:
        raiseAssert "expected `x` as the export marker"
    elif n.kind == DotToken:
      skip n
    else:
      raiseAssert "expected `x` or '.' but got " & $n.kind

    expect n, TagLit
    {.cast(uncheckedAssign).}:
      s.kindImpl = parse(TSymKind, cursorTag(n))

    if s.kindImpl == skPackage and s.name.s.endsWith(PkgMarker):
      # Fallback: stubs are normally created with the clean name already
      # (see stubKindAndName); strip the NIF-only marker if one slipped through.
      s.name = c.cache.getIdent(s.name.s[0 ..< s.name.s.len - PkgMarker.len])

    n.into:  # the (kind ...) sub-block
      case s.kindImpl
      of skLet, skVar, skField, skForVar:
        s.guardImpl = loadSymStub(c, n, thisModule, localSyms)
        loadField s.bitsizeImpl
        loadField s.alignmentImpl
      else:
        discard

    loadField s.magicImpl
    loadField s.flagsImpl
    loadField s.optionsImpl
    loadField s.offsetImpl

    if s.kindImpl == skModule:
      expect n, DotToken
      skip n
      var isKnownFile = false
      s.positionImpl = int c.infos.config.registerNifSuffix(thisModule, isKnownFile)
      # do to the precompiled mechanism things end up as main modules which are not!
      excl s.flagsImpl, sfMainModule
    else:
      loadField s.positionImpl

    s.annexImpl = loadAnnex(c, n, thisModule, localSyms)

    # Local symbols were already extracted upfront in loadSym, so we can use
    # the simple loadTypeStub here.
    s.typImpl = loadTypeStub(c, n, localSyms)
    s.ownerFieldImpl = loadSymStub(c, n, thisModule, localSyms)
    # Load the AST for routine symbols and constants
    # Constants need their AST for astdef() to return the constant's value
    let astNodesBefore = nodesDecoded
    s.astImpl = loadNode(c, n, thisModule, localSyms)
    if loadStatsInit == 1 and s.kindImpl in routineKinds:
      astFieldNodes += nodesDecoded - astNodesBefore
    loadLoc c, n, s.locImpl
    s.constraintImpl = loadNode(c, n, thisModule, localSyms)
    s.instantiatedFromImpl = loadSymStub(c, n, thisModule, localSyms)
    # The TRANSFORMED body slot (see writeSymDef). It means DIFFERENT things by
    # which file `moduleId` loaded (see toNifFilename):
    #  * `cg`/`emit` read `.t.bif` — the slot is the `lower` stage's AUTHORITATIVE
    #    lowered body; ALWAYS load it so `transformBody` short-circuits and the
    #    backend NEVER re-derives (the whole point of the artifact).
    #  * the `lower` stage reads `.s.bif` — the slot is the VM/CT lowering sem
    #    cached; load it only when REUSE is on (`icReuseSemLowering`), else leave
    #    `transformedBody` nil so the `lower` stage re-derives from the pristine
    #    body (the 2026-06-27 simplicity spec, doc/ic_backend_simplify.md §6).
    #  * frontend `cmdM` never loads it (a dependent needs no foreign lowered body,
    #    and reconstructing one must not perturb effect/exception inference).
    let conf = c.infos.config
    let loadSlot = s.kindImpl in routineKinds and conf.cmd == cmdNifC and
      (conf.icBackendStage == "cg" or conf.icBackendStage == "emit" or
       (conf.icBackendStage == "lower" and icReuseSemLowering(conf)))
    if loadSlot:
      s.transformedBodyImpl = loadNode(c, n, thisModule, localSyms)
    else:
      skip n

proc loadSym*(c: var DecodeContext; s: PSym) =
  if s.state != Partial: return
  s.state = c.loadedState
  if loaderCtx == nil: loaderCtx = addr c
  recordLoad(c, s.itemId.module.FileIndex, isType = false)
  let symsModule = s.itemId.module.FileIndex
  let nifname = globalName(s, c.infos.config)
  var n = cursorFromIndexEntry(c, symsModule, c.syms[nifname][1])

  expect n, TagLit
  if not tagIs(n, symDefTagName):
    raiseAssert "(sd) expected"

  # Pre-scan the ENTIRE symbol definition to extract ALL local symbols upfront.
  # This ensures local symbols are registered before any references to them,
  # regardless of where they appear in the definition (in types, nested procs, etc.)
  var localSyms = initTable[string, PSym]()
  var scanCursor = n
  extractLocalSymsFromTree(c, scanCursor, c.mods[symsModule].suffix, localSyms)

  # Now parse the symbol definition with all local symbols pre-registered
  s.infoImpl = c.infos.oldLineInfo(n.info, cursorPool(n))
  # The `##` doc comment (if any) rides as a NIF comment on the sym def token;
  # capture it before advancing, then restore it onto the loaded AST so that
  # suggest's `extractDocComment` (findDocComment on `s.ast`) finds it.
  let docId = rawLineInfo(n).comment   # nifcore StrId of the `#..#` doc comment
  let docPool = cursorPool(n)          # the buffer's own strings pool (shared or bif-fresh)
  loadSymFromCursor(c, s, n, c.mods[symsModule].suffix, localSyms)
  if uint32(docId) != 0'u32 and s.astImpl != nil and nodeCommentWriter != nil:
    nodeCommentWriter(s.astImpl, docPool.strings[docId])

proc sealLoadedRoutines*(c: var DecodeContext) =
  ## Before `writeLoweredModule` re-serializes the lowered module, seal ONLY the
  ## module's ROUTINE syms. A `.t.nif` written by `writeLoweredModule` is the
  ## SOLE source the `cg` stage loads (there is no `.s.nif` fallback for its
  ## bodies), so every type, global, param and local must still emit a REAL def
  ## in it — only cross-routine references may be `SymUse`s (each routine's def is
  ## emitted once, at module scope, by the explicit stub loop). Types/globals stay
  ## `Complete` so `writeType`/`writeGlobals` emit them; routines become `Sealed`
  ## so a body referencing another routine writes a `SymUse` resolved through the
  ## module index.
  for _, v in c.syms:
    if v[0] != nil and v[0].state == Complete and v[0].kindImpl in routineKinds:
      v[0].state = Sealed

proc resolveHookSym*(c: var DecodeContext; name: string): PSym

template withNode(c: var DecodeContext; n: var Cursor; result: PNode; kind: TNodeKind; body: untyped) =
  let info = c.infos.oldLineInfo(n.info, cursorPool(n))
  result = newNodeI(kind, info)
  n.into:
    result.flags = loadAtom(TNodeFlags, n)
    result.typField = c.loadTypeStub(n, localSyms)
    body

proc loadNode(c: var DecodeContext; n: var Cursor; thisModule: string;
              localSyms: var Table[string, PSym]): PNode =
  if loadStatsInit == 1: inc nodesDecoded
  result = nil
  case n.kind
  of Symbol:
    let info = c.infos.oldLineInfo(n.info, cursorPool(n))
    let symName = symName(n)
    # Check local symbols first
    let localSym = localSyms.getOrDefault(symName)
    if localSym != nil:
      result = newSymNode(localSym, info)
      skip n
    elif isFieldNifName(symName):
      # Cross-context object-field reference: stub a `skField` from the local name
      # (see `loadFieldStub`). The field's type is recovered from the object type at
      # codegen time, so this leaf carries no type of its own.
      result = newSymNode(c.loadFieldStub(symName, thisModule, localSyms), info)
      result.flags.incl nfLazyType
      skip n
    else:
      result = newSymNode(c.loadSymStub(n, thisModule, localSyms), info)
      if result.typField == nil:
        result.flags.incl nfLazyType
  of DotToken:
    result = nil
    skip n
  of StrLit:
    result = newStrNode(strVal(n), c.infos.oldLineInfo(n.info, cursorPool(n)))
    skip n
  of TagLit:
    let kind = n.nodeKind
    case kind
    of nkNone:
      # special NIF introduced tag?
      if tagIs(n, hiddenTypeTagName):
        n.into:
          let typ = c.loadTypeStub(n, localSyms)
          let info = c.infos.oldLineInfo(n.info, cursorPool(n))
          var s: PSym
          if n.kind == Symbol and isFieldNifName(symName(n)):
            # Field SymUse wrapped with its explicit type (see writeSymNode): stub
            # the field, carrying the wrapper's type on BOTH the node and the sym so
            # a lower-stage transform that builds a fresh node off the sym still has a
            # type to re-serialize.
            s = c.loadFieldStub(symName(n), thisModule, localSyms, typ)
            skip n
          else:
            s = c.loadSymStub(n, thisModule, localSyms)
          result = newSymNode(s, info)
          result.typField = typ
          # `(ht . <sym>)` — an EXPLICITLY nil node type — is left exactly as the
          # writer meant it: NIL. The wrapper is only emitted when the node's own
          # type differed from its symbol's (`writeSymNode`), so a nil here says
          # the node genuinely had no type while the symbol had one, and that is
          # load-bearing: a type symbol used as a VALUE (`newException(KeyError,
          # ...)`) is exactly that shape, and handing it `sym.typ` makes sem read
          # the typedesc as an expression of the type it denotes ("only a 'ref
          # object' can be raised").
          #
          # There IS a load-order dependence here — `newSymNode` above marks the
          # node lazy when the symbol was still an unloaded stub, so `ast.typ`
          # answers `sym.typ` for that population and `nil` for the rest — and it
          # is NOT fixed by pinning the flag either way: setting it breaks sem as
          # above, and clearing it would strip the fallback from the stub
          # population that `nifcBackendActive` exists to serve. Left alone
          # deliberately; `bnode.typ` answers the faithful `nil` and the grinder
          # excludes this one shape with the reason recorded there.
      elif tagIs(n, symDefTagName):
        let info = c.infos.oldLineInfo(n.info, cursorPool(n))
        let name = n.firstSon
        assert name.kind == SymbolDef
        let symName = symName(name)
        # Check if this is a local symbol (no module suffix in name)
        let sn = parseSymName(symName)
        let isLocal = sn.module.len == 0
        var sym: PSym
        # In every branch below `n` stays at the `(sd` TagLit; `loadSymFromCursor`
        # enters and consumes the whole block, and `skip n` consumes it wholesale.
        if isLocal:
          # Local symbol - not in the index, defined inline in NIF.
          # Check if we already have a stub from extractLocalSymsFromType
          sym = localSyms.getOrDefault(symName)
          if sym == nil:
            # First time seeing this local symbol - create it
            let module = moduleId(c, thisModule)
            let id = c.nextSymId(module, isBk = false)
            # strip NIF-only markers (a field's `` `f ``) so the backend sees the
            # clean name; `loadSymFromCursor` below fills the real kind.
            let (_, stubName) = stubKindAndName(c.cache, sn.name)
            sym = PSym(itemId: id, kindImpl: skStub, name: stubName,
                       disamb: sn.count.int32, state: Complete)
            localSyms[symName] = sym  # register for later references
            when defined(icLocalSymStats): inc lsSdReg
          # Now fully load the symbol from the sdef
          loadSymFromCursor(c, sym, n, thisModule, localSyms)
          sym.state = c.loadedState  # mark as fully loaded
          result = newSymNode(sym, info)
        elif sn.module.endsWith(BackendLocalMarker):
          # A backend-minted (`@bk`) def lives ONLY inline in this `.t.nif` body
          # (not in any module index): create/find its cached stub and FILL it
          # from the sdef instead of skipping (which would leave the skModule/
          # Partial stub `loadSymStub` made unresolved).
          sym = c.loadSymStub(symName, thisModule, localSyms)
          if sym.state == Partial:
            sym.state = c.loadedState
            loadSymFromCursor(c, sym, n, thisModule, localSyms)
          else:
            skip n
          result = newSymNode(sym, info)
          result.flags.incl nfLazyType
        else:
          # A module-homed inline sdef. Normally its def lives in that module's
          # index and is loaded lazily, so we skip the inline copy. BUT a
          # transform-created closure-env FIELD (`x0.0.clo`) is module-homed yet
          # lives ONLY inline in this `.t.nif` reclist — it has no index entry.
          # Skipping it leaves a nil-typed `skModule` fallback stub (from
          # loadSymStub's "no offset" path) and codegen of the env struct then
          # dereferences a nil field type. Detect the unindexed case and FILL
          # the sym from the inline def instead.
          let m = moduleId(c, sn.module)
          let indexed = c.mods[m].index.hasKey(symName)
          if indexed:
            sym = c.loadSymStub(symName, thisModule, localSyms)
            skip n  # skip the entire sdef for indexed symbols
          else:
            sym = c.syms.getOrDefault(symName)[0]
            if sym == nil:
              sym = PSym(itemId: c.nextSymId(m, isBk = false), kindImpl: skStub,
                         name: c.cache.getIdent(sn.name), disamb: sn.count.int32,
                         state: Partial)
            c.syms[symName] = (sym, NifIndexEntry())
            sym.state = c.loadedState
            loadSymFromCursor(c, sym, n, thisModule, localSyms)
          result = newSymNode(sym, info)
          result.flags.incl nfLazyType
      elif tagIs(n, symNodeFlagsTagName):
        # `(nflags <ident> <symuse>)`: node flags for the wrapped sym use.
        n.into:
          let flags = loadAtom(TNodeFlags, n)
          result = loadNode(c, n, thisModule, localSyms)
          if result != nil: result.flags = result.flags + flags
          while n.hasMore: skip n
      elif tagIs(n, typeDefTagName):
        raiseAssert "`td` tag in invalid context"
      elif tagIs(n, "none"):
        result = newNodeI(nkNone, c.infos.oldLineInfo(n.info, cursorPool(n)))
        n.into:
          result.flags = loadAtom(TNodeFlags, n)
      else:
        raiseAssert "Unknown NIF tag " & cursorTag(n)
    of nkEmpty:
      result = newNodeI(nkEmpty, c.infos.oldLineInfo(n.info, cursorPool(n)))
      n.into:
        if n.hasMore:
          result.flags = loadAtom(TNodeFlags, n)
          result.typField = c.loadTypeStub(n, localSyms)
    of nkIdent:
      let info = c.infos.oldLineInfo(n.info, cursorPool(n))
      n.into:
        let flags = loadAtom(TNodeFlags, n)
        let typ = c.loadTypeStub(n, localSyms)
        expect n, Ident
        result = newIdentNode(c.cache.getIdent(strVal(n)), info)
        skip n
        result.flags = flags
        result.typField = typ
    of nkSym:
      #let info = c.infos.oldLineInfo(n.info, cursorPool(n))
      #result = newSymNode(c.loadSymStub n, info)
      raiseAssert "nkSym should be mapped to a NIF symbol, not a tag"
    of nkCharLit:
      c.withNode n, result, kind:
        expect n, CharLit
        result.intVal = n.charLit.int
        skip n
    of nkIntLit .. nkInt64Lit:
      c.withNode n, result, kind:
        expect n, IntLit
        result.intVal = intVal(n)
        skip n
    of nkUIntLit .. nkUInt64Lit:
      c.withNode n, result, kind:
        expect n, UIntLit
        result.intVal = cast[BiggestInt](uintVal(n))
        skip n
    of nkFloatLit .. nkFloat128Lit:
      c.withNode n, result, kind:
        if n.kind == FloatLit:
          result.floatVal = floatVal(n)
          skip n
        elif n.kind == TagLit:
          if tagIs(n, "inf"):
            result.floatVal = Inf
          elif tagIs(n, "nan"):
            result.floatVal = NaN
          elif tagIs(n, "neginf"):
            result.floatVal = NegInf
          else:
            raiseAssert "expected float literal but got " & cursorTag(n)
          n.into:
            discard
        else:
          raiseAssert "expected float literal but got " & $n.kind
    of nkStrLit .. nkTripleStrLit:
      c.withNode n, result, kind:
        expect n, StrLit
        result.strVal = strVal(n)
        skip n
    of nkNilLit:
      c.withNode n, result, kind:
        discard
    of routineDefs:
      # Defer the heavy `bodyPos` son: build the routine-def header eagerly, but
      # install a `nfLazyBody` placeholder (carrying the real body kind, so cheap
      # `ast[bodyPos].kind != nkEmpty` checks need no load) whose children are
      # materialized on demand (see `materializeLazyBody`, driven by the `len`
      # hook). An empty body is a single node — not worth deferring.
      #
      # ONLY an `nkStmtList` body is deferred, and that restriction is what keeps
      # the placeholder a WELL-FORMED node. The compiler's most basic invariant is
      # that a node's kind implies its arity: every `case n.kind` is entitled to
      # reach `n[0]`/`n[1]` without asking `len` first, and hundreds do. A
      # childless placeholder claiming to be an `nkAsgn` breaks that — `x = s` as a
      # nested proc's whole body IndexDefect'd in `trees.getPotentialWrites`, which
      # does exactly `n[0]`/`n[1]` under `of nkAsgn`. A childless `nkStmtList` is
      # legal, so no such reader can be surprised.
      #
      # Hooking `[]` instead would not close this: `sons` is a public field with
      # ~35 direct uses in the compiler, plus `firstSon`/`secondSon`/`lastSon`,
      # and none of them route through `[]`. Nor does the restriction cost much:
      # `nkStmtList` is 82.5% of the 278_604 bodies a `nim ic` of the compiler
      # defers, and 13.1% of the rest are one-line `nkAsgn` bodies.
      c.withNode n, result, kind:
        var idx = 0
        while n.hasMore:
          if idx == bodyPos and n.kind == TagLit and
             n.nodeKind == nkStmtList:
            let info = c.infos.oldLineInfo(n.info, cursorPool(n))
            let ph = newNodeI(n.nodeKind, info)
            ph.flags.incl nfLazyBody
            c.pendingBodies[cast[int](ph)] =
              PendingBody(cursor: n, thisModule: thisModule, localSyms: localSyms)
            result.sons.add ph
            skip n
          else:
            result.sons.add c.loadNode(n, thisModule, localSyms)
          inc idx
    else:
      c.withNode n, result, kind:
        while n.hasMore:
          result.sons.add c.loadNode(n, thisModule, localSyms)
  else:
    raiseAssert "expected string literal but got " & $n.kind

proc materializeLazyBody*(c: var DecodeContext; node: PNode) =
  ## Fill a `nfLazyBody` placeholder's children in place (identity-preserving:
  ## callers already hold `node`). Decodes the deferred body from the stashed
  ## cursor with the enclosing def's `localSyms` so param/local refs resolve to
  ## the SAME PSyms the signature created.
  node.flags.excl nfLazyBody   # clear first: the loadNode below calls `len`
  let key = cast[int](node)
  var pb = PendingBody()
  if not c.pendingBodies.pop(key, pb): return
  var cur = pb.cursor
  let real = c.loadNode(cur, pb.thisModule, pb.localSyms)
  # `real` has the same kind as the placeholder (peeked at defer time); graft its
  # decoded content onto the node the callers hold.
  node.sons = real.sons
  node.typField = real.typField
  node.flags = real.flags

# ---------------------------------------------------------------------------
# Cursor-native backend seam (see `bnode.nim`)
#
# The three things a `.bif` `Cursor` cannot answer on its own — what symbol a
# `Symbol` token names, what type a node's type slot denotes, and what
# `TLineInfo` its packed line info maps to — all need the decoder's state. They
# are exposed here rather than reimplemented in `bnode` so that the Cursor
# backend and the `PNode` loader resolve names through exactly the same code.
# ---------------------------------------------------------------------------

type
  BodyScope* = object
    ## Resolution scope for reading ONE routine body straight off a cursor.
    ## `thisModule` is the owning module's NIF suffix (a `Symbol` token with no
    ## module suffix is body-local and appears in no index) and `localSyms` is
    ## the enclosing sym def's local symbols, so a param/local reference
    ## resolves to the SAME `PSym` the signature already created.
    thisModule*: string
    localSyms*: Table[string, PSym]

proc lazyBodyCursor*(c: var DecodeContext; node: PNode; scope: var BodyScope;
                     body: var Cursor): bool =
  ## Non-destructive lookup of a deferred routine body: the cursor at its
  ## `(stmtlist ...)` plus the scope its symbol references resolve in. Unlike
  ## `materializeLazyBody` this does NOT consume the pending entry, so the
  ## `PNode` path still works afterwards and the two representations of the same
  ## body can be walked side by side and compared — which is how a proc migrated
  ## to `BNode` is checked against the one it replaces.
  let key = cast[int](node)
  if not c.pendingBodies.hasKey(key): return false
  let pb = c.pendingBodies[key]
  body = pb.cursor
  scope = BodyScope(thisModule: pb.thisModule, localSyms: pb.localSyms)
  result = true

proc symFromCursor*(c: var DecodeContext; n: Cursor; scope: var BodyScope): PSym =
  ## The `PSym` a `Symbol` / `SymbolDef` / `(sd ...)` token names. Non-consuming
  ## (`loadSymStub` advances a `var Cursor`; this one works on a copy).
  ##
  ## The bare `SymbolDef` case goes through the by-name overload: the cursor
  ## overload of `loadSymStub` deliberately rejects it, because inside the
  ## loader a def token is always reached through its `(sd ...)` wrapper and a
  ## bare one means a malformed stream. A reader that starts at an arbitrary
  ## token has no such guarantee, and the def NAMES the same symbol the use
  ## does.
  var cur = n
  if cur.kind == SymbolDef:
    result = loadSymStub(c, symName(cur), scope.thisModule, scope.localSyms)
  else:
    result = loadSymStub(c, cur, scope.thisModule, scope.localSyms)

proc typeFromCursor*(c: var DecodeContext; n: Cursor; scope: var BodyScope): PType =
  ## The `PType` a node's type slot denotes — a `Symbol`, an inline `(td ...)`,
  ## or a `DotToken` for "no type of its own". Non-consuming.
  var cur = n
  result = loadTypeStub(c, cur, scope.localSyms)

proc nodeFlagsFromCursor*(n: Cursor): TNodeFlags =
  ## The node-flags slot: an `Ident` naming the set, or a `DotToken` for empty.
  ## Non-consuming.
  var cur = n
  result = loadAtom(TNodeFlags, cur)

proc identFromCursor*(c: var DecodeContext; n: Cursor): PIdent =
  ## The `PIdent` an `Ident` token names, interned in the SAME cache the loader
  ## uses — `nkIdent` nodes compare by identity in places.
  result = c.cache.getIdent(strVal(n))

proc lineInfoFromCursor*(c: var DecodeContext; n: Cursor): TLineInfo =
  ## The `TLineInfo` for a token's packed line info. The `FileId` inside belongs
  ## to the `.bif`'s OWN filename pool, so the mapping needs both the pool and
  ## the `ConfigRef` the `LineInfoWriter` holds.
  result = c.infos.oldLineInfo(n.info, cursorPool(n))

forceLazyBodyHook = proc (n: PNode) {.nimcall, raises: [], tags: [], gcsafe.} =
  # `len` (the sole caller path) MUST stay effect-free, so this hook is typed
  # `raises: []`. The underlying `loadNode` chain infers `raises: [KeyError]`
  # (index/sym Table lookups), but materialization only ever runs for a body
  # DEFERRED during THIS load — the buffer/index is present by construction, so a
  # KeyError here means a corrupt cache: a fatal bug, not a recoverable error.
  # Treat it as effect-free (a `Defect`-like invariant) via a scoped cast.
  if loaderCtx != nil:
    {.cast(raises: []).}:
      {.cast(tags: []).}:
        {.cast(gcsafe).}:
          materializeLazyBody(loaderCtx[], n)

proc loadSymFromIndexEntry(c: var DecodeContext; module: FileIndex;
                           nifName: string; entry: NifIndexEntry; thisModule: string): PSym =
  ## Loads a symbol from the NIF index entry using the entry directly.
  ## Creates a symbol stub without looking up in the index (since the index may be moved out).
  result = c.syms.getOrDefault(nifName)[0]
  if result == nil:
    let sn = parseSymName(nifName)
    let rawMod = if sn.module.len > 0: sn.module else: thisModule
    let (_, id) = c.mintSymId(rawMod)
    result = c.makePartialSymStub(nifName, sn, id, entry)

proc extractBasename(nifName: string): string =
  ## Extract the base name from a NIF name (ident.disamb.module -> ident)
  result = ""
  for c in nifName:
    if c == '.': break
    result.add c

proc populateInterfaceTablesFromIndex(c: var DecodeContext; module: FileIndex;
                                      interf, interfHidden: var TStrTable; thisModule: string) =
  ## Populates interface tables from the NIF index structure.
  ## Uses the simple embedded index for offsets, exports passed from processTopLevel.

  # Move the index table out to avoid iterator invalidation
  # (moduleId can add to c.mods which would invalidate Table iterators)
  var indexTab = move c.mods[module].index

  # Only the EXPORTED half; `buildHiddenInterface` below does the rest, on
  # demand. Exported symbols go into both tables, which costs little and leaves
  # `interfHidden` a coherent view of a module with no hidden symbols rather
  # than an empty one.
  prof pIfaceModules
  for nifName, entry in indexTab:
    if entry.vis == Exported:
      prof pIfaceExported
      let sym = loadSymFromIndexEntry(c, module, nifName, entry, thisModule)
      if sym != nil:
        strTableAdd(interf, sym)
        strTableAdd(interfHidden, sym)

  # Move index table back
  c.mods[module].index = move indexTab

proc buildHiddenInterface*(c: var DecodeContext; suffix: string;
                           interfHidden: var TStrTable): bool {.discardable.} =
  ## The hidden-only half of a loaded module's interface, materialised on
  ## demand. Deferred because almost nothing reads it: `interfHidden` is reached
  ## exclusively through `modulegraphs.interfSelect`, which picks it only when
  ## `optImportHidden` is in the module's options, and that flag is set in
  ## exactly one place — an `import x {.all.}`. Building it eagerly was 1.05s of
  ## a cold Atlas build: 1.70M hidden stubs against 0.29M exported ones, made by
  ## every `nim m` for every module it imports and read by none of them.
  ##
  ## Takes the module SUFFIX, not a FileIndex, and that is the whole trick. A
  ## module has TWO FileIndexes: `registerNifSuffix` keys
  ## `filenameToIndexTbl` by the suffix string and mints a `fikNifModule` entry,
  ## while the graph indexes `g.ifaces` by the module's `fikSource` file. `c.mods`
  ## is keyed by the former. Asking it with the latter misses every single time,
  ## silently, and an `import x {.all.}` then reports "undeclared identifier"
  ## for a symbol that is right there.
  ##
  ## Returns false when the artifact is not on disk yet — an import the build
  ## has not produced. The caller must leave the request PENDING then: writing
  ## it off on that first miss costs the module its hidden symbols for the rest
  ## of the process.
  let conf = c.infos.config
  if not fileExists((getNimcacheDir(conf) / RelativeFile(suffix & ".s.bif")).string):
    return false
  let module = moduleId(c, suffix, {})
  if not c.mods.hasKey(module): return false
  var indexTab = move c.mods[module].index
  for nifName, entry in indexTab:
    if entry.vis != Exported and not nifName.startsWith("`t"):
      prof pIfaceHidden
      # do not load types, they are not part of an interface but an implementation detail!
      let sym = loadSymFromIndexEntry(c, module, nifName, entry, suffix)
      if sym != nil:
        strTableAdd(interfHidden, sym)
  c.mods[module].index = move indexTab
  result = true

proc moduleSymbolStubs*(c: var DecodeContext; module: FileIndex): seq[PSym] =
  ## Stubs for every non-type symbol serialized in `module`'s NIF index. The
  ## per-module backend uses this to emit the routines a module OWNS: procs are
  ## serialized as `(sd ...)` symbol-defs and loaded lazily, never as
  ## `nkProcDef` statements in the top-level stmt list, so `genTopLevelStmt`
  ## alone never reaches them — without this, a routine called only from other
  ## modules would be emitted by nobody once the demanding module merely
  ## prototypes it.
  ##
  ## Returns lazy stubs: the index table is moved out while iterating (loading a
  ## symbol can register new modules and invalidate the iterator), so the caller
  ## forces full load (`.kind`, `.ast`) and filters AFTER this returns, with the
  ## index back in place.
  ##
  ## Ordered by the entry's OFFSET, i.e. the order the writer emitted them, which
  ## is source order. A `Table` iteration is hash order — arbitrary, and not even
  ## stable between two compilers — so the `lower` stage transformed a module's
  ## routines in a random order. That is visible (`--expandArc` diagnostics came
  ## out shuffled) and it makes the backend's minted ids depend on the hash seed.
  result = @[]
  if not c.mods.hasKey(module): return
  var indexTab = move c.mods[module].index
  let thisModule = c.mods[module].suffix
  var entries: seq[(int, string)] = @[]
  for nifName, entry in indexTab:
    if nifName.startsWith("`t"): continue  # types are not routines
    entries.add (entry.offset, nifName)
  sort entries
  for (_, nifName) in entries:
    let sym = loadSymFromIndexEntry(c, module, nifName, indexTab[nifName], thisModule)
    if sym != nil: result.add sym
  c.mods[module].index = move indexTab

proc loadedModuleTypes*(c: var DecodeContext; module: FileIndex): seq[PType] =
  ## Stubs for every TYPE this module owns — but, unlike before, WITHOUT force-
  ## loading them. `writeLoweredModule` emits a real def into the `.t.bif` only for
  ## the ones already `Complete` (= the lower stage actually loaded, hence possibly
  ## MUTATED — lambda-lifting flips a proc type to `ccClosure` and grows env types
  ## with captured fields). Every untouched type stays `Partial`, so a reference to
  ## it serializes as a `SymUse` that a cg/emit consumer resolves from the `.s.bif`
  ## (loader fallback `typeCursor`/`ensureSemBuf`) — the lower stage leaves those
  ## defs unchanged, so re-emitting them into `.t.bif` was pure cost. Collect names
  ## first: `createTypeStub` may register modules / mutate `c.types`, which must not
  ## invalidate the index iterator.
  result = @[]
  if not c.mods.hasKey(module): return
  var names: seq[string] = @[]
  for nifName in c.mods[module].index.keys:
    if nifName.startsWith("`t"): names.add nifName
  for nm in names:
    let t = createTypeStub(c, nm)
    if t != nil: result.add t

proc toNifFilename*(conf: ConfigRef; f: FileIndex): string =
  let suffix = moduleSuffix(conf, f)
  # The `cg`/`emit` backend stages load the lowered whole-module NIF (transformed
  # bodies + lifted sigs baked in); the `lower` stage and the frontend (`cmdM`)
  # read the semchecked `.s.bif`. All module artifacts are binary NIF (`.bif`)
  # now — one file per stage, no text twin (debug via `tools/bif2nif`).
  if conf.cmd == cmdNifC and
     (conf.icBackendStage == "cg" or conf.icBackendStage == "emit"):
    let t = toGeneratedFile(conf, AbsoluteFile(suffix), ".t.bif").string
    if fileExists(t):
      return t
  result = toGeneratedFile(conf, AbsoluteFile(suffix), ".s.bif").string

proc resolveSym(c: var DecodeContext; symAsStr: string; alsoConsiderPrivate: bool): PSym =
  result = c.syms.getOrDefault(symAsStr)[0]
  if result != nil:
    return result

  let sn = parseSymName(symAsStr)
  if sn.module.len == 0:
    return nil  # Local symbols shouldn't be hooks
  let (isBk, realMod) = stripBkSuffix(sn.module)
  let module = moduleId(c, realMod)
  # Look up the symbol in the module's index
  # Try both formats: with module suffix (e.g., "foo.0.modulename") and without (e.g., "foo.0.")
  # NIF spec allows local symbols to be stored without module suffix
  var offs = c.mods[module].index.getOrDefault(symAsStr)
  if offs.offset == 0:
    # Try the format without module suffix
    let localKey = sn.name & "." & $sn.count & "."
    offs = c.mods[module].index.getOrDefault(localKey)
  if offs.offset == 0:
    return nil
  if not alsoConsiderPrivate and offs.vis == Hidden:
    return nil
  # Create a stub symbol (skProc: `resolveSym` only resolves hook/routine syms).
  result = PSym(itemId: c.nextSymId(module, isBk), kindImpl: skProc,
                name: c.cache.getIdent(sn.name), disamb: sn.count.int32, state: Partial)
  c.syms[symAsStr] = (result, offs)

proc resolveHookSym*(c: var DecodeContext; name: string): PSym =
  ## Resolves a hook symbol NAME to a PSym.
  ## Hook symbols are often private (generated =destroy, =wasMoved, etc.)
  result = resolveSym(c, name, true)

proc tryResolveCompilerProc*(c: var DecodeContext; name: string; moduleFileIdx: FileIndex): PSym =
  ## Tries to resolve a compiler proc from a module by checking the NIF index.
  ## Returns nil if the symbol doesn't exist. The NIF disamb is mint order, so
  ## `name.0.` can be any of the overloads sharing the name — for `newSeq` it
  ## is the generic magic, not the RTL proc (a refc build then demands codegen
  ## of the generic and dies on `seq[T]`): enumerate the index entries with
  ## this basename and pick the one that carries `sfCompilerProc`.
  result = nil
  let suffix = moduleSuffix(c.infos.config, moduleFileIdx)
  let module = moduleId(c, suffix)
  let prefix = name & "."
  var candidates: seq[int] = @[]
  for key in c.mods[module].index.keys:
    if key.len > prefix.len and key.startsWith(prefix):
      let sn = parseSymName(key)
      if sn.name == name:
        candidates.add sn.count
  # the loads below can grow `c.mods` (symbols reference other modules), so
  # resolve only after the index iteration is done
  for count in candidates:
    let sym = resolveSym(c, name & "." & $count & "." & suffix, true)
    if sym != nil:
      loadSym(c, sym)
      if sfCompilerProc in sym.flagsImpl:
        return sym

proc loadLogOp(c: var DecodeContext; logOps: var seq[LogEntry]; cur: var Cursor;
               kind: LogEntryKind; op: TTypeAttachedOp; module: int) =
  ## Step 2 phase 2: read one `(rep* "key" sym)` from the resident-buffer cursor.
  cur.into:
    expect cur, StrLit
    let key = strVal(cur)
    skip cur
    if cur.hasMore and cur.kind == Symbol:
      let sym = resolveHookSym(c, symName(cur))
      if sym != nil:
        logOps.add LogEntry(kind: kind, op: op, module: module, key: key, sym: sym)
      # else: symbol not indexed, skip this hook entry
      skip cur

type
  ModuleSuffix* = distinct string
  PrecompiledModule* = object
    topLevel*: PNode # top level statements of the main module
    deps*: seq[ModuleSuffix] # other modules we need to process the top level statements of
    logOps*: seq[LogEntry]
    module*: PSym # set by modulegraphs.nim!
    reexportedModules*: seq[(string, string)] # (name, suffix) of re-exported MODULE syms;
                                              # materialized by modulegraphs.nim
    genericOffers*: seq[tuple[generic, inst: PSym; concreteTypes: seq[PType];
                              genericParamsCount: int]]
      ## generic instances this module created; modulegraphs.nim rebuilds
      ## `procInstCache` from them so a consumer reuses the instance instead of
      ## re-instantiating it in its own (operator-blind) module scope.
    typeOffers*: seq[tuple[generic: PSym; inst: PType]]
      ## generic TYPE instances this module created; modulegraphs.nim rebuilds
      ## `typeInstCache` from them so a consumer reuses the baked instance
      ## (e.g. a `mixin`/`compiles()`-dependent array bound) instead of
      ## re-instantiating it with a different bound in its own scope.
    moduleFlags*: int32 ## the module SYMBOL's backend-relevant flags; see
                        ## `(modflags)` / `ModFlagInjectDestructors`.
    includes*: seq[string] # resolved full paths of files this module `include`s;
                           # replayed into `inclToMod` by modulegraphs.nim so that
                           # nimsuggest can map a query in an include file back to
                           # this module (`parentModule`) and recompile it.

proc loadImport(c: var DecodeContext; cur: var Cursor; deps: var seq[ModuleSuffix]) =
  cur.into:
    while cur.hasMore and cur.kind == DotToken: skip cur  # flags / type
    if cur.hasMore and cur.kind == StrLit:
      deps.add ModuleSuffix(strVal(cur))
      skip cur
    else:
      raiseAssert "expected StrLit but got " & $cur.kind

proc loadInclude(c: var DecodeContext; cur: var Cursor; includes: var seq[string]) =
  ## Reads an `(include . . "path"...)` entry written by `trInclude`. The paths
  ## are resolved full paths (see semstmts.evalInclude under cmdM/optCompress).
  cur.into:
    while cur.hasMore and cur.kind == DotToken: skip cur  # flags / type
    while cur.hasMore and cur.kind == StrLit:
      includes.add strVal(cur)
      skip cur

proc scanIncludeGraph*(config: ConfigRef): seq[tuple[includer: string; includes: seq[string]]] =
  ## Standalone "full table" scan of every `<suffix>.nif` in the nimcache: reads
  ## only each module's header records — `(modulesrc "path")` (the includer's own
  ## source) and `(include . . "path"...)` (resolved included files) — and returns
  ## (includerSource, includedSources) pairs for the modules that `include`
  ## anything. No `DecodeContext`, no symbol/index loading: it parses the few dep
  ## tokens at the top of the file and stops at the first non-dep node.
  ##
  ## Used by nimsuggest to answer, for a cold-opened *include* file, "which module
  ## includes me?" without NIF-loading that module — so the includer can be
  ## *source*-compiled (modules that `include` files are never served from NIF).
  result = @[]
  let dir = getNimcacheDir(config)
  if not dirExists(dir.string): return
  # The primary module artifacts are `<suffix>.s.bif` (the sidecars are
  # `.iface.nif`/`.impl.nif`/`.edges.nif`/`.s.deps.nif`, which this glob excludes).
  for f in walkFiles((dir / RelativeFile"*.s.bif").string):
    var m = bif.load(f)
    var includer = ""
    var includes: seq[string] = @[]
    var c = m.buf.beginRead()
    if c.kind == TagLit and tagIs(c, toNifTag(nkStmtList)):
      # The dep records (import/include/reexpmod/modulesrc) are written first and
      # contiguously; `done` short-circuits once the first body node is seen
      # (`into` forbids an early `break`, so we skip the remainder instead).
      var done = false
      c.loopInto:
        if done or c.kind != TagLit:
          skip c
        elif tagIs(c, "include") or tagIs(c, "modulesrc"):
          let isInc = tagIs(c, "include")
          var ic = c
          ic.loopInto:
            if ic.kind == StrLit:
              if isInc: includes.add strVal(ic)
              else: includer = strVal(ic)
            skip ic
          skip c
        elif tagIs(c, "import") or tagIs(c, "reexpmod"):
          skip c
        else:
          done = true
          skip c
    if includer.len > 0 and includes.len > 0:
      result.add (includer, includes)

proc nifModuleHasIncludes*(config: ConfigRef; fileIdx: FileIndex): bool =
  ## Cheap header-only check: does the module's `<suffix>.nif` contain an
  ## `(include ...)` record? Used by nimsuggest (`moduleFromNifFile`) to refuse to
  ## NIF-serve modules that `include` files, so the includer is source-compiled
  ## and the included symbols never round-trip through NIF (which mishandles their
  ## owner/line-info on reload).
  let f = toNifFilename(config, fileIdx)
  if not fileExists(f): return false
  var m = bif.load(f)
  result = false
  var c = m.buf.beginRead()
  if c.kind == TagLit and tagIs(c, toNifTag(nkStmtList)):
    var done = false
    c.loopInto:
      if done or c.kind != TagLit:
        skip c
      elif tagIs(c, "include"):
        result = true
        done = true
        skip c
      elif tagIs(c, "modulesrc") or tagIs(c, "import") or tagIs(c, "reexpmod"):
        skip c
      else:
        done = true
        skip c

proc peekSymKind(c: var DecodeContext; module: FileIndex;
                 entry: NifIndexEntry): TSymKind =
  ## The kind a symbol's `(sd …)` header records, WITHOUT decoding the symbol.
  ##
  ## The layout is `(sd <SymbolDef name> <marker: `x` | `.`> <kind> …)`, which is
  ## exactly what `loadSymFromCursor` walks — that proc is the definition this
  ## mirrors, so the two must be changed together. Anything unexpected answers
  ## `skUnknown` and the caller falls back to a real load rather than guessing.
  var n = cursorFromIndexEntry(c, module, entry)
  if n.kind != TagLit or not tagIs(n, symDefTagName): return skUnknown
  var k = childCursor(n)
  if not k.hasMore or k.kind != SymbolDef: return skUnknown
  skip k                     # the name
  if not k.hasMore: return skUnknown
  skip k                     # the `x` / `.` export marker
  if not k.hasMore or k.kind != TagLit: return skUnknown
  result = parse(TSymKind, cursorTag(k))

proc symKindFast(c: var DecodeContext; sym: PSym; symAsStr: string): TSymKind =
  ## `sym`'s kind, taken from its def header while it is still `Partial` rather
  ## than by forcing the full decode. An already-loaded symbol answers from the
  ## field, and anything the peek cannot read falls back to loading.
  ##
  ## `-d:icPeekKindCheck` grades the peek against the load it replaces, on every
  ## call: the loaded kind is authoritative, so a disagreement is the peek's bug.
  ## The oracle has to be run for the answer to mean anything — and broken on
  ## purpose once, to confirm it fires.
  if sym.state != Partial:
    prof pPeekLoaded
    return sym.kindImpl
  let e = c.syms.getOrDefault(symAsStr)
  if e[1].offset == 0:
    prof pPeekFallback
    loadSym(c, sym)
    return sym.kindImpl
  result = peekSymKind(c, sym.itemId.module.FileIndex, e[1])
  if result == skUnknown:
    # The peek could not read the header. Correct, but it is also how a walk
    # that has drifted out of step with `loadSymFromCursor` would present, so
    # the rate is counted rather than shrugged at: `-d:icBNodeProf` reports
    # `PeekFallback` beside `PeekKind`, and it should stay at zero.
    prof pPeekFallback
    loadSym(c, sym)
    return sym.kindImpl
  prof pPeekKind
  when defined(icPeekKindCheck):
    let peeked = result
    loadSym(c, sym)
    doAssert peeked == sym.kindImpl,
      "peekSymKind disagrees for " & symAsStr & ": peeked " & $peeked &
      " but the load says " & $sym.kindImpl

proc addReexportedEnumFields(c: var DecodeContext; sym: PSym; symAsStr: string;
                             interf: var TStrTable) =
  ## When a non-pure enum type is (re-)exported, its fields must also become
  ## visible (unqualified) to importers. In a from-source build this happens via
  ## `rawImportSymbol`'s enum handling when the type is imported; the lazy IC
  ## importer never runs that, so we materialise the fields into the interface
  ## here, when the export list is processed.
  ##
  ## Only a TYPE can contribute fields, and almost none of an export list is
  ## types — so the kind is read off the def header first (`symKindFast`) rather
  ## than by forcing every exported symbol through a full decode to find out.
  ## That decode was 290ms of an 8.6s build over 34815 symbols.
  if symKindFast(c, sym, symAsStr) != skType: return
  loadSym(c, sym)
  if sym.kindImpl != skType or sfPure in sym.flagsImpl: return
  let et = sym.typImpl
  if et == nil: return
  loadType(c, et)
  if et.kind notin {tyEnum, tyBool}: return
  let fields = et.nImpl
  if fields == nil: return
  for i in 0 ..< fields.len:
    let f = fields[i]
    if f != nil and f.kind == nkSym and f.sym != nil:
      strTableAdd(interf, f.sym)

type
  TopTag = enum
    ## Which top-level directive a tag names. `processTopLevel` used to decide
    ## this with an `elif` chain of ~20 `tagIs` calls, i.e. up to twenty tag-NAME
    ## string comparisons per node, and the common cases (a real statement, or
    ## `implementation`) sit at the END of the chain so the average node walked
    ## all of it — 1.46M nodes on a 68-module build. Resolved once per tag id
    ## instead, and the chain becomes a `case`.
    ttOther, ttReplay, ttUnusedId, ttModFlags,
    ttRepConverter, ttRepDestroy, ttRepWasMoved, ttRepCopy, ttRepSink, ttRepDup,
    ttRepTrace, ttRepDeepCopy, ttRepEnumToStr, ttRepMethod, ttRepPureEnum,
    ttRepCppMember, ttExport, ttInclude, ttImport, ttReexpMod, ttOffer, ttTOffer,
    ttModuleSrc, ttExpansion, ttSig, ttImplementation,
    ttLetSection, ttVarSection, ttPragma

const
  letSectionTag = toNifTag(nkLetSection)
  varSectionTag = toNifTag(nkVarSection)
  pragmaTag = toNifTag(nkPragma)

proc classifyTopTag(name: string): TopTag =
  case name
  of "replay": ttReplay
  of "unusedid": ttUnusedId
  of "modflags": ttModFlags
  of "repconverter": ttRepConverter
  of "repdestroy": ttRepDestroy
  of "repwasmoved": ttRepWasMoved
  of "repcopy": ttRepCopy
  of "repsink": ttRepSink
  of "repdup": ttRepDup
  of "reptrace": ttRepTrace
  of "repdeepcopy": ttRepDeepCopy
  of "repenumtostr": ttRepEnumToStr
  of "repmethod": ttRepMethod
  of "reppureenum": ttRepPureEnum
  of "repcppmember": ttRepCppMember
  of "export": ttExport
  of "include": ttInclude
  of "import": ttImport
  of "reexpmod": ttReexpMod
  of "offer": ttOffer
  of "toffer": ttTOffer
  of "modulesrc": ttModuleSrc
  of "expansion": ttExpansion
  of "sig": ttSig
  of "implementation": ttImplementation
  else:
    if name == letSectionTag: ttLetSection
    elif name == varSectionTag: ttVarSection
    elif name == pragmaTag: ttPragma
    else: ttOther

var topTagPool: TagPool = nil
var topTagCache: seq[int8] = @[]
  ## `TagId -> TopTag`, -1 unresolved, for ONE tag pool. `topTagPool` holds the
  ## pool by REFERENCE so it stays alive and a freed pool cannot be replaced at
  ## the same address — the same argument `indexFromBif`'s and `bnode`'s memos
  ## rest on.

proc topTagAt(cur: Cursor): TopTag =
  let pool {.cursor.} = cur.tags
  if pool != topTagPool:
    topTagPool = pool
    topTagCache = @[]
  let id = int(uint32(cursorTagId(cur)))
  if id >= topTagCache.len:
    let oldLen = topTagCache.len
    topTagCache.setLen(id + 1)
    for i in oldLen ..< topTagCache.len: topTagCache[i] = -1'i8
  if topTagCache[id] < 0:
    topTagCache[id] = int8(ord(classifyTopTag(pool.tagName(cursorTagId(cur)))))
  result = TopTag(topTagCache[id])

proc processTopLevel(c: var DecodeContext; cur: var Cursor; flags: set[LoadFlag];
                     interf: var TStrTable; suffix: string; module: int): PrecompiledModule =
  ## Step 2 phase 2: walk the module body directly over the resident `buf` cursor
  ## (was a `next(s)` stream walk). `cur` enters at the `(stmts` type dot. Lazy
  ## loads done here (resolveSym/loadType/…) read INDEPENDENT cursors into the
  ## resident buffers, never `cur` — so the old export/toffer `jumpTo(saved)`
  ## save/restore dance is gone.
  result = PrecompiledModule(topLevel: newNode(nkStmtList))
  var localSyms = initTable[string, PSym]()

  skip cur  # the (stmts type dot
  # Top-level `let`/`var` sections are loaded even without LoadFullAst: they may
  # declare `{.compileTime.}` globals whose VM slots the importer initializes
  # eagerly (pipelines.initLoadedCompileTimeGlobals), which needs them visible in
  # `topLevel`. They sit in the module header before `(implementation)`.
  var cont = true
  while cont and cur.hasMore:
    prof pTopNodes
    if cur.kind != TagLit:
      cont = false
    else:
      case topTagAt(cur)
      of ttReplay:
        # Always load replay actions (macro cache operations)
        icProfStart(tTopReplay)
        cur.into:
          while cur.hasMore:
            let replayNode = loadNode(c, cur, suffix, localSyms)
            if replayNode != nil:
              result.topLevel.sons.add replayNode
        icProfStop(tTopReplay)
      of ttUnusedId:
        # backend id seed — consumed eagerly by `moduleId`/`readUnusedId`; just
        # skip past it here so the rest of the header still loads.
        skip cur
      of ttModFlags:
        cur.into:
          if cur.hasMore and cur.kind == IntLit:
            result.moduleFlags = int32 intVal(cur)
            skip cur
          while cur.hasMore: skip cur
      of ttRepConverter:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, ConverterEntry, attachedTrace, module)
      of ttRepDestroy:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, HookEntry, attachedDestructor, module)
      of ttRepWasMoved:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, HookEntry, attachedWasMoved, module)
      of ttRepCopy:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, HookEntry, attachedAsgn, module)
      of ttRepSink:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, HookEntry, attachedSink, module)
      of ttRepDup:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, HookEntry, attachedDup, module)
      of ttRepTrace:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, HookEntry, attachedTrace, module)
      of ttRepDeepCopy:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, HookEntry, attachedDeepCopy, module)
      of ttRepEnumToStr:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, EnumToStrEntry, attachedTrace, module)
      of ttRepMethod:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, MethodEntry, attachedTrace, module)
      of ttRepPureEnum:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, PureEnumEntry, attachedTrace, module)
      of ttRepCppMember:
        timed tTopLogOps:
          loadLogOp(c, result.logOps, cur, CppMemberEntry, attachedTrace, module)
      of ttExport:
        if SkipInterfaceTables in flags:
          # Same reason the interface tables are skipped: `interf` is a scratch
          # table this caller throws away, so every `resolveSym` here (one per
          # exported symbol, plus `addReexportedEnumFields`) only warms the
          # name-keyed `c.syms` cache that `resolveSym` refills lazily on a miss.
          skip cur
          continue
        icProfStart(tExportBranch)
        cur.into:
          while cur.hasMore and cur.kind == DotToken: skip cur  # flags / type
          while cur.hasMore:
            if cur.kind == Symbol:
              prof pExportSyms
              let symAsStr = symName(cur)
              # Skip symbols re-exported by this dependency but owned by the module
              # being compiled fresh (they would collide with the fresh originals).
              if c.mainModuleSuffix.len == 0 or
                 parseSymName(symAsStr).module != c.mainModuleSuffix:
                icProfStart(tResolveSym)
                let sym = resolveSym(c, symAsStr, false)
                icProfStop(tResolveSym)
                if sym != nil:
                  strTableAdd(interf, sym)
                  icProfStart(tEnumFields)
                  addReexportedEnumFields(c, sym, symAsStr, interf)
                  icProfStop(tEnumFields)
              skip cur
            else:
              raiseAssert "expected Symbol or ParRi but got " & $cur.kind &
                " in export list of module " & suffix
        icProfStop(tExportBranch)
      of ttInclude: loadInclude(c, cur, result.includes)
      of ttImport:  loadImport(c, cur, result.deps)
      of ttReexpMod:
        # a re-exported MODULE: (reexpmod "name" "suffix"); the module sym is a
        # qualifier in this module's interface — materialized by modulegraphs.
        var mname, msuffix = ""
        cur.into:
          if cur.hasMore and cur.kind == StrLit: (mname = strVal(cur); skip cur)
          if cur.hasMore and cur.kind == StrLit: (msuffix = strVal(cur); skip cur)
        if mname.len > 0 and msuffix.len > 0:
          result.reexportedModules.add (mname, msuffix)
      of ttOffer:
        # The offers exist to rebuild the FRONTEND's instantiation caches
        # (`procInstCache`/`typeInstCache`, see modulegraphs) so a later `nim m`
        # reuses an instance instead of re-instantiating it in its own scope.
        # No backend stage instantiates anything — nothing under `nifc` reads
        # either cache — yet resolving them was the single largest item in a
        # `cg` process's heap: 73MB of 152MB in the compiler's main-module `cg`,
        # 17MB of 40MB in the average one (`-d:icBNodeProf`, `TopOffersdKB`).
        # A `(toffer)` in particular FULLY loads its instance type, so this is
        # where most of a program's generic type instances got materialised in
        # every backend process. The lowered `.t.bif` then carries no offers
        # either (`writeLoweredModule` writes what was loaded), which is fine:
        # its only readers are backend stages.
        if c.infos.config.cmd == cmdNifC:
          skip cur
          continue
        # (offer <genericSym> <instSym> <genericParamsCount> <type>...) — resolve
        # to PSyms/PTypes; modulegraphs registers them into `procInstCache`.
        # Best-effort: a type that fails to resolve drops the whole offer.
        var genSym, instSym: PSym = nil
        var paramsCount = 0
        var cts: seq[PType] = @[]
        var idx = 0
        var ok = true
        icProfStart(tTopOffers)
        cur.into:
          while cur.hasMore:
            if cur.kind == Symbol:
              if idx == 0: genSym = resolveHookSym(c, symName(cur))
              elif idx == 1: instSym = resolveHookSym(c, symName(cur))
              else:
                let ct = tryCreateTypeStub(c, symName(cur))
                if ct == nil: ok = false
                else: cts.add ct
              inc idx
              skip cur
            elif cur.kind == IntLit:
              paramsCount = int(intVal(cur))
              skip cur
            else: skip cur
        if ok and genSym != nil and instSym != nil:
          result.genericOffers.add (genSym, instSym, cts, paramsCount)
        icProfStop(tTopOffers)
      of ttTOffer:
        if c.infos.config.cmd == cmdNifC:
          skip cur              # see `ttOffer`
          continue
        # (toffer "<genericBodySym>" "<instType>") — intern the two full names,
        # resolve, FULLY load the instance (so `searchInstTypes` can match its
        # params). Best-effort: a failure to resolve drops the offer.
        var genName, instName = ""
        var idx = 0
        icProfStart(tTopOffers)
        cur.into:
          while cur.hasMore:
            if cur.kind == StrLit:
              if idx == 0: genName = strVal(cur)
              elif idx == 1: instName = strVal(cur)
              inc idx
              skip cur
            else: skip cur
        if genName.len > 0 and instName.len > 0:
          let genSym = resolveHookSym(c, genName)
          let inst = tryCreateTypeStub(c, instName)
          if genSym != nil and inst != nil:
            loadType(c, inst)
            result.typeOffers.add (genSym, inst)
        icProfStop(tTopOffers)
      of ttModuleSrc:
        prof pTopToolingSkip
        # self-identification record for the standalone include-graph scanner;
        # not needed by the loader, just skip past it.
        skip cur
      of ttExpansion:
        prof pTopToolingSkip
        # template/macro expansion usage record for tooling (`idetools` scans it
        # as a `Symbol` use); the loader itself needs nothing from it.
        skip cur
      of ttSig:
        prof pTopToolingSkip
        # signature-symbol occurrence record for tooling (`idetools` scans it as a
        # `Symbol` use); the loader itself needs nothing from it.
        skip cur
      of ttImplementation:
        cont = false
      of ttLetSection, ttVarSection, ttPragma:
        # Parse the full statement. let/var sections are loaded unconditionally
        # (see above) so `{.compileTime.}` globals reach the eager initializer.
        # Top-level pragmas are loaded too: a module-level `{.emit.}` (and the
        # `{.push/pop.}` around it) must reach the `cg` stage's genPragma/genEmit,
        # else e.g. a `#include` is dropped and the generated C won't compile.
        # writeToplevelNode routes these into this header section.
        icProfStart(tTopStmts)
        let stmtNode = loadNode(c, cur, suffix, localSyms)
        if stmtNode != nil:
          result.topLevel.sons.add stmtNode
        icProfStop(tTopStmts)
      of ttOther:
        if LoadFullAst in flags:
          let stmtNode = loadNode(c, cur, suffix, localSyms)
          if stmtNode != nil:
            result.topLevel.sons.add stmtNode
        else:
          cont = false

proc registerModuleSelfSym*(c: var DecodeContext; suffix: string; m: PSym) =
  ## Bind the module's NIF name to the ONE module symbol the graph registered.
  ##
  ## A module's own symbol is the owner of every top-level symbol, so the writer
  ## emits it as a real `(sd)` with an index entry (`mymod.0.<suffix>`). Without
  ## this binding the loader mints a SECOND `skModule` PSym for it the first time
  ## some symbol's owner slot is resolved — and `sym.owner == owner` is an
  ## IDENTITY test in `aliasanalysis.isAnalysableFieldAccess`, so every
  ## module-level location looked un-analysable to the move optimizer: a
  ## top-level `let (a, b) = f()` copied instead of moved, which is a hard error
  ## for a type with a disabled `=copy`.
  ##
  ## Only the backend (`nim nifc`) does this — see the call site.
  let key = m.name.s & ".0." & suffix
  if not c.syms.hasKey(key):
    c.syms[key] = (m, NifIndexEntry())

proc loadNifModule*(c: var DecodeContext; suffix: ModuleSuffix; interf, interfHidden: var TStrTable;
                    flags: set[LoadFlag] = {}): PrecompiledModule =
  # Ensure module index is loaded - moduleId returns the FileIndex for this suffix
  icProfStart(tModuleId)
  let module = moduleId(c, string(suffix), flags)
  icProfStop(tModuleId)

  # Load the module AST (or just replay actions if loadFullAst is false).
  # processTopLevel also collects export instructions. Step 2 phase 2: read the
  # body straight from the resident `buf` cursor (no stream, no rewind — lazy
  # loads use independent cursors so they never disturb this one).
  var cur = beginRead(c.mods[module].buf)
  if cur.kind == TagLit and tagIs(cur, toNifTag(nkStmtList)):
    inc cur        # enter (stmts (past the tag head, onto the flags dot)
    skip cur       # flags dot  (processTopLevel skips the type dot itself)
    icProfStart(tTopLevel)
    result = processTopLevel(c, cur, flags, interf, string(suffix), module.int)
    icProfStop(tTopLevel)
  else:
    result = PrecompiledModule(topLevel: newNode(nkStmtList))

  # Populate interface tables from the NIF index structure
  # Symbols are created as stubs (Partial state) and will be loaded lazily via loadSym
  # Use exports collected by processTopLevel
  if SkipInterfaceTables notin flags:
    icProfStart(tInterfTables)
    populateInterfaceTablesFromIndex(c, module, interf, interfHidden, string(suffix))
    icProfStop(tInterfTables)

proc loadNifModule*(c: var DecodeContext; f: FileIndex; interf, interfHidden: var TStrTable;
                    flags: set[LoadFlag] = {}): PrecompiledModule =
  let suffix = ModuleSuffix(moduleSuffix(c.infos.config, f))
  result = loadNifModule(c, suffix, interf, interfHidden, flags)

proc writeLoweredModule*(c: var DecodeContext; config: ConfigRef;
                         precomp: PrecompiledModule;
                         hooks: openArray[LogEntry]; outfile: string) =
  ## Re-serialize a backend-loaded module as a FULL module NIF (`.t.nif`) whose
  ## routine `(sd)` entries carry their TRANSFORMED bodies (the `lower` stage set
  ## them, recursively lifting nested closures — including the async state-machine
  ## procs whose inner closure the per-`(lowered)`-entry path failed to cross) and
  ## whose lambda-lift-minted entities (closure-env types/syms, lifted nested
  ## procs) are real, indexed defs. The `cg` stage then loads it through the
  ## normal module loader (`moduleFromNifFile`), so a transformed body arrives via
  ## `loadSymFromCursor`'s Step-A 2-way-body slot WITH the lifted signature — no
  ## `(lowered)` side-car, no `:envP` re-weld. This realizes `ic_ideas.md`'s eager
  ## two-way body whole-module.
  let thisModule = precomp.module.positionImpl.int32
  # Routines → Sealed (cross-routine refs become SymUse, defs emitted once below);
  # types/globals/params/locals stay Complete and emit real defs (the `.t.nif` is
  # the sole source the cg stage reads — no `.s.nif` fallback for them).
  sealLoadedRoutines(c)
  var w = Writer(infos: newLineInfoWriter(config), currentModule: thisModule)
  w.deps = newIcBuilder(64)
  w.inProc = 1
  w.lowering = true
  var content = newIcBuilder(300)
  let rootInfo = trLineInfo(w, precomp.topLevel.info)
  createStmtList(content, rootInfo)

  # This module's ops (hooks/converters/methods/pure-enums) loaded from `.s.nif`,
  # plus the type-bound ops the lower transform just lifted (closure-env
  # `=destroy` etc., which have no `.s.nif` entry).
  for op in precomp.logOps:
    if op.module == thisModule.int:
      writeOp(w, content, op)
  for op in hooks:
    writeOp(w, content, op)

  var bottom = newIcBuilder(300)
  # Imperative init code + global let/var/const sections + replay actions — all
  # that a backend-loaded `topLevel` carries (routines are lazy index sdefs, not
  # here). Emits + seals the module's globals.
  w.writeToplevelNode content, bottom, precomp.topLevel

  # TYPE DEFS: emit into the `.t.bif` ONLY the owned types the lower stage actually
  # loaded (`Complete`) — those are the ones it can have MUTATED (proc type →
  # `ccClosure`, env type grown with captured fields), so the `.t.bif` must carry
  # the mutated version. Every untouched owned type stays `Partial` → a reference to
  # it below writes a `SymUse` that a cg/emit consumer resolves from the `.s.bif`
  # (loader fallback `typeCursor`/`ensureSemBuf`), so we no longer force-load +
  # re-serialize the whole type table here. Guard on `Complete`: a type reached as
  # an owned son of an earlier def is already `Sealed` (emitted inline) — skip it.
  for t in loadedModuleTypes(c, FileIndex thisModule):
    if t.state == Complete:
      writeType(w, bottom, t)

  # Routine DEFS (with transformed bodies) + CONST DEFS this module owns, sourced
  # from the index. Consts are lazy index sdefs too (like routines): the
  # backend-loaded `topLevel` carries only runtime init (module var/let sections),
  # NOT consts — especially `importc`/magic consts (`SIG_DFL`, `hasAllocStack`, …)
  # which have no runtime init at all. `writeNifModule` emitted them via the full
  # AST walk; here we must enumerate them from the index, else a cross-module
  # `SymUse` resolves to a nil `skModule` stub (`expr(skModule); unknown symbol`).
  for s in moduleSymbolStubs(c, FileIndex thisModule):
    if (s.kindImpl in routineKinds or s.kindImpl == skConst) and
        s.itemId.module == thisModule:
      writeSymDef(w, bottom, s)

  # Lifted hook ROUTINES (`@bk`, NEW in the lower stage — no `.s.nif` sdef, so
  # absent from `moduleSymbolStubs`): emit each as a full def (sig + transformed
  # body) so `injectDestructorCalls` in cg resolves the loaded env's `=destroy`.
  var emittedHooks = initHashSet[int32]()
  for op in hooks:
    if op.sym != nil and op.sym.kindImpl in routineKinds and
        not emittedHooks.containsOrIncl(op.sym.itemId.item):
      writeSymDef(w, bottom, op.sym)

  # deps / reexports / offers — mirror writeNifModule so the cg backend closure
  # walk, interface re-export and generic-instance reuse all work off `.t.nif`.
  for dep in precomp.deps:
    if not w.depSuffixes.containsOrIncl(dep.string):
      w.deps.addParLe importTag, NoLineInfo
      w.deps.addDotToken
      w.deps.addDotToken
      w.deps.addStrLit dep.string
      w.deps.addParRi
  for (mname, msuffix) in precomp.reexportedModules:
    w.deps.addParLe reexpModTag, NoLineInfo
    w.deps.addStrLit mname
    w.deps.addStrLit msuffix
    w.deps.addParRi
  for off in precomp.genericOffers:
    w.deps.addParLe offerTag, NoLineInfo
    w.deps.addSymUse pool.syms.getOrIncl(w.toNifSymName(off.generic)), NoLineInfo
    w.deps.addSymUse pool.syms.getOrIncl(w.toNifSymName(off.inst)), NoLineInfo
    w.deps.addIntLit off.genericParamsCount
    for ct in off.concreteTypes:
      # Canonical name, see `writeNifModule`'s copy of this loop.
      w.deps.addSymUse pool.syms.getOrIncl(nifTypeName(w, ct)), NoLineInfo
    w.deps.addParRi
  for off in precomp.typeOffers:
    w.deps.addParLe typeOfferTag, NoLineInfo
    w.deps.addStrLit w.toNifSymName(off.generic)
    w.deps.addStrLit nifTypeName(w, off.inst)   # canonical name, see above
    w.deps.addParRi
  # OWNER MUST EMIT offered types this module owns (see writeNifModule).
  for off in precomp.genericOffers:
    for ct in off.concreteTypes:
      if ct != nil and ct.itemId.module == w.currentModule and ct.state == Complete:
        writeType(w, bottom, ct)
  for off in precomp.typeOffers:
    if off.inst != nil and off.inst.itemId.module == w.currentModule and
        off.inst.state == Complete:
      writeType(w, bottom, off.inst)

  # Assemble exactly as writeNifModule: (stmts . . <deps> <ops+toplevel>
  # (implementation) <bottom> ).
  content.addParLe implTag, NoLineInfo
  content.addParRi()
  addAll(content, bottom)
  content.addParRi()

  var dest = newIcBuilder(600)
  createStmtList(dest, rootInfo)
  # Carry the seed FORWARD: the lower stage minted backend syms/types from the
  # per-module counters (seeded out of the `.s.bif`'s `(unusedid)`), so they now
  # hold the post-lower high-water mark. Record it so the `cg` stage — which
  # loads THIS `.t.bif` and mints still more (RTTI hooks) — seeds above it too.
  let lfi = FileIndex thisModule
  let loweredSeed = if c.mods.hasKey(lfi):
                      max(c.mods[lfi].symCounter, c.mods[lfi].typeCounter)
                    else: 0'i32
  dest.addParLe unusedIdTag, NoLineInfo
  dest.addIntLit loweredSeed.int64
  dest.addParRi()
  # Carry the module flags forward: `cg` loads THIS `.t.bif`, not the `.s.bif`.
  dest.addParLe modFlagsTag, NoLineInfo
  dest.addIntLit precomp.moduleFlags.int64
  dest.addParRi()
  addAll(dest, w.deps)
  addStmtsBody(dest, content)
  dest.addParRi()
  # Step 3: the lowered whole-module artifact is binary NIF (`.t.bif`) too — the
  # cg/emit stages load it via `toNifFilename`. No text twin (debug via bif2nif).
  storeBif(dest, outfile, "." & extractModuleSuffix(outfile))

when isMainModule:
  import std / syncio
  let obj = parseSymName("a.123.sys")
  echo obj.name, " ", obj.module, " ", obj.count
  let objb = parseSymName("abcdef.0121")
  echo objb.name, " ", objb.module, " ", objb.count
