#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# this module folds constants; used by semantic checking phase
# and evaluation phase

import 
  strutils, lists, options, ast, astalgo, trees, treetab, nimsets, times, 
  nversion, platform, math, msgs, os, condsyms, idents, rnimsyn, types

proc getConstExpr*(module: PSym, n: PNode): PNode
  # evaluates the constant expression or returns nil if it is no constant
  # expression
proc evalOp*(m: TMagic, n, a, b, c: PNode): PNode
proc leValueConv*(a, b: PNode): bool
proc newIntNodeT*(intVal: BiggestInt, n: PNode): PNode
proc newFloatNodeT*(floatVal: BiggestFloat, n: PNode): PNode
proc newStrNodeT*(strVal: string, n: PNode): PNode
proc getInt*(a: PNode): biggestInt
proc getFloat*(a: PNode): biggestFloat
proc getStr*(a: PNode): string
proc getStrOrChar*(a: PNode): string
# implementation

proc newIntNodeT(intVal: BiggestInt, n: PNode): PNode = 
  if skipTypes(n.typ, abstractVarRange).kind == tyChar: 
    result = newIntNode(nkCharLit, intVal)
  else: 
    result = newIntNode(nkIntLit, intVal)
  result.typ = n.typ
  result.info = n.info

proc newFloatNodeT(floatVal: BiggestFloat, n: PNode): PNode = 
  result = newFloatNode(nkFloatLit, floatVal)
  result.typ = n.typ
  result.info = n.info

proc newStrNodeT(strVal: string, n: PNode): PNode = 
  result = newStrNode(nkStrLit, strVal)
  result.typ = n.typ
  result.info = n.info

proc getInt(a: PNode): biggestInt = 
  case a.kind
  of nkIntLit..nkInt64Lit: result = a.intVal
  else: 
    internalError(a.info, "getInt")
    result = 0

proc getFloat(a: PNode): biggestFloat = 
  case a.kind
  of nkFloatLit..nkFloat64Lit: result = a.floatVal
  else: 
    internalError(a.info, "getFloat")
    result = 0.0

proc getStr(a: PNode): string = 
  case a.kind
  of nkStrLit..nkTripleStrLit: result = a.strVal
  else: 
    internalError(a.info, "getStr")
    result = ""

proc getStrOrChar(a: PNode): string = 
  case a.kind
  of nkStrLit..nkTripleStrLit: result = a.strVal
  of nkCharLit: result = chr(int(a.intVal)) & ""
  else: 
    internalError(a.info, "getStrOrChar")
    result = ""

proc enumValToString(a: PNode): string = 
  var 
    n: PNode
    field: PSym
    x: biggestInt
  x = getInt(a)
  n = skipTypes(a.typ, abstractInst).n
  for i in countup(0, sonsLen(n) - 1): 
    if n.sons[i].kind != nkSym: InternalError(a.info, "enumValToString")
    field = n.sons[i].sym
    if field.position == x: 
      return field.name.s
  InternalError(a.info, "no symbol for ordinal value: " & $(x))

proc evalOp(m: TMagic, n, a, b, c: PNode): PNode = 
  # b and c may be nil
  result = nil
  case m
  of mOrd: 
    result = newIntNodeT(getOrdValue(a), n)
  of mChr: 
    result = newIntNodeT(getInt(a), n)
  of mUnaryMinusI, mUnaryMinusI64: 
    result = newIntNodeT(- getInt(a), n)
  of mUnaryMinusF64: 
    result = newFloatNodeT(- getFloat(a), n)
  of mNot: 
    result = newIntNodeT(1 - getInt(a), n)
  of mCard: 
    result = newIntNodeT(nimsets.cardSet(a), n)
  of mBitnotI, mBitnotI64: 
    result = newIntNodeT(not getInt(a), n)
  of mLengthStr: 
    result = newIntNodeT(len(getStr(a)), n)
  of mLengthArray: 
    result = newIntNodeT(lengthOrd(a.typ), n)
  of mLengthSeq, mLengthOpenArray: 
    result = newIntNodeT(sonsLen(a), n) # BUGFIX
  of mUnaryPlusI, mUnaryPlusI64, mUnaryPlusF64: 
    result = a                # throw `+` away
  of mToFloat, mToBiggestFloat: 
    result = newFloatNodeT(toFloat(int(getInt(a))), n)
  of mToInt, mToBiggestInt: 
    result = newIntNodeT(system.toInt(getFloat(a)), n)
  of mAbsF64: 
    result = newFloatNodeT(abs(getFloat(a)), n)
  of mAbsI, mAbsI64: 
    if getInt(a) >= 0: result = a
    else: result = newIntNodeT(- getInt(a), n)
  of mZe8ToI, mZe8ToI64, mZe16ToI, mZe16ToI64, mZe32ToI64, mZeIToI64: 
    # byte(-128) = 1...1..1000_0000'64 --> 0...0..1000_0000'64
    result = newIntNodeT(getInt(a) and (`shl`(1, getSize(a.typ) * 8) - 1), n)
  of mToU8: 
    result = newIntNodeT(getInt(a) and 0x000000FF, n)
  of mToU16: 
    result = newIntNodeT(getInt(a) and 0x0000FFFF, n)
  of mToU32: 
    result = newIntNodeT(getInt(a) and 0x00000000FFFFFFFF'i64, n)
  of mSucc: 
    result = newIntNodeT(getOrdValue(a) + getInt(b), n)
  of mPred: 
    result = newIntNodeT(getOrdValue(a) - getInt(b), n)
  of mAddI, mAddI64: 
    result = newIntNodeT(getInt(a) + getInt(b), n)
  of mSubI, mSubI64: 
    result = newIntNodeT(getInt(a) - getInt(b), n)
  of mMulI, mMulI64: 
    result = newIntNodeT(getInt(a) * getInt(b), n)
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
    of tyInt64, tyInt: result = newIntNodeT(`shl`(getInt(a), getInt(b)), n)
    else: InternalError(n.info, "constant folding for shl")
  of mShrI, mShrI64: 
    case skipTypes(n.typ, abstractRange).kind
    of tyInt8: result = newIntNodeT(int8(getInt(a)) shr int8(getInt(b)), n)
    of tyInt16: result = newIntNodeT(int16(getInt(a)) shr int16(getInt(b)), n)
    of tyInt32: result = newIntNodeT(int32(getInt(a)) shr int32(getInt(b)), n)
    of tyInt64, tyInt: result = newIntNodeT(`shr`(getInt(a), getInt(b)), n)
    else: InternalError(n.info, "constant folding for shl")
  of mDivI, mDivI64: 
    result = newIntNodeT(getInt(a) div getInt(b), n)
  of mModI, mModI64: 
    result = newIntNodeT(getInt(a) mod getInt(b), n)
  of mAddF64: 
    result = newFloatNodeT(getFloat(a) + getFloat(b), n)
  of mSubF64: 
    result = newFloatNodeT(getFloat(a) - getFloat(b), n)
  of mMulF64: 
    result = newFloatNodeT(getFloat(a) * getFloat(b), n)
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
  of mIsNil: 
    result = newIntNodeT(ord(a.kind == nkNilLit), n)
  of mLtI, mLtI64, mLtB, mLtEnum, mLtCh: 
    result = newIntNodeT(ord(getOrdValue(a) < getOrdValue(b)), n)
  of mLeI, mLeI64, mLeB, mLeEnum, mLeCh: 
    result = newIntNodeT(ord(getOrdValue(a) <= getOrdValue(b)), n)
  of mEqI, mEqI64, mEqB, mEqEnum, mEqCh: 
    result = newIntNodeT(ord(getOrdValue(a) == getOrdValue(b)), n) # operators for floats
  of mLtF64: 
    result = newIntNodeT(ord(getFloat(a) < getFloat(b)), n)
  of mLeF64: 
    result = newIntNodeT(ord(getFloat(a) <= getFloat(b)), n)
  of mEqF64: 
    result = newIntNodeT(ord(getFloat(a) == getFloat(b)), n) # operators for strings
  of mLtStr: 
    result = newIntNodeT(ord(getStr(a) < getStr(b)), n)
  of mLeStr: 
    result = newIntNodeT(ord(getStr(a) <= getStr(b)), n)
  of mEqStr: 
    result = newIntNodeT(ord(getStr(a) == getStr(b)), n)
  of mLtU, mLtU64: 
    result = newIntNodeT(ord(`<%`(getOrdValue(a), getOrdValue(b))), n)
  of mLeU, mLeU64: 
    result = newIntNodeT(ord(`<=%`(getOrdValue(a), getOrdValue(b))), n)
  of mBitandI, mBitandI64, mAnd: 
    result = newIntNodeT(getInt(a) and getInt(b), n)
  of mBitorI, mBitorI64, mOr: 
    result = newIntNodeT(getInt(a) or getInt(b), n)
  of mBitxorI, mBitxorI64, mXor: 
    result = newIntNodeT(getInt(a) xor getInt(b), n)
  of mAddU, mAddU64: 
    result = newIntNodeT(`+%`(getInt(a), getInt(b)), n)
  of mSubU, mSubU64: 
    result = newIntNodeT(`-%`(getInt(a), getInt(b)), n)
  of mMulU, mMulU64: 
    result = newIntNodeT(`*%`(getInt(a), getInt(b)), n)
  of mModU, mModU64: 
    result = newIntNodeT(`%%`(getInt(a), getInt(b)), n)
  of mDivU, mDivU64: 
    result = newIntNodeT(`/%`(getInt(a), getInt(b)), n)
  of mLeSet: 
    result = newIntNodeT(Ord(containsSets(a, b)), n)
  of mEqSet: 
    result = newIntNodeT(Ord(equalSets(a, b)), n)
  of mLtSet: 
    result = newIntNodeT(Ord(containsSets(a, b) and not equalSets(a, b)), n)
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
  of mConStrStr: 
    result = newStrNodeT(getStrOrChar(a) & getStrOrChar(b), n)
  of mInSet: 
    result = newIntNodeT(Ord(inSet(a, b)), n)
  of mRepr: 
    # BUGFIX: we cannot eval mRepr here. But this means that it is not 
    # available for interpretation. I don't know how to fix this.
    #result := newStrNodeT(renderTree(a, {@set}[renderNoComments]), n);      
  of mIntToStr, mInt64ToStr: 
    result = newStrNodeT($(getOrdValue(a)), n)
  of mBoolToStr: 
    if getOrdValue(a) == 0: result = newStrNodeT("false", n)
    else: result = newStrNodeT("true", n)
  of mCopyStr: 
    result = newStrNodeT(copy(getStr(a), int(getOrdValue(b)) + 0), n)
  of mCopyStrLast: 
    result = newStrNodeT(copy(getStr(a), int(getOrdValue(b)) + 0, 
                              int(getOrdValue(c)) + 0), n)
  of mFloatToStr: 
    result = newStrNodeT($(getFloat(a)), n)
  of mCStrToStr, mCharToStr: 
    result = newStrNodeT(getStrOrChar(a), n)
  of mStrToStr: 
    result = a
  of mEnumToStr: 
    result = newStrNodeT(enumValToString(a), n)
  of mArrToSeq: 
    result = copyTree(a)
    result.typ = n.typ
  of mNewString, mExit, mInc, ast.mDec, mEcho, mAssert, mSwap, mAppendStrCh, 
     mAppendStrStr, mAppendSeqElem, mSetLengthStr, mSetLengthSeq, mNLen..mNError: 
    nil
  else: InternalError(a.info, "evalOp(" & $m & ')')
  
proc getConstIfExpr(c: PSym, n: PNode): PNode = 
  var it, e: PNode
  result = nil
  for i in countup(0, sonsLen(n) - 1): 
    it = n.sons[i]
    case it.kind
    of nkElifExpr: 
      e = getConstExpr(c, it.sons[0])
      if e == nil: 
        return nil
      if getOrdValue(e) != 0: 
        if result == nil: 
          result = getConstExpr(c, it.sons[1])
          if result == nil: return 
    of nkElseExpr: 
      if result == nil: result = getConstExpr(c, it.sons[0])
    else: internalError(it.info, "getConstIfExpr()")
  
proc partialAndExpr(c: PSym, n: PNode): PNode = 
  # partial evaluation
  var a, b: PNode
  result = n
  a = getConstExpr(c, n.sons[1])
  b = getConstExpr(c, n.sons[2])
  if a != nil: 
    if getInt(a) == 0: result = a
    elif b != nil: result = b
    else: result = n.sons[2]
  elif b != nil: 
    if getInt(b) == 0: result = b
    else: result = n.sons[1]
  
proc partialOrExpr(c: PSym, n: PNode): PNode = 
  # partial evaluation
  var a, b: PNode
  result = n
  a = getConstExpr(c, n.sons[1])
  b = getConstExpr(c, n.sons[2])
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
  of nkCharLit..nkInt64Lit: 
    case b.kind
    of nkCharLit..nkInt64Lit: result = a.intVal <= b.intVal
    of nkFloatLit..nkFloat64Lit: result = a.intVal <= round(b.floatVal)
    else: InternalError(a.info, "leValueConv")
  of nkFloatLit..nkFloat64Lit: 
    case b.kind
    of nkFloatLit..nkFloat64Lit: result = a.floatVal <= b.floatVal
    of nkCharLit..nkInt64Lit: result = a.floatVal <= toFloat(int(b.intVal))
    else: InternalError(a.info, "leValueConv")
  else: InternalError(a.info, "leValueConv")
  
proc getConstExpr(module: PSym, n: PNode): PNode = 
  var 
    s: PSym
    a, b, c: PNode
  result = nil
  case n.kind
  of nkSym: 
    s = n.sym
    if s.kind == skEnumField: 
      result = newIntNodeT(s.position, n)
    elif (s.kind == skConst): 
      case s.magic
      of mIsMainModule: result = newIntNodeT(ord(sfMainModule in module.flags), 
          n)
      of mCompileDate: result = newStrNodeT(times.getDateStr(), n)
      of mCompileTime: result = newStrNodeT(times.getClockStr(), n)
      of mNimrodVersion: result = newStrNodeT(VersionAsString, n)
      of mNimrodMajor: result = newIntNodeT(VersionMajor, n)
      of mNimrodMinor: result = newIntNodeT(VersionMinor, n)
      of mNimrodPatch: result = newIntNodeT(VersionPatch, n)
      of mCpuEndian: result = newIntNodeT(ord(CPU[targetCPU].endian), n)
      of mHostOS: result = newStrNodeT(toLower(platform.OS[targetOS].name), n)
      of mHostCPU: result = newStrNodeT(toLower(platform.CPU[targetCPU].name), n)
      of mNaN: result = newFloatNodeT(NaN, n)
      of mInf: result = newFloatNodeT(Inf, n)
      of mNegInf: result = newFloatNodeT(NegInf, n)
      else: 
        result = copyTree(s.ast) # BUGFIX
    elif s.kind in {skProc, skMethod}: # BUGFIX
      result = n
  of nkCharLit..nkNilLit: 
    result = copyNode(n)
  of nkIfExpr: 
    result = getConstIfExpr(module, n)
  of nkCall, nkCommand, nkCallStrLit: 
    if (n.sons[0].kind != nkSym): return 
    s = n.sons[0].sym
    if (s.kind != skProc): return 
    try: 
      case s.magic
      of mNone: 
        return                # XXX: if it has no sideEffect, it should be evaluated
      of mSizeOf: 
        a = n.sons[1]
        if computeSize(a.typ) < 0: 
          liMessage(a.info, errCannotEvalXBecauseIncompletelyDefined, "sizeof")
        if a.typ.kind in {tyArray, tyObject, tyTuple}: 
          result = nil        # XXX: size computation for complex types
                              # is still wrong
        else: 
          result = newIntNodeT(getSize(a.typ), n)
      of mLow: 
        result = newIntNodeT(firstOrd(n.sons[1].typ), n)
      of mHigh: 
        if not (skipTypes(n.sons[1].typ, abstractVar).kind in
            {tyOpenArray, tySequence, tyString}): 
          result = newIntNodeT(lastOrd(skipTypes(n.sons[1].typ, abstractVar)), n)
      else: 
        a = getConstExpr(module, n.sons[1])
        if a == nil: return 
        if sonsLen(n) > 2: 
          b = getConstExpr(module, n.sons[2])
          if b == nil: return 
          if sonsLen(n) > 3: 
            c = getConstExpr(module, n.sons[3])
            if c == nil: return 
        else: 
          b = nil
        result = evalOp(s.magic, n, a, b, c)
    except EOverflow: 
      liMessage(n.info, errOverOrUnderflow)
    except EDivByZero: 
      liMessage(n.info, errConstantDivisionByZero)
  of nkAddr: 
    a = getConstExpr(module, n.sons[0])
    if a != nil: 
      result = n
      n.sons[0] = a
  of nkBracket: 
    result = copyTree(n)
    for i in countup(0, sonsLen(n) - 1): 
      a = getConstExpr(module, n.sons[i])
      if a == nil: 
        return nil
      result.sons[i] = a
    incl(result.flags, nfAllConst)
  of nkRange: 
    a = getConstExpr(module, n.sons[0])
    if a == nil: return 
    b = getConstExpr(module, n.sons[1])
    if b == nil: return 
    result = copyNode(n)
    addSon(result, a)
    addSon(result, b)
  of nkCurly: 
    result = copyTree(n)
    for i in countup(0, sonsLen(n) - 1): 
      a = getConstExpr(module, n.sons[i])
      if a == nil: 
        return nil
      result.sons[i] = a
    incl(result.flags, nfAllConst)
  of nkPar: 
    # tuple constructor
    result = copyTree(n)
    if (sonsLen(n) > 0) and (n.sons[0].kind == nkExprColonExpr): 
      for i in countup(0, sonsLen(n) - 1): 
        a = getConstExpr(module, n.sons[i].sons[1])
        if a == nil: 
          return nil
        result.sons[i].sons[1] = a
    else: 
      for i in countup(0, sonsLen(n) - 1): 
        a = getConstExpr(module, n.sons[i])
        if a == nil: 
          return nil
        result.sons[i] = a
    incl(result.flags, nfAllConst)
  of nkChckRangeF, nkChckRange64, nkChckRange: 
    a = getConstExpr(module, n.sons[0])
    if a == nil: return 
    if leValueConv(n.sons[1], a) and leValueConv(a, n.sons[2]): 
      result = a              # a <= x and x <= b
      result.typ = n.typ
    else: 
      liMessage(n.info, errGenerated, `%`(
          msgKindToString(errIllegalConvFromXtoY), 
          [typeToString(n.sons[0].typ), typeToString(n.typ)]))
  of nkStringToCString, nkCStringToString: 
    a = getConstExpr(module, n.sons[0])
    if a == nil: return 
    result = a
    result.typ = n.typ
  of nkHiddenStdConv, nkHiddenSubConv, nkConv, nkCast: 
    a = getConstExpr(module, n.sons[1])
    if a == nil: return 
    case skipTypes(n.typ, abstractRange).kind
    of tyInt..tyInt64: 
      case skipTypes(a.typ, abstractRange).kind
      of tyFloat..tyFloat64: result = newIntNodeT(system.toInt(getFloat(a)), n)
      of tyChar: result = newIntNodeT(getOrdValue(a), n)
      else: 
        result = a
        result.typ = n.typ
    of tyFloat..tyFloat64: 
      case skipTypes(a.typ, abstractRange).kind
      of tyInt..tyInt64, tyEnum, tyBool, tyChar: 
        result = newFloatNodeT(toFloat(int(getOrdValue(a))), n)
      else: 
        result = a
        result.typ = n.typ
    of tyOpenArray, tyProc: 
      nil
    else: 
      #n.sons[1] := a;
      #result := n;
      result = a
      result.typ = n.typ
  else: 
    nil
