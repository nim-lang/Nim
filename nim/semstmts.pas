//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
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
        if (e.kind <> nkIntLit) then InternalError(n.info, 'semWhen');
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
  if result = nil then result := newNodeI(nkNilLit, n.info);
  // The ``when`` statement implements the mechanism for platform dependant
  // code. Thus we try to ensure here consistent ID allocation after the
  // ``when`` statement.
  IDsynchronizationPoint(200);
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
        openScope(c.tab);
        it.sons[0] := semExprWithType(c, it.sons[0]);
        checkBool(it.sons[0]);
        it.sons[1] := semStmt(c, it.sons[1]);
        closeScope(c.tab);
      end;
      nkElse: begin
        if sonsLen(it) = 1 then it.sons[0] := semStmtScope(c, it.sons[0])
        else illFormedAst(it)
      end;
      else illFormedAst(n)
    end
  end
end;

function semDiscard(c: PContext; n: PNode): PNode;
begin
  result := n;
  checkSonsLen(n, 1);
  n.sons[0] := semExprWithType(c, n.sons[0]);
  if n.sons[0].typ = nil then liMessage(n.info, errInvalidDiscard);
end;

function semBreakOrContinue(c: PContext; n: PNode): PNode;
var
  s: PSym;
  x: PNode;
begin
  result := n;
  checkSonsLen(n, 1);
  if n.sons[0] <> nil then begin
    case n.sons[0].kind of
      nkIdent: s := lookUp(c, n.sons[0]);
      nkSym: s := n.sons[0].sym;
      else illFormedAst(n)
    end;
    if (s.kind = skLabel) and (s.owner.id = c.p.owner.id) then begin
      x := newSymNode(s);
      x.info := n.info;
      include(s.flags, sfUsed);
      n.sons[0] := x
    end
    else
      liMessage(n.info, errInvalidControlFlowX, s.name.s)
  end
  else if (c.p.nestedLoopCounter <= 0) and (c.p.nestedBlockCounter <= 0) then
    liMessage(n.info, errInvalidControlFlowX,
              renderTree(n, {@set}[renderNoComments]))
end;

function semBlock(c: PContext; n: PNode): PNode;
var
  labl: PSym;
begin
  result := n;
  Inc(c.p.nestedBlockCounter);
  checkSonsLen(n, 2);
  openScope(c.tab); // BUGFIX: label is in the scope of block!
  if n.sons[0] <> nil then begin
    labl := newSymS(skLabel, n.sons[0], c);
    addDecl(c, labl);
    n.sons[0] := newSymNode(labl); // BUGFIX
  end;
  n.sons[1] := semStmt(c, n.sons[1]);
  closeScope(c.tab);
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
  checkSonsLen(n, 2);
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
        b := strutils.find(str, marker, a);
        if b < strStart then
          sub := ncopy(str, a)
        else
          sub := ncopy(str, a, b-1);
        if sub <> '' then
          addSon(result, newStrNode(nkStrLit, sub));

        if b < strStart then break;
        c := strutils.find(str, marker, b+1);
        if c < strStart then
          sub := ncopy(str, b+1)
        else
          sub := ncopy(str, b+1, c-1);
        if sub <> '' then begin
          e := SymtabGet(con.tab, getIdent(sub));
          if e <> nil then begin
            if e.kind = skStub then loadStub(e);
            addSon(result, newSymNode(e))
          end
          else
            addSon(result, newStrNode(nkStrLit, sub));
        end;
        if c < strStart then break;
        a := c+1;
      until false;
    end;
    else illFormedAst(n)
  end
end;

function semWhile(c: PContext; n: PNode): PNode;
begin
  result := n;
  checkSonsLen(n, 2);
  openScope(c.tab);
  n.sons[0] := semExprWithType(c, n.sons[0]);
  CheckBool(n.sons[0]);
  inc(c.p.nestedLoopCounter);
  n.sons[1] := semStmt(c, n.sons[1]);
  dec(c.p.nestedLoopCounter);
  closeScope(c.tab);
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
  checkMinSonsLen(n, 2);
  openScope(c.tab);
  n.sons[0] := semExprWithType(c, n.sons[0]);
  chckCovered := false;
  covered := 0;
  case skipTypes(n.sons[0].Typ, abstractVarRange).Kind of
    tyInt..tyInt64, tyChar, tyEnum: chckCovered := true;
    tyFloat..tyFloat128, tyString: begin end
    else liMessage(n.info, errSelectorMustBeOfCertainTypes);
  end;
  for i := 1 to sonsLen(n)-1 do begin
    x := n.sons[i];
    case x.kind of
      nkOfBranch: begin
        checkMinSonsLen(x, 2);
        semCaseBranch(c, n, x, i, covered);
        len := sonsLen(x);
        x.sons[len-1] := semStmtScope(c, x.sons[len-1]);
      end;
      nkElifBranch: begin
        chckCovered := false;
        checkSonsLen(x, 2);
        x.sons[0] := semExprWithType(c, x.sons[0]);
        checkBool(x.sons[0]);
        x.sons[1] := semStmtScope(c, x.sons[1])
      end;
      nkElse: begin
        chckCovered := false;
        checkSonsLen(x, 1);
        x.sons[0] := semStmtScope(c, x.sons[0])
      end;
      else illFormedAst(x);
    end;
  end;
  if chckCovered and (covered <> lengthOrd(n.sons[0].typ)) then
    liMessage(n.info, errNotAllCasesCovered);
  closeScope(c.tab);
end;

function semAsgn(c: PContext; n: PNode): PNode;
var
  le: PType;
  a: PNode;
  id: PIdent;
begin
  checkSonsLen(n, 2);
  a := n.sons[0];
  case a.kind of
    nkDotExpr, nkQualified: begin
      // r.f = x
      // --> `f=` (r, x)
      checkSonsLen(a, 2);
      id := considerAcc(a.sons[1]);
      result := newNodeI(nkCall, n.info);
      addSon(result, newIdentNode(getIdent(id.s+'='), n.info));
      addSon(result, semExpr(c, a.sons[0]));
      addSon(result, semExpr(c, n.sons[1]));
      result := semDirectCallAnalyseEffects(c, result, {@set}[]);
      if result <> nil then begin
        fixAbstractType(c, result);
        analyseIfAddressTakenInCall(c, result);
        exit;
      end
    end;
    nkBracketExpr: begin
      // a[i..j] = x
      // --> `[..]=`(a, i, j, x)
      result := newNodeI(nkCall, n.info);
      checkSonsLen(a, 2);
      if a.sons[1].kind = nkRange then begin
        checkSonsLen(a.sons[1], 2);
        addSon(result, newIdentNode(getIdent(whichSliceOpr(a.sons[1])+'='),
                                    n.info));
        addSon(result, semExpr(c, a.sons[0]));
        addSonIfNotNil(result, semExpr(c, a.sons[1].sons[0]));
        addSonIfNotNil(result, semExpr(c, a.sons[1].sons[1]));
        addSon(result, semExpr(c, n.sons[1]));
        result := semDirectCallAnalyseEffects(c, result, {@set}[]);
        if result <> nil then begin
          fixAbstractType(c, result);
          analyseIfAddressTakenInCall(c, result);
          exit;
        end
      end
      else begin
        addSon(result, newIdentNode(getIdent('[]='), n.info));
        addSon(result, semExpr(c, a.sons[0]));
        addSon(result, semExpr(c, a.sons[1]));
        addSon(result, semExpr(c, n.sons[1]));
        result := semDirectCallAnalyseEffects(c, result, {@set}[]);
        if result <> nil then begin
          fixAbstractType(c, result);
          analyseIfAddressTakenInCall(c, result);
          exit;
        end
      end;
    end;
    else begin end;
  end;
  n.sons[0] := semExprWithType(c, n.sons[0], {@set}[efLValue]);
  n.sons[1] := semExprWithType(c, n.sons[1]);
  le := n.sons[0].typ;
  if (skipTypes(le, {@set}[tyGenericInst]).kind <> tyVar) 
  and not IsAssignable(n.sons[0]) then begin
    liMessage(n.sons[0].info, errXCannotBeAssignedTo,
              renderTree(n.sons[0], {@set}[renderNoComments]));
  end
  else begin
    n.sons[1] := fitNode(c, le, n.sons[1]);
    fixAbstractType(c, n);
  end;
  result := n;
end;

function SemReturn(c: PContext; n: PNode): PNode;
var
  restype: PType;
  a: PNode; // temporary assignment for code generator
begin
  result := n;
  checkSonsLen(n, 1);
  if not (c.p.owner.kind in [skConverter, skProc, skMacro]) then
    liMessage(n.info, errXNotAllowedHere, '''return''');
  if (n.sons[0] <> nil) then begin
    n.sons[0] := SemExprWithType(c, n.sons[0]);
    // check for type compatibility:
    restype := c.p.owner.typ.sons[0];
    if (restype <> nil) then begin
      a := newNodeI(nkAsgn, n.sons[0].info);

      n.sons[0] := fitNode(c, restype, n.sons[0]);
      // optimize away ``return result``, because it would be transformed
      // to ``result = result; return``:
      if (n.sons[0].kind = nkSym) and (sfResult in n.sons[0].sym.flags) then
      begin
        n.sons[0] := nil;
      end
      else begin
        if (c.p.resultSym = nil) then InternalError(n.info, 'semReturn');
        addSon(a, semExprWithType(c, newSymNode(c.p.resultSym)));
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
  checkSonsLen(n, 1);
  if (c.p.owner = nil) or (c.p.owner.kind <> skIterator) then
    liMessage(n.info, errYieldNotAllowedHere);
  if (n.sons[0] <> nil) then begin
    n.sons[0] := SemExprWithType(c, n.sons[0]);
    // check for type compatibility:
    restype := c.p.owner.typ.sons[0];
    if (restype <> nil) then begin
      n.sons[0] := fitNode(c, restype, n.sons[0]);
      if (n.sons[0].typ = nil) then InternalError(n.info, 'semYield');
    end
    else
      liMessage(n.info, errCannotReturnExpr);
  end
end;

function fitRemoveHiddenConv(c: PContext; typ: Ptype; n: PNode): PNode;
begin
  result := fitNode(c, typ, n);
  if (result.kind in [nkHiddenStdConv, nkHiddenSubConv]) then begin
    changeType(result.sons[1], typ);
    result := result.sons[1];
  end
  else if not sameType(result.typ, typ) then
    changeType(result, typ)
end;

function semVar(c: PContext; n: PNode): PNode;
var
  i, j, len: int;
  a, b, def: PNode;
  typ, tup: PType;
  v: PSym;
begin
  result := copyNode(n);
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    if (a.kind <> nkIdentDefs) and (a.kind <> nkVarTuple) then IllFormedAst(a);
    checkMinSonsLen(a, 3);
    len := sonsLen(a);
    if a.sons[len-2] <> nil then 
      typ := semTypeNode(c, a.sons[len-2], nil)
    else
      typ := nil;
    if a.sons[len-1] <> nil then begin
      def := semExprWithType(c, a.sons[len-1]);
      // BUGFIX: ``fitNode`` is needed here!
      // check type compability between def.typ and typ:
      if (typ <> nil) then def := fitNode(c, typ, def)
      else typ := def.typ;
    end
    else
      def := nil;
    if not typeAllowed(typ, skVar) then begin
      //debug(typ);
      liMessage(a.info, errXisNoType, typeToString(typ));
    end;
    tup := skipTypes(typ, {@set}[tyGenericInst]);
    if a.kind = nkVarTuple then begin
      if tup.kind <> tyTuple then liMessage(a.info, errXExpected, 'tuple');
      if len-2 <> sonsLen(tup) then
        liMessage(a.info, errWrongNumberOfVariables);
      b := newNodeI(nkVarTuple, a.info);
      newSons(b, len);
      b.sons[len-2] := nil; // no type desc
      b.sons[len-1] := def;
      addSon(result, b);
    end;
    for j := 0 to len-3 do begin
      if (c.p.owner.kind = skModule) then begin
        v := semIdentWithPragma(c, skVar, a.sons[j], {@set}[sfStar, sfMinus]);
        include(v.flags, sfGlobal);
      end
      else
        v := semIdentWithPragma(c, skVar, a.sons[j], {@set}[]);
      if v.flags * [sfStar, sfMinus] <> {@set}[] then
        include(v.flags, sfInInterface);
      addInterfaceDecl(c, v);
      if a.kind <> nkVarTuple then begin
        v.typ := typ;
        b := newNodeI(nkIdentDefs, a.info);
        addSon(b, newSymNode(v));
        addSon(b, nil); // no type description
        addSon(b, copyTree(def));
        addSon(result, b);
      end
      else begin
        v.typ := tup.sons[j];
        b.sons[j] := newSymNode(v);
      end
    end
  end
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
    if (a.kind <> nkConstDef) then IllFormedAst(a);
    checkSonsLen(a, 3);
    if (c.p.owner.kind = skModule) then begin
      v := semIdentWithPragma(c, skConst, a.sons[0], {@set}[sfStar, sfMinus]);
      include(v.flags, sfGlobal);
    end
    else
      v := semIdentWithPragma(c, skConst, a.sons[0], {@set}[]);

    if a.sons[1] <> nil then typ := semTypeNode(c, a.sons[1], nil)
    else typ := nil;
    def := semAndEvalConstExpr(c, a.sons[2]);
    // check type compability between def.typ and typ:
    if (typ <> nil) then begin
      def := fitRemoveHiddenConv(c, typ, def);
    end
    else typ := def.typ;
    if not typeAllowed(typ, skConst) then
      liMessage(a.info, errXisNoType, typeToString(typ));

    v.typ := typ;
    v.ast := def; // no need to copy
    if v.flags * [sfStar, sfMinus] <> {@set}[] then
      include(v.flags, sfInInterface);
    addInterfaceDecl(c, v);
    b := newNodeI(nkConstDef, a.info);
    addSon(b, newSymNode(v));
    addSon(b, nil); // no type description
    addSon(b, copyTree(def));
    addSon(result, b);
  end;
end;

function semFor(c: PContext; n: PNode): PNode;
var
  i, len: int;
  v, countup: PSym;
  iter: PType;
  countupNode, call: PNode;
begin
  result := n;
  checkMinSonsLen(n, 3);
  len := sonsLen(n);
  openScope(c.tab);
  if n.sons[len-2].kind = nkRange then begin
    checkSonsLen(n.sons[len-2], 2);
    // convert ``in 3..5`` to ``in countup(3, 5)``
    countupNode := newNodeI(nkCall, n.sons[len-2].info);    
    countUp := StrTableGet(magicsys.systemModule.Tab, getIdent('countup'));
    if (countUp = nil) then
      liMessage(countupNode.info, errSystemNeeds, 'countup');
    newSons(countupNode, 3);
    countupnode.sons[0] := newSymNode(countup);
    countupNode.sons[1] := n.sons[len-2].sons[0];
    countupNode.sons[2] := n.sons[len-2].sons[1];
    
    n.sons[len-2] := countupNode;
  end;
  n.sons[len-2] := semExprWithType(c, n.sons[len-2], {@set}[efWantIterator]);
  call := n.sons[len-2];
  if (call.kind <> nkCall) or (call.sons[0].kind <> nkSym)
  or (call.sons[0].sym.kind <> skIterator) then
    liMessage(n.sons[len-2].info, errIteratorExpected);
  iter := skipTypes(n.sons[len-2].typ, {@set}[tyGenericInst]);
  if iter.kind <> tyTuple then begin
    if len <> 3 then liMessage(n.info, errWrongNumberOfVariables);
    v := newSymS(skForVar, n.sons[0], c);
    v.typ := iter;
    n.sons[0] := newSymNode(v);
    addDecl(c, v);
  end
  else begin
    if len-2 <> sonsLen(iter) then liMessage(n.info, errWrongNumberOfVariables);
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
  checkSonsLen(n, 1);
  if n.sons[0] <> nil then begin
    n.sons[0] := semExprWithType(c, n.sons[0]);
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
  checkMinSonsLen(n, 2);
  n.sons[0] := semStmtScope(c, n.sons[0]);
  IntSetInit(check);
  for i := 1 to sonsLen(n)-1 do begin
    a := n.sons[i];
    checkMinSonsLen(a, 1);
    len := sonsLen(a);
    if a.kind = nkExceptBranch then begin
      for j := 0 to len-2 do begin
        typ := semTypeNode(c, a.sons[j], nil);
        if typ.kind = tyRef then typ := typ.sons[0];
        if (typ.kind <> tyObject) then
          liMessage(a.sons[j].info, errExprCannotBeRaised);
        a.sons[j] := newNodeI(nkType, a.sons[j].info);
        a.sons[j].typ := typ;
        if IntSetContainsOrIncl(check, typ.id) then
          liMessage(a.sons[j].info, errExceptionAlreadyHandled);
      end
    end
    else if a.kind <> nkFinally then
      illFormedAst(n);
    // last child of an nkExcept/nkFinally branch is a statement:
    a.sons[len-1] := semStmtScope(c, a.sons[len-1]);
  end;
end;

function semGenericParamList(c: PContext; n: PNode; father: PType = nil): PNode;
var
  i, j, L: int;
  s: PSym;
  a, def: PNode;
  typ: PType;
begin
  result := copyNode(n);
  if n.kind <> nkGenericParams then
    InternalError(n.info, 'semGenericParamList');
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind <> nkIdentDefs then illFormedAst(n);
    L := sonsLen(a);
    def := a.sons[L-1];
    if a.sons[L-2] <> nil then
      typ := semTypeNode(c, a.sons[L-2], nil)
    else if def <> nil then
      typ := newTypeS(tyExpr, c)
    else
      typ := nil;
    for j := 0 to L-3 do begin
      if (typ = nil) or (typ.kind = tyTypeDesc) then begin
        s := newSymS(skType, a.sons[j], c);      
        s.typ := newTypeS(tyGenericParam, c)
      end
      else begin
        s := newSymS(skGenericParam, a.sons[j], c);
        s.typ := typ
      end;
      s.ast := def;
      s.typ.sym := s;
      if father <> nil then addSon(father, s.typ);
      s.position := i;
      addSon(result, newSymNode(s));
      addDecl(c, s);
    end
  end
end;

procedure addGenericParamListToScope(c: PContext; n: PNode);
var
  i: int;
  a: PNode;
begin
  if n.kind <> nkGenericParams then
    InternalError(n.info, 'addGenericParamListToScope');
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind <> nkSym then internalError(a.info, 'addGenericParamListToScope');
    addDecl(c, a.sym)
  end
end;

function SemTypeSection(c: PContext; n: PNode): PNode;
var
  i: int;
  s: PSym;
  t, body: PType;
  a: PNode;
begin
  result := n;
  // process the symbols on the left side for the whole type section, before
  // we even look at the type definitions on the right
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    if (a.kind <> nkTypeDef) then IllFormedAst(a);
    checkSonsLen(a, 3);
    if (c.p.owner.kind = skModule) then begin
      s := semIdentWithPragma(c, skType, a.sons[0], {@set}[sfStar, sfMinus]);
      include(s.flags, sfGlobal);
    end
    else
      s := semIdentWithPragma(c, skType, a.sons[0], {@set}[]);
    if s.flags * [sfStar, sfMinus] <> {@set}[] then
      include(s.flags, sfInInterface);
    s.typ := newTypeS(tyForward, c);
    s.typ.sym := s;
    // process pragmas:
    if a.sons[0].kind = nkPragmaExpr then
      pragma(c, s, a.sons[0].sons[1], typePragmas);
    // add it here, so that recursive types are possible:
    addInterfaceDecl(c, s);
    a.sons[0] := newSymNode(s);
  end;

  // process the right side of the types:
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    if (a.kind <> nkTypeDef) then IllFormedAst(a);
    checkSonsLen(a, 3);
    if (a.sons[0].kind <> nkSym) then IllFormedAst(a);
    s := a.sons[0].sym;
    if (s.magic = mNone) and (a.sons[2] = nil) then
      liMessage(a.info, errImplOfXexpected, s.name.s);
    if s.magic <> mNone then processMagicType(c, s);
    if a.sons[1] <> nil then begin
      // We have a generic type declaration here. In generic types,
      // symbol lookup needs to be done here.
      openScope(c.tab);
      pushOwner(s);
      s.typ.kind := tyGenericBody;
      if s.typ.containerID <> 0 then
        InternalError(a.info, 'semTypeSection: containerID');
      s.typ.containerID := getID();
      a.sons[1] := semGenericParamList(c, a.sons[1], s.typ);
      addSon(s.typ, nil); // to be filled out later
      s.ast := a;
      body := semTypeNode(c, a.sons[2], nil);
      if body <> nil then body.sym := s;
      s.typ.sons[sonsLen(s.typ)-1] := body;
      //debug(s.typ);
      popOwner();
      closeScope(c.tab);
    end
    else if a.sons[2] <> nil then begin
      // process the type's body:
      pushOwner(s);
      t := semTypeNode(c, a.sons[2], s.typ);
      if (t <> s.typ) and (s.typ <> nil) then
        internalError(a.info, 'semTypeSection()');
      s.typ := t;
      s.ast := a;
      popOwner();
    end;
  end;
  // unfortunately we need another pass over the section for checking of
  // illegal recursions and type aliases:
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    if (a.sons[0].kind <> nkSym) then IllFormedAst(a);
    s := a.sons[0].sym;
    // compute the type's size and check for illegal recursions:
    if a.sons[1] = nil then begin
      if (a.sons[2] <> nil)
      and (a.sons[2].kind in [nkSym, nkIdent, nkAccQuoted]) then begin
        // type aliases are hard:
        //MessageOut('for type ' + typeToString(s.typ));
        t := semTypeNode(c, a.sons[2], nil);
        if t.kind in [tyObject, tyEnum] then begin
          assignType(s.typ, t);
          s.typ.id := t.id; // same id
        end
      end;
      checkConstructedType(s.info, s.typ);
    end
  end
end;

procedure semParamList(c: PContext; n, genericParams: PNode; s: PSym);
begin
  s.typ := semProcTypeNode(c, n, genericParams, nil);
end;

procedure addParams(c: PContext; n: PNode);
var
  i: int;
begin
  for i := 1 to sonsLen(n)-1 do begin
    if (n.sons[i].kind <> nkSym) then InternalError(n.info, 'addParams');
    addDecl(c, n.sons[i].sym);
  end
end;

procedure semBorrow(c: PContext; n: PNode; s: PSym);
var
  b: PSym;
begin
  // search for the correct alias:
  b := SearchForBorrowProc(c, s, c.tab.tos-2);
  if b = nil then liMessage(n.info, errNoSymbolToBorrowFromFound);
  // store the alias:
  n.sons[codePos] := newSymNode(b);
end;

procedure sideEffectsCheck(c: PContext; s: PSym);
begin
  if [sfNoSideEffect, sfSideEffect] * s.flags = 
     [sfNoSideEffect, sfSideEffect] then 
    liMessage(s.info, errXhasSideEffects, s.name.s);
end;

procedure addResult(c: PContext; t: PType; const info: TLineInfo);
var
  s: PSym;
begin
  if t <> nil then begin
    s := newSym(skVar, getIdent('result'), getCurrOwner());
    s.info := info;
    s.typ := t;
    Include(s.flags, sfResult);
    Include(s.flags, sfUsed);
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
  checkSonsLen(n, codePos+1);
  s := newSym(skProc, getIdent(':anonymous'), getCurrOwner());
  s.info := n.info;

  oldP := c.p; // restore later
  s.ast := n;
  n.sons[namePos] := newSymNode(s);

  pushOwner(s);
  openScope(c.tab);
  if (n.sons[genericParamsPos] <> nil) then illFormedAst(n);
  // process parameters:
  if n.sons[paramsPos] <> nil then begin
    semParamList(c, n.sons[ParamsPos], nil, s);
    addParams(c, s.typ.n);
  end
  else begin
    s.typ := newTypeS(tyProc, c);
    addSon(s.typ, nil);
  end;

  // we are in a nested proc:
  s.typ.callConv := ccClosure;
  if n.sons[pragmasPos] <> nil then
    pragma(c, s, n.sons[pragmasPos], lambdaPragmas);

  s.options := gOptions;
  if n.sons[codePos] <> nil then begin
    if sfImportc in s.flags then
      liMessage(n.sons[codePos].info, errImplOfXNotAllowed, s.name.s);
    c.p := newProcCon(s);
    addResult(c, s.typ.sons[0], n.info);
    n.sons[codePos] := semStmtScope(c, n.sons[codePos]);
    addResultNode(c, n);
  end
  else
    liMessage(n.info, errImplOfXexpected, s.name.s);
  closeScope(c.tab); // close scope for parameters
  popOwner();
  c.p := oldP; // restore
  result.typ := s.typ;
end;

function semProcAux(c: PContext; n: PNode; kind: TSymKind;
                    const validPragmas: TSpecialWords): PNode;
var
  s, proto: PSym;
  oldP: PProcCon;
  gp: PNode;
begin
  result := n;
  checkSonsLen(n, codePos+1);
  if c.p.owner.kind = skModule then begin
    s := semIdentVis(c, kind, n.sons[0], {@set}[sfStar]);
    include(s.flags, sfGlobal);
  end
  else
    s := semIdentVis(c, kind, n.sons[0], {@set}[]);
  n.sons[namePos] := newSymNode(s);
  oldP := c.p; // restore later
  if sfStar in s.flags then include(s.flags, sfInInterface);
  s.ast := n;

  pushOwner(s);
  openScope(c.tab);
  if n.sons[genericParamsPos] <> nil then begin
    n.sons[genericParamsPos] := semGenericParamList(c, n.sons[genericParamsPos]);
    gp := n.sons[genericParamsPos]
  end
  else
    gp := newNodeI(nkGenericParams, n.info);
  // process parameters:
  if n.sons[paramsPos] <> nil then begin
    semParamList(c, n.sons[ParamsPos], gp, s);
    if sonsLen(gp) > 0 then n.sons[genericParamsPos] := gp;
    addParams(c, s.typ.n);
  end
  else begin
    s.typ := newTypeS(tyProc, c);
    addSon(s.typ, nil);
  end;

  proto := SearchForProc(c, s, c.tab.tos-2); // -2 because we have a scope open
                                             // for parameters
  if proto = nil then begin
    if oldP.owner.kind <> skModule then // we are in a nested proc
      s.typ.callConv := ccClosure
    else
      s.typ.callConv := lastOptionEntry(c).defaultCC;
    // add it here, so that recursive procs are possible:
    // -2 because we have a scope open for parameters
    if kind in OverloadableSyms then
      addInterfaceOverloadableSymAt(c, s, c.tab.tos-2)
    else
      addDeclAt(c, s, c.tab.tos-2);
    if n.sons[pragmasPos] <> nil then
      pragma(c, s, n.sons[pragmasPos], validPragmas)
  end
  else begin
    if n.sons[pragmasPos] <> nil then
      liMessage(n.sons[pragmasPos].info, errPragmaOnlyInHeaderOfProc);
    if not (sfForward in proto.flags) then
      liMessage(n.info, errAttemptToRedefineX, proto.name.s);
    exclude(proto.flags, sfForward);
    closeScope(c.tab); // close scope with wrong parameter symbols
    openScope(c.tab); // open scope for old (correct) parameter symbols
    if proto.ast.sons[genericParamsPos] <> nil then
      addGenericParamListToScope(c, proto.ast.sons[genericParamsPos]);
    addParams(c, proto.typ.n);
    proto.info := s.info; // more accurate line information
    s.typ := proto.typ;
    s := proto;
    n.sons[genericParamsPos] := proto.ast.sons[genericParamsPos];
    n.sons[paramsPos] := proto.ast.sons[paramsPos];
    if (n.sons[namePos].kind <> nkSym) then InternalError(n.info, 'semProcAux');
    n.sons[namePos].sym := proto;
    proto.ast := n; // needed for code generation
    popOwner();
    pushOwner(s);
  end;

  s.options := gOptions;
  if n.sons[codePos] <> nil then begin
    if [sfImportc, sfBorrow] * s.flags <> [] then
      liMessage(n.sons[codePos].info, errImplOfXNotAllowed, s.name.s);
    if (n.sons[genericParamsPos] = nil) then begin
      c.p := newProcCon(s);
      if (s.typ.sons[0] <> nil) and (kind <> skIterator) then
        addResult(c, s.typ.sons[0], n.info);
      n.sons[codePos] := semStmtScope(c, n.sons[codePos]);
      if (s.typ.sons[0] <> nil) and (kind <> skIterator) then
        addResultNode(c, n);
    end
    else begin
      if (s.typ.sons[0] <> nil) and (kind <> skIterator) then
        addDecl(c, newSym(skUnknown, getIdent('result'), nil));
      n.sons[codePos] := semGenericStmtScope(c, n.sons[codePos]);
    end
  end
  else begin
    if proto <> nil then
      liMessage(n.info, errImplOfXexpected, proto.name.s);
    if [sfImportc, sfBorrow] * s.flags = [] then Include(s.flags, sfForward)
    else if sfBorrow in s.flags then 
      semBorrow(c, n, s);
  end;
  sideEffectsCheck(c, s);
  closeScope(c.tab); // close scope for parameters
  popOwner();
  c.p := oldP; // restore
end;

function semIterator(c: PContext; n: PNode): PNode;
var
  t: PType;
  s: PSym;
begin
  result := semProcAux(c, n, skIterator, iteratorPragmas);
  s := result.sons[namePos].sym;
  t := s.typ;
  if t.sons[0] = nil then liMessage(n.info, errXNeedsReturnType, 'iterator');
  if n.sons[codePos] = nil then liMessage(n.info, errImplOfXexpected, s.name.s);
end;

function semProc(c: PContext; n: PNode): PNode;
begin
  result := semProcAux(c, n, skProc, procPragmas);
end;

function semConverterDef(c: PContext; n: PNode): PNode;
var
  t: PType;
  s: PSym;
begin
  checkSonsLen(n, codePos+1);
  if n.sons[genericParamsPos] <> nil then
    liMessage(n.info, errNoGenericParamsAllowedForX, 'converter');
  result := semProcAux(c, n, skConverter, converterPragmas);
  s := result.sons[namePos].sym;
  t := s.typ;
  if t.sons[0] = nil then liMessage(n.info, errXNeedsReturnType, 'converter');
  if sonsLen(t) <> 2 then liMessage(n.info, errXRequiresOneArgument, 'converter');
  addConverter(c, s);
end;

function semMacroDef(c: PContext; n: PNode): PNode;
var
  t: PType;
  s: PSym;
begin
  checkSonsLen(n, codePos+1);
  if n.sons[genericParamsPos] <> nil then
    liMessage(n.info, errNoGenericParamsAllowedForX, 'macro');
  result := semProcAux(c, n, skMacro, macroPragmas);
  s := result.sons[namePos].sym;
  t := s.typ;
  if t.sons[0] = nil then liMessage(n.info, errXNeedsReturnType, 'macro');
  if sonsLen(t) <> 2 then liMessage(n.info, errXRequiresOneArgument, 'macro');
  if n.sons[codePos] = nil then liMessage(n.info, errImplOfXexpected, s.name.s);
end;

function evalInclude(c: PContext; n: PNode): PNode;
var
  i, fileIndex: int;
  x: PNode;
  f, name, ext: string;
begin
  result := newNodeI(nkStmtList, n.info);
  addSon(result, n); // the rodwriter needs include information!
  for i := 0 to sonsLen(n)-1 do begin
    f := getModuleFile(n.sons[i]);
    fileIndex := includeFilename(f);
    if IntSetContainsOrIncl(c.includedFiles, fileIndex) then
      liMessage(n.info, errRecursiveDependencyX, f);
    SplitFilename(f, name, ext);
    if cmpIgnoreCase(ext, '.'+TmplExt) = 0 then
      x := gIncludeTmplFile(f)
    else
      x := gIncludeFile(f);
    x := semStmt(c, x);
    addSon(result, x);
    IntSetExcl(c.includedFiles, fileIndex);
  end;
end;

function semCommand(c: PContext; n: PNode): PNode;
begin
  result := semExpr(c, n);
  if result.typ <> nil then liMessage(n.info, errDiscardValue);
end;

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
  if nfSem in n.flags then exit;
  case n.kind of
    nkAsgn: result := semAsgn(c, n);
    nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand, nkMacroStmt, nkCallStrLit:
      result := semCommand(c, n);
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
        end
      end
    end;
    nkRaiseStmt: result := semRaise(c, n);
    nkVarSection: result := semVar(c, n);
    nkConstSection: result := semConst(c, n);
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
    nkYieldStmt: result := semYield(c, n);
    nkPragma: pragma(c, c.p.owner, n, stmtPragmas);
    nkIteratorDef: result := semIterator(c, n);
    nkProcDef: result := semProc(c, n);
    nkConverterDef: result := semConverterDef(c, n);
    nkMacroDef: result := semMacroDef(c, n);
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
  end;
  if result = nil then InternalError(n.info, 'SemStmt: result = nil');
  include(result.flags, nfSem);
end;

function semStmtScope(c: PContext; n: PNode): PNode;
begin
  openScope(c.tab);
  result := semStmt(c, n);
  closeScope(c.tab);
end;
