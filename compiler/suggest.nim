#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This file implements features required for IDE support.

# included from sigmatch.nim

import algorithm, sequtils

when defined(nimsuggest):
  import passes, tables # importer

const
  sep = '\t'

type
  Suggest* = object
    section*: IdeCmd
    qualifiedPath*: seq[string]
    filePath*: string
    line*: int                   # Starts at 1
    column*: int                 # Starts at 0
    doc*: string           # Not escaped (yet)
    symkind*: TSymKind
    forth*: string               # XXX TODO object on symkind
    quality*: range[0..100]   # matching quality
    isGlobal*: bool # is a global variable
    tokenLen*: int

var
  suggestionResultHook*: proc (result: Suggest) {.closure.}
  suggestVersion*: int

#template sectionSuggest(): expr = "##begin\n" & getStackTrace() & "##end\n"

template origModuleName(m: PSym): string = m.name.s

proc symToSuggest(s: PSym, isLocal: bool, section: string, li: TLineInfo;
                  quality: range[0..100]): Suggest =
  result.section = parseIdeCmd(section)
  result.quality = quality
  result.isGlobal = sfGlobal in s.flags
  result.tokenLen = s.name.s.len
  if optIdeTerse in gGlobalOptions:
    result.symkind = s.kind
    result.filePath = toFullPath(li)
    result.line = toLinenumber(li)
    result.column = toColumn(li)
  else:
    result.symkind = s.kind
    result.qualifiedPath = @[]
    if not isLocal and s.kind != skModule:
      let ow = s.owner
      if ow.kind != skModule and ow.owner != nil:
        let ow2 = ow.owner
        result.qualifiedPath.add(ow2.origModuleName)
      result.qualifiedPath.add(ow.origModuleName)
    result.qualifiedPath.add(s.name.s)

    if s.typ != nil:
      result.forth = typeToString(s.typ)
    else:
      result.forth = ""
    result.filePath = toFullPath(li)
    result.line = toLinenumber(li)
    result.column = toColumn(li)
    when not defined(noDocgen):
      result.doc = s.extractDocComment

proc `$`(suggest: Suggest): string =
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
    if suggestVersion == 2:
      result.add(sep)
      result.add($suggest.quality)

proc symToSuggest(s: PSym, isLocal: bool, section: string;
                  quality: range[0..100]): Suggest =
  result = symToSuggest(s, isLocal, section, s.info, quality)

proc suggestResult(s: Suggest) =
  if not isNil(suggestionResultHook):
    suggestionResultHook(s)
  else:
    suggestWriteln($(s))

proc filterSym(s: PSym): bool {.inline.} =
  result = s.kind != skModule

proc filterSymNoOpr(s: PSym): bool {.inline.} =
  result = s.kind != skModule and s.name.s[0] in lexer.SymChars and
     not isKeyword(s.name)

proc fieldVisible*(c: PContext, f: PSym): bool {.inline.} =
  let fmoduleId = getModule(f).id
  result = sfExported in f.flags or fmoduleId == c.module.id
  for module in c.friendModules:
    if fmoduleId == module.id:
      result = true
      break

proc suggestField(c: PContext, s: PSym, outputs: var int) =
  if filterSym(s) and fieldVisible(c, s):
    suggestResult(symToSuggest(s, isLocal=true, $ideSug, 100))
    inc outputs

template wholeSymTab(cond, section: untyped) =
  var isLocal = true
  for scope in walkScopes(c.currentScope):
    if scope == c.topLevelScope: isLocal = false
    var entries = sequtils.toSeq(items(scope.symbols))
    sort(entries) do (a,b: PSym) -> int:
      return cmp(a.name.s, b.name.s)
    for item in entries:
      let it {.inject.} = item
      if cond:
        suggestResult(symToSuggest(it, isLocal = isLocal, section, 100))
        inc outputs

proc suggestSymList(c: PContext, list: PNode, outputs: var int) =
  for i in countup(0, sonsLen(list) - 1):
    if list.sons[i].kind == nkSym:
      suggestField(c, list.sons[i].sym, outputs)
    #else: InternalError(list.info, "getSymFromList")

proc suggestObject(c: PContext, n: PNode, outputs: var int) =
  case n.kind
  of nkRecList:
    for i in countup(0, sonsLen(n)-1): suggestObject(c, n.sons[i], outputs)
  of nkRecCase:
    var L = sonsLen(n)
    if L > 0:
      suggestObject(c, n.sons[0], outputs)
      for i in countup(1, L-1): suggestObject(c, lastSon(n.sons[i]), outputs)
  of nkSym: suggestField(c, n.sym, outputs)
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

proc suggestCall(c: PContext, n, nOrig: PNode, outputs: var int) =
  wholeSymTab(filterSym(it) and nameFits(c, it, n) and argsFit(c, it, n, nOrig),
              $ideCon)

proc typeFits(c: PContext, s: PSym, firstArg: PType): bool {.inline.} =
  if s.typ != nil and sonsLen(s.typ) > 1 and s.typ.sons[1] != nil:
    # special rule: if system and some weird generic match via 'tyExpr'
    # or 'tyGenericParam' we won't list it either to reduce the noise (nobody
    # wants 'system.`-|` as suggestion
    let m = s.getModule()
    if m != nil and sfSystemModule in m.flags:
      if s.kind == skType: return
      var exp = s.typ.sons[1].skipTypes({tyGenericInst, tyVar})
      if exp.kind == tyVarargs: exp = elemType(exp)
      if exp.kind in {tyExpr, tyStmt, tyGenericParam, tyAnything}: return
    result = sigmatch.argtypeMatches(c, s.typ.sons[1], firstArg)

proc suggestOperations(c: PContext, n: PNode, typ: PType, outputs: var int) =
  assert typ != nil
  wholeSymTab(filterSymNoOpr(it) and typeFits(c, it, typ), $ideSug)

proc suggestEverything(c: PContext, n: PNode, outputs: var int) =
  # do not produce too many symbols:
  var isLocal = true
  for scope in walkScopes(c.currentScope):
    if scope == c.topLevelScope: isLocal = false
    for it in items(scope.symbols):
      if filterSym(it):
        suggestResult(symToSuggest(it, isLocal = isLocal, $ideSug, 0))
        inc outputs
    if scope == c.topLevelScope: break

proc suggestFieldAccess(c: PContext, n: PNode, outputs: var int) =
  # special code that deals with ``myObj.``. `n` is NOT the nkDotExpr-node, but
  # ``myObj``.
  var typ = n.typ
  when defined(nimsuggest):
    if n.kind == nkSym and n.sym.kind == skError and suggestVersion == 2:
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
            if filterSym(it):
              suggestResult(symToSuggest(it, isLocal=false, $ideSug, 100))
              inc outputs
          suggestResult(symToSuggest(m, isLocal=false, $ideMod, 100))

  if typ == nil:
    # a module symbol has no type for example:
    if n.kind == nkSym and n.sym.kind == skModule:
      if n.sym == c.module:
        # all symbols accessible, because we are in the current module:
        for it in items(c.topLevelScope.symbols):
          if filterSym(it):
            suggestResult(symToSuggest(it, isLocal=false, $ideSug, 100))
            inc outputs
      else:
        for it in items(n.sym.tab):
          if filterSym(it):
            suggestResult(symToSuggest(it, isLocal=false, $ideSug, 100))
            inc outputs
    else:
      # fallback:
      suggestEverything(c, n, outputs)
  elif typ.kind == tyEnum and n.kind == nkSym and n.sym.kind == skType:
    # look up if the identifier belongs to the enum:
    var t = typ
    while t != nil:
      suggestSymList(c, t.n, outputs)
      t = t.sons[0]
    suggestOperations(c, n, typ, outputs)
  else:
    typ = skipTypes(typ, {tyGenericInst, tyVar, tyPtr, tyRef})
    if typ.kind == tyObject:
      var t = typ
      while true:
        suggestObject(c, t.n, outputs)
        if t.sons[0] == nil: break
        t = skipTypes(t.sons[0], skipPtrs)
      suggestOperations(c, n, typ, outputs)
    elif typ.kind == tyTuple and typ.n != nil:
      suggestSymList(c, typ.n, outputs)
      suggestOperations(c, n, typ, outputs)
    else:
      suggestOperations(c, n, typ, outputs)

type
  TCheckPointResult = enum
    cpNone, cpFuzzy, cpExact

proc inCheckpoint(current: TLineInfo): TCheckPointResult =
  if current.fileIndex == gTrackPos.fileIndex:
    if current.line == gTrackPos.line and
        abs(current.col-gTrackPos.col) < 4:
      return cpExact
    if current.line >= gTrackPos.line:
      return cpFuzzy

proc findClosestDot(n: PNode): PNode =
  if n.kind == nkDotExpr and inCheckpoint(n.info) == cpExact:
    result = n
  else:
    for i in 0.. <safeLen(n):
      result = findClosestDot(n.sons[i])
      if result != nil: return

proc findClosestCall(n: PNode): PNode =
  if n.kind in nkCallKinds and inCheckpoint(n.info) == cpExact:
    result = n
  else:
    for i in 0.. <safeLen(n):
      result = findClosestCall(n.sons[i])
      if result != nil: return

proc isTracked*(current: TLineInfo, tokenLen: int): bool =
  if current.fileIndex==gTrackPos.fileIndex and current.line==gTrackPos.line:
    let col = gTrackPos.col
    if col >= current.col and col <= current.col+tokenLen-1:
      return true

proc findClosestSym(n: PNode): PNode =
  if n.kind == nkSym and inCheckpoint(n.info) == cpExact:
    result = n
  elif n.kind notin {nkNone..nkNilLit}:
    for i in 0.. <sonsLen(n):
      result = findClosestSym(n.sons[i])
      if result != nil: return

when defined(nimsuggest):
  # Since TLineInfo defined a == operator that doesn't include the column,
  # we map TLineInfo to a unique int here for this lookup table:
  proc infoToInt(info: TLineInfo): int64 =
    info.fileIndex + info.line.int64 shl 32 + info.col.int64 shl 48

  proc addNoDup(s: PSym; info: TLineInfo) =
    let infoAsInt = info.infoToInt
    for infoB in s.allUsages:
      if infoB.infoToInt == infoAsInt: return
    s.allUsages.add(info)

var
  usageSym*: PSym
  lastLineInfo*: TLineInfo

proc findUsages(info: TLineInfo; s: PSym) =
  if suggestVersion < 2:
    if usageSym == nil and isTracked(info, s.name.s.len):
      usageSym = s
      suggestResult(symToSuggest(s, isLocal=false, $ideUse, 100))
    elif s == usageSym:
      if lastLineInfo != info:
        suggestResult(symToSuggest(s, isLocal=false, $ideUse, info, 100))
      lastLineInfo = info

when defined(nimsuggest):
  proc listUsages*(s: PSym) =
    #echo "usages ", len(s.allUsages)
    for info in s.allUsages:
      let x = if info == s.info and info.col == s.info.col: "def" else: "use"
      suggestResult(symToSuggest(s, isLocal=false, x, info, 100))

proc findDefinition(info: TLineInfo; s: PSym) =
  if s.isNil: return
  if isTracked(info, s.name.s.len):
    suggestResult(symToSuggest(s, isLocal=false, $ideDef, 100))
    suggestQuit()

proc ensureIdx[T](x: var T, y: int) =
  if x.len <= y: x.setLen(y+1)

proc ensureSeq[T](x: var seq[T]) =
  if x == nil: newSeq(x, 0)

proc suggestSym*(info: TLineInfo; s: PSym; isDecl=true) {.inline.} =
  ## misnamed: should be 'symDeclared'
  when defined(nimsuggest):
    if suggestVersion == 2:
      if s.allUsages.isNil:
        s.allUsages = @[info]
      else:
        s.addNoDup(info)

    if gIdeCmd == ideUse:
      findUsages(info, s)
    elif gIdeCmd == ideDef:
      findDefinition(info, s)
    elif gIdeCmd == ideDus and s != nil:
      if isTracked(info, s.name.s.len):
        suggestResult(symToSuggest(s, isLocal=false, $ideDef, 100))
      findUsages(info, s)
    elif gIdeCmd == ideHighlight and info.fileIndex == gTrackPos.fileIndex:
      suggestResult(symToSuggest(s, isLocal=false, $ideHighlight, info, 100))
    elif gIdeCmd == ideOutline and info.fileIndex == gTrackPos.fileIndex and
        isDecl:
      suggestResult(symToSuggest(s, isLocal=false, $ideOutline, info, 100))

proc markUsed(info: TLineInfo; s: PSym) =
  incl(s.flags, sfUsed)
  if s.kind == skEnumField and s.owner != nil:
    incl(s.owner.flags, sfUsed)
  if {sfDeprecated, sfError} * s.flags != {}:
    if sfDeprecated in s.flags: message(info, warnDeprecated, s.name.s)
    if sfError in s.flags: localError(info, errWrongSymbolX, s.name.s)
  when defined(nimsuggest):
    suggestSym(info, s, false)

proc useSym*(sym: PSym): PNode =
  result = newSymNode(sym)
  markUsed(result.info, sym)

proc safeSemExpr*(c: PContext, n: PNode): PNode =
  # use only for idetools support!
  try:
    result = c.semExpr(c, n)
  except ERecoverableError:
    result = ast.emptyNode

proc suggestExpr*(c: PContext, node: PNode) =
  if gTrackPos.line < 0: return
  var cp = inCheckpoint(node.info)
  if cp == cpNone: return
  var outputs = 0
  # This keeps semExpr() from coming here recursively:
  if c.compilesContextId > 0: return
  inc(c.compilesContextId)

  if gIdeCmd == ideSug:
    var n = findClosestDot(node)
    if n == nil: n = node
    if n.kind == nkDotExpr:
      var obj = safeSemExpr(c, n.sons[0])
      suggestFieldAccess(c, obj, outputs)

      #if optIdeDebug in gGlobalOptions:
      #  echo "expression ", renderTree(obj), " has type ", typeToString(obj.typ)
      #writeStackTrace()
    else:
      suggestEverything(c, n, outputs)

  elif gIdeCmd == ideCon:
    var n = findClosestCall(node)
    if n == nil: n = node
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
  if outputs > 0 and gIdeCmd in {ideSug, ideCon, ideDef}: suggestQuit()

proc suggestStmt*(c: PContext, n: PNode) =
  suggestExpr(c, n)
