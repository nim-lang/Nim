import sem, cgen, modulegraphs, ast, llstream, parser, msgs,
       lineinfos, reorder, options, semdata, cgendata, modules, pathutils,
       packages, syntaxes, depends, vm, pragmas, idents, lookups, wordrecg,
       liftdestructors, nifgen

when not defined(nimKochBootstrap):
  import vmdef
  import ast2nif
  import "../dist/nimony/src/lib" / [nifstreams, bitabs]

import pipelineutils

import ../dist/checksums/src/checksums/sha1

when not defined(leanCompiler):
  import jsgen, docgen2

import std/[syncio, objectdollar, assertions, tables, strutils, strtabs, sets, intsets]
import renderer
import ic/replayer

proc setPipeLinePass*(graph: ModuleGraph; pass: PipelinePass) =
  graph.pipelinePass = pass

proc processPipeline(graph: ModuleGraph; semNode: PNode; bModule: PPassContext): PNode =
  case graph.pipelinePass
  of CgenPass:
    result = semNode
    if bModule != nil:
      genTopLevelStmt(BModule(bModule), result)
  of NifgenPass:
    result = semNode
    if bModule != nil:
      genTopLevelNif(bModule, result)
  of JSgenPass:
    when not defined(leanCompiler):
      result = processJSCodeGen(bModule, semNode)
    else:
      result = nil
  of GenDependPass:
    result = addDotDependency(bModule, semNode)
  of SemPass:
    # Return the semantic node for cmdM (NIF generation needs it)
    # For regular check, we don't need the result
    if graph.config.cmd == cmdM:
      result = semNode
    else:
      result = graph.emptyNode
  of Docgen2Pass, Docgen2TexPass:
    when not defined(leanCompiler):
      result = processNode(bModule, semNode)
    else:
      result = nil
  of Docgen2JsonPass:
    when not defined(leanCompiler):
      result = processNodeJson(bModule, semNode)
    else:
      result = nil
  of EvalPass, InterpreterPass:
    result = interpreterCode(bModule, semNode)
  of NonePass:
    raiseAssert "use setPipeLinePass to set a proper PipelinePass"

proc processImplicitImports*(graph: ModuleGraph; implicits: seq[string], nodeKind: TNodeKind,
                             m: PSym, ctx: PContext, bModule: PPassContext, idgen: IdGenerator;
                             topLevelStmts: PNode) =
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
      if semNode == nil:
        break
      let top = processPipeline(graph, semNode, bModule)
      if top == nil:
        break
      if topLevelStmts != nil:
        topLevelStmts.add top

proc prePass*(c: PContext; n: PNode) =
  for son in n:
    if son.kind == nkPragma:
      for s in son:
        var key = if s.kind in nkPragmaCallKinds and s.len > 1: s[0] else: s
        if key.kind in {nkBracketExpr, nkCast} or key.kind notin nkIdentKinds:
          continue
        let ident = whichKeyword(considerQuotedIdent(c, key))
        case ident
        of wReorder:
          pragmaNoForward(c, s, flag = sfReorder)
        of wExperimental:
          if isTopLevel(c) and s.kind in nkPragmaCallKinds and s.len == 2:
            let name = c.semConstExpr(c, s[1])
            case name.kind
            of nkStrLit, nkRStrLit, nkTripleStrLit:
              try:
                let feature = parseEnum[Feature](name.strVal)
                if feature == codeReordering:
                  c.features.incl feature
                  c.module.incl sfReorder
              except ValueError:
                discard
            else:
              discard
        else:
          discard

proc processPipelineModule*(graph: ModuleGraph; module: PSym; idgen: IdGenerator;
                    stream: PLLStream): bool =
  if graph.stopCompile(): return true
  var
    p: Parser = default(Parser)
    s: PLLStream
    fileIdx = module.fileIdx

  prepareConfigNotes(graph, module)
  let ctx = preparePContext(graph, module, idgen)
  let bModule: PPassContext =
    case graph.pipelinePass
    of CgenPass:
      setupCgen(graph, module, idgen)
    of JSgenPass:
      when not defined(leanCompiler):
        setupJSgen(graph, module, idgen)
      else:
        nil
    of EvalPass, InterpreterPass:
      setupEvalGen(graph, module, idgen)
    of GenDependPass:
      setupDependPass(graph, module, idgen)
    of Docgen2Pass:
      when not defined(leanCompiler):
        openHtml(graph, module, idgen)
      else:
        nil
    of Docgen2TexPass:
      when not defined(leanCompiler):
        openTex(graph, module, idgen)
      else:
        nil
    of Docgen2JsonPass:
      when not defined(leanCompiler):
        openJson(graph, module, idgen)
      else:
        nil
    of SemPass:
      nil
    of NifgenPass:
      setupNifgen(graph, module, idgen)
    of NonePass:
      raiseAssert "use setPipeLinePass to set a proper PipelinePass"

  if stream == nil:
    let filename = toFullPathConsiderDirty(graph.config, fileIdx)
    s = llStreamOpen(filename, fmRead)
    if s == nil:
      rawMessage(graph.config, errCannotOpenFile, filename.string)
      return false
    graph.interactive = false
  else:
    s = stream
    graph.interactive = stream.kind == llsStdIn
  var topLevelStmts =
    if optCompress in graph.config.globalOptions or graph.config.cmd == cmdM:
      newNodeI(nkStmtList, module.info)
    else:
      nil
  while true:
    syntaxes.openParser(p, fileIdx, s, graph.cache, graph.config)

    if not belongsToStdlib(graph, module) or (belongsToStdlib(graph, module) and module.name.s == "distros"):
      # XXX what about caching? no processing then? what if I change the
      # modules to include between compilation runs? we'd need to track that
      # in ROD files. I think we should enable this feature only
      # for the interactive mode.
      if module.name.s != "nimscriptapi":
        processImplicitImports graph, graph.config.implicitImports, nkImportStmt, module, ctx, bModule, idgen, topLevelStmts
        processImplicitImports graph, graph.config.implicitIncludes, nkIncludeStmt, module, ctx, bModule, idgen, topLevelStmts

    checkFirstLineIndentation(p)
    block processCode:
      if graph.stopCompile(): break processCode
      var n = parseTopLevelStmt(p)
      if n.kind == nkEmpty: break processCode
      # read everything, no streaming possible
      var sl = newNodeI(nkStmtList, n.info)
      sl.add n
      while true:
        var n = parseTopLevelStmt(p)
        if n.kind == nkEmpty: break
        sl.add n

      prePass(ctx, sl)
      if sfReorder in module.flags or codeReordering in graph.config.features:
        sl = reorder(graph, sl, module)
      if graph.pipelinePass != EvalPass:
        message(graph.config, sl.info, hintProcessingStmt, $idgen[])
      var semNode = semWithPContext(ctx, sl)
      let top = processPipeline(graph, semNode, bModule)
      if top != nil and topLevelStmts != nil:
        topLevelStmts.add top

    closeParser(p)
    if s.kind != llsStdIn: break
  let finalNode = closePContext(graph, ctx, nil)
  case graph.pipelinePass
  of CgenPass:
    if bModule != nil:
      let m = BModule(bModule)
      finalCodegenActions(graph, m, finalNode)
      if graph.dispatchers.len > 0:
        let ctx = preparePContext(graph, module, idgen)
        for disp in getDispatchers(graph):
          let retTyp = disp.typ.returnType
          if retTyp != nil:
            # TODO: properly semcheck the code of dispatcher?
            createTypeBoundOps(graph, ctx, retTyp, disp.ast.info, idgen)
          genProcLvl3(m, disp)
        discard closePContext(graph, ctx, nil)
  of JSgenPass:
    when not defined(leanCompiler):
      discard finalJSCodeGen(graph, bModule, finalNode)
  of EvalPass, InterpreterPass:
    discard interpreterCode(bModule, finalNode)
  of SemPass, GenDependPass:
    discard
  of Docgen2Pass, Docgen2TexPass:
    when not defined(leanCompiler):
      discard closeDoc(graph, bModule, finalNode)
  of Docgen2JsonPass:
    when not defined(leanCompiler):
      discard closeJson(graph, bModule, finalNode)
  of NifgenPass:
    closeNif(graph, bModule, finalNode)
  of NonePass:
    raiseAssert "use setPipeLinePass to set a proper PipelinePass"

  when not defined(nimKochBootstrap):
    # For cmdM: only write NIF for the main module, not for imported modules
    # (imported modules should be loaded from existing NIF files). Members of the
    # current strongly-connected import group (`--icGroup`) are the exception:
    # they are compiled from source here, so each must write its own NIF.
    let shouldWriteNif = (optCompress in graph.config.globalOptions) or
                         (graph.config.cmd == cmdM and
                          (sfMainModule in module.flags or
                           (graph.config.icGroup.len > 0 and
                            toFullPath(graph.config, module.position.FileIndex) in graph.config.icGroup)))
    if shouldWriteNif and not graph.config.isDefined("nimscript"):
      topLevelStmts.add finalNode
      # Collect replay actions from both pragma computations and VM state diff
      var replayActions: seq[PNode] = @[]
      # Get pragma-recorded replay actions (compile, link, passC, passL, etc.)
      if graph.nifReplayActions.hasKey(module.position.int32):
        replayActions.add graph.nifReplayActions[module.position.int32]
      # Also get VM state diff (macro cache operations)
      if graph.vm != nil:
        for (m, n) in PCtx(graph.vm).vmstateDiff:
          if m == module:
            replayActions.add n

      # NeedsImpl edge recording: which modules' bodies this process consumed
      # at compile time (VM/getImpl). For an --icGroup cycle every member gets
      # the union; intra-group entries are filtered by the writer.
      var implDeps: seq[int] = @[]
      for id in graph.icImplDeps: implDeps.add id
      writeNifModule(graph.config, module.position.int32, topLevelStmts, graph.opsLog,
                     replayActions, implDeps, reexportedModuleSyms(graph, module))
      # The module's REAL direct imports (incl. macro-generated) for `nim ic`'s
      # graph re-derivation; see ast2nif.writeSemDeps / semdata.addImportFileDep.
      var semDepPaths: seq[string] = @[]
      for f in graph.importDeps.getOrDefault(module.position.FileIndex, @[]):
        semDepPaths.add toFullPath(graph.config, f)
      writeSemDeps(graph.config, module.position.int32, semDepPaths)

  result = true

proc compilePipelineModule*(graph: ModuleGraph; fileIdx: FileIndex; flags: TSymFlags; fromModule: PSym = nil): PSym =
  var flags = flags
  if fileIdx == graph.config.projectMainIdx2: flags.incl sfMainModule
  result = graph.getModule(fileIdx)

  template processModuleAux(moduleStatus) =
    onProcessing(graph, fileIdx, moduleStatus, fromModule = fromModule)
    var s: PLLStream = nil
    if sfMainModule in flags:
      if graph.config.projectIsStdin: s = stdin.llStreamOpen
      elif graph.config.projectIsCmd: s = llStreamOpen(graph.config.cmdInput)
    discard processPipelineModule(graph, result, idGeneratorFromModule(result), s)
  if result == nil:
    when not defined(nimKochBootstrap):
      # For cmdM: load imports from NIF files (but compile the main module from source)
      # Skip when withinSystem is true (compiling system.nim itself).
      # Also skip for members of the current strongly-connected import group
      # (`--icGroup`): those are mutually recursive with the main module and have
      # no precompiled NIF yet, so they must be compiled from source in this same
      # process (falling through below) — that resolves the cycle in-memory, the
      # same way the non-incremental compiler handles recursive module imports.
      if graph.config.cmd == cmdM and
         sfMainModule notin flags and
         not graph.withinSystem and
         not graph.config.isDefined("nimscript") and
         (graph.config.icGroup.len == 0 or
          toFullPath(graph.config, fileIdx) notin graph.config.icGroup):
        let precomp = moduleFromNifFile(graph, fileIdx)
        if precomp.module == nil:
          let nifPath = toNifFilename(graph.config, fileIdx)
          # Macro-generated imports (e.g. chronicles' parseStmt("import
          # chronicles/textlines") driven by the chronicles_sinks define) are
          # invisible to the static scanner, so this module's NIF was never
          # built. The importer already recorded this import via
          # addImportFileDep, so flush every module's `.s.deps`: `nim ic` reads
          # it, re-derives the graph with the missing node + edge, and reruns
          # the frontend. We still error — this process cannot finish sem
          # without the import — but the discovery is structured data now, not
          # a side-channel file.
          for importer, deps in graph.importDeps.pairs:
            var paths: seq[string] = @[]
            for f in deps: paths.add toFullPath(graph.config, f)
            writeSemDeps(graph.config, importer.int32, paths)
          globalError(graph.config, unknownLineInfo,
            "nim m requires precompiled NIF for import: " & toFullPath(graph.config, fileIdx) &
            " (expected: " & nifPath & ")")
          return nil  # Don't fall through to compile from source
        else:
          # Module successfully loaded from NIF file - use it and skip processing
          result = precomp.module
          if sfSystemModule in flags:
            graph.systemModule = result
          partialInitModule(result, graph, fileIdx, AbsoluteFile(toFullPath(graph.config, fileIdx)))
          # Replay state changes from the loaded NIF module
          if result.ast != nil:
            replayStateChanges(result, graph)
          return result  # Return early, don't process from source
    let path = toFullPath(graph.config, fileIdx)
    let filename = AbsoluteFile path
    # it could be a stdinfile/cmdfile
    if fileExists(filename) and not graph.config.projectIsStdin:
      graph.cachedFiles[path] = $secureHashFile(path)
    if result == nil:
      result = newModule(graph, fileIdx)
      result.incl flags
      registerModule(graph, result)
      processModuleAux("import")
    else:
      if sfSystemModule in flags:
        graph.systemModule = result
      if sfMainModule in flags and graph.config.cmd == cmdM:
        result.incl flags
        registerModule(graph, result)
        processModuleAux("import")
      partialInitModule(result, graph, fileIdx, filename)
  elif graph.isDirty(result):
    result.excl sfDirty
    # reset module fields:
    initStrTables(graph, result)
    result.ast = nil
    processModuleAux("import(dirty)")
    graph.markClientsDirty(fileIdx)

proc importPipelineModule(graph: ModuleGraph; s: PSym, fileIdx: FileIndex): PSym =
  # this is called by the semantic checking phase
  assert graph.config != nil
  result = compilePipelineModule(graph, fileIdx, {}, s)
  graph.addDep(s, fileIdx)
  # keep track of import relationships
  if graph.config.hcrOn:
    graph.importDeps.mgetOrPut(FileIndex(s.position), @[]).add(fileIdx)
  #if sfSystemModule in result.flags:
  #  localError(result.info, errAttemptToRedefine, result.name.s)
  # restore the notes for outer module:
  graph.config.notes =
    if graph.config.belongsToProjectPackage(s) or isDefined(graph.config, "booting"): graph.config.mainPackageNotes
    else: graph.config.foreignPackageNotes

proc connectPipelineCallbacks*(graph: ModuleGraph) =
  graph.includeFileCallback = modules.includeModule
  graph.importModuleCallback = importPipelineModule

proc compilePipelineSystemModule*(graph: ModuleGraph) =
  if graph.systemModule == nil:
    graph.withinSystem = true
    connectPipelineCallbacks(graph)
    graph.config.m.systemFileIdx = fileInfoIdx(graph.config,
        graph.config.libpath / RelativeFile"system.nim")
    discard graph.compilePipelineModule(graph.config.m.systemFileIdx, {sfSystemModule})
    graph.withinSystem = false

proc compilePipelineProject*(graph: ModuleGraph; projectFileIdx = InvalidFileIdx) =
  connectPipelineCallbacks(graph)
  let conf = graph.config
  wantMainModule(conf)
  configComplete(graph)

  let systemFileIdx = fileInfoIdx(conf, conf.libpath / RelativeFile"system.nim")
  let projectFile = if projectFileIdx == InvalidFileIdx: conf.projectMainIdx else: projectFileIdx
  conf.projectMainIdx2 = projectFile

  var packSym = getPackage(graph, projectFile)
  if graph.config.cmd in {cmdM, cmdNifC} and graph.config.icProject.len > 0:
    # per-module IC children: the process' project file is the MODULE being
    # compiled, which would make its package the "main package" and unfilter
    # foreign-package diagnostics (a vendored package's hintAsError promotion
    # then aborts builds the whole-program compilation accepts). Use the
    # original project, forwarded by deps.nim via --icproject.
    packSym = getPackage(graph, fileInfoIdx(graph.config, AbsoluteFile graph.config.icProject))
  graph.config.mainPackageId = packSym.getPackageId
  graph.importStack.add projectFile

  if projectFile == systemFileIdx:
    graph.withinSystem = true
    discard graph.compilePipelineModule(projectFile, {sfMainModule, sfSystemModule})
    graph.withinSystem = false
  elif graph.config.cmd == cmdM:
    # For cmdM: load system.nim from NIF first, then compile the main module
    connectPipelineCallbacks(graph)
    # Record the main module so the IC loader won't materialise duplicate stubs
    # for its own symbols when a dependency (e.g. system) re-exports them.
    setIcMainModule(projectFile)
    graph.config.m.systemFileIdx = fileInfoIdx(graph.config,
        graph.config.libpath / RelativeFile"system.nim")
    when not defined(nimKochBootstrap):
      let precomp = moduleFromNifFile(graph, graph.config.m.systemFileIdx)
      graph.systemModule = precomp.module
      if graph.systemModule == nil:
        let nifPath = toNifFilename(graph.config, graph.config.m.systemFileIdx)
        localError(graph.config, unknownLineInfo,
          "nim m requires precompiled NIF for system module (expected: " & nifPath & ")")
        return
    discard graph.compilePipelineModule(projectFile, {sfMainModule})
  else:
    graph.compilePipelineSystemModule()
    discard graph.compilePipelineModule(projectFile, {sfMainModule})
