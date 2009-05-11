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
    result := ropef('IL64($1)', [toRope(i)])
  else
    result := toRope('(IL64(-9223372036854775807) - IL64(1))')
end;

function int32Literal(i: Int): PRope;
begin
  if i = int(low(int32)) then
    // Nimrod has the same bug for the same reasons :-)
    result := toRope('(-2147483647 -1)')
  else
    result := toRope(i)
end;

function genHexLiteral(v: PNode): PRope;
// hex literals are unsigned in C
// so we don't generate hex literals any longer.
begin
  if not (v.kind in [nkIntLit..nkInt64Lit]) then
    internalError(v.info, 'genHexLiteral');
  result := intLiteral(v.intVal)
end;

function getStrLit(m: BModule; const s: string): PRope;
begin
  useMagic(m, 'TGenericSeq');
  result := con('TMP', toRope(getID()));
  appf(m.s[cfsData], 'STRING_LITERAL($1, $2, $3);$n',
    [result, makeCString(s), ToRope(length(s))]);
end;

function genLiteral(p: BProc; v: PNode; ty: PType): PRope; overload;
var
  f: biggestFloat;
  id: int;
begin
  if ty = nil then internalError(v.info, 'genLiteral: ty is nil');
  case v.kind of
    nkCharLit..nkInt64Lit: begin
      case skipVarGenericRange(ty).kind of
        tyChar, tyInt64, tyNil: result := intLiteral(v.intVal);
        tyInt8:  
          result := ropef('((NI8) $1)', [intLiteral(biggestInt(int8(v.intVal)))]);
        tyInt16: 
          result := ropef('((NI16) $1)', [intLiteral(biggestInt(int16(v.intVal)))]);
        tyInt32: 
          result := ropef('((NI32) $1)', [intLiteral(biggestInt(int32(v.intVal)))]);
        tyInt: begin
          if (v.intVal >= low(int32)) and (v.intVal <= high(int32)) then
            result := int32Literal(int32(v.intVal))
          else
            result := intLiteral(v.intVal);
        end;
        tyBool: begin
          if v.intVal <> 0 then result := toRope('NIM_TRUE')
          else result := toRope('NIM_FALSE');
        end;
        else
          result := ropef('(($1) $2)', [getTypeDesc(p.module,
            skipVarGenericRange(ty)), intLiteral(v.intVal)])
      end
    end;
    nkNilLit:
      result := toRope('0'+'');
    nkStrLit..nkTripleStrLit: begin
      if skipVarGenericRange(ty).kind = tyString then begin
        id := NodeTableTestOrSet(p.module.dataCache, v, gid);
        if id = gid then begin
          // string literal not found in the cache:
          useMagic(p.module, 'NimStringDesc');
          result := ropef('((NimStringDesc*) &$1)',
                          [getStrLit(p.module, v.strVal)])
        end
        else
          result := ropef('((NimStringDesc*) &TMP$1)',
                          [toRope(id)]);
      end
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
  end
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
  if CPU[platform.hostCPU].endian = CPU[targetCPU].endian then begin
    for j := 0 to size-1 do
      if j < length(s) then
        result := result or shlu(Ze64(s[j]), j * 8)
  end
  else begin
    for j := 0 to size-1 do
      if j < length(s) then
        result := result or shlu(Ze64(s[j]), (Size-1-j) * 8)
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
      appf(result, frmt, [toRope(toHex(Ze64(cs[i]), 2))])
    end
  end
  else
    result := intLiteral(bitSetToWord(cs, size))
  //  result := toRope('0x' + ToHex(bitSetToWord(cs, size), size * 2))
end;

function genSetNode(p: BProc; n: PNode): PRope;
var
  cs: TBitSet;
  size, id: int;
begin
  size := int(getSize(n.typ));
  toBitSet(n, cs);
  if size > 8 then begin
    id := NodeTableTestOrSet(p.module.dataCache, n, gid);
    result := con('TMP', toRope(id));
    if id = gid then begin
      // not found in cache:
      inc(gid);
      appf(p.module.s[cfsData],
        'static NIM_CONST $1 $2 = $3;',
        [getTypeDesc(p.module, n.typ), result, genRawSetData(cs, size)])
    end
  end
  else
    result := genRawSetData(cs, size)
end;

// --------------------------- assignment generator -----------------------

function getStorageLoc(n: PNode): TStorageLoc;
begin
  case n.kind of
    nkSym: begin
      case n.sym.kind of
        skParam, skForVar, skTemp: result := OnStack;
        skVar: begin
          if sfGlobal in n.sym.flags then result := OnHeap
          else result := OnStack
        end;
        else result := OnUnknown;
      end
    end;
    //nkHiddenAddr, nkAddr:
    nkDerefExpr, nkHiddenDeref:
      case n.sons[0].typ.kind of
        tyVar: result := OnUnknown;
        tyPtr: result := OnStack;
        tyRef: result := OnHeap;
        else InternalError(n.info, 'getStorageLoc');
      end;
    nkBracketExpr, nkDotExpr, nkObjDownConv, nkObjUpConv:
      result := getStorageLoc(n.sons[0]);
    else result := OnUnknown;
  end
end;

function rdLoc(const a: TLoc): PRope; // 'read' location (deref if indirect)
begin
  result := a.r;
  if lfIndirect in a.flags then
    result := ropef('(*$1 /*rdLoc*/)', [result])
end;

function addrLoc(const a: TLoc): PRope;
begin
  result := a.r;
  if not (lfIndirect in a.flags) then
    result := con('&'+'', result)
end;

function rdCharLoc(const a: TLoc): PRope;
// read a location that may need a char-cast:
begin
  result := rdLoc(a);
  if skipRange(a.t).kind = tyChar then
    result := ropef('((NU8)($1))', [result])
end;

type
  TAssignmentFlag = (needToCopy, needForSubtypeCheck,
                     afDestIsNil, afDestIsNotNil,
                     afSrcIsNil, afSrcIsNotNil);
  TAssignmentFlags = set of TAssignmentFlag;

procedure genRefAssign(p: BProc; const dest, src: TLoc;
                       flags: TAssignmentFlags);
begin
  if (dest.s = OnStack) or not (optRefcGC in gGlobalOptions) then
    // location is on hardware stack
    appf(p.s[cpsStmts], '$1 = $2;$n', [rdLoc(dest), rdLoc(src)])
  else if dest.s = OnHeap then begin // location is on heap
    // now the writer barrier is inlined for performance:
    (*
    if afSrcIsNotNil in flags then begin
      UseMagic(p.module, 'nimGCref');
      appf(p.s[cpsStmts], 'nimGCref($1);$n', [rdLoc(src)]);
    end
    else if not (afSrcIsNil in flags) then begin
      UseMagic(p.module, 'nimGCref');
      appf(p.s[cpsStmts], 'if ($1) nimGCref($1);$n', [rdLoc(src)]);
    end;
    if afDestIsNotNil in flags then begin
      UseMagic(p.module, 'nimGCunref');
      appf(p.s[cpsStmts], 'nimGCunref($1);$n', [rdLoc(dest)]);
    end
    else if not (afDestIsNil in flags) then begin
      UseMagic(p.module, 'nimGCunref');
      appf(p.s[cpsStmts], 'if ($1) nimGCunref($1);$n', [rdLoc(dest)]);
    end;
    appf(p.s[cpsStmts], '$1 = $2;$n', [rdLoc(dest), rdLoc(src)]); *)
    if canFormAcycle(dest.t) then begin
      UseMagic(p.module, 'asgnRef');
      appf(p.s[cpsStmts], 'asgnRef((void**) $1, $2);$n',
                         [addrLoc(dest), rdLoc(src)])
    end
    else begin
      UseMagic(p.module, 'asgnRefNoCycle');
      appf(p.s[cpsStmts], 'asgnRefNoCycle((void**) $1, $2);$n',
                         [addrLoc(dest), rdLoc(src)])    
    end
  end
  else begin
    UseMagic(p.module, 'unsureAsgnRef');
    appf(p.s[cpsStmts], 'unsureAsgnRef((void**) $1, $2);$n',
      [addrLoc(dest), rdLoc(src)])
  end
end;

procedure genAssignment(p: BProc; const dest, src: TLoc;
                        flags: TAssignmentFlags); overload;
  // This function replaces all other methods for generating
  // the assignment operation in C.
var
  ty: PType;
begin;
  ty := skipVarGenericRange(dest.t);
  case ty.kind of
    tyRef:
      genRefAssign(p, dest, src, flags);
    tySequence: begin
      if not (needToCopy in flags) then
        genRefAssign(p, dest, src, flags)
      else begin
        useMagic(p.module, 'genericSeqAssign'); // BUGFIX
        appf(p.s[cpsStmts], 'genericSeqAssign($1, $2, $3);$n',
          [addrLoc(dest), rdLoc(src), genTypeInfo(p.module, dest.t)])
      end
    end;
    tyString: begin
      if not (needToCopy in flags) then
        genRefAssign(p, dest, src, flags)
      else begin
        useMagic(p.module, 'copyString');
        if (dest.s = OnStack) or not (optRefcGC in gGlobalOptions) then
          appf(p.s[cpsStmts], '$1 = copyString($2);$n',
            [rdLoc(dest), rdLoc(src)])
        else if dest.s = OnHeap then begin
          useMagic(p.module, 'asgnRefNoCycle');
          useMagic(p.module, 'copyString'); // BUGFIX
          appf(p.s[cpsStmts], 'asgnRefNoCycle((void**) $1, copyString($2));$n',
            [addrLoc(dest), rdLoc(src)])
        end
        else begin
          useMagic(p.module, 'unsureAsgnRef');
          useMagic(p.module, 'copyString'); // BUGFIX
          appf(p.s[cpsStmts],
            'unsureAsgnRef((void**) $1, copyString($2));$n',
            [addrLoc(dest), rdLoc(src)])
        end
      end
    end;

    tyTuple:
      if needsComplexAssignment(dest.t) then begin
        useMagic(p.module, 'genericAssign');
        appf(p.s[cpsStmts],
          'genericAssign((void*)$1, (void*)$2, $3);$n',
          [addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t)])
      end
      else
        appf(p.s[cpsStmts], '$1 = $2;$n', [rdLoc(dest), rdLoc(src)]);
    tyArray, tyArrayConstr:
      if needsComplexAssignment(dest.t) then begin
        useMagic(p.module, 'genericAssign');
        appf(p.s[cpsStmts],
          'genericAssign((void*)$1, (void*)$2, $3);$n',
          [addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t)])
      end
      else
        appf(p.s[cpsStmts],
          'memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($1));$n',
          [rdLoc(dest), rdLoc(src)]);
    tyObject:
      // XXX: check for subtyping?
      if needsComplexAssignment(dest.t) then begin
        useMagic(p.module, 'genericAssign');
        appf(p.s[cpsStmts],
          'genericAssign((void*)$1, (void*)$2, $3);$n',
          [addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t)])
      end
      else
        appf(p.s[cpsStmts], '$1 = $2;$n', [rdLoc(dest), rdLoc(src)]);
    tyOpenArray: begin
      // open arrays are always on the stack - really? What if a sequence is
      // passed to an open array?
      if needsComplexAssignment(dest.t) then begin
        useMagic(p.module, 'genericAssignOpenArray');
        appf(p.s[cpsStmts],// XXX: is this correct for arrays?
          'genericAssignOpenArray((void*)$1, (void*)$2, $1Len0, $3);$n',
          [addrLoc(dest), addrLoc(src), genTypeInfo(p.module, dest.t)])
      end
      else
        appf(p.s[cpsStmts],
          'memcpy((void*)$1, (NIM_CONST void*)$2, sizeof($1[0])*$1Len0);$n',
          [rdLoc(dest), rdLoc(src)]);
    end;
    tySet:
      if mapType(ty) = ctArray then
        appf(p.s[cpsStmts], 'memcpy((void*)$1, (NIM_CONST void*)$2, $3);$n',
          [rdLoc(dest), rdLoc(src), toRope(getSize(dest.t))])
      else
        appf(p.s[cpsStmts], '$1 = $2;$n',
          [rdLoc(dest), rdLoc(src)]);
    tyPtr, tyPointer, tyChar, tyBool, tyProc, tyEnum,
        tyCString, tyInt..tyFloat128, tyRange:
      appf(p.s[cpsStmts], '$1 = $2;$n', [rdLoc(dest), rdLoc(src)]);
    else
      InternalError('genAssignment(' + typeKindToStr[ty.kind] + ')')
  end
end;

// ------------------------------ expressions -----------------------------

procedure expr(p: BProc; e: PNode; var d: TLoc); forward;

procedure initLocExpr(p: BProc; e: PNode; var result: TLoc);
begin
  initLoc(result, locNone, getUniqueType(e.typ), OnUnknown);
  expr(p, e, result)
end;

procedure getDestLoc(p: BProc; var d: TLoc; typ: PType);
begin
  if d.k = locNone then getTemp(p, typ, d)
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
    initLoc(a, locExpr, getUniqueType(t), OnUnknown);
    a.r := r;
    if lfNoDeepCopy in d.flags then
      genAssignment(p, d, a, {@set}[])
    else
      genAssignment(p, d, a, {@set}[needToCopy])
  end
  else begin // we cannot call initLoc() here as that would overwrite
             // the flags field!
    d.k := locExpr;
    d.t := getUniqueType(t);
    d.r := r;
    d.a := -1
  end
end;

procedure binaryStmt(p: BProc; e: PNode; var d: TLoc;
                     const magic, frmt: string);
var
  a, b: TLoc;
begin
  if (d.k <> locNone) then InternalError(e.info, 'binaryStmt');
  if magic <> '' then useMagic(p.module, magic);
  InitLocExpr(p, e.sons[1], a);
  InitLocExpr(p, e.sons[2], b);
  appf(p.s[cpsStmts], frmt, [rdLoc(a), rdLoc(b)]);
end;

procedure unaryStmt(p: BProc; e: PNode; var d: TLoc;
                    const magic, frmt: string);
var
  a: TLoc;
begin
  if (d.k <> locNone) then InternalError(e.info, 'unaryStmt');
  if magic <> '' then useMagic(p.module, magic);
  InitLocExpr(p, e.sons[1], a);
  appf(p.s[cpsStmts], frmt, [rdLoc(a)]);
end;

procedure binaryStmtChar(p: BProc; e: PNode; var d: TLoc;
                         const magic, frmt: string);
var
  a, b: TLoc;
begin
  if (d.k <> locNone) then InternalError(e.info, 'binaryStmtChar');
  if magic <> '' then useMagic(p.module, magic);
  InitLocExpr(p, e.sons[1], a);
  InitLocExpr(p, e.sons[2], b);
  appf(p.s[cpsStmts], frmt, [rdCharLoc(a), rdCharLoc(b)]);
end;

procedure binaryExpr(p: BProc; e: PNode; var d: TLoc;
                     const magic, frmt: string);
var
  a, b: TLoc;
begin
  if magic <> '' then useMagic(p.module, magic);
  assert(e.sons[1].typ <> nil);
  assert(e.sons[2].typ <> nil);
  InitLocExpr(p, e.sons[1], a);
  InitLocExpr(p, e.sons[2], b);
  putIntoDest(p, d, e.typ, ropef(frmt, [rdLoc(a), rdLoc(b)]));
end;

procedure binaryExprChar(p: BProc; e: PNode; var d: TLoc;
                         const magic, frmt: string);
var
  a, b: TLoc;
begin
  if magic <> '' then useMagic(p.module, magic);
  assert(e.sons[1].typ <> nil);
  assert(e.sons[2].typ <> nil);
  InitLocExpr(p, e.sons[1], a);
  InitLocExpr(p, e.sons[2], b);
  putIntoDest(p, d, e.typ, ropef(frmt, [rdCharLoc(a), rdCharLoc(b)]));
end;

procedure unaryExpr(p: BProc; e: PNode; var d: TLoc;
                    const magic, frmt: string);
var
  a: TLoc;
begin
  if magic <> '' then useMagic(p.module, magic);
  InitLocExpr(p, e.sons[1], a);
  putIntoDest(p, d, e.typ, ropef(frmt, [rdLoc(a)]));
end;

procedure unaryExprChar(p: BProc; e: PNode; var d: TLoc;
                        const magic, frmt: string);
var
  a: TLoc;
begin
  if magic <> '' then useMagic(p.module, magic);
  InitLocExpr(p, e.sons[1], a);
  putIntoDest(p, d, e.typ, ropef(frmt, [rdCharLoc(a)]));
end;

procedure binaryArithOverflow(p: BProc; e: PNode; var d: TLoc; m: TMagic);
const
  prc: array [mAddi..mModi64] of string = (
    'addInt', 'subInt', 'mulInt', 'divInt', 'modInt',
    'addInt64', 'subInt64', 'mulInt64', 'divInt64', 'modInt64'
  );
  opr: array [mAddi..mModi64] of string = (
    '+'+'', '-'+'', '*'+'', '/'+'', '%'+'', 
    '+'+'', '-'+'', '*'+'', '/'+'', '%'+''
  );
var
  a, b: TLoc;
  t: PType;
begin
  assert(e.sons[1].typ <> nil);
  assert(e.sons[2].typ <> nil);
  InitLocExpr(p, e.sons[1], a);
  InitLocExpr(p, e.sons[2], b);
  t := skipGenericRange(e.typ);
  if getSize(t) >= platform.IntSize then begin
    if optOverflowCheck in p.options then begin
      useMagic(p.module, prc[m]);
      putIntoDest(p, d, e.typ, ropef('$1($2, $3)', 
                  [toRope(prc[m]), rdLoc(a), rdLoc(b)]));
    end
    else
      putIntoDest(p, d, e.typ, ropef('(NI$4)($2 $1 $3)', 
                  [toRope(opr[m]), rdLoc(a), rdLoc(b), toRope(getSize(t)*8)]));
  end
  else begin
    if optOverflowCheck in p.options then begin
      useMagic(p.module, 'raiseOverflow');
      if (m = mModI) or (m = mDivI) then begin
        useMagic(p.module, 'raiseDivByZero');
        appf(p.s[cpsStmts], 'if (!$1) raiseDivByZero();$n', [rdLoc(b)]);       
      end;
      a.r := ropef('((NI)($2) $1 (NI)($3))', 
                   [toRope(opr[m]), rdLoc(a), rdLoc(b)]);
      if d.k = locNone then getTemp(p, getSysType(tyInt), d);
      genAssignment(p, d, a, {@set}[]);
      appf(p.s[cpsStmts], 'if ($1 < $2 || $1 > $3) raiseOverflow();$n',
           [rdLoc(d), intLiteral(firstOrd(t)), intLiteral(lastOrd(t))]);
      d.t := e.typ;
      d.r := ropef('(NI$1)($2)', [toRope(getSize(t)*8), rdLoc(d)]);       
    end
    else 
      putIntoDest(p, d, e.typ, ropef('(NI$4)($2 $1 $3)', 
                  [toRope(opr[m]), rdLoc(a), rdLoc(b), toRope(getSize(t)*8)]));
  end
end;

procedure unaryArithOverflow(p: BProc; e: PNode; var d: TLoc; m: TMagic);
const
  opr: array [mUnaryMinusI..mAbsI64] of string = (
    '((NI$2)-($1))', // UnaryMinusI
    '-($1)', // UnaryMinusI64
    '(NI$2)abs($1)', // AbsI
    '($1 > 0? ($1) : -($1))' // AbsI64
  );
var
  a: TLoc;
  t: PType;
begin
  assert(e.sons[1].typ <> nil);
  InitLocExpr(p, e.sons[1], a);
  t := skipGenericRange(e.typ);
  if optOverflowCheck in p.options then begin
    useMagic(p.module, 'raiseOverflow');
    appf(p.s[cpsStmts], 'if ($1 == $2) raiseOverflow();$n', 
         [rdLoc(a), intLiteral(firstOrd(t))]);       
  end;
  putIntoDest(p, d, e.typ, ropef(opr[m], [rdLoc(a), toRope(getSize(t)*8)]));
end;

procedure binaryArith(p: BProc; e: PNode; var d: TLoc; op: TMagic);
const
  binArithTab: array [mShrI..mXor] of string = (
    '(NI$3)((NU$3)($1) >> (NU$3)($2))', // ShrI
    '(NI$3)((NU$3)($1) << (NU$3)($2))', // ShlI
    '(NI$3)($1 & $2)', // BitandI
    '(NI$3)($1 | $2)', // BitorI
    '(NI$3)($1 ^ $2)', // BitxorI
    '(($1 <= $2) ? $1 : $2)', // MinI
    '(($1 >= $2) ? $1 : $2)', // MaxI
    '(NI64)((NU64)($1) >> (NU64)($2))', // ShrI64
    '(NI64)((NU64)($1) << (NU64)($2))', // ShlI64
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

    '(NI$3)((NU$3)($1) + (NU$3)($2))', // AddU
    '(NI$3)((NU$3)($1) - (NU$3)($2))', // SubU
    '(NI$3)((NU$3)($1) * (NU$3)($2))', // MulU
    '(NI$3)((NU$3)($1) / (NU$3)($2))', // DivU
    '(NI$3)((NU$3)($1) % (NU$3)($2))', // ModU
    '(NI64)((NU64)($1) + (NU64)($2))', // AddU64
    '(NI64)((NU64)($1) - (NU64)($2))', // SubU64
    '(NI64)((NU64)($1) * (NU64)($2))', // MulU64
    '(NI64)((NU64)($1) / (NU64)($2))', // DivU64
    '(NI64)((NU64)($1) % (NU64)($2))', // ModU64

    '($1 == $2)', // EqI
    '($1 <= $2)', // LeI
    '($1 < $2)', // LtI
    '($1 == $2)', // EqI64
    '($1 <= $2)', // LeI64
    '($1 < $2)', // LtI64
    '($1 == $2)', // EqF64
    '($1 <= $2)', // LeF64
    '($1 < $2)', // LtF64

    '((NU$3)($1) <= (NU$3)($2))', // LeU
    '((NU$3)($1) < (NU$3)($2))',  // LtU
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
var
  a, b: TLoc;
  s: biggestInt;
begin
  assert(e.sons[1].typ <> nil);
  assert(e.sons[2].typ <> nil);
  InitLocExpr(p, e.sons[1], a);
  InitLocExpr(p, e.sons[2], b);
  // BUGFIX: cannot use result-type here, as it may be a boolean
  s := max(getSize(a.t), getSize(b.t))*8;
  putIntoDest(p, d, e.typ, ropef(binArithTab[op], 
              [rdLoc(a), rdLoc(b), toRope(s)]));
end;

procedure unaryArith(p: BProc; e: PNode; var d: TLoc; op: TMagic);
const
  unArithTab: array [mNot..mToBiggestInt] of string = (
    '!($1)',  // Not
    '$1',  // UnaryPlusI
    '(NI$2)((NU$2) ~($1))',  // BitnotI
    '$1',  // UnaryPlusI64
    '~($1)',  // BitnotI64
    '$1',  // UnaryPlusF64
    '-($1)',  // UnaryMinusF64
    '($1 > 0? ($1) : -($1))',  // AbsF64; BUGFIX: fabs() makes problems 
                               // for Tiny C, so we don't use it
    '((NI)(NU)(NU8)($1))', // mZe8ToI
    '((NI64)(NU64)(NU8)($1))', // mZe8ToI64
    '((NI)(NU)(NU16)($1))', // mZe16ToI
    '((NI64)(NU64)(NU16)($1))', // mZe16ToI64
    '((NI64)(NU64)(NU32)($1))', // mZe32ToI64
    '((NI64)(NU64)(NU)($1))', // mZeIToI64

    '((NI8)(NU8)(NU)($1))', // ToU8
    '((NI16)(NU16)(NU)($1))', // ToU16
    '((NI32)(NU32)(NU64)($1))', // ToU32

    '((double) ($1))', // ToFloat
    '((double) ($1))', // ToBiggestFloat
    'float64ToInt32($1)', // ToInt XXX: this is not correct!
    'float64ToInt64($1)'  // ToBiggestInt
  );
var
  a: TLoc;
  t: PType;
begin
  assert(e.sons[1].typ <> nil);
  InitLocExpr(p, e.sons[1], a);
  t := skipGenericRange(e.typ);
  putIntoDest(p, d, e.typ, ropef(unArithTab[op], 
              [rdLoc(a), toRope(getSize(t)*8)]));
end;

procedure genDeref(p: BProc; e: PNode; var d: TLoc);
var
  a: TLoc;
begin
  if mapType(e.sons[0].typ) = ctArray then
    expr(p, e.sons[0], d)
  else begin
    initLocExpr(p, e.sons[0], a);
    case skipGeneric(a.t).kind of
      tyRef: d.s := OnHeap;
      tyVar: d.s := OnUnknown;
      tyPtr: d.s := OnUnknown; // BUGFIX!
      else InternalError(e.info, 'genDeref ' + typekindToStr[a.t.kind]);
    end;
    putIntoDest(p, d, a.t.sons[0], ropef('(*$1)', [rdLoc(a)]));
  end
end;

procedure genAddr(p: BProc; e: PNode; var d: TLoc);
var
  a: TLoc;
begin
  if mapType(e.sons[0].typ) = ctArray then
    expr(p, e.sons[0], d)
  else begin
    InitLocExpr(p, e.sons[0], a);
    putIntoDest(p, d, e.typ, addrLoc(a));
  end
end;

function genRecordFieldAux(p: BProc; e: PNode; var d, a: TLoc): PType;
begin
  initLocExpr(p, e.sons[0], a);
  if (e.sons[1].kind <> nkSym) then InternalError(e.info, 'genRecordFieldAux');
  if d.k = locNone then d.s := a.s;
  {@discard} getTypeDesc(p.module, a.t); // fill the record's fields.loc
  result := getUniqueType(a.t);
end;

procedure genRecordField(p: BProc; e: PNode; var d: TLoc);
var
  a: TLoc;
  f, field: PSym;
  ty: PType;
  r: PRope;
begin
  ty := genRecordFieldAux(p, e, d, a);
  r := rdLoc(a);
  f := e.sons[1].sym;
  field := nil;
  while ty <> nil do begin
    assert(ty.kind in [tyTuple, tyObject]);
    field := lookupInRecord(ty.n, f.name);
    if field <> nil then break;
    if gCmd <> cmdCompileToCpp then app(r, '.Sup');
    ty := GetUniqueType(ty.sons[0]);
  end;
  if field = nil then InternalError(e.info, 'genRecordField');
  if field.loc.r = nil then InternalError(e.info, 'genRecordField');
  appf(r, '.$1', [field.loc.r]);
  putIntoDest(p, d, field.typ, r);
end;

procedure genTupleElem(p: BProc; e: PNode; var d: TLoc);
var
  a: TLoc;
  field: PSym;
  ty: PType;
  r: PRope;
  i: int;
begin
  initLocExpr(p, e.sons[0], a);
  if d.k = locNone then d.s := a.s;
  {@discard} getTypeDesc(p.module, a.t); // fill the record's fields.loc
  ty := getUniqueType(a.t);
  r := rdLoc(a);
  case e.sons[1].kind of
    nkIntLit..nkInt64Lit: i := int(e.sons[1].intVal);
    else internalError(e.info, 'genTupleElem');
  end;
  if ty.n <> nil then begin
    field := ty.n.sons[i].sym;
    if field = nil then InternalError(e.info, 'genTupleElem');
    if field.loc.r = nil then InternalError(e.info, 'genTupleElem');
    appf(r, '.$1', [field.loc.r]);
  end
  else
    appf(r, '.Field$1', [toRope(i)]);
  putIntoDest(p, d, ty.sons[i], r);
end;

procedure genInExprAux(p: BProc; e: PNode; var a, b, d: TLoc); forward;

procedure genCheckedRecordField(p: BProc; e: PNode; var d: TLoc);
var
  a, u, v, test: TLoc;
  f, field, op: PSym;
  ty: PType;
  r, strLit: PRope;
  i, id: int;
  it: PNode;
begin
  if optFieldCheck in p.options then begin
    useMagic(p.module, 'raiseFieldError');
    useMagic(p.module, 'NimStringDesc');
    ty := genRecordFieldAux(p, e.sons[0], d, a);
    r := rdLoc(a);
    f := e.sons[0].sons[1].sym;
    field := nil;
    while ty <> nil do begin
      assert(ty.kind in [tyTuple, tyObject]);
      field := lookupInRecord(ty.n, f.name);
      if field <> nil then break;
      if gCmd <> cmdCompileToCpp then app(r, '.Sup');
      ty := getUniqueType(ty.sons[0])
    end;
    if field = nil then InternalError(e.info, 'genCheckedRecordField');
    if field.loc.r = nil then InternalError(e.info, 'genCheckedRecordField');
    // generate the checks:
    for i := 1 to sonsLen(e)-1 do begin
      it := e.sons[i];
      assert(it.kind = nkCall);
      assert(it.sons[0].kind = nkSym);
      op := it.sons[0].sym;
      if op.magic = mNot then it := it.sons[1];
      assert(it.sons[2].kind = nkSym);
      initLoc(test, locNone, it.typ, OnStack);
      InitLocExpr(p, it.sons[1], u);
      initLoc(v, locExpr, it.sons[2].typ, OnUnknown);
      v.r := ropef('$1.$2', [r, it.sons[2].sym.loc.r]);
      genInExprAux(p, it, u, v, test);

      id := NodeTableTestOrSet(p.module.dataCache,
                               newStrNode(nkStrLit, field.name.s), gid);
      if id = gid then
        strLit := getStrLit(p.module, field.name.s)
      else
        strLit := con('TMP', toRope(id));
      if op.magic = mNot then
        appf(p.s[cpsStmts],
          'if ($1) raiseFieldError(((NimStringDesc*) &$2));$n',
          [rdLoc(test), strLit])
      else
        appf(p.s[cpsStmts],
          'if (!($1)) raiseFieldError(((NimStringDesc*) &$2));$n',
          [rdLoc(test), strLit])
    end;
    appf(r, '.$1', [field.loc.r]);
    putIntoDest(p, d, field.typ, r);
  end
  else
    genRecordField(p, e.sons[0], d)
end;

procedure genArrayElem(p: BProc; e: PNode; var d: TLoc);
var
  a, b: TLoc;
  ty: PType;
  first: PRope;
begin
  initLocExpr(p, e.sons[0], a);
  initLocExpr(p, e.sons[1], b);
  ty := skipPtrsGeneric(skipVarGenericRange(a.t));
  first := intLiteral(firstOrd(ty));
  // emit range check:
  if (optBoundsCheck in p.options) then begin
    if not isConstExpr(e.sons[1]) then begin
      // semantic pass has already checked for const index expressions
      useMagic(p.module, 'raiseIndexError');
      if firstOrd(ty) = 0 then begin
        if (firstOrd(b.t) < firstOrd(ty)) or (lastOrd(b.t) > lastOrd(ty)) then
          appf(p.s[cpsStmts],
             'if ((NU)($1) > (NU)($2)) raiseIndexError();$n',
               [rdCharLoc(b), intLiteral(lastOrd(ty))])
      end
      else
        appf(p.s[cpsStmts],
             'if ($1 < $2 || $1 > $3) raiseIndexError();$n',
             [rdCharLoc(b), first, intLiteral(lastOrd(ty))])
    end;
  end;
  if d.k = locNone then d.s := a.s;
  putIntoDest(p, d, elemType(skipVarGeneric(ty)), ropef('$1[($2)-$3]',
    [rdLoc(a), rdCharLoc(b), first]));
end;

procedure genCStringElem(p: BProc; e: PNode; var d: TLoc);
var
  a, b: TLoc;
  ty: PType;
begin
  initLocExpr(p, e.sons[0], a);
  initLocExpr(p, e.sons[1], b);
  ty := skipVarGenericRange(a.t);
  if d.k = locNone then d.s := a.s;
  putIntoDest(p, d, elemType(skipVarGeneric(ty)), ropef('$1[$2]',
    [rdLoc(a), rdCharLoc(b)]));
end;

procedure genOpenArrayElem(p: BProc; e: PNode; var d: TLoc);
var
  a, b: TLoc;
begin
  initLocExpr(p, e.sons[0], a);
  initLocExpr(p, e.sons[1], b);
  // emit range check:
  if (optBoundsCheck in p.options) then begin
    useMagic(p.module, 'raiseIndexError');
    appf(p.s[cpsStmts],
      'if ((NU)($1) >= (NU)($2Len0)) raiseIndexError();$n', [rdLoc(b), rdLoc(a)])
    // BUGFIX: ``>=`` and not ``>``!
  end;
  if d.k = locNone then d.s := a.s;
  putIntoDest(p, d, elemType(skipVarGeneric(a.t)), ropef('$1[$2]',
    [rdLoc(a), rdCharLoc(b)]));
end;

procedure genSeqElem(p: BPRoc; e: PNode; var d: TLoc);
var
  a, b: TLoc;
  ty: PType;
begin
  initLocExpr(p, e.sons[0], a);
  initLocExpr(p, e.sons[1], b);
  ty := skipVarGenericRange(a.t);
  if ty.kind in [tyRef, tyPtr] then ty := skipVarGenericRange(ty.sons[0]);
  // emit range check:
  if (optBoundsCheck in p.options) then begin
    useMagic(p.module, 'raiseIndexError');
    if ty.kind = tyString then
      appf(p.s[cpsStmts],
        'if ((NU)($1) > (NU)($2->Sup.len)) raiseIndexError();$n',
        [rdLoc(b), rdLoc(a)])
    else
      appf(p.s[cpsStmts],
        'if ((NU)($1) >= (NU)($2->Sup.len)) raiseIndexError();$n',
        [rdLoc(b), rdLoc(a)])
  end;
  if d.k = locNone then d.s := OnHeap;
  if skipVarGenericRange(a.t).kind in [tyRef, tyPtr] then
    a.r := ropef('(*$1)', [a.r]);
  putIntoDest(p, d, elemType(skipVarGeneric(a.t)), ropef('$1->data[$2]',
    [rdLoc(a), rdCharLoc(b)]));
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
  getTemp(p, e.typ, tmp); // force it into a temp!
  expr(p, e.sons[1], tmp);
  L := getLabel(p);
  if m = mOr then
    appf(p.s[cpsStmts], 'if ($1) goto $2;$n', [rdLoc(tmp), L])
  else // mAnd:
    appf(p.s[cpsStmts], 'if (!($1)) goto $2;$n', [rdLoc(tmp), L]);
  expr(p, e.sons[2], tmp);
  fixLabel(p, L);
  if d.k = locNone then
    d := tmp
  else
    genAssignment(p, d, tmp, {@set}[]); // no need for deep copying
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
  getTemp(p, n.typ, tmp); // force it into a temp!
  Lend := getLabel(p);
  for i := 0 to sonsLen(n)-1 do begin
    it := n.sons[i];
    case it.kind of
      nkElifExpr: begin
        initLocExpr(p, it.sons[0], a);
        Lelse := getLabel(p);
        appf(p.s[cpsStmts], 'if (!$1) goto $2;$n', [rdLoc(a), Lelse]);
        expr(p, it.sons[1], tmp);
        appf(p.s[cpsStmts], 'goto $1;$n', [Lend]);
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
  else
    genAssignment(p, d, tmp, {@set}[]); // no need for deep copying
end;

procedure genCall(p: BProc; t: PNode; var d: TLoc);
var
  param: PSym;
  invalidRetType: bool;
  typ: PType;
  pl: PRope; // parameter list
  op, list, a: TLoc;
  len, i: int;
begin
  // this is a hotspot in the compiler
  initLocExpr(p, t.sons[0], op);
  pl := con(op.r, '('+'');
  //typ := getUniqueType(t.sons[0].typ);
  typ := t.sons[0].typ; // getUniqueType() is too expensive here!
  assert(typ.kind = tyProc);
  invalidRetType := isInvalidReturnType(typ.sons[0]);
  len := sonsLen(t);
  for i := 1 to len-1 do begin
    initLocExpr(p, t.sons[i], a); // generate expression for param
    assert(sonsLen(typ) = sonsLen(typ.n));
    if (i < sonsLen(typ)) then begin
      assert(typ.n.sons[i].kind = nkSym);
      param := typ.n.sons[i].sym;
      if ccgIntroducedPtr(param) then app(pl, addrLoc(a))
      else                            app(pl, rdLoc(a));
    end
    else
      app(pl, rdLoc(a));
    if (i < len-1) or (invalidRetType and (typ.sons[0] <> nil)) then
      app(pl, ', ')
  end;
  if (typ.sons[0] <> nil) and invalidRetType then begin
    if d.k = locNone then getTemp(p, typ.sons[0], d);
    app(pl, addrLoc(d));
  end;
  app(pl, ')'+'');
  if (typ.sons[0] <> nil) and not invalidRetType then begin
    if d.k = locNone then getTemp(p, typ.sons[0], d);
    assert(d.t <> nil);
    // generate an assignment to d:
    initLoc(list, locCall, nil, OnUnknown);
    list.r := pl;
    genAssignment(p, d, list, {@set}[]) // no need for deep copying
  end
  else begin
    app(p.s[cpsStmts], pl);
    app(p.s[cpsStmts], ';' + tnl)
  end
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
  a, tmp: TLoc;
  appends, lens: PRope;
  L, i: int;
begin
  useMagic(p.module, 'rawNewString');
  getTemp(p, e.typ, tmp);
  L := 0;
  appends := nil;
  lens := nil;
  for i := 0 to sonsLen(e)-2 do begin
    // compute the length expression:
    initLocExpr(p, e.sons[i+1], a);
    if skipVarGenericRange(e.sons[i+1].Typ).kind = tyChar then begin
      Inc(L);
      useMagic(p.module, 'appendChar');
      appf(appends, 'appendChar($1, $2);$n', [tmp.r, rdLoc(a)])
    end
    else begin
      if e.sons[i+1].kind in [nkStrLit..nkTripleStrLit] then  // string literal?
        Inc(L, length(e.sons[i+1].strVal))
      else
        appf(lens, '$1->Sup.len + ', [rdLoc(a)]);
      useMagic(p.module, 'appendString');
      appf(appends, 'appendString($1, $2);$n', [tmp.r, rdLoc(a)])
    end
  end;
  appf(p.s[cpsStmts], '$1 = rawNewString($2$3);$n',
    [tmp.r, lens, toRope(L)]);
  app(p.s[cpsStmts], appends);
  if d.k = locNone then
    d := tmp
  else 
    genAssignment(p, d, tmp, {@set}[]); // no need for deep copying
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
  a, dest: TLoc;
  L, i: int;
  appends, lens: PRope;
begin
  assert(d.k = locNone);
  useMagic(p.module, 'resizeString');
  L := 0;
  appends := nil;
  lens := nil;
  initLocExpr(p, e.sons[1], dest);
  for i := 0 to sonsLen(e)-3 do begin
    // compute the length expression:
    initLocExpr(p, e.sons[i+2], a);
    if skipVarGenericRange(e.sons[i+2].Typ).kind = tyChar then begin
      Inc(L);
      useMagic(p.module, 'appendChar');
      appf(appends, 'appendChar($1, $2);$n',
        [rdLoc(dest), rdLoc(a)])
    end
    else begin
      if e.sons[i+2].kind in [nkStrLit..nkTripleStrLit] then  // string literal?
        Inc(L, length(e.sons[i+2].strVal))
      else
        appf(lens, '$1->Sup.len + ', [rdLoc(a)]);
      useMagic(p.module, 'appendString');
      appf(appends, 'appendString($1, $2);$n',
        [rdLoc(dest), rdLoc(a)])
    end
  end;
  appf(p.s[cpsStmts], '$1 = resizeString($1, $2$3);$n',
    [rdLoc(dest), lens, toRope(L)]);
  app(p.s[cpsStmts], appends);
end;

procedure genSeqElemAppend(p: BProc; e: PNode; var d: TLoc);
// seq &= x  -->
//    seq = (typeof seq) incrSeq(&seq->Sup, sizeof(x));
//    seq->data[seq->len-1] = x;
var
  a, b, dest: TLoc;
begin
  useMagic(p.module, 'incrSeq');
  InitLocExpr(p, e.sons[1], a);
  InitLocExpr(p, e.sons[2], b);
  appf(p.s[cpsStmts],
    '$1 = ($2) incrSeq(&($1)->Sup, sizeof($3));$n',
    [rdLoc(a), getTypeDesc(p.module, skipVarGeneric(e.sons[1].typ)),
    getTypeDesc(p.module, skipVarGeneric(e.sons[2].Typ))]);
  initLoc(dest, locExpr, b.t, OnHeap);
  dest.r := ropef('$1->data[$1->Sup.len-1]', [rdLoc(a)]);
  genAssignment(p, dest, b, {@set}[needToCopy, afDestIsNil]);
end;

procedure genObjectInit(p: BProc; t: PType; const a: TLoc; takeAddr: bool);
var
  r: PRope;
  s: PType;
begin
  case analyseObjectWithTypeField(t) of
    frNone: begin end;
    frHeader: begin
      r := rdLoc(a);
      if not takeAddr then r := ropef('(*$1)', [r]);
      s := t;
      while (s.kind = tyObject) and (s.sons[0] <> nil) do begin
        app(r, '.Sup');
        s := skipGeneric(s.sons[0]);
      end;    
      appf(p.s[cpsStmts], '$1.m_type = $2;$n', [r, genTypeInfo(p.module, t)])
    end;
    frEmbedded: begin 
      // worst case for performance:
      useMagic(p.module, 'objectInit');
      if takeAddr then r := addrLoc(a)
      else r := rdLoc(a);
      appf(p.s[cpsStmts], 'objectInit($1, $2);$n', [r, genTypeInfo(p.module, t)])
    end
  end
end;

procedure genNew(p: BProc; e: PNode);
var
  a, b: TLoc;
  reftype, bt: PType;
begin
  useMagic(p.module, 'newObj');
  refType := skipVarGenericRange(e.sons[1].typ);
  InitLocExpr(p, e.sons[1], a);
  initLoc(b, locExpr, a.t, OnHeap);
  b.r := ropef('($1) newObj($2, sizeof($3))',
    [getTypeDesc(p.module, reftype), genTypeInfo(p.module, refType),
    getTypeDesc(p.module, skipGenericRange(reftype.sons[0]))]);
  genAssignment(p, a, b, {@set}[]);
  // set the object type:
  bt := skipGenericRange(refType.sons[0]);
  genObjectInit(p, bt, a, false);
end;

procedure genNewSeq(p: BProc; e: PNode);
var
  a, b, c: TLoc;
  seqtype: PType;
begin
  useMagic(p.module, 'newSeq');
  seqType := skipVarGenericRange(e.sons[1].typ);
  InitLocExpr(p, e.sons[1], a);
  InitLocExpr(p, e.sons[2], b);
  initLoc(c, locExpr, a.t, OnHeap);
  c.r := ropef('($1) newSeq($2, $3)', 
    [getTypeDesc(p.module, seqtype),
    genTypeInfo(p.module, seqType),
    rdLoc(b)]);
  genAssignment(p, a, c, {@set}[]);
end;

procedure genIs(p: BProc; n: PNode; var d: TLoc);
var
  a: TLoc;
  dest, t: PType;
  r, nilcheck: PRope;
begin
  initLocExpr(p, n.sons[1], a);
  dest := skipPtrsGeneric(n.sons[2].typ);
  useMagic(p.module, 'isObj');
  r := rdLoc(a);
  nilCheck := nil;
  t := skipGeneric(a.t);
  while t.kind in [tyVar, tyPtr, tyRef] do begin
    if t.kind <> tyVar then nilCheck := r;
    r := ropef('(*$1)', [r]);
    t := skipGeneric(t.sons[0])
  end;
  if gCmd <> cmdCompileToCpp then
    while (t.kind = tyObject) and (t.sons[0] <> nil) do begin
      app(r, '.Sup');
      t := skipGeneric(t.sons[0]);
    end;
  if nilCheck <> nil then
    r := ropef('(($1) && isObj($2.m_type, $3))',
      [nilCheck, r, genTypeInfo(p.module, dest)])
  else
    r := ropef('isObj($1.m_type, $2)',
      [r, genTypeInfo(p.module, dest)]);
  putIntoDest(p, d, n.typ, r);
end;

procedure genNewFinalize(p: BProc; e: PNode);
var
  a, b, f: TLoc;
  refType, bt: PType;
  ti: PRope;
  oldModule: BModule;
begin
  useMagic(p.module, 'newObj');
  refType := skipVarGenericRange(e.sons[1].typ);
  InitLocExpr(p, e.sons[1], a);
  
  // This is a little hack: 
  // XXX this is also a bug, if the finalizer expression produces side-effects
  oldModule := p.module;
  p.module := gmti;
  InitLocExpr(p, e.sons[2], f);
  p.module := oldModule;
  
  initLoc(b, locExpr, a.t, OnHeap);
  ti := genTypeInfo(p.module, refType);
  
  appf(gmti.s[cfsTypeInit3], '$1->finalizer = (void*)$2;$n', [
    ti, rdLoc(f)]);
  b.r := ropef('($1) newObj($2, sizeof($3))',
                   [getTypeDesc(p.module, refType), ti,
                    getTypeDesc(p.module, skipGenericRange(reftype.sons[0]))]);
  genAssignment(p, a, b, {@set}[]);
  // set the object type:
  bt := skipGenericRange(refType.sons[0]);
  genObjectInit(p, bt, a, false);
end;

procedure genRepr(p: BProc; e: PNode; var d: TLoc);
var
  a: TLoc;
  t: PType;
begin
  InitLocExpr(p, e.sons[1], a);
  t := skipVarGenericRange(e.sons[1].typ);
  case t.kind of
    tyInt..tyInt64: begin
      UseMagic(p.module, 'reprInt');
      putIntoDest(p, d, e.typ, ropef('reprInt($1)', [rdLoc(a)]))
    end;
    tyFloat..tyFloat128: begin
      UseMagic(p.module, 'reprFloat');
      putIntoDest(p, d, e.typ, ropef('reprFloat($1)', [rdLoc(a)]))
    end;
    tyBool: begin
      UseMagic(p.module, 'reprBool');
      putIntoDest(p, d, e.typ, ropef('reprBool($1)', [rdLoc(a)]))
    end;
    tyChar: begin
      UseMagic(p.module, 'reprChar');
      putIntoDest(p, d, e.typ, ropef('reprChar($1)', [rdLoc(a)]))
    end;
    tyEnum, tyAnyEnum: begin
      UseMagic(p.module, 'reprEnum');
      putIntoDest(p, d, e.typ,
        ropef('reprEnum($1, $2)', [rdLoc(a), genTypeInfo(p.module, t)]))
    end;
    tyString: begin
      UseMagic(p.module, 'reprStr');
      putIntoDest(p, d, e.typ, ropef('reprStr($1)', [rdLoc(a)]))
    end;
    tySet: begin
      useMagic(p.module, 'reprSet');
      putIntoDest(p, d, e.typ, ropef('reprSet($1, $2)',
        [rdLoc(a), genTypeInfo(p.module, t)]))
    end;
    tyOpenArray: begin
      useMagic(p.module, 'reprOpenArray');
      case a.t.kind of
        tyOpenArray:
          putIntoDest(p, d, e.typ, ropef('$1, $1Len0', [rdLoc(a)]));
        tyString, tySequence:
          putIntoDest(p, d, e.typ, ropef('$1->data, $1->Sup.len', [rdLoc(a)]));
        tyArray, tyArrayConstr:
          putIntoDest(p, d, e.typ, ropef('$1, $2',
            [rdLoc(a), toRope(lengthOrd(a.t))]));
        else InternalError(e.sons[0].info, 'genRepr()')
      end;
      putIntoDest(p, d, e.typ, ropef('reprOpenArray($1, $2)',
        [rdLoc(d), genTypeInfo(p.module, elemType(t))]))
    end;
    tyCString, tyArray, tyArrayConstr,
       tyRef, tyPtr, tyPointer, tyNil, tySequence: begin
      useMagic(p.module, 'reprAny');
      putIntoDest(p, d, e.typ, ropef('reprAny($1, $2)',
        [rdLoc(a), genTypeInfo(p.module, t)]))
    end
    else begin
      useMagic(p.module, 'reprAny');
      putIntoDest(p, d, e.typ, ropef('reprAny($1, $2)',
        [addrLoc(a), genTypeInfo(p.module, t)]))
    end
  end;
end;

procedure genDollar(p: BProc; n: PNode; var d: TLoc; const magic, frmt: string);
var
  a: TLoc;
begin
  InitLocExpr(p, n.sons[1], a);
  UseMagic(p.module, magic);
  a.r := ropef(frmt, [rdLoc(a)]);
  if d.k = locNone then getTemp(p, n.typ, d);
  genAssignment(p, d, a, {@set}[]);
end;

procedure genArrayLen(p: BProc; e: PNode; var d: TLoc; op: TMagic);
var
  typ: PType;
begin
  typ := skipPtrsGeneric(e.sons[1].Typ);
  case typ.kind of
    tyOpenArray: begin
      while e.sons[1].kind = nkPassAsOpenArray do
        e.sons[1] := e.sons[1].sons[0];
      if op = mHigh then
        unaryExpr(p, e, d, '', '($1Len0-1)')
      else
        unaryExpr(p, e, d, '', '$1Len0');
    end;
    tyCstring:
      if op = mHigh then
        unaryExpr(p, e, d, '', '(strlen($1)-1)')
      else
        unaryExpr(p, e, d, '', 'strlen($1)');
    tyString, tySequence:
      if op = mHigh then
        unaryExpr(p, e, d, '', '($1->Sup.len-1)')
      else
        unaryExpr(p, e, d, '', '$1->Sup.len');
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
  useMagic(p.module, 'setLengthSeq');
  InitLocExpr(p, e.sons[1], a);
  InitLocExpr(p, e.sons[2], b);
  t := skipVarGeneric(e.sons[1].typ);
  appf(p.s[cpsStmts],
    '$1 = ($3) setLengthSeq(&($1)->Sup, sizeof($4), $2);$n',
    [rdLoc(a), rdLoc(b), getTypeDesc(p.module, t),
    getTypeDesc(p.module, t.sons[0])]);
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
  getTemp(p, skipVarGeneric(e.sons[1].typ), tmp);
  InitLocExpr(p, e.sons[1], a); // eval a
  InitLocExpr(p, e.sons[2], b); // eval b
  genAssignment(p, tmp, a, {@set}[]);
  genAssignment(p, a, b, {@set}[]);
  genAssignment(p, b, tmp, {@set}[]);
end;

// -------------------- set operations ------------------------------------

function rdSetElemLoc(const a: TLoc; setType: PType): PRope;
// read a location of an set element; it may need a substraction operation
// before the set operation
begin
  result := rdCharLoc(a);
  assert(setType.kind = tySet);
  if (firstOrd(setType) <> 0) then
    result := ropef('($1-$2)', [result, toRope(firstOrd(setType))])
end;

function fewCmps(s: PNode): bool;
// this function estimates whether it is better to emit code
// for constructing the set or generating a bunch of comparisons directly
begin
  if s.kind <> nkCurly then InternalError(s.info, 'fewCmps');
  if (getSize(s.typ) <= platform.intSize) and (nfAllConst in s.flags) then
    result := false      // it is better to emit the set generation code
  else if elemType(s.typ).Kind in [tyInt, tyInt16..tyInt64] then
    result := true       // better not emit the set if int is basetype!
  else
    result := sonsLen(s) <= 8 // 8 seems to be a good value
end;

procedure binaryExprIn(p: BProc; e: PNode; var a, b, d: TLoc;
                       const frmt: string);
begin
  putIntoDest(p, d, e.typ, ropef(frmt, [rdLoc(a), rdSetElemLoc(b, a.t)]));
end;

procedure genInExprAux(p: BProc; e: PNode; var a, b, d: TLoc);
begin
  case int(getSize(skipVarGeneric(e.sons[1].typ))) of
    1: binaryExprIn(p, e, a, b, d, '(($1 &(1<<(($2)&7)))!=0)');
    2: binaryExprIn(p, e, a, b, d, '(($1 &(1<<(($2)&15)))!=0)');
    4: binaryExprIn(p, e, a, b, d, '(($1 &(1<<(($2)&31)))!=0)');
    8: binaryExprIn(p, e, a, b, d, '(($1 &(IL64(1)<<(($2)&IL64(63))))!=0)');
    else binaryExprIn(p, e, a, b, d, '(($1[$2/8] &(1<<($2%8)))!=0)');
  end
end;

procedure binaryStmtInExcl(p: BProc; e: PNode; var d: TLoc; const frmt: string);
var
  a, b: TLoc;
begin
  assert(d.k = locNone);
  InitLocExpr(p, e.sons[1], a);
  InitLocExpr(p, e.sons[2], b);
  appf(p.s[cpsStmts], frmt, [rdLoc(a), rdSetElemLoc(b, a.t)]);
end;

procedure genInOp(p: BProc; e: PNode; var d: TLoc);
var
  a, b, x, y: TLoc;
  len, i: int;
begin
  if (e.sons[1].Kind = nkCurly) and fewCmps(e.sons[1]) then begin
    // a set constructor but not a constant set:
    // do not emit the set, but generate a bunch of comparisons
    initLocExpr(p, e.sons[2], a);
    initLoc(b, locExpr, e.typ, OnUnknown);
    b.r := toRope('('+'');
    len := sonsLen(e.sons[1]);
    for i := 0 to len-1 do begin
      if e.sons[1].sons[i].Kind = nkRange then begin
        InitLocExpr(p, e.sons[1].sons[i].sons[0], x);
        InitLocExpr(p, e.sons[1].sons[i].sons[1], y);
        appf(b.r, '$1 >= $2 && $1 <= $3',
          [rdCharLoc(a), rdCharLoc(x), rdCharLoc(y)])
      end
      else begin
        InitLocExpr(p, e.sons[1].sons[i], x);
        appf(b.r, '$1 == $2', [rdCharLoc(a), rdCharLoc(x)])
      end;
      if i < len - 1 then app(b.r, ' || ')
    end;
    app(b.r, ')'+'');
    putIntoDest(p, d, e.typ, b.r);
  end
  else begin
    assert(e.sons[1].typ <> nil);
    assert(e.sons[2].typ <> nil);
    InitLocExpr(p, e.sons[1], a);
    InitLocExpr(p, e.sons[2], b);
    genInExprAux(p, e, a, b, d);
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
  setType := skipVarGeneric(e.sons[1].Typ);
  size := int(getSize(setType));
  case size of
    1, 2, 4, 8: begin
      case op of
        mIncl: begin
          ts := 'NI' + toString(size*8);
          binaryStmtInExcl(p, e, d,
            '$1 |=(1<<((' +{&} ts +{&} ')($2)%(sizeof(' +{&} ts +{&}
            ')*8)));$n');
        end;
        mExcl: begin
          ts := 'NI' + toString(size*8);
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
          getTemp(p, getSysType(tyInt), i); // our counter
          initLocExpr(p, e.sons[1], a);
          initLocExpr(p, e.sons[2], b);
          if d.k = locNone then getTemp(p, a.t, d);
          appf(p.s[cpsStmts], lookupOpr[op], [rdLoc(i), toRope(size),
            rdLoc(d), rdLoc(a), rdLoc(b)]);
        end;
        mEqSet:
          binaryExprChar(p, e, d, '',
                         '(memcmp($1, $2, ' + ToString(size) + ')==0)');
        mMulSet, mPlusSet, mMinusSet, mSymDiffSet: begin
          // we inline the simple for loop for better code generation:
          getTemp(p, getSysType(tyInt), i); // our counter
          initLocExpr(p, e.sons[1], a);
          initLocExpr(p, e.sons[2], b);
          if d.k = locNone then getTemp(p, a.t, d);
          appf(p.s[cpsStmts],
            'for ($1 = 0; $1 < $2; $1++) $n' +
            '  $3[$1] = $4[$1] $6 $5[$1];$n', [rdLoc(i), toRope(size),
            rdLoc(d), rdLoc(a), rdLoc(b), toRope(lookupOpr[op])]);
        end;
        mInSet: genInOp(p, e, d);
        else internalError(e.info, 'genSetOp')
      end
    end
  end
end;

// --------------------- end of set operations ----------------------------

procedure genOrd(p: BProc; e: PNode; var d: TLoc);
begin
  unaryExprChar(p, e, d, '', '$1');
end;

procedure genCast(p: BProc; e: PNode; var d: TLoc);
const
  ValueTypes = {@set}[tyTuple, tyObject, tyArray, tyOpenArray, tyArrayConstr];
// we use whatever C gives us. Except if we have a value-type, we
// need to go through its address:
var
  a: TLoc;
begin
  InitLocExpr(p, e.sons[1], a);
  if (skipGenericRange(e.typ).kind in ValueTypes)
  and not (lfIndirect in a.flags) then
    putIntoDest(p, d, e.typ, ropef('(*($1*) ($2))',
      [getTypeDesc(p.module, e.typ), addrLoc(a)]))
  else
    putIntoDest(p, d, e.typ, ropef('(($1) ($2))',
      [getTypeDesc(p.module, e.typ), rdCharLoc(a)]));
end;

procedure genRangeChck(p: BProc; n: PNode; var d: TLoc; const magic: string);
var
  a: TLoc;
  dest: PType;
begin
  dest := skipVarGeneric(n.typ);
  if not (optRangeCheck in p.options) then begin
    InitLocExpr(p, n.sons[0], a);
    putIntoDest(p, d, n.typ, ropef('(($1) ($2))',
      [getTypeDesc(p.module, dest), rdCharLoc(a)]));
  end
  else begin
    InitLocExpr(p, n.sons[0], a);
    useMagic(p.module, magic);
    putIntoDest(p, d, dest,
      ropef('(($1)$5($2, $3, $4))',
        [getTypeDesc(p.module, dest),
         rdCharLoc(a), genLiteral(p, n.sons[1], dest),
                       genLiteral(p, n.sons[2], dest),
                       toRope(magic)]));
  end
end;

procedure genConv(p: BProc; e: PNode; var d: TLoc);
begin
  genCast(p, e, d)
end;

procedure passToOpenArray(p: BProc; n: PNode; var d: TLoc);
var
  a: TLoc;
  dest: PType;
begin
  while n.sons[0].kind = nkPassAsOpenArray do
    n.sons[0] := n.sons[0].sons[0]; // BUGFIX
  dest := skipVarGeneric(n.typ);
  case skipVarGeneric(n.sons[0].typ).kind of
    tyOpenArray: begin
      initLocExpr(p, n.sons[0], a);
      putIntoDest(p, d, dest, ropef('$1, $1Len0', [rdLoc(a)]));
    end;
    tyString, tySequence: begin
      initLocExpr(p, n.sons[0], a);
      putIntoDest(p, d, dest, ropef('$1->data, $1->Sup.len', [rdLoc(a)]));
    end;
    tyArray, tyArrayConstr: begin
      initLocExpr(p, n.sons[0], a);
      putIntoDest(p, d, dest, ropef('$1, $2',
        [rdLoc(a), toRope(lengthOrd(a.t))]));
    end
    else InternalError(n.sons[0].info, 'passToOpenArray: ' + typeToString(a.t))
  end
end;

procedure convStrToCStr(p: BProc; n: PNode; var d: TLoc);
var
  a: TLoc;
begin
  initLocExpr(p, n.sons[0], a);
  putIntoDest(p, d, skipVarGeneric(n.typ), ropef('$1->data', [rdLoc(a)]));
end;

procedure convCStrToStr(p: BProc; n: PNode; var d: TLoc);
var
  a: TLoc;
begin
  useMagic(p.module, 'cstrToNimstr');
  initLocExpr(p, n.sons[0], a);
  putIntoDest(p, d, skipVarGeneric(n.typ),
              ropef('cstrToNimstr($1)', [rdLoc(a)]));
end;

procedure genStrEquals(p: BProc; e: PNode; var d: TLoc);
var
  a, b: PNode;
  x: TLoc;
begin
  a := e.sons[1];
  b := e.sons[2];
  if (a.kind = nkNilLit) or (b.kind = nkNilLit) then
    binaryExpr(p, e, d, '', '($1 == $2)')
  else if (a.kind in [nkStrLit..nkTripleStrLit]) and (a.strVal = '') then begin
    initLocExpr(p, e.sons[2], x);
    putIntoDest(p, d, e.typ, ropef('(($1) && ($1)->Sup.len == 0)', [rdLoc(x)]));
  end
  else if (b.kind in [nkStrLit..nkTripleStrLit]) and (b.strVal = '') then begin
    initLocExpr(p, e.sons[1], x);
    putIntoDest(p, d, e.typ, ropef('(($1) && ($1)->Sup.len == 0)', [rdLoc(x)]));
  end
  else
    binaryExpr(p, e, d, 'eqStrings', 'eqStrings($1, $2)');
end;

procedure genSeqConstr(p: BProc; t: PNode; var d: TLoc);
var
  newSeq, arr: TLoc;
  i: int;
begin
  useMagic(p.module, 'newSeq');
  if d.k = locNone then getTemp(p, t.typ, d);
  // generate call to newSeq before adding the elements per hand:

  initLoc(newSeq, locExpr, t.typ, OnHeap);
  newSeq.r := ropef('($1) newSeq($2, $3)',
    [getTypeDesc(p.module, t.typ),
    genTypeInfo(p.module, t.typ), intLiteral(sonsLen(t))]);
  genAssignment(p, d, newSeq, {@set}[afSrcIsNotNil]);
  for i := 0 to sonsLen(t)-1 do begin
    initLoc(arr, locExpr, elemType(skipGeneric(t.typ)), OnHeap);
    arr.r := ropef('$1->data[$2]', [rdLoc(d), intLiteral(i)]);
    arr.s := OnHeap; // we know that sequences are on the heap
    expr(p, t.sons[i], arr)
  end
end;

procedure genArrToSeq(p: BProc; t: PNode; var d: TLoc);
var
  newSeq, elem, a, arr: TLoc;
  L, i: int;
begin
  if t.kind = nkBracket then begin
    t.sons[1].typ := t.typ;
    genSeqConstr(p, t.sons[1], d);
    exit
  end;
  useMagic(p.module, 'newSeq');
  if d.k = locNone then getTemp(p, t.typ, d);
  // generate call to newSeq before adding the elements per hand:
  L := int(lengthOrd(t.sons[1].typ));
  initLoc(newSeq, locExpr, t.typ, OnHeap);
  newSeq.r := ropef('($1) newSeq($2, $3)',
    [getTypeDesc(p.module, t.typ),
    genTypeInfo(p.module, t.typ), intLiteral(L)]);
  genAssignment(p, d, newSeq, {@set}[afSrcIsNotNil]);
  initLocExpr(p, t.sons[1], a);
  for i := 0 to L-1 do begin
    initLoc(elem, locExpr, elemType(skipGeneric(t.typ)), OnHeap);
    elem.r := ropef('$1->data[$2]', [rdLoc(d), intLiteral(i)]);
    elem.s := OnHeap; // we know that sequences are on the heap
    initLoc(arr, locExpr, elemType(skipGeneric(t.sons[1].typ)), a.s);
    arr.r := ropef('$1[$2]', [rdLoc(a), intLiteral(i)]);
    genAssignment(p, elem, arr, {@set}[afDestIsNil, needToCopy]);
  end
end;

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
      InitLocExpr(p, e.sons[1], a);
      assert(a.t <> nil);
      expr(p, e.sons[2], a);
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
        binaryExpr(p, e, d, '', '$1 + $2')
      else
        binaryExpr(p, e, d, 'addInt', 'addInt($1, $2)')
    end;
    mConStrStr: genStrConcat(p, e, d);
    mAppendStrCh: binaryStmt(p, e, d, 'addChar', '$1 = addChar($1, $2);$n');
    mAppendStrStr: genStrAppend(p, e, d);
    mAppendSeqElem: genSeqElemAppend(p, e, d);
    mEqStr: genStrEquals(p, e, d);
    mLeStr: binaryExpr(p, e, d, 'cmpStrings', '(cmpStrings($1, $2) <= 0)');
    mLtStr: binaryExpr(p, e, d, 'cmpStrings', '(cmpStrings($1, $2) < 0)');
    mIsNil: unaryExpr(p, e, d, '', '$1 == 0');
    mIntToStr: genDollar(p, e, d, 'nimIntToStr', 'nimIntToStr($1)');
    mInt64ToStr: genDollar(p, e, d, 'nimInt64ToStr', 'nimInt64ToStr($1)');
    mBoolToStr: genDollar(p, e, d, 'nimBoolToStr', 'nimBoolToStr($1)');
    mCharToStr: genDollar(p, e, d, 'nimCharToStr', 'nimCharToStr($1)');
    mFloatToStr: genDollar(p, e, d, 'nimFloatToStr', 'nimFloatToStr($1)');
    mCStrToStr: genDollar(p, e, d, 'cstrToNimstr', 'cstrToNimstr($1)');
    mStrToStr: expr(p, e.sons[1], d);
    mEnumToStr: genRepr(p, e, d);
    mAssert: begin
      if (optAssert in p.Options) then begin
        useMagic(p.module, 'internalAssert');
        expr(p, e.sons[1], d);
        line := toRope(toLinenumber(e.info));
        filen := makeCString(ToFilename(e.info));
        appf(p.s[cpsStmts], 'internalAssert($1, $2, $3);$n',
                      [filen, line, rdLoc(d)])
      end
    end;
    mIs: genIs(p, e, d);
    mNew: genNew(p, e);
    mNewFinalize: genNewFinalize(p, e);
    mNewSeq: genNewSeq(p, e);
    mSizeOf:
      putIntoDest(p, d, e.typ,
        ropef('((NI)sizeof($1))', [getTypeDesc(p.module, e.sons[1].typ)]));
    mChr: genCast(p, e, d); // expr(p, e.sons[1], d);
    mOrd: genOrd(p, e, d);
    mLengthArray, mHigh, mLengthStr, mLengthSeq, mLengthOpenArray:
      genArrayLen(p, e, d, op);
    mInc: begin
      if not (optOverflowCheck in p.Options) then
        binaryStmt(p, e, d, '', '$1 += $2;$n')
      else if skipVarGeneric(e.sons[1].typ).kind = tyInt64 then
        binaryStmt(p, e, d, 'addInt64', '$1 = addInt64($1, $2);$n')
      else
        binaryStmt(p, e, d, 'addInt', '$1 = addInt($1, $2);$n')
    end;
    ast.mDec: begin
      if not (optOverflowCheck in p.Options) then
        binaryStmt(p, e, d, '', '$1 -= $2;$n')
      else if skipVarGeneric(e.sons[1].typ).kind = tyInt64 then
        binaryStmt(p, e, d, 'subInt64', '$1 = subInt64($1, $2);$n')
      else
        binaryStmt(p, e, d, 'subInt', '$1 = subInt($1, $2);$n')
    end;
    mGCref: unaryStmt(p, e, d, 'nimGCref', 'nimGCref($1);$n');
    mGCunref: unaryStmt(p, e, d, 'nimGCunref', 'nimGCunref($1);$n');
    mSetLengthStr: genSetLengthStr(p, e, d);
    mSetLengthSeq: genSetLengthSeq(p, e, d);
    mIncl, mExcl, mCard, mLtSet, mLeSet, mEqSet, mMulSet, mPlusSet,
    mMinusSet, mInSet: genSetOp(p, e, d, op);
    mNewString, mCopyStr, mCopyStrLast: genCall(p, e, d);
    mExit: genCall(p, e, d);
    mArrToSeq: genArrToSeq(p, e, d);
    mNLen..mNError:
      liMessage(e.info, errCannotGenerateCodeForX, e.sons[0].sym.name.s);
    else internalError(e.info, 'genMagicExpr: ' + magicToStr[op]);
  end
end;

function genConstExpr(p: BProc; n: PNode): PRope; forward;

function handleConstExpr(p: BProc; n: PNode; var d: TLoc): bool;
var
  id: int;
  t: PType;
begin
  if (nfAllConst in n.flags) and (d.k = locNone)
      and (sonsLen(n) > 0) then begin
    t := getUniqueType(n.typ);
    {@discard} getTypeDesc(p.module, t); // so that any fields are initialized
    id := NodeTableTestOrSet(p.module.dataCache, n, gid);
    fillLoc(d, locData, t, con('TMP', toRope(id)), OnHeap);
    if id = gid then begin
      // expression not found in the cache:
      inc(gid);
      appf(p.module.s[cfsData], 'NIM_CONST $1 $2 = $3;$n',
          [getTypeDesc(p.module, t), d.r, genConstExpr(p, n)]);
    end;
    result := true
  end
  else
    result := false
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
  if nfAllConst in e.flags then
    putIntoDest(p, d, e.typ, genSetNode(p, e))
  else begin
    if d.k = locNone then getTemp(p, e.typ, d);
    if getSize(e.typ) > 8 then begin // big set:
      appf(p.s[cpsStmts], 'memset($1, 0, sizeof($1));$n', [rdLoc(d)]);
      for i := 0 to sonsLen(e)-1 do begin
        if e.sons[i].kind = nkRange then begin
          getTemp(p, getSysType(tyInt), idx); // our counter
          initLocExpr(p, e.sons[i].sons[0], a);
          initLocExpr(p, e.sons[i].sons[1], b);
          appf(p.s[cpsStmts],
            'for ($1 = $3; $1 <= $4; $1++) $n' +
            '$2[$1/8] |=(1<<($1%8));$n',
            [rdLoc(idx), rdLoc(d), rdSetElemLoc(a, e.typ),
             rdSetElemLoc(b, e.typ)]);
        end
        else begin
          initLocExpr(p, e.sons[i], a);
          appf(p.s[cpsStmts], '$1[$2/8] |=(1<<($2%8));$n',
                       [rdLoc(d), rdSetElemLoc(a, e.typ)]);
        end
      end
    end
    else begin // small set
      ts := 'NI' + toString(getSize(e.typ)*8);
      appf(p.s[cpsStmts], '$1 = 0;$n', [rdLoc(d)]);
      for i := 0 to sonsLen(e) - 1 do begin
        if e.sons[i].kind = nkRange then begin
          getTemp(p, getSysType(tyInt), idx); // our counter
          initLocExpr(p, e.sons[i].sons[0], a);
          initLocExpr(p, e.sons[i].sons[1], b);
          appf(p.s[cpsStmts],
            'for ($1 = $3; $1 <= $4; $1++) $n' +{&}
            '$2 |=(1<<((' +{&} ts +{&} ')($1)%(sizeof(' +{&}ts+{&}')*8)));$n',
            [rdLoc(idx), rdLoc(d), rdSetElemLoc(a, e.typ),
             rdSetElemLoc(b, e.typ)]);
        end
        else begin
          initLocExpr(p, e.sons[i], a);
          appf(p.s[cpsStmts],
                        '$1 |=(1<<((' +{&} ts +{&} ')($2)%(sizeof(' +{&}ts+{&}
                        ')*8)));$n',
                        [rdLoc(d), rdSetElemLoc(a, e.typ)]);
        end
      end
    end
  end
end;

procedure genTupleConstr(p: BProc; n: PNode; var d: TLoc);
var
  i: int;
  rec: TLoc;
  it: PNode;
  t: PType;
begin
  if not handleConstExpr(p, n, d) then begin
    t := getUniqueType(n.typ);
    {@discard} getTypeDesc(p.module, t); // so that any fields are initialized
    if d.k = locNone then getTemp(p, t, d);
    for i := 0 to sonsLen(n)-1 do begin
      it := n.sons[i];
      if it.kind = nkExprColonExpr then begin
        initLoc(rec, locExpr, it.sons[1].typ, d.s);
        if (t.n.sons[i].kind <> nkSym) then
          InternalError(n.info, 'genTupleConstr');
        rec.r := ropef('$1.$2', [rdLoc(d), mangleRecFieldName(t.n.sons[i].sym, t)]);
        expr(p, it.sons[1], rec);
      end
      else if t.n = nil then begin
        initLoc(rec, locExpr, it.typ, d.s);
        rec.r := ropef('$1.Field$2', [rdLoc(d), toRope(i)]);
        expr(p, it, rec);
      end
      else begin
        initLoc(rec, locExpr, it.typ, d.s);
        if (t.n.sons[i].kind <> nkSym) then
          InternalError(n.info, 'genTupleConstr: 2');
        rec.r := ropef('$1.$2', [rdLoc(d), mangleRecFieldName(t.n.sons[i].sym, t)]);
        expr(p, it, rec);
      end
    end
  end
end;

procedure genArrayConstr(p: BProc; n: PNode; var d: TLoc);
var
  arr: TLoc;
  i: int;
begin
  if not handleConstExpr(p, n, d) then begin
    if d.k = locNone then getTemp(p, n.typ, d);
    for i := 0 to sonsLen(n)-1 do begin
      initLoc(arr, locExpr, elemType(skipGeneric(n.typ)), d.s);
      arr.r := ropef('$1[$2]', [rdLoc(d), intLiteral(i)]);
      expr(p, n.sons[i], arr)
    end
  end
end;

procedure genComplexConst(p: BProc; sym: PSym; var d: TLoc);
begin
  genConstPrototype(p.module, sym);
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

procedure upConv(p: BProc; n: PNode; var d: TLoc);
var
  a: TLoc;
  dest, t: PType;
  r, nilCheck: PRope;
begin
  initLocExpr(p, n.sons[0], a);
  dest := skipPtrsGeneric(n.typ);
  if (optObjCheck in p.options) and not (isPureObject(dest)) then begin
    useMagic(p.module, 'chckObj');
    r := rdLoc(a);
    nilCheck := nil;
    t := skipGeneric(a.t);
    while t.kind in [tyVar, tyPtr, tyRef] do begin
      if t.kind <> tyVar then nilCheck := r;
      r := ropef('(*$1)', [r]);
      t := skipGeneric(t.sons[0])
    end;
    if gCmd <> cmdCompileToCpp then
      while (t.kind = tyObject) and (t.sons[0] <> nil) do begin
        app(r, '.Sup');
        t := skipGeneric(t.sons[0]);
      end;
    if nilCheck <> nil then
      appf(p.s[cpsStmts], 'if ($1) chckObj($2.m_type, $3);$n',
        [nilCheck, r, genTypeInfo(p.module, dest)])
    else
      appf(p.s[cpsStmts], 'chckObj($1.m_type, $2);$n',
        [r, genTypeInfo(p.module, dest)]);
  end;
  if n.sons[0].typ.kind <> tyObject then
    putIntoDest(p, d, n.typ, ropef('(($1) ($2))',
      [getTypeDesc(p.module, n.typ), rdLoc(a)]))
  else
    putIntoDest(p, d, n.typ, ropef('(*($1*) ($2))',
      [getTypeDesc(p.module, dest), addrLoc(a)]));
end;

procedure downConv(p: BProc; n: PNode; var d: TLoc);
var
  a: TLoc;
  dest, src: PType;
  i: int;
  r: PRope;
begin
  if gCmd = cmdCompileToCpp then
    expr(p, n.sons[0], d) // downcast does C++ for us
  else begin
    dest := skipPtrsGeneric(n.typ);
    src := skipPtrsGeneric(n.sons[0].typ);
    initLocExpr(p, n.sons[0], a);
    r := rdLoc(a);
    if skipGeneric(n.sons[0].typ).kind in [tyRef, tyPtr, tyVar] then begin
      app(r, '->Sup');
      for i := 2 to abs(inheritanceDiff(dest, src)) do app(r, '.Sup');
      r := con('&'+'', r);
    end
    else
      for i := 1 to abs(inheritanceDiff(dest, src)) do app(r, '.Sup');
    putIntoDest(p, d, n.typ, r);
  end
end;

procedure genBlock(p: BProc; t: PNode; var d: TLoc); forward;

procedure expr(p: BProc; e: PNode; var d: TLoc);
var
  sym: PSym;
  ty: PType;
begin
  case e.kind of
    nkSym: begin
      sym := e.sym;
      case sym.Kind of
        skProc, skConverter: begin
          genProc(p.module, sym);
          if ((sym.loc.r = nil) or (sym.loc.t = nil)) then
            InternalError(e.info, 'expr: proc not init ' + sym.name.s);
          putLocIntoDest(p, d, sym.loc);
        end;
        skConst:
          if isSimpleConst(sym.typ) then
            putIntoDest(p, d, e.typ, genLiteral(p, sym.ast, sym.typ))
          else
            genComplexConst(p, sym, d);
        skEnumField: putIntoDest(p, d, e.typ, toRope(sym.position));
        skVar: begin
          if (sfGlobal in sym.flags) then genVarPrototype(p.module, sym);
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
    end;
    nkQualified: expr(p, e.sons[1], d);
    nkStrLit..nkTripleStrLit, nkIntLit..nkInt64Lit,
    nkFloatLit..nkFloat64Lit, nkNilLit, nkCharLit: begin
      putIntoDest(p, d, e.typ, genLiteral(p, e));
    end;
    nkCall, nkHiddenCallConv, nkInfix, nkPrefix, nkPostfix, nkCommand: begin
      if (e.sons[0].kind = nkSym) and
         (e.sons[0].sym.magic <> mNone) then
        genMagicExpr(p, e, d, e.sons[0].sym.magic)
      else
        genCall(p, e, d)
    end;
    nkCurly: genSetConstr(p, e, d);
    nkBracket:
      if (skipVarGenericRange(e.typ).kind = tySequence) then  // BUGFIX
        genSeqConstr(p, e, d)
      else
        genArrayConstr(p, e, d);
    nkPar:
      genTupleConstr(p, e, d);
    nkCast: genCast(p, e, d);
    nkHiddenStdConv, nkHiddenSubConv, nkConv: genConv(p, e, d);
    nkHiddenAddr, nkAddr: genAddr(p, e, d);
    nkBracketExpr: begin
      ty := skipVarGenericRange(e.sons[0].typ);
      if ty.kind in [tyRef, tyPtr] then ty := skipVarGenericRange(ty.sons[0]);
      case ty.kind of
        tyArray, tyArrayConstr: genArrayElem(p, e, d);
        tyOpenArray: genOpenArrayElem(p, e, d);
        tySequence, tyString: genSeqElem(p, e, d);
        tyCString: genCStringElem(p, e, d);
        tyTuple: genTupleElem(p, e, d);
        else InternalError(e.info,
               'expr(nkBracketExpr, ' + typeKindToStr[ty.kind] + ')');
      end
    end;
    nkDerefExpr, nkHiddenDeref: genDeref(p, e, d);
    nkDotExpr: genRecordField(p, e, d);
    nkCheckedFieldExpr: genCheckedRecordField(p, e, d);
    nkBlockExpr: genBlock(p, e, d);
    nkStmtListExpr: genStmtListExpr(p, e, d);
    nkIfExpr: genIfExpr(p, e, d);
    nkObjDownConv: downConv(p, e, d);
    nkObjUpConv: upConv(p, e, d);
    nkChckRangeF: genRangeChck(p, e, d, 'chckRangeF');
    nkChckRange64: genRangeChck(p, e, d, 'chckRange64');
    nkChckRange: genRangeChck(p, e, d, 'chckRange');
    nkStringToCString: convStrToCStr(p, e, d);
    nkCStringToString: convCStrToStr(p, e, d);
    nkPassAsOpenArray: passToOpenArray(p, e, d);
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
  t := getUniqueType(skipVarGenericRange(n.Typ));
  if t.n = nil then
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

function genConstSimpleList(p: BProc; n: PNode): PRope;
var
  len, i: int;
begin
  len := sonsLen(n);
  result := toRope('{'+'');
  for i := 0 to len - 2 do
    appf(result, '$1,$n', [genConstExpr(p, n.sons[i])]);
  if len > 0 then app(result, genConstExpr(p, n.sons[len-1]));
  app(result, '}' + tnl)
end;

function genConstExpr(p: BProc; n: PNode): PRope;
var
  trans: PNode;
  cs: TBitSet;
  d: TLoc;
begin
  case n.Kind of
    nkHiddenStdConv, nkHiddenSubConv: result := genConstExpr(p, n.sons[1]);
    nkCurly: begin
      toBitSet(n, cs);
      result := genRawSetData(cs, int(getSize(n.typ)))
    end;
    nkBracket: begin
      // XXX: tySequence!
      result := genConstSimpleList(p, n);
    end;
    nkPar: begin
      if hasSonWith(n, nkExprColonExpr) then
        trans := transformRecordExpr(n)
      else
        trans := n;
      result := genConstSimpleList(p, trans);
    end
    else begin
      //  result := genLiteral(p, n)
      initLocExpr(p, n, d);
      result := rdLoc(d)
    end
  end
end;
