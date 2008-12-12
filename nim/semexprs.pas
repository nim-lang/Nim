//
//
//           The Ethexor Morpork Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//


// this module does the semantic checking for expressions

function semDotExpr(c: PContext; n: PNode;
                    flags: TExprFlags = {@set}[]): PNode; forward;

function semExprWithType(c: PContext; n: PNode;
                         flags: TExprFlags = {@set}[]): PNode;
var
  d: PNode;
begin
  result := semExpr(c, n, flags);
  if result = nil then InternalError('semExprWithType');
  if (result.typ = nil) then
    liMessage(n.info, errExprXHasNoType,
              renderTree(result, {@set}[renderNoComments]));
  if result.typ.kind = tyVar then begin
    d := newNodeIT(nkHiddenDeref, result.info, result.typ.sons[0]);
    addSon(d, result);
    result := d
  end
end;

procedure checkConversionBetweenObjects(const info: TLineInfo;
                                        castDest, src: PType);
var
  diff: int;
begin
  diff := inheritanceDiff(castDest, src);
  if diff = 0 then
    liMessage(info, hintConvToBaseNotNeeded)
  else if diff = high(int) then
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
      (castDest.kind in [tyInt..tyFloat128]) or
      (src.kind in [tyInt..tyFloat128])
end;

function semConv(c: PContext; n: PNode; s: PSym): PNode;
begin
  if sonsLen(n) <> 2 then liMessage(n.info, errConvNeedsOneArg);
  result := newNodeI(nkConv, n.info);
  result.typ := semTypeNode(c, n.sons[0], nil);
  addSon(result, copyTree(n.sons[0]));
  addSon(result, semExprWithType(c, n.sons[1]));
  checkConvertible(result.info, result.typ, result.sons[1].typ);
end;

function semCast(c: PContext; n: PNode): PNode;
begin
  if optSafeCode in gGlobalOptions then liMessage(n.info, errCastNotInSafeMode);
  checkSonsLen(n, 2);
  result := newNodeI(nkCast, n.info);
  result.typ := semTypeNode(c, n.sons[0], nil);
  addSon(result, copyTree(n.sons[0]));
  addSon(result, semExprWithType(c, n.sons[1]));
  if not isCastable(result.typ, result.sons[1].Typ) then
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
    n.sons[1] := semExprWithType(c, n.sons[1], {@set}[efAllowType]);
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
    n.sons[1] := semExprWithType(c, n.sons[1], {@set}[efAllowType]);
  n.typ := getSysType(tyInt);
  result := n
end;

function semIs(c: PContext; n: PNode): PNode;
var
  a, b: PType;
begin
  if sonsLen(n) = 3 then begin
    n.sons[1] := semExprWithType(c, n.sons[1], {@set}[efAllowType]);
    n.sons[2] := semExprWithType(c, n.sons[2], {@set}[efAllowType]);
    a := n.sons[1].typ;
    b := n.sons[2].typ;
    if (b.kind <> tyObject) or (a.kind <> tyObject) then
      liMessage(n.info, errIsExpectsObjectTypes);
    while (b <> nil) and (b.id <> a.id) do b := b.sons[0];
    if b = nil then
      liMessage(n.info, errXcanNeverBeOfThisSubtype, typeToString(a));
    n.typ := getSysType(tyBool);
  end
  else
    liMessage(n.info, errIsExpectsTwoArguments);
  result := n;
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
      checkSonsLen(a, 2);
      info := a.sons[0].info;
      a.sons[0] := newIdentNode(considerAcc(a.sons[0]), info);
      a.sons[1] := semExprWithType(c, a.sons[1]);
      a.typ := a.sons[1].typ;
    end
    else
      n.sons[i] := semExprWithType(c, a);
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
    result := newNodeI(nkCall, n.info);
    addSon(result, newIdentNode(par, n.info));
    for i := 0 to sonsLen(n)-1 do addSon(result, n.sons[i]);
    result := semExpr(c, result)
  end
end;

procedure changeType(n: PNode; newType: PType);
var
  i: int;
  f: PSym;
  a, m: PNode;
begin
  case n.kind of
    nkCurly, nkBracket: begin
      for i := 0 to sonsLen(n)-1 do changeType(n.sons[i], elemType(newType));
    end;
    nkPar: begin
      if newType.kind <> tyTuple then
        InternalError(n.info, 'changeType: no tuple type for constructor');
      if newType.n = nil then
        InternalError(n.info, 'changeType: no tuple fields');
      if (sonsLen(n) > 0) and (n.sons[0].kind = nkExprColonExpr) then begin
        for i := 0 to sonsLen(n)-1 do begin
          m := n.sons[i].sons[0];
          if m.kind <> nkSym then
            internalError(m.info, 'changeType(): invalid tuple constr');
          f := getSymFromList(newType.n, m.sym.name);
          if f = nil then
            internalError(m.info, 'changeType(): invalid identifier');
          changeType(n.sons[i].sons[1], f.typ);
        end
      end
      else begin
        for i := 0 to sonsLen(n)-1 do begin
          m := n.sons[i];
          a := newNodeIT(nkExprColonExpr, m.info, newType.sons[i]);
          addSon(a, newSymNode(newType.n.sons[i].sym));
          addSon(a, m);
          changeType(m, newType.sons[i]);
          n.sons[i] := a;
        end;
      end
    end;
    else begin end
  end;
  n.typ := newType;
end;

function semArrayConstr(c: PContext; n: PNode): PNode;
var
  typ: PType;
  i: int;
begin
  result := newNodeI(nkBracket, n.info);
  result.typ := newTypeS(tyArrayConstr, c);
  addSon(result.typ, nil); // index type
  if sonsLen(n) = 0 then
    addSon(result.typ, newTypeS(tyEmpty, c)) // needs an empty basetype!
  else begin
    addSon(result, semExprWithType(c, n.sons[0]));
    typ := skipVar(result.sons[0].typ);
    for i := 1 to sonsLen(n)-1 do begin
      n.sons[i] := semExprWithType(c, n.sons[i]);
      addSon(result, fitNode(c, typ, n.sons[i]));
    end;
    addSon(result.typ, typ)
  end;
  result.typ.sons[0] := makeRangeType(c, 0, sonsLen(result)-1, n.info);
end;

const
  ConstAbstractTypes = {@set}[tyNil, tyChar, tyInt..tyInt64,
                              tyFloat..tyFloat128,
                              tyArrayConstr, tyTuple, tySet];

procedure fixAbstractType(c: PContext; n: PNode);
var
  i: int;
  s: PType;
  it: PNode;
begin
  for i := 1 to sonsLen(n)-1 do begin
    it := n.sons[i];
    case it.kind of
      nkHiddenStdConv, nkHiddenSubConv: begin
        if it.sons[1].kind = nkBracket then
          it.sons[1] := semArrayConstr(c, it.sons[1]);
        if skipVarGeneric(it.typ).kind = tyOpenArray then begin
          s := skipVarGeneric(it.sons[1].typ);
          if (s.kind = tyArrayConstr) and (s.sons[1].kind = tyEmpty) then begin
            s := copyType(s, getCurrOwner(), false);
            skipVarGeneric(s).sons[1] := elemType(skipVarGeneric(it.typ));
            it.sons[1].typ := s;
          end
        end
        else if skipVarGeneric(it.sons[1].typ).kind in [tyNil, tyArrayConstr,
                      tyTuple, tySet] then begin
          s := skipVarGeneric(it.typ);
          changeType(it.sons[1], s);
          n.sons[i] := it.sons[1];
        end
      end;
      nkBracket: begin
        // an implicitely constructed array (passed to an open array):
        n.sons[i] := semArrayConstr(c, it);
      end;
      else if (it.typ = nil) then
        InternalError(it.info, 'fixAbstractType: ' + renderTree(it));
    end
  end
end;

function skipObjConv(n: PNode): PNode;
begin
  case n.kind of
    nkHiddenStdConv, nkHiddenSubConv, nkConv: begin
      if skipPtrsGeneric(n.sons[1].typ).kind in [tyTuple, tyObject] then
        result := n.sons[1]
      else
        result := n
    end;
    nkObjUpConv, nkObjDownConv: result := n.sons[0];
    else result := n
  end
end;

function isAssignable(n: PNode): bool;
begin
  result := false;
  case n.kind of
    nkSym: result := n.sym.kind in [skVar, skTemp];
    nkDotExpr, nkQualified, nkBracketExpr: begin
      checkMinSonsLen(n, 1);
      if skipGeneric(n.sons[0].typ).kind in [tyVar, tyPtr, tyRef] then
        result := true
      else
        result := isAssignable(n.sons[0]);
    end;
    nkHiddenStdConv, nkHiddenSubConv, nkConv: begin
      // Object and tuple conversions are still addressable, so we skip them
      //if skipPtrsGeneric(n.sons[1].typ).kind in [tyOpenArray,
      //                                           tyTuple, tyObject] then
      if skipPtrsGeneric(n.typ).kind in [tyOpenArray, tyTuple, tyObject] then
        result := isAssignable(n.sons[1])
    end;
    nkHiddenDeref, nkDerefExpr: result := true;
    nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr:
      result := isAssignable(n.sons[0]);
    else begin end
  end
end;

function newHiddenAddrTaken(c: PContext; n: PNode): PNode;
begin
  if n.kind = nkHiddenDeref then begin
    checkSonsLen(n, 1);
    result := n.sons[0]
  end
  else begin
    result := newNodeIT(nkHiddenAddr, n.info, makeVarType(c, n.typ));
    addSon(result, n);
    if not isAssignable(n) then begin
      liMessage(n.info, errVarForOutParamNeeded);
    end
  end
end;

function analyseIfAddressTaken(c: PContext; n: PNode): PNode;
begin
  result := n;
  case n.kind of
    nkSym: begin
      if skipGeneric(n.sym.typ).kind <> tyVar then begin
        include(n.sym.flags, sfAddrTaken);
        result := newHiddenAddrTaken(c, n);
      end
    end;
    nkDotExpr, nkQualified: begin
      checkSonsLen(n, 2);
      if n.sons[1].kind <> nkSym then
        internalError(n.info, 'analyseIfAddressTaken');
      if skipGeneric(n.sons[1].sym.typ).kind <> tyVar then begin
        include(n.sons[1].sym.flags, sfAddrTaken);
        result := newHiddenAddrTaken(c, n);
      end
    end;
    nkBracketExpr: begin
      checkMinSonsLen(n, 1);
      if skipGeneric(n.sons[0].typ).kind <> tyVar then begin
        if n.sons[0].kind = nkSym then
          include(n.sons[0].sym.flags, sfAddrTaken);
        result := newHiddenAddrTaken(c, n);
      end
    end;
    else result := newHiddenAddrTaken(c, n);  // BUGFIX!
  end
end;

procedure analyseIfAddressTakenInCall(c: PContext; n: PNode);
const
  FakeVarParams = {@set}[mNew, mNewFinalize, mInc, ast.mDec, mIncl,
                         mExcl, mSetLengthStr, mSetLengthSeq,
                         mAppendStrCh, mAppendStrStr, mSwap,
                         mAppendSeqElem, mAppendSeqSeq,
                         mNewSeq];
var
  i: int;
  t: PType;
begin
  checkMinSonsLen(n, 1);
  t := n.sons[0].typ;
  if (n.sons[0].kind = nkSym)
      and (n.sons[0].sym.magic in FakeVarParams) then exit;
  for i := 1 to sonsLen(n)-1 do
    if (i < sonsLen(t)) and (skipGeneric(t.sons[i]).kind = tyVar) then
      n.sons[i] := analyseIfAddressTaken(c, n.sons[i]);
end;

function semIndirectOp(c: PContext; n: PNode): PNode;
var
  m: TCandidate;
  msg: string;
  i: int;
begin
  result := nil;
  checkMinSonsLen(n, 1);
  case n.sons[0].kind of
    nkDotExpr, nkQualified: begin
      checkSonsLen(n.sons[0], 2);
      n.sons[0] := semDotExpr(c, n.sons[0]);
      if n.sons[0].kind = nkDotCall then begin // it is a static call!
        result := n.sons[0];
        result.kind := nkCall;
        for i := 1 to sonsLen(n)-1 do
          addSon(result, n.sons[i]);
        result := semExpr(c, result);
        exit
      end
    end;
    else n.sons[0] := semExpr(c, n.sons[0]);
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
    if result = nil then result := semDirectCall(c, n);
    if result = nil then liMessage(n.info, errExprCannotBeCalled);
  end;
  fixAbstractType(c, result);
  analyseIfAddressTakenInCall(c, result);
end;

function semDirectOp(c: PContext; n: PNode): PNode;
begin
  // this seems to be a hotspot in the compiler!
  semOpAux(c, n);
  result := semDirectCall(c, n);
  if result = nil then begin
    result := overloadedCallOpr(c, n);
    if result = nil then
      liMessage(n.Info, errGenerated, getNotFoundError(c, n))
  end;
  fixAbstractType(c, result);
  analyseIfAddressTakenInCall(c, result);
end;

function semIncSucc(c: PContext; n: PNode; const opr: string): PNode;
// handles Inc, Dec, Succ and Pred
var
  a: PNode;
  typ: PType;
begin
  checkMinSonsLen(n, 1);
  n.sons[1] := semExprWithType(c, n.sons[1]);
  typ := skipVar(n.sons[1].Typ);
  if not isOrdinalType(typ) or enumHasWholes(typ) then
    liMessage(n.sons[1].Info, errOrdinalTypeExpected);
  if sonsLen(n) = 3 then begin
    n.sons[2] := semExprWithType(c, n.sons[2]);
    a := IndexTypesMatch(c, getSysType(tyInt), n.sons[2].typ, n.sons[2]);
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
  checkSonsLen(n, 2);
  n.sons[1] := semExprWithType(c, n.sons[1]);
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
    nkIdent: result := SymtabGet(c.Tab, n.ident); // no need for stub loading
    nkDotExpr, nkQualified: begin
      checkSonsLen(n, 2);
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
    nkAccQuoted: begin
      checkSonsLen(n, 1);
      result := lookupForDefined(c, n.sons[0]);
    end
    else begin
      liMessage(n.info, errIdentifierExpected, renderTree(n));
      result := nil;
    end
  end
end;

function semDefined(c: PContext; n: PNode): PNode;
begin
  checkSonsLen(n, 2);
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
// this is a hotspot in the compiler!
begin
  result := n;
  case s.magic of // magics that need special treatment
    mDefined: result := semDefined(c, setMs(n, s));
    mLow:     result := semLowHigh(c, setMs(n, s), mLow);
    mHigh:    result := semLowHigh(c, setMs(n, s), mHigh);
    mSizeOf:  result := semSizeof(c, setMs(n, s));
    mIs:      result := semIs(c, setMs(n, s));
    mSucc:    begin
      result := semIncSucc(c, setMs(n, s), 'succ');
      result.typ := n.sons[1].typ;
    end;
    mPred:    begin
      result := semIncSucc(c, setMs(n, s), 'pred');
      result.typ := n.sons[1].typ;
    end;
    mInc:     result := semIncSucc(c, setMs(n, s), 'inc');
    ast.mDec: result := semIncSucc(c, setMs(n, s), 'dec');
    mOrd:     result := semOrd(c, setMs(n, s));
    else      result := semDirectOp(c, n);
  end;
end;

function semSym(c: PContext; n: PNode; s: PSym; flags: TExprFlags): PNode;
begin
  result := newSymNode(s);
  result.info := n.info;
  result.typ := s.typ;
  include(s.flags, sfUsed);
  if (s.kind = skType) and not (efAllowType in flags) then
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
          proc q(a: openarray[char], c: char)
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

function lookupInRecordAndBuildCheck(c: PContext; n, r: PNode;
                                     field: PIdent; var check: PNode): PSym;
// transform in a node that contains the runtime check for the
// field, if it is in a case-part...
var
  i, j: int;
  s, it, inExpr, notExpr: PNode;
begin
  result := nil;
  case r.kind of
    nkRecList: begin
      for i := 0 to sonsLen(r)-1 do begin
        result := lookupInRecordAndBuildCheck(c, n, r.sons[i], field, check);
        if result <> nil then exit
      end
    end;
    nkRecCase: begin
      checkMinSonsLen(r, 2);
      if (r.sons[0].kind <> nkSym) then IllFormedAst(r);
      result := lookupInRecordAndBuildCheck(c, n, r.sons[0], field, check);
      if result <> nil then exit;
      s := newNodeI(nkCurly, r.info);
      for i := 1 to sonsLen(r)-1 do begin
        it := r.sons[i];
        case it.kind of
          nkOfBranch: begin
            result := lookupInRecordAndBuildCheck(c, n, lastSon(it),
                                                  field, check);
            if result = nil then begin
              for j := 0 to sonsLen(it)-2 do addSon(s, copyTree(it.sons[j]));
            end
            else begin
              if check = nil then begin
                check := newNodeI(nkCheckedFieldExpr, n.info);
                addSon(check, nil); // make space for access node
              end;
              s := newNodeI(nkCurly, n.info);
              for j := 0 to sonsLen(it)-2 do addSon(s, copyTree(it.sons[j]));
              inExpr := newNodeI(nkCall, n.info);
              addSon(inExpr, newIdentNode(getIdent('in'), n.info));
              addSon(inExpr, copyTree(r.sons[0]));
              addSon(inExpr, s);
              //writeln(output, renderTree(inExpr));
              addSon(check, semExpr(c, inExpr));
              exit
            end
          end;
          nkElse: begin
            result := lookupInRecordAndBuildCheck(c, n, lastSon(it),
                                                  field, check);
            if result <> nil then begin
              if check = nil  then begin
                check := newNodeI(nkCheckedFieldExpr, n.info);
                addSon(check, nil); // make space for access node
              end;
              inExpr := newNodeI(nkCall, n.info);
              addSon(inExpr, newIdentNode(getIdent('in'), n.info));
              addSon(inExpr, copyTree(r.sons[0]));
              addSon(inExpr, s);
              notExpr := newNodeI(nkCall, n.info);
              addSon(notExpr, newIdentNode(getIdent('not'), n.info));
              addSon(notExpr, inExpr);
              addSon(check, semExpr(c, notExpr));
              exit
            end
          end;
          else
            illFormedAst(it);
        end
      end
    end;
    nkSym: begin
      if r.sym.name.id = field.id then result := r.sym;
    end;
    else illFormedAst(n);
  end
end;

function makeDeref(n: PNode): PNode;
var
  t: PType;
  a: PNode;
begin
  t := n.typ;
  result := n;
  if t.kind = tyVar then begin
    result := newNodeIT(nkHiddenDeref, n.info, t.sons[0]);
    addSon(result, n);
    t := t.sons[0];
  end;
  if t.kind in [tyPtr, tyRef] then begin
    a := result;
    result := newNodeIT(nkDerefExpr, n.info, t.sons[0]);
    addSon(result, a);
  end
end;

function semFieldAccess(c: PContext; n: PNode; flags: TExprFlags): PNode;
var
  f: PSym;
  ty: PType;
  i: PIdent;
  check: PNode;
begin
  // this is difficult, because the '.' is used in many different contexts
  // in Nimrod. We first allow types in the semantic checking.
  checkSonsLen(n, 2);
  n.sons[0] := semExprWithType(c, n.sons[0], [efAllowType]+flags);
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
  else if not (efAllowType in flags) and isTypeExpr(n.sons[0]) then begin
    liMessage(n.sons[0].info, errATypeHasNoValue);
    exit
  end;

  ty := skipPtrsGeneric(ty);
  if ty.kind = tyObject then begin
    while true do begin
      check := nil;
      f := lookupInRecordAndBuildCheck(c, n, ty.n, i, check);
      //f := lookupInRecord(ty.n, i);
      if f <> nil then break;
      if ty.sons[0] = nil then break;
      ty := skipGeneric(ty.sons[0]);
    end;
    if f <> nil then begin
      if ([sfStar, sfMinus] * f.flags <> [])
      or (getModule(f).id = c.module.id) then begin
        // is the access to a public field or in the same module?
        n.sons[0] := makeDeref(n.sons[0]);
        n.sons[1] := newSymNode(f); // we now have the correct field
        n.typ := f.typ;
        if check = nil then result := n
        else begin
          check.sons[0] := n;
          check.typ := n.typ;
          result := check
        end;
        exit
      end
    end
  end
  else if ty.kind = tyTuple then begin
    f := getSymFromList(ty.n, i);
    if f <> nil then begin
      n.sons[0] := makeDeref(n.sons[0]);
      n.sons[1] := newSymNode(f);
      n.typ := f.typ;
      result := n;
      exit
    end
  end;
  // allow things like "".replace(...)
  // --> replace("", ...)
  f := SymTabGet(c.tab, i);
  if (f <> nil) and (f.kind = skStub) then loadStub(f);
  if (f <> nil) and (f.kind in [skProc, skIterator]) then begin
    result := newNodeI(nkDotCall, n.info);
    // This special node kind is to merge with the call handler in `semExpr`.
    addSon(result, newIdentNode(i, n.info));
    addSon(result, copyTree(n.sons[0]));
  end
  else begin
    liMessage(n.Info, errUndeclaredFieldX, i.s);
  end
end;

function whichSliceOpr(n: PNode): string;
begin
  if (n.sons[0] = nil) then
    if (n.sons[1] = nil) then result := '[..]'
    else result := '[..$]'
  else if (n.sons[1] = nil) then result := '[$..]'
  else result := '[$..$]'
end;

function semArrayAccess(c: PContext; n: PNode; flags: TExprFlags): PNode;
var
  arr, indexType: PType;
  i: int;
  arg: PNode;
  idx: biggestInt;
begin
  // check if array type:
  checkMinSonsLen(n, 2);
  n.sons[0] := semExprWithType(c, n.sons[0], flags-[efAllowType]);
  arr := skipPtrsGeneric(n.sons[0].typ);
  case arr.kind of
    tyArray, tyOpenArray, tyArrayConstr, tySequence, tyString,
    tyCString: begin
      n.sons[0] := makeDeref(n.sons[0]);
      for i := 1 to sonsLen(n)-1 do
        n.sons[i] := semExprWithType(c, n.sons[i], flags-[efAllowType]);
      if arr.kind = tyArray then indexType := arr.sons[0]
      else indexType := getSysType(tyInt);
      arg := IndexTypesMatch(c, indexType, n.sons[1].typ, n.sons[1]);
      if arg <> nil then
        n.sons[1] := arg
      else
        liMessage(n.info, errIndexTypesDoNotMatch);
      result := n;
      result.typ := elemType(arr);
    end;
    tyTuple: begin
      n.sons[0] := makeDeref(n.sons[0]);
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
      result := newNodeI(nkCall, n.info);
      if n.sons[1].kind = nkRange then begin
        checkSonsLen(n.sons[1], 2);
        addSon(result, newIdentNode(getIdent(whichSliceOpr(n.sons[1])), n.info));
        addSon(result, n.sons[0]);
        addSonIfNotNil(result, n.sons[1].sons[0]);
        addSonIfNotNil(result, n.sons[1].sons[1]);
      end
      else begin
        addSon(result, newIdentNode(getIdent('[]'), n.info));
        addSon(result, n.sons[0]);
        addSon(result, n.sons[1]);
      end;
      result := semExpr(c, result);
    end
  end
end;

function semIfExpr(c: PContext; n: PNode): PNode;
var
  typ: PType;
  i: int;
  it: PNode;
begin
  result := n;
  checkSonsLen(n, 2);
  typ := nil;
  for i := 0 to sonsLen(n) - 1 do begin
    it := n.sons[i];
    case it.kind of
      nkElifExpr: begin
        checkSonsLen(it, 2);
        it.sons[0] := semExprWithType(c, it.sons[0]);
        checkBool(it.sons[0]);
        it.sons[1] := semExprWithType(c, it.sons[1]);
        if typ = nil then typ := it.sons[1].typ
        else it.sons[1] := fitNode(c, typ, it.sons[1])
      end;
      nkElseExpr: begin
        checkSonsLen(it, 1);
        it.sons[0] := semExprWithType(c, it.sons[0]);
        if (typ = nil) then InternalError(it.info, 'semIfExpr');
        it.sons[0] := fitNode(c, typ, it.sons[0]);
      end;
      else illFormedAst(n);
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
  result := newNodeI(nkCurly, n.info);
  result.typ := newTypeS(tySet, c);
  if sonsLen(n) = 0 then 
    addSon(result.typ, newTypeS(tyEmpty, c))
  else begin
    // only semantic checking for all elements, later type checking:
    typ := nil;
    for i := 0 to sonsLen(n)-1 do begin
      if n.sons[i].kind = nkRange then begin
        checkSonsLen(n.sons[i], 2);
        n.sons[i].sons[0] := semExprWithType(c, n.sons[i].sons[0]);
        n.sons[i].sons[1] := semExprWithType(c, n.sons[i].sons[1]);
        if typ = nil then typ := skipVar(n.sons[i].sons[0].typ);
        n.sons[i].typ := n.sons[i].sons[1].typ; // range node needs type too
      end
      else begin
        n.sons[i] := semExprWithType(c, n.sons[i]);
        if typ = nil then typ := skipVar(n.sons[i].typ)
      end
    end;
    if not isOrdinalType(typ) then begin
      liMessage(n.info, errOrdinalTypeExpected);
      exit
    end;
    if lengthOrd(typ) > MaxSetElements then
      typ := makeRangeType(c, 0, MaxSetElements-1, n.info);
    addSon(result.typ, typ);

    for i := 0 to sonsLen(n)-1 do begin
      if n.sons[i].kind = nkRange then begin
        m := newNodeI(nkRange, n.sons[i].info);
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
  TParKind = (paNone, paSingle, paTupleFields, paTuplePositions);

function checkPar(n: PNode): TParKind;
var
  i, len: int;
begin
  len := sonsLen(n);
  if len = 0 then result := paTuplePositions // ()
  else if len = 1 then result := paSingle // (expr)
  else begin
    if n.sons[0].kind = nkExprColonExpr then result := paTupleFields
    else result := paTuplePositions;
    for i := 0 to len-1 do begin
      if result = paTupleFields then begin
        if (n.sons[i].kind <> nkExprColonExpr)
        or not (n.sons[i].sons[0].kind in [nkSym, nkIdent]) then begin
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

function semTupleFieldsConstr(c: PContext; n: PNode): PNode;
var
  i: int;
  typ: PType;
  ids: TIntSet;
  id: PIdent;
  f: PSym;
begin
  result := newNodeI(nkPar, n.info);
  typ := newTypeS(tyTuple, c);
  typ.n := newNodeI(nkRecList, n.info); // nkIdentDefs
  IntSetInit(ids);
  for i := 0 to sonsLen(n)-1 do begin
    if (n.sons[i].kind <> nkExprColonExpr)
    or not (n.sons[i].sons[0].kind in [nkSym, nkIdent]) then
      illFormedAst(n.sons[i]);
    if n.sons[i].sons[0].kind = nkIdent then
      id := n.sons[i].sons[0].ident
    else
      id := n.sons[i].sons[0].sym.name;
    if IntSetContainsOrIncl(ids, id.id) then
      liMessage(n.sons[i].info, errFieldInitTwice, id.s);
    n.sons[i].sons[1] := semExprWithType(c, n.sons[i].sons[1]);
    f := newSymS(skField, n.sons[i].sons[0], c);
    f.typ := n.sons[i].sons[1].typ;
    addSon(typ, f.typ);
    addSon(typ.n, newSymNode(f));
    n.sons[i].sons[0] := newSymNode(f);
    addSon(result, n.sons[i]);
  end;
  result.typ := typ;
end;

function semTuplePositionsConstr(c: PContext; n: PNode): PNode;
var
  i: int;
  typ: PType;
begin
  result := n; // we don't modify n, but compute the type:
  typ := newTypeS(tyTuple, c);
  // leave typ.n nil!
  for i := 0 to sonsLen(n)-1 do begin
    n.sons[i] := semExprWithType(c, n.sons[i]);
    addSon(typ, n.sons[i].typ);
  end;
  result.typ := typ;
end;

function semStmtListExpr(c: PContext; n: PNode): PNode;
var
  len, i: int;
begin
  result := n;
  checkMinSonsLen(n, 1);
  len := sonsLen(n);
  for i := 0 to len-2 do begin
    n.sons[i] := semStmt(c, n.sons[i]);
  end;
  if len > 0 then begin
    n.sons[len-1] := semExprWithType(c, n.sons[len-1]);
    n.typ := n.sons[len-1].typ
  end
end;

function semBlockExpr(c: PContext; n: PNode): PNode;
begin
  result := n;
  Inc(c.p.nestedBlockCounter);
  checkSonsLen(n, 2);
  openScope(c.tab); // BUGFIX: label is in the scope of block!
  if n.sons[0] <> nil then begin
    addDecl(c, newSymS(skLabel, n.sons[0], c))
  end;
  n.sons[1] := semStmtListExpr(c, n.sons[1]);
  n.typ := n.sons[1].typ;
  closeScope(c.tab);
  Dec(c.p.nestedBlockCounter);
end;

function semDotExpr(c: PContext; n: PNode; flags: TExprFlags): PNode;
var
  s: PSym;
begin
  s := qualifiedLookup(c, n, true); // check for ambiguity
  if s <> nil then
    result := semSym(c, n, s, flags)
  else
    // test!
    result := semFieldAccess(c, n, flags);
end;

function semExpr(c: PContext; n: PNode; flags: TExprFlags = {@set}[]): PNode;
var
  s: PSym;
begin
  result := n;
  if n = nil then exit;
  if nfSem in n.flags then exit;
  case n.kind of
    // atoms:
    nkIdent: begin
      s := lookUp(c, n);
      result := semSym(c, n, s, flags);
    end;
    nkSym: begin
      s := n.sym;
      include(s.flags, sfUsed);
      if (s.kind = skType) and not (efAllowType in flags) then
        liMessage(n.info, errATypeHasNoValue);
      if (s.magic <> mNone) and
          (s.kind in [skProc, skIterator, skConverter]) then
        liMessage(n.info, errInvalidContextForBuiltinX, s.name.s);
    end;
    nkEmpty, nkNone: begin end;
    nkNilLit: result.typ := getSysType(tyNil);
    nkType: begin
      if not (efAllowType in flags) then liMessage(n.info, errATypeHasNoValue);
      n.typ := semTypeNode(c, n, nil);
    end;
    nkIntLit: if result.typ = nil then result.typ := getSysType(tyInt);
    nkInt8Lit: if result.typ = nil then result.typ := getSysType(tyInt8);
    nkInt16Lit: if result.typ = nil then result.typ := getSysType(tyInt16);
    nkInt32Lit: if result.typ = nil then result.typ := getSysType(tyInt32);
    nkInt64Lit: if result.typ = nil then result.typ := getSysType(tyInt64);
    nkFloatLit: if result.typ = nil then result.typ := getSysType(tyFloat);
    nkFloat32Lit: if result.typ = nil then result.typ := getSysType(tyFloat32);
    nkFloat64Lit: if result.typ = nil then result.typ := getSysType(tyFloat64);
    nkStrLit..nkTripleStrLit:
      if result.typ = nil then result.typ := getSysType(tyString);
    nkCharLit:
      if result.typ = nil then result.typ := getSysType(tyChar);
    nkQualified, nkDotExpr: begin
      result := semDotExpr(c, n, flags);
      if result.kind = nkDotCall then begin
        result.kind := nkCall;
        result := semExpr(c, result, flags)
      end;
    end;
    // complex expressions
    nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand: begin
      // check if it is an expression macro:
      checkMinSonsLen(n, 1);
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
            if n.kind <> nkCall then
              liMessage(n.info, errXisNotCallable, s.name.s);
            result := semConv(c, n, s);
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
      checkMinSonsLen(n, 1);
      s := qualifiedLookup(c, n.sons[0], false);
      if (s <> nil) and (s.kind in [skProc, skConverter, skIterator]) then begin
        // type parameters: partial generic specialization
        // XXX: too implement!
        internalError(n.info, 'explicit generic instantation not implemented');
        result := partialSpecialization(c, n, s);
      end
      else begin
        result := semArrayAccess(c, n, flags);
      end
    end;
    nkPragmaExpr: begin
      // which pragmas are allowed for expressions? `likely`, `unlikely`
      internalError(n.info, 'semExpr() to implement');
      // XXX: to implement
    end;
    nkPar: begin
      case checkPar(n) of
        paNone: result := nil;
        paTuplePositions:  result := semTuplePositionsConstr(c, n);
        paTupleFields: result := semTupleFieldsConstr(c, n);
        paSingle: result := semExpr(c, n.sons[0]);
      end;
    end;
    nkCurly: result := semSetConstr(c, n);
    nkBracket: result := semArrayConstr(c, n);
    nkLambda: result := semLambda(c, n); // handled in semstmts
    nkExprColonExpr: begin
      internalError(n.info, 'semExpr() to implement');
      // XXX: to implement for array constructors!
    end;
    nkDerefExpr: begin
      checkSonsLen(n, 1);
      n.sons[0] := semExprWithType(c, n.sons[0]);
      result := n;
      case skipVarGeneric(n.sons[0].typ).kind of
        tyRef, tyPtr: n.typ := n.sons[0].typ.sons[0];
        else liMessage(n.sons[0].info, errCircumNeedsPointer);
      end;
      result := n;
    end;
    nkAddr: begin
      result := n;
      checkSonsLen(n, 1);
      n.sons[0] := semExprWithType(c, n.sons[0]);
      if not isAssignable(n.sons[0]) then liMessage(n.info, errExprHasNoAddress);
      n.typ := makePtrType(c, n.sons[0].typ);
    end;
    nkHiddenAddr, nkHiddenDeref: begin
      checkSonsLen(n, 1);
      n.sons[0] := semExpr(c, n.sons[0], flags);
    end;
    nkCast: result := semCast(c, n);
    nkAccQuoted: begin
      checkSonsLen(n, 1);
      result := semExpr(c, n.sons[0]);
    end;
    nkHeaderQuoted: begin
      // look up the proc:
      internalError(n.info, 'semExpr() to implement');
      // XXX: to implement
    end;
    nkIfExpr: result := semIfExpr(c, n);
    nkStmtListExpr: result := semStmtListExpr(c, n);
    nkBlockExpr: result := semBlockExpr(c, n);
    nkHiddenStdConv, nkHiddenSubConv, nkConv, nkHiddenCallConv:
      checkSonsLen(n, 2);
    nkStringToCString, nkCStringToString, nkPassAsOpenArray, nkObjDownConv,
    nkObjUpConv:
      checkSonsLen(n, 1);
    nkChckRangeF, nkChckRange64, nkChckRange:
      checkSonsLen(n, 3);
    nkCheckedFieldExpr:
      checkMinSonsLen(n, 2);
    else begin
      //InternalError(n.info, nodeKindToStr[n.kind]);
      liMessage(n.info, errInvalidExpressionX,
                renderTree(n, {@set}[renderNoComments]));
      result := nil
    end
  end;
  include(result.flags, nfSem);
end;
