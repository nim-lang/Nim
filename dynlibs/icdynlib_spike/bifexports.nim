import std/[json, os, sets, strutils]
import ../../dist/nimony/src/lib/[bif, nifcore]

type
  DynlibMetadataError* = object of ValueError

  DynlibParam* = object
    name*: string
    nimType*: string
    cType*: string

  DynlibExport* = object
    nimName*: string
    nifSymbol*: string
    externalName*: string
    returnNimType*: string
    returnCType*: string
    params*: seq[DynlibParam]

proc metadataError(message: string) {.noinline, noreturn.} =
  raise newException(DynlibMetadataError, message)

proc tagName(c: Cursor): string {.inline.} =
  c.tags.tags[c.cursorTagId]

proc scanExportMetadata(c: var Cursor; metadata: var string) =
  while c.hasMore:
    case c.kind
    of TagLit:
      c.into:
        scanExportMetadata(c, metadata)
    of StrLit:
      let value = c.strVal
      if value.startsWith("nimdynmeta:"):
        metadata = value["nimdynmeta:".len .. ^1]
      c.skip
    else:
      c.skip

proc parseMetadata(metadata, nifSymbol: string): DynlibExport =
  try:
    let node = parseJson(metadata)
    if node["version"].getInt != 1:
      metadataError("unsupported dynlib metadata version")
    result = DynlibExport(
      nimName: node["nimName"].getStr,
      nifSymbol: nifSymbol,
      externalName: node["externalName"].getStr,
      returnNimType: node["returnNimType"].getStr,
      returnCType: node["returnCType"].getStr)
    for param in node["params"]:
      result.params.add DynlibParam(
        name: param["name"].getStr,
        nimType: param["nimType"].getStr,
        cType: param["cType"].getStr)
  except DynlibMetadataError:
    raise
  except CatchableError as exc:
    metadataError("invalid dynlib metadata for " & nifSymbol & ": " & exc.msg)

proc firstSymbolDef(c: var Cursor): string =
  while c.hasMore:
    if result.len > 0:
      c.skip
    else:
      case c.kind
      of SymbolDef:
        result = c.symName
        c.skip
      of TagLit:
        c.into:
          result = firstSymbolDef(c)
      else:
        c.skip

proc collectExports(c: var Cursor; exports: var seq[DynlibExport];
                    seen: var HashSet[string]) =
  while c.hasMore:
    if c.kind == TagLit:
      if c.tagName == "sd":
        var declaration = c
        var nifSymbol = ""
        declaration.into:
          nifSymbol = firstSymbolDef(declaration)
        var marker = c
        var metadata = ""
        marker.into:
          scanExportMetadata(marker, metadata)
        if nifSymbol.len > 0 and metadata.len > 0:
          let item = parseMetadata(metadata, nifSymbol)
          if not seen.containsOrIncl(item.externalName):
            exports.add item
      c.into:
        collectExports(c, exports, seen)
    else:
      c.skip

proc readDynlibExports*(path: string): seq[DynlibExport] =
  ## Reads the exports created by `dynexport` from one IC semantic BIF.
  var module = bif.load(path)
  var cursor = module.buf.beginRead()
  var seen = initHashSet[string]()
  collectExports(cursor, result, seen)
  cursor.endRead()

proc scanModuleSource(c: var Cursor; source: var string) =
  while c.hasMore:
    if c.kind == TagLit:
      let isModuleSource = c.tagName == "modulesrc"
      c.into:
        while c.hasMore:
          if isModuleSource and source.len == 0 and c.kind == StrLit:
            source = c.strVal
            c.skip
          elif c.kind == TagLit:
            scanModuleSource(c, source)
          else:
            c.skip
    else:
      c.skip

proc readModuleSource*(path: string): string =
  ## Returns the source path recorded by one semantic BIF.
  var module = bif.load(path)
  var cursor = module.buf.beginRead()
  scanModuleSource(cursor, result)
  cursor.endRead()

proc findSemanticBif*(nimcacheDir, sourcePath: string): string =
  ## Finds the semantic BIF whose `modulesrc` record names `sourcePath`.
  let expected = normalizedPath(absolutePath(sourcePath))
  for path in walkFiles(nimcacheDir / "*.s.bif"):
    let candidate = readModuleSource(path)
    if candidate.len > 0 and normalizedPath(absolutePath(candidate)) == expected:
      return path
  raise newException(IOError, "semantic BIF not found for: " & sourcePath)
