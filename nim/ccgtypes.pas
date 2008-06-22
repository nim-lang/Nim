//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// ------------------------- Name Mangling --------------------------------

function getUnique(p: BProc): PRope;
begin
  inc(p.unique);
  result := toRope(p.unique)
end;

function mangle(const name: string): string;
var
  i: int;
begin
  if name[strStart] in ['A'..'Z', '0'..'9', 'a'..'z'] then
    result := toUpper(name[strStart])+''
  else
    result := 'HEX' + toHex(ord(name[strStart]), 2);
  for i := 2 to length(name) - 1 + strStart do begin
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
  if s.owner <> nil then
    result := ropeFormat('$1_$2_$3', [toRope(mangle(s.owner.name.s)),
                                      toRope(mangle(s.name.s)),
                                      toRope(s.id)])
  else
    result := ropeFormat('$1_$2', [toRope(mangle(s.name.s)),
                                  toRope(s.id)]);
  if optGenMapping in gGlobalOptions then
    if s.owner <> nil then
      appRopeFormat(gMapping, '$1.$2    $3$n',
        [toRope(s.owner.Name.s), toRope(s.name.s), result])
end;

// ------------------------------ C type generator ------------------------

function getTypeDesc(typ: PType): PRope; forward;

function needsComplexAssignment(typ: PType): bool;
begin
  result := containsGarbageCollectedRef(typ);
end;

function isInvalidReturnType(rettype: PType): bool;
var
  t: PType;
begin
  // Arrays and sets cannot be returned by a C procedure, because C is
  // such a poor programming language.
  // We exclude records with refs too. This enhances efficiency and
  // is necessary for proper code generation of assignments.
  if rettype = nil then
    result := true
  else begin
    t := skipAbstract(rettype);
    case t.kind of
      tyArray, tyArrayConstr: result := true;
      tyObject, tyRecord: result := needsComplexAssignment(t);
      tySet: begin
        case int(getSize(t)) of
          1, 2, 4, 8: result := false;
          else result := true
        end
      end
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

var
  gUnique: int;

function getTempName(): PRope;
begin
  inc(gUnique);
  result := con('T'+'', toRope(gUnique))
end;

function isCArray(typ: PType): bool;
var
  t: PType;
begin
  t := skipVarGeneric(typ);
  case t.kind of
    tyArray, tyArrayConstr, tyOpenArray: result := true;
    tySet: result := getSize(t) > 8;
    else result := false
  end
end;

function UsePtrPassing(param: PSym): bool;
// this is pretty complicated ...
var
  pt: PType;
begin
  pt := param.typ;
  if (sfResult in param.flags) and not isInvalidReturnType(pt) then
    result := false  // BUGFIX
  else if pt.Kind = tyObject then begin
    // objects are always passed by reference,
    // otherwise implicit casting doesn't work
    result := true;
  end
  else if (pt.kind in [tyRecordConstr, tyRecord]) and
      ((getSize(pt) > platform.floatSize) or
        (optByRef in param.options)) then begin
    result := true;
  end
  else if isCArray(pt) then
    result := false
  else if (pt.kind = tyVar) or (getSize(pt) > platform.floatSize) then begin
    result := true;
  end
  else
    result := false
end;

const
  PointerTypes = {@set}[tySequence, tyString, tyRef, tyPtr, tyPointer];

procedure fillResult(param: PSym);
begin
  fillLoc(param.loc, locParam, param.typ,
          toRope('Result'), {@set}[lfOnUnknown]);
  if UsePtrPassing(param) then param.loc.indirect := 1
end;

procedure genProcParams(t: PType; out rettype, params: PRope);
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
    rettype := getTypeDesc(t.sons[0]);
  for i := 1 to sonsLen(t.n)-1 do begin
    assert(t.n.sons[i].kind = nkSym);
    param := t.n.sons[i].sym;
    fillLoc(param.loc, locParam, param.typ,
            con(toRope('Par'), toRope(i)), {@set}[lfOnStack]);
    if param.typ.kind = tyVar then begin
      param.loc.flags := {@set}[lfOnUnknown]; // BUGFIX!
      app(params, getTypeDesc(param.typ.sons[0]));
    end
    else
      app(params, getTypeDesc(param.typ));
    if UsePtrPassing(param) then begin
      app(params, '*'+'');
      param.loc.indirect := 1
    end;
    app(params, ' '+'');

    app(params, param.loc.r);
    // declare the len field for open arrays:
    arr := param.typ;
    if arr.kind = tyVar then arr := arr.sons[0];
    j := 0;
    while arr.Kind = tyOpenArray do begin // need to pass hidden parameter:
      appRopeFormat(params, ', const int $1Len$2', [param.loc.r, toRope(j)]);
      inc(j);
      arr := arr.sons[0]
    end;
    if i < sonsLen(t.n)-1 then app(params, ', ');
  end;
  if (t.sons[0] <> nil) and isInvalidReturnType(t.sons[0]) then begin
    if params <> nil then app(params, ', ');
    app(params, getTypeDesc(t.sons[0]));
    if not isCArray(t.sons[0]) then app(params, '*'+'');
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

function getLengthOfSet(s: PNode): int;
begin
  result := int(getSize(s.typ))
end;

function isImportedType(t: PType): bool;
begin
  result := (t.sym <> nil) and (sfImportc in t.sym.flags)
end;

function getTypeName(typ: PType): PRope;
begin
  if typ.sym <> nil then begin
    result := typ.sym.loc.r;
    if result = nil then begin
      assert(typ.owner <> nil);
      result := toRope(mangle(typ.owner.Name.s) + '_' +{&}
                       mangle(typ.sym.name.s));
    end
  end
  else begin
    // we must use a unique type id here because we don't store
    // whether a type has to be given a certain name because its
    // forward declaration has already been given:
    if typ.loc.r = nil then begin
      inc(currMod.unique);
      assert(typ.owner <> nil);
      typ.loc.r := ropeFormat('$1_Ty$2', [
        toRope(mangle(typ.owner.Name.s)),
        toRope(currMod.unique)])
    end;
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
    'NS', 'NS8', 'NS16', 'NS32', 'NS64', 'NF', 'NF32', 'NF64', 'NF128');
begin
  case typ.Kind of
    tyPointer: result := typeNameOrLiteral(typ, 'void*');
    tyEnum: begin
      if firstOrd(typ) < 0 then
        result := typeNameOrLiteral(typ, 'NS32')
      else begin
        case int(getSize(typ)) of
          1: result := typeNameOrLiteral(typ, 'NU8');
          2: result := typeNameOrLiteral(typ, 'NU16');
          4: result := typeNameOrLiteral(typ, 'NS32');
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

function getTypePre(typ: PType): PRope;
begin
  if typ = nil then
    result := toRope('void')
  else begin
    result := getSimpleTypeDesc(typ);
    if result = nil then
      result := CacheGetType(currMod.typeCache, typ)
  end
end;

function getForwardStructFormat(): string;
begin
  if gCmd = cmdCompileToCpp then result := 'struct $1;$n'
  else result := 'typedef struct $1 $1;$n'
end;

function getTypeForward(typ: PType): PRope;
begin
  result := CacheGetType(currMod.forwTypeCache, typ);
  if result <> nil then exit;
  result := getTypePre(typ);
  if result <> nil then exit;
  case typ.kind of
    tySequence, tyRecord, tyObject: begin
      result := getTypeName(typ);
      if not isImportedType(typ) then
        appRopeFormat(currMod.s[cfsForwardTypes],
          getForwardStructFormat(), [result]);
      IdTablePut(currMod.forwTypeCache, typ, result)
    end
    else
      InternalError('getTypeForward(' + typeKindToStr[typ.kind] + ')')
  end
end;

function mangleRecFieldName(field: PSym; rectype: PType): PRope;
begin
  if (rectype.sym <> nil)
  and ([sfImportc, sfExportc] * rectype.sym.flags <> []) then
    result := toRope(field.name.s)
  else
    result := toRope(mangle(field.name.s))
end;

function genRecordFieldsAux(n: PNode; accessExpr: PRope; rectype: PType): PRope;
var
  i: int;
  ae, uname, sname, a: PRope;
  m: PNode;
  field: PSym;
begin
  result := nil;
  case n.kind of
    nkRecList: begin
      for i := 0 to sonsLen(n)-1 do begin
        app(result, genRecordFieldsAux(n.sons[i], accessExpr, rectype));
      end
    end;
    nkRecCase: begin
      assert(n.sons[0].kind = nkSym);
      app(result, genRecordFieldsAux(n.sons[0], accessExpr, rectype));
      uname := toRope(mangle(n.sons[0].sym.name.s)+ 'U');
      if accessExpr <> nil then ae := ropeFormat('$1.$2', [accessExpr, uname])
      else ae := uname;
      app(result, 'union {'+tnl);
      for i := 1 to sonsLen(n)-1 do begin
        case n.sons[i].kind of
          nkOfBranch, nkElse: begin
            m := lastSon(n.sons[i]);
            if m.kind <> nkSym then begin
              sname := con('S'+'', toRope(i));
              a := genRecordFieldsAux(m, ropeFormat('$1.$2', [ae, sname]),
                                      rectype);
              if a <> nil then begin
                app(result, 'struct {');
                app(result, a);
                appRopeFormat(result, '} $1;$n', [sname]);
              end
            end
            else app(result, genRecordFieldsAux(m, ae, rectype));
          end;
          else internalError('genRecordFieldsAux(record case branch)');
        end;
      end;
      appRopeFormat(result, '} $1;$n', [uname])
    end;
    nkSym: begin
      field := n.sym;
      assert(field.ast = nil);
      sname := mangleRecFieldName(field, rectype);
      if accessExpr <> nil then ae := ropeFormat('$1.$2', [accessExpr, sname])
      else ae := sname;
      fillLoc(field.loc, locField, field.typ, ae, {@set}[]);
      appRopeFormat(result, '$1 $2;$n', [getTypeDesc(field.loc.t), sname])
    end;
    else internalError(n.info, 'genRecordFieldsAux()');
  end
end;

function getRecordFields(typ: PType): PRope;
begin
  result := genRecordFieldsAux(typ.n, nil, typ);
end;

function getRecordDesc(typ: PType; name: PRope): PRope;
var
  desc: PRope;
begin
  // declare the record:
  if typ.kind = tyObject then begin
    useMagic('TNimType');
    if typ.sons[0] = nil then begin
      if (typ.sym <> nil) and (sfPure in typ.sym.flags) then
        result := ropeFormat('struct $1 {$n', [name])
      else
        result := ropeFormat('struct $1 {$nTNimType* m_type;$n', [name])
    end
    else if gCmd = cmdCompileToCpp then
      result := ropeFormat('struct $1 : public $2 {$n',
        [name, getTypeDesc(typ.sons[0])])
    else
      result := ropeFormat('struct $1 {$n  $2 Sup;$n',
        [name, getTypeDesc(typ.sons[0])])
  end
  else
    result := ropeFormat('struct $1 {$n', [name]);
  desc := getRecordFields(typ);
  if (typ.kind <> tyObject) and (desc = nil) and (gCmd <> cmdCompileToCpp) then
  // no fields in struct are not valid in C, so generate a dummy:
    appRopeFormat(result, 'char dummy;$n', [])
  else
    app(result, desc);
  app(result, '};' + tnl);
end;

function getTypeDesc(typ: PType): PRope;
// returns only the type's name
var
  name, rettype, desc, recdesc: PRope;
  n: biggestInt;
begin
  if typ.sym <> nil then useHeader(typ.sym);
  result := getTypePre(typ);
  if result <> nil then exit;
  case typ.Kind of
    tyRef, tyPtr, tyVar, tyOpenArray: begin
      case typ.sons[0].Kind of
        tyRecord, tyObject, tySequence: begin
          // no restriction!
          // We have a forward declaration for structs
          name := getTypeForward(typ.sons[0]);
          result := con(name, '*'+'');
          IdTablePut(currMod.typeCache, typ, result)
        end;
        else begin
          // else we have a strong dependency  :-(
          result := con(getTypeDesc(typ.sons[0]), '*'+'');
          IdTablePut(currMod.typeCache, typ, result)
        end
      end
    end;
    tyProc: begin
      result := getTypeName(typ);
      IdTablePut(currMod.typeCache, typ, result);
      genProcParams(typ, rettype, desc);
      if not isImportedType(typ) then begin
        if typ.callConv <> ccClosure then
          appRopeFormat(currMod.s[cfsTypes], 'typedef $1_PTR($2, $3) $4;$n',
            [toRope(CallingConvToStr[typ.callConv]), rettype, result, desc])
        else // procedure vars may need a closure!
          appRopeFormat(currMod.s[cfsTypes], 'typedef struct $1 {$n' +
                                             'N_CDECL_PTR($2, PrcPart) $3;$n' +
                                             'void* ClPart;$n};$n',
            [result, rettype, desc]);
      end
    end;
    tySequence: begin
      // we cannot use getTypeForward here because then typ would be associated
      // with the name of the struct, not with the pointer to the struct:
      result := getTypeName(typ);
      IdTablePut(currMod.typeCache, typ, con(result, '*'+''));
      if not isImportedType(typ) then begin
        appRopeFormat(currMod.s[cfsForwardTypes],
          getForwardStructFormat(), [result]);
        appRopeFormat(currMod.s[cfsSeqTypes],
          // BUGFIX: needed to introduce cfsSeqTypes
          'struct $2 {$n' +
          '  NS len, space;$n' +
          '  $1 data[SEQ_DECL_SIZE];$n' +
          '};$n', [getTypeDesc(typ.sons[0]), result]);
      end;
      app(result, '*'+'');
    end;
    tyArrayConstr, tyArray: begin
      n := lengthOrd(typ);
      if n <= 0 then n := 1; // make an array of at least one element
      result := getTypeName(typ);
      IdTablePut(currMod.typeCache, typ, result);
      if not isImportedType(typ) then
        appRopeFormat(currMod.s[cfsTypes], 'typedef $1 $2[$3];$n',
          [getTypeDesc(typ.sons[1]), result, ToRope(n)])
    end;
    tyObject, tyRecord, tyRecordConstr: begin
      result := getTypeName(typ);
      IdTablePut(currMod.typeCache, typ, result);
      recdesc := getRecordDesc(typ, result); // always compute for sideeffects
      if not isImportedType(typ) then
        app(currMod.s[cfsTypes], recdesc);
      if CacheGetType(currMod.forwTypeCache, typ) = nil then begin
        if not isImportedType(typ) then
          appRopeFormat(currMod.s[cfsForwardTypes],
            getForwardStructFormat(), [result]);
        IdTablePut(currMod.forwTypeCache, typ, result)
      end
    end;
    tySet: begin
      case int(getSize(typ)) of
        1: result := toRope('NS8');
        2: result := toRope('NS16');
        4: result := toRope('NS32');
        8: result := toRope('NS64');
        else begin
          result := getTypeName(typ);
          IdTablePut(currMod.typeCache, typ, result);
          if not isImportedType(typ) then
            appRopeFormat(currMod.s[cfsTypes], 'typedef NS8 $1[$2];$n',
              [result, toRope(getSize(typ))])
        end
      end
    end
    else begin
      InternalError('getTypeDesc(' + typeKindToStr[typ.kind] + ')');
      result := nil
    end
  end
end;

function genProcHeader(prc: PSym): PRope;
var
  rettype, params: PRope;
begin
  // using static is needed for inline procs
  if (prc.typ.callConv = ccInline) then
    result := toRope('static ')
  else
    result := nil;
  fillLoc(prc.loc, locProc, prc.typ, mangleName(prc), {@set}[]);
  genProcParams(prc.typ, rettype, params);
  appRopeFormat(result, '$1($2, $3)$4',
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
  appRopeFormat(m.s[cfsTypeInit1], 'static TNimType $1;$n', [tmp]);
  appRopeFormat(m.s[cfsTypeInit2], '$2 = &$1;$n', [tmp, name]);
end;

procedure genTypeInfoAuxBase(m: BModule; typ: PType; name, base: PRope);
begin
  allocMemTI(m, name);
  appRopeFormat(m.s[cfsTypeInit3],
    '$1->size = sizeof($2);$n' +
    '$1->kind = $3;$n' +
    '$1->base = $4;$n', [
    name, getTypeDesc(typ), toRope(ord(typ.kind)), base]);
  appRopeFormat(m.s[cfsVars], 'TNimType* $1;$n', [name]);
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
        appRopeFormat(m.s[cfsTypeInit1], 'static TNimNode* $1[$2];$n',
                                         [tmp, toRope(len)]);
        for i := 0 to len-1 do begin
          tmp2 := getTempName();
          appRopeFormat(m.s[cfsTypeInit1], 'static TNimNode $1;$n', [tmp2]);
          appRopeFormat(m.s[cfsTypeInit3], '$1[$2] = &$3;$n',
                        [tmp, toRope(i), tmp2]);
          genObjectFields(m, typ, n.sons[i], tmp2);
        end;
        appRopeFormat(m.s[cfsTypeInit3],
          '$1.len = $2; $1.kind = 2; $1.sons = &$3;$n', [
          expr, toRope(len), tmp]);
      end
      else
        appRopeFormat(m.s[cfsTypeInit3],
          '$1.len = $2; $1.kind = 2;$n', [expr, toRope(len)]);
    end;
    nkRecCase: begin
      len := sonsLen(n);
      assert(n.sons[0].kind = nkSym);
      field := n.sons[0].sym;
      tmp := getTempName();
      appRopeFormat(m.s[cfsTypeInit3], '$1.kind = 3;$n' +
                                       '$1.offset = offsetof($2, $3);$n' +
                                       '$1.typ = $4;$n' +
                                       '$1.name = $5;$n' +
                                       '$1.sons = &$6;$n' +
                                       '$1.len = $7;$n',
            [expr, getTypeDesc(typ), field.loc.r,
             genTypeInfo(m, field.typ),
             makeCString(field.name.s), tmp,
             toRope(lengthOrd(field.typ))]);
      appRopeFormat(m.s[cfsTypeInit1], 'static TNimNode* $1[$2];$n',
                                       [tmp, toRope(lengthOrd(field.typ)+1)]);
      for i := 1 to len-1 do begin
        b := n.sons[i]; // branch
        tmp2 := getTempName();
        appRopeFormat(m.s[cfsTypeInit1], 'static TNimNode $1;$n', [tmp2]);
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
                  appRopeFormat(m.s[cfsTypeInit3], '$1[$2] = &$3;$n',
                                [tmp, toRope(x), tmp2]);
                  inc(x);
                end;
              end
              else
                appRopeFormat(m.s[cfsTypeInit3], '$1[$2] = &$3;$n',
                             [tmp, toRope(getOrdValue(b.sons[j])), tmp2])
            end
          end;
          nkElse: begin
            appRopeFormat(m.s[cfsTypeInit3], '$1[$2] = &$3;$n',
                          [tmp, toRope(lengthOrd(field.typ)), tmp2]);
          end
          else
            internalError(n.info, 'genObjectFields(nkRecCase)');
        end
      end
    end;
    nkSym: begin
      field := n.sym;
      appRopeFormat(m.s[cfsTypeInit3], '$1.kind = 1;$n' +
                                       '$1.offset = offsetof($2, $3);$n' +
                                       '$1.typ = $4;$n' +
                                       '$1.name = $5;$n',
                                       [expr, getTypeDesc(typ), field.loc.r,
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
  genTypeInfoAux(m, typ, name);
  tmp := getTempName();
  appRopeFormat(m.s[cfsTypeInit1], 'static TNimNode $1;$n', [tmp]);
  genObjectFields(m, typ, typ.n, tmp);
  appRopeFormat(m.s[cfsTypeInit3], '$1->node = &$2;$n', [name, tmp]);
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
  appRopeFormat(m.s[cfsTypeInit1], 'static TNimNode* $1[$2];$n' +
                                   'static TNimNode $3;$n',
                                   [tmp, toRope(len), tmp2]);
  for i := 0 to len-1 do begin
    assert(typ.n.sons[i].kind = nkSym);
    field := typ.n.sons[i].sym;
    tmp3 := getTempName();
    appRopeFormat(m.s[cfsTypeInit1], 'static TNimNode $1;$n', [tmp3]);
    appRopeFormat(m.s[cfsTypeInit3], '$1[$2] = &$3;$n' +
                                     '$3.kind = 1;$n' +
                                     '$3.offset = $4;$n' +
                                     '$3.typ = $5;$n' +
                                     '$3.name = $6;$n',
                  [tmp, toRope(i), tmp3,
                   toRope(field.position),
                   name, makeCString(field.name.s)]);
  end;
  appRopeFormat(m.s[cfsTypeInit3],
    '$1.len = $2; $1.kind = 2; $1.sons = &$3;$n$4->node = &$1;$n', [
    tmp2, toRope(len), tmp, name]);
end;

procedure genSetInfo(m: BModule; typ: PType; name: PRope);
var
  tmp: PRope;
begin
  assert(typ.sons[0] <> nil);
  genTypeInfoAux(m, typ, name);
  tmp := getTempName();
  appRopeFormat(m.s[cfsTypeInit1], 'static TNimNode $1;$n', [tmp]);
  appRopeFormat(m.s[cfsTypeInit3],
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
  t := typ;
  if t.kind = tyGenericInst then t := lastSon(t);
  result := ropeFormat('NTI$1', [toRope(t.id)]);
  if not IntSetContainsOrIncl(m.typeInfoMarker, t.id) then begin
    // declare type information structures:
    useMagic('TNimType');
    useMagic('TNimNode');
    appRopeFormat(m.s[cfsVars], 'extern TNimType* $1;$n', [result]);
  end;
  if IntSetContainsOrIncl(gTypeInfoGenerated, t.id) then exit;
  case t.kind of
    tyPointer, tyProc, tyBool, tyChar, tyCString, tyString, tyInt..tyFloat128:
      genTypeInfoAuxBase(m, t, result, toRope('0'+''));
    tyRef, tyPtr, tySequence, tyRange: genTypeInfoAux(m, t, result);
    tyArrayConstr, tyArray: genArrayInfo(m, t, result);
    tySet: genSetInfo(m, t, result);
    tyEnum: genEnumInfo(m, t, result);
    tyObject, tyRecord, tyRecordConstr: genObjectInfo(m, t, result);
    tyVar: result := genTypeInfo(m, typ.sons[0]);
    else InternalError('genTypeInfo(' + typekindToStr[t.kind] + ')');
  end
end;
