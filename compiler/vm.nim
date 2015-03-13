#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This file implements the new evaluation engine for Nim code.
## An instruction is 1-3 int32s in memory, it is a register based VM.

const debugEchoCode = false

import ast except getstr

import
  strutils, astalgo, msgs, vmdef, vmgen, nimsets, types, passes, unsigned,
  parser, vmdeps, idents, trees, renderer, options, transf, parseutils

from semfold import leValueConv, ordinalValToString
from evaltempl import evalTemplate

when hasFFI:
  import evalffi

type
  TRegisterKind = enum
    rkNone, rkNode, rkInt, rkFloat, rkRegisterAddr, rkNodeAddr
  TFullReg = object   # with a custom mark proc, we could use the same
                      # data representation as LuaJit (tagged NaNs).
    case kind: TRegisterKind
    of rkNone: nil
    of rkInt: intVal: BiggestInt
    of rkFloat: floatVal: BiggestFloat
    of rkNode: node: PNode
    of rkRegisterAddr: regAddr: ptr TFullReg
    of rkNodeAddr: nodeAddr: ptr PNode

  PStackFrame* = ref TStackFrame
  TStackFrame* = object
    prc: PSym                 # current prc; proc that is evaluated
    slots: seq[TFullReg]      # parameters passed to the proc + locals;
                              # parameters come first
    next: PStackFrame         # for stacking
    comesFrom: int
    safePoints: seq[int]      # used for exception handling
                              # XXX 'break' should perform cleanup actions
                              # What does the C backend do for it?

proc stackTraceAux(c: PCtx; x: PStackFrame; pc: int; recursionLimit=100) =
  if x != nil:
    if recursionLimit == 0:
      var calls = 0
      var x = x
      while x != nil:
        inc calls
        x = x.next
      msgWriteln($calls & " calls omitted\n")
      return
    stackTraceAux(c, x.next, x.comesFrom, recursionLimit-1)
    var info = c.debug[pc]
    # we now use the same format as in system/except.nim
    var s = toFilename(info)
    var line = toLinenumber(info)
    if line > 0:
      add(s, '(')
      add(s, $line)
      add(s, ')')
    if x.prc != nil:
      for k in 1..max(1, 25-s.len): add(s, ' ')
      add(s, x.prc.name.s)
    msgWriteln(s)

proc stackTrace(c: PCtx, tos: PStackFrame, pc: int,
                msg: TMsgKind, arg = "") =
  msgWriteln("stack trace: (most recent call last)")
  stackTraceAux(c, tos, pc)
  # XXX test if we want 'globalError' for every mode
  if c.mode == emRepl: globalError(c.debug[pc], msg, arg)
  else: localError(c.debug[pc], msg, arg)

proc bailOut(c: PCtx; tos: PStackFrame) =
  stackTrace(c, tos, c.exceptionInstr, errUnhandledExceptionX,
             c.currentExceptionA.sons[2].strVal)

when not defined(nimComputedGoto):
  {.pragma: computedGoto.}

proc myreset(n: var TFullReg) = reset(n)

template ensureKind(k: expr) {.immediate, dirty.} =
  if regs[ra].kind != k:
    myreset(regs[ra])
    regs[ra].kind = k

template decodeB(k: expr) {.immediate, dirty.} =
  let rb = instr.regB
  ensureKind(k)

template decodeBC(k: expr) {.immediate, dirty.} =
  let rb = instr.regB
  let rc = instr.regC
  ensureKind(k)

template declBC() {.immediate, dirty.} =
  let rb = instr.regB
  let rc = instr.regC

template decodeBImm(k: expr) {.immediate, dirty.} =
  let rb = instr.regB
  let imm = instr.regC - byteExcess
  ensureKind(k)

template decodeBx(k: expr) {.immediate, dirty.} =
  let rbx = instr.regBx - wordExcess
  ensureKind(k)

template move(a, b: expr) {.immediate, dirty.} = system.shallowCopy(a, b)
# XXX fix minor 'shallowCopy' overloading bug in compiler

proc createStrKeepNode(x: var TFullReg) =
  if x.node.isNil:
    x.node = newNode(nkStrLit)
  elif x.node.kind == nkNilLit:
    when defined(useNodeIds):
      let id = x.node.id
    system.reset(x.node[])
    x.node.kind = nkStrLit
    when defined(useNodeIds):
      x.node.id = id
  elif x.node.kind notin {nkStrLit..nkTripleStrLit} or
      nfAllConst in x.node.flags:
    # XXX this is hacky; tests/txmlgen triggers it:
    x.node = newNode(nkStrLit)
    # It not only hackey, it is also wrong for tgentemplate. The primary
    # cause of bugs like these is that the VM does not properly distinguish
    # between variable defintions (var foo = e) and variable updates (foo = e).

include vmhooks

template createStr(x) =
  x.node = newNode(nkStrLit)

template createSet(x) =
  x.node = newNode(nkCurly)

proc moveConst(x: var TFullReg, y: TFullReg) =
  if x.kind != y.kind:
    myreset(x)
    x.kind = y.kind
  case x.kind
  of rkNone: discard
  of rkInt: x.intVal = y.intVal
  of rkFloat: x.floatVal = y.floatVal
  of rkNode: x.node = y.node
  of rkRegisterAddr: x.regAddr = y.regAddr
  of rkNodeAddr: x.nodeAddr = y.nodeAddr

# this seems to be the best way to model the reference semantics
# of system.NimNode:
template asgnRef(x, y: expr) = moveConst(x, y)

proc copyValue(src: PNode): PNode =
  if src == nil or nfIsRef in src.flags:
    return src
  result = newNode(src.kind)
  result.info = src.info
  result.typ = src.typ
  result.flags = src.flags * PersistentNodeFlags
  when defined(useNodeIds):
    if result.id == nodeIdToDebug:
      echo "COMES FROM ", src.id
  case src.kind
  of nkCharLit..nkUInt64Lit: result.intVal = src.intVal
  of nkFloatLit..nkFloat128Lit: result.floatVal = src.floatVal
  of nkSym: result.sym = src.sym
  of nkIdent: result.ident = src.ident
  of nkStrLit..nkTripleStrLit: result.strVal = src.strVal
  else:
    newSeq(result.sons, sonsLen(src))
    for i in countup(0, sonsLen(src) - 1):
      result.sons[i] = copyValue(src.sons[i])

proc asgnComplex(x: var TFullReg, y: TFullReg) =
  if x.kind != y.kind:
    myreset(x)
    x.kind = y.kind
  case x.kind
  of rkNone: discard
  of rkInt: x.intVal = y.intVal
  of rkFloat: x.floatVal = y.floatVal
  of rkNode: x.node = copyValue(y.node)
  of rkRegisterAddr: x.regAddr = y.regAddr
  of rkNodeAddr: x.nodeAddr = y.nodeAddr

proc putIntoNode(n: var PNode; x: TFullReg) =
  case x.kind
  of rkNone: discard
  of rkInt: n.intVal = x.intVal
  of rkFloat: n.floatVal = x.floatVal
  of rkNode:
    if nfIsRef in x.node.flags: n = x.node
    else: n[] = x.node[]
  of rkRegisterAddr: putIntoNode(n, x.regAddr[])
  of rkNodeAddr: n[] = x.nodeAddr[][]

proc putIntoReg(dest: var TFullReg; n: PNode) =
  case n.kind
  of nkStrLit..nkTripleStrLit:
    dest.kind = rkNode
    createStr(dest)
    dest.node.strVal = n.strVal
  of nkCharLit..nkUInt64Lit:
    dest.kind = rkInt
    dest.intVal = n.intVal
  of nkFloatLit..nkFloat128Lit:
    dest.kind = rkFloat
    dest.floatVal = n.floatVal
  else:
    dest.kind = rkNode
    dest.node = n

proc regToNode(x: TFullReg): PNode =
  case x.kind
  of rkNone: result = newNode(nkEmpty)
  of rkInt: result = newNode(nkIntLit); result.intVal = x.intVal
  of rkFloat: result = newNode(nkFloatLit); result.floatVal = x.floatVal
  of rkNode: result = x.node
  of rkRegisterAddr: result = regToNode(x.regAddr[])
  of rkNodeAddr: result = x.nodeAddr[]

template getstr(a: expr): expr =
  (if a.kind == rkNode: a.node.strVal else: $chr(int(a.intVal)))

proc pushSafePoint(f: PStackFrame; pc: int) =
  if f.safePoints.isNil: f.safePoints = @[]
  f.safePoints.add(pc)

proc popSafePoint(f: PStackFrame) = discard f.safePoints.pop()

proc cleanUpOnException(c: PCtx; tos: PStackFrame):
                                              tuple[pc: int, f: PStackFrame] =
  let raisedType = c.currentExceptionA.typ.skipTypes(abstractPtrs)
  var f = tos
  while true:
    while f.safePoints.isNil or f.safePoints.len == 0:
      f = f.next
      if f.isNil: return (-1, nil)
    var pc2 = f.safePoints[f.safePoints.high]

    var nextExceptOrFinally = -1
    if c.code[pc2].opcode == opcExcept:
      nextExceptOrFinally = pc2 + c.code[pc2].regBx - wordExcess
      inc pc2
    while c.code[pc2].opcode == opcExcept:
      let exceptType = c.types[c.code[pc2].regBx-wordExcess].skipTypes(
                          abstractPtrs)
      if inheritanceDiff(exceptType, raisedType) <= 0:
        # mark exception as handled but keep it in B for
        # the getCurrentException() builtin:
        c.currentExceptionB = c.currentExceptionA
        c.currentExceptionA = nil
        # execute the corresponding handler:
        while c.code[pc2].opcode == opcExcept: inc pc2
        return (pc2, f)
      inc pc2
      if c.code[pc2].opcode != opcExcept and nextExceptOrFinally >= 0:
        # we're at the end of the *except list*, but maybe there is another
        # *except branch*?
        pc2 = nextExceptOrFinally+1
        if c.code[pc2].opcode == opcExcept:
          nextExceptOrFinally = pc2 + c.code[pc2].regBx - wordExcess

    if nextExceptOrFinally >= 0:
      pc2 = nextExceptOrFinally
    if c.code[pc2].opcode == opcFinally:
      # execute the corresponding handler, but don't quit walking the stack:
      return (pc2, f)
    # not the right one:
    discard f.safePoints.pop

proc cleanUpOnReturn(c: PCtx; f: PStackFrame): int =
  if f.safePoints.isNil: return -1
  for s in f.safePoints:
    var pc = s
    while c.code[pc].opcode == opcExcept:
      pc = pc + c.code[pc].regBx - wordExcess
    if c.code[pc].opcode == opcFinally:
      return pc
  return -1

proc opConv*(dest: var TFullReg, src: TFullReg, desttyp, srctyp: PType): bool =
  if desttyp.kind == tyString:
    if dest.kind != rkNode:
      myreset(dest)
      dest.kind = rkNode
    dest.node = newNode(nkStrLit)
    let styp = srctyp.skipTypes(abstractRange)
    case styp.kind
    of tyEnum:
      let n = styp.n
      let x = src.intVal.int
      if x <% n.len and (let f = n.sons[x].sym; f.position == x):
        dest.node.strVal = if f.ast.isNil: f.name.s else: f.ast.strVal
      else:
        for i in 0.. <n.len:
          if n.sons[i].kind != nkSym: internalError("opConv for enum")
          let f = n.sons[i].sym
          if f.position == x:
            dest.node.strVal = if f.ast.isNil: f.name.s else: f.ast.strVal
            return
        internalError("opConv for enum")
    of tyInt..tyInt64:
      dest.node.strVal = $src.intVal
    of tyUInt..tyUInt64:
      dest.node.strVal = $uint64(src.intVal)
    of tyBool:
      dest.node.strVal = if src.intVal == 0: "false" else: "true"
    of tyFloat..tyFloat128:
      dest.node.strVal = $src.floatVal
    of tyString, tyCString:
      dest.node.strVal = src.node.strVal
    of tyChar:
      dest.node.strVal = $chr(src.intVal)
    else:
      internalError("cannot convert to string " & desttyp.typeToString)
  else:
    case skipTypes(desttyp, abstractRange).kind
    of tyInt..tyInt64:
      if dest.kind != rkInt:
        myreset(dest); dest.kind = rkInt
      case skipTypes(srctyp, abstractRange).kind
      of tyFloat..tyFloat64:
        dest.intVal = int(src.floatVal)
      else:
        dest.intVal = src.intVal
      if dest.intVal < firstOrd(desttyp) or dest.intVal > lastOrd(desttyp):
        return true
    of tyUInt..tyUInt64:
      if dest.kind != rkInt:
        myreset(dest); dest.kind = rkInt
      case skipTypes(srctyp, abstractRange).kind
      of tyFloat..tyFloat64:
        dest.intVal = int(src.floatVal)
      else:
        dest.intVal = src.intVal and ((1 shl (desttyp.size*8))-1)
    of tyFloat..tyFloat64:
      if dest.kind != rkFloat:
        myreset(dest); dest.kind = rkFloat
      case skipTypes(srctyp, abstractRange).kind
      of tyInt..tyInt64, tyUInt..tyUInt64, tyEnum, tyBool, tyChar:
        dest.floatVal = toFloat(src.intVal.int)
      else:
        dest.floatVal = src.floatVal
    else:
      asgnComplex(dest, src)

proc compile(c: PCtx, s: PSym): int =
  result = vmgen.genProc(c, s)
  when debugEchoCode: c.echoCode result
  #c.echoCode

template handleJmpBack() {.dirty.} =
  if c.loopIterations <= 0:
    if allowInfiniteLoops in c.features:
      c.loopIterations = MaxLoopIterations
    else:
      msgWriteln("stack trace: (most recent call last)")
      stackTraceAux(c, tos, pc)
      globalError(c.debug[pc], errTooManyIterations)
  dec(c.loopIterations)

proc skipColon(n: PNode): PNode =
  result = n
  if n.kind == nkExprColonExpr:
    result = n.sons[1]

proc rawExecute(c: PCtx, start: int, tos: PStackFrame): TFullReg =
  var pc = start
  var tos = tos
  var regs: seq[TFullReg] # alias to tos.slots for performance
  move(regs, tos.slots)
  #echo "NEW RUN ------------------------"
  while true:
    #{.computedGoto.}
    let instr = c.code[pc]
    let ra = instr.regA
    #if c.traceActive:
    #  echo "PC ", pc, " ", c.code[pc].opcode, " ra ", ra
    #  message(c.debug[pc], warnUser, "Trace")
    case instr.opcode
    of opcEof: return regs[ra]
    of opcRet:
      # XXX perform any cleanup actions
      pc = tos.comesFrom
      tos = tos.next
      let retVal = regs[0]
      if tos.isNil:
        #echo "RET ", retVal.rendertree
        return retVal

      move(regs, tos.slots)
      assert c.code[pc].opcode in {opcIndCall, opcIndCallAsgn}
      if c.code[pc].opcode == opcIndCallAsgn:
        regs[c.code[pc].regA] = retVal
        #echo "RET2 ", retVal.rendertree, " ", c.code[pc].regA
    of opcYldYoid: assert false
    of opcYldVal: assert false
    of opcAsgnInt:
      decodeB(rkInt)
      regs[ra].intVal = regs[rb].intVal
    of opcAsgnStr:
      decodeB(rkNode)
      createStrKeepNode regs[ra]
      regs[ra].node.strVal = regs[rb].node.strVal
    of opcAsgnFloat:
      decodeB(rkFloat)
      regs[ra].floatVal = regs[rb].floatVal
    of opcAsgnComplex:
      asgnComplex(regs[ra], regs[instr.regB])
    of opcAsgnRef:
      asgnRef(regs[ra], regs[instr.regB])
    of opcRegToNode:
      decodeB(rkNode)
      putIntoNode(regs[ra].node, regs[rb])
    of opcNodeToReg:
      let ra = instr.regA
      let rb = instr.regB
      # opcDeref might already have loaded it into a register. XXX Let's hope
      # this is still correct this way:
      if regs[rb].kind != rkNode:
        regs[ra] = regs[rb]
      else:
        assert regs[rb].kind == rkNode
        let nb = regs[rb].node
        case nb.kind
        of nkCharLit..nkInt64Lit:
          ensureKind(rkInt)
          regs[ra].intVal = nb.intVal
        of nkFloatLit..nkFloat64Lit:
          ensureKind(rkFloat)
          regs[ra].floatVal = nb.floatVal
        else:
          ensureKind(rkNode)
          regs[ra].node = nb
    of opcLdArr:
      # a = b[c]
      decodeBC(rkNode)
      if regs[rc].intVal > high(int):
        stackTrace(c, tos, pc, errIndexOutOfBounds)
      let idx = regs[rc].intVal.int
      let src = regs[rb].node
      if src.kind notin {nkEmpty..nkNilLit} and idx <% src.len:
        regs[ra].node = src.sons[idx]
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcLdStrIdx:
      decodeBC(rkInt)
      let idx = regs[rc].intVal.int
      let s = regs[rb].node.strVal
      if s.isNil:
        stackTrace(c, tos, pc, errNilAccess)
      elif idx <=% s.len:
        regs[ra].intVal = s[idx].ord
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcWrArr:
      # a[b] = c
      decodeBC(rkNode)
      let idx = regs[rb].intVal.int
      if idx <% regs[ra].node.len:
        putIntoNode(regs[ra].node.sons[idx], regs[rc])
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcLdObj:
      # a = b.c
      decodeBC(rkNode)
      let src = regs[rb].node
      if src.kind notin {nkEmpty..nkNilLit}:
        let n = src.sons[rc].skipColon
        regs[ra].node = n
      else:
        stackTrace(c, tos, pc, errNilAccess)
    of opcWrObj:
      # a.b = c
      decodeBC(rkNode)
      putIntoNode(regs[ra].node.sons[rb], regs[rc])
    of opcWrStrIdx:
      decodeBC(rkNode)
      let idx = regs[rb].intVal.int
      if idx <% regs[ra].node.strVal.len:
        regs[ra].node.strVal[idx] = chr(regs[rc].intVal)
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcAddrReg:
      decodeB(rkRegisterAddr)
      regs[ra].regAddr = addr(regs[rb])
    of opcAddrNode:
      decodeB(rkNodeAddr)
      regs[ra].nodeAddr = addr(regs[rb].node)
    of opcLdDeref:
      # a = b[]
      let ra = instr.regA
      let rb = instr.regB
      case regs[rb].kind
      of rkNodeAddr:
        ensureKind(rkNode)
        regs[ra].node = regs[rb].nodeAddr[]
      of rkRegisterAddr:
        ensureKind(regs[rb].regAddr.kind)
        regs[ra] = regs[rb].regAddr[]
      of rkNode:
        if regs[rb].node.kind == nkNilLit:
          stackTrace(c, tos, pc, errNilAccess)
        assert regs[rb].node.kind == nkRefTy
        regs[ra].node = regs[rb].node.sons[0]
      else:
        stackTrace(c, tos, pc, errNilAccess)
    of opcWrDeref:
      # a[] = c; b unused
      let ra = instr.regA
      let rc = instr.regC
      case regs[ra].kind
      of rkNodeAddr: putIntoNode(regs[ra].nodeAddr[], regs[rc])
      of rkRegisterAddr: regs[ra].regAddr[] = regs[rc]
      of rkNode: putIntoNode(regs[ra].node, regs[rc])
      else: stackTrace(c, tos, pc, errNilAccess)
    of opcAddInt:
      decodeBC(rkInt)
      let
        bVal = regs[rb].intVal
        cVal = regs[rc].intVal
        sum = bVal +% cVal
      if (sum xor bVal) >= 0 or (sum xor cVal) >= 0:
        regs[ra].intVal = sum
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcAddImmInt:
      decodeBImm(rkInt)
      #message(c.debug[pc], warnUser, "came here")
      #debug regs[rb].node
      let
        bVal = regs[rb].intVal
        cVal = imm
        sum = bVal +% cVal
      if (sum xor bVal) >= 0 or (sum xor cVal) >= 0:
        regs[ra].intVal = sum
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcSubInt:
      decodeBC(rkInt)
      let
        bVal = regs[rb].intVal
        cVal = regs[rc].intVal
        diff = bVal -% cVal
      if (diff xor bVal) >= 0 or (diff xor not cVal) >= 0:
        regs[ra].intVal = diff
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcSubImmInt:
      decodeBImm(rkInt)
      let
        bVal = regs[rb].intVal
        cVal = imm
        diff = bVal -% cVal
      if (diff xor bVal) >= 0 or (diff xor not cVal) >= 0:
        regs[ra].intVal = diff
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcLenSeq:
      decodeBImm(rkInt)
      #assert regs[rb].kind == nkBracket
      # also used by mNLen:
      regs[ra].intVal = regs[rb].node.safeLen - imm
    of opcLenStr:
      decodeBImm(rkInt)
      assert regs[rb].kind == rkNode
      regs[ra].intVal = regs[rb].node.strVal.len - imm
    of opcIncl:
      decodeB(rkNode)
      let b = regs[rb].regToNode
      if not inSet(regs[ra].node, b):
        addSon(regs[ra].node, copyTree(b))
    of opcInclRange:
      decodeBC(rkNode)
      var r = newNode(nkRange)
      r.add regs[rb].regToNode
      r.add regs[rc].regToNode
      addSon(regs[ra].node, r.copyTree)
    of opcExcl:
      decodeB(rkNode)
      var b = newNodeIT(nkCurly, regs[rb].node.info, regs[rb].node.typ)
      addSon(b, regs[rb].regToNode)
      var r = diffSets(regs[ra].node, b)
      discardSons(regs[ra].node)
      for i in countup(0, sonsLen(r) - 1): addSon(regs[ra].node, r.sons[i])
    of opcCard:
      decodeB(rkInt)
      regs[ra].intVal = nimsets.cardSet(regs[rb].node)
    of opcMulInt:
      decodeBC(rkInt)
      let
        bVal = regs[rb].intVal
        cVal = regs[rc].intVal
        product = bVal *% cVal
        floatProd = toBiggestFloat(bVal) * toBiggestFloat(cVal)
        resAsFloat = toBiggestFloat(product)
      if resAsFloat == floatProd:
        regs[ra].intVal = product
      elif 32.0 * abs(resAsFloat - floatProd) <= abs(floatProd):
        regs[ra].intVal = product
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcDivInt:
      decodeBC(rkInt)
      if regs[rc].intVal == 0: stackTrace(c, tos, pc, errConstantDivisionByZero)
      else: regs[ra].intVal = regs[rb].intVal div regs[rc].intVal
    of opcModInt:
      decodeBC(rkInt)
      if regs[rc].intVal == 0: stackTrace(c, tos, pc, errConstantDivisionByZero)
      else: regs[ra].intVal = regs[rb].intVal mod regs[rc].intVal
    of opcAddFloat:
      decodeBC(rkFloat)
      regs[ra].floatVal = regs[rb].floatVal + regs[rc].floatVal
    of opcSubFloat:
      decodeBC(rkFloat)
      regs[ra].floatVal = regs[rb].floatVal - regs[rc].floatVal
    of opcMulFloat:
      decodeBC(rkFloat)
      regs[ra].floatVal = regs[rb].floatVal * regs[rc].floatVal
    of opcDivFloat:
      decodeBC(rkFloat)
      regs[ra].floatVal = regs[rb].floatVal / regs[rc].floatVal
    of opcShrInt:
      decodeBC(rkInt)
      regs[ra].intVal = regs[rb].intVal shr regs[rc].intVal
    of opcShlInt:
      decodeBC(rkInt)
      regs[ra].intVal = regs[rb].intVal shl regs[rc].intVal
    of opcBitandInt:
      decodeBC(rkInt)
      regs[ra].intVal = regs[rb].intVal and regs[rc].intVal
    of opcBitorInt:
      decodeBC(rkInt)
      regs[ra].intVal = regs[rb].intVal or regs[rc].intVal
    of opcBitxorInt:
      decodeBC(rkInt)
      regs[ra].intVal = regs[rb].intVal xor regs[rc].intVal
    of opcAddu:
      decodeBC(rkInt)
      regs[ra].intVal = regs[rb].intVal +% regs[rc].intVal
    of opcSubu:
      decodeBC(rkInt)
      regs[ra].intVal = regs[rb].intVal -% regs[rc].intVal
    of opcMulu:
      decodeBC(rkInt)
      regs[ra].intVal = regs[rb].intVal *% regs[rc].intVal
    of opcDivu:
      decodeBC(rkInt)
      regs[ra].intVal = regs[rb].intVal /% regs[rc].intVal
    of opcModu:
      decodeBC(rkInt)
      regs[ra].intVal = regs[rb].intVal %% regs[rc].intVal
    of opcEqInt:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].intVal == regs[rc].intVal)
    of opcLeInt:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].intVal <= regs[rc].intVal)
    of opcLtInt:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].intVal < regs[rc].intVal)
    of opcEqFloat:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].floatVal == regs[rc].floatVal)
    of opcLeFloat:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].floatVal <= regs[rc].floatVal)
    of opcLtFloat:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].floatVal < regs[rc].floatVal)
    of opcLeu:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].intVal <=% regs[rc].intVal)
    of opcLtu:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].intVal <% regs[rc].intVal)
    of opcEqRef, opcEqNimrodNode:
      decodeBC(rkInt)
      regs[ra].intVal = ord((regs[rb].node.kind == nkNilLit and
                             regs[rc].node.kind == nkNilLit) or
                             regs[rb].node == regs[rc].node)
    of opcXor:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].intVal != regs[rc].intVal)
    of opcNot:
      decodeB(rkInt)
      assert regs[rb].kind == rkInt
      regs[ra].intVal = 1 - regs[rb].intVal
    of opcUnaryMinusInt:
      decodeB(rkInt)
      assert regs[rb].kind == rkInt
      let val = regs[rb].intVal
      if val != int64.low:
        regs[ra].intVal = -val
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcUnaryMinusFloat:
      decodeB(rkFloat)
      assert regs[rb].kind == rkFloat
      regs[ra].floatVal = -regs[rb].floatVal
    of opcBitnotInt:
      decodeB(rkInt)
      assert regs[rb].kind == rkInt
      regs[ra].intVal = not regs[rb].intVal
    of opcEqStr:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].node.strVal == regs[rc].node.strVal)
    of opcLeStr:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].node.strVal <= regs[rc].node.strVal)
    of opcLtStr:
      decodeBC(rkInt)
      regs[ra].intVal = ord(regs[rb].node.strVal < regs[rc].node.strVal)
    of opcLeSet:
      decodeBC(rkInt)
      regs[ra].intVal = ord(containsSets(regs[rb].node, regs[rc].node))
    of opcEqSet:
      decodeBC(rkInt)
      regs[ra].intVal = ord(equalSets(regs[rb].node, regs[rc].node))
    of opcLtSet:
      decodeBC(rkInt)
      let a = regs[rb].node
      let b = regs[rc].node
      regs[ra].intVal = ord(containsSets(a, b) and not equalSets(a, b))
    of opcMulSet:
      decodeBC(rkNode)
      createSet(regs[ra])
      move(regs[ra].node.sons,
            nimsets.intersectSets(regs[rb].node, regs[rc].node).sons)
    of opcPlusSet:
      decodeBC(rkNode)
      createSet(regs[ra])
      move(regs[ra].node.sons,
           nimsets.unionSets(regs[rb].node, regs[rc].node).sons)
    of opcMinusSet:
      decodeBC(rkNode)
      createSet(regs[ra])
      move(regs[ra].node.sons,
           nimsets.diffSets(regs[rb].node, regs[rc].node).sons)
    of opcSymdiffSet:
      decodeBC(rkNode)
      createSet(regs[ra])
      move(regs[ra].node.sons,
           nimsets.symdiffSets(regs[rb].node, regs[rc].node).sons)
    of opcConcatStr:
      decodeBC(rkNode)
      createStr regs[ra]
      regs[ra].node.strVal = getstr(regs[rb])
      for i in rb+1..rb+rc-1:
        regs[ra].node.strVal.add getstr(regs[i])
    of opcAddStrCh:
      decodeB(rkNode)
      #createStrKeepNode regs[ra]
      regs[ra].node.strVal.add(regs[rb].intVal.chr)
    of opcAddStrStr:
      decodeB(rkNode)
      #createStrKeepNode regs[ra]
      regs[ra].node.strVal.add(regs[rb].node.strVal)
    of opcAddSeqElem:
      decodeB(rkNode)
      if regs[ra].node.kind == nkBracket:
        regs[ra].node.add(copyTree(regs[rb].regToNode))
      else:
        stackTrace(c, tos, pc, errNilAccess)
    of opcEcho:
      let rb = instr.regB
      if rb == 1:
        msgWriteln(regs[ra].node.strVal)
      else:
        var outp = ""
        for i in ra..ra+rb-1:
          #if regs[i].kind != rkNode: debug regs[i]
          outp.add(regs[i].node.strVal)
        msgWriteln(outp)
    of opcContainsSet:
      decodeBC(rkInt)
      regs[ra].intVal = ord(inSet(regs[rb].node, regs[rc].regToNode))
    of opcSubStr:
      decodeBC(rkNode)
      inc pc
      assert c.code[pc].opcode == opcSubStr
      let rd = c.code[pc].regA
      createStr regs[ra]
      regs[ra].node.strVal = substr(regs[rb].node.strVal,
                                    regs[rc].intVal.int, regs[rd].intVal.int)
    of opcParseFloat:
      decodeBC(rkInt)
      inc pc
      assert c.code[pc].opcode == opcParseFloat
      let rd = c.code[pc].regA
      var rcAddr = addr(regs[rc])
      if rcAddr.kind == rkRegisterAddr: rcAddr = rcAddr.regAddr
      elif regs[rc].kind != rkFloat:
        myreset(regs[rc])
        regs[rc].kind = rkFloat
      regs[ra].intVal = parseBiggestFloat(regs[rb].node.strVal,
                                          rcAddr.floatVal, regs[rd].intVal.int)
    of opcRangeChck:
      let rb = instr.regB
      let rc = instr.regC
      if not (leValueConv(regs[rb].regToNode, regs[ra].regToNode) and
              leValueConv(regs[ra].regToNode, regs[rc].regToNode)):
        stackTrace(c, tos, pc, errGenerated,
          msgKindToString(errIllegalConvFromXtoY) % [
          $regs[ra].regToNode, "[" & $regs[rb].regToNode & ".." & $regs[rc].regToNode & "]"])
    of opcIndCall, opcIndCallAsgn:
      # dest = call regStart, n; where regStart = fn, arg1, ...
      let rb = instr.regB
      let rc = instr.regC
      let bb = regs[rb].node
      let isClosure = bb.kind == nkPar
      let prc = if not isClosure: bb.sym else: bb.sons[0].sym
      if prc.offset < -1:
        # it's a callback:
        c.callbacks[-prc.offset-2].value(
          VmArgs(ra: ra, rb: rb, rc: rc, slots: cast[pointer](regs),
                 currentException: c.currentExceptionB))
      elif sfImportc in prc.flags:
        if allowFFI notin c.features:
          globalError(c.debug[pc], errGenerated, "VM not allowed to do FFI")
        # we pass 'tos.slots' instead of 'regs' so that the compiler can keep
        # 'regs' in a register:
        when hasFFI:
          let prcValue = c.globals.sons[prc.position-1]
          if prcValue.kind == nkEmpty:
            globalError(c.debug[pc], errGenerated, "canot run " & prc.name.s)
          let newValue = callForeignFunction(prcValue, prc.typ, tos.slots,
                                             rb+1, rc-1, c.debug[pc])
          if newValue.kind != nkEmpty:
            assert instr.opcode == opcIndCallAsgn
            putIntoReg(regs[ra], newValue)
        else:
          globalError(c.debug[pc], errGenerated, "VM not built with FFI support")
      elif prc.kind != skTemplate:
        let newPc = compile(c, prc)
        # tricky: a recursion is also a jump back, so we use the same
        # logic as for loops:
        if newPc < pc: handleJmpBack()
        #echo "new pc ", newPc, " calling: ", prc.name.s
        var newFrame = PStackFrame(prc: prc, comesFrom: pc, next: tos)
        newSeq(newFrame.slots, prc.offset)
        if not isEmptyType(prc.typ.sons[0]) or prc.kind == skMacro:
          putIntoReg(newFrame.slots[0], getNullValue(prc.typ.sons[0], prc.info))
        for i in 1 .. rc-1:
          newFrame.slots[i] = regs[rb+i]
        if isClosure:
          newFrame.slots[rc].kind = rkNode
          newFrame.slots[rc].node = regs[rb].node.sons[1]
        tos = newFrame
        move(regs, newFrame.slots)
        # -1 for the following 'inc pc'
        pc = newPc-1
      else:
        # for 'getAst' support we need to support template expansion here:
        let genSymOwner = if tos.next != nil and tos.next.prc != nil:
                            tos.next.prc
                          else:
                            c.module
        var macroCall = newNodeI(nkCall, c.debug[pc])
        macroCall.add(newSymNode(prc))
        for i in 1 .. rc-1: macroCall.add(regs[rb+i].regToNode)
        let a = evalTemplate(macroCall, prc, genSymOwner)
        ensureKind(rkNode)
        regs[ra].node = a
    of opcTJmp:
      # jump Bx if A != 0
      let rbx = instr.regBx - wordExcess - 1 # -1 for the following 'inc pc'
      if regs[ra].intVal != 0:
        inc pc, rbx
    of opcFJmp:
      # jump Bx if A == 0
      let rbx = instr.regBx - wordExcess - 1 # -1 for the following 'inc pc'
      if regs[ra].intVal == 0:
        inc pc, rbx
    of opcJmp:
      # jump Bx
      let rbx = instr.regBx - wordExcess - 1 # -1 for the following 'inc pc'
      inc pc, rbx
    of opcJmpBack:
      let rbx = instr.regBx - wordExcess - 1 # -1 for the following 'inc pc'
      inc pc, rbx
      handleJmpBack()
    of opcBranch:
      # we know the next instruction is a 'fjmp':
      let branch = c.constants[instr.regBx-wordExcess]
      var cond = false
      for j in countup(0, sonsLen(branch) - 2):
        if overlap(regs[ra].regToNode, branch.sons[j]):
          cond = true
          break
      assert c.code[pc+1].opcode == opcFJmp
      inc pc
      # we skip this instruction so that the final 'inc(pc)' skips
      # the following jump
      if not cond:
        let instr2 = c.code[pc]
        let rbx = instr2.regBx - wordExcess - 1 # -1 for the following 'inc pc'
        inc pc, rbx
    of opcTry:
      let rbx = instr.regBx - wordExcess
      tos.pushSafePoint(pc + rbx)
      assert c.code[pc+rbx].opcode in {opcExcept, opcFinally}
    of opcExcept:
      # just skip it; it's followed by a jump;
      # we'll execute in the 'raise' handler
      let rbx = instr.regBx - wordExcess - 1 # -1 for the following 'inc pc'
      inc pc, rbx
      assert c.code[pc+1].opcode in {opcExcept, opcFinally}
    of opcFinally:
      # just skip it; it's followed by the code we need to execute anyway
      tos.popSafePoint()
    of opcFinallyEnd:
      if c.currentExceptionA != nil:
        # we are in a cleanup run:
        let (newPc, newTos) = cleanUpOnException(c, tos)
        if newPc-1 < 0:
          bailOut(c, tos)
          return
        pc = newPc-1
        if tos != newTos:
          tos = newTos
          move(regs, tos.slots)
    of opcRaise:
      let raised = regs[ra].node
      c.currentExceptionA = raised
      c.exceptionInstr = pc
      let (newPc, newTos) = cleanUpOnException(c, tos)
      # -1 because of the following 'inc'
      if newPc-1 < 0:
        bailOut(c, tos)
        return
      pc = newPc-1
      if tos != newTos:
        tos = newTos
        move(regs, tos.slots)
    of opcNew:
      ensureKind(rkNode)
      let typ = c.types[instr.regBx - wordExcess]
      regs[ra].node = getNullValue(typ, c.debug[pc])
      regs[ra].node.flags.incl nfIsRef
    of opcNewSeq:
      let typ = c.types[instr.regBx - wordExcess]
      inc pc
      ensureKind(rkNode)
      let instr2 = c.code[pc]
      let count = regs[instr2.regA].intVal.int
      regs[ra].node = newNodeI(nkBracket, c.debug[pc])
      regs[ra].node.typ = typ
      newSeq(regs[ra].node.sons, count)
      for i in 0 .. <count:
        regs[ra].node.sons[i] = getNullValue(typ.sons[0], c.debug[pc])
    of opcNewStr:
      decodeB(rkNode)
      regs[ra].node = newNodeI(nkStrLit, c.debug[pc])
      regs[ra].node.strVal = newString(regs[rb].intVal.int)
    of opcLdImmInt:
      # dest = immediate value
      decodeBx(rkInt)
      regs[ra].intVal = rbx
    of opcLdNull:
      ensureKind(rkNode)
      let typ = c.types[instr.regBx - wordExcess]
      regs[ra].node = getNullValue(typ, c.debug[pc])
      # opcLdNull really is the gist of the VM's problems: should it load
      # a fresh null to  regs[ra].node  or to regs[ra].node[]? This really
      # depends on whether regs[ra] represents the variable itself or wether
      # it holds the indirection! Due to the way registers are re-used we cannot
      # say for sure here! --> The codegen has to deal with it
      # via 'genAsgnPatch'.
    of opcLdNullReg:
      let typ = c.types[instr.regBx - wordExcess]
      if typ.skipTypes(abstractInst+{tyRange}-{tyTypeDesc}).kind in {
          tyFloat..tyFloat128}:
        ensureKind(rkFloat)
        regs[ra].floatVal = 0.0
      else:
        ensureKind(rkInt)
        regs[ra].intVal = 0
    of opcLdConst:
      let rb = instr.regBx - wordExcess
      let cnst = c.constants.sons[rb]
      if fitsRegister(cnst.typ):
        myreset(regs[ra])
        putIntoReg(regs[ra], cnst)
      else:
        ensureKind(rkNode)
        regs[ra].node = cnst
    of opcAsgnConst:
      let rb = instr.regBx - wordExcess
      let cnst = c.constants.sons[rb]
      if fitsRegister(cnst.typ):
        putIntoReg(regs[ra], cnst)
      else:
        ensureKind(rkNode)
        regs[ra].node = cnst.copyTree
    of opcLdGlobal:
      let rb = instr.regBx - wordExcess - 1
      ensureKind(rkNode)
      regs[ra].node = c.globals.sons[rb]
    of opcLdGlobalAddr:
      let rb = instr.regBx - wordExcess - 1
      ensureKind(rkNodeAddr)
      regs[ra].nodeAddr = addr(c.globals.sons[rb])
    of opcRepr:
      decodeB(rkNode)
      createStr regs[ra]
      regs[ra].node.strVal = renderTree(regs[rb].regToNode, {renderNoComments})
    of opcQuit:
      if c.mode in {emRepl, emStaticExpr, emStaticStmt}:
        message(c.debug[pc], hintQuitCalled)
        msgQuit(int8(getOrdValue(regs[ra].regToNode)))
      else:
        return TFullReg(kind: rkNone)
    of opcSetLenStr:
      decodeB(rkNode)
      #createStrKeepNode regs[ra]
      regs[ra].node.strVal.setLen(regs[rb].intVal.int)
    of opcOf:
      decodeBC(rkInt)
      let typ = c.types[regs[rc].intVal.int]
      regs[ra].intVal = ord(inheritanceDiff(regs[rb].node.typ, typ) >= 0)
    of opcIs:
      decodeBC(rkInt)
      let t1 = regs[rb].node.typ.skipTypes({tyTypeDesc})
      let t2 = c.types[regs[rc].intVal.int]
      # XXX: This should use the standard isOpImpl
      let match = if t2.kind == tyUserTypeClass: true
                  else: sameType(t1, t2)
      regs[ra].intVal = ord(match)
    of opcSetLenSeq:
      decodeB(rkNode)
      let newLen = regs[rb].intVal.int
      if regs[ra].node.isNil: stackTrace(c, tos, pc, errNilAccess)
      else: setLen(regs[ra].node.sons, newLen)
    of opcSwap:
      let rb = instr.regB
      if regs[ra].kind == regs[rb].kind:
        case regs[ra].kind
        of rkNone: discard
        of rkInt: swap regs[ra].intVal, regs[rb].intVal
        of rkFloat: swap regs[ra].floatVal, regs[rb].floatVal
        of rkNode: swap regs[ra].node, regs[rb].node
        of rkRegisterAddr: swap regs[ra].regAddr, regs[rb].regAddr
        of rkNodeAddr: swap regs[ra].nodeAddr, regs[rb].nodeAddr
      else:
        internalError(c.debug[pc], "cannot swap operands")
    of opcReset:
      internalError(c.debug[pc], "too implement")
    of opcNarrowS:
      decodeB(rkInt)
      let min = -(1.BiggestInt shl (rb-1))
      let max = (1.BiggestInt shl (rb-1))-1
      if regs[ra].intVal < min or regs[ra].intVal > max:
        stackTrace(c, tos, pc, errGenerated,
          msgKindToString(errUnhandledExceptionX) % "value out of range")
    of opcNarrowU:
      decodeB(rkInt)
      regs[ra].intVal = regs[ra].intVal and ((1'i64 shl rb)-1)
    of opcIsNil:
      decodeB(rkInt)
      let node = regs[rb].node
      regs[ra].intVal = ord(node.kind == nkNilLit or
        (node.kind in {nkStrLit..nkTripleStrLit} and node.strVal.isNil))
    of opcNBindSym:
      decodeBx(rkNode)
      regs[ra].node = copyTree(c.constants.sons[rbx])
    of opcNChild:
      decodeBC(rkNode)
      let idx = regs[rc].intVal.int
      let src = regs[rb].node
      if src.kind notin {nkEmpty..nkNilLit} and idx <% src.len:
        regs[ra].node = src.sons[idx]
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcNSetChild:
      decodeBC(rkNode)
      let idx = regs[rb].intVal.int
      var dest = regs[ra].node
      if dest.kind notin {nkEmpty..nkNilLit} and idx <% dest.len:
        dest.sons[idx] = regs[rc].node
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcNAdd:
      decodeBC(rkNode)
      var u = regs[rb].node
      if u.kind notin {nkEmpty..nkNilLit}:
        u.add(regs[rc].node)
      else:
        stackTrace(c, tos, pc, errGenerated, "cannot add to node kind: " & $u.kind)
      regs[ra].node = u
    of opcNAddMultiple:
      decodeBC(rkNode)
      let x = regs[rc].node
      var u = regs[rb].node
      if u.kind notin {nkEmpty..nkNilLit}:
        # XXX can be optimized:
        for i in 0.. <x.len: u.add(x.sons[i])
      else:
        stackTrace(c, tos, pc, errGenerated, "cannot add to node kind: " & $u.kind)
      regs[ra].node = u
    of opcNKind:
      decodeB(rkInt)
      regs[ra].intVal = ord(regs[rb].node.kind)
      c.comesFromHeuristic = regs[rb].node.info
    of opcNIntVal:
      decodeB(rkInt)
      let a = regs[rb].node
      case a.kind
      of nkCharLit..nkInt64Lit: regs[ra].intVal = a.intVal
      else: stackTrace(c, tos, pc, errFieldXNotFound, "intVal")
    of opcNFloatVal:
      decodeB(rkFloat)
      let a = regs[rb].node
      case a.kind
      of nkFloatLit..nkFloat64Lit: regs[ra].floatVal = a.floatVal
      else: stackTrace(c, tos, pc, errFieldXNotFound, "floatVal")
    of opcNSymbol:
      decodeB(rkNode)
      let a = regs[rb].node
      if a.kind == nkSym:
        regs[ra].node = copyNode(a)
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "symbol")
    of opcNIdent:
      decodeB(rkNode)
      let a = regs[rb].node
      if a.kind == nkIdent:
        regs[ra].node = copyNode(a)
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "ident")
    of opcNGetType:
      let rb = instr.regB
      let rc = instr.regC
      if rc == 0:
        ensureKind(rkNode)
        if regs[rb].kind == rkNode and regs[rb].node.typ != nil:
          regs[ra].node = opMapTypeToAst(regs[rb].node.typ, c.debug[pc])
        else:
          stackTrace(c, tos, pc, errGenerated, "node has no type")
      else:
        # typeKind opcode:
        ensureKind(rkInt)
        if regs[rb].kind == rkNode and regs[rb].node.typ != nil:
          regs[ra].intVal = ord(regs[rb].node.typ.kind)
        #else:
        #  stackTrace(c, tos, pc, errGenerated, "node has no type")
    of opcNStrVal:
      decodeB(rkNode)
      createStr regs[ra]
      let a = regs[rb].node
      if a.kind in {nkStrLit..nkTripleStrLit}: regs[ra].node.strVal = a.strVal
      else: stackTrace(c, tos, pc, errFieldXNotFound, "strVal")
    of opcSlurp:
      decodeB(rkNode)
      createStr regs[ra]
      regs[ra].node.strVal = opSlurp(regs[rb].node.strVal, c.debug[pc],
                                     c.module)
    of opcGorge:
      decodeBC(rkNode)
      createStr regs[ra]
      regs[ra].node.strVal = opGorge(regs[rb].node.strVal,
                                     regs[rc].node.strVal)
    of opcNError:
      stackTrace(c, tos, pc, errUser, regs[ra].node.strVal)
    of opcNWarning:
      message(c.debug[pc], warnUser, regs[ra].node.strVal)
    of opcNHint:
      message(c.debug[pc], hintUser, regs[ra].node.strVal)
    of opcParseExprToAst:
      decodeB(rkNode)
      # c.debug[pc].line.int - countLines(regs[rb].strVal) ?
      var error: string
      let ast = parseString(regs[rb].node.strVal, c.debug[pc].toFullPath,
                            c.debug[pc].line.int,
                            proc (info: TLineInfo; msg: TMsgKind; arg: string) =
                              if error.isNil and msg <= msgs.errMax:
                                error = formatMsg(info, msg, arg))
      if not error.isNil:
        c.errorFlag = error
      elif sonsLen(ast) != 1:
        c.errorFlag = formatMsg(c.debug[pc], errExprExpected, "multiple statements")
      else:
        regs[ra].node = ast.sons[0]
    of opcParseStmtToAst:
      decodeB(rkNode)
      var error: string
      let ast = parseString(regs[rb].node.strVal, c.debug[pc].toFullPath,
                            c.debug[pc].line.int,
                            proc (info: TLineInfo; msg: TMsgKind; arg: string) =
                              if error.isNil and msg <= msgs.errMax:
                                error = formatMsg(info, msg, arg))
      if not error.isNil:
        c.errorFlag = error
      else:
        regs[ra].node = ast
    of opcQueryErrorFlag:
      createStr regs[ra]
      regs[ra].node.strVal = c.errorFlag
      c.errorFlag.setLen 0
    of opcCallSite:
      ensureKind(rkNode)
      if c.callsite != nil: regs[ra].node = c.callsite
      else: stackTrace(c, tos, pc, errFieldXNotFound, "callsite")
    of opcNLineInfo:
      decodeB(rkNode)
      let n = regs[rb].node
      createStr regs[ra]
      regs[ra].node.strVal = n.info.toFileLineCol
      regs[ra].node.info = c.debug[pc]
    of opcEqIdent:
      decodeBC(rkInt)
      if regs[rb].node.kind == nkIdent and regs[rc].node.kind == nkIdent:
        regs[ra].intVal = ord(regs[rb].node.ident.id == regs[rc].node.ident.id)
      else:
        regs[ra].intVal = 0
    of opcStrToIdent:
      decodeB(rkNode)
      if regs[rb].node.kind notin {nkStrLit..nkTripleStrLit}:
        stackTrace(c, tos, pc, errFieldXNotFound, "strVal")
      else:
        regs[ra].node = newNodeI(nkIdent, c.debug[pc])
        regs[ra].node.ident = getIdent(regs[rb].node.strVal)
    of opcIdentToStr:
      decodeB(rkNode)
      let a = regs[rb].node
      createStr regs[ra]
      regs[ra].node.info = c.debug[pc]
      if a.kind == nkSym:
        regs[ra].node.strVal = a.sym.name.s
      elif a.kind == nkIdent:
        regs[ra].node.strVal = a.ident.s
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "ident")
    of opcSetType:
      if regs[ra].kind != rkNode:
        internalError(c.debug[pc], "cannot set type")
      regs[ra].node.typ = c.types[instr.regBx - wordExcess]
    of opcConv:
      let rb = instr.regB
      inc pc
      let desttyp = c.types[c.code[pc].regBx - wordExcess]
      inc pc
      let srctyp = c.types[c.code[pc].regBx - wordExcess]

      if opConv(regs[ra], regs[rb], desttyp, srctyp):
        stackTrace(c, tos, pc, errGenerated,
          msgKindToString(errIllegalConvFromXtoY) % [
          typeToString(srctyp), typeToString(desttyp)])
    of opcCast:
      let rb = instr.regB
      inc pc
      let desttyp = c.types[c.code[pc].regBx - wordExcess]
      inc pc
      let srctyp = c.types[c.code[pc].regBx - wordExcess]

      when hasFFI:
        let dest = fficast(regs[rb], desttyp)
        asgnRef(regs[ra], dest)
      else:
        globalError(c.debug[pc], "cannot evaluate cast")
    of opcNSetIntVal:
      decodeB(rkNode)
      var dest = regs[ra].node
      if dest.kind in {nkCharLit..nkInt64Lit} and
         regs[rb].kind in {rkInt}:
        dest.intVal = regs[rb].intVal
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "intVal")
    of opcNSetFloatVal:
      decodeB(rkNode)
      var dest = regs[ra].node
      if dest.kind in {nkFloatLit..nkFloat64Lit} and
         regs[rb].kind in {rkFloat}:
        dest.floatVal = regs[rb].floatVal
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "floatVal")
    of opcNSetSymbol:
      decodeB(rkNode)
      var dest = regs[ra].node
      if dest.kind == nkSym and regs[rb].node.kind == nkSym:
        dest.sym = regs[rb].node.sym
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "symbol")
    of opcNSetIdent:
      decodeB(rkNode)
      var dest = regs[ra].node
      if dest.kind == nkIdent and regs[rb].node.kind == nkIdent:
        dest.ident = regs[rb].node.ident
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "ident")
    of opcNSetType:
      decodeB(rkNode)
      let b = regs[rb].node
      internalAssert b.kind == nkSym and b.sym.kind == skType
      internalAssert regs[ra].node != nil
      regs[ra].node.typ = b.sym.typ
    of opcNSetStrVal:
      decodeB(rkNode)
      var dest = regs[ra].node
      if dest.kind in {nkStrLit..nkTripleStrLit} and
         regs[rb].kind in {rkNode}:
        dest.strVal = regs[rb].node.strVal
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "strVal")
    of opcNNewNimNode:
      decodeBC(rkNode)
      var k = regs[rb].intVal
      if k < 0 or k > ord(high(TNodeKind)):
        internalError(c.debug[pc],
          "request to create a NimNode of invalid kind")
      let cc = regs[rc].node

      regs[ra].node = newNodeI(TNodeKind(int(k)),
        if cc.kind != nkNilLit:
          cc.info
        elif c.comesFromHeuristic.line > -1:
          c.comesFromHeuristic
        elif c.callsite != nil and c.callsite.safeLen > 1:
          c.callsite[1].info
        else:
          c.debug[pc])
      regs[ra].node.flags.incl nfIsRef
    of opcNCopyNimNode:
      decodeB(rkNode)
      regs[ra].node = copyNode(regs[rb].node)
    of opcNCopyNimTree:
      decodeB(rkNode)
      regs[ra].node = copyTree(regs[rb].node)
    of opcNDel:
      decodeBC(rkNode)
      let bb = regs[rb].intVal.int
      for i in countup(0, regs[rc].intVal.int-1):
        delSon(regs[ra].node, bb)
    of opcGenSym:
      decodeBC(rkNode)
      let k = regs[rb].intVal
      let name = if regs[rc].node.strVal.len == 0: ":tmp"
                 else: regs[rc].node.strVal
      if k < 0 or k > ord(high(TSymKind)):
        internalError(c.debug[pc], "request to create symbol of invalid kind")
      var sym = newSym(k.TSymKind, name.getIdent, c.module, c.debug[pc])
      incl(sym.flags, sfGenSym)
      regs[ra].node = newSymNode(sym)
    of opcTypeTrait:
      # XXX only supports 'name' for now; we can use regC to encode the
      # type trait operation
      decodeB(rkNode)
      var typ = regs[rb].node.typ
      internalAssert typ != nil
      while typ.kind == tyTypeDesc and typ.len > 0: typ = typ.sons[0]
      createStr regs[ra]
      regs[ra].node.strVal = typ.typeToString(preferExported)
    inc pc

proc execute(c: PCtx, start: int): PNode =
  var tos = PStackFrame(prc: nil, comesFrom: 0, next: nil)
  newSeq(tos.slots, c.prc.maxSlots)
  result = rawExecute(c, start, tos).regToNode

proc evalStmt*(c: PCtx, n: PNode) =
  let n = transformExpr(c.module, n)
  let start = genStmt(c, n)
  # execute new instructions; this redundant opcEof check saves us lots
  # of allocations in 'execute':
  if c.code[start].opcode != opcEof:
    discard execute(c, start)

proc evalExpr*(c: PCtx, n: PNode): PNode =
  let n = transformExpr(c.module, n)
  let start = genExpr(c, n)
  assert c.code[start].opcode != opcEof
  result = execute(c, start)

include vmops

# for now we share the 'globals' environment. XXX Coming soon: An API for
# storing&loading the 'globals' environment to get what a component system
# requires.
var
  globalCtx: PCtx

proc setupGlobalCtx(module: PSym) =
  if globalCtx.isNil:
    globalCtx = newCtx(module)
    registerAdditionalOps(globalCtx)
  else:
    refresh(globalCtx, module)

proc myOpen(module: PSym): PPassContext =
  #var c = newEvalContext(module, emRepl)
  #c.features = {allowCast, allowFFI, allowInfiniteLoops}
  #pushStackFrame(c, newStackFrame())

  # XXX produce a new 'globals' environment here:
  setupGlobalCtx(module)
  result = globalCtx
  when hasFFI:
    globalCtx.features = {allowFFI, allowCast}

var oldErrorCount: int

proc myProcess(c: PPassContext, n: PNode): PNode =
  # don't eval errornous code:
  if oldErrorCount == msgs.gErrorCounter:
    evalStmt(PCtx(c), n)
    result = emptyNode
  else:
    result = n
  oldErrorCount = msgs.gErrorCounter

const evalPass* = makePass(myOpen, nil, myProcess, myProcess)

proc evalConstExprAux(module, prc: PSym, n: PNode, mode: TEvalMode): PNode =
  let n = transformExpr(module, n)
  setupGlobalCtx(module)
  var c = globalCtx
  c.mode = mode
  let start = genExpr(c, n, requiresValue = mode!=emStaticStmt)
  if c.code[start].opcode == opcEof: return emptyNode
  assert c.code[start].opcode != opcEof
  when debugEchoCode: c.echoCode start
  var tos = PStackFrame(prc: prc, comesFrom: 0, next: nil)
  newSeq(tos.slots, c.prc.maxSlots)
  #for i in 0 .. <c.prc.maxSlots: tos.slots[i] = newNode(nkEmpty)
  result = rawExecute(c, start, tos).regToNode
  if result.info.line < 0: result.info = n.info

proc evalConstExpr*(module: PSym, e: PNode): PNode =
  result = evalConstExprAux(module, nil, e, emConst)

proc evalStaticExpr*(module: PSym, e: PNode, prc: PSym): PNode =
  result = evalConstExprAux(module, prc, e, emStaticExpr)

proc evalStaticStmt*(module: PSym, e: PNode, prc: PSym) =
  discard evalConstExprAux(module, prc, e, emStaticStmt)

proc setupCompileTimeVar*(module: PSym, n: PNode) =
  discard evalConstExprAux(module, nil, n, emStaticStmt)

proc setupMacroParam(x: PNode): PNode =
  result = x
  if result.kind in {nkHiddenSubConv, nkHiddenStdConv}: result = result.sons[1]
  result = canonValue(result)
  result.flags.incl nfIsRef
  result.typ = x.typ

var evalMacroCounter: int

proc evalMacroCall*(module: PSym, n, nOrig: PNode, sym: PSym): PNode =
  # XXX GlobalError() is ugly here, but I don't know a better solution for now
  inc(evalMacroCounter)
  if evalMacroCounter > 100:
    globalError(n.info, errTemplateInstantiationTooNested)

  # immediate macros can bypass any type and arity checking so we check the
  # arity here too:
  if sym.typ.len > n.safeLen and sym.typ.len > 1:
    globalError(n.info, "in call '$#' got $#, but expected $# argument(s)" % [
        n.renderTree,
        $ <n.safeLen, $ <sym.typ.len])

  setupGlobalCtx(module)
  var c = globalCtx

  c.callsite = nOrig
  let start = genProc(c, sym)

  var tos = PStackFrame(prc: sym, comesFrom: 0, next: nil)
  let maxSlots = sym.offset
  newSeq(tos.slots, maxSlots)
  # setup arguments:
  var L = n.safeLen
  if L == 0: L = 1
  # This is wrong for tests/reject/tind1.nim where the passed 'else' part
  # doesn't end up in the parameter:
  #InternalAssert tos.slots.len >= L

  # return value:
  tos.slots[0].kind = rkNode
  tos.slots[0].node = newNodeIT(nkEmpty, n.info, sym.typ.sons[0])
  # setup parameters:
  for i in 1 .. < min(tos.slots.len, L):
    tos.slots[i].kind = rkNode
    tos.slots[i].node = setupMacroParam(n.sons[i])
  # temporary storage:
  #for i in L .. <maxSlots: tos.slots[i] = newNode(nkEmpty)
  result = rawExecute(c, start, tos).regToNode
  if result.info.line < 0: result.info = n.info
  if cyclicTree(result): globalError(n.info, errCyclicTree)
  dec(evalMacroCounter)
  c.callsite = nil
  #debug result
