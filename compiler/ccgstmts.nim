#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# included from cgen.nim

const
  RangeExpandLimit = 256      # do not generate ranges
                              # over 'RangeExpandLimit' elements
  stringCaseThreshold = 8
    # above X strings a hash-switch for strings is generated

proc getTraverseProc(p: BProc, v: Psym): Rope =
  if p.config.selectedGC in {gcMarkAndSweep, gcDestructors, gcV2, gcRefc} and
      optNimV2 notin p.config.globalOptions and
      containsGarbageCollectedRef(v.loc.t):
    # we register a specialized marked proc here; this has the advantage
    # that it works out of the box for thread local storage then :-)
    result = genTraverseProcForGlobal(p.module, v, v.info)

proc registerTraverseProc(p: BProc, v: PSym, traverseProc: Rope) =
  if sfThread in v.flags:
    appcg(p.module, p.module.initProc.procSec(cpsInit),
      "$n\t#nimRegisterThreadLocalMarker($1);$n$n", [traverseProc])
  else:
    appcg(p.module, p.module.initProc.procSec(cpsInit),
      "$n\t#nimRegisterGlobalMarker($1);$n$n", [traverseProc])

proc isAssignedImmediately(conf: ConfigRef; n: PNode): bool {.inline.} =
  if n.kind == nkEmpty: return false
  if isInvalidReturnType(conf, n.typ):
    # var v = f()
    # is transformed into: var v;  f(addr v)
    # where 'f' **does not** initialize the result!
    return false
  result = true

proc inExceptBlockLen(p: BProc): int =
  for x in p.nestedTryStmts:
    if x.inExcept: result.inc

proc startBlockInternal(p: BProc): int {.discardable.} =
  inc(p.labels)
  result = len(p.blocks)
  setLen(p.blocks, result + 1)
  p.blocks[result].id = p.labels
  p.blocks[result].nestedTryStmts = p.nestedTryStmts.len.int16
  p.blocks[result].nestedExceptStmts = p.inExceptBlockLen.int16

template startBlock(p: BProc, start: FormatStr = "{$n",
                args: varargs[Rope]): int =
  lineCg(p, cpsStmts, start, args)
  startBlockInternal(p)

proc endBlock(p: BProc)

proc genVarTuple(p: BProc, n: PNode) =
  var tup, field: TLoc
  if n.kind != nkVarTuple: internalError(p.config, n.info, "genVarTuple")
  var L = sonsLen(n)

  # if we have a something that's been captured, use the lowering instead:
  for i in countup(0, L-3):
    if n[i].kind != nkSym:
      genStmts(p, lowerTupleUnpacking(p.module.g.graph, n, p.prc))
      return

  # check only the first son
  var forHcr = treatGlobalDifferentlyForHCR(p.module, n.sons[0].sym)
  let hcrCond = if forHcr: getTempName(p.module) else: nil
  var hcrGlobals: seq[tuple[loc: TLoc, tp: Rope]]
  # determine if the tuple is constructed at top-level scope or inside of a block (if/while/block)
  let isGlobalInBlock = forHcr and p.blocks.len > 2
  # do not close and reopen blocks if this is a 'global' but inside of a block (if/while/block)
  forHcr = forHcr and not isGlobalInBlock

  if forHcr:
    # check with the boolean if the initializing code for the tuple should be ran
    lineCg(p, cpsStmts, "if ($1)$n", [hcrCond])
    startBlock(p)
  defer:
    if forHcr:
      # end the block where the tuple gets initialized
      endBlock(p)
    if forHcr or isGlobalInBlock:
      # insert the registration of the globals for the different parts of the tuple at the
      # start of the current scope (after they have been iterated) and init a boolean to
      # check if any of them is newly introduced and the initializing code has to be ran
      lineCg(p, cpsLocals, "NIM_BOOL $1 = NIM_FALSE;$n", [hcrCond])
      for curr in hcrGlobals:
        lineCg(p, cpsLocals, "$1 |= hcrRegisterGlobal($4, \"$2\", sizeof($3), $5, (void**)&$2);$N",
               [hcrCond, curr.loc.r, rdLoc(curr.loc), getModuleDllPath(p.module, n.sons[0].sym), curr.tp])

  genLineDir(p, n)
  initLocExpr(p, n.sons[L-1], tup)
  var t = tup.t.skipTypes(abstractInst)
  for i in countup(0, L-3):
    let vn = n.sons[i]
    let v = vn.sym
    if sfCompileTime in v.flags: continue
    var traverseProc: Rope
    if sfGlobal in v.flags:
      assignGlobalVar(p, vn)
      genObjectInit(p, cpsInit, v.typ, v.loc, true)
      traverseProc = getTraverseProc(p, v)
      if traverseProc != nil and not p.hcrOn:
        registerTraverseProc(p, v, traverseProc)
    else:
      assignLocalVar(p, vn)
      initLocalVar(p, v, immediateAsgn=isAssignedImmediately(p.config, n[L-1]))
    initLoc(field, locExpr, vn, tup.storage)
    if t.kind == tyTuple:
      field.r = "$1.Field$2" % [rdLoc(tup), rope(i)]
    else:
      if t.n.sons[i].kind != nkSym: internalError(p.config, n.info, "genVarTuple")
      field.r = "$1.$2" % [rdLoc(tup), mangleRecFieldName(p.module, t.n.sons[i].sym)]
    putLocIntoDest(p, v.loc, field)
    if forHcr or isGlobalInBlock:
      hcrGlobals.add((loc: v.loc, tp: if traverseProc == nil: ~"NULL" else: traverseProc))

proc loadInto(p: BProc, le, ri: PNode, a: var TLoc) {.inline.} =
  if ri.kind in nkCallKinds and (ri.sons[0].kind != nkSym or
                                 ri.sons[0].sym.magic == mNone):
    genAsgnCall(p, le, ri, a)
  else:
    # this is a hacky way to fix #1181 (tmissingderef)::
    #
    #  var arr1 = cast[ptr array[4, int8]](addr foo)[]
    #
    # However, fixing this properly really requires modelling 'array' as
    # a 'struct' in C to preserve dereferencing semantics completely. Not
    # worth the effort until version 1.0 is out.
    a.flags.incl(lfEnforceDeref)
    expr(p, ri, a)

proc assignLabel(b: var TBlock): Rope {.inline.} =
  b.label = "LA" & b.id.rope
  result = b.label

proc blockBody(b: var TBlock): Rope =
  result = b.sections[cpsLocals]
  if b.frameLen > 0:
    result.addf("FR_.len+=$1;$n", [b.frameLen.rope])
  result.add(b.sections[cpsInit])
  result.add(b.sections[cpsStmts])

proc endBlock(p: BProc, blockEnd: Rope) =
  let topBlock = p.blocks.len-1
  # the block is merged into the parent block
  add(p.blocks[topBlock-1].sections[cpsStmts], p.blocks[topBlock].blockBody)
  setLen(p.blocks, topBlock)
  # this is done after the block is popped so $n is
  # properly indented when pretty printing is enabled
  line(p, cpsStmts, blockEnd)

proc endBlock(p: BProc) =
  let topBlock = p.blocks.len - 1
  let frameLen = p.blocks[topBlock].frameLen
  var blockEnd: Rope
  if frameLen > 0:
    blockEnd.addf("FR_.len-=$1;$n", [frameLen.rope])
  if p.blocks[topBlock].label != nil:
    blockEnd.addf("} $1: ;$n", [p.blocks[topBlock].label])
  else:
    blockEnd.addf("}$n", [])
  endBlock(p, blockEnd)

proc genSimpleBlock(p: BProc, stmts: PNode) {.inline.} =
  startBlock(p)
  genStmts(p, stmts)
  endBlock(p)

proc exprBlock(p: BProc, n: PNode, d: var TLoc) =
  startBlock(p)
  expr(p, n, d)
  endBlock(p)

template preserveBreakIdx(body: untyped): untyped =
  var oldBreakIdx = p.breakIdx
  body
  p.breakIdx = oldBreakIdx

proc genState(p: BProc, n: PNode) =
  internalAssert p.config, n.len == 1
  let n0 = n[0]
  if n0.kind == nkIntLit:
    let idx = n.sons[0].intVal
    linefmt(p, cpsStmts, "STATE$1: ;$n", [idx])
  elif n0.kind == nkStrLit:
    linefmt(p, cpsStmts, "$1: ;$n", [n0.strVal])

proc blockLeaveActions(p: BProc, howManyTrys, howManyExcepts: int) =
  # Called by return and break stmts.
  # Deals with issues faced when jumping out of try/except/finally stmts,

  var stack = newSeq[tuple[n: PNode, inExcept: bool]](0)

  for i in countup(1, howManyTrys):
    let tryStmt = p.nestedTryStmts.pop
    if not p.module.compileToCpp or optNoCppExceptions in p.config.globalOptions:
      # Pop safe points generated by try
      if not tryStmt.inExcept:
        linefmt(p, cpsStmts, "#popSafePoint();$n", [])

    # Pop this try-stmt of the list of nested trys
    # so we don't infinite recurse on it in the next step.
    stack.add(tryStmt)

    # Find finally-stmt for this try-stmt
    # and generate a copy of its sons
    var finallyStmt = lastSon(tryStmt.n)
    if finallyStmt.kind == nkFinally:
      genStmts(p, finallyStmt.sons[0])

  # push old elements again:
  for i in countdown(howManyTrys-1, 0):
    p.nestedTryStmts.add(stack[i])

  if not p.module.compileToCpp or optNoCppExceptions in p.config.globalOptions:
    # Pop exceptions that was handled by the
    # except-blocks we are in
    if not p.noSafePoints:
      for i in countdown(howManyExcepts-1, 0):
        linefmt(p, cpsStmts, "#popCurrentException();$n", [])

proc genGotoState(p: BProc, n: PNode) =
  # we resist the temptation to translate it into duff's device as it later
  # will be translated into computed gotos anyway for GCC at least:
  # switch (x.state) {
  #   case 0: goto STATE0;
  # ...
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  lineF(p, cpsStmts, "switch ($1) {$n", [rdLoc(a)])
  p.beforeRetNeeded = true
  lineF(p, cpsStmts, "case -1:$n", [])
  blockLeaveActions(p,
    howManyTrys    = p.nestedTryStmts.len,
    howManyExcepts = p.inExceptBlockLen)
  lineF(p, cpsStmts, " goto BeforeRet_;$n", [])
  var statesCounter = lastOrd(p.config, n.sons[0].typ)
  if n.len >= 2 and n[1].kind == nkIntLit:
    statesCounter = n[1].intVal
  let prefix = if n.len == 3 and n[2].kind == nkStrLit: n[2].strVal.rope
               else: rope"STATE"
  for i in 0i64 .. statesCounter:
    lineF(p, cpsStmts, "case $2: goto $1$2;$n", [prefix, rope(i)])
  lineF(p, cpsStmts, "}$n", [])

proc genBreakState(p: BProc, n: PNode, d: var TLoc) =
  var a: TLoc
  initLoc(d, locExpr, n, OnUnknown)

  if n.sons[0].kind == nkClosure:
    initLocExpr(p, n.sons[0].sons[1], a)
    d.r = "(((NI*) $1)[1] < 0)" % [rdLoc(a)]
  else:
    initLocExpr(p, n.sons[0], a)
    # the environment is guaranteed to contain the 'state' field at offset 1:
    d.r = "((((NI*) $1.ClE_0)[1]) < 0)" % [rdLoc(a)]

proc genGotoVar(p: BProc; value: PNode) =
  if value.kind notin {nkCharLit..nkUInt64Lit}:
    localError(p.config, value.info, "'goto' target must be a literal value")
  else:
    lineF(p, cpsStmts, "goto NIMSTATE_$#;$n", [value.intVal.rope])

proc genSingleVar(p: BProc, a: PNode) =
  let vn = a.sons[0]
  let v = vn.sym
  if sfCompileTime in v.flags: return
  if sfGoto in v.flags:
    # translate 'var state {.goto.} = X' into 'goto LX':
    genGotoVar(p, a.sons[2])
    return
  var targetProc = p
  var traverseProc: Rope
  if sfGlobal in v.flags:
    if v.flags * {sfImportc, sfExportc} == {sfImportc} and
        a.sons[2].kind == nkEmpty and
        v.loc.flags * {lfHeader, lfNoDecl} != {}:
      return
    if sfPure in v.flags:
      # v.owner.kind != skModule:
      targetProc = p.module.preInitProc
    assignGlobalVar(targetProc, vn)
    # XXX: be careful here.
    # Global variables should not be zeromem-ed within loops
    # (see bug #20).
    # That's why we are doing the construction inside the preInitProc.
    # genObjectInit relies on the C runtime's guarantees that
    # global variables will be initialized to zero.
    var loc = v.loc

    # When the native TLS is unavailable, a global thread-local variable needs
    # one more layer of indirection in order to access the TLS block.
    # Only do this for complex types that may need a call to `objectInit`
    if sfThread in v.flags and emulatedThreadVars(p.config) and
      isComplexValueType(v.typ):
      initLocExprSingleUse(p.module.preInitProc, vn, loc)
    genObjectInit(p.module.preInitProc, cpsInit, v.typ, loc, true)
    # Alternative construction using default constructor (which may zeromem):
    # if sfImportc notin v.flags: constructLoc(p.module.preInitProc, v.loc)
    if sfExportc in v.flags and p.module.g.generatedHeader != nil:
      genVarPrototype(p.module.g.generatedHeader, vn)
    traverseProc = getTraverseProc(p, v)
    if traverseProc != nil and not p.hcrOn:
      registerTraverseProc(p, v, traverseProc)
  else:
    let value = a.sons[2]
    let imm = isAssignedImmediately(p.config, value)
    if imm and p.module.compileToCpp and p.splitDecls == 0 and
        not containsHiddenPointer(v.typ):
      # C++ really doesn't like things like 'Foo f; f = x' as that invokes a
      # parameterless constructor followed by an assignment operator. So we
      # generate better code here: 'Foo f = x;'
      genLineDir(p, a)
      let decl = localVarDecl(p, vn)
      var tmp: TLoc
      if value.kind in nkCallKinds and value[0].kind == nkSym and
           sfConstructor in value[0].sym.flags:
        var params: Rope
        let typ = skipTypes(value.sons[0].typ, abstractInst)
        assert(typ.kind == tyProc)
        for i in 1..<value.len:
          if params != nil: params.add(~", ")
          assert(sonsLen(typ) == sonsLen(typ.n))
          add(params, genOtherArg(p, value, i, typ))
        if params == nil:
          lineF(p, cpsStmts, "$#;$n", [decl])
        else:
          lineF(p, cpsStmts, "$#($#);$n", [decl, params])
      else:
        initLocExprSingleUse(p, value, tmp)
        lineF(p, cpsStmts, "$# = $#;$n", [decl, tmp.rdLoc])
      return
    assignLocalVar(p, vn)
    initLocalVar(p, v, imm)

  if traverseProc == nil: traverseProc = ~"NULL"
  # If the var is in a block (control flow like if/while or a block) in global scope just
  # register the so called "global" so it can be used later on. There is no need to close
  # and reopen of if (nim_hcr_do_init_) blocks because we are in one already anyway.
  var forHcr = treatGlobalDifferentlyForHCR(p.module, v)
  if forHcr and targetProc.blocks.len > 3 and v.owner.kind == skModule:
    # put it in the locals section - mainly because of loops which
    # use the var in a call to resetLoc() in the statements section
    lineCg(targetProc, cpsLocals, "hcrRegisterGlobal($3, \"$1\", sizeof($2), $4, (void**)&$1);$n",
           [v.loc.r, rdLoc(v.loc), getModuleDllPath(p.module, v), traverseProc])
    # nothing special left to do later on - let's avoid closing and reopening blocks
    forHcr = false

  # we close and reopen the global if (nim_hcr_do_init_) blocks in the main Init function
  # for the module so we can have globals and top-level code be interleaved and still
  # be able to re-run it but without the top level code - just the init of globals
  if forHcr:
    lineCg(targetProc, cpsStmts, "if (hcrRegisterGlobal($3, \"$1\", sizeof($2), $4, (void**)&$1))$N",
           [v.loc.r, rdLoc(v.loc), getModuleDllPath(p.module, v), traverseProc])
    startBlock(targetProc)
  defer:
    if forHcr:
      endBlock(targetProc)

  if a.sons[2].kind != nkEmpty:
    genLineDir(targetProc, a)
    loadInto(targetProc, a.sons[0], a.sons[2], v.loc)

proc genClosureVar(p: BProc, a: PNode) =
  var immediateAsgn = a.sons[2].kind != nkEmpty
  var v: TLoc
  initLocExpr(p, a.sons[0], v)
  genLineDir(p, a)
  if immediateAsgn:
    loadInto(p, a.sons[0], a.sons[2], v)
  else:
    constructLoc(p, v)

proc genVarStmt(p: BProc, n: PNode) =
  for it in n.sons:
    if it.kind == nkCommentStmt: continue
    if it.kind == nkIdentDefs:
      # can be a lifted var nowadays ...
      if it.sons[0].kind == nkSym:
        genSingleVar(p, it)
      else:
        genClosureVar(p, it)
    else:
      genVarTuple(p, it)

proc genIf(p: BProc, n: PNode, d: var TLoc) =
  #
  #  { if (!expr1) goto L1;
  #   thenPart }
  #  goto LEnd
  #  L1:
  #  { if (!expr2) goto L2;
  #   thenPart2 }
  #  goto LEnd
  #  L2:
  #  { elsePart }
  #  Lend:
  var
    a: TLoc
    lelse: TLabel
  if not isEmptyType(n.typ) and d.k == locNone:
    getTemp(p, n.typ, d)
  genLineDir(p, n)
  let lend = getLabel(p)
  for it in n.sons:
    # bug #4230: avoid false sharing between branches:
    if d.k == locTemp and isEmptyType(n.typ): d.k = locNone
    if it.len == 2:
      startBlock(p)
      initLocExprSingleUse(p, it.sons[0], a)
      lelse = getLabel(p)
      inc(p.labels)
      lineF(p, cpsStmts, "if (!$1) goto $2;$n",
            [rdLoc(a), lelse])
      if p.module.compileToCpp:
        # avoid "jump to label crosses initialization" error:
        add(p.s(cpsStmts), "{")
        expr(p, it.sons[1], d)
        add(p.s(cpsStmts), "}")
      else:
        expr(p, it.sons[1], d)
      endBlock(p)
      if sonsLen(n) > 1:
        lineF(p, cpsStmts, "goto $1;$n", [lend])
      fixLabel(p, lelse)
    elif it.len == 1:
      startBlock(p)
      expr(p, it.sons[0], d)
      endBlock(p)
    else: internalError(p.config, n.info, "genIf()")
  if sonsLen(n) > 1: fixLabel(p, lend)

proc genReturnStmt(p: BProc, t: PNode) =
  if nfPreventCg in t.flags: return
  p.beforeRetNeeded = true
  genLineDir(p, t)
  if (t.sons[0].kind != nkEmpty): genStmts(p, t.sons[0])
  blockLeaveActions(p,
    howManyTrys    = p.nestedTryStmts.len,
    howManyExcepts = p.inExceptBlockLen)
  if (p.finallySafePoints.len > 0) and not p.noSafePoints:
    # If we're in a finally block, and we came here by exception
    # consume it before we return.
    var safePoint = p.finallySafePoints[p.finallySafePoints.len-1]
    linefmt(p, cpsStmts, "if ($1.status != 0) #popCurrentException();$n", [safePoint])
  lineF(p, cpsStmts, "goto BeforeRet_;$n", [])

proc genGotoForCase(p: BProc; caseStmt: PNode) =
  for i in 1 ..< caseStmt.len:
    startBlock(p)
    let it = caseStmt.sons[i]
    for j in 0 .. it.len-2:
      if it.sons[j].kind == nkRange:
        localError(p.config, it.info, "range notation not available for computed goto")
        return
      let val = getOrdValue(it.sons[j])
      lineF(p, cpsStmts, "NIMSTATE_$#:$n", [val.rope])
    genStmts(p, it.lastSon)
    endBlock(p)


iterator fieldValuePairs(n: PNode): tuple[memberSym, valueSym: PNode] =
  assert(n.kind in {nkLetSection, nkVarSection})
  for identDefs in n:
    if identDefs.kind == nkIdentDefs:
      let valueSym = identDefs[^1]
      for i in 0 ..< identDefs.len-2:
        let memberSym = identDefs[i]
        yield((memberSym: memberSym, valueSym: valueSym))

proc genComputedGoto(p: BProc; n: PNode) =
  # first pass: Generate array of computed labels:
  var casePos = -1
  var arraySize: int
  for i in 0 ..< n.len:
    let it = n.sons[i]
    if it.kind == nkCaseStmt:
      if lastSon(it).kind != nkOfBranch:
        localError(p.config, it.info,
            "case statement must be exhaustive for computed goto"); return
      casePos = i
      if enumHasHoles(it.sons[0].typ):
        localError(p.config, it.info,
            "case statement cannot work on enums with holes for computed goto"); return
      let aSize = lengthOrd(p.config, it.sons[0].typ)
      if aSize > 10_000:
        localError(p.config, it.info,
            "case statement has too many cases for computed goto"); return
      arraySize = aSize.int
      if firstOrd(p.config, it.sons[0].typ) != 0:
        localError(p.config, it.info,
            "case statement has to start at 0 for computed goto"); return
  if casePos < 0:
    localError(p.config, n.info, "no case statement found for computed goto"); return
  var id = p.labels+1
  inc p.labels, arraySize+1
  let tmp = "TMP$1_" % [id.rope]
  var gotoArray = "static void* $#[$#] = {" % [tmp, arraySize.rope]
  for i in 1..arraySize-1:
    gotoArray.addf("&&TMP$#_, ", [rope(id+i)])
  gotoArray.addf("&&TMP$#_};$n", [rope(id+arraySize)])
  line(p, cpsLocals, gotoArray)

  for j in 0 ..< casePos:
    genStmts(p, n.sons[j])

  let caseStmt = n.sons[casePos]
  var a: TLoc
  initLocExpr(p, caseStmt.sons[0], a)
  # first goto:
  lineF(p, cpsStmts, "goto *$#[$#];$n", [tmp, a.rdLoc])

  for i in 1 ..< caseStmt.len:
    startBlock(p)
    let it = caseStmt.sons[i]
    for j in 0 .. it.len-2:
      if it.sons[j].kind == nkRange:
        localError(p.config, it.info, "range notation not available for computed goto")
        return

      let val = getOrdValue(it.sons[j])
      lineF(p, cpsStmts, "TMP$#_:$n", [intLiteral(val+id+1)])

    genStmts(p, it.lastSon)

    for j in casePos+1 ..< n.sons.len:
      genStmts(p, n.sons[j])

    for j in 0 ..< casePos:
      # prevent new local declarations
      # compile declarations as assignments
      let it = n.sons[j]
      if it.kind in {nkLetSection, nkVarSection}:
        let asgn = copyNode(it)
        asgn.kind = nkAsgn
        asgn.sons.setLen 2
        for sym, value in it.fieldValuePairs:
          if value.kind != nkEmpty:
            asgn.sons[0] = sym
            asgn.sons[1] = value
            genStmts(p, asgn)
      else:
        genStmts(p, it)

    var a: TLoc
    initLocExpr(p, caseStmt.sons[0], a)
    lineF(p, cpsStmts, "goto *$#[$#];$n", [tmp, a.rdLoc])
    endBlock(p)

  for j in casePos+1 ..< n.sons.len:
    genStmts(p, n.sons[j])


proc genWhileStmt(p: BProc, t: PNode) =
  # we don't generate labels here as for example GCC would produce
  # significantly worse code
  var
    a: TLoc
  assert(sonsLen(t) == 2)
  inc(p.withinLoop)
  genLineDir(p, t)

  preserveBreakIdx:
    var loopBody = t.sons[1]
    if loopBody.stmtsContainPragma(wComputedGoto) and
       hasComputedGoto in CC[p.config.cCompiler].props:
         # for closure support weird loop bodies are generated:
      if loopBody.len == 2 and loopBody.sons[0].kind == nkEmpty:
        loopBody = loopBody.sons[1]
      genComputedGoto(p, loopBody)
    else:
      p.breakIdx = startBlock(p, "while (1) {$n")
      p.blocks[p.breakIdx].isLoop = true
      initLocExpr(p, t.sons[0], a)
      if (t.sons[0].kind != nkIntLit) or (t.sons[0].intVal == 0):
        let label = assignLabel(p.blocks[p.breakIdx])
        lineF(p, cpsStmts, "if (!$1) goto $2;$n", [rdLoc(a), label])
      genStmts(p, loopBody)

      if optProfiler in p.options:
        # invoke at loop body exit:
        linefmt(p, cpsStmts, "#nimProfile();$n", [])
      endBlock(p)

  dec(p.withinLoop)

proc genBlock(p: BProc, n: PNode, d: var TLoc) =
  if not isEmptyType(n.typ):
    # bug #4505: allocate the temp in the outer scope
    # so that it can escape the generated {}:
    if d.k == locNone:
      getTemp(p, n.typ, d)
    d.flags.incl(lfEnforceDeref)
  preserveBreakIdx:
    p.breakIdx = startBlock(p)
    if n.sons[0].kind != nkEmpty:
      # named block?
      assert(n.sons[0].kind == nkSym)
      var sym = n.sons[0].sym
      sym.loc.k = locOther
      sym.position = p.breakIdx+1
    expr(p, n.sons[1], d)
    endBlock(p)

proc genParForStmt(p: BProc, t: PNode) =
  assert(sonsLen(t) == 3)
  inc(p.withinLoop)
  genLineDir(p, t)

  preserveBreakIdx:
    let forLoopVar = t.sons[0].sym
    var rangeA, rangeB: TLoc
    assignLocalVar(p, t.sons[0])
    #initLoc(forLoopVar.loc, locLocalVar, forLoopVar.typ, onStack)
    #discard mangleName(forLoopVar)
    let call = t.sons[1]
    assert(sonsLen(call) in {4, 5})
    initLocExpr(p, call.sons[1], rangeA)
    initLocExpr(p, call.sons[2], rangeB)

    # $n at the beginning because of #9710
    if call.sonsLen == 4: # `||`(a, b, annotation)
      lineF(p, cpsStmts, "$n#pragma omp $4$n" &
                          "for ($1 = $2; $1 <= $3; ++$1)",
                          [forLoopVar.loc.rdLoc,
                          rangeA.rdLoc, rangeB.rdLoc,
                          call.sons[3].getStr.rope])
    else: # `||`(a, b, step, annotation)
      var step: TLoc
      initLocExpr(p, call.sons[3], step)
      lineF(p, cpsStmts, "$n#pragma omp $5$n" &
                    "for ($1 = $2; $1 <= $3; $1 += $4)",
                    [forLoopVar.loc.rdLoc,
                    rangeA.rdLoc, rangeB.rdLoc, step.rdLoc,
                    call.sons[4].getStr.rope])

    p.breakIdx = startBlock(p)
    p.blocks[p.breakIdx].isLoop = true
    genStmts(p, t.sons[2])
    endBlock(p)

  dec(p.withinLoop)

proc genBreakStmt(p: BProc, t: PNode) =
  var idx = p.breakIdx
  if t.sons[0].kind != nkEmpty:
    # named break?
    assert(t.sons[0].kind == nkSym)
    var sym = t.sons[0].sym
    doAssert(sym.loc.k == locOther)
    idx = sym.position-1
  else:
    # an unnamed 'break' can only break a loop after 'transf' pass:
    while idx >= 0 and not p.blocks[idx].isLoop: dec idx
    if idx < 0 or not p.blocks[idx].isLoop:
      internalError(p.config, t.info, "no loop to break")
  let label = assignLabel(p.blocks[idx])
  blockLeaveActions(p,
    p.nestedTryStmts.len - p.blocks[idx].nestedTryStmts,
    p.inExceptBlockLen - p.blocks[idx].nestedExceptStmts)
  genLineDir(p, t)
  lineF(p, cpsStmts, "goto $1;$n", [label])

proc genRaiseStmt(p: BProc, t: PNode) =
  if p.module.compileToCpp:
    discard cgsym(p.module, "popCurrentExceptionEx")
  if p.nestedTryStmts.len > 0 and p.nestedTryStmts[^1].inExcept:
    # if the current try stmt have a finally block,
    # we must execute it before reraising
    var finallyBlock = p.nestedTryStmts[^1].n[^1]
    if finallyBlock.kind == nkFinally:
      genSimpleBlock(p, finallyBlock[0])
  if t[0].kind != nkEmpty:
    var a: TLoc
    initLocExprSingleUse(p, t[0], a)
    var e = rdLoc(a)
    var typ = skipTypes(t[0].typ, abstractPtrs)
    genLineDir(p, t)
    if isImportedException(typ, p.config):
      lineF(p, cpsStmts, "throw $1;$n", [e])
    else:
      lineCg(p, cpsStmts, "#raiseExceptionEx((#Exception*)$1, $2, $3, $4, $5);$n",
          [e, makeCString(typ.sym.name.s),
          makeCString(if p.prc != nil: p.prc.name.s else: p.module.module.name.s),
          makeCString(toFileName(p.config, t.info)), toLinenumber(t.info)])
      if optNimV2 in p.config.globalOptions:
        lineCg(p, cpsStmts, "$1 = NIM_NIL;$n", [e])
  else:
    genLineDir(p, t)
    # reraise the last exception:
    if p.module.compileToCpp and optNoCppExceptions notin p.config.globalOptions:
      line(p, cpsStmts, ~"throw;$n")
    else:
      linefmt(p, cpsStmts, "#reraiseException();$n", [])

template genCaseGenericBranch(p: BProc, b: PNode, e: TLoc,
                          rangeFormat, eqFormat: FormatStr, labl: TLabel) =
  var
    x, y: TLoc
  var length = sonsLen(b)
  for i in countup(0, length - 2):
    if b.sons[i].kind == nkRange:
      initLocExpr(p, b.sons[i].sons[0], x)
      initLocExpr(p, b.sons[i].sons[1], y)
      lineCg(p, cpsStmts, rangeFormat,
           [rdCharLoc(e), rdCharLoc(x), rdCharLoc(y), labl])
    else:
      initLocExpr(p, b.sons[i], x)
      lineCg(p, cpsStmts, eqFormat, [rdCharLoc(e), rdCharLoc(x), labl])

proc genCaseSecondPass(p: BProc, t: PNode, d: var TLoc,
                       labId, until: int): TLabel =
  var lend = getLabel(p)
  for i in 1..until:
    # bug #4230: avoid false sharing between branches:
    if d.k == locTemp and isEmptyType(t.typ): d.k = locNone
    lineF(p, cpsStmts, "LA$1_: ;$n", [rope(labId + i)])
    if t.sons[i].kind == nkOfBranch:
      var length = sonsLen(t.sons[i])
      exprBlock(p, t.sons[i].sons[length - 1], d)
      lineF(p, cpsStmts, "goto $1;$n", [lend])
    else:
      exprBlock(p, t.sons[i].sons[0], d)
  result = lend

template genIfForCaseUntil(p: BProc, t: PNode, d: var TLoc,
                       rangeFormat, eqFormat: FormatStr,
                       until: int, a: TLoc): TLabel =
  # generate a C-if statement for a Nim case statement
  var res: TLabel
  var labId = p.labels
  for i in 1..until:
    inc(p.labels)
    if t.sons[i].kind == nkOfBranch: # else statement
      genCaseGenericBranch(p, t.sons[i], a, rangeFormat, eqFormat,
                           "LA" & rope(p.labels) & "_")
    else:
      lineF(p, cpsStmts, "goto LA$1_;$n", [rope(p.labels)])
  if until < t.len-1:
    inc(p.labels)
    var gotoTarget = p.labels
    lineF(p, cpsStmts, "goto LA$1_;$n", [rope(gotoTarget)])
    res = genCaseSecondPass(p, t, d, labId, until)
    lineF(p, cpsStmts, "LA$1_: ;$n", [rope(gotoTarget)])
  else:
    res = genCaseSecondPass(p, t, d, labId, until)
  res

template genCaseGeneric(p: BProc, t: PNode, d: var TLoc,
                    rangeFormat, eqFormat: FormatStr) =
  var a: TLoc
  initLocExpr(p, t.sons[0], a)
  var lend = genIfForCaseUntil(p, t, d, rangeFormat, eqFormat, sonsLen(t)-1, a)
  fixLabel(p, lend)

proc genCaseStringBranch(p: BProc, b: PNode, e: TLoc, labl: TLabel,
                         branches: var openArray[Rope]) =
  var x: TLoc
  var length = sonsLen(b)
  for i in countup(0, length - 2):
    assert(b.sons[i].kind != nkRange)
    initLocExpr(p, b.sons[i], x)
    assert(b.sons[i].kind in {nkStrLit..nkTripleStrLit})
    var j = int(hashString(p.config, b.sons[i].strVal) and high(branches))
    appcg(p.module, branches[j], "if (#eqStrings($1, $2)) goto $3;$n",
         [rdLoc(e), rdLoc(x), labl])

proc genStringCase(p: BProc, t: PNode, d: var TLoc) =
  # count how many constant strings there are in the case:
  var strings = 0
  for i in countup(1, sonsLen(t) - 1):
    if t.sons[i].kind == nkOfBranch: inc(strings, sonsLen(t.sons[i]) - 1)
  if strings > stringCaseThreshold:
    var bitMask = math.nextPowerOfTwo(strings) - 1
    var branches: seq[Rope]
    newSeq(branches, bitMask + 1)
    var a: TLoc
    initLocExpr(p, t.sons[0], a) # fist pass: gnerate ifs+goto:
    var labId = p.labels
    for i in countup(1, sonsLen(t) - 1):
      inc(p.labels)
      if t.sons[i].kind == nkOfBranch:
        genCaseStringBranch(p, t.sons[i], a, "LA" & rope(p.labels) & "_",
                            branches)
      else:
        # else statement: nothing to do yet
        # but we reserved a label, which we use later
        discard
    linefmt(p, cpsStmts, "switch (#hashString($1) & $2) {$n",
            [rdLoc(a), bitMask])
    for j in countup(0, high(branches)):
      if branches[j] != nil:
        lineF(p, cpsStmts, "case $1: $n$2break;$n",
             [intLiteral(j), branches[j]])
    lineF(p, cpsStmts, "}$n", []) # else statement:
    if t.sons[sonsLen(t)-1].kind != nkOfBranch:
      lineF(p, cpsStmts, "goto LA$1_;$n", [rope(p.labels)])
    # third pass: generate statements
    var lend = genCaseSecondPass(p, t, d, labId, sonsLen(t)-1)
    fixLabel(p, lend)
  else:
    genCaseGeneric(p, t, d, "", "if (#eqStrings($1, $2)) goto $3;$n")

proc branchHasTooBigRange(b: PNode): bool =
  for i in countup(0, sonsLen(b)-2):
    # last son is block
    if (b.sons[i].kind == nkRange) and
        b.sons[i].sons[1].intVal - b.sons[i].sons[0].intVal > RangeExpandLimit:
      return true

proc ifSwitchSplitPoint(p: BProc, n: PNode): int =
  for i in 1..n.len-1:
    var branch = n[i]
    var stmtBlock = lastSon(branch)
    if stmtBlock.stmtsContainPragma(wLinearScanEnd):
      result = i
    elif hasSwitchRange notin CC[p.config.cCompiler].props:
      if branch.kind == nkOfBranch and branchHasTooBigRange(branch):
        result = i

proc genCaseRange(p: BProc, branch: PNode) =
  var length = branch.len
  for j in 0 .. length-2:
    if branch[j].kind == nkRange:
      if hasSwitchRange in CC[p.config.cCompiler].props:
        lineF(p, cpsStmts, "case $1 ... $2:$n", [
            genLiteral(p, branch[j][0]),
            genLiteral(p, branch[j][1])])
      else:
        var v = copyNode(branch[j][0])
        while v.intVal <= branch[j][1].intVal:
          lineF(p, cpsStmts, "case $1:$n", [genLiteral(p, v)])
          inc(v.intVal)
    else:
      lineF(p, cpsStmts, "case $1:$n", [genLiteral(p, branch[j])])

proc genOrdinalCase(p: BProc, n: PNode, d: var TLoc) =
  # analyse 'case' statement:
  var splitPoint = ifSwitchSplitPoint(p, n)

  # generate if part (might be empty):
  var a: TLoc
  initLocExpr(p, n.sons[0], a)
  var lend = if splitPoint > 0: genIfForCaseUntil(p, n, d,
                    rangeFormat = "if ($1 >= $2 && $1 <= $3) goto $4;$n",
                    eqFormat = "if ($1 == $2) goto $3;$n",
                    splitPoint, a) else: nil

  # generate switch part (might be empty):
  if splitPoint+1 < n.len:
    lineF(p, cpsStmts, "switch ($1) {$n", [rdCharLoc(a)])
    var hasDefault = false
    for i in splitPoint+1 ..< n.len:
      # bug #4230: avoid false sharing between branches:
      if d.k == locTemp and isEmptyType(n.typ): d.k = locNone
      var branch = n[i]
      if branch.kind == nkOfBranch:
        genCaseRange(p, branch)
      else:
        # else part of case statement:
        lineF(p, cpsStmts, "default:$n", [])
        hasDefault = true
      exprBlock(p, branch.lastSon, d)
      lineF(p, cpsStmts, "break;$n", [])
    if (hasAssume in CC[p.config.cCompiler].props) and not hasDefault:
      lineF(p, cpsStmts, "default: __assume(0);$n", [])
    lineF(p, cpsStmts, "}$n", [])
  if lend != nil: fixLabel(p, lend)

proc genCase(p: BProc, t: PNode, d: var TLoc) =
  genLineDir(p, t)
  if not isEmptyType(t.typ) and d.k == locNone:
    getTemp(p, t.typ, d)
  case skipTypes(t.sons[0].typ, abstractVarRange).kind
  of tyString:
    genStringCase(p, t, d)
  of tyFloat..tyFloat128:
    genCaseGeneric(p, t, d, "if ($1 >= $2 && $1 <= $3) goto $4;$n",
                            "if ($1 == $2) goto $3;$n")
  else:
    if t.sons[0].kind == nkSym and sfGoto in t.sons[0].sym.flags:
      genGotoForCase(p, t)
    else:
      genOrdinalCase(p, t, d)

proc genRestoreFrameAfterException(p: BProc) =
  if optStackTrace in p.module.config.options:
    if not p.hasCurFramePointer:
      p.hasCurFramePointer = true
      p.procSec(cpsLocals).add(ropecg(p.module, "\tTFrame* _nimCurFrame;$n", []))
      p.procSec(cpsInit).add(ropecg(p.module, "\t_nimCurFrame = #getFrame();$n", []))
    linefmt(p, cpsStmts, "#setFrame(_nimCurFrame);$n", [])

proc genTryCpp(p: BProc, t: PNode, d: var TLoc) =
  # code to generate:
  #
  #   try
  #   {
  #      myDiv(4, 9);
  #   } catch (NimExceptionType1&) {
  #      body
  #   } catch (NimExceptionType2&) {
  #      finallyPart()
  #      raise;
  #   }
  #   catch(...) {
  #     general_handler_body
  #   }
  #   finallyPart();

  template genExceptBranchBody(body: PNode) {.dirty.} =
    genRestoreFrameAfterException(p)
    expr(p, body, d)

  if not isEmptyType(t.typ) and d.k == locNone:
    getTemp(p, t.typ, d)
  genLineDir(p, t)
  discard cgsym(p.module, "popCurrentExceptionEx")
  add(p.nestedTryStmts, (t, false))
  startBlock(p, "try {$n")
  expr(p, t[0], d)
  endBlock(p)

  var catchAllPresent = false

  p.nestedTryStmts[^1].inExcept = true
  for i in 1..<t.len:
    if t[i].kind != nkExceptBranch: break

    # bug #4230: avoid false sharing between branches:
    if d.k == locTemp and isEmptyType(t.typ): d.k = locNone

    if t[i].len == 1:
      # general except section:
      catchAllPresent = true
      startBlock(p, "catch (...) {$n")
      genExceptBranchBody(t[i][0])
      endBlock(p)
    else:
      for j in 0..t[i].len-2:
        if t[i][j].isInfixAs():
          let exvar = t[i][j][2] # ex1 in `except ExceptType as ex1:`
          fillLoc(exvar.sym.loc, locTemp, exvar, mangleLocalName(p, exvar.sym), OnUnknown)
          startBlock(p, "catch ($1& $2) {$n", getTypeDesc(p.module, t[i][j][1].typ), rdLoc(exvar.sym.loc))
        else:
          startBlock(p, "catch ($1&) {$n", getTypeDesc(p.module, t[i][j].typ))
        genExceptBranchBody(t[i][^1])  # exception handler body will duplicated for every type
        endBlock(p)

  discard pop(p.nestedTryStmts)

  if t[^1].kind == nkFinally:
    # c++ does not have finally, therefore code needs to be generated twice
    if not catchAllPresent:
      # finally requires catch all presence
      startBlock(p, "catch (...) {$n")
      genStmts(p, t[^1][0])
      line(p, cpsStmts, ~"throw;$n")
      endBlock(p)

    genSimpleBlock(p, t[^1][0])

proc genTry(p: BProc, t: PNode, d: var TLoc) =
  # code to generate:
  #
  # XXX: There should be a standard dispatch algorithm
  # that's used both here and with multi-methods
  #
  #  TSafePoint sp;
  #  pushSafePoint(&sp);
  #  sp.status = setjmp(sp.context);
  #  if (sp.status == 0) {
  #    myDiv(4, 9);
  #    popSafePoint();
  #  } else {
  #    popSafePoint();
  #    /* except DivisionByZero: */
  #    if (sp.status == DivisionByZero) {
  #      printf('Division by Zero\n');
  #      clearException();
  #    } else {
  #      clearException();
  #    }
  #  }
  #  {
  #    /* finally: */
  #    printf('fin!\n');
  #  }
  #  if (exception not cleared)
  #    propagateCurrentException();
  #
  if not isEmptyType(t.typ) and d.k == locNone:
    getTemp(p, t.typ, d)
  let quirkyExceptions = isDefined(p.config, "nimQuirky") or
      (t.kind == nkHiddenTryStmt and sfSystemModule in p.module.module.flags)
  if not quirkyExceptions:
    p.module.includeHeader("<setjmp.h>")
  else:
    p.noSafePoints = true
  genLineDir(p, t)
  discard cgsym(p.module, "Exception")
  var safePoint: Rope
  if not quirkyExceptions:
    safePoint = getTempName(p.module)
    linefmt(p, cpsLocals, "#TSafePoint $1;$n", [safePoint])
    linefmt(p, cpsStmts, "#pushSafePoint(&$1);$n", [safePoint])
    if isDefined(p.config, "nimStdSetjmp"):
      linefmt(p, cpsStmts, "$1.status = setjmp($1.context);$n", [safePoint])
    elif isDefined(p.config, "nimSigSetjmp"):
      linefmt(p, cpsStmts, "$1.status = sigsetjmp($1.context, 0);$n", [safePoint])
    elif isDefined(p.config, "nimRawSetjmp"):
      linefmt(p, cpsStmts, "$1.status = _setjmp($1.context);$n", [safePoint])
    else:
      linefmt(p, cpsStmts, "$1.status = setjmp($1.context);$n", [safePoint])
    startBlock(p, "if ($1.status == 0) {$n", [safePoint])
  var length = sonsLen(t)
  add(p.nestedTryStmts, (t, quirkyExceptions))
  expr(p, t.sons[0], d)
  if not quirkyExceptions:
    linefmt(p, cpsStmts, "#popSafePoint();$n", [])
    endBlock(p)
    startBlock(p, "else {$n")
    linefmt(p, cpsStmts, "#popSafePoint();$n", [])
    genRestoreFrameAfterException(p)
  elif 1 < length and t.sons[1].kind == nkExceptBranch:
    startBlock(p, "if (#getCurrentException()) {$n")
  else:
    startBlock(p)
  p.nestedTryStmts[^1].inExcept = true
  var i = 1
  while (i < length) and (t.sons[i].kind == nkExceptBranch):
    # bug #4230: avoid false sharing between branches:
    if d.k == locTemp and isEmptyType(t.typ): d.k = locNone
    var blen = sonsLen(t.sons[i])
    if blen == 1:
      # general except section:
      if i > 1: lineF(p, cpsStmts, "else", [])
      startBlock(p)
      if not quirkyExceptions:
        linefmt(p, cpsStmts, "$1.status = 0;$n", [safePoint])
      expr(p, t.sons[i].sons[0], d)
      linefmt(p, cpsStmts, "#popCurrentException();$n", [])
      endBlock(p)
    else:
      var orExpr: Rope = nil
      for j in countup(0, blen - 2):
        assert(t.sons[i].sons[j].kind == nkType)
        if orExpr != nil: add(orExpr, "||")
        let checkFor = if optNimV2 in p.config.globalOptions:
          genTypeInfo2Name(p.module, t[i][j].typ)
        else:
          genTypeInfo(p.module, t[i][j].typ, t[i][j].info)
        let memberName = if p.module.compileToCpp: "m_type" else: "Sup.m_type"
        appcg(p.module, orExpr, "#isObj(#getCurrentException()->$1, $2)", [memberName, checkFor])

      if i > 1: line(p, cpsStmts, "else ")
      startBlock(p, "if ($1) {$n", [orExpr])
      if not quirkyExceptions:
        linefmt(p, cpsStmts, "$1.status = 0;$n", [safePoint])
      expr(p, t.sons[i].sons[blen-1], d)
      linefmt(p, cpsStmts, "#popCurrentException();$n", [])
      endBlock(p)
    inc(i)
  discard pop(p.nestedTryStmts)
  endBlock(p) # end of else block
  if i < length and t.sons[i].kind == nkFinally:
    p.finallySafePoints.add(safePoint)
    genSimpleBlock(p, t.sons[i].sons[0])
    discard pop(p.finallySafePoints)
  if not quirkyExceptions:
    linefmt(p, cpsStmts, "if ($1.status != 0) #reraiseException();$n", [safePoint])

proc genAsmOrEmitStmt(p: BProc, t: PNode, isAsmStmt=false): Rope =
  var res = ""
  for it in t.sons:
    case it.kind
    of nkStrLit..nkTripleStrLit:
      res.add(it.strVal)
    of nkSym:
      var sym = it.sym
      if sym.kind in {skProc, skFunc, skIterator, skMethod}:
        var a: TLoc
        initLocExpr(p, it, a)
        res.add($rdLoc(a))
      elif sym.kind == skType:
        res.add($getTypeDesc(p.module, sym.typ))
      else:
        discard getTypeDesc(p.module, skipTypes(sym.typ, abstractPtrs))
        var r = sym.loc.r
        if r == nil:
          # if no name has already been given,
          # it doesn't matter much:
          r = mangleName(p.module, sym)
          sym.loc.r = r       # but be consequent!
        res.add($r)
    of nkTypeOfExpr:
      res.add($getTypeDesc(p.module, it.typ))
    else:
      discard getTypeDesc(p.module, skipTypes(it.typ, abstractPtrs))
      var a: TLoc
      initLocExpr(p, it, a)
      res.add($a.rdLoc)

  if isAsmStmt and hasGnuAsm in CC[p.config.cCompiler].props:
    for x in splitLines(res):
      var j = 0
      while j < x.len and x[j] in {' ', '\t'}: inc(j)
      if j < x.len:
        if x[j] in {'"', ':'}:
          # don't modify the line if already in quotes or
          # some clobber register list:
          add(result, x); add(result, "\L")
        else:
          # ignore empty lines
          add(result, "\"")
          add(result, x)
          add(result, "\\n\"\n")
  else:
    res.add("\L")
    result = res.rope

proc genAsmStmt(p: BProc, t: PNode) =
  assert(t.kind == nkAsmStmt)
  genLineDir(p, t)
  var s = genAsmOrEmitStmt(p, t, isAsmStmt=true)
  # see bug #2362, "top level asm statements" seem to be a mis-feature
  # but even if we don't do this, the example in #2362 cannot possibly
  # work:
  if p.prc == nil:
    # top level asm statement?
    add(p.module.s[cfsProcHeaders], runtimeFormat(CC[p.config.cCompiler].asmStmtFrmt, [s]))
  else:
    add(p.s(cpsStmts), indentLine(p, runtimeFormat(CC[p.config.cCompiler].asmStmtFrmt, [s])))

proc determineSection(n: PNode): TCFileSection =
  result = cfsProcHeaders
  if n.len >= 1 and n.sons[0].kind in {nkStrLit..nkTripleStrLit}:
    let sec = n.sons[0].strVal
    if sec.startsWith("/*TYPESECTION*/"): result = cfsTypes
    elif sec.startsWith("/*VARSECTION*/"): result = cfsVars
    elif sec.startsWith("/*INCLUDESECTION*/"): result = cfsHeaders

proc genEmit(p: BProc, t: PNode) =
  var s = genAsmOrEmitStmt(p, t.sons[1])
  if p.prc == nil:
    # top level emit pragma?
    let section = determineSection(t[1])
    genCLineDir(p.module.s[section], t.info, p.config)
    add(p.module.s[section], s)
  else:
    genLineDir(p, t)
    line(p, cpsStmts, s)

proc genBreakPoint(p: BProc, t: PNode) =
  var name: string
  if optEndb in p.options:
    if t.kind == nkExprColonExpr:
      assert(t.sons[1].kind in {nkStrLit..nkTripleStrLit})
      name = normalize(t.sons[1].strVal)
    else:
      inc(p.module.g.breakPointId)
      name = "bp" & $p.module.g.breakPointId
    genLineDir(p, t)          # BUGFIX
    appcg(p.module, p.module.g.breakpoints,
         "#dbgRegisterBreakpoint($1, (NCSTRING)$2, (NCSTRING)$3);$n", [
        toLinenumber(t.info), makeCString(toFilename(p.config, t.info)),
        makeCString(name)])

proc genWatchpoint(p: BProc, n: PNode) =
  if optEndb notin p.options: return
  var a: TLoc
  initLocExpr(p, n.sons[1], a)
  let typ = skipTypes(n.sons[1].typ, abstractVarRange)
  lineCg(p, cpsStmts, "#dbgRegisterWatchpoint($1, (NCSTRING)$2, $3);$n",
        [addrLoc(p.config, a), makeCString(renderTree(n.sons[1])),
        genTypeInfo(p.module, typ, n.info)])

proc genPragma(p: BProc, n: PNode) =
  for it in n.sons:
    case whichPragma(it)
    of wEmit: genEmit(p, it)
    of wBreakpoint: genBreakPoint(p, it)
    of wWatchPoint: genWatchpoint(p, it)
    of wInjectStmt:
      var p = newProc(nil, p.module)
      p.options = p.options - {optLineTrace, optStackTrace}
      genStmts(p, it.sons[1])
      p.module.injectStmt = p.s(cpsStmts)
    else: discard

proc fieldDiscriminantCheckNeeded(p: BProc, asgn: PNode): bool =
  if optFieldCheck in p.options:
    var le = asgn.sons[0]
    if le.kind == nkCheckedFieldExpr:
      var field = le.sons[0].sons[1].sym
      result = sfDiscriminant in field.flags
    elif le.kind == nkDotExpr:
      var field = le.sons[1].sym
      result = sfDiscriminant in field.flags

proc genDiscriminantCheck(p: BProc, a, tmp: TLoc, objtype: PType,
                          field: PSym) =
  var t = skipTypes(objtype, abstractVar)
  assert t.kind == tyObject
  discard genTypeInfo(p.module, t, a.lode.info)
  var L = lengthOrd(p.config, field.typ)
  if not containsOrIncl(p.module.declaredThings, field.id):
    appcg(p.module, cfsVars, "extern $1",
          [discriminatorTableDecl(p.module, t, field)])
  lineCg(p, cpsStmts,
        "#FieldDiscriminantCheck((NI)(NU)($1), (NI)(NU)($2), $3, $4);$n",
        [rdLoc(a), rdLoc(tmp), discriminatorTableName(p.module, t, field),
         intLiteral(L+1)])

proc asgnFieldDiscriminant(p: BProc, e: PNode) =
  var a, tmp: TLoc
  var dotExpr = e.sons[0]
  if dotExpr.kind == nkCheckedFieldExpr: dotExpr = dotExpr.sons[0]
  initLocExpr(p, e.sons[0], a)
  getTemp(p, a.t, tmp)
  expr(p, e.sons[1], tmp)
  genDiscriminantCheck(p, a, tmp, dotExpr.sons[0].typ, dotExpr.sons[1].sym)
  genAssignment(p, a, tmp, {})

proc genAsgn(p: BProc, e: PNode, fastAsgn: bool) =
  if e.sons[0].kind == nkSym and sfGoto in e.sons[0].sym.flags:
    genLineDir(p, e)
    genGotoVar(p, e.sons[1])
  elif not fieldDiscriminantCheckNeeded(p, e):
    let le = e[0]
    let ri = e[1]
    var a: TLoc
    discard getTypeDesc(p.module, le.typ.skipTypes(skipPtrs))
    initLoc(a, locNone, le, OnUnknown)
    a.flags.incl(lfEnforceDeref)
    expr(p, le, a)
    if fastAsgn: incl(a.flags, lfNoDeepCopy)
    assert(a.t != nil)
    genLineDir(p, ri)
    loadInto(p, e.sons[0], ri, a)
  else:
    genLineDir(p, e)
    asgnFieldDiscriminant(p, e)

proc genStmts(p: BProc, t: PNode) =
  var a: TLoc

  let isPush = hintExtendedContext in p.config.notes
  if isPush: pushInfoContext(p.config, t.info)
  expr(p, t, a)
  if isPush: popInfoContext(p.config)
  internalAssert p.config, a.k in {locNone, locTemp, locLocalVar, locExpr}
