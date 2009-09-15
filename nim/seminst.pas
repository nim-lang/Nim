//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// This module does the instantiation of generic procs and types.

function generateInstance(c: PContext; fn: PSym; const pt: TIdTable;
                          const info: TLineInfo): PSym; forward;
// generates an instantiated proc


function searchInstTypes(const tab: TIdTable; key: PType): PType;
var
  t: PType;
  h: THash;
  j: int;
  match: bool;
begin // returns nil if we need to declare this type
  result := PType(IdTableGet(tab, key));
  if (result = nil) and (tab.counter > 0) then begin
    // we have to do a slow linear search because types may need
    // to be compared by their structure:
    for h := 0 to high(tab.data) do begin
      t := PType(tab.data[h].key);
      if t <> nil then begin
        if key.containerId = t.containerID then begin
          match := true;
          for j := 0 to sonsLen(t) - 1 do begin
            // XXX sameType is not really correct for nested generics?
            if not sameType(t.sons[j], key.sons[j]) then begin
              match := false; break
            end
          end;
          if match then begin result := PType(tab.data[h].val); exit end;
        end
      end
    end
  end
end;

function containsGenericTypeIter(t: PType; closure: PObject): bool;
begin
  result := t.kind in GenericTypes;
end;

function containsGenericType(t: PType): bool;
begin
  result := iterOverType(t, containsGenericTypeIter, nil);
end;

(*
function instantiateSym(c: PInstantiateClosure; sym: PSym): PSym;
begin
  if sym = nil then begin result := nil; exit end; // BUGFIX
  result := PSym(idTableGet(c.symMap, sym));
  if (result = nil) then begin
    if (sym.owner.id = c.fn.id) then begin // XXX: nested generics?
      result := copySym(sym, false);
      include(result.flags, sfFromGeneric);
      idTablePut(c.symMap, sym, result); // BUGFIX
      result.typ := instantiateType(c, sym.typ);
      if (result.owner <> nil) and (result.owner.kind = skModule) then
        result.owner := c.module // BUGFIX
      else
        result.owner := instantiateSym(c, result.owner);
      if sym.ast <> nil then begin
        result.ast := instantiateTree(c, sym.ast);
      end
    end
    else
      result := sym // do not copy t!
  end
end;
*)

procedure instantiateGenericParamList(c: PContext; n: PNode; const pt: TIdTable);
var
  i: int;
  s, q: PSym;
  t: PType;
  a: PNode;
begin
  if (n.kind <> nkGenericParams) then 
    InternalError(n.info, 'instantiateGenericParamList; no generic params');
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind <> nkSym then 
      InternalError(a.info, 'instantiateGenericParamList; no symbol');
    q := a.sym;
    if not (q.typ.kind in [tyTypeDesc, tyGenericParam]) then continue;
    s := newSym(skType, q.name, getCurrOwner());
    t := PType(IdTableGet(pt, q.typ));
    if t = nil then liMessage(a.info, errCannotInstantiateX, s.name.s);
    if (t.kind = tyGenericParam) then begin
      InternalError(a.info, 'instantiateGenericParamList: ' + q.name.s);
    end;
    s.typ := t;
    addDecl(c, s)
  end
end;

function GenericCacheGet(c: PContext; genericSym, instSym: PSym): PSym;
var
  i: int;
  a, b: PSym;
begin
  result := nil;
  for i := 0 to sonsLen(c.generics)-1 do begin
    if c.generics.sons[i].kind <> nkExprEqExpr then
      InternalError(genericSym.info, 'GenericCacheGet');
    a := c.generics.sons[i].sons[0].sym;
    if genericSym.id = a.id then begin
      b := c.generics.sons[i].sons[1].sym;
      if equalParams(b.typ.n, instSym.typ.n) = paramsEqual then begin
        //if gVerbosity > 0 then 
        //  MessageOut('found in cache: ' + getProcHeader(instSym));
        result := b; exit
      end
    end
  end
end;

procedure GenericCacheAdd(c: PContext; genericSym, instSym: PSym);
var
  n: PNode;
begin
  n := newNode(nkExprEqExpr);
  addSon(n, newSymNode(genericSym));
  addSon(n, newSymNode(instSym));
  addSon(c.generics, n);
end;

function generateInstance(c: PContext; fn: PSym; const pt: TIdTable;
                          const info: TLineInfo): PSym;
// generates an instantiated proc
var
  oldPrc, oldMod: PSym;
  oldP: PProcCon;
  n: PNode;
begin
  if c.InstCounter > 1000 then InternalError(fn.ast.info, 'nesting too deep');
  inc(c.InstCounter);
  oldP := c.p; // restore later
  // NOTE: for access of private fields within generics from a different module
  // and other identifiers we fake the current module temporarily!
  oldMod := c.module;
  c.module := getModule(fn);
  result := copySym(fn, false);
  include(result.flags, sfFromGeneric);
  result.owner := getCurrOwner().owner;
  n := copyTree(fn.ast);
  result.ast := n;
  pushOwner(result);
  openScope(c.tab);
  if (n.sons[genericParamsPos] = nil) then 
    InternalError(n.info, 'generateInstance');
  n.sons[namePos] := newSymNode(result);
  pushInfoContext(info);

  instantiateGenericParamList(c, n.sons[genericParamsPos], pt);
  n.sons[genericParamsPos] := nil;
  // semantic checking for the parameters:
  if n.sons[paramsPos] <> nil then begin
    semParamList(c, n.sons[ParamsPos], nil, result);
    addParams(c, result.typ.n);
  end
  else begin
    result.typ := newTypeS(tyProc, c);
    addSon(result.typ, nil);
  end;

  // now check if we have already such a proc generated
  oldPrc := GenericCacheGet(c, fn, result);
  if oldPrc = nil then begin
    // add it here, so that recursive generic procs are possible:
    GenericCacheAdd(c, fn, result);
    addDecl(c, result);
    if n.sons[codePos] <> nil then begin
      c.p := newProcCon(result);
      if result.kind in [skProc, skConverter] then begin
        addResult(c, result.typ.sons[0], n.info);
        addResultNode(c, n);
      end;
      n.sons[codePos] := semStmtScope(c, n.sons[codePos]);
    end
  end
  else
    result := oldPrc;
  popInfoContext();
  closeScope(c.tab); // close scope for parameters
  popOwner();
  c.p := oldP; // restore
  c.module := oldMod;
  dec(c.InstCounter);
end;

procedure checkConstructedType(const info: TLineInfo; t: PType);
begin
  if (tfAcyclic in t.flags)
  and (skipTypes(t, abstractInst).kind <> tyObject) then
    liMessage(info, errInvalidPragmaX, 'acyclic');
  if computeSize(t) < 0 then
    liMessage(info, errIllegalRecursionInTypeX, typeToString(t));
  if (t.kind = tyVar) and (t.sons[0].kind = tyVar) then
    liMessage(info, errVarVarTypeNotAllowed);
end;

type
  TReplTypeVars = record
    c: PContext;
    typeMap: TIdTable; // map PType to PType
    symMap: TIdTable;  // map PSym to PSym
    info: TLineInfo;
  end;

function ReplaceTypeVarsT(var cl: TReplTypeVars; t: PType): PType; forward;
function ReplaceTypeVarsS(var cl: TReplTypeVars; s: PSym): PSym; forward;

function ReplaceTypeVarsN(var cl: TReplTypeVars; n: PNode): PNode;
var
  i, Len: int;
begin
  result := nil;
  if n <> nil then begin
    result := copyNode(n);
    result.typ := ReplaceTypeVarsT(cl, n.typ);
    case n.kind of
      nkNone..pred(nkSym), succ(nkSym)..nkNilLit: begin end;
      nkSym: begin
        result.sym := ReplaceTypeVarsS(cl, n.sym);
      end;
      else begin
        len := sonsLen(n);
        if len > 0 then begin
          newSons(result, len);
          for i := 0 to len-1 do
            result.sons[i] := ReplaceTypeVarsN(cl, n.sons[i]);
        end
      end
    end
  end
end;

function ReplaceTypeVarsS(var cl: TReplTypeVars; s: PSym): PSym;
begin
  if s = nil then begin result := nil; exit end;
  result := PSym(idTableGet(cl.symMap, s));
  if (result = nil) then begin
    result := copySym(s, false);
    include(result.flags, sfFromGeneric);
    idTablePut(cl.symMap, s, result);
    result.typ := ReplaceTypeVarsT(cl, s.typ);
    result.owner := s.owner;
    result.ast := ReplaceTypeVarsN(cl, s.ast);
  end
end;

function lookupTypeVar(cl: TReplTypeVars; t: PType): PType;
begin
  result := PType(idTableGet(cl.typeMap, t));
  if result = nil then
    liMessage(t.sym.info, errCannotInstantiateX, typeToString(t))
  else if result.kind = tyGenericParam then
    InternalError(cl.info, 'substitution with generic parameter');
end;

function ReplaceTypeVarsT(var cl: TReplTypeVars; t: PType): PType;
var
  i: int;
  body, newbody, x, header: PType;
begin
  result := t;
  if t = nil then exit;
  case t.kind of
    tyGenericParam: begin
      result := lookupTypeVar(cl, t);
    end;
    tyGenericInvokation: begin
      body := t.sons[0];
      if body.kind <> tyGenericBody then
        InternalError(cl.info, 'no generic body');
      header := nil;
      for i := 1 to sonsLen(t)-1 do begin
        if t.sons[i].kind = tyGenericParam then begin
          x := lookupTypeVar(cl, t.sons[i]);
          if header = nil then header := copyType(t, t.owner, false);
          header.sons[i] := x;
        end
        else
          x := t.sons[i];
        idTablePut(cl.typeMap, body.sons[i-1], x);
      end;
      // cycle detection:
      if header = nil then header := t;
      result := searchInstTypes(gInstTypes, header);
      if result <> nil then exit;
      
      result := newType(tyGenericInst, t.sons[0].owner);
      for i := 0 to sonsLen(t)-1 do begin
        // if one of the params is not concrete, we cannot do anything
        // but we already raised an error!
        addSon(result, header.sons[i]);
      end;
      // add these before recursive calls:
      idTablePut(gInstTypes, header, result);

      newbody := ReplaceTypeVarsT(cl, lastSon(body));
      newbody.n := ReplaceTypeVarsN(cl, lastSon(body).n);
      addSon(result, newbody);
      //writeln(output, ropeToStr(Typetoyaml(newbody)));
      checkConstructedType(cl.info, newbody);
    end;
    tyGenericBody: begin
      InternalError(cl.info, 'ReplaceTypeVarsT: tyGenericBody');
      result := ReplaceTypeVarsT(cl, lastSon(t));
    end 
    else begin
      if containsGenericType(t) then begin
        result := copyType(t, t.owner, false);
        for i := 0 to sonsLen(result)-1 do
          result.sons[i] := ReplaceTypeVarsT(cl, result.sons[i]);
        result.n := ReplaceTypeVarsN(cl, result.n);
        if result.Kind in GenericTypes then 
          liMessage(cl.info, errCannotInstantiateX, TypeToString(t, preferName));
        //writeln(output, ropeToStr(Typetoyaml(result)));
        //checkConstructedType(cl.info, result);
      end
    end
  end
end;

function instGenericContainer(c: PContext; n: PNode; header: PType): PType;
var
  cl: TReplTypeVars;
begin
  InitIdTable(cl.symMap);
  InitIdTable(cl.typeMap);
  cl.info := n.info;
  cl.c := c;
  result := ReplaceTypeVarsT(cl, header);
end;

function generateTypeInstance(p: PContext; const pt: TIdTable;
                              arg: PNode; t: PType): PType;
var
  cl: TReplTypeVars;
begin
  InitIdTable(cl.symMap);
  copyIdTable(cl.typeMap, pt);
  cl.info := arg.info;
  cl.c := p;
  pushInfoContext(arg.info);
  result := ReplaceTypeVarsT(cl, t);
  popInfoContext();
end;

function partialSpecialization(c: PContext; n: PNode; s: PSym): PNode;
begin
  result := n;
end;
