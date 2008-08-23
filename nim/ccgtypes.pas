//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// ------------------------- Name Mangling --------------------------------

function mangle(const name: string): string;
var
  i: int;
begin
  if name[strStart] in ['A'..'Z', '0'..'9', 'a'..'z'] then
    result := toUpper(name[strStart])+''
  else
    result := 'HEX' + toHex(ord(name[strStart]), 2);
  for i := strStart+1 to length(name) + strStart-1 do begin
    case name[i] of
      'A'..'Z': addChar(result, chr(ord(name[i]) - ord('A') + ord('a')));
      '_': begin end;
      'a'..'z', '0'..'9': addChar(result, name[i]);
      else result := result + 'HEX' +{&} toHex(ord(name[i]), 2);
    end
  end
end;

function mangleName(s: PSym): PRope;
begin
  result := ropef('$1_$2', [toRope(mangle(s.name.s)), toRope(s.id)]);
  if optGenMapping in gGlobalOptions then
    if s.owner <> nil then
      appf(gMapping, '$1.$2    $3$n',
        [toRope(s.owner.Name.s), toRope(s.name.s), result])
end;

// ------------------------------ C type generator ------------------------

function mapType(typ: PType): TCTypeKind;
begin
  case typ.kind of
    tyNone: result := ctVoid;
    tyBool: result := ctBool;
    tyChar: result := ctChar;
    tyEmptySet, tySet: begin
      case int(getSize(typ)) of
        1: result := ctInt8;
        2: result := ctInt16;
        4: result := ctInt32;
        8: result := ctInt64;
        else result := ctArray
      end
    end;
    tyOpenArray, tyArrayConstr, tyArray: result := ctArray;
    tyObject, tyTuple: result := ctStruct;
    tyGeneric, tyGenericInst, tyGenericParam: result := mapType(lastSon(typ));
    tyEnum, tyAnyEnum: begin
      if firstOrd(typ) < 0 then
        result := ctInt32
      else begin
        case int(getSize(typ)) of
          1: result := ctUInt8;
          2: result := ctUInt16;
          4: result := ctInt32;
          else internalError('mapType');
        end
      end
    end;
    tyRange: result := mapType(typ.sons[0]);
    tyPtr, tyVar, tyRef: begin
      case typ.sons[0].kind of
        tyOpenArray, tyArrayConstr, tyArray: result := ctArray;
        (*tySet: begin
          if mapType(typ.sons[0]) = ctArray then result := ctArray
          else result := ctPtr
        end*)
        else result := ctPtr
      end
    end;
    tyPointer: result := ctPtr;
    tySequence: result := ctNimSeq;
    tyProc: result := ctProc;
    tyString: result := ctNimStr;
    tyCString: result := ctCString;
    tyInt..tyFloat128:
      result := TCTypeKind(ord(typ.kind) - ord(tyInt) + ord(ctInt));
    else InternalError('mapType');
  end
end;

function getTypeDesc(m: BModule; typ: PType): PRope; forward;

function needsComplexAssignment(typ: PType): bool;
begin
  result := containsGarbageCollectedRef(typ);
end;

function isInvalidReturnType(rettype: PType): bool;
begin
  // Arrays and sets cannot be returned by a C procedure, because C is
  // such a poor programming language.
  // We exclude records with refs too. This enhances efficiency and
  // is necessary for proper code generation of assignments.
  if rettype = nil then
    result := true
  else begin
    case mapType(rettype) of
      ctArray: result := true;
      ctStruct: result := needsComplexAssignment(skipGeneric(rettype));
      else result := false;
    end
  end
end;

const
  CallingConvToStr: array [TCallingConvention] of string = ('N_NIMCALL',
    'N_STDCALL', 'N_CDECL', 'N_SAFECALL', 'N_SYSCALL',
    // this is probably not correct for all platforms,
    // but one can //define it to what you want so there will no problem
    'N_INLINE', 'N_FASTCALL', 'N_CLOSURE', 'N_NOCONV');

function CacheGetType(const tab: TIdTable; key: PType): PRope;
begin
  // returns nil if we need to declare this type
  result := PRope(TableGetType(tab, key))
end;

function getTempName(): PRope;
begin
  inc(gUnique);
  result := con('T'+'', toRope(gUnique))
end;

function ccgIntroducedPtr(s: PSym): bool;
var
  pt: PType;
begin
  pt := s.typ;
  assert(not (sfResult in s.flags));
  case pt.Kind of
    tyObject: begin
      if (optByRef in s.options) or (getSize(pt) > platform.floatSize) then
        result := true // requested anyway
      else if (tfFinal in pt.flags) and (pt.sons[0] = nil) then
        result := false // no need, because no subtyping possible
      else
        result := true; // ordinary objects are always passed by reference,
                        // otherwise casting doesn't work
    end;
    tyTuple:
      result := (getSize(pt) > platform.floatSize) or (optByRef in s.options);
    else
      result := false
  end
end;

procedure fillResult(param: PSym);
begin
  fillLoc(param.loc, locParam, param.typ, toRope('Result'), OnStack);
  if (mapType(param.typ) <> ctArray) and IsInvalidReturnType(param.typ) then
  begin
    include(param.loc.flags, lfIndirect);
    param.loc.s := OnUnknown
  end
end;

procedure genProcParams(m: BModule; t: PType; out rettype, params: PRope);
var
  i, j: int;
  param: PSym;
  arr: PType;
begin
  params := nil;
  if (t.sons[0] = nil) or isInvalidReturnType(t.sons[0]) then
    // C cannot return arrays (what a poor language...)
    rettype := toRope('void')
  else
    rettype := getTypeDesc(m, t.sons[0]);
  for i := 1 to sonsLen(t.n)-1 do begin
    if t.n.sons[i].kind <> nkSym then InternalError(t.n.info, 'genProcParams');
    param := t.n.sons[i].sym;
    fillLoc(param.loc, locParam, param.typ, mangleName(param), OnStack);
    app(params, getTypeDesc(m, param.typ));
    if ccgIntroducedPtr(param) then begin
      app(params, '*'+'');
      include(param.loc.flags, lfIndirect);
      param.loc.s := OnUnknown;
    end;
    app(params, ' '+'');
    app(params, param.loc.r);
    // declare the len field for open arrays:
    arr := param.typ;
    if arr.kind = tyVar then arr := arr.sons[0];
    j := 0;
    while arr.Kind = tyOpenArray do begin // need to pass hidden parameter:
      appf(params, ', NI $1Len$2', [param.loc.r, toRope(j)]);
      inc(j);
      arr := arr.sons[0]
    end;
    if i < sonsLen(t.n)-1 then app(params, ', ');
  end;
  if (t.sons[0] <> nil) and isInvalidReturnType(t.sons[0]) then begin
    if params <> nil then app(params, ', ');
    app(params, getTypeDesc(m, t.sons[0]));
    if mapType(t.sons[0]) <> ctArray then app(params, '*'+'');
    app(params, ' Result');
  end;
  if t.callConv = ccClosure then begin
    if params <> nil then app(params, ', ');
    app(params, 'void* ClPart')
  end;
  if tfVarargs in t.flags then begin
    if params <> nil then app(params, ', ');
    app(params, '...')
  end;
  if params = nil then
    app(params, 'void)')
  else
    app(params, ')'+'');
  params := con('('+'', params);
end;

function isImportedType(t: PType): bool;
begin
  result := (t.sym <> nil) and (sfImportc in t.sym.flags)
end;

function getTypeName(typ: PType): PRope;
begin
  if (typ.sym <> nil) and ([sfImportc, sfExportc] * typ.sym.flags <> []) then
    result := typ.sym.loc.r
  else begin
    if typ.loc.r = nil then typ.loc.r := con('Ty', toRope(typ.id));
    result := typ.loc.r
  end
end;

function typeNameOrLiteral(typ: PType; const literal: string): PRope;
begin
  if isImportedType(typ) then
    result := getTypeName(typ)
  else
    result := toRope(literal)
end;

function getSimpleTypeDesc(typ: PType): PRope;
const
  NumericalTypeToStr: array [tyInt..tyFloat128] of string = (
    'NI', 'NI8', 'NI16', 'NI32', 'NI64', 'NF', 'NF32', 'NF64', 'NF128');
begin
  case typ.Kind of
    tyPointer: result := typeNameOrLiteral(typ, 'void*');
    tyEnum: begin
      if firstOrd(typ) < 0 then
        result := typeNameOrLiteral(typ, 'NI32')
      else begin
        case int(getSize(typ)) of
          1: result := typeNameOrLiteral(typ, 'NU8');
          2: result := typeNameOrLiteral(typ, 'NU16');
          4: result := typeNameOrLiteral(typ, 'NI32');
          else begin
            internalError('getSimpleTypeDesc()');
            result := nil
          end
        end
      end
    end;
    tyString: result := typeNameOrLiteral(typ, 'string');
    tyCstring: result := typeNameOrLiteral(typ, 'NCSTRING');
    tyBool: result := typeNameOrLiteral(typ, 'NIM_BOOL');
    tyChar: result := typeNameOrLiteral(typ, 'NIM_CHAR');
    tyNil: result := typeNameOrLiteral(typ, '0'+'');
    tyInt..tyFloat128:
      result := typeNameOrLiteral(typ, NumericalTypeToStr[typ.Kind]);
    tyRange: result := getSimpleTypeDesc(typ.sons[0]);
    else result := nil;
  end
end;

function getTypePre(m: BModule; typ: PType): PRope;
begin
  if typ = nil then
    result := toRope('void')
  else begin
    result := getSimpleTypeDesc(typ);
    if result = nil then
      result := CacheGetType(m.typeCache, typ)
  end
end;

function getForwardStructFormat(): string;
begin
  if gCmd = cmdCompileToCpp then result := 'struct $1;$n'
  else result := 'typedef struct $1 $1;$n'
end;

function getTypeForward(m: BModule; typ: PType): PRope;
begin
  result := CacheGetType(m.forwTypeCache, typ);
  if result <> nil then exit;
  result := getTypePre(m, typ);
  if result <> nil then exit;
  case typ.kind of
    tySequence, tyTuple, tyObject: begin
      result := getTypeName(typ);
      if not isImportedType(typ) then
        appf(m.s[cfsForwardTypes], getForwardStructFormat(), [result]);
      IdTablePut(m.forwTypeCache, typ, result)
    end
    else
      InternalError('getTypeForward(' + typeKindToStr[typ.kind] + ')')
  end
end;

function mangleRecFieldName(field: PSym; rectype: PType): PRope;
begin
  if (rectype.sym <> nil)
  and ([sfImportc, sfExportc] * rectype.sym.flags <> []) then
    result := field.loc.r
  else
    result := toRope(mangle(field.name.s));
  if result = nil then InternalError(field.info, 'mangleRecFieldName');
end;

function genRecordFieldsAux(m: BModule; n: PNode; accessExpr: PRope;
                            rectype: PType): PRope;
var
  i: int;
  ae, uname, sname, a: PRope;
  k: PNode;
  field: PSym;
begin
  result := nil;
  case n.kind of
    nkRecList: begin
      for i := 0 to sonsLen(n)-1 do begin
        app(result, genRecordFieldsAux(m, n.sons[i], accessExpr, rectype));
      end
    end;
    nkRecCase: begin
      if (n.sons[0].kind <> nkSym) then
        InternalError(n.info, 'genRecordFieldsAux');
      app(result, genRecordFieldsAux(m, n.sons[0], accessExpr, rectype));
      uname := toRope(mangle(n.sons[0].sym.name.s)+ 'U');
      if accessExpr <> nil then ae := ropef('$1.$2', [accessExpr, uname])
      else ae := uname;
      app(result, 'union {'+tnl);
      for i := 1 to sonsLen(n)-1 do begin
        case n.sons[i].kind of
          nkOfBranch, nkElse: begin
            k := lastSon(n.sons[i]);
            if k.kind <> nkSym then begin
              sname := con('S'+'', toRope(i));
              a := genRecordFieldsAux(m, k, ropef('$1.$2', [ae, sname]),
                                      rectype);
              if a <> nil then begin
                app(result, 'struct {');
                app(result, a);
                appf(result, '} $1;$n', [sname]);
              end
            end
            else app(result, genRecordFieldsAux(m, k, ae, rectype));
          end;
          else internalError('genRecordFieldsAux(record case branch)');
        end;
      end;
      appf(result, '} $1;$n', [uname])
    end;
    nkSym: begin
      field := n.sym;
      assert(field.ast = nil);
      sname := mangleRecFieldName(field, rectype);
      if accessExpr <> nil then ae := ropef('$1.$2', [accessExpr, sname])
      else ae := sname;
      fillLoc(field.loc, locField, field.typ, ae, OnUnknown);
      appf(result, '$1 $2;$n', [getTypeDesc(m, field.loc.t), sname])
    end;
    else internalError(n.info, 'genRecordFieldsAux()');
  end
end;

function getRecordFields(m: BModule; typ: PType): PRope;
begin
  result := genRecordFieldsAux(m, typ.n, nil, typ);
end;

function getRecordDesc(m: BModule; typ: PType; name: PRope): PRope;
var
  desc: PRope;
  hasField: bool;
begin
  // declare the record:
  hasField := false;
  if typ.kind = tyObject then begin
    useMagic(m, 'TNimType');
    if typ.sons[0] = nil then begin
      if (typ.sym <> nil) and (sfPure in typ.sym.flags)
      or (tfFinal in typ.flags) then
        result := ropef('struct $1 {$n', [name])
      else begin
        result := ropef('struct $1 {$nTNimType* m_type;$n', [name]);
        hasField := true
      end
    end
    else if gCmd = cmdCompileToCpp then begin
      result := ropef('struct $1 : public $2 {$n',
        [name, getTypeDesc(m, typ.sons[0])]);
      hasField := true
    end
    else begin
      result := ropef('struct $1 {$n  $2 Sup;$n',
        [name, getTypeDesc(m, typ.sons[0])]);
      hasField := true
    end
  end
  else
    result := ropef('struct $1 {$n', [name]);
  desc := getRecordFields(m, typ);
  if (desc = nil) and not hasField then
  // no fields in struct are not valid in C, so generate a dummy:
    appf(result, 'char dummy;$n', [])
  else
    app(result, desc);
  app(result, '};' + tnl);
end;

procedure pushType(m: BModule; typ: PType);
var
  L: int;
begin
  L := length(m.typeStack);
  setLength(m.typeStack, L+1);
  m.typeStack[L] := typ;
end;

function getTypeDesc(m: BModule; typ: PType): PRope;
// returns only the type's name
var
  name, rettype, desc, recdesc: PRope;
  n: biggestInt;
  t, et: PType;
begin
  t := getUniqueType(typ);
  if t = nil then InternalError('getTypeDesc: t == nil');
  if t.sym <> nil then useHeader(m, t.sym);
  result := getTypePre(m, t);
  if result <> nil then exit;
  case t.Kind of
    tyRef, tyPtr, tyVar, tyOpenArray: begin
      et := getUniqueType(t.sons[0]);
      if et.kind in [tyArrayConstr, tyArray, tyOpenArray] then
        et := getUniqueType(elemType(et));
      case et.Kind of
        tyObject, tyTuple: begin
          // no restriction! We have a forward declaration for structs
          name := getTypeForward(m, et);
          result := con(name, '*'+'');
          IdTablePut(m.typeCache, t, result);
          pushType(m, et);
        end;
        tySequence: begin
          // no restriction! We have a forward declaration for structs
          name := getTypeForward(m, et);
          result := con(name, '**');
          IdTablePut(m.typeCache, t, result);
          pushType(m, et);
        end;
        else begin
          // else we have a strong dependency  :-(
          result := con(getTypeDesc(m, et), '*'+'');
          IdTablePut(m.typeCache, t, result)
        end
      end
    end;
    tyProc: begin
      result := getTypeName(t);
      IdTablePut(m.typeCache, t, result);
      genProcParams(m, t, rettype, desc);
      if not isImportedType(t) then begin
        if t.callConv <> ccClosure then
          appf(m.s[cfsTypes], 'typedef $1_PTR($2, $3) $4;$n',
            [toRope(CallingConvToStr[t.callConv]), rettype, result, desc])
        else // procedure vars may need a closure!
          appf(m.s[cfsTypes], 'typedef struct $1 {$n' +
                              'N_CDECL_PTR($2, PrcPart) $3;$n' +
                              'void* ClPart;$n};$n',
            [result, rettype, desc]);
      end
    end;
    tySequence: begin
      // we cannot use getTypeForward here because then t would be associated
      // with the name of the struct, not with the pointer to the struct:
      result := CacheGetType(m.forwTypeCache, t);
      if result = nil then begin
        result := getTypeName(t);
        if not isImportedType(t) then
          appf(m.s[cfsForwardTypes], getForwardStructFormat(), [result]);
        IdTablePut(m.forwTypeCache, t, result);
      end;
      assert(CacheGetType(m.typeCache, t) = nil);
      IdTablePut(m.typeCache, t, con(result, '*'+''));
      if not isImportedType(t) then
        appf(m.s[cfsSeqTypes],
          'struct $2 {$n' +
          '  NI len, space;$n' +
          '  $1 data[SEQ_DECL_SIZE];$n' +
          '};$n', [getTypeDesc(m, t.sons[0]), result]);
      app(result, '*'+'');
    end;
    tyArrayConstr, tyArray: begin
      n := lengthOrd(t);
      if n <= 0 then n := 1; // make an array of at least one element
      result := getTypeName(t);
      IdTablePut(m.typeCache, t, result);
      if not isImportedType(t) then
        appf(m.s[cfsTypes], 'typedef $1 $2[$3];$n',
          [getTypeDesc(m, t.sons[1]), result, ToRope(n)])
    end;
    tyObject, tyTuple: begin
      result := CacheGetType(m.forwTypeCache, t);
      if result = nil then begin
        result := getTypeName(t);
        if not isImportedType(t) then
          appf(m.s[cfsForwardTypes],
            getForwardStructFormat(), [result]);
        IdTablePut(m.forwTypeCache, t, result)
      end;
      IdTablePut(m.typeCache, t, result);
      recdesc := getRecordDesc(m, t, result); // always call for sideeffects
      if not isImportedType(t) then app(m.s[cfsTypes], recdesc);
    end;
    tySet: begin
      case int(getSize(t)) of
        1: result := toRope('NU8');
        2: result := toRope('NU16');
        4: result := toRope('NU32');
        8: result := toRope('NU64');
        else begin
          result := getTypeName(t);
          IdTablePut(m.typeCache, t, result);
          if not isImportedType(t) then
            appf(m.s[cfsTypes], 'typedef NU8 $1[$2];$n',
              [result, toRope(getSize(t))])
        end
      end
    end;
    tyGenericInst: result := getTypeDesc(m, lastSon(t));
    else begin
      InternalError('getTypeDesc(' + typeKindToStr[t.kind] + ')');
      result := nil
    end
  end
end;

procedure finishTypeDescriptions(m: BModule);
var
  i: int;
begin
  i := 0;
  while i < length(m.typeStack) do begin
    {@discard} getTypeDesc(m, m.typeStack[i]);
    inc(i);
  end;
end;

function genProcHeader(m: BModule; prc: PSym): PRope;
var
  rettype, params: PRope;
begin
  // using static is needed for inline procs
  if (prc.typ.callConv = ccInline) then
    result := toRope('static ')
  else
    result := nil;
  fillLoc(prc.loc, locProc, prc.typ, mangleName(prc), OnUnknown);
  genProcParams(m, prc.typ, rettype, params);
  appf(result, '$1($2, $3)$4',
               [toRope(CallingConvToStr[prc.typ.callConv]),
               rettype, prc.loc.r, params])
end;

// ----------------------- type information ----------------------------------

var
  gTypeInfoGenerated: TIntSet;

function genTypeInfo(m: BModule; typ: PType): PRope; forward;

procedure allocMemTI(m: BModule; name: PRope);
var
  tmp: PRope;
begin
  tmp := getTempName();
  appf(m.s[cfsTypeInit1], 'static TNimType $1;$n', [tmp]);
  appf(m.s[cfsTypeInit2], '$2 = &$1;$n', [tmp, name]);
end;

procedure genTypeInfoAuxBase(m: BModule; typ: PType; name, base: PRope);
var
  nimtypeKind: int;
begin
  allocMemTI(m, name);
  if (typ.kind = tyObject) and (tfFinal in typ.flags)
  and (typ.sons[0] = nil) then
    nimtypeKind := ord(high(TTypeKind))+1 // tyPureObject
  else
    nimtypeKind := ord(typ.kind);
  appf(m.s[cfsTypeInit3],
    '$1->size = sizeof($2);$n' +
    '$1->kind = $3;$n' +
    '$1->base = $4;$n', [
    name, getTypeDesc(m, typ), toRope(nimtypeKind), base]);
  appf(m.s[cfsVars], 'TNimType* $1;$n', [name]);
end;

procedure genTypeInfoAux(m: BModule; typ: PType; name: PRope);
var
  base: PRope;
begin
  if (sonsLen(typ) > 0) and (typ.sons[0] <> nil) then
    base := genTypeInfo(m, typ.sons[0])
  else
    base := toRope('0'+'');
  genTypeInfoAuxBase(m, typ, name, base);
end;

procedure genObjectFields(m: BModule; typ: PType; n: PNode; expr: PRope);
var
  tmp, tmp2: PRope;
  len, i, j, x, y: int;
  field: PSym;
  b: PNode;
begin
  case n.kind of
    nkRecList: begin
      len := sonsLen(n);
      if len = 1 then  // generates more compact code!
        genObjectFields(m, typ, n.sons[0], expr)
      else if len > 0 then begin
        tmp := getTempName();
        appf(m.s[cfsTypeInit1], 'static TNimNode* $1[$2];$n',
            [tmp, toRope(len)]);
        for i := 0 to len-1 do begin
          tmp2 := getTempName();
          appf(m.s[cfsTypeInit1], 'static TNimNode $1;$n', [tmp2]);
          appf(m.s[cfsTypeInit3], '$1[$2] = &$3;$n',
                        [tmp, toRope(i), tmp2]);
          genObjectFields(m, typ, n.sons[i], tmp2);
        end;
        appf(m.s[cfsTypeInit3],
          '$1.len = $2; $1.kind = 2; $1.sons = &$3[0];$n', [
          expr, toRope(len), tmp]);
      end
      else
        appf(m.s[cfsTypeInit3],
          '$1.len = $2; $1.kind = 2;$n', [expr, toRope(len)]);
    end;
    nkRecCase: begin
      len := sonsLen(n);
      assert(n.sons[0].kind = nkSym);
      field := n.sons[0].sym;
      tmp := getTempName();
      appf(m.s[cfsTypeInit3], '$1.kind = 3;$n' +
                              '$1.offset = offsetof($2, $3);$n' +
                              '$1.typ = $4;$n' +
                              '$1.name = $5;$n' +
                              '$1.sons = &$6[0];$n' +
                              '$1.len = $7;$n',
            [expr, getTypeDesc(m, typ), field.loc.r,
             genTypeInfo(m, field.typ),
             makeCString(field.name.s), tmp,
             toRope(lengthOrd(field.typ))]);
      appf(m.s[cfsTypeInit1], 'static TNimNode* $1[$2];$n',
                                       [tmp, toRope(lengthOrd(field.typ)+1)]);
      for i := 1 to len-1 do begin
        b := n.sons[i]; // branch
        tmp2 := getTempName();
        appf(m.s[cfsTypeInit1], 'static TNimNode $1;$n', [tmp2]);
        genObjectFields(m, typ, lastSon(b), tmp2);
        //writeln(output, renderTree(b.sons[j]));
        case b.kind of
          nkOfBranch: begin
            if sonsLen(b) < 2 then
              internalError(b.info, 'genObjectFields; nkOfBranch broken');
            for j := 0 to sonsLen(b)-2 do begin
              if b.sons[j].kind = nkRange then begin
                x := int(getOrdValue(b.sons[j].sons[0]));
                y := int(getOrdValue(b.sons[j].sons[1]));
                while x <= y do begin
                  appf(m.s[cfsTypeInit3], '$1[$2] = &$3;$n',
                                [tmp, toRope(x), tmp2]);
                  inc(x);
                end;
              end
              else
                appf(m.s[cfsTypeInit3], '$1[$2] = &$3;$n',
                             [tmp, toRope(getOrdValue(b.sons[j])), tmp2])
            end
          end;
          nkElse: begin
            appf(m.s[cfsTypeInit3], '$1[$2] = &$3;$n',
                          [tmp, toRope(lengthOrd(field.typ)), tmp2]);
          end
          else
            internalError(n.info, 'genObjectFields(nkRecCase)');
        end
      end
    end;
    nkSym: begin
      field := n.sym;
      appf(m.s[cfsTypeInit3], '$1.kind = 1;$n' +
                              '$1.offset = offsetof($2, $3);$n' +
                              '$1.typ = $4;$n' +
                              '$1.name = $5;$n',
                              [expr, getTypeDesc(m, typ), field.loc.r,
                              genTypeInfo(m, field.typ),
                              makeCString(field.name.s)]);
    end;
    else internalError(n.info, 'genObjectFields');
  end
end;

procedure genObjectInfo(m: BModule; typ: PType; name: PRope);
var
  tmp: PRope;
begin
  if typ.kind = tyObject then genTypeInfoAux(m, typ, name)
  else genTypeInfoAuxBase(m, typ, name, toRope('0'+''));
  tmp := getTempName();
  appf(m.s[cfsTypeInit1], 'static TNimNode $1;$n', [tmp]);
  genObjectFields(m, typ, typ.n, tmp);
  appf(m.s[cfsTypeInit3], '$1->node = &$2;$n', [name, tmp]);
end;

procedure genEnumInfo(m: BModule; typ: PType; name: PRope);
var
  tmp, tmp2, tmp3: PRope;
  len, i: int;
  field: PSym;
begin
  genTypeInfoAux(m, typ, name);
  tmp := getTempName();
  tmp2 := getTempName();
  len := sonsLen(typ.n);
  appf(m.s[cfsTypeInit1], 'static TNimNode* $1[$2];$n' +
                          'static TNimNode $3;$n',
                          [tmp, toRope(len), tmp2]);
  for i := 0 to len-1 do begin
    assert(typ.n.sons[i].kind = nkSym);
    field := typ.n.sons[i].sym;
    tmp3 := getTempName();
    appf(m.s[cfsTypeInit1], 'static TNimNode $1;$n', [tmp3]);
    appf(m.s[cfsTypeInit3], '$1[$2] = &$3;$n' +
                            '$3.kind = 1;$n' +
                            '$3.offset = $4;$n' +
                            '$3.typ = $5;$n' +
                            '$3.name = $6;$n',
                  [tmp, toRope(i), tmp3,
                   toRope(field.position),
                   name, makeCString(field.name.s)]);
  end;
  appf(m.s[cfsTypeInit3],
    '$1.len = $2; $1.kind = 2; $1.sons = &$3[0];$n$4->node = &$1;$n', [
    tmp2, toRope(len), tmp, name]);
end;

procedure genSetInfo(m: BModule; typ: PType; name: PRope);
var
  tmp: PRope;
begin
  assert(typ.sons[0] <> nil);
  genTypeInfoAux(m, typ, name);
  tmp := getTempName();
  appf(m.s[cfsTypeInit1], 'static TNimNode $1;$n', [tmp]);
  appf(m.s[cfsTypeInit3],
    '$1.len = $2; $1.kind = 0;$n' +
    '$3->node = &$1;$n', [tmp, toRope(firstOrd(typ)), name]);
end;

procedure genArrayInfo(m: BModule; typ: PType; name: PRope);
begin
  genTypeInfoAuxBase(m, typ, name, genTypeInfo(m, typ.sons[1]));
end;

function genTypeInfo(m: BModule; typ: PType): PRope;
var
  t: PType;
begin
  t := getUniqueType(typ);
  result := ropef('NTI$1', [toRope(t.id)]);
  if not IntSetContainsOrIncl(m.typeInfoMarker, t.id) then begin
    // declare type information structures:
    useMagic(m, 'TNimType');
    useMagic(m, 'TNimNode');
    appf(m.s[cfsVars], 'extern TNimType* $1;$n', [result]);
  end;
  if IntSetContainsOrIncl(gTypeInfoGenerated, t.id) then exit;
  case t.kind of
    tyPointer, tyProc, tyBool, tyChar, tyCString, tyString, tyInt..tyFloat128:
      genTypeInfoAuxBase(m, t, result, toRope('0'+''));
    tyRef, tyPtr, tySequence, tyRange: genTypeInfoAux(m, t, result);
    tyArrayConstr, tyArray: genArrayInfo(m, t, result);
    tySet: genSetInfo(m, t, result);
    tyEnum: genEnumInfo(m, t, result);
    tyObject, tyTuple: genObjectInfo(m, t, result);
    tyVar: result := genTypeInfo(m, typ.sons[0]);
    else InternalError('genTypeInfo(' + typekindToStr[t.kind] + ')');
  end
end;
