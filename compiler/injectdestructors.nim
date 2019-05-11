#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Injects destructor calls into Nim code as well as
## an optimizer that optimizes copies to moves. This is implemented as an
## AST to AST transformation so that every backend benefits from it.

## Rules for destructor injections:
##
## foo(bar(X(), Y()))
## X and Y get destroyed after bar completes:
##
## foo( (tmpX = X(); tmpY = Y(); tmpBar = bar(tmpX, tmpY);
##       destroy(tmpX); destroy(tmpY);
##       tmpBar))
## destroy(tmpBar)
##
## var x = f()
## body
##
## is the same as:
##
##  var x;
##  try:
##    move(x, f())
##  finally:
##    destroy(x)
##
## But this really just an optimization that tries to avoid to
## introduce too many temporaries, the 'destroy' is caused by
## the 'f()' call. No! That is not true for 'result = f()'!
##
## x = y where y is read only once
## is the same as:  move(x, y)
##
## Actually the more general rule is: The *last* read of ``y``
## can become a move if ``y`` is the result of a construction.
##
## We also need to keep in mind here that the number of reads is
## control flow dependent:
## let x = foo()
## while true:
##   y = x  # only one read, but the 2nd iteration will fail!
## This also affects recursions! Only usages that do not cross
## a loop boundary (scope) and are not used in function calls
## are safe.
##
##
## x = f() is the same as:  move(x, f())
##
## x = y
## is the same as:  copy(x, y)
##
## Reassignment works under this scheme:
## var x = f()
## x = y
##
## is the same as:
##
##  var x;
##  try:
##    move(x, f())
##    copy(x, y)
##  finally:
##    destroy(x)
##
##  result = f()  must not destroy 'result'!
##
## The produced temporaries clutter up the code and might lead to
## inefficiencies. A better strategy is to collect all the temporaries
## in a single object that we put into a single try-finally that
## surrounds the proc body. This means the code stays quite efficient
## when compiled to C. In fact, we do the same for variables, so
## destructors are called when the proc returns, not at scope exit!
## This makes certains idioms easier to support. (Taking the slice
## of a temporary object.)
##
## foo(bar(X(), Y()))
## X and Y get destroyed after bar completes:
##
## var tmp: object
## foo( (move tmp.x, X(); move tmp.y, Y(); tmp.bar = bar(tmpX, tmpY);
##       tmp.bar))
## destroy(tmp.bar)
## destroy(tmp.x); destroy(tmp.y)
##

#[
From https://github.com/nim-lang/Nim/wiki/Destructors

Rule      Pattern                 Transformed into
----      -------                 ----------------
1.1	      var x: T; stmts	        var x: T; try stmts
                                  finally: `=destroy`(x)
2         x = f()                 `=sink`(x, f())
3         x = lastReadOf z        `=sink`(x, z); wasMoved(z)
3.2       x = path z; body        ``x = bitwiseCopy(path z);``
                                  do not emit `=destroy(x)`. Note: body
                                  must not mutate ``z`` nor ``x``. All
                                  assignments to ``x`` must be of the form
                                  ``path z`` but the ``z`` can differ.
                                  Neither ``z`` nor ``x`` can have the
                                  flag ``sfAddrTaken`` to ensure no other
                                  aliasing is going on.
4.1       y = sinkParam           `=sink`(y, sinkParam)
4.2       x = y                   `=`(x, y) # a copy
5.1       f_sink(g())             f_sink(g())
5.2       f_sink(y)               f_sink(copy y); # copy unless we can see it's the last read
5.3       f_sink(move y)          f_sink(y); wasMoved(y) # explicit moves empties 'y'
5.4       f_noSink(g())           var tmp = bitwiseCopy(g()); f(tmp); `=destroy`(tmp)

Rule 3.2 describes a "cursor" variable, a variable that is only used as a
view into some data structure. See ``compiler/cursors.nim`` for details.

Note: In order to avoid the very common combination ``reset(x); =sink(x, y)`` for
variable definitions we must turn "the first sink/assignment" operation into a
copyMem. This is harder than it looks:

  while true:
    try:
      if cond: break # problem if we run destroy(x) here :-/
      var x = f()
    finally:
      destroy(x)

And the C++ optimizers don't sweat to optimize it for us, so we don't have
to do it.
]#

import
  intsets, ast, astalgo, msgs, renderer, magicsys, types, idents, trees,
  strutils, options, dfa, lowerings, tables, modulegraphs, msgs,
  lineinfos, parampatterns, sighashes

const
  InterestingSyms = {skVar, skResult, skLet, skForVar, skTemp}

type
  Con = object
    owner: PSym
    g: ControlFlowGraph
    jumpTargets: IntSet
    destroys, topLevelVars: PNode
    graph: ModuleGraph
    emptyNode: PNode
    otherRead: PNode
    uninit: IntSet # set of uninit'ed vars
    uninitComputed: bool

const toDebug = ""

template dbg(body) =
  when toDebug.len > 0:
    if c.owner.name.s == toDebug or toDebug == "always":
      body

proc isLastRead(location: PNode; c: var Con; pc, comesFrom: int): int =
  var pc = pc
  while pc < c.g.len:
    case c.g[pc].kind
    of def:
      if instrTargets(c.g[pc], location):
        # the path lead to a redefinition of 's' --> abandon it.
        return high(int)
      inc pc
    of use:
      if instrTargets(c.g[pc], location):
        c.otherRead = c.g[pc].n
        return -1
      inc pc
    of goto:
      pc = pc + c.g[pc].dest
    of fork:
      # every branch must lead to the last read of the location:
      var variantA = isLastRead(location, c, pc+1, pc)
      if variantA < 0: return -1
      let variantB = isLastRead(location, c, pc + c.g[pc].dest, pc)
      if variantB < 0: return -1
      elif variantA == high(int):
        variantA = variantB
      pc = variantA
    of InstrKind.join:
      let dest = pc + c.g[pc].dest
      if dest == comesFrom: return pc + 1
      inc pc
  return pc

proc isLastRead(n: PNode; c: var Con): bool =
  # first we need to search for the instruction that belongs to 'n':
  c.otherRead = nil
  var instr = -1
  let m = dfa.skipConvDfa(n)

  for i in 0..<c.g.len:
    # This comparison is correct and MUST not be ``instrTargets``:
    if c.g[i].kind == use and c.g[i].n == m:
      if instr < 0:
        instr = i
        break

  dbg:
    echo "starting point for ", n, " is ", instr, " ", n.kind

  if instr < 0: return false
  # we go through all paths beginning from 'instr+1' and need to
  # ensure that we don't find another 'use X' instruction.
  if instr+1 >= c.g.len: return true

  result = isLastRead(n, c, instr+1, -1) >= 0
  dbg:
    echo "ugh ", c.otherRead.isNil, " ", result

  when false:
    let s = n.sym
    var pcs: seq[int] = @[instr+1]
    var takenGotos: IntSet
    var takenForks = initIntSet()
    while pcs.len > 0:
      var pc = pcs.pop

      takenGotos = initIntSet()
      while pc < c.g.len:
        case c.g[pc].kind
        of def:
          if c.g[pc].sym == s:
            # the path lead to a redefinition of 's' --> abandon it.
            break
          inc pc
        of use:
          if c.g[pc].sym == s:
            c.otherRead = c.g[pc].n
            return false
          inc pc
        of goto:
          # we must leave endless loops eventually:
          if not takenGotos.containsOrIncl(pc):
            pc = pc + c.g[pc].dest
          else:
            inc pc
        of fork:
          # we follow the next instruction but push the dest onto our "work" stack:
          if not takenForks.containsOrIncl(pc):
            pcs.add pc + c.g[pc].dest
          inc pc
        of InstrKind.join:
          inc pc
    #echo c.graph.config $ n.info, " last read here!"
    return true

proc initialized(code: ControlFlowGraph; pc: int,
                 init, uninit: var IntSet; comesFrom: int): int =
  ## Computes the set of definitely initialized variables accross all code paths
  ## as an IntSet of IDs.
  var pc = pc
  while pc < code.len:
    case code[pc].kind
    of goto:
      pc = pc + code[pc].dest
    of fork:
      let target = pc + code[pc].dest
      var initA = initIntSet()
      var initB = initIntSet()
      let pcA = initialized(code, pc+1, initA, uninit, pc)
      discard initialized(code, target, initB, uninit, pc)
      # we add vars if they are in both branches:
      for v in initA:
        if v in initB:
          init.incl v
      pc = pcA+1
    of InstrKind.join:
      let target = pc + code[pc].dest
      if comesFrom == target: return pc
      inc pc
    of use:
      let v = code[pc].sym
      if v.kind != skParam and v.id notin init:
        # attempt to read an uninit'ed variable
        uninit.incl v.id
      inc pc
    of def:
      let v = code[pc].sym
      init.incl v.id
      inc pc
  return pc

template interestingSym(s: PSym): bool =
  s.owner == c.owner and s.kind in InterestingSyms and hasDestructor(s.typ)

template isUnpackedTuple(s: PSym): bool =
  ## we move out all elements of unpacked tuples,
  ## hence unpacked tuples themselves don't need to be destroyed
  s.kind == skTemp and s.typ.kind == tyTuple

proc checkForErrorPragma(c: Con; t: PType; ri: PNode; opname: string) =
  var m = "'" & opname & "' is not available for type <" & typeToString(t) & ">"
  if opname == "=" and ri != nil:
    m.add "; requires a copy because it's not the last read of '"
    m.add renderTree(ri)
    m.add '\''
    if c.otherRead != nil:
      m.add "; another read is done here: "
      m.add c.graph.config $ c.otherRead.info
    elif ri.kind == nkSym and ri.sym.kind == skParam and not isSinkType(ri.sym.typ):
      m.add "; try to make "
      m.add renderTree(ri)
      m.add " a 'sink' parameter"
  localError(c.graph.config, ri.info, errGenerated, m)

proc makePtrType(c: Con, baseType: PType): PType =
  result = newType(tyPtr, c.owner)
  addSonSkipIntLit(result, baseType)

proc genOp(c: Con; t: PType; kind: TTypeAttachedOp; dest, ri: PNode): PNode =
  var op = t.attachedOps[kind]

  if op == nil:
    # give up and find the canonical type instead:
    let h = sighashes.hashType(t, {CoType, CoConsiderOwned, CoDistinct})
    let canon = c.graph.canonTypes.getOrDefault(h)
    if canon != nil:
      op = canon.attachedOps[kind]

  if op == nil:
    globalError(c.graph.config, dest.info, "internal error: '" & AttachedOpToStr[kind] &
      "' operator not found for type " & typeToString(t))
  elif op.ast[genericParamsPos].kind != nkEmpty:
    globalError(c.graph.config, dest.info, "internal error: '" & AttachedOpToStr[kind] &
      "' operator is generic")
  if sfError in op.flags: checkForErrorPragma(c, t, ri, AttachedOpToStr[kind])
  let addrExp = newNodeIT(nkHiddenAddr, dest.info, makePtrType(c, dest.typ))
  addrExp.add(dest)
  result = newTree(nkCall, newSymNode(op), addrExp)

proc genSink(c: Con; t: PType; dest, ri: PNode): PNode =
  let t = t.skipTypes({tyGenericInst, tyAlias, tySink})
  let k = if t.attachedOps[attachedSink] != nil: attachedSink
           else: attachedAsgn
  if t.attachedOps[k] != nil:
    result = genOp(c, t, k, dest, ri)
  else:
    # in rare cases only =destroy exists but no sink or assignment
    # (see Pony object in tmove_objconstr.nim)
    # we generate a fast assignment in this case:
    result = newTree(nkFastAsgn, dest)

proc genCopy(c: Con; t: PType; dest, ri: PNode): PNode =
  if tfHasOwned in t.flags:
    checkForErrorPragma(c, t, ri, "=")
  let t = t.skipTypes({tyGenericInst, tyAlias, tySink})
  result = genOp(c, t, attachedAsgn, dest, ri)

proc genCopyNoCheck(c: Con; t: PType; dest, ri: PNode): PNode =
  let t = t.skipTypes({tyGenericInst, tyAlias, tySink})
  result = genOp(c, t, attachedAsgn, dest, ri)

proc genDestroy(c: Con; t: PType; dest: PNode): PNode =
  let t = t.skipTypes({tyGenericInst, tyAlias, tySink})
  result = genOp(c, t, attachedDestructor, dest, nil)

proc addTopVar(c: var Con; v: PNode) =
  c.topLevelVars.add newTree(nkIdentDefs, v, c.emptyNode, c.emptyNode)

proc getTemp(c: var Con; typ: PType; info: TLineInfo): PNode =
  let sym = newSym(skTemp, getIdent(c.graph.cache, ":tmpD"), c.owner, info)
  sym.typ = typ
  result = newSymNode(sym)
  c.addTopVar(result)

proc p(n: PNode; c: var Con): PNode

template recurse(n, dest) =
  for i in 0..<n.len:
    dest.add p(n[i], c)

proc genMagicCall(n: PNode; c: var Con; magicname: string; m: TMagic): PNode =
  result = newNodeI(nkCall, n.info)
  result.add(newSymNode(createMagic(c.graph, magicname, m)))
  result.add n

proc genWasMoved(n: PNode; c: var Con): PNode =
  # The mWasMoved builtin does not take the address.
  result = genMagicCall(n, c, "wasMoved", mWasMoved)

proc genDefaultCall(t: PType; c: Con; info: TLineInfo): PNode =
  result = newNodeI(nkCall, info)
  result.add(newSymNode(createMagic(c.graph, "default", mDefault)))
  result.typ = t

proc destructiveMoveVar(n: PNode; c: var Con): PNode =
  # generate: (let tmp = v; reset(v); tmp)
  # XXX: Strictly speaking we can only move if there is a ``=sink`` defined
  # or if no ``=sink`` is defined and also no assignment.
  result = newNodeIT(nkStmtListExpr, n.info, n.typ)

  var temp = newSym(skLet, getIdent(c.graph.cache, "blitTmp"), c.owner, n.info)
  temp.typ = n.typ
  var v = newNodeI(nkLetSection, n.info)
  let tempAsNode = newSymNode(temp)

  var vpart = newNodeI(nkIdentDefs, tempAsNode.info, 3)
  vpart.sons[0] = tempAsNode
  vpart.sons[1] = c.emptyNode
  vpart.sons[2] = n
  add(v, vpart)

  result.add v
  result.add genWasMoved(n, c)
  result.add tempAsNode

proc sinkParamIsLastReadCheck(c: var Con, s: PNode) =
  assert s.kind == nkSym and s.sym.kind == skParam
  if not isLastRead(s, c):
     localError(c.graph.config, c.otherRead.info, "sink parameter `" & $s.sym.name.s &
         "` is already consumed at " & toFileLineCol(c. graph.config, s.info))

proc isSinkTypeForParam(t: PType): bool =
  # a parameter like 'seq[owned T]' must not be used only once, but its
  # elements must, so we detect this case here:
  result = t.skipTypes({tyGenericInst, tyAlias}).kind in {tySink, tyOwned}
  when false:
    if isSinkType(t):
      if t.skipTypes({tyGenericInst, tyAlias}).kind in {tyArray, tyVarargs, tyOpenArray, tySequence}:
        result = false
      else:
        result = true

proc passCopyToSink(n: PNode; c: var Con): PNode =
  result = newNodeIT(nkStmtListExpr, n.info, n.typ)
  let tmp = getTemp(c, n.typ, n.info)
  # XXX This is only required if we are in a loop. Since we move temporaries
  # out of loops we need to mark it as 'wasMoved'.
  result.add genWasMoved(tmp, c)
  if hasDestructor(n.typ):
    var m = genCopy(c, n.typ, tmp, n)
    m.add p(n, c)
    result.add m
    if isLValue(n):
      message(c.graph.config, n.info, hintPerformance,
        ("passing '$1' to a sink parameter introduces an implicit copy; " &
        "use 'move($1)' to prevent it") % $n)
  else:
    result.add newTree(nkAsgn, tmp, p(n, c))
  result.add tmp

proc pArg(arg: PNode; c: var Con; isSink: bool): PNode =
  template pArgIfTyped(argPart: PNode): PNode =
    # typ is nil if we are in if/case expr branch with noreturn
    if argPart.typ == nil: p(argPart, c)
    else: pArg(argPart, c, isSink)

  if isSink:
    if arg.kind in nkCallKinds:
      # recurse but skip the call expression in order to prevent
      # destructor injections: Rule 5.1 is different from rule 5.4!
      result = copyNode(arg)
      let parameters = arg[0].typ
      let L = if parameters != nil: parameters.len else: 0
      result.add arg[0]
      for i in 1..<arg.len:
        result.add pArg(arg[i], c, i < L and isSinkTypeForParam(parameters[i]))
    elif arg.kind in {nkBracket, nkObjConstr, nkTupleConstr, nkBracket, nkCharLit..nkTripleStrLit}:
      discard "object construction to sink parameter: nothing to do"
      result = arg
    elif arg.kind == nkSym and isSinkParam(arg.sym):
      # Sinked params can be consumed only once. We need to reset the memory
      # to disable the destructor which we have not elided
      sinkParamIsLastReadCheck(c, arg)
      result = destructiveMoveVar(arg, c)
    elif arg.kind == nkSym and arg.sym.kind in InterestingSyms and isLastRead(arg, c):
      # it is the last read, can be sinked. We need to reset the memory
      # to disable the destructor which we have not elided
      result = destructiveMoveVar(arg, c)
    elif arg.kind in {nkBlockExpr, nkBlockStmt}:
      result = copyNode(arg)
      result.add arg[0]
      result.add pArg(arg[1], c, isSink)
    elif arg.kind == nkStmtListExpr:
      result = copyNode(arg)
      for i in 0..arg.len-2:
        result.add p(arg[i], c)
      result.add pArg(arg[^1], c, isSink)
    elif arg.kind in {nkIfExpr, nkIfStmt}:
      result = copyNode(arg)
      for i in 0..<arg.len:
        var branch = copyNode(arg[i])
        if arg[i].kind in {nkElifBranch, nkElifExpr}:
          branch.add p(arg[i][0], c)
          branch.add pArgIfTyped(arg[i][1])
        else:
          branch.add pArgIfTyped(arg[i][0])
        result.add branch
    elif arg.kind == nkCaseStmt:
      result = copyNode(arg)
      result.add p(arg[0], c)
      for i in 1..<arg.len:
        var branch: PNode
        if arg[i].kind == nkOfbranch:
          branch = arg[i] # of branch conditions are constants
          branch[^1] = pArgIfTyped(arg[i][^1])
        elif arg[i].kind in {nkElifBranch, nkElifExpr}:
          branch = copyNode(arg[i])
          branch.add p(arg[i][0], c)
          branch.add pArgIfTyped(arg[i][1])
        else:
          branch = copyNode(arg[i])
          branch.add pArgIfTyped(arg[i][0])
        result.add branch
    elif isAnalysableFieldAccess(arg, c.owner) and isLastRead(arg, c):
      result = destructiveMoveVar(arg, c)
    else:
      # an object that is not temporary but passed to a 'sink' parameter
      # results in a copy.
      result = passCopyToSink(arg, c)
  else:
    result = p(arg, c)

proc moveOrCopy(dest, ri: PNode; c: var Con): PNode =
  # unfortunately, this needs to be kept consistent with the cases
  # we handle in the 'case of' statement below:
  const movableNodeKinds = (nkCallKinds + {nkSym, nkTupleConstr, nkObjConstr,
                                           nkBracket, nkBracketExpr, nkNilLit})

  template moveOrCopyIfTyped(riPart: PNode): PNode =
    # typ is nil if we are in if/case expr branch with noreturn
    if riPart.typ == nil: p(riPart, c)
    else: moveOrCopy(dest, riPart, c)

  case ri.kind
  of nkCallKinds:
    result = genSink(c, dest.typ, dest, ri)
    # watch out and no not transform 'ri' twice if it's a call:
    let ri2 = copyNode(ri)
    let parameters = ri[0].typ
    let L = if parameters != nil: parameters.len else: 0
    ri2.add ri[0]
    for i in 1..<ri.len:
      ri2.add pArg(ri[i], c, i < L and isSinkTypeForParam(parameters[i]))
    #recurse(ri, ri2)
    result.add ri2
  of nkBracketExpr:
    if ri[0].kind == nkSym and isUnpackedTuple(ri[0].sym):
      # unpacking of tuple: move out the elements
      result = genSink(c, dest.typ, dest, ri)
      result.add p(ri, c)
    elif isAnalysableFieldAccess(ri, c.owner) and isLastRead(ri, c):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      var snk = genSink(c, dest.typ, dest, ri)
      snk.add ri
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    else:
      result = genCopy(c, dest.typ, dest, ri)
      result.add p(ri, c)
  of nkStmtListExpr:
    result = newNodeI(nkStmtList, ri.info)
    for i in 0..ri.len-2:
      result.add p(ri[i], c)
    result.add moveOrCopy(dest, ri[^1], c)
  of nkBlockExpr, nkBlockStmt:
    result = newNodeI(nkBlockStmt, ri.info)
    result.add ri[0] ## add label
    result.add moveOrCopy(dest, ri[1], c)
  of nkIfExpr, nkIfStmt:
    result = newNodeI(nkIfStmt, ri.info)
    for i in 0..<ri.len:
      var branch = copyNode(ri[i])
      if ri[i].kind in {nkElifBranch, nkElifExpr}:
        branch.add p(ri[i][0], c)
        branch.add moveOrCopyIfTyped(ri[i][1])
      else:
        branch.add moveOrCopyIfTyped(ri[i][0])
      result.add branch
  of nkCaseStmt:
    result = newNodeI(nkCaseStmt, ri.info)
    result.add p(ri[0], c)
    for i in 1..<ri.len:
      var branch: PNode
      if ri[i].kind == nkOfbranch:
        branch = ri[i] # of branch conditions are constants
        branch[^1] = moveOrCopyIfTyped(ri[i][^1])
      elif ri[i].kind in {nkElifBranch, nkElifExpr}:
        branch = copyNode(ri[i])
        branch.add p(ri[i][0], c)
        branch.add moveOrCopyIfTyped(ri[i][1])
      else:
        branch = copyNode(ri[i])
        branch.add moveOrCopyIfTyped(ri[i][0])
      result.add branch
  of nkBracket:
    # array constructor
    result = genSink(c, dest.typ, dest, ri)
    let ri2 = copyTree(ri)
    for i in 0..<ri.len:
      # everything that is passed to an array constructor is consumed,
      # so these all act like 'sink' parameters:
      ri2[i] = pArg(ri[i], c, isSink = true)
    result.add ri2
  of nkObjConstr:
    result = genSink(c, dest.typ, dest, ri)
    let ri2 = copyTree(ri)
    for i in 1..<ri.len:
      # everything that is passed to an object constructor is consumed,
      # so these all act like 'sink' parameters:
      ri2[i].sons[1] = pArg(ri[i][1], c, isSink = true)
    result.add ri2
  of nkTupleConstr, nkClosure:
    result = genSink(c, dest.typ, dest, ri)
    let ri2 = copyTree(ri)
    for i in 0..<ri.len:
      # everything that is passed to an tuple constructor is consumed,
      # so these all act like 'sink' parameters:
      if ri[i].kind == nkExprColonExpr:
        ri2[i].sons[1] = pArg(ri[i][1], c, isSink = true)
      else:
        ri2[i] = pArg(ri[i], c, isSink = true)
    result.add ri2
  of nkNilLit:
    result = genSink(c, dest.typ, dest, ri)
    result.add ri
  of nkSym:
    if isSinkParam(ri.sym):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      sinkParamIsLastReadCheck(c, ri)
      var snk = genSink(c, dest.typ, dest, ri)
      snk.add ri
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    elif ri.sym.kind != skParam and ri.sym.owner == c.owner and isLastRead(ri, c):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      var snk = genSink(c, dest.typ, dest, ri)
      snk.add ri
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    else:
      result = genCopy(c, dest.typ, dest, ri)
      result.add p(ri, c)
  of nkHiddenSubConv, nkHiddenStdConv:
    if sameType(ri.typ, ri[1].typ):
      result = moveOrCopy(dest, ri[1], c)
    elif ri[1].kind in movableNodeKinds:
      result = moveOrCopy(dest, ri[1], c)
      var b = newNodeIT(ri.kind, ri.info, ri.typ)
      b.add ri[0] # add empty node
      let L = result.len-1
      b.add result[L]
      result[L] = b
    else:
      result = genCopy(c, dest.typ, dest, ri)
      result.add p(ri, c)
  of nkObjDownConv, nkObjUpConv:
    if ri[0].kind in movableNodeKinds:
      result = moveOrCopy(dest, ri[0], c)
      var b = newNodeIT(ri.kind, ri.info, ri.typ)
      let L = result.len-1
      b.add result[L]
      result[L] = b
    else:
      result = genCopy(c, dest.typ, dest, ri)
      result.add p(ri, c)
  else:
    if isAnalysableFieldAccess(ri, c.owner) and isLastRead(ri, c):
      # Rule 3: `=sink`(x, z); wasMoved(z)
      var snk = genSink(c, dest.typ, dest, ri)
      snk.add ri
      result = newTree(nkStmtList, snk, genWasMoved(ri, c))
    else:
      # XXX At least string literals can be moved?
      result = genCopy(c, dest.typ, dest, ri)
      result.add p(ri, c)

proc computeUninit(c: var Con) =
  if not c.uninitComputed:
    c.uninitComputed = true
    c.uninit = initIntSet()
    var init = initIntSet()
    discard initialized(c.g, pc = 0, init, c.uninit, comesFrom = -1)

proc injectDefaultCalls(n: PNode, c: var Con) =
  case n.kind
  of nkVarSection, nkLetSection:
    for i in 0..<n.len:
      let it = n[i]
      let L = it.len-1
      let ri = it[L]
      if it.kind == nkIdentDefs and ri.kind == nkEmpty:
        computeUninit(c)
        for j in 0..L-2:
          let v = it[j]
          doAssert v.kind == nkSym
          if c.uninit.contains(v.sym.id):
            it[L] = genDefaultCall(v.sym.typ, c, v.info)
            break
  of nkNone..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef, nkMethodDef,
      nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo, nkFuncDef:
    discard
  else:
    for i in 0..<safeLen(n):
      injectDefaultCalls(n[i], c)

proc isCursor(n: PNode): bool {.inline.} =
  result = n.kind == nkSym and sfCursor in n.sym.flags

proc keepVar(n, it: PNode, c: var Con): PNode =
  # keep the var but transform 'ri':
  result = copyNode(n)
  var itCopy = copyNode(it)
  for j in 0..it.len-2:
    itCopy.add it[j]
  itCopy.add p(it[it.len-1], c)
  result.add itCopy

proc p(n: PNode; c: var Con): PNode =
  case n.kind
  of nkVarSection, nkLetSection:
    discard "transform; var x = y to  var x; x op y  where op is a move or copy"
    result = newNodeI(nkStmtList, n.info)

    for i in 0..<n.len:
      let it = n[i]
      let L = it.len
      let ri = it[L-1]
      if it.kind == nkVarTuple and hasDestructor(ri.typ):
        let x = lowerTupleUnpacking(c.graph, it, c.owner)
        result.add p(x, c)
      elif it.kind == nkIdentDefs and hasDestructor(it[0].typ) and not isCursor(it[0]):
        for j in 0..L-3:
          let v = it[j]
          if v.kind == nkSym:
            if sfCompileTime in v.sym.flags: continue
            # move the variable declaration to the top of the frame:
            c.addTopVar v
            # make sure it's destroyed at the end of the proc:
            if not isUnpackedTuple(it[0].sym):
              c.destroys.add genDestroy(c, v.typ, v)
          if ri.kind != nkEmpty:
            let r = moveOrCopy(v, ri, c)
            result.add r
      else:
        result.add keepVar(n, it, c)
  of nkCallKinds:
    let parameters = n[0].typ
    let L = if parameters != nil: parameters.len else: 0
    for i in 1 ..< n.len:
      n.sons[i] = pArg(n[i], c, i < L and isSinkTypeForParam(parameters[i]))
    if n.typ != nil and hasDestructor(n.typ):
      discard "produce temp creation"
      result = newNodeIT(nkStmtListExpr, n.info, n.typ)
      let tmp = getTemp(c, n.typ, n.info)
      var sinkExpr = genSink(c, n.typ, tmp, n)
      sinkExpr.add n
      result.add sinkExpr
      result.add tmp
      c.destroys.add genDestroy(c, n.typ, tmp)
    else:
      result = n
  of nkAsgn, nkFastAsgn:
    if hasDestructor(n[0].typ) and n[1].kind notin {nkProcDef, nkDo, nkLambda, nkClosure}:
      result = moveOrCopy(n[0], n[1], c)
    else:
      result = copyNode(n)
      recurse(n, result)
  of nkNone..nkNilLit, nkTypeSection, nkProcDef, nkConverterDef, nkMethodDef,
      nkIteratorDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo, nkFuncDef:
    result = n
  of nkCast, nkHiddenStdConv, nkHiddenSubConv, nkConv:
    result = copyNode(n)
    # Destination type
    result.add n[0]
    # Analyse the inner expression
    result.add p(n[1], c)
  of nkWhen:
    # This should be a "when nimvm" node.
    result = copyTree(n)
    result[1][0] = p(result[1][0], c)
  of nkRaiseStmt:
    if optNimV2 in c.graph.config.globalOptions and n[0].kind != nkEmpty:
      let t = n[0].typ
      let tmp = getTemp(c, t, n.info)
      var m = genCopyNoCheck(c, t, tmp, n[0])

      m.add p(n[0], c)
      result = newTree(nkStmtList, genWasMoved(tmp, c), m)
      var toDisarm = n[0]
      if toDisarm.kind == nkStmtListExpr: toDisarm = toDisarm.lastSon
      if toDisarm.kind == nkSym and toDisarm.sym.owner == c.owner:
        result.add genWasMoved(toDisarm, c)
      result.add newTree(nkRaiseStmt, tmp)
    else:
      result = copyNode(n)
      recurse(n, result)
  else:
    result = copyNode(n)
    recurse(n, result)

proc extractDestroysForTemporaries(c: Con, destroys: PNode): PNode =
  result = newNodeI(nkStmtList, destroys.info)
  for i in 0 ..< destroys.len:
    if destroys[i][1][0].sym.kind == skTemp:
      result.add destroys[i]
      destroys[i] = c.emptyNode

proc reverseDestroys(destroys: PNode) =
  var reversed: seq[PNode]
  for i in countdown(destroys.len - 1, 0):
    reversed.add(destroys[i])
  destroys.sons = reversed

proc injectDestructorCalls*(g: ModuleGraph; owner: PSym; n: PNode): PNode =
  if sfGeneratedOp in owner.flags or isInlineIterator(owner): return n
  var c: Con
  c.owner = owner
  c.destroys = newNodeI(nkStmtList, n.info)
  c.topLevelVars = newNodeI(nkVarSection, n.info)
  c.graph = g
  c.emptyNode = newNodeI(nkEmpty, n.info)
  let cfg = constructCfg(owner, n)
  shallowCopy(c.g, cfg)
  c.jumpTargets = initIntSet()
  for i in 0..<c.g.len:
    if c.g[i].kind in {goto, fork}:
      c.jumpTargets.incl(i+c.g[i].dest)
  dbg:
    echo "injecting into ", n
    echoCfg(c.g)
  if owner.kind in {skProc, skFunc, skMethod, skIterator, skConverter}:
    let params = owner.typ.n
    for i in 1 ..< params.len:
      let param = params[i].sym
      if isSinkTypeForParam(param.typ) and hasDestructor(param.typ.skipTypes({tySink})):
        c.destroys.add genDestroy(c, param.typ.skipTypes({tyGenericInst, tyAlias, tySink}), params[i])

  #if optNimV2 in c.graph.config.globalOptions:
  #  injectDefaultCalls(n, c)
  let body = p(n, c)
  result = newNodeI(nkStmtList, n.info)
  if c.topLevelVars.len > 0:
    result.add c.topLevelVars
  if c.destroys.len > 0:
    reverseDestroys(c.destroys)
    if owner.kind == skModule:
      result.add newTryFinally(body, extractDestroysForTemporaries(c, c.destroys))
      g.globalDestructors.add c.destroys
    else:
      result.add newTryFinally(body, c.destroys)
  else:
    result.add body

  dbg:
    echo "------------------------------------"
    echo owner.name.s, " transformed to: "
    echo result
