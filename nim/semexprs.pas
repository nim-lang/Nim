//
//
//           The Ethexor Morpork Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//


// this module does the semantic checking for expressions

function semDotExpr(c: PContext; n: PNode; typeAllowed: bool): PNode; forward;

function semExprWithType(c: PContext; n: PNode;
                         typeAllowed: bool): PNode;
begin
  result := semExpr(c, n, typeAllowed);
  if result.typ = nil then
    liMessage(n.info, errExprXHasNoType,
              renderTree(result, {@set}[renderNoComments]));
end;

procedure checkConversionBetweenObjects(const info: TLineInfo;
                                        castDest, src: PType);
var
  d, s: PType;
begin
  // conversion to superclass?
  d := castDest;
  while (d <> src) and (d <> nil) do d := base(d);
  if d = src then exit; // is ok
  // conversion to baseclass?
  s := src;
  while (castDest <> s) and (s <> nil) do s := base(s);
  if (castDest = s) then
    liMessage(info, hintConvToBaseNotNeeded)
  else
    liMessage(info, errGenerated,
      format(MsgKindToString(errIllegalConvFromXtoY),
        [typeToString(src), typeToString(castDest)]));
end;

procedure checkConvertible(const info: TLineInfo; castDest, src: PType);
const
  IntegralTypes = [tyBool, tyEnum, tyChar, tyInt..tyFloat128];
var
  d, s: PType;
begin
  if sameType(castDest, src) then begin
    // don't annoy conversions that may be needed on another processor:
    if not (castDest.kind in [tyInt..tyFloat128, tyNil]) then
      liMessage(info, hintConvFromXtoItselfNotNeeded, typeToString(castDest));
    exit
  end;

  // common case first (converting of objects)
  d := skipVarGeneric(castDest);
  s := skipVarGeneric(src);
  while (d <> nil) and (d.Kind in [tyPtr, tyRef])
  and (d.Kind = s.Kind) do begin
    d := base(d);
    s := base(s);
  end;
  if d = nil then
    liMessage(info, errGenerated,
      format(msgKindToString(errIllegalConvFromXtoY),
        [typeToString(src), typeToString(castDest)]));
  if (d.Kind = tyObject) and (s.Kind = tyObject) then
    checkConversionBetweenObjects(info, d, s)
  else if (skipVarGenericRange(castDest).Kind in IntegralTypes)
  and (skipVarGenericRange(src).Kind in IntegralTypes) then begin
    // accept conversion between intregral types
  end
  else begin
    case cmpTypes(d, s) of
      isNone, isGeneric:
        // we use d, s here to speed up that operation a bit
        liMessage(info, errGenerated,
          format(MsgKindToString(errIllegalConvFromXtoY),
            [typeToString(src), typeToString(castDest)]));
      else begin end
    end
  end
end;

function isCastable(castDest, src: PType): Boolean;
var
  ds, ss: biggestInt;
begin
  // this is very unrestrictive; cast is allowed if castDest.size >= src.size
  ds := computeSize(castDest);
  ss := computeSize(src);
  if ds < 0 then result := false
  else if ss < 0 then result := false
  else
    result := (ds >= ss) or
      (castDest.kind in [tyInt..tyFloat128]) and // BUGFIX
      (src.kind in [tyInt..tyFloat128])
end;

function semConv(c: PContext; n: PNode; s: PSym): PNode;
begin
  if sonsLen(n) = 2 then begin
    result := newNode(nkConv);
    result.info := n.info;
    result.typ := semTypeNode(c, n.sons[0], nil);
    addSon(result, semExprWithType(c, n.sons[1], false));
    checkConvertible(result.info, result.typ, result.sons[0].typ);
  end
  else begin
    liMessage(n.info, errConvNeedsOneArg);
    result := nil
  end
end;

function semCast(c: PContext; n: PNode): PNode;
begin
  if optSafeCode in gGlobalOptions then
    liMessage(n.info, errCastNotInSafeMode);
  assert(sonsLen(n) = 2);
  result := newNode(nkCast);
  result.info := n.info;
  result.typ := semTypeNode(c, n.sons[0], nil);
  addSon(result, semExprWithType(c, n.sons[1], false));
  if not isCastable(result.typ, result.sons[0].Typ) then
    liMessage(result.info, errExprCannotBeCastedToX, typeToString(result.Typ));
end;

function semLowHigh(c: PContext; n: PNode; m: TMagic): PNode;
const
  opToStr: array [mLow..mHigh] of string = ('low', 'high');
var
  typ: PType;
begin
  if sonsLen(n) <> 2 then
    liMessage(n.info, errXExpectsTypeOrValue, opToStr[m])
  else begin
    n.sons[1] := semExprWithType(c, n.sons[1], true);
    typ := skipVarGenericRange(n.sons[1].typ);
    case typ.Kind of
      tySequence, tyString, tyOpenArray: begin
        n.typ := getSysType(tyInt);
      end;
      tyArrayConstr, tyArray: begin
        n.typ := n.sons[1].typ.sons[0]; // indextype
      end;
      tyInt..tyInt64, tyChar, tyBool, tyEnum: begin
        n.typ := n.sons[1].typ;
      end
      else
        liMessage(n.info, errInvalidArgForX, opToStr[m])
    end
  end;
  result := n;
end;

function semSizeof(c: PContext; n: PNode): PNode;
begin
  if sonsLen(n) <> 2 then
    liMessage(n.info, errXExpectsTypeOrValue, 'sizeof')
  else
    n.sons[1] := semExprWithType(c, n.sons[1], true);
  n.typ := getSysType(tyInt);
  result := n
end;

procedure semOpAux(c: PContext; n: PNode);
var
  i: int;
  a: PNode;
  info: TLineInfo;
begin
  for i := 1 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkExprEqExpr then begin
      info := a.sons[0].info;
      a.sons[0] := newIdentNode(considerAcc(a.sons[0]));
      a.sons[0].info := info;
      a.sons[1] := semExprWithType(c, a.sons[1], false);
      a.typ := a.sons[1].typ;
    end
    else
      n.sons[i] := semExprWithType(c, a, false);
  end
end;

function overloadedCallOpr(c: PContext; n: PNode): PNode;
var
  par: PIdent;
  i: int;
begin
  // quick check if there is *any* () operator overloaded:
  par := getIdent('()');
  if SymtabGet(c.Tab, par) = nil then begin
    result := nil
  end
  else begin
    result := newNode(nkCall);
    result.info := n.info;
    addSon(result, newIdentNode(par));
    for i := 0 to sonsLen(n)-1 do addSon(result, n.sons[i]);
    result := semExpr(c, result)
  end
end;

procedure changeType(n: PNode; newType: PType);
var
  i: int;
  f: PSym;
  m: PNode;
begin
  case n.kind of
    nkSetConstr, nkConstSetConstr,
    nkArrayConstr, nkConstArrayConstr: begin
      for i := 0 to sonsLen(n)-1 do
        changeType(n.sons[i], elemType(newType));
    end;
    nkRecordConstr, nkConstRecordConstr: begin
      for i := 0 to sonsLen(n)-1 do begin
        m := n.sons[i].sons[0];
        if m.kind <> nkSym then
          internalError(m.info, 'changeType(): invalid record constr');
        if not (newType.kind in [tyRecord, tyObject]) then
          internalError(m.info, 'changeType(): invalid type');
        f := lookupInRecord(newType.n, m.sym.name);
        if f = nil then
          internalError(m.info, 'changeType(): invalid identifier');
        changeType(n.sons[i].sons[1], f.typ);
      end
    end;
    nkPar: begin
      if newType.kind <> tyTuple then
        internalError(n.info, 'changeType(): no tuple type');
      for i := 0 to sonsLen(n)-1 do
        changeType(n.sons[i], newType.sons[i]);
    end;
    else begin end
  end;
  n.typ := newType;
end;

const
  ConstAbstractTypes = {@set}[tyNil, tyChar, tyInt..tyInt64,
                              tyFloat..tyFloat128,
                              tyArrayConstr, tyRecordConstr, tyTuple,
                              tyEmptySet, tySet];

procedure fixAbstractType(c: PContext; n: PNode);
var
  i: int;
  s: PType;
  it: PNode;
begin
  for i := 1 to sonsLen(n)-1 do begin
    it := n.sons[i];
    if it.kind in [nkHiddenStdConv, nkHiddenSubConv] then begin
      if skipVarGeneric(it.typ).kind = tyOpenArray then begin
        s := skipVarGeneric(it.sons[0].typ);
        if (s.kind = tyArrayConstr) and (s.sons[1] = nil) then begin
          s := copyType(s, getCurrOwner(c));
          s.id := getID();
          skipVarGeneric(s).sons[1] := elemType(skipVarGeneric(it.typ));
          it.sons[0].typ := s;
        end
      end
      else if skipVarGeneric(it.sons[0].typ).kind in [tyNil, tyArrayConstr,
                                                 tyRecordConstr, tyTuple,
                                                 tyEmptySet, tySet] then begin
        s := skipVarGeneric(it.typ);
        if s.kind = tyEmptySet then InternalError(it.info, 'fixAbstractType');
        changeType(it.sons[0], s);
        n.sons[i] := it.sons[0];
      end
    end
    else if it.typ.kind = tyEmptySet then
      InternalError(it.info, 'fixAbstractType: 2');
  end
end;

function semIndirectOp(c: PContext; n: PNode): PNode;
var
  m: TCandidate;
  msg: string;
  i: int;
begin
  result := nil;
  case n.sons[0].kind of
    nkDotExpr, nkQualified: begin
      n.sons[0] := semDotExpr(c, n.sons[0], false);
      if n.sons[0].kind = nkDotCall then begin // it is a static call!
        result := n.sons[0];
        result.kind := nkCall;
        for i := 1 to sonsLen(n)-1 do
          addSon(result, n.sons[i]);
        result := semExpr(c, result, false);
        exit
      end
    end;
    else n.sons[0] := semExpr(c, n.sons[0], false);
  end;
  if n.sons[0].typ = nil then
    liMessage(n.sons[0].info, errExprXHasNoType,
              renderTree(n.sons[0], {@set}[renderNoComments]));
  semOpAux(c, n);
  if (n.sons[0].typ <> nil) and (n.sons[0].typ.kind = tyProc) then begin
    initCandidate(m, n.sons[0].typ);
    matches(c, n, m);
    if m.state <> csMatch then begin
      msg := msgKindToString(errTypeMismatch);
      for i := 1 to sonsLen(n)-1 do begin
        msg := msg +{&} typeToString(n.sons[i].typ);
        if i <> sonsLen(n)-1 then msg := msg + ', ';
      end;
      msg := msg +{&} ')' +{&} nl +{&} msgKindToString(errButExpected) +{&}
             nl +{&} typeToString(n.sons[0].typ);
      liMessage(n.Info, errGenerated, msg);
      result := nil
    end
    else
      result := m.call;
  end
  else begin
    result := overloadedCallOpr(c, n);
    if result = nil then liMessage(n.info, errExprCannotBeCalled);
  end;
  fixAbstractType(c, result);
end;

function semDirectOp(c: PContext; n: PNode): PNode;
begin
  semOpAux(c, n);
  result := semDirectCall(c, n);
  if result = nil then begin
    result := overloadedCallOpr(c, n);
    if result = nil then
      liMessage(n.Info, errGenerated, getNotFoundError(c, n))
  end;
  fixAbstractType(c, result);
end;

function semIncSucc(c: PContext; n: PNode; const opr: string): PNode;
// handles Inc, Dec, Succ and Pred
var
  a: PNode;
  typ: PType;
begin
  n.sons[1] := semExprWithType(c, n.sons[1], false);
  typ := skipVar(n.sons[1].Typ);
  if not isOrdinalType(typ) or enumHasWholes(typ) then
    liMessage(n.sons[1].Info, errOrdinalTypeExpected);
  if sonsLen(n) = 3 then begin
    n.sons[2] := semExprWithType(c, n.sons[2], false);
    a := IndexTypesMatch(c, getSysType(tyInt), n.sons[2].typ,
                                 n.sons[2]);
    if a = nil then
      typeMismatch(n.sons[2], getSysType(tyInt), n.sons[2].typ);
    n.sons[2] := a;
  end
  else if sonsLen(n) = 2 then begin // default value of 1
    a := newIntNode(nkIntLit, 1);
    a.info := n.info;
    a.typ := getSysType(tyInt);
    addSon(n, a)
  end
  else
    liMessage(n.info, errInvalidArgForX, opr);
  result := n;
end;

function semOrd(c: PContext; n: PNode): PNode;
begin
  n.sons[1] := semExprWithType(c, n.sons[1], false);
  if not isOrdinalType(skipVar(n.sons[1].Typ)) then
    liMessage(n.Info, errOrdinalTypeExpected);
  n.typ := getSysType(tyInt);
  result := n
end;

function LookUpForDefined(c: PContext; n: PNode): PSym;
var
  m: PSym;
  ident: PIdent;
begin
  case n.kind of
    nkIdent: result := SymtabGet(c.Tab, n.ident);
    nkDotExpr, nkQualified: begin
      result := nil;
      m := LookupForDefined(c, n.sons[0]);
      if (m <> nil) and (m.kind = skModule) then begin
        if (n.sons[1].kind = nkIdent) then begin
          ident := n.sons[1].ident;
          if m = c.module then
            // a module may access its private members:
            result := StrTableGet(c.tab.stack[ModuleTablePos], ident)
          else
            result := StrTableGet(m.tab, ident);
        end
        else
          liMessage(n.sons[1].info, errIdentifierExpected, '');
      end
    end;
    nkAccQuoted:
      result := lookupForDefined(c, n.sons[0]);
    else begin
      liMessage(n.info, errIdentifierExpected, '');
      result := nil;
    end
  end
end;

function semDefined(c: PContext; n: PNode): PNode;
begin
  result := newIntNode(nkIntLit, 0);
  // we replace this node by a 'true' or 'false' node
  if LookUpForDefined(c, n.sons[1]) <> nil then
    result.intVal := 1
  else if (n.sons[1].kind = nkIdent)
      and condsyms.isDefined(n.sons[1].ident) then
    result.intVal := 1;
  result.info := n.info;
  result.typ := getSysType(tyBool);
end;

function setMs(n: PNode; s: PSym): PNode;
begin
  result := n;
  n.sons[0] := newSymNode(s);
  n.sons[0].info := n.info;
end;

function semMagic(c: PContext; n: PNode; s: PSym): PNode;
begin
  result := n;
  case s.magic of // magics that need special treatment
    mDefined: result := semDefined(c, setMs(n, s));
    mLow:     result := semLowHigh(c, setMs(n, s), mLow);
    mHigh:    result := semLowHigh(c, setMs(n, s), mHigh);
    mSizeOf:  result := semSizeof(c, setMs(n, s));
    mSucc:    begin
      result := semIncSucc(c, setMs(n, s), 'succ');
      result.typ := n.sons[1].typ;
    end;
    mPred:    begin
      result := semIncSucc(c, setMs(n, s), 'pred');
      result.typ := n.sons[1].typ;
    end;
    mInc:     result := semIncSucc(c, setMs(n, s), 'inc');
    mDec:     result := semIncSucc(c, setMs(n, s), 'dec');
    mOrd:     result := semOrd(c, setMs(n, s));
    else      result := semDirectOp(c, n);
  end;
end;

function semSym(c: PContext; n: PNode; s: PSym; typeAllowed: bool): PNode;
begin
  result := newSymNode(s);
  result.info := n.info;
  result.typ := s.typ;
  include(s.flags, sfUsed);
  if (s.kind = skType) and not typeAllowed then
    liMessage(n.info, errATypeHasNoValue);
  case s.kind of
    skProc, skIterator, skConverter:
      if (s.magic <> mNone) then
        liMessage(n.info, errInvalidContextForBuiltinX, s.name.s);
    skConst: begin
      (*
        Consider::
          const x = []
          proc p(a: openarray[int], i: int)
          proc q(a: sequence[char], c: char)
          p(x, 0)
          q(x, '\0')

        It is clear that ``[]`` means two totally different things. Thus, we
        copy `x`'s AST into each context, so that the type fixup phase can
        deal with two different ``[]``.
      *)
      if s.typ.kind in ConstAbstractTypes then begin
        result := copyTree(s.ast);
        result.info := n.info;
        result.typ := s.typ;
      end
    end
    else begin end
  end
end;

function isTypeExpr(n: PNode): bool;
begin
  case n.kind of
    nkType, nkTypeOfExpr: result := true;
    nkSym: result := n.sym.kind = skType;
    else result := false
  end
end;

function semFieldAccess(c: PContext; n: PNode; typeAllowed: bool): PNode;
var
  f: PSym;
  ty: PType;
  i: PIdent;
  asgn: bool;
begin
  asgn := false;
  // this is difficult, because the '.' is used in many different contexts
  // in Nimrod. We first allow types in the semantic checking.
  n.sons[0] := semExprWithType(c, n.sons[0], true);
  i := considerAcc(n.sons[1]);
  ty := n.sons[0].Typ;
  f := nil;
  result := nil;
  if ty.kind = tyEnum then begin
    // look up if the identifier belongs to the enum:
    while (ty <> nil) do begin
      f := getSymFromList(ty.n, i);
      if f <> nil then breaK;
      ty := ty.sons[0]; // enum inheritance
    end;
    if f <> nil then begin
      result := newSymNode(f);
      result.info := n.info;
      result.typ := ty;
    end
    else
      liMessage(n.sons[1].info, errEnumHasNoValueX, i.s);
    exit;
  end
  else if not typeAllowed and isTypeExpr(n.sons[0]) then begin
    liMessage(n.sons[0].info, errATypeHasNoValue);
    exit
  end;

  while ty.kind = tyVar do begin ty := ty.sons[0]; asgn := true; end;
  if ty.Kind in [tyRef, tyPtr] then begin ty := ty.sons[0]; asgn := true; end;
  if (ty.kind in [tyRecord, tyObject]) then begin
    while ty <> nil do begin
      f := lookupInRecord(ty.n, i);
      if f <> nil then break;
      ty := ty.sons[0];
    end;
    if f <> nil then begin
      if ([sfStar, sfMinus] * f.flags <> [])
      or (getModule(f).id = c.module.id) then begin
        // is the access to a public field or in the same module?
        if not asgn then begin
          if not (sfMinus in f.flags) or (getModule(f).id = c.module.id) then
            asgn := tfAssignable in ty.flags;
        end;

        n.sons[1] := newSymNode(f); // we now have the correct field
        n.typ := inheritAssignable(f.typ, asgn);
        result := n;
        exit
      end
    end
  end;
  // allow things like "".replace(...)
  // --> replace("", ...)
  f := SymTabGet(c.tab, i);
  if (f <> nil) and (f.kind in [skProc, skIterator]) then begin
    result := newNode(nkDotCall);
    // This special node kind is to merge with the call handler in `semExpr`.
    result.info := n.info;
    addSon(result, newIdentNode(i));
    addSon(result, copyTree(n.sons[0]));
  end
  else begin
    liMessage(n.Info, errUndeclaredFieldX, i.s);
  end
end;

function semArrayAccess(c: PContext; n: PNode): PNode;
var
  arr, indexType: PType;
  i: int;
  asgn: bool;
  arg: PNode;
  idx: biggestInt;
begin
  asgn := false;
  // check if array type:
  n.sons[0] := semExprWithType(c, n.sons[0], false);
  arr := n.sons[0].typ;
  while arr.kind = tyVar do begin arr := arr.sons[0]; asgn := true; end;
  if arr.kind in [tyRef, tyPtr] then begin
    arr := arr.sons[0]; asgn := true
  end;
  case arr.kind of
    tyArray, tyOpenArray, tyArrayConstr, tySequence, tyString,
    tyCString: begin
      asgn := asgn or (tfAssignable in arr.flags) or (arr.kind = tyCString);
      for i := 1 to sonsLen(n)-1 do
        n.sons[i] := semExprWithType(c, n.sons[i], false);
      if arr.kind = tyArray then indexType := arr.sons[0]
      else indexType := getSysType(tyInt);
      arg := IndexTypesMatch(c, indexType, n.sons[1].typ, n.sons[1]);
      if arg <> nil then
        n.sons[1] := arg
      else
        liMessage(n.info, errIndexTypesDoNotMatch);
      result := n;
      result.typ := inheritAssignable(elemType(arr), asgn); // BUGFIX
    end;
    tyTuple: begin
      // [] operator for tuples requires constant expression
      n.sons[1] := semConstExpr(c, n.sons[1]);
      if skipRange(n.sons[1].typ).kind in [tyInt..tyInt64] then begin
        idx := getOrdValue(n.sons[1]);
        if (idx >= 0) and (idx < sonsLen(arr)) then
          n.typ := arr.sons[int(idx)]
        else
          liMessage(n.info, errInvalidIndexValueForTuple);
      end
      else
        liMessage(n.info, errIndexTypesDoNotMatch);
      result := n;
    end
    else begin // overloaded [] operator:
      result := newNode(nkCall);
      if n.sons[1].kind = nkRange then
        addSon(result, newIdentNode(getIdent('[..]')))
      else
        addSon(result, newIdentNode(getIdent('[]')));
      for i := 0 to sonsLen(n)-1 do
        addSon(result, n.sons[i]);
      result := semExpr(c, result);
    end
  end
end;

function semArrayConstr(c: PContext; n: PNode): PNode;
var
  typ: PType;
  i: int;
begin
  result := newNode(nkArrayConstr);
  result.info := n.info;
  result.typ := newTypeS(tyArrayConstr, c);
  addSon(result.typ, nil); // index type
  if sonsLen(n) = 0 then
    // empty array
    addSon(result.typ, nil) // needs an empty basetype!
  else begin
    addSon(result, semExprWithType(c, n.sons[0], false));
    typ := skipVar(result.sons[0].typ);
    for i := 1 to sonsLen(n)-1 do begin
      n.sons[i] := semExprWithType(c, n.sons[i], false);
      addSon(result, fitNode(c, typ, n.sons[i]));
    end;
    addSon(result.typ, typ)
  end;
  result.typ.sons[0] := makeRangeType(c, 0, sonsLen(result)-1);
end;

function semIfExpr(c: PContext; n: PNode): PNode;
var
  typ: PType;
  i: int;
  it: PNode;
begin
  result := n;
  typ := nil;
  for i := 0 to sonsLen(n) - 1 do begin
    it := n.sons[i];
    case it.kind of
      nkElifExpr: begin
        it.sons[0] := semExprWithType(c, it.sons[0], false);
        checkBool(it.sons[0]);
        it.sons[1] := semExprWithType(c, it.sons[1], false);
        if typ = nil then typ := it.sons[1].typ
        else it.sons[1] := fitNode(c, typ, it.sons[1])
      end;
      nkElseExpr: begin
        it.sons[0] := semExprWithType(c, it.sons[0], false);
        assert(typ <> nil);
        it.sons[0] := fitNode(c, typ, it.sons[0]);
      end;
      else internalError(it.info, 'semIfExpr()');
    end
  end;
  result.typ := typ;
end;

function semSetConstr(c: PContext; n: PNode): PNode;
var
  typ: PType;
  i: int;
  m: PNode;
begin
  result := newNode(nkSetConstr);
  result.info := n.info;
  if sonsLen(n) = 0 then
    result.typ := newTypeS(tyEmptySet, c)
  else begin
    // only semantic checking for all elements, later type checking:
    typ := nil;
    for i := 0 to sonsLen(n)-1 do begin
      if n.sons[i].kind = nkRange then begin
        n.sons[i].sons[0] := semExprWithType(c, n.sons[i].sons[0], false);
        n.sons[i].sons[1] := semExprWithType(c, n.sons[i].sons[1], false);
        if typ = nil then typ := skipVar(n.sons[i].sons[0].typ);
        n.sons[i].typ := n.sons[i].sons[1].typ; // range node needs type too
      end
      else begin
        n.sons[i] := semExprWithType(c, n.sons[i], false);
        if typ = nil then typ := skipVar(n.sons[i].typ)
      end
    end;

    result.typ := newTypeS(tySet, c);
    if not isOrdinalType(typ) then begin
      liMessage(n.info, errOrdinalTypeExpected);
      exit
    end;
    if lengthOrd(typ) > MaxSetElements then
      typ := makeRangeType(c, 0, MaxSetElements-1);
    addSon(result.typ, typ);

    for i := 0 to sonsLen(n)-1 do begin
      if n.sons[i].kind = nkRange then begin
        m := newNode(nkRange);
        m.info := n.sons[i].info;
        addSon(m, fitNode(c, typ, n.sons[i].sons[0]));
        addSon(m, fitNode(c, typ, n.sons[i].sons[1]));
      end
      else begin
        m := fitNode(c, typ, n.sons[i]);
      end;
      addSon(result, m);
    end
  end
end;

type
  TParKind = (paNone, paSingle, paRecord, paTuple);

function checkPar(n: PNode): TParKind;
var
  i, len: int;
begin
  len := sonsLen(n);
  if len = 0 then result := paTuple // ()
  else if len = 1 then result := paSingle // (expr)
  else begin
    if n.sons[0].kind = nkExprColonExpr then result := paRecord
    else result := paTuple;
    for i := 0 to len-1 do begin
      if result = paRecord then begin
        if (n.sons[i].kind <> nkExprColonExpr)
        or (n.sons[i].sons[0].kind <> nkIdent) then begin
          liMessage(n.sons[i].info, errNamedExprExpected);
          result := paNone; exit
        end
      end
      else begin
        if n.sons[i].kind = nkExprColonExpr then begin
          liMessage(n.sons[i].info, errNamedExprNotAllowed);
          result := paNone; exit
        end
      end
    end
  end
end;

function semRecordConstr(c: PContext; n: PNode): PNode;
var
  i: int;
  typ: PType;
  ids: TIntSet;
  id: PIdent;
  f: PSym;
begin
  result := newNode(nkRecordConstr);
  result.info := n.info;
  typ := newTypeS(tyRecordConstr, c);
  typ.n := newNode(nkRecList); // nkIdentDefs
  IntSetInit(ids);
  for i := 0 to sonsLen(n)-1 do begin
    if (n.sons[i].kind <> nkExprColonExpr)
    or (n.sons[i].sons[0].kind <> nkIdent) then
      illFormedAst(n.sons[i]);
    id := n.sons[i].sons[0].ident;
    if IntSetContainsOrIncl(ids, id.id) then
      liMessage(n.sons[i].info, errFieldInitTwice, id.s);
    n.sons[i].sons[1] := semExprWithType(c, n.sons[i].sons[1], false);
    f := newSymS(skField, n.sons[i].sons[0], c);
    f.typ := n.sons[i].sons[1].typ;
    addSon(typ.n, newSymNode(f));
    n.sons[i].sons[0] := newSymNode(f);
    addSon(result, n.sons[i]);
  end;
  result.typ := typ;
end;

function semTupleConstr(c: PContext; n: PNode): PNode;
var
  i: int;
  typ: PType;
begin
  result := n; // we don't modify n, but compute the type:
  typ := newTypeS(tyTuple, c);
  for i := 0 to sonsLen(n)-1 do begin
    n.sons[i] := semExprWithType(c, n.sons[i], false);
    addSon(typ, n.sons[i].typ);
  end;
  result.typ := typ;
end;

function semStmtListExpr(c: PContext; n: PNode): PNode;
var
  len, i: int;
begin
  result := n;
  len := sonsLen(n);
  for i := 0 to len-2 do begin
    n.sons[i] := semStmt(c, n.sons[i]);
  end;
  if len > 0 then begin
    n.sons[len-1] := semExprWithType(c, n.sons[len-1], false);
    n.typ := n.sons[len-1].typ
  end
end;

function semBlockExpr(c: PContext; n: PNode): PNode;
begin
  result := n;
  Inc(c.p.nestedBlockCounter);
  if sonsLen(n) = 2 then begin
    openScope(c.tab); // BUGFIX: label is in the scope of block!
    if n.sons[0] <> nil then begin
      addDecl(c, newSymS(skLabel, n.sons[0], c))
    end;
    n.sons[1] := semStmtListExpr(c, n.sons[1]);
    n.typ := n.sons[1].typ;
    closeScope(c.tab);
  end
  else
    illFormedAst(n);
  Dec(c.p.nestedBlockCounter);
end;

function semDotExpr(c: PContext; n: PNode; typeAllowed: bool): PNode;
var
  s: PSym;
begin
  s := qualifiedLookup(c, n, true); // check for ambiguity
  if s <> nil then
    result := semSym(c, n, s, typeAllowed)
  else
    // record access: if the field does not exist, check for a proc:
    result := semFieldAccess(c, n, typeAllowed);
end;

function semExpr(c: PContext; n: PNode; typeAllowed: bool = false): PNode;
var
  s: PSym;
begin
  result := n;
  if n = nil then exit;
  embeddedDbg(c, n);
  case n.kind of
    // atoms:
    nkIdent: begin
      // lookup the symbol:
      s := SymtabGet(c.Tab, n.ident);
      if s <> nil then result := semSym(c, n, s, typeAllowed)
      else liMessage(n.info, errUndeclaredIdentifier, n.ident.s);
    end;
    nkSym: begin
      s := n.sym;
      include(s.flags, sfUsed);
      if (s.kind = skType) and not typeAllowed then
        liMessage(n.info, errATypeHasNoValue);
      if s.magic <> mNone then
        liMessage(n.info, errInvalidContextForBuiltinX, s.name.s);
    end;
    nkEmpty, nkNone: begin end;
    nkNilLit: result.typ := getSysType(tyNil);
    nkType: begin
      if not typeAllowed then liMessage(n.info, errATypeHasNoValue);
      n.typ := semTypeNode(c, n, nil);
    end;
    nkIntLit: result.typ := getSysType(tyInt);
    nkInt8Lit: result.typ := getSysType(tyInt8);
    nkInt16Lit: result.typ := getSysType(tyInt16);
    nkInt32Lit: result.typ := getSysType(tyInt32);
    nkInt64Lit: result.typ := getSysType(tyInt64);
    nkFloatLit: result.typ := getSysType(tyFloat);
    nkFloat32Lit: result.typ := getSysType(tyFloat32);
    nkFloat64Lit: result.typ := getSysType(tyFloat64);
    nkStrLit..nkTripleStrLit: result.typ := getSysType(tyString);
    nkCharLit, nkRCharLit: result.typ := getSysType(tyChar);

    nkQualified, nkDotExpr: begin
      result := semDotExpr(c, n, typeAllowed);
      if result.kind = nkDotCall then begin
        result.kind := nkCall;
        result := semExpr(c, result, typeAllowed)
      end;
    end;
    // complex expressions
    nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand: begin
      // check if it is an expression macro:
      s := qualifiedLookup(c, n.sons[0], false);
      if (s <> nil) then begin
        case s.kind of
          skMacro: begin
            include(s.flags, sfUsed);
            result := semMacroExpr(c, n, s);
          end;
          skTemplate: begin
            include(s.flags, sfUsed);
            pushInfoContext(n.info);
            result := evalTemplate(c, n, s);
            popInfoContext();
          end;
          skType: begin
            include(s.flags, sfUsed);
            result := semConv(c, n, s);
            if n.kind <> nkCall then
              liMessage(n.info, errXisNotCallable, s.name.s)
          end;
          skProc, skConverter, skIterator: begin
            if s.magic = mNone then result := semDirectOp(c, n)
            else result := semMagic(c, n, s);
          end;
          else result := semIndirectOp(c, n)
        end
      end
      else result := semIndirectOp(c, n);
    end;
    nkBracketExpr: begin
      s := qualifiedLookup(c, n.sons[0], false);
      if (s <> nil) and (s.kind in [skProc, skConverter, skIterator]) then begin
        // type parameters: partial generic specialization
        // XXX: too implement!
        internalError(n.info, 'explicit generic instantation not implemented');
        result := partialSpecialization(c, n, s);
      end
      else begin
        result := semArrayAccess(c, n);
      end
    end;
    nkPragmaExpr: begin
      // which pragmas are allowed for expressions? `likely`, `unlikely`
      internalError(n.info, 'semExpr() to implement');
      // XXX: to implement
    end;
    nkPar, nkRecordConstr, nkConstRecordConstr: begin
      case checkPar(n) of
        paNone: result := nil;
        paTuple:  result := semTupleConstr(c, n);
        paRecord: result := semRecordConstr(c, n);
        paSingle: result := semExpr(c, n.sons[0], typeAllowed);
      end;
    end;
    nkCurly, nkSetConstr, nkConstSetConstr: begin
      result := semSetConstr(c, n);
    end;
    nkBracket, nkArrayConstr, nkConstArrayConstr: begin
      result := semArrayConstr(c, n);
    end;
    nkLambda: begin
      result := semLambda(c, n); // handled in semstmts
    end;
    nkExprColonExpr: begin
      internalError(n.info, 'semExpr() to implement');
      // XXX: to implement for array constructors!
    end;
    nkDerefExpr: begin
      if sonsLen(n) = 1 then begin
        n.sons[0] := semExprWithType(c, n.sons[0], typeAllowed);
        result := n;
        case n.sons[0].typ.kind of
          tyRef, tyPtr: n.typ := n.sons[0].typ.sons[0];
          else liMessage(n.sons[0].info, errCircumNeedsPointer);
        end;
        result := n;
        result.typ := inheritAssignable(result.typ, true);
      end
      else
        illFormedAst(n)
    end;
    nkAddr: begin
      result := n;
      n.sons[0] := semExprWithType(c, n.sons[0], false);
      //if not (tfAssignable in n.sons[0].typ.flags) then
      //  liMessage(n.info, errExprHasNoAddress);
      // XXX: the above check is not correct for parameters
      n.typ := makePtrType(c, n.sons[0].typ);
    end;
    nkCast: begin
      result := semCast(c, n);
    end;
    nkAccQuoted: begin
      result := semExpr(c, n.sons[0]);
    end;
    nkHeaderQuoted: begin
      // look up the proc:
      internalError(n.info, 'semExpr() to implement');
      // XXX: to implement
    end;
    nkIfExpr: begin
      result := semIfExpr(c, n);
    end;
    nkStmtListExpr: begin
      result := semStmtListExpr(c, n);
    end;
    nkBlockExpr: begin
      result := semBlockExpr(c, n);
    end;
    else begin
      liMessage(n.info, errInvalidExpressionX,
                renderTree(n, {@set}[renderNoComments]));
      result := nil
    end
  end
end;
