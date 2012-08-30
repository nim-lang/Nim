#
#
#           The Nimrod Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the pattern matching features for term rewriting
## macro support.

import ast, astalgo, types, semdata, sigmatch, msgs, idents

type
  TPatternContext = object
    owner: PSym
    mapping: TIdNodeTable  # maps formal parameters to nodes
    c: PContext
  PPatternContext = var TPatternContext

proc matches(c: PPatternContext, p, n: PNode): bool
proc checkConstraints(c: PPatternContext, p, n: PNode): bool =
  # XXX create a new mapping here? --> need use cases
  result = matches(c, p, n)

proc canonKind(n: PNode): TNodeKind =
  ## nodekind canonilization for pattern matching
  result = n.kind
  case result
  of nkCallKinds: result = nkCall
  of nkStrLit..nkTripleStrLit: result = nkStrLit
  of nkFastAsgn: result = nkAsgn
  else: nil

proc sameKinds(a, b: PNode): bool {.inline.} =
  result = a.kind == b.kind or a.canonKind == b.canonKind

proc sameTrees(a, b: PNode): bool =
  if sameKinds(a, b):
    case a.kind
    of nkSym: result = a.sym == b.sym
    of nkIdent: result = a.ident.id == b.ident.id
    of nkCharLit..nkInt64Lit: result = a.intVal == b.intVal
    of nkFloatLit..nkFloat64Lit: result = a.floatVal == b.floatVal
    of nkStrLit..nkTripleStrLit: result = a.strVal == b.strVal
    of nkEmpty, nkNilLit: result = true
    of nkType: result = sameTypeOrNil(a.typ, b.typ)
    else:
      if sonsLen(a) == sonsLen(b):
        for i in countup(0, sonsLen(a) - 1):
          if not sameTrees(a.sons[i], b.sons[i]): return
        result = true

proc inSymChoice(sc, x: PNode): bool =
  if sc.kind in {nkOpenSymChoice, nkClosedSymChoice}:
    for i in 0.. <sc.len:
      if sc.sons[i].sym == x.sym: return true

proc checkTypes(c: PPatternContext, p: PSym, n: PNode): bool =
  # XXX tyVarargs is special here; lots of other special cases
  if isNil(n.typ):
    result = p.typ.kind == tyStmt
  else:
    result = sigmatch.argtypeMatches(c.c, p.typ, n.typ)

proc matches(c: PPatternContext, p, n: PNode): bool =
  # XXX special treatment: statement list,
  # ignore comments, nkPar, hidden conversions
  # f(..X) ~> how can 'X' stand for all remaining parameters? -> introduce
  # a new local node kind (alias of nkReturnToken or something)
  if p.kind == nkSym and p.sym.kind == skParam and p.sym.owner == c.owner:
    var pp = IdNodeTableGetLazy(c.mapping, p.sym)
    if pp != nil:
      # check if we got the same pattern (already unified):
      result = matches(c, pp, n)
    elif checkTypes(c, p.sym, n) and 
        (p.sym.ast == nil or checkConstraints(c, p.sym.ast, n)):
      IdNodeTablePutLazy(c.mapping, p.sym, n)
      result = true
  elif n.kind == nkSym and inSymChoice(p, n):
    result = true
  elif n.kind == nkSym and n.sym.kind == skConst:
    # try both:
    if sameTrees(p, n): result = true
    elif matches(c, p, n.sym.ast):
      result = true
  elif sameKinds(p, n):
    case p.kind
    of nkSym: result = p.sym == n.sym
    of nkIdent: result = p.ident.id == n.ident.id
    of nkCharLit..nkInt64Lit: result = p.intVal == n.intVal
    of nkFloatLit..nkFloat64Lit: result = p.floatVal == n.floatVal
    of nkStrLit..nkTripleStrLit: result = p.strVal == n.strVal
    of nkEmpty, nkNilLit, nkType: 
      result = true
      # of nkStmtList:
      # both are statement lists; we need to ignore comment statements and
      # 'nil' statements and check whether p <: n which is however trivially
      # checked as 'applyRule' is checked after every created statement
      # already; We need to ensure that the matching span is passed to the
      # macro and NOT simply 'n'!
      # XXX
    else:
      if sonsLen(p) == sonsLen(n):
        for i in countup(0, sonsLen(p) - 1):
          if not matches(c, p.sons[i], n.sons[i]): return
        result = true

# writeln(X, a); writeln(X, b); --> writeln(X, a, b)

proc applyRule*(c: PContext, s: PSym, n: PNode): PNode =
  ## returns a tree to semcheck if the rule triggered; nil otherwise
  var ctx: TPatternContext
  ctx.owner = s
  ctx.c = c
  # we perform 'initIdNodeTable' lazily for performance
  if matches(ctx, s.ast.sons[patternPos], n):
    # each parameter should have been bound; we simply setup a call and
    # let semantic checking deal with the rest :-)
    # this also saves type checking if we allow for type checking errors
    # as in 'system.compiles' and simply discard the results. But an error
    # may have been desired in the first place! Meh, it's good enough for
    # a first implementation:
    result = newNodeI(nkCall, n.info)
    result.add(newSymNode(s, n.info))
    let params = s.typ.n
    for i in 1 .. < params.len:
      let param = params.sons[i].sym
      let x = IdNodeTableGetLazy(ctx.mapping, param)
      # couldn't bind parameter:
      if isNil(x): return nil
      result.add(x)
    markUsed(n, s)
