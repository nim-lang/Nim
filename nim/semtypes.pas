//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
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
  assert((prev = nil) or (prev.Kind = tyForward));
  if prev = nil then
    result := newTypeS(kind, c)
  else begin
    result := prev;
    result.kind := kind
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
  result.n := newNode(nkEnumTy);
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
        if (x <> counter) and (i <> 1) then
          include(result.flags, tfEnumHasWholes);
        if x < counter then
          liMessage(n.sons[i].info, errInvalidOrderInEnumX, e.name.s);
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
      StrTableAdd(c.module.tab, e); // BUGFIX
    end;
    addSon(result.n, newSymNode(e));
    addOverloadableSymAt(c, e, c.tab.tos-1);
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

function semRangeAux(c: PContext; n: PNode; prev: PType): PType;
var
  a, b: PNode;
begin
  assert(n.kind = nkRange);
  result := newOrPrevType(tyRange, prev, c);
  result.n := copyTree(n);
  result.n := newNode(nkRange);
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

function semTypeIdent(c: PContext; n: PNode): PSym;
begin
  result := qualifiedLookup(c, n, true);
  if (result <> nil) then begin
    include(result.flags, sfUsed);
    if not (result.kind in [skTypeParam, skType]) then
      liMessage(n.info, errTypeExpected);
  end
  else
    liMessage(n.info, errIdentifierExpected);
end;

function semTuple(c: PContext; n: PNode; prev: PType): PType;
var
  i: int;
  elem: PType;
begin
  result := newOrPrevType(tyTuple, prev, c);
  for i := 1 to sonsLen(n)-1 do begin // BUGFIX: start from 1
    elem := semTypeNode(c, n.sons[i], nil);
    addSon(result, elem);
  end
end;

function instGenericAux(c: PContext; templ, actual: PNode;
                        sym: PSym): PNode;
var
  i: int;
begin
  case templ.kind of
    nkSym: begin
      if (templ.sym.kind = skTypeParam)
      and (templ.sym.owner.id = sym.id) then
        result := copyTree(actual.sons[templ.sym.position+1])
      else
        result := copyNode(templ)
    end;
    nkNone..nkIdent, nkType..nkNilLit: // atom
      result := copyNode(templ);
    else begin
      result := copyNode(templ);
      newSons(result, sonsLen(templ));
      for i := 0 to sonsLen(templ)-1 do
        result.sons[i] := instGenericAux(c, templ.sons[i], actual, sym);
    end
  end
end;

function semGeneric(c: PContext; n: PNode; s: PSym; prev: PType): PType;
var
  i: int;
  elem: PType;
  inst: PNode;
begin
  if (s.typ = nil) or (s.typ.kind <> tyGeneric) then
    liMessage(n.info, errCannotInstantiateX, s.name.s);
  result := newOrPrevType(tyGenericInst, prev, c);
  result.containerID := s.typ.containerID;
  assert(s.typ.containerID <> 0);
  for i := 1 to sonsLen(n)-1 do begin
    elem := semTypeNode(c, n.sons[i], nil);
    addSon(result, elem);
  end;
  if s.ast <> nil then begin
    inst := instGenericAux(c, s.ast.sons[2], n, s);
    elem := semTypeNode(c, inst, nil);
    // does checking of instantiated type for us!
    addSon(result, elem);
  end
  else
    liMessage(n.info, errCannotInstantiateX, s.name.s);
end;

function semIdentVis(c: PContext; kind: TSymKind; n: PNode;
                     const allowed: TSymFlags): PSym;
// identifier with visability
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
    result := semIdentVis(c, kind, n.sons[0], allowed);
    case kind of
      skType: pragmaType(c, result, n.sons[1]);
      skField: pragmaField(c, result, n.sons[1]);
      skVar: pragmaVar(c, result, n.sons[1]);
      skConst: pragmaConst(c, result, n.sons[1]);
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
      if overlap(t.sons[i].sons[j], ex) then
        liMessage(ex.info, errDuplicateCaseLabel);
end;

procedure semBranchExpr(c: PContext; t: PNode; var ex: PNode);
begin
  ex := semConstExpr(c, ex);
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
      semBranchExpr(c, t, b.sons[0]);
      semBranchExpr(c, t, b.sons[1]);
      if emptyRange(b.sons[0], b.sons[1]) then
        liMessage(b.info, errRangeIsEmpty);
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
                           var pos: int; father: PNode); forward;

procedure semRecordCase(c: PContext; n: PNode;
                        var check: TIntSet;
                        var pos: int; father: PNode);
var
  i: int;
  covered: biggestint;
  chckCovered: boolean;
  a, b: PNode;
  typ: PType;
begin
  a := copyNode(n);
  semRecordNodeAux(c, n.sons[0], check, pos, a);
  if a.sons[0].kind <> nkSym then
    internalError('semRecordCase: dicriminant is no symbol');
  include(a.sons[0].sym.flags, sfDiscriminant);
  covered := 0;
  typ := skipVarGeneric(a.sons[0].Typ);
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
      nkOfBranch: semCaseBranch(c, a, b, i, covered);
      nkElse: chckCovered := false;
      else internalError(n.info, 'semRecordAux(record case branch)');
    end;
    delSon(b, sonsLen(b)-1);
    semRecordNodeAux(c, lastSon(n.sons[i]), check, pos, b);
    addSon(a, b);
  end;
  if chckCovered and (covered <> lengthOrd(a.sons[0].typ)) then
    liMessage(a.info, errNotAllCasesCovered);
  addSon(father, a);
end;

procedure semRecordNodeAux(c: PContext; n: PNode;
                           var check: TIntSet;
                           var pos: int; father: PNode);
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
            assert(e.kind = nkIntLit);
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
        semRecordNodeAux(c, branch, check, pos, father);
    end;
    nkRecCase: begin
      semRecordCase(c, n, check, pos, father);
    end;
    nkRecList: begin
      // attempt to keep the nesting at a sane level:
      if father.kind = nkRecList then a := father
      else a := copyNode(n);
      for i := 0 to sonsLen(n)-1 do begin
        semRecordNodeAux(c, n.sons[i], check, pos, a);
      end;
      if a <> father then
        addSon(father, a);
    end;
    nkIdentDefs: begin
      len := sonsLen(n);
      if (father.kind <> nkRecList) and (len >= 4) then a := newNode(nkRecList)
      else a := nil;
      if n.sons[len-1] <> nil then
        liMessage(n.sons[len-1].info, errInitHereNotAllowed);
      if n.sons[len-2] = nil then
        liMessage(n.info, errTypeExpected);
      typ := semTypeNode(c, n.sons[len-2], nil);
      for i := 0 to sonsLen(n)-3 do begin
        f := semIdentWithPragma(c, skField, n.sons[i], {@set}[sfStar, sfMinus]);
        f.typ := typ;
        f.position := pos;
        inc(pos);
        if IntSetContainsOrIncl(check, f.name.id) then
          liMessage(n.sons[i].info, errAttemptToRedefine, f.name.s);
        if a = nil then addSon(father, newSymNode(f))
        else addSon(a, newSymNode(f))
      end;
      if a <> nil then addSon(father, a);
    end;
    else begin
      InternalError(n.info, 'semRecordAux(' +{&} nodeKindToStr[n.kind] +{&} ')')
    end
  end
end;

procedure addInheritedFieldsAux(c: PContext; var check: TIntSet;
                                var pos: int; n: PNode);
var
  i: int;
begin
  case n.kind of
    nkRecCase: begin
      assert(n.sons[0].kind = nkSym);
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
  if n.sons[1] <> nil then begin
    base := semTypeNode(c, n.sons[1].sons[0], nil);
    if base.kind = tyObject then
      addInheritedFields(c, check, pos, base)
    else
      liMessage(n.sons[1].info, errInheritanceOnlyWithObjects);
  end
  else
    base := nil;
  if n.kind = nkObjectTy then
    result := newOrPrevType(tyObject, prev, c)
  else
    result := newOrPrevType(tyRecord, prev, c);
  addSon(result, base);
  result.n := newNode(nkRecList);
  semRecordNodeAux(c, n.sons[2], check, pos, result.n);
end;

function semProcTypeNode(c: PContext; n: PNode; prev: PType): PType;
var
  i, j, len, counter: int;
  a, def, res: PNode;
  typ: PType;
  arg: PSym;
  check: TIntSet;
begin
  result := newOrPrevType(tyProc, prev, c);
  result.callConv := lastOptionEntry(c).defaultCC;
  result.n := newNode(nkFormalParams);
  if n.sons[0] = nil then begin
    addSon(result, nil); // return type
    addSon(result.n, newNode(nkType)); // BUGFIX: nkType-Node must be present!
  end
  else begin
    addSon(result, semTypeNode(c, n.sons[0], nil)); // return type
    res := newNode(nkType);
    res.typ := result.sons[0];
    addSon(result.n, res);
  end;
  IntSetInit(check);
  counter := 0;
  for i := 1 to sonsLen(n)-1 do begin
    a := n.sons[i];
    assert(a.kind = nkIdentDefs);
    len := sonsLen(a);
    if a.sons[len-2] <> nil then
      typ := semTypeNode(c, a.sons[len-2], nil)
    else
      typ := nil;
    if a.sons[len-1] <> nil then begin
      def := semExprWithType(c, a.sons[len-1], false);
      // check type compability between def.typ and typ:
      if (typ <> nil) then begin
        if (cmpTypes(typ, def.typ) <= isConvertible) then begin
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
  end
end;

function semTypeNode(c: PContext; n: PNode; prev: PType): PType;
var
  s: PSym;
begin
  result := nil;
  if n = nil then exit;
  embeddedDbg(c, n);
  case n.kind of
    nkTypeOfExpr: begin
      result := semExprWithType(c, n, true).typ;
    end;
    nkBracketExpr: begin
      s := semTypeIdent(c, n.sons[0]);
      case s.magic of
        mArray: result := semArray(c, n, prev);
        mOpenArray: result := semContainer(c, n, tyOpenArray, 'openarray', prev);
        mRange: result := semRange(c, n, prev);
        mTuple: result := semTuple(c, n, prev);
        mSet: result := semSet(c, n, prev);
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
        result := prev;
      end
      // result :=  copyType(s.typ, s.owner);
    end;
    nkSym: begin
      if (n.sym.kind in [skTypeParam, skType]) and (n.sym.typ <> nil) then begin
        if prev = nil then
          result := n.sym.typ
        else begin
          assignType(prev, s.typ);
          result := prev;
        end;
        //  result := copyType(n.sym.typ, n.sym.owner);
        include(n.sym.flags, sfUsed); // BUGFIX
      end
      else
        liMessage(n.info, errTypeExpected);
    end;
    nkRecordTy, nkObjectTy: begin
      result := semObjectNode(c, n, prev);
    end;
    nkRefTy: result := semAnyRef(c, n, tyRef, 'ref', prev);
    nkPtrTy: result := semAnyRef(c, n, tyPtr, 'ptr', prev);
    nkVarTy: result := semAnyRef(c, n, tyVar, 'var', prev);
    nkProcTy: begin
      result := semProcTypeNode(c, n.sons[0], prev);
      // dummy symbol for `pragma`:
      s := newSymS(skProc, newIdentNode(getIdent('dummy')), c);
      s.typ := result;
      pragmaProcType(c, s, n.sons[1]);
    end;
    nkEnumTy: result := semEnum(c, n, prev);
    nkType: result := n.typ;
    else liMessage(n.info, errTypeExpected);
    //internalError(n.info, 'semTypeNode(' +{&} nodeKindToStr[n.kind] +{&} ')');
  end
end;
