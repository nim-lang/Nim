#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module folds constants; used by semantic checking phase
# and evaluation phase

import 
  strutils, lists, options, ast, astalgo, trees, treetab, nimsets, times, 
  nversion, platform, math, msgs, os, condsyms, idents, renderer, types,
  commands, magicsys, saturate

proc getConstExpr*(m: PSym, n: PNode): PNode
  # evaluates the constant expression or returns nil if it is no constant
  # expression
proc evalOp*(m: TMagic, n, a, b, c: PNode): PNode
proc leValueConv*(a, b: PNode): bool
proc newIntNodeT*(intVal: BiggestInt, n: PNode): PNode
proc newFloatNodeT(floatVal: BiggestFloat, n: PNode): PNode
proc newStrNodeT*(strVal: string, n: PNode): PNode

# implementation

proc newIntNodeT(intVal: BiggestInt, n: PNode): PNode =
  case skipTypes(n.typ, abstractVarRange).kind
  of tyInt:
    result = newIntNode(nkIntLit, intVal)
    result.typ = getIntLitType(result)
    # hrm, this is not correct: 1 + high(int) shouldn't produce tyInt64 ...
    #setIntLitType(result)
  of tyChar:
    result = newIntNode(nkCharLit, intVal)
    result.typ = n.typ
  else:
    result = newIntNode(nkIntLit, intVal)
    result.typ = n.typ
  result.info = n.info

proc newFloatNodeT(floatVal: BiggestFloat, n: PNode): PNode = 
  result = newFloatNode(nkFloatLit, floatVal)
  if skipTypes(n.typ, abstractVarRange).kind == tyFloat:
    result.typ = getFloatLitType(result)
  else:
    result.typ = n.typ
  result.info = n.info

proc newStrNodeT(strVal: string, n: PNode): PNode = 
  result = newStrNode(nkStrLit, strVal)
  result.typ = n.typ
  result.info = n.info

proc ordinalValToString*(a: PNode): string = 
  # because $ has the param ordinal[T], `a` is not necessarily an enum, but an
  # ordinal
  var x = getInt(a)
  
  var t = skipTypes(a.typ, abstractRange)
  case t.kind
  of tyChar: 
    result = $chr(int(x) and 0xff)
  of tyEnum:
    var n = t.n
    for i in countup(0, sonsLen(n) - 1): 
      if n.sons[i].kind != nkSym: internalError(a.info, "ordinalValToString")
      var field = n.sons[i].sym
      if field.position == x: 
        if field.ast == nil: 
          return field.name.s
        else:
          return field.ast.strVal
    internalError(a.info, "no symbol for ordinal value: " & $x)
  else:
    result = $x

proc isFloatRange(t: PType): bool {.inline.} =
  result = t.kind == tyRange and t.sons[0].kind in {tyFloat..tyFloat128}

proc isIntRange(t: PType): bool {.inline.} =
  result = t.kind == tyRange and t.sons[0].kind in {
      tyInt..tyInt64, tyUInt8..tyUInt32}

proc pickIntRange(a, b: PType): PType =
  if isIntRange(a): result = a
  elif isIntRange(b): result = b
  else: result = a

proc isIntRangeOrLit(t: PType): bool =
  result = isIntRange(t) or isIntLit(t)

proc pickMinInt(n: PNode): BiggestInt =
  if n.kind in {nkIntLit..nkUInt64Lit}:
    result = n.intVal
  elif isIntLit(n.typ):
    result = n.typ.n.intVal
  elif isIntRange(n.typ):
    result = firstOrd(n.typ)
  else:
    internalError(n.info, "pickMinInt")

proc pickMaxInt(n: PNode): BiggestInt =
  if n.kind in {nkIntLit..nkUInt64Lit}:
    result = n.intVal
  elif isIntLit(n.typ):
    result = n.typ.n.intVal
  elif isIntRange(n.typ):
    result = lastOrd(n.typ)
  else:
    internalError(n.info, "pickMaxInt")

proc makeRange(typ: PType, first, last: BiggestInt): PType = 
  let minA = min(first, last)
  let maxA = max(first, last)
  let lowerNode = newIntNode(nkIntLit, minA)
  if typ.kind == tyInt and minA == maxA:
    result = getIntLitType(lowerNode)
  else:
    var n = newNode(nkRange)
    addSon(n, lowerNode)
    addSon(n, newIntNode(nkIntLit, maxA))
    result = newType(tyRange, typ.owner)
    result.n = n
    addSonSkipIntLit(result, skipTypes(typ, {tyRange}))

proc makeRangeF(typ: PType, first, last: BiggestFloat): PType =
  var n = newNode(nkRange)
  addSon(n, newFloatNode(nkFloatLit, min(first.float, last.float)))
  addSon(n, newFloatNode(nkFloatLit, max(first.float, last.float)))
  result = newType(tyRange, typ.owner)
  result.n = n
  addSonSkipIntLit(result, skipTypes(typ, {tyRange}))

proc getIntervalType*(m: TMagic, n: PNode): PType =
  # Nimrod requires interval arithmetic for ``range`` types. Lots of tedious
  # work but the feature is very nice for reducing explicit conversions.
  result = n.typ
  
  template commutativeOp(opr: expr) {.immediate.} =
    let a = n.sons[1]
    let b = n.sons[2]
    if isIntRangeOrLit(a.typ) and isIntRangeOrLit(b.typ):
      result = makeRange(pickIntRange(a.typ, b.typ),
                         opr(pickMinInt(a), pickMinInt(b)),
                         opr(pickMaxInt(a), pickMaxInt(b)))
  
  template binaryOp(opr: expr) {.immediate.} =
    let a = n.sons[1]
    let b = n.sons[2]
    if isIntRange(a.typ) and b.kind in {nkIntLit..nkUInt64Lit}:
      result = makeRange(a.typ,
                         opr(pickMinInt(a), pickMinInt(b)),
                         opr(pickMaxInt(a), pickMaxInt(b)))
  
  case m
  of mUnaryMinusI, mUnaryMinusI64:
    let a = n.sons[1].typ
    if isIntRange(a):
      # (1..3) * (-1) == (-3.. -1)
      result = makeRange(a, 0|-|lastOrd(a), 0|-|firstOrd(a))
  of mUnaryMinusF64:
    let a = n.sons[1].typ
    if isFloatRange(a):
      result = makeRangeF(a, -getFloat(a.n.sons[1]),
                             -getFloat(a.n.sons[0]))
  of mAbsF64:
    let a = n.sons[1].typ
    if isFloatRange(a):
      # abs(-5.. 1) == (1..5)
      result = makeRangeF(a, abs(getFloat(a.n.sons[1])),
                             abs(getFloat(a.n.sons[0])))
  of mAbsI, mAbsI64:
    let a = n.sons[1].typ
    if isIntRange(a):
      result = makeRange(a, `|abs|`(getInt(a.n.sons[1])),
                            `|abs|`(getInt(a.n.sons[0])))
  of mSucc:
    let a = n.sons[1].typ
    let b = n.sons[2].typ
    if isIntRange(a) and isIntLit(b):
      # (-5.. 1) + 6 == (-5 + 6)..(-1 + 6)
      result = makeRange(a, pickMinInt(n.sons[1]) |+| pickMinInt(n.sons[2]),
                            pickMaxInt(n.sons[1]) |+| pickMaxInt(n.sons[2]))
  of mPred:
    let a = n.sons[1].typ
    let b = n.sons[2].typ
    if isIntRange(a) and isIntLit(b):
      result = makeRange(a, pickMinInt(n.sons[1]) |-| pickMinInt(n.sons[2]),
                            pickMaxInt(n.sons[1]) |-| pickMaxInt(n.sons[2]))
  of mAddI, mAddI64, mAddU:
    commutativeOp(`|+|`)
  of mMulI, mMulI64, mMulU:
    commutativeOp(`|*|`)
  of mSubI, mSubI64, mSubU:
    binaryOp(`|-|`)
  of mBitandI, mBitandI64:
    # since uint64 is still not even valid for 'range' (since it's no ordinal
    # yet), we exclude it from the list (see bug #1638) for now:
    var a = n.sons[1]
    var b = n.sons[2]
    # symmetrical:
    if b.kind notin {nkIntLit..nkUInt32Lit}: swap(a, b)
    if b.kind in {nkIntLit..nkUInt32Lit}:
      let x = b.intVal|+|1
      if (x and -x) == x and x >= 0:
        result = makeRange(a.typ, 0, b.intVal)
  of mModU:
    let a = n.sons[1]
    let b = n.sons[2]
    if b.kind in {nkIntLit..nkUInt32Lit}:
      if b.intVal >= 0:
        result = makeRange(a.typ, 0, b.intVal-1)
      else:
        result = makeRange(a.typ, b.intVal+1, 0)
  of mModI, mModI64:
    # so ... if you ever wondered about modulo's signedness; this defines it:
    let a = n.sons[1]
    let b = n.sons[2]
    if b.kind in {nkIntLit..nkUInt64Lit}:
      if b.intVal >= 0:
        result = makeRange(a.typ, -(b.intVal-1), b.intVal-1)
      else:
        result = makeRange(a.typ, b.intVal+1, -(b.intVal+1))
  of mDivI, mDivI64, mDivU:
    binaryOp(`|div|`)
  of mMinI, mMinI64:
    commutativeOp(min)
  of mMaxI, mMaxI64:
    commutativeOp(max)
  else: discard
  
discard """
  mShlI, mShlI64,
  mShrI, mShrI64, mAddF64, mSubF64, mMulF64, mDivF64, mMaxF64, mMinF64
"""

proc evalIs(n, a: PNode): PNode =
  # XXX: This should use the standard isOpImpl
  internalAssert a.kind == nkSym and a.sym.kind == skType
  internalAssert n.sonsLen == 3 and
    n[2].kind in {nkStrLit..nkTripleStrLit, nkType}
  
  let t1 = a.sym.typ

  if n[2].kind in {nkStrLit..nkTripleStrLit}:
    case n[2].strVal.normalize
    of "closure":
      let t = skipTypes(t1, abstractRange)
      result = newIntNode(nkIntLit, ord(t.kind == tyProc and
                                        t.callConv == ccClosure and 
                                        tfIterator notin t.flags))
    of "iterator":
      let t = skipTypes(t1, abstractRange)
      result = newIntNode(nkIntLit, ord(t.kind == tyProc and
                                        t.callConv == ccClosure and 
                                        tfIterator in t.flags))
    else: discard
  else:
    # XXX semexprs.isOpImpl is slightly different and requires a context. yay.
    let t2 = n[2].typ
    var match = sameType(t1, t2)
    result = newIntNode(nkIntLit, ord(match))
  result.typ = n.typ

proc evalOp(m: TMagic, n, a, b, c: PNode): PNode = 
  # b and c may be nil
  result = nil
  case m
  of mOrd: result = newIntNodeT(getOrdValue(a), n)
  of mChr: result = newIntNodeT(getInt(a), n)
  of mUnaryMinusI, mUnaryMinusI64: result = newIntNodeT(- getInt(a), n)
  of mUnaryMinusF64: result = newFloatNodeT(- getFloat(a), n)
  of mNot: result = newIntNodeT(1 - getInt(a), n)
  of mCard: result = newIntNodeT(nimsets.cardSet(a), n)
  of mBitnotI, mBitnotI64: result = newIntNodeT(not getInt(a), n)
  of mLengthStr: result = newIntNodeT(len(getStr(a)), n)
  of mLengthArray: result = newIntNodeT(lengthOrd(a.typ), n)
  of mLengthSeq, mLengthOpenArray: result = newIntNodeT(sonsLen(a), n) # BUGFIX
  of mUnaryPlusI, mUnaryPlusI64, mUnaryPlusF64: result = a # throw `+` away
  of mToFloat, mToBiggestFloat: 
    result = newFloatNodeT(toFloat(int(getInt(a))), n)
  of mToInt, mToBiggestInt: result = newIntNodeT(system.toInt(getFloat(a)), n)
  of mAbsF64: result = newFloatNodeT(abs(getFloat(a)), n)
  of mAbsI, mAbsI64: 
    if getInt(a) >= 0: result = a
    else: result = newIntNodeT(- getInt(a), n)
  of mZe8ToI, mZe8ToI64, mZe16ToI, mZe16ToI64, mZe32ToI64, mZeIToI64: 
    # byte(-128) = 1...1..1000_0000'64 --> 0...0..1000_0000'64
    result = newIntNodeT(getInt(a) and (`shl`(1, getSize(a.typ) * 8) - 1), n)
  of mToU8: result = newIntNodeT(getInt(a) and 0x000000FF, n)
  of mToU16: result = newIntNodeT(getInt(a) and 0x0000FFFF, n)
  of mToU32: result = newIntNodeT(getInt(a) and 0x00000000FFFFFFFF'i64, n)
  of mUnaryLt: result = newIntNodeT(getOrdValue(a) - 1, n)
  of mSucc: result = newIntNodeT(getOrdValue(a) + getInt(b), n)
  of mPred: result = newIntNodeT(getOrdValue(a) - getInt(b), n)
  of mAddI, mAddI64: result = newIntNodeT(getInt(a) + getInt(b), n)
  of mSubI, mSubI64: result = newIntNodeT(getInt(a) - getInt(b), n)
  of mMulI, mMulI64: result = newIntNodeT(getInt(a) * getInt(b), n)
  of mMinI, mMinI64: 
    if getInt(a) > getInt(b): result = newIntNodeT(getInt(b), n)
    else: result = newIntNodeT(getInt(a), n)
  of mMaxI, mMaxI64: 
    if getInt(a) > getInt(b): result = newIntNodeT(getInt(a), n)
    else: result = newIntNodeT(getInt(b), n)
  of mShlI, mShlI64: 
    case skipTypes(n.typ, abstractRange).kind
    of tyInt8: result = newIntNodeT(int8(getInt(a)) shl int8(getInt(b)), n)
    of tyInt16: result = newIntNodeT(int16(getInt(a)) shl int16(getInt(b)), n)
    of tyInt32: result = newIntNodeT(int32(getInt(a)) shl int32(getInt(b)), n)
    of tyInt64, tyInt, tyUInt..tyUInt64: 
      result = newIntNodeT(`shl`(getInt(a), getInt(b)), n)
    else: internalError(n.info, "constant folding for shl")
  of mShrI, mShrI64: 
    case skipTypes(n.typ, abstractRange).kind
    of tyInt8: result = newIntNodeT(int8(getInt(a)) shr int8(getInt(b)), n)
    of tyInt16: result = newIntNodeT(int16(getInt(a)) shr int16(getInt(b)), n)
    of tyInt32: result = newIntNodeT(int32(getInt(a)) shr int32(getInt(b)), n)
    of tyInt64, tyInt, tyUInt..tyUInt64:
      result = newIntNodeT(`shr`(getInt(a), getInt(b)), n)
    else: internalError(n.info, "constant folding for shr")
  of mDivI, mDivI64:
    let y = getInt(b)
    if y != 0:
      result = newIntNodeT(getInt(a) div y, n)
  of mModI, mModI64:
    let y = getInt(b)
    if y != 0:
      result = newIntNodeT(getInt(a) mod y, n)
  of mAddF64: result = newFloatNodeT(getFloat(a) + getFloat(b), n)
  of mSubF64: result = newFloatNodeT(getFloat(a) - getFloat(b), n)
  of mMulF64: result = newFloatNodeT(getFloat(a) * getFloat(b), n)
  of mDivF64: 
    if getFloat(b) == 0.0: 
      if getFloat(a) == 0.0: result = newFloatNodeT(NaN, n)
      else: result = newFloatNodeT(Inf, n)
    else: 
      result = newFloatNodeT(getFloat(a) / getFloat(b), n)
  of mMaxF64: 
    if getFloat(a) > getFloat(b): result = newFloatNodeT(getFloat(a), n)
    else: result = newFloatNodeT(getFloat(b), n)
  of mMinF64: 
    if getFloat(a) > getFloat(b): result = newFloatNodeT(getFloat(b), n)
    else: result = newFloatNodeT(getFloat(a), n)
  of mIsNil: result = newIntNodeT(ord(a.kind == nkNilLit), n)
  of mLtI, mLtI64, mLtB, mLtEnum, mLtCh: 
    result = newIntNodeT(ord(getOrdValue(a) < getOrdValue(b)), n)
  of mLeI, mLeI64, mLeB, mLeEnum, mLeCh: 
    result = newIntNodeT(ord(getOrdValue(a) <= getOrdValue(b)), n)
  of mEqI, mEqI64, mEqB, mEqEnum, mEqCh: 
    result = newIntNodeT(ord(getOrdValue(a) == getOrdValue(b)), n) 
  of mLtF64: result = newIntNodeT(ord(getFloat(a) < getFloat(b)), n)
  of mLeF64: result = newIntNodeT(ord(getFloat(a) <= getFloat(b)), n)
  of mEqF64: result = newIntNodeT(ord(getFloat(a) == getFloat(b)), n) 
  of mLtStr: result = newIntNodeT(ord(getStr(a) < getStr(b)), n)
  of mLeStr: result = newIntNodeT(ord(getStr(a) <= getStr(b)), n)
  of mEqStr: result = newIntNodeT(ord(getStr(a) == getStr(b)), n)
  of mLtU, mLtU64: 
    result = newIntNodeT(ord(`<%`(getOrdValue(a), getOrdValue(b))), n)
  of mLeU, mLeU64: 
    result = newIntNodeT(ord(`<=%`(getOrdValue(a), getOrdValue(b))), n)
  of mBitandI, mBitandI64, mAnd: result = newIntNodeT(a.getInt and b.getInt, n)
  of mBitorI, mBitorI64, mOr: result = newIntNodeT(getInt(a) or getInt(b), n)
  of mBitxorI, mBitxorI64, mXor: result = newIntNodeT(a.getInt xor b.getInt, n)
  of mAddU: result = newIntNodeT(`+%`(getInt(a), getInt(b)), n)
  of mSubU: result = newIntNodeT(`-%`(getInt(a), getInt(b)), n)
  of mMulU: result = newIntNodeT(`*%`(getInt(a), getInt(b)), n)
  of mModU:
    let y = getInt(b)
    if y != 0:
      result = newIntNodeT(`%%`(getInt(a), y), n)
  of mDivU:
    let y = getInt(b)
    if y != 0:
      result = newIntNodeT(`/%`(getInt(a), y), n)
  of mLeSet: result = newIntNodeT(ord(containsSets(a, b)), n)
  of mEqSet: result = newIntNodeT(ord(equalSets(a, b)), n)
  of mLtSet: 
    result = newIntNodeT(ord(containsSets(a, b) and not equalSets(a, b)), n)
  of mMulSet: 
    result = nimsets.intersectSets(a, b)
    result.info = n.info
  of mPlusSet: 
    result = nimsets.unionSets(a, b)
    result.info = n.info
  of mMinusSet: 
    result = nimsets.diffSets(a, b)
    result.info = n.info
  of mSymDiffSet: 
    result = nimsets.symdiffSets(a, b)
    result.info = n.info
  of mConStrStr: result = newStrNodeT(getStrOrChar(a) & getStrOrChar(b), n)
  of mInSet: result = newIntNodeT(ord(inSet(a, b)), n)
  of mRepr:
    # BUGFIX: we cannot eval mRepr here for reasons that I forgot.
    discard
  of mIntToStr, mInt64ToStr: result = newStrNodeT($(getOrdValue(a)), n)
  of mBoolToStr: 
    if getOrdValue(a) == 0: result = newStrNodeT("false", n)
    else: result = newStrNodeT("true", n)
  of mCopyStr: result = newStrNodeT(substr(getStr(a), int(getOrdValue(b))), n)
  of mCopyStrLast: 
    result = newStrNodeT(substr(getStr(a), int(getOrdValue(b)), 
                                           int(getOrdValue(c))), n)
  of mFloatToStr: result = newStrNodeT($getFloat(a), n)
  of mCStrToStr, mCharToStr: result = newStrNodeT(getStrOrChar(a), n)
  of mStrToStr: result = a
  of mEnumToStr: result = newStrNodeT(ordinalValToString(a), n)
  of mArrToSeq: 
    result = copyTree(a)
    result.typ = n.typ
  of mCompileOption:
    result = newIntNodeT(ord(commands.testCompileOption(a.getStr, n.info)), n)  
  of mCompileOptionArg:
    result = newIntNodeT(ord(
      testCompileOptionArg(getStr(a), getStr(b), n.info)), n)
  of mNewString, mNewStringOfCap, 
     mExit, mInc, ast.mDec, mEcho, mSwap, mAppendStrCh, 
     mAppendStrStr, mAppendSeqElem, mSetLengthStr, mSetLengthSeq, 
     mParseExprToAst, mParseStmtToAst, mExpandToAst, mTypeTrait,
     mNLen..mNError, mEqRef, mSlurp, mStaticExec, mNGenSym, mSpawn, mParallel:
    discard
  else: internalError(a.info, "evalOp(" & $m & ')')
  
proc getConstIfExpr(c: PSym, n: PNode): PNode = 
  result = nil
  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    if it.len == 2:
      var e = getConstExpr(c, it.sons[0])
      if e == nil: return nil
      if getOrdValue(e) != 0: 
        if result == nil: 
          result = getConstExpr(c, it.sons[1])
          if result == nil: return 
    elif it.len == 1:
      if result == nil: result = getConstExpr(c, it.sons[0])
    else: internalError(it.info, "getConstIfExpr()")

proc partialAndExpr(c: PSym, n: PNode): PNode = 
  # partial evaluation
  result = n
  var a = getConstExpr(c, n.sons[1])
  var b = getConstExpr(c, n.sons[2])
  if a != nil: 
    if getInt(a) == 0: result = a
    elif b != nil: result = b
    else: result = n.sons[2]
  elif b != nil: 
    if getInt(b) == 0: result = b
    else: result = n.sons[1]
  
proc partialOrExpr(c: PSym, n: PNode): PNode = 
  # partial evaluation
  result = n
  var a = getConstExpr(c, n.sons[1])
  var b = getConstExpr(c, n.sons[2])
  if a != nil: 
    if getInt(a) != 0: result = a
    elif b != nil: result = b
    else: result = n.sons[2]
  elif b != nil: 
    if getInt(b) != 0: result = b
    else: result = n.sons[1]
  
proc leValueConv(a, b: PNode): bool = 
  result = false
  case a.kind
  of nkCharLit..nkUInt64Lit: 
    case b.kind
    of nkCharLit..nkUInt64Lit: result = a.intVal <= b.intVal
    of nkFloatLit..nkFloat128Lit: result = a.intVal <= round(b.floatVal)
    else: internalError(a.info, "leValueConv")
  of nkFloatLit..nkFloat128Lit: 
    case b.kind
    of nkFloatLit..nkFloat128Lit: result = a.floatVal <= b.floatVal
    of nkCharLit..nkUInt64Lit: result = a.floatVal <= toFloat(int(b.intVal))
    else: internalError(a.info, "leValueConv")
  else: internalError(a.info, "leValueConv")
  
proc magicCall(m: PSym, n: PNode): PNode =
  if sonsLen(n) <= 1: return

  var s = n.sons[0].sym
  var a = getConstExpr(m, n.sons[1])
  var b, c: PNode
  if a == nil: return 
  if sonsLen(n) > 2: 
    b = getConstExpr(m, n.sons[2])
    if b == nil: return 
    if sonsLen(n) > 3: 
      c = getConstExpr(m, n.sons[3])
      if c == nil: return 
  result = evalOp(s.magic, n, a, b, c)
  
proc getAppType(n: PNode): PNode =
  if gGlobalOptions.contains(optGenDynLib):
    result = newStrNodeT("lib", n)
  elif gGlobalOptions.contains(optGenStaticLib):
    result = newStrNodeT("staticlib", n)
  elif gGlobalOptions.contains(optGenGuiApp):
    result = newStrNodeT("gui", n)
  else:
    result = newStrNodeT("console", n)

proc rangeCheck(n: PNode, value: BiggestInt) =
  if value < firstOrd(n.typ) or value > lastOrd(n.typ):
    localError(n.info, errGenerated, "cannot convert " & $value &
                                     " to " & typeToString(n.typ))

proc foldConv*(n, a: PNode; check = false): PNode = 
  # XXX range checks?
  case skipTypes(n.typ, abstractRange).kind
  of tyInt..tyInt64: 
    case skipTypes(a.typ, abstractRange).kind
    of tyFloat..tyFloat64:
      result = newIntNodeT(int(getFloat(a)), n)
    of tyChar: result = newIntNodeT(getOrdValue(a), n)
    else: 
      result = a
      result.typ = n.typ
    if check: rangeCheck(n, result.intVal)
  of tyFloat..tyFloat64:
    case skipTypes(a.typ, abstractRange).kind
    of tyInt..tyInt64, tyEnum, tyBool, tyChar: 
      result = newFloatNodeT(toFloat(int(getOrdValue(a))), n)
    else:
      result = a
      result.typ = n.typ
  of tyOpenArray, tyVarargs, tyProc: 
    discard
  else: 
    result = a
    result.typ = n.typ
  
proc getArrayConstr(m: PSym, n: PNode): PNode =
  if n.kind == nkBracket:
    result = n
  else:
    result = getConstExpr(m, n)
    if result == nil: result = n
  
proc foldArrayAccess(m: PSym, n: PNode): PNode = 
  var x = getConstExpr(m, n.sons[0])
  if x == nil or x.typ.skipTypes({tyGenericInst}).kind == tyTypeDesc: return
  
  var y = getConstExpr(m, n.sons[1])
  if y == nil: return
  
  var idx = getOrdValue(y)
  case x.kind
  of nkPar: 
    if idx >= 0 and idx < sonsLen(x):
      result = x.sons[int(idx)]
      if result.kind == nkExprColonExpr: result = result.sons[1]
    else:
      localError(n.info, errIndexOutOfBounds)
  of nkBracket:
    idx = idx - x.typ.firstOrd
    if idx >= 0 and idx < x.len: result = x.sons[int(idx)]
    else: localError(n.info, errIndexOutOfBounds)
  of nkStrLit..nkTripleStrLit:
    result = newNodeIT(nkCharLit, x.info, n.typ)
    if idx >= 0 and idx < len(x.strVal): 
      result.intVal = ord(x.strVal[int(idx)])
    elif idx == len(x.strVal): 
      discard
    else: 
      localError(n.info, errIndexOutOfBounds)
  else: discard
  
proc foldFieldAccess(m: PSym, n: PNode): PNode =
  # a real field access; proc calls have already been transformed
  var x = getConstExpr(m, n.sons[0])
  if x == nil or x.kind notin {nkObjConstr, nkPar}: return

  var field = n.sons[1].sym
  for i in countup(ord(x.kind == nkObjConstr), sonsLen(x) - 1):
    var it = x.sons[i]
    if it.kind != nkExprColonExpr:
      # lookup per index:
      result = x.sons[field.position]
      if result.kind == nkExprColonExpr: result = result.sons[1]
      return
    if it.sons[0].sym.name.id == field.name.id: 
      result = x.sons[i].sons[1]
      return
  localError(n.info, errFieldXNotFound, field.name.s)
  
proc foldConStrStr(m: PSym, n: PNode): PNode = 
  result = newNodeIT(nkStrLit, n.info, n.typ)
  result.strVal = ""
  for i in countup(1, sonsLen(n) - 1): 
    let a = getConstExpr(m, n.sons[i])
    if a == nil: return nil
    result.strVal.add(getStrOrChar(a))

proc newSymNodeTypeDesc*(s: PSym; info: TLineInfo): PNode =
  result = newSymNode(s, info)
  result.typ = newType(tyTypeDesc, s.owner)
  result.typ.addSonSkipIntLit(s.typ)

proc getConstExpr(m: PSym, n: PNode): PNode = 
  result = nil
  case n.kind
  of nkSym: 
    var s = n.sym
    case s.kind
    of skEnumField:
      result = newIntNodeT(s.position, n)
    of skConst:
      case s.magic
      of mIsMainModule: result = newIntNodeT(ord(sfMainModule in m.flags), n)
      of mCompileDate: result = newStrNodeT(times.getDateStr(), n)
      of mCompileTime: result = newStrNodeT(times.getClockStr(), n)
      of mCpuEndian: result = newIntNodeT(ord(CPU[targetCPU].endian), n)
      of mHostOS: result = newStrNodeT(toLower(platform.OS[targetOS].name), n)
      of mHostCPU: result = newStrNodeT(platform.CPU[targetCPU].name.toLower, n)
      of mAppType: result = getAppType(n)
      of mNaN: result = newFloatNodeT(NaN, n)
      of mInf: result = newFloatNodeT(Inf, n)
      of mNegInf: result = newFloatNodeT(NegInf, n)
      else:
        if sfFakeConst notin s.flags: result = copyTree(s.ast)
    of {skProc, skMethod}:
      result = n
    of skType:
      result = newSymNodeTypeDesc(s, n.info)
    of skGenericParam:
      if s.typ.kind == tyStatic:
        if s.typ.n != nil:
          result = s.typ.n
          result.typ = s.typ.sons[0]
      else:
        result = newSymNodeTypeDesc(s, n.info)
    else: discard
  of nkCharLit..nkNilLit: 
    result = copyNode(n)
  of nkIfExpr: 
    result = getConstIfExpr(m, n)
  of nkCall, nkCommand, nkCallStrLit, nkPrefix, nkInfix: 
    if n.sons[0].kind != nkSym: return 
    var s = n.sons[0].sym
    if s.kind != skProc: return 
    try:
      case s.magic
      of mNone:
        # If it has no sideEffect, it should be evaluated. But not here.
        return
      of mSizeOf:
        var a = n.sons[1]
        if computeSize(a.typ) < 0: 
          localError(a.info, errCannotEvalXBecauseIncompletelyDefined, 
                     "sizeof")
          result = nil
        elif skipTypes(a.typ, typedescInst).kind in
             IntegralTypes+NilableTypes+{tySet}:
          #{tyArray,tyObject,tyTuple}:
          result = newIntNodeT(getSize(a.typ), n)
        else:
          result = nil
          # XXX: size computation for complex types is still wrong
      of mLow: 
        result = newIntNodeT(firstOrd(n.sons[1].typ), n)
      of mHigh: 
        if skipTypes(n.sons[1].typ, abstractVar).kind notin
            {tySequence, tyString, tyCString, tyOpenArray, tyVarargs}:
          result = newIntNodeT(lastOrd(skipTypes(n[1].typ, abstractVar)), n)
        else:
          var a = getArrayConstr(m, n.sons[1])
          if a.kind == nkBracket:
            # we can optimize it away: 
            result = newIntNodeT(sonsLen(a)-1, n)
      of mLengthOpenArray:
        var a = getArrayConstr(m, n.sons[1])
        if a.kind == nkBracket:
          # we can optimize it away! This fixes the bug ``len(134)``. 
          result = newIntNodeT(sonsLen(a), n)
        else:
          result = magicCall(m, n)
      of mLengthArray:
        # It doesn't matter if the argument is const or not for mLengthArray.
        # This fixes bug #544.
        result = newIntNodeT(lengthOrd(n.sons[1].typ), n)
      of mAstToStr:
        result = newStrNodeT(renderTree(n[1], {renderNoComments}), n)
      of mConStrStr:
        result = foldConStrStr(m, n)
      of mIs:
        let a = getConstExpr(m, n[1])
        if a != nil and a.kind == nkSym and a.sym.kind == skType:
          result = evalIs(n, a)
      else:
        result = magicCall(m, n)
    except OverflowError: 
      localError(n.info, errOverOrUnderflow)
    except DivByZeroError: 
      localError(n.info, errConstantDivisionByZero)
  of nkAddr: 
    var a = getConstExpr(m, n.sons[0])
    if a != nil: 
      result = n
      n.sons[0] = a
  of nkBracket: 
    result = copyTree(n)
    for i in countup(0, sonsLen(n) - 1): 
      var a = getConstExpr(m, n.sons[i])
      if a == nil: return nil
      result.sons[i] = a
    incl(result.flags, nfAllConst)
  of nkRange: 
    var a = getConstExpr(m, n.sons[0])
    if a == nil: return 
    var b = getConstExpr(m, n.sons[1])
    if b == nil: return 
    result = copyNode(n)
    addSon(result, a)
    addSon(result, b)
  of nkCurly: 
    result = copyTree(n)
    for i in countup(0, sonsLen(n) - 1): 
      var a = getConstExpr(m, n.sons[i])
      if a == nil: return nil
      result.sons[i] = a
    incl(result.flags, nfAllConst)
  of nkObjConstr:
    result = copyTree(n)
    for i in countup(1, sonsLen(n) - 1):
      var a = getConstExpr(m, n.sons[i].sons[1])
      if a == nil: return nil
      result.sons[i].sons[1] = a
    incl(result.flags, nfAllConst)
  of nkPar:
    # tuple constructor
    result = copyTree(n)
    if (sonsLen(n) > 0) and (n.sons[0].kind == nkExprColonExpr): 
      for i in countup(0, sonsLen(n) - 1): 
        var a = getConstExpr(m, n.sons[i].sons[1])
        if a == nil: return nil
        result.sons[i].sons[1] = a
    else: 
      for i in countup(0, sonsLen(n) - 1): 
        var a = getConstExpr(m, n.sons[i])
        if a == nil: return nil
        result.sons[i] = a
    incl(result.flags, nfAllConst)
  of nkChckRangeF, nkChckRange64, nkChckRange: 
    var a = getConstExpr(m, n.sons[0])
    if a == nil: return 
    if leValueConv(n.sons[1], a) and leValueConv(a, n.sons[2]): 
      result = a              # a <= x and x <= b
      result.typ = n.typ
    else: 
      localError(n.info, errGenerated, `%`(
          msgKindToString(errIllegalConvFromXtoY), 
          [typeToString(n.sons[0].typ), typeToString(n.typ)]))
  of nkStringToCString, nkCStringToString: 
    var a = getConstExpr(m, n.sons[0])
    if a == nil: return 
    result = a
    result.typ = n.typ
  of nkHiddenStdConv, nkHiddenSubConv, nkConv: 
    var a = getConstExpr(m, n.sons[1])
    if a == nil: return
    result = foldConv(n, a, check=n.kind == nkHiddenStdConv)
  of nkCast:
    var a = getConstExpr(m, n.sons[1])
    if a == nil: return
    if n.typ.kind in NilableTypes:
      # we allow compile-time 'cast' for pointer types:
      result = a
      result.typ = n.typ
  of nkBracketExpr: result = foldArrayAccess(m, n)
  of nkDotExpr: result = foldFieldAccess(m, n)
  else:
    discard
