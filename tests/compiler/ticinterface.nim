discard """
  joinable: false
"""

import std/[assertions, os, strutils, tempfiles]
import compiler/[ast, astalgo, ast2nif, idents, lineinfos, modulegraphs, msgs, options, pathutils, typekeys]

# Compare the actual lookup sequence, not just successful overload resolution.
# Enough symbols share each name to exercise multiple source-table rehashes.
proc ids(tab: TStrTable; name: PIdent): seq[int32] =
  var it: TIdentIter
  var sym = initIdentIter(it, tab, name)
  while sym != nil:
    result.add sym.disamb
    sym = nextIdentIter(it, tab)

type Visibility = enum
  allPublic, allPrivate, mixed

proc run(count: int; visibility: Visibility) =
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
    let names = [getIdent(cache, "choose"), getIdent(cache, "anotherChoice"),
      getIdent(cache, "anotherAlternative"),
      getIdent(cache, "longOverloadedNameThatCannotBeStoredInline")]
    let body = newNodeI(nkStmtList, info)
    var publicTable = initStrTable()
    for i in 0 ..< count:
      for name in names:
        # Style-equivalent spellings share a lookup group too.
        let spelling = if i mod 2 == 0: name else:
          getIdent(cache, name.s[0] & "_" & name.s[1..^1].toUpperAscii)
        let sym = newSym(skProc, spelling, idgen, module, info)
        # Interleave private and public overloads under the SAME identifiers.
        if visibility == allPublic or (visibility == mixed and i mod 3 == 0):
          sym.incl sfExported
          graph.strTableAdds(module, sym)
          strTableAdd(publicTable, sym)
        else:
          strTableAdd(semtabAll(graph, module), sym)
        body.add newSymNode(sym)
      # Unrelated names force hash collisions and table growth too.
      let other = newSym(skProc, getIdent(cache, "other" & $i), idgen, module, info)
      if visibility != allPrivate:
        other.incl sfExported
        graph.strTableAdds(module, other)
        strTableAdd(publicTable, other)
      else:
        strTableAdd(semtabAll(graph, module), other)
      body.add newSymNode(other)
    var expectedPublic, expectedHidden: seq[seq[int32]]
    for name in names:
      expectedPublic.add ids(publicTable, name)
      expectedHidden.add ids(semtabAll(graph, module), name)
    writeNifModule(conf, file.int32, body, @[])

    # Each independent decoder must reconstruct the same order from disk.
    for _ in 0..1:
      var decoder = createDecodeContext(conf, cache)
      var exported = initStrTable()
      var hidden = initStrTable()
      discard loadNifModule(decoder, file, exported, hidden)
      for i, name in names:
        doAssert ids(exported, name) == expectedPublic[i], $visibility & ": " & $count
      # The private half is lazy: until it is asked for, `interfHidden` holds
      # the exported symbols alone.
      doAssert hidden.counter == exported.counter
      doAssert buildHiddenInterface(decoder, cachedModuleSuffix(conf, file), hidden)
      for i, name in names:
        doAssert ids(hidden, name) == expectedHidden[i], $visibility & ": " & $count
        doAssert ids(exported, name) == expectedPublic[i]
      doAssert exported.counter == publicTable.counter
      doAssert hidden.counter == semtabAll(graph, module).counter
  finally:
    removeDir(dir)

# Include empty/singleton tables and both sides of table-growth boundaries.
for count in [0, 1, 2, 7, 8, 9, 31, 32, 33, 127, 128, 129]:
  for visibility in Visibility:
    run(count, visibility)
