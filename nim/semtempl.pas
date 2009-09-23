//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

function isExpr(n: PNode): bool;
// returns true if ``n`` looks like an expression
var
  i: int;
begin
  if n = nil then begin result := false; exit end;
  case n.kind of
    nkIdent..nkNilLit: result := true;
    nkCall..nkPassAsOpenArray: begin
      for i := 0 to sonsLen(n)-1 do
        if not isExpr(n.sons[i]) then begin
          result := false; exit
        end;
      result := true
    end
    else result := false
  end
end;

function isTypeDesc(n: PNode): bool;
// returns true if ``n`` looks like a type desc
var
  i: int;
begin
  if n = nil then begin result := false; exit end;
  case n.kind of
    nkIdent, nkSym, nkType: result := true;
    nkDotExpr, nkQualified, nkBracketExpr: begin
      for i := 0 to sonsLen(n)-1 do
        if not isTypeDesc(n.sons[i]) then begin
          result := false; exit
        end;
      result := true
    end;
    nkTypeOfExpr..nkEnumTy: result := true;
    else result := false
  end
end;

function evalTemplateAux(c: PContext; templ, actual: PNode; sym: PSym): PNode;
var
  i: int;
  p: PSym;
begin
  if templ = nil then begin result := nil; exit end;
  case templ.kind of
    nkSym: begin
      p := templ.sym;
      if (p.kind = skParam) and (p.owner.id = sym.id) then 
        result := copyTree(actual.sons[p.position])
      else
        result := copyNode(templ)
    end;
    nkNone..nkIdent, nkType..nkNilLit: // atom
      result := copyNode(templ);
    else begin
      result := copyNode(templ);
      newSons(result, sonsLen(templ));
      for i := 0 to sonsLen(templ)-1 do
        result.sons[i] := evalTemplateAux(c, templ.sons[i], actual, sym);
    end
  end
end;

var
  evalTemplateCounter: int = 0; // to prevend endless recursion in templates
                                // instantation

function evalTemplateArgs(c: PContext; n: PNode; s: PSym): PNode;
var
  f, a, i: int;
  arg: PNode;
begin
  f := sonsLen(s.typ);
  // if the template has zero arguments, it can be called without ``()``
  // `n` is then a nkSym or something similar
  case n.kind of
    nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand, nkCallStrLit:
      a := sonsLen(n);
    else a := 0
  end;
  if a > f then liMessage(n.info, errWrongNumberOfArguments);
  result := copyNode(n);
  for i := 1 to f-1 do begin
    if i < a then 
      arg := n.sons[i]
    else 
      arg := copyTree(s.typ.n.sons[i].sym.ast);
    if arg = nil then liMessage(n.info, errWrongNumberOfArguments);
    if not (s.typ.sons[i].kind in [tyTypeDesc, tyStmt, tyExpr]) then begin
      // concrete type means semantic checking for argument:
      arg := fitNode(c, s.typ.sons[i], semExprWithType(c, arg));
    end;
    addSon(result, arg);
  end
end;

function evalTemplate(c: PContext; n: PNode; sym: PSym): PNode;
var
  args: PNode;
begin
  inc(evalTemplateCounter);
  if evalTemplateCounter > 100 then
    liMessage(n.info, errTemplateInstantiationTooNested);
  // replace each param by the corresponding node:
  args := evalTemplateArgs(c, n, sym);
  result := evalTemplateAux(c, sym.ast.sons[codePos], args, sym);
  dec(evalTemplateCounter);
end;

function symChoice(c: PContext; n: PNode; s: PSym): PNode;
var
  a: PSym;
  o: TOverloadIter;
  i: int;
begin
  i := 0;
  a := initOverloadIter(o, c, n);
  while a <> nil do begin
    a := nextOverloadIter(o, c, n);
    inc(i);
  end;
  if i <= 1 then begin
    result := newSymNode(s);
    result.info := n.info;
    markUsed(n, s);
  end
  else begin
    // semantic checking requires a type; ``fitNode`` deals with it
    // appropriately
    result := newNodeIT(nkSymChoice, n.info, newTypeS(tyNone, c));
    a := initOverloadIter(o, c, n);
    while a <> nil do begin
      addSon(result, newSymNode(a));
      a := nextOverloadIter(o, c, n);
    end;
    //liMessage(n.info, warnUser, s.name.s + ' is here symchoice');
  end
end;

function resolveTemplateParams(c: PContext; n: PNode; withinBind: bool): PNode;
var
  i: int;
  s: PSym;
begin
  if n = nil then begin result := nil; exit end;
  case n.kind of
    nkIdent: begin
      if not withinBind then begin
        s := SymTabLocalGet(c.Tab, n.ident);
        if (s <> nil) then begin
          result := newSymNode(s);
          result.info := n.info
        end
        else
          result := n
      end
      else begin
        result := symChoice(c, n, lookup(c, n))
      end
    end;
    nkSym..nkNilLit: // atom
      result := n;
    nkBind: 
      result := resolveTemplateParams(c, n.sons[0], true);
    else begin
      result := n;
      for i := 0 to sonsLen(n)-1 do
        result.sons[i] := resolveTemplateParams(c, n.sons[i], withinBind);
    end
  end
end;

function transformToExpr(n: PNode): PNode;
var
  i, realStmt: int;
begin
  result := n;
  case n.kind of
    nkStmtList: begin
      realStmt := -1;
      for i := 0 to sonsLen(n)-1 do begin
        case n.sons[i].kind of
          nkCommentStmt, nkEmpty, nkNilLit: begin end;
          else begin
            if realStmt = -1 then realStmt := i
            else realStmt := -2
          end
        end
      end;
      if realStmt >= 0 then
        result := transformToExpr(n.sons[realStmt])
      else
        n.kind := nkStmtListExpr;
    end;
    nkBlockStmt: n.kind := nkBlockExpr;
    //nkIfStmt: n.kind := nkIfExpr; // this is not correct!
    else begin end
  end
end;

function semTemplateDef(c: PContext; n: PNode): PNode;
var
  s: PSym;
begin
  if c.p.owner.kind = skModule then begin
    s := semIdentVis(c, skTemplate, n.sons[0], {@set}[sfStar]);
    include(s.flags, sfGlobal);
  end
  else
    s := semIdentVis(c, skTemplate, n.sons[0], {@set}[]);
  if sfStar in s.flags then include(s.flags, sfInInterface);
  // check parameter list:
  pushOwner(s);
  openScope(c.tab);
  n.sons[namePos] := newSymNode(s);

  // check that no pragmas exist:
  if n.sons[pragmasPos] <> nil then
    liMessage(n.info, errNoPragmasAllowedForX, 'template');
  // check that no generic parameters exist:
  if n.sons[genericParamsPos] <> nil then
    liMessage(n.info, errNoGenericParamsAllowedForX, 'template');
  if (n.sons[paramsPos] = nil) then begin
    // use ``stmt`` as implicit result type
    s.typ := newTypeS(tyProc, c);
    s.typ.n := newNodeI(nkFormalParams, n.info);
    addSon(s.typ, newTypeS(tyStmt, c));
    addSon(s.typ.n, newNodeIT(nkType, n.info, s.typ.sons[0]));
  end
  else begin
    semParamList(c, n.sons[ParamsPos], nil, s);
    if n.sons[paramsPos].sons[0] = nil then begin
      // use ``stmt`` as implicit result type
      s.typ.sons[0] := newTypeS(tyStmt, c);
      s.typ.n.sons[0] := newNodeIT(nkType, n.info, s.typ.sons[0]);
    end
  end;
  addParams(c, s.typ.n);
  
  // resolve parameters:
  n.sons[codePos] := resolveTemplateParams(c, n.sons[codePos], false);
  if not (s.typ.sons[0].kind in [tyStmt, tyTypeDesc]) then
    n.sons[codePos] := transformToExpr(n.sons[codePos]);

  // only parameters are resolved, no type checking is performed
  closeScope(c.tab);
  popOwner();
  s.ast := n;

  result := n;
  if n.sons[codePos] = nil then
    liMessage(n.info, errImplOfXexpected, s.name.s);
  // add identifier of template as a last step to not allow
  // recursive templates
  addInterfaceDecl(c, s);
end;
