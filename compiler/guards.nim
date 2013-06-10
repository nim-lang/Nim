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

proc isLet(n: PNode): bool =
  if n.kind == nkSym:
    if n.sym.kind in {skLet, skTemp, skForVar}:
      result = true
    elif n.sym.kind == skParam and skipTypes(n.sym.typ, 
                                             abstractInst).kind != tyVar:
      result = true

proc isVar(n: PNode): bool =
  n.kind == nkSym and n.sym.kind in {skResult, skVar} and
      sfGlobal notin n.sym.flags

proc isLetLocation(m: PNode, isApprox: bool): bool =
  # consider: 'n[].kind' --> we really need to support 1 deref op even if this
  # is technically wrong due to aliasing :-( We could introduce "soft" facts
  # for this; this would still be very useful for warnings and also nicely
  # solves the 'var' problems. For now we fix this by requiring much more
  # restrictive expressions for the 'not nil' checking.
  var n = m
  var derefs = 0
  while true:
    case n.kind
    of nkDotExpr, nkCheckedFieldExpr, nkObjUpConv, nkObjDownConv:
      n = n.sons[0]
    of nkDerefExpr, nkHiddenDeref:
      n = n.sons[0]
      inc derefs
    of nkBracketExpr:
      if isConstExpr(n.sons[1]) or isLet(n.sons[1]):
        n = n.sons[0]
      else: return
    of nkHiddenStdConv, nkHiddenSubConv, nkConv:
      n = n.sons[1]
    else:
      break
  result = n.isLet and derefs <= ord(isApprox)
  if not result and isApprox:
    result = isVar(n)

proc interestingCaseExpr*(m: PNode): bool = 
  var n = m
  while true:
    case n.kind
    of nkDotExpr, nkCheckedFieldExpr, nkObjUpConv, nkObjDownConv, 
       nkDerefExpr, nkHiddenDeref:
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

proc buildIsNil(arg: PNode): PNode =
  result = newNodeI(nkCall, arg.info, 2)
  result.sons[0] = newSymNode(getSysMagic("isNil", mIsNil))
  result.sons[1] = arg

proc usefulFact(n: PNode): PNode =
  case n.getMagic
  of someEq:
    if skipConv(n.sons[2]).kind == nkNilLit and (
        isLetLocation(n.sons[1], false) or isVar(n.sons[1])):
      result = buildIsNil(n.sons[1])
    else:
      if isLetLocation(n.sons[1], true) or isLetLocation(n.sons[2], true):
        # XXX algebraic simplifications!  'i-1 < a.len' --> 'i < a.len+1'
        result = n
  of someLe+someLt:
    if isLetLocation(n.sons[1], true) or isLetLocation(n.sons[2], true):
      # XXX algebraic simplifications!  'i-1 < a.len' --> 'i < a.len+1'
      result = n
  of mIsNil:
    if isLetLocation(n.sons[1], false) or isVar(n.sons[1]):
      result = n
  of someIn:
    if isLetLocation(n.sons[1], true):
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
      if a != nil:
        result = copyTree(n)
        result.sons[1] = a
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

proc hasSubTree(n, x: PNode): bool =
  if n.sameTree(x): result = true
  else:
    for i in 0..safeLen(n)-1:
      if hasSubTree(n.sons[i], x): return true

proc invalidateFacts*(m: var TModel, n: PNode) =
  # We are able to guard local vars (as opposed to 'let' variables)!
  # 'while p != nil: f(p); p = p.next'
  # This is actually quite easy to do:
  # Re-assignments (incl. pass to a 'var' param) trigger an invalidation
  # of every fact that contains 'v'. 
  # 
  #   if x < 4:
  #     if y < 5
  #       x = unknown()
  #       # we invalidate 'x' here but it's known that x >= 4
  #       # for the else anyway
  #   else:
  #     echo x
  #
  # The same mechanism could be used for more complex data stored on the heap;
  # procs that 'write: []' cannot invalidate 'n.kind' for instance. In fact, we
  # could CSE these expressions then and help C's optimizer.
  for i in 0..high(m):
    if m[i] != nil and m[i].hasSubTree(n): m[i] = nil

proc valuesUnequal(a, b: PNode): bool =
  if a.isValue and b.isValue:
    result = not SameValue(a, b)

proc pred(n: PNode): PNode =
  if n.kind in {nkCharLit..nkUInt64Lit} and n.intVal != low(biggestInt):
    result = copyNode(n)
    dec result.intVal
  else:
    result = n

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
    # remember: mInSet is 'contains' so the set comes first!
    if sameTree(fact.sons[2], eq.sons[loc]) and isValue(eq.sons[val]):
      if inSet(fact.sons[1], eq.sons[val]): result = impYes
      else: result = impNo
  of mNot, mOr, mAnd: internalError(eq.info, "impliesEq")
  else: discard
  
proc leImpliesIn(x, c, aSet: PNode): TImplication =
  if c.kind in {nkCharLit..nkUInt64Lit}:
    # fact:  x <= 4;  question x in {56}?
    # --> true iff every value <= 4 is in the set {56}
    #   
    var value = newIntNode(c.kind, firstOrd(x.typ))
    # don't iterate too often:
    if c.intVal - value.intVal < 1000:
      var i, pos, neg: int
      while value.intVal <= c.intVal:
        if inSet(aSet, value): inc pos
        else: inc neg
        inc i; inc value.intVal
      if pos == i: result = impYes
      elif neg == i: result = impNo
      #echo "result ", result, " ", i, " ", neg, " ", pos
      # XXX wrong for the impNo case

proc geImpliesIn(x, c, aSet: PNode): TImplication =
  if c.kind in {nkCharLit..nkUInt64Lit}:
    # fact:  x >= 4;  question x in {56}?
    # --> true iff every value >= 4 is in the set {56}
    #   
    var value = newIntNode(c.kind, c.intVal)
    let max = lastOrd(x.typ)
    # don't iterate too often:
    if max - value.intVal < 1000:
      var i, pos, neg: int
      while value.intVal <= max:
        if inSet(aSet, value): inc pos
        else: inc neg
        inc i; inc value.intVal
      if pos == i: result = impYes
      elif neg == i: result = impNo

proc compareSets(a, b: PNode): TImplication =
  if equalSets(a, b): result = impYes
  elif intersectSets(a, b).len == 0: result = impNo

proc impliesIn(fact, loc, aSet: PNode): TImplication =
  case fact.sons[0].sym.magic
  of someEq:
    if sameTree(fact.sons[1], loc):
      if inSet(aSet, fact.sons[2]): result = impYes
      else: result = impNo
    elif sameTree(fact.sons[2], loc):
      if inSet(aSet, fact.sons[1]): result = impYes
      else: result = impNo
  of mInSet:
    if sameTree(fact.sons[2], loc):
      result = compareSets(fact.sons[1], aSet)
  of someLe:
    if sameTree(fact.sons[1], loc):
      result = leImpliesIn(fact.sons[1], fact.sons[2], aSet)
    elif sameTree(fact.sons[2], loc):
      result = geImpliesIn(fact.sons[2], fact.sons[1], aSet)
  of someLt:
    if sameTree(fact.sons[1], loc):
      result = leImpliesIn(fact.sons[1], fact.sons[2].pred, aSet)
    elif sameTree(fact.sons[2], loc):
      # 4 < x  -->  3 <= x
      result = geImpliesIn(fact.sons[2], fact.sons[1].pred, aSet)
  of mNot, mOr, mAnd: internalError(loc.info, "impliesIn")
  else: discard
  
proc impliesIsNil(fact, eq: PNode): TImplication =
  case fact.sons[0].sym.magic
  of mIsNil:
    if sameTree(fact.sons[1], eq.sons[1]):
      result = impYes
  of mNot, mOr, mAnd: internalError(eq.info, "impliesIsNil")
  else: discard

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
  else: discard

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
  of mInSet:
    result = impliesIn(fact, prop.sons[2], prop.sons[1])
  else:
    internalError(prop.info, "invalid proposition")

proc doesImply*(facts: TModel, prop: PNode): TImplication =
  assert prop.kind in nkCallKinds
  for f in facts:
    # facts can be invalidated, in which case they are 'nil':
    if not f.isNil:
      result = f.factImplies(prop, false)
      if result != impUnknown: return

proc impliesNotNil*(facts: TModel, arg: PNode): TImplication =
  result = doesImply(facts, buildIsNil(arg).neg)

proc settype(n: PNode): PType =
  result = newType(tySet, n.typ.owner)
  addSonSkipIntLit(result, n.typ)

proc buildOf(it, loc: PNode): PNode =
  var s = newNodeI(nkCurly, it.info, it.len-1)
  s.typ = settype(loc)
  for i in 0..it.len-2: s.sons[i] = it.sons[i]
  result = newNodeI(nkCall, it.info, 3)
  result.sons[0] = newSymNode(getSysMagic("contains", mInSet))
  result.sons[1] = s
  result.sons[2] = loc

proc buildElse(n: PNode): PNode =
  var s = newNodeIT(nkCurly, n.info, settype(n.sons[0]))
  for i in 1..n.len-2:
    let branch = n.sons[i]
    assert branch.kind == nkOfBranch
    for j in 0..branch.len-2:
      s.add(branch.sons[j])
  result = newNodeI(nkCall, n.info, 3)
  result.sons[0] = newSymNode(getSysMagic("contains", mInSet))
  result.sons[1] = s
  result.sons[2] = n.sons[0]

proc addCaseBranchFacts*(m: var TModel, n: PNode, i: int) =
  let branch = n.sons[i]
  if branch.kind == nkOfBranch:
    m.add buildOf(branch, n.sons[0])
  else:
    m.add n.buildElse.neg

proc buildProperFieldCheck(access, check: PNode): PNode =
  if check.sons[1].kind == nkCurly:
    result = copyTree(check)
    if access.kind == nkDotExpr:
      var a = copyTree(access)
      a.sons[1] = check.sons[2]
      result.sons[2] = a
      # 'access.kind != nkDotExpr' can happen for object constructors
      # which we don't check yet
  else:
    # it is some 'not'
    assert check.getMagic == mNot
    result = buildProperFieldCheck(access, check.sons[1]).neg

proc checkFieldAccess*(m: TModel, n: PNode) =
  for i in 1..n.len-1:
    let check = buildProperFieldCheck(n.sons[0], n.sons[i])
    if m.doesImply(check) != impYes:
      Message(n.info, warnProveField, renderTree(n.sons[0])); break
