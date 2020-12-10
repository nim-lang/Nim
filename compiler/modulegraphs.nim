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
## or stored in a Sqlite database.
##
## The caching of modules is critical for 'nimsuggest' and is tricky to get
## right. If module E is being edited, we need autocompletion (and type
## checking) for E but we don't want to recompile depending
## modules right away for faster turnaround times. Instead we mark the module's
## dependencies as 'dirty'. Let D be a dependency of E. If D is dirty, we
## need to recompile it and all of its dependencies that are marked as 'dirty'.
## 'nimsuggest sug' actually is invoked for the file being edited so we know
## its content changed and there is no need to compute any checksums.
## Instead of a recursive algorithm, we use an iterative algorithm:
##
## - If a module gets recompiled, its dependencies need to be updated.
## - Its dependent module stays the same.
##

import ast, intsets, tables, options, lineinfos, hashes, idents,
  incremental, btrees, md5, astalgo, msgs

type
  SigHash* = distinct MD5Digest

import ic/[packed_ast, contexts, store]

import std/sequtils
import std/options as stdoptions

type
  IfaceState = enum Uninitialized, Loaded, Unpacked, Unloaded
  Iface* = object       ## data we don't want to store directly in the
                        ## ast.PSym type for s.kind == skModule
    encoder*: ref PackedEncoder
    decoder*: ref PackedDecoder
    module*: PSym       ## module this "Iface" belongs to
    converters*: seq[PSym]
    patterns*: seq[PSym]
    pureEnums*: seq[PSym]
    tree: PackedTree

  ModuleGraph* = ref object
    ifaces*: seq[Iface]  ## indexed by int32 fileIdx
    packageSyms*: TStrTable
    deps*: IntSet # the dependency graph or potentially its transitive closure.
    importDeps*: Table[FileIndex, seq[FileIndex]] # explicit import module dependencies
    suggestMode*: bool # whether we are in nimsuggest mode or not.
    invalidTransitiveClosure: bool
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
    exposed*: TStrTable
    intTypeCache*: array[-5..64, PType]
    opContains*, opNot*: PSym
    emptyNode*: PNode
    incr*: IncrementalCtx
    canonTypes*: Table[SigHash, PType]
    symBodyHashes*: Table[int, SigHash] # symId to digest mapping
    importModuleCallback*: proc (graph: ModuleGraph; m: PSym, fileIdx: FileIndex): PSym {.nimcall.}
    includeFileCallback*: proc (graph: ModuleGraph; m: PSym, fileIdx: FileIndex): PNode {.nimcall.}
    recordStmt*: proc (graph: ModuleGraph; m: PSym; n: PNode) {.nimcall.}
    cacheSeqs*: Table[string, PNode] # state that is shared to support the 'macrocache' API
    cacheCounters*: Table[string, BiggestInt]
    cacheTables*: Table[string, BTree[string, PNode]]
    passes*: seq[TPass]
    onDefinition*: proc (graph: ModuleGraph; s: PSym; info: TLineInfo) {.nimcall.}
    onDefinitionResolveForward*: proc (graph: ModuleGraph; s: PSym; info: TLineInfo) {.nimcall.}
    onUsage*: proc (graph: ModuleGraph; s: PSym; info: TLineInfo) {.nimcall.}
    globalDestructors*: seq[PNode]
    strongSemCheck*: proc (graph: ModuleGraph; owner: PSym; body: PNode) {.nimcall.}
    compatibleProps*: proc (graph: ModuleGraph; formal, actual: PType): bool {.nimcall.}
    idgen*: IdGenerator

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

proc getExport*(g: ModuleGraph; m: PSym; name: PIdent): PSym

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
  result = newSym(skProc, getIdent(g.cache, name), nextId(g.idgen),
                  nil, unknownLineInfo, {})
  result.magic = m
  result.flags = {sfNeverRaises}

proc newModuleGraph*(cache: IdentCache; config: ConfigRef): ModuleGraph =
  result = ModuleGraph()
  result.idgen = IdGenerator(module: -1'i32, item: 0'i32)
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
  result.opNot = createMagic(result, "not", mNot)
  result.opContains = createMagic(result, "contains", mInSet)
  result.emptyNode = newNode(nkEmpty)
  init(result.incr)
  result.recordStmt = proc (graph: ModuleGraph; m: PSym; n: PNode) {.nimcall.} =
    discard
  result.cacheSeqs = initTable[string, PNode]()
  result.cacheCounters = initTable[string, BiggestInt]()
  result.cacheTables = initTable[string, BTree[string, PNode]]()
  result.canonTypes = initTable[SigHash, PType]()
  result.symBodyHashes = initTable[int, SigHash]()

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
  if fileIdx.int32 >= 0 and fileIdx.int32 < g.ifaces.len:
    result = g.ifaces[fileIdx.int32].module

proc dependsOn(a, b: int): int {.inline.} = (a shl 15) + b

proc addDep*(g: ModuleGraph; m: PSym, dep: FileIndex) =
  assert m.position == m.info.fileIndex.int32
  addModuleDep(g.incr, g.config, m.info.fileIndex, dep, isIncludeFile = false)
  if g.suggestMode:
    g.deps.incl m.position.dependsOn(dep.int)
    # we compute the transitive closure later when querying the graph lazily.
    # this improves efficiency quite a lot:
    #invalidTransitiveClosure = true

proc addIncludeDep*(g: ModuleGraph; module, includeFile: FileIndex) =
  addModuleDep(g.incr, g.config, module, includeFile, isIncludeFile = true)
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

import ic/[to_packed_ast, from_packed_ast]

proc `state=`*(iface: var Iface; state: IfaceState) =
  ## guard crazy state changes
  assert state > iface.state, "state can only advance"
  system.`=`(iface.state, state)

proc state*(iface: Iface): IfaceState = iface.state

proc contains(state: IfaceState; iface: Iface): bool =
  ## syntax comfort for `iface in Loaded` (state)
  if state == Loaded:
    iface.state in {Loaded, Unpacked}
  else:
    iface.state == state

proc makeResolver*(graph: ModuleGraph): Resolver =
  proc resolver(module: int32; name: string): PSym =
    ## this resolver callback serves to add the graph to the scope of
    ## the packed ast decoder without requiring the graph itself
    let ident = getIdent(graph.cache, name)
    echo "resolve ", name
    if module == PackageModuleId:
      result = strTableGet(graph.packageSyms, ident)
    else:
      block found:
        # we'll just do this stupidly for now
        for i in countup(0, graph.ifaces.high):
          template iface: Iface = graph.ifaces[i]
          if iface.module != nil:
            if iface.module.itemId.module == module:
              result = getExport(graph, iface.module, ident)
              break found
        internalError(graph.config, "unable to resolve module " & $module)
    if result == nil:
      internalError(graph.config, "unable to retrieve " & name)
    echo "ok"
  result = resolver

proc initIface*(iface: var Iface; graph: ModuleGraph; s: PSym) =
  ## try to initialize the iface with an available rodfile
  template conf: ConfigRef = graph.config
  let m = tryReadModule(conf, rodFile(conf, s))
  iface.state =
    if m.isNone:
      Unloaded
    else:
      iface.decoder = new (ref PackedDecoder)
      initDecoder(iface.decoder[], graph.cache, makeResolver graph)
      iface.tree = (get m).ast
      assert iface.tree[0].kind != nkNone, "unexpectedly none ast"
      Loaded

proc initExports*(g: ModuleGraph; m: PSym) =
  ## prepare module to addExport
  template iface: Iface = g.ifaces[m.position]
  if m.kind == skModule:
    if iface.state == Uninitialized:
      initIface(iface, g, m)
  else:
    # implicit assertion that `m` is skPackage
    initStrTable m.pkgTab

template clearExports*(g: ModuleGraph; m: PSym) = initExports(g, m)

proc patterns*(g: ModuleGraph; m: PSym): seq[PSym] =
  ## return symbols exported from the given module
  template iface: Iface = g.ifaces[m.position]
  case iface.state
  of Uninitialized:
    assert false, "initialize iface first"
  of Loaded:
    iface.patterns = unpackAllSymbols(iface.tree, iface.decoder[], iface.module)
    iface.state = Unpacked
  of Unpacked, Unloaded:
    discard
  result = iface.patterns

proc converters*(g: ModuleGraph; m: PSym): seq[PSym] =
  ## return converters exported from the given module
  filterIt patterns(g, m): it.kind == skConverter

proc nextIdentIter*(it: var TIdentIter; g: ModuleGraph; m: PSym): PSym =
  ## replicate the existing iterator semantics for the iface cache
  template iface: Iface = g.ifaces[m.position]
  assert iface.state != Uninitialized
  block done:
    if patterns(g, m).high >= it.h.int:
      for i in countup(1 + it.h.int, patterns(g, m).high):
        let s = patterns(g, m)[i]
        if s.name.s == it.name.s:
          it.name = s.name
          it.h = i.Hash
          result = s
          break done
      # advance the iterator past the last index
      it.h = Hash patterns(g, m).len

proc initIdentIter*(it: var TIdentIter; g: ModuleGraph; m: PSym;
                    name: PIdent): PSym =
  ## replicate the existing iterator semantics for the iface cache
  template iface: Iface = g.ifaces[m.position]
  assert iface.state != Uninitialized
  it.name = name
  it.h = -1.Hash
  result = nextIdentIter(it, g, m)

iterator symbols*(g: ModuleGraph; m: PSym): PSym =
  ## lazy version of patterns
  template iface: Iface = g.ifaces[m.position]
  case iface.state
  of Uninitialized:
    assert false, "init iface first"
  of Loaded:
    for s in unpackSymbols(iface.tree, iface.decoder[], iface.module):
      yield s
  of Unpacked, Unloaded:
    for s in iface.patterns:
      yield s

iterator symbols*(g: ModuleGraph; m: PSym; name: PIdent): PSym =
  ## lazy version of patterns
  template iface: Iface = g.ifaces[m.position]
  case iface.state
  of Uninitialized:
    assert false, "init iface first"
  of Loaded:
    for s in unpackSymbols(iface.tree, iface.decoder[], iface.module,
                           name = name):
      yield s
  of Unpacked, Unloaded:
    for s in iface.patterns:
      if name.s == s.name.s:
        yield s

proc getExport*(g: ModuleGraph; m: PSym; name: PIdent): PSym =
  ## fetch an exported symbol for the module by ident
  template iface: Iface = g.ifaces[m.position]
  if m.kind == skModule:
    assert iface.state != Uninitialized
    for s in symbols(g, m, name = name):
      result = s
      break
  else:
    # implicit assertion that `m` is skPackage
    result = strTableGet(m.pkgTab, name)

proc addExport*(g: ModuleGraph; m: PSym; s: PSym) =
  ## add a symbol to a module's exported interface
  template iface: Iface = g.ifaces[m.position]
  assert s != nil
  assert m != nil
  if s.kind in {skModule, skPackage}:
    s.flags.incl sfExported
  if sfExported in s.flags:
    if m.kind == skModule:
      case iface.state
      of Uninitialized: assert false
      of Unloaded:
        block found:
          for p in iface.patterns.items:
            if p.id == s.id:
              break found
          iface.patterns.add s
      of Unpacked, Loaded:
        if s.kind != skModule:
          block found:
            for p in patterns(g, m):
              assert p.itemId.module == s.itemId.module
              echo "export ", p.id
              if p.id == s.id:
                break found
            echo "we received ", s.kind, " ", s.itemId
            echo iface.state, " wants to export ", s.name.s
            assert false, "imagine the two of us, meeting like this"
    else:
      # implicit assertion that `m` is skPackage
      strTableAdd(m.pkgTab, s)
  else:
    internalError(g.config, "cannot add export for unexported symbol")

proc addConverter*(g: ModuleGraph; m: PSym; s: PSym) =
  ## a pcontext version calls this one to record the converter in the
  ## correct iface ... i guess.
  assert m.kind == skModule
  addExport(g, m, s)

proc addPattern*(g: ModuleGraph; m: PSym; s: PSym) =
  ## a pcontext version calls this one to record the pattern in the
  ## correct iface ... i guess.
  assert m.kind == skModule
  addExport(g, m, s)

proc registerModule*(g: ModuleGraph; m: PSym) =
  ## setup the module's interface
  assert m != nil
  assert m.kind == skModule

  if m.position >= g.ifaces.len:
    setLen(g.ifaces, m.position + 1)
  g.ifaces[m.position] = Iface(module: m)
  initExports(g, m)
  addExport(g, m, m)       # a module always knows itself
