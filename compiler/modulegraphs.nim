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

import ast, astalgo, intsets, tables, options, lineinfos, hashes, idents,
  btrees, md5

import ic / [packed_ast, to_packed_ast]

type
  SigHash* = distinct MD5Digest

  LazySym* = object
    id*: FullId
    sym*: PSym

  Iface* = object       ## data we don't want to store directly in the
                        ## ast.PSym type for s.kind == skModule
    module*: PSym       ## module this "Iface" belongs to
    converters*: seq[LazySym]
    patterns*: seq[LazySym]
    pureEnums*: seq[LazySym]
    interf: TStrTable

  Operators* = object
    opNot*, opContains*, opLe*, opLt*, opAnd*, opOr*, opIsNil*, opEq*: PSym
    opAdd*, opSub*, opMul*, opDiv*, opLen*: PSym

  FullId* = object
    module*: int
    packed*: PackedItemId

  LazyType* = object
    id*: FullId
    typ*: PType

  LazyInstantiation* = object
    module*: int
    sym*: FullId
    concreteTypes*: seq[FullId]
    inst*: PInstantiation

  ModuleGraph* = ref object
    ifaces*: seq[Iface]  ## indexed by int32 fileIdx
    packed*: PackedModuleGraph

    typeInstCache*: Table[ItemId, seq[LazyType]] # A symbol's ItemId.
    procInstCache*: Table[ItemId, seq[LazyInstantiation]] # A symbol's ItemId.
    attachedOps*: array[TTypeAttachedOp, Table[ItemId, PSym]] # Type ID, destructors, etc.
    methodsPerType*: Table[ItemId, seq[(int, LazySym)]] # Type ID, attached methods
    enumToStringProcs*: Table[ItemId, LazySym]

    startupPackedConfig*: PackedConfig
    packageSyms*: TStrTable
    modulesPerPackage*: Table[ItemId, TStrTable]
    deps*: IntSet # the dependency graph or potentially its transitive closure.
    importDeps*: Table[FileIndex, seq[FileIndex]] # explicit import module dependencies
    suggestMode*: bool # whether we are in nimsuggest mode or not.
    invalidTransitiveClosure: bool
    systemModuleComplete*: bool
    inclToMod*: Table[FileIndex, FileIndex] # mapping of include file to the
                                            # first module that included it
    importStack*: seq[FileIndex]  # The current import stack. Used for detecting recursive
                                  # module dependencies.
    backend*: RootRef # minor hack so that a backend can extend this easily
    config*: ConfigRef
    cache*: IdentCache
    vm*: RootRef # unfortunately the 'vm' state is shared project-wise, this will
                 # be clarified in later compiler implementations.
    doStopCompile*: proc(): bool {.closure.}
    usageSym*: PSym # for nimsuggest
    owners*: seq[PSym]
    methods*: seq[tuple[methods: seq[PSym], dispatcher: PSym]] # needs serialization!
    systemModule*: PSym
    sysTypes*: array[TTypeKind, PType]
    compilerprocs*: TStrTable
    lazyCompilerprocs*: Table[string, FullId]
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
    passes*: seq[TPass]
    onDefinition*: proc (graph: ModuleGraph; s: PSym; info: TLineInfo) {.nimcall.}
    onDefinitionResolveForward*: proc (graph: ModuleGraph; s: PSym; info: TLineInfo) {.nimcall.}
    onUsage*: proc (graph: ModuleGraph; s: PSym; info: TLineInfo) {.nimcall.}
    globalDestructors*: seq[PNode]
    strongSemCheck*: proc (graph: ModuleGraph; owner: PSym; body: PNode) {.nimcall.}
    compatibleProps*: proc (graph: ModuleGraph; formal, actual: PType): bool {.nimcall.}
    idgen*: IdGenerator
    operators*: Operators

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

template semtab*(m: PSym; g: ModuleGraph): TStrTable =
  g.ifaces[m.position].interf

proc isCachedModule(g: ModuleGraph; module: int): bool {.inline.} =
  result = module < g.packed.len and g.packed[module].status == loaded

proc isCachedModule(g: ModuleGraph; m: PSym): bool {.inline.} =
  isCachedModule(g, m.position)

proc simulateCachedModule*(g: ModuleGraph; moduleSym: PSym; m: PackedModule) =
  when false:
    echo "simulating ", moduleSym.name.s, " ", moduleSym.position
  simulateLoadedModule(g.packed, g.config, g.cache, moduleSym, m)

type
  ModuleIter* = object
    fromRod: bool
    modIndex: int
    ti: TIdentIter
    rodIt: RodIter

proc initModuleIter*(mi: var ModuleIter; g: ModuleGraph; m: PSym; name: PIdent): PSym =
  assert m.kind == skModule
  mi.modIndex = m.position
  mi.fromRod = isCachedModule(g, mi.modIndex)
  if mi.fromRod:
    result = initRodIter(mi.rodIt, g.config, g.cache, g.packed, FileIndex mi.modIndex, name)
  else:
    result = initIdentIter(mi.ti, g.ifaces[mi.modIndex].interf, name)

proc nextModuleIter*(mi: var ModuleIter; g: ModuleGraph): PSym =
  if mi.fromRod:
    result = nextRodIter(mi.rodIt, g.packed)
  else:
    result = nextIdentIter(mi.ti, g.ifaces[mi.modIndex].interf)

iterator allSyms*(g: ModuleGraph; m: PSym): PSym =
  if isCachedModule(g, m):
    var rodIt: RodIter
    var r = initRodIterAllSyms(rodIt, g.config, g.cache, g.packed, FileIndex m.position)
    while r != nil:
      yield r
      r = nextRodIter(rodIt, g.packed)
  else:
    for s in g.ifaces[m.position].interf.data:
      if s != nil:
        yield s

proc someSym*(g: ModuleGraph; m: PSym; name: PIdent): PSym =
  if isCachedModule(g, m):
    result = interfaceSymbol(g.config, g.cache, g.packed, FileIndex(m.position), name)
  else:
    result = strTableGet(g.ifaces[m.position].interf, name)

proc systemModuleSym*(g: ModuleGraph; name: PIdent): PSym =
  result = someSym(g, g.systemModule, name)

iterator systemModuleSyms*(g: ModuleGraph; name: PIdent): PSym =
  var mi: ModuleIter
  var r = initModuleIter(mi, g, g.systemModule, name)
  while r != nil:
    yield r
    r = nextModuleIter(mi, g)

proc resolveType(g: ModuleGraph; t: var LazyType): PType =
  result = t.typ
  if result == nil and isCachedModule(g, t.id.module):
    result = loadTypeFromId(g.config, g.cache, g.packed, t.id.module, t.id.packed)
    t.typ = result
  assert result != nil

proc resolveSym(g: ModuleGraph; t: var LazySym): PSym =
  result = t.sym
  if result == nil and isCachedModule(g, t.id.module):
    result = loadSymFromId(g.config, g.cache, g.packed, t.id.module, t.id.packed)
    t.sym = result
  assert result != nil

proc resolveInst(g: ModuleGraph; t: var LazyInstantiation): PInstantiation =
  result = t.inst
  if result == nil and isCachedModule(g, t.module):
    result = PInstantiation(sym: loadSymFromId(g.config, g.cache, g.packed, t.sym.module, t.sym.packed))
    result.concreteTypes = newSeq[PType](t.concreteTypes.len)
    for i in 0..high(result.concreteTypes):
      result.concreteTypes[i] = loadTypeFromId(g.config, g.cache, g.packed,
          t.concreteTypes[i].module, t.concreteTypes[i].packed)
    t.inst = result
  assert result != nil

iterator typeInstCacheItems*(g: ModuleGraph; s: PSym): PType =
  if g.typeInstCache.contains(s.itemId):
    let x = addr(g.typeInstCache[s.itemId])
    for t in mitems(x[]):
      yield resolveType(g, t)

iterator procInstCacheItems*(g: ModuleGraph; s: PSym): PInstantiation =
  if g.procInstCache.contains(s.itemId):
    let x = addr(g.procInstCache[s.itemId])
    for t in mitems(x[]):
      yield resolveInst(g, t)

proc getAttachedOp*(g: ModuleGraph; t: PType; op: TTypeAttachedOp): PSym =
  ## returns the requested attached operation for type `t`. Can return nil
  ## if no such operation exists.
  result = g.attachedOps[op].getOrDefault(t.itemId)

proc setAttachedOp*(g: ModuleGraph; module: int; t: PType; op: TTypeAttachedOp; value: PSym) =
  ## we also need to record this to the packed module.
  g.attachedOps[op][t.itemId] = value
  # XXX Also add to the packed module!

proc setAttachedOpPartial*(g: ModuleGraph; module: int; t: PType; op: TTypeAttachedOp; value: PSym) =
  ## we also need to record this to the packed module.
  g.attachedOps[op][t.itemId] = value
  # XXX Also add to the packed module!

proc completePartialOp*(g: ModuleGraph; module: int; t: PType; op: TTypeAttachedOp; value: PSym) =
  discard "To implement"

proc getToStringProc*(g: ModuleGraph; t: PType): PSym =
  result = resolveSym(g, g.enumToStringProcs[t.itemId])
  assert result != nil

proc setToStringProc*(g: ModuleGraph; t: PType; value: PSym) =
  g.enumToStringProcs[t.itemId] = LazySym(sym: value)

iterator methodsForGeneric*(g: ModuleGraph; t: PType): (int, PSym) =
  if g.methodsPerType.contains(t.itemId):
    for it in mitems g.methodsPerType[t.itemId]:
      yield (it[0], resolveSym(g, it[1]))

proc addMethodToGeneric*(g: ModuleGraph; module: int; t: PType; col: int; m: PSym) =
  g.methodsPerType.mgetOrPut(t.itemId, @[]).add (col, LazySym(sym: m))

proc hasDisabledAsgn*(g: ModuleGraph; t: PType): bool =
  let op = getAttachedOp(g, t, attachedAsgn)
  result = op != nil and sfError in op.flags

proc copyTypeProps*(g: ModuleGraph; module: int; dest, src: PType) =
  for k in low(TTypeAttachedOp)..high(TTypeAttachedOp):
    let op = getAttachedOp(g, src, k)
    if op != nil:
      setAttachedOp(g, module, dest, k, op)

proc loadCompilerProc*(g: ModuleGraph; name: string): PSym =
  if g.config.symbolFiles == disabledSf: return nil
  let t = g.lazyCompilerprocs.getOrDefault(name)
  if t.module != 0:
    assert isCachedModule(g, t.module)
    result = loadSymFromId(g.config, g.cache, g.packed, t.module, t.packed)
    if result != nil:
      strTableAdd(g.compilerprocs, result)

proc `$`*(u: SigHash): string =
  toBase64a(cast[cstring](unsafeAddr u), sizeof(u))

proc `==`*(a, b: SigHash): bool =
  result = equalMem(unsafeAddr a, unsafeAddr b, sizeof(a))

proc hash*(u: SigHash): Hash =
  result = 0
  for x in 0..3:
    result = (result shl 8) or u.MD5Digest[x].int

proc hash*(x: FileIndex): Hash {.borrow.}

when defined(nimfind):
  template onUse*(info: TLineInfo; s: PSym) =
    when compiles(c.c.graph):
      if c.c.graph.onUsage != nil: c.c.graph.onUsage(c.c.graph, s, info)
    else:
      if c.graph.onUsage != nil: c.graph.onUsage(c.graph, s, info)

  template onDef*(info: TLineInfo; s: PSym) =
    when compiles(c.c.graph):
      if c.c.graph.onDefinition != nil: c.c.graph.onDefinition(c.c.graph, s, info)
    else:
      if c.graph.onDefinition != nil: c.graph.onDefinition(c.graph, s, info)

  template onDefResolveForward*(info: TLineInfo; s: PSym) =
    when compiles(c.c.graph):
      if c.c.graph.onDefinitionResolveForward != nil:
        c.c.graph.onDefinitionResolveForward(c.c.graph, s, info)
    else:
      if c.graph.onDefinitionResolveForward != nil:
        c.graph.onDefinitionResolveForward(c.graph, s, info)

else:
  template onUse*(info: TLineInfo; s: PSym) = discard
  template onDef*(info: TLineInfo; s: PSym) = discard
  template onDefResolveForward*(info: TLineInfo; s: PSym) = discard

proc stopCompile*(g: ModuleGraph): bool {.inline.} =
  result = g.doStopCompile != nil and g.doStopCompile()

proc createMagic*(g: ModuleGraph; name: string, m: TMagic): PSym =
  result = newSym(skProc, getIdent(g.cache, name), nextSymId(g.idgen), nil, unknownLineInfo, {})
  result.magic = m
  result.flags = {sfNeverRaises}

proc registerModule*(g: ModuleGraph; m: PSym) =
  assert m != nil
  assert m.kind == skModule

  if m.position >= g.ifaces.len:
    setLen(g.ifaces, m.position + 1)

  if m.position >= g.packed.len:
    setLen(g.packed, m.position + 1)

  g.ifaces[m.position] = Iface(module: m, converters: @[], patterns: @[])
  initStrTable(g.ifaces[m.position].interf)

proc initOperators(g: ModuleGraph): Operators =
  # These are safe for IC.
  result.opLe = createMagic(g, "<=", mLeI)
  result.opLt = createMagic(g, "<", mLtI)
  result.opAnd = createMagic(g, "and", mAnd)
  result.opOr = createMagic(g, "or", mOr)
  result.opIsNil = createMagic(g, "isnil", mIsNil)
  result.opEq = createMagic(g, "==", mEqI)
  result.opAdd = createMagic(g, "+", mAddI)
  result.opSub = createMagic(g, "-", mSubI)
  result.opMul = createMagic(g, "*", mMulI)
  result.opDiv = createMagic(g, "div", mDivI)
  result.opLen = createMagic(g, "len", mLengthSeq)
  result.opNot = createMagic(g, "not", mNot)
  result.opContains = createMagic(g, "contains", mInSet)

proc newModuleGraph*(cache: IdentCache; config: ConfigRef): ModuleGraph =
  result = ModuleGraph()
  # A module ID of -1 means that the symbol is not attached to a module at all,
  # but to the module graph:
  result.idgen = IdGenerator(module: -1'i32, symId: 0'i32, typeId: 0'i32)
  initStrTable(result.packageSyms)
  result.deps = initIntSet()
  result.importDeps = initTable[FileIndex, seq[FileIndex]]()
  result.ifaces = @[]
  result.importStack = @[]
  result.inclToMod = initTable[FileIndex, FileIndex]()
  result.config = config
  result.cache = cache
  result.owners = @[]
  result.methods = @[]
  initStrTable(result.compilerprocs)
  initStrTable(result.exposed)
  initStrTable(result.packageTypes)
  result.emptyNode = newNode(nkEmpty)
  result.cacheSeqs = initTable[string, PNode]()
  result.cacheCounters = initTable[string, BiggestInt]()
  result.cacheTables = initTable[string, BTree[string, PNode]]()
  result.canonTypes = initTable[SigHash, PType]()
  result.symBodyHashes = initTable[int, SigHash]()
  result.operators = initOperators(result)

proc resetAllModules*(g: ModuleGraph) =
  initStrTable(g.packageSyms)
  g.deps = initIntSet()
  g.ifaces = @[]
  g.importStack = @[]
  g.inclToMod = initTable[FileIndex, FileIndex]()
  g.usageSym = nil
  g.owners = @[]
  g.methods = @[]
  initStrTable(g.compilerprocs)
  initStrTable(g.exposed)

proc getModule*(g: ModuleGraph; fileIdx: FileIndex): PSym =
  if fileIdx.int32 >= 0:
    if isCachedModule(g, fileIdx.int32):
      result = g.packed[fileIdx.int32].module
    elif fileIdx.int32 < g.ifaces.len:
      result = g.ifaces[fileIdx.int32].module

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
  if m != nil: incl m.flags, sfDirty

proc markClientsDirty*(g: ModuleGraph; fileIdx: FileIndex) =
  # we need to mark its dependent modules D as dirty right away because after
  # nimsuggest is done with this module, the module's dirty flag will be
  # cleared but D still needs to be remembered as 'dirty'.
  if g.invalidTransitiveClosure:
    g.invalidTransitiveClosure = false
    transitiveClosure(g.deps, g.ifaces.len)

  # every module that *depends* on this file is also dirty:
  for i in 0i32..<g.ifaces.len.int32:
    let m = g.ifaces[i].module
    if m != nil and g.deps.contains(i.dependsOn(fileIdx.int)):
      incl m.flags, sfDirty

proc isDirty*(g: ModuleGraph; m: PSym): bool =
  result = g.suggestMode and sfDirty in m.flags

proc getBody*(g: ModuleGraph; s: PSym): PNode {.inline.} =
  result = s.ast[bodyPos]
  if result == nil and g.config.symbolFiles in {readOnlySf, v2Sf, stressTest}:
    result = loadProcBody(g.config, g.cache, g.packed, s)
    s.ast[bodyPos] = result
  assert result != nil

proc moduleFromRodFile*(g: ModuleGraph; fileIdx: FileIndex;
                        cachedModules: var seq[FileIndex]): PSym =
  ## Returns 'nil' if the module needs to be recompiled.
  if g.config.symbolFiles in {readOnlySf, v2Sf, stressTest}:
    result = moduleFromRodFile(g.packed, g.config, g.cache, fileIdx, cachedModules)

proc configComplete*(g: ModuleGraph) =
  rememberStartupConfig(g.startupPackedConfig, g.config)
