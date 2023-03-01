import sem, cgen, modulegraphs, ast, llstream, parser, msgs,
       lineinfos, reorder, options, semdata, cgendata, modules, pathutils,
       packages, syntaxes, jsgen, depends, docgen2


import pipelineutils
import vm

import std/[syncio, objectdollar, assertions, tables]
import renderer
import ic/replayer

const CLikeBackend = {backendC, backendCpp, backendObjc}

type
  PipelinePhase* = enum
    SemPass
    JSgenPass
    CgenPass
    EvalPass
    InterpreterPass
    GenDependPass
    Docgen2TexPass
    Docgen2JsonPass
    Docgen2Pass

proc classifyPipelinePass*(graph: ModuleGraph): PipelinePhase =
  case graph.config.cmd
  of cmdBackends:
    case graph.config.backend
    of CLikeBackend:
      if graph.config.symbolFiles == disabledSf:
        result = CgenPass
      else:
        result = SemPass
    of backendJs:
      result = JSgenPass
    else:
      result = SemPass
  of cmdGendepend:
    result = GenDependPass
  of cmdDoc:
    result = Docgen2Pass
  of cmdRst2tex, cmdMd2tex, cmdDoc2tex:
    result = Docgen2TexPass
  of cmdJsondoc:
    result = Docgen2JsonPass
  of cmdInteractive:
    result = InterpreterPass
  else:
    result = SemPass

proc processPipeline(graph: ModuleGraph; semNode: PNode; bModule: PPassContext, phase: PipelinePhase): PNode =
  case phase
  of CgenPass:
    result = processCodeGen(bModule, semNode)
  of JSgenPass:
    result = processJSCodeGen(bModule, semNode)
  of GenDependPass:
    result = addDotDependency(bModule, semNode)
  of SemPass:
    result = graph.emptyNode
  of Docgen2Pass, Docgen2TexPass:
    result = processNode(bModule, semNode)
  of Docgen2JsonPass:
    result = processNodeJson(bModule, semNode)
  of EvalPass, InterpreterPass:
    result = interpreterCode(bModule, semNode)

proc processImplicitImports(graph: ModuleGraph; implicits: seq[string], nodeKind: TNodeKind,
                      m: PSym, ctx: PContext, bModule: PPassContext, idgen: IdGenerator,
                      phase: PipelinePhase) =
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
      if semNode == nil or processPipeline(graph, semNode, bModule, phase) == nil:
        break

proc processPipelineModule*(graph: ModuleGraph; module: PSym; idgen: IdGenerator;
                    stream: PLLStream, phase: PipelinePhase): bool =
  if graph.stopCompile(): return true
  var
    p: Parser
    s: PLLStream
    fileIdx = module.fileIdx

  prepareConfigNotes(graph, module)
  let ctx = preparePContext(graph, module, idgen)
  let bModule: PPassContext =
    case phase
    of CgenPass:
      setupBackendGen(graph, module, idgen)
    of JSgenPass:
      setupJSgen(graph, module, idgen)
    of EvalPass, InterpreterPass:
      setupVMContext(graph, module, idgen)
    of GenDependPass:
      setupDependPass(graph, module, idgen)
    of Docgen2Pass:
      openHtml(graph, module, idgen)
    of Docgen2TexPass:
      openTex(graph, module, idgen)
    of Docgen2JsonPass:
      openJson(graph, module, idgen)
    of SemPass:
      nil
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
    syntaxes.openParser(p, fileIdx, s, graph.cache, graph.config)

    if not belongsToStdlib(graph, module) or (belongsToStdlib(graph, module) and module.name.s == "distros"):
      # XXX what about caching? no processing then? what if I change the
      # modules to include between compilation runs? we'd need to track that
      # in ROD files. I think we should enable this feature only
      # for the interactive mode.
      if module.name.s != "nimscriptapi":
        processImplicitImports graph, graph.config.implicitImports, nkImportStmt, module, ctx, bModule, idgen, phase
        processImplicitImports graph, graph.config.implicitIncludes, nkIncludeStmt, module, ctx, bModule, idgen, phase

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
      if sfReorder in module.flags or codeReordering in graph.config.features:
        sl = reorder(graph, sl, module)
      if phase != EvalPass:
        message(graph.config, sl.info, hintProcessingStmt, $idgen[])
      var semNode = semWithPContext(ctx, sl)
      discard processPipeline(graph, semNode, bModule, phase)

    closeParser(p)
    if s.kind != llsStdIn: break
  let finalNode = closePContext(graph, ctx, nil)
  case phase
  of CgenPass:
    discard finalCodeGen(graph, bModule, finalNode)
  of JSgenPass:
    discard finalJSCodeGen(graph, bModule, finalNode)
  of EvalPass, InterpreterPass:
    discard interpreterCode(bModule, finalNode)
  of SemPass, GenDependPass:
    discard
  of Docgen2Pass, Docgen2TexPass:
    discard closeDoc(graph, bModule, finalNode)
  of Docgen2JsonPass:
    discard closeJson(graph, bModule, finalNode)

  if graph.config.backend notin CLikeBackend:
    # We only write rod files here if no C-like backend is active.
    # The C-like backends have been patched to support the IC mechanism.
    # They are responsible for closing the rod files. See `cbackend.nim`.
    closeRodFile(graph, module)
  result = true

proc compilePipelineModule*(graph: ModuleGraph; fileIdx: FileIndex; flags: TSymFlags, phase: PipelinePhase, fromModule: PSym = nil): PSym =
  var flags = flags
  if fileIdx == graph.config.projectMainIdx2: flags.incl sfMainModule
  result = graph.getModule(fileIdx)

  template processModuleAux(moduleStatus) =
    onProcessing(graph, fileIdx, moduleStatus, fromModule = fromModule)
    var s: PLLStream
    if sfMainModule in flags:
      if graph.config.projectIsStdin: s = stdin.llStreamOpen
      elif graph.config.projectIsCmd: s = llStreamOpen(graph.config.cmdInput)
    discard processPipelineModule(graph, result, idGeneratorFromModule(result), s, phase)
  if result == nil:
    var cachedModules: seq[FileIndex]
    result = moduleFromRodFile(graph, fileIdx, cachedModules)
    let filename = AbsoluteFile toFullPath(graph.config, fileIdx)
    if result == nil:
      result = newModule(graph, fileIdx)
      result.flags.incl flags
      registerModule(graph, result)
      processModuleAux("import")
    else:
      if sfSystemModule in flags:
        graph.systemModule = result
      partialInitModule(result, graph, fileIdx, filename)
    for m in cachedModules:
      registerModuleById(graph, m)
      replayStateChanges(graph.packed[m.int].module, graph)
      replayGenericCacheInformation(graph, m.int)
  elif graph.isDirty(result):
    result.flags.excl sfDirty
    # reset module fields:
    initStrTables(graph, result)
    result.ast = nil
    processModuleAux("import(dirty)")
    graph.markClientsDirty(fileIdx)

proc importPipelineModule(graph: ModuleGraph; s: PSym, fileIdx: FileIndex): PSym =
  # this is called by the semantic checking phase
  assert graph.config != nil
  let phase = classifyPipelinePass(graph)
  result = compilePipelineModule(graph, fileIdx, {}, phase, s)
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

proc compilePipelineSystemModule*(graph: ModuleGraph, phase: PipelinePhase) =
  if graph.systemModule == nil:
    connectPipelineCallbacks(graph)
    graph.config.m.systemFileIdx = fileInfoIdx(graph.config,
        graph.config.libpath / RelativeFile"system.nim")
    discard graph.compilePipelineModule(graph.config.m.systemFileIdx, {sfSystemModule}, phase)

proc compilePipelineProject*(graph: ModuleGraph; projectFileIdx = InvalidFileIdx) =
  connectPipelineCallbacks(graph)
  let conf = graph.config
  wantMainModule(conf)
  configComplete(graph)

  let systemFileIdx = fileInfoIdx(conf, conf.libpath / RelativeFile"system.nim")
  let projectFile = if projectFileIdx == InvalidFileIdx: conf.projectMainIdx else: projectFileIdx
  conf.projectMainIdx2 = projectFile

  let packSym = getPackage(graph, projectFile)
  graph.config.mainPackageId = packSym.getPackageId
  graph.importStack.add projectFile

  let phase = classifyPipelinePass(graph)

  if projectFile == systemFileIdx:
    discard graph.compilePipelineModule(projectFile, {sfMainModule, sfSystemModule}, phase)
  else:
    graph.compilePipelineSystemModule(phase)
    discard graph.compilePipelineModule(projectFile, {sfMainModule}, phase)
