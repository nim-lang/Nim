#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Injects destructor calls into Nim code as well as
## an optimizer that optimizes copies to moves. This is implemented as an
## AST to AST transformation so that every backend benefits from it.

## Rules for destructor injections:
##
## foo(bar(X(), Y()))
## X and Y get destroyed after bar completes:
##
## foo( (tmpX = X(); tmpY = Y(); tmpBar = bar(tmpX, tmpY);
##       destroy(tmpX); destroy(tmpY);
##       tmpBar))
## destroy(tmpBar)
##
## var x = f()
## body
##
## is the same as:
##
##  var x;
##  try:
##    move(x, f())
##  finally:
##    destroy(x)
##
## But this really just an optimization that tries to avoid to
## introduce too many temporaries, the 'destroy' is caused by
## the 'f()' call. No! That is not true for 'result = f()'!
##
## x = y where y is read only once
## is the same as:  move(x, y)
##
## Actually the more general rule is: The *last* read of ``y``
## can become a move if ``y`` is the result of a construction.
##
## We also need to keep in mind here that the number of reads is
## control flow dependent:
## let x = foo()
## while true:
##   y = x  # only one read, but the 2nd iteration will fail!
## This also affects recursions! Only usages that do not cross
## a loop boundary (scope) and are not used in function calls
## are safe.
##
##
## x = f() is the same as:  move(x, f())
##
## x = y
## is the same as:  copy(x, y)
##
## Reassignment works under this scheme:
## var x = f()
## x = y
##
## is the same as:
##
##  var x;
##  try:
##    move(x, f())
##    copy(x, y)
##  finally:
##    destroy(x)
##
##  result = f()  must not destroy 'result'!
##
## The produced temporaries clutter up the code and might lead to
## inefficiencies. A better strategy is to collect all the temporaries
## in a single object that we put into a single try-finally that
## surrounds the proc body. This means the code stays quite efficient
## when compiled to C.
##
## foo(bar(X(), Y()))
## X and Y get destroyed after bar completes:
##
## var tmp: object
## foo( (move tmp.x, X(); move tmp.y, Y(); tmp.bar = bar(tmpX, tmpY);
##       tmp.bar))
## destroy(tmp.bar)
## destroy(tmp.x); destroy(tmp.y)


import
  intsets, ast, astalgo, msgs, renderer, magicsys, types, idents, trees,
  strutils, options, dfa, lowerings

template hasDestructor(t: PType): bool = tfHasAsgn in t.flags

when false:
  type
    VarInfo = object
      hasInitValue: bool
      addrTaken: bool
      assigned: int      # we don't care about the 'var' vs 'let'
                        # distinction; it's an optimization pass
      read: int
      scope: int         # the scope the variable is declared in

    Con = object
      t: Table[int, VarInfo]
      owner: PSym
      scope: int

  const
    InterestingSyms = {skVar, skResult}

  proc collectData(c: var Con; n: PNode)

  proc collectDef(c: var Con; n: PNode; hasInitValue: bool) =
    if n.kind == nkSym:
      c.t[n.sym.id] = VarInfo(hasInitValue: hasInitValue,
                              addrTaken: false, assigned: 0, read: 0,
                              scope: scope)

  proc collectVarSection(c: var Con; n: PNode) =
    for a in n:
      if a.kind == nkCommentStmt: continue
      if a.kind == nkVarTuple:
        collectData(c, a.lastSon)
        for i in 0 .. a.len-3: collectDef(c, a[i], a.lastSon != nil)
      else:
        collectData(c, a.lastSon)
        if a.lastSon.kind != nkEmpty:
          collectDef(c, a.sons[0], a.lastSon != nil)

  proc collectData(c: var Con; n: PNode) =
    case n.kind
    of nkAsgn, nkFastAsgn:
      if n[0].kind == nkSym and (let s = n[0].sym; s.owner == c.owner and
                                s.kind in InterestingSyms):
        inc c.t[s.id].assigned
      collectData(c, n[1])
    of nkSym:
      if (let s = n[0].sym; s.owner == c.owner and
          s.kind in InterestingSyms):
        inc c.t[s.id].read
    of nkAddr, nkHiddenAddr:
      var n = n[0]
      while n.kind == nkBracketExpr: n = n[0]
      if (let s = n[0].sym; s.owner == c.owner and
          s.kind in InterestingSyms):
        c.t[s.id].addrTaken = true

    of nkCallKinds:
      if n.sons[0].kind == nkSym:
        let s = n.sons[0].sym
        if s.magic != mNone:
          genMagic(c, n, s.magic)
        else:
          genCall(c, n)
      else:
        genCall(c, n)
    of nkCharLit..nkNilLit, nkIdent: discard
    of nkDotExpr, nkCheckedFieldExpr, nkBracketExpr,
        nkDerefExpr, nkHiddenDeref:
      collectData(c, n[0])
    of nkIfStmt, nkIfExpr: genIf(c, n)
    of nkWhenStmt:
      # This is "when nimvm" node. Chose the first branch.
      collectData(c, n.sons[0].sons[1])
    of nkCaseStmt: genCase(c, n)
    of nkWhileStmt: genWhile(c, n)
    of nkBlockExpr, nkBlockStmt: genBlock(c, n)
    of nkReturnStmt: genReturn(c, n)
    of nkRaiseStmt: genRaise(c, n)
    of nkBreakStmt: genBreak(c, n)
    of nkTryStmt: genTry(c, n)
    of nkStmtList, nkStmtListExpr, nkChckRangeF, nkChckRange64, nkChckRange,
        nkBracket, nkCurly, nkPar, nkClosure, nkObjConstr:
      for x in n: collectData(c, x)
    of nkPragmaBlock: collectData(c, n.lastSon)
    of nkDiscardStmt: collectData(c, n.sons[0])
    of nkHiddenStdConv, nkHiddenSubConv, nkConv, nkExprColonExpr, nkExprEqExpr,
        nkCast:
      collectData(c, n.sons[1])
    of nkObjDownConv, nkStringToCString, nkCStringToString:
      collectData(c, n.sons[0])
    of nkVarSection, nkLetSection: collectVarSection(c, n)
    else: discard

proc injectDestructorCalls*(owner: PSym; n: PNode;
                            disableExceptions = false): PNode =
  when false:
    var c = Con(t: initTable[int, VarInfo](), owner: owner)
    collectData(c, n)
  var allTemps = createObj(owner, n.info)

