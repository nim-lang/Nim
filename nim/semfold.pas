//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//
unit semfold;

// this module folds constants; used by semantic checking phase
// and evaluation phase

interface

{$include 'config.inc'}

uses
  sysutils, nsystem, charsets, strutils,
  lists, options, ast, astalgo, trees, treetab, nimsets, ntime, nversion,
  platform, nmath, msgs, nos, condsyms, idents, rnimsyn, types;

function getConstExpr(module: PSym; n: PNode): PNode;
  // evaluates the constant expression or returns nil if it is no constant
  // expression

function evalOp(m: TMagic; n, a, b, c: PNode): PNode; 
function leValueConv(a, b: PNode): Boolean;

function newIntNodeT(const intVal: BiggestInt; n: PNode): PNode;
function newFloatNodeT(const floatVal: BiggestFloat; n: PNode): PNode;
function newStrNodeT(const strVal: string; n: PNode): PNode;
function getInt(a: PNode): biggestInt;
function getFloat(a: PNode): biggestFloat;
function getStr(a: PNode): string;
function getStrOrChar(a: PNode): string;

implementation

function newIntNodeT(const intVal: BiggestInt; n: PNode): PNode;
begin
  if skipTypes(n.typ, abstractVarRange).kind = tyChar then
    result := newIntNode(nkCharLit, intVal)
  else
    result := newIntNode(nkIntLit, intVal);
  result.typ := n.typ;
  result.info := n.info;
end;

function newFloatNodeT(const floatVal: BiggestFloat; n: PNode): PNode;
begin
  result := newFloatNode(nkFloatLit, floatVal);
  result.typ := n.typ;
  result.info := n.info;
end;

function newStrNodeT(const strVal: string; n: PNode): PNode;
begin
  result := newStrNode(nkStrLit, strVal);
  result.typ := n.typ;
  result.info := n.info;
end;

function getInt(a: PNode): biggestInt;
begin
  case a.kind of
    nkIntLit..nkInt64Lit: result := a.intVal;
    else begin internalError(a.info, 'getInt'); result := 0 end;
  end
end;

function getFloat(a: PNode): biggestFloat;
begin
  case a.kind of
    nkFloatLit..nkFloat64Lit: result := a.floatVal;
    else begin internalError(a.info, 'getFloat'); result := 0.0 end;
  end
end;

function getStr(a: PNode): string;
begin
  case a.kind of
    nkStrLit..nkTripleStrLit: result := a.strVal;
    else begin internalError(a.info, 'getStr'); result := '' end;
  end
end;

function getStrOrChar(a: PNode): string;
begin
  case a.kind of
    nkStrLit..nkTripleStrLit: result := a.strVal;
    nkCharLit: result := chr(int(a.intVal))+'';
    else begin internalError(a.info, 'getStrOrChar'); result := '' end;
  end
end;

function enumValToString(a: PNode): string;
var
  n: PNode;
  field: PSym;
  x: biggestInt;
  i: int;
begin
  x := getInt(a);
  n := skipTypes(a.typ, abstractInst).n;
  for i := 0 to sonsLen(n)-1 do begin
    if n.sons[i].kind <> nkSym then InternalError(a.info, 'enumValToString');
    field := n.sons[i].sym;
    if field.position = x then begin
      result := field.name.s; exit
    end;
  end;
  InternalError(a.info, 'no symbol for ordinal value: ' + toString(x));
end;

function evalOp(m: TMagic; n, a, b, c: PNode): PNode;
// b and c may be nil
begin
  result := nil;
  case m of
    mOrd:  result := newIntNodeT(getOrdValue(a), n);
    mChr:  result := newIntNodeT(getInt(a), n);
    mUnaryMinusI, mUnaryMinusI64: result := newIntNodeT(-getInt(a), n);
    mUnaryMinusF64: result := newFloatNodeT(-getFloat(a), n);
    mNot: result := newIntNodeT(1 - getInt(a), n);
    mCard: result := newIntNodeT(nimsets.cardSet(a), n);
    mBitnotI, mBitnotI64: result := newIntNodeT(not getInt(a), n);

    mLengthStr: result := newIntNodeT(length(getStr(a)), n);
    mLengthArray: result := newIntNodeT(lengthOrd(a.typ), n);
    mLengthSeq, mLengthOpenArray: 
      result := newIntNodeT(sonsLen(a), n); // BUGFIX

    mUnaryPlusI, mUnaryPlusI64, mUnaryPlusF64: result := a; // throw `+` away
    mToFloat, mToBiggestFloat:
      result := newFloatNodeT(toFloat(int(getInt(a))), n);
    mToInt, mToBiggestInt: result := newIntNodeT(nsystem.toInt(getFloat(a)), n);
    mAbsF64: result := newFloatNodeT(abs(getFloat(a)), n);
    mAbsI, mAbsI64: begin
      if getInt(a) >= 0 then result := a
      else result := newIntNodeT(-getInt(a), n);
    end;
    mZe8ToI, mZe8ToI64, mZe16ToI, mZe16ToI64, mZe32ToI64, mZeIToI64: begin
      // byte(-128) = 1...1..1000_0000'64 --> 0...0..1000_0000'64
      result := newIntNodeT(getInt(a) and (shlu(1, getSize(a.typ)*8) - 1), n);
    end;
    mToU8:  result := newIntNodeT(getInt(a) and $ff, n);
    mToU16: result := newIntNodeT(getInt(a) and $ffff, n);
    mToU32: result := newIntNodeT(getInt(a) and $00000000ffffffff, n);

    mSucc: result := newIntNodeT(getOrdValue(a)+getInt(b), n);
    mPred: result := newIntNodeT(getOrdValue(a)-getInt(b), n);

    mAddI, mAddI64: result := newIntNodeT(getInt(a)+getInt(b), n);
    mSubI, mSubI64: result := newIntNodeT(getInt(a)-getInt(b), n);
    mMulI, mMulI64: result := newIntNodeT(getInt(a)*getInt(b), n);
    mMinI, mMinI64: begin
      if getInt(a) > getInt(b) then result := newIntNodeT(getInt(b), n)
      else result := newIntNodeT(getInt(a), n);
    end;
    mMaxI, mMaxI64: begin
      if getInt(a) > getInt(b) then result := newIntNodeT(getInt(a), n)
      else result := newIntNodeT(getInt(b), n);
    end;
    mShlI, mShlI64: begin
      case skipTypes(n.typ, abstractRange).kind of
        tyInt8:  result := newIntNodeT(int8(getInt(a)) shl int8(getInt(b)), n);
        tyInt16: result := newIntNodeT(int16(getInt(a)) shl int16(getInt(b)), n);
        tyInt32: result := newIntNodeT(int32(getInt(a)) shl int32(getInt(b)), n);
        tyInt64, tyInt:
          result := newIntNodeT(shlu(getInt(a), getInt(b)), n);
        else InternalError(n.info, 'constant folding for shl');
      end
    end;
    mShrI, mShrI64: begin
      case skipTypes(n.typ, abstractRange).kind of
        tyInt8:  result := newIntNodeT(int8(getInt(a)) shr int8(getInt(b)), n);
        tyInt16: result := newIntNodeT(int16(getInt(a)) shr int16(getInt(b)), n);
        tyInt32: result := newIntNodeT(int32(getInt(a)) shr int32(getInt(b)), n);
        tyInt64, tyInt:
          result := newIntNodeT(shru(getInt(a), getInt(b)), n);
        else InternalError(n.info, 'constant folding for shl');
      end
    end;
    mDivI, mDivI64: result := newIntNodeT(getInt(a) div getInt(b), n);
    mModI, mModI64: result := newIntNodeT(getInt(a) mod getInt(b), n);

    mAddF64: result := newFloatNodeT(getFloat(a)+getFloat(b), n);
    mSubF64: result := newFloatNodeT(getFloat(a)-getFloat(b), n);
    mMulF64: result := newFloatNodeT(getFloat(a)*getFloat(b), n);
    mDivF64: begin
      if getFloat(b) = 0.0 then begin
        if getFloat(a) = 0.0 then
          result := newFloatNodeT(NaN, n)
        else
          result := newFloatNodeT(Inf, n);
      end
      else
        result := newFloatNodeT(getFloat(a)/getFloat(b), n);
    end;
    mMaxF64: begin
      if getFloat(a) > getFloat(b) then result := newFloatNodeT(getFloat(a), n)
      else result := newFloatNodeT(getFloat(b), n);
    end;
    mMinF64: begin
      if getFloat(a) > getFloat(b) then result := newFloatNodeT(getFloat(b), n)
      else result := newFloatNodeT(getFloat(a), n);
    end;
    mIsNil: result := newIntNodeT(ord(a.kind = nkNilLit), n);
    mLtI, mLtI64, mLtB, mLtEnum, mLtCh:
      result := newIntNodeT(ord(getOrdValue(a) < getOrdValue(b)), n);
    mLeI, mLeI64, mLeB, mLeEnum, mLeCh:
      result := newIntNodeT(ord(getOrdValue(a) <= getOrdValue(b)), n);
    mEqI, mEqI64, mEqB, mEqEnum, mEqCh:
      result := newIntNodeT(ord(getOrdValue(a) = getOrdValue(b)), n);
    // operators for floats
    mLtF64: result := newIntNodeT(ord(getFloat(a) < getFloat(b)), n);
    mLeF64: result := newIntNodeT(ord(getFloat(a) <= getFloat(b)), n);
    mEqF64: result := newIntNodeT(ord(getFloat(a) = getFloat(b)), n);
    // operators for strings
    mLtStr: result := newIntNodeT(ord(getStr(a) < getStr(b)), n);
    mLeStr: result := newIntNodeT(ord(getStr(a) <= getStr(b)), n);
    mEqStr: result := newIntNodeT(ord(getStr(a) = getStr(b)), n);

    mLtU, mLtU64:
      result := newIntNodeT(ord(ltU(getOrdValue(a), getOrdValue(b))), n);
    mLeU, mLeU64:
      result := newIntNodeT(ord(leU(getOrdValue(a), getOrdValue(b))), n);
    mBitandI, mBitandI64, mAnd:
      result := newIntNodeT(getInt(a) and getInt(b), n);
    mBitorI, mBitorI64, mOr:
      result := newIntNodeT(getInt(a) or getInt(b), n);
    mBitxorI, mBitxorI64, mXor:
      result := newIntNodeT(getInt(a) xor getInt(b), n);

    mAddU, mAddU64: result := newIntNodeT(addU(getInt(a), getInt(b)), n);
    mSubU, mSubU64: result := newIntNodeT(subU(getInt(a), getInt(b)), n);
    mMulU, mMulU64: result := newIntNodeT(mulU(getInt(a), getInt(b)), n);
    mModU, mModU64: result := newIntNodeT(modU(getInt(a), getInt(b)), n);
    mDivU, mDivU64: result := newIntNodeT(divU(getInt(a), getInt(b)), n);

    mLeSet: result := newIntNodeT(Ord(containsSets(a, b)), n);
    mEqSet: result := newIntNodeT(Ord(equalSets(a, b)), n);
    mLtSet: result := newIntNodeT(Ord(containsSets(a, b)
                                  and not equalSets(a, b)), n);
    mMulSet: begin
      result := nimsets.intersectSets(a, b);
      result.info := n.info;
    end;
    mPlusSet: begin
      result := nimsets.unionSets(a, b);
      result.info := n.info;
    end;
    mMinusSet: begin
      result := nimsets.diffSets(a, b);
      result.info := n.info;
    end;
    mSymDiffSet: begin
      result := nimsets.symdiffSets(a, b);
      result.info := n.info;
    end;
    mConStrStr: result := newStrNodeT(getStrOrChar(a)+{&}getStrOrChar(b), n);
    mInSet: result := newIntNodeT(Ord(inSet(a, b)), n);
    mRepr: begin
      // BUGFIX: we cannot eval mRepr here. But this means that it is not 
      // available for interpretation. I don't know how to fix this.
      //result := newStrNodeT(renderTree(a, {@set}[renderNoComments]), n);      
    end;
    mIntToStr, mInt64ToStr:
      result := newStrNodeT(toString(getOrdValue(a)), n);
    mBoolToStr: begin
      if getOrdValue(a) = 0 then
        result := newStrNodeT('false', n)
      else
        result := newStrNodeT('true', n)
    end;
    mCopyStr: 
      result := newStrNodeT(ncopy(getStr(a), int(getOrdValue(b))+strStart), n);
    mCopyStrLast: 
      result := newStrNodeT(ncopy(getStr(a), int(getOrdValue(b))+strStart, 
                                             int(getOrdValue(c))+strStart), n);
    mFloatToStr: result := newStrNodeT(toStringF(getFloat(a)), n);
    mCStrToStr, mCharToStr: result := newStrNodeT(getStrOrChar(a), n);
    mStrToStr: result := a;
    mEnumToStr: result := newStrNodeT(enumValToString(a), n);
    mArrToSeq: begin
      result := copyTree(a);
      result.typ := n.typ;
    end;
    mNewString, mExit, mInc, ast.mDec, mEcho, mAssert, mSwap,
    mAppendStrCh, mAppendStrStr, mAppendSeqElem, mAppendSeqSeq,
    mSetLengthStr, mSetLengthSeq, mNLen..mNError: begin end;
    else InternalError(a.info, 'evalOp(' +{&} magicToStr[m] +{&} ')');
  end
end;

function getConstIfExpr(c: PSym; n: PNode): PNode;
var
  i: int;
  it, e: PNode;
begin
  result := nil;
  for i := 0 to sonsLen(n) - 1 do begin
    it := n.sons[i];
    case it.kind of
      nkElifExpr: begin
        e := getConstExpr(c, it.sons[0]);
        if e = nil then begin result := nil; exit end;
        if getOrdValue(e) <> 0 then
          if result = nil then begin
            result := getConstExpr(c, it.sons[1]);
            if result = nil then exit
          end
      end;
      nkElseExpr: begin
        if result = nil then
          result := getConstExpr(c, it.sons[0]);
      end;
      else internalError(it.info, 'getConstIfExpr()');
    end
  end
end;

function partialAndExpr(c: PSym; n: PNode): PNode;
// partial evaluation
var
  a, b: PNode;
begin
  result := n;
  a := getConstExpr(c, n.sons[1]);
  b := getConstExpr(c, n.sons[2]);
  if a <> nil then begin
    if getInt(a) = 0 then result := a
    else if b <> nil then result := b
    else result := n.sons[2]
  end
  else if b <> nil then begin
    if getInt(b) = 0 then result := b
    else result := n.sons[1]
  end
end;

function partialOrExpr(c: PSym; n: PNode): PNode;
// partial evaluation
var
  a, b: PNode;
begin
  result := n;
  a := getConstExpr(c, n.sons[1]);
  b := getConstExpr(c, n.sons[2]);
  if a <> nil then begin
    if getInt(a) <> 0 then result := a
    else if b <> nil then result := b
    else result := n.sons[2]
  end
  else if b <> nil then begin
    if getInt(b) <> 0 then result := b
    else result := n.sons[1]
  end
end;

function leValueConv(a, b: PNode): Boolean;
begin
  result := false;
  case a.kind of
    nkCharLit..nkInt64Lit:
      case b.kind of
        nkCharLit..nkInt64Lit: result := a.intVal <= b.intVal;
        nkFloatLit..nkFloat64Lit: result := a.intVal <= round(b.floatVal);
        else InternalError(a.info, 'leValueConv');
      end;
    nkFloatLit..nkFloat64Lit:
      case b.kind of
        nkFloatLit..nkFloat64Lit: result := a.floatVal <= b.floatVal;
        nkCharLit..nkInt64Lit: result := a.floatVal <= toFloat(int(b.intVal));
        else InternalError(a.info, 'leValueConv');
      end;
    else InternalError(a.info, 'leValueConv');
  end
end;

function getConstExpr(module: PSym; n: PNode): PNode;
var
  s: PSym;
  a, b, c: PNode;
  i: int;
begin
  result := nil;
  case n.kind of
    nkSym: begin
      s := n.sym;
      if s.kind = skEnumField then
        result := newIntNodeT(s.position, n)
      else if (s.kind = skConst) then begin
        case s.magic of
          mIsMainModule:  
            result := newIntNodeT(ord(sfMainModule in module.flags), n);
          mCompileDate:   result := newStrNodeT(ntime.getDateStr(), n);
          mCompileTime:   result := newStrNodeT(ntime.getClockStr(), n);
          mNimrodVersion: result := newStrNodeT(VersionAsString, n);
          mNimrodMajor:   result := newIntNodeT(VersionMajor, n);
          mNimrodMinor:   result := newIntNodeT(VersionMinor, n);
          mNimrodPatch:   result := newIntNodeT(VersionPatch, n);
          mCpuEndian:     result := newIntNodeT(ord(CPU[targetCPU].endian), n);
          mHostOS:        
            result := newStrNodeT(toLower(platform.OS[targetOS].name), n);
          mHostCPU:       
            result := newStrNodeT(toLower(platform.CPU[targetCPU].name),n);
          mNaN:           result := newFloatNodeT(NaN, n);
          mInf:           result := newFloatNodeT(Inf, n);
          mNegInf:        result := newFloatNodeT(NegInf, n);
          else            result := copyTree(s.ast); // BUGFIX
        end
      end
      else if s.kind = skProc then // BUGFIX
        result := n
    end;
    nkCharLit..nkNilLit: result := copyNode(n);
    nkIfExpr: result := getConstIfExpr(module, n);
    nkCall, nkCommand, nkCallStrLit: begin
      if (n.sons[0].kind <> nkSym) then exit;
      s := n.sons[0].sym;
      if (s.kind <> skProc) then exit;
      try
        case s.magic of
          mNone: begin
            exit
            // XXX: if it has no sideEffect, it should be evaluated
          end;
          mSizeOf: begin
            a := n.sons[1];
            if computeSize(a.typ) < 0 then
              liMessage(a.info, errCannotEvalXBecauseIncompletelyDefined,
                        'sizeof');
            if a.typ.kind in [tyArray, tyObject, tyTuple] then
              result := nil // XXX: size computation for complex types
                            // is still wrong
            else
              result := newIntNodeT(getSize(a.typ), n);
          end;
          mLow:  result := newIntNodeT(firstOrd(n.sons[1].typ), n);
          mHigh: begin
            if not (skipTypes(n.sons[1].typ, abstractVar).kind in [tyOpenArray,
                                     tySequence, tyString]) then
              result := newIntNodeT(lastOrd(
                skipTypes(n.sons[1].typ, abstractVar)), n);
          end;
          else begin
            a := getConstExpr(module, n.sons[1]);
            if a = nil then exit;
            if sonsLen(n) > 2 then begin
              b := getConstExpr(module, n.sons[2]);
              if b = nil then exit;
              if sonsLen(n) > 3 then begin
                c := getConstExpr(module, n.sons[3]);
                if c = nil then exit;
              end
            end
            else b := nil;
            result := evalOp(s.magic, n, a, b, c);
          end
        end
      except
        on EIntOverflow do liMessage(n.info, errOverOrUnderflow);
        on EDivByZero do liMessage(n.info, errConstantDivisionByZero);
      end
    end;
    nkAddr: begin
      a := getConstExpr(module, n.sons[0]);
      if a <> nil then begin
        result := n;
        n.sons[0] := a
      end;
    end;
    nkBracket: begin
      result := copyTree(n);
      for i := 0 to sonsLen(n)-1 do begin
        a := getConstExpr(module, n.sons[i]);
        if a = nil then begin result := nil; exit end;
        result.sons[i] := a;
      end;
      include(result.flags, nfAllConst);
    end;
    nkRange: begin
      a := getConstExpr(module, n.sons[0]);
      if a = nil then exit;
      b := getConstExpr(module, n.sons[1]);
      if b = nil then exit;
      result := copyNode(n);
      addSon(result, a);
      addSon(result, b);
    end;
    nkCurly: begin
      result := copyTree(n);
      for i := 0 to sonsLen(n)-1 do begin
        a := getConstExpr(module, n.sons[i]);
        if a = nil then begin result := nil; exit end;
        result.sons[i] := a;
      end;
      include(result.flags, nfAllConst);
    end;
    nkPar: begin // tuple constructor
      result := copyTree(n);
      if (sonsLen(n) > 0) and (n.sons[0].kind = nkExprColonExpr) then begin
        for i := 0 to sonsLen(n)-1 do begin
          a := getConstExpr(module, n.sons[i].sons[1]);
          if a = nil then begin result := nil; exit end;
          result.sons[i].sons[1] := a;
        end
      end
      else begin
        for i := 0 to sonsLen(n)-1 do begin
          a := getConstExpr(module, n.sons[i]);
          if a = nil then begin result := nil; exit end;
          result.sons[i] := a;
        end
      end;
      include(result.flags, nfAllConst);
    end;
    nkChckRangeF, nkChckRange64, nkChckRange: begin
      a := getConstExpr(module, n.sons[0]);
      if a = nil then exit;
      if leValueConv(n.sons[1], a) and leValueConv(a, n.sons[2]) then begin
        result := a; // a <= x and x <= b
        result.typ := n.typ
      end
      else
        liMessage(n.info, errGenerated,
          format(msgKindToString(errIllegalConvFromXtoY),
            [typeToString(n.sons[0].typ), typeToString(n.typ)]));
    end;
    nkStringToCString, nkCStringToString: begin
      a := getConstExpr(module, n.sons[0]);
      if a = nil then exit;
      result := a;
      result.typ := n.typ;
    end;
    nkHiddenStdConv, nkHiddenSubConv, nkConv, nkCast: begin
      a := getConstExpr(module, n.sons[1]);
      if a = nil then exit;
      case skipTypes(n.typ, abstractRange).kind of
        tyInt..tyInt64: begin
          case skipTypes(a.typ, abstractRange).kind of
            tyFloat..tyFloat64: 
              result := newIntNodeT(nsystem.toInt(getFloat(a)), n);
            tyChar: 
              result := newIntNodeT(getOrdValue(a), n);
            else begin 
              result := a;
              result.typ := n.typ;
            end
          end
        end;
        tyFloat..tyFloat64: begin
          case skipTypes(a.typ, abstractRange).kind of
            tyInt..tyInt64, tyEnum, tyBool, tyChar: 
              result := newFloatNodeT(toFloat(int(getOrdValue(a))), n);
            else begin
              result := a;
              result.typ := n.typ;
            end
          end
        end;
        tyOpenArray, tyProc: begin end;
        else begin
          //n.sons[1] := a;
          //result := n;
          result := a;
          result.typ := n.typ;
        end
      end
    end
    else begin
    end
  end
end;

end.
