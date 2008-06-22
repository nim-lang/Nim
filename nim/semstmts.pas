//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// this module does the semantic checking of statements

function semWhen(c: PContext; n: PNode): PNode;
var
  i: int;
  it, e: PNode;
begin
  result := nil;
  for i := 0 to sonsLen(n)-1 do begin
    it := n.sons[i];
    if it = nil then illFormedAst(n);
    case it.kind of
      nkElifBranch: begin
        checkSonsLen(it, 2);
        e := semConstExpr(c, it.sons[0]);
        checkBool(e);
        assert(e.kind = nkIntLit);
        if (e.intVal <> 0) and (result = nil) then
          result := semStmt(c, it.sons[1]); // do not open a new scope!
      end;
      nkElse: begin
        checkSonsLen(it, 1);
        if result = nil then result := semStmt(c, it.sons[0])
        // do not open a new scope!
      end;
      else illFormedAst(n)
    end
  end;
  if result = nil then result := newNode(nkNilLit);
end;

function semIf(c: PContext; n: PNode): PNode;
var
  i: int;
  it: PNode;
begin
  result := n;
  for i := 0 to sonsLen(n)-1 do begin
    it := n.sons[i];
    if it = nil then illFormedAst(n);
    case it.kind of
      nkElifBranch: begin
        checkSonsLen(it, 2);
        it.sons[0] := semExpr(c, it.sons[0]);
        checkBool(it.sons[0]);
        it.sons[1] := semStmtScope(c, it.sons[1])
      end;
      nkElse: begin
        if sonsLen(it) = 1 then it.sons[0] := semStmtScope(c, it.sons[0])
        else illFormedAst(it)
      end;
      else illFormedAst(n)
    end
  end;
end;

function semDiscard(c: PContext; n: PNode): PNode;
begin
  result := n;
  if sonsLen(n) = 1 then begin
    n.sons[0] := semExpr(c, n.sons[0]);
    if n.sons[0].typ = nil then liMessage(n.info, errInvalidDiscard);
  end
  else
    illFormedAst(n);
end;

function semBreakOrContinue(c: PContext; n: PNode): PNode;
var
  s: PSym;
  x: PNode;
begin
  result := n;
  if sonsLen(n) = 1 then begin
    if n.sons[0] <> nil then begin
      if n.sons[0].kind = nkIdent then begin
        // lookup the symbol:
        s := SymtabGet(c.Tab, n.sons[0].ident);
        if s <> nil then begin
          if (s.kind = skLabel) and (s.owner.id = c.p.owner.id) then begin
            x := newSymNode(s);
            x.info := n.info;
            include(s.flags, sfUsed);
            n.sons[0] := x
          end
          else
            liMessage(n.info, errInvalidControlFlowX, s.name.s)
        end
        else
          liMessage(n.info, errUndeclaredIdentifier, n.sons[0].ident.s);
      end
      else illFormedAst(n)
    end
    else if (c.p.nestedLoopCounter <= 0) and (c.p.nestedBlockCounter <= 0) then
      liMessage(n.info, errInvalidControlFlowX,
               renderTree(n, {@set}[renderNoComments]))
  end
  else
    illFormedAst(n);
end;

function semBlock(c: PContext; n: PNode): PNode;
var
  labl: PSym;
begin
  result := n;
  Inc(c.p.nestedBlockCounter);
  if sonsLen(n) = 2 then begin
    openScope(c.tab); // BUGFIX: label is in the scope of block!
    if n.sons[0] <> nil then begin
      labl := newSymS(skLabel, n.sons[0], c);
      addDecl(c, labl);
      n.sons[0] := newSymNode(labl); // BUGFIX
    end;
    n.sons[1] := semStmt(c, n.sons[1]);
    closeScope(c.tab);
  end
  else
    illFormedAst(n);
  Dec(c.p.nestedBlockCounter);
end;

function semAsm(con: PContext; n: PNode): PNode;
var
  str, sub: string;
  a, b, c: int;
  e: PSym;
  marker: Char;
begin
  result := n;
  if sonsLen(n) = 2 then begin
    marker := pragmaAsm(con, n.sons[0]);
    if marker = #0 then marker := '`'; // default marker
    case n.sons[1].kind of
      nkStrLit, nkRStrLit, nkTripleStrLit: begin
        result := copyNode(n);
        str := n.sons[1].strVal;
        if str = '' then liMessage(n.info, errEmptyAsm);
        // now parse the string literal and substitute symbols:
        a := strStart;
        repeat
          b := findSubStr(marker, str, a);
          if b < strStart then
            sub := ncopy(str, a)
          else
            sub := ncopy(str, a, b-1);
          if sub = '' then break;
          addSon(result, newStrNode(nkStrLit, sub));

          if b < strStart then break;
          c := findSubStr(marker, str, b+1);
          if c < strStart then
            sub := ncopy(str, b+1)
          else
            sub := ncopy(str, b+1, c-1);
          e := SymtabGet(con.tab, getIdent(sub));
          if e <> nil then
            addSon(result, newSymNode(e))
          else
            addSon(result, newStrNode(nkStrLit, sub));
          if c < strStart then break;
          a := c+1;
        until false;
      end;
      else illFormedAst(n)
    end
  end
  else
    illFormedAst(n);
end;

function semWhile(c: PContext; n: PNode): PNode;
begin
  result := n;
  if sonsLen(n) = 2 then begin
    n.sons[0] := semExpr(c, n.sons[0]);
    CheckBool(n.sons[0]);
    inc(c.p.nestedLoopCounter);
    n.sons[1] := semStmtScope(c, n.sons[1]);
    dec(c.p.nestedLoopCounter);
  end
  else
    illFormedAst(n);
end;

function semCase(c: PContext; n: PNode): PNode;
var
  i, len: int;
  covered: biggestint;
  // for some types we count to check if all cases have been covered
  chckCovered: boolean;
  x: PNode;
begin
  // check selector:
  result := n;
  n.sons[0] := semExprWithType(c, n.sons[0], false);
  chckCovered := false;
  covered := 0;
  case skipVarGenericRange(n.sons[0].Typ).Kind of
    tyInt..tyInt64, tyChar, tyEnum: chckCovered := true;
    tyFloat..tyFloat128, tyString: begin end
    else liMessage(n.info, errSelectorMustBeOfCertainTypes);
  end;
  for i := 1 to sonsLen(n)-1 do begin
    x := n.sons[i];
    case x.kind of
      nkOfBranch: begin
        semCaseBranch(c, n, x, i, covered);
        len := sonsLen(x);
        x.sons[len-1] := semStmtScope(c, x.sons[len-1]);
      end;
      nkElifBranch: begin
        chckCovered := false;
        checkSonsLen(n, 2);
        x.sons[0] := semExpr(c, x.sons[0]);
        checkBool(x.sons[0]);
        x.sons[1] := semStmtScope(c, x.sons[1])
      end;
      nkElse: begin
        chckCovered := false;
        if sonsLen(x) = 1 then x.sons[0] := semStmtScope(c, x.sons[0])
        else illFormedAst(x)
      end;
      else illFormedAst(x);
    end;
  end;
  if chckCovered and (covered <> lengthOrd(n.sons[0].typ)) then
    liMessage(n.info, errNotAllCasesCovered);
end;

function semAsgn(c: PContext; n: PNode): PNode;
var
  le: PType;
begin
  result := n;
  n.sons[0] := semExprWithType(c, n.sons[0], false);
  n.sons[1] := semExprWithType(c, n.sons[1], false);
  le := n.sons[0].typ;
  if not (tfAssignable in le.flags) and (le.kind <> tyVar) then begin
    liMessage(n.sons[0].info, errXCannotBeAssignedTo,
              renderTree(n.sons[0], {@set}[renderNoComments]));
  end
  else begin
    n.sons[1] := fitNode(c, le, n.sons[1]);
    fixAbstractType(c, n); 
  end
end;

function SemReturn(c: PContext; n: PNode): PNode;
var
  restype: PType;
  a: PNode; // temporary assignment for code generator
begin
  result := n;
  if not (c.p.owner.kind in [skConverter, skProc]) then
    liMessage(n.info, errReturnNotAllowedHere);
  if (n.sons[0] <> nil) then begin
    n.sons[0] := SemExprWithType(c, n.sons[0], false);
    // check for type compatibility:
    restype := c.p.owner.typ.sons[0];
    if (restype <> nil) then begin
      a := newNode(nkAsgn);
      a.info := n.sons[0].info;

      n.sons[0] := fitNode(c, restype, n.sons[0]);
      // optimize away ``return result``, because it would be transferred
      // to ``result = result; return``:
      if (n.sons[0].kind = nkSym) and (sfResult in n.sons[0].sym.flags) then
      begin
        n.sons[0] := nil;
      end
      else begin
        assert(c.p.resultSym <> nil);
        addSon(a, semExprWithType(c, newSymNode(c.p.resultSym), false));
        addSon(a, n.sons[0]);
        n.sons[0] := a;
      end
    end
    else
      liMessage(n.info, errCannotReturnExpr);
  end;
end;

function SemYield(c: PContext; n: PNode): PNode;
var
  restype: PType;
begin
  result := n;
  if (c.p.owner = nil) or (c.p.owner.kind <> skIterator) then
    liMessage(n.info, errYieldNotAllowedHere);
  if (n.sons[0] <> nil) then begin
    n.sons[0] := SemExprWithType(c, n.sons[0], false);
    // check for type compatibility:
    restype := c.p.owner.typ.sons[0];
    if (restype <> nil) then begin
      n.sons[0] := fitNode(c, restype, n.sons[0]);
      assert(n.sons[0].typ <> nil);
    end
    else
      liMessage(n.info, errCannotReturnExpr);
  end
end;

function fitRemoveHiddenConv(c: PContext; typ: Ptype; n: PNode): PNode;
begin 
  result := fitNode(c, typ, n);
  if (result.kind in [nkHiddenStdConv, nkHiddenSubConv]) then begin
    changeType(result.sons[0], typ);
    result := result.sons[0];
  end
  else if not sameType(result.typ, typ) then
    changeType(result, typ)
end;

function semVar(c: PContext; n: PNode): PNode;
var
  i, j, len: int;
  a, b, def: PNode;
  typ: PType;
  v: PSym;
begin
  result := copyNode(n);
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    assert(a.kind = nkIdentDefs);
    len := sonsLen(a);
    if a.sons[len-2] <> nil then
      typ := semTypeNode(c, a.sons[len-2], nil)
    else
      typ := nil;
    if a.sons[len-1] <> nil then begin
      def := semExprWithType(c, a.sons[len-1], false);
      // check type compability between def.typ and typ:
      if (typ <> nil) then def := fitRemoveHiddenConv(c, typ, def)
      else typ := def.typ;
    end
    else
      def := nil;
    typ := copyType(typ, typ.owner);
    include(typ.flags, tfAssignable);
    for j := 0 to len-3 do begin
      if (c.p.owner = nil) then begin
        v := semIdentWithPragma(c, skVar, a.sons[j], {@set}[sfStar, sfMinus]);
        include(v.flags, sfGlobal);
      end
      else
        v := semIdentWithPragma(c, skVar, a.sons[j], {@set}[]);
      v.typ := typ;
      if v.flags * [sfStar, sfMinus] <> {@set}[] then
        include(v.flags, sfInInterface);
      addInterfaceDecl(c, v);
      b := newNode(nkIdentDefs);
      b.info := a.info;
      addSon(b, newSymNode(v));
      addSon(b, nil); // no type description
      addSon(b, copyTree(def));
      addSon(result, b);
    end
  end;
end;

function semConst(c: PContext; n: PNode): PNode;
var
  a, def, b: PNode;
  i: int;
  v: PSym;
  typ: PType;
begin
  result := copyNode(n);
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    assert(a.kind = nkConstDef);
    assert(sonsLen(a) = 3);
    if (c.p.owner = nil) then begin
      v := semIdentWithPragma(c, skConst, a.sons[0], {@set}[sfStar, sfMinus]);
      include(v.flags, sfGlobal);
    end
    else
      v := semIdentWithPragma(c, skConst, a.sons[0], {@set}[]);

    if a.sons[1] <> nil then typ := semTypeNode(c, a.sons[1], nil)
    else typ := nil;
    def := semConstExpr(c, a.sons[2]);
    // check type compability between def.typ and typ:
    if (typ <> nil) then begin
      def := fitRemoveHiddenConv(c, typ, def);
    end
    else typ := def.typ;

    v.typ := typ;
    v.ast := def; // no need to copy
    if v.flags * [sfStar, sfMinus] <> {@set}[] then
      include(v.flags, sfInInterface);
    addInterfaceDecl(c, v);
    b := newNode(nkConstDef);
    b.info := a.info;
    addSon(b, newSymNode(v));
    addSon(b, nil); // no type description
    addSon(b, copyTree(def));
    addSon(result, b);
  end;
end;

function semFor(c: PContext; n: PNode): PNode;
var
  i, len: int;
  v: PSym;
  iter: PType;
  countupNode, m: PNode;
begin
  result := n;
  len := sonsLen(n);
  if n.sons[len-2].kind = nkRange then begin
    // convert ``in 3..5`` to ``in countup(3, 5)``
    // YYY: if the programmer overrides system.countup in a local scope
    // this leads to wrong code. This is extremely hard to fix! But it may
    // not even be a bug, but a feature...
    countupNode := newNodeI(nkCall, n.sons[len-2].info);
    newSons(countupNode, 3);
    countupNode.sons[0] := newNodeI(nkQualified, n.sons[len-2].info);
    newSons(countupNode.sons[0], 2);
    m := newIdentNode(getIdent('system'));
    m.info := n.sons[len-2].info;
    countupNode.sons[0].sons[0] := m;
    m := newIdentNode(getIdent('countup'));
    m.info := n.sons[len-2].info;
    countupNode.sons[0].sons[1] := m;
    countupNode.sons[1] := n.sons[len-2].sons[0];
    countupNode.sons[2] := n.sons[len-2].sons[1];
    n.sons[len-2] := countupNode;
  end;
  n.sons[len-2] := semExprWithType(c, n.sons[len-2], false);
  iter := n.sons[len-2].typ;
  openScope(c.tab);
  if iter.kind <> tyTuple then begin
    if len <> 3 then liMessage(n.info, errWrongNumberOfLoopVariables);
    v := newSymS(skForVar, n.sons[0], c);
    v.typ := iter;
    n.sons[0] := newSymNode(v);
    addDecl(c, v);
  end
  else begin
    if len-2 <> sonsLen(iter) then
      liMessage(n.info, errWrongNumberOfLoopVariables);
    for i := 0 to len-3 do begin
      v := newSymS(skForVar, n.sons[i], c);
      v.typ := iter.sons[i];
      n.sons[i] := newSymNode(v);
      addDecl(c, v);
    end
  end;
  // semantic checking for the sub statements:
  Inc(c.p.nestedLoopCounter);
  n.sons[len-1] := SemStmt(c, n.sons[len-1]);
  closeScope(c.tab);
  Dec(c.p.nestedLoopCounter);
end;

function semRaise(c: PContext; n: PNode): PNode;
var
  typ: PType;
begin
  result := n;
  if n.sons[0] <> nil then begin
    n.sons[0] := semExprWithType(c, n.sons[0], false);
    typ := n.sons[0].typ;
    if (typ.kind <> tyRef) or (typ.sons[0].kind <> tyObject) then
      liMessage(n.info, errExprCannotBeRaised)
  end;
end;

function semTry(c: PContext; n: PNode): PNode;
var
  i, j, len: int;
  a: PNode;
  typ: PType;
  check: TIntSet;
begin
  result := n;
  n.sons[0] := semStmtScope(c, n.sons[0]);
  IntSetInit(check);
  for i := 1 to sonsLen(n)-1 do begin
    a := n.sons[i];
    len := sonsLen(a);
    if a.kind = nkExceptBranch then begin
      for j := 0 to len-2 do begin
        typ := semTypeNode(c, a.sons[j], nil);
        if typ.kind = tyRef then typ := typ.sons[0];
        if (typ.kind <> tyObject) then
          liMessage(a.sons[j].info, errExprCannotBeRaised);
        a.sons[j] := newNode(nkType);
        a.sons[j].typ := typ;
        if IntSetContainsOrIncl(check, typ.id) then
          liMessage(a.sons[j].info, errExceptionAlreadyHandled);
      end
    end;
    // last child of an nkExcept/nkFinally branch is a statement:
    a.sons[len-1] := semStmtScope(c, a.sons[len-1]);
  end;
end;

procedure semGenericParamList(c: PContext; n: PNode);
var
  i: int;
  s: PSym;
begin
  assert(n.kind = nkGenericParams);
  for i := 0 to sonsLen(n)-1 do begin
    if n.sons[i].kind = nkDefaultTypeParam then begin
      internalError(n.sons[i].info, 'semGenericParamList() to implement');
      // XXX
    end
    else begin
      s := newSymS(skTypeParam, n.sons[i], c);
      s.typ := newTypeS(tyGenericParam, c);
      s.typ.sym := s;
    end;
    s.position := i;
    n.sons[i] := newSymNode(s);
    addDecl(c, s);
  end
end;

function resolveGenericParams(c: PContext; n: PNode): PNode;
begin
  //result := resolveTemplateParams(c, n); // we can use the same algorithm
  result := n;
end;

function SemTypeSection(c: PContext; n: PNode): PNode;
var
  i: int;
  s: PSym;
  t: PType;
  a: PNode;
begin
  result := n;
  // process the symbols on the left side for the whole type section, before
  // we even look at the type definitions on the right
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    assert(a.kind = nkTypeDef);
    assert(sonsLen(a) = 3);
    if (c.p.owner = nil) then begin
      s := semIdentWithPragma(c, skType, a.sons[0], {@set}[sfStar, sfMinus]);
      include(s.flags, sfGlobal);
    end
    else
      s := semIdentWithPragma(c, skType, a.sons[0], {@set}[]);
    if s.flags * [sfStar, sfMinus] <> {@set}[] then
      include(s.flags, sfInInterface);
    s.typ := newTypeS(tyForward, c);
    s.typ.sym := s;
    // add it here, so that recursive types are possible:
    addInterfaceDecl(c, s);
    a.sons[0] := newSymNode(s);
  end;

  // process the right side of the types:
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    assert(a.kind = nkTypeDef);
    assert(a.sons[0].kind = nkSym);
    assert(sonsLen(a) = 3);
    s := a.sons[0].sym;
    if (s.magic = mNone) and (a.sons[2] = nil) then
      liMessage(a.info, errTypeXNeedsImplementation, s.name.s);
    if a.sons[1] <> nil then begin
      // we have a generic type declaration here, so we don't process the
      // type's body:
      openScope(c.tab);
      pushOwner(c, s);
      semGenericParamList(c, a.sons[1]);
      // process the type body for symbol lookup of generic params:
      a.sons[2] := resolveGenericParams(c, a.sons[2]);
      s.ast := a;
      assert(s.typ.containerID = 0);
      s.typ.containerID := getID();
      popOwner(c);
      closeScope(c.tab);
    end
    else begin
      // process the type's body:
      pushOwner(c, s);
      t := semTypeNode(c, a.sons[2], s.typ);
      if (t <> s.typ) then internalError(a.info, 'semTypeSection()');
      s.typ := t;
      s.ast := a;
      popOwner(c);
      // compute the type's size and check for illegal recursions:
      if computeSize(s.typ) < 0 then
        liMessage(s.info, errIllegalRecursionInTypeX, s.name.s);
    end;
  end;
end;

procedure semParamList(c: PContext; n: PNode; s: PSym);
begin
  s.typ := semProcTypeNode(c, n, nil);
end;

procedure addParams(c: PContext; n: PNode);
var
  i: int;
begin
  for i := 1 to sonsLen(n)-1 do begin
    assert(n.sons[i].kind = nkSym);
    addDecl(c, n.sons[i].sym);
  end
end;

function semIterator(c: PContext; n: PNode): PNode;
var
  s: PSym;
  oldP: PProcCon;
begin
  result := n;
  if c.p.owner <> nil then
    liMessage(n.info, errIteratorNotAllowed);
  oldP := c.p; // restore later
  s := semIdentVis(c, skIterator, n.sons[0], {@set}[sfStar]);
  n.sons[namePos] := newSymNode(s);
  include(s.flags, sfGlobal);
  if sfStar in s.flags then include(s.flags, sfInInterface);
  s.ast := n;
  pushOwner(c, s);
  if n.sons[genericParamsPos] <> nil then begin
    // we have a generic type declaration here, so we don't process the
    // type's body:
    openScope(c.tab);
    semGenericParamList(c, n.sons[genericParamsPos]);
  end;
  // process parameters:
  if n.sons[paramsPos] <> nil then
    semParamList(c, n.sons[ParamsPos], s)
  else
    liMessage(n.info, errIteratorNeedsReturnType);
  s.typ.callConv := lastOptionEntry(c).defaultCC;
  if n.sons[pragmasPos] <> nil then
    pragmaIterator(c, s, n.sons[pragmasPos]);
  s.options := gOptions;
  if n.sons[codePos] <> nil then begin
    if n.sons[genericParamsPos] = nil then begin
      c.p := newProcCon(s);
      openScope(c.tab);
      addParams(c, s.typ.n);
      n.sons[codePos] := semStmtScope(c, n.sons[codePos]);
    end
    else begin
      n.sons[codePos] := resolveGenericParams(c, n.sons[codePos]);
    end
  end
  else
    liMessage(n.info, errIteratorNeedsImplementation);
  closeScope(c.tab);
  popOwner(c);
  c.p := oldP;
  // add it here, so that recursive iterators are impossible:
  addInterfaceOverloadableSymAt(c, s, c.tab.tos-1);
  //writeln(renderTree(n.sons[codePos], {@set}[renderIds]));
end;

{$include 'procfind.pas'}

procedure addResult(c: PContext; t: PType; const info: TLineInfo);
var
  s: PSym;
begin
  if t <> nil then begin
    s := newSym(skVar, getIdent('result'), getCurrOwner(c));
    s.info := info;
    s.typ := inheritAssignable(t, true);
    Include(s.flags, sfResult);
    addDecl(c, s);
    c.p.resultSym := s;
  end
end;

procedure addResultNode(c: PContext; n: PNode);
begin
  if c.p.resultSym <> nil then addSon(n, newSymNode(c.p.resultSym));
end;

function semLambda(c: PContext; n: PNode): PNode;
var
  s: PSym;
  oldP: PProcCon;
begin
  result := n;
  s := newSym(skProc, getIdent(genPrefix + 'anonymous'), getCurrOwner(c));
  s.info := n.info;

  oldP := c.p; // restore later
  s.ast := n;
  n.sons[namePos] := newSymNode(s);

  pushOwner(c, s);
  openScope(c.tab);
  assert(n.sons[genericParamsPos] = nil);
  // process parameters:
  if n.sons[paramsPos] <> nil then begin
    semParamList(c, n.sons[ParamsPos], s);
    addParams(c, s.typ.n);
  end
  else begin
    s.typ := newTypeS(tyProc, c);
    addSon(s.typ, nil);
  end;

  // we are in a nested proc:
  s.typ.callConv := ccClosure;
  if n.sons[pragmasPos] <> nil then
    pragmaLambda(c, s, n.sons[pragmasPos]);

  s.options := gOptions;
  if n.sons[codePos] <> nil then begin
    if sfImportc in s.flags then
      liMessage(n.sons[codePos].info, errImportedProcCannotHaveImpl);
    c.p := newProcCon(s);
    addResult(c, s.typ.sons[0], n.info);
    n.sons[codePos] := semStmtScope(c, n.sons[codePos]);
    addResultNode(c, n);
  end
  else begin
    liMessage(n.info, errImplOfXexpected, s.name.s);
    if not (sfImportc in s.flags) then
      Include(s.flags, sfForward);
  end;
  closeScope(c.tab); // close scope for parameters
  popOwner(c);
  c.p := oldP; // restore
end;

function semProc(c: PContext; n: PNode): PNode;
var
  s, proto: PSym;
  oldP: PProcCon;
begin
  result := n;
  if c.p.owner = nil then begin
    s := semIdentVis(c, skProc, n.sons[0], {@set}[sfStar]);
    include(s.flags, sfGlobal);
  end
  else
    s := semIdentVis(c, skProc, n.sons[0], {@set}[]);
  n.sons[namePos] := newSymNode(s);
  oldP := c.p; // restore later
  if sfStar in s.flags then include(s.flags, sfInInterface);
  s.ast := n;

  pushOwner(c, s);
  openScope(c.tab);
  if n.sons[genericParamsPos] <> nil then
    semGenericParamList(c, n.sons[genericParamsPos]);
  // process parameters:
  if n.sons[paramsPos] <> nil then begin
    semParamList(c, n.sons[ParamsPos], s);
    addParams(c, s.typ.n);
  end
  else begin
    s.typ := newTypeS(tyProc, c);
    addSon(s.typ, nil);
  end;

  proto := SearchForProc(c, s, c.tab.tos-2); // -2 because we have a scope open
                                             // for parameters
  if proto = nil then begin
    if oldP.owner <> nil then // we are in a nested proc
      s.typ.callConv := ccClosure
    else
      s.typ.callConv := lastOptionEntry(c).defaultCC;
    // add it here, so that recursive procs are possible:
    // -2 because we have a scope open for parameters
    addInterfaceOverloadableSymAt(c, s, c.tab.tos-2);
    if n.sons[pragmasPos] <> nil then
      pragmaProc(c, s, n.sons[pragmasPos]);
  end
  else begin
    if n.sons[pragmasPos] <> nil then
      liMessage(n.sons[pragmasPos].info, errPragmaOnlyInHeaderOfProc);
    if not (sfForward in proto.flags) then
      liMessage(n.info, errAttemptToRedefineX, proto.name.s);
    exclude(proto.flags, sfForward);
    proto.info := s.info; // more accurate line information
    s.typ.callConv := proto.typ.callConv;
    s.typ.flags := proto.typ.flags;

    proto.typ := s.typ;
    s := proto;
    proto.ast := n; // needed for code generation
    assert(n.sons[namePos].kind = nkSym);
    n.sons[namePos].sym := proto;
    popOwner(c);
    pushOwner(c, s);
  end;

  s.options := gOptions;
  //writeln(s.name.s, '  ', ropeToStr(optionsToStr(s.options)));
  if n.sons[codePos] <> nil then begin
    if sfImportc in s.flags then
      liMessage(n.sons[codePos].info, errImportedProcCannotHaveImpl);
    if n.sons[genericParamsPos] = nil then begin
      c.p := newProcCon(s);
      addResult(c, s.typ.sons[0], n.info);
      n.sons[codePos] := semStmtScope(c, n.sons[codePos]);
      addResultNode(c, n);
    end
    else begin
      n.sons[codePos] := resolveGenericParams(c, n.sons[codePos]);
    end
  end
  else begin
    if proto <> nil then
      liMessage(n.info, errImplOfXexpected, proto.name.s);
    if not (sfImportc in s.flags) then
      Include(s.flags, sfForward);
  end;
  closeScope(c.tab); // close scope for parameters
  popOwner(c);
  c.p := oldP; // restore
end;

function isTopLevel(c: PContext): bool;
begin
  result := c.tab.tos <= 2
end;

{$include 'importer.pas'}
(*
function isConcreteStmt(n: PNode): bool;
begin
  case n.kind of
    nkProcDef, nkIteratorDef: result := n.sons[genericParamsPos] = nil;
    nkCommentStmt, nkTemplateDef, nkMacroDef: result := false;
    else result := true
  end
end;

function TopLevelEvent(c: PContext; n: PNode): PNode;
begin
  result := n;
  if isTopLevel(c) and (eTopLevel in c.b.eventMask) then begin
    if isConcreteStmt(result) then begin
      if optVerbose in gGlobalOptions then
        MessageOut('compiling: ' + renderTree(result, {@set}[renderNoBody,
                                                        renderNoComments]));
      result := transform(c, result);
      result := c.b.topLevelEvent(c.b, result);
    end
  end
end; *)

function SemStmt(c: PContext; n: PNode): PNode;
const
  // must be last statements in a block:
  LastBlockStmts = {@set}[nkRaiseStmt, nkReturnStmt, nkBreakStmt, 
                          nkContinueStmt];
var
  len, i, j: int;
begin
  result := n;
  if n = nil then exit;
  embeddedDbg(c, n);
  case n.kind of
    nkAsgn: result := semAsgn(c, n);
    nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand: begin
      result := semExpr(c, n);
      if result.typ <> nil then liMessage(n.info, errDiscardValue);
    end;
    nkEmpty, nkCommentStmt, nkNilLit: begin end;
    nkBlockStmt: result := semBlock(c, n);
    nkStmtList: begin
      len := sonsLen(n);
      for i := 0 to len-1 do begin
        n.sons[i] := semStmt(c, n.sons[i]);
        if (n.sons[i].kind in LastBlockStmts) then begin
          for j := i+1 to len-1 do
            case n.sons[j].kind of
              nkPragma, nkCommentStmt, nkNilLit, nkEmpty: begin end;
              else liMessage(n.sons[j].info, errStmtInvalidAfterReturn);
            end
        end;
      end;
    end;
    nkRaiseStmt: result := semRaise(c, n);
    nkVarSection: result := SemVar(c, n);
    nkConstSection: result := SemConst(c, n);
    nkTypeSection: result := SemTypeSection(c, n);
    nkIfStmt: result := SemIf(c, n);
    nkWhenStmt: result := semWhen(c, n);
    nkDiscardStmt: result := semDiscard(c, n);
    nkWhileStmt: result := semWhile(c, n);
    nkTryStmt: result := semTry(c, n);
    nkBreakStmt, nkContinueStmt: result := semBreakOrContinue(c, n);
    nkForStmt: result := semFor(c, n);
    nkCaseStmt: result := semCase(c, n);
    nkReturnStmt: result := semReturn(c, n);
    nkAsmStmt: result := semAsm(c, n);
    nkYieldStmt: result := SemYield(c, n);
    nkPragma: pragmaStmt(c, n);
    nkIteratorDef: result := semIterator(c, n);
    nkProcDef: result := semProc(c, n);
    nkTemplateDef: result := semTemplateDef(c, n);
    nkImportStmt: begin
      if not isTopLevel(c) then
        liMessage(n.info, errXOnlyAtModuleScope, 'import');
      result := evalImport(c, n);
    end;
    nkFromStmt: begin
      if not isTopLevel(c) then
        liMessage(n.info, errXOnlyAtModuleScope, 'from');
      result := evalFrom(c, n);
    end;
    nkIncludeStmt: begin
      if not isTopLevel(c) then
        liMessage(n.info, errXOnlyAtModuleScope, 'include');
      result := evalInclude(c, n);
    end;
    else liMessage(n.info, errStmtExpected);
  end
end;

function semStmtScope(c: PContext; n: PNode): PNode;
begin
  openScope(c.tab);
  result := semStmt(c, n);
  closeScope(c.tab);
end;
