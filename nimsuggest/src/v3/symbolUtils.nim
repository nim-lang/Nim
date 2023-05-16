
import algorithm, tables, net

import ../compiler/[renderer, options, msgs, sigmatch, ast, modulegraphs, prefixmatches, lineinfos]


proc findByTLineInfo*(trackPos: TLineInfo, infoPairs: seq[SymInfoPair]):
    ref SymInfoPair =
  for s in infoPairs:
    if s.info.exactEquals trackPos:
      new(result)
      result[] = s
      break
proc suggestResult*(graph: ModuleGraph, sym: PSym, info: TLineInfo, defaultSection = ideNone,
    endLine: uint16 = 0, endCol = 0) =
  let section =
    if defaultSection != ideNone:
      defaultSection
    elif sym.info.exactEquals(info):
      ideDef
    else:
      ideUse
  let suggest = symToSuggest(graph, sym, isLocal = false, section,
                               info, 100, PrefixMatch.None, false, 0,
                               endLine = endLine, endCol = endCol)
  suggestResult(graph.config, suggest)

func deduplicateSymInfoPair*[SymInfoPair](xs: seq[SymInfoPair]): seq[SymInfoPair] =
  # xs contains duplicate items and we want to filter them by range because the
  # sym may not match. This can happen when xs contains the same definition but
  # with different signature because suggestSym might be called multiple times
  # for the same symbol (e. g. including/excluding the pragma)
  result = newSeqOfCap[SymInfoPair](xs.len)
  for itm in xs.reversed:
    var found = false
    for res in result:
      if res.info.exactEquals(itm.info):
        found = true
        break
    if not found:
      result.add(itm)
  result.reverse()
