//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// This module does the instantiation of generic procs and types.

function generateInstance(c: PContext; fn: PSym; const pt: TIdTable;
                          const instantiator: TLineInfo): PSym; forward;
// generates an instantiated proc

type
  TInstantiateClosure = object(NObject)
    mapping: TIdTable;            // map {ptype, psym} to {ptype, psym}
    fn: PSym;
    module: PSym;
    newOwner: PSym;
    instantiator: TLineInfo;
  end;
  PInstClosure = ^TInstantiateClosure;

function instantiateTree(var c: TInstantiateClosure; t: PNode): PNode; forward;

function instantiateSym(var c: TInstantiateClosure; sym: PSym): PSym; forward;

function containsGenericTypeIter(t: PType; closure: PObject): bool;
begin
  result := t.kind in GenericTypes;
end;

function containsGenericType(t: PType): bool;
begin
  result := iterOverType(t, containsGenericTypeIter, nil);
end;


function instantiateTypeMutator(typ: PType; c: PObject): PType;
begin
  result := PType(idTableGet(PInstClosure(c).mapping, typ));
  if result <> nil then exit;
  if containsGenericType(typ) then begin
    result := copyType(typ, PInstClosure(c).newOwner);
    idTablePut(PInstClosure(c).mapping, typ, result)
  end
  else
    result := typ;
  if result.Kind in GenericTypes then begin
    liMessage(PInstClosure(c).instantiator, errCannotInstantiateX,
              TypeToString(typ, preferName));
  end;
end;

function instantiateType(var c: TInstantiateClosure; typ: PType): PType;
begin
  result := mutateType(typ, instantiateTypeMutator, {@cast}PObject(addr(c)));
end;

function instantiateSym(var c: TInstantiateClosure; sym: PSym): PSym;
begin
  if sym = nil then begin result := nil; exit end; // BUGFIX
  result := PSym(idTableGet(c.mapping, sym));
  if (result = nil) then begin
    if (sym.owner.id = c.fn.id) or (sym.id = c.fn.id) then begin
      result := copySym(sym, nil);
      if sym.id = c.fn.id then c.newOwner := result;
      include(result.flags, sfIsCopy);
      idTablePut(c.mapping, sym, result); // BUGFIX
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

function instantiateTree(var c: TInstantiateClosure; t: PNode): PNode;
var
  len, i: int;
begin
  if t = nil then begin result := nil; exit end;
  result := copyNode(t);
  if result.typ <> nil then result.typ := instantiateType(c, result.typ);
  case t.kind of
    nkNone..pred(nkSym), succ(nkSym)..nkNilLit: begin end;
    nkSym: begin
      if result.sym <> nil then result.sym := instantiateSym(c, result.sym);
    end
    else begin
      len := sonsLen(t);
      if len > 0 then begin
        newSons(result, len);
        for i := 0 to len-1 do
          result.sons[i] := instantiateTree(c, t.sons[i]);
      end
    end
  end
end;

procedure instantiateGenericParamList(c: PContext; n: PNode;
                                      const pt: TIdTable);
var
  i: int;
  s, q: PSym;
  t: PType;
begin
  assert(n.kind = nkGenericParams);
  for i := 0 to sonsLen(n)-1 do begin
    if n.sons[i].kind = nkDefaultTypeParam then begin
      internalError(n.sons[i].info,
        'instantiateGenericParamList() to implement');
      // XXX
    end;
    assert(n.sons[i].kind = nkSym);
    q := n.sons[i].sym;
    s := newSym(skType, q.name, getCurrOwner(c));
    t := PType(IdTableGet(pt, q.typ));
    if t = nil then liMessage(n.sons[i].info, errCannotInstantiateX, s.name.s);
    assert(t.kind <> tyGenericParam);
    s.typ := t;
    addDecl(c, s);
  end
end;

function GenericCacheGet(c: PContext; genericSym, instSym: PSym): PSym;
var
  i: int;
  a, b: PSym;
begin
  result := nil;
  for i := 0 to sonsLen(c.generics)-1 do begin
    assert(c.generics.sons[i].kind = nkExprEqExpr);
    a := c.generics.sons[i].sons[0].sym;
    if genericSym.id = a.id then begin
      b := c.generics.sons[i].sons[1].sym;
      if equalParams(b.typ.n, instSym.typ.n) = paramsEqual then begin
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

procedure semParamList(c: PContext; n: PNode; s: PSym); forward;
procedure addParams(c: PContext; n: PNode); forward;
procedure addResult(c: PContext; t: PType; const info: TLineInfo); forward;
procedure addResultNode(c: PContext; n: PNode); forward;

function generateInstance(c: PContext; fn: PSym; const pt: TIdTable;
                          const instantiator: TLineInfo): PSym;
// generates an instantiated proc
var
  oldPrc: PSym;
  oldP: PProcCon;
  n: PNode;
begin
  oldP := c.p; // restore later
  result := copySym(fn, getCurrOwner(c));
  result.id := getId();
  n := copyTree(fn.ast);
  result.ast := n;
  pushOwner(c, result);
  openScope(c.tab);
  assert(n.sons[genericParamsPos] <> nil);
  n.sons[namePos] := newSymNode(result);
  pushInfoContext(instantiator);

  instantiateGenericParamList(c, n.sons[genericParamsPos], pt);
  n.sons[genericParamsPos] := nil;
  // semantic checking for the parameters:
  if n.sons[paramsPos] <> nil then begin
    semParamList(c, n.sons[ParamsPos], result);
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
    addDecl(c, result);
    if n.sons[codePos] <> nil then begin
      c.p := newProcCon(result);
      if result.kind = skProc then begin
        addResult(c, result.typ.sons[0], n.info);
        addResultNode(c, n);
      end;
      n.sons[codePos] := semStmtScope(c, n.sons[codePos]);
    end;
    GenericCacheAdd(c, fn, result);
  end
  else
    result := oldPrc;
  popInfoContext();
  closeScope(c.tab); // close scope for parameters
  popOwner(c);
  c.p := oldP; // restore
end;

function generateTypeInstance(p: PContext; const pt: TIdTable;
                              const instantiator: TLineInfo; t: PType): PType;
var
  c: TInstantiateClosure;
begin
  c.mapping := pt; // making a copy is not necessary
  c.fn := nil;
  c.instantiator := instantiator;
  c.module := p.module;
  c.newOwner := getCurrOwner(p);
  result := instantiateType(c, t);
end;

function partialSpecialization(c: PContext; n: PNode; s: PSym): PNode;
begin
  result := n;
end;
