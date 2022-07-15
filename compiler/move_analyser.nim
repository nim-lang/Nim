#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The move analyser analyses which operations can be moves,
## which ones must be copies and which ones can be borrows.

## An assignment `a = b` is a move operation if it is the last read of `b`.
## A "last read of `b`" has two different causes:
## 1. The control flow indicates it; every possible instruction that follows
##    does not use `b`.
## 2. The data flow indicates it; every possible instruction that follows
##    assigns to `b`. Consider:
##
##    a = b; b = x  --> a = move b; wasMoved b; b = x
##
##    a = b;
##    if cond: b = x else: b = y
##

import std / intsets
import ast, renderer, aliasanalysis, trees, parampatterns

type
  BlockLevel = int

#[

Consider:

  block foo:
    # block level 1
    block:
      # block level 2
      if cond:
        break
      else:
        break foo

We seek to merge the "block leave" information. For the entire `if` statement
we know that it leaves the inner block (level 2). Thus we need to take the
maximum.

]#

#[

Some performance indicators: Nim version 1.6 uses
2017 lastRead queries for 11788 procs. This indicates that a lazy approach
is worthwhile and slightly easier to implement.

We know the `use x` we're interested in. We traverse the AST and
copy it, leaving out the irrelevant sections of the `if` statement.

We also translate `break` to a `return` statement when it leaves the scope
we're interested in:

var x = f()

while cond:
  x = g()
  block lab:
    use x
    if cond:
      break lab
    else:
      break lab

As an approximation we model it as "leaves the scope the variable was declared in".
Then all we have to do is to model the `loop` construct. We do this by a backwards
jump. Every backwards jump is run exactly one time. This avoids exponential code
explosions. This is subtle, but correct for nested loops:

  while condA:
    x = def
    while condB:
      discard
    use x

--> we get linear trace of the code we're interested in.

]#

type
  Opcode = enum
    JmpBack, Ret, Store, Load
  Instruction = object
    case opc: Opcode
    of JmpBack:
      intVal: int
    of Ret:
      discard
    of Store, Load:
      mem: PNode

when defined(nimDebugUtils):
  # this allows inserting debugging utilties in all modules that import `options`
  # with a single switch, which is useful when debugging compiler.
  import debugutils, msgs

proc showVm(code: seq[Instruction]; start = 0) =
  var i = 0
  while i < code.len:
    case code[i].opc
    of Ret:
      echo i, " Ret"
    of JmpBack:
      echo i, " JmpBack ", i - code[i].intVal
    of Store:
      echo i, " Store ", renderTree(code[i].mem)
    of Load:
      echo i, " Load ", renderTree(code[i].mem)
      when defined(nimDebugUtils):
        echo getConfigRef() $ code[i].mem.info
    inc i
  echo "Start at ", start

proc interpret(code: seq[Instruction]; start: int; x: PNode): bool =
  # small interpreter loop:
  var i = start
  result = true
  var jmpsHandled = initIntSet()
  var nonDeterministicJump = false
  while i < code.len:
    case code[i].opc
    of Ret:
      result = true
      break
    of JmpBack:
      # jump back a single time:
      if not jmpsHandled.containsOrIncl(i):
        i = i - code[i].intVal
        if i < start: nonDeterministicJump = true
      else:
        inc i
    of Store:
      # store into the location we are interested in?
      # If we look for the last read of 'x', a store to 'x.field' does not help.
      # But if we look for 'x.field' a store to 'x' does:
      if aliases(code[i].mem, x) == yes and not nonDeterministicJump:
        #[ the case `nonDeterministicJump` is required too because if we ever took
           a jump back, the control flow is not deterministic anymore. For example:

           while cond:
             result = value
             # ^ jump back to this line
             use result # this is not the last use!
           useAgain result

        ]#
        result = true
        break
      inc i
    of Load:
      # load of the location we are interested in?
      # if so the usage definitely was not the last one:
      # situation: we found 'x' and want to know if 'x.field' is the last access.
      # or: we found 'x.field' (which reads 'x' too) and want to know if 'x' is the last access:
      if aliases(code[i].mem, x) != no or aliases(x, code[i].mem) != no:
        result = false
        break
      inc i

const
  ReturnBlock = 1
  NoBlock = BlockLevel(high(int))

type
  BlockFlag = enum
    containsUse, containsLeave

  BlockInfo = object
    id: BlockLevel
    leaves: BlockLevel
    writesTo: seq[PNode]
    trace: seq[Instruction]
    entryAt: int
    flags: set[BlockFlag]

  Context = object
    #g: ModuleGraph
    x: PNode
    root: PSym
    currentBlock, usedInBlock: BlockLevel
    inTryStmt: int
    blocks: seq[(PSym, BlockLevel)]
    foundDecl: bool

proc merge(c: var Context; dest: var BlockInfo; branches: openArray[BlockInfo]) =
  var m = branches[0].leaves
  var flags = branches[0].flags
  for i in 1 ..< branches.len:
    m = max(m, branches[i].leaves)
    flags = flags + branches[i].flags
  if m != NoBlock and dest.id >= m:
    dest.leaves = m
  # we synthesize a trace from the alternatives as given in `branches`.
  # There are two case to consider.
  # Case: One branch is definitely the active one as it contains the 'use x'
  # that we care about:
  var selectedBranch = -1
  if containsUse notin dest.flags:
    for i in 0 ..< branches.len:
      if containsUse in branches[i].flags:
        selectedBranch = i
        dest.entryAt = dest.trace.len + branches[selectedBranch].entryAt
        #if dest.leaves == NoBlock:
        #  dest.leaves = branches[i].leaves
        break
  if selectedBranch < 0:
    # assume the worst branch. The worst branch is the one that might perform
    # a read. `interpret` does compute this for us.
    for i in 0 ..< branches.len:
      #if branches[i].trace.len > 0:
      #  showVm(c.p, branches[i].trace, branches[i].entryAt)
      if not interpret(branches[i].trace, branches[i].entryAt, c.x):
        selectedBranch = i
        # keep b.entryAt as it is
        break
  if selectedBranch >= 0:
    dest.trace.add branches[selectedBranch].trace

  if containsLeave notin flags:
    # writes can only be remembered if the blocks don't have `return` or `break`
    # statements:
    for wa in branches[0].writesTo:
      var inBranches = 1
      for i in 1 ..< branches.len:
        for wb in branches[i].writesTo:
          if exprStructuralEquivalent(wa, wb, strictSymEquality=true):
            inc inBranches
            break
      if inBranches == branches.len:
        dest.writesTo.add wa
        dest.trace.add Instruction(opc: Store, mem: wa)
  dest.flags = dest.flags + flags
  if dest.leaves <= c.usedInBlock:
    dest.trace.add Instruction(opc: Ret)

proc traverse(c: var Context; b: var BlockInfo; n: PNode)

template createBlockInfo(): BlockInfo =
  BlockInfo(id: c.currentBlock, leaves: NoBlock, writesTo: @[], trace: @[], entryAt: 0, flags: b.flags)

proc traverseIf(c: var Context; b: var BlockInfo; n: PNode) =
  var branches: seq[BlockInfo] = @[]
  var hasElse = false
  for ch in items(n):
    var thisBranch = createBlockInfo()
    case ch.kind
    of nkElifBranch, nkElifExpr:
      traverse c, thisBranch, ch[0]
      traverse c, thisBranch, ch[1]
    of nkElse, nkElseExpr:
      traverse c, thisBranch, ch[0]
      hasElse = true
    else:
      discard
    branches.add thisBranch
  if not hasElse:
    branches.add createBlockInfo()
  merge c, b, branches

proc traverseConditional(c: var Context; b: var BlockInfo; n: PNode) =
  # (a and b) is the same as (if a: b else: false)
  # (a or b) is the same as (if a: true else: b)
  # Thus we use the current block for `a` and a different one for `b`.
  var branches: seq[BlockInfo] = @[createBlockInfo()]
  traverse c, b, n[1]
  traverse c, branches[0], n[2]
  merge c, b, branches

proc traverseCase(c: var Context; b: var BlockInfo; n: PNode) =
  var branches: seq[BlockInfo] = @[]
  traverse c, b, n[0]
  let isExhaustive = skipTypes(n[0].typ,
    abstractVarRange-{tyTypeDesc}).kind notin {tyFloat..tyFloat128, tyString}
  for i in 1..<n.len:
    let ch = n[i]
    var thisBranch = createBlockInfo()
    case ch.kind
    of nkOfBranch:
      traverse(c, thisBranch, ch.lastSon)
    of nkElifBranch:
      traverse c, thisBranch, ch[0]
      traverse c, thisBranch, ch[1]
    of nkElse:
      traverse(c, thisBranch, ch[0])
    else:
      discard
    branches.add thisBranch
  if not isExhaustive:
    branches.add createBlockInfo()
  merge c, b, branches

proc traverseBreak(c: var Context; b: var BlockInfo; n: PNode) =
  #[

    It can happen that the basic block we start with contains a
    break we cannot understand:

      while cond:
        var x = f()  |
        use x        |  the block we start with
        if x: break  |

    We must treat these break statements like `return` for our purposes.
  ]#
  b.flags.incl containsLeave
  if n[0].kind == nkEmpty:
    if c.blocks.len > 0:
      b.leaves = c.currentBlock
    else:
      b.leaves = ReturnBlock
  else:
    b.leaves = ReturnBlock
    for i in countdown(high(c.blocks), 0):
      if c.blocks[i][0] == n[0].sym:
        b.leaves = c.blocks[i][1]
        break
  if b.leaves <= ReturnBlock:
    b.trace.add Instruction(opc: Ret)

proc traverseBlock(c: var Context; b: var BlockInfo; n: PNode) =
  inc c.currentBlock
  if n[0].kind == nkEmpty:
    c.blocks.add (nil, c.currentBlock)
  else:
    c.blocks.add (n[0].sym, c.currentBlock)
  var branches = @[createBlockInfo()]
  traverse c, branches[0], n[1]
  discard c.blocks.pop()
  dec c.currentBlock
  merge c, b, branches

proc traverseWhile(c: var Context; b: var BlockInfo; n: PNode) =
  inc c.currentBlock
  c.blocks.add (nil, c.currentBlock)
  let pos = b.trace.len
  traverse c, b, n[0]
  var branches = @[createBlockInfo(), createBlockInfo()]
  traverse c, branches[0], n[1]
  discard c.blocks.pop()
  dec c.currentBlock
  merge c, b, branches
  let distance = b.trace.len - pos
  if distance > 0:
    b.trace.add Instruction(opc: JmpBack, intVal: distance)

proc traverseTry(c: var Context; b: var BlockInfo; n: PNode) =
  inc c.inTryStmt
  for ch in items(n):
    traverse(c, b, ch)
  dec c.inTryStmt

proc traverseRaise(c: var Context; b: var BlockInfo; n: PNode) =
  traverse c, b, n[0]
  if c.inTryStmt == 0:
    b.leaves = ReturnBlock
    b.flags.incl containsLeave
    b.trace.add Instruction(opc: Ret)

proc traverseAsgn(c: var Context; b: var BlockInfo; n: PNode) =
  let le = n[0]

  if not isAtom(le):
    # don't forget the case `x[g(use(y))]`:
    for ch in items(le):
      traverse(c, b, ch)

  traverse(c, b, n[1])
  if parampatterns.exprRoot(le) == c.root:
    b.writesTo.add le
    b.trace.add Instruction(opc: Store, mem: le)

proc traverseLocal(c: var Context; b: var BlockInfo; n: PNode) =
  let le = n[0]
  if le.kind != nkSym:
    # handle closures' environment `env`.
    if parampatterns.exprRoot(le) == c.root:
      b.writesTo.add le
      b.trace.add Instruction(opc: Store, mem: le)
  traverse(c, b, n.lastSon)

proc traverse(c: var Context; b: var BlockInfo; n: PNode) =
  case n.kind
  of nkSym:
    if n.sym == c.root:
      b.trace.add Instruction(opc: Load, mem: n)
    if n == c.x:
      b.flags.incl containsUse
      b.entryAt = b.trace.len
      c.usedInBlock = c.currentBlock
  of PathKinds0, PathKinds1:
    # If n is `obj.f` and c.x is the same then model it as `load obj.f`
    # instead of `load obj`. This is a bit questionable ("avoid smart solutions")
    # but much more compatible with the older move analyser that we shipped with 1.6
    # and earlier.
    if n == c.x:
      if n.kind notin PathKinds1:
        for i in 1..<n.len:
          traverse(c, b, n[i])
      b.trace.add Instruction(opc: Load, mem: n)
      b.flags.incl containsUse
      b.entryAt = b.trace.len
      c.usedInBlock = c.currentBlock
    elif exprRoot(n) == c.root:
      if n.kind notin PathKinds1:
        for i in 1..<n.len:
          traverse(c, b, n[i])
      b.trace.add Instruction(opc: Load, mem: n)
    else:
      for ch in items(n):
        traverse(c, b, ch)
  of nkReturnStmt:
    traverse c, b, n[0]
    b.leaves = ReturnBlock
    b.flags.incl containsLeave
    if c.root.kind == skResult:
      b.trace.add Instruction(opc: Load, mem: newSymNode(c.root))
    b.trace.add Instruction(opc: Ret)
  of nkBreakStmt:
    traverseBreak c, b, n
  of nkIfStmt, nkIfExpr:
    traverseIf c, b, n
  of nkCaseStmt:
    traverseCase c, b, n
  of nkCallKinds:
    if getMagic(n) in {mAnd, mOr}:
      traverseConditional c, b, n
    else:
      for ch in items(n):
        traverse c, b, ch
  of nkBlockStmt, nkBlockExpr:
    traverseBlock c, b, n
  of nkAsgn, nkFastAsgn:
    traverseAsgn c, b, n
  of nkVarSection, nkLetSection:
    for ch in items(n):
      traverseLocal c, b, ch
  of nkWhileStmt:
    traverseWhile c, b, n
  of nkTryStmt:
    traverseTry c, b, n
  of nkRaiseStmt:
    traverseRaise c, b, n
  of nkWhen:
    # This should be a "when nimvm" node.
    traverse(c, b, n[1][0])
  of nodesToIgnoreSet:
    discard
  else:
    for ch in items(n):
      traverse(c, b, ch)

proc beginTraverse(c: var Context; b: var BlockInfo; parent, n: PNode; nindex: int) =
  # we search the innermost block that contains the var declaration of the
  # location we're interested in:
  case n.kind
  of nkVarSection, nkLetSection:
    for ch in items(n):
      for j in 0 ..< ch.len - 2:
        let v = ch[j]
        if v.kind == nkSym and v.sym == c.root:
          c.foundDecl = true
          if parent.kind in {nkStmtList, nkStmtListExpr}:
            for i in nindex+1 ..< parent.len:
              traverse(c, b, parent[i])
          else:
            assert(false, "declaration not in statement list position?")
          break
      if not c.foundDecl:
        beginTraverse(c, b, parent, ch.lastSon, nindex)
  of nodesToIgnoreSet:
    discard
  else:
    for i in 0..<n.safeLen:
      beginTraverse(c, b, n, n[i], i)

proc isLastRead*(n, x: PNode): bool =
  let root = parampatterns.exprRoot(x)
  if root == nil: return false

  var c = Context(x: x,
                  currentBlock: ReturnBlock, usedInBlock: ReturnBlock, blocks: @[],
                  foundDecl: false,
                  root: root)
  var b = BlockInfo(id: c.currentBlock, leaves: NoBlock, writesTo: @[], trace: @[], entryAt: 0, flags: {})
  if root.kind == skResult:
    c.foundDecl = true
    traverse(c, b, n)
    b.trace.add Instruction(opc: Load, mem: newSymNode(root))
  elif root.kind == skParam:
    c.foundDecl = true
    traverse(c, b, n)
  else:
    beginTraverse(c, b, n, n, -1)
  if c.foundDecl:
    #showVm(b.trace, b.entryAt)
    result = interpret(b.trace, b.entryAt, x)
    #echo b.flags, " body ", renderTree(n), " x ", renderTree(x)
  else:
    #echo "did not find the declaration ", renderTree(n), " ", renderTree(x)
    result = false
