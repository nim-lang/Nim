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
    typeMap: TIdTable;            // map PType to PType
    symMap: TIdTable;             // map PSym to PSym
    fn: PSym;
    module: PSym;
    //newOwner: PSym;
    instantiator: TLineInfo;
  end;
  PInstantiateClosure = ^TInstantiateClosure;
  PInstClosure = PInstantiateClosure;

function instantiateTree(c: PInstantiateClosure; t: PNode): PNode; forward;
function instantiateSym(c: PInstantiateClosure; sym: PSym): PSym; forward;
function instantiateType(c: PInstantiateClosure; typ: PType): PType; forward;

function containsGenericTypeIter(t: PType; closure: PObject): bool;
begin
  result := t.kind in GenericTypes;
end;

function containsGenericType(t: PType): bool;
begin
  result := iterOverType(t, containsGenericTypeIter, nil);
end;

function instTypeNode(c: PInstantiateClosure; n: PNode): PNode;
var
  i: int;
begin
  result := nil;
  if n <> nil then begin
    result := copyNode(n);
    result.typ := instantiateType(c, n.typ);
    case n.kind of
      nkNone..nkNilLit: begin // a leaf
      end;
      else begin
        for i := 0 to sonsLen(n)-1 do
          addSon(result, instTypeNode(c, n.sons[i]));
      end
    end
  end
end;

procedure genericToConcreteTypeKind(t: PType);
var
  body: PNode;
begin
  if (t.kind = tyGeneric) and (t.sym <> nil) then begin
    body := t.sym.ast.sons[2];
    case body.kind of
      nkObjectTy: t.kind := tyObject;
      nkTupleTy: t.kind := tyTuple;
      nkRefTy: t.kind := tyRef;
      nkPtrTy: t.kind := tyPtr;
      nkVarTy: t.kind := tyVar;
      nkProcTy: t.kind := tyProc;
      else InternalError('genericToConcreteTypeKind');
    end
  end
end;

function instantiateType(c: PInstantiateClosure; typ: PType): PType;
var
  i: int;
begin
  if typ = nil then begin result := nil; exit end;
  result := PType(idTableGet(c.typeMap, typ));
  if result <> nil then exit;
  //if typ.kind = tyOpenArray then
  //  liMessage(c.instantiator, warnUser, 'instantiating type for: openarray');
  if containsGenericType(typ) then begin
    result := copyType(typ, typ.owner, false);
    idTablePut(c.typeMap, typ, result); // to avoid cycles
    for i := 0 to sonsLen(result)-1 do
      result.sons[i] := instantiateType(c, result.sons[i]);
    if result.n <> nil then
      result.n := instTypeNode(c, result.n);
    genericToConcreteTypeKind(result);
  end
  else
    result := typ;
  if result.Kind in GenericTypes then begin
    liMessage(c.instantiator, errCannotInstantiateX,
              TypeToString(typ, preferName));
  end
  else if result.kind = tyVar then begin
    if result.sons[0].kind = tyVar then
      liMessage(c.instantiator, errVarVarTypeNotAllowed);
  end;
end;

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

function instantiateTree(c: PInstantiateClosure; t: PNode): PNode;
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
  if (n.kind <> nkGenericParams) then 
    InternalError(n.info, 'instantiateGenericParamList');
  for i := 0 to sonsLen(n)-1 do begin
    if n.sons[i].kind = nkDefaultTypeParam then begin
      internalError(n.sons[i].info,
        'instantiateGenericParamList() to implement');
      // XXX
    end;
    if (n.sons[i].kind <> nkSym) then 
      InternalError(n.info, 'instantiateGenericParamList');
    q := n.sons[i].sym;
    s := newSym(skType, q.name, getCurrOwner());
    t := PType(IdTableGet(pt, q.typ));
    if t = nil then
      liMessage(n.sons[i].info, errCannotInstantiateX, s.name.s);
    if (t.kind = tyGenericParam) then
      InternalError(n.info, 'instantiateGenericParamList');    
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
  result := copySym(fn, false);
  include(result.flags, sfFromGeneric);
  //include(fn.flags, sfFromGeneric);
  result.owner := getCurrOwner().owner;
  //idTablePut(c.mapping, fn, result);
  n := copyTree(fn.ast);
  result.ast := n;
  pushOwner(result);
  openScope(c.tab);
  if (n.sons[genericParamsPos] = nil) then 
    InternalError(n.info, 'generateInstance');
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
      if result.kind in [skProc, skConverter] then begin
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
  popOwner();
  c.p := oldP; // restore
end;

function generateTypeInstance(p: PContext; const pt: TIdTable;
                              const instantiator: TLineInfo; t: PType): PType;
var
  c: PInstantiateClosure;
begin
  new(c);
{@ignore}
  fillChar(c^, sizeof(c^), 0);
{@emit}
  copyIdTable(c.typeMap, pt);
  InitIdTable(c.symMap);
  c.fn := nil;
  c.instantiator := instantiator;
  c.module := p.module;
  result := instantiateType(c, t);
end;

function newInstantiateClosure(p: PContext;
          const instantiator: TLineInfo): PInstantiateClosure;
begin
  new(result);
{@ignore}
  fillChar(result^, sizeof(result^), 0);
{@emit}
  InitIdTable(result.typeMap);
  InitIdTable(result.symMap);
  result.fn := nil;
  result.instantiator := instantiator;
  result.module := p.module;
end;

function partialSpecialization(c: PContext; n: PNode; s: PSym): PNode;
begin
  result := n;
end;
