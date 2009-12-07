//
//
//           The Nimrod Compiler
//        (c) Copyright 2009 Andreas Rumpf
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
    appff(p.s[cpsStmts], 
      '#line $2 "$1"$n',
      '; line $2 "$1"$n',
      [toRope(toFilename(t.info)), toRope(line)]);
  if ([optStackTrace, optEndb] * p.Options = [optStackTrace, optEndb]) and
      ((p.prc = nil) or not (sfPure in p.prc.flags)) then begin
    useMagic(p.module, 'endb');      // new: endb support
    appff(p.s[cpsStmts], 'endb($1);$n', 
         'call void @endb(%NI $1)$n',
         [toRope(line)])
  end
  else if ([optLineTrace, optStackTrace] * p.Options =
        [optLineTrace, optStackTrace]) and ((p.prc = nil) or
      not (sfPure in p.prc.flags)) then begin
    inc(p.labels);
    appff(p.s[cpsStmts], 'F.line = $1;$n', 
         '%LOC$2 = getelementptr %TF %F, %NI 2$n' +
         'store %NI $1, %NI* %LOC$2$n',
         [toRope(line), toRope(p.labels)])
  end
end;

procedure finishTryStmt(p: BProc; howMany: int);
var
  i: int;
begin
  for i := 1 to howMany do begin
    inc(p.labels, 3);
    appff(p.s[cpsStmts], 'excHandler = excHandler->prev;$n',
          '%LOC$1 = load %TSafePoint** @excHandler$n' +
          '%LOC$2 = getelementptr %TSafePoint* %LOC$1, %NI 0$n' +
          '%LOC$3 = load %TSafePoint** %LOC$2$n' +
          'store %TSafePoint* %LOC$3, %TSafePoint** @excHandler$n', 
          [toRope(p.labels), toRope(p.labels-1), toRope(p.labels-2)]);
  end
end;

procedure genReturnStmt(p: BProc; t: PNode);
begin
  p.beforeRetNeeded := true;
  genLineDir(p, t);
  if (t.sons[0] <> nil) then genStmts(p, t.sons[0]);
  finishTryStmt(p, p.nestedTryStmts);
  appff(p.s[cpsStmts], 'goto BeforeRet;$n', 'br label %BeforeRet$n', [])
end;

procedure initVariable(p: BProc; v: PSym);
begin
  if containsGarbageCollectedRef(v.typ) or (v.ast = nil) then
    // Language change: always initialize variables if v.ast == nil!
    if not (skipTypes(v.typ, abstractVarRange).Kind in [tyArray, 
            tyArrayConstr, tySet, tyTuple, tyObject]) then begin
      if gCmd = cmdCompileToLLVM then
        appf(p.s[cpsStmts], 'store $2 0, $2* $1$n', 
             [addrLoc(v.loc), getTypeDesc(p.module, v.loc.t)])
      else
        appf(p.s[cpsStmts], '$1 = 0;$n', [rdLoc(v.loc)])
    end
    else begin
      if gCmd = cmdCompileToLLVM then begin
        app(p.module.s[cfsProcHeaders], 
            'declare void @llvm.memset.i32(i8*, i8, i32, i32)' + tnl);
        inc(p.labels, 2);
        appf(p.s[cpsStmts], 
            '%LOC$3 = getelementptr $2* null, %NI 1$n' +
            '%LOC$4 = cast $2* %LOC$3 to i32$n' +
            'call void @llvm.memset.i32(i8* $1, i8 0, i32 %LOC$4, i32 0)$n', 
            [addrLoc(v.loc), getTypeDesc(p.module, v.loc.t), 
            toRope(p.labels), toRope(p.labels-1)])
      end
      else
        appf(p.s[cpsStmts], 'memset((void*)$1, 0, sizeof($2));$n',
          [addrLoc(v.loc), rdLoc(v.loc)])
   end
end;

procedure genVarTuple(p: BProc; n: PNode);
var
  i, L: int;
  v: PSym;
  tup, field: TLoc;
  t: PType;
begin
  if n.kind <> nkVarTuple then InternalError(n.info, 'genVarTuple');
  L := sonsLen(n);
  genLineDir(p, n);
  initLocExpr(p, n.sons[L-1], tup);
  t := tup.t;
  for i := 0 to L-3 do begin
    v := n.sons[i].sym;
    if sfGlobal in v.flags then
      assignGlobalVar(p, v)
    else begin
      assignLocalVar(p, v);
      initVariable(p, v)
    end;
    // generate assignment:
    initLoc(field, locExpr, t.sons[i], tup.s);
    if t.n = nil then begin
      field.r := ropef('$1.Field$2', [rdLoc(tup), toRope(i)]);
    end
    else begin
      if (t.n.sons[i].kind <> nkSym) then
        InternalError(n.info, 'genVarTuple');
      field.r := ropef('$1.$2', [rdLoc(tup), 
        mangleRecFieldName(t.n.sons[i].sym, t)]);
    end;
    putLocIntoDest(p, v.loc, field);
    genObjectInit(p, v.typ, v.loc, true);
  end
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
    if a.kind = nkIdentDefs then begin
      assert(a.sons[0].kind = nkSym);
      v := a.sons[0].sym;
      if sfGlobal in v.flags then
        assignGlobalVar(p, v)
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
      genObjectInit(p, v.typ, v.loc, true); // correct position
    end
    else
      genVarTuple(p, a);
  end
end;

procedure genConstStmt(p: BProc; t: PNode);
var
  c: PSym;
  i: int;
begin
  for i := 0 to sonsLen(t)-1 do begin
    if t.sons[i].kind = nkCommentStmt then continue;
    if t.sons[i].kind <> nkConstDef then InternalError(t.info, 'genConstStmt');
    c := t.sons[i].sons[0].sym;
    // This can happen for forward consts:
    if (c.ast <> nil) and (c.typ.kind in ConstantDataTypes) and
           not (lfNoDecl in c.loc.flags) then begin
      // generate the data:
      fillLoc(c.loc, locData, c.typ, mangleName(c), OnUnknown);
      if sfImportc in c.flags then
        appf(p.module.s[cfsData], 'extern NIM_CONST $1 $2;$n',
          [getTypeDesc(p.module, c.typ), c.loc.r])
      else
        appf(p.module.s[cfsData], 'NIM_CONST $1 $2 = $3;$n',
          [getTypeDesc(p.module, c.typ), c.loc.r,
          genConstExpr(p, c.ast)])
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
        initLocExpr(p, it.sons[0], a);
        Lelse := getLabel(p);
        inc(p.labels);
        appff(p.s[cpsStmts], 'if (!$1) goto $2;$n', 
                             'br i1 $1, label %LOC$3, label %$2$n' +
                             'LOC$3: $n', 
                             [rdLoc(a), Lelse, toRope(p.labels)]);
        genStmts(p, it.sons[1]);
        if sonsLen(n) > 1 then
          appff(p.s[cpsStmts], 'goto $1;$n', 'br label %$1$n', [Lend]);
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
  inc(p.labels);
  Labl := con('LA', toRope(p.labels));
  len := length(p.blocks);
  setLength(p.blocks, len+1);
  p.blocks[len].id := -p.labels; // negative because it isn't used yet
  p.blocks[len].nestedTryStmts := p.nestedTryStmts;
  app(p.s[cpsStmts], 'while (1) {' + tnl);
  initLocExpr(p, t.sons[0], a);
  if (t.sons[0].kind <> nkIntLit) or (t.sons[0].intVal = 0) then begin
    p.blocks[len].id := abs(p.blocks[len].id);
    appf(p.s[cpsStmts], 'if (!$1) goto $2;$n', [rdLoc(a), Labl]);
  end;
  genStmts(p, t.sons[1]);
  if p.blocks[len].id > 0 then
    appf(p.s[cpsStmts], '} $1: ;$n', [Labl])
  else
    app(p.s[cpsStmts], '}'+tnl);
  setLength(p.blocks, length(p.blocks)-1)
end;

procedure genBlock(p: BProc; t: PNode; var d: TLoc);
var
  idx: int;
  sym: PSym;
begin
  inc(p.labels);
  idx := length(p.blocks);
  if t.sons[0] <> nil then begin // named block?
    assert(t.sons[0].kind = nkSym);
    sym := t.sons[0].sym;
    sym.loc.k := locOther;
    sym.loc.a := idx
  end;
  setLength(p.blocks, idx+1);
  p.blocks[idx].id := -p.labels; // negative because it isn't used yet
  p.blocks[idx].nestedTryStmts := p.nestedTryStmts;
  if t.kind = nkBlockExpr then genStmtListExpr(p, t.sons[1], d)
  else genStmts(p, t.sons[1]);
  if p.blocks[idx].id > 0 then // label has been used:
    appf(p.s[cpsStmts], 'LA$1: ;$n', [toRope(p.blocks[idx].id)]);
  setLength(p.blocks, idx)
end;

// try:
//   while:
//     try:
//       if ...:
//         break # we need to finish only one try statement here!
// finally:

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
  p.blocks[idx].id := abs(p.blocks[idx].id); // label is used
  finishTryStmt(p, p.nestedTryStmts - p.blocks[idx].nestedTryStmts);
  appf(p.s[cpsStmts], 'goto LA$1;$n', [toRope(p.blocks[idx].id)])
end;

procedure genAsmStmt(p: BProc; t: PNode);
var
  i: int;
  sym: PSym;
  r, s: PRope;
  a: TLoc;
begin
  genLineDir(p, t);
  assert(t.kind = nkAsmStmt);
  s := nil;
  for i := 0 to sonsLen(t) - 1 do begin
    case t.sons[i].Kind of
      nkStrLit..nkTripleStrLit: app(s, t.sons[i].strVal);
      nkSym: begin
        sym := t.sons[i].sym;
        if sym.kind in [skProc, skMethod] then begin
          initLocExpr(p, t.sons[i], a);
          app(s, rdLoc(a));
        end
        else begin
          r := sym.loc.r;
          if r = nil then begin // if no name has already been given,
                                // it doesn't matter much:
            r := mangleName(sym);
            sym.loc.r := r; // but be consequent!
          end;
          app(s, r)
        end
      end
      else
        InternalError(t.sons[i].info, 'genAsmStmt()')
    end
  end;
  appf(p.s[cpsStmts], CC[ccompiler].asmStmtFrmt, [s]);
end;

function getRaiseFrmt(p: BProc): string;
begin
  if gCmd = cmdCompileToCpp then
    result := 'throw nimException($1, $2);$n'
  else begin
    useMagic(p.module, 'E_Base');
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
    if gCmd <> cmdCompileToCpp then useMagic(p.module, 'raiseException');
    InitLocExpr(p, t.sons[0], a);
    e := rdLoc(a);
    typ := t.sons[0].typ;
    while typ.kind in [tyVar, tyRef, tyPtr] do typ := typ.sons[0];
    appf(p.s[cpsStmts], getRaiseFrmt(p),
      [e, makeCString(typ.sym.name.s)])
  end
  else begin
    // reraise the last exception:
    if gCmd = cmdCompileToCpp then
      app(p.s[cpsStmts], 'throw;' + tnl)
    else begin
      useMagic(p.module, 'reraiseException');
      app(p.s[cpsStmts], 'reraiseException();' + tnl)
    end
  end
end;

// ---------------- case statement generation -----------------------------

const
  stringCaseThreshold = 100000; 
  // above X strings a hash-switch for strings is generated
  // this version sets it too high to avoid hashing, because this has not
  // been tested for a long time
  // XXX test and enable this optimization!

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
      initLocExpr(p, b.sons[i].sons[0], x);
      initLocExpr(p, b.sons[i].sons[1], y);
      appf(p.s[cpsStmts], rangeFormat,
        [rdCharLoc(e), rdCharLoc(x), rdCharLoc(y), labl])
    end
    else begin
      initLocExpr(p, b.sons[i], x);
      appf(p.s[cpsStmts], eqFormat,
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
    appf(p.s[cpsStmts], 'LA$1: ;$n', [toRope(labId+i)]);
    if t.sons[i].kind = nkOfBranch then begin
      len := sonsLen(t.sons[i]);
      genStmts(p, t.sons[i].sons[len-1]);
      appf(p.s[cpsStmts], 'goto $1;$n', [Lend])
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
  initLocExpr(p, t.sons[0], a);
  // fist pass: gnerate ifs+goto:
  labId := p.labels;
  for i := 1 to sonsLen(t) - 1 do begin
    inc(p.labels);
    if t.sons[i].kind = nkOfBranch then
      genCaseGenericBranch(p, t.sons[i], a, rangeFormat, eqFormat,
        con('LA', toRope(p.labels)))
    else
      // else statement
      appf(p.s[cpsStmts], 'goto LA$1;$n', [toRope(p.labels)]);
  end;
  // second pass: generate statements
  genCaseSecondPass(p, t, labId);
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
      b := b +{%} shlu(b, 10);
      b := b xor shru(b, 6)
    end;
    b := b +{%} shlu(b, 3);
    b := b xor shru(b, 11);
    b := b +{%} shlu(b, 15);
    result := b
  end
  else begin
    a := 0;
    for i := 0 to Length(s)-1 do begin
      a := a +{%} int32(Ord(s[i]));
      a := a +{%} shlu(a, int32(10));
      a := a xor shru(a, int32(6));
    end;
    a := a +{%} shlu(a, int32(3));
    a := a xor shru(a, int32(11));
    a := a +{%} shlu(a, int32(15));
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
    initLocExpr(p, b.sons[i], x);
    assert(b.sons[i].kind in [nkStrLit..nkTripleStrLit]);
    j := int(hashString(b.sons[i].strVal) and high(branches));
    appf(branches[j], 'if (eqStrings($1, $2)) goto $3;$n',
      [rdLoc(e), rdLoc(x), labl])
  end
end;

procedure genStringCase(p: BProc; t: PNode);
var
  strings, i, j, bitMask, labId: int;
  a: TLoc;
  branches: TRopeSeq;
begin
  useMagic(p.module, 'eqStrings');
  // count how many constant strings there are in the case:
  strings := 0;
  for i := 1 to sonsLen(t)-1 do
    if t.sons[i].kind = nkOfBranch then inc(strings, sonsLen(t.sons[i])-1);
  if strings > stringCaseThreshold then begin
    useMagic(p.module, 'hashString');
    bitMask := nmath.nextPowerOfTwo(strings)-1;
  {@ignore}
    setLength(branches, bitMask+1);
  {@emit newSeq(branches, bitMask+1);}
    initLocExpr(p, t.sons[0], a);
    // fist pass: gnerate ifs+goto:
    labId := p.labels;
    for i := 1 to sonsLen(t) - 1 do begin
      inc(p.labels);
      if t.sons[i].kind = nkOfBranch then
        genCaseStringBranch(p, t.sons[i], a, con('LA', toRope(p.labels)),
                            branches)
      else begin
        // else statement: nothing to do yet
        // but we reserved a label, which we use later
      end
    end;
    // second pass: generate switch statement based on hash of string:
    appf(p.s[cpsStmts], 'switch (hashString($1) & $2) {$n',
      [rdLoc(a), toRope(bitMask)]);
    for j := 0 to high(branches) do
      if branches[j] <> nil then
        appf(p.s[cpsStmts], 'case $1: $n$2break;$n',
          [intLiteral(j), branches[j]]);
    app(p.s[cpsStmts], '}' + tnl);
    // else statement:
    if t.sons[sonsLen(t)-1].kind <> nkOfBranch then
      appf(p.s[cpsStmts], 'goto LA$1;$n', [toRope(p.labels)]);
    // third pass: generate statements
    genCaseSecondPass(p, t, labId);
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
  canGenerateSwitch, hasDefault: bool;
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
    initLocExpr(p, t.sons[0], a);
    appf(p.s[cpsStmts], 'switch ($1) {$n', [rdCharLoc(a)]);
    hasDefault := false;
    for i := 1 to sonsLen(t)-1 do begin
      if t.sons[i].kind = nkOfBranch then begin
        len := sonsLen(t.sons[i]);
        for j := 0 to len-2 do begin
          if t.sons[i].sons[j].kind = nkRange then begin // a range
            if hasSwitchRange in CC[ccompiler].props then
              appf(p.s[cpsStmts], 'case $1 ... $2:$n',
                [genLiteral(p, t.sons[i].sons[j].sons[0]),
                 genLiteral(p, t.sons[i].sons[j].sons[1])])
            else begin
              v := copyNode(t.sons[i].sons[j].sons[0]);
              while (v.intVal <= t.sons[i].sons[j].sons[1].intVal) do begin
                appf(p.s[cpsStmts], 'case $1:$n', [genLiteral(p, v)]);
                Inc(v.intVal)
              end
            end;
          end
          else
            appf(p.s[cpsStmts], 'case $1:$n',
              [genLiteral(p, t.sons[i].sons[j])]);
        end;
        genStmts(p, t.sons[i].sons[len-1])
      end
      else begin // else part of case statement:
        app(p.s[cpsStmts], 'default:' + tnl);
        genStmts(p, t.sons[i].sons[0]);
        hasDefault := true;
      end;
      app(p.s[cpsStmts], 'break;' + tnl);
    end;
    if (hasAssume in CC[ccompiler].props) and not hasDefault then 
      app(p.s[cpsStmts], 'default: __assume(0);' + tnl);      
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
  case skipTypes(t.sons[0].typ, abstractVarRange).kind of
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
    appf(p.s[cpsLocals], 'volatile NIM_BOOL $1 = NIM_FALSE;$n',
      [rethrowFlag])
  end;
  if optStackTrace in p.Options then
    app(p.s[cpsStmts], 'framePtr = (TFrame*)&F;' + tnl);
  app(p.s[cpsStmts], 'try {' + tnl);
  inc(p.nestedTryStmts);
  genStmts(p, t.sons[0]);
  len := sonsLen(t);
  if t.sons[1].kind = nkExceptBranch then begin
    appf(p.s[cpsStmts], '} catch (NimException& $1) {$n', [exc]);
    if rethrowFlag <> nil then
      appf(p.s[cpsStmts], '$1 = NIM_TRUE;$n', [rethrowFlag]);
    appf(p.s[cpsStmts], 'if ($1.sp.exc) {$n', [exc])
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
        appf(p.s[cpsStmts], 'case $1:$n',
          [toRope(t.sons[i].sons[j].typ.id)])
      end;
      genStmts(p, t.sons[i].sons[blen - 1])
    end;
    // code to clear the exception:
    if rethrowFlag <> nil then
      appf(p.s[cpsStmts], '$1 = NIM_FALSE;  ', [rethrowFlag]);
    app(p.s[cpsStmts], 'break;' + tnl);
    inc(i);
  end;
  if t.sons[1].kind = nkExceptBranch then // BUGFIX
    app(p.s[cpsStmts], '}}' + tnl); // end of catch-switch statement
  dec(p.nestedTryStmts);
  app(p.s[cpsStmts], 'excHandler = excHandler->prev;' + tnl);
  if (i < len) and (t.sons[i].kind = nkFinally) then begin
    genStmts(p, t.sons[i].sons[0]);
    if rethrowFlag <> nil then
      appf(p.s[cpsStmts], 'if ($1) { throw; }$n', [rethrowFlag])
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
  useMagic(p.module, 'TSafePoint');
  useMagic(p.module, 'E_Base');
  useMagic(p.module, 'excHandler');
  appf(p.s[cpsLocals], 'TSafePoint $1;$n', [safePoint]);
  appf(p.s[cpsStmts], '$1.prev = excHandler;$n' +
                      'excHandler = &$1;$n' +
                      '$1.status = setjmp($1.context);$n',
                      [safePoint]);
  if optStackTrace in p.Options then
    app(p.s[cpsStmts], 'framePtr = (TFrame*)&F;' + tnl);
  appf(p.s[cpsStmts], 'if ($1.status == 0) {$n', [safePoint]);
  len := sonsLen(t);
  inc(p.nestedTryStmts);
  genStmts(p, t.sons[0]);
  app(p.s[cpsStmts], '} else {' + tnl);
  i := 1;
  while (i < len) and (t.sons[i].kind = nkExceptBranch) do begin
    blen := sonsLen(t.sons[i]);
    if blen = 1 then begin
      // general except section:
      if i > 1 then app(p.s[cpsStmts], 'else {' + tnl);
      genStmts(p, t.sons[i].sons[0]);
      appf(p.s[cpsStmts], '$1.status = 0;$n', [safePoint]);
      if i > 1 then app(p.s[cpsStmts], '}' + tnl);
    end
    else begin
      orExpr := nil;
      for j := 0 to blen - 2 do begin
        assert(t.sons[i].sons[j].kind = nkType);
        if orExpr <> nil then app(orExpr, '||');
        appf(orExpr, '($1.exc->Sup.m_type == $2)',
          [safePoint, genTypeInfo(p.module, t.sons[i].sons[j].typ)])
      end;
      if i > 1 then app(p.s[cpsStmts], 'else ');
      appf(p.s[cpsStmts], 'if ($1) {$n', [orExpr]);
      genStmts(p, t.sons[i].sons[blen - 1]);
      // code to clear the exception:
      appf(p.s[cpsStmts], '$1.status = 0;}$n', [safePoint]);
    end;
    inc(i)
  end;
  app(p.s[cpsStmts], '}' + tnl); // end of if statement
  finishTryStmt(p, p.nestedTryStmts);
  dec(p.nestedTryStmts);
  if (i < len) and (t.sons[i].kind = nkFinally) then begin
    genStmts(p, t.sons[i].sons[0]);
    useMagic(p.module, 'raiseException');
    appf(p.s[cpsStmts], 'if ($1.status != 0) { ' +
      'raiseException($1.exc, $1.exc->name); }$n', [safePoint])
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
    appf(gBreakpoints,
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
    if key.kind = nkIdent then
      case whichKeyword(key.ident) of
        wBreakpoint: genBreakPoint(p, it);
        wDeadCodeElim: begin
          if not (optDeadCodeElim in gGlobalOptions) then begin
            // we need to keep track of ``deadCodeElim`` pragma
            if (sfDeadCodeElim in p.module.module.flags) then
              addPendingModule(p.module)
          end            
        end
        else begin end
      end
  end
end;

procedure genAsgn(p: BProc; e: PNode);
var
  a: TLoc;
begin
  genLineDir(p, e); // BUGFIX
  InitLocExpr(p, e.sons[0], a);
  assert(a.t <> nil);
  expr(p, e.sons[1], a);
end;

procedure genFastAsgn(p: BProc; e: PNode);
var
  a: TLoc;
begin
  genLineDir(p, e); // BUGFIX
  InitLocExpr(p, e.sons[0], a);
  include(a.flags, lfNoDeepCopy);
  assert(a.t <> nil);
  expr(p, e.sons[1], a);
end;

procedure genStmts(p: BProc; t: PNode);
var
  a: TLoc;
  i: int;
  prc: PSym;
begin
  //assert(t <> nil);
  if inCheckpoint(t.info) then
    MessageOut(renderTree(t));
  case t.kind of
    nkEmpty: begin end; // nothing to do!
    nkStmtList: begin
      for i := 0 to sonsLen(t)-1 do genStmts(p, t.sons[i]);
    end;
    nkBlockStmt:   genBlock(p, t, a);
    nkIfStmt:      genIfStmt(p, t);
    nkWhileStmt:   genWhileStmt(p, t);
    nkVarSection:  genVarStmt(p, t);
    nkConstSection: genConstStmt(p, t);
    nkForStmt:     internalError(t.info, 'for statement not eliminated');
    nkCaseStmt:    genCaseStmt(p, t);
    nkReturnStmt:  genReturnStmt(p, t);
    nkBreakStmt:   genBreakStmt(p, t);
    nkCall, nkHiddenCallConv, nkInfix, nkPrefix, nkPostfix, nkCommand,
    nkCallStrLit: begin
      genLineDir(p, t);
      initLocExpr(p, t, a);
    end;
    nkAsgn: genAsgn(p, t);
    nkFastAsgn: genFastAsgn(p, t);
    nkDiscardStmt: begin
      genLineDir(p, t);
      initLocExpr(p, t.sons[0], a);
    end;
    nkAsmStmt: genAsmStmt(p, t);
    nkTryStmt: begin
      if gCmd = cmdCompileToCpp then genTryStmtCpp(p, t)
      else genTryStmt(p, t);
    end;
    nkRaiseStmt: genRaiseStmt(p, t);
    nkTypeSection: begin
      // we have to emit the type information for object types here to support
      // separate compilation:
      genTypeSection(p.module, t);
    end;
    nkCommentStmt, nkNilLit, nkIteratorDef, nkIncludeStmt, nkImportStmt,
    nkFromStmt, nkTemplateDef, nkMacroDef: begin end;
    nkPragma: genPragma(p, t);
    nkProcDef, nkMethodDef, nkConverterDef: begin
      if (t.sons[genericParamsPos] = nil) then begin
        prc := t.sons[namePos].sym;
        if not (optDeadCodeElim in gGlobalOptions) and
            not (sfDeadCodeElim in getModule(prc).flags)
        or ([sfExportc, sfCompilerProc] * prc.flags = [sfExportc])
        or (prc.kind = skMethod) then begin
          if (t.sons[codePos] <> nil) or (lfDynamicLib in prc.loc.flags) then begin
            genProc(p.module, prc)
          end
        end
      end
    end;
    else
      internalError(t.info, 'genStmts(' +{&} nodeKindToStr[t.kind] +{&} ')')
  end
end;
