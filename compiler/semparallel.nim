#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Semantic checking for 'parallel'.

# - codegen needs to support mSlice (+)
# - lowerings must not perform unnecessary copies (+)
# - slices should become "nocopy" to openArray (+)
#   - need to perform bound checks (+)
#
# - parallel needs to insert a barrier (+)
# - passed arguments need to be ensured to be "const"
#   - what about 'f(a)'? --> f shouldn't have side effects anyway
# - passed arrays need to be ensured not to alias
# - passed slices need to be ensured to be disjoint (+)
# - output slices need special logic (+)

import
  ast, astalgo, idents, lowerings, magicsys, guards, sempass2, msgs,
  renderer, types
from trees import getMagic
from strutils import `%`

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
    v, alias: PSym        # to support the ordinary 'countup' iterator
                          # we need to detect aliases
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

proc lookupSlot(c: AnalysisCtx; s: PSym): int =
  for i in 0.. <c.locals.len:
    if c.locals[i].v == s or c.locals[i].alias == s: return i
  return -1

proc getSlot(c: var AnalysisCtx; v: PSym): ptr MonotonicVar =
  let s = lookupSlot(c, v)
  if s >= 0: return addr(c.locals[s])
  let L = c.locals.len
  c.locals.setLen(L+1)
  c.locals[L].v = v
  return addr(c.locals[L])

proc gatherArgs(c: var AnalysisCtx; n: PNode) =
  for i in 0.. <n.safeLen:
    let root = getRoot n[i]
    if root != nil:
      block addRoot:
        for r in items(c.args):
          if r == root: break addRoot
        c.args.add root
    gatherArgs(c, n[i])

proc isSingleAssignable(n: PNode): bool =
  n.kind == nkSym and (let s = n.sym;
    s.kind in {skTemp, skForVar, skLet} and
          {sfAddrTaken, sfGlobal} * s.flags == {})

proc isLocal(n: PNode): bool =
  n.kind == nkSym and (let s = n.sym;
    s.kind in {skResult, skTemp, skForVar, skVar, skLet} and
          {sfAddrTaken, sfGlobal} * s.flags == {})

proc checkLocal(c: AnalysisCtx; n: PNode) =
  if isLocal(n):
    let s = c.lookupSlot(n.sym)
    if s >= 0 and c.locals[s].stride != nil:
      localError(n.info, "invalid usage of counter after increment")
  else:
    for i in 0 .. <n.safeLen: checkLocal(c, n.sons[i])

template `?`(x): expr = x.renderTree

proc checkLe(c: AnalysisCtx; a, b: PNode) =
  case proveLe(c.guards, a, b)
  of impUnknown:
    localError(a.info, "cannot prove: " & ?a & " <= " & ?b)
  of impYes: discard
  of impNo:
    localError(a.info, "can prove: " & ?a & " > " & ?b)

proc checkBounds(c: AnalysisCtx; arr, idx: PNode) =
  checkLe(c, arr.lowBound, idx)
  checkLe(c, idx, arr.highBound)

proc addLowerBoundAsFacts(c: var AnalysisCtx) =
  for v in c.locals:
    if not v.blacklisted:
      c.guards.addFactLe(v.lower, newSymNode(v.v))

proc addSlice(c: var AnalysisCtx; n: PNode; x, le, ri: PNode) =
  checkLocal(c, n)
  let le = le.canon
  let ri = ri.canon
  # perform static bounds checking here; and not later!
  let oldState = c.guards.len
  addLowerBoundAsFacts(c)
  c.checkBounds(x, le)
  c.checkBounds(x, ri)
  c.guards.setLen(oldState)
  c.slices.add((x, le, ri, c.currentSpawnId, c.inLoop > 0))

proc overlap(m: TModel; x,y,c,d: PNode) =
  #  X..Y and C..D overlap iff (X <= D and C <= Y)
  case proveLe(m, x, d)
  of impUnknown:
    localError(x.info,
      "cannot prove: $# > $#; required for ($#)..($#) disjoint from ($#)..($#)" %
        [?x, ?d, ?x, ?y, ?c, ?d])
  of impYes:
    case proveLe(m, c, y)
    of impUnknown:
      localError(x.info,
        "cannot prove: $# > $#; required for ($#)..($#) disjoint from ($#)..($#)" %
          [?c, ?y, ?x, ?y, ?c, ?d])
    of impYes:
      localError(x.info, "($#)..($#) not disjoint from ($#)..($#)" % [?x, ?y, ?c, ?d])
    of impNo: discard
  of impNo: discard

proc stride(c: AnalysisCtx; n: PNode): BiggestInt =
  if isLocal(n):
    let s = c.lookupSlot(n.sym)
    if s >= 0 and c.locals[s].stride != nil:
      result = c.locals[s].stride.intVal
  else:
    for i in 0 .. <n.safeLen: result += stride(c, n.sons[i])

proc subStride(c: AnalysisCtx; n: PNode): PNode =
  # substitute with stride:
  if isLocal(n):
    let s = c.lookupSlot(n.sym)
    if s >= 0 and c.locals[s].stride != nil:
      result = n +@ c.locals[s].stride.intVal
    else:
      result = n
  elif n.safeLen > 0:
    result = shallowCopy(n)
    for i in 0 .. <n.len: result.sons[i] = subStride(c, n.sons[i])
  else:
    result = n

proc checkSlicesAreDisjoint(c: var AnalysisCtx) =
  # this is the only thing that we need to perform after we have traversed
  # the whole tree so that the strides are available.
  # First we need to add all the computed lower bounds:
  addLowerBoundAsFacts(c)
  # Every slice used in a loop needs to be disjoint with itself:
  for x,a,b,id,inLoop in items(c.slices):
    if inLoop: overlap(c.guards, a,b, c.subStride(a), c.subStride(b))
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
    for j in i+1 .. high(c.slices):
      let x = c.slices[i]
      let y = c.slices[j]
      if x.spawnId != y.spawnId and guards.sameTree(x.x, y.x):
        if not x.inLoop or not y.inLoop:
          # XXX strictly speaking, 'or' is not correct here and it needs to
          # be 'and'. However this prevents too many obviously correct programs
          # like f(a[0..x]); for i in x+1 .. a.high: f(a[i])
          overlap(c.guards, x.a, x.b, y.a, y.b)
        elif (let k = simpleSlice(x.a, x.b); let m = simpleSlice(y.a, y.b);
              k >= 0 and m >= 0):
          # ah I cannot resist the temptation and add another sweet heuristic:
          # if both slices have the form (i+k)..(i+k)  and (i+m)..(i+m) we
          # check they are disjoint and k < stride and m < stride:
          overlap(c.guards, x.a, x.b, y.a, y.b)
          let stride = min(c.stride(x.a), c.stride(y.a))
          if k < stride and m < stride:
            discard
          else:
            localError(x.x.info, "cannot prove ($#)..($#) disjoint from ($#)..($#)" %
              [?x.a, ?x.b, ?y.a, ?y.b])
        else:
          localError(x.x.info, "cannot prove ($#)..($#) disjoint from ($#)..($#)" %
            [?x.a, ?x.b, ?y.a, ?y.b])

proc analyse(c: var AnalysisCtx; n: PNode)

proc analyseSons(c: var AnalysisCtx; n: PNode) =
  for i in 0 .. <safeLen(n): analyse(c, n[i])

proc min(a, b: PNode): PNode =
  if a.isNil: result = b
  elif a.intVal < b.intVal: result = a
  else: result = b

proc fromSystem(op: PSym): bool = sfSystemModule in getModule(op).flags

template pushSpawnId(c: expr, body: stmt) {.immediate, dirty.} =
  inc c.spawns
  let oldSpawnId = c.currentSpawnId
  c.currentSpawnId = c.spawns
  body
  c.currentSpawnId = oldSpawnId

proc analyseCall(c: var AnalysisCtx; n: PNode; op: PSym) =
  if op.magic == mSpawn:
    pushSpawnId(c):
      gatherArgs(c, n[1])
      analyseSons(c, n)
  elif op.magic == mInc or (op.name.s == "+=" and op.fromSystem):
    if n[1].isLocal:
      let incr = n[2].skipConv
      if incr.kind in {nkCharLit..nkUInt32Lit} and incr.intVal > 0:
        let slot = c.getSlot(n[1].sym)
        slot.stride = min(slot.stride, incr)
    analyseSons(c, n)
  elif op.name.s == "[]" and op.fromSystem:
    c.addSlice(n, n[1], n[2][1], n[2][2])
    analyseSons(c, n)
  elif op.name.s == "[]=" and op.fromSystem:
    c.addSlice(n, n[1], n[2][1], n[2][2])
    analyseSons(c, n)
  else:
    analyseSons(c, n)

proc analyseCase(c: var AnalysisCtx; n: PNode) =
  analyse(c, n.sons[0])
  let oldFacts = c.guards.len
  for i in 1.. <n.len:
    let branch = n.sons[i]
    setLen(c.guards, oldFacts)
    addCaseBranchFacts(c.guards, n, i)
    for i in 0 .. <branch.len:
      analyse(c, branch.sons[i])
  setLen(c.guards, oldFacts)

proc analyseIf(c: var AnalysisCtx; n: PNode) =
  analyse(c, n.sons[0].sons[0])
  let oldFacts = c.guards.len
  addFact(c.guards, canon(n.sons[0].sons[0]))

  analyse(c, n.sons[0].sons[1])
  for i in 1.. <n.len:
    let branch = n.sons[i]
    setLen(c.guards, oldFacts)
    for j in 0..i-1:
      addFactNeg(c.guards, canon(n.sons[j].sons[0]))
    if branch.len > 1:
      addFact(c.guards, canon(branch.sons[0]))
    for i in 0 .. <branch.len:
      analyse(c, branch.sons[i])
  setLen(c.guards, oldFacts)

proc analyse(c: var AnalysisCtx; n: PNode) =
  case n.kind
  of nkAsgn, nkFastAsgn:
    let y = n[1].skipConv
    if n[0].isSingleAssignable and y.isLocal:
      let slot = c.getSlot(y.sym)
      slot.alias = n[0].sym
    elif n[0].isLocal:
      # since we already ensure sfAddrTaken is not in s.flags, we only need to
      # prevent direct assignments to the monotonic variable:
      let slot = c.getSlot(n[0].sym)
      slot.blacklisted = true
    invalidateFacts(c.guards, n[0])
    let value = n[1]
    if getMagic(value) == mSpawn:
      pushSpawnId(c):
        gatherArgs(c, value[1])
        analyseSons(c, value[1])
        analyse(c, n[0])
    else:
      analyseSons(c, n)
    addAsgnFact(c.guards, n[0], y)
  of nkCallKinds:
    # direct call:
    if n[0].kind == nkSym: analyseCall(c, n, n[0].sym)
    else: analyseSons(c, n)
  of nkBracketExpr:
    c.addSlice(n, n[0], n[1], n[1])
    analyseSons(c, n)
  of nkReturnStmt, nkRaiseStmt, nkTryStmt:
    localError(n.info, "invalid control flow for 'parallel'")
    # 'break' that leaves the 'parallel' section is not valid either
    # or maybe we should generate a 'try' XXX
  of nkVarSection, nkLetSection:
    for it in n:
      let value = it.lastSon
      let isSpawned = getMagic(value) == mSpawn
      if isSpawned:
        pushSpawnId(c):
          gatherArgs(c, value[1])
          analyseSons(c, value[1])
      if value.kind != nkEmpty:
        for j in 0 .. it.len-3:
          if it[j].isLocal:
            let slot = c.getSlot(it[j].sym)
            if slot.lower.isNil: slot.lower = value
            else: internalError(it.info, "slot already has a lower bound")
        if not isSpawned: analyse(c, value)
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
      addFact(c.guards, canon(n.sons[0]))
      analyse(c, n.sons[1])
      setLen(c.locals, oldState)
      setLen(c.guards, oldFacts)
      # we know after the loop the negation holds:
      if not hasSubnodeWith(n.sons[1], nkBreakStmt):
        addFactNeg(c.guards, canon(n.sons[0]))
    dec c.inLoop
  of nkTypeSection, nkProcDef, nkConverterDef, nkMethodDef, nkIteratorDef,
      nkMacroDef, nkTemplateDef, nkConstSection, nkPragma:
    discard
  else:
    analyseSons(c, n)

proc transformSlices(n: PNode): PNode =
  if n.kind in nkCallKinds and n[0].kind == nkSym:
    let op = n[0].sym
    if op.name.s == "[]" and op.fromSystem:
      result = copyNode(n)
      result.add opSlice.newSymNode
      result.add n[1]
      result.add n[2][1]
      result.add n[2][2]
      return result
  if n.safeLen > 0:
    result = shallowCopy(n)
    for i in 0 .. < n.len:
      result.sons[i] = transformSlices(n.sons[i])
  else:
    result = n

proc transformSpawn(owner: PSym; n, barrier: PNode): PNode
proc transformSpawnSons(owner: PSym; n, barrier: PNode): PNode =
  result = shallowCopy(n)
  for i in 0 .. < n.len:
    result.sons[i] = transformSpawn(owner, n.sons[i], barrier)

proc transformSpawn(owner: PSym; n, barrier: PNode): PNode =
  case n.kind
  of nkVarSection, nkLetSection:
    result = nil
    for it in n:
      let b = it.lastSon
      if getMagic(b) == mSpawn:
        if it.len != 3: localError(it.info, "invalid context for 'spawn'")
        let m = transformSlices(b)
        if result.isNil:
          result = newNodeI(nkStmtList, n.info)
          result.add n
        let t = b[1][0].typ.sons[0]
        if spawnResult(t, true) == srByVar:
          result.add wrapProcForSpawn(owner, m, b.typ, barrier, it[0])
          it.sons[it.len-1] = emptyNode
        else:
          it.sons[it.len-1] = wrapProcForSpawn(owner, m, b.typ, barrier, nil)
    if result.isNil: result = n
  of nkAsgn, nkFastAsgn:
    let b = n[1]
    if getMagic(b) == mSpawn and (let t = b[1][0].typ.sons[0];
        spawnResult(t, true) == srByVar):
      let m = transformSlices(b)
      return wrapProcForSpawn(owner, m, b.typ, barrier, n[0])
    result = transformSpawnSons(owner, n, barrier)
  of nkCallKinds:
    if getMagic(n) == mSpawn:
      result = transformSlices(n)
      return wrapProcForSpawn(owner, result, n.typ, barrier, nil)
    result = transformSpawnSons(owner, n, barrier)
  elif n.safeLen > 0:
    result = transformSpawnSons(owner, n, barrier)
  else:
    result = n

proc checkArgs(a: var AnalysisCtx; n: PNode) =
  discard "too implement"

proc generateAliasChecks(a: AnalysisCtx; result: PNode) =
  discard "too implement"

proc liftParallel*(owner: PSym; n: PNode): PNode =
  # this needs to be called after the 'for' loop elimination

  # first pass:
  # - detect monotonic local integer variables
  # - detect used slices
  # - detect used arguments
  #echo "PAR ", renderTree(n)

  var a = initAnalysisCtx()
  let body = n.lastSon
  analyse(a, body)
  if a.spawns == 0:
    localError(n.info, "'parallel' section without 'spawn'")
  checkSlicesAreDisjoint(a)
  checkArgs(a, body)

  var varSection = newNodeI(nkVarSection, n.info)
  var temp = newSym(skTemp, getIdent"barrier", owner, n.info)
  temp.typ = magicsys.getCompilerProc("Barrier").typ
  incl(temp.flags, sfFromGeneric)
  let tempNode = newSymNode(temp)
  varSection.addVar tempNode

  let barrier = genAddrOf(tempNode)
  result = newNodeI(nkStmtList, n.info)
  generateAliasChecks(a, result)
  result.add varSection
  result.add callCodegenProc("openBarrier", barrier)
  result.add transformSpawn(owner, body, barrier)
  result.add callCodegenProc("closeBarrier", barrier)
