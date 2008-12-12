//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

//var
//  newDummyVar: int; // just to check the rodgen mechanism

// ------------------------- Name Mangling --------------------------------

function mangle(const name: string): string;
var
  i: int;
begin
  case name[strStart] of
    'a'..'z': begin
      result := '';
      addChar(result, chr(ord(name[strStart]) - ord('a') + ord('A')));
    end;
    '0'..'9', 'A'..'Z': begin
      result := '';
      addChar(result, name[strStart]);
    end;
    else
      result := 'HEX' + toHex(ord(name[strStart]), 2);
  end;
  for i := strStart+1 to length(name) + strStart-1 do begin
    case name[i] of
      'A'..'Z': addChar(result, chr(ord(name[i]) - ord('A') + ord('a')));
      '_': begin end;
      'a'..'z', '0'..'9': addChar(result, name[i]);
      else begin
        add(result, 'HEX');
        add(result, toHex(ord(name[i]), 2))
      end
    end
  end
end;

function mangleName(s: PSym): PRope;
begin
  result := s.loc.r;
  if result = nil then begin
    result := toRope(mangle(s.name.s));
    app(result, '_'+'');
    app(result, toRope(s.id));
    if optGenMapping in gGlobalOptions then
      if s.owner <> nil then
        appf(gMapping, '"$1.$2": $3$n',
          [toRope(s.owner.Name.s), toRope(s.name.s), result]);
    s.loc.r := result;
  end
end;

function getTypeName(typ: PType): PRope;
begin
  if (typ.sym <> nil) and ([sfImportc, sfExportc] * typ.sym.flags <> []) then
    result := typ.sym.loc.r
  else begin
    if typ.loc.r = nil then typ.loc.r := con('TY', toRope(typ.id));
    result := typ.loc.r
  end;
  if result = nil then InternalError('getTypeName: ' + typeKindToStr[typ.kind]);
end;

// ------------------------------ C type generator ------------------------

function mapType(typ: PType): TCTypeKind;
begin
  case typ.kind of
    tyNone: result := ctVoid;
    tyBool: result := ctBool;
    tyChar: result := ctChar;
    tySet: begin
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
          8: result := ctInt64;
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

function getTypeDescAux(m: BModule; typ: PType;
                        var check: TIntSet): PRope; forward;

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
      ctArray:
        result := not (skipGeneric(rettype).kind in [tyVar, tyRef, tyPtr]);
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
    'N_INLINE', 'N_NOINLINE', 'N_FASTCALL', 'N_CLOSURE', 'N_NOCONV');

function CacheGetType(const tab: TIdTable; key: PType): PRope;
begin
  // returns nil if we need to declare this type
  // since types are now unique via the ``GetUniqueType`` mechanism, this slow
  // linear search is not necessary anymore:
  result := PRope(IdTableGet(tab, key))
end;

function getTempName(): PRope;
begin
  result := con('TMP', toRope(gId));
  inc(gId);
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

procedure genProcParams(m: BModule; t: PType; out rettype, params: PRope;
                        var check: TIntSet);
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
    rettype := getTypeDescAux(m, t.sons[0], check);
  for i := 1 to sonsLen(t.n)-1 do begin
    if t.n.sons[i].kind <> nkSym then InternalError(t.n.info, 'genProcParams');
    param := t.n.sons[i].sym;
    fillLoc(param.loc, locParam, param.typ, mangleName(param), OnStack);
    app(params, getTypeDescAux(m, param.typ, check));
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
    app(params, getTypeDescAux(m, t.sons[0], check));
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

function typeNameOrLiteral(t: PType; const literal: string): PRope;
begin
  if (t.sym <> nil) and (sfImportc in t.sym.flags) and
                        (t.sym.magic = mNone) then
    result := getTypeName(t)
  else
    result := toRope(literal)
end;

function getSimpleTypeDesc(m: BModule; typ: PType): PRope;
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
          8: result := typeNameOrLiteral(typ, 'NI64');
          else begin
            internalError(typ.sym.info,
                          'getSimpleTypeDesc: ' + toString(getSize(typ)));
            result := nil
          end
        end
      end
    end;
    tyString: begin
      useMagic(m, 'NimStringDesc');
      result := typeNameOrLiteral(typ, 'NimStringDesc*');
    end;
    tyCstring: result := typeNameOrLiteral(typ, 'NCSTRING');
    tyBool: result := typeNameOrLiteral(typ, 'NIM_BOOL');
    tyChar: result := typeNameOrLiteral(typ, 'NIM_CHAR');
    tyNil: result := typeNameOrLiteral(typ, '0'+'');
    tyInt..tyFloat128:
      result := typeNameOrLiteral(typ, NumericalTypeToStr[typ.Kind]);
    tyRange: result := getSimpleTypeDesc(m, typ.sons[0]);
    else result := nil;
  end
end;

function getTypePre(m: BModule; typ: PType): PRope;
begin
  if typ = nil then
    result := toRope('void')
  else begin
    result := getSimpleTypeDesc(m, typ);
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
                            rectype: PType; var check: TIntSet): PRope;
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
        app(result, genRecordFieldsAux(m, n.sons[i], accessExpr,
                                       rectype, check));
      end
    end;
    nkRecCase: begin
      if (n.sons[0].kind <> nkSym) then
        InternalError(n.info, 'genRecordFieldsAux');
      app(result, genRecordFieldsAux(m, n.sons[0], accessExpr, rectype, check));
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
                                      rectype, check);
              if a <> nil then begin
                app(result, 'struct {');
                app(result, a);
                appf(result, '} $1;$n', [sname]);
              end
            end
            else app(result, genRecordFieldsAux(m, k, ae, rectype, check));
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
      appf(result, '$1 $2;$n', [getTypeDescAux(m, field.loc.t, check), sname])
    end;
    else internalError(n.info, 'genRecordFieldsAux()');
  end
end;

function getRecordFields(m: BModule; typ: PType; var check: TIntSet): PRope;
begin
  result := genRecordFieldsAux(m, typ.n, nil, typ, check);
end;

function getRecordDesc(m: BModule; typ: PType; name: PRope;
                       var check: TIntSet): PRope;
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
        [name, getTypeDescAux(m, typ.sons[0], check)]);
      hasField := true
    end
    else begin
      result := ropef('struct $1 {$n  $2 Sup;$n',
        [name, getTypeDescAux(m, typ.sons[0], check)]);
      hasField := true
    end
  end
  else
    result := ropef('struct $1 {$n', [name]);
  desc := getRecordFields(m, typ, check);
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

function getTypeDescAux(m: BModule; typ: PType; var check: TIntSet): PRope;
// returns only the type's name
var
  name, rettype, desc, recdesc: PRope;
  n: biggestInt;
  t, et: PType;
begin
  t := getUniqueType(typ);
  if t = nil then InternalError('getTypeDescAux: t == nil');
  if t.sym <> nil then useHeader(m, t.sym);
  result := getTypePre(m, t);
  if result <> nil then exit;
  if IntSetContainsOrIncl(check, t.id) then begin
    InternalError('cannot generate C type for: ' + typeToString(typ));
    // XXX: this BUG is hard to fix -> we need to introduce helper structs,
    // but determining when this needs to be done is hard. We should split
    // C type generation into an analysis and a code generation phase somehow.
  end;
  case t.Kind of
    tyRef, tyPtr, tyVar: begin
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
          result := con(getTypeDescAux(m, et, check), '*'+'');
          IdTablePut(m.typeCache, t, result)
        end
      end
    end;
    tyOpenArray: begin
      et := getUniqueType(t.sons[0]);
      result := con(getTypeDescAux(m, et, check), '*'+'');
      IdTablePut(m.typeCache, t, result)
    end;
    tyProc: begin
      result := getTypeName(t);
      IdTablePut(m.typeCache, t, result);
      genProcParams(m, t, rettype, desc, check);
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
      if not isImportedType(t) then begin
        useMagic(m, 'TGenericSeq');
        appf(m.s[cfsSeqTypes],
          'struct $2 {$n' +
          '  TGenericSeq Sup;$n' +
          '  $1 data[SEQ_DECL_SIZE];$n' +
          '};$n', [getTypeDescAux(m, t.sons[0], check), result]);
      end;
      app(result, '*'+'');
    end;
    tyArrayConstr, tyArray: begin
      n := lengthOrd(t);
      if n <= 0 then n := 1; // make an array of at least one element
      result := getTypeName(t);
      IdTablePut(m.typeCache, t, result);
      if not isImportedType(t) then
        appf(m.s[cfsTypes], 'typedef $1 $2[$3];$n',
          [getTypeDescAux(m, t.sons[1], check), result, ToRope(n)])
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
      // always call for sideeffects:
      recdesc := getRecordDesc(m, t, result, check);
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
    tyGenericInst: result := getTypeDescAux(m, lastSon(t), check);
    else begin
      InternalError('getTypeDescAux(' + typeKindToStr[t.kind] + ')');
      result := nil
    end
  end
end;

function getTypeDesc(m: BModule; typ: PType): PRope;
var
  check: TIntSet;
begin
  IntSetInit(check);
  result := getTypeDescAux(m, typ, check);
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
  check: TIntSet;
begin
  // using static is needed for inline procs
  if (prc.typ.callConv = ccInline) then
    result := toRope('static ')
  else
    result := nil;
  IntSetInit(check);
  fillLoc(prc.loc, locProc, prc.typ, mangleName(prc), OnUnknown);
  genProcParams(m, prc.typ, rettype, params, check);
  appf(result, '$1($2, $3)$4',
               [toRope(CallingConvToStr[prc.typ.callConv]),
               rettype, prc.loc.r, params])
end;

// ----------------------- type information ----------------------------------

function genTypeInfo(m: BModule; typ: PType): PRope; forward;

function getNimNode(m: BModule): PRope;
begin
  result := ropef('$1[$2]', [m.typeNodesName, toRope(m.typeNodes)]);
  inc(m.typeNodes);
end;

function getNimType(m: BModule): PRope;
begin
  result := ropef('$1[$2]', [m.nimTypesName, toRope(m.nimTypes)]);
  inc(m.nimTypes);
end;

procedure allocMemTI(m: BModule; typ: PType; name: PRope);
var
  tmp: PRope;
begin
  tmp := getNimType(m);
  appf(m.s[cfsTypeInit2], '$2 = &$1;$n', [tmp, name]);
end;

procedure genTypeInfoAuxBase(m: BModule; typ: PType; name, base: PRope);
var
  nimtypeKind, flags: int;
begin
  allocMemTI(m, typ, name);
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
  // compute type flags for GC optimization
  flags := 0;
  if not containsGarbageCollectedRef(typ) then flags := flags or 1;
  if not canFormAcycle(typ) then flags := flags or 2;
  //else MessageOut('can contain a cycle: ' + typeToString(typ));
  if flags <> 0 then
    appf(m.s[cfsTypeInit3], '$1->flags = $2;$n', [name, toRope(flags)]);
  appf(m.s[cfsVars], 'TNimType* $1; /* $2 */$n',
      [name, toRope(typeToString(typ))]);
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
          tmp2 := getNimNode(m);
          appf(m.s[cfsTypeInit3], '$1[$2] = &$3;$n', [tmp, toRope(i), tmp2]);
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
        tmp2 := getNimNode(m);
        genObjectFields(m, typ, lastSon(b), tmp2);
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
  tmp := getNimNode(m);
  genObjectFields(m, typ, typ.n, tmp);
  appf(m.s[cfsTypeInit3], '$1->node = &$2;$n', [name, tmp]);
end;

procedure genEnumInfo(m: BModule; typ: PType; name: PRope);
var
  nodePtrs, elemNode, enumNames, enumArray, counter, specialCases: PRope;
  len, i, firstNimNode: int;
  field: PSym;
begin
  // Type information for enumerations is quite heavy, so we do some
  // optimizations here: The ``typ`` field is never set, as it is redundant
  // anyway. We generate a cstring array and a loop over it. Exceptional
  // positions will be reset after the loop.
  genTypeInfoAux(m, typ, name);
  nodePtrs := getTempName();
  len := sonsLen(typ.n);
  appf(m.s[cfsTypeInit1], 'static TNimNode* $1[$2];$n', [nodePtrs, toRope(len)]);
  enumNames := nil;
  specialCases := nil;
  firstNimNode := m.typeNodes;
  for i := 0 to len-1 do begin
    assert(typ.n.sons[i].kind = nkSym);
    field := typ.n.sons[i].sym;
    elemNode := getNimNode(m);
    app(enumNames, makeCString(field.name.s));
    if i < len-1 then app(enumNames, ', '+tnl);
    if field.position <> i then
      appf(specialCases, '$1.offset = $2;$n', [elemNode, toRope(field.position)]);
  end;
  enumArray := getTempName();
  counter := getTempName();
  appf(m.s[cfsTypeInit1], 'NI $1;$n', [counter]);
  appf(m.s[cfsTypeInit1], 'static char* NIM_CONST $1[$2] = {$n$3};$n',
       [enumArray, toRope(len), enumNames]);
  appf(m.s[cfsTypeInit3], 'for ($1 = 0; $1 < $2; $1++) {$n' +
                          '$3[$1+$4].kind = 1;$n' +
                          '$3[$1+$4].offset = $1;$n' +
                          '$3[$1+$4].name = $5[$1];$n' +
                          '$6[$1] = &$3[$1+$4];$n' +
                          '}$n',
      [counter, toRope(len), m.typeNodesName, toRope(firstNimNode),
       enumArray, nodePtrs]);
  app(m.s[cfsTypeInit3], specialCases);
  appf(m.s[cfsTypeInit3],
    '$1.len = $2; $1.kind = 2; $1.sons = &$3[0];$n$4->node = &$1;$n', [
    getNimNode(m), toRope(len), nodePtrs, name]);
end;

procedure genSetInfo(m: BModule; typ: PType; name: PRope);
var
  tmp: PRope;
begin
  assert(typ.sons[0] <> nil);
  genTypeInfoAux(m, typ, name);
  tmp := getNimNode(m);
  appf(m.s[cfsTypeInit3],
    '$1.len = $2; $1.kind = 0;$n' +
    '$3->node = &$1;$n', [tmp, toRope(firstOrd(typ)), name]);
end;

procedure genArrayInfo(m: BModule; typ: PType; name: PRope);
begin
  genTypeInfoAuxBase(m, typ, name, genTypeInfo(m, typ.sons[1]));
end;

var
  gToTypeInfoId: TIiTable;

(* // this does not work any longer thanks to separate compilation:
function getTypeInfoName(t: PType): PRope;
begin
  result := ropef('NTI$1', [toRope(t.id)]);
end;*)

function genTypeInfo(m: BModule; typ: PType): PRope;
var
  t: PType;
  id: int;
  dataGen: bool;
begin
  t := getUniqueType(typ);
  id := IiTableGet(gToTypeInfoId, t.id);
  if id = invalidKey then begin
    dataGen := false;
    case t.kind of
      tyEnum, tyBool: begin
        id := t.id;
        dataGen := true
      end;
      tyObject: begin
        if isPureObject(t) then
          id := getID()
        else begin
          id := t.id;
          dataGen := true
        end
      end
      else
        id := getID();
    end;
    IiTablePut(gToTypeInfoId, t.id, id);
  end
  else
    dataGen := true;
  result := ropef('NTI$1', [toRope(id)]);
  if not IntSetContainsOrIncl(m.typeInfoMarker, t.id) then begin
    // declare type information structures:
    useMagic(m, 'TNimType');
    useMagic(m, 'TNimNode');
    if dataGen then
      appf(m.s[cfsVars], 'extern TNimType* $1; /* $2 */$n',
           [result, toRope(typeToString(t))]);
  end;
  if dataGen then exit;
  case t.kind of
    tyPointer, tyProc, tyBool, tyChar, tyCString, tyString,
    tyInt..tyFloat128, tyVar:
      genTypeInfoAuxBase(m, t, result, toRope('0'+''));
    tyRef, tyPtr, tySequence, tyRange: genTypeInfoAux(m, t, result);
    tyArrayConstr, tyArray: genArrayInfo(m, t, result);
    tySet: genSetInfo(m, t, result);
    tyEnum: genEnumInfo(m, t, result);
    tyObject, tyTuple: genObjectInfo(m, t, result);
    else InternalError('genTypeInfo(' + typekindToStr[t.kind] + ')');
  end
end;

procedure genTypeSection(m: BModule; n: PNode);
var
  i: int;
  a: PNode;
  t: PType;
begin
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    if (a.sons[0].kind <> nkSym) then InternalError(a.info, 'genTypeSection');
    t := a.sons[0].sym.typ;
    if (a.sons[2] = nil)
    or not (a.sons[2].kind in [nkSym, nkIdent, nkAccQuoted]) then
      if t <> nil then
        case t.kind of
          tyEnum, tyBool: begin
            useMagic(m, 'TNimType');
            useMagic(m, 'TNimNode');
            genEnumInfo(m, t, ropef('NTI$1', [toRope(t.id)]));
          end;
          tyObject: begin
            if not isPureObject(t) then begin
              useMagic(m, 'TNimType');
              useMagic(m, 'TNimNode');
              genObjectInfo(m, t, ropef('NTI$1', [toRope(t.id)]));
            end
          end
          else begin end
        end
  end
end;
