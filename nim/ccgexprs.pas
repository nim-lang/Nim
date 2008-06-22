//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// -------------------------- constant expressions ------------------------

function intLiteral(i: biggestInt): PRope;
begin
  if (i > low(int32)) and (i <= high(int32)) then
    result := toRope(i)
  else if i = low(int32) then
    // Nimrod has the same bug for the same reasons :-)
    result := toRope('(-2147483647 -1)')
  else if i > low(int64) then
    result := ropeFormat('IL64($1)', [toRope(i)])
  else
    result := toRope('(IL64(-9223372036854775807) - IL64(1))')
end;

function genHexLiteral(v: PNode): PRope;
// in C hex literals are unsigned (at least I think so)
// so we don't generate hex literals any longer.
begin
  assert(v.kind in [nkIntLit..nkInt64Lit]);
  result := intLiteral(v.intVal)
end;

function getStrLit(const s: string): PRope;
begin
  inc(currMod.unique);
  result := con('Str', toRope(currMod.unique));
  appRopeFormat(currMod.s[cfsData],
    'STRING_LITERAL($1, $2, $3);$n',
    [result, makeCString(s), ToRope(length(s))])
end;

function genLiteral(p: BProc; v: PNode; ty: PType): PRope; overload;
var
  f: biggestFloat;
begin
  if ty = nil then internalError(v.info, 'genLiteral: ty is nil');
  case v.kind of
    nkIntLit..nkInt64Lit, nkCharLit..nkRCharLit: begin
      case skipVarGenericRange(ty).kind of
        tyChar, tyInt..tyInt64, tyNil: result := intLiteral(v.intVal);
        tyBool: begin
          if v.intVal <> 0 then result := toRope('NIM_TRUE')
          else result := toRope('NIM_FALSE');        
        end;
        else
          result := ropeFormat('(($1) $2)', [getTypeDesc(
            skipVarGenericRange(ty)), intLiteral(v.intVal)])
      end
    end;
    nkNilLit:
      result := toRope('0'+'');
    nkStrLit..nkTripleStrLit: begin
      if skipVarGenericRange(ty).kind = tyString then
        result := ropeFormat('((string) &$1)', [getStrLit(v.strVal)])
      else
        result := makeCString(v.strVal)
    end;
    nkFloatLit..nkFloat64Lit: begin
      f := v.floatVal;
      if f <> f then // NAN
        result := toRope('NAN')
      else if f = 0.0 then
        result := toRopeF(f)
      else if f = 0.5 * f then
        if f > 0.0 then result := toRope('INF')
        else result := toRope('-INF')
      else
        result := toRopeF(f);
    end
    else begin
      InternalError(v.info, 'genLiteral(' +{&} nodeKindToStr[v.kind] +{&} ')');
      result := nil
    end
  end;
  (*
  case ty.Kind of
    tyRange: result := genLiteral(p, v, ty.sons[0]);
    tyInt..tyInt64, tyEnum:
      result := intLiteral(v.intVal);
    tyPointer, tyRef, tyPtr, tyProc:
      if v.kind = nkNilLit then
        result := toRope('0'+'') // 0 is better for C++
      else
        result := ropeFormat('(($1) $2)',
                             [getTypeDesc(ty), intLiteral(v.intVal)]);
    tyFloat..tyFloat128: begin
      f := v.floatVal;
      // BUGFIX: handle INF and NAN correctly:
      if f <> f then // NAN
        result := toRope('NAN')
      else if f = 0.0 then
        result := toRopeF(f)
      else if f = 0.5 * f then
        if f > 0.0 then
          result := toRope('INF')
        else
          result := toRope('-INF')
      else
        result := toRopeF(f);
    end;
    tyString: begin // also merges constants
      if v.kind = nkNilLit then result := toRope('0'+'')
      else result := ropeFormat('((string) &$1)', [getStrLit(v.strVal)]);
    end;
    tyCString: begin
      if v.kind = nkNilLit then
        result := toRope('0'+'')
      else if v.kind in [nkIntLit..nkInt64Lit] then begin
        result := ropeFormat('((NCSTRING) $1)', [intLiteral(v.intVal)])
      end
      else 
        result := makeCString(v.strVal)
    end;
    tySequence: begin
      if v.kind = nkNilLit then 
        result := toRope('0'+'')      
      else if v.kind in [nkIntLit..nkInt64Lit] then
        result := ropeFormat('(($1) $2)',
                            [getTypeDesc(ty), intLiteral(v.intVal)])
      else begin
        assert(false);
        result := nil // XXX: to implement
      end
    end;
    tyChar: begin
      result := toRope('''' + toCChar(Chr(int(v.intVal))) + '''')
    end;
    tyBool:
      if v.intVal <> 0 then result := toRope('NIM_TRUE')
      else result := toRope('NIM_FALSE');
    tyNil:
      result := toRope('0'+''); // 0-pointer is better for C++
    tyVar: result := genLiteral(p, v, ty.sons[0]);
    else begin
      InternalError(v.info, 'genLiteral(' +{&} typeKindToStr[ty.kind] +{&} ')');
      result := nil
    end
  end*)
end;

function genLiteral(p: BProc; v: PNode): PRope; overload;
begin
  result := genLiteral(p, v, v.typ)
end;

function bitSetToWord(const s: TBitSet; size: int): BiggestInt;
var
  j: int;
begin
  result := 0;
  if CPU[hostCPU].endian = CPU[targetCPU].endian then begin
    for j := 0 to size-1 do
      if j < length(s) then result := result or shlu(s[j], j * 8)
  end
  else begin
    for j := 0 to size-1 do
      if j < length(s) then result := result or shlu(s[j], (Size - 1 - j) * 8)
  end
end;

function genRawSetData(const cs: TBitSet; size: int): PRope;
var
  frmt: TFormatStr;
  i: int;
begin
  if size > 8 then begin
    result := toRope('{' + tnl);
    for i := 0 to size-1 do begin
      if i < size-1 then begin  // not last iteration?
        if (i + 1) mod 8 = 0 then frmt := '0x$1,$n'
        else frmt := '0x$1, '
      end
      else frmt := '0x$1}$n';
      appRopeFormat(result, frmt, [toRope(toHex(cs[i], 2))])
    end
  end
  else
    result := toRope('0x' + ToHex(bitSetToWord(cs, size), IntSize * 2))
end;

function genSetNode(p: BProc; n: PNode): PRope;
var
  cs: TBitSet;
  size: int;
begin
  size := int(getSize(n.typ));
  toBitSet(n, cs);
  if size > 8 then begin
    result := getTempName();
    appRopeFormat(currMod.s[cfsData],
      'static $1$2 $3 = $4;',  // BUGFIX
      [constTok, getTypeDesc(n.typ), result, genRawSetData(cs, size)])
  end
  else
    result := genRawSetData(cs, size)
end;

// --------------------------- assignment generator -----------------------

function rdLoc(const a: TLoc): PRope; // 'read' location (deref if indirect)
begin
  result := a.r;
  if a.indirect > 0 then
    result := ropeFormat('($2$1)', 
                         [result, toRope(repeatChar(a.indirect, '*'))])
end;

function addrLoc(const a: TLoc): PRope;
begin
  result := a.r;
  if a.indirect = 0 then
    result := con('&'+'', result)
  else if a.indirect > 1 then
    result := ropeFormat('($2$1)', 
                         [result, toRope(repeatChar(a.indirect-1, '*'))])
end;

function rdCharLoc(const a: TLoc): PRope;
// read a location that may need a char-cast:
begin
  result := rdLoc(a);
  if skipRange(a.t).kind = tyChar then
    result := ropeFormat('((NU8)($1))', [result])
end;

procedure genRefAssign(p: BProc; const dest, src: TLoc);
begin
  if (lfOnStack in dest.flags) or not (optRefcGC in gGlobalOptions) then
    // location is on hardware stack
    appRopeFormat(p.s[cpsStmts], '$1 = $2;$n', [rdLoc(dest), rdLoc(src)])
  else if lfOnHeap in dest.flags then begin // location is on heap
    UseMagic('asgnRef');
    appRopeFormat(p.s[cpsStmts], 'asgnRef((void**) $1, $2);$n',
      [addrLoc(dest), rdLoc(src)])
  end
  else begin
    UseMagic('unsureAsgnRef');
    appRopeFormat(p.s[cpsStmts], 'unsureAsgnRef((void**) $1, $2);$n',
      [addrLoc(dest), rdLoc(src)])
  end
end;

type
  TAssignmentFlag = (needToCopy, needForSubtypeCheck);
  TAssignmentFlags = set of TAssignmentFlag;

procedure genAssignment(p: BProc; const dest, src: TLoc;
                        flags: TAssignmentFlags); overload;
  // This function replaces all other methods for generating
  // the assignment operation in C.
var
  ty: PType;
begin;
  ty := skipAbstract(dest.t);
  while ty.kind = tyVar do ty := ty.sons[0];
  case ty.kind of
    tyRef:
      genRefAssign(p, dest, src);
    tySequence: begin
      if not (needToCopy in flags) then
        genRefAssign(p, dest, src)
      else begin
        useMagic('genericSeqAssign'); // BUGFIX
        appRopeFormat(p.s[cpsStmts], 'genericSeqAssign($1, $2, $3);$n',
          [addrLoc(dest), rdLoc(src), genTypeInfo(currMod, dest.t)])
      end
    end;
    tyString: begin
      if not (needToCopy in flags) then
        genRefAssign(p, dest, src)
      else begin
        useMagic('copyString');
        if (lfOnStack in dest.flags) or not (optRefcGC in gGlobalOptions) then
          // location is on hardware stack
          appRopeFormat(p.s[cpsStmts], '$1 = copyString($2);$n',
            [rdLoc(dest), rdLoc(src)])
        else if lfOnHeap in dest.flags then begin // location is on heap
          useMagic('asgnRef');
          useMagic('copyString'); // BUGFIX
          appRopeFormat(p.s[cpsStmts], 'asgnRef((void**) $1, copyString($2));$n',
            [addrLoc(dest), rdLoc(src)])
        end
        else begin
          useMagic('unsureAsgnRef');
          useMagic('copyString'); // BUGFIX
          appRopeFormat(p.s[cpsStmts],
            'unsureAsgnRef((void**) $1, copyString($2));$n',
            [addrLoc(dest), rdLoc(src)])
        end
      end
    end;

    tyRecordConstr, tyRecord:
      // BUGFIX
      if needsComplexAssignment(dest.t) then begin
        useMagic('genericAssign');
        appRopeFormat(p.s[cpsStmts],
          'genericAssign((void*)$1, (void*)$2, $3);$n',
          [addrLoc(dest), addrLoc(src), genTypeInfo(currMod, dest.t)])
      end
      else
        appRopeFormat(p.s[cpsStmts], '$1 = $2;$n', [rdLoc(dest), rdLoc(src)]);
    tyArray, tyArrayConstr:
      if needsComplexAssignment(dest.t) then begin
        useMagic('genericAssign');
        appRopeFormat(p.s[cpsStmts],
          'genericAssign((void*)$1, (void*)$2, $3);$n',
          // XXX: is this correct for arrays?
          [addrLoc(dest), addrLoc(src), genTypeInfo(currMod, dest.t)])
      end
      else
        appRopeFormat(p.s[cpsStmts],
          'memcpy((void*)$1, (const void*)$2, sizeof($1));$n',
          [addrLoc(dest), addrLoc(src)]);
    tyObject:
      // XXX: check for subtyping?
      if needsComplexAssignment(dest.t) then begin
        useMagic('genericAssign');
        appRopeFormat(p.s[cpsStmts],
          'genericAssign((void*)$1, (void*)$2, $3);$n',
          [addrLoc(dest), addrLoc(src), genTypeInfo(currMod, dest.t)])
      end
      else
        appRopeFormat(p.s[cpsStmts], '$1 = $2;$n', [rdLoc(dest), rdLoc(src)]);
    tyOpenArray: begin
      // open arrays are always on the stack, really? What if a sequence is
      // passed to an open array?
      if needsComplexAssignment(dest.t) then begin
        useMagic('genericAssignOpenArray');
        appRopeFormat(p.s[cpsStmts],// XXX: is this correct for arrays?
          'genericAssignOpenArray((void*)$1, (void*)$2, $1Len0, $3);$n',
          [addrLoc(dest), addrLoc(src), genTypeInfo(currMod, dest.t)])
      end
      else
        appRopeFormat(p.s[cpsStmts],
          'memcpy((void*)$1, (const void*)$2, sizeof($1[0])*$1Len0);$n',
          [addrLoc(dest), addrLoc(src)]);
    end;
    tySet:
      if getSize(ty) <= 8 then
        appRopeFormat(p.s[cpsStmts], '$1 = $2;$n',
          [rdLoc(dest), rdLoc(src)])
      else
        appRopeFormat(p.s[cpsStmts], 'memcpy((void*)$1, (const void*)$2, $3);$n',
          [rdLoc(dest), rdLoc(src), toRope(getSize(dest.t))]);
    tyPtr, tyPointer, tyChar, tyBool, tyProc, tyEnum,
        tyCString, tyInt..tyFloat128, tyRange:
      appRopeFormat(p.s[cpsStmts], '$1 = $2;$n', [rdLoc(dest), rdLoc(src)]);
    else
      InternalError('genAssignment(' + typeKindToStr[ty.kind] + ')')
  end
end;

// ------------------------------ expressions -----------------------------

procedure expr(p: BProc; e: PNode; var d: TLoc); forward;

function initLocExpr(p: BProc; e: PNode): TLoc;
begin
  result := initLoc(locNone, e.typ);
  expr(p, e, result)
end;

procedure getDestLoc(p: BProc; var d: TLoc; typ: PType);
begin
  if d.k = locNone then d := getTemp(p, typ)
end;

procedure putLocIntoDest(p: BProc; var d: TLoc; const s: TLoc);
begin
  if d.k <> locNone then // need to generate an assignment here
    if lfNoDeepCopy in d.flags then
      genAssignment(p, d, s, {@set}[])
    else
      genAssignment(p, d, s, {@set}[needToCopy])
  else
    d := s // ``d`` is free, so fill it with ``s``
end;

procedure putIntoDest(p: BProc; var d: TLoc; t: PType; r: PRope);
var
  a: TLoc;
begin
  if d.k <> locNone then begin // need to generate an assignment here
    a := initLoc(locExpr, t);
    a.r := r;
    if lfNoDeepCopy in d.flags then
      genAssignment(p, d, a, {@set}[])
    else
      genAssignment(p, d, a, {@set}[needToCopy])
  end
  else begin // we cannot call initLoc() here as that would overwrite
             // the flags field!
    d.k := locExpr;
    d.t := t;
    d.r := r;
    d.a := -1
  end
end;

procedure binaryStmt(p: BProc; e: PNode; var d: TLoc;
                     const magic, frmt: string);
var
  a, b: TLoc;
begin
  assert(d.k = locNone);
  if magic <> '' then
    useMagic(magic);
  a := InitLocExpr(p, e.sons[1]);
  b := InitLocExpr(p, e.sons[2]);
  appRopeFormat(p.s[cpsStmts], frmt, [rdLoc(a), rdLoc(b)]);
  freeTemp(p, a);
  freeTemp(p, b)
end;

procedure binaryStmtChar(p: BProc; e: PNode; var d: TLoc;
                         const magic, frmt: string);
var
  a, b: TLoc;
begin
  assert(d.k = locNone);
  if magic <> '' then
    useMagic(magic);
  a := InitLocExpr(p, e.sons[1]);
  b := InitLocExpr(p, e.sons[2]);
  appRopeFormat(p.s[cpsStmts], frmt, [rdCharLoc(a), rdCharLoc(b)]);
  freeTemp(p, a);
  freeTemp(p, b)
end;

procedure binaryExpr(p: BProc; e: PNode; var d: TLoc;
                     const magic, frmt: string);
var
  a, b: TLoc;
begin
  if magic <> '' then
    useMagic(magic);
  assert(e.sons[1].typ <> nil);
  assert(e.sons[2].typ <> nil);
  a := InitLocExpr(p, e.sons[1]);
  b := InitLocExpr(p, e.sons[2]);
  putIntoDest(p, d, e.typ, ropeFormat(frmt, [rdLoc(a), rdLoc(b)]));
  if d.k <> locExpr then begin // BACKPORT
    freeTemp(p, a);
    freeTemp(p, b)
  end
end;

procedure binaryExprChar(p: BProc; e: PNode; var d: TLoc;
                         const magic, frmt: string);
var
  a, b: TLoc;
begin
  if magic <> '' then
    useMagic(magic);
  assert(e.sons[1].typ <> nil);
  assert(e.sons[2].typ <> nil);
  a := InitLocExpr(p, e.sons[1]);
  b := InitLocExpr(p, e.sons[2]);
  putIntoDest(p, d, e.typ, ropeFormat(frmt, [rdCharLoc(a), rdCharLoc(b)]));
  if d.k <> locExpr then begin // BACKPORT
    freeTemp(p, a);
    freeTemp(p, b)
  end
end;

procedure unaryExpr(p: BProc; e: PNode; var d: TLoc;
                    const magic, frmt: string);
var
  a: TLoc;
begin
  if magic <> '' then
    useMagic(magic);
  a := InitLocExpr(p, e.sons[1]);
  putIntoDest(p, d, e.typ, ropeFormat(frmt, [rdLoc(a)]));
  if d.k <> locExpr then // BACKPORT
    freeTemp(p, a)
end;

procedure unaryExprChar(p: BProc; e: PNode; var d: TLoc;
                        const magic, frmt: string);
var
  a: TLoc;
begin
  if magic <> '' then
    useMagic(magic);
  a := InitLocExpr(p, e.sons[1]);
  putIntoDest(p, d, e.typ, ropeFormat(frmt, [rdCharLoc(a)]));
  if d.k <> locExpr then // BACKPORT
    freeTemp(p, a)
end;

const
  binOverflowTab: array [mAddi..mModi64] of string = (
    'addInt', 'subInt', 'mulInt', 'divInt', 'modInt',
    'addInt64', 'subInt64', 'mulInt64', 'divInt64', 'modInt64'
  );
  binWoOverflowTab: array [mAddi..mModi64] of string = (
    '($1 + $2)', '($1 - $2)', '($1 * $2)', '($1 / $2)', '($1 % $2)',
    '($1 + $2)', '($1 - $2)', '($1 * $2)', '($1 / $2)', '($1 % $2)'
  );
  binArithTab: array [mShrI..mXor] of string = (
    '(NS)((NU)($1) >> (NU)($2))', // ShrI
    '(NS)((NU)($1) << (NU)($2))', // ShlI
    '($1 & $2)', // BitandI
    '($1 | $2)', // BitorI
    '($1 ^ $2)', // BitxorI
    '(($1 <= $2) ? $1 : $2)', // MinI
    '(($1 >= $2) ? $1 : $2)', // MaxI
    '(NS64)((NU64)($1) >> (NU64)($2))', // ShrI64
    '(NS64)((NU64)($1) << (NU64)($2))', // ShlI64
    '($1 & $2)', // BitandI64
    '($1 | $2)', // BitorI64
    '($1 ^ $2)', // BitxorI64
    '(($1 <= $2) ? $1 : $2)', // MinI64
    '(($1 >= $2) ? $1 : $2)', // MaxI64

    '($1 + $2)', // AddF64
    '($1 - $2)', // SubF64
    '($1 * $2)', // MulF64
    '($1 / $2)', // DivF64
    '(($1 <= $2) ? $1 : $2)', // MinF64
    '(($1 >= $2) ? $1 : $2)', // MaxF64

    '(NS)((NU)($1) + (NU)($2))', // AddU
    '(NS)((NU)($1) - (NU)($2))', // SubU
    '(NS)((NU)($1) * (NU)($2))', // MulU
    '(NS)((NU)($1) / (NU)($2))', // DivU
    '(NS)((NU)($1) % (NU)($2))', // ModU
    '(NS64)((NU64)($1) + (NU64)($2))', // AddU64
    '(NS64)((NU64)($1) - (NU64)($2))', // SubU64
    '(NS64)((NU64)($1) * (NU64)($2))', // MulU64
    '(NS64)((NU64)($1) / (NU64)($2))', // DivU64
    '(NS64)((NU64)($1) % (NU64)($2))', // ModU64

    '($1 == $2)', // EqI
    '($1 <= $2)', // LeI
    '($1 < $2)', // LtI
    '($1 == $2)', // EqI64
    '($1 <= $2)', // LeI64
    '($1 < $2)', // LtI64
    '($1 == $2)', // EqF64
    '($1 <= $2)', // LeF64
    '($1 < $2)', // LtF64

    '((NU)($1) <= (NU)($2))', // LeU
    '((NU)($1) < (NU)($2))',  // LtU
    '((NU64)($1) <= (NU64)($2))', // LeU64
    '((NU64)($1) < (NU64)($2))', // LtU64

    '($1 == $2)', // EqEnum
    '($1 <= $2)', // LeEnum
    '($1 < $2)', // LtEnum
    '((NU8)($1) == (NU8)($2))', // EqCh
    '((NU8)($1) <= (NU8)($2))', // LeCh
    '((NU8)($1) < (NU8)($2))', // LtCh
    '($1 == $2)', // EqB
    '($1 <= $2)', // LeB
    '($1 < $2)', // LtB

    '($1 == $2)', // EqRef
    '($1 == $2)', // EqProc
    '($1 == $2)', // EqPtr
    '($1 <= $2)', // LePtr
    '($1 < $2)', // LtPtr
    '($1 == $2)', // EqCString

    '($1 != $2)' // Xor
  );
  unArithTab: array [mNot..mToBiggestInt] of string = (
    '!($1)',  // Not
    '+($1)',  // UnaryPlusI
    '~($1)',  // BitnotI
    '+($1)',  // UnaryPlusI64
    '~($1)',  // BitnotI64
    '+($1)',  // UnaryPlusF64
    '-($1)',  // UnaryMinusF64
    '($1 > 0? ($1) : -($1))',  // AbsF64; BUGFIX: fabs() makes problems for Tiny C, so we don't use it

    '((NS)(NU)($1))',  // Ze
    '((NS64)(NU64)($1))', // Ze64
    '((NS8)(NU8)(NU)($1))', // ToU8
    '((NS16)(NU16)(NU)($1))', // ToU16
    '((NS32)(NU32)(NU64)($1))', // ToU32

    '((double) ($1))', // ToFloat
    '((double) ($1))', // ToBiggestFloat
    'float64ToInt32($1)', // ToInt XXX: this is not correct!
    'float64ToInt64($1)'  // ToBiggestInt
  );
  unOverflowTab: array [mUnaryMinusI..mAbsI64] of string = (
    'negInt', // UnaryMinusI
    'negInt64', // UnaryMinusI64
    'absInt', // AbsI
    'absInt64'  // AbsI64
  );
  unWoOverflowTab: array [mUnaryMinusI..mAbsI64] of string = (
    '-($1)', // UnaryMinusI
    '-($1)', // UnaryMinusI64
    'abs($1)', // AbsI
    '($1 > 0? ($1) : -($1))' // AbsI64
  );

procedure binaryArith(p: BProc; e: PNode; var d: TLoc; op: TMagic);
begin
  binaryExpr(p, e, d, '', binArithTab[op])
end;

procedure binaryArithOverflow(p: BProc; e: PNode; var d: TLoc; op: TMagic);
begin
  if optOverflowCheck in p.options then
    binaryExpr(p, e, d, binOverflowTab[op], binOverflowTab[op] + '($1, $2)')
  else
    binaryExpr(p, e, d, '', binWoOverflowTab[op])
end;

procedure unaryArith(p: BProc; e: PNode; var d: TLoc; op: TMagic);
begin
  unaryExpr(p, e, d, '', unArithTab[op])
end;

procedure unaryArithOverflow(p: BProc; e: PNode; var d: TLoc; op: TMagic);
begin
  if optOverflowCheck in p.options then
    unaryExpr(p, e, d, unOverflowTab[op], unOverflowTab[op] + '($1)')
  else
    unaryExpr(p, e, d, '', unWoOverflowTab[op])
end;

procedure genDeref(p: BProc; e: PNode; var d: TLoc);
var
  a: TLoc;
begin
  a := initLocExpr(p, e.sons[0]);
  putIntoDest(p, d, a.t.sons[0], ropeFormat('(*$1)', [rdLoc(a)]));
  if d.k <> locExpr then // BACKPORT
    freeTemp(p, a)
end;

procedure fillInLocation(var a, d: TLoc);
begin
  case skipAbstract(a.t).kind of
    tyRef: begin
      if d.k = locNone then d.flags := {@set}[lfOnHeap];
      a.r := ropeFormat('(*$1)', [a.r])
    end;
    tyPtr: begin
      if d.k = locNone then d.flags := {@set}[lfOnUnknown];
      a.r := ropeFormat('(*$1)', [a.r])
    end;
    // element has same flags as the array (except lfIndirect):
    else
      if d.k = locNone then inheritStorage(d, a)
  end
end;

procedure genRecordField(p: BProc; e: PNode; var d: TLoc);
var
  a: TLoc;
  f, field: PSym;
  ty: PType;
  r: PRope;
begin
  a := initLocExpr(p, e.sons[0]);
  assert(e.sons[1].kind = nkSym);
  f := e.sons[1].sym;

  if d.k = locNone then inheritStorage(d, a);
  // for objects we have to search the hierarchy for determining
  // how much ``Sup`` we need:
  ty := skipAbstract(a.t);
  while true do begin
    case ty.kind of
      tyRef: begin
        if d.k = locNone then d.flags := {@set}[lfOnHeap];
        inc(a.indirect);
      end;
      tyPtr: begin
        if d.k = locNone then d.flags := {@set}[lfOnUnknown];
        inc(a.indirect);
      end;
      tyVar: begin
        if d.k = locNone then d.flags := {@set}[lfOnUnknown];
      end;
      else break
    end;
    ty := skipAbstract(ty.sons[0]);
  end;
  r := rdLoc(a);
  {@discard} getTypeDesc(ty); // fill the record's fields.loc
  field := nil;
  while ty <> nil do begin
    assert(ty.kind in [tyRecord, tyObject]);
    field := lookupInRecord(ty.n, f.name);
    if field <> nil then break;
    if gCmd <> cmdCompileToCpp then app(r, '.Sup');
    ty := ty.sons[0]
  end;
  assert((field <> nil) and (field.loc.r <> nil));
  appRopeFormat(r, '.$1', [field.loc.r]);
  putIntoDest(p, d, field.typ, r);
  // freeTemp(p, a) // BACKPORT
end;

procedure genArrayElem(p: BProc; e: PNode; var d: TLoc);
var
  a, b: TLoc;
  ty: PType;
  first: PRope;
begin
  a := initLocExpr(p, e.sons[0]);
  b := initLocExpr(p, e.sons[1]);
  ty := skipAbstract(a.t);
  if ty.kind in [tyRef, tyPtr] then ty := skipAbstract(ty.sons[0]);
  first := intLiteral(firstOrd(ty));
  // emit range check:
  if optBoundsCheck in p.options then
    if b.k <> locImmediate then begin // semantic pass has already checked:
      useMagic('raiseIndexError');
      appRopeFormat(p.s[cpsStmts],
               'if ($1 < $2 || $1 > $3) raiseIndexError();$n',
               [rdCharLoc(b), first, intLiteral(lastOrd(ty))])
    end;
  fillInLocation(a, d);
  putIntoDest(p, d, elemType(skipVarGeneric(ty)), ropeFormat('$1[($2)-$3]',
    [rdLoc(a), rdCharLoc(b), first]));
  // freeTemp(p, a); // backport
  // freeTemp(p, b)
end;

procedure genCStringElem(p: BProc; e: PNode; var d: TLoc);
var
  a, b: TLoc;
  ty: PType;
begin
  a := initLocExpr(p, e.sons[0]);
  b := initLocExpr(p, e.sons[1]);
  ty := skipAbstract(a.t);
  fillInLocation(a, d);
  putIntoDest(p, d, elemType(skipVarGeneric(ty)), ropeFormat('$1[$2]',
    [rdLoc(a), rdCharLoc(b)]));
  // freeTemp(p, a); // backport
  // freeTemp(p, b)
end;

procedure genOpenArrayElem(p: BProc; e: PNode; var d: TLoc);
var
  a, b: TLoc;
begin
  a := initLocExpr(p, e.sons[0]);
  b := initLocExpr(p, e.sons[1]);
  // emit range check:
  if optBoundsCheck in p.options then
    if b.k <> locImmediate then begin // semantic pass has already checked:
      useMagic('raiseIndexError');
      appRopeFormat(p.s[cpsStmts],
        'if ((NU)($1) > (NU)($2Len0)) raiseIndexError();$n', [rdLoc(b), a.r])
    end;
  if d.k = locNone then inheritStorage(d, a);
  putIntoDest(p, d, elemType(skipVarGeneric(a.t)), ropeFormat('$1[$2]',
    [rdLoc(a), rdCharLoc(b)]));
  // freeTemp(p, a); // backport
  // freeTemp(p, b)
end;

procedure genSeqElem(p: BPRoc; e: PNode; var d: TLoc);
var
  a, b: TLoc;
  ty: PType;
begin
  a := initLocExpr(p, e.sons[0]);
  b := initLocExpr(p, e.sons[1]);
  ty := skipAbstract(a.t);
  if ty.kind in [tyRef, tyPtr] then ty := skipAbstract(ty.sons[0]);
  // emit range check:
  if optBoundsCheck in p.options then
    if b.k <> locImmediate then begin // semantic pass has already checked:
      useMagic('raiseIndexError');
      if ty.kind = tyString then
        appRopeFormat(p.s[cpsStmts],
          'if ((NU)($1) > (NU)($2->len)) raiseIndexError();$n',
          [rdLoc(b), rdLoc(a)])
      else
        appRopeFormat(p.s[cpsStmts],
          'if ((NU)($1) >= (NU)($2->len)) raiseIndexError();$n',
          [rdLoc(b), rdLoc(a)])
    end;
  // element has same flags as the array (except lfIndirect):
  if d.k = locNone then d.flags := {@set}[lfOnHeap];
  if skipAbstract(a.t).kind in [tyRef, tyPtr] then
    a.r := ropeFormat('(*$1)', [a.r]);
  putIntoDest(p, d, elemType(skipVarGeneric(a.t)), ropeFormat('$1->data[$2]',
    [rdLoc(a), rdCharLoc(b)]));
  // freeTemp(p, a); // backport
  // freeTemp(p, b)
end;

procedure genAndOr(p: BProc; e: PNode; var d: TLoc; m: TMagic);
// how to generate code?
//  'expr1 and expr2' becomes:
//     result = expr1
//     fjmp result, end
//     result = expr2
//  end:
//  ... (result computed)
// BUGFIX:
//   a = b or a
// used to generate:
// a = b
// if a: goto end
// a = a
// end:
// now it generates:
// tmp = b
// if tmp: goto end
// tmp = a
// end:
// a = tmp
var
  L: TLabel;
  tmp: TLoc;
begin
  tmp := getTemp(p, e.typ); // force it into a temp!
  expr(p, e.sons[1], tmp);
  L := getLabel(p);
  if m = mOr then
    appRopeFormat(p.s[cpsStmts], 'if ($1) goto $2;$n', [rdLoc(tmp), L])
  else // mAnd:
    appRopeFormat(p.s[cpsStmts], 'if (!($1)) goto $2;$n', [rdLoc(tmp), L]);
  expr(p, e.sons[2], tmp);
  fixLabel(p, L);
  if d.k = locNone then
    d := tmp
  else begin
    genAssignment(p, d, tmp, {@set}[]); // no need for deep copying
    freeTemp(p, tmp);
  end
end;

procedure genIfExpr(p: BProc; n: PNode; var d: TLoc);
(*
  if (!expr1) goto L1;
  thenPart
  goto LEnd
  L1:
  if (!expr2) goto L2;
  thenPart2
  goto LEnd
  L2:
  elsePart
  Lend:
*)
var
  i: int;
  it: PNode;
  a, tmp: TLoc;
  Lend, Lelse: TLabel;
begin
  tmp := getTemp(p, n.typ); // force it into a temp!
  Lend := getLabel(p);
  for i := 0 to sonsLen(n)-1 do begin
    it := n.sons[i];
    case it.kind of
      nkElifExpr: begin
        a := initLocExpr(p, it.sons[0]);
        Lelse := getLabel(p);
        appRopeFormat(p.s[cpsStmts], 'if (!$1) goto $2;$n', [rdLoc(a), Lelse]);
        freeTemp(p, a);
        expr(p, it.sons[1], tmp);
        appRopeFormat(p.s[cpsStmts], 'goto $1;$n', [Lend]);
        fixLabel(p, Lelse);
      end;
      nkElseExpr: begin
        expr(p, it.sons[0], tmp);
      end;
      else internalError(n.info, 'genIfExpr()');
    end
  end;
  fixLabel(p, Lend);
  if d.k = locNone then
    d := tmp
  else begin
    genAssignment(p, d, tmp, {@set}[]); // no need for deep copying
    freeTemp(p, tmp);
  end
end;

procedure genCall(p: BProc; t: PNode; var d: TLoc);
var
  param: PSym;
  a: array of TLoc;
  invalidRetType: bool;
  typ: PType;
  pl: PRope; // parameter list
  op, list: TLoc;
  len, i: int;
begin
  op := initLocExpr(p, t.sons[0]);
  pl := con(op.r, '('+'');
  typ := t.sons[0].typ;
  assert(typ.kind = tyProc);
  invalidRetType := isInvalidReturnType(typ.sons[0]);
  len := sonsLen(t);
  setLength(a, len-1);
  for i := 1 to len-1 do begin
    a[i-1] := initLocExpr(p, t.sons[i]); // generate expression for param
    assert(sonsLen(typ) = sonsLen(typ.n));
    if (i < sonsLen(typ)) then begin
      assert(typ.n.sons[i].kind = nkSym);
      param := typ.n.sons[i].sym;
      if usePtrPassing(param) then app(pl, addrLoc(a[i-1]))
      else                         app(pl, rdLoc(a[i-1]));
    end
    else
      app(pl, rdLoc(a[i-1]));
    if (i < len-1) or (invalidRetType and (typ.sons[0] <> nil)) then
      app(pl, ', ')
  end;
  if (typ.sons[0] <> nil) and invalidRetType then begin
    if d.k = locNone then d := getTemp(p, typ.sons[0]);
    app(pl, addrLoc(d))
  end;
  app(pl, ')'+'');
  for i := 0 to high(a) do
    freeTemp(p, a[i]); // important to free the temporaries
  freeTemp(p, op);
  if (typ.sons[0] <> nil) and not invalidRetType then begin
    if d.k = locNone then d := getTemp(p, typ.sons[0]);
    assert(d.t <> nil);
    // generate an assignment to d:
    list := initLoc(locCall, nil);
    list.r := pl;
    genAssignment(p, d, list, {@set}[]) // no need for deep copying
  end
  else
    appRopeFormat(p.s[cpsStmts], '$1;$n', [pl])
end;

procedure genStrConcat(p: BProc; e: PNode; var d: TLoc);
//   <Nimrod code>
//   s = 'hallo ' & name & ' how do you feel?' & 'z'
//
//   <generated C code>
//  {
//    string tmp0;
//    ...
//    tmp0 = rawNewString(6 + 17 + 1 + s2->len);
//    // we cannot generate s = rawNewString(...) here, because
//    // ``s`` may be used on the right side of the expression
//    appendString(tmp0, strlit_1);
//    appendString(tmp0, name);
//    appendString(tmp0, strlit_2);
//    appendChar(tmp0, 'z');
//    asgn(s, tmp0);
//  }
var
  tmp: TLoc;
  a: array of TLoc;
  appends, lens: PRope;
  L, i: int;
begin
  useMagic('rawNewString');
  tmp := getTemp(p, e.typ);
  L := 0;
  appends := nil;
  lens := nil;
  setLength(a, sonsLen(e)-1);
  for i := 0 to sonsLen(e)-2 do begin
    // compute the length expression:
    a[i] := initLocExpr(p, e.sons[i+1]);
    if skipAbstract(e.sons[i+1].Typ).kind = tyChar then begin
      Inc(L);
      useMagic('appendChar');
      appRopeFormat(appends, 'appendChar($1, $2);$n', [tmp.r, rdLoc(a[i])])
    end
    else begin
      if e.sons[i+1].kind in [nkStrLit..nkTripleStrLit] then  // string literal?
        Inc(L, length(e.sons[i+1].strVal))
      else
        appRopeFormat(lens, '$1->len + ', [rdLoc(a[i])]);
      useMagic('appendString');
      appRopeFormat(appends, 'appendString($1, $2);$n', [tmp.r, rdLoc(a[i])])
    end
  end;
  appRopeFormat(p.s[cpsStmts], '$1 = rawNewString($2$3);$n',
    [tmp.r, lens, toRope(L)]);
  app(p.s[cpsStmts], appends);
  for i := 0 to high(a) do
    freeTemp(p, a[i]);
  if d.k = locNone then
    d := tmp
  else begin
    genAssignment(p, d, tmp, {@set}[]); // no need for deep copying
    freeTemp(p, tmp); // BACKPORT
  end
end;

procedure genStrAppend(p: BProc; e: PNode; var d: TLoc);
//  <Nimrod code>
//  s &= 'hallo ' & name & ' how do you feel?' & 'z'
//  // BUG: what if s is on the left side too?
//  <generated C code>
//  {
//    s = resizeString(s, 6 + 17 + 1 + name->len);
//    appendString(s, strlit_1);
//    appendString(s, name);
//    appendString(s, strlit_2);
//    appendChar(s, 'z');
//  }
var
  a: array of TLoc;
  L, i: int;
  appends, lens: PRope;
begin
  assert(d.k = locNone);
  useMagic('resizeString');
  L := 0;
  appends := nil;
  lens := nil;
  setLength(a, sonsLen(e)-1);
  expr(p, e.sons[1], a[0]);
  for i := 0 to sonsLen(e)-3 do begin
    // compute the length expression:
    a[i+1] := initLocExpr(p, e.sons[i+2]);
    if skipAbstract(e.sons[i+2].Typ).kind = tyChar then begin
      Inc(L);
      useMagic('appendChar');
      appRopeFormat(appends, 'appendChar($1, $2);$n',
        [rdLoc(a[0]), rdLoc(a[i+1])])
    end
    else begin
      if e.sons[i+2].kind in [nkStrLit..nkTripleStrLit] then  // string literal?
        Inc(L, length(e.sons[i+2].strVal))
      else
        appRopeFormat(lens, '$1->len + ', [rdLoc(a[i+1])]);
      useMagic('appendString');
      appRopeFormat(appends, 'appendString($1, $2);$n',
        [rdLoc(a[0]), rdLoc(a[i+1])])
    end
  end;
  appRopeFormat(p.s[cpsStmts], '$1 = resizeString($1, $2$3);$n',
    [rdLoc(a[0]), lens, toRope(L)]);
  app(p.s[cpsStmts], appends);
  for i := 0 to high(a) do
    freeTemp(p, a[i])
end;

procedure genSeqElemAppend(p: BProc; e: PNode; var d: TLoc);
// seq &= x  -->
//    seq = (typeof seq) incrSeq( (TGenericSeq*) seq, sizeof(x));
//    seq->data[seq->len-1] = x;
var
  a, b, dest: TLoc;
begin
  useMagic('incrSeq');
  a := InitLocExpr(p, e.sons[1]);
  b := InitLocExpr(p, e.sons[2]);
  appRopeFormat(p.s[cpsStmts],
    '$1 = ($2) incrSeq((TGenericSeq*) $1, sizeof($3));$n',
    [rdLoc(a), getTypeDesc(skipVarGeneric(e.sons[1].typ)),
    getTypeDesc(skipVarGeneric(e.sons[2].Typ))]);
  dest := initLoc(locExpr, b.t);
  dest.flags := {@set}[lfOnHeap];
  dest.r := ropeFormat('$1->data[$1->len-1]', [rdLoc(a)]);
  genAssignment(p, dest, b, {@set}[needToCopy]);
  freeTemp(p, a);
  freeTemp(p, b)
end;

procedure genNew(p: BProc; e: PNode);
var
  a, b: TLoc;
  reftype, bt: PType;
begin
  useMagic('newObj');
  refType := skipAbstract(e.sons[1].typ);
  if refType.kind = tyVar then refType := skipAbstract(refType.sons[0]);
  a := InitLocExpr(p, e.sons[1]);
  b := initLoc(locExpr, a.t);
  b.flags := {@set}[lfOnHeap];
  b.r := ropeFormat('($1) newObj($2, sizeof($3))',
    [getTypeDesc(reftype), genTypeInfo(currMod, refType),
    getTypeDesc(skipAbstract(reftype.sons[0]))]);
  genAssignment(p, a, b, {@set}[]);
  // set the object type:
  bt := skipAbstract(refType.sons[0]);
  if containsObject(bt) then begin
    useMagic('objectInit');
    appRopeFormat(p.s[cpsStmts], 'objectInit($1, $2);$n',
                  [rdLoc(a), genTypeInfo(currMod, bt)])
  end;
  freeTemp(p, a)
end;

procedure genNewFinalize(p: BProc; e: PNode);
var
  a, b, f: TLoc;
  refType, bt: PType;
  ti: PRope;
begin
  useMagic('newObj');
  refType := skipAbstract(e.sons[1].typ);
  if refType.kind = tyVar then refType := skipAbstract(refType.sons[0]);
  a := InitLocExpr(p, e.sons[1]);
  f := InitLocExpr(p, e.sons[2]);
  b := initLoc(locExpr, a.t);
  b.flags := {@set}[lfOnHeap];
  ti := genTypeInfo(currMod, refType);
  appRopeFormat(currMod.s[cfsTypeInit3], '$1->finalizer = (void*)$2;$n', [
    ti, rdLoc(f)]);
  b.r := ropeFormat('($1) newObj($2, sizeof($3))',
                   [getTypeDesc(refType), ti,
                    getTypeDesc(skipAbstract(reftype.sons[0]))]);
  genAssignment(p, a, b, {@set}[]);
  // set the object type:
  bt := skipAbstract(refType.sons[0]);
  if containsObject(bt) then begin
    useMagic('objectInit');
    appRopeFormat(p.s[cpsStmts], 'objectInit($1, $2);$n',
                  [rdLoc(a), genTypeInfo(currMod, bt)])
  end;
  freeTemp(p, a);
  freeTemp(p, f)
end;

procedure genRepr(p: BProc; e: PNode; var d: TLoc);
var
  a: TLoc;
  t: PType;
begin
  a := InitLocExpr(p, e.sons[1]);
  t := skipAbstract(e.sons[1].typ);
  case t.kind of
    tyInt..tyInt64: begin
      UseMagic('reprInt');
      putIntoDest(p, d, e.typ, ropeFormat('reprInt($1)', [rdLoc(a)]))
    end;
    tyFloat..tyFloat128: begin
      UseMagic('reprFloat');
      putIntoDest(p, d, e.typ, ropeFormat('reprFloat($1)', [rdLoc(a)]))
    end;
    tyBool: begin
      UseMagic('reprBool');
      putIntoDest(p, d, e.typ, ropeFormat('reprBool($1)', [rdLoc(a)]))
    end;
    tyChar: begin
      UseMagic('reprChar');
      putIntoDest(p, d, e.typ, ropeFormat('reprChar($1)', [rdLoc(a)]))
    end;
    tyEnum: begin
      UseMagic('reprEnum');
      putIntoDest(p, d, e.typ,
        ropeFormat('reprEnum($1, $2)', [rdLoc(a), genTypeInfo(currMod, t)]))
    end;
    tyString: begin
      UseMagic('reprStr');
      putIntoDest(p, d, e.typ, ropeFormat('reprStr($1)', [rdLoc(a)]))
    end;
    tySet: begin
      useMagic('reprSet');
      putIntoDest(p, d, e.typ, ropeFormat('reprSet($1, $2)',
        [rdLoc(a), genTypeInfo(currMod, t)]))
    end;
    tyCString, tyArray, tyOpenArray, tyArrayConstr,
       tyRef, tyPtr, tyPointer, tyNil: begin
      useMagic('reprAny');
      putIntoDest(p, d, e.typ, ropeFormat('reprAny($1, $2)',
        [rdLoc(a), genTypeInfo(currMod, t)]))
    end
    else begin
      useMagic('reprAny');
      putIntoDest(p, d, e.typ, ropeFormat('reprAny($1, $2)',
        [addrLoc(a), genTypeInfo(currMod, t)]))
    end
  end;
  if d.k <> locExpr then
    freeTemp(p, a);
end;

procedure genArrayLen(p: BProc; e: PNode; var d: TLoc; op: TMagic);
var
  typ: PType;
begin
  typ := skipAbstract(e.sons[1].Typ);
  if typ.kind in [tyRef, tyPtr, tyVar] then
    typ := skipAbstract(typ.sons[0]);
  case typ.kind of
    tyOpenArray:
      if op = mHigh then
        unaryExpr(p, e, d, '', '($1Len0-1)')
      else
        unaryExpr(p, e, d, '', '$1Len0');
    tyString, tySequence:
      if op = mHigh then
        unaryExpr(p, e, d, '', '($1->len-1)')
      else
        unaryExpr(p, e, d, '', '$1->len');
    tyArray, tyArrayConstr: begin
      // YYY: length(sideeffect) is optimized away incorrectly?
      if op = mHigh then
        putIntoDest(p, d, e.typ, toRope(lastOrd(Typ)))
      else
        putIntoDest(p, d, e.typ, toRope(lengthOrd(typ)))
    end
    else
      InternalError(e.info, 'genArrayLen()')
  end
end;

procedure genSetLengthSeq(p: BProc; e: PNode; var d: TLoc);
var
  a, b: TLoc;
  t: PType;
begin
  assert(d.k = locNone);
  useMagic('setLengthSeq');
  a := InitLocExpr(p, e.sons[1]);
  b := InitLocExpr(p, e.sons[2]);
  t := skipVarGeneric(e.sons[1].typ);
  appRopeFormat(p.s[cpsStmts],
    '$1 = ($3) setLengthSeq((TGenericSeq*) ($1), sizeof($4), $2);$n',
    [rdLoc(a), rdLoc(b), getTypeDesc(t), getTypeDesc(t.sons[0])]);
  freeTemp(p, a);
  freeTemp(p, b)
end;

procedure genSetLengthStr(p: BProc; e: PNode; var d: TLoc);
begin
  binaryStmt(p, e, d, 'setLengthStr', '$1 = setLengthStr($1, $2);$n')
end;

procedure genSwap(p: BProc; e: PNode; var d: TLoc);
  // swap(a, b) -->
  // temp = a
  // a = b
  // b = temp
var
  a, b, tmp: TLoc;
begin
  tmp := getTemp(p, skipVarGeneric(e.sons[1].typ));
  a := InitLocExpr(p, e.sons[1]); // eval a
  b := InitLocExpr(p, e.sons[2]); // eval b
  genAssignment(p, tmp, a, {@set}[]);
  genAssignment(p, a, b, {@set}[]);
  genAssignment(p, b, tmp, {@set}[]);
  freeTemp(p, tmp); // BACKPORT
end;

// -------------------- set operations ------------------------------------

function rdSetElemLoc(const a: TLoc; setType: PType): PRope;
// read a location of an set element; it may need a substraction operation
// before the set operation
begin
  result := rdCharLoc(a);
  assert(setType.kind = tySet);
  if (firstOrd(setType) <> 0) then
    result := ropeFormat('($1-$2)', [result, toRope(firstOrd(setType))])
end;

function fewCmps(s: PNode): bool;
// this function estimates whether it is better to emit code
// for constructing the set or generating a bunch of comparisons directly
begin
  assert(s.kind in [nkSetConstr, nkConstSetConstr]);
  if (getSize(s.typ) <= platform.intSize) and
      (s.kind = nkConstSetConstr) then
    result := false      // it is better to emit the set generation code
  else if elemType(s.typ).Kind in [tyInt, tyInt16..tyInt64] then
    result := true       // better not emit the set if int is basetype!
  else
    result := sonsLen(s) <= 8 // 8 seems to be a good value
end;

procedure binaryExprIn(p: BProc; e: PNode; var d: TLoc; const frmt: string);
var
  a, b: TLoc;
begin
  assert(e.sons[1].typ <> nil);
  assert(e.sons[2].typ <> nil);
  a := InitLocExpr(p, e.sons[1]);
  b := InitLocExpr(p, e.sons[2]);
  putIntoDest(p, d, e.typ, ropeFormat(frmt, [rdLoc(a), rdSetElemLoc(b, a.t)]));
  if d.k <> locExpr then begin
    freeTemp(p, a);
    freeTemp(p, b)
  end
end;

procedure binaryStmtInExcl(p: BProc; e: PNode; var d: TLoc; const frmt: string);
var
  a, b: TLoc;
begin
  assert(d.k = locNone);
  a := InitLocExpr(p, e.sons[1]);
  b := InitLocExpr(p, e.sons[2]);
  appRopeFormat(p.s[cpsStmts], frmt, [rdLoc(a), rdSetElemLoc(b, a.t)]);
  freeTemp(p, a);
  freeTemp(p, b)
end;

procedure genInOp(p: BProc; e: PNode; var d: TLoc);
var
  a, b: TLoc;
  c: array of TLoc;  // Generate code for the 'in' operator
  len, i: int;
begin
  if (e.sons[1].Kind = nkSetConstr) and fewCmps(e.sons[1]) then begin
    // a set constructor but not a constant set:
    // do not emit the set, but generate a bunch of comparisons
    a := initLocExpr(p, e.sons[2]);
    b := initLoc(locExpr, e.typ);
    b.r := toRope('('+'');
    len := sonsLen(e.sons[1]);
    for i := 0 to len-1 do begin
      if e.sons[1].sons[i].Kind = nkRange then begin
        setLength(c, length(c)+2);
        c[high(c)-1] := InitLocExpr(p, e.sons[1].sons[i].sons[0]);
        c[high(c)] := InitLocExpr(p, e.sons[1].sons[i].sons[1]);
        appRopeFormat(b.r, '$1 >= $2 && $1 <= $3',
          [rdCharLoc(a), rdCharLoc(c[high(c)-1]), rdCharLoc(c[high(c)])])
      end
      else begin
        setLength(c, length(c)+1);
        c[high(c)] := InitLocExpr(p, e.sons[1].sons[i]);
        appRopeFormat(b.r, '$1 == $2', [rdCharLoc(a), rdCharLoc(c[high(c)])])
      end;
      if i < len - 1 then
        app(b.r, ' || ')
    end;
    app(b.r, ')'+'');
    putIntoDest(p, d, e.typ, b.r);
    if d.k <> locExpr then begin
      for i := 0 to high(c) do freeTemp(p, c[i]);
      freeTemp(p, a)
    end
  end
  else begin
    case int(getSize(skipVarGeneric(e.sons[1].typ))) of
      1: binaryExprIn(p, e, d, '(($1 &(1<<(($2)&7)))!=0)');
      2: binaryExprIn(p, e, d, '(($1 &(1<<(($2)&15)))!=0)');
      4: binaryExprIn(p, e, d, '(($1 &(1<<(($2)&31)))!=0)');
      8: binaryExprIn(p, e, d, '(($1 &(1<<(($2)&63)))!=0)');
      else binaryExprIn(p, e, d, '(($1[$2/8] &(1<<($2%8)))!=0)');
    end
  end
end;

procedure genSetOp(p: BProc; e: PNode; var d: TLoc; op: TMagic);
const
  lookupOpr: array [mLeSet..mSymDiffSet] of string = (
    'for ($1 = 0; $1 < $2; $1++) { $n' +
    '  $3 = (($4[$1] & ~ $5[$1]) == 0);$n' +
    '  if (!$3) break;}$n',
    'for ($1 = 0; $1 < $2; $1++) { $n' +
    '  $3 = (($4[$1] & ~ $5[$1]) == 0);$n' +
    '  if (!$3) break;}$n' +
    'if ($3) $3 = (memcmp($4, $5, $2) != 0);$n',
    '&'+'', '|'+'', '& ~', '^'+'');
var
  size: int;
  setType: PType;
  a, b, i: TLoc;
  ts: string;
begin
  setType := e.sons[1].Typ;
  if setType.kind = tyVar then setType := skipAbstract(setType.sons[0]);
  size := int(getSize(setType));
  case size of
    1, 2, 4, 8: begin
      case op of
        mIncl: begin
          ts := 'NS' + toString(size*8);
          binaryStmtInExcl(p, e, d,
            '$1 |=(1<<((' +{&} ts +{&} ')($2)%(sizeof(' +{&} ts +{&} 
            ')*8)));$n');
        end;
        mExcl: begin
          ts := 'NS' + toString(size*8);
          binaryStmtInExcl(p, e, d,
            '$1 &= ~(1 << ((' +{&} ts +{&} ')($2) % (sizeof(' +{&} ts +{&}
            ')*8)));$n');
        end;
        mCard: begin
          if size <= 4 then
            unaryExprChar(p, e, d, 'countBits32', 'countBits32($1)')
          else
            unaryExprChar(p, e, d, 'countBits64', 'countBits64($1)');
        end;
        mLtSet: binaryExprChar(p, e, d, '', '(($1 & ~ $2 ==0)&&($1 != $2))');
        mLeSet: binaryExprChar(p, e, d, '', '(($1 & ~ $2)==0)');
        mEqSet: binaryExpr(p, e, d, '', '($1 == $2)');
        mMulSet: binaryExpr(p, e, d, '', '($1 & $2)');
        mPlusSet: binaryExpr(p, e, d, '', '($1 | $2)');
        mMinusSet: binaryExpr(p, e, d, '', '($1 & ~ $2)');
        mSymDiffSet: binaryExpr(p, e, d, '', '($1 ^ $2)');
        mInSet: genInOp(p, e, d);
        else internalError(e.info, 'genSetOp()')
      end
    end
    else begin
      case op of
        mIncl: binaryStmtInExcl(p, e, d, '$1[$2/8] |=(1<<($2%8));$n');
        mExcl: binaryStmtInExcl(p, e, d, '$1[$2/8] &= ~(1<<($2%8));$n');
        mCard: unaryExprChar(p, e, d, 'countBitsVar',
                                  'countBitsVar($1, ' + ToString(size) + ')');
        mLtSet, mLeSet: begin
          i := getTemp(p, getSysType(tyInt)); // our counter
          a := initLocExpr(p, e.sons[1]);
          b := initLocExpr(p, e.sons[2]);
          if d.k = locNone then
            d := getTemp(p, a.t);
          appRopeFormat(p.s[cpsStmts], lookupOpr[op], [rdLoc(i), toRope(size),
            rdLoc(d), rdLoc(a), rdLoc(b)]);
          freeTemp(p, a);
          freeTemp(p, b);
          freeTemp(p, i)
        end;
        mEqSet:
          binaryExprChar(p, e, d, '',
                         '(memcmp($1, $2, ' + ToString(size) + ')==0)');
        mMulSet, mPlusSet, mMinusSet, mSymDiffSet: begin
          // we inline the simple for loop for better code generation:
          i := getTemp(p, getSysType(tyInt)); // our counter
          a := initLocExpr(p, e.sons[1]);
          b := initLocExpr(p, e.sons[2]);
          if d.k = locNone then
            d := getTemp(p, a.t);
          appRopeFormat(p.s[cpsStmts],
            'for ($1 = 0; $1 < $2; $1++) $n' +
            '  $3[$1] = $4[$1] $6 $5[$1];$n', [rdLoc(i), toRope(size),
            rdLoc(d), rdLoc(a), rdLoc(b), toRope(lookupOpr[op])]);
          freeTemp(p, a);
          freeTemp(p, b);
          freeTemp(p, i)
        end;
        mInSet: genInOp(p, e, d);
        else internalError(e.info, 'genSetOp')
      end
    end
  end
end;

// --------------------- end of set operations ----------------------------

procedure genMagicExpr(p: BProc; e: PNode; var d: TLoc; op: TMagic);
var
  a: TLoc;
  line, filen: PRope;
begin
  case op of
    mOr, mAnd: genAndOr(p, e, d, op);
    mNot..mToBiggestInt: unaryArith(p, e, d, op);
    mUnaryMinusI..mAbsI64: unaryArithOverflow(p, e, d, op);
    mShrI..mXor: binaryArith(p, e, d, op);
    mAddi..mModi64: binaryArithOverflow(p, e, d, op);
    mRepr: genRepr(p, e, d);
    mAsgn: begin
      a := InitLocExpr(p, e.sons[1]);
      assert(a.t <> nil);
      expr(p, e.sons[2], a);
      freeTemp(p, a)
    end;
    mSwap: genSwap(p, e, d);
    mPred: begin // XXX: range checking?
      if not (optOverflowCheck in p.Options) then
        binaryExpr(p, e, d, '', '$1 - $2')
      else
        binaryExpr(p, e, d, 'subInt', 'subInt($1, $2)')
    end;
    mSucc: begin // XXX: range checking?
      if not (optOverflowCheck in p.Options) then
        binaryExpr(p, e, d, '', '$1 - $2')
      else
        binaryExpr(p, e, d, 'addInt', 'addInt($1, $2)')
    end;
    mConStrStr: genStrConcat(p, e, d);
    mAppendStrCh: binaryStmt(p, e, d, 'addChar', '$1 = addChar($1, $2);$n');
    mAppendStrStr: genStrAppend(p, e, d);
    mAppendSeqElem: genSeqElemAppend(p, e, d);
    mEqStr: binaryExpr(p, e, d, 'eqStrings', 'eqStrings($1, $2)');
    mLeStr: binaryExpr(p, e, d, 'cmpStrings', '(cmpStrings($1, $2) <= 0)');
    mLtStr: binaryExpr(p, e, d, 'cmpStrings', '(cmpStrings($1, $2) < 0)');
    mAssert: begin
      if (optAssert in p.Options) then begin
        useMagic('internalAssert');
        expr(p, e.sons[1], d);
        line := toRope(toLinenumber(e.info));
        filen := makeCString(ToFilename(e.info));
        appRopeFormat(p.s[cpsStmts], 'internalAssert($1, $2, $3);$n',
                      [filen, line, rdLoc(d)])
      end
    end;
    mNew: genNew(p, e);
    mNewFinalize: genNewFinalize(p, e);
    mSizeOf:
      putIntoDest(p, d, e.typ,
        ropeFormat('sizeof($1)', [getTypeDesc(e.sons[1].typ)]));
    mChr: expr(p, e.sons[1], d);
    mOrd:
      // ord only allows things that are allowed in C anyway, so generate
      // no code for it:
      expr(p, e.sons[1], d);
    mLengthArray, mHigh, mLengthStr, mLengthSeq, mLengthOpenArray:
      genArrayLen(p, e, d, op);
    mInc: begin
      if not (optOverflowCheck in p.Options) then
        binaryStmt(p, e, d, '', '$1 += $2;$n')
      else
        binaryStmt(p, e, d, 'addInt', '$1 = addInt($1, $2);$n')
    end;
    ast.mDec: begin
      if not (optOverflowCheck in p.Options) then
        binaryStmt(p, e, d, '', '$1 -= $2;$n')
      else
        binaryStmt(p, e, d, 'subInt', '$1 = subInt($1, $2);$n')
    end;
    mSetLengthStr: genSetLengthStr(p, e, d);
    mSetLengthSeq: genSetLengthSeq(p, e, d);
    mIncl, mExcl, mCard, mLtSet, mLeSet, mEqSet, mMulSet, mPlusSet,
    mMinusSet, mInSet: genSetOp(p, e, d, op);
    mExit: genCall(p, e, d);
    else internalError(e.info, 'genMagicExpr: ' + magicToStr[op]);
  end
end;

procedure genSetConstr(p: BProc; e: PNode; var d: TLoc);
// example: { a..b, c, d, e, f..g }
// we have to emit an expression of the form:
// memset(tmp, 0, sizeof(tmp)); inclRange(tmp, a, b); incl(tmp, c);
// incl(tmp, d); incl(tmp, e); inclRange(tmp, f, g);
var
  a, b, idx: TLoc;
  i: int;
  ts: string;
begin
  if e.kind = nkConstSetConstr then
    putIntoDest(p, d, e.typ, genSetNode(p, e))
  else begin
    if d.k = locNone then d := getTemp(p, e.typ);
    if getSize(e.typ) > 8 then begin // big set:
      appRopeFormat(p.s[cpsStmts], 'memset($1, 0, sizeof($1));$n', [rdLoc(d)]);
      for i := 0 to sonsLen(e)-1 do begin
        if e.sons[i].kind = nkRange then begin
          idx := getTemp(p, getSysType(tyInt)); // our counter
          a := initLocExpr(p, e.sons[i].sons[1]);
          b := initLocExpr(p, e.sons[i].sons[2]);
          appRopeFormat(p.s[cpsStmts],
            'for ($1 = $3; $1 <= $4; $1++) $n' +
            '$2[$1/8] |=(1<<($1%8));$n',
            [rdLoc(idx), rdLoc(d), rdSetElemLoc(a, e.typ),
             rdSetElemLoc(b, e.typ)]);
          freeTemp(p, a);
          freeTemp(p, b);
          freeTemp(p, idx)
        end
        else begin
          a := initLocExpr(p, e.sons[i]);
          appRopeFormat(p.s[cpsStmts], '$1[$2/8] |=(1<<($2%8));$n',
                       [rdLoc(d), rdSetElemLoc(a, e.typ)]);
          freeTemp(p, a)
        end
      end
    end
    else begin // small set
      ts := 'NS' + toString(getSize(e.typ)*8);
      appRopeFormat(p.s[cpsStmts], '$1 = 0;$n', [rdLoc(d)]);
      for i := 0 to sonsLen(e) - 1 do begin
        if e.sons[i].kind = nkRange then begin
          idx := getTemp(p, getSysType(tyInt)); // our counter
          a := initLocExpr(p, e.sons[i].sons[1]);
          b := initLocExpr(p, e.sons[i].sons[2]);
          appRopeFormat(p.s[cpsStmts],
            'for ($1 = $3; $1 <= $4; $1++) $n' +{&}
            '$2 |=(1<<((' +{&} ts +{&} ')($1)%(sizeof(' +{&}ts+{&}')*8)));$n',
            [rdLoc(idx), rdLoc(d), rdSetElemLoc(a, e.typ),
             rdSetElemLoc(b, e.typ)]);
          freeTemp(p, a);
          freeTemp(p, b);
          freeTemp(p, idx)
        end
        else begin
          a := initLocExpr(p, e.sons[i]);
          appRopeFormat(p.s[cpsStmts],
                        '$1 |=(1<<((' +{&} ts +{&} ')($2)%(sizeof(' +{&}ts+{&}
                        ')*8)));$n',
                        [rdLoc(d), rdSetElemLoc(a, e.typ)]);
          freeTemp(p, a)
        end
      end
    end
  end
end;

procedure genRecordConstr(p: BProc; t: PNode; var d: TLoc);
var
  i, len: int;
  rec: TLoc;
begin
  {@discard} getTypeDesc(t.typ); // so that any fields are initialized
  if d.k = locNone then
    d := getTemp(p, t.typ);
  i := 0;
  len := sonsLen(t);
  while i < len do begin
    rec := initLoc(locExpr, t.sons[i].typ);
    assert(t.sons[i].sym.loc.r <> nil);
    rec.r := ropeFormat('$1.$2', [rdLoc(d), t.sons[i].sym.loc.r]);
    inheritStorage(rec, d);
    expr(p, t.sons[i+1], rec);
    inc(i, 2)
  end
end;

procedure genArrayConstr(p: BProc; t: PNode; var d: TLoc);
var
  arr: TLoc;
  i: int;
begin
  if d.k = locNone then
    d := getTemp(p, t.typ);
  for i := 0 to sonsLen(t)-1 do begin
    arr := initLoc(locExpr, elemType(skipGeneric(t.typ)));
    arr.r := ropeFormat('$1[$2]', [rdLoc(d), intLiteral(i)]);
    inheritStorage(arr, d);
    expr(p, t.sons[i], arr)
  end
end;

procedure genSeqConstr(p: BProc; t: PNode; var d: TLoc);
var
  newSeq, arr: TLoc;
  i: int;
begin
  useMagic('newSeq');
  if d.k = locNone then
    d := getTemp(p, t.typ);
  // generate call to newSeq before adding the elements per hand:

  newSeq := initLoc(locExpr, t.typ);
  newSeq.r := ropeFormat('($1) newSeq($2, $3)',
    [getTypeDesc(t.typ), genTypeInfo(currMod, t.typ), toRope(sonsLen(t))]);
  genAssignment(p, d, newSeq, {@set}[]);
  for i := 0 to sonsLen(t)-1 do begin
    arr := initLoc(locExpr, elemType(skipGeneric(t.typ)));
    arr.r := ropeFormat('$1->data[$2]', [rdLoc(d), intLiteral(i)]);
    arr.flags := {@set}[lfOnHeap]; // we know that sequences are on the heap
    expr(p, t.sons[i], arr)
  end
end;

procedure genCast(p: BProc; e: PNode; var d: TLoc);
const
  ValueTypes = {@set}[tyRecord, tyObject, tyArray, tyOpenArray, tyArrayConstr];
// we use whatever C gives us. Except if we have a value-type, we
// need to go through its address:
var
  a: TLoc;
begin
  a := InitLocExpr(p, e.sons[0]);
  if (skipAbstract(e.typ).kind in ValueTypes) and (a.indirect = 0) then
    putIntoDest(p, d, e.typ, ropeFormat('(*($1*) ($2))',
      [getTypeDesc(e.typ), addrLoc(a)]))
  else
    putIntoDest(p, d, e.typ, ropeFormat('(($1) ($2))',
      [getTypeDesc(e.typ), rdCharLoc(a)]));
  if d.k <> locExpr then
    freeTemp(p, a)
end;

procedure genConv(p: BProc; e: PNode; var d: TLoc);
  // type conversion: it doesn't matter if implicit or explicit;
  // type conversions are not casts!
var
  a: TLoc;
  r: PRope;
  source, dest: PType;
begin
  // numeric types need range checks:
  dest := skipVarGeneric(e.typ);
  case dest.kind of
    tyRange, tyInt..tyInt64, tyEnum, tyChar, tyBool: begin
      if not (optRangeCheck in p.options) or
          (firstOrd(dest) <= firstOrd(skipVarGeneric(e.sons[0].typ))) and // first >= x
           (lastOrd(skipVarGeneric(e.sons[0].typ)) <= lastOrd(dest)) then // x <= last
        expr(p, e.sons[0], d) // no need for a range check
      else begin // generate a range check:
        a := InitLocExpr(p, e.sons[0]);
        if    (a.t.kind in [tyFloat..tyFloat128]) or
             (dest.kind in [tyFloat..tyFloat128]) then begin
          useMagic('chckRangeF');
          putIntoDest(p, d, dest, ropeFormat('chckRangeF($1, $2, $3)',
            [rdCharLoc(a), genLiteral(p, dest.n.sons[0], dest),
                           genLiteral(p, dest.n.sons[1], dest)]))
        end
        else if (a.t.kind = tyInt64) or (dest.kind = tyInt64) then begin
          useMagic('chckRange64');
          putIntoDest(p, d, dest, ropeFormat('chckRange64($1, $2, $3)',
            [rdCharLoc(a), intLiteral(firstOrd(dest)),
                           intLiteral(lastOrd(dest))]))
        end
        else begin
          useMagic('chckRange');
          putIntoDest(p, d, dest, ropeFormat('chckRange($1, $2, $3)',
            [rdCharLoc(a), intLiteral(firstOrd(dest)),
                           intLiteral(lastOrd(dest))]))
        end;
        if d.k <> locExpr then
          freeTemp(p, a)
      end
    end;
    // open arrays need implicit length passed:
    tyOpenArray: begin
      a := initLocExpr(p, e.sons[0]);
      case a.t.kind of
        tyOpenArray:
          putIntoDest(p, d, dest, ropeFormat('$1, $1Len0', [rdLoc(a)]));
        tyString, tySequence:
          putIntoDest(p, d, dest, ropeFormat('$1->data, $1->len', [rdLoc(a)]));
        tyArray, tyArrayConstr:
          putIntoDest(p, d, dest, ropeFormat('$1, $2',
            [rdLoc(a), toRope(lengthOrd(a.t))]));
        else InternalError(e.sons[0].info, 'genConv()')
      end;
      if d.k <> locExpr then freeTemp(p, a)
    end;
    // conversions from string to cstring:
    tyCString: begin
      if skipVarGeneric(e.sons[0].typ).kind = tyString then begin
        a := initLocExpr(p, e.sons[0]);
        putIntoDest(p, d, e.typ, ropeFormat('$1->data', [rdLoc(a)]));
        if d.k <> locExpr then freeTemp(p, a)
      end
      else if not isCompatibleToCString(e.sons[0].typ) then
        // ordinary type cast:
        genCast(p, e, d)
      else
        expr(p, e.sons[0], d) // BUGFIX!
    end;
    // conversions from cstring to string:
    tyString: begin
      if skipVarGeneric(e.sons[0].typ).kind = tyCString then begin
        useMagic('cstrToNimstr');
        a := initLocExpr(p, e.sons[0]);
        putIntoDest(p, d, dest, ropeFormat('cstrToNimstr($1)', [rdLoc(a)]));
        if d.k <> locExpr then freeTemp(p, a)
      end
      else // ordinary type cast:
        genCast(p, e, d)
    end;
    // conversions between different object types:
    tyObject: begin
      source := skipVarGeneric(e.sons[0].typ);
      // if source is a subtype of dest, downcast:
      a := initLocExpr(p, e.sons[0]);
      r := rdLoc(a);
      while source.sons[0] <> nil do begin
        source := source.sons[0];
        if gCmd <> cmdCompileToCpp then
          app(r, '.Sup');
        if source.id = dest.id then break
      end;
      if source.id = dest.id then // we really have a downcast here:
        if gCmd = cmdCompileToCpp then
          putLocIntoDest(p, d, a) // downcast does C++ for us
        else
          putIntoDest(p, d, dest, r)
      else if gCmd = cmdCompileToCpp then
        genCast(p, e, d) // discard ``a``
      else // upcasts are uglier in C
        putIntoDest(p, d, dest, ropeFormat('(*($1*) ($2))',
          [getTypeDesc(dest), addrLoc(a)]));
      if d.k <> locExpr then freeTemp(p, a)
    end;
    tyGenericParam, tyAnyEnum:
      expr(p, e.sons[0], d);
      // happens sometimes for generated assignments, etc.
    else // use an ordinary cast
      genCast(p, e, d)
  end
end;

procedure genComplexConst(p: BProc; sym: PSym; var d: TLoc);
begin
  genConstPrototype(sym);
  assert((sym.loc.r <> nil) and (sym.loc.t <> nil));
  putLocIntoDest(p, d, sym.loc)
end;

procedure genStmtListExpr(p: BProc; n: PNode; var d: TLoc);
var
  len, i: int;
begin
  len := sonsLen(n);
  for i := 0 to len-2 do genStmts(p, n.sons[i]);
  if len > 0 then expr(p, n.sons[len-1], d);
end;

procedure genBlock(p: BProc; t: PNode; var d: TLoc); forward;

procedure expr(p: BProc; e: PNode; var d: TLoc);
// do not forget that lfIndirect in d.flags may be requested!
var
  sym: PSym;
  a: TLoc;
  ty: PType;
begin
  case e.kind of
    nkQualified: expr(p, e.sons[1], d);
    nkStrLit..nkTripleStrLit, nkIntLit..nkInt64Lit,
    nkFloatLit..nkFloat64Lit, nkNilLit, nkCharLit, nkRCharLit: begin
      putIntoDest(p, d, e.typ, genLiteral(p, e));
      d.k := locImmediate // for removal of index checks
    end;
    nkCall, nkHiddenCallConv: begin
      if (e.sons[0].kind = nkSym) and
         (e.sons[0].sym.magic <> mNone) then
        genMagicExpr(p, e, d, e.sons[0].sym.magic)
      else
        genCall(p, e, d)
    end;
    nkConstSetConstr, nkSetConstr: genSetConstr(p, e, d);
    nkConstArrayConstr, nkArrayConstr:
      if (skipAbstract(e.typ).kind = tySequence) then  // BUGFIX
        genSeqConstr(p, e, d)
      else
        genArrayConstr(p, e, d);
    nkConstRecordConstr, nkRecordConstr:
      genRecordConstr(p, e, d);
    nkCast: genCast(p, e, d);
    nkHiddenStdConv, nkHiddenSubConv, nkConv: genConv(p, e, d);
    nkAddr: begin
      a := InitLocExpr(p, e.sons[0]);
      putIntoDest(p, d, e.typ, addrLoc(a));
      if d.k <> locExpr then
        freeTemp(p, a)
    end;
    nkBracketExpr: begin
      ty := skipAbstract(e.sons[0].typ);
      if ty.kind in [tyRef, tyPtr, tyVar] then ty := skipAbstract(ty.sons[0]);
      case ty.kind of
        tyArray, tyArrayConstr: genArrayElem(p, e, d);
        tyOpenArray: genOpenArrayElem(p, e, d);
        tySequence, tyString: genSeqElem(p, e, d);
        tyCString: genCStringElem(p, e, d);
        else InternalError(e.info,
               'expr(nkBracketExpr, ' + typeKindToStr[ty.kind] + ')');
      end
    end;
    nkDerefExpr: genDeref(p, e, d);
    nkDotExpr: genRecordField(p, e, d);
    nkBlockExpr: genBlock(p, e, d);
    nkStmtListExpr: genStmtListExpr(p, e, d);
    nkIfExpr: genIfExpr(p, e, d);
    nkSym: begin
      sym := e.sym;
      case sym.Kind of
        skProc: begin
          // generate prototype if not already declared in this translation unit
          genProcPrototype(sym);
          if ((sym.loc.r = nil) or (sym.loc.t = nil)) then
            InternalError(e.info, 'expr: proc not init ' + sym.name.s);
          putLocIntoDest(p, d, sym.loc)
        end;
        skConst:
          if isSimpleConst(sym.typ) then
            putIntoDest(p, d, e.typ, genLiteral(p, sym.ast, sym.typ))
          else
            genComplexConst(p, sym, d);
        skEnumField: putIntoDest(p, d, e.typ, toRope(sym.position));
        skVar: begin
          if (sfGlobal in sym.flags) then genVarPrototype(sym);
          if ((sym.loc.r = nil) or (sym.loc.t = nil)) then
            InternalError(e.info, 'expr: var not init ' + sym.name.s);
          putLocIntoDest(p, d, sym.loc);
        end;
        skForVar, skTemp: begin
          if ((sym.loc.r = nil) or (sym.loc.t = nil)) then
            InternalError(e.info, 'expr: temp not init ' + sym.name.s);
          putLocIntoDest(p, d, sym.loc)
        end;
        skParam: begin
          if ((sym.loc.r = nil) or (sym.loc.t = nil)) then
            InternalError(e.info, 'expr: param not init ' + sym.name.s);
          putLocIntoDest(p, d, sym.loc)
        end
        else
          InternalError(e.info, 'expr(' +{&} symKindToStr[sym.kind] +{&}
                                '); unknown symbol')
      end
    end
    else
      InternalError(e.info, 'expr(' +{&} nodeKindToStr[e.kind] +{&}
                            '); unknown node kind')
  end
end;

// ---------------------- generation of complex constants -----------------

function transformRecordExpr(n: PNode): PNode;
var
  i: int;
  t: PType;
  field: PSym;
begin
  result := copyNode(n);
  newSons(result, sonsLen(n));
  t := skipAbstract(n.Typ);
  if t.kind = tyRecordConstr then 
    InternalError(n.info, 'transformRecordExpr: invalid type');
  for i := 0 to sonsLen(n)-1 do begin
    assert(n.sons[i].kind = nkExprColonExpr);
    assert(n.sons[i].sons[0].kind = nkSym);
    field := n.sons[i].sons[0].sym;
    field := lookupInRecord(t.n, field.name);
    if field = nil then
      InternalError(n.sons[i].info, 'transformRecordExpr: unknown field');
    if result.sons[field.position] <> nil then
      InternalError(n.sons[i].info, 'transformRecordExpr: value twice');
    result.sons[field.position] := copyTree(n.sons[i].sons[1]);
  end;
end;

function genConstExpr(p: BProc; n: PNode): PRope; forward;

function genConstSimpleList(p: BProc; n: PNode): PRope;
var
  len, i: int;
begin
  len := sonsLen(n);
  result := toRope('{'+'');
  for i := 0 to len - 2 do
    app(result, ropeFormat('$1,$n', [genConstExpr(p, n.sons[i])]));
  if len > 0 then app(result, genConstExpr(p, n.sons[len-1]));
  app(result, '}' + tnl)
end;

function genConstExpr(p: BProc; n: PNode): PRope;
var
  trans: PNode;
  cs: TBitSet;
begin
  case n.Kind of
    nkHiddenStdConv, nkHiddenSubConv: result := genConstExpr(p, n.sons[0]);
    nkSetConstr, nkConstSetConstr: begin
      toBitSet(n, cs);
      result := genRawSetData(cs, int(getSize(n.typ)))
      // XXX: tySequence!
    end;
    nkConstArrayConstr: result := genConstSimpleList(p, n);
    nkPar, nkConstRecordConstr, nkRecordConstr: begin
      if hasSonWith(n, nkExprColonExpr) then 
        trans := transformRecordExpr(n)
      else 
        trans := n;
      result := genConstSimpleList(p, trans);
    end
    else
      result := genLiteral(p, n)
  end
end;
