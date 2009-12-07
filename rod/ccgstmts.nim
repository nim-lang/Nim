#
#
#           The Nimrod Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

const 
  RangeExpandLimit = 256      # do not generate ranges
                              # over 'RangeExpandLimit' elements

proc genLineDir(p: BProc, t: PNode) = 
  var line = toLinenumber(t.info) # BUGFIX
  if line < 0: 
    line = 0                  # negative numbers are not allowed in #line
  if optLineDir in p.Options: 
    appff(p.s[cpsStmts], "#line $2 \"$1\"$n", "; line $2 \"$1\"$n", 
          [toRope(toFilename(t.info)), toRope(line)])
  if ({optStackTrace, optEndb} * p.Options == {optStackTrace, optEndb}) and
      ((p.prc == nil) or not (sfPure in p.prc.flags)): 
    useMagic(p.module, "endb") # new: endb support
    appff(p.s[cpsStmts], "endb($1);$n", "call void @endb(%NI $1)$n", 
          [toRope(line)])
  elif ({optLineTrace, optStackTrace} * p.Options ==
      {optLineTrace, optStackTrace}) and
      ((p.prc == nil) or not (sfPure in p.prc.flags)): 
    inc(p.labels)
    appff(p.s[cpsStmts], "F.line = $1;$n", 
        "%LOC$2 = getelementptr %TF %F, %NI 2$n" &
        "store %NI $1, %NI* %LOC$2$n", [toRope(line), toRope(p.labels)])

proc finishTryStmt(p: BProc, howMany: int) = 
  for i in countup(1, howMany): 
    inc(p.labels, 3)
    appff(p.s[cpsStmts], "excHandler = excHandler->prev;$n", 
        "%LOC$1 = load %TSafePoint** @excHandler$n" &
        "%LOC$2 = getelementptr %TSafePoint* %LOC$1, %NI 0$n" &
        "%LOC$3 = load %TSafePoint** %LOC$2$n" &
        "store %TSafePoint* %LOC$3, %TSafePoint** @excHandler$n", 
          [toRope(p.labels), toRope(p.labels - 1), toRope(p.labels - 2)])

proc genReturnStmt(p: BProc, t: PNode) = 
  p.beforeRetNeeded = true
  genLineDir(p, t)
  if (t.sons[0] != nil): genStmts(p, t.sons[0])
  finishTryStmt(p, p.nestedTryStmts)
  appff(p.s[cpsStmts], "goto BeforeRet;$n", "br label %BeforeRet$n", [])

proc initVariable(p: BProc, v: PSym) = 
  if containsGarbageCollectedRef(v.typ) or (v.ast == nil): 
    if not (skipTypes(v.typ, abstractVarRange).Kind in
        {tyArray, tyArrayConstr, tySet, tyTuple, tyObject}): 
      if gCmd == cmdCompileToLLVM: 
        appf(p.s[cpsStmts], "store $2 0, $2* $1$n", 
             [addrLoc(v.loc), getTypeDesc(p.module, v.loc.t)])
      else: 
        appf(p.s[cpsStmts], "$1 = 0;$n", [rdLoc(v.loc)])
    else: 
      if gCmd == cmdCompileToLLVM: 
        app(p.module.s[cfsProcHeaders], 
            "declare void @llvm.memset.i32(i8*, i8, i32, i32)" & tnl)
        inc(p.labels, 2)
        appf(p.s[cpsStmts], "%LOC$3 = getelementptr $2* null, %NI 1$n" &
            "%LOC$4 = cast $2* %LOC$3 to i32$n" &
            "call void @llvm.memset.i32(i8* $1, i8 0, i32 %LOC$4, i32 0)$n", [
            addrLoc(v.loc), getTypeDesc(p.module, v.loc.t), toRope(p.labels), 
            toRope(p.labels - 1)])
      else: 
        appf(p.s[cpsStmts], "memset((void*)$1, 0, sizeof($2));$n", 
             [addrLoc(v.loc), rdLoc(v.loc)])
  
proc genVarTuple(p: BProc, n: PNode) = 
  var 
    L: int
    v: PSym
    tup, field: TLoc
    t: PType
  if n.kind != nkVarTuple: InternalError(n.info, "genVarTuple")
  L = sonsLen(n)
  genLineDir(p, n)
  initLocExpr(p, n.sons[L - 1], tup)
  t = tup.t
  for i in countup(0, L - 3): 
    v = n.sons[i].sym
    if sfGlobal in v.flags: 
      assignGlobalVar(p, v)
    else: 
      assignLocalVar(p, v)
      initVariable(p, v)
    initLoc(field, locExpr, t.sons[i], tup.s)
    if t.n == nil: 
      field.r = ropef("$1.Field$2", [rdLoc(tup), toRope(i)])
    else: 
      if (t.n.sons[i].kind != nkSym): InternalError(n.info, "genVarTuple")
      field.r = ropef("$1.$2", 
                      [rdLoc(tup), mangleRecFieldName(t.n.sons[i].sym, t)])
    putLocIntoDest(p, v.loc, field)
    genObjectInit(p, v.typ, v.loc, true)

proc genVarStmt(p: BProc, n: PNode) = 
  var 
    v: PSym
    a: PNode
  for i in countup(0, sonsLen(n) - 1): 
    a = n.sons[i]
    if a.kind == nkCommentStmt: continue 
    if a.kind == nkIdentDefs: 
      assert(a.sons[0].kind == nkSym)
      v = a.sons[0].sym
      if sfGlobal in v.flags: 
        assignGlobalVar(p, v)
      else: 
        assignLocalVar(p, v)
        initVariable(p, v)    # XXX: this is not required if a.sons[2] != nil,
                              # unless it is a GC'ed pointer
      if a.sons[2] != nil: 
        genLineDir(p, a)
        expr(p, a.sons[2], v.loc)
      genObjectInit(p, v.typ, v.loc, true) # correct position
    else: 
      genVarTuple(p, a)
  
proc genConstStmt(p: BProc, t: PNode) = 
  var c: PSym
  for i in countup(0, sonsLen(t) - 1): 
    if t.sons[i].kind == nkCommentStmt: continue 
    if t.sons[i].kind != nkConstDef: InternalError(t.info, "genConstStmt")
    c = t.sons[i].sons[0].sym # This can happen for forward consts:
    if (c.ast != nil) and (c.typ.kind in ConstantDataTypes) and
        not (lfNoDecl in c.loc.flags): 
      # generate the data:
      fillLoc(c.loc, locData, c.typ, mangleName(c), OnUnknown)
      if sfImportc in c.flags: 
        appf(p.module.s[cfsData], "extern NIM_CONST $1 $2;$n", 
             [getTypeDesc(p.module, c.typ), c.loc.r])
      else: 
        appf(p.module.s[cfsData], "NIM_CONST $1 $2 = $3;$n", 
             [getTypeDesc(p.module, c.typ), c.loc.r, genConstExpr(p, c.ast)])
  
proc genIfStmt(p: BProc, n: PNode) = 
  #
  #  if (!expr1) goto L1;
  #  thenPart
  #  goto LEnd
  #  L1:
  #  if (!expr2) goto L2;
  #  thenPart2
  #  goto LEnd
  #  L2:
  #  elsePart
  #  Lend:
  #
  var 
    a: TLoc
    Lelse: TLabel
  genLineDir(p, n)
  var Lend = getLabel(p)
  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    case it.kind
    of nkElifBranch: 
      initLocExpr(p, it.sons[0], a)
      Lelse = getLabel(p)
      inc(p.labels)
      appff(p.s[cpsStmts], "if (!$1) goto $2;$n", 
            "br i1 $1, label %LOC$3, label %$2$n" & "LOC$3: $n", 
            [rdLoc(a), Lelse, toRope(p.labels)])
      genStmts(p, it.sons[1])
      if sonsLen(n) > 1: 
        appff(p.s[cpsStmts], "goto $1;$n", "br label %$1$n", [Lend])
      fixLabel(p, Lelse)
    of nkElse: 
      genStmts(p, it.sons[0])
    else: internalError(n.info, "genIfStmt()")
  if sonsLen(n) > 1: fixLabel(p, Lend)
  
proc genWhileStmt(p: BProc, t: PNode) = 
  # we don't generate labels here as for example GCC would produce
  # significantly worse code
  var 
    a: TLoc
    Labl: TLabel
    length: int
  genLineDir(p, t)
  assert(sonsLen(t) == 2)
  inc(p.labels)
  Labl = con("LA", toRope(p.labels))
  length = len(p.blocks)
  setlen(p.blocks, length + 1)
  p.blocks[length].id = - p.labels # negative because it isn't used yet
  p.blocks[length].nestedTryStmts = p.nestedTryStmts
  app(p.s[cpsStmts], "while (1) {" & tnl)
  initLocExpr(p, t.sons[0], a)
  if (t.sons[0].kind != nkIntLit) or (t.sons[0].intVal == 0): 
    p.blocks[length].id = abs(p.blocks[length].id)
    appf(p.s[cpsStmts], "if (!$1) goto $2;$n", [rdLoc(a), Labl])
  genStmts(p, t.sons[1])
  if p.blocks[length].id > 0: appf(p.s[cpsStmts], "} $1: ;$n", [Labl])
  else: app(p.s[cpsStmts], '}' & tnl)
  setlen(p.blocks, len(p.blocks) - 1)

proc genBlock(p: BProc, t: PNode, d: var TLoc) = 
  inc(p.labels)
  var idx = len(p.blocks)
  if t.sons[0] != nil: 
    # named block?
    assert(t.sons[0].kind == nkSym)
    var sym = t.sons[0].sym
    sym.loc.k = locOther
    sym.loc.a = idx
  setlen(p.blocks, idx + 1)
  p.blocks[idx].id = - p.labels # negative because it isn't used yet
  p.blocks[idx].nestedTryStmts = p.nestedTryStmts
  if t.kind == nkBlockExpr: genStmtListExpr(p, t.sons[1], d)
  else: genStmts(p, t.sons[1])
  if p.blocks[idx].id > 0: 
    appf(p.s[cpsStmts], "LA$1: ;$n", [toRope(p.blocks[idx].id)])
  setlen(p.blocks, idx)

proc genBreakStmt(p: BProc, t: PNode) = 
  genLineDir(p, t)
  var idx = len(p.blocks) - 1
  if t.sons[0] != nil: 
    # named break?
    assert(t.sons[0].kind == nkSym)
    var sym = t.sons[0].sym
    assert(sym.loc.k == locOther)
    idx = sym.loc.a
  p.blocks[idx].id = abs(p.blocks[idx].id) # label is used
  finishTryStmt(p, p.nestedTryStmts - p.blocks[idx].nestedTryStmts)
  appf(p.s[cpsStmts], "goto LA$1;$n", [toRope(p.blocks[idx].id)])

proc genAsmStmt(p: BProc, t: PNode) = 
  var 
    sym: PSym
    r, s: PRope
    a: TLoc
  genLineDir(p, t)
  assert(t.kind == nkAsmStmt)
  s = nil
  for i in countup(0, sonsLen(t) - 1): 
    case t.sons[i].Kind
    of nkStrLit..nkTripleStrLit: 
      app(s, t.sons[i].strVal)
    of nkSym: 
      sym = t.sons[i].sym
      if sym.kind in {skProc, skMethod}: 
        initLocExpr(p, t.sons[i], a)
        app(s, rdLoc(a))
      else: 
        r = sym.loc.r
        if r == nil: 
          # if no name has already been given,
          # it doesn't matter much:
          r = mangleName(sym)
          sym.loc.r = r       # but be consequent!
        app(s, r)
    else: InternalError(t.sons[i].info, "genAsmStmt()")
  appf(p.s[cpsStmts], CC[ccompiler].asmStmtFrmt, [s])

proc getRaiseFrmt(p: BProc): string = 
  if gCmd == cmdCompileToCpp: 
    result = "throw nimException($1, $2);$n"
  else: 
    useMagic(p.module, "E_Base")
    result = "raiseException((E_Base*)$1, $2);$n"

proc genRaiseStmt(p: BProc, t: PNode) = 
  var 
    e: PRope
    a: TLoc
    typ: PType
  genLineDir(p, t)
  if t.sons[0] != nil: 
    if gCmd != cmdCompileToCpp: useMagic(p.module, "raiseException")
    InitLocExpr(p, t.sons[0], a)
    e = rdLoc(a)
    typ = t.sons[0].typ
    while typ.kind in {tyVar, tyRef, tyPtr}: typ = typ.sons[0]
    appf(p.s[cpsStmts], getRaiseFrmt(p), [e, makeCString(typ.sym.name.s)])
  else: 
    # reraise the last exception:
    if gCmd == cmdCompileToCpp: 
      app(p.s[cpsStmts], "throw;" & tnl)
    else: 
      useMagic(p.module, "reraiseException")
      app(p.s[cpsStmts], "reraiseException();" & tnl)

const 
  stringCaseThreshold = 100000 
    # above X strings a hash-switch for strings is generated
    # this version sets it too high to avoid hashing, because this has not
    # been tested for a long time
    # XXX test and enable this optimization!

proc genCaseGenericBranch(p: BProc, b: PNode, e: TLoc, 
                          rangeFormat, eqFormat: TFormatStr, labl: TLabel) = 
  var 
    x, y: TLoc
  var length = sonsLen(b)
  for i in countup(0, length - 2): 
    if b.sons[i].kind == nkRange: 
      initLocExpr(p, b.sons[i].sons[0], x)
      initLocExpr(p, b.sons[i].sons[1], y)
      appf(p.s[cpsStmts], rangeFormat, 
           [rdCharLoc(e), rdCharLoc(x), rdCharLoc(y), labl])
    else: 
      initLocExpr(p, b.sons[i], x)
      appf(p.s[cpsStmts], eqFormat, [rdCharLoc(e), rdCharLoc(x), labl])

proc genCaseSecondPass(p: BProc, t: PNode, labId: int) = 
  var Lend = getLabel(p)
  for i in countup(1, sonsLen(t) - 1): 
    appf(p.s[cpsStmts], "LA$1: ;$n", [toRope(labId + i)])
    if t.sons[i].kind == nkOfBranch: # else statement
      var length = sonsLen(t.sons[i])
      genStmts(p, t.sons[i].sons[length - 1])
      appf(p.s[cpsStmts], "goto $1;$n", [Lend])
    else: 
      genStmts(p, t.sons[i].sons[0])
  fixLabel(p, Lend)

proc genCaseGeneric(p: BProc, t: PNode, rangeFormat, eqFormat: TFormatStr) = 
  # generate a C-if statement for a Nimrod case statement
  var a: TLoc
  initLocExpr(p, t.sons[0], a) # fist pass: gnerate ifs+goto:
  var labId = p.labels
  for i in countup(1, sonsLen(t) - 1): 
    inc(p.labels)
    if t.sons[i].kind == nkOfBranch: # else statement
      genCaseGenericBranch(p, t.sons[i], a, rangeFormat, eqFormat, 
                           con("LA", toRope(p.labels)))
    else: 
      appf(p.s[cpsStmts], "goto LA$1;$n", [toRope(p.labels)])
  genCaseSecondPass(p, t, labId)

proc hashString(s: string): biggestInt = 
  var 
    a: int32
    b: int64
  if CPU[targetCPU].bit == 64: 
    # we have to use the same bitwidth
    # as the target CPU
    b = 0
    for i in countup(0, len(s) - 1): 
      b = b +% Ord(s[i])
      b = b +% `shl`(b, 10)
      b = b xor `shr`(b, 6)
    b = b +% `shl`(b, 3)
    b = b xor `shr`(b, 11)
    b = b +% `shl`(b, 15)
    result = b
  else: 
    a = 0
    for i in countup(0, len(s) - 1): 
      a = a +% int32(Ord(s[i]))
      a = a +% `shl`(a, int32(10))
      a = a xor `shr`(a, int32(6))
    a = a +% `shl`(a, int32(3))
    a = a xor `shr`(a, int32(11))
    a = a +% `shl`(a, int32(15))
    result = a

type 
  TRopeSeq = seq[PRope]

proc genCaseStringBranch(p: BProc, b: PNode, e: TLoc, labl: TLabel, 
                         branches: var TRopeSeq) = 
  var 
    length, j: int
    x: TLoc
  length = sonsLen(b)
  for i in countup(0, length - 2): 
    assert(b.sons[i].kind != nkRange)
    initLocExpr(p, b.sons[i], x)
    assert(b.sons[i].kind in {nkStrLit..nkTripleStrLit})
    j = int(hashString(b.sons[i].strVal) and high(branches))
    appf(branches[j], "if (eqStrings($1, $2)) goto $3;$n", 
         [rdLoc(e), rdLoc(x), labl])

proc genStringCase(p: BProc, t: PNode) = 
  var 
    strings, bitMask, labId: int
    a: TLoc
    branches: TRopeSeq
  useMagic(p.module, "eqStrings") # count how many constant strings there are in the case:
  strings = 0
  for i in countup(1, sonsLen(t) - 1): 
    if t.sons[i].kind == nkOfBranch: inc(strings, sonsLen(t.sons[i]) - 1)
  if strings > stringCaseThreshold: 
    useMagic(p.module, "hashString")
    bitMask = math.nextPowerOfTwo(strings) - 1
    newSeq(branches, bitMask + 1)
    initLocExpr(p, t.sons[0], a) # fist pass: gnerate ifs+goto:
    labId = p.labels
    for i in countup(1, sonsLen(t) - 1): 
      inc(p.labels)
      if t.sons[i].kind == nkOfBranch: 
        genCaseStringBranch(p, t.sons[i], a, con("LA", toRope(p.labels)), 
                            branches)
      else: 
        # else statement: nothing to do yet
        # but we reserved a label, which we use later
    appf(p.s[cpsStmts], "switch (hashString($1) & $2) {$n", 
         [rdLoc(a), toRope(bitMask)])
    for j in countup(0, high(branches)): 
      if branches[j] != nil: 
        appf(p.s[cpsStmts], "case $1: $n$2break;$n", 
             [intLiteral(j), branches[j]])
    app(p.s[cpsStmts], '}' & tnl) # else statement:
    if t.sons[sonsLen(t) - 1].kind != nkOfBranch: 
      appf(p.s[cpsStmts], "goto LA$1;$n", [toRope(p.labels)]) # third pass: generate statements
    genCaseSecondPass(p, t, labId)
  else: 
    genCaseGeneric(p, t, "", "if (eqStrings($1, $2)) goto $3;$n")
  
proc branchHasTooBigRange(b: PNode): bool = 
  for i in countup(0, sonsLen(b) - 2): 
    # last son is block
    if (b.sons[i].Kind == nkRange) and
        (b.sons[i].sons[1].intVal - b.sons[i].sons[0].intVal > RangeExpandLimit): 
      return true
  result = false

proc genOrdinalCase(p: BProc, t: PNode) = 
  # We analyse if we have a too big switch range. If this is the case,
  # we generate an ordinary if statement and rely on the C compiler
  # to produce good code.
  var 
    canGenerateSwitch, hasDefault: bool
    length: int
    a: TLoc
    v: PNode
  canGenerateSwitch = true
  if not (hasSwitchRange in CC[ccompiler].props): 
    for i in countup(1, sonsLen(t) - 1): 
      if (t.sons[i].kind == nkOfBranch) and branchHasTooBigRange(t.sons[i]): 
        canGenerateSwitch = false
        break 
  if canGenerateSwitch: 
    initLocExpr(p, t.sons[0], a)
    appf(p.s[cpsStmts], "switch ($1) {$n", [rdCharLoc(a)])
    hasDefault = false
    for i in countup(1, sonsLen(t) - 1): 
      if t.sons[i].kind == nkOfBranch: 
        length = sonsLen(t.sons[i])
        for j in countup(0, length - 2): 
          if t.sons[i].sons[j].kind == nkRange: 
            # a range
            if hasSwitchRange in CC[ccompiler].props: 
              appf(p.s[cpsStmts], "case $1 ... $2:$n", [
                  genLiteral(p, t.sons[i].sons[j].sons[0]), 
                  genLiteral(p, t.sons[i].sons[j].sons[1])])
            else: 
              v = copyNode(t.sons[i].sons[j].sons[0])
              while (v.intVal <= t.sons[i].sons[j].sons[1].intVal): 
                appf(p.s[cpsStmts], "case $1:$n", [genLiteral(p, v)])
                Inc(v.intVal)
          else: 
            appf(p.s[cpsStmts], "case $1:$n", [genLiteral(p, t.sons[i].sons[j])])
        genStmts(p, t.sons[i].sons[length - 1])
      else: 
        # else part of case statement:
        app(p.s[cpsStmts], "default:" & tnl)
        genStmts(p, t.sons[i].sons[0])
        hasDefault = true
      app(p.s[cpsStmts], "break;" & tnl)
    if (hasAssume in CC[ccompiler].props) and not hasDefault: 
      app(p.s[cpsStmts], "default: __assume(0);" & tnl)
    app(p.s[cpsStmts], '}' & tnl)
  else: 
    genCaseGeneric(p, t, "if ($1 >= $2 && $1 <= $3) goto $4;$n", 
                   "if ($1 == $2) goto $3;$n")
  
proc genCaseStmt(p: BProc, t: PNode) = 
  genLineDir(p, t)
  case skipTypes(t.sons[0].typ, abstractVarRange).kind
  of tyString: 
    genStringCase(p, t)
  of tyFloat..tyFloat128: 
    genCaseGeneric(p, t, "if ($1 >= $2 && $1 <= $3) goto $4;$n", 
                   "if ($1 == $2) goto $3;$n") # ordinal type: generate a switch statement
  else: genOrdinalCase(p, t)
  
proc hasGeneralExceptSection(t: PNode): bool = 
  var length, i, blen: int
  length = sonsLen(t)
  i = 1
  while (i < length) and (t.sons[i].kind == nkExceptBranch): 
    blen = sonsLen(t.sons[i])
    if blen == 1: 
      return true
    inc(i)
  result = false

proc genTryStmtCpp(p: BProc, t: PNode) = 
  # code to generate:
  #
  #   bool tmpRethrow = false;
  #   try
  #   {
  #      myDiv(4, 9);
  #   } catch (NimException& tmp) {
  #      tmpRethrow = true;
  #      switch (tmp.exc)
  #      {
  #         case DIVIDE_BY_ZERO:
  #           tmpRethrow = false;
  #           printf('Division by Zero\n');
  #         break;
  #      default: // used for general except!
  #         generalExceptPart();
  #         tmpRethrow = false;
  #      }
  #  }
  #  excHandler = excHandler->prev; // we handled the exception
  #  finallyPart();
  #  if (tmpRethrow) throw; 
  var 
    rethrowFlag: PRope
    exc: PRope
    i, length, blen: int
  genLineDir(p, t)
  rethrowFlag = nil
  exc = getTempName()
  if not hasGeneralExceptSection(t): 
    rethrowFlag = getTempName()
    appf(p.s[cpsLocals], "volatile NIM_BOOL $1 = NIM_FALSE;$n", [rethrowFlag])
  if optStackTrace in p.Options: 
    app(p.s[cpsStmts], "framePtr = (TFrame*)&F;" & tnl)
  app(p.s[cpsStmts], "try {" & tnl)
  inc(p.nestedTryStmts)
  genStmts(p, t.sons[0])
  length = sonsLen(t)
  if t.sons[1].kind == nkExceptBranch: 
    appf(p.s[cpsStmts], "} catch (NimException& $1) {$n", [exc])
    if rethrowFlag != nil: 
      appf(p.s[cpsStmts], "$1 = NIM_TRUE;$n", [rethrowFlag])
    appf(p.s[cpsStmts], "if ($1.sp.exc) {$n", [exc])
  i = 1
  while (i < length) and (t.sons[i].kind == nkExceptBranch): 
    blen = sonsLen(t.sons[i])
    if blen == 1: 
      # general except section:
      app(p.s[cpsStmts], "default: " & tnl)
      genStmts(p, t.sons[i].sons[0])
    else: 
      for j in countup(0, blen - 2): 
        assert(t.sons[i].sons[j].kind == nkType)
        appf(p.s[cpsStmts], "case $1:$n", [toRope(t.sons[i].sons[j].typ.id)])
      genStmts(p, t.sons[i].sons[blen - 1])
    if rethrowFlag != nil: 
      appf(p.s[cpsStmts], "$1 = NIM_FALSE;  ", [rethrowFlag])
    app(p.s[cpsStmts], "break;" & tnl)
    inc(i)
  if t.sons[1].kind == nkExceptBranch: 
    app(p.s[cpsStmts], "}}" & tnl) # end of catch-switch statement
  dec(p.nestedTryStmts)
  app(p.s[cpsStmts], "excHandler = excHandler->prev;" & tnl)
  if (i < length) and (t.sons[i].kind == nkFinally): 
    genStmts(p, t.sons[i].sons[0])
    if rethrowFlag != nil: 
      appf(p.s[cpsStmts], "if ($1) { throw; }$n", [rethrowFlag])
  
proc genTryStmt(p: BProc, t: PNode) = 
  # code to generate:
  #
  #  sp.prev = excHandler;
  #  excHandler = &sp;
  #  sp.status = setjmp(sp.context);
  #  if (sp.status == 0) {
  #    myDiv(4, 9);
  #  } else {
  #    /* except DivisionByZero: */
  #    if (sp.status == DivisionByZero) {
  #      printf('Division by Zero\n');
  #
  #      /* longjmp(excHandler->context, RangeError); /* raise rangeError */
  #      sp.status = RangeError; /* if raise; else 0 */
  #    }
  #  }
  #  /* finally: */
  #  printf('fin!\n');
  #  if (sp.status != 0)
  #    longjmp(excHandler->context, sp.status);
  #  excHandler = excHandler->prev; /* deactivate this safe point */ 
  var 
    i, length, blen: int
    safePoint, orExpr: PRope
  genLineDir(p, t)
  safePoint = getTempName()
  useMagic(p.module, "TSafePoint")
  useMagic(p.module, "E_Base")
  useMagic(p.module, "excHandler")
  appf(p.s[cpsLocals], "TSafePoint $1;$n", [safePoint])
  appf(p.s[cpsStmts], "$1.prev = excHandler;$n" & "excHandler = &$1;$n" &
      "$1.status = setjmp($1.context);$n", [safePoint])
  if optStackTrace in p.Options: 
    app(p.s[cpsStmts], "framePtr = (TFrame*)&F;" & tnl)
  appf(p.s[cpsStmts], "if ($1.status == 0) {$n", [safePoint])
  length = sonsLen(t)
  inc(p.nestedTryStmts)
  genStmts(p, t.sons[0])
  app(p.s[cpsStmts], "} else {" & tnl)
  i = 1
  while (i < length) and (t.sons[i].kind == nkExceptBranch): 
    blen = sonsLen(t.sons[i])
    if blen == 1: 
      # general except section:
      if i > 1: app(p.s[cpsStmts], "else {" & tnl)
      genStmts(p, t.sons[i].sons[0])
      appf(p.s[cpsStmts], "$1.status = 0;$n", [safePoint])
      if i > 1: app(p.s[cpsStmts], '}' & tnl)
    else: 
      orExpr = nil
      for j in countup(0, blen - 2): 
        assert(t.sons[i].sons[j].kind == nkType)
        if orExpr != nil: app(orExpr, "||")
        appf(orExpr, "($1.exc->Sup.m_type == $2)", 
             [safePoint, genTypeInfo(p.module, t.sons[i].sons[j].typ)])
      if i > 1: app(p.s[cpsStmts], "else ")
      appf(p.s[cpsStmts], "if ($1) {$n", [orExpr])
      genStmts(p, t.sons[i].sons[blen - 1]) # code to clear the exception:
      appf(p.s[cpsStmts], "$1.status = 0;}$n", [safePoint])
    inc(i)
  app(p.s[cpsStmts], '}' & tnl) # end of if statement
  finishTryStmt(p, p.nestedTryStmts)
  dec(p.nestedTryStmts)
  if (i < length) and (t.sons[i].kind == nkFinally): 
    genStmts(p, t.sons[i].sons[0])
    useMagic(p.module, "raiseException")
    appf(p.s[cpsStmts], "if ($1.status != 0) { " &
        "raiseException($1.exc, $1.exc->name); }$n", [safePoint])

var 
  breakPointId: int = 0
  gBreakpoints: PRope # later the breakpoints are inserted into the main proc

proc genBreakPoint(p: BProc, t: PNode) = 
  var name: string
  if optEndb in p.Options: 
    if t.kind == nkExprColonExpr: 
      assert(t.sons[1].kind in {nkStrLit..nkTripleStrLit})
      name = normalize(t.sons[1].strVal)
    else: 
      inc(breakPointId)
      name = "bp" & $(breakPointId)
    genLineDir(p, t)          # BUGFIX
    appf(gBreakpoints, 
         "dbgRegisterBreakpoint($1, (NCSTRING)$2, (NCSTRING)$3);$n", [
        toRope(toLinenumber(t.info)), makeCString(toFilename(t.info)), 
        makeCString(name)])

proc genPragma(p: BProc, n: PNode) = 
  for i in countup(0, sonsLen(n) - 1): 
    var it = n.sons[i]
    var key: PNode
    if it.kind == nkExprColonExpr: 
      key = it.sons[0]
    else: 
      key = it
    if key.kind == nkIdent: 
      case whichKeyword(key.ident)
      of wBreakpoint: 
        genBreakPoint(p, it)
      of wDeadCodeElim: 
        if not (optDeadCodeElim in gGlobalOptions): 
          # we need to keep track of ``deadCodeElim`` pragma
          if (sfDeadCodeElim in p.module.module.flags): 
            addPendingModule(p.module)
      else: 
        nil
  
proc genAsgn(p: BProc, e: PNode) = 
  var a: TLoc
  genLineDir(p, e)            # BUGFIX
  InitLocExpr(p, e.sons[0], a)
  assert(a.t != nil)
  expr(p, e.sons[1], a)

proc genFastAsgn(p: BProc, e: PNode) = 
  var a: TLoc
  genLineDir(p, e)            # BUGFIX
  InitLocExpr(p, e.sons[0], a)
  incl(a.flags, lfNoDeepCopy)
  assert(a.t != nil)
  expr(p, e.sons[1], a)

proc genStmts(p: BProc, t: PNode) = 
  var 
    a: TLoc
    prc: PSym
  #assert(t <> nil);
  if inCheckpoint(t.info): MessageOut(renderTree(t))
  case t.kind
  of nkEmpty: 
    nil
  of nkStmtList: 
    for i in countup(0, sonsLen(t) - 1): genStmts(p, t.sons[i])
  of nkBlockStmt: genBlock(p, t, a)
  of nkIfStmt: genIfStmt(p, t)
  of nkWhileStmt: genWhileStmt(p, t)
  of nkVarSection: genVarStmt(p, t)
  of nkConstSection: genConstStmt(p, t)
  of nkForStmt: internalError(t.info, "for statement not eliminated")
  of nkCaseStmt: genCaseStmt(p, t)
  of nkReturnStmt: genReturnStmt(p, t)
  of nkBreakStmt: genBreakStmt(p, t)
  of nkCall, nkHiddenCallConv, nkInfix, nkPrefix, nkPostfix, nkCommand, 
     nkCallStrLit: 
    genLineDir(p, t)
    initLocExpr(p, t, a)
  of nkAsgn: genAsgn(p, t)
  of nkFastAsgn: genFastAsgn(p, t)
  of nkDiscardStmt: 
    genLineDir(p, t)
    initLocExpr(p, t.sons[0], a)
  of nkAsmStmt: genAsmStmt(p, t)
  of nkTryStmt: 
    if gCmd == cmdCompileToCpp: genTryStmtCpp(p, t)
    else: genTryStmt(p, t)
  of nkRaiseStmt: genRaiseStmt(p, t)
  of nkTypeSection: 
    # we have to emit the type information for object types here to support
    # separate compilation:
    genTypeSection(p.module, t)
  of nkCommentStmt, nkNilLit, nkIteratorDef, nkIncludeStmt, nkImportStmt, 
     nkFromStmt, nkTemplateDef, nkMacroDef: 
    nil
  of nkPragma: genPragma(p, t)
  of nkProcDef, nkMethodDef, nkConverterDef: 
    if (t.sons[genericParamsPos] == nil): 
      prc = t.sons[namePos].sym
      if not (optDeadCodeElim in gGlobalOptions) and
          not (sfDeadCodeElim in getModule(prc).flags) or
          ({sfExportc, sfCompilerProc} * prc.flags == {sfExportc}) or
          (prc.kind == skMethod): 
        if (t.sons[codePos] != nil) or (lfDynamicLib in prc.loc.flags): 
          genProc(p.module, prc)
  else: internalError(t.info, "genStmts(" & $t.kind & ')')
  
