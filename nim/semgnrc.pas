//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//


// This implements the first pass over the generic body; it resolves some
// symbols. Thus for generics there is a two-phase symbol lookup just like
// in C++.
// A problem is that it cannot be detected if the symbol is introduced
// as in ``var x = ...`` or used because macros/templates can hide this!
// So we have to eval templates/macros right here so that symbol
// lookup can be accurate.

type
  TSemGenericFlag = (withinBind, withinTypeDesc);
  TSemGenericFlags = set of TSemGenericFlag;

function semGenericStmt(c: PContext; n: PNode; 
                        flags: TSemGenericFlags = {@set}[]): PNode; forward;

function semGenericStmtScope(c: PContext; n: PNode; 
                             flags: TSemGenericFlags = {@set}[]): PNode;
begin
  openScope(c.tab);
  result := semGenericStmt(c, n, flags);
  closeScope(c.tab);
end;

function semGenericStmtSymbol(c: PContext; n: PNode; s: PSym): PNode;
begin
  case s.kind of
    skUnknown: begin
      // Introduced in this pass! Leave it as an identifier.
      result := n;
    end;
    skProc, skMethod, skIterator, skConverter: result := symChoice(c, n, s);
    skTemplate: result := semTemplateExpr(c, n, s, false);
    skMacro: result := semMacroExpr(c, n, s, false);
    skGenericParam: result := newSymNode(s);
    skParam: result := n;
    skType: begin
      if (s.typ <> nil) and (s.typ.kind <> tyGenericParam) then
        result := newSymNode(s)
      else    
        result := n
    end
    else result := newSymNode(s)
  end
end;

function getIdentNode(n: PNode): PNode;
begin
  case n.kind of
    nkPostfix: result := getIdentNode(n.sons[1]);
    nkPragmaExpr, nkAccQuoted: result := getIdentNode(n.sons[0]);
    nkIdent: result := n;
    else begin
      illFormedAst(n);
      result := nil
    end
  end
end;

function semGenericStmt(c: PContext; n: PNode; 
                        flags: TSemGenericFlags = {@set}[]): PNode;
var
  i, j, L: int;
  a: PNode;
  s: PSym;
begin
  result := n;
  if n = nil then exit;
  case n.kind of
    nkIdent, nkAccQuoted: begin
      s := lookUp(c, n);
      if withinBind in flags then
        result := symChoice(c, n, s)
      else
        result := semGenericStmtSymbol(c, n, s);
    end;
    nkDotExpr: begin
      s := QualifiedLookUp(c, n, true);
      if s <> nil then
        result := semGenericStmtSymbol(c, n, s);
    end;
    nkSym..nkNilLit: begin end;
    nkBind: result := semGenericStmt(c, n.sons[0], {@set}[withinBind]);
    
    nkCall, nkHiddenCallConv, nkInfix, nkPrefix, nkCommand, nkCallStrLit: begin
      // check if it is an expression macro:
      checkMinSonsLen(n, 1);
      s := qualifiedLookup(c, n.sons[0], false);
      if (s <> nil) then begin
        case s.kind of
          skMacro: begin result := semMacroExpr(c, n, s, false); exit end;
          skTemplate: begin result := semTemplateExpr(c, n, s, false); exit end;
          skUnknown, skParam: begin
            // Leave it as an identifier.
          end;
          skProc, skMethod, skIterator, skConverter: begin
            n.sons[0] := symChoice(c, n.sons[0], s);
          end;
          skGenericParam: n.sons[0] := newSymNode(s);
          skType: begin
            // bad hack for generics:
            if (s.typ <> nil) and (s.typ.kind <> tyGenericParam) then begin
              n.sons[0] := newSymNode(s);
            end
          end;
          else n.sons[0] := newSymNode(s)
        end
      end;
      for i := 1 to sonsLen(n)-1 do
        n.sons[i] := semGenericStmt(c, n.sons[i], flags);
    end;
    nkMacroStmt: begin
      result := semMacroStmt(c, n, false);
    end;
    nkIfStmt: begin
      for i := 0 to sonsLen(n)-1 do
        n.sons[i] := semGenericStmtScope(c, n.sons[i]);
    end;
    nkWhileStmt: begin
      openScope(c.tab);
      for i := 0 to sonsLen(n)-1 do
        n.sons[i] := semGenericStmt(c, n.sons[i]);
      closeScope(c.tab);
    end;
    nkCaseStmt: begin
      openScope(c.tab);
      n.sons[0] := semGenericStmt(c, n.sons[0]);
      for i := 1 to sonsLen(n)-1 do begin
        a := n.sons[i];
        checkMinSonsLen(a, 1);
        L := sonsLen(a);
        for j := 0 to L-2 do
          a.sons[j] := semGenericStmt(c, a.sons[j]);
        a.sons[L-1] := semGenericStmtScope(c, a.sons[L-1]);
      end;
      closeScope(c.tab);
    end;
    nkForStmt: begin
      L := sonsLen(n);
      openScope(c.tab);
      n.sons[L-2] := semGenericStmt(c, n.sons[L-2]);
      for i := 0 to L-3 do
        addDecl(c, newSymS(skUnknown, n.sons[i], c));
      n.sons[L-1] := semGenericStmt(c, n.sons[L-1]);
      closeScope(c.tab);
    end;
    nkBlockStmt, nkBlockExpr, nkBlockType: begin
      checkSonsLen(n, 2);
      openScope(c.tab);
      if n.sons[0] <> nil then 
        addDecl(c, newSymS(skUnknown, n.sons[0], c));
      n.sons[1] := semGenericStmt(c, n.sons[1]);
      closeScope(c.tab);
    end;
    nkTryStmt: begin
      checkMinSonsLen(n, 2);
      n.sons[0] := semGenericStmtScope(c, n.sons[0]);
      for i := 1 to sonsLen(n)-1 do begin
        a := n.sons[i];
        checkMinSonsLen(a, 1);
        L := sonsLen(a);
        for j := 0 to L-2 do 
          a.sons[j] := semGenericStmt(c, a.sons[j], {@set}[withinTypeDesc]);
        a.sons[L-1] := semGenericStmtScope(c, a.sons[L-1]);
      end;    
    end;
    nkVarSection: begin
      for i := 0 to sonsLen(n)-1 do begin
        a := n.sons[i];
        if a.kind = nkCommentStmt then continue;
        if (a.kind <> nkIdentDefs) and (a.kind <> nkVarTuple) then
          IllFormedAst(a);
        checkMinSonsLen(a, 3);
        L := sonsLen(a);
        a.sons[L-2] := semGenericStmt(c, a.sons[L-2], {@set}[withinTypeDesc]);
        a.sons[L-1] := semGenericStmt(c, a.sons[L-1]);
        for j := 0 to L-3 do
          addDecl(c, newSymS(skUnknown, getIdentNode(a.sons[j]), c));
      end
    end;
    nkGenericParams: begin
      for i := 0 to sonsLen(n)-1 do begin
        a := n.sons[i];
        if (a.kind <> nkIdentDefs) then IllFormedAst(a);
        checkMinSonsLen(a, 3);
        L := sonsLen(a);
        a.sons[L-2] := semGenericStmt(c, a.sons[L-2], {@set}[withinTypeDesc]);
        // do not perform symbol lookup for default expressions 
        for j := 0 to L-3 do
          addDecl(c, newSymS(skUnknown, getIdentNode(a.sons[j]), c));
      end
    end;
    nkConstSection: begin
      for i := 0 to sonsLen(n)-1 do begin
        a := n.sons[i];
        if a.kind = nkCommentStmt then continue;
        if (a.kind <> nkConstDef) then IllFormedAst(a);
        checkSonsLen(a, 3);
        addDecl(c, newSymS(skUnknown, getIdentNode(a.sons[0]), c));
        a.sons[1] := semGenericStmt(c, a.sons[1], {@set}[withinTypeDesc]);
        a.sons[2] := semGenericStmt(c, a.sons[2]);
      end
    end;
    nkTypeSection: begin
      for i := 0 to sonsLen(n)-1 do begin
        a := n.sons[i];
        if a.kind = nkCommentStmt then continue;
        if (a.kind <> nkTypeDef) then IllFormedAst(a);
        checkSonsLen(a, 3);
        addDecl(c, newSymS(skUnknown, getIdentNode(a.sons[0]), c));
      end;
      for i := 0 to sonsLen(n)-1 do begin
        a := n.sons[i];
        if a.kind = nkCommentStmt then continue;
        if (a.kind <> nkTypeDef) then IllFormedAst(a);
        checkSonsLen(a, 3);
        if a.sons[1] <> nil then begin
          openScope(c.tab);
          a.sons[1] := semGenericStmt(c, a.sons[1]);
          a.sons[2] := semGenericStmt(c, a.sons[2], {@set}[withinTypeDesc]);
          closeScope(c.tab);
        end
        else
          a.sons[2] := semGenericStmt(c, a.sons[2], {@set}[withinTypeDesc]);
      end
    end;
    nkEnumTy: begin
      checkMinSonsLen(n, 1);
      if n.sons[0] <> nil then
        n.sons[0] := semGenericStmt(c, n.sons[0], {@set}[withinTypeDesc]);
      for i := 1 to sonsLen(n)-1 do begin
        case n.sons[i].kind of
          nkEnumFieldDef: a := n.sons[i].sons[0];
          nkIdent: a := n.sons[i];
          else illFormedAst(n);
        end;
        addDeclAt(c, newSymS(skUnknown, getIdentNode(a.sons[i]), c),
                  c.tab.tos-1);
      end
    end;
    nkObjectTy, nkTupleTy: begin end;
    nkFormalParams: begin
      checkMinSonsLen(n, 1);
      if n.sons[0] <> nil then 
        n.sons[0] := semGenericStmt(c, n.sons[0], {@set}[withinTypeDesc]);
      for i := 1 to sonsLen(n)-1 do begin
        a := n.sons[i];
        if (a.kind <> nkIdentDefs) then IllFormedAst(a);
        checkMinSonsLen(a, 3);
        L := sonsLen(a);
        a.sons[L-1] := semGenericStmt(c, a.sons[L-2], {@set}[withinTypeDesc]);
        a.sons[L-1] := semGenericStmt(c, a.sons[L-1]);
        for j := 0 to L-3 do begin
          addDecl(c, newSymS(skUnknown, getIdentNode(a.sons[j]), c));
        end
      end
    end;
    nkProcDef, nkMethodDef, nkConverterDef, nkMacroDef, nkTemplateDef,
    nkIteratorDef, nkLambda: begin
      checkSonsLen(n, codePos+1);
      addDecl(c, newSymS(skUnknown, getIdentNode(n.sons[0]), c));
      openScope(c.tab);
      n.sons[genericParamsPos] := semGenericStmt(c, n.sons[genericParamsPos]);
      if n.sons[paramsPos] <> nil then begin
        if n.sons[paramsPos].sons[0] <> nil then
          addDecl(c, newSym(skUnknown, getIdent('result'), nil));
        n.sons[paramsPos] := semGenericStmt(c, n.sons[paramsPos]);
      end;
      n.sons[pragmasPos] := semGenericStmt(c, n.sons[pragmasPos]);
      n.sons[codePos] := semGenericStmtScope(c, n.sons[codePos]);
      closeScope(c.tab);
    end
    else begin
      for i := 0 to sonsLen(n)-1 do
        result.sons[i] := semGenericStmt(c, n.sons[i], flags);
    end
  end
end;
