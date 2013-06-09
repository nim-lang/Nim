#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the 'implies' relation for guards.

import ast, astalgo, msgs, magicsys, nimsets, trees, types, renderer

const
  someEq = {mEqI, mEqI64, mEqF64, mEqEnum, mEqCh, mEqB, mEqRef, mEqProc, 
    mEqUntracedRef, mEqStr, mEqSet, mEqCString}
  
  # set excluded here as the semantics are vastly different:
  someLe = {mLeI, mLeI64, mLeF64, mLeU, mLeU64, mLeEnum,  
            mLeCh, mLeB, mLePtr, mLeStr}
  someLt = {mLtI, mLtI64, mLtF64, mLtU, mLtU64, mLtEnum, 
            mLtCh, mLtB, mLtPtr, mLtStr}

  someLen = {mLengthOpenArray, mLengthStr, mLengthArray, mLengthSeq}

  someIn = {mInRange, mInSet}

proc isValue(n: PNode): bool = n.kind in {nkCharLit..nkNilLit}
proc isLocation(n: PNode): bool = not n.isValue
#n.kind in {nkSym, nkBracketExpr, nkDerefExpr, nkHiddenDeref, nkDotExpr}

proc isLet(n: PNode): bool =
  if n.kind == nkSym:
    # XXX allow skResult, skVar here if not re-bound
    if n.sym.kind in {skLet, skTemp, skForVar}:
      result = true
    elif n.sym.kind == skParam and skipTypes(n.sym.typ, 
                                             abstractInst).kind != tyVar:
      result = true

proc isLetLocation(m: PNode): bool =
  var n = m
  while true:
    case n.kind
    of nkDotExpr, nkCheckedFieldExpr, nkObjUpConv, nkObjDownConv:
      n = n.sons[0]
    of nkBracketExpr:
      if isConstExpr(n.sons[1]) or isLet(n.sons[1]):
        n = n.sons[0]
      else: return
    of nkHiddenStdConv, nkHiddenSubConv, nkConv:
      n = n.sons[1]
    else:
      break
  result = n.isLet

proc neg(n: PNode): PNode =
  if n.getMagic == mNot:
    result = n.sons[1]
  else:
    result = newNodeI(nkCall, n.info, 2)
    result.sons[0] = newSymNode(getSysMagic("not", mNot))
    result.sons[1] = n

proc usefulFact(n: PNode): PNode =
  case n.getMagic
  of someEq+someLe+someLt:
    if isLetLocation(n.sons[1]) or n.len == 3 and isLetLocation(n.sons[2]):
      # XXX algebraic simplifications!  'i-1 < a.len' --> 'i < a.len+1'
      result = n
  of someIn, mIsNil:
    if isLetLocation(n.sons[1]):
      result = n
  of mAnd:
    let
      a = usefulFact(n.sons[1])
      b = usefulFact(n.sons[2])
    if a != nil and b != nil:
      result = newNodeI(nkCall, n.info, 3)
      result.sons[0] = newSymNode(getSysMagic("and", mAnd))
      result.sons[1] = a
      result.sons[2] = b
    elif a != nil:
      result = a
    elif b != nil:
      result = b
  of mNot:
    case n.sons[1].getMagic
    of mNot:
      # normalize 'not (not a)' into 'a':
      result = usefulFact(n.sons[1].sons[1])
    of mOr:
      # not (a or b) --> not a and not b
      let n = n.sons[1]
      let
        a = usefulFact(n.sons[1])
        b = usefulFact(n.sons[2])
      if a != nil and b != nil:
        result = newNodeI(nkCall, n.info, 3)
        result.sons[0] = newSymNode(getSysMagic("and", mAnd))
        result.sons[1] = a.neg
        result.sons[2] = b.neg
    else:
      let a = usefulFact(n.sons[1])
      if a != nil: result = n
  of mOr:
    # 'or' sucks! (p.isNil or q.isNil) --> hard to do anything
    # with that knowledge...
    # DeMorgan helps a little though: 
    #   not a or not b --> not (a and b)
    #  (x == 3) or (y == 2)  ---> not ( not (x==3) and not (y == 2))
    #  not (x != 3 and y != 2)
    let
      a = usefulFact(n.sons[1])
      b = usefulFact(n.sons[2])
    if a != nil and b != nil:
      result = newNodeI(nkCall, n.info, 3)
      result.sons[0] = newSymNode(getSysMagic("and", mAnd))
      result.sons[1] = a.neg
      result.sons[2] = b.neg
      result = result.neg
  elif n.kind == nkSym and n.sym.kind == skLet:
    # consider:
    #   let a = 2 < x
    #   if a:
    #     ...
    # We make can easily replace 'a' by '2 < x' here:
    result = usefulFact(n.sym.ast)
  elif n.kind == nkStmtListExpr:
    result = usefulFact(n.lastSon)

type
  TModel* = seq[PNode] # the "knowledge base"

proc addFact*(m: var TModel, n: PNode) =
  let n = usefulFact(n)
  if n != nil: m.add n

proc addFactNeg*(m: var TModel, n: PNode) = addFact(m, n.neg)

proc sameTree(a, b: PNode): bool = 
  result = false
  if a == b:
    result = true
  elif (a != nil) and (b != nil) and (a.kind == b.kind):
    case a.kind
    of nkSym: result = a.sym == b.sym
    of nkIdent: result = a.ident.id == b.ident.id
    of nkCharLit..nkInt64Lit: result = a.intVal == b.intVal
    of nkFloatLit..nkFloat64Lit: result = a.floatVal == b.floatVal
    of nkStrLit..nkTripleStrLit: result = a.strVal == b.strVal
    of nkType: result = a.typ == b.typ
    of nkEmpty, nkNilLit: result = true
    else:
      if sonsLen(a) == sonsLen(b):
        for i in countup(0, sonsLen(a) - 1):
          if not sameTree(a.sons[i], b.sons[i]): return
        result = true

proc valuesUnequal(a, b: PNode): bool =
  if a.isValue and b.isValue:
    result = not SameValue(a, b)

type
  TImplication* = enum
    impUnknown, impNo, impYes  

proc impliesEq(fact, eq: PNode): TImplication =
  let (loc, val) = if isLocation(eq.sons[1]): (1, 2) else: (2, 1)
  
  case fact.sons[0].sym.magic
  of someEq:
    if sameTree(fact.sons[1], eq.sons[loc]):
      # this is not correct; consider:  a == b;  a == 1 --> unknown!
      if sameTree(fact.sons[2], eq.sons[val]): result = impYes
      elif valuesUnequal(fact.sons[2], eq.sons[val]): result = impNo
    elif sameTree(fact.sons[2], eq.sons[loc]):
      if sameTree(fact.sons[1], eq.sons[val]): result = impYes
      elif valuesUnequal(fact.sons[1], eq.sons[val]): result = impNo
  of mInSet:
    if sameTree(fact.sons[1], eq.sons[loc]) and isValue(eq.sons[val]):
      if inSet(fact.sons[2], eq.sons[val]): result = impYes
      else: result = impNo
  of mIsNil:
    if sameTree(fact.sons[1], eq.sons[loc]):
      if eq.sons[val].kind == nkNilLit:
        result = impYes
  of mNot, mOr, mAnd: internalError(eq.info, "impliesEq")
  else: nil
  
proc impliesIsNil(fact, eq: PNode): TImplication =
  case fact.sons[0].sym.magic
  of someEq:
    if sameTree(fact.sons[1], eq.sons[1]):
      if fact.sons[2].kind == nkNilLit: result = impYes
    elif sameTree(fact.sons[2], eq.sons[1]):
      if fact.sons[1].kind == nkNilLit: result = impYes
  of mIsNil:
    if sameTree(fact.sons[1], eq.sons[1]):
      result = impYes
  of mNot, mOr, mAnd: internalError(eq.info, "impliesIsNil")
  else: nil

proc pred(n: PNode): PNode =
  if n.kind in {nkCharLit..nkUInt64Lit} and n.intVal != low(biggestInt):
    result = copyNode(n)
    dec result.intVal
  else:
    result = n

proc impliesGe(fact, x, c: PNode): TImplication =
  InternalAssert isLocation(x)
  case fact.sons[0].sym.magic
  of someEq:
    if sameTree(fact.sons[1], x):
      if isValue(fact.sons[2]) and isValue(c):
        # fact:  x = 4;  question x >= 56? --> true iff 4 >= 56
        if leValue(c, fact.sons[2]): result = impYes
        else: result = impNo
    elif sameTree(fact.sons[2], x):
      if isValue(fact.sons[1]) and isValue(c):
        if leValue(c, fact.sons[1]): result = impYes
        else: result = impNo
  of someLt:
    if sameTree(fact.sons[1], x):
      if isValue(fact.sons[2]) and isValue(c):
        # fact:  x < 4;  question N <= x? --> false iff N <= 4
        if leValue(fact.sons[2], c): result = impNo
        # fact:  x < 4;  question 2 <= x? --> we don't know
    elif sameTree(fact.sons[2], x):
      # fact: 3 < x; question: N-1 < x ?  --> true iff N-1 <= 3
      if isValue(fact.sons[1]) and isValue(c):
        if leValue(c.pred, fact.sons[1]): result = impYes
  of someLe:
    if sameTree(fact.sons[1], x):
      if isValue(fact.sons[2]) and isValue(c):
        # fact:  x <= 4;  question x >= 56? --> false iff 4 <= 56
        if leValue(fact.sons[2], c): result = impNo
        # fact:  x <= 4;  question x >= 2? --> we don't know
    elif sameTree(fact.sons[2], x):
      # fact: 3 <= x; question: x >= 2 ?  --> true iff 2 <= 3
      if isValue(fact.sons[1]) and isValue(c):
        if leValue(c, fact.sons[1]): result = impYes
  of mNot, mOr, mAnd: internalError(x.info, "impliesGe")
  else: nil

proc impliesLe(fact, x, c: PNode): TImplication =
  if not isLocation(x):
    return impliesGe(fact, c, x)
  case fact.sons[0].sym.magic
  of someEq:
    if sameTree(fact.sons[1], x):
      if isValue(fact.sons[2]) and isValue(c):
        # fact:  x = 4;  question x <= 56? --> true iff 4 <= 56
        if leValue(fact.sons[2], c): result = impYes
        else: result = impNo
    elif sameTree(fact.sons[2], x):
      if isValue(fact.sons[1]) and isValue(c):
        if leValue(fact.sons[1], c): result = impYes
        else: result = impNo
  of someLt:
    if sameTree(fact.sons[1], x):
      if isValue(fact.sons[2]) and isValue(c):
        # fact:  x < 4;  question x <= N? --> true iff N-1 <= 4
        if leValue(fact.sons[2], c.pred): result = impYes
        # fact:  x < 4;  question x <= 2? --> we don't know
    elif sameTree(fact.sons[2], x):
      # fact: 3 < x; question: x <= 1 ?  --> false iff 1 <= 3
      if isValue(fact.sons[1]) and isValue(c): 
        if leValue(c, fact.sons[1]): result = impNo
    
  of someLe:
    if sameTree(fact.sons[1], x):
      if isValue(fact.sons[2]) and isValue(c):
        # fact:  x <= 4;  question x <= 56? --> true iff 4 <= 56
        if leValue(fact.sons[2], c): result = impYes
        # fact:  x <= 4;  question x <= 2? --> we don't know
    
    elif sameTree(fact.sons[2], x):
      # fact: 3 <= x; question: x <= 2 ?  --> false iff 2 < 3
      if isValue(fact.sons[1]) and isValue(c): 
        if leValue(c, fact.sons[1].pred): result = impNo

  of mNot, mOr, mAnd: internalError(x.info, "impliesLe")
  else: nil

proc impliesLt(fact, x, c: PNode): TImplication =
  # x < 3  same as x <= 2:
  let p = c.pred
  if p != c:
    result = impliesLe(fact, x, p)
  else:
    # 4 < x  same as 3 <= x
    let q = x.pred
    if q != x:
      result = impliesLe(fact, q, c)

proc factImplies(fact, prop: PNode, isNegation: bool): TImplication =
  case fact.getMagic
  of mNot:
    case factImplies(fact.sons[1], prop, not isNegation)
    of impUnknown: return impUnknown
    of impNo: return impYes
    of impYes: return impNo
  of mAnd:
    if not isNegation:
      result = factImplies(fact.sons[1], prop, isNegation)
      if result != impUnknown: return result
      return factImplies(fact.sons[2], prop, isNegation)
    else:
      # careful!  not (a and b)  means  not a or not b:
      # a or b --> both need to imply 'prop'
      let a = factImplies(fact.sons[1], prop, isNegation)
      let b = factImplies(fact.sons[2], prop, isNegation)
      if a == b: return a
      return impUnknown
  else: discard
  
  case prop.sons[0].sym.magic
  of mNot:
    case fact.factImplies(prop.sons[1], isNegation)
    of impUnknown: result = impUnknown
    of impNo: result = impYes
    of impYes: result = impNo
  of mIsNil:
    result = impliesIsNil(fact, prop)
  of someEq:
    result = impliesEq(fact, prop)
  of someLe:
    result = impliesLe(fact, prop.sons[1], prop.sons[2])
  of someLt:
    result = impliesLt(fact, prop.sons[1], prop.sons[2])
  else:
    internalError(prop.info, "invalid proposition")

proc doesImply*(facts: TModel, prop: PNode): TImplication =
  assert prop.kind in nkCallKinds
  for f in facts:
    result = f.factImplies(prop, false)
    if result != impUnknown: return

proc impliesNotNil*(facts: TModel, arg: PNode): TImplication =
  var x = newNodeI(nkCall, arg.info, 2)
  x.sons[0] = newSymNode(getSysMagic("isNil", mIsNil))
  x.sons[1] = arg
  result = doesImply(facts, x.neg)
