//
//
//           The Nimrod Compiler
//        (c) Copyright 2008 Andreas Rumpf
//
//    See the file "copying.txt", included in this
//    distribution, for details about the copyright.
//

const
  RangeExpandLimit = 256;     // do not generate ranges
  // over 'RangeExpandLimit' elements

procedure genLineDir(p: BProc; t: PNode);
var
  line: int;
begin
  line := toLinenumber(t.info); // BUGFIX
  if line < 0 then line := 0; // negative numbers are not allowed in #line
  if optLineDir in p.Options then
    appRopeFormat(p.s[cpsStmts], '#line $2 "$1"$n',
      [toRope(toFilename(t.info)), toRope(line)]);
  if ([optStackTrace, optEndb] * p.Options = [optStackTrace, optEndb]) and
      ((p.prc = nil) or not (sfPure in p.prc.flags)) then begin
    useMagic('endb');      // new: endb support
    appRopeFormat(p.s[cpsStmts], 'endb($1);$n', [toRope(line)])
  end
  else if ([optLineTrace, optStackTrace] * p.Options =
        [optLineTrace, optStackTrace]) and ((p.prc = nil) or
      not (sfPure in p.prc.flags)) then
    appRopeFormat(p.s[cpsStmts], 'F.line = $1;$n', [toRope(line)])
end;

procedure genReturnStmt(p: BProc; t: PNode);
begin
  p.beforeRetNeeded := true;
  genLineDir(p, t);
  if (t.sons[0] <> nil) then genStmts(p, t.sons[0]);
  app(p.s[cpsStmts], 'goto BeforeRet;' + tnl)
end;

procedure genObjectInit(p: BProc; sym: PSym);
begin
  if containsObject(sym.typ) then begin
    useMagic('objectInit');
    appRopeFormat(p.s[cpsInit], 'objectInit($1, $2);$n',
      [addrLoc(sym.loc), genTypeInfo(currMod, sym.typ)])
  end
end;

procedure initVariable(p: BProc; v: PSym);
begin
  if containsGarbageCollectedRef(v.typ) or (v.ast = nil) then
    // Language change: always initialize variables if v.ast == nil!
    if not (skipAbstract(v.typ).Kind in [tyArray, tyArrayConstr, tySet,
                                         tyRecord, tyTuple, tyObject]) then
      appRopeFormat(p.s[cpsInit], '$1 = 0;$n', [v.loc.r])
    else
      appRopeFormat(p.s[cpsInit], 'memset((void*)&$1, 0, sizeof($1));$n',
        [v.loc.r])
end;

procedure genVarStmt(p: BProc; n: PNode);
var
  i: int;
  v: PSym;
  a: PNode;
begin
  for i := 0 to sonsLen(n)-1 do begin
    a := n.sons[i];
    if a.kind = nkCommentStmt then continue;
    assert(a.kind = nkIdentDefs);
    assert(a.sons[0].kind = nkSym);
    v := a.sons[0].sym;
    if sfGlobal in v.flags then
      assignGlobalVar(v)
    else begin
      assignLocalVar(p, v);
      initVariable(p, v) // XXX: this is not required if a.sons[2] != nil,
                         // unless it is a GC'ed pointer
    end;
    // generate assignment:
    if a.sons[2] <> nil then begin
      genLineDir(p, a);
      expr(p, a.sons[2], v.loc);
    end;
    genObjectInit(p, v); // XXX: correct position?
  end
end;

procedure genConstStmt(p: BProc; t: PNode);
var
  c: PSym;
  i: int;
begin
  for i := 0 to sonsLen(t)-1 do begin
    if t.sons[i].kind = nkCommentStmt then continue;
    assert(t.sons[i].kind = nkConstDef);
    c := t.sons[i].sons[0].sym;
    // This can happen for forward consts:
    if (c.ast <> nil) and (c.typ.kind in ConstantDataTypes) and
           not (lfNoDecl in c.loc.flags) then begin
      // generate the data:
      fillLoc(c.loc, locData, c.typ, mangleName(c), {@set}[lfOnData]);
      if sfImportc in c.flags then
        appRopeFormat(currMod.s[cfsData], 'extern $1$2 $3;$n',
          [constTok, getTypeDesc(c.typ), c.loc.r])
      else
        appRopeFormat(currMod.s[cfsData], '$1$2 $3 = $4;$n',
          [constTok, getTypeDesc(c.typ), c.loc.r, genConstExpr(p, c.ast)])
    end
  end
end;

procedure genIfStmt(p: BProc; n: PNode);
(*
  if (!expr1) goto L1;
  thenPart
  goto LEnd
  L1:
  if (!expr2) goto L2;
  thenPart2
  goto LEnd
  L2:
  elsePart
  Lend:
*)
var
  i: int;
  it: PNode;
  a: TLoc;
  Lend, Lelse: TLabel;
begin
  genLineDir(p, n);
  Lend := getLabel(p);
  for i := 0 to sonsLen(n)-1 do begin
    it := n.sons[i];
    case it.kind of
      nkElifBranch: begin
        a := initLocExpr(p, it.sons[0]);
        Lelse := getLabel(p);
        appRopeFormat(p.s[cpsStmts], 'if (!$1) goto $2;$n', [rdLoc(a), Lelse]);
        freeTemp(p, a);
        genStmts(p, it.sons[1]);
        if sonsLen(n) > 1 then
          appRopeFormat(p.s[cpsStmts], 'goto $1;$n', [Lend]);
        fixLabel(p, Lelse);
      end;
      nkElse: begin
        genStmts(p, it.sons[0]);
      end;
      else internalError(n.info, 'genIfStmt()');
    end
  end;
  if sonsLen(n) > 1 then
    fixLabel(p, Lend);
end;

procedure genWhileStmt(p: BProc; t: PNode);
// we don't generate labels here as for example GCC would produce
// significantly worse code
var
  a: TLoc;
  Labl: TLabel;
  len: int;
begin
  genLineDir(p, t);
  assert(sonsLen(t) = 2);
  inc(p.unique);
  Labl := con('L'+'', toRope(p.unique));
  len := length(p.blocks);
  setLength(p.blocks, len+1);
  p.blocks[len] := p.unique; // positive because we use it right away:
  app(p.s[cpsStmts], 'while (1) {' + tnl);
  a := initLocExpr(p, t.sons[0]);
  appRopeFormat(p.s[cpsStmts], 'if (!$1) goto $2;$n', [rdLoc(a), Labl]);
  freeTemp(p, a);
  genStmts(p, t.sons[1]);
  appRopeFormat(p.s[cpsStmts], '} $1: ;$n', [Labl]);
  setLength(p.blocks, length(p.blocks)-1)
end;

procedure genBlock(p: BProc; t: PNode; var d: TLoc);
var
  idx: int;
  sym: PSym;
begin
  inc(p.unique);
  idx := length(p.blocks);
  if t.sons[0] <> nil then begin // named block?
    assert(t.sons[0].kind = nkSym);
    sym := t.sons[0].sym;
    sym.loc.k := locOther;
    sym.loc.a := idx
  end;
  setLength(p.blocks, idx+1);
  p.blocks[idx] := -p.unique; // negative because it isn't used yet
  if t.kind = nkBlockExpr then genStmtListExpr(p, t.sons[1], d)
  else genStmts(p, t.sons[1]);
  if p.blocks[idx] > 0 then // label has been used:
    appRopeFormat(p.s[cpsStmts], 'L$1: ;$n', [toRope(p.blocks[idx])]);
  setLength(p.blocks, idx)
end;

procedure genBreakStmt(p: BProc; t: PNode);
var
  idx: int;
  sym: PSym;
begin
  genLineDir(p, t);
  idx := length(p.blocks)-1;
  if t.sons[0] <> nil then begin // named break?
    assert(t.sons[0].kind = nkSym);
    sym := t.sons[0].sym;
    assert(sym.loc.k = locOther);
    idx := sym.loc.a
  end;
  p.blocks[idx] := abs(p.blocks[idx]); // label is used
  appRopeFormat(p.s[cpsStmts], 'goto L$1;$n', [toRope(p.blocks[idx])])
end;

procedure genAsmStmt(p: BProc; t: PNode);
var
  i: int;
  sym: PSym;
  r, s: PRope;
begin
  genLineDir(p, t);
  assert(t.kind = nkAsmStmt);
  s := nil;
  for i := 0 to sonsLen(t) - 1 do begin
    case t.sons[i].Kind of
      nkStrLit..nkTripleStrLit: app(s, t.sons[i].strVal);
      nkSym: begin
        sym := t.sons[i].sym;
        r := sym.loc.r;
        if r = nil then begin // if no name has already been given,
                     // it doesn't matter much:
          r := mangleName(sym);
          sym.loc.r := r; // but be consequent!
        end;
        app(s, r)
      end
      else
        InternalError(t.sons[i].info, 'genAsmStmt()')
    end
  end;
  appRopeFormat(p.s[cpsStmts], CC[ccompiler].asmStmtFrmt, [s]);
end;

function getRaiseFrmt(): string;
begin
  if gCmd = cmdCompileToCpp then
    result := 'throw nimException($1, $2);$n'
  else begin  
    useMagic('E_Base');
    result := 'raiseException((E_Base*)$1, $2);$n'
  end
end;

procedure genRaiseStmt(p: BProc; t: PNode);
var
  e: PRope;
  a: TLoc;
  typ: PType;
begin
  genLineDir(p, t);
  if t.sons[0] <> nil then begin
    if gCmd <> cmdCompileToCpp then
      useMagic('raiseException');
    a := InitLocExpr(p, t.sons[0]);
    e := rdLoc(a);
    freeTemp(p, a);
    typ := t.sons[0].typ;
    while typ.kind in [tyVar, tyRef, tyPtr] do typ := typ.sons[0];
    appRopeFormat(p.s[cpsStmts], getRaiseFrmt(),
      [e, makeCString(typ.sym.name.s)])
  end
  else begin
    // reraise the last exception:
    if gCmd = cmdCompileToCpp then
      app(p.s[cpsStmts], 'throw;' + tnl)
    else begin
      useMagic('reraiseException');
      app(p.s[cpsStmts], 'reraiseException();' + tnl)
    end
  end
end;

// ---------------- case statement generation -----------------------------

const
  stringCaseThreshold = 1000; //4; // above X strings a hash-switch for strings
                          // is generated
  // this version sets it too high to avoid hashing, because the hashing
  // algorithm won't be the same; I don't know why

procedure genCaseGenericBranch(p: BProc; b: PNode; const e: TLoc;
                               const rangeFormat, eqFormat: TFormatStr;
                               labl: TLabel);
var
  len, i: int;
  x, y: TLoc;
begin
  len := sonsLen(b);
  for i := 0 to len - 2 do begin
    if b.sons[i].kind = nkRange then begin
      x := initLocExpr(p, b.sons[i].sons[0]);
      y := initLocExpr(p, b.sons[i].sons[1]);
      freeTemp(p, x);
      freeTemp(p, y);
      appRopeFormat(p.s[cpsStmts], rangeFormat,
        [rdCharLoc(e), rdCharLoc(x), rdCharLoc(y), labl])
    end
    else begin
      x := initLocExpr(p, b.sons[i]);
      freeTemp(p, x);
      appRopeFormat(p.s[cpsStmts], eqFormat,
        [rdCharLoc(e), rdCharLoc(x), labl])
    end
  end
end;

procedure genCaseSecondPass(p: BProc; t: PNode; labId: int);
var
  Lend: TLabel;
  i, len: int;
begin
  Lend := getLabel(p);
  for i := 1 to sonsLen(t) - 1 do begin
    appRopeFormat(p.s[cpsStmts], 'L$1: ;$n', [toRope(labId+i)]);
    if t.sons[i].kind = nkOfBranch then begin
      len := sonsLen(t.sons[i]);
      genStmts(p, t.sons[i].sons[len-1]);
      appRopeFormat(p.s[cpsStmts], 'goto $1;$n', [Lend])
    end
    else // else statement
      genStmts(p, t.sons[i].sons[0])
  end;
  fixLabel(p, Lend);
end;

procedure genCaseGeneric(p: BProc; t: PNode; const rangeFormat,
                         eqFormat: TFormatStr);
  // generate a C-if statement for a Nimrod case statement
var
  a: TLoc;
  i, labId: int;
begin
  a := initLocExpr(p, t.sons[0]);
  // fist pass: gnerate ifs+goto:
  labId := p.unique;
  for i := 1 to sonsLen(t) - 1 do begin
    inc(p.unique);
    if t.sons[i].kind = nkOfBranch then
      genCaseGenericBranch(p, t.sons[i], a, rangeFormat, eqFormat,
        con('L'+'', toRope(p.unique)))
    else
      // else statement
      appRopeFormat(p.s[cpsStmts], 'goto L$1;$n', [toRope(p.unique)]);
  end;
  // second pass: generate statements
  genCaseSecondPass(p, t, labId);
  freeTemp(p, a)
end;

{@ignore}
{$ifopt Q+} { we need Q- here! }
  {$define Q_on}
  {$Q-}
{$endif}

{$ifopt R+}
  {$define R_on}
  {$R-}
{$endif}
{@emit}
function hashString(const s: string): biggestInt;
var
  a: int32;
  b: int64;
  i: int;
begin
  if CPU[targetCPU].bit = 64 then begin // we have to use the same bitwidth
    // as the target CPU
    b := 0;
    for i := 0 to Length(s)-1 do begin
      b := b +{%} Ord(s[i]);
      b := b +{%} b shl 10;
      b := b xor (b shr 6)
    end;
    b := b +{%} b shl 3;
    b := b xor (b shr 11);
    b := b +{%} b shl 15;
    result := b
  end
  else begin
    a := 0;
    for i := 0 to Length(s)-1 do begin
      a := a +{%} Ord(s[i]);
      a := a +{%} a shl 10;
      a := a xor (a shr 6);
    end;
    a := a +{%} a shl 3;
    a := a xor (a shr 11);
    a := a +{%} a shl 15;
    result := a
  end
end;
{@ignore}
{$ifdef Q_on}
  {$undef Q_on}
  {$Q+}
{$endif}

{$ifdef R_on}
  {$undef R_on}
  {$R+}
{$endif}
{@emit}

type
  TRopeSeq = array of PRope;

procedure genCaseStringBranch(p: BProc; b: PNode; const e: TLoc;
                              labl: TLabel; var branches: TRopeSeq);
var
  len, i, j: int;
  x: TLoc;
begin
  len := sonsLen(b);
  for i := 0 to len - 2 do begin
    assert(b.sons[i].kind <> nkRange);
    x := initLocExpr(p, b.sons[i]);
    freeTemp(p, x);
    assert(b.sons[i].kind in [nkStrLit..nkTripleStrLit]);
    j := int(hashString(b.sons[i].strVal) and high(branches));
    appRopeFormat(branches[j], 'if (eqStrings($1, $2)) goto $3;$n',
      [rdLoc(e), rdLoc(x), labl])
  end
end;

procedure genStringCase(p: BProc; t: PNode);
var
  strings, i, j, bitMask, labId: int;
  a: TLoc;
  branches: TRopeSeq;
begin
  useMagic('eqStrings');
  // count how many constant strings there are in the case:
  strings := 0;
  for i := 1 to sonsLen(t)-1 do
    if t.sons[i].kind = nkOfBranch then inc(strings, sonsLen(t.sons[i])-1);
  if strings > stringCaseThreshold then begin
    useMagic('hashString');
    bitMask := nmath.nextPowerOfTwo(strings)-1;
    setLength(branches, bitMask+1);
    a := initLocExpr(p, t.sons[0]);
    // fist pass: gnerate ifs+goto:
    labId := p.unique;
    for i := 1 to sonsLen(t) - 1 do begin
      inc(p.unique);
      if t.sons[i].kind = nkOfBranch then
        genCaseStringBranch(p, t.sons[i], a, con('L'+'', toRope(p.unique)),
                            branches)
      else begin end
        // else statement: nothing to do yet
        // but we reserved a label, which we use later
    end;
    // second pass: generate switch statement based on hash of string:
    appRopeFormat(p.s[cpsStmts], 'switch (hashString($1) & $2) {$n',
      [rdLoc(a), toRope(bitMask)]);
    for j := 0 to high(branches) do
      if branches[j] <> nil then
        appRopeFormat(p.s[cpsStmts], 'case $1: $n$2break;$n',
          [intLiteral(j), branches[j]]);
    app(p.s[cpsStmts], '}' + tnl);
    // else statement:
    if t.sons[sonsLen(t)-1].kind <> nkOfBranch then
      appRopeFormat(p.s[cpsStmts], 'goto L$1;$n', [toRope(p.unique)]);
    // third pass: generate statements
    genCaseSecondPass(p, t, labId);
    freeTemp(p, a);
  end
  else
    genCaseGeneric(p, t, '', 'if (eqStrings($1, $2)) goto $3;$n')
end;

function branchHasTooBigRange(b: PNode): bool;
var
  i: int;
begin
  for i := 0 to sonsLen(b)-2 do begin  // last son is block
    if (b.sons[i].Kind = nkRange) and
        (b.sons[i].sons[1].intVal - b.sons[i].sons[0].intVal >
        RangeExpandLimit) then begin
      result := true; exit
    end;
  end;
  result := false
end;

procedure genOrdinalCase(p: BProc; t: PNode);
// We analyse if we have a too big switch range. If this is the case,
// we generate an ordinary if statement and rely on the C compiler
// to produce good code.
var
  canGenerateSwitch: bool;
  i, j, len: int;
  a: TLoc;
  v: PNode;
begin
  canGenerateSwitch := true;
  if not (hasSwitchRange in CC[ccompiler].props) then
    // if the C compiler supports switch ranges, no analysis is necessary
    for i := 1 to sonsLen(t)-1 do
      if (t.sons[i].kind = nkOfBranch) and branchHasTooBigRange(t.sons[i]) then
      begin
        canGenerateSwitch := false;
        break
      end;
  if canGenerateSwitch then begin
    a := initLocExpr(p, t.sons[0]);
    appRopeFormat(p.s[cpsStmts], 'switch ($1) {$n', [rdCharLoc(a)]);
    freeTemp(p, a);
    for i := 1 to sonsLen(t)-1 do begin
      if t.sons[i].kind = nkOfBranch then begin
        len := sonsLen(t.sons[i]);
        for j := 0 to len-2 do begin
          if t.sons[i].sons[j].kind = nkRange then begin // a range
            if hasSwitchRange in CC[ccompiler].props then
              appRopeFormat(p.s[cpsStmts], 'case $1 ... $2:$n',
                [genLiteral(p, t.sons[i].sons[j].sons[0]),
                 genLiteral(p, t.sons[i].sons[j].sons[1])])
            else begin
              v := copyNode(t.sons[i].sons[j].sons[0]);
              while (v.intVal <= t.sons[i].sons[j].sons[1].intVal) do begin
                appRopeFormat(p.s[cpsStmts], 'case $1:$n', [genLiteral(p, v)]);
                Inc(v.intVal)
              end
            end;
          end
          else
            appRopeFormat(p.s[cpsStmts], 'case $1:$n',
              [genLiteral(p, t.sons[i].sons[j])]);
        end;
        genStmts(p, t.sons[i].sons[len-1])
      end
      else begin // else part of case statement:
        app(p.s[cpsStmts], 'default:' + tnl);
        genStmts(p, t.sons[i].sons[0]);
      end;
      app(p.s[cpsStmts], 'break;' + tnl);
    end;
    app(p.s[cpsStmts], '}' + tnl);
  end
  else
    genCaseGeneric(p, t,
      'if ($1 >= $2 && $1 <= $3) goto $4;$n',
      'if ($1 == $2) goto $3;$n')
end;

procedure genCaseStmt(p: BProc; t: PNode);
begin
  genLineDir(p, t);
  case skipAbstract(t.sons[0].typ).kind of
    tyString: genStringCase(p, t);
    tyFloat..tyFloat128:
      genCaseGeneric(p, t, 'if ($1 >= $2 && $1 <= $3) goto $4;$n',
                           'if ($1 == $2) goto $3;$n');
  // ordinal type: generate a switch statement
    else genOrdinalCase(p, t)
  end
end;

// ----------------------- end of case statement generation ---------------

function hasGeneralExceptSection(t: PNode): bool;
var
  len, i, blen: int;
begin
  len := sonsLen(t);
  i := 1;
  while (i < len) and (t.sons[i].kind = nkExceptBranch) do begin
    blen := sonsLen(t.sons[i]);
    if blen = 1 then begin result := true; exit end;
    inc(i)
  end;
  result := false
end;

procedure genTryStmtCpp(p: BProc; t: PNode);
  // code to generate:
(*
   bool tmpRethrow = false;
   try
   {
      myDiv(4, 9);
   } catch (NimException& tmp) {
      tmpRethrow = true;
      switch (tmp.exc)
      {
         case DIVIDE_BY_ZERO:
           tmpRethrow = false;
           printf('Division by Zero\n');
         break;
      default: // used for general except!
         generalExceptPart();
         tmpRethrow = false;
      }
  }
  excHandler = excHandler->prev; // we handled the exception
  finallyPart();
  if (tmpRethrow) throw; *)
var
  rethrowFlag: PRope;
  exc: PRope;
  i, len, blen, j: int;
begin
  genLineDir(p, t);
  rethrowFlag := nil;
  exc := getTempName();
  if not hasGeneralExceptSection(t) then begin
    rethrowFlag := getTempName();
    appRopeFormat(p.s[cpsLocals], 'volatile NIM_BOOL $1 = NIM_FALSE;$n',
      [rethrowFlag])
  end;
  if optStackTrace in p.Options then
    app(p.s[cpsStmts], 'framePtr = (TFrame*)&F;' + tnl);
  app(p.s[cpsStmts], 'try {' + tnl);
  inc(p.inTryStmt);
  genStmts(p, t.sons[0]);
  dec(p.inTryStmt);
  len := sonsLen(t);
  if t.sons[1].kind = nkExceptBranch then begin
    appRopeFormat(p.s[cpsStmts], '} catch (NimException& $1) {$n', [exc]);
    if rethrowFlag <> nil then
      appRopeFormat(p.s[cpsStmts], '$1 = NIM_TRUE;$n', [rethrowFlag]);
    appRopeFormat(p.s[cpsStmts], 'if ($1.sp.exc) {$n', [exc])
  end; // XXX: this is not correct!
  i := 1;
  while (i < len) and (t.sons[i].kind = nkExceptBranch) do begin
    blen := sonsLen(t.sons[i]);
    if blen = 1 then begin      // general except section:
      app(p.s[cpsStmts], 'default: ' + tnl);
      genStmts(p, t.sons[i].sons[0])
    end
    else begin
      for j := 0 to blen - 2 do begin
        assert(t.sons[i].sons[j].kind = nkType);
        appRopeFormat(p.s[cpsStmts], 'case $1:$n',
          [toRope(t.sons[i].sons[j].typ.id)])
      end;
      genStmts(p, t.sons[i].sons[blen - 1])
    end;
    // code to clear the exception:
    if rethrowFlag <> nil then
      appRopeFormat(p.s[cpsStmts], '$1 = NIM_FALSE;  ', [rethrowFlag]);
    app(p.s[cpsStmts], 'break;' + tnl);
    inc(i);
  end;
  if t.sons[1].kind = nkExceptBranch then // BUGFIX
    app(p.s[cpsStmts], '}}' + tnl); // end of catch-switch statement
  app(p.s[cpsStmts], 'excHandler = excHandler->prev;' + tnl);
  if (i < len) and (t.sons[i].kind = nkFinally) then begin
    genStmts(p, t.sons[i].sons[0]);
    if rethrowFlag <> nil then
      appRopeFormat(p.s[cpsStmts], 'if ($1) { throw; }$n', [rethrowFlag])
  end
end;

procedure genTryStmt(p: BProc; t: PNode);
  // code to generate:
(*
  sp.prev = excHandler;
  excHandler = &sp;
  sp.status = setjmp(sp.context);
  if (sp.status == 0) {
    myDiv(4, 9);
  } else {
    /* except DivisionByZero: */
    if (sp.status == DivisionByZero) {
      printf('Division by Zero\n');

      /* longjmp(excHandler->context, RangeError); /* raise rangeError */
      sp.status = RangeError; /* if raise; else 0 */
    }
  }
  /* finally: */
  printf('fin!\n');
  if (sp.status != 0)
    longjmp(excHandler->context, sp.status);
  excHandler = excHandler->prev; /* deactivate this safe point */ *)
var
  i, j, len, blen: int;
  safePoint, orExpr: PRope;
begin
  genLineDir(p, t);

  safePoint := getTempName();
  useMagic('TSafePoint');
  useMagic('E_Base');
  useMagic('excHandler');
  appRopeFormat(p.s[cpsLocals], 'volatile TSafePoint $1;$n', [safePoint]);
  appRopeFormat(p.s[cpsStmts], '$1.prev = excHandler;$n' +
                               'excHandler = &$1;$n' +
                               '$1.status = setjmp($1.context);$n' +
                               'if ($1.status == 0) {$n', [safePoint]);
  if optStackTrace in p.Options then
    app(p.s[cpsStmts], 'framePtr = (TFrame*)&F;' + tnl);
  len := sonsLen(t);
  inc(p.inTryStmt);
  genStmts(p, t.sons[0]);
  app(p.s[cpsStmts], '} else {' + tnl);
  dec(p.inTryStmt);
  i := 1;
  while (i < len) and (t.sons[i].kind = nkExceptBranch) do begin
    blen := sonsLen(t.sons[i]);
    if blen = 1 then begin
      // general except section:
      if i > 1 then app(p.s[cpsStmts], 'else {' + tnl);
      genStmts(p, t.sons[i].sons[0]);
      appRopeFormat(p.s[cpsStmts], '$1.status = 0;$n', [safePoint]);
      if i > 1 then app(p.s[cpsStmts], '}' + tnl);
    end
    else begin
      orExpr := nil;
      for j := 0 to blen - 2 do begin
        assert(t.sons[i].sons[j].kind = nkType);
        if orExpr <> nil then app(orExpr, '||');
        appRopeFormat(orExpr, '($1.exc->Sup.m_type == $2)',
          [safePoint, genTypeInfo(currMod, t.sons[i].sons[j].typ)])
      end;
      if i > 1 then app(p.s[cpsStmts], 'else ');
      appRopeFormat(p.s[cpsStmts], 'if ($1) {$n', [orExpr]);
      genStmts(p, t.sons[i].sons[blen - 1]);
      // code to clear the exception:
      appRopeFormat(p.s[cpsStmts], '$1.status = 0;}$n', [safePoint]);
    end;
    inc(i)
  end;
  app(p.s[cpsStmts], '}' + tnl); // end of if statement
  app(p.s[cpsStmts], 'excHandler = excHandler->prev;' + tnl);
  if (i < len) and (t.sons[i].kind = nkFinally) then begin
    genStmts(p, t.sons[i].sons[0]);
    useMagic('raiseException');
    appRopeFormat(p.s[cpsStmts], 'if ($1.status != 0) { ' +
      'raiseException($1.exc, $1.exc->Name); }$n', [safePoint])
  end
end;

var
  breakPointId: int = 0;
  gBreakpoints: PRope; // later the breakpoints are inserted into the main proc

procedure genBreakPoint(p: BProc; t: PNode);
var
  name: string;
begin
  if optEndb in p.Options then begin
    if t.kind = nkExprColonExpr then begin
      assert(t.sons[1].kind in [nkStrLit..nkTripleStrLit]);
      name := normalize(t.sons[1].strVal)
    end
    else begin
      inc(breakPointId);
      name := 'bp' + toString(breakPointId)
    end;
    genLineDir(p, t); // BUGFIX
    appRopeFormat(gBreakpoints,
      'dbgRegisterBreakpoint($1, (NCSTRING)$2, (NCSTRING)$3);$n',
      [toRope(toLinenumber(t.info)), makeCString(toFilename(t.info)),
      makeCString(name)])
  end
end;

procedure genPragma(p: BProc; n: PNode);
var
  i: int;
  it, key: PNode;
begin
  for i := 0 to sonsLen(n)-1 do begin
    it := n.sons[i];
    if it.kind = nkExprColonExpr then begin
      key := it.sons[0];
    end
    else begin
      key := it;
    end;
    assert(key.kind = nkIdent);
    case whichKeyword(key.ident) of
      wBreakpoint: genBreakPoint(p, it);
      else begin end
    end
  end
end;

procedure genAsgn(p: BProc; e: PNode);
var
  a: TLoc;
begin
  genLineDir(p, e); // BUGFIX
  a := InitLocExpr(p, e.sons[0]);
  assert(a.t <> nil);
  expr(p, e.sons[1], a);
  freeTemp(p, a)
end;

procedure genStmts(p: BProc; t: PNode);
var
  a: TLoc;
  i: int;
  prc: PSym;
begin
  assert(t <> nil);
  if inCheckpoint(t.info) then
    MessageOut(renderTree(t));
  case t.kind of
    nkEmpty:       begin end; // nothing to do!
    nkStmtList:
      for i := 0 to sonsLen(t) - 1 do
        genStmts(p, t.sons[i]);
    nkBlockStmt:   genBlock(p, t, a);
    nkIfStmt:      genIfStmt(p, t);
    nkWhileStmt:   genWhileStmt(p, t);
    nkVarSection:  genVarStmt(p, t);
    nkConstSection: genConstStmt(p, t);
    nkForStmt:     internalError(t.info, 'for statement not eliminated');
    nkCaseStmt:    genCaseStmt(p, t);
    nkReturnStmt:  genReturnStmt(p, t);
    nkBreakStmt:   genBreakStmt(p, t);
    nkCall: begin
      genLineDir(p, t);
      a := initLocExpr(p, t);
      freeTemp(p, a);
    end;
    nkAsgn: genAsgn(p, t);
    nkDiscardStmt: begin
      genLineDir(p, t);
      a := initLocExpr(p, t.sons[0]);
      freeTemp(p, a)
    end;
    nkAsmStmt: genAsmStmt(p, t);
    nkTryStmt:
      if gCmd = cmdCompileToCpp then genTryStmtCpp(p, t)
      else genTryStmt(p, t);
    nkRaiseStmt: genRaiseStmt(p, t);
    nkTypeSection: begin
      // nothing to do:
      // we generate only when the symbol is accessed
    end;
    nkCommentStmt, nkNilLit, nkIteratorDef, nkIncludeStmt, nkImportStmt,
    nkFromStmt, nkTemplateDef, nkMacroDef: begin end;
    nkPragma: genPragma(p, t);
    nkProcDef: begin
      if (t.sons[genericParamsPos] = nil) then begin
        prc := t.sons[namePos].sym;
        if (t.sons[codePos] <> nil) 
        or (lfDynamicLib in prc.loc.flags) then begin // BUGFIX
          if IntSetContainsOrIncl(currMod.debugDeclared, prc.id) then begin
            internalError(t.info, 'genProc()'); // XXX: remove this check!
          end;
          genProc(prc)
        end
        //else if sfCompilerProc in prc.flags then genProcPrototype(prc);
      end
    end;
    else
      internalError(t.info, 'genStmts(' +{&} nodeKindToStr[t.kind] +{&} ')')
  end
end;
