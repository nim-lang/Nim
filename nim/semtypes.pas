//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// this module does the semantic checking of type declarations

function fitNode(c: PContext; formal: PType; arg: PNode): PNode;
begin
  result := IndexTypesMatch(c, formal, arg.typ, arg);
  if result = nil then typeMismatch(arg, formal, arg.typ);
end;

function newOrPrevType(kind: TTypeKind; prev: PType; c: PContext): PType;
begin
  if prev = nil then
    result := newTypeS(kind, c)
  else begin
    result := prev;
    if result.kind = tyForward then result.kind := kind
  end
end;

function semEnum(c: PContext; n: PNode; prev: PType): PType;
var
  i: int;
  counter, x: BiggestInt;
  e: PSym;
  base: PType;
  v: PNode;
begin
  counter := 0;
  base := nil;
  result := newOrPrevType(tyEnum, prev, c);
  result.n := newNodeI(nkEnumTy, n.info);
  checkMinSonsLen(n, 1);
  if n.sons[0] <> nil then begin
    base := semTypeNode(c, n.sons[0].sons[0], nil);
    if base.kind <> tyEnum then
      liMessage(n.sons[0].info, errInheritanceOnlyWithEnums);
    counter := lastOrd(base)+1;
  end;
  addSon(result, base);
  for i := 1 to sonsLen(n)-1 do begin
    case n.sons[i].kind of
      nkEnumFieldDef: begin
        e := newSymS(skEnumField, n.sons[i].sons[0], c);
        v := semConstExpr(c, n.sons[i].sons[1]);
        x := getOrdValue(v);
        if i <> 1 then begin
          if (x <> counter) then
            include(result.flags, tfEnumHasWholes);
          if x < counter then
            liMessage(n.sons[i].info, errInvalidOrderInEnumX, e.name.s);
        end;
        counter := x;
      end;
      nkSym: e := n.sons[i].sym;
      nkIdent: begin
        e := newSymS(skEnumField, n.sons[i], c);
      end;
      else
        illFormedAst(n);
    end;
    e.typ := result;
    e.position := int(counter);
    if (result.sym <> nil) and (sfInInterface in result.sym.flags) then begin
      include(e.flags, sfUsed); // BUGFIX
      include(e.flags, sfInInterface); // BUGFIX
      StrTableAdd(c.module.tab, e); // BUGFIX
    end;
    addSon(result.n, newSymNode(e));
    addDeclAt(c, e, c.tab.tos-1);
    inc(counter);
  end;
end;

function semSet(c: PContext; n: PNode; prev: PType): PType;
var
  base: PType;
begin
  result := newOrPrevType(tySet, prev, c);
  if sonsLen(n) = 2 then begin
    base := semTypeNode(c, n.sons[1], nil);
    addSon(result, base);
    if base.kind = tyGenericInst then base := lastSon(base);
    if base.kind <> tyGenericParam then begin
      if not isOrdinalType(base) then liMessage(n.info, errOrdinalTypeExpected);
      if lengthOrd(base) > MaxSetElements then liMessage(n.info, errSetTooBig);
    end
  end
  else
    liMessage(n.info, errXExpectsOneTypeParam, 'set');
end;

function semContainer(c: PContext; n: PNode;
                      kind: TTypeKind; const kindStr: string;
                      prev: PType): PType;
var
  base: PType;
begin
  result := newOrPrevType(kind, prev, c);
  if sonsLen(n) = 2 then begin
    base := semTypeNode(c, n.sons[1], nil);
    addSon(result, base);
  end
  else
    liMessage(n.info, errXExpectsOneTypeParam, kindStr);
end;

function semAnyRef(c: PContext; n: PNode;
                   kind: TTypeKind; const kindStr: string; prev: PType): PType;
var
  base: PType;
begin
  result := newOrPrevType(kind, prev, c);
  if sonsLen(n) = 1 then begin
    base := semTypeNode(c, n.sons[0], nil);
    addSon(result, base);
  end
  else
    liMessage(n.info, errXExpectsOneTypeParam, kindStr);
end;

function semVarType(c: PContext; n: PNode; prev: PType): PType;
var
  base: PType;
begin
  result := newOrPrevType(tyVar, prev, c);
  if sonsLen(n) = 1 then begin
    base := semTypeNode(c, n.sons[0], nil);
    if base.kind = tyVar then liMessage(n.info, errVarVarTypeNotAllowed);
    addSon(result, base);
  end
  else
    liMessage(n.info, errXExpectsOneTypeParam, 'var');
end;

function semDistinct(c: PContext; n: PNode; prev: PType): PType;
begin
  result := newOrPrevType(tyDistinct, prev, c);
  if sonsLen(n) = 1 then 
    addSon(result, semTypeNode(c, n.sons[0], nil))
  else
    liMessage(n.info, errXExpectsOneTypeParam, 'distinct');
end;

function semRangeAux(c: PContext; n: PNode; prev: PType): PType;
var
  a, b: PNode;
begin
  if (n.kind <> nkRange) then InternalError(n.info, 'semRangeAux');
  checkSonsLen(n, 2);
  result := newOrPrevType(tyRange, prev, c);
  result.n := newNodeI(nkRange, n.info);
  if (n.sons[0] = nil) or (n.sons[1] = nil) then
    liMessage(n.Info, errRangeIsEmpty);
  a := semConstExpr(c, n.sons[0]);
  b := semConstExpr(c, n.sons[1]);
  if not sameType(a.typ, b.typ) then
    liMessage(n.info, errPureTypeMismatch);
  if not (a.typ.kind in [tyInt..tyInt64, tyEnum, tyBool, tyChar,
                         tyFloat..tyFloat128]) then
    liMessage(n.info, errOrdinalTypeExpected);
  if enumHasWholes(a.typ) then
    liMessage(n.info, errEnumXHasWholes, a.typ.sym.name.s);
  if not leValue(a, b) then 
    liMessage(n.Info, errRangeIsEmpty);
  addSon(result.n, a);
  addSon(result.n, b);
  addSon(result, b.typ);
end;

function semRange(c: PContext; n: PNode; prev: PType): PType;
begin
  result := nil;
  if sonsLen(n) = 2 then begin
    if n.sons[1].kind = nkRange then
      result := semRangeAux(c, n.sons[1], prev)
    else
      liMessage(n.sons[0].info, errRangeExpected);
  end
  else
    liMessage(n.info, errXExpectsOneTypeParam, 'range');
end;

function semArray(c: PContext; n: PNode; prev: PType): PType;
var
  indx, base: PType;
begin
  result := newOrPrevType(tyArray, prev, c);
  if sonsLen(n) = 3 then begin // 3 = length(array indx base)
    if n.sons[1].kind = nkRange then indx := semRangeAux(c, n.sons[1], nil)
    else indx := semTypeNode(c, n.sons[1], nil);
    addSon(result, indx);
    if indx.kind = tyGenericInst then indx := lastSon(indx);
    if indx.kind <> tyGenericParam then begin
      if not isOrdinalType(indx) then
        liMessage(n.sons[1].info, errOrdinalTypeExpected);
      if enumHasWholes(indx) then
        liMessage(n.sons[1].info, errEnumXHasWholes, indx.sym.name.s);
    end;
    base := semTypeNode(c, n.sons[2], nil);
    addSon(result, base);
  end
  else
    liMessage(n.info, errArrayExpectsTwoTypeParams);
end;

function semOrdinal(c: PContext; n: PNode; prev: PType): PType;
var
  base: PType;
begin
  result := newOrPrevType(tyOrdinal, prev, c);
  if sonsLen(n) = 2 then begin
    base := semTypeNode(c, n.sons[1], nil);
    if base.kind <> tyGenericParam then begin
      if not isOrdinalType(base) then
        liMessage(n.sons[1].info, errOrdinalTypeExpected);
    end;
    addSon(result, base);
  end
  else
    liMessage(n.info, errXExpectsOneTypeParam, 'ordinal');
end;

function semTypeIdent(c: PContext; n: PNode): PSym;
begin
  result := qualifiedLookup(c, n, true);
  if (result <> nil) then begin
    markUsed(n, result);
    if result.kind <> skType then liMessage(n.info, errTypeExpected);
  end
  else
    liMessage(n.info, errIdentifierExpected);
end;

function semTuple(c: PContext; n: PNode; prev: PType): PType;
var
  i, j, len, counter: int;
  typ: PType;
  check: TIntSet;
  a: PNode;
  field: PSym;
begin
  result := newOrPrevType(tyTuple, prev, c);
  result.n := newNodeI(nkRecList, n.info);
  IntSetInit(check);
  counter := 0;
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if (a.kind <> nkIdentDefs) then IllFormedAst(a);
    checkMinSonsLen(a, 3);
    len := sonsLen(a);
    if a.sons[len-2] <> nil then
      typ := semTypeNode(c, a.sons[len-2], nil)
    else
      liMessage(a.info, errTypeExpected);
    if a.sons[len-1] <> nil then
      liMessage(a.sons[len-1].info, errInitHereNotAllowed);
    for j := 0 to len-3 do begin
      field := newSymS(skField, a.sons[j], c);
      field.typ := typ;
      field.position := counter;
      inc(counter);
      if IntSetContainsOrIncl(check, field.name.id) then
        liMessage(a.sons[j].info, errAttemptToRedefine, field.name.s);
      addSon(result.n, newSymNode(field));
      addSon(result, typ);
    end
  end
end;

function semGeneric(c: PContext; n: PNode; s: PSym; prev: PType): PType;
var
  i: int;
  elem: PType;
  isConcrete: bool;
begin
  if (s.typ = nil) or (s.typ.kind <> tyGenericBody) then
    liMessage(n.info, errCannotInstantiateX, s.name.s);
  result := newOrPrevType(tyGenericInvokation, prev, c);
  if (s.typ.containerID = 0) then InternalError(n.info, 'semtypes.semGeneric');
  if sonsLen(n) <> sonsLen(s.typ) then 
    liMessage(n.info, errWrongNumberOfArguments);
  addSon(result, s.typ);
  isConcrete := true;
  // iterate over arguments:
  for i := 1 to sonsLen(n)-1 do begin
    elem := semTypeNode(c, n.sons[i], nil);
    if elem.kind = tyGenericParam then isConcrete := false;
    addSon(result, elem);
  end;
  if isConcrete then begin
    if s.ast = nil then liMessage(n.info, errCannotInstantiateX, s.name.s);
    result := instGenericContainer(c, n, result);
  end
end;

function semIdentVis(c: PContext; kind: TSymKind; n: PNode;
                     const allowed: TSymFlags): PSym;
// identifier with visibility
var
  v: PIdent;
begin
  result := nil;
  if n.kind = nkPostfix then begin
    if (sonsLen(n) = 2) and (n.sons[0].kind = nkIdent) then begin
      result := newSymS(kind, n.sons[1], c);
      v := n.sons[0].ident;
      if (sfStar in allowed) and (v.id = ord(wStar)) then
        include(result.flags, sfStar)
      else if (sfMinus in allowed) and (v.id = ord(wMinus)) then
        include(result.flags, sfMinus)
      else
        liMessage(n.sons[0].info, errInvalidVisibilityX, v.s);
    end
    else
      illFormedAst(n);
  end
  else
    result := newSymS(kind, n, c);
end;

function semIdentWithPragma(c: PContext; kind: TSymKind;
                            n: PNode; const allowed: TSymFlags): PSym;
begin
  if n.kind = nkPragmaExpr then begin
    checkSonsLen(n, 2);
    result := semIdentVis(c, kind, n.sons[0], allowed);
    case kind of
      skType: begin
        // process pragmas later, because result.typ has not been set yet
      end;
      skField: pragma(c, result, n.sons[1], fieldPragmas);
      skVar: pragma(c, result, n.sons[1], varPragmas);
      skConst: pragma(c, result, n.sons[1], constPragmas);
      else begin end
    end
  end
  else
    result := semIdentVis(c, kind, n, allowed);
end;

procedure checkForOverlap(c: PContext; t, ex: PNode; branchIndex: int);
var
  j, i: int;
begin
  for i := 1 to branchIndex-1 do
    for j := 0 to sonsLen(t.sons[i])-2 do
      if overlap(t.sons[i].sons[j], ex) then begin
        //MessageOut(renderTree(t));
        liMessage(ex.info, errDuplicateCaseLabel);
      end
end;

procedure semBranchExpr(c: PContext; t: PNode; var ex: PNode);
begin
  ex := semConstExpr(c, ex);
  checkMinSonsLen(t, 1);
  if (cmpTypes(t.sons[0].typ, ex.typ) <= isConvertible) then begin
    typeMismatch(ex, t.sons[0].typ, ex.typ);
  end;
end;

procedure SemCaseBranch(c: PContext; t, branch: PNode;
                        branchIndex: int; var covered: biggestInt);
var
  i: int;
  b: PNode;
begin
  for i := 0 to sonsLen(branch)-2 do begin
    b := branch.sons[i];
    if b.kind = nkRange then begin
      checkSonsLen(b, 2);
      semBranchExpr(c, t, b.sons[0]);
      semBranchExpr(c, t, b.sons[1]);
      if emptyRange(b.sons[0], b.sons[1]) then begin
        //MessageOut(renderTree(t));
        liMessage(b.info, errRangeIsEmpty);
      end;
      covered := covered + getOrdValue(b.sons[1]) - getOrdValue(b.sons[0]) + 1;
    end
    else begin
      semBranchExpr(c, t, branch.sons[i]); // NOT: `b`, because of var-param!
      inc(covered);
    end;
    checkForOverlap(c, t, branch.sons[i], branchIndex)
  end
end;

procedure semRecordNodeAux(c: PContext; n: PNode;
                           var check: TIntSet;
                           var pos: int; father: PNode;
                           rectype: PSym); forward;

procedure semRecordCase(c: PContext; n: PNode;
                        var check: TIntSet;
                        var pos: int; father: PNode; rectype: PSym);
var
  i: int;
  covered: biggestint;
  chckCovered: boolean;
  a, b: PNode;
  typ: PType;
begin
  a := copyNode(n);
  checkMinSonsLen(n, 2);
  semRecordNodeAux(c, n.sons[0], check, pos, a, rectype);
  if a.sons[0].kind <> nkSym then
    internalError('semRecordCase: dicriminant is no symbol');
  include(a.sons[0].sym.flags, sfDiscriminant);
  covered := 0;
  typ := skipTypes(a.sons[0].Typ, abstractVar);
  if not isOrdinalType(typ) then
    liMessage(n.info, errSelectorMustBeOrdinal);
  if firstOrd(typ) < 0 then
    liMessage(n.info, errOrdXMustNotBeNegative, a.sons[0].sym.name.s);
  if lengthOrd(typ) > $7fff then
    liMessage(n.info, errLenXinvalid, a.sons[0].sym.name.s);
  chckCovered := true;
  for i := 1 to sonsLen(n)-1 do begin
    b := copyTree(n.sons[i]);
    case n.sons[i].kind of
      nkOfBranch: begin
        checkMinSonsLen(b, 2);
        semCaseBranch(c, a, b, i, covered);
      end;
      nkElse: begin
        chckCovered := false;
        checkSonsLen(b, 1);
      end;
      else illFormedAst(n);
    end;
    delSon(b, sonsLen(b)-1);
    semRecordNodeAux(c, lastSon(n.sons[i]), check, pos, b, rectype);
    addSon(a, b);
  end;
  if chckCovered and (covered <> lengthOrd(a.sons[0].typ)) then
    liMessage(a.info, errNotAllCasesCovered);
  addSon(father, a);
end;

procedure semRecordNodeAux(c: PContext; n: PNode; var check: TIntSet;
                           var pos: int; father: PNode; rectype: PSym);
var
  i, len: int;
  f: PSym; // new field
  a, it, e, branch: PNode;
  typ: PType;
begin
  if n = nil then exit; // BUGFIX: nil is possible
  case n.kind of
    nkRecWhen: begin
      branch := nil; // the branch to take
      for i := 0 to sonsLen(n)-1 do begin
        it := n.sons[i];
        if it = nil then illFormedAst(n);
        case it.kind of
          nkElifBranch: begin
            checkSonsLen(it, 2);
            e := semConstExpr(c, it.sons[0]);
            checkBool(e);
            if (e.kind <> nkIntLit) then
              InternalError(e.info, 'semRecordNodeAux');
            if (e.intVal <> 0) and (branch = nil) then
              branch := it.sons[1]
          end;
          nkElse: begin
            checkSonsLen(it, 1);
            if branch = nil then branch := it.sons[0];
          end;
          else illFormedAst(n)
        end
      end;
      if branch <> nil then
        semRecordNodeAux(c, branch, check, pos, father, rectype);
    end;
    nkRecCase: begin
      semRecordCase(c, n, check, pos, father, rectype);
    end;
    nkNilLit: begin
      if father.kind <> nkRecList then
        addSon(father, newNodeI(nkRecList, n.info));
    end;
    nkRecList: begin
      // attempt to keep the nesting at a sane level:
      if father.kind = nkRecList then a := father
      else a := copyNode(n);
      for i := 0 to sonsLen(n)-1 do begin
        semRecordNodeAux(c, n.sons[i], check, pos, a, rectype);
      end;
      if a <> father then addSon(father, a);
    end;
    nkIdentDefs: begin
      checkMinSonsLen(n, 3);
      len := sonsLen(n);
      if (father.kind <> nkRecList) and (len >= 4) then 
        a := newNodeI(nkRecList, n.info)
      else 
        a := nil;
      if n.sons[len-1] <> nil then
        liMessage(n.sons[len-1].info, errInitHereNotAllowed);
      if n.sons[len-2] = nil then
        liMessage(n.info, errTypeExpected);
      typ := semTypeNode(c, n.sons[len-2], nil);
      for i := 0 to sonsLen(n)-3 do begin
        f := semIdentWithPragma(c, skField, n.sons[i], {@set}[sfStar, sfMinus]);
        f.typ := typ;
        f.position := pos;
        if (rectype <> nil)
        and ([sfImportc, sfExportc] * rectype.flags <> [])
        and (f.loc.r = nil) then begin
          f.loc.r := toRope(f.name.s);
          f.flags := f.flags + ([sfImportc, sfExportc] * rectype.flags);
        end;
        inc(pos);
        if IntSetContainsOrIncl(check, f.name.id) then
          liMessage(n.sons[i].info, errAttemptToRedefine, f.name.s);
        if a = nil then addSon(father, newSymNode(f))
        else addSon(a, newSymNode(f))
      end;
      if a <> nil then addSon(father, a);
    end;
    else illFormedAst(n);
  end
end;

procedure addInheritedFieldsAux(c: PContext; var check: TIntSet;
                                var pos: int; n: PNode);
var
  i: int;
begin
  case n.kind of
    nkRecCase: begin
      if (n.sons[0].kind <> nkSym) then
        InternalError(n.info, 'addInheritedFieldsAux');
      addInheritedFieldsAux(c, check, pos, n.sons[0]);
      for i := 1 to sonsLen(n)-1 do begin
        case n.sons[i].kind of
          nkOfBranch, nkElse: begin
            addInheritedFieldsAux(c, check, pos, lastSon(n.sons[i]));
          end;
          else internalError(n.info,
                             'addInheritedFieldsAux(record case branch)');
        end
      end;
    end;
    nkRecList: begin
      for i := 0 to sonsLen(n)-1 do begin
        addInheritedFieldsAux(c, check, pos, n.sons[i]);
      end;
    end;
    nkSym: begin
      IntSetIncl(check, n.sym.name.id);
      inc(pos);
    end;
    else
      InternalError(n.info, 'addInheritedFieldsAux()');
  end;
end;

procedure addInheritedFields(c: PContext; var check: TIntSet; var pos: int;
                             obj: PType);
begin
  if (sonsLen(obj) > 0) and (obj.sons[0] <> nil) then
    addInheritedFields(c, check, pos, obj.sons[0]);
  addInheritedFieldsAux(c, check, pos, obj.n);
end;

function semObjectNode(c: PContext; n: PNode; prev: PType): PType;
var
  check: TIntSet;
  base: PType;
  pos: int;
begin
  IntSetInit(check);
  pos := 0;
  // n.sons[0] contains the pragmas (if any). We process these later...
  checkSonsLen(n, 3);
  if n.sons[1] <> nil then begin
    base := semTypeNode(c, n.sons[1].sons[0], nil);
    if base.kind = tyObject then
      addInheritedFields(c, check, pos, base)
    else
      liMessage(n.sons[1].info, errInheritanceOnlyWithNonFinalObjects);
  end
  else
    base := nil;
  if n.kind <> nkObjectTy then InternalError(n.info, 'semObjectNode');
  result := newOrPrevType(tyObject, prev, c);
  addSon(result, base);
  result.n := newNodeI(nkRecList, n.info);
  semRecordNodeAux(c, n.sons[2], check, pos, result.n, result.sym);
  if (base <> nil) and (tfFinal in base.flags) then
    liMessage(n.sons[1].info, errInheritanceOnlyWithNonFinalObjects);
end;

function addTypeVarsOfGenericBody(c: PContext; t: PType; genericParams: PNode;
                                  var cl: TIntSet): PType;
var
  i, L: int;
  s: PSym;
begin
  result := t;
  if (t = nil) then exit;
  if IntSetContainsOrIncl(cl, t.id) then exit;
  case t.kind of
    tyGenericBody: begin
      result := newTypeS(tyGenericInvokation, c);
      addSon(result, t);
      for i := 0 to sonsLen(t)-2 do begin
        if t.sons[i].kind <> tyGenericParam then
          InternalError('addTypeVarsOfGenericBody');
        s := copySym(t.sons[i].sym);
        s.position := sonsLen(genericParams);
        addDecl(c, s);
        addSon(genericParams, newSymNode(s));
        addSon(result, t.sons[i]);
      end;
    end;
    tyGenericInst: begin
      L := sonsLen(t)-1;
      t.sons[L] := addTypeVarsOfGenericBody(c, t.sons[L], genericParams, cl);
    end;
    tyGenericInvokation: begin
      for i := 1 to sonsLen(t)-1 do
        t.sons[i] := addTypeVarsOfGenericBody(c, t.sons[i], genericParams, cl);
    end
    else begin
      for i := 0 to sonsLen(t)-1 do
        t.sons[i] := addTypeVarsOfGenericBody(c, t.sons[i], genericParams, cl);
    end
  end
end;

function paramType(c: PContext; n, genericParams: PNode;
                   var cl: TIntSet): PType;
begin
  result := semTypeNode(c, n, nil);
  if (genericParams <> nil) and (sonsLen(genericParams) = 0) then 
    result := addTypeVarsOfGenericBody(c, result, genericParams, cl);
end;

function semProcTypeNode(c: PContext; n, genericParams: PNode;
                         prev: PType): PType;
var
  i, j, len, counter: int;
  a, def, res: PNode;
  typ: PType;
  arg: PSym;
  check, cl: TIntSet;
begin
  checkMinSonsLen(n, 1);
  result := newOrPrevType(tyProc, prev, c);
  result.callConv := lastOptionEntry(c).defaultCC;
  result.n := newNodeI(nkFormalParams, n.info);
  if (genericParams <> nil) and (sonsLen(genericParams) = 0) then
    IntSetInit(cl);
  if n.sons[0] = nil then begin
    addSon(result, nil); // return type
    addSon(result.n, newNodeI(nkType, n.info)); // BUGFIX: nkType must exist!
    // XXX but it does not, if n.sons[paramsPos] == nil?
  end
  else begin
    addSon(result, nil);
    res := newNodeI(nkType, n.info);
    addSon(result.n, res);
  end;
  IntSetInit(check);
  counter := 0;
  for i := 1 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if (a.kind <> nkIdentDefs) then IllFormedAst(a);
    checkMinSonsLen(a, 3);
    len := sonsLen(a);
    if a.sons[len-2] <> nil then
      typ := paramType(c, a.sons[len-2], genericParams, cl)
    else
      typ := nil;
    if a.sons[len-1] <> nil then begin
      def := semExprWithType(c, a.sons[len-1]);
      // check type compability between def.typ and typ:
      if (typ <> nil) then begin
        if (cmpTypes(typ, def.typ) < isConvertible) then begin
          typeMismatch(a.sons[len-1], typ, def.typ);
        end;
        def := fitNode(c, typ, def);
      end
      else typ := def.typ;
    end
    else
      def := nil;
    for j := 0 to len-3 do begin
      arg := newSymS(skParam, a.sons[j], c);
      arg.typ := typ;
      arg.position := counter;
      inc(counter);
      arg.ast := copyTree(def);
      if IntSetContainsOrIncl(check, arg.name.id) then
        liMessage(a.sons[j].info, errAttemptToRedefine, arg.name.s);
      addSon(result.n, newSymNode(arg));
      addSon(result, typ);
    end
  end;
  // NOTE: semantic checking of the result type needs to be done here!
  if n.sons[0] <> nil then begin
    result.sons[0] := paramType(c, n.sons[0], genericParams, cl);
    res.typ := result.sons[0];
  end
end;

function semStmtListType(c: PContext; n: PNode; prev: PType): PType;
var
  len, i: int;
begin
  checkMinSonsLen(n, 1);
  len := sonsLen(n);
  for i := 0 to len-2 do begin
    n.sons[i] := semStmt(c, n.sons[i]);
  end;
  if len > 0 then begin
    result := semTypeNode(c, n.sons[len-1], prev);
    n.typ := result;
    n.sons[len-1].typ := result
  end
  else
    result := nil;
end;

function semBlockType(c: PContext; n: PNode; prev: PType): PType;
begin
  Inc(c.p.nestedBlockCounter);
  checkSonsLen(n, 2);
  openScope(c.tab);
  if n.sons[0] <> nil then begin
    addDecl(c, newSymS(skLabel, n.sons[0], c))
  end;
  result := semStmtListType(c, n.sons[1], prev);
  n.sons[1].typ := result;
  n.typ := result;
  closeScope(c.tab);
  Dec(c.p.nestedBlockCounter);
end;

function semTypeNode(c: PContext; n: PNode; prev: PType): PType;
var
  s: PSym;
  t: PType;
begin
  result := nil;
  if n = nil then exit;
  case n.kind of
    nkTypeOfExpr: begin
      result := semExprWithType(c, n, {@set}[efAllowType]).typ;
    end;
    nkBracketExpr: begin
      checkMinSonsLen(n, 2);
      s := semTypeIdent(c, n.sons[0]);
      case s.magic of
        mArray: result := semArray(c, n, prev);
        mOpenArray: result := semContainer(c, n, tyOpenArray, 'openarray', prev);
        mRange: result := semRange(c, n, prev);
        mSet: result := semSet(c, n, prev);
        mOrdinal: result := semOrdinal(c, n, prev);
        mSeq: result := semContainer(c, n, tySequence, 'seq', prev);
        else result := semGeneric(c, n, s, prev);
      end
    end;
    nkIdent, nkDotExpr, nkQualified, nkAccQuoted: begin
      s := semTypeIdent(c, n);
      if s.typ = nil then
        liMessage(n.info, errTypeExpected);
      if prev = nil then
        result := s.typ
      else begin
        assignType(prev, s.typ);
        prev.id := s.typ.id;
        result := prev;
      end
    end;
    nkSym: begin
      if (n.sym.kind = skType) and (n.sym.typ <> nil) then begin
        t := n.sym.typ;
        if prev = nil then
          result := t
        else begin
          assignType(prev, t);
          result := prev;
        end;
        markUsed(n, n.sym);
      end
      else
        liMessage(n.info, errTypeExpected);
    end;
    nkObjectTy: result := semObjectNode(c, n, prev);
    nkTupleTy: result := semTuple(c, n, prev);
    nkRefTy: result := semAnyRef(c, n, tyRef, 'ref', prev);
    nkPtrTy: result := semAnyRef(c, n, tyPtr, 'ptr', prev);
    nkVarTy: result := semVarType(c, n, prev);
    nkDistinctTy: result := semDistinct(c, n, prev);
    nkProcTy: begin
      checkSonsLen(n, 2);
      result := semProcTypeNode(c, n.sons[0], nil, prev);
      // dummy symbol for `pragma`:
      s := newSymS(skProc, newIdentNode(getIdent('dummy'), n.info), c);
      s.typ := result;
      pragma(c, s, n.sons[1], procTypePragmas);
    end;
    nkEnumTy: result := semEnum(c, n, prev);
    nkType: result := n.typ;
    nkStmtListType: result := semStmtListType(c, n, prev);
    nkBlockType: result := semBlockType(c, n, prev);
    else liMessage(n.info, errTypeExpected);
    //internalError(n.info, 'semTypeNode(' +{&} nodeKindToStr[n.kind] +{&} ')');
  end
end;

procedure setMagicType(m: PSym; kind: TTypeKind; size: int);
begin
  m.typ.kind := kind;
  m.typ.align := size;
  m.typ.size := size;
  //m.typ.sym := nil;
end;

procedure processMagicType(c: PContext; m: PSym);
begin
  case m.magic of
    mInt:     setMagicType(m, tyInt, intSize);
    mInt8:    setMagicType(m, tyInt8, 1);
    mInt16:   setMagicType(m, tyInt16, 2);
    mInt32:   setMagicType(m, tyInt32, 4);
    mInt64:   setMagicType(m, tyInt64, 8);
    mFloat:   setMagicType(m, tyFloat, floatSize);
    mFloat32: setMagicType(m, tyFloat32, 4);
    mFloat64: setMagicType(m, tyFloat64, 8);
    mBool:    setMagicType(m, tyBool, 1);
    mChar:    setMagicType(m, tyChar, 1);
    mString:  begin
      setMagicType(m, tyString, ptrSize);
      addSon(m.typ, getSysType(tyChar));
    end;
    mCstring: begin
      setMagicType(m, tyCString, ptrSize);
      addSon(m.typ, getSysType(tyChar));
    end;
    mPointer: setMagicType(m, tyPointer, ptrSize);
    mEmptySet: begin
      setMagicType(m, tySet, 1);
      addSon(m.typ, newTypeS(tyEmpty, c));
    end;
    mIntSetBaseType: begin
      setMagicType(m, tyRange, intSize);
      //intSetBaseType := m.typ;
      exit
    end;
    mNil: setMagicType(m, tyNil, ptrSize);
    mExpr: setMagicType(m, tyExpr, 0);
    mStmt: setMagicType(m, tyStmt, 0);
    mTypeDesc: setMagicType(m, tyTypeDesc, 0);
    mArray, mOpenArray, mRange, mSet, mSeq, mOrdinal: exit;
    else liMessage(m.info, errTypeExpected);
  end;
  //registerSysType(m.typ);
end;
