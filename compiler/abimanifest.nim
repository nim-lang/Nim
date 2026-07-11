#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Writes the native Nim ABI sidecar after C code generation has finalized
## exported symbols and semantic type layouts.

import
  ast, astalgo, ccgutils, cnif, modulegraphs, nversion, options, pathutils,
  platform, renderer, sighashes, types

from ast2nif import globalName, icNifTypeName
from typekeys import modname
from std/algorithm import sort
from std/os import extractFilename, tryRemoveFile
import std/[intsets, sets, strutils]
import "../dist/nimony/src/lib/nifbuilder" except Builder
from ../dist/checksums/src/checksums/md5 import getMD5

type
  AbiHook = tuple[typ: PType, op: TTypeAttachedOp, hook: PSym]

  AbiManifestState = object
    types: seq[PType]
    seenTypeIds: IntSet

proc nativeDynlibAllocator(config: ConfigRef): string =
  if isDefined(config, "useMalloc"):
    result = "malloc"
  elif isDefined(config, "nimAllocPagesViaMalloc"):
    result = "nimAllocPagesViaMalloc"
  elif isDefined(config, "useNimRtl"):
    result = "nimrtl"
  else:
    result = "nim-default"

proc layoutType(typ: PType): PType =
  result = typ
  while result != nil and result.kind in {
      tyGenericInst, tyAlias, tySink, tyOwned, tyInferred}:
    result = result.skipModifier

proc collectType(state: var AbiManifestState; typ: PType)

proc collectNodeTypes(state: var AbiManifestState; node: PNode) =
  if node == nil:
    return
  if node.kind == nkSym and node.sym.typ != nil:
    state.collectType(node.sym.typ)
  else:
    for child in node:
      state.collectNodeTypes(child)

proc collectType(state: var AbiManifestState; typ: PType) =
  if typ == nil or typ.isCompileTimeOnly or
      state.seenTypeIds.containsOrIncl(typ.id):
    return

  state.types.add typ
  state.collectNodeTypes(typ.n)
  for child in typ.sons:
    state.collectType(child)

proc collectProcTypes(state: var AbiManifestState; prc: PSym) =
  if prc.typ == nil:
    return
  state.collectType(prc.typ.returnType)
  if prc.typ.n != nil:
    for i in 1 ..< prc.typ.n.len:
      if prc.typ.n[i].kind == nkSym:
        state.collectType(prc.typ.n[i].sym.typ)

proc addLayoutInt(manifest: var nifbuilder.Builder; value: BiggestInt) =
  if value >= 0:
    nifbuilder.addIntLit(manifest, value)
  else:
    nifbuilder.addIdent(manifest, "unknown")

proc typeSymbol(typ: PType; config: ConfigRef): string =
  if typ == nil:
    result = ""
  else:
    result = icNifTypeName(typ, config)

proc typeKind(typ: PType): string =
  let concrete = layoutType(typ)
  if concrete == nil:
    result = "none"
  else:
    result = $concrete.kind
    result.removePrefix("ty")
    result = result.toLowerAscii

proc isManaged(typ: PType): bool =
  if typ == nil:
    return false
  let concrete = layoutType(typ)
  result = hasDestructor(typ) or containsGarbageCollectedRef(typ) or
    (concrete != nil and concrete.kind in {tyString, tySequence, tyRef}) or
    (concrete != nil and concrete.kind == tyProc and
      concrete.callConv == ccClosure)

proc appendLayoutFingerprint(node: PNode; config: ConfigRef; dest: var string) =
  if node == nil:
    return
  case node.kind
  of nkRecList:
    dest.add "list("
    for child in node:
      appendLayoutFingerprint(child, config, dest)
    dest.add ")"
  of nkRecCase:
    dest.add "case("
    appendLayoutFingerprint(node[0], config, dest)
    for i in 1 ..< node.len:
      dest.add $i
      dest.add ':'
      dest.add $node[i].kind
      dest.add ':'
      for j in 0 ..< node[i].len - 1:
        dest.add renderTree(node[i][j])
        dest.add ','
      appendLayoutFingerprint(node[i].lastSon, config, dest)
    dest.add ")"
  of nkSym:
    let field = node.sym
    dest.add field.name.s
    dest.add ':'
    dest.add typeSymbol(field.typ, config)
    dest.add ':'
    dest.add $field.offset
    dest.add ':'
    dest.add $getSize(config, field.typ)
    dest.add ':'
    dest.add $getAlign(config, field.typ)
    dest.add ':'
    dest.add $field.bitsize
    dest.add ':'
    dest.add $field.alignment
    dest.add ':'
    dest.add(if sfExported in field.flags: "exported" else: "private")
    dest.add ';'
  else:
    discard

proc layoutFingerprint(typ: PType; config: ConfigRef): string =
  let concrete = layoutType(typ)
  var value = typeSymbol(typ, config) & ':' & $getSize(config, typ) & ':' &
    $getAlign(config, typ) & ':'
  if concrete != nil:
    value.add $concrete.flags
    value.add ':'
    if concrete.kind == tyObject and concrete.baseClass != nil:
      value.add typeSymbol(concrete.baseClass, config)
      value.add ':'
    appendLayoutFingerprint(concrete.n, config, value)
  result = $getMD5(value)

proc writeField(manifest: var nifbuilder.Builder; field: PSym;
                config: ConfigRef; role: string) =
  nifbuilder.withTree(manifest, "field"):
    nifbuilder.addStrLit(manifest, field.name.s)
    nifbuilder.addStrLit(manifest, typeSymbol(field.typ, config))
    addLayoutInt(manifest, field.offset)
    addLayoutInt(manifest, getSize(config, field.typ))
    addLayoutInt(manifest, getAlign(config, field.typ))
    nifbuilder.addIdent(manifest,
      if sfExported in field.flags: "exported" else: "private")
    nifbuilder.addIdent(manifest,
      if isManaged(field.typ): "managed" else: "plain")
    nifbuilder.addIdent(manifest, role)

proc writeRecord(manifest: var nifbuilder.Builder; node: PNode;
                 config: ConfigRef)

proc writeBranch(manifest: var nifbuilder.Builder; branch: PNode;
                 branchIndex: int; config: ConfigRef) =
  nifbuilder.withTree(manifest, "branch"):
    nifbuilder.addIntLit(manifest, branchIndex)
    nifbuilder.addIdent(manifest,
      if branch.kind == nkElse: "else" else: "of")
    nifbuilder.withTree(manifest, "selectors"):
      if branch.kind == nkOfBranch:
        for i in 0 ..< branch.len - 1:
          nifbuilder.addStrLit(manifest, renderTree(branch[i]))
    nifbuilder.withTree(manifest, "record"):
      if branch.len > 0:
        writeRecord(manifest, branch.lastSon, config)

proc writeRecord(manifest: var nifbuilder.Builder; node: PNode;
                 config: ConfigRef) =
  if node == nil:
    return
  case node.kind
  of nkRecList:
    for child in node:
      writeRecord(manifest, child, config)
  of nkRecCase:
    nifbuilder.withTree(manifest, "case"):
      if node.len > 0 and node[0].kind == nkSym:
        writeField(manifest, node[0].sym, config, "discriminant")
      for i in 1 ..< node.len:
        writeBranch(manifest, node[i], i - 1, config)
  of nkSym:
    if node.sym.kind == skField and node.sym.typ != nil and
        node.sym.typ.kind != tyVoid:
      writeField(manifest, node.sym, config, "field")
  else:
    discard

proc writeEnum(manifest: var nifbuilder.Builder; node: PNode) =
  if node == nil:
    return
  for child in node:
    if child.kind == nkSym and child.sym.kind == skEnumField:
      nifbuilder.withTree(manifest, "value"):
        nifbuilder.addStrLit(manifest, child.sym.name.s)
        nifbuilder.addIntLit(manifest, child.sym.position)

proc writeType(manifest: var nifbuilder.Builder; typ: PType;
               config: ConfigRef) =
  let concrete = layoutType(typ)
  nifbuilder.withTree(manifest, "type"):
    nifbuilder.addStrLit(manifest, typeSymbol(typ, config))
    nifbuilder.addIdent(manifest, typeKind(typ))
    addLayoutInt(manifest, getSize(config, typ))
    addLayoutInt(manifest, getAlign(config, typ))
    nifbuilder.addStrLit(manifest, layoutFingerprint(typ, config))
    nifbuilder.addIdent(manifest,
      if isManaged(typ): "managed" else: "plain")
    if concrete != nil and tfPacked in concrete.flags:
      nifbuilder.addIdent(manifest, "packed")
    else:
      nifbuilder.addIdent(manifest, "unpacked")
    if concrete != nil and tfUnion in concrete.flags:
      nifbuilder.addIdent(manifest, "union")
    else:
      nifbuilder.addIdent(manifest, "regular")
    if concrete != nil and concrete.kind == tyObject and
        tfFinal notin concrete.flags:
      nifbuilder.addIdent(manifest, "inheritable")
    else:
      nifbuilder.addIdent(manifest, "final")
    if concrete != nil and concrete.kind == tyObject and
        concrete.baseClass != nil:
      nifbuilder.withTree(manifest, "base"):
        nifbuilder.addStrLit(manifest,
          typeSymbol(concrete.baseClass, config))
    if concrete != nil and concrete.kind in {tyObject, tyTuple}:
      nifbuilder.withTree(manifest, "record"):
        writeRecord(manifest, concrete.n, config)
    elif concrete != nil and concrete.kind == tyEnum:
      nifbuilder.withTree(manifest, "enum"):
        writeEnum(manifest, concrete.n)
    elif concrete != nil and concrete.sons.len > 0:
      nifbuilder.withTree(manifest, "element"):
        nifbuilder.addStrLit(manifest,
          typeSymbol(concrete.sons[^1], config))

proc openArrayLengthCount(typ: PType): int =
  result = 0
  var current = typ.skipTypes({tyGenericInst})
  if current.kind in {tyVar, tyLent, tySink}:
    current = current.elementType
  while current.kind in {tyOpenArray, tyVarargs}:
    inc result
    current = current.elementType.skipTypes({tySink})

proc parameterMode(param: PSym; returnType: PType;
                   config: ConfigRef): string =
  let typ = param.typ.skipTypes({tyGenericInst, tyAlias, tySink, tyOwned})
  if ccgIntroducedPtr(config, param, returnType):
    result = "indirect"
  elif typ.kind in {tyVar, tyLent, tyPtr, tyRef, tyPointer, tyArray,
      tyOpenArray, tyVarargs, tyUncheckedArray}:
    result = "pointer"
  else:
    result = "direct"

proc writeLowering(manifest: var nifbuilder.Builder; prc: PSym;
                   config: ConfigRef) =
  nifbuilder.withTree(manifest, "lowering"):
    nifbuilder.withTree(manifest, "callconv"):
      nifbuilder.addStrLit(manifest, $prc.typ.callConv)
    nifbuilder.withTree(manifest, "result"):
      nifbuilder.addStrLit(manifest, typeSymbol(prc.typ.returnType, config))
      nifbuilder.addIdent(manifest,
        if prc.typ.returnType == nil: "void"
        elif ccgAbiResultIsIndirect(config, prc.typ): "indirect"
        else: "direct")
    nifbuilder.withTree(manifest, "parameters"):
      for i in 1 ..< prc.typ.n.len:
        if prc.typ.n[i].kind != nkSym:
          continue
        let param = prc.typ.n[i].sym
        if param.typ.isCompileTimeOnly:
          continue
        nifbuilder.withTree(manifest, "parameter"):
          nifbuilder.addStrLit(manifest, param.name.s)
          nifbuilder.addStrLit(manifest, typeSymbol(param.typ, config))
          nifbuilder.addIdent(manifest,
            parameterMode(param, prc.typ.returnType, config))
          nifbuilder.addIntLit(manifest, openArrayLengthCount(param.typ))
    nifbuilder.withTree(manifest, "closureenv"):
      nifbuilder.addIdent(manifest,
        if prc.typ.callConv == ccClosure: "true" else: "false")
    nifbuilder.withTree(manifest, "varargs"):
      nifbuilder.addIdent(manifest,
        if tfVarargs in prc.typ.flags: "true" else: "false")

proc uniqueHooks(graph: ModuleGraph; config: ConfigRef): seq[AbiHook] =
  result = newSeqOfCap[AbiHook](graph.abiHooks.len)
  for hook in graph.abiHooks:
    result.add hook
  result.sort(proc(a, b: AbiHook): int =
    result = cmp(icNifTypeName(a.typ, config), icNifTypeName(b.typ, config))
    if result == 0:
      result = cmp(ord(a.op), ord(b.op)))
  var writeAt = 0
  for readAt in 0 ..< result.len:
    if writeAt == 0 or result[writeAt - 1].op != result[readAt].op or
        icNifTypeName(result[writeAt - 1].typ, config) !=
          icNifTypeName(result[readAt].typ, config):
      result[writeAt] = result[readAt]
      inc writeAt
  result.setLen(writeAt)

proc abiFingerprint(config: ConfigRef; types: seq[PType]; procs: seq[PSym];
                    hooks: seq[AbiHook]): string =
  var value = VersionAsString & ':' & $NimCompilerApiVersion & ':' &
    RodFileVersion & ':' & platform.OS[config.target.targetOS].name & ':' &
    platform.CPU[config.target.targetCPU].name & ':' & $config.selectedGC & ':' &
    nativeDynlibAllocator(config) & ':' & $config.exc & ':' &
    $config.selectedStrings & ':' &
    (if optThreads in config.globalOptions: "threads" else: "single") & ':' &
    config.nimMainPrefix & "NimMain\n"
  for typ in types:
    value.add typeSymbol(typ, config)
    value.add ':'
    value.add layoutFingerprint(typ, config)
    value.add '\n'
  for prc in procs:
    value.add globalName(prc, config)
    value.add ':'
    value.add $hashType(prc.typ, config)
    value.add '\n'
  for hook in hooks:
    value.add typeSymbol(hook.typ, config)
    value.add ':'
    value.add AttachedOpToStr[hook.op]
    value.add ':'
    value.add globalName(hook.hook, config)
    value.add '\n'
  result = $getMD5(value)

proc writeAbiManifest*(config: ConfigRef; graph: ModuleGraph;
                       exportedAbiProcs: seq[PSym]) =
  if config.cmd == cmdNifC:
    return

  let path = config.nimcacheDir /
    RelativeFile(config.projectName & ".abi.nif")
  if exportedAbiProcs.len == 0:
    discard tryRemoveFile(path.string)
    return

  let hooks = uniqueHooks(graph, config)

  var procs: seq[PSym] = @[]
  for prc in exportedAbiProcs:
    if sfOverridden notin prc.flags:
      procs.add prc
  procs.sort(proc(a, b: PSym): int =
    cmp(globalName(a, config), globalName(b, config)))

  var state = AbiManifestState(seenTypeIds: initIntSet())
  for prc in procs:
    state.collectProcTypes(prc)
  for item in hooks:
    state.collectType(item.typ)
    state.collectProcTypes(item.hook)
  state.types.sort(proc(a, b: PType): int =
    cmp(typeSymbol(a, config), typeSymbol(b, config)))
  var uniqueTypes: seq[PType] = @[]
  for typ in state.types:
    if uniqueTypes.len == 0 or
        typeSymbol(uniqueTypes[^1], config) != typeSymbol(typ, config):
      uniqueTypes.add typ
  state.types = move uniqueTypes

  var modules: seq[(string, string)] = @[]
  var seenModules = initHashSet[string]()
  proc addModule(sym: PSym) =
    let module = sym.getModule
    let identity = modname(module, config)
    if not seenModules.containsOrIncl(identity):
      modules.add (identity, module.name.s)
  for prc in procs:
    addModule(prc)
  for item in hooks:
    addModule(item.hook)
  for typ in state.types:
    if typ.sym != nil:
      addModule(typ.sym)
  modules.sort(proc(a, b: (string, string)): int = cmp(a[0], b[0]))

  var manifest = nifbuilder.open(
    path.string, writeMode = nifbuilder.OnlyIfChanged)
  nifbuilder.addHeader(manifest, "nim", "nim-native-dynlib")
  nifbuilder.withTree(manifest, "abi"):
    nifbuilder.withTree(manifest, "format"):
      nifbuilder.addIntLit(manifest, 4)
    nifbuilder.withTree(manifest, "abiid"):
      nifbuilder.addStrLit(manifest,
        abiFingerprint(config, state.types, procs, hooks))
    nifbuilder.withTree(manifest, "compiler"):
      nifbuilder.addStrLit(manifest, VersionAsString)
      nifbuilder.addIntLit(manifest, NimCompilerApiVersion)
      nifbuilder.addStrLit(manifest, RodFileVersion)
    nifbuilder.withTree(manifest, "target"):
      nifbuilder.addStrLit(manifest, platform.OS[config.target.targetOS].name)
      nifbuilder.addStrLit(manifest, platform.CPU[config.target.targetCPU].name)
      nifbuilder.addStrLit(manifest,
        $platform.CPU[config.target.targetCPU].endian)
      nifbuilder.addIntLit(manifest,
        platform.CPU[config.target.targetCPU].bit)
    nifbuilder.withTree(manifest, "runtime"):
      nifbuilder.addStrLit(manifest, $config.selectedGC)
      nifbuilder.addStrLit(manifest, nativeDynlibAllocator(config))
      nifbuilder.addStrLit(manifest, $config.exc)
      nifbuilder.addStrLit(manifest, $config.selectedStrings)
      nifbuilder.addIdent(manifest,
        if optThreads in config.globalOptions: "true" else: "false")
      nifbuilder.addStrLit(manifest, config.nimMainPrefix & "NimMain")
    nifbuilder.withTree(manifest, "library"):
      nifbuilder.addStrLit(manifest, config.outFile.string.extractFilename)
    nifbuilder.withTree(manifest, "modules"):
      for module in modules:
        nifbuilder.withTree(manifest, "module"):
          nifbuilder.addStrLit(manifest, module[0])
          nifbuilder.addStrLit(manifest, module[1])
    nifbuilder.withTree(manifest, "types"):
      for typ in state.types:
        writeType(manifest, typ, config)
    nifbuilder.withTree(manifest, "hooks"):
      for item in hooks:
        nifbuilder.withTree(manifest, "hook"):
          nifbuilder.addStrLit(manifest, icNifTypeName(item.typ, config))
          nifbuilder.addStrLit(manifest, AttachedOpToStr[item.op])
          nifbuilder.addStrLit(manifest, globalName(item.hook, config))
          if sfError in item.hook.flags:
            nifbuilder.addIdent(manifest, "forbidden")
            nifbuilder.addEmpty(manifest)
          else:
            nifbuilder.addIdent(manifest, "custom")
            nifbuilder.addStrLit(manifest,
              stripCnifMarks(item.hook.loc.snippet))
    nifbuilder.withTree(manifest, "procs"):
      for prc in procs:
        nifbuilder.withTree(manifest, "proc"):
          nifbuilder.addStrLit(manifest, globalName(prc, config))
          nifbuilder.addStrLit(manifest, prc.name.s)
          nifbuilder.addStrLit(manifest, stripCnifMarks(prc.loc.snippet))
          nifbuilder.addStrLit(manifest, $hashType(prc.typ, config))
          nifbuilder.addIdent(manifest,
            if sfFromGeneric in prc.flags: "true" else: "false")
          writeLowering(manifest, prc, config)
  nifbuilder.close(manifest)
