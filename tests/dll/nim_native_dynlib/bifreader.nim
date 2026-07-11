import std/[os, strutils]
import ../../../dist/nimony/src/lib/[bif, nifcoreparse]
import model

type
  NativeBifError* = object of ValueError

  AbiProcEntry = object
    nifSymbol: string
    nimName: string
    cSymbol: string
    signatureFingerprint: string
    genericInstance: bool

  AbiHookEntry = object
    typeSymbol: string
    kind: string
    nifSymbol: string
    cSymbol: string
    status: NativeHookStatus

  AbiManifest = object
    formatVersion: int64
    libraryName: string
    compilerVersion: string
    targetOS: string
    targetCPU: string
    memoryManager: string
    allocator: string
    modules: seq[NativeModule]
    hooks: seq[AbiHookEntry]
    procs: seq[AbiProcEntry]

proc fail(message: string) {.noinline, noreturn.} =
  raise newException(NativeBifError, message)

func tagName(c: Cursor): string {.inline.} =
  c.tags.tags[c.cursorTagId]

proc readStrings(node: Cursor; field: string; count: int): seq[string] =
  var children = node.childCursor()
  while children.hasMore:
    if children.kind == StrLit:
      result.add children.strVal
    else:
      fail("native ABI manifest " & field & " has an invalid field")
    children.skip
  if result.len != count:
    fail("native ABI manifest " & field & " expects " & $count &
      " string value(s)")

proc parseAbiProc(node: Cursor): AbiProcEntry =
  var values: seq[string] = @[]
  var hasGenericInstance = false
  var children = node.childCursor()
  while children.hasMore:
    case children.kind
    of StrLit:
      values.add children.strVal
    of Ident:
      if hasGenericInstance:
        fail("native ABI manifest proc has duplicate generic flag")
      case children.strVal
      of "true": result.genericInstance = true
      of "false": result.genericInstance = false
      else: fail("native ABI manifest proc has invalid generic flag")
      hasGenericInstance = true
    else:
      fail("native ABI manifest proc has an invalid field")
    children.skip

  if values.len != 4 or not hasGenericInstance:
    fail("native ABI manifest proc has an invalid shape")
  result.nifSymbol = values[0]
  result.nimName = values[1]
  result.cSymbol = values[2]
  result.signatureFingerprint = values[3]

proc parseAbiProcs(node: Cursor): seq[AbiProcEntry] =
  var children = node.childCursor()
  while children.hasMore:
    if children.kind == TagLit and children.tagName == "proc":
      result.add parseAbiProc(children)
    elif children.kind != DotToken:
      fail("native ABI manifest procs contains an invalid entry")
    children.skip

proc parseAbiHook(node: Cursor): AbiHookEntry =
  var values: seq[string] = @[]
  var hasStatus = false
  var children = node.childCursor()
  while children.hasMore:
    case children.kind
    of StrLit:
      values.add children.strVal
    of Ident:
      if hasStatus:
        fail("native ABI manifest hook has duplicate status")
      case children.strVal
      of "custom": result.status = nhCustom
      of "forbidden": result.status = nhForbidden
      else: fail("native ABI manifest hook has invalid status")
      hasStatus = true
    of DotToken:
      discard
    else:
      fail("native ABI manifest hook has an invalid field")
    children.skip

  if not hasStatus or values.len notin {3, 4}:
    fail("native ABI manifest hook has an invalid shape")
  result.typeSymbol = values[0]
  result.kind = values[1]
  result.nifSymbol = values[2]
  if result.status == nhCustom:
    if values.len != 4:
      fail("custom native ABI hook has no linker symbol")
    result.cSymbol = values[3]
  elif values.len != 3:
    fail("forbidden native ABI hook has a linker symbol")

proc parseAbiHooks(node: Cursor): seq[AbiHookEntry] =
  var children = node.childCursor()
  while children.hasMore:
    if children.kind == TagLit and children.tagName == "hook":
      result.add parseAbiHook(children)
    elif children.kind != DotToken:
      fail("native ABI manifest hooks contains an invalid entry")
    children.skip

proc parseAbiModules(node: Cursor): seq[NativeModule] =
  var children = node.childCursor()
  while children.hasMore:
    if children.kind == TagLit and children.tagName == "module":
      let values = readStrings(children, "module", 2)
      result.add NativeModule(identity: values[0], name: values[1])
    elif children.kind != DotToken:
      fail("native ABI manifest modules contains an invalid entry")
    children.skip

proc readAbiManifest(path: string): AbiManifest =
  var manifest = nifcoreparse.parseFromFile(path)
  var cursor = manifest.beginRead()
  if cursor.kind != TagLit or cursor.tagName != "abi":
    fail("native ABI manifest has no abi root")

  result.formatVersion = -1
  cursor.loopInto:
    if cursor.kind == TagLit:
      case cursor.tagName
      of "format":
        var values = cursor.childCursor()
        if not values.hasMore or values.kind != IntLit:
          fail("native ABI manifest has no format version")
        result.formatVersion = values.intVal
        values.skip
        if values.hasMore:
          fail("native ABI manifest format has extra fields")
      of "compiler":
        result.compilerVersion = readStrings(cursor, "compiler", 1)[0]
      of "target":
        let values = readStrings(cursor, "target", 2)
        result.targetOS = values[0]
        result.targetCPU = values[1]
      of "memorymanager":
        result.memoryManager = readStrings(cursor, "memorymanager", 1)[0]
      of "allocator":
        result.allocator = readStrings(cursor, "allocator", 1)[0]
      of "library":
        result.libraryName = readStrings(cursor, "library", 1)[0]
      of "modules":
        result.modules = parseAbiModules(cursor)
      of "hooks":
        result.hooks = parseAbiHooks(cursor)
      of "procs":
        result.procs = parseAbiProcs(cursor)
      else:
        discard
    cursor.skip
  cursor.endRead()

  if result.formatVersion != 3:
    fail("unsupported native ABI manifest format")
  if result.compilerVersion.len == 0 or result.targetOS.len == 0 or
      result.targetCPU.len == 0 or result.memoryManager.len == 0 or
      result.allocator.len == 0 or result.libraryName.len == 0 or
      result.modules.len == 0:
    fail("native ABI manifest is missing target metadata")

func symbolBase(symbol: string): string =
  let dot = symbol.find('.')
  if dot < 0: symbol
  else: symbol[0 ..< dot]

proc findDirectTag(node: Cursor; name: string): Cursor =
  var children = node.childCursor()
  while children.hasMore:
    if children.kind == TagLit and children.tagName == name:
      return children
    children.skip

proc findTag(node: Cursor; name: string): Cursor =
  var children = node.childCursor()
  while children.hasMore:
    if children.kind == TagLit:
      if children.tagName == name:
        return children
      let nested = findTag(children, name)
      if not nested.cursorIsNil:
        return nested
    children.skip

proc firstDirectSymbol(node: Cursor): string =
  var children = node.childCursor()
  while children.hasMore:
    if children.kind == Symbol:
      return children.symName
    children.skip

proc lastDirectSymbol(node: Cursor): string =
  var children = node.childCursor()
  while children.hasMore:
    if children.kind == Symbol:
      result = children.symName
    children.skip

proc firstSymbolDef(node: Cursor): string =
  var children = node.childCursor()
  while children.hasMore:
    if children.kind == SymbolDef:
      return children.symName
    children.skip

proc identifier(node: Cursor): string =
  var children = node.childCursor()
  while children.hasMore:
    if children.kind == Ident:
      result = children.strVal
    children.skip

proc fieldName(node: Cursor): tuple[name: string, exported: bool] =
  if node.kind != TagLit:
    return
  if node.tagName == "ident":
    result.name = identifier(node)
  elif node.tagName == "postfix":
    var children = node.childCursor()
    while children.hasMore:
      if children.kind == TagLit and children.tagName == "ident":
        let value = identifier(children)
        if value == "*":
          result.exported = true
        elif value.len > 0:
          result.name = value
      children.skip

proc parseFields(objectType: Cursor): seq[NativeField] =
  let fields = findDirectTag(objectType, "reclist")
  if fields.cursorIsNil:
    return

  var children = fields.childCursor()
  while children.hasMore:
    if children.kind == TagLit and children.tagName == "identdefs":
      var names: seq[tuple[name: string, exported: bool]] = @[]
      var typeSymbol = ""
      var parts = children.childCursor()
      while parts.hasMore:
        if parts.kind == TagLit and typeSymbol.len == 0:
          let field = fieldName(parts)
          if field.name.len > 0:
            names.add field
        elif parts.kind == Symbol and typeSymbol.len == 0:
          typeSymbol = parts.symName
        parts.skip
      if typeSymbol.len == 0:
        fail("native ABI field has no resolved type")
      for name in names:
        result.add NativeField(
          name: name.name,
          typeSymbol: typeSymbol,
          exported: name.exported)
    elif children.kind == TagLit and children.tagName != "empty":
      fail("native ABI does not support variant object fields")
    children.skip

proc validateObjectBase(objectType: Cursor; typeName: string) =
  var children = objectType.childCursor()
  if children.hasMore:
    children.skip # expression flags
  if children.hasMore:
    children.skip # resolved object type
  if children.hasMore and
      not (children.kind == TagLit and children.tagName == "empty"):
    fail("native ABI does not support object inheritance: " & typeName)

proc parseNativeType(declaration: Cursor; nifSymbol: string): NativeType =
  let sourceType = findDirectTag(declaration, "type0")
  if sourceType.cursorIsNil:
    fail("missing source type declaration for " & nifSymbol)

  let refType = findDirectTag(sourceType, "refty")
  let objectType = findDirectTag(sourceType, "objectty")
  result.name = symbolBase(nifSymbol)
  result.nifSymbol = nifSymbol
  let typeDesc = findTag(declaration, "td")
  result.typeId = firstSymbolDef(typeDesc)
  if result.typeId.len == 0:
    fail("missing resolved type id for " & nifSymbol)
  if not refType.cursorIsNil:
    let payload = findDirectTag(refType, "objectty")
    if payload.cursorIsNil:
      fail("native ABI only supports ref object types: " & result.name)
    result.kind = ntRefObject
    validateObjectBase(payload, result.name)
    result.fields = parseFields(payload)
  elif not objectType.cursorIsNil:
    result.kind = ntObject
    validateObjectBase(objectType, result.name)
    result.fields = parseFields(objectType)
  else:
    fail("native ABI only supports object and ref object types: " & result.name)

proc parseParam(declaration: Cursor): NativeParam =
  result.name = symbolBase(firstSymbolDef(declaration))
  let metadata = findDirectTag(declaration, "param")
  if metadata.cursorIsNil:
    fail("missing parameter metadata for " & result.name)
  let typeDesc = findDirectTag(declaration, "td")
  if not typeDesc.cursorIsNil:
    let typeId = firstSymbolDef(typeDesc)
    if typeId.startsWith("`t23."):
      result.byVar = true
      result.typeSymbol = lastDirectSymbol(typeDesc)
    else:
      fail("native ABI does not support parameter type: " & typeId)
  else:
    result.typeSymbol = firstDirectSymbol(declaration)
  if result.typeSymbol.len == 0:
    fail("native ABI only supports value parameters: " & result.name)

proc findFormalParams(declaration: Cursor): Cursor =
  result = findTag(declaration, "formalparams")

proc parseNativeProc(declaration: Cursor; nifSymbol, cSymbol: string): NativeProc =
  result.name = symbolBase(nifSymbol)
  result.nifSymbol = nifSymbol
  result.cSymbol = cSymbol
  let formals = findFormalParams(declaration)
  if formals.cursorIsNil:
    fail("missing resolved signature for " & nifSymbol)

  var children = formals.childCursor()
  if children.hasMore:
    children.skip # expression flags
  if children.hasMore:
    if children.kind == Symbol:
      result.returnTypeSymbol = children.symName
    children.skip
  while children.hasMore:
    if children.kind == TagLit and children.tagName == "sd":
      let metadata = findDirectTag(children, "param")
      if not metadata.cursorIsNil:
        result.params.add parseParam(children)
    children.skip

proc findDeclaration(module: var BifModule; nifSymbol: string): Cursor =
  for entry in module.index:
    if module.buf.pool.syms[entry.sym] == nifSymbol:
      return module.buf.cursorAt(entry.pos)

proc readNativeApi*(bifPath, manifestPath: string): NativeApi =
  let manifest = readAbiManifest(manifestPath)
  result.libraryName = manifest.libraryName
  result.compilerVersion = manifest.compilerVersion
  result.targetOS = manifest.targetOS
  result.targetCPU = manifest.targetCPU
  result.memoryManager = manifest.memoryManager
  result.allocator = manifest.allocator
  result.modules = manifest.modules

  var module = bif.load(bifPath)
  for entry in module.index:
    if entry.vis == ivExported:
      let nifSymbol = module.buf.pool.syms[entry.sym]
      let declaration = module.buf.cursorAt(entry.pos)
      if not findDirectTag(declaration, "type").cursorIsNil and
          not findDirectTag(declaration, "type0").cursorIsNil:
        let typ = parseNativeType(declaration, nifSymbol)
        result.types.add typ

  for item in manifest.procs:
    if item.genericInstance:
      fail("concrete generic exports need signature materialization support: " &
        item.cSymbol)
    let nifSymbol = item.nifSymbol
    let declaration = findDeclaration(module, nifSymbol)
    if declaration.cursorIsNil:
      fail("semantic declaration not found for " & nifSymbol)
    result.procs.add parseNativeProc(
      declaration, nifSymbol, item.cSymbol)

  for item in manifest.hooks:
    let declaration = findDeclaration(module, item.nifSymbol)
    if declaration.cursorIsNil:
      fail("semantic hook declaration not found for " & item.nifSymbol)
    result.hooks.add NativeHook(
      typeSymbol: item.typeSymbol,
      kind: item.kind,
      status: item.status,
      procInfo: parseNativeProc(
        declaration, item.nifSymbol, item.cSymbol))

proc scanModuleSource(cursor: var Cursor; source: var string) =
  while cursor.hasMore:
    if cursor.kind == TagLit:
      let isModuleSource = cursor.tagName == "modulesrc"
      cursor.into:
        while cursor.hasMore:
          if isModuleSource and source.len == 0 and cursor.kind == StrLit:
            source = cursor.strVal
            cursor.skip
          elif cursor.kind == TagLit:
            scanModuleSource(cursor, source)
          else:
            cursor.skip
    else:
      cursor.skip

proc readModuleSource*(path: string): string =
  var module = bif.load(path)
  var cursor = module.buf.beginRead()
  scanModuleSource(cursor, result)
  cursor.endRead()

proc findSemanticBif*(nimcacheDir, sourcePath: string): string =
  let expected = normalizedPath(absolutePath(sourcePath))
  for path in walkFiles(nimcacheDir / "*.s.bif"):
    let candidate = readModuleSource(path)
    if candidate.len > 0 and
        normalizedPath(absolutePath(candidate)) == expected:
      return path
  raise newException(IOError, "semantic BIF not found for: " & sourcePath)
