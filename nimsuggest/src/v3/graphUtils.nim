import symbolUtils, net

import ../compiler/[renderer, options, msgs, sigmatch, ast, idents, modulegraphs, lineinfos, pathutils]

## A collection of utility functions for use in traversing graphs
proc outlineNode*(graph: ModuleGraph, n: PNode, endInfo: TLineInfo, infoPairs: seq[SymInfoPair]): bool =
  proc checkSymbol(sym: PSym, info: TLineInfo): bool =
    result = (sym.owner.kind in {skModule, skType} or sym.kind in {skProc, skMethod, skIterator, skTemplate, skType})

  if n.kind == nkSym and n.sym.checkSymbol(n.info):
    graph.suggestResult(n.sym, n.sym.info, ideOutline, endInfo.line, endInfo.col)
    return true
  elif n.kind == nkIdent:
    let symData = findByTLineInfo(n.info, infoPairs)
    if symData != nil and symData.sym.checkSymbol(symData.info):
       let sym = symData.sym
       graph.suggestResult(sym, sym.info, ideOutline, endInfo.line, endInfo.col)
       return true

proc handleIdentOrSym*(graph: ModuleGraph, n: PNode, endInfo: TLineInfo, infoPairs: seq[SymInfoPair]): bool =
  for child in n:
    if child.kind in {nkIdent, nkSym}:
      if graph.outlineNode(child, endInfo, infoPairs):
        return true
    elif child.kind == nkPostfix:
      if graph.handleIdentOrSym(child, endInfo, infoPairs):
        return true

proc iterateOutlineNodes*(graph: ModuleGraph, n: PNode, infoPairs: seq[SymInfoPair]) =
  var matched = true
  if n.kind == nkIdent:
    let symData = findByTLineInfo(n.info, infoPairs)
    if symData != nil and symData.sym.kind == skEnumField and symData.info.exactEquals(symData.sym.info):
       let sym = symData.sym
       graph.suggestResult(sym, sym.info, ideOutline, n.endInfo.line, n.endInfo.col)
  elif (n.kind in {nkFuncDef, nkProcDef, nkTypeDef, nkMacroDef, nkTemplateDef, nkConverterDef, nkEnumFieldDef, nkConstDef}):
    matched = handleIdentOrSym(graph, n, n.endInfo, infoPairs)
  else:
    matched = false

  if n.kind != nkFormalParams:
    for child in n:
      graph.iterateOutlineNodes(child, infoPairs)

proc calculateExpandRange*(n: PNode, info: TLineInfo): TLineInfo =
  if ((n.kind in {nkFuncDef, nkProcDef, nkIteratorDef, nkTemplateDef, nkMethodDef, nkConverterDef} and
          n.info.exactEquals(info)) or
         (n.kind in {nkCall, nkCommand} and n[0].info.exactEquals(info))):
    result = n.endInfo
  else:
    for child in n:
      result = child.calculateExpandRange(info)
      if result != unknownLineInfo:
        return result
    result = unknownLineInfo




proc findSymData*(graph: ModuleGraph, trackPos: TLineInfo):
    ref SymInfoPair =
  for s in graph.fileSymbols(trackPos.fileIndex).deduplicateSymInfoPair:
    if isTracked(s.info, trackPos, s.sym.name.s.len):
      new(result)
      result[] = s
      break

proc findSymData*(graph: ModuleGraph, file: AbsoluteFile; line, col: int):
    ref SymInfoPair =
  let
    fileIdx = fileInfoIdx(graph.config, file)
    trackPos = newLineInfo(fileIdx, line, col)
  result = findSymData(graph, trackPos)