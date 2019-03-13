#
#
#           The Nim Compiler
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## exposes the Nim VM to clients.
import
  ast, astalgo, modules, passes, condsyms,
  options, sem, semdata, llstream, vm, vmdef,
  modulegraphs, idents, os, pathutils, passaux,
  scriptconfig

type
  Interpreter* = ref object ## Use Nim as an interpreter with this object
    mainModule: PSym
    graph: ModuleGraph
    scriptName: string

iterator exportedSymbols*(i: Interpreter): PSym =
  assert i != nil
  assert i.mainModule != nil, "no main module selected"
  var it: TTabIter
  var s = initTabIter(it, i.mainModule.tab)
  while s != nil:
    yield s
    s = nextIter(it, i.mainModule.tab)

proc selectUniqueSymbol*(i: Interpreter; name: string;
                         symKinds: set[TSymKind] = {skLet, skVar}): PSym =
  ## Can be used to access a unique symbol of ``name`` and
  ## the given ``symKinds`` filter.
  assert i != nil
  assert i.mainModule != nil, "no main module selected"
  let n = getIdent(i.graph.cache, name)
  var it: TIdentIter
  var s = initIdentIter(it, i.mainModule.tab, n)
  result = nil
  while s != nil:
    if s.kind in symKinds:
      if result == nil: result = s
      else: return nil # ambiguous
    s = nextIdentIter(it, i.mainModule.tab)

proc selectRoutine*(i: Interpreter; name: string): PSym =
  ## Selects a declared rountine (proc/func/etc) from the main module.
  ## The routine needs to have the export marker ``*``. The only matching
  ## routine is returned and ``nil`` if it is overloaded.
  result = selectUniqueSymbol(i, name, {skTemplate, skMacro, skFunc,
                                        skMethod, skProc, skConverter})

proc callRoutine*(i: Interpreter; routine: PSym; args: openArray[PNode]): PNode =
  assert i != nil
  result = vm.execProc(PCtx i.graph.vm, routine, args)

proc getGlobalValue*(i: Interpreter; letOrVar: PSym): PNode =
  result = vm.getGlobalValue(PCtx i.graph.vm, letOrVar)

proc implementRoutine*(i: Interpreter; pkg, module, name: string;
                       impl: proc (a: VmArgs) {.closure, gcsafe.}) =
  assert i != nil
  let vm = PCtx(i.graph.vm)
  vm.registerCallback(pkg & "." & module & "." & name, impl)

proc evalScript*(i: Interpreter; scriptStream: PLLStream = nil) =
  ## This can also be used to *reload* the script.
  assert i != nil
  assert i.mainModule != nil, "no main module selected"
  initStrTable(i.mainModule.tab)
  i.mainModule.ast = nil

  let s = if scriptStream != nil: scriptStream
          else: llStreamOpen(findFile(i.graph.config, i.scriptName), fmRead)
  processModule(i.graph, i.mainModule, s)

proc findNimStdLib*(): string =
  ## Tries to find a path to a valid "system.nim" file.
  ## Returns "" on failure.
  try:
    let nimexe = os.findExe("nim")
    if nimexe.len == 0: return ""
    result = nimexe.splitPath()[0] /../ "lib"
    if not fileExists(result / "system.nim"):
      when defined(unix):
        result = nimexe.expandSymlink.splitPath()[0] /../ "lib"
        if not fileExists(result / "system.nim"): return ""
  except OSError, ValueError:
    return ""

proc findNimStdLibCompileTime*(): string =
  ## Same as ``findNimStdLib`` but uses source files used at compile time,
  ## and asserts on error.
  const sourcePath = currentSourcePath()
  result = sourcePath.parentDir.parentDir / "lib"
  doAssert fileExists(result / "system.nim"), "result:" & result

proc createInterpreter*(scriptName: string;
                        searchPaths: openArray[string];
                        flags: TSandboxFlags = {}): Interpreter =
  var conf = newConfigRef()
  var cache = newIdentCache()
  var graph = newModuleGraph(cache, conf)
  connectCallbacks(graph)
  initDefines(conf.symbols)
  defineSymbol(conf.symbols, "nimscript")
  defineSymbol(conf.symbols, "nimconfig")
  registerPass(graph, semPass)
  registerPass(graph, evalPass)

  for p in searchPaths:
    conf.searchPaths.add(AbsoluteDir p)
    if conf.libpath.isEmpty: conf.libpath = AbsoluteDir p

  var m = graph.makeModule(scriptName)
  incl(m.flags, sfMainModule)
  var vm = newCtx(m, cache, graph)
  vm.mode = emRepl
  vm.features = flags
  graph.vm = vm
  graph.compileSystemModule()
  result = Interpreter(mainModule: m, graph: graph, scriptName: scriptName)

proc destroyInterpreter*(i: Interpreter) =
  ## destructor.
  discard "currently nothing to do."

proc runRepl*(r: TLLRepl;
              searchPaths: openArray[string];
              supportNimscript: bool) =
  var conf = newConfigRef()
  var cache = newIdentCache()
  var graph = newModuleGraph(cache, conf)

  for p in searchPaths:
    conf.searchPaths.add(AbsoluteDir p)
    if conf.libpath.isEmpty: conf.libpath = AbsoluteDir p

  conf.cmd = cmdInteractive
  conf.errorMax = high(int)
  initDefines(conf.symbols)
  defineSymbol(conf.symbols, "nimscript")
  if supportNimscript: defineSymbol(conf.symbols, "nimconfig")
  when hasFFI: defineSymbol(graph.config.symbols, "nimffi")
  registerPass(graph, verbosePass)
  registerPass(graph, semPass)
  registerPass(graph, evalPass)
  var m = graph.makeStdinModule()
  incl(m.flags, sfMainModule)
  if supportNimscript: graph.vm = setupVM(m, cache, "stdin", graph)
  graph.compileSystemModule()
  processModule(graph, m, llStreamOpenStdIn(r))
