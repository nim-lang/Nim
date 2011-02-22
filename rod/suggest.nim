#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This file implements features required for IDE support.

import scanner, ast, astalgo, semdata, msgs, types, sigmatch

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
  result = n.sons[0].kind == nkSym and n.sons[0].sym.name.id == s.name.id

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

proc suggestCall*(c: PContext, n: PNode) = 
  wholeSymTab(filterSym(it) and nameFits(c, it, n) and argsFit(c, it, n))

proc typeFits(c: PContext, s: PSym, firstArg: PType): bool {.inline.} = 
  if s.typ != nil and sonsLen(s.typ) > 1:
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

proc suggestExpr*(c: PContext, n: PNode) = 
  var cp = msgs.inCheckpoint(n.info)
  if cp == cpNone: return
  block:
    case n.kind
    of nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand, 
        nkCallStrLit, nkMacroStmt: 
      var a = copyNode(n)
      for i in 0..sonsLen(n)-1:
        # use as many typed arguments as possible:
        var x = c.semExpr(c, n.sons[i])
        if x.kind == nkEmpty or x.typ == nil: break
        addSon(a, x)
      suggestCall(c, n)
      break
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

