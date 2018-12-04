#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Data flow analysis for Nim.
## We transform the AST into a linear list of instructions first to
## make this easier to handle: There are only 2 different branching
## instructions: 'goto X' is an unconditional goto, 'fork X'
## is a conditional goto (either the next instruction or 'X' can be
## taken). Exhaustive case statements could be translated
## so that the last branch is transformed into an 'else' branch, but
## this is currently not done.
## ``return`` and ``break`` are all covered by 'goto'.
##
## Control flow through exception handling:
## Contrary to popular belief, exception handling doesn't cause
## many problems for this DFA representation, ``raise`` is a statement
## that ``goes to`` the outer ``finally`` or ``except`` if there is one,
## otherwise it is the same as ``return``. Every call is treated as
## a call that can potentially ``raise``. However, without a surrounding
## ``try`` we don't emit these ``fork ReturnLabel`` instructions in order
## to speed up the dataflow analysis passes.
##
## The data structures and algorithms used here are inspired by
## "A Graph–Free Approach to Data–Flow Analysis" by Markus Mohnen.
## https://link.springer.com/content/pdf/10.1007/3-540-45937-5_6.pdf

import ast, astalgo, types, intsets, tables, msgs, options, lineinfos

type
  InstrKind* = enum
    goto, fork, def, use
  Instr* = object
    n*: PNode
    case kind*: InstrKind
    of def, use: sym*: PSym
    of goto, fork: dest*: int

  ControlFlowGraph* = seq[Instr]

  TPosition = distinct int
  TBlock = object
    label: PSym
    fixups: seq[TPosition]

  ValueKind = enum
    undef, value, valueOrUndef

  Con = object
    code: ControlFlowGraph
    inCall, inTryStmt: int
    blocks: seq[TBlock]
    tryStmtFixups: seq[TPosition]
    owner: PSym

proc debugInfo(info: TLineInfo): string =
  result = $info.line #info.toFilename & ":" & $info.line

proc codeListing(c: ControlFlowGraph, result: var string, start=0; last = -1) =
  # for debugging purposes
  # first iteration: compute all necessary labels:
  var jumpTargets = initIntSet()
  let last = if last < 0: c.len-1 else: min(last, c.len-1)
  for i in start..last:
    if c[i].kind in {goto, fork}:
      jumpTargets.incl(i+c[i].dest)
  var i = start
  while i <= last:
    if i in jumpTargets: result.add("L" & $i & ":\n")
    result.add "\t"
    result.add $c[i].kind
    result.add "\t"
    case c[i].kind
    of def, use:
      result.add c[i].sym.name.s
    of goto, fork:
      result.add "L"
      result.add c[i].dest+i
    result.add("\t#")
    result.add(debugInfo(c[i].n.info))
    result.add("\n")
    inc i
  if i in jumpTargets: result.add("L" & $i & ": End\n")


proc echoCfg*(c: ControlFlowGraph; start=0; last = -1) {.deprecated.} =
  ## echos the ControlFlowGraph for debugging purposes.
  var buf = ""
  codeListing(c, buf, start, last)
  when declared(echo):
    echo buf

proc forkI(c: var Con; n: PNode): TPosition =
  result = TPosition(c.code.len)
  c.code.add Instr(n: n, kind: fork, dest: 0)

proc gotoI(c: var Con; n: PNode): TPosition =
  result = TPosition(c.code.len)
  c.code.add Instr(n: n, kind: goto, dest: 0)

proc genLabel(c: Con): TPosition =
  result = TPosition(c.code.len)

proc jmpBack(c: var Con, n: PNode, p = TPosition(0)) =
  let dist = p.int - c.code.len
  doAssert(-0x7fff < dist and dist < 0x7fff)
  c.code.add Instr(n: n, kind: goto, dest: dist)

proc patch(c: var Con, p: TPosition) =
  # patch with current index
  let p = p.int
  let diff = c.code.len - p
  doAssert(-0x7fff < diff and diff < 0x7fff)
  c.code[p].dest = diff

proc popBlock(c: var Con; oldLen: int) =
  for f in c.blocks[oldLen].fixups:
    c.patch(f)
  c.blocks.setLen(oldLen)

template withBlock(labl: PSym; body: untyped) {.dirty.} =
  var oldLen {.gensym.} = c.blocks.len
  c.blocks.add TBlock(label: labl, fixups: @[])
  body
  popBlock(c, oldLen)

proc isTrue(n: PNode): bool =
  n.kind == nkSym and n.sym.kind == skEnumField and n.sym.position != 0 or
    n.kind == nkIntLit and n.intVal != 0

proc gen(c: var Con; n: PNode) # {.noSideEffect.}

proc genWhile(c: var Con; n: PNode) =
  # L1:
  #   cond, tmp
  #   fork tmp, L2
  #   body
  #   jmp L1
  # L2:
  let L1 = c.genLabel
  withBlock(nil):
    if isTrue(n.sons[0]):
      c.gen(n.sons[1])
      c.jmpBack(n, L1)
    else:
      c.gen(n.sons[0])
      let L2 = c.forkI(n)
      c.gen(n.sons[1])
      c.jmpBack(n, L1)
      c.patch(L2)

proc genBlock(c: var Con; n: PNode) =
  withBlock(n.sons[0].sym):
    c.gen(n.sons[1])

proc genBreak(c: var Con; n: PNode) =
  let L1 = c.gotoI(n)
  if n.sons[0].kind == nkSym:
    #echo cast[int](n.sons[0].sym)
    for i in countdown(c.blocks.len-1, 0):
      if c.blocks[i].label == n.sons[0].sym:
        c.blocks[i].fixups.add L1
        return
    #globalError(n.info, "VM problem: cannot find 'break' target")
  else:
    c.blocks[c.blocks.high].fixups.add L1

proc genIf(c: var Con, n: PNode) =
  var endings: seq[TPosition] = @[]
  for i in countup(0, len(n) - 1):
    var it = n.sons[i]
    c.gen(it.sons[0])
    if it.len == 2:
      let elsePos = c.forkI(it.sons[1])
      c.gen(it.sons[1])
      if i < sonsLen(n)-1:
        endings.add(c.gotoI(it.sons[1]))
      c.patch(elsePos)
  for endPos in endings: c.patch(endPos)

proc genAndOr(c: var Con; n: PNode) =
  #   asgn dest, a
  #   fork L1
  #   asgn dest, b
  # L1:
  c.gen(n.sons[1])
  let L1 = c.forkI(n)
  c.gen(n.sons[2])
  c.patch(L1)

proc genCase(c: var Con; n: PNode) =
  #  if (!expr1) goto L1;
  #    thenPart
  #    goto LEnd
  #  L1:
  #  if (!expr2) goto L2;
  #    thenPart2
  #    goto LEnd
  #  L2:
  #    elsePart
  #  Lend:
  when false:
    # XXX Exhaustiveness is not yet mapped to the control flow graph as
    # it seems to offer no benefits for the 'last read of' question.
    let isExhaustive = skipTypes(n.sons[0].typ,
      abstractVarRange-{tyTypeDesc}).kind in {tyFloat..tyFloat128, tyString} or
      lastSon(n).kind == nkElse

  var endings: seq[TPosition] = @[]
  c.gen(n.sons[0])
  for i in 1 ..< n.len:
    let it = n.sons[i]
    if it.len == 1:
      c.gen(it.sons[0])
    else:
      let elsePos = c.forkI(it.lastSon)
      c.gen(it.lastSon)
      if i < sonsLen(n)-1:
        endings.add(c.gotoI(it.lastSon))
      c.patch(elsePos)
  for endPos in endings: c.patch(endPos)

proc genTry(c: var Con; n: PNode) =
  var endings: seq[TPosition] = @[]
  inc c.inTryStmt
  var newFixups: seq[TPosition]
  swap(newFixups, c.tryStmtFixups)

  let elsePos = c.forkI(n)
  c.gen(n.sons[0])
  dec c.inTryStmt
  for f in newFixups:
    c.patch(f)
  swap(newFixups, c.tryStmtFixups)

  c.patch(elsePos)
  for i in 1 ..< n.len:
    let it = n.sons[i]
    if it.kind != nkFinally:
      var blen = len(it)
      let endExcept = c.forkI(it)
      c.gen(it.lastSon)
      if i < sonsLen(n)-1:
        endings.add(c.gotoI(it))
      c.patch(endExcept)
  for endPos in endings: c.patch(endPos)
  let fin = lastSon(n)
  if fin.kind == nkFinally:
    c.gen(fin.sons[0])

proc genRaise(c: var Con; n: PNode) =
  gen(c, n.sons[0])
  if c.inTryStmt > 0:
    c.tryStmtFixups.add c.gotoI(n)
  else:
    c.code.add Instr(n: n, kind: goto, dest: high(int) - c.code.len)

proc genImplicitReturn(c: var Con) =
  if c.owner.kind in {skProc, skFunc, skMethod, skIterator, skConverter} and resultPos < c.owner.ast.len:
    gen(c, c.owner.ast.sons[resultPos])

proc genReturn(c: var Con; n: PNode) =
  if n.sons[0].kind != nkEmpty:
    gen(c, n.sons[0])
  else:
    genImplicitReturn(c)
  c.code.add Instr(n: n, kind: goto, dest: high(int) - c.code.len)

const
  InterestingSyms = {skVar, skResult, skLet}

proc genUse(c: var Con; n: PNode) =
  var n = n
  while n.kind in {nkDotExpr, nkCheckedFieldExpr,
                   nkBracketExpr, nkDerefExpr, nkHiddenDeref,
                   nkAddr, nkHiddenAddr}:
    n = n[0]
  if n.kind == nkSym and n.sym.kind in InterestingSyms:
    c.code.add Instr(n: n, kind: use, sym: n.sym)

proc genDef(c: var Con; n: PNode) =
  if n.kind == nkSym and n.sym.kind in InterestingSyms:
    c.code.add Instr(n: n, kind: def, sym: n.sym)

proc genCall(c: var Con; n: PNode) =
  gen(c, n[0])
  var t = n[0].typ
  if t != nil: t = t.skipTypes(abstractInst)
  inc c.inCall
  for i in 1..<n.len:
    gen(c, n[i])
    if t != nil and i < t.len and t.sons[i].kind == tyVar:
      genDef(c, n[i])
  # every call can potentially raise:
  if c.inTryStmt > 0:
    c.tryStmtFixups.add c.forkI(n)
  dec c.inCall

proc genMagic(c: var Con; n: PNode; m: TMagic) =
  case m
  of mAnd, mOr: c.genAndOr(n)
  of mNew, mNewFinalize:
    genDef(c, n[1])
    for i in 2..<n.len: gen(c, n[i])
  of mExit:
    genCall(c, n)
    c.code.add Instr(n: n, kind: goto, dest: high(int) - c.code.len)
  else:
    genCall(c, n)

proc genVarSection(c: var Con; n: PNode) =
  for a in n:
    if a.kind == nkCommentStmt: continue
    if a.kind == nkVarTuple:
      gen(c, a.lastSon)
      for i in 0 .. a.len-3: genDef(c, a[i])
    else:
      gen(c, a.lastSon)
      if a.lastSon.kind != nkEmpty:
        genDef(c, a.sons[0])

proc gen(c: var Con; n: PNode) =
  case n.kind
  of nkSym: genUse(c, n)
  of nkCallKinds:
    if n.sons[0].kind == nkSym:
      let s = n.sons[0].sym
      if s.magic != mNone:
        genMagic(c, n, s.magic)
      else:
        genCall(c, n)
    else:
      genCall(c, n)
  of nkCharLit..nkNilLit: discard
  of nkAsgn, nkFastAsgn:
    gen(c, n[1])
    genDef(c, n[0])
  of nkDotExpr, nkCheckedFieldExpr, nkBracketExpr,
     nkDerefExpr, nkHiddenDeref, nkAddr, nkHiddenAddr:
    gen(c, n[0])
  of nkIfStmt, nkIfExpr: genIf(c, n)
  of nkWhenStmt:
    # This is "when nimvm" node. Chose the first branch.
    gen(c, n.sons[0].sons[1])
  of nkCaseStmt: genCase(c, n)
  of nkWhileStmt: genWhile(c, n)
  of nkBlockExpr, nkBlockStmt: genBlock(c, n)
  of nkReturnStmt: genReturn(c, n)
  of nkRaiseStmt: genRaise(c, n)
  of nkBreakStmt: genBreak(c, n)
  of nkTryStmt: genTry(c, n)
  of nkStmtList, nkStmtListExpr, nkChckRangeF, nkChckRange64, nkChckRange,
     nkBracket, nkCurly, nkPar, nkTupleConstr, nkClosure, nkObjConstr:
    for x in n: gen(c, x)
  of nkPragmaBlock: gen(c, n.lastSon)
  of nkDiscardStmt: gen(c, n.sons[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv, nkExprColonExpr, nkExprEqExpr,
     nkCast:
    gen(c, n.sons[1])
  of nkObjDownConv, nkStringToCString, nkCStringToString: gen(c, n.sons[0])
  of nkVarSection, nkLetSection: genVarSection(c, n)
  of nkDefer:
    doAssert false, "dfa construction pass requires the elimination of 'defer'"
  else: discard

proc dfa(code: seq[Instr]; conf: ConfigRef) =
  var u = newSeq[IntSet](code.len) # usages
  var d = newSeq[IntSet](code.len) # defs
  var c = newSeq[IntSet](code.len) # consumed
  var backrefs = initTable[int, int]()
  for i in 0..<code.len:
    u[i] = initIntSet()
    d[i] = initIntSet()
    c[i] = initIntSet()
    case code[i].kind
    of use: u[i].incl(code[i].sym.id)
    of def: d[i].incl(code[i].sym.id)
    of fork, goto:
      let d = i+code[i].dest
      backrefs.add(d, i)

  var w = @[0]
  var maxIters = 50
  var someChange = true
  var takenGotos = initIntSet()
  var consuming = -1
  while w.len > 0 and maxIters > 0: # and someChange:
    dec maxIters
    var pc = w.pop() # w[^1]
    var prevPc = -1
    # this simulates a single linear control flow execution:
    while pc < code.len:
      if prevPc >= 0:
        someChange = false
        # merge step and test for changes (we compute the fixpoints here):
        # 'u' needs to be the union of prevPc, pc
        # 'd' needs to be the intersection of 'pc'
        for id in u[prevPc]:
          if not u[pc].containsOrIncl(id):
            someChange = true
        # in (a; b) if ``a`` sets ``v`` so does ``b``. The intersection
        # is only interesting on merge points:
        for id in d[prevPc]:
          if not d[pc].containsOrIncl(id):
            someChange = true
        # if this is a merge point, we take the intersection of the 'd' sets:
        if backrefs.hasKey(pc):
          var intersect = initIntSet()
          assign(intersect, d[pc])
          var first = true
          for prevPc in backrefs.allValues(pc):
            for def in d[pc]:
              if def notin d[prevPc]:
                excl(intersect, def)
                someChange = true
                when defined(debugDfa):
                  echo "Excluding ", pc, " prev ", prevPc
          assign d[pc], intersect
      if consuming >= 0:
        if not c[pc].containsOrIncl(consuming):
          someChange = true
        consuming = -1

      # our interpretation ![I!]:
      prevPc = pc
      case code[pc].kind
      of goto:
        # we must leave endless loops eventually:
        if not takenGotos.containsOrIncl(pc) or someChange:
          pc = pc + code[pc].dest
        else:
          inc pc
      of fork:
        # we follow the next instruction but push the dest onto our "work" stack:
        #if someChange:
        w.add pc + code[pc].dest
        inc pc
      of use:
        #if not d[prevPc].missingOrExcl():
        # someChange = true
        consuming = code[pc].sym.id
        inc pc
      of def:
        if not d[pc].containsOrIncl(code[pc].sym.id):
          someChange = true
        inc pc

  when defined(useDfa) and defined(debugDfa):
    for i in 0..<code.len:
      echo "PC ", i, ": defs: ", d[i], "; uses ", u[i], "; consumes ", c[i]

  # now check the condition we're interested in:
  for i in 0..<code.len:
    case code[i].kind
    of use:
      let s = code[i].sym
      if s.id notin d[i]:
        localError(conf, code[i].n.info, "usage of uninitialized variable: " & s.name.s)
      if s.id in c[i]:
        localError(conf, code[i].n.info, "usage of an already consumed variable: " & s.name.s)

    else: discard

proc dataflowAnalysis*(s: PSym; body: PNode; conf: ConfigRef) =
  var c = Con(code: @[], blocks: @[])
  gen(c, body)
  genImplicitReturn(c)
  when defined(useDfa) and defined(debugDfa): echoCfg(c.code)
  dfa(c.code, conf)

proc constructCfg*(s: PSym; body: PNode): ControlFlowGraph =
  ## constructs a control flow graph for ``body``.
  var c = Con(code: @[], blocks: @[], owner: s)
  gen(c, body)
  genImplicitReturn(c)
  shallowCopy(result, c.code)
