#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This file implements features required for IDE support.
##
## Due to Nim's nature and the fact that ``system.nim`` is always imported,
## there are lots of potential symbols. Furthermore thanks to templates and
## macros even context based analysis does not help much: In a context like
## ``let x: |`` where a type has to follow, that type might be constructed from
## a template like ``extractField(MyObject, fieldName)``. We deal with this
## problem by smart sorting so that the likely symbols come first. This sorting
## is done this way:
##
## - If there is a prefix (foo|), symbols starting with this prefix come first.
## - If the prefix is part of the name (but the name doesn't start with it),
##   these symbols come second.
## - If we have a prefix, only symbols matching this prefix are returned and
##   nothing else.
## - If we have no prefix, consider the context. We currently distinguish
##   between type and non-type contexts.
## - Finally, sort matches by relevance. The relevance is determined by the
##   number of usages, so ``strutils.replace`` comes before
##   ``strutils.wordWrap``.
## - In any case, sorting also considers scoping information. Local variables
##   get high priority.

# included from sigmatch.nim

import algorithm, prefixmatches, configuration
from wordrecg import wDeprecated

when defined(nimsuggest):
  import passes, tables # importer

const
  sep = '\t'

type
  Suggest* = ref object
    section*: IdeCmd
    qualifiedPath*: seq[string]
    name*: PIdent                # not used beyond sorting purposes; name is also
                                 # part of 'qualifiedPath'
    filePath*: string
    line*: int                   # Starts at 1
    column*: int                 # Starts at 0
    doc*: string           # Not escaped (yet)
    symkind*: TSymKind
    forth*: string               # type
    quality*: range[0..100]   # matching quality
    isGlobal*: bool # is a global variable
    contextFits*: bool # type/non-type context matches
    prefix*: PrefixMatch
    scope*, localUsages*, globalUsages*: int # more usages is better
    tokenLen*: int
  Suggestions* = seq[Suggest]

var
  suggestionResultHook*: proc (result: Suggest) {.closure.}
  suggestVersion*: int
  suggestMaxResults* = 10_000

#template sectionSuggest(): expr = "##begin\n" & getStackTrace() & "##end\n"

template origModuleName(m: PSym): string = m.name.s

proc findDocComment(n: PNode): PNode =
  if n == nil: return nil
  if not isNil(n.comment): return n
  if n.kind in {nkStmtList, nkStmtListExpr, nkObjectTy, nkRecList} and n.len > 0:
    result = findDocComment(n.sons[0])
    if result != nil: return
    if n.len > 1:
      result = findDocComment(n.sons[1])
  elif n.kind in {nkAsgn, nkFastAsgn} and n.len == 2:
    result = findDocComment(n.sons[1])

proc extractDocComment(s: PSym): string =
  var n = findDocComment(s.ast)
  if n.isNil and s.kind in routineKinds and s.ast != nil:
    n = findDocComment(s.ast[bodyPos])
  if not n.isNil:
    result = n.comment.replace("\n##", "\n").strip
  else:
    result = ""

proc cmpSuggestions(a, b: Suggest): int =
  template cf(field) {.dirty.} =
    result = b.field.int - a.field.int
    if result != 0: return result

  cf scope
  cf prefix
  # when the first type matches, it's better when it's a generic match:
  cf quality
  cf contextFits
  cf localUsages
  cf globalUsages
  # if all is equal, sort alphabetically for deterministic output,
  # independent of hashing order:
  result = cmp(a.name.s, b.name.s)

proc symToSuggest(s: PSym, isLocal: bool, section: IdeCmd, info: TLineInfo;
                  quality: range[0..100]; prefix: PrefixMatch;
                  inTypeContext: bool; scope: int): Suggest =
  new(result)
  result.section = section
  result.quality = quality
  result.isGlobal = sfGlobal in s.flags
  result.tokenLen = s.name.s.len
  result.prefix = prefix
  result.contextFits = inTypeContext == (s.kind in {skType, skGenericParam})
  result.scope = scope
  result.name = s.name
  when defined(nimsuggest):
    result.globalUsages = s.allUsages.len
    var c = 0
    for u in s.allUsages:
      if u.fileIndex == info.fileIndex: inc c
    result.localUsages = c
  result.symkind = s.kind
  if optIdeTerse notin gGlobalOptions:
    result.qualifiedPath = @[]
    if not isLocal and s.kind != skModule:
      let ow = s.owner
      if ow != nil and ow.kind != skModule and ow.owner != nil:
        let ow2 = ow.owner
        result.qualifiedPath.add(ow2.origModuleName)
      if ow != nil:
        result.qualifiedPath.add(ow.origModuleName)
    result.qualifiedPath.add(s.name.s)

    if s.typ != nil:
      result.forth = typeToString(s.typ)
    else:
      result.forth = ""
    when not defined(noDocgen):
      result.doc = s.extractDocComment
  let infox = if section in {ideUse, ideHighlight, ideOutline}: info else: s.info
  result.filePath = toFullPath(infox)
  result.line = toLinenumber(infox)
  result.column = toColumn(infox)

proc `$`*(suggest: Suggest): string =
  result = $suggest.section
  result.add(sep)
  if suggest.section == ideHighlight:
    if suggest.symkind == skVar and suggest.isGlobal:
      result.add("skGlobalVar")
    elif suggest.symkind == skLet and suggest.isGlobal:
      result.add("skGlobalLet")
    else:
      result.add($suggest.symkind)
    result.add(sep)
    result.add($suggest.line)
    result.add(sep)
    result.add($suggest.column)
    result.add(sep)
    result.add($suggest.tokenLen)
  else:
    result.add($suggest.symkind)
    result.add(sep)
    if suggest.qualifiedPath != nil:
      result.add(suggest.qualifiedPath.join("."))
    result.add(sep)
    result.add(suggest.forth)
    result.add(sep)
    result.add(suggest.filePath)
    result.add(sep)
    result.add($suggest.line)
    result.add(sep)
    result.add($suggest.column)
    result.add(sep)
    when not defined(noDocgen):
      result.add(suggest.doc.escape)
    if suggestVersion == 0:
      result.add(sep)
      result.add($suggest.quality)
      if suggest.section == ideSug:
        result.add(sep)
        result.add($suggest.prefix)

proc suggestResult(s: Suggest) =
  if not isNil(suggestionResultHook):
    suggestionResultHook(s)
  else:
    suggestWriteln($s)

proc produceOutput(a: var Suggestions; conf: ConfigRef) =
  if conf.ideCmd in {ideSug, ideCon}:
    a.sort cmpSuggestions
  when defined(debug):
    # debug code
    writeStackTrace()
  if a.len > suggestMaxResults: a.setLen(suggestMaxResults)
  if not isNil(suggestionResultHook):
    for s in a:
      suggestionResultHook(s)
  else:
    for s in a:
      suggestWriteln($s)

proc filterSym(s: PSym; prefix: PNode; res: var PrefixMatch): bool {.inline.} =
  proc prefixMatch(s: PSym; n: PNode): PrefixMatch =
    case n.kind
    of nkIdent: result = n.ident.s.prefixMatch(s.name.s)
    of nkSym: result = n.sym.name.s.prefixMatch(s.name.s)
    of nkOpenSymChoice, nkClosedSymChoice, nkAccQuoted:
      if n.len > 0:
        result = prefixMatch(s, n[0])
    else: discard
  if s.kind != skModule:
    if prefix != nil:
      res = prefixMatch(s, prefix)
      result = res != PrefixMatch.None
    else:
      result = true

proc filterSymNoOpr(s: PSym; prefix: PNode; res: var PrefixMatch): bool {.inline.} =
  result = filterSym(s, prefix, res) and s.name.s[0] in lexer.SymChars and
     not isKeyword(s.name)

proc fieldVisible*(c: PContext, f: PSym): bool {.inline.} =
  let fmoduleId = getModule(f).id
  result = sfExported in f.flags or fmoduleId == c.module.id
  for module in c.friendModules:
    if fmoduleId == module.id:
      result = true
      break

proc suggestField(c: PContext, s: PSym; f: PNode; info: TLineInfo; outputs: var Suggestions) =
  var pm: PrefixMatch
  if filterSym(s, f, pm) and fieldVisible(c, s):
    outputs.add(symToSuggest(s, isLocal=true, ideSug, info, 100, pm, c.inTypeContext > 0, 0))

proc getQuality(s: PSym): range[0..100] =
  if s.typ != nil and s.typ.len > 1:
    var exp = s.typ.sons[1].skipTypes({tyGenericInst, tyVar, tyLent, tyAlias, tySink})
    if exp.kind == tyVarargs: exp = elemType(exp)
    if exp.kind in {tyExpr, tyStmt, tyGenericParam, tyAnything}: return 50
  return 100

template wholeSymTab(cond, section: untyped) =
  var isLocal = true
  var scopeN = 0
  for scope in walkScopes(c.currentScope):
    if scope == c.topLevelScope: isLocal = false
    dec scopeN
    for item in scope.symbols:
      let it {.inject.} = item
      var pm {.inject.}: PrefixMatch
      if cond:
        outputs.add(symToSuggest(it, isLocal = isLocal, section, info, getQuality(it),
                                 pm, c.inTypeContext > 0, scopeN))

proc suggestSymList(c: PContext, list, f: PNode; info: TLineInfo, outputs: var Suggestions) =
  for i in countup(0, sonsLen(list) - 1):
    if list.sons[i].kind == nkSym:
      suggestField(c, list.sons[i].sym, f, info, outputs)
    #else: InternalError(list.info, "getSymFromList")

proc suggestObject(c: PContext, n, f: PNode; info: TLineInfo, outputs: var Suggestions) =
  case n.kind
  of nkRecList:
    for i in countup(0, sonsLen(n)-1): suggestObject(c, n.sons[i], f, info, outputs)
  of nkRecCase:
    var L = sonsLen(n)
    if L > 0:
      suggestObject(c, n.sons[0], f, info, outputs)
      for i in countup(1, L-1): suggestObject(c, lastSon(n.sons[i]), f, info, outputs)
  of nkSym: suggestField(c, n.sym, f, info, outputs)
  else: discard

proc nameFits(c: PContext, s: PSym, n: PNode): bool =
  var op = n.sons[0]
  if op.kind in {nkOpenSymChoice, nkClosedSymChoice}: op = op.sons[0]
  var opr: PIdent
  case op.kind
  of nkSym: opr = op.sym.name
  of nkIdent: opr = op.ident
  else: return false
  result = opr.id == s.name.id

proc argsFit(c: PContext, candidate: PSym, n, nOrig: PNode): bool =
  case candidate.kind
  of OverloadableSyms:
    var m: TCandidate
    initCandidate(c, m, candidate, nil)
    sigmatch.partialMatch(c, n, nOrig, m)
    result = m.state != csNoMatch
  else:
    result = false

proc suggestCall(c: PContext, n, nOrig: PNode, outputs: var Suggestions) =
  let info = n.info
  wholeSymTab(filterSym(it, nil, pm) and nameFits(c, it, n) and argsFit(c, it, n, nOrig),
              ideCon)

proc typeFits(c: PContext, s: PSym, firstArg: PType): bool {.inline.} =
  if s.typ != nil and sonsLen(s.typ) > 1 and s.typ.sons[1] != nil:
    # special rule: if system and some weird generic match via 'tyExpr'
    # or 'tyGenericParam' we won't list it either to reduce the noise (nobody
    # wants 'system.`-|` as suggestion
    let m = s.getModule()
    if m != nil and sfSystemModule in m.flags:
      if s.kind == skType: return
      var exp = s.typ.sons[1].skipTypes({tyGenericInst, tyVar, tyLent, tyAlias, tySink})
      if exp.kind == tyVarargs: exp = elemType(exp)
      if exp.kind in {tyExpr, tyStmt, tyGenericParam, tyAnything}: return
    result = sigmatch.argtypeMatches(c, s.typ.sons[1], firstArg)

proc suggestOperations(c: PContext, n, f: PNode, typ: PType, outputs: var Suggestions) =
  assert typ != nil
  let info = n.info
  wholeSymTab(filterSymNoOpr(it, f, pm) and typeFits(c, it, typ), ideSug)

proc suggestEverything(c: PContext, n, f: PNode, outputs: var Suggestions) =
  # do not produce too many symbols:
  var isLocal = true
  var scopeN = 0
  for scope in walkScopes(c.currentScope):
    if scope == c.topLevelScope: isLocal = false
    dec scopeN
    for it in items(scope.symbols):
      var pm: PrefixMatch
      if filterSym(it, f, pm):
        outputs.add(symToSuggest(it, isLocal = isLocal, ideSug, n.info, 0, pm,
                                 c.inTypeContext > 0, scopeN))
    #if scope == c.topLevelScope and f.isNil: break

proc suggestFieldAccess(c: PContext, n, field: PNode, outputs: var Suggestions) =
  # special code that deals with ``myObj.``. `n` is NOT the nkDotExpr-node, but
  # ``myObj``.
  var typ = n.typ
  var pm: PrefixMatch
  when defined(nimsuggest):
    if n.kind == nkSym and n.sym.kind == skError and suggestVersion == 0:
      # consider 'foo.|' where 'foo' is some not imported module.
      let fullPath = findModule(n.sym.name.s, n.info.toFullPath)
      if fullPath.len == 0:
        # error: no known module name:
        typ = nil
      else:
        let m = gImportModule(c.graph, c.module, fullpath.fileInfoIdx, c.cache)
        if m == nil: typ = nil
        else:
          for it in items(n.sym.tab):
            if filterSym(it, field, pm):
              outputs.add(symToSuggest(it, isLocal=false, ideSug, n.info, 100, pm, c.inTypeContext > 0, -100))
          outputs.add(symToSuggest(m, isLocal=false, ideMod, n.info, 100, PrefixMatch.None,
            c.inTypeContext > 0, -99))

  if typ == nil:
    # a module symbol has no type for example:
    if n.kind == nkSym and n.sym.kind == skModule:
      if n.sym == c.module:
        # all symbols accessible, because we are in the current module:
        for it in items(c.topLevelScope.symbols):
          if filterSym(it, field, pm):
            outputs.add(symToSuggest(it, isLocal=false, ideSug, n.info, 100, pm, c.inTypeContext > 0, -99))
      else:
        for it in items(n.sym.tab):
          if filterSym(it, field, pm):
            outputs.add(symToSuggest(it, isLocal=false, ideSug, n.info, 100, pm, c.inTypeContext > 0, -99))
    else:
      # fallback:
      suggestEverything(c, n, field, outputs)
  elif typ.kind == tyEnum and n.kind == nkSym and n.sym.kind == skType:
    # look up if the identifier belongs to the enum:
    var t = typ
    while t != nil:
      suggestSymList(c, t.n, field, n.info, outputs)
      t = t.sons[0]
    suggestOperations(c, n, field, typ, outputs)
  else:
    let orig = typ # skipTypes(typ, {tyGenericInst, tyAlias, tySink})
    typ = skipTypes(typ, {tyGenericInst, tyVar, tyLent, tyPtr, tyRef, tyAlias, tySink})
    if typ.kind == tyObject:
      var t = typ
      while true:
        suggestObject(c, t.n, field, n.info, outputs)
        if t.sons[0] == nil: break
        t = skipTypes(t.sons[0], skipPtrs)
    elif typ.kind == tyTuple and typ.n != nil:
      suggestSymList(c, typ.n, field, n.info, outputs)
    suggestOperations(c, n, field, orig, outputs)
    if typ != orig:
      suggestOperations(c, n, field, typ, outputs)

type
  TCheckPointResult* = enum
    cpNone, cpFuzzy, cpExact

proc inCheckpoint*(current: TLineInfo): TCheckPointResult =
  if current.fileIndex == gTrackPos.fileIndex:
    if current.line == gTrackPos.line and
        abs(current.col-gTrackPos.col) < 4:
      return cpExact
    if current.line >= gTrackPos.line:
      return cpFuzzy

proc isTracked*(current: TLineInfo, tokenLen: int): bool =
  if current.fileIndex==gTrackPos.fileIndex and current.line==gTrackPos.line:
    let col = gTrackPos.col
    if col >= current.col and col <= current.col+tokenLen-1:
      return true

when defined(nimsuggest):
  # Since TLineInfo defined a == operator that doesn't include the column,
  # we map TLineInfo to a unique int here for this lookup table:
  proc infoToInt(info: TLineInfo): int64 =
    info.fileIndex.int64 + info.line.int64 shl 32 + info.col.int64 shl 48

  proc addNoDup(s: PSym; info: TLineInfo) =
    # ensure nothing gets too slow:
    if s.allUsages.len > 500: return
    let infoAsInt = info.infoToInt
    for infoB in s.allUsages:
      if infoB.infoToInt == infoAsInt: return
    s.allUsages.add(info)

var
  lastLineInfo*: TLineInfo

proc findUsages(info: TLineInfo; s: PSym; usageSym: var PSym) =
  if suggestVersion == 1:
    if usageSym == nil and isTracked(info, s.name.s.len):
      usageSym = s
      suggestResult(symToSuggest(s, isLocal=false, ideUse, info, 100, PrefixMatch.None, false, 0))
    elif s == usageSym:
      if lastLineInfo != info:
        suggestResult(symToSuggest(s, isLocal=false, ideUse, info, 100, PrefixMatch.None, false, 0))
      lastLineInfo = info

when defined(nimsuggest):
  proc listUsages*(s: PSym) =
    #echo "usages ", len(s.allUsages)
    for info in s.allUsages:
      let x = if info == s.info and info.col == s.info.col: ideDef else: ideUse
      suggestResult(symToSuggest(s, isLocal=false, x, info, 100, PrefixMatch.None, false, 0))

proc findDefinition(info: TLineInfo; s: PSym) =
  if s.isNil: return
  if isTracked(info, s.name.s.len):
    suggestResult(symToSuggest(s, isLocal=false, ideDef, info, 100, PrefixMatch.None, false, 0))
    suggestQuit()

proc ensureIdx[T](x: var T, y: int) =
  if x.len <= y: x.setLen(y+1)

proc ensureSeq[T](x: var seq[T]) =
  if x == nil: newSeq(x, 0)

proc suggestSym*(info: TLineInfo; s: PSym; usageSym: var PSym; isDecl=true) {.inline.} =
  ## misnamed: should be 'symDeclared'
  when defined(nimsuggest):
    if suggestVersion == 0:
      if s.allUsages.isNil:
        s.allUsages = @[info]
      else:
        s.addNoDup(info)

    if gIdeCmd == ideUse:
      findUsages(info, s, usageSym)
    elif gIdeCmd == ideDef:
      findDefinition(info, s)
    elif gIdeCmd == ideDus and s != nil:
      if isTracked(info, s.name.s.len):
        suggestResult(symToSuggest(s, isLocal=false, ideDef, info, 100, PrefixMatch.None, false, 0))
      findUsages(info, s, usageSym)
    elif gIdeCmd == ideHighlight and info.fileIndex == gTrackPos.fileIndex:
      suggestResult(symToSuggest(s, isLocal=false, ideHighlight, info, 100, PrefixMatch.None, false, 0))
    elif gIdeCmd == ideOutline and info.fileIndex == gTrackPos.fileIndex and
        isDecl:
      suggestResult(symToSuggest(s, isLocal=false, ideOutline, info, 100, PrefixMatch.None, false, 0))

proc warnAboutDeprecated(conf: ConfigRef; info: TLineInfo; s: PSym) =
  if s.kind in routineKinds:
    let n = s.ast[pragmasPos]
    if n.kind != nkEmpty:
      for it in n:
        if whichPragma(it) == wDeprecated and it.safeLen == 2 and
            it[1].kind in {nkStrLit..nkTripleStrLit}:
          message(conf, info, warnDeprecated, it[1].strVal & "; " & s.name.s)
          return
  message(conf, info, warnDeprecated, s.name.s)

proc markUsed(conf: ConfigRef; info: TLineInfo; s: PSym; usageSym: var PSym) =
  incl(s.flags, sfUsed)
  if s.kind == skEnumField and s.owner != nil:
    incl(s.owner.flags, sfUsed)
  if {sfDeprecated, sfError} * s.flags != {}:
    if sfDeprecated in s.flags: warnAboutDeprecated(conf, info, s)
    if sfError in s.flags: localError(conf, info,  "usage of '$1' is a user-defined error" % s.name.s)
  when defined(nimsuggest):
    suggestSym(info, s, usageSym, false)

proc useSym*(conf: ConfigRef; sym: PSym; usageSym: var PSym): PNode =
  result = newSymNode(sym)
  markUsed(conf, result.info, sym, usageSym)

proc safeSemExpr*(c: PContext, n: PNode): PNode =
  # use only for idetools support!
  try:
    result = c.semExpr(c, n)
  except ERecoverableError:
    result = ast.emptyNode

proc sugExpr(c: PContext, n: PNode, outputs: var Suggestions) =
  if n.kind == nkDotExpr:
    var obj = safeSemExpr(c, n.sons[0])
    # it can happen that errnously we have collected the fieldname
    # of the next line, so we check the 'field' is actually on the same
    # line as the object to prevent this from happening:
    let prefix = if n.len == 2 and n[1].info.line == n[0].info.line and
       not gTrackPosAttached: n[1] else: nil
    suggestFieldAccess(c, obj, prefix, outputs)

    #if optIdeDebug in gGlobalOptions:
    #  echo "expression ", renderTree(obj), " has type ", typeToString(obj.typ)
    #writeStackTrace()
  else:
    let prefix = if gTrackPosAttached: nil else: n
    suggestEverything(c, n, prefix, outputs)

proc suggestExprNoCheck*(c: PContext, n: PNode) =
  # This keeps semExpr() from coming here recursively:
  if c.compilesContextId > 0: return
  inc(c.compilesContextId)
  var outputs: Suggestions = @[]
  if c.config.ideCmd == ideSug:
    sugExpr(c, n, outputs)
  elif c.config.ideCmd == ideCon:
    if n.kind in nkCallKinds:
      var a = copyNode(n)
      var x = safeSemExpr(c, n.sons[0])
      if x.kind == nkEmpty or x.typ == nil: x = n.sons[0]
      addSon(a, x)
      for i in 1..sonsLen(n)-1:
        # use as many typed arguments as possible:
        var x = safeSemExpr(c, n.sons[i])
        if x.kind == nkEmpty or x.typ == nil: break
        addSon(a, x)
      suggestCall(c, a, n, outputs)

  dec(c.compilesContextId)
  if outputs.len > 0 and c.config.ideCmd in {ideSug, ideCon, ideDef}:
    produceOutput(outputs, c.config)
    suggestQuit()

proc suggestExpr*(c: PContext, n: PNode) =
  if exactEquals(gTrackPos, n.info): suggestExprNoCheck(c, n)

proc suggestDecl*(c: PContext, n: PNode; s: PSym) =
  let attached = gTrackPosAttached
  if attached: inc(c.inTypeContext)
  defer:
    if attached: dec(c.inTypeContext)
  suggestExpr(c, n)

proc suggestStmt*(c: PContext, n: PNode) =
  suggestExpr(c, n)

proc suggestEnum*(c: PContext; n: PNode; t: PType) =
  var outputs: Suggestions = @[]
  suggestSymList(c, t.n, nil, n.info, outputs)
  produceOutput(outputs, c.config)
  if outputs.len > 0: suggestQuit()

proc suggestSentinel*(c: PContext) =
  if c.config.ideCmd != ideSug or c.module.position != gTrackPos.fileIndex.int32: return
  if c.compilesContextId > 0: return
  inc(c.compilesContextId)
  var outputs: Suggestions = @[]
  # suggest everything:
  var isLocal = true
  var scopeN = 0
  for scope in walkScopes(c.currentScope):
    if scope == c.topLevelScope: isLocal = false
    dec scopeN
    for it in items(scope.symbols):
      var pm: PrefixMatch
      if filterSymNoOpr(it, nil, pm):
        outputs.add(symToSuggest(it, isLocal = isLocal, ideSug, newLineInfo(gTrackPos.fileIndex, -1, -1), 0, PrefixMatch.None, false, scopeN))

  dec(c.compilesContextId)
  produceOutput(outputs, c.config)
