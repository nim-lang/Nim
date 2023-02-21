import sem, cgen, passes, modulegraphs, ast, llstream, parser, msgs,
       lineinfos, reorder, options, semdata, cgendata

import std/[syncio, objectdollar]
import renderer


proc processImplicitImports(graph: ModuleGraph; implicits: seq[string], nodeKind: TNodeKind,
                      m: PSym, ctx: PContext, bModule: BModule, idgen: IdGenerator) =
  # XXX fixme this should actually be relative to the config file!
  let relativeTo = toFullPath(graph.config, m.info)
  for module in items(implicits):
    # implicit imports should not lead to a module importing itself
    if m.position != resolveMod(graph.config, module, relativeTo).int32:
      var importStmt = newNodeI(nodeKind, m.info)
      var str = newStrNode(nkStrLit, module)
      str.info = m.info
      importStmt.add str
      message(graph.config, importStmt.info, hintProcessingStmt, $idgen[])
      let semNode = semWithPContext(ctx, importStmt)
      if semNode == nil or processCodeGen(bModule, semNode) == nil:
        break


proc processSingleModule*(graph: ModuleGraph; module: PSym; idgen: IdGenerator;
                    stream: PLLStream): bool =
  if graph.stopCompile(): return true
  var
    p: Parser
    s: PLLStream
    fileIdx = module.fileIdx
    semNode: PNode
    codeGenNode: PNode
  prepareConfigNotes(graph, module)
  let ctx = preparePContext(graph, module, idgen)
  let bModule = setupBackendGen(graph, module, idgen)
  if stream == nil:
    let filename = toFullPathConsiderDirty(graph.config, fileIdx)
    s = llStreamOpen(filename, fmRead)
    if s == nil:
      rawMessage(graph.config, errCannotOpenFile, filename.string)
      return false
  else:
    s = stream

  when defined(nimsuggest):
    let filename = toFullPathConsiderDirty(graph.config, fileIdx).string
    msgs.setHash(graph.config, fileIdx, $sha1.secureHashFile(filename))

  while true:
    openParser(p, fileIdx, s, graph.cache, graph.config)

    if not belongsToStdlib(graph, module) or (belongsToStdlib(graph, module) and module.name.s == "distros"):
      # XXX what about caching? no processing then? what if I change the
      # modules to include between compilation runs? we'd need to track that
      # in ROD files. I think we should enable this feature only
      # for the interactive mode.
      if module.name.s != "nimscriptapi":
        processImplicitImports graph, graph.config.implicitImports, nkImportStmt, module, ctx, bModule, idgen
        processImplicitImports graph, graph.config.implicitIncludes, nkIncludeStmt, module, ctx, bModule, idgen

    checkFirstLineIndentation(p)
    while true:
      if graph.stopCompile(): break
      var n = parseTopLevelStmt(p)
      if n.kind == nkEmpty: break
      # read everything, no streaming possible
      var sl = newNodeI(nkStmtList, n.info)
      sl.add n
      while true:
        var n = parseTopLevelStmt(p)
        if n.kind == nkEmpty: break
        sl.add n
      if sfReorder in module.flags or codeReordering in graph.config.features:
        sl = reorder(graph, sl, module)
      message(graph.config, sl.info, hintProcessingStmt, $idgen[])
      semNode = semWithPContext(ctx, sl)
      codeGenNode = processCodeGen(bModule, semNode)

    closeParser(p)
    if s.kind != llsStdIn: break
  let finalNode = closePContext(graph, ctx, nil)
  discard finalCodeGen(graph, bModule, finalNode)
  if graph.config.backend notin {backendC, backendCpp, backendObjc}:
    # We only write rod files here if no C-like backend is active.
    # The C-like backends have been patched to support the IC mechanism.
    # They are responsible for closing the rod files. See `cbackend.nim`.
    closeRodFile(graph, module)
  result = true
