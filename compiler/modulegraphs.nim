#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the module graph data structure. The module graph
## represents a complete Nim project. Single modules can either be kept in RAM
## or stored in a rod-file.

import std/[intsets, tables, hashes, strtabs, os, strutils, parseutils, sets]
import ../dist/checksums/src/checksums/md5
import ast, astalgo, options, lineinfos,idents, btrees, ropes, msgs, pathutils, packages, suggestsymdb

when not defined(nimKochBootstrap):
  import ast2nif
  import "../dist/nimony/src/lib" / [nifstreams, bitabs]

import typekeys

when defined(nimPreviewSlimSystem):
  import std/assertions

type
  SigHash* = distinct MD5Digest

  Iface* = object       ## data we don't want to store directly in the
                        ## ast.PSym type for s.kind == skModule
    module*: PSym       ## module this "Iface" belongs to
    converters*: seq[PSym]
    patterns*: seq[PSym]
    pureEnums*: seq[PSym]
    interf: TStrTable
    interfHidden: TStrTable
    uniqueName*: Rope

  Operators* = object
    opNot*, opContains*, opLe*, opLt*, opAnd*, opOr*, opIsNil*, opEq*: PSym
    opAdd*, opSub*, opMul*, opDiv*, opLen*: PSym

  PipelinePass* = enum
    NonePass
    SemPass
    JSgenPass
    CgenPass
    NifgenPass
    EvalPass
    InterpreterPass
    GenDependPass
    Docgen2TexPass
    Docgen2JsonPass
    Docgen2Pass

  ModuleGraph* {.acyclic.} = ref object
    ifaces*: seq[Iface]  ## indexed by int32 fileIdx

    typeInstCache*: Table[ItemId, seq[PType]] # A symbol's ItemId.
    procInstCache*: Table[ItemId, seq[PInstantiation]] # A symbol's ItemId.
    attachedOps*: array[TTypeAttachedOp, Table[ItemId, PSym]] # Type ID, destructors, etc.
    loadedOps: array[TTypeAttachedOp, Table[string, PSym]] # This can later by unified with `attachedOps` once it's stable
    opsLog*: seq[LogEntry]
    methodsPerGenericType*: Table[ItemId, seq[(int, PSym)]] # Type ID, attached methods
    memberProcsPerType*: Table[ItemId, seq[PSym]] # Type ID, attached member procs (only c++, virtual,member and ctor so far).
    initializersPerType*: Table[ItemId, PNode] # Type ID, AST call to the default ctor (c++ only)
    enumToStringProcs*: Table[ItemId, PSym]
    loadedEnumToStringProcs: Table[string, PSym]
    emittedTypeInfo*: Table[string, FileIndex]
    instDisambs: Table[(int, int32), ItemId] # (name id, content disamb) ->
                                  # instance, for collision probing in
                                  # `setInstanceDisamb`
    icCnifFiles*: seq[string]     # `.c.nif` artifacts written by this run
    pendingMethodReplays*: seq[PSym] # method registrations loaded under
                                  # `nim nifc`, bucketed only after every
                                  # module is loaded (`flushMethodReplays`)
    icImplDeps*: IntSet           # NeedsImpl edge tracking under `nim m`:
                                  # module ids (FileIndex) whose routine BODIES
                                  # this compilation consumed at compile time.
                                  # Written to the `.edges` sidecar; deps.nim
                                  # then gates the dependent on those modules'
                                  # IMPL cookie instead of the iface cookie, so
                                  # e.g. `const x = dep.foo()` re-sems when foo's
                                  # body changes. Uniform across body-access
                                  # kinds — the iface cookie hashes signatures
                                  # ONLY (see ast2nif.cookieSd), so every body
                                  # consumer records an edge here: VM-compiled /
                                  # getImpl'ed bodies (recordIcImplDep from vm/
                                  # vmgen), expanded templates (semTemplateExpr)
                                  # and instantiated generics (generateInstance).
                                  # Inline iterators / `inline` procs are NOT
                                  # tracked: they are inlined at codegen, where
                                  # the nifc backend's NIF-mtime invalidation
                                  # already re-codegens their users.
    icQualIfaces*: IntSet         # module positions whose interface tables were
                                  # populated ONLY for qualified access through a
                                  # module re-export (`import x; export x`); the
                                  # Iface.module stays nil so a later direct
                                  # import still takes the full load path
    inVMTransform*: int           # >0 while the VM compiles a routine body
                                  # (vmgen.genProc's transformBody): hooks lifted
                                  # there (e.g. for closure-env types of LOADED
                                  # routines) are process-local VM artifacts —
                                  # serializing them would embed references to
                                  # derived env-field syms that no module defines

    packageSyms*: TStrTable
    deps*: IntSet # the dependency graph or potentially its transitive closure.
    importDeps*: Table[FileIndex, seq[FileIndex]] # explicit import module dependencies
    suggestMode*: bool # whether we are in nimsuggest mode or not.
    invalidTransitiveClosure: bool
    interactive*: bool
    withinSystem*: bool # in system.nim or a module imported by system.nim
    inclToMod*: Table[FileIndex, FileIndex] # mapping of include file to the
                                            # first module that included it
    importStack*: seq[FileIndex]  # The current import stack. Used for detecting recursive
                                  # module dependencies.
    backend*: RootRef # minor hack so that a backend can extend this easily
    config*: ConfigRef
    cache*: IdentCache
    vm*: RootRef # unfortunately the 'vm' state is shared project-wise, this will
                 # be clarified in later compiler implementations.
    repl*: RootRef # REPL state is shared project-wise.
    doStopCompile*: proc(): bool {.closure.}
    usageSym*: PSym # for nimsuggest
    owners*: seq[PSym]
    suggestSymbols*: SuggestSymbolDatabase
    suggestErrors*: Table[FileIndex, seq[Suggest]]
    methods*: seq[tuple[methods: seq[PSym], dispatcher: PSym]] # needs serialization!
    bucketTable*: CountTable[ItemId]
    objectTree*: Table[ItemId, seq[tuple[depth: int, value: PType]]]
    displayTokens*: Table[ItemId, uint32]
    displayTokensByKey: Table[string, uint32]
    nextBaseDisplayTokenByDepth*: Table[int16, int]
    nextSiblingDisplayTokenByParent*: Table[string, int]
    methodsPerType*: Table[ItemId, seq[PSym]]
    dispatchers*: seq[PSym]

    systemModule*: PSym
    sysTypes*: array[TTypeKind, PType]
    compilerprocs*: TStrTable
    missingCompilerProcs*: HashSet[string]
                                  # `nim nifc` only: compilerproc names no
                                  # loaded module defines, so the whole-program
                                  # index scan in `loadCompilerProc` runs once
    exposed*: TStrTable
    packageTypes*: TStrTable
    emptyNode*: PNode
    canonTypes*: Table[SigHash, PType]
    symBodyHashes*: Table[int, SigHash] # symId to digest mapping
    importModuleCallback*: proc (graph: ModuleGraph; m: PSym, fileIdx: FileIndex): PSym {.nimcall.}
    includeFileCallback*: proc (graph: ModuleGraph; m: PSym, fileIdx: FileIndex): PNode {.nimcall.}
    cacheSeqs*: Table[string, PNode] # state that is shared to support the 'macrocache' API; IC: implemented
    cacheCounters*: Table[string, BiggestInt] # IC: implemented
    cacheTables*: Table[string, BTree[string, PNode]] # IC: implemented
    pendingNifInit*: seq[tuple[module: PSym; topLevel: PNode]]
      # EVERY module loaded from a NIF — whether a direct import (moduleFromNifFile)
      # or only a dep-of-a-dep (loadTransitiveHooks) — is recorded here with its
      # serialized top-level AST. The sem driver drains it once
      # (pipelines.finalizeLoadedModules) and applies the module's VM-level load
      # effects UNIFORMLY: macro-cache replay (std/macrocache put/inc/add/incl) and
      # eager `{.compileTime.}` global init. This is the single place "what a loaded
      # module does to global state" lives, so a transitively-reached module — which
      # never passes through compilePipelineModule — gets the SAME treatment as a
      # direct import instead of silently skipping it (its macrocache state would be
      # lost; its CT globals would stay nil and a macro splicing one, e.g.
      # chronicles' `chroniclesBlockName`, emits `break nil` / `nil == 0`). To add a
      # new per-load VM effect, extend the drain — never a parallel buffer.
    passes*: seq[TPass]
    pipelinePass*: PipelinePass
    onDefinition*: proc (graph: ModuleGraph; s: PSym; info: TLineInfo) {.nimcall.}
    onDefinitionResolveForward*: proc (graph: ModuleGraph; s: PSym; info: TLineInfo) {.nimcall.}
    onUsage*: proc (graph: ModuleGraph; s: PSym; info: TLineInfo) {.nimcall.}
    globalDestructors*: seq[PNode]
    icModuleDtors*: seq[string]   # per-module backend: the C names of the
                                  # other modules' global-destructor procs
                                  # (`genIcModuleDestroyGlobals`), already in
                                  # call order; only the main module's `cg`
                                  # fills this, from the `.c.nif` meta heads
    strongSemCheck*: proc (graph: ModuleGraph; owner: PSym; body: PNode) {.nimcall.}
    compatibleProps*: proc (graph: ModuleGraph; formal, actual: PType): bool {.nimcall.}
    idgen*: IdGenerator
    vmTransfIdgen*: IdGenerator   # process-local backend idgen for closure envs
                                  # minted while the VM compiles a routine body
                                  # (inVMTransform); see lambdalifting / ast2nif @bk
    operators*: Operators

    cachedFiles*: StringTableRef

    procGlobals*: seq[PNode]
    nifReplayActions*: Table[int32, seq[PNode]]  # module position -> replay actions for NIF
    nifExpansions*: Table[int32, seq[(PSym, TLineInfo)]]
      # module position -> (template/macro sym, call-site info) for every expansion
      # in that module. Templates/macros leave no trace in the sem'checked AST, so
      # this side-channel (written into the `.bif`, see ast2nif) is what lets
      # `nim track --usages`/`--def` find them. Populated by `rememberExpansion`.
    cachedMods: IntSet
    hookClosure: IntSet # modules whose serialized hooks were already registered

  TPassContext* = object of RootObj # the pass's context
    idgen*: IdGenerator
  PPassContext* = ref TPassContext

  TPassOpen* = proc (graph: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext {.nimcall.}
  TPassClose* = proc (graph: ModuleGraph; p: PPassContext, n: PNode): PNode {.nimcall.}
  TPassProcess* = proc (p: PPassContext, topLevelStmt: PNode): PNode {.nimcall.}

  TPass* = tuple[open: TPassOpen,
                 process: TPassProcess,
                 close: TPassClose,
                 isFrontend: bool]

const runtimeTypeSkipPtrs = {tyVar, tyPtr, tyRef, tyGenericInst, tyGenericBody,
  tyTypeDesc, tyAlias, tyInferred, tySink, tyLent, tyOwned}

proc normalizeRuntimeType(typ: PType): PType =
  result = skipTypesOrNil(typ, runtimeTypeSkipPtrs)
  if result == nil or result.kind != tyObject:
    result = nil
    return

  var root = result
  while root.sonsImpl.len > 0 and root.sonsImpl[0] != nil:
    root = skipTypesOrNil(root.sonsImpl[0], runtimeTypeSkipPtrs)
    if root == nil:
      return nil

  let hasBase = result.sonsImpl.len > 0 and result.sonsImpl[0] != nil
  if ((tfFinal in result.flags) and not hasBase) or
      (root.sym != nil and sfPure in root.sym.flags):
    result = nil

proc runtimeTypeDepth(typ: PType): int16 =
  var typ = normalizeRuntimeType(typ)
  result = 0
  while typ != nil and typ.sonsImpl.len > 0 and typ.sonsImpl[0] != nil:
    inc result
    typ = normalizeRuntimeType(typ.sonsImpl[0])

proc runtimeTypeKey(g: ModuleGraph; typ: PType): string =
  let typ = normalizeRuntimeType(typ)
  if typ == nil:
    result = ""
  else:
    result = typeKey(typ, g.config, loadTypeCallback, loadSymCallback)

proc runtimeTypeParentKey(g: ModuleGraph; typ: PType): string =
  let typ = normalizeRuntimeType(typ)
  if typ == nil or typ.sonsImpl.len == 0 or typ.sonsImpl[0] == nil:
    result = ""
  else:
    result = g.runtimeTypeKey(typ.sonsImpl[0])

proc runtimeTypeRoot(typ: PType): PType =
  result = normalizeRuntimeType(typ)
  while result != nil and result.sonsImpl.len > 0 and result.sonsImpl[0] != nil:
    let parent = normalizeRuntimeType(result.sonsImpl[0])
    if parent == nil:
      break
    result = parent

proc packDisplayToken(baseToken, siblingToken: int): uint32 =
  result = uint32(baseToken) or (uint32(siblingToken) shl 16)

proc siblingDisplayToken*(token: uint32): uint16 {.inline.} =
  result = uint16(token shr 16)

proc baseDisplayToken*(token: uint32): uint16 {.inline.} =
  result = uint16(token and 0xFFFF'u32)

const displayTokenOverflowMsg =
  "too many descendants of base $1, max is $2, use {.inheritable.} pragma to define decoupled inheritance bases."

proc raiseDisplayTokenOverflow(g: ModuleGraph; typ: PType) =
  let root = runtimeTypeRoot(typ)
  let baseName = if root != nil and root.sym != nil: root.sym.name.s else: "<anonymous>"
  globalError(g.config, unknownLineInfo,
    displayTokenOverflowMsg % [baseName, $high(uint16)])

proc nextDisplayToken[K](g: ModuleGraph; counter: var Table[K, int];
                         key: K; typ: PType): int =
  result = counter.getOrDefault(key, 1)
  if result > int(high(uint16)):
    g.raiseDisplayTokenOverflow(typ)
  counter[key] = result + 1

proc assignDisplayToken(g: ModuleGraph; typ: PType) =
  let typ = normalizeRuntimeType(typ)
  if typ == nil or typ.itemId in g.displayTokens:
    return
  let key = g.runtimeTypeKey(typ)
  if key in g.displayTokensByKey:
    g.displayTokens[typ.itemId] = g.displayTokensByKey[key]
    return
  let
    depth = runtimeTypeDepth(typ)
    parent = g.runtimeTypeParentKey(typ)
    baseToken = g.nextDisplayToken(g.nextBaseDisplayTokenByDepth, depth, typ)
    siblingToken = g.nextDisplayToken(g.nextSiblingDisplayTokenByParent, parent, typ)
    token = packDisplayToken(baseToken, siblingToken)
  g.displayTokens[typ.itemId] = token
  g.displayTokensByKey[key] = token

proc addRuntimeObjectType*(g: ModuleGraph; typ: PType) =
  let typ = normalizeRuntimeType(typ)
  g.assignDisplayToken(typ)

proc displayToken*(g: ModuleGraph; typ: PType): uint32 =
  let typ = normalizeRuntimeType(typ)
  if typ == nil:
    return 0
  if typ.itemId notin g.displayTokens:
    g.addRuntimeObjectType(typ)
  result = g.displayTokens[typ.itemId]

proc resetForBackend*(g: ModuleGraph) =
  g.compilerprocs = initStrTable()
  g.typeInstCache.clear()
  g.procInstCache.clear()
  for a in mitems(g.attachedOps):
    a.clear()
  g.methodsPerGenericType.clear()
  g.enumToStringProcs.clear()
  g.loadedEnumToStringProcs.clear()
  g.dispatchers.setLen(0)
  g.methodsPerType.clear()
  for a in mitems(g.loadedOps):
    a.clear()
  g.opsLog.setLen(0)
  # Keep sempass-seeded RTTI tokens so `nifc` does not gratuitously retag
  # inheritance families within the current graph

const
  cb64 = [
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
    "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n",
    "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9a",
    "9b", "9c"]

proc toBase64a(s: cstring, len: int): string =
  ## encodes `s` into base64 representation.
  result = newStringOfCap(((len + 2) div 3) * 4)
  result.add "__"
  var i = 0
  while i < len - 2:
    let a = ord(s[i])
    let b = ord(s[i+1])
    let c = ord(s[i+2])
    result.add cb64[a shr 2]
    result.add cb64[((a and 3) shl 4) or ((b and 0xF0) shr 4)]
    result.add cb64[((b and 0x0F) shl 2) or ((c and 0xC0) shr 6)]
    result.add cb64[c and 0x3F]
    inc(i, 3)
  if i < len-1:
    let a = ord(s[i])
    let b = ord(s[i+1])
    result.add cb64[a shr 2]
    result.add cb64[((a and 3) shl 4) or ((b and 0xF0) shr 4)]
    result.add cb64[((b and 0x0F) shl 2)]
  elif i < len:
    let a = ord(s[i])
    result.add cb64[a shr 2]
    result.add cb64[(a and 3) shl 4]

template interfSelect(iface: Iface, importHidden: bool): TStrTable =
  var ret = iface.interf.addr # without intermediate ptr, it creates a copy and compiler becomes 15x slower!
  if importHidden: ret = iface.interfHidden.addr
  ret[]

template semtab(g: ModuleGraph, m: PSym): TStrTable =
  g.ifaces[m.position].interf

template semtabAll*(g: ModuleGraph, m: PSym): TStrTable =
  g.ifaces[m.position].interfHidden

proc initStrTables*(g: ModuleGraph, m: PSym) =
  semtab(g, m) = initStrTable()
  semtabAll(g, m) = initStrTable()

proc strTableAdds*(g: ModuleGraph, m: PSym, s: PSym) =
  strTableAdd(semtab(g, m), s)
  strTableAdd(semtabAll(g, m), s)

proc isCachedModule(g: ModuleGraph; module: int): bool {.inline.} =
  result = module in g.cachedMods

proc isCachedModule*(g: ModuleGraph; m: PSym): bool {.inline.} =
  isCachedModule(g, m.position)

type
  ModuleIter* = object
    modIndex: int
    ti: TIdentIter
    importHidden: bool

proc initModuleIter*(mi: var ModuleIter; g: ModuleGraph; m: PSym; name: PIdent): PSym =
  assert m.kind == skModule
  mi.modIndex = m.position
  mi.importHidden = optImportHidden in m.options
  result = initIdentIter(mi.ti, g.ifaces[mi.modIndex].interfSelect(mi.importHidden), name)

proc nextModuleIter*(mi: var ModuleIter; g: ModuleGraph): PSym =
  result = nextIdentIter(mi.ti, g.ifaces[mi.modIndex].interfSelect(mi.importHidden))

iterator allSyms*(g: ModuleGraph; m: PSym): PSym =
  let importHidden = optImportHidden in m.options
  for s in g.ifaces[m.position].interfSelect(importHidden).data:
    if s != nil:
      yield s

proc reexportedModuleSyms*(g: ModuleGraph; m: PSym): seq[(string, string)] =
  ## (name, NIF module suffix) of MODULE syms in `m`'s interface — these are
  ## re-exports (`import x; export x`, added by `reexportSym`) acting as
  ## qualifiers (`m.x.sym`). Consumed by the NIF writer; semExport does not
  ## put them into the nkExportStmt children, so the AST walk cannot see them.
  result = @[]
  var seen = initIntSet()
  for s in g.ifaces[m.position].interf.data:
    if s != nil and s.kind == skModule and s.position != m.position and
        not seen.containsOrIncl(s.position):
      result.add (s.name.s, cachedModuleSuffix(g.config, FileIndex s.position))

proc someSym*(g: ModuleGraph; m: PSym; name: PIdent): PSym =
  let importHidden = optImportHidden in m.options
  result = strTableGet(g.ifaces[m.position].interfSelect(importHidden), name)

proc someSymAmb*(g: ModuleGraph; m: PSym; name: PIdent; amb: var bool): PSym =
  let importHidden = optImportHidden in m.options
  var ti: TIdentIter = default(TIdentIter)
  result = initIdentIter(ti, g.ifaces[m.position].interfSelect(importHidden), name)
  if result != nil and nextIdentIter(ti, g.ifaces[m.position].interfSelect(importHidden)) != nil:
    # another symbol exists with same name
    amb = true

proc systemModuleSym*(g: ModuleGraph; name: PIdent): PSym =
  result = someSym(g, g.systemModule, name)

iterator systemModuleSyms*(g: ModuleGraph; name: PIdent): PSym =
  var mi: ModuleIter = default(ModuleIter)
  var r = initModuleIter(mi, g, g.systemModule, name)
  while r != nil:
    yield r
    r = nextModuleIter(mi, g)

iterator typeInstCacheItems*(g: ModuleGraph; s: PSym): PType =
  if g.typeInstCache.contains(s.itemId):
    let x = addr(g.typeInstCache[s.itemId])
    for t in mitems(x[]):
      yield t

iterator procInstCacheItems*(g: ModuleGraph; s: PSym): PInstantiation =
  if g.procInstCache.contains(s.itemId):
    let x = addr(g.procInstCache[s.itemId])
    for t in mitems(x[]):
      yield t


proc getAttachedOp*(g: ModuleGraph; t: PType; op: TTypeAttachedOp): PSym =
  ## returns the requested attached operation for type `t`. Can return nil
  ## if no such operation exists.
  if g.attachedOps[op].contains(t.bindingId):
    result = g.attachedOps[op][t.bindingId]
  elif g.config.cmd in {cmdNifC, cmdM}:
    # Fall back to key-based lookup for NIF-loaded hooks
    let key = typeKey(t, g.config, loadTypeCallback, loadSymCallback)
    result = g.loadedOps[op].getOrDefault(key)
    #echo "fallback ", key, " ", op, " ", result
    when defined(icDbgHash):
      if result == nil and op == attachedDestructor:
        echo "HOOK MISS key=", key, " table.len=", g.loadedOps[op].len,
          " kind=", t.kind, " sym=", (if t.sym != nil: t.sym.name.s else: "NIL")
        if key.len > 10:
          let probe = key[3 ..< min(key.len, 18)]
          for k in g.loadedOps[op].keys:
            if probe in k: echo "  candidate: ", k
  else:
    result = nil

proc setAttachedOp*(g: ModuleGraph; module: int; t: PType; op: TTypeAttachedOp; value: PSym) =
  ## we also need to record this to the packed module.
  # Key-based deduplication for opsLog: different type objects (e.g. canon vs
  # orig) can have different itemIds but the same structural key.
  let key = typeKey(t, g.config, loadTypeCallback, loadSymCallback)
  if g.inVMTransform > 0 and g.config.cmd == cmdM:
    # hook lifted while the VM compiles a routine body (closure-env types of
    # loaded routines): register it for in-process lookup but keep it out of
    # the serialized log — it is a process-local artifact whose type graph
    # references derived env-field syms that no module's NIF defines
    if g.loadedOps[op].getOrDefault(key) == nil:
      g.loadedOps[op][key] = value
    g.attachedOps[op][t.bindingId] = value
    return
  let existing = g.loadedOps[op].getOrDefault(key)
  if existing == nil:
    # Stamp the entry with the module whose compilation produced the hook
    # (`module`), NOT the type's def module: each `nim m` is a separate
    # process, so a hook lifted while compiling a *downstream* module simply
    # does not exist in the def module's process — stamping it with the def
    # module produced a `LogEntry` that no module ever writes (the def
    # module's writer ran in another process that never lifted it; this
    # module's writer skips it because `op.module != thisModule`) and codegen
    # failed with "'=destroy' operator not found" (e.g. astdef's `TStrTable`,
    # whose destroy is first needed by modulegraphs). This holds for nominal
    # types as much as for generic/structural instances. Duplicate
    # registrations across lifting modules are reconciled deterministically
    # at load time (see the HookEntry replay in `replayStateChanges`).
    g.opsLog.add LogEntry(kind: HookEntry, op: op, module: module, key: key, sym: value)
    g.loadedOps[op][key] = value
  elif existing != value:
    # Re-registration replacing an earlier sym for the same key. This happens
    # legitimately: `createTypeBoundOps` first registers empty `symPrototype`
    # placeholders, then `produceSym` replaces them — in particular
    # `produceSymDistinctType` replaces a distinct type's placeholder with the
    # BASE type's hook (a `distinct string` uses string's `=sink`). The log
    # must follow the replacement, otherwise the NIF ships the dead,
    # empty-bodied prototype and codegen in another process calls a no-op
    # `=sink`/`=copy`, silently losing the value (e.g. `conf.projectPath`
    # ended up empty: "cannot open '/'").
    g.loadedOps[op][key] = value
    var updated = false
    for e in mitems(g.opsLog):
      if e.kind == HookEntry and e.op == op and e.key == key:
        e.sym = value
        e.module = module
        updated = true
        break
    if not updated:
      g.opsLog.add LogEntry(kind: HookEntry, op: op, module: module, key: key, sym: value)
  g.attachedOps[op][t.bindingId] = value

proc setAttachedOp*(g: ModuleGraph; module: int; typeId: ItemId; op: TTypeAttachedOp; value: PSym) =
  ## Overload that takes ItemId directly, useful for registering hooks from NIF index.
  g.attachedOps[op][typeId] = value

proc setAttachedOpPartial*(g: ModuleGraph; module: int; t: PType; op: TTypeAttachedOp; value: PSym) =
  ## we also need to record this to the packed module.
  g.attachedOps[op][t.bindingId] = value

proc completePartialOp*(g: ModuleGraph; module: int; t: PType; op: TTypeAttachedOp; value: PSym) {.inline.} =
  discard

iterator getDispatchers*(g: ModuleGraph): PSym =
  for i in g.dispatchers.mitems:
    yield i

proc addDispatchers*(g: ModuleGraph, value: PSym) =
  # TODO: add it for packed modules
  g.dispatchers.add value

proc setMethodsPerType*(g: ModuleGraph; id: ItemId, methods: seq[PSym]) =
  # TODO: add it for packed modules
  g.methodsPerType[id] = methods

proc addNifReplayAction*(g: ModuleGraph; module: int32; n: PNode) =
  ## Stores a replay action for NIF-based incremental compilation.
  g.nifReplayActions.mgetOrPut(module, @[]).add n

iterator getMethodsPerType*(g: ModuleGraph; t: PType): PSym =
  if g.methodsPerType.contains(t.bindingId):
    for it in mitems g.methodsPerType[t.bindingId]:
      yield it

proc getToStringProc*(g: ModuleGraph; t: PType): PSym =
  result = g.enumToStringProcs.getOrDefault(t.bindingId)
  if result == nil and g.config.cmd in {cmdNifC, cmdM}:
    let key = typeKey(t, g.config, loadTypeCallback, loadSymCallback)
    result = g.loadedEnumToStringProcs.getOrDefault(key)
  assert result != nil

proc setToStringProc*(g: ModuleGraph; t: PType; value: PSym) =
  g.enumToStringProcs[t.bindingId] = value
  let key = typeKey(t, g.config, loadTypeCallback, loadSymCallback)
  # Stamp with the module that owns the generated proc, not the enum's def
  # module: the def module's process may never have generated it (same
  # "written by nobody" failure as hook entries, see setAttachedOp).
  g.opsLog.add LogEntry(kind: EnumToStrEntry, module: value.itemId.module.int, key: key, sym: value)

iterator methodsForGeneric*(g: ModuleGraph; t: PType): (int, PSym) =
  if g.methodsPerGenericType.contains(t.bindingId):
    for it in mitems g.methodsPerGenericType[t.bindingId]:
      yield (it[0], it[1])

proc addMethodToGeneric*(g: ModuleGraph; module: int; t: PType; col: int; m: PSym) =
  g.methodsPerGenericType.mgetOrPut(t.bindingId, @[]).add (col, m)
  let key = typeKey(t, g.config, loadTypeCallback, loadSymCallback)
  let ownerModule = if t.sym != nil: t.sym.itemId.module.int else: module
  g.opsLog.add LogEntry(kind: MethodEntry, module: ownerModule, key: key, sym: m)

proc logMethodDef*(g: ModuleGraph; s: PSym) =
  ## Log a method registration (`cgmeth.methodDef`) so that importers and
  ## the backend can rebuild the dispatch buckets (`g.methods`) from the
  ## NIF replay log — the serialized method ast carries its dispatcher sym
  ## at `dispatcherPos`, so replay reuses the original dispatcher that all
  ## call sites reference by name (see `registerLoadedMethod`).
  if g.config.cmd in {cmdNifC, cmdM}:
    g.opsLog.add LogEntry(kind: MethodEntry, module: s.itemId.module.int,
                          key: "", sym: s)

proc logCppMember*(g: ModuleGraph; s: PSym) =
  ## Log a C++ `{.member.}`/`{.virtual.}`/`{.constructor.}` registration (and the
  ## `importcpp` default-initializer flavour) so the NIF backend can rebuild
  ## `memberProcsPerType`/`initializersPerType`, which live only in the sem
  ## process. Without them the per-module backend emitted the struct WITHOUT its
  ## in-class member declarations and the out-of-class definitions did not match
  ## ("no declaration matches 'void Doo::memberProc()'").
  ##
  ## No type key: `replayCppMember` re-derives the type from the routine's
  ## signature exactly as `semCppMember` does, so nothing has to survive the
  ## round trip except the routine itself.
  if g.config.cmd in {cmdNifC, cmdM}:
    g.opsLog.add LogEntry(kind: CppMemberEntry, module: s.itemId.module.int,
                          key: "", sym: s)

proc replayCppMember*(g: ModuleGraph; s: PSym) =
  ## Inverse of `logCppMember`, mirroring `semstmts.semCppMember`'s derivation.
  if s == nil or s.typ == nil: return
  if sfImportc notin s.flags:
    var typ = if sfConstructor in s.flags: s.typ.returnType else: s.typ.firstParamType
    if typ != nil and typ.kind == tyPtr and sfConstructor notin s.flags:
      typ = typ.elementType
    if typ != nil and typ.kind == tyObject:
      let procs = addr g.memberProcsPerType.mgetOrPut(typ.bindingId, @[])
      for prc in procs[]:
        if prc == s: return
      procs[].add s
  else:
    let typ = s.typ.returnType
    if typ != nil and typ.kind == tyObject and
        typ.bindingId notin g.initializersPerType and s.typ.n != nil:
      # The default values sem read off the `nkIdentDefs` live on the param syms.
      var call = newTree(nkCall, newSymNode(s))
      var isInitializer = s.typ.n.len > 1
      for i in 1 ..< s.typ.n.len:
        let p = s.typ.n[i]
        if p.kind != nkSym or p.sym.ast == nil or p.sym.ast.kind == nkEmpty:
          isInitializer = false
          break
        call.add p.sym.ast
      if isInitializer:
        g.initializersPerType[typ.bindingId] = call

proc registerLoadedMethod*(g: ModuleGraph; m: PSym) =
  ## Rebuild the dispatch buckets from a serialized method registration.
  ## Buckets group the methods sharing a dispatcher; the dispatcher's BODY
  ## does not exist in serialized form — `generateIfMethodDispatchers`
  ## synthesizes it in the backend from the complete bucket.
  template dbg(msg: string) =
    when defined(icDbgMeth):
      echo "[icMeth] replay ", (if m != nil: m.name.s else: "nil"), ": ", msg
  if m == nil or sfDispatcher in m.flags: dbg "skip self/nil"; return
  if m.ast == nil or dispatcherPos >= m.ast.len:
    dbg "no dispatcherPos (len " & $(if m.ast != nil: m.ast.len else: -1) & ")"
    return
  let dn = m.ast[dispatcherPos]
  if dn == nil or dn.kind != nkSym or dn.sym == nil: dbg "empty dispatcher slot"; return
  let disp = dn.sym
  if sfDispatcher notin disp.flags: dbg "slot sym not a dispatcher"; return
  dbg "ok -> bucket of " & disp.name.s & "." & $disp.disamb
  for i in 0..<g.methods.len:
    if g.methods[i].dispatcher.itemId == disp.itemId:
      for existing in g.methods[i].methods:
        if existing.itemId == m.itemId: return
      g.methods[i].methods.add m
      return
  g.methods.add (methods: @[m], dispatcher: disp)

proc flushMethodReplays*(g: ModuleGraph) =
  ## Builds the dispatch buckets from the method registrations collected
  ## during module loading; called once every module of the program is
  ## loaded (`nifbackend.generateCode`).
  for s in g.pendingMethodReplays:
    registerLoadedMethod(g, s)
  g.pendingMethodReplays.setLen 0

proc logGenericInstance*(g: ModuleGraph; inst: PSym) =
  ## Log a generic instance so it gets written to the NIF file.
  ## This is needed when generic instances are created during compile-time
  ## evaluation and may be referenced from other modules compiled in the same run.
  if g.config.cmd in {cmdNifC, cmdM}:
    let ownerModule = inst.itemId.module.int
    g.opsLog.add LogEntry(kind: GenericInstEntry, module: ownerModule, sym: inst)

const
  InstanceDisambBit* = 0x4000_0000'i32
    ## Set in the `disamb` of routine instances whose value is content-derived
    ## (see `setInstanceDisamb`); keeps them disjoint from the small counter
    ## range ordinary symbols draw from, so the NIF name `name.disamb.module`
    ## stays collision-free within a module.

proc setInstanceDisamb*(g: ModuleGraph; inst, generic: PSym;
                        concreteTypes: openArray[PType]) =
  ## Under IC, replace a fresh routine instance's counter-based `disamb` with
  ## a content-derived one: a hash of the generic's identity plus the
  ## `typeKey` of every concrete type argument — exactly the identity the
  ## instantiation cache compares. The instance's NIF name
  ## `name.disamb.modsuffix` then differs only in the module suffix when the
  ## same instantiation is made by different modules, which is the
  ## prerequisite for cross-module generic-instance merging (and gives the
  ## dce analysis its `offers` keys). The hash is computed once, here; it is
  ## never recomputed — the value travels in the serialized `disamb` field.
  if g.config.cmd notin {cmdNifC, cmdM}: return
  if isDefined(g.config, "icNoInstKey"): return
  var key = generic.name.s
  key.add '.'
  key.addInt generic.disamb
  key.add '.'
  key.add modname(generic.itemId.module, g.config)
  for t in concreteTypes:
    key.add '|'
    key.add typeKey(t, g.config, loadTypeCallback, loadSymCallback)
  let d = toMD5(key)
  var h = (int32(d[0]) or (int32(d[1]) shl 8) or (int32(d[2]) shl 16) or
           (int32(d[3] and 0x3F'u8) shl 24)) or InstanceDisambBit
  # Same-name hash collisions inside this process get probed to the next
  # free value; the loser stays correct (its name keeps the module suffix),
  # it merely won't merge cross-module.
  while true:
    let probe = (inst.name.id, h)
    if g.instDisambs.hasKey(probe):
      if g.instDisambs[probe] == inst.itemId: break
      h = if h == high(int32): InstanceDisambBit else: h + 1
    else:
      g.instDisambs[probe] = inst.itemId
      break
  inst.disamb = h

const
  HookDisambBit* = 0x2000_0000'i32
    ## Set in the `disamb` of synthesized type-bound operators and `$enum`
    ## procs whose value is content-derived (see `setHookDisamb`); disjoint
    ## from both the small counter range and the `InstanceDisambBit` range.

proc setHookDisamb*(g: ModuleGraph; hook: PSym; opName: string; typ: PType) =
  ## Under IC, replace a synthesized hook's counter-based `disamb` with a
  ## content-derived one: a hash of the operation name plus the `typeKey` of
  ## the type it is bound to. Counter disambs renumber whenever an *earlier*
  ## hook appears in a re-semmed module, so cached translation units keep
  ## calling the old `_u<disamb>` C name while the regenerated producer
  ## defines a new one — the hook flavor of the backend def-migration hole.
  ## With a content-derived value the hook's NIF name (and hence its C name)
  ## is stable as long as the type itself is unchanged.
  if g.config.cmd notin {cmdNifC, cmdM}: return
  if isDefined(g.config, "icNoHookKey"): return
  var key = opName
  key.add '|'
  key.add typeKey(typ, g.config, loadTypeCallback, loadSymCallback)
  let d = toMD5(key)
  var h = (int32(d[0]) or (int32(d[1]) shl 8) or (int32(d[2]) shl 16) or
           (int32(d[3] and 0x1F'u8) shl 24)) or HookDisambBit
  # Same-name hash collisions inside this process get probed to the next
  # free value (staying below InstanceDisambBit); the loser merely loses
  # cross-run name stability.
  while true:
    let probe = (hook.name.id, h)
    if g.instDisambs.hasKey(probe):
      if g.instDisambs[probe] == hook.itemId: break
      h = if h == InstanceDisambBit - 1'i32: HookDisambBit else: h + 1
    else:
      g.instDisambs[probe] = hook.itemId
      break
  hook.disamb = h

proc hasDisabledOp(g: ModuleGraph; t: PType; kind: TTypeAttachedOp): bool =
  let op = getAttachedOp(g, t, kind)
  result = op != nil and sfError in op.flags

proc hasDisabledAsgn*(g: ModuleGraph; t: PType): bool =
  result = hasDisabledOp(g, t, attachedAsgn)

proc hasDisabledDup*(g: ModuleGraph; t: PType): bool =
  result = hasDisabledOp(g, t, attachedDup)

proc copyTypeProps*(g: ModuleGraph; module: int; dest, src: PType) =
  for k in low(TTypeAttachedOp)..high(TTypeAttachedOp):
    let op = getAttachedOp(g, src, k)
    if op != nil:
      setAttachedOp(g, module, dest, k, op)

proc loadCompilerProc*(g: ModuleGraph; name: string): PSym =
  result = nil
  if g.config.symbolFiles == disabledSf and optWithinConfigSystem notin g.config.globalOptions:
    # For NIF-based compilation, search in loaded NIF modules
    when not defined(nimKochBootstrap):
      # Try to resolve from NIF for both cmdNifC and cmdM (which uses NIF files)
      if g.config.cmd in {cmdNifC, cmdM}:
        # First try system module (most compilerprocs are there).
        # Only consult the NIF if it actually exists: under nimsuggest's cold
        # cache (ideActive) system is compiled from source and has no NIF yet,
        # in which case the proc is already registered in-memory and the caller
        # found/falls back to it — so degrade to nil instead of asserting.
        let systemFileIdx = g.config.m.systemFileIdx
        if systemFileIdx != InvalidFileIdx and not g.withinSystem and
           fileExists(toNifFilename(g.config, systemFileIdx)):
          result = tryResolveCompilerProc(ast.program, name, systemFileIdx)
          if result != nil:
            strTableAdd(g.compilerprocs, result)
            return result

        # `nim nifc`: a module loaded from a NIF is named by its mangled suffix
        # (`thrkxstl4`), not by its source name, and its file index resolves to
        # that suffix too — so the `"threadpool"` match below can never fire and
        # `spawn`, expanded at codegen time, died on `system module needs:
        # nimArgsPassingDone`. The backend loads the WHOLE program before
        # codegen starts, so just consult every loaded module's index; a miss is
        # final for the rest of the process (nothing more gets loaded) and is
        # remembered, because `getCompilerProc` is also used as a mere presence
        # probe and would otherwise rescan every index on every call.
        if g.config.cmd == cmdNifC:
          if name in g.missingCompilerProcs: return nil
          for moduleIdx in 0..<g.ifaces.len:
            let module = g.ifaces[moduleIdx].module
            if module == nil or module.position.FileIndex == systemFileIdx: continue
            if not fileExists(toNifFilename(g.config, module.position.FileIndex)):
              continue
            result = tryResolveCompilerProc(ast.program, name, module.position.FileIndex)
            if result != nil:
              strTableAdd(g.compilerprocs, result)
              return result
          g.missingCompilerProcs.incl name
          return nil

        # Try threadpool module (some compilerprocs like FlowVar are there)
        # Find threadpool module by searching loaded modules
        for moduleIdx in 0..<g.ifaces.len:
          let module = g.ifaces[moduleIdx].module
          if module != nil and module.name.s == "threadpool":
            let threadpoolFileIdx = module.position.FileIndex
            if not fileExists(toNifFilename(g.config, threadpoolFileIdx)): break
            result = tryResolveCompilerProc(ast.program, name, threadpoolFileIdx)
            if result != nil:
              strTableAdd(g.compilerprocs, result)
              return result
    return nil

proc `$`*(u: SigHash): string =
  toBase64a(cast[cstring](unsafeAddr u), sizeof(u))

proc `==`*(a, b: SigHash): bool =
  result = equalMem(unsafeAddr a, unsafeAddr b, sizeof(a))

proc hash*(u: SigHash): Hash =
  result = 0
  for x in 0..3:
    result = (result shl 8) or u.MD5Digest[x].int

proc hash*(x: FileIndex): Hash {.borrow.}

when defined(nimsuggest):
  template onUse*(info: TLineInfo; s: PSym; isGenericInstance = false) = discard
  template onDefResolveForward*(info: TLineInfo; s: PSym) = discard
else:
  template onUse*(info: TLineInfo; s: PSym; isGenericInstance = false) = discard
  template onDef*(info: TLineInfo; s: PSym) = discard
  template onDefResolveForward*(info: TLineInfo; s: PSym) = discard

proc stopCompile*(g: ModuleGraph): bool {.inline.} =
  result = g.doStopCompile != nil and g.doStopCompile()

proc createMagic*(g: ModuleGraph; idgen: IdGenerator; name: string, m: TMagic): PSym =
  result = newSym(skProc, getIdent(g.cache, name), idgen, nil, unknownLineInfo, {})
  result.magic = m
  result.flags = {sfNeverRaises}

proc createMagic(g: ModuleGraph; name: string, m: TMagic): PSym =
  result = createMagic(g, g.idgen, name, m)

proc uniqueModuleName*(conf: ConfigRef; m: PSym): string =
  ## The unique module name is guaranteed to only contain {'A'..'Z', 'a'..'z', '0'..'9', '_'}
  ## so that it is useful as a C identifier snippet.
  let fid = FileIndex(m.position)
  let path = AbsoluteFile toFullPath(conf, fid)
  var isLib = false
  var rel = ""
  if path.string.startsWith(conf.libpath.string):
    isLib = true
    rel = relativeTo(path, conf.libpath).string
  else:
    rel = relativeTo(path, conf.projectPath).string

  if not isLib and not belongsToProjectPackage(conf, m):
    # special handlings for nimble packages
    when DirSep == '\\':
      let rel2 = replace(rel, '\\', '/')
    else:
      let rel2 = rel
    const pkgs2 = "pkgs2/"
    var start = rel2.find(pkgs2)
    if start >= 0:
      start += pkgs2.len
      start += skipUntil(rel2, {'/'}, start)
      if start+1 < rel2.len:
        rel = "pkg/" & rel2[start+1..<rel.len] # strips paths

  let trunc = if rel.endsWith(".nim"): rel.len - len(".nim") else: rel.len
  result = newStringOfCap(trunc)
  for i in 0..<trunc:
    let c = rel[i]
    case c
    of 'a'..'z', '0'..'9':
      result.add c
    of {os.DirSep, os.AltSep}:
      result.add 'Z' # because it looks a bit like '/'
    of '.':
      result.add 'O' # a circle
    else:
      # We mangle upper letters too so that there cannot
      # be clashes with our special meanings of 'Z' and 'O'
      result.addInt ord(c)

proc registerModule*(g: ModuleGraph; m: PSym) =
  assert m != nil
  assert m.kind == skModule

  if m.position >= g.ifaces.len:
    setLen(g.ifaces, m.position + 1)

  if g.ifaces[m.position].module == nil:
    g.ifaces[m.position] = Iface(module: m, converters: @[], patterns: @[],
                                uniqueName: rope(uniqueModuleName(g.config, m)))
    initStrTables(g, m)

proc registerModuleById*(g: ModuleGraph; m: FileIndex) =
  registerModule(g, g.ifaces[int m].module)

proc initOperators*(g: ModuleGraph): Operators =
  # These are safe for IC.
  # Public because it's used by DrNim.
  result = Operators(
    opLe: createMagic(g, "<=", mLeI),
    opLt: createMagic(g, "<", mLtI),
    opAnd: createMagic(g, "and", mAnd),
    opOr: createMagic(g, "or", mOr),
    opIsNil: createMagic(g, "isnil", mIsNil),
    opEq: createMagic(g, "==", mEqI),
    opAdd: createMagic(g, "+", mAddI),
    opSub: createMagic(g, "-", mSubI),
    opMul: createMagic(g, "*", mMulI),
    opDiv: createMagic(g, "div", mDivI),
    opLen: createMagic(g, "len", mLengthSeq),
    opNot: createMagic(g, "not", mNot),
    opContains: createMagic(g, "contains", mInSet)
  )

proc initModuleGraphFields(result: ModuleGraph) =
  # A module ID of -1 means that the symbol is not attached to a module at all,
  # but to the module graph:
  result.idgen = IdGenerator(module: -1'i32, symId: 0'i32, typeId: 0'i32)
  result.packageSyms = initStrTable()
  result.deps = initIntSet()
  result.importDeps = initTable[FileIndex, seq[FileIndex]]()
  result.ifaces = @[]
  result.importStack = @[]
  result.inclToMod = initTable[FileIndex, FileIndex]()
  result.owners = @[]
  result.suggestSymbols = initTable[FileIndex, SuggestFileSymbolDatabase]()
  result.suggestErrors = initTable[FileIndex, seq[Suggest]]()
  result.methods = @[]
  result.displayTokens = initTable[ItemId, uint32]()
  result.displayTokensByKey = initTable[string, uint32]()
  result.nextBaseDisplayTokenByDepth = initTable[int16, int]()
  result.nextSiblingDisplayTokenByParent = initTable[string, int]()
  result.compilerprocs = initStrTable()
  result.exposed = initStrTable()
  result.packageTypes = initStrTable()
  result.emptyNode = newNode(nkEmpty)
  result.cacheSeqs = initTable[string, PNode]()
  result.cacheCounters = initTable[string, BiggestInt]()
  result.cacheTables = initTable[string, BTree[string, PNode]]()
  result.canonTypes = initTable[SigHash, PType]()
  result.symBodyHashes = initTable[int, SigHash]()
  result.operators = initOperators(result)
  result.emittedTypeInfo = initTable[string, FileIndex]()
  result.cachedFiles = newStringTable()
  result.cachedMods = initIntSet()
  result.hookClosure = initIntSet()

proc newModuleGraph*(cache: IdentCache; config: ConfigRef): ModuleGraph =
  result = ModuleGraph()
  result.config = config
  result.cache = cache
  initModuleGraphFields(result)
  ast.setupProgram(config, cache)

proc resetAllModules*(g: ModuleGraph) =
  g.packageSyms = initStrTable()
  g.deps = initIntSet()
  g.ifaces = @[]
  g.importStack = @[]
  g.inclToMod = initTable[FileIndex, FileIndex]()
  g.usageSym = nil
  g.owners = @[]
  g.methods = @[]
  g.compilerprocs = initStrTable()
  g.exposed = initStrTable()
  initModuleGraphFields(g)

proc getModule*(g: ModuleGraph; fileIdx: FileIndex): PSym =
  if fileIdx.int32 >= 0 and fileIdx.int32 < g.ifaces.len:
    result = g.ifaces[fileIdx.int32].module
  else:
    result = nil

proc moduleOpenForCodegen*(g: ModuleGraph; m: FileIndex): bool {.inline.} =
  result = true

proc recordIcImplDep*(g: ModuleGraph; s: PSym) =
  ## NeedsImpl edge tracking, see `icImplDeps`. Called from the compile-time
  ## body consumption sites (vmgen's proc compilation, the getImpl opcodes).
  ## Own-module and group-member entries are filtered out when the `.edges`
  ## sidecar is written.
  if g.config.cmd == cmdM and s != nil and s.kind in routineKinds and
     s.itemId.module >= 0 and not isBackendMinted(s.itemId):
    g.icImplDeps.incl module(s.itemId).int

proc dependsOn(a, b: int): int {.inline.} = (a shl 15) + b

proc addDep*(g: ModuleGraph; m: PSym, dep: FileIndex) =
  assert m.position == m.info.fileIndex.int32
  if g.suggestMode:
    g.deps.incl m.position.dependsOn(dep.int)
    # we compute the transitive closure later when querying the graph lazily.
    # this improves efficiency quite a lot:
    #invalidTransitiveClosure = true

proc addIncludeDep*(g: ModuleGraph; module, includeFile: FileIndex) =
  discard hasKeyOrPut(g.inclToMod, includeFile, module)

proc parentModule*(g: ModuleGraph; fileIdx: FileIndex): FileIndex =
  ## returns 'fileIdx' if the file belonging to this index is
  ## directly used as a module or else the module that first
  ## references this include file.
  if fileIdx.int32 >= 0 and fileIdx.int32 < g.ifaces.len and g.ifaces[fileIdx.int32].module != nil:
    result = fileIdx
  else:
    result = g.inclToMod.getOrDefault(fileIdx)

proc transitiveClosure(g: var IntSet; n: int) =
  # warshall's algorithm
  for k in 0..<n:
    for i in 0..<n:
      for j in 0..<n:
        if i != j and not g.contains(i.dependsOn(j)):
          if g.contains(i.dependsOn(k)) and g.contains(k.dependsOn(j)):
            g.incl i.dependsOn(j)

proc markDirty*(g: ModuleGraph; fileIdx: FileIndex) =
  let m = g.getModule fileIdx
  if m != nil:
    g.suggestSymbols.del(fileIdx)
    g.suggestErrors.del(fileIdx)
    incl m.flagsImpl, sfDirty

proc unmarkAllDirty*(g: ModuleGraph) =
  for i in 0i32..<g.ifaces.len.int32:
    let m = g.ifaces[i].module
    if m != nil:
      m.flagsImpl.excl sfDirty

proc isDirty*(g: ModuleGraph; m: PSym): bool =
  result = g.suggestMode and sfDirty in m.flags

proc markClientsDirty*(g: ModuleGraph; fileIdx: FileIndex) =
  # we need to mark its dependent modules D as dirty right away because after
  # nimsuggest is done with this module, the module's dirty flag will be
  # cleared but D still needs to be remembered as 'dirty'.
  if g.invalidTransitiveClosure:
    g.invalidTransitiveClosure = false
    transitiveClosure(g.deps, g.ifaces.len)

  # every module that *depends* on this file is also dirty:
  for i in 0i32..<g.ifaces.len.int32:
    if g.deps.contains(i.dependsOn(fileIdx.int)):
      g.markDirty(FileIndex(i))

proc needsCompilation*(g: ModuleGraph): bool =
  # every module that *depends* on this file is also dirty:
  result = false
  for i in 0i32..<g.ifaces.len.int32:
    let m = g.ifaces[i].module
    if m != nil:
      if sfDirty in m.flags:
        return true

proc needsCompilation*(g: ModuleGraph, fileIdx: FileIndex): bool =
  result = false
  let module = g.getModule(fileIdx)
  if module != nil and g.isDirty(module):
    return true

  for i in 0i32..<g.ifaces.len.int32:
    let m = g.ifaces[i].module
    if m != nil and g.isDirty(m) and g.deps.contains(fileIdx.int32.dependsOn(i)):
      return true

proc getBody*(g: ModuleGraph; s: PSym): PNode {.inline.} =
  result = s.ast[bodyPos]
  if result != nil and nfLazyBody in result.flags and forceLazyBodyHook != nil:
    # Sanctioned body-access gate (see astdef.bodyPos): materialize the deferred
    # IC body so callers may safely touch `.sons` directly, not only via `len`.
    forceLazyBodyHook(result)
  assert result != nil

when not defined(nimKochBootstrap):
  proc registerLoadedHooks*(g: ModuleGraph; logOps: seq[LogEntry]) =
    let mainSuffix = getMainModuleSuffix(ast.program)
    for x in logOps:
      # A dependency's NIF may carry hooks whose syms belong to the module we
      # are compiling fresh (e.g. a stale NIF of that very module written by an
      # earlier in-process compilation). Loading those would collide with the
      # freshly semchecked hook declarations.
      if mainSuffix.len > 0 and
         cachedModuleSuffix(g.config, x.sym.itemId.module.FileIndex) == mainSuffix:
        continue
      case x.kind
      of HookEntry:
        # The same structural hook may be serialized by several instantiating
        # modules (a generic/structural instance has no single def site, so each
        # using module owns its copy). Pick one deterministic program-wide winner
        # by the smaller owning-module name, so every lookup resolves to the same
        # sym regardless of module load order.
        let existing = g.loadedOps[x.op].getOrDefault(x.key)
        if existing == nil or
           cachedModuleSuffix(g.config, x.sym.itemId.module.FileIndex) <
           cachedModuleSuffix(g.config, existing.itemId.module.FileIndex):
          g.loadedOps[x.op][x.key] = x.sym
      of EnumToStrEntry:
        g.loadedEnumToStringProcs[x.key] = x.sym
      of CppMemberEntry:
        replayCppMember(g, x.sym)
      of MethodEntry:
        # only `methodDef` registrations (empty key) rebuild dispatch
        # buckets; the `addMethodToGeneric` flavor (typeKey key) announces
        # the uninstantiated generic method, which must never enter a
        # bucket (methodsPerGenericType replay is still a todo).
        # Under `nim nifc` the replay is deferred: building a bucket forces
        # the method's body, and a body loaded mid `loadModuleDependencies`
        # registers modules it references in a different path context than
        # the lazy loads during codegen do (`flushMethodReplays`).
        if x.key.len == 0:
          if g.config.cmd == cmdNifC:
            g.pendingMethodReplays.add x.sym
          else:
            registerLoadedMethod(g, x.sym)
      else:
        discard

  proc loadTransitiveHooks(g: ModuleGraph; deps: seq[ModuleSuffix]) =
    ## Registers the serialized hooks (and enum-to-string procs) of every module
    ## in the import closure of `deps`. Deliberately does NOT use
    ## `moduleFromNifFile`: that would register the dep as a fully loaded module
    ## and a later direct import of it would then skip `replayStateChanges`.
    var stack = deps
    var interf = initStrTable()
    var interfHidden = initStrTable()
    while stack.len > 0:
      let suffix = stack.pop()
      var isKnownFile = false
      let fileIdx = g.config.registerNifSuffix(string suffix, isKnownFile)
      if not g.hookClosure.containsOrIncl(fileIdx.int):
        let precomp = loadNifModule(ast.program, suffix, interf, interfHidden, {})
        registerLoadedHooks(g, precomp.logOps)
        # Record this transitively-loaded module so the sem driver applies its
        # VM-level load effects (macro-cache replay + `{.compileTime.}` global init)
        # exactly as for a direct import — see `pendingNifInit`. A throwaway module
        # symbol (same shape as moduleFromNifFile's) gives the drain an idgen/info
        # context; it is not registered, so a later direct import still loads fully.
        if g.config.cmd == cmdM:
          let m = PSym(kindImpl: skModule, itemId: itemId(int32(fileIdx), 0'i32),
                       name: getIdent(g.cache, splitFile(toFullPath(g.config, fileIdx)).name),
                       infoImpl: newLineInfo(fileIdx, 1, 1), positionImpl: int(fileIdx))
          setOwner(m, getPackage(g.config, g.cache, fileIdx))
          g.pendingNifInit.add (m, precomp.topLevel)
        # Rebuild generic TYPE- and PROC-instance offers across the WHOLE closure,
        # not just direct imports (`moduleFromNifFile`). An instance is frozen at
        # the FIRST module to create it (in a scope where its body's symbols
        # resolve unambiguously); a consumer many imports away must REUSE it rather
        # than re-instantiate in its own scope, which may resolve a body symbol
        # differently — a divergent `compiles()`-dependent array bound (SSZ
        # `HashArray[8192, Gwei]`, type offer), or an ambiguous unqualified ident
        # leaked from an unrelated import (`fromRaw` -> `SkRawPublicKeySize` from
        # both `secp` and `secp256k1`, proc offer). Direct-only rebuild left the
        # deep offer invisible when the clean instance lives a transitive hop away.
        for off in precomp.typeOffers:
          g.typeInstCache.mgetOrPut(off.generic.itemId, @[]).add off.inst
        for off in precomp.genericOffers:
          g.procInstCache.mgetOrPut(off.generic.itemId, @[]).add PInstantiation(
            sym: off.inst, concreteTypes: off.concreteTypes,
            genericParamsCount: off.genericParamsCount, compilesId: 0)
        for d in precomp.deps: stack.add d

  proc materializeReexportedModule(g: ModuleGraph; mname, msuffix: string): PSym =
    ## A re-exported MODULE (`import x; export x`) acts as a qualifier in the
    ## re-exporting module's interface (`asmm.x86.nd`). Reconstruct a module
    ## symbol for it and make its interface tables available for qualified
    ## lookup (`someSym` reads `g.ifaces[position]`) — WITHOUT registering
    ## the module: `Iface.module` stays nil so a later direct import still
    ## takes the full load path (replayStateChanges etc.).
    var isKnown = false
    let fIdx = g.config.registerNifSuffix(msuffix, isKnown)
    if fIdx.int >= g.ifaces.len: setLen(g.ifaces, fIdx.int + 1)
    if g.ifaces[fIdx.int].module != nil and
        g.ifaces[fIdx.int].module.name.s == mname:
      # properly registered already (directly imported earlier): reuse it
      return g.ifaces[fIdx.int].module
    result = PSym(kindImpl: skModule, itemId: itemId(int32(fIdx), 0'i32),
                  name: getIdent(g.cache, mname),
                  infoImpl: newLineInfo(fIdx, 1, 1),
                  positionImpl: int(fIdx))
    setOwner(result, getPackage(g.config, g.cache, fIdx))
    if g.ifaces[fIdx.int].module == nil and
        not g.icQualIfaces.containsOrIncl(fIdx.int):
      var interf = initStrTable()
      var interfHidden = initStrTable()
      let precomp = loadNifModule(ast.program, ModuleSuffix(msuffix),
                                  interf, interfHidden, {})
      # chains: the re-exported module may itself re-export modules
      for (n2, s2) in precomp.reexportedModules:
        let inner = materializeReexportedModule(g, n2, s2)
        if inner != nil:
          strTableAdd(interf, inner)
      g.ifaces[fIdx.int].interf = interf
      g.ifaces[fIdx.int].interfHidden = interfHidden

  proc moduleFromNifFile*(g: ModuleGraph; fileIdx: FileIndex;
                          flags: set[LoadFlag] = {}): PrecompiledModule =
    ## Returns 'nil' if the module needs to be recompiled.
    ## Loads module from NIF file when optCompress is enabled.
    ## When loadFullAst is true, loads the complete module AST for code generation.
    if not fileExists(toNifFilename(g.config, fileIdx)):
      return PrecompiledModule(module: nil)

    # NOTE: direction-(c) experiment (refuse to NIF-serve include-bearing modules
    # under ideActive, forcing a source compile) is disabled — it reproduces the
    # known sibling-resolution corruption (system.string -> excpt.nim:746). The
    # cold-include *discovery* scan (scanIncludeGraph) stays; the round-trip
    # fidelity of included symbols is the separate, still-open loader problem.
    when false:
      if g.config.ideActive and not g.withinSystem and
         fileIdx != g.config.m.systemFileIdx and
         nifModuleHasIncludes(g.config, fileIdx):
        return PrecompiledModule(module: nil)

    # Create module symbol
    let filename = AbsoluteFile toFullPath(g.config, fileIdx)

    let m = PSym(
      kindImpl: skModule,
      itemId: itemId(int32(fileIdx), 0'i32),
      name: getIdent(g.cache, splitFile(filename).name),
      infoImpl: newLineInfo(fileIdx, 1, 1),
      positionImpl: int(fileIdx))
    setOwner(m, getPackage(g.config, g.cache, fileIdx))
    # Register module in graph
    registerModule(g, m)
    # ... and, in the BACKEND, bind its NIF name to THIS symbol before anything
    # in the file is decoded, so the loader never mints a second `skModule` for
    # it (see `registerModuleSelfSym`). Backend-only: under `nim m` a module is
    # loaded for its INTERFACE, and re-pointing the owner slot of every loaded
    # symbol at the freshly built module sym changes what sem sees for an
    # imported routine — `times.toDateTimeByWeek` then lost its inferred
    # `raises` and the importer failed with "can raise an unlisted exception".
    if g.config.cmd == cmdNifC:
      registerModuleSelfSym(ast.program, cachedModuleSuffix(g.config, fileIdx), m)

    result = loadNifModule(ast.program, fileIdx,
                           g.ifaces[fileIdx.int].interf,
                           g.ifaces[fileIdx.int].interfHidden, flags)
    result.module = m
    # Restore the module symbol's persisted flags (see ast2nif `(modflags)`);
    # `cgen.genTopLevelStmt` gates the destructor pass on `sfInjectDestructors`.
    if (result.moduleFlags and ModFlagInjectDestructors) != 0:
      m.incl sfInjectDestructors
    for (mname, msuffix) in result.reexportedModules:
      let ms = materializeReexportedModule(g, mname, msuffix)
      if ms != nil:
        strTableAdd(g.ifaces[fileIdx.int].interf, ms)
    # Re-establish include->module mapping so nimsuggest's `parentModule` can map
    # a query in an included file back to this (NIF-loaded) module and recompile
    # it, exactly as it does for a from-source module. Without this the include
    # relationship is invisible for NIF-served modules.
    for incPath in result.includes:
      g.addIncludeDep(fileIdx, fileInfoIdx(g.config, AbsoluteFile incPath))

    # Rebuild `procInstCache` from this module's generic-instance OFFERS so a
    # consumer's `genericCacheGet` finds the instance and SKIPS re-running
    # `instantiateBody` in its own module scope (which lacks symbols visible only
    # at the generic's definition site — see ast2nif's `(offer …)`).
    for off in result.genericOffers:
      g.procInstCache.mgetOrPut(off.generic.itemId, @[]).add PInstantiation(
        sym: off.inst, concreteTypes: off.concreteTypes,
        genericParamsCount: off.genericParamsCount, compilesId: 0)

    # Rebuild `typeInstCache` from this module's generic TYPE-instance OFFERS so a
    # consumer's `searchInstTypes` reuses the baked instance (e.g. an SSZ
    # `HashArray` whose array bound depends on import-scope-sensitive `compiles()`)
    # rather than re-instantiating it with a divergent bound — see ast2nif's
    # `(toffer …)`. Keyed by the generic body sym's itemId, as `searchInstTypes`.
    for off in result.typeOffers:
      g.typeInstCache.mgetOrPut(off.generic.itemId, @[]).add off.inst

    # Mark module as cached
    g.cachedMods.incl fileIdx.int
    g.hookClosure.incl fileIdx.int

    # Register hooks from NIF index with the module graph
    registerLoadedHooks(g, result.logOps)
    for x in result.logOps:
      case x.kind
      of ConverterEntry:
        g.ifaces[fileIdx.int].converters.add x.sym
      of PureEnumEntry:
        # rebuild the pure-enum list (source path: `addPureEnum`) so importers can
        # offer this loaded `{.pure.}` enum's fields as the restricted pure-enum
        # fallback (`importPureEnumFields`).
        g.ifaces[fileIdx.int].pureEnums.add x.sym
      of MethodEntry:
        discard "dispatch buckets already rebuilt by registerLoadedHooks"
      of GenericInstEntry:
        raiseAssert "GenericInstEntry should not be in the NIF index"
      of HookEntry, EnumToStrEntry, CppMemberEntry:
        discard "already done by registerLoadedHooks"
    # Register methods per type from NIF index
    discard "todo"
    # `nim m` loads only its *direct* imports through this proc, but a hook for
    # a structural type (e.g. `=destroy` for `seq[PNode]`) lives in the NIF of
    # whichever module first lifted it — possibly a dependency of a dependency
    # that the current module never imports directly. Walk the whole import
    # closure so every serialized hook is visible. (Codegen, `nim nifc`, already
    # walks the closure in nifbackend.loadModuleDependencies.)
    if g.config.cmd == cmdM:
      loadTransitiveHooks(g, result.deps)
      # Record the directly-loaded module for the same VM-level load effects as its
      # transitive deps (`pendingNifInit`). AFTER loadTransitiveHooks so the drain
      # applies deps before the dependent (macro-cache order).
      g.pendingNifInit.add (m, result.topLevel)

  proc isModuleFile(g: ModuleGraph; fileIdx: FileIndex): bool =
    let i = fileIdx.int32
    i >= 0 and i < g.ifaces.len and g.ifaces[i].module != nil

  proc registerIncluderFromNif*(g: ModuleGraph; fileIdx: FileIndex): bool =
    ## Targeted cold-include discovery for nimsuggest: scan the nimcache NIFs
    ## (`scanIncludeGraph`) for a module whose include-set contains *this* file
    ## and register only that single include->module edge in `inclToMod`, so a
    ## query inside the include file resolves its includer via `parentModule`.
    ##
    ## Deliberately targeted: registering *every* include relationship (i.e. also
    ## `system`'s own `include`s) eagerly assigns FileIndexes and pollutes
    ## `inclToMod`, which perturbs the NIF line-info decode of unrelated modules
    ## (`system.string` then resolves into `excpt.nim`). Touch nothing but the
    ## one edge we need.
    let target = toFullPath(g.config, fileIdx)
    for (includer, includes) in scanIncludeGraph(g.config):
      for incFile in includes:
        if cmpPaths(incFile, target) == 0:
          g.addIncludeDep(fileInfoIdx(g.config, AbsoluteFile includer), fileIdx)
          return true
    result = false

  proc needsIncludeScan*(g: ModuleGraph; fileIdx: FileIndex): bool =
    ## True when `fileIdx` is neither a known module of its own nor an
    ## already-known include file — i.e. a cold-opened file whose includer we
    ## must still discover via `registerIncluderFromNif`.
    not g.isModuleFile(fileIdx) and not g.inclToMod.hasKey(fileIdx)

proc configComplete*(g: ModuleGraph) =
  #rememberStartupConfig(g.startupPackedConfig, g.config)
  discard

proc onProcessing*(graph: ModuleGraph, fileIdx: FileIndex, moduleStatus: string, fromModule: PSym) =
  let conf = graph.config
  let isNimscript = conf.isDefined("nimscript")
  if (not isNimscript) or hintProcessing in conf.cmdlineNotes:
    let path = toFilenameOption(conf, fileIdx, conf.filenameOption)
    let indent = ">".repeat(graph.importStack.len)
    let fromModule2 = if fromModule != nil: $fromModule.name.s else: "(toplevel)"
    let mode = if isNimscript: "(nims) " else: ""
    rawMessage(conf, hintProcessing, "$#$# $#: $#: $#" % [mode, indent, fromModule2, moduleStatus, path])

proc getPackage*(graph: ModuleGraph; fileIdx: FileIndex): PSym =
  ## Returns a package symbol for yet to be defined module for fileIdx.
  ## The package symbol is added to the graph if it doesn't exist.
  let pkgSym = getPackage(graph.config, graph.cache, fileIdx)
  # check if the package is already in the graph
  result = graph.packageSyms.strTableGet(pkgSym.name)
  if result == nil:
     # the package isn't in the graph, so create and add it
    result = pkgSym
    graph.packageSyms.strTableAdd(pkgSym)

proc belongsToStdlib*(graph: ModuleGraph, sym: PSym): bool =
  ## Check if symbol belongs to the 'stdlib' package.
  # Compare the package *name* (an interned ident), not the package symbol's
  # `.id`. Under per-module IC (`nim m`) the system module is loaded from a NIF
  # in a process that does not compile it from source, so its package symbol is
  # reconstructed with a fresh `.id` that no longer matches the freshly-interned
  # package of a stdlib module compiled standalone here — making the old id
  # comparison wrongly report `false` and inject `--import`ed modules into the
  # stdlib. Both are canonically named `stdlib` (lib/stdlib.nimble); in a normal
  # `nim c` build (system compiled from source) the ids match too, so this is a
  # no-op there.
  sym.getPackageSymbol.name.id == graph.systemModule.getPackageSymbol.name.id

proc fileSymbols*(graph: ModuleGraph, fileIdx: FileIndex): SuggestFileSymbolDatabase =
  result = graph.suggestSymbols.getOrDefault(fileIdx, newSuggestFileSymbolDatabase(fileIdx, optIdeExceptionInlayHints in graph.config.globalOptions))
  doAssert(result.fileIndex == fileIdx)

iterator suggestSymbolsIter*(g: ModuleGraph): SymInfoPair =
  for xs in g.suggestSymbols.values:
    for i in xs.lineInfo.low..xs.lineInfo.high:
      yield xs.getSymInfoPair(i)

iterator suggestErrorsIter*(g: ModuleGraph): Suggest =
  for xs in g.suggestErrors.values:
    for x in xs:
      yield x
