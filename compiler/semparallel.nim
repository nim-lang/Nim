#
#
#           The Nimrod Compiler
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Semantic checking for 'parallel'.

# - slices should become "nocopy" to openArray (+)
#   - need to perform bound checks (+)
#
# - parallel needs to insert a barrier (+)
# - passed arguments need to be ensured to be "const"
#   - what about 'f(a)'? --> f shouldn't have side effects anyway
# - passed arrays need to be ensured not to alias
# - passed slices need to be ensured to be disjoint (+)
# - output slices need special logic

import lowerings, guards, sempass2

discard """

one major problem:
  spawn f(a[i])
  inc i
  spawn f(a[i])
is valid, but
  spawn f(a[i])
  spawn f(a[i])
  inc i
is not! However, 
  spawn f(a[i])
  if guard: inc i
  spawn f(a[i])
is not valid either! --> We need a flow dependent analysis here.

However:
  while foo:
    spawn f(a[i])
    inc i
    spawn f(a[i])

Is not valid either! --> We should really restrict 'inc' to loop endings?

The heuristic that we implement here (that has no false positives) is: Usage
of 'i' in a slice *after* we determined the stride is invalid!
"""

type
  TDirection = enum
    ascending, descending
  MonotonicVar = object
    v: PSym
    lower, upper, stride: PNode
    dir: TDirection
    blacklisted: bool     # blacklisted variables that are not monotonic
  AnalysisCtx = object
    locals: seq[MonotonicVar]
    slices: seq[tuple[x,a,b: PNode, spawnId: int, inLoop: bool]]
    guards: TModel      # nested guards
    args: seq[PSym]     # args must be deeply immutable
    spawns: int         # we can check that at last 1 spawn is used in
                        # the 'parallel' section
    currentSpawnId: int
    inLoop: int

let opSlice = createMagic("slice", mSlice)

proc initAnalysisCtx(): AnalysisCtx =
  result.locals = @[]
  result.slices = @[]
  result.args = @[]
  result.guards = @[]

proc getSlot(c: var AnalysisCtx; s: PSym): ptr MonotonicVar =
  var L = c.locals.len
  for i in 0.. <L:
    if c.locals[i].v == s: return addr(c.locals[i])
  c.locals.setLen(L+1)
  c.locals[L].v = s
  return addr(c.locals[L])

proc getRoot(n: PNode): PSym =
  ## ``getRoot`` takes a *path* ``n``. A path is an lvalue expression
  ## like ``obj.x[i].y``. The *root* of a path is the symbol that can be
  ## determined as the owner; ``obj`` in the example.
  case n.kind
  of nkSym:
    if n.sym.kind in {skVar, skResult, skTemp, skLet, skForVar}:
      result = n.sym
  of nkDotExpr, nkBracketExpr, nkHiddenDeref, nkDerefExpr,
      nkObjUpConv, nkObjDownConv, nkCheckedFieldExpr:
    result = getRoot(n.sons[0])
  of nkHiddenStdConv, nkHiddenSubConv, nkConv:
    result = getRoot(n.sons[1])
  of nkCallKinds:
    if getMagic(n) == mSlice: result = getRoot(n.sons[1])
  else: discard

proc gatherArgs(c: var AnalysisCtx; n: PNode) =
  for i in 0.. <n.safeLen:
    let root = getRoot n[i]
    if root != nil:
      block addRoot:
        for r in items(c.args):
          if r == root: break addRoot
        c.args.add root
    gatherArgs(c, n[i])

proc isLocal(s: PSym): bool = 
  s.kind in {skResult, skTemp, skForVar, skVar, skLet} and
        {sfAddrTaken, sfGlobal} * s.flags == {}

proc checkLocal(c: var AnalysisCtx; n: PNode) =
  if n.kind == nkSym and isLocal(n.sym):
    let slot = c.getSlot(n[1].sym)
    if slot.stride != nil:
      localError(n.info, "invalid usage of counter after increment")
  else:
    for i in 0 .. <n.safeLen: checkLocal(c, n.sons[i])

proc checkLe(c: AnalysisCtx; a, b: PNode) =
  case proveLe(c.guards, a, b)
  of impUnkown:
    localError(n.info, "cannot prove: " & a.renderTree & " <= " & b.renderTree)
  of impYes: discard
  of impNo:
    localError(n.info, "can prove: " & a.renderTree & " > " & b.renderTree)

proc checkBounds(c: AnalysisCtx; arr, idx: PNode) =
  checkLe(c, arr.lowBound, idx)
  checkLe(c, idx, arr.highBound)

proc addLowerBoundAsFacts(c: var AnalysisCtx) =
  for v in c.locals:
    if not v.blacklisted:
      c.guards.addFactLe(v.lower, newSymNode(v.v))

proc addSlice(c: var AnalysisCtx; n: PNode; x, le, ri: int) =
  checkLocal(c, n)
  let le = n.sons[le]
  let ri = n.sons[ri]
  let x = n.sons[x]
  # perform static bounds checking here; and not later!
  let oldState = c.guards.len
  addLowerBoundAsFacts(c)
  c.checkBounds(x, le)
  c.checkBounds(x, ri)
  c.guards.setLen(oldState)
  c.slices.add((x, le, ri, c.currentSpawnId, c.inLoop > 0))

template `?`(x): expr = x.renderTree

proc overlap(m: TModel; x,y,c,d: PNode) =
  #  X..Y and C..D overlap iff (X <= D and Y >= C)
  case proveLe(m, x, d)
  of impUnkown:
    localError(x.info,
      "cannot prove: $# > $#; required for $#..$# disjoint from $#..$#" %
        [?x, ?d, ?x, ?y, ?c, ?d])
  of impYes:
    case proveLe(m, y, c)
    of impUnknown:
      localError(x.info,
        "cannot prove: $# > $#; required for $#..$# disjoint from $#..$#" %
          [?y, ?d, ?x, ?y, ?c, ?d])
    of impYes:
      localError(x.info, "$#..$# not disjoint from $#..$#" % [?x, ?y, ?c, ?d])
    of impNo: discard
  of impNo: discard

proc stride(c: AnalysisCtx; n: PNode): BiggestInt =
  # note: 0 if it cannot be determined is just right because then
  # we analyse 'i..i' and 'i+0 .. i+0' and these are not disjoint!
  if n.kind == nkSym and isLocal(n.sym):
    let slot = c.getSlot(n[1].sym)
    if slot.stride != nil:
      result = slot.stride.intVal
  else:
    for i in 0 .. <n.safeLen: inc(result, stride(c, n.sons[i]))

proc checkSlicesAreDisjoint(c: var AnalysisCtx) =
  # this is the only thing that we need to perform after we have traversed
  # the whole tree so that the strides are available.
  # First we need to add all the computed lower bounds:
  addLowerBoundAsFacts(c)
  # Every slice used in a loop needs to be disjoint with itself:
  for x,a,b,id,inLoop in items(c.slices):
    if inLoop: overlap(c.guards, a,b, a+@c.stride(a), b+@c.stride(b))
  # Another tricky example is:
  #   while true:
  #     spawn f(a[i])
  #     spawn f(a[i+1])
  #     inc i  # inc i, 2  would be correct here
  #
  # Or even worse:
  #   while true:
  #     spawn f(a[i+1 .. i+3])
  #     spawn f(a[i+4 .. i+5])
  #     inc i, 4
  # Prove that i*k*stride + 3 != i*k'*stride + 5
  # For the correct example this amounts to
  #   i*k*2 != i*k'*2 + 1
  # which is true.
  # For now, we don't try to prove things like that at all, even though it'd
  # be feasible for many useful examples. Instead we attach the slice to
  # a spawn and if the attached spawns differ, we bail out:
  for i in 0 .. high(c.slices):
    for j in 0 .. high(c.slices):
      let x = c.slices[i]
      let y = c.slices[j]
      if i != j and x.spawnId != y.spawnId and guards.sameTree(x.x, y.x):
        if not x.inLoop and not y.inLoop:
          overlap(c.guards, x.a, x.b, y.a, y.b)
        else:
          # ah I cannot resists the temptation and add another sweet heuristic:
          # if both slices have the form (i+c)..(i+c)  and (i+d)..(i+d) we
          # check they are disjoint and c <= stride and d <= stride:
          # XXX
          localError(x.x.info, "cannot prove $#..$# disjoint from $#..$#" %
            [?x.a, ?x.b, ?y.a, ?y.b])

proc analyse(c: var AnalysisCtx; n: PNode)

proc analyseSons(c: var AnalysisCtx; n: PNode) =
  for i in 0 .. <safeLen(n): analyse(c, n[i])

proc min(a, b: PNode): PNode =
  if a.isNil: result = b
  elif a.intVal < b.intVal: result = a
  else: result = b

proc analyseCall(c: var AnalysisCtx; n: PNode; op: PSym) =
  if op.magic == mSpawn:
    inc c.spawns
    let oldSpawnId = c.currentSpawnId
    c.currentSpawnId = c.spawns
    gatherArgs(c, n[1])
    analyseSons(c, n)
    c.currentSpawnId = oldSpawnId
  elif op.magic == mInc or (op.name.s == "+=" and sfSystemModule in op.owner.flags):
    if n[1].kind == nkSym and n[1].isLocal:
      let incr = n[1].skipConv
      if incr.kind in {nkCharLit..nkUInt32Lit} and incr.intVal > 0:
        let slot = c.getSlot(n[1].sym)
        slot.stride = min(slot.stride, incr)
    analyseSons(c, n)
  elif op.name.s == "[]" and sfSystemModule in op.owner.flags:
    c.addSlice(n, 1, 2, 3)
    analyseSons(c, n)
  elif op.name.s == "[]=" and sfSystemModule in op.owner.flags:
    c.addSlice(n, 1, 2, 3)
    analyseSons(c, n)
  else:
    analyseSons(c, n)

proc analyseCase(c: var AnalysisCtx; n: PNode) =
  analyse(c, n.sons[0])
  #let oldState = c.locals.len
  let oldFacts = c.guards.len
  for i in 1.. <n.len:
    let branch = n.sons[i]
    #setLen(c.locals, oldState)
    setLen(c.guards, oldFacts)
    addCaseBranchFacts(c.guards, n, i)
    for i in 0 .. <branch.len:
      analyse(c, branch.sons[i])
  #setLen(c.locals, oldState)
  setLen(c.guards, oldFacts)

proc analyseIf(c: var AnalysisCtx; n: PNode) =
  analyse(c, n.sons[0].sons[0])
  let oldFacts = c.guards.len
  addFact(c.guards, n.sons[0].sons[0])
  #let oldState = c.locals.len

  analyse(c, n.sons[0].sons[1])
  for i in 1.. <n.len:
    let branch = n.sons[i]
    setLen(c.guards, oldFacts)
    for j in 0..i-1:
      addFactNeg(c.guards, n.sons[j].sons[0])
    if branch.len > 1:
      addFact(c.guards, branch.sons[0])
    #setLen(c.locals, oldState)
    for i in 0 .. <branch.len:
      analyse(c, branch.sons[i])
  #setLen(c.locals, oldState)
  setLen(c.guards, oldFacts)

proc analyse(c: var AnalysisCtx; n: PNode) =
  case n.kind
  of nkAsgn, nkFastAsgn:
    # since we already ensure sfAddrTaken is not in s.flags, we only need to
    # prevent direct assignments to the monotonic variable:
    if n[0].kind == nkSym and n[0].isLocal:
      let slot = c.getSlot(it[j].sym)
      slot.blackListed = true
    invalidateFacts(c.guards, n.sons[0])
    analyseSons(c, n)
    addAsgnFact(c.guards, n.sons[0], n.sons[1])
  of nkCallKinds:
    # direct call:
    if n[0].kind == nkSym: analyseCall(c, n, n[0].sym)
    else: analyseSons(c, n)
  of nkBracket:
    c.addSlice(n, 0, 1, 1)
    analyseSons(c, n)
  of nkReturnStmt, nkRaiseStmt, nkTryStmt:
    localError(n.info, "invalid control flow for 'parallel'")
    # 'break' that leaves the 'parallel' section is not valid either
    # or maybe we should generate a 'try' XXX
  of nkVarSection:
    for it in n:
      if it.sons[it.len-1].kind != nkEmpty:
        for j in 0 .. it.len-3:
          if it[j].kind == nkSym and it[j].isLocal:
            let slot = c.getSlot(it[j].sym)
            if slot.lower.isNil: slot.lower = it.sons[it.len-1]
            else: internalError(it.info, "slot already has a lower bound")
    analyseSons(c, n)

  of nkCaseStmt: analyseCase(c, n)
  of nkIfStmt, nkIfExpr: analyseIf(c, n)
  of nkWhileStmt:
    analyse(c, n.sons[0])
    # 'while true' loop?
    inc c.inLoop
    if isTrue(n.sons[0]):
      analyseSons(c, n.sons[1])
    else:
      # loop may never execute:
      let oldState = c.locals.len
      let oldFacts = c.guards.len
      addFact(c.guards, n.sons[0])
      analyse(c, n.sons[1])
      setLen(c.locals, oldState)
      setLen(c.guards, oldFacts)
      # we know after the loop the negation holds:
      if not containsNode(n.sons[1], nkBreakStmt):
        addFactNeg(c.guards, n.sons[0])
    dec c.inLoop
  of nkTypeSection, nkProcDef, nkConverterDef, nkMethodDef, nkIteratorDef,
      nkMacroDef, nkTemplateDef, nkConstSection, nkPragma:
    discard
  else:
    analyseSons(c, n)

proc transformSlices(n: PNode): PNode =
  if n.kind in nkCalls and n[0].kind == nkSym:
    let op = n[0].sym
    if op.name.s == "[]" and sfSystemModule in op.owner.flags:
      result = copyTree(n)
      result.sons[0] = opSlice
      return result
  if n.safeLen > 0:
    result = copyNode(n.kind, n.info, n.len)
    for i in 0 .. < n.len:
      result.sons[i] = transformSlices(n.sons[i])
  else:
    result = n

proc transformSpawn(owner: PSym; n, barrier: PNode): PNode =
  if n.kind in nkCalls:
    if n[0].kind == nkSym:
      let op = n[0].sym
      if op.magic == mSpawn:
        result = transformSlices(n)
        return wrapProcForSpawn(owner, result, barrier)
  elif n.safeLen > 0:
    result = copyNode(n.kind, n.info, n.len)
    for i in 0 .. < n.len:
      result.sons[i] = transformSpawn(owner, n.sons[i], barrier)
  else:
    result = n

proc liftParallel*(owner: PSym; n: PNode): PNode =
  # this needs to be called after the 'for' loop elimination

  # first pass:
  # - detect monotonic local integer variables
  # - detect used slices
  # - detect used arguments
  
  var a = initAnalysisCtx()
  let body = n.lastSon
  analyse(a, body)
  if a.spawns == 0:
    localError(n.info, "'parallel' section without 'spawn'")
  checkSlices(a)
  checkArgs(a, body)

  var varSection = newNodeI(nkVarSection, n.info)
  var temp = newSym(skTemp, "barrier", owner, n.info)
  temp.typ = magicsys.getCompilerProc("Barrier").typ
  incl(temp.flags, sfFromGeneric)

  var vpart = newNodeI(nkIdentDefs, n.info, 3)
  vpart.sons[0] = newSymNode(temp)
  vpart.sons[1] = ast.emptyNode
  vpart.sons[2] = indirectAccess(castExpr, field, n.info)
  varSection.add vpart

  barrier = genAddrOf(vpart[0])

  result = newNodeI(nkStmtList, n.info)
  generateAliasChecks(a, result)
  result.add varSection
  result.add callCodeGenProc("openBarrier", barrier)
  result.add transformSpawn(owner, body, barrier)
  result.add callCodeGenProc("closeBarrier", barrier)
