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

proc suggestExpr*(c: PContext, n: PNode) = 
  if not msgs.inCheckpoint(n.info): return

  for i in countdown(c.tab.tos-1, 0): 
    for it in items(c.tab.stack[i]): 
      if filterSym(it):
        MessageOut(SymToStr(it, isLocal = i > ModuleTablePos))
  quit(0)

proc suggestStmt*(c: PContext, n: PNode) = 
  suggestExpr(c, n)

proc suggestSymList(list: PNode) = 
  for i in countup(0, sonsLen(list) - 1): 
    if list.sons[i].kind != nkSym: InternalError(list.info, "getSymFromList")
    suggestField(list.sons[i].sym)

proc suggestObject(n: PNode) = 
  case n.kind
  of nkRecList: 
    for i in countup(0, sonsLen(n) - 1): suggestObject(n.sons[i])
  of nkRecCase: 
    var L = sonsLen(n)
    if L > 0:
      suggestObject(n.sons[0])
      for i in countup(1, L-1): 
        suggestObject(lastSon(n.sons[i]))
  of nkSym: suggestField(n.sym)
  else: nil

proc suggestOperations(c: PContext, n: PNode, typ: PType) =
  nil

proc suggestFieldAccess*(c: PContext, n: PNode) =
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
      suggestExpr(c, n)
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
      suggestExpr(c, n)

