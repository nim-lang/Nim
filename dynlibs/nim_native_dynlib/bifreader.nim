import std/[json, os, strutils]
import ../../dist/nimony/src/lib/[bif, nifcore]
import model

type
  NativeBifError* = object of ValueError

proc fail(message: string) {.noinline, noreturn.} =
  raise newException(NativeBifError, message)

func tagName(c: Cursor): string {.inline.} =
  c.tags.tags[c.cursorTagId]

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
  let manifest = parseFile(manifestPath)
  if manifest["format"].getStr != "nim-native-dynlib-backend-v1":
    fail("unsupported native ABI backend manifest")

  result.compilerVersion = manifest["compilerVersion"].getStr
  result.targetOS = manifest["targetOS"].getStr
  result.targetCPU = manifest["targetCPU"].getStr
  result.memoryManager = manifest["memoryManager"].getStr
  result.allocator = manifest["allocator"].getStr

  var module = bif.load(bifPath)
  for entry in module.index:
    if entry.vis == ivExported:
      let nifSymbol = module.buf.pool.syms[entry.sym]
      let declaration = module.buf.cursorAt(entry.pos)
      if not findDirectTag(declaration, "type").cursorIsNil and
          not findDirectTag(declaration, "type0").cursorIsNil:
        let typ = parseNativeType(declaration, nifSymbol)
        result.types.add typ

  for item in manifest["procs"]:
    if item["genericInstance"].getBool:
      fail("concrete generic exports need signature materialization support: " &
        item["cSymbol"].getStr)
    let nifSymbol = item["nifSymbol"].getStr
    let declaration = findDeclaration(module, nifSymbol)
    if declaration.cursorIsNil:
      fail("semantic declaration not found for " & nifSymbol)
    result.procs.add parseNativeProc(
      declaration, nifSymbol, item["cSymbol"].getStr)

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
