import std/assertions
import "../../compiler/icnif" / [nifencoder, nifdecoder]
import "../../compiler" / [idents, ast, astalgo, options, pathutils, modulegraphs, modules, msgs, pipelines, syntaxes, sem, llstream, lineinfos]

# This test generates PNode by semchecks test code.
# Then it is used to test icnif/nifencoder and nifdecoder.

const TestCodeDir = currentSourcePath().AbsoluteFile.splitFile().dir / RelativeDir"testcode"

proc newConfigRefForTest(): ConfigRef =
  var conf = newConfigRef()
  conf.setDefaultLibpath()
  conf.searchPaths.add(conf.libpath)
  excl(conf.notes, hintProcessing)
  excl(conf.mainPackageNotes, hintProcessing)
  result = conf
 
proc newModuleGraphForSem(cache: IdentCache; conf: ConfigRef): ModuleGraph =
  var graph = newModuleGraph(cache, conf)
  graph.setPipeLinePass(SemPass)
  graph.compilePipelineSystemModule()
  result = graph

proc sem(graph: ModuleGraph; path: AbsoluteFile): PNode =
  result = nil

  let fileIdx = fileInfoIdx(graph.config, path)
  var module = newModule(graph, fileIdx)
  registerModule(graph, module)

  var idgen = idGeneratorFromModule(module)
  let ctx = preparePContext(graph, module, idgen)

  var stream = llStreamOpen(path, fmRead)
  if stream == nil:
    rawMessage(graph.config, errCannotOpenFile, path.string)
    return nil

  var p: Parser = default(Parser)
  syntaxes.openParser(p, fileIdx, stream, graph.cache, graph.config)

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

    var semNode = semWithPContext(ctx, sl)

    return semNode

# Compare PSym and PNode but ignores fields nifencoder and nifdecoder doesn't support
proc eql(x, y: PSym): bool =
  if x == nil and y == nil:
    result = true
  elif x == nil or y == nil:
    result = false
  elif x.itemId.item == y.itemId.item and x.kind == y.kind and x.name.s == y.name.s and x.flags == y.flags and x.disamb == y.disamb:
    if x.owner == nil and y.owner == nil:
      result = true
    elif x.owner == nil or y.owner == nil:
      result = false
    elif x.owner.kind == y.owner.kind and x.owner.name.s == y.owner.name.s:
      if x.kind == skModule:
        result = true
      else:
        result = x.position == y.position
    else:
      result = false
  else:
    result = false

proc eql(x, y: PNode): bool =
  if x == nil and y == nil:
    result = true
  elif x == nil or y == nil:
    result = false
  elif x.kind == y.kind and x.safeLen == y.safeLen:
    case x.kind:
    of nkSym:
      result = eql(x.sym, y.sym)
      if not result:
        echo "Symbol mismatch:"
        #debug(x)
        #debug(y)
    of nkCharLit .. nkTripleStrLit:
      result = sameValue(x, y)
    else:
      result = true
      for i in 0 ..< x.safeLen:
        if not eql(x[i], y[i]):
          result = false
          break
  else:
    result = false

proc testNifEncDec(graph: ModuleGraph; src: string) =
  let fullPath = TestCodeDir / RelativeFile(src)
  let n = sem(graph, fullPath)
  let nif = saveNifToBuffer(n, graph.config)
  # Don't reuse the ModuleGraph used for semcheck when load NIF.
  var graphForLoad = newModuleGraph(newIdentCache(), newConfigRefForTest())
  let n2 = loadNifFromBuffer(nif, fullPath, graphForLoad)
  #debug(n)
  #debug(n2)
  #if src == "modtestliterals.nim":
  #  echo nif
  assert eql(n, n2)

var conf = newConfigRefForTest()
var cache = newIdentCache()
var graph = newModuleGraphForSem(cache, conf)
testNifEncDec(graph, "modtest1.nim")
testNifEncDec(graph, "modtestliterals.nim")
