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
## taken). Exhaustive case statements are translated
## so that the last branch is transformed into an 'else' branch.
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
    goto, fork, join, def, use
  Instr* = object
    n*: PNode
    case kind*: InstrKind
    of def, use: sym*: PSym
    of goto, fork, join: dest*: int

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
    forks: seq[TPosition]
    owner: PSym

proc debugInfo(info: TLineInfo): string =
  result = $info.line #info.toFilename & ":" & $info.line

proc codeListing(c: ControlFlowGraph, result: var string, start=0; last = -1) =
  # for debugging purposes
  # first iteration: compute all necessary labels:
  var jumpTargets = initIntSet()
  let last = if last < 0: c.len-1 else: min(last, c.len-1)
  for i in start..last:
    if c[i].kind in {goto, fork, join}:
      jumpTargets.incl(i+c[i].dest)
  var i = start
  while i <= last:
    if i in jumpTargets: result.add("L" & $i & ":\n")
    result.add "\t"
    result.add ($i & " " & $c[i].kind)
    result.add "\t"
    case c[i].kind
    of def, use:
      result.add c[i].sym.name.s
    of goto, fork, join:
      result.add "L"
      result.add c[i].dest+i
    result.add("\t#")
    result.add(debugInfo(c[i].n.info))
    result.add("\n")
    inc i
  if i in jumpTargets: result.add("L" & $i & ": End\n")
  # consider calling `asciitables.alignTable`

proc echoCfg*(c: ControlFlowGraph; start=0; last = -1) {.deprecated.} =
  ## echos the ControlFlowGraph for debugging purposes.
  var buf = ""
  codeListing(c, buf, start, last)
  when declared(echo):
    echo buf

proc forkI(c: var Con; n: PNode): TPosition =
  result = TPosition(c.code.len)
  c.code.add Instr(n: n, kind: fork, dest: 0)
  c.forks.add result

proc gotoI(c: var Con; n: PNode): TPosition =
  result = TPosition(c.code.len)
  c.code.add Instr(n: n, kind: goto, dest: 0)

#[

Design of join
==============

block:
  if cond: break
  def(x)

use(x)

Generates:

L0: fork L1
  join L0  # patched.
  goto Louter
L1:
  def x
  join L0
Louter:
  use x


block outer:
  while a:
    while b:
      if foo:
        if bar:
          break outer # --> we need to 'join' every pushed 'fork' here


This works and then our abstract interpretation needs to deal with 'fork'
differently. It really causes a split in execution. Two threads are
"spawned" and both need to reach the 'join L' instruction. Afterwards
the abstract interpretations are joined and execution resumes single
threaded.


Abstract Interpretation
-----------------------

proc interpret(pc, state, comesFrom): state =
  result = state
  # we need an explicit 'create' instruction (an explicit heap), in order
  # to deal with 'var x = create(); var y = x; var z = y; destroy(z)'
  while true:
    case pc
    of fork:
      let a = interpret(pc+1, result, pc)
      let b = interpret(forkTarget, result, pc)
      result = a ++ b # ++ is a union operation
      inc pc
    of join:
      if joinTarget == comesFrom: return result
      else: inc pc
    of use X:
      if not result.contains(x):
        error "variable not initialized " & x
      inc pc
    of def X:
      if not result.contains(x):
        result.incl X
      else:
        error "overwrite of variable causes memory leak " & x
      inc pc
    of destroy X:
      result.excl X

This is correct but still can lead to false positives:

proc p(cond: bool) =
  if cond:
    new(x)
  otherThings()
  if cond:
    destroy x

Is not a leak. We should find a way to model *data* flow, not just
control flow. One solution is to rewrite the 'if' without a fork
instruction. The unstructured aspect can now be easily dealt with
the 'goto' and 'join' instructions.

proc p(cond: bool) =
  L0: fork Lend
    new(x)
    # do not 'join' here!

  Lend:
    otherThings()
    join L0  # SKIP THIS FOR new(x) SOMEHOW
  destroy x
  join L0 # but here.



But if we follow 'goto Louter' we will never come to the join point.
We restore the bindings after popping pc from the stack then there
"no" problem?!


while cond:
  prelude()
  if not condB: break
  postlude()

--->
var setFlag = true
while cond and not setFlag:
  prelude()
  if not condB:
    setFlag = true   # BUT: Dependency
  if not setFlag:    # HERE
    postlude()

--->
var setFlag = true
while cond and not setFlag:
  prelude()
  if not condB:
    postlude()
    setFlag = true


-------------------------------------------------

while cond:
  prelude()
  if more:
    if not condB: break
    stuffHere()
  postlude()

-->
var setFlag = true
while cond and not setFlag:
  prelude()
  if more:
    if not condB:
      setFlag = false
    else:
      stuffHere()
      postlude()
  else:
    postlude()

This is getting complicated. Instead we keep the whole 'join' idea but
duplicate the 'join' instructions on breaks and return exits!

]#

proc joinI(c: var Con; fromFork: TPosition; n: PNode) =
  let dist = fromFork.int - c.code.len
  c.code.add Instr(n: n, kind: join, dest: dist)

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

when true:
  proc genWhile(c: var Con; n: PNode) =
    # We unroll every loop 3 times. We emulate 0, 1, 2 iterations
    # through the loop. We need to prove this is correct for our
    # purposes. But Herb Sutter claims it is. (Proof by authority.)
    #[
    while cond:
      body

    Becomes:

    if cond:
      body
      if cond:
        body
        if cond:
          body

    We still need to ensure 'break' resolves properly, so an AST to AST
    translation is impossible.

    So the code to generate is:

      cond
      fork L4  # F1
      body
      cond
      fork L5  # F2
      body
      cond
      fork L6  # F3
      body
    L6:
      join F3
    L5:
      join F2
    L4:
      join F1
    ]#
    if isTrue(n.sons[0]):
      # 'while true' is an idiom in Nim and so we produce
      # better code for it:
      for i in 0..2:
        withBlock(nil):
          c.gen(n.sons[1])
    else:
      let oldForksLen = c.forks.len
      var endings: array[3, TPosition]
      for i in 0..2:
        withBlock(nil):
          c.gen(n.sons[0])
          endings[i] = c.forkI(n)
          c.gen(n.sons[1])
      for i in countdown(endings.high, 0):
        let endPos = endings[i]
        c.patch(endPos)
        c.joinI(c.forks.pop(), n)
      doAssert(c.forks.len == oldForksLen)

else:

  proc genWhile(c: var Con; n: PNode) =
    # L1:
    #   cond, tmp
    #   fork tmp, L2
    #   body
    #   jmp L1
    # L2:
    let oldForksLen = c.forks.len
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
    setLen(c.forks, oldForksLen)

proc genBlock(c: var Con; n: PNode) =
  withBlock(n.sons[0].sym):
    c.gen(n.sons[1])

proc genJoins(c: var Con; n: PNode) =
  for i in countdown(c.forks.high, 0): joinI(c, c.forks[i], n)

proc genBreak(c: var Con; n: PNode) =
  genJoins(c, n)
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

template forkT(n, body) =
  let oldLen = c.forks.len
  let L1 = c.forkI(n)
  body
  c.patch(L1)
  c.joinI(L1, n)
  setLen(c.forks, oldLen)

proc genIf(c: var Con, n: PNode) =
  #[

  if cond:
    A
  elif condB:
    B
  elif condC:
    C
  else:
    D

  cond
  fork L1
  A
  goto Lend
  L1:
    condB
    fork L2
    B
    goto Lend2
  L2:
    condC
    fork L3
    C
    goto Lend3
  L3:
    D
    goto Lend3 # not eliminated to simplify the join generation
  Lend3:
    join F3
  Lend2:
    join F2
  Lend:
    join F1

  ]#
  let oldLen = c.forks.len
  var endings: seq[TPosition] = @[]
  for i in countup(0, len(n) - 1):
    var it = n.sons[i]
    c.gen(it.sons[0])
    if it.len == 2:
      let elsePos = forkI(c, it[1])
      c.gen(it.sons[1])
      endings.add(c.gotoI(it.sons[1]))
      c.patch(elsePos)
  for i in countdown(endings.high, 0):
    let endPos = endings[i]
    c.patch(endPos)
    c.joinI(c.forks.pop(), n)
  doAssert(c.forks.len == oldLen)

proc genAndOr(c: var Con; n: PNode) =
  #   asgn dest, a
  #   fork L1
  #   asgn dest, b
  # L1:
  #   join F1
  c.gen(n.sons[1])
  forkT(n):
    c.gen(n.sons[2])

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
  let isExhaustive = skipTypes(n.sons[0].typ,
    abstractVarRange-{tyTypeDesc}).kind notin {tyFloat..tyFloat128, tyString}

  var endings: seq[TPosition] = @[]
  let oldLen = c.forks.len
  c.gen(n.sons[0])
  for i in 1 ..< n.len:
    let it = n.sons[i]
    if it.len == 1:
      c.gen(it.sons[0])
    elif i == n.len-1 and isExhaustive:
      # treat the last branch as 'else' if this is an exhaustive case statement.
      c.gen(it.lastSon)
    else:
      let elsePos = c.forkI(it.lastSon)
      c.gen(it.lastSon)
      endings.add(c.gotoI(it.lastSon))
      c.patch(elsePos)
  for i in countdown(endings.high, 0):
    let endPos = endings[i]
    c.patch(endPos)
    c.joinI(c.forks.pop(), n)
  doAssert(c.forks.len == oldLen)

proc genTry(c: var Con; n: PNode) =
  let oldLen = c.forks.len
  var endings: seq[TPosition] = @[]
  inc c.inTryStmt
  let oldFixups = c.tryStmtFixups.len

  #let elsePos = c.forkI(n)
  c.gen(n.sons[0])
  dec c.inTryStmt
  for i in oldFixups..c.tryStmtFixups.high:
    let f = c.tryStmtFixups[i]
    c.patch(f)
    # we also need to produce join instructions
    # for the 'fork' that might preceed the goto instruction
    if f.int-1 >= 0 and c.code[f.int-1].kind == fork:
      c.joinI(TPosition(f.int-1), n)

  setLen(c.tryStmtFixups, oldFixups)

  #c.patch(elsePos)
  for i in 1 ..< n.len:
    let it = n.sons[i]
    if it.kind != nkFinally:
      var blen = len(it)
      let endExcept = c.forkI(it)
      c.gen(it.lastSon)
      endings.add(c.gotoI(it))
      c.patch(endExcept)
  for i in countdown(endings.high, 0):
    let endPos = endings[i]
    c.patch(endPos)
    c.joinI(c.forks.pop(), n)

  # join the 'elsePos' forkI instruction:
  #c.joinI(c.forks.pop(), n)

  let fin = lastSon(n)
  if fin.kind == nkFinally:
    c.gen(fin.sons[0])
  doAssert(c.forks.len == oldLen)

template genNoReturn(c: var Con; n: PNode) =
  # leave the graph
  c.code.add Instr(n: n, kind: goto, dest: high(int) - c.code.len)

proc genRaise(c: var Con; n: PNode) =
  genJoins(c, n)
  gen(c, n.sons[0])
  if c.inTryStmt > 0:
    c.tryStmtFixups.add c.gotoI(n)
  else:
    genNoReturn(c, n)

proc genImplicitReturn(c: var Con) =
  if c.owner.kind in {skProc, skFunc, skMethod, skIterator, skConverter} and resultPos < c.owner.ast.len:
    gen(c, c.owner.ast.sons[resultPos])

proc genReturn(c: var Con; n: PNode) =
  genJoins(c, n)
  if n.sons[0].kind != nkEmpty:
    gen(c, n.sons[0])
  else:
    genImplicitReturn(c)
  genNoReturn(c, n)

const
  InterestingSyms = {skVar, skResult, skLet, skParam}

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

proc canRaise(fn: PNode): bool =
  const magicsThatCanRaise = {
    mNone, mSlurp, mStaticExec, mParseExprToAst, mParseStmtToAst}
  if fn.kind == nkSym and fn.sym.magic notin magicsThatCanRaise:
    result = false
  else:
    result = true

proc genCall(c: var Con; n: PNode) =
  gen(c, n[0])
  var t = n[0].typ
  if t != nil: t = t.skipTypes(abstractInst)
  inc c.inCall
  for i in 1..<n.len:
    gen(c, n[i])
    when false:
      if t != nil and i < t.len and t.sons[i].kind == tyVar:
        # This is wrong! Pass by var is a 'might def', not a 'must def'
        # like the other defs we emit. This is not good enough for a move
        # optimizer.
        genDef(c, n[i])
  # every call can potentially raise:
  if c.inTryStmt > 0 and canRaise(n[0]):
    # we generate the instruction sequence:
    # fork L1
    # goto exceptionHandler (except or finally)
    # L1:
    # join F1
    let endGoto = c.forkI(n)
    c.tryStmtFixups.add c.gotoI(n)
    c.patch(endGoto)
    c.joinI(c.forks.pop(), n)
  dec c.inCall

proc genMagic(c: var Con; n: PNode; m: TMagic) =
  case m
  of mAnd, mOr: c.genAndOr(n)
  of mNew, mNewFinalize:
    genDef(c, n[1])
    for i in 2..<n.len: gen(c, n[i])
  else:
    genCall(c, n)

proc genVarSection(c: var Con; n: PNode) =
  for a in n:
    if a.kind == nkCommentStmt:
      discard
    elif a.kind == nkVarTuple:
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
      if sfNoReturn in n.sons[0].sym.flags:
        genNoReturn(c, n)
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

proc constructCfg*(s: PSym; body: PNode): ControlFlowGraph =
  ## constructs a control flow graph for ``body``.
  var c = Con(code: @[], blocks: @[], owner: s)
  gen(c, body)
  genImplicitReturn(c)
  shallowCopy(result, c.code)
