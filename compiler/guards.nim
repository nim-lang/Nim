#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the 'implies' relation for guards.

import ast, astalgo, msgs, magicsys, nimsets, trees, types, renderer, idents,
  saturate, modulegraphs, options, lineinfos

const
  someEq = {mEqI, mEqF64, mEqEnum, mEqCh, mEqB, mEqRef, mEqProc,
    mEqUntracedRef, mEqStr, mEqSet, mEqCString}

  # set excluded here as the semantics are vastly different:
  someLe = {mLeI, mLeF64, mLeU, mLeU64, mLeEnum,
            mLeCh, mLeB, mLePtr, mLeStr}
  someLt = {mLtI, mLtF64, mLtU, mLtU64, mLtEnum,
            mLtCh, mLtB, mLtPtr, mLtStr}

  someLen = {mLengthOpenArray, mLengthStr, mLengthArray, mLengthSeq,
             mXLenStr, mXLenSeq}

  someIn = {mInRange, mInSet}

  someHigh = {mHigh}
  # we don't list unsigned here because wrap around semantics suck for
  # proving anything:
  someAdd = {mAddI, mAddF64, mSucc}
  someSub = {mSubI, mSubF64, mPred}
  someMul = {mMulI, mMulF64}
  someDiv = {mDivI, mDivF64}
  someMod = {mModI}
  someMax = {mMaxI, mMaxF64}
  someMin = {mMinI, mMinF64}
  someBinaryOp = someAdd+someSub+someMul+someMax+someMin

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
      {sfAddrTaken} * n.sym.flags == {}

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
      if isConstExpr(n.sons[1]) or isLet(n.sons[1]) or isConstExpr(n.sons[1].skipConv):
        n = n.sons[0]
      else: return
    of nkHiddenStdConv, nkHiddenSubConv, nkConv:
      n = n.sons[1]
    else:
      break
  result = n.isLet and derefs <= ord(isApprox)
  if not result and isApprox:
    result = isVar(n)

proc interestingCaseExpr*(m: PNode): bool = isLetLocation(m, true)

type
  Operators* = object
    opNot, opContains, opLe, opLt, opAnd, opOr, opIsNil, opEq: PSym
    opAdd, opSub, opMul, opDiv, opLen: PSym

proc initOperators*(g: ModuleGraph): Operators =
  result.opLe = createMagic(g, "<=", mLeI)
  result.opLt = createMagic(g, "<", mLtI)
  result.opAnd = createMagic(g, "and", mAnd)
  result.opOr = createMagic(g, "or", mOr)
  result.opIsNil = createMagic(g, "isnil", mIsNil)
  result.opEq = createMagic(g, "==", mEqI)
  result.opAdd = createMagic(g, "+", mAddI)
  result.opSub = createMagic(g, "-", mSubI)
  result.opMul = createMagic(g, "*", mMulI)
  result.opDiv = createMagic(g, "div", mDivI)
  result.opLen = createMagic(g, "len", mLengthSeq)
  result.opNot = createMagic(g, "not", mNot)
  result.opContains = createMagic(g, "contains", mInSet)

proc swapArgs(fact: PNode, newOp: PSym): PNode =
  result = newNodeI(nkCall, fact.info, 3)
  result.sons[0] = newSymNode(newOp)
  result.sons[1] = fact.sons[2]
  result.sons[2] = fact.sons[1]

proc neg(n: PNode; o: Operators): PNode =
  if n == nil: return nil
  case n.getMagic
  of mNot:
    result = n.sons[1]
  of someLt:
    # not (a < b)  ==  a >= b  ==  b <= a
    result = swapArgs(n, o.opLe)
  of someLe:
    result = swapArgs(n, o.opLt)
  of mInSet:
    if n.sons[1].kind != nkCurly: return nil
    let t = n.sons[2].typ.skipTypes(abstractInst)
    result = newNodeI(nkCall, n.info, 3)
    result.sons[0] = n.sons[0]
    result.sons[2] = n.sons[2]
    if t.kind == tyEnum:
      var s = newNodeIT(nkCurly, n.info, n.sons[1].typ)
      for e in t.n:
        let eAsNode = newIntNode(nkIntLit, e.sym.position)
        if not inSet(n.sons[1], eAsNode): s.add eAsNode
      result.sons[1] = s
    #elif t.kind notin {tyString, tySequence} and lengthOrd(t) < 1000:
    #  result.sons[1] = complement(n.sons[1])
    else:
      # not ({2, 3, 4}.contains(x))   x != 2 and x != 3 and x != 4
      # XXX todo
      result = nil
  of mOr:
    # not (a or b) --> not a and not b
    let
      a = n.sons[1].neg(o)
      b = n.sons[2].neg(o)
    if a != nil and b != nil:
      result = newNodeI(nkCall, n.info, 3)
      result.sons[0] = newSymNode(o.opAnd)
      result.sons[1] = a
      result.sons[2] = b
    elif a != nil:
      result = a
    elif b != nil:
      result = b
  else:
    # leave  not (a == 4)  as it is
    result = newNodeI(nkCall, n.info, 2)
    result.sons[0] = newSymNode(o.opNot)
    result.sons[1] = n

proc buildCall(op: PSym; a: PNode): PNode =
  result = newNodeI(nkCall, a.info, 2)
  result.sons[0] = newSymNode(op)
  result.sons[1] = a

proc buildCall(op: PSym; a, b: PNode): PNode =
  result = newNodeI(nkInfix, a.info, 3)
  result.sons[0] = newSymNode(op)
  result.sons[1] = a
  result.sons[2] = b

proc `|+|`(a, b: PNode): PNode =
  result = copyNode(a)
  if a.kind in {nkCharLit..nkUInt64Lit}: result.intVal = a.intVal |+| b.intVal
  else: result.floatVal = a.floatVal + b.floatVal

proc `|-|`(a, b: PNode): PNode =
  result = copyNode(a)
  if a.kind in {nkCharLit..nkUInt64Lit}: result.intVal = a.intVal |-| b.intVal
  else: result.floatVal = a.floatVal - b.floatVal

proc `|*|`(a, b: PNode): PNode =
  result = copyNode(a)
  if a.kind in {nkCharLit..nkUInt64Lit}: result.intVal = a.intVal |*| b.intVal
  else: result.floatVal = a.floatVal * b.floatVal

proc `|div|`(a, b: PNode): PNode =
  result = copyNode(a)
  if a.kind in {nkCharLit..nkUInt64Lit}: result.intVal = a.intVal div b.intVal
  else: result.floatVal = a.floatVal / b.floatVal

proc negate(a, b, res: PNode; o: Operators): PNode =
  if b.kind in {nkCharLit..nkUInt64Lit} and b.intVal != low(BiggestInt):
    var b = copyNode(b)
    b.intVal = -b.intVal
    if a.kind in {nkCharLit..nkUInt64Lit}:
      b.intVal = b.intVal |+| a.intVal
      result = b
    else:
      result = buildCall(o.opAdd, a, b)
  elif b.kind in {nkFloatLit..nkFloat64Lit}:
    var b = copyNode(b)
    b.floatVal = -b.floatVal
    result = buildCall(o.opAdd, a, b)
  else:
    result = res

proc zero(): PNode = nkIntLit.newIntNode(0)
proc one(): PNode = nkIntLit.newIntNode(1)
proc minusOne(): PNode = nkIntLit.newIntNode(-1)

proc lowBound*(conf: ConfigRef; x: PNode): PNode =
  result = nkIntLit.newIntNode(firstOrd(conf, x.typ))
  result.info = x.info

proc highBound*(conf: ConfigRef; x: PNode; o: Operators): PNode =
  let typ = x.typ.skipTypes(abstractInst)
  result = if typ.kind == tyArray:
             nkIntLit.newIntNode(lastOrd(conf, typ))
           elif typ.kind == tySequence and x.kind == nkSym and
               x.sym.kind == skConst:
             nkIntLit.newIntNode(x.sym.ast.len-1)
           else:
             o.opAdd.buildCall(o.opLen.buildCall(x), minusOne())
  result.info = x.info

proc reassociation(n: PNode; o: Operators): PNode =
  result = n
  # (foo+5)+5 --> foo+10;  same for '*'
  case result.getMagic
  of someAdd:
    if result[2].isValue and
        result[1].getMagic in someAdd and result[1][2].isValue:
      result = o.opAdd.buildCall(result[1][1], result[1][2] |+| result[2])
      if result[2].intVal == 0:
        result = result[1]
  of someMul:
    if result[2].isValue and
        result[1].getMagic in someMul and result[1][2].isValue:
      result = o.opMul.buildCall(result[1][1], result[1][2] |*| result[2])
      if result[2].intVal == 1:
        result = result[1]
      elif result[2].intVal == 0:
        result = zero()
  else: discard

proc pred(n: PNode): PNode =
  if n.kind in {nkCharLit..nkUInt64Lit} and n.intVal != low(BiggestInt):
    result = copyNode(n)
    dec result.intVal
  else:
    result = n

proc canon*(n: PNode; o: Operators): PNode =
  # XXX for now only the new code in 'semparallel' uses this
  if n.safeLen >= 1:
    result = shallowCopy(n)
    for i in 0 ..< n.len:
      result.sons[i] = canon(n.sons[i], o)
  elif n.kind == nkSym and n.sym.kind == skLet and
      n.sym.astdef.getMagic in (someEq + someAdd + someMul + someMin +
      someMax + someHigh + {mUnaryLt} + someSub + someLen + someDiv):
    result = n.sym.astdef.copyTree
  else:
    result = n
  case result.getMagic
  of someEq, someAdd, someMul, someMin, someMax:
    # these are symmetric; put value as last:
    if result.sons[1].isValue and not result.sons[2].isValue:
      result = swapArgs(result, result.sons[0].sym)
      # (4 + foo) + 2 --> (foo + 4) + 2
  of someHigh:
    # high == len+(-1)
    result = o.opAdd.buildCall(o.opLen.buildCall(result[1]), minusOne())
  of mUnaryLt:
    result = buildCall(o.opAdd, result[1], minusOne())
  of someSub:
    # x - 4  -->  x + (-4)
    result = negate(result[1], result[2], result, o)
  of someLen:
    result.sons[0] = o.opLen.newSymNode
  of someLt:
    # x < y  same as x <= y-1:
    let y = n[2].canon(o)
    let p = pred(y)
    let minus = if p != y: p else: o.opAdd.buildCall(y, minusOne()).canon(o)
    result = o.opLe.buildCall(n[1].canon(o), minus)
  else: discard

  result = skipConv(result)
  result = reassociation(result, o)
  # most important rule: (x-4) <= a.len -->  x <= a.len+4
  case result.getMagic
  of someLe:
    let x = result[1]
    let y = result[2]
    if x.kind in nkCallKinds and x.len == 3 and x[2].isValue and
        isLetLocation(x[1], true):
      case x.getMagic
      of someSub:
        result = buildCall(result[0].sym, x[1],
                           reassociation(o.opAdd.buildCall(y, x[2]), o))
      of someAdd:
        # Rule A:
        let plus = negate(y, x[2], nil, o).reassociation(o)
        if plus != nil: result = buildCall(result[0].sym, x[1], plus)
      else: discard
    elif y.kind in nkCallKinds and y.len == 3 and y[2].isValue and
        isLetLocation(y[1], true):
      # a.len < x-3
      case y.getMagic
      of someSub:
        result = buildCall(result[0].sym, y[1],
                           reassociation(o.opAdd.buildCall(x, y[2]), o))
      of someAdd:
        let plus = negate(x, y[2], nil, o).reassociation(o)
        # ensure that Rule A will not trigger afterwards with the
        # additional 'not isLetLocation' constraint:
        if plus != nil and not isLetLocation(x, true):
          result = buildCall(result[0].sym, plus, y[1])
      else: discard
    elif x.isValue and y.getMagic in someAdd and y[2].isValue:
      # 0 <= a.len + 3
      # -3 <= a.len
      result.sons[1] = x |-| y[2]
      result.sons[2] = y[1]
    elif x.isValue and y.getMagic in someSub and y[2].isValue:
      # 0 <= a.len - 3
      # 3 <= a.len
      result.sons[1] = x |+| y[2]
      result.sons[2] = y[1]
  else: discard

proc buildAdd*(a: PNode; b: BiggestInt; o: Operators): PNode =
  canon(if b != 0: o.opAdd.buildCall(a, nkIntLit.newIntNode(b)) else: a, o)

proc usefulFact(n: PNode; o: Operators): PNode =
  case n.getMagic
  of someEq:
    if skipConv(n.sons[2]).kind == nkNilLit and (
        isLetLocation(n.sons[1], false) or isVar(n.sons[1])):
      result = o.opIsNil.buildCall(n.sons[1])
    else:
      if isLetLocation(n.sons[1], true) or isLetLocation(n.sons[2], true):
        # XXX algebraic simplifications!  'i-1 < a.len' --> 'i < a.len+1'
        result = n
  of someLe+someLt:
    if isLetLocation(n.sons[1], true) or isLetLocation(n.sons[2], true):
      # XXX algebraic simplifications!  'i-1 < a.len' --> 'i < a.len+1'
      result = n
    elif n[1].getMagic in someLen or n[2].getMagic in someLen:
      # XXX Rethink this whole idea of 'usefulFact' for semparallel
      result = n
  of mIsNil:
    if isLetLocation(n.sons[1], false) or isVar(n.sons[1]):
      result = n
  of someIn:
    if isLetLocation(n.sons[1], true):
      result = n
  of mAnd:
    let
      a = usefulFact(n.sons[1], o)
      b = usefulFact(n.sons[2], o)
    if a != nil and b != nil:
      result = newNodeI(nkCall, n.info, 3)
      result.sons[0] = newSymNode(o.opAnd)
      result.sons[1] = a
      result.sons[2] = b
    elif a != nil:
      result = a
    elif b != nil:
      result = b
  of mNot:
    let a = usefulFact(n.sons[1], o)
    if a != nil:
      result = a.neg(o)
  of mOr:
    # 'or' sucks! (p.isNil or q.isNil) --> hard to do anything
    # with that knowledge...
    # DeMorgan helps a little though:
    #   not a or not b --> not (a and b)
    #  (x == 3) or (y == 2)  ---> not ( not (x==3) and not (y == 2))
    #  not (x != 3 and y != 2)
    let
      a = usefulFact(n.sons[1], o).neg(o)
      b = usefulFact(n.sons[2], o).neg(o)
    if a != nil and b != nil:
      result = newNodeI(nkCall, n.info, 3)
      result.sons[0] = newSymNode(o.opAnd)
      result.sons[1] = a
      result.sons[2] = b
      result = result.neg(o)
  elif n.kind == nkSym and n.sym.kind == skLet:
    # consider:
    #   let a = 2 < x
    #   if a:
    #     ...
    # We make can easily replace 'a' by '2 < x' here:
    if n.sym.astdef != nil:
      result = usefulFact(n.sym.astdef, o)
  elif n.kind == nkStmtListExpr:
    result = usefulFact(n.lastSon, o)

type
  TModel* = object
    s*: seq[PNode] # the "knowledge base"
    o*: Operators

proc addFact*(m: var TModel, nn: PNode) =
  let n = usefulFact(nn, m.o)
  if n != nil: m.s.add n

proc addFactNeg*(m: var TModel, n: PNode) =
  let n = n.neg(m.o)
  if n != nil: addFact(m, n)

proc sameOpr(a, b: PSym): bool =
  case a.magic
  of someEq: result = b.magic in someEq
  of someLe: result = b.magic in someLe
  of someLt: result = b.magic in someLt
  of someLen: result = b.magic in someLen
  of someAdd: result = b.magic in someAdd
  of someSub: result = b.magic in someSub
  of someMul: result = b.magic in someMul
  of someDiv: result = b.magic in someDiv
  else: result = a == b

proc sameTree*(a, b: PNode): bool =
  result = false
  if a == b:
    result = true
  elif a != nil and b != nil and a.kind == b.kind:
    case a.kind
    of nkSym:
      result = a.sym == b.sym
      if not result and a.sym.magic != mNone:
        result = a.sym.magic == b.sym.magic or sameOpr(a.sym, b.sym)
    of nkIdent: result = a.ident.id == b.ident.id
    of nkCharLit..nkInt64Lit: result = a.intVal == b.intVal
    of nkFloatLit..nkFloat64Lit: result = a.floatVal == b.floatVal
    of nkStrLit..nkTripleStrLit: result = a.strVal == b.strVal
    of nkType: result = a.typ == b.typ
    of nkEmpty, nkNilLit: result = true
    else:
      if sonsLen(a) == sonsLen(b):
        for i in 0 ..< sonsLen(a):
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
  for i in 0..high(m.s):
    if m.s[i] != nil and m.s[i].hasSubTree(n): m.s[i] = nil

proc valuesUnequal(a, b: PNode): bool =
  if a.isValue and b.isValue:
    result = not sameValue(a, b)

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
  of mNot, mOr, mAnd: assert(false, "impliesEq")
  else: discard

proc leImpliesIn(x, c, aSet: PNode): TImplication =
  if c.kind in {nkCharLit..nkUInt64Lit}:
    # fact:  x <= 4;  question x in {56}?
    # --> true if every value <= 4 is in the set {56}
    #
    var value = newIntNode(c.kind, firstOrd(nil, x.typ))
    # don't iterate too often:
    if c.intVal - value.intVal < 1000:
      var i, pos, neg: int
      while value.intVal <= c.intVal:
        if inSet(aSet, value): inc pos
        else: inc neg
        inc i; inc value.intVal
      if pos == i: result = impYes
      elif neg == i: result = impNo

proc geImpliesIn(x, c, aSet: PNode): TImplication =
  if c.kind in {nkCharLit..nkUInt64Lit}:
    # fact:  x >= 4;  question x in {56}?
    # --> true iff every value >= 4 is in the set {56}
    #
    var value = newIntNode(c.kind, c.intVal)
    let max = lastOrd(nil, x.typ)
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
  if equalSets(nil, a, b): result = impYes
  elif intersectSets(nil, a, b).len == 0: result = impNo

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
  of mNot, mOr, mAnd: assert(false, "impliesIn")
  else: discard

proc valueIsNil(n: PNode): TImplication =
  if n.kind == nkNilLit: impYes
  elif n.kind in {nkStrLit..nkTripleStrLit, nkBracket, nkObjConstr}: impNo
  else: impUnknown

proc impliesIsNil(fact, eq: PNode): TImplication =
  case fact.sons[0].sym.magic
  of mIsNil:
    if sameTree(fact.sons[1], eq.sons[1]):
      result = impYes
  of someEq:
    if sameTree(fact.sons[1], eq.sons[1]):
      result = valueIsNil(fact.sons[2].skipConv)
    elif sameTree(fact.sons[2], eq.sons[1]):
      result = valueIsNil(fact.sons[1].skipConv)
  of mNot, mOr, mAnd: assert(false, "impliesIsNil")
  else: discard

proc impliesGe(fact, x, c: PNode): TImplication =
  assert isLocation(x)
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
  of mNot, mOr, mAnd: assert(false, "impliesGe")
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

  of mNot, mOr, mAnd: assert(false, "impliesLe")
  else: discard

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

proc `~`(x: TImplication): TImplication =
  case x
  of impUnknown: impUnknown
  of impNo: impYes
  of impYes: impNo

proc factImplies(fact, prop: PNode): TImplication =
  case fact.getMagic
  of mNot:
    # Consider:
    # enum nkBinary, nkTernary, nkStr
    # fact:      not (k <= nkBinary)
    # question:  k in {nkStr}
    # --> 'not' for facts is entirely different than 'not' for questions!
    # it's provably wrong if every value > 4 is in the set {56}
    # That's because we compute the implication and  'a -> not b' cannot
    # be treated the same as 'not a -> b'

    #  (not a) -> b  compute as  not (a -> b) ???
    #  == not a or not b == not (a and b)
    let arg = fact.sons[1]
    case arg.getMagic
    of mIsNil, mEqRef:
      return ~factImplies(arg, prop)
    of mAnd:
      # not (a and b)  means  not a or not b:
      # a or b --> both need to imply 'prop'
      let a = factImplies(arg.sons[1], prop)
      let b = factImplies(arg.sons[2], prop)
      if a == b: return ~a
      return impUnknown
    else:
      return impUnknown
  of mAnd:
    result = factImplies(fact.sons[1], prop)
    if result != impUnknown: return result
    return factImplies(fact.sons[2], prop)
  else: discard

  case prop.sons[0].sym.magic
  of mNot: result = ~fact.factImplies(prop.sons[1])
  of mIsNil: result = impliesIsNil(fact, prop)
  of someEq: result = impliesEq(fact, prop)
  of someLe: result = impliesLe(fact, prop.sons[1], prop.sons[2])
  of someLt: result = impliesLt(fact, prop.sons[1], prop.sons[2])
  of mInSet: result = impliesIn(fact, prop.sons[2], prop.sons[1])
  else: result = impUnknown

proc doesImply*(facts: TModel, prop: PNode): TImplication =
  assert prop.kind in nkCallKinds
  for f in facts.s:
    # facts can be invalidated, in which case they are 'nil':
    if not f.isNil:
      result = f.factImplies(prop)
      if result != impUnknown: return

proc impliesNotNil*(m: TModel, arg: PNode): TImplication =
  result = doesImply(m, m.o.opIsNil.buildCall(arg).neg(m.o))

proc simpleSlice*(a, b: PNode): BiggestInt =
  # returns 'c' if a..b matches (i+c)..(i+c), -1 otherwise. (i)..(i) is matched
  # as if it is (i+0)..(i+0).
  if guards.sameTree(a, b):
    if a.getMagic in someAdd and a[2].kind in {nkCharLit..nkUInt64Lit}:
      result = a[2].intVal
    else:
      result = 0
  else:
    result = -1


template isMul(x): untyped = x.getMagic in someMul
template isDiv(x): untyped = x.getMagic in someDiv
template isAdd(x): untyped = x.getMagic in someAdd
template isSub(x): untyped = x.getMagic in someSub
template isVal(x): untyped = x.kind in {nkCharLit..nkUInt64Lit}
template isIntVal(x, y): untyped = x.intVal == y

import macros

macro `=~`(x: PNode, pat: untyped): bool =
  proc m(x, pat, conds: NimNode) =
    case pat.kind
    of nnkInfix:
      case $pat[0]
      of "*": conds.add getAst(isMul(x))
      of "/": conds.add getAst(isDiv(x))
      of "+": conds.add getAst(isAdd(x))
      of "-": conds.add getAst(isSub(x))
      else:
        error("invalid pattern")
      m(newTree(nnkBracketExpr, x, newLit(1)), pat[1], conds)
      m(newTree(nnkBracketExpr, x, newLit(2)), pat[2], conds)
    of nnkPar:
      if pat.len == 1:
        m(x, pat[0], conds)
      else:
        error("invalid pattern")
    of nnkIdent:
      let c = newTree(nnkStmtListExpr, newLetStmt(pat, x))
      conds.add c
      # XXX why is this 'isVal(pat)' and not 'isVal(x)'?
      if ($pat)[^1] == 'c': c.add(getAst(isVal(x)))
      else: c.add bindSym"true"
    of nnkIntLit:
      conds.add(getAst(isIntVal(x, pat.intVal)))
    else:
      error("invalid pattern")

  var conds = newTree(nnkBracket)
  m(x, pat, conds)
  when compiles(nestList(ident"and", conds)):
    result = nestList(ident"and", conds)
  #elif declared(macros.toNimIdent):
  #  result = nestList(toNimIdent"and", conds)
  else:
    result = nestList(!"and", conds)

proc isMinusOne(n: PNode): bool =
  n.kind in {nkCharLit..nkUInt64Lit} and n.intVal == -1

proc pleViaModel(model: TModel; aa, bb: PNode): TImplication

proc ple(m: TModel; a, b: PNode): TImplication =
  template `<=?`(a,b): untyped = ple(m,a,b) == impYes
  template `>=?`(a,b): untyped = ple(m, nkIntLit.newIntNode(b), a) == impYes

  #   0 <= 3
  if a.isValue and b.isValue:
    return if leValue(a, b): impYes else: impNo

  # use type information too:  x <= 4  iff  high(x) <= 4
  if b.isValue and a.typ != nil and a.typ.isOrdinalType:
    if lastOrd(nil, a.typ) <= b.intVal: return impYes
  # 3 <= x   iff  low(x) <= 3
  if a.isValue and b.typ != nil and b.typ.isOrdinalType:
    if firstOrd(nil, b.typ) <= a.intVal: return impYes

  # x <= x
  if sameTree(a, b): return impYes

  # 0 <= x.len
  if b.getMagic in someLen and a.isValue:
    if a.intVal <= 0: return impYes

  #   x <= y+c  if 0 <= c and x <= y
  #   x <= y+(-c)  if c <= 0  and y >= x
  if b.getMagic in someAdd and zero() <=? b[2] and a <=? b[1]: return impYes

  #   x+c <= y  if c <= 0 and x <= y
  if a.getMagic in someAdd and a[2] <=? zero() and a[1] <=? b: return impYes

  #   x <= y*c  if  1 <= c and x <= y  and 0 <= y
  if b.getMagic in someMul:
    if a <=? b[1] and one() <=? b[2] and zero() <=? b[1]: return impYes


  if a.getMagic in someMul and a[2].isValue and a[1].getMagic in someDiv and
      a[1][2].isValue:
    # simplify   (x div 4) * 2 <= y   to  x div (c div d)  <= y
    if ple(m, buildCall(m.o.opDiv, a[1][1], `|div|`(a[1][2], a[2])), b) == impYes:
      return impYes

  # x*3 + x == x*4. It follows that:
  # x*3 + y <= x*4  if  y <= x  and 3 <= 4
  if a =~ x*dc + y and b =~ x2*ec:
    if sameTree(x, x2):
      let ec1 = m.o.opAdd.buildCall(ec, minusOne())
      if x >=? 1 and ec >=? 1 and dc >=? 1 and dc <=? ec1 and y <=? x:
        return impYes
  elif a =~ x*dc and b =~ x2*ec + y:
    #echo "BUG cam ehrer e ", a, " <=? ", b
    if sameTree(x, x2):
      let ec1 = m.o.opAdd.buildCall(ec, minusOne())
      if x >=? 1 and ec >=? 1 and dc >=? 1 and dc <=? ec1 and y <=? zero():
        return impYes

  #  x+c <= x+d  if c <= d. Same for *, - etc.
  if a.getMagic in someBinaryOp and a.getMagic == b.getMagic:
    if sameTree(a[1], b[1]) and a[2] <=? b[2]: return impYes
    elif sameTree(a[2], b[2]) and a[1] <=? b[1]: return impYes

  #   x div c <= y   if   1 <= c  and  0 <= y  and x <= y:
  if a.getMagic in someDiv:
    if one() <=? a[2] and zero() <=? b and a[1] <=? b: return impYes

    #  x div c <= x div d  if d <= c
    if b.getMagic in someDiv:
      if sameTree(a[1], b[1]) and b[2] <=? a[2]: return impYes

    # x div z <= x - 1   if  z <= x
    if a[2].isValue and b.getMagic in someAdd and b[2].isMinusOne:
      if a[2] <=? a[1] and sameTree(a[1], b[1]): return impYes

  # slightly subtle:
  # x <= max(y, z)  iff x <= y or x <= z
  # note that 'x <= max(x, z)' is a special case of the above rule
  if b.getMagic in someMax:
    if a <=? b[1] or a <=? b[2]: return impYes

  # min(x, y) <= z  iff x <= z or y <= z
  if a.getMagic in someMin:
    if a[1] <=? b or a[2] <=? b: return impYes

  # use the knowledge base:
  return pleViaModel(m, a, b)
  #return doesImply(m, o.opLe.buildCall(a, b))

type TReplacements = seq[tuple[a, b: PNode]]

proc replaceSubTree(n, x, by: PNode): PNode =
  if sameTree(n, x):
    result = by
  elif hasSubTree(n, x):
    result = shallowCopy(n)
    for i in 0 .. safeLen(n)-1:
      result.sons[i] = replaceSubTree(n.sons[i], x, by)
  else:
    result = n

proc applyReplacements(n: PNode; rep: TReplacements): PNode =
  result = n
  for x in rep: result = result.replaceSubTree(x.a, x.b)

proc pleViaModelRec(m: var TModel; a, b: PNode): TImplication =
  # now check for inferrable facts: a <= b and b <= c  implies a <= c
  for i in 0..m.s.high:
    let fact = m.s[i]
    if fact != nil and fact.getMagic in someLe:
      # mark as used:
      m.s[i] = nil
      # i <= len-100
      # i <=? len-1
      # --> true  if  (len-100) <= (len-1)
      let x = fact[1]
      let y = fact[2]
      if sameTree(x, a) and y.getMagic in someAdd and b.getMagic in someAdd and
         sameTree(y[1], b[1]):
        if ple(m, b[2], y[2]) == impYes:
          return impYes

      # x <= y implies a <= b  if  a <= x and y <= b
      if ple(m, a, x) == impYes:
        if ple(m, y, b) == impYes:
          return impYes
        #if pleViaModelRec(m, y, b): return impYes
      # fact:  16 <= i
      #         x    y
      # question: i <= 15? no!
      result = impliesLe(fact, a, b)
      if result != impUnknown:
        return result
      when false:
        # given: x <= y;  y==a;  x <= a this means: a <= b  if  x <= b
        if sameTree(y, a):
          result = ple(m, b, x)
          if result != impUnknown:
            return result

proc pleViaModel(model: TModel; aa, bb: PNode): TImplication =
  # compute replacements:
  var replacements: TReplacements = @[]
  for fact in model.s:
    if fact != nil and fact.getMagic in someEq:
      let a = fact[1]
      let b = fact[2]
      if a.kind == nkSym: replacements.add((a,b))
      else: replacements.add((b,a))
  var m: TModel
  var a = aa
  var b = bb
  if replacements.len > 0:
    m.s = @[]
    m.o = model.o
    # make the other facts consistent:
    for fact in model.s:
      if fact != nil and fact.getMagic notin someEq:
        # XXX 'canon' should not be necessary here, but it is
        m.s.add applyReplacements(fact, replacements).canon(m.o)
    a = applyReplacements(aa, replacements)
    b = applyReplacements(bb, replacements)
  else:
    # we have to make a copy here, because the model will be modified:
    m = model
  result = pleViaModelRec(m, a, b)

proc proveLe*(m: TModel; a, b: PNode): TImplication =
  let x = canon(m.o.opLe.buildCall(a, b), m.o)
  #echo "ROOT ", renderTree(x[1]), " <=? ", renderTree(x[2])
  result = ple(m, x[1], x[2])
  if result == impUnknown:
    # try an alternative:  a <= b  iff  not (b < a)  iff  not (b+1 <= a):
    let y = canon(m.o.opLe.buildCall(m.o.opAdd.buildCall(b, one()), a), m.o)
    result = ~ple(m, y[1], y[2])

proc addFactLe*(m: var TModel; a, b: PNode) =
  m.s.add canon(m.o.opLe.buildCall(a, b), m.o)

proc settype(n: PNode): PType =
  result = newType(tySet, n.typ.owner)
  addSonSkipIntLit(result, n.typ)

proc buildOf(it, loc: PNode; o: Operators): PNode =
  var s = newNodeI(nkCurly, it.info, it.len-1)
  s.typ = settype(loc)
  for i in 0..it.len-2: s.sons[i] = it.sons[i]
  result = newNodeI(nkCall, it.info, 3)
  result.sons[0] = newSymNode(o.opContains)
  result.sons[1] = s
  result.sons[2] = loc

proc buildElse(n: PNode; o: Operators): PNode =
  var s = newNodeIT(nkCurly, n.info, settype(n.sons[0]))
  for i in 1..n.len-2:
    let branch = n.sons[i]
    assert branch.kind == nkOfBranch
    for j in 0..branch.len-2:
      s.add(branch.sons[j])
  result = newNodeI(nkCall, n.info, 3)
  result.sons[0] = newSymNode(o.opContains)
  result.sons[1] = s
  result.sons[2] = n.sons[0]

proc addDiscriminantFact*(m: var TModel, n: PNode) =
  var fact = newNodeI(nkCall, n.info, 3)
  fact.sons[0] = newSymNode(m.o.opEq)
  fact.sons[1] = n.sons[0]
  fact.sons[2] = n.sons[1]
  m.s.add fact

proc addAsgnFact*(m: var TModel, key, value: PNode) =
  var fact = newNodeI(nkCall, key.info, 3)
  fact.sons[0] = newSymNode(m.o.opEq)
  fact.sons[1] = key
  fact.sons[2] = value
  m.s.add fact

proc sameSubexprs*(m: TModel; a, b: PNode): bool =
  # This should be used to check whether two *path expressions* refer to the
  # same memory location according to 'm'. This is tricky:
  # lock a[i].guard:
  #   ...
  #   access a[i].guarded
  #
  # Here a[i] is the same as a[i] iff 'i' and 'a' are not changed via '...'.
  # However, nil checking requires exactly the same mechanism! But for now
  # we simply use sameTree and live with the unsoundness of the analysis.
  var check = newNodeI(nkCall, a.info, 3)
  check.sons[0] = newSymNode(m.o.opEq)
  check.sons[1] = a
  check.sons[2] = b
  result = m.doesImply(check) == impYes

proc addCaseBranchFacts*(m: var TModel, n: PNode, i: int) =
  let branch = n.sons[i]
  if branch.kind == nkOfBranch:
    m.s.add buildOf(branch, n.sons[0], m.o)
  else:
    m.s.add n.buildElse(m.o).neg(m.o)

proc buildProperFieldCheck(access, check: PNode; o: Operators): PNode =
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
    result = buildProperFieldCheck(access, check.sons[1], o).neg(o)

proc checkFieldAccess*(m: TModel, n: PNode; conf: ConfigRef) =
  for i in 1..n.len-1:
    let check = buildProperFieldCheck(n.sons[0], n.sons[i], m.o)
    if check != nil and m.doesImply(check) != impYes:
      message(conf, n.info, warnProveField, renderTree(n.sons[0])); break
