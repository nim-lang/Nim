discard """
  joinable: false
"""

import std/[assertions, os, tempfiles]
import compiler/[ast, astalgo, ast2nif, idents, lineinfos, modulegraphs, msgs, options, pathutils, typekeys]

# Compare the actual lookup sequence, not just successful overload resolution.
# Enough symbols share each name to exercise multiple source-table rehashes.
proc ids(tab: TStrTable; name: PIdent): seq[int32] =
  var it: TIdentIter
  var sym = initIdentIter(it, tab, name)
  while sym != nil:
    result.add sym.disamb
    sym = nextIdentIter(it, tab)

proc run(count: int) =
  let dir = createTempDir("nim_ic_interface_", "")
  try:
    let conf = newConfigRef()
    conf.cmd = cmdM
    conf.backend = backendC
    conf.projectPath = AbsoluteDir(dir)
    conf.nimcacheDir = AbsoluteDir(dir)
    conf.projectFull = AbsoluteFile(dir / "sample.nim")
    writeFile(conf.projectFull.string, "")
    let cache = newIdentCache()
    let graph = newModuleGraph(cache, conf)
    let file = fileInfoIdx(conf, conf.projectFull)
    let info = newLineInfo(file, 1, 1)
    let module = PSym(kindImpl: skModule, name: getIdent(cache, "sample"),
      itemId: itemId(file.int32, 0), positionImpl: file.int, infoImpl: info)
    graph.registerModule(module)
    let idgen = idGeneratorFromModule(module)
    let name = getIdent(cache, "choose")
    let body = newNodeI(nkStmtList, info)
    var publicTable = initStrTable()
    for i in 0 ..< count:
      let sym = newSym(skProc, name, idgen, module, info)
      # Interleave private and public overloads under the SAME identifier.
      if i mod 3 == 0:
        sym.incl sfExported
        graph.strTableAdds(module, sym)
        strTableAdd(publicTable, sym)
      else:
        strTableAdd(semtabAll(graph, module), sym)
      body.add newSymNode(sym)
      # Unrelated names force hash collisions and table growth too.
      let other = newSym(skProc, getIdent(cache, "other" & $i), idgen, module, info)
      other.incl sfExported
      graph.strTableAdds(module, other)
      strTableAdd(publicTable, other)
      body.add newSymNode(other)
    let expectedPublic = ids(publicTable, name)
    let expectedHidden = ids(semtabAll(graph, module), name)
    let publicSyms = orderedInterface(graph, module)
    let hiddenSyms = orderedInterface(graph, module, hidden = true)
    writeNifModule(conf, file.int32, body, @[],
      publicInterface = publicSyms, hiddenInterface = hiddenSyms)

    var decoder = createDecodeContext(conf, cache)
    var exported = initStrTable()
    var hidden = initStrTable()
    discard loadNifModule(decoder, file, exported, hidden)
    doAssert ids(exported, name) == expectedPublic
    doAssert hidden.counter == 0 # hidden symbols are still lazy
    doAssert buildHiddenInterface(decoder, cachedModuleSuffix(conf, file), hidden, nil)
    doAssert ids(hidden, name) == expectedHidden
    doAssert ids(exported, name) == expectedPublic # loading hidden changes no public order
    doAssert exported.counter == publicSyms.len
    doAssert hidden.counter == hiddenSyms.len
  finally:
    removeDir(dir)

for count in [2, 8, 32, 128]:
  run(count)
