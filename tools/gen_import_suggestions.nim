# Auto-generates import suggestions for the Nim compiler
# Run from Nim repo root: nim c -r tools/gen_import_suggestions.nim

import std/[os, strutils, tables, sets, algorithm, sequtils]
import compiler/[ast, idents, options, lineinfos, pathutils,
                 llstream, parser, lexer, msgs]

proc extractExportedSymbols(moduleFile: AbsoluteFile, modulePath: string, cache: IdentCache, config: ConfigRef): seq[string] =
  ## Parse a module file and extract exported symbols from the AST
  result = @[]

  try:
    let fileIdx = fileInfoIdx(config, moduleFile)
    var stream = llStreamOpen(moduleFile, fmRead)
    if stream == nil:
      when defined(debugSuggestions):
        echo "  Skipped (cannot open): ", modulePath
      return

    var parser: Parser
    parser.lex.errorHandler = proc(conf: ConfigRef; info: TLineInfo; msg: TMsgKind; arg: string) =
      # Silently ignore parse errors
      discard

    openParser(parser, fileIdx, stream, cache, config)

    # Parse the module
    let moduleNode = parseAll(parser)
    closeParser(parser)

    # Walk the AST looking for exported symbols
    proc walkNode(n: PNode, symbols: var seq[string]) =
      if n == nil: return

      try:
        case n.kind
        of nkProcDef, nkFuncDef, nkMethodDef, nkConverterDef, nkIteratorDef:
          # Check if it has the * export marker
          if n.len > 0 and n[0].kind == nkPostfix:
            let name = n[0][1]
            if name.kind == nkIdent:
              let identName = name.ident.s
              if identName.len > 0 and not identName.startsWith("internal") and not identName.startsWith("`"):
                symbols.add identName

        of nkTypeDef:
          # Type definitions: check for export marker
          if n.len > 0 and n[0].kind == nkPostfix:
            let name = n[0][1]
            if name.kind == nkIdent:
              let identName = name.ident.s
              if identName.len > 0 and not identName.startsWith("internal"):
                symbols.add identName

        of nkConstDef, nkLetSection, nkVarSection:
          # Constants and variables with export marker
          for i in 0..<n.len:
            if n[i].kind == nkIdentDefs and n[i].len > 0:
              let nameNode = n[i][0]
              if nameNode.kind == nkPostfix:
                let name = nameNode[1]
                if name.kind == nkIdent:
                  let identName = name.ident.s
                  if identName.len > 0 and not identName.startsWith("internal"):
                    symbols.add identName

        else: discard

        # Recursively walk children (safely)
        if n.len > 0:
          for i in 0..<n.len:
            walkNode(n[i], symbols)
      except FieldDefect:
        # Some node kinds don't support .len, just skip them
        discard

    walkNode(moduleNode, result)

  except CatchableError as e:
    # Module failed to parse - skip it
    when defined(debugSuggestions):
      echo "  Skipped (parse error): ", modulePath, " - ", e.msg

proc getModulePath(filePath: string): string =
  # Convert "lib/std/os.nim" -> "std/os"
  # Convert "lib/pure/json.nim" -> "json"
  # Convert "lib/core/typeinfo.nim" -> "typeinfo"
  result = filePath
  result.removePrefix("lib/")
  result.removeSuffix(".nim")

  # For pure/impure/core, strip the directory since they're imported without it
  for prefix in ["pure/", "impure/", "core/"]:
    if result.startsWith(prefix):
      result.removePrefix(prefix)
      break

proc shouldIncludeModule(path: string): bool =
  # Skip unwanted modules
  if "private" in path: return false
  if "internal" in path: return false
  if "/test" in path or "tests/" in path: return false
  if "testament" in path: return false
  if "compiler/" in path: return false
  if "nimsuggest/" in path: return false

  let name = path.splitPath.tail
  if name == "system.nim": return false  # Always imported
  if name.startsWith("test"): return false

  return true

proc generateSuggestions*() =
  echo "Initializing..."
  let cache = newIdentCache()
  let config = newConfigRef()

  # Minimal config setup
  let nimRoot = getCurrentDir()
  config.libpath = AbsoluteDir(nimRoot / "lib")
  config.prefixDir = AbsoluteDir(nimRoot)

  echo "Scanning lib/ directory..."
  let libPath = getCurrentDir() / "lib"

  var symbolMap: Table[string, seq[string]]  # symbol -> list of modules
  var moduleCount = 0
  var totalSymbols = 0

  for path in walkDirRec(libPath, {pcFile}):
    if not path.endsWith(".nim"): continue
    if not shouldIncludeModule(path): continue

    let relativePath = path.relativePath(getCurrentDir())
    let modulePath = getModulePath(relativePath)
    let absPath = AbsoluteFile(path)

    inc moduleCount
    if moduleCount mod 20 == 0:
      echo "  Processed ", moduleCount, " modules..."

    let symbols = extractExportedSymbols(absPath, modulePath, cache, config)

    for symName in symbols:
      inc totalSymbols

      if symName notin symbolMap:
        symbolMap[symName] = @[]

      # Add module if not already present
      if modulePath notin symbolMap[symName]:
        symbolMap[symName].add modulePath

  echo "Found ", symbolMap.len, " unique symbols from ", moduleCount, " modules"
  echo "Total symbol exports: ", totalSymbols

  # Count symbols in multiple modules
  var multiModuleCount = 0
  for modules in symbolMap.values:
    if modules.len > 1:
      inc multiModuleCount
  echo "Symbols in multiple modules: ", multiModuleCount

  # Generate output file
  echo "Generating compiler/suggest_imports.nim..."

  var output = """# Auto-generated by tools/gen_import_suggestions.nim
# Run from Nim repo root: nim c -r tools/gen_import_suggestions.nim
# Do not edit manually

import std/tables

const importSuggestions* = {
"""

  # Sort for deterministic output
  var sortedSymbols = toSeq(symbolMap.pairs)
  sortedSymbols.sort(proc (a, b: auto): int = cmp(a[0], b[0]))

  for (name, modules) in sortedSymbols:
    # Escape the symbol name
    let escapedName = name.multiReplace([("\\", "\\\\"), ("\"", "\\\"")])

    # Format module list
    output.add "  \"$#\": @[" % escapedName
    for i, module in modules:
      let escapedModule = module.multiReplace([("\\", "\\\\"), ("\"", "\\\"")])
      if i > 0:
        output.add ", "
      output.add "\"$#\"" % escapedModule
    output.add "],\n"

  output.add "}.toTable\n"

  writeFile("compiler/suggest_imports.nim", output)

  let fileSize = getFileSize("compiler/suggest_imports.nim")
  echo "Done! Generated compiler/suggest_imports.nim"
  echo "  File size: ", (fileSize div 1024), " KB"

when isMainModule:
  generateSuggestions()
