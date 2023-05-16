import strutils, os, parseutils, net, strformat, times

import compiler/[renderer, options, modules, passes, msgs, sigmatch, ast, idents, modulegraphs,
    lineinfos, pathutils]

import globals

const DummyEof* = "!EOF!"

template benchmark*(benchmarkName: untyped, code: untyped) =
  block:
    myLog "Started [" & benchmarkName & "]..."
    let t0 = epochTime()
    code
    let elapsed = epochTime() - t0
    let elapsedStr = elapsed.formatFloat(format = ffDecimal, precision = 3)
    myLog "CPU Time [" & benchmarkName & "] " & elapsedStr & "s"

proc recompileFullProject*(graph: ModuleGraph) =
  benchmark "Recompilation(clean)":
    graph.resetForBackend()
    graph.resetSystemArtifacts()
    graph.vm = nil
    graph.resetAllModules()
    GC_fullCollect()
    graph.compileProject()

proc findNode*(n: PNode; trackPos: TLineInfo): PSym =
  #echo "checking node ", n.info
  if n.kind == nkSym:
    if isTracked(n.info, trackPos, n.sym.name.s.len): return n.sym
  else:
    for i in 0 ..< safeLen(n):
      let res = findNode(n[i], trackPos)
      if res != nil: return res

proc symFromInfo*(graph: ModuleGraph; trackPos: TLineInfo): PSym =
  let m = graph.getModule(trackPos.fileIndex)
  if m != nil and m.ast != nil:
    result = findNode(m.ast, trackPos)

template checkSanity*(client, sizeHex, size, messageBuffer: typed) =
  if client.recv(sizeHex, 6) != 6:
    raise newException(ValueError, "didn't get all the hexbytes")
  if parseHex(sizeHex, size) == 0:
    raise newException(ValueError, "invalid size hex: " & $sizeHex)
  if client.recv(messageBuffer, size) != size:
    raise newException(ValueError, "didn't get all the bytes")
