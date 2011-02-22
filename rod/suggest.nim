#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This file implements features required for IDE support.

import scanner, idents, ast, astalgo, semdata, msgs, types, sigmatch

const
  sep = '\t'

proc SymToStr(s: PSym, isLocal: bool): string = 
  result = ""
  result.add($s.kind)
  result.add(sep)
  if not isLocal: 
    if s.kind != skModule and s.owner != nil: 
      result.add(s.owner.name.s)
      result.add('.')
  result.add(s.name.s)
  result.add(sep)
  if s.typ != nil: 
    result.add(typeToString(s.typ))
  result.add(sep)
  result.add(toFilename(s.info))
  result.add(sep)
  result.add($ToLinenumber(s.info))
  result.add(sep)
  result.add($ToColumn(s.info))

proc filterSym(s: PSym): bool {.inline.} = 
  result = s.name.s[0] in scanner.SymChars

proc suggestField(s: PSym) = 
  if filterSym(s):
    MessageOut(SymToStr(s, isLocal=true))

template wholeSymTab(cond: expr) = 
  for i in countdown(c.tab.tos-1, 0): 
    for it in items(c.tab.stack[i]): 
      if cond:
        MessageOut(SymToStr(it, isLocal = i > ModuleTablePos))

proc suggestSymList(list: PNode) = 
  for i in countup(0, sonsLen(list) - 1): 
    if list.sons[i].kind != nkSym: InternalError(list.info, "getSymFromList")
    suggestField(list.sons[i].sym)

proc suggestObject(n: PNode) = 
  case n.kind
  of nkRecList: 
    for i in countup(0, sonsLen(n)-1): suggestObject(n.sons[i])
  of nkRecCase: 
    var L = sonsLen(n)
    if L > 0:
      suggestObject(n.sons[0])
      for i in countup(1, L-1): suggestObject(lastSon(n.sons[i]))
  of nkSym: suggestField(n.sym)
  else: nil

proc nameFits(c: PContext, s: PSym, n: PNode): bool = 
  var op = n.sons[0]
  if op.kind == nkSymChoice: op = op.sons[0]
  var opr: PIdent
  case op.kind
  of nkSym: opr = op.sym.name
  of nkIdent: opr = op.ident
  else: return false
  result = opr.id == s.name.id

proc argsFit(c: PContext, candidate: PSym, n: PNode): bool = 
  case candidate.kind 
  of skProc, skIterator, skMethod:
    var m: TCandidate
    initCandidate(m, candidate, nil)
    sigmatch.partialMatch(c, n, m)
    result = m.state != csNoMatch
  of skTemplate, skMacro:
    result = true
  else:
    result = false

proc suggestCall(c: PContext, n: PNode) = 
  wholeSymTab(filterSym(it) and nameFits(c, it, n) and argsFit(c, it, n))

proc typeFits(c: PContext, s: PSym, firstArg: PType): bool {.inline.} = 
  if s.typ != nil and sonsLen(s.typ) > 1 and s.typ.sons[1] != nil:
    result = sigmatch.argtypeMatches(c, s.typ.sons[1], firstArg)

proc suggestOperations(c: PContext, n: PNode, typ: PType) =
  assert typ != nil
  wholeSymTab(filterSym(it) and typeFits(c, it, typ))

proc suggestEverything(c: PContext, n: PNode) = 
  wholeSymTab(filterSym(it))

proc suggestFieldAccess(c: PContext, n: PNode) =
  # special code that deals with ``myObj.``. `n` is NOT the nkDotExpr-node, but
  # ``myObj``.
  var typ = n.Typ
  if typ == nil:
    # a module symbol has no type for example:
    if n.kind == nkSym and n.sym.kind == skModule: 
      if n.sym == c.module: 
        # all symbols accessible, because we are in the current module:
        for it in items(c.tab.stack[ModuleTablePos]): 
          if filterSym(it): MessageOut(SymToStr(it, isLocal=false))
      else: 
        for it in items(n.sym.tab): 
          if filterSym(it): MessageOut(SymToStr(it, isLocal=false))
    else:
      # fallback:
      suggestEverything(c, n)
  elif typ.kind == tyEnum: 
    # look up if the identifier belongs to the enum:
    var t = typ
    while t != nil: 
      suggestSymList(t.n)
      t = t.sons[0]
    suggestOperations(c, n, typ)
  else:
    typ = skipTypes(typ, {tyGenericInst, tyVar, tyPtr, tyRef})
    if typ.kind == tyObject: 
      var t = typ
      while true: 
        suggestObject(t.n)
        if t.sons[0] == nil: break 
        t = skipTypes(t.sons[0], {tyGenericInst})
      suggestOperations(c, n, typ)
    elif typ.kind == tyTuple and typ.n != nil: 
      suggestSymList(typ.n)
      suggestOperations(c, n, typ)
    else:
      # fallback: 
      suggestEverything(c, n)

proc interestingNode(n: PNode): bool {.inline.} =
  result = n.kind == nkDotExpr

proc findClosestNode(n: PNode): PNode = 
  if msgs.inCheckpoint(n.info) == cpExact: 
    result = n
  elif n.kind notin {nkNone..nkNilLit}:
    for i in 0.. <sonsLen(n):
      if interestingNode(n.sons[i]):
        result = findClosestNode(n.sons[i])
        if result != nil: return

var recursiveCheck = 0

proc suggestExpr*(c: PContext, node: PNode) = 
  var cp = msgs.inCheckpoint(node.info)
  if cp == cpNone: return
  # HACK: This keeps semExpr() from coming here recursively:
  if recursiveCheck > 0: return
  inc(recursiveCheck)
  var n = findClosestNode(node)
  if n == nil: n = node
  else: cp = msgs.inCheckpoint(n.info)
  block:
    case n.kind
    of nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand, 
        nkCallStrLit, nkMacroStmt: 
      when false:
        # this provides "context information", not "type suggestion":
        var a = copyNode(n)
        var x = c.semExpr(c, n.sons[0])
        if x.kind == nkEmpty or x.typ == nil: x = n.sons[0]
        addSon(a, x)
        for i in 1..sonsLen(n)-1:
          # use as many typed arguments as possible:
          var x = c.semExpr(c, n.sons[i])
          if x.kind == nkEmpty or x.typ == nil: break
          addSon(a, x)
        suggestCall(c, a)
        break
      else:
        nil
    of nkDotExpr: 
      if cp == cpExact:
        var obj = c.semExpr(c, n.sons[0])
        suggestFieldAccess(c, obj)
        break
    else: nil
    suggestEverything(c, n)
  quit(0)

proc suggestStmt*(c: PContext, n: PNode) = 
  suggestExpr(c, n)

