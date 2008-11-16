//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
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

function evalTemplateAux(c: PContext; templ, actual: PNode;
                         sym: PSym): PNode;
var
  i: int;
begin
  if templ = nil then begin result := nil; exit end;
  case templ.kind of
    nkSym: begin
      if (templ.sym.kind = skParam) and (templ.sym.owner.id = sym.id) then
        result := copyTree(actual.sons[templ.sym.position+1]) // BUGFIX: +1
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

function evalTemplate(c: PContext; n: PNode; sym: PSym): PNode;
var
  r: PNode;
begin
  inc(evalTemplateCounter);
  if evalTemplateCounter > 100 then
    liMessage(n.info, errTemplateInstantiationTooNested);
  // replace each param by the corresponding node:
  r := sym.ast.sons[paramsPos].sons[0];
  if (r.kind <> nkIdent) then InternalError(r.info, 'evalTemplate');
  result := evalTemplateAux(c, sym.ast.sons[codePos], n, sym);
  if r.ident.id = ord(wExpr) then result := semExpr(c, result)
  else result := semStmt(c, result);
  dec(evalTemplateCounter);
end;

function resolveTemplateParams(c: PContext; n: PNode): PNode;
var
  i: int;
  s: PSym;
begin
  if n = nil then begin result := nil; exit end;
  case n.kind of
    nkIdent: begin
      s := SymTabLocalGet(c.Tab, n.ident);
      if (s <> nil) then begin
        result := newSymNode(s);
        result.info := n.info
      end
      else
        result := n
    end;
    nkSym..nkNilLit: // atom
      result := n;
    else begin
      result := n;
      for i := 0 to sonsLen(n)-1 do
        result.sons[i] := resolveTemplateParams(c, n.sons[i]);
    end
  end
end;

function semTemplateParamKind(c: PContext; n, p: PNode): PNode;
begin
  if (p = nil) or (p.kind <> nkIdent) then
    liMessage(n.info, errInvalidParamKindX, renderTree(p))
  else begin
    case p.ident.id of
      ord(wExpr), ord(wStmt), ord(wTypeDesc): begin end;
      else
        liMessage(p.info, errInvalidParamKindX, p.ident.s)
    end
  end;
  result := p;
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
  s, param: PSym;
  i, j, len, counter: int;
  params, p, paramKind: PNode;
begin
  if c.p.owner = nil then begin
    s := semIdentVis(c, skTemplate, n.sons[0], {@set}[sfStar]);
    include(s.flags, sfGlobal);
  end
  else
    s := semIdentVis(c, skTemplate, n.sons[0], {@set}[]);
  if sfStar in s.flags then include(s.flags, sfInInterface);
  // check parameter list:
  pushOwner(s);
  openScope(c.tab);
  params := n.sons[paramsPos];
  counter := 0;
  for i := 1 to sonsLen(params)-1 do begin
    p := params.sons[i];
    len := sonsLen(p);
    paramKind := semTemplateParamKind(c, p, p.sons[len-2]);
    if (p.sons[len-1] <> nil) then
      liMessage(p.sons[len-1].info, errDefaultArgumentInvalid);
    for j := 0 to len-3 do begin
      param := newSymS(skParam, p.sons[j], c);
      param.position := counter;
      param.ast := paramKind;
      inc(counter);
      addDecl(c, param)
    end;
  end;
  params.sons[0] := semTemplateParamKind(c, params, params.sons[0]);
  n.sons[namePos] := newSymNode(s);

  // check that no pragmas exist:
  if n.sons[pragmasPos] <> nil then
    liMessage(n.info, errNoPragmasAllowedForX, 'template');
  // check that no generic parameters exist:
  if n.sons[genericParamsPos] <> nil then
    liMessage(n.info, errNoGenericParamsAllowedForX, 'template');
  // resolve parameters:
  n.sons[codePos] := resolveTemplateParams(c, n.sons[codePos]);
  if params.sons[0].ident.id = ord(wExpr) then
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
