//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

// This module implements the signature matching for resolving
// the call to overloaded procs, generic procs and operators.

type
  TCandidateState = (csEmpty, csMatch, csNoMatch);
  TCandidate = record
    exactMatches: int;
    subtypeMatches: int;
    intConvMatches: int; // conversions to int are not as expensive
    convMatches: int;
    genericMatches: int;
    state: TCandidateState;
    callee: PType; // may not be nil!
    calleeSym: PSym; // may be nil
    call: PNode; // modified call
    bindings: TIdTable; // maps sym-ids to types
    baseTypeMatch: bool; // needed for conversions from T to openarray[T]
                         // for example
  end;
  TTypeRelation = (isNone, isConvertible, isIntConv, isSubtype, 
                   isGeneric, isEqual);
  // order is important!

procedure initCandidate(out c: TCandidate; callee: PType);
begin
  c.exactMatches := 0;
  c.subtypeMatches := 0;
  c.convMatches := 0;
  c.intConvMatches := 0;
  c.genericMatches := 0;
  c.state := csEmpty;
  c.callee := callee;
  c.calleeSym := nil;
  c.call := nil;
  c.baseTypeMatch := false;
  initIdTable(c.bindings);
  assert(c.callee <> nil);
end;

function cmpCandidates(const a, b: TCandidate): int;
begin
  result := a.exactMatches - b.exactMatches;
  if result <> 0 then exit;
  result := a.genericMatches - b.genericMatches;
  if result <> 0 then exit;
  result := a.subtypeMatches - b.subtypeMatches;
  if result <> 0 then exit;
  result := a.intConvMatches - b.intConvMatches;
  if result <> 0 then exit;
  result := a.convMatches - b.convMatches;
end;

procedure writeMatches(const c: TCandidate);
begin
  Writeln(output, 'exact matches: ' + toString(c.exactMatches));
  Writeln(output, 'subtype matches: ' + toString(c.subtypeMatches));
  Writeln(output, 'conv matches: ' + toString(c.convMatches));
  Writeln(output, 'intconv matches: ' + toString(c.intConvMatches));
  Writeln(output, 'generic matches: ' + toString(c.genericMatches));
end;

function getNotFoundError(c: PContext; n: PNode): string;
// Gives a detailed error message; this is seperated from semDirectCall,
// as semDirectCall is already pretty slow (and we need this information only
// in case of an error).
var
  sym: PSym;
  o: TOverloadIter;
  i: int;
  candidates: string;
begin
  result := msgKindToString(errTypeMismatch);
  for i := 1 to sonsLen(n)-1 do begin
    result := result +{&} typeToString(n.sons[i].typ);
    if i <> sonsLen(n)-1 then result := result + ', ';
  end;
  addChar(result, ')');
  candidates := '';
  sym := initOverloadIter(o, c, n.sons[0]);
  while sym <> nil do begin
    if sym.kind in [skProc, skIterator, skConverter] then
      candidates := candidates +{&} getProcHeader(sym) +{&} nl;
    sym := nextOverloadIter(o, c, n.sons[0]);
  end;
  if candidates <> '' then
    result := result +{&} nl +{&} msgKindToString(errButExpected) +{&} nl
            +{&} candidates;
end;

function typeRel(var mapping: TIdTable; f, a: PType): TTypeRelation; overload;
  forward;

function concreteType(t: PType): PType;
begin
  case t.kind of
    tyArrayConstr: begin  // make it an array
      result := newType(tyArray, t.owner);
      addSon(result, t.sons[0]); // XXX: t.owner is wrong for ID!
      addSon(result, t.sons[1]); // XXX: semantic checking for the type?
    end;
    tyNil: result := nil; // what should it be?
    else result := t // Note: empty is valid here
  end
end;

function handleRange(f, a: PType; min, max: TTypeKind): TTypeRelation;
var
  k: TTypeKind;
begin
  if a.kind = f.kind then
    result := isEqual
  else begin
    k := skipRange(a).kind;
    if k = f.kind then
      result := isSubtype
    else if (f.kind = tyInt) and (k in [tyInt..tyInt32]) then 
      result := isIntConv
    else if (k >= min) and (k <= max) then
      result := isConvertible
    else
      result := isNone
  end
end;

function handleFloatRange(f, a: PType): TTypeRelation;
var
  k: TTypeKind;
begin
  if a.kind = f.kind then
    result := isEqual
  else begin
    k := skipRange(a).kind;
    if k = f.kind then
      result := isSubtype
    else if (k >= tyFloat) and (k <= tyFloat128) then
      result := isConvertible
    else
      result := isNone
  end
end;

function isObjectSubtype(a, f: PType): bool;
var
  t: PType;
begin
  t := a;
  while (t <> nil) and (t.id <> f.id) do t := base(t);
  result := t <> nil
end;

function minRel(a, b: TTypeRelation): TTypeRelation;
begin
  if a <= b then result := a else result := b
end;

function tupleRel(var mapping: TIdTable; f, a: PType): TTypeRelation;
var
  i: int;
  x, y: PSym;
  m: TTypeRelation;
begin
  result := isNone;
  if sonsLen(a) = sonsLen(f) then begin
    result := isEqual;
    for i := 0 to sonsLen(f)-1 do begin
      m := typeRel(mapping, f.sons[i], a.sons[i]);
      if m < isSubtype then begin result := isNone; exit end;
      result := minRel(result, m);
    end;
    if (f.n <> nil) and (a.n <> nil) then begin
      for i := 0 to sonsLen(f.n)-1 do begin
        // check field names:
        if f.n.sons[i].kind <> nkSym then InternalError(f.n.info, 'tupleRel');
        if a.n.sons[i].kind <> nkSym then InternalError(a.n.info, 'tupleRel');
        x := f.n.sons[i].sym;
        y := a.n.sons[i].sym;
        if x.name.id <> y.name.id then begin
          result := isNone; exit
        end
      end
    end
  end
end;

function typeRel(var mapping: TIdTable; f, a: PType): TTypeRelation;
var
  x, concrete: PType;
  i: Int;
  m: TTypeRelation;
begin // is a subtype of f?
  result := isNone;
  assert(f <> nil);
  assert(a <> nil);
  if (a.kind = tyGenericInst) and (skipVar(f).kind <> tyGeneric) then begin
    result := typeRel(mapping, f, lastSon(a));
    exit
  end;
  if (a.kind = tyVar) and (f.kind <> tyVar) then begin
    result := typeRel(mapping, f, a.sons[0]);
    exit
  end;
  case f.kind of
    tyEnum: begin
      if (a.kind = f.kind) and (a.id = f.id) then result := isEqual
      else if (skipRange(a).id = f.id) then result := isSubtype
    end;
    tyBool, tyChar: begin
      if (a.kind = f.kind) then result := isEqual
      else if skipRange(a).kind = f.kind then result := isSubtype
    end;
    tyRange: begin
      if (a.kind = f.kind) then begin
        result := typeRel(mapping, base(a), base(f));
        if result < isGeneric then result := isNone
      end
      else if skipRange(f).kind = a.kind then
        result := isConvertible // a convertible to f
    end;
    tyInt:   result := handleRange(f, a, tyInt8, tyInt32);
    tyInt8:  result := handleRange(f, a, tyInt8, tyInt8);
    tyInt16: result := handleRange(f, a, tyInt8, tyInt16);
    tyInt32: result := handleRange(f, a, tyInt, tyInt32);
    tyInt64: result := handleRange(f, a, tyInt, tyInt64);
    tyFloat: result := handleFloatRange(f, a);
    tyFloat32: result := handleFloatRange(f, a);
    tyFloat64: result := handleFloatRange(f, a);
    tyFloat128: result := handleFloatRange(f, a);

    tyVar: begin
      if (a.kind = f.kind) then
        result := typeRel(mapping, base(f), base(a))
      else
        result := typeRel(mapping, base(f), a)
    end;
    tyArray, tyArrayConstr: begin // tyArrayConstr cannot happen really, but
      // we wanna be safe here
      case a.kind of
        tyArray: begin
          result := minRel(typeRel(mapping, f.sons[0], a.sons[0]),
                           typeRel(mapping, f.sons[1], a.sons[1]));
          if result < isGeneric then result := isNone;
        end;
        tyArrayConstr: begin
          result := typeRel(mapping, f.sons[1], a.sons[1]);
          if result < isGeneric then 
            result := isNone
          else begin
            if (result <> isGeneric) and (lengthOrd(f) <> lengthOrd(a)) then
              result := isNone
            else if f.sons[0].kind in GenericTypes then
              result := minRel(result, typeRel(mapping, f.sons[0], a.sons[0]));
          end
        end;
        else begin end
      end
    end;
    tyOpenArray: begin
      case a.Kind of
        tyOpenArray: begin
          result := typeRel(mapping, base(f), base(a));
          if result < isGeneric then result := isNone
        end;
        tyArrayConstr: begin
          if (f.sons[0].kind <> tyGenericParam) and
              (a.sons[1].kind = tyEmpty) then 
            result := isSubtype // [] is allowed here
          else if typeRel(mapping, base(f), a.sons[1]) >= isGeneric then
            result := isSubtype;
        end;
        tyArray: begin
          if (f.sons[0].kind <> tyGenericParam) and
              (a.sons[1].kind = tyEmpty) then 
            result := isSubtype
          else if typeRel(mapping, base(f), a.sons[1]) >= isGeneric then
            result := isConvertible
        end;
        tySequence: begin
          if (f.sons[0].kind <> tyGenericParam) and
              (a.sons[0].kind = tyEmpty) then 
            result := isConvertible
          else if typeRel(mapping, base(f), a.sons[0]) >= isGeneric then
            result := isConvertible;
        end
        else begin end
      end
    end;
    tySequence: begin
      case a.Kind of
        tyNil: result := isSubtype;
        tySequence: begin
          if (f.sons[0].kind <> tyGenericParam) and
              (a.sons[0].kind = tyEmpty) then 
            result := isSubtype
          else begin
            result := typeRel(mapping, f.sons[0], a.sons[0]);
            if result < isGeneric then result := isNone
          end
        end;
        else begin end
      end
    end;
    tyForward: InternalError('forward type in typeRel()');
    tyNil: begin
      if a.kind = f.kind then result := isEqual
    end;
    tyTuple: begin
      if a.kind = tyTuple then result := tupleRel(mapping, f, a);
    end;
    tyObject: begin
      if a.kind = tyObject then begin
        if a.id = f.id then result := isEqual
        else if isObjectSubtype(a, f) then result := isSubtype
      end
    end;
    tySet: begin
      if a.kind = tySet then begin
        if (f.sons[0].kind <> tyGenericParam) and
            (a.sons[0].kind = tyEmpty) then 
          result := isSubtype
        else begin
          result := typeRel(mapping, f.sons[0], a.sons[0]);
          if result <= isConvertible then result := isNone // BUGFIX!
        end
      end
    end;
    tyPtr: begin
      case a.kind of
        tyPtr: begin
          result := typeRel(mapping, base(f), base(a));
          if result <= isConvertible then result := isNone
        end;
        tyNil: result := isSubtype
        else begin end
      end
    end;
    tyRef: begin
      case a.kind of
        tyRef: begin
          result := typeRel(mapping, base(f), base(a));
          if result <= isConvertible then result := isNone
        end;
        tyNil: result := isSubtype
        else begin end
      end
    end;
    tyProc: begin
      case a.kind of
        tyNil: result := isSubtype;
        tyProc: begin
          if (sonsLen(f) = sonsLen(a)) and (f.callconv = a.callconv) then begin
            // Note: We have to do unification for the parameters before the
            // return type! Otherwise it'd be counter-intuitive for the standard
            // Nimrod syntax. For the C-based syntax it IS counter-intuitive.
            // But that is one of the reasons a standard syntax was picked.
            result := isEqual; // start with maximum; also correct for no
                               // params at all
            for i := 1 to sonsLen(f)-1 do begin
              m := typeRel(mapping, f.sons[i], a.sons[i]);
              if (m = isNone) and (typeRel(mapping, a.sons[i],
                                           f.sons[i]) = isSubtype) then begin
                // allow ``f.son`` as subtype of ``a.son``!
                result := isConvertible;
              end
              else if m < isSubtype then begin
                result := isNone; exit
              end
              else result := minRel(m, result)
            end;
            if f.sons[0] <> nil then begin
              if a.sons[0] <> nil then begin
                m := typeRel(mapping, f.sons[0], a.sons[0]);
                // Subtype is sufficient for return types!
                if m < isSubtype then result := isNone
                else if m = isSubtype then result := isConvertible
                else result := minRel(m, result)
              end
              else
                result := isNone
            end
            else if a.sons[0] <> nil then
              result := isNone
          end
        end
        else begin end
      end
    end;
    tyPointer: begin
      case a.kind of
        tyPointer: result := isEqual;
        tyNil: result := isSubtype;
        tyRef, tyPtr, tyProc, tyCString: result := isConvertible;
        else begin end
      end
    end;
    tyString: begin
      case a.kind of
        tyString: result := isEqual;
        tyNil:    result := isSubtype;
        else begin end
      end
    end;
    tyCString: begin
      // conversion from string to cstring is automatic:
      case a.Kind of
        tyCString: result := isEqual;
        tyNil: result := isSubtype;
        tyString: result := isConvertible;
        tyPtr: if a.sons[0].kind = tyChar then result := isConvertible;
        tyArray: begin
          if (firstOrd(a.sons[0]) = 0)
              and (skipRange(a.sons[0]).kind in [tyInt..tyInt64])
              and (a.sons[1].kind = tyChar) then
            result := isConvertible;
        end
        else begin end
      end
    end;

    tyEmpty: begin
      if a.kind = tyEmpty then result := isEqual;
    end;
    tyAnyEnum: begin
      case a.kind of
        tyRange: result := typeRel(mapping, f, base(a));
        tyEnum:  result := isEqual;
        else begin end
      end
    end;
    tyGenericInst: begin
      result := typeRel(mapping, lastSon(f), a);
    end;
    tyGeneric: begin
      x := PType(idTableGet(mapping, f));
      if x = nil then begin
        assert(f.containerID <> 0);
        assert(lastSon(f) = nil);
        if (a.kind = tyGenericInst) and (f.containerID = a.containerID) and
           (sonsLen(a) = sonsLen(f)) then begin
          for i := 0 to sonsLen(f)-2 do begin
            if typeRel(mapping, f.sons[i], a.sons[i]) < isGeneric then exit;
          end;
          result := isGeneric;
          idTablePut(mapping, f, a);
        end
      end
      else begin
        result := typeRel(mapping, x, a) // check if it fits
      end
    end;
    tyGenericParam: begin
      x := PType(idTableGet(mapping, f));
      if x = nil then begin
        if sonsLen(f) = 0 then begin // no constraints
          concrete := concreteType(a);
          if concrete <> nil then begin
            idTablePut(mapping, f, concrete);
            result := isGeneric
          end;
        end
        else begin
          // check constraints:
          for i := 0 to sonsLen(f)-1 do begin
            if typeRel(mapping, f.sons[i], a) >= isSubtype then begin
              concrete := concreteType(a);
              if concrete <> nil then begin
                idTablePut(mapping, f, concrete);
                result := isGeneric
              end;
              break
            end
          end
        end
      end
      else if a.kind = tyEmpty then
        result := isGeneric
      else begin
        result := typeRel(mapping, x, a); // check if it fits
      end
    end
    else internalError('typeRel(' +{&} typeKindToStr[f.kind] +{&} ')');
  end
end;

function cmpTypes(f, a: PType): TTypeRelation;
var
  mapping: TIdTable;
begin
  InitIdTable(mapping);
  result := typeRel(mapping, f, a);
end;

function getInstantiatedType(c: PContext; arg: PNode; const m: TCandidate;
                             f: PType): PType;
begin
  result := PType(idTableGet(m.bindings, f));
  if result = nil then begin
    result := generateTypeInstance(c, m.bindings, arg.info, f);
  end;
  if result = nil then InternalError(arg.info, 'getInstantiatedType');
end;

function implicitConv(kind: TNodeKind; f: PType; arg: PNode;
                      const m: TCandidate; c: PContext): PNode;
begin
  result := newNodeI(kind, arg.info);
  if containsGenericType(f) then
    result.typ := getInstantiatedType(c, arg, m, f)
  else
    result.typ := f;
  if result.typ = nil then InternalError(arg.info, 'implicitConv');
  addSon(result, nil);
  addSon(result, arg);
end;

function userConvMatch(c: PContext; var m: TCandidate; f, a: PType;
                       arg: PNode): PNode;
var
  i: int;
  src, dest: PType;
  s: PNode;
begin
  result := nil;
  for i := 0 to length(c.converters)-1 do begin
    src := c.converters[i].typ.sons[1];
    dest := c.converters[i].typ.sons[0];
    if (typeRel(m.bindings, f, dest) = isEqual) and
       (typeRel(m.bindings, src, a) = isEqual) then begin
      s := newSymNode(c.converters[i]);
      s.typ := c.converters[i].typ;
      s.info := arg.info;
      result := newNodeIT(nkHiddenCallConv, arg.info, s.typ.sons[0]);
      addSon(result, s);
      addSon(result, copyTree(arg));
      inc(m.convMatches);
      exit
    end
  end
end;

function ParamTypesMatch(c: PContext; var m: TCandidate; f, a: PType;
                         arg: PNode): PNode;
var
  r: TTypeRelation;
begin
  r := typeRel(m.bindings, f, a);
  case r of
    isConvertible: begin
      inc(m.convMatches);
      result := implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c);
    end;
    isIntConv: begin
      inc(m.intConvMatches);
      result := implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c);
    end;
    isSubtype: begin
      inc(m.subtypeMatches);
      result := implicitConv(nkHiddenSubConv, f, copyTree(arg), m, c);
    end;
    isGeneric: begin
      inc(m.genericMatches);
      result := copyTree(arg);
      result.typ := getInstantiatedType(c, arg, m, f);
      // BUG: f may not be the right key!
      if (skipVarGeneric(f).kind in [tyTuple, tyOpenArray]) then
        // BUGFIX: must pass length implicitely
        result := implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c);
    end;
    isEqual: begin
      inc(m.exactMatches);
      result := copyTree(arg);
      if (skipVarGeneric(f).kind in [tyTuple, tyOpenArray]) then
        // BUGFIX: must pass length implicitely
        result := implicitConv(nkHiddenStdConv, f, copyTree(arg), m, c);
    end;
    isNone: begin
      result := userConvMatch(c, m, f, a, arg);
      // check for a base type match, which supports openarray[T] without []
      // constructor in a call:
      if (result = nil) and (f.kind = tyOpenArray) then begin
        r := typeRel(m.bindings, base(f), a);
        if r >= isGeneric then begin
          inc(m.convMatches);
          result := copyTree(arg);
          if r = isGeneric then
            result.typ := getInstantiatedType(c, arg, m, base(f));
          m.baseTypeMatch := true;
        end
        else
          result := userConvMatch(c, m, base(f), a, arg);
      end
    end
  end
end;

function IndexTypesMatch(c: PContext; f, a: PType; arg: PNode): PNode;
var
  m: TCandidate;
begin
  initCandidate(m, f);
  result := paramTypesMatch(c, m, f, a, arg)
end;

procedure setSon(father: PNode; at: int; son: PNode);
begin
  if sonsLen(father) <= at then
    setLength(father.sons, at+1);
  father.sons[at] := son;
end;

procedure matches(c: PContext; n: PNode; var m: TCandidate);
var
  f: int; // iterates over formal parameters
  a: int; // iterates over the actual given arguments
  formalLen: int;
  marker: TIntSet;
  container, arg: PNode; // constructed container
  formal: PSym;
begin
  f := 1;
  a := 1;
  m.state := csMatch; // until proven otherwise
  m.call := newNodeI(nkCall, n.info);
  m.call.typ := base(m.callee); // may be nil
  formalLen := sonsLen(m.callee.n);
  addSon(m.call, copyTree(n.sons[0]));
  IntSetInit(marker);
  container := nil;
  formal := nil;
  while a < sonsLen(n) do begin
    if n.sons[a].kind = nkExprEqExpr then begin
      // named param
      // check if m.callee has such a param:
      if n.sons[a].sons[0].kind <> nkIdent then begin
        liMessage(n.sons[a].info, errNamedParamHasToBeIdent);
        m.state := csNoMatch;
        exit
      end;
      formal := getSymFromList(m.callee.n, n.sons[a].sons[0].ident, 1);
      if formal = nil then begin
        // no error message!
        m.state := csNoMatch;
        exit;
      end;
      if IntSetContainsOrIncl(marker, formal.position) then begin
        // already in namedParams:
        liMessage(n.sons[a].info, errCannotBindXTwice, formal.name.s);
        m.state := csNoMatch;
        exit
      end;
      m.baseTypeMatch := false;
      arg := ParamTypesMatch(c, m, formal.typ, n.sons[a].typ,
                             n.sons[a].sons[1]);
      if (arg = nil) then begin m.state := csNoMatch; exit end;
      if m.baseTypeMatch then begin
        assert(container = nil);
        container := newNodeI(nkBracket, n.sons[a].info);
        addSon(container, arg);
        setSon(m.call, formal.position+1, container);
        if f <> formalLen-1 then container := nil;
      end
      else begin
        setSon(m.call, formal.position+1, arg);
      end
    end
    else begin
      // unnamed param
      if f >= formalLen then begin // too many arguments?
        if tfVarArgs in m.callee.flags then begin
          // is ok... but don't increment any counters...
          if skipVarGeneric(n.sons[a].typ).kind = tyString then
            // conversion to cstring
            addSon(m.call, implicitConv(nkHiddenStdConv,
              getSysType(tyCString), copyTree(n.sons[a]), m, c))
          else
            addSon(m.call, copyTree(n.sons[a]));
        end
        else if formal <> nil then begin
          m.baseTypeMatch := false;
          arg := ParamTypesMatch(c, m, formal.typ, n.sons[a].typ, n.sons[a]);
          if (arg <> nil) and m.baseTypeMatch and (container <> nil) then begin
            addSon(container, arg);
          end
          else begin
            m.state := csNoMatch;
            exit
          end;
        end
        else begin
          m.state := csNoMatch;
          exit
        end
      end
      else begin
        if m.callee.n.sons[f].kind <> nkSym then
          InternalError(n.sons[a].info, 'matches');
        formal := m.callee.n.sons[f].sym;
        if IntSetContainsOrIncl(marker, formal.position) then begin
          // already in namedParams:
          liMessage(n.sons[a].info, errCannotBindXTwice, formal.name.s);
          m.state := csNoMatch;
          exit
        end;
        m.baseTypeMatch := false;
        arg := ParamTypesMatch(c, m, formal.typ, n.sons[a].typ, n.sons[a]);
        if (arg = nil) then begin m.state := csNoMatch; exit end;
        if m.baseTypeMatch then begin
          assert(container = nil);
          container := newNodeI(nkBracket, n.sons[a].info);
          addSon(container, arg);
          setSon(m.call, formal.position+1,
            implicitConv(nkHiddenStdConv, formal.typ, container, m, c));
          if f <> formalLen-1 then container := nil;
        end
        else begin
          setSon(m.call, formal.position+1, arg);
        end;
        inc(f);
      end
    end;
    inc(a);
  end;
  // iterate over all formal params and check all are provided:
  f := 1;
  while f < sonsLen(m.callee.n) do begin
    formal := m.callee.n.sons[f].sym;
    if not IntSetContainsOrIncl(marker, formal.position) then begin
      if formal.ast = nil then begin // no default value
        m.state := csNoMatch; break
      end
      else begin
        // use default value:
        setSon(m.call, formal.position+1, copyTree(formal.ast));
      end
    end;
    inc(f);
  end
end;

function semDirectCall(c: PContext; n: PNode): PNode;
var
  sym: PSym;
  o: TOverloadIter;
  x, y, z: TCandidate;
  cmp: int;
begin
  sym := initOverloadIter(o, c, n.sons[0]);
  result := nil;
  if sym = nil then exit;
  initCandidate(x, sym.typ);
  x.calleeSym := sym;
  initCandidate(y, sym.typ);
  y.calleeSym := sym;
  while sym <> nil do begin
    if sym.kind in [skProc, skIterator, skConverter] then begin
      initCandidate(z, sym.typ);
      z.calleeSym := sym;
      matches(c, n, z);
      if z.state = csMatch then begin
        case x.state of
          csEmpty, csNoMatch: x := z;
          csMatch: begin
            cmp := cmpCandidates(x, z);
            if cmp < 0 then x := z // z is better than x
            else if cmp = 0 then y := z // z is as good as x
            else begin end // z is worse than x
          end
        end
      end
    end;
    sym := nextOverloadIter(o, c, n.sons[0])
  end;
  if x.state = csEmpty then begin
    // no overloaded proc found
    // do not generate an error yet; the semantic checking will check for
    // an overloaded () operator
  end
  else if (y.state = csMatch) and (cmpCandidates(x, y) = 0) then begin
    if x.state <> csMatch then
      InternalError(n.info, 'x.state is not csMatch');
    //writeMatches(x);
    //writeMatches(y);
    liMessage(n.Info, errGenerated,
      format(msgKindToString(errAmbigiousCallXYZ),
        [getProcHeader(x.calleeSym),
        getProcHeader(y.calleeSym), x.calleeSym.Name.s]))
  end
  else begin
    // only one valid interpretation found:
    include(x.calleeSym.flags, sfUsed);
    if x.calleeSym.ast = nil then
      internalError(n.info, 'calleeSym.ast is nil'); // XXX: remove this check!
    if x.calleeSym.ast.sons[genericParamsPos] <> nil then begin
      // a generic proc!
      x.calleeSym := generateInstance(c, x.calleeSym, x.bindings, n.info);
      x.callee := x.calleeSym.typ;
    end;
    result := x.call;
    result.sons[0] := newSymNode(x.calleeSym);
    result.typ := x.callee.sons[0];
  end
end;
