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

import ast, types, intsets, lineinfos, renderer
import std/private/asciitables

from patterns import sameTrees

type
  InstrKind* = enum
    goto, fork, def, use
  Instr* = object
    n*: PNode # contains the def/use location.
    case kind*: InstrKind
    of goto, fork: dest*: int
    else: discard

  ControlFlowGraph* = seq[Instr]

  TPosition = distinct int

  TBlock = object
    case isTryBlock: bool
    of false:
      label: PSym
      breakFixups: seq[(TPosition, seq[PNode])] #Contains the gotos for the breaks along with their pending finales
    of true:
      finale: PNode
      raiseFixups: seq[TPosition] #Contains the gotos for the raises

  Con = object
    code: ControlFlowGraph
    inTryStmt: int
    blocks: seq[TBlock]
    owner: PSym

proc codeListing(c: ControlFlowGraph, start = 0; last = -1): string =
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
    result.add ($i & " " & $c[i].kind)
    result.add "\t"
    case c[i].kind
    of def, use:
      result.add renderTree(c[i].n)
    of goto, fork:
      result.add "L"
      result.addInt c[i].dest+i
    result.add("\t#")
    result.add($c[i].n.info.line)
    result.add("\n")
    inc i
  if i in jumpTargets: result.add("L" & $i & ": End\n")

proc echoCfg*(c: ControlFlowGraph; start = 0; last = -1) {.deprecated.} =
  ## echos the ControlFlowGraph for debugging purposes.
  echo codeListing(c, start, last).alignTable

proc forkI(c: var Con; n: PNode): TPosition =
  result = TPosition(c.code.len)
  c.code.add Instr(n: n, kind: fork, dest: 0)

proc gotoI(c: var Con; n: PNode): TPosition =
  result = TPosition(c.code.len)
  c.code.add Instr(n: n, kind: goto, dest: 0)

#[

Join is no more
===============
Instead of generating join instructions we adapt our traversal of the CFG.

When encountering a fork we split into two paths, we follow the path
starting at "pc + 1" until it encounters the joinpoint: "pc + forkInstr.dest".
If we encounter gotos that would jump further than the current joinpoint,
as can happen with gotos generated by unstructured controlflow such as break, raise or return,
we simply suspend following the current path, and follow the other path until the new joinpoint
which is simply the instruction pointer returned to us by the now suspended path.
If the path we are following now, also encounters a goto that exceeds the joinpoint
we repeat the process; suspending the current path and evaluating the other one with a new joinpoint.
If we eventually reach a common joinpoint we join the two paths.
This new "ping-pong" approach has the obvious advantage of not requiring join instructions, as such
cutting down on the CFG size but is also mandatory for correctly handling complicated cases
of unstructured controlflow.


Design of join
==============

block:
  if cond: break
  def(x)

use(x)

Generates:

L0: fork lab1
  join L0  # patched.
  goto Louter
lab1:
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

proc genLabel(c: Con): TPosition = TPosition(c.code.len)

template checkedDistance(dist): int =
  doAssert low(int) div 2 + 1 < dist and dist < high(int) div 2
  dist

proc jmpBack(c: var Con, n: PNode, p = TPosition(0)) =
  c.code.add Instr(n: n, kind: goto, dest: checkedDistance(p.int - c.code.len))

proc patch(c: var Con, p: TPosition) =
  # patch with current index
  c.code[p.int].dest = checkedDistance(c.code.len - p.int)

proc gen(c: var Con; n: PNode)

proc popBlock(c: var Con; oldLen: int) =
  var exits: seq[TPosition]
  exits.add c.gotoI(newNode(nkEmpty))
  for f in c.blocks[oldLen].breakFixups:
    c.patch(f[0])
    for finale in f[1]:
      c.gen(finale)
    exits.add c.gotoI(newNode(nkEmpty))
  for e in exits:
    c.patch e
  c.blocks.setLen(oldLen)

template withBlock(labl: PSym; body: untyped) =
  let oldLen = c.blocks.len
  c.blocks.add TBlock(isTryBlock: false, label: labl)
  body
  popBlock(c, oldLen)

proc isTrue(n: PNode): bool =
  n.kind == nkSym and n.sym.kind == skEnumField and n.sym.position != 0 or
    n.kind == nkIntLit and n.intVal != 0

when true:
  proc genWhile(c: var Con; n: PNode) =
    # We unroll every loop 3 times. We emulate 0, 1, 2 iterations
    # through the loop. We need to prove this is correct for our
    # purposes. But Herb Sutter claims it is. (Proof by authority.)
    #[
    while cond:
      body

    Becomes:

    block:
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
    if isTrue(n[0]):
      # 'while true' is an idiom in Nim and so we produce
      # better code for it:
      withBlock(nil):
        for i in 0..2:
          c.gen(n[1])
    else:
      withBlock(nil):
        var endings: array[3, TPosition]
        for i in 0..2:
          c.gen(n[0])
          endings[i] = c.forkI(n)
          c.gen(n[1])
        for i in countdown(endings.high, 0):
          c.patch(endings[i])

else:
  proc genWhile(c: var Con; n: PNode) =
    # lab1:
    #   cond, tmp
    #   fork tmp, lab2
    #   body
    #   jmp lab1
    # lab2:
    let lab1 = c.genLabel
    withBlock(nil):
      if isTrue(n[0]):
        c.gen(n[1])
        c.jmpBack(n, lab1)
      else:
        c.gen(n[0])
        forkT(n):
          c.gen(n[1])
          c.jmpBack(n, lab1)

template forkT(n, body) =
  let lab1 = c.forkI(n)
  body
  c.patch(lab1)

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
  fork lab1
  A
  goto Lend
  lab1:
    condB
    fork lab2
    B
    goto Lend2
  lab2:
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
  var endings: seq[TPosition] = @[]
  for i in 0..<n.len:
    let it = n[i]
    c.gen(it[0])
    if it.len == 2:
      forkT(it[1]):
        c.gen(it[1])
        endings.add c.gotoI(it[1])
  for i in countdown(endings.high, 0):
    c.patch(endings[i])

proc genAndOr(c: var Con; n: PNode) =
  #   asgn dest, a
  #   fork lab1
  #   asgn dest, b
  # lab1:
  #   join F1
  c.gen(n[1])
  forkT(n):
    c.gen(n[2])

proc genCase(c: var Con; n: PNode) =
  #  if (!expr1) goto lab1;
  #    thenPart
  #    goto LEnd
  #  lab1:
  #  if (!expr2) goto lab2;
  #    thenPart2
  #    goto LEnd
  #  lab2:
  #    elsePart
  #  Lend:
  let isExhaustive = skipTypes(n[0].typ,
    abstractVarRange-{tyTypeDesc}).kind notin {tyFloat..tyFloat128, tyString}

  var endings: seq[TPosition] = @[]
  c.gen(n[0])
  for i in 1..<n.len:
    let it = n[i]
    if it.len == 1 or (i == n.len-1 and isExhaustive):
      # treat the last branch as 'else' if this is an exhaustive case statement.
      c.gen(it.lastSon)
    else:
      forkT(it.lastSon):
        c.gen(it.lastSon)
        endings.add c.gotoI(it.lastSon)
  for i in countdown(endings.high, 0):
    let endPos = endings[i]
    c.patch(endPos)

proc genBlock(c: var Con; n: PNode) =
  withBlock(n[0].sym):
    c.gen(n[1])

proc genBreakOrRaiseAux(c: var Con, i: int, n: PNode) =
  let lab1 = c.gotoI(n)
  if c.blocks[i].isTryBlock:
    c.blocks[i].raiseFixups.add lab1
  else:
    var trailingFinales: seq[PNode]
    if c.inTryStmt > 0: #Ok, we are in a try, lets see which (if any) try's we break out from:
      for b in countdown(c.blocks.high, i):
        if c.blocks[b].isTryBlock:
          trailingFinales.add c.blocks[b].finale

    c.blocks[i].breakFixups.add (lab1, trailingFinales)

proc genBreak(c: var Con; n: PNode) =
  if n[0].kind == nkSym:
    for i in countdown(c.blocks.high, 0):
      if not c.blocks[i].isTryBlock and c.blocks[i].label == n[0].sym:
        genBreakOrRaiseAux(c, i, n)
        return
    #globalError(n.info, "VM problem: cannot find 'break' target")
  else:
    for i in countdown(c.blocks.high, 0):
      if not c.blocks[i].isTryBlock:
        genBreakOrRaiseAux(c, i, n)
        return

proc genTry(c: var Con; n: PNode) =
  var endings: seq[TPosition] = @[]

  let oldLen = c.blocks.len
  c.blocks.add TBlock(isTryBlock: true, finale: if n[^1].kind == nkFinally: n[^1] else: newNode(nkEmpty))

  inc c.inTryStmt
  c.gen(n[0])
  dec c.inTryStmt

  for f in c.blocks[oldLen].raiseFixups:
    c.patch(f)

  c.blocks.setLen oldLen

  for i in 1..<n.len:
    let it = n[i]
    if it.kind != nkFinally:
      forkT(it):
        c.gen(it.lastSon)
        endings.add c.gotoI(it)
  for i in countdown(endings.high, 0):
    c.patch(endings[i])

  let fin = lastSon(n)
  if fin.kind == nkFinally:
    c.gen(fin[0])

template genNoReturn(c: var Con; n: PNode) =
  # leave the graph
  c.code.add Instr(n: n, kind: goto, dest: high(int) - c.code.len)

proc genRaise(c: var Con; n: PNode) =
  gen(c, n[0])
  if c.inTryStmt > 0:
    for i in countdown(c.blocks.high, 0):
      if c.blocks[i].isTryBlock:
        genBreakOrRaiseAux(c, i, n)
        return
    assert false #Unreachable
  else:
    genNoReturn(c, n)

proc genImplicitReturn(c: var Con) =
  if c.owner.kind in {skProc, skFunc, skMethod, skIterator, skConverter} and resultPos < c.owner.ast.len:
    gen(c, c.owner.ast[resultPos])

proc genReturn(c: var Con; n: PNode) =
  if n[0].kind != nkEmpty:
    gen(c, n[0])
  else:
    genImplicitReturn(c)
  genBreakOrRaiseAux(c, 0, n)

const
  InterestingSyms = {skVar, skResult, skLet, skParam, skForVar, skTemp}
  PathKinds0 = {nkDotExpr, nkCheckedFieldExpr,
                nkBracketExpr, nkDerefExpr, nkHiddenDeref,
                nkAddr, nkHiddenAddr,
                nkObjDownConv, nkObjUpConv}
  PathKinds1 = {nkHiddenStdConv, nkHiddenSubConv}

proc skipConvDfa*(n: PNode): PNode =
  result = n
  while true:
    case result.kind
    of nkObjDownConv, nkObjUpConv:
      result = result[0]
    of PathKinds1:
      result = result[1]
    else: break

type AliasKind* = enum
  yes, no, maybe

from trees import exprStructuralEquivalent

proc aliases*(obj, field: PNode): AliasKind =
  # obj -> field:
  # x -> x: true
  # x -> x.f: true
  # x.f -> x: false
  # x.f -> x.f: true
  # x.f -> x.v: false
  # x -> x[0]: true
  # x[0] -> x: false
  # x[0] -> x[0]: true
  # x[0] -> x[1]: false
  # x -> x[i]: true
  # x[i] -> x: false
  # x[i] -> x[i]: MAYBE Further analysis could make this return true when i is a runtime-constant
  # x[i] -> x[j]: MAYBE also returns MAYBE if only one of i or j is a compiletime-constant
  var n = field
  var obj = obj
  var objImportantNodeStack: seq[PNode]
  while true:
    case obj.kind
    of PathKinds0 - {nkDotExpr, nkCheckedFieldExpr, nkBracketExpr}:
      obj = obj[0]
    of PathKinds1:
      obj = obj[1]
    of nkDotExpr, nkCheckedFieldExpr, nkBracketExpr:
      objImportantNodeStack.add obj# [1]
      obj = obj[0]
    of nkSym:
      objImportantNodeStack.add obj; break
    else: return no
  var fieldImportantNodeStack: seq[PNode]
  while true:
    case n.kind
    of PathKinds0 - {nkDotExpr, nkCheckedFieldExpr, nkBracketExpr}:
      n = n[0]
    of nkDotExpr, nkCheckedFieldExpr, nkBracketExpr:
      fieldImportantNodeStack.add n# [1]
      n = n[0]
    of PathKinds1:
      n = n[1]
    of nkSym:
      fieldImportantNodeStack.add n; break
    else: return no

  if fieldImportantNodeStack.len < objImportantNodeStack.len: return no

  result = yes
  for i in 1..objImportantNodeStack.len:
    template currFieldPath: untyped = fieldImportantNodeStack[^i]
    template currObjPath: untyped = objImportantNodeStack[^i]

    if currFieldPath.kind != currObjPath.kind:
      return no

    case currFieldPath.kind
    of nkSym:
      if currFieldPath.sym != currObjPath.sym: return no
    of nkDotExpr, nkCheckedFieldExpr:
      if currFieldPath[1].sym != currObjPath[1].sym: return no
    of nkBracketExpr:
      if currFieldPath[1].kind in nkLiterals and currObjPath[1].kind in nkLiterals:
        if not exprStructuralEquivalent(currFieldPath[1], currObjPath[1]):
          return no
      else:
        result = maybe
    else: assert false, "unreachable"

type InstrTargetKind* = enum
  None, Full, Partial

proc instrTargets*(insloc, loc: PNode): InstrTargetKind =
  if insloc.aliases(loc) == yes:
    Full    # x -> x; x -> x.f
  elif insloc.aliases(loc) == maybe:
    Partial # XXX?
  elif loc.aliases(insloc) != no:
    Partial # x.f -> x
  else: None

proc isAnalysableFieldAccess*(orig: PNode; owner: PSym): bool =
  var n = orig
  while true:
    case n.kind
    of PathKinds0 - {nkBracketExpr, nkHiddenDeref, nkDerefExpr}:
      n = n[0]
    of PathKinds1:
      n = n[1]
    of nkBracketExpr:
      # in a[i] the 'i' must be known
      assert n.len > 1
      n = n[0]
    of nkHiddenDeref, nkDerefExpr:
      # We "own" sinkparam[].loc but not ourVar[].location as it is a nasty
      # pointer indirection.
      # bug #14159, we cannot reason about sinkParam[].location as it can
      # still be shared for tyRef.
      n = n[0]
      return n.kind == nkSym and n.sym.owner == owner and
         (n.sym.typ.skipTypes(abstractInst-{tyOwned}).kind in {tyOwned})
    else: break
  # XXX Allow closure deref operations here if we know
  # the owner controlled the closure allocation?
  result = n.kind == nkSym and n.sym.owner == owner and
    {sfGlobal, sfThread, sfCursor} * n.sym.flags == {} and
    (n.sym.kind != skParam or isSinkParam(n.sym)) # or n.sym.typ.kind == tyVar)
  # Note: There is a different move analyzer possible that checks for
  # consume(param.key); param.key = newValue  for all paths. Then code like
  #
  #   let splited = split(move self.root, x)
  #   self.root = merge(splited.lower, splited.greater)
  #
  # could be written without the ``move self.root``. However, this would be
  # wrong! Then the write barrier for the ``self.root`` assignment would
  # free the old data and all is lost! Lesson: Don't be too smart, trust the
  # lower level C++ optimizer to specialize this code.

proc skipTrivials(c: var Con, n: PNode): PNode =
  result = n
  while true:
    case result.kind
    of PathKinds0 - {nkBracketExpr}:
      result = result[0]
    of nkBracketExpr:
      gen(c, result[1])
      result = result[0]
    of PathKinds1:
      result = result[1]
    else: break

proc genUse(c: var Con; orig: PNode) =
  let n = c.skipTrivials(orig)

  if n.kind == nkSym and n.sym.kind in InterestingSyms:
    c.code.add Instr(n: orig, kind: use)
  elif n.kind in nkCallKinds:
    gen(c, n)

proc genDef(c: var Con; orig: PNode) =
  let n = c.skipTrivials(orig)

  if n.kind == nkSym and n.sym.kind in InterestingSyms:
    c.code.add Instr(n: orig, kind: def)

proc genCall(c: var Con; n: PNode) =
  gen(c, n[0])
  var t = n[0].typ
  if t != nil: t = t.skipTypes(abstractInst)
  for i in 1..<n.len:
    gen(c, n[i])
    when false:
      if t != nil and i < t.len and t[i].kind == tyOut:
        # Pass by 'out' is a 'must def'. Good enough for a move optimizer.
        genDef(c, n[i])
  # every call can potentially raise:
  if c.inTryStmt > 0 and canRaiseConservative(n[0]):
    # we generate the instruction sequence:
    # fork lab1
    # goto exceptionHandler (except or finally)
    # lab1:
    # join F1
    forkT(n):
      for i in countdown(c.blocks.high, 0):
        if c.blocks[i].isTryBlock:
          genBreakOrRaiseAux(c, i, n)
          break

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
      for i in 0..<a.len-2: genDef(c, a[i])
    else:
      gen(c, a.lastSon)
      if a.lastSon.kind != nkEmpty:
        genDef(c, a[0])

proc gen(c: var Con; n: PNode) =
  case n.kind
  of nkSym: genUse(c, n)
  of nkCallKinds:
    if n[0].kind == nkSym:
      let s = n[0].sym
      if s.magic != mNone:
        genMagic(c, n, s.magic)
      else:
        genCall(c, n)
      if sfNoReturn in n[0].sym.flags:
        genNoReturn(c, n)
    else:
      genCall(c, n)
  of nkCharLit..nkNilLit: discard
  of nkAsgn, nkFastAsgn:
    gen(c, n[1])
    # watch out: 'obj[i].f2 = value' sets 'f2' but
    # "uses" 'i'. But we are only talking about builtin array indexing so
    # it doesn't matter and 'x = 34' is NOT a usage of 'x'.
    genDef(c, n[0])
  of PathKinds0 - {nkObjDownConv, nkObjUpConv}:
    genUse(c, n)
  of nkIfStmt, nkIfExpr: genIf(c, n)
  of nkWhenStmt:
    # This is "when nimvm" node. Chose the first branch.
    gen(c, n[0][1])
  of nkCaseStmt: genCase(c, n)
  of nkWhileStmt: genWhile(c, n)
  of nkBlockExpr, nkBlockStmt: genBlock(c, n)
  of nkReturnStmt: genReturn(c, n)
  of nkRaiseStmt: genRaise(c, n)
  of nkBreakStmt: genBreak(c, n)
  of nkTryStmt, nkHiddenTryStmt: genTry(c, n)
  of nkStmtList, nkStmtListExpr, nkChckRangeF, nkChckRange64, nkChckRange,
     nkBracket, nkCurly, nkPar, nkTupleConstr, nkClosure, nkObjConstr, nkYieldStmt:
    for x in n: gen(c, x)
  of nkPragmaBlock: gen(c, n.lastSon)
  of nkDiscardStmt, nkObjDownConv, nkObjUpConv, nkStringToCString, nkCStringToString:
    gen(c, n[0])
  of nkConv, nkExprColonExpr, nkExprEqExpr, nkCast, PathKinds1:
    gen(c, n[1])
  of nkVarSection, nkLetSection: genVarSection(c, n)
  of nkDefer: doAssert false, "dfa construction pass requires the elimination of 'defer'"
  else: discard

proc constructCfg*(s: PSym; body: PNode): ControlFlowGraph =
  ## constructs a control flow graph for ``body``.
  var c = Con(code: @[], blocks: @[], owner: s)
  withBlock(s):
    gen(c, body)
    genImplicitReturn(c)
  when defined(gcArc) or defined(gcOrc):
    result = c.code # will move
  else:
    shallowCopy(result, c.code)
