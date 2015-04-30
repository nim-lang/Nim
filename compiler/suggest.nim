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

const
  sep = '\t'
  sectionSuggest = "sug"
  sectionDef = "def"
  sectionContext = "con"
  sectionUsage = "use"

#template sectionSuggest(): expr = "##begin\n" & getStackTrace() & "##end\n"

template origModuleName(m: PSym): string = m.name.s

proc symToStr(s: PSym, isLocal: bool, section: string, li: TLineInfo): string = 
  result = section
  result.add(sep)
  if optIdeTerse in gGlobalOptions:
    if s.kind in routineKinds:
      result.add renderTree(s.ast, {renderNoBody, renderNoComments,
                                    renderDocComments, renderNoPragmas})
    else:
      result.add s.name.s
    result.add(sep)
    result.add(toFullPath(li))
    result.add(sep)
    result.add($toLinenumber(li))
    result.add(sep)
    result.add($toColumn(li))
  else:
    result.add($s.kind)
    result.add(sep)
    if not isLocal and s.kind != skModule:
      let ow = s.owner
      if ow.kind != skModule and ow.owner != nil:
        let ow2 = ow.owner
        result.add(ow2.origModuleName)
        result.add('.')
      result.add(ow.origModuleName)
      result.add('.')
    result.add(s.name.s)
    result.add(sep)
    if s.typ != nil: 
      result.add(typeToString(s.typ))
    result.add(sep)
    result.add(toFullPath(li))
    result.add(sep)
    result.add($toLinenumber(li))
    result.add(sep)
    result.add($toColumn(li))
    result.add(sep)
    when not defined(noDocgen):
      result.add(s.extractDocComment.escape)

proc symToStr(s: PSym, isLocal: bool, section: string): string = 
  result = symToStr(s, isLocal, section, s.info)

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
    suggestWriteln(symToStr(s, isLocal=true, sectionSuggest))
    inc outputs

template wholeSymTab(cond, section: expr) {.immediate.} =
  var isLocal = true
  for scope in walkScopes(c.currentScope):
    if scope == c.topLevelScope: isLocal = false
    var entries = sequtils.toSeq(items(scope.symbols))
    sort(entries) do (a,b: PSym) -> int:
      return cmp(a.name.s, b.name.s)
    for item in entries:
      let it {.inject.} = item
      if cond:
        suggestWriteln(symToStr(it, isLocal = isLocal, section))
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
              sectionContext)

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
  wholeSymTab(filterSymNoOpr(it) and typeFits(c, it, typ), sectionSuggest)

proc suggestEverything(c: PContext, n: PNode, outputs: var int) =
  # do not produce too many symbols:
  var isLocal = true
  for scope in walkScopes(c.currentScope):
    if scope == c.topLevelScope: isLocal = false
    for it in items(scope.symbols):
      if filterSym(it):
        suggestWriteln(symToStr(it, isLocal = isLocal, sectionSuggest))
        inc outputs
    if scope == c.topLevelScope: break

proc suggestFieldAccess(c: PContext, n: PNode, outputs: var int) =
  # special code that deals with ``myObj.``. `n` is NOT the nkDotExpr-node, but
  # ``myObj``.
  var typ = n.typ
  if typ == nil:
    # a module symbol has no type for example:
    if n.kind == nkSym and n.sym.kind == skModule: 
      if n.sym == c.module: 
        # all symbols accessible, because we are in the current module:
        for it in items(c.topLevelScope.symbols):
          if filterSym(it): 
            suggestWriteln(symToStr(it, isLocal=false, sectionSuggest))
            inc outputs
      else: 
        for it in items(n.sym.tab): 
          if filterSym(it): 
            suggestWriteln(symToStr(it, isLocal=false, sectionSuggest))
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
        t = skipTypes(t.sons[0], {tyGenericInst})
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

proc isTracked(current: TLineInfo, tokenLen: int): bool =
  if current.fileIndex == gTrackPos.fileIndex:
    if current.line == gTrackPos.line:
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

var
  usageSym*: PSym
  lastLineInfo: TLineInfo

proc findUsages(info: TLineInfo; s: PSym) =
  if usageSym == nil and isTracked(info, s.name.s.len):
    usageSym = s
    suggestWriteln(symToStr(s, isLocal=false, sectionUsage))
  elif s == usageSym:
    if lastLineInfo != info:
      suggestWriteln(symToStr(s, isLocal=false, sectionUsage, info))
    lastLineInfo = info

proc findDefinition(info: TLineInfo; s: PSym) =
  if s.isNil: return
  if isTracked(info, s.name.s.len):
    suggestWriteln(symToStr(s, isLocal=false, sectionDef))
    suggestQuit()

proc ensureIdx[T](x: var T, y: int) =
  if x.len <= y: x.setLen(y+1)

proc ensureSeq[T](x: var seq[T]) =
  if x == nil: newSeq(x, 0)

proc suggestSym*(info: TLineInfo; s: PSym) {.inline.} =
  ## misnamed: should be 'symDeclared'
  if gIdeCmd == ideUse:
    findUsages(info, s)
  elif gIdeCmd == ideDef:
    findDefinition(info, s)

proc markUsed(info: TLineInfo; s: PSym) =
  incl(s.flags, sfUsed)
  if {sfDeprecated, sfError} * s.flags != {}:
    if sfDeprecated in s.flags: message(info, warnDeprecated, s.name.s)
    if sfError in s.flags: localError(info, errWrongSymbolX, s.name.s)
  suggestSym(info, s)

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
  if nfIsCursor notin node.flags:
    if gTrackPos.line < 0: return
    var cp = inCheckpoint(node.info)
    if cp == cpNone: return
  var outputs = 0
  # This keeps semExpr() from coming here recursively:
  if c.inCompilesContext > 0: return
  inc(c.inCompilesContext)

  if gIdeCmd == ideSug:
    var n = if nfIsCursor in node.flags: node else: findClosestDot(node)
    if n == nil: n = node
    if n.kind == nkDotExpr:
      var obj = safeSemExpr(c, n.sons[0])
      suggestFieldAccess(c, obj, outputs)
      if optIdeDebug in gGlobalOptions:
        echo "expression ", renderTree(obj), " has type ", typeToString(obj.typ)
      #writeStackTrace()
    else:
      suggestEverything(c, n, outputs)
  
  elif gIdeCmd == ideCon:
    var n = if nfIsCursor in node.flags: node else: findClosestCall(node)
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
          
  dec(c.inCompilesContext)
  if outputs > 0 and gIdeCmd != ideUse: suggestQuit()

proc suggestStmt*(c: PContext, n: PNode) = 
  suggestExpr(c, n)
