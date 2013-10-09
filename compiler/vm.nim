#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This file implements the new evaluation engine for Nimrod code.
## An instruction is 1-2 int32s in memory, it is a register based VM.

import
  strutils, ast, astalgo, msgs, vmdef, vmgen, nimsets, types, passes, unsigned,
  parser, vmdeps, idents

from semfold import leValueConv, ordinalValToString

type
  PStackFrame* = ref TStackFrame
  TStackFrame* = object
    prc: PSym                 # current prc; proc that is evaluated
    slots: TNodeSeq           # parameters passed to the proc + locals;
                              # parameters come first
    next: PStackFrame         # for stacking
    comesFrom: int
    safePoints: seq[int]      # used for exception handling
                              # XXX 'break' should perform cleanup actions
                              # What does the C backend do for it?

proc stackTraceAux(c: PCtx; x: PStackFrame; pc: int) =
  if x != nil:
    stackTraceAux(c, x.next, x.comesFrom)
    var info = c.debug[pc]
    # we now use the same format as in system/except.nim
    var s = toFilename(info)
    var line = toLineNumber(info)
    if line > 0:
      add(s, '(')
      add(s, $line)
      add(s, ')')
    if x.prc != nil:
      for k in 1..max(1, 25-s.len): add(s, ' ')
      add(s, x.prc.name.s)
    MsgWriteln(s)

proc stackTrace(c: PCtx, tos: PStackFrame, pc: int,
                msg: TMsgKind, arg = "") =
  MsgWriteln("stack trace: (most recent call last)")
  stackTraceAux(c, tos, pc)
  LocalError(c.debug[pc], msg, arg)

proc bailOut(c: PCtx; tos: PStackFrame) =
  stackTrace(c, tos, c.exceptionInstr, errUnhandledExceptionX,
             c.currentExceptionA.sons[2].strVal)

when not defined(nimComputedGoto):
  {.pragma: computedGoto.}

template inc(pc: ptr TInstr, diff = 1) =
  inc cast[TAddress](pc), TInstr.sizeof * diff

proc myreset(n: PNode) =
  when defined(system.reset): 
    var oldInfo = n.info
    reset(n[])
    n.info = oldInfo

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

template move(a, b: expr) = system.shallowCopy(a, b)
# XXX fix minor 'shallowCopy' overloading bug in compiler

proc asgnRef(x, y: PNode) =
  myreset(x)
  x.kind = y.kind
  x.typ = y.typ
  case x.kind
  of nkCharLit..nkInt64Lit: x.intVal = y.intVal
  of nkFloatLit..nkFloat64Lit: x.floatVal = y.floatVal
  of nkStrLit..nkTripleStrLit: x.strVal = y.strVal
  of nkIdent: x.ident = y.ident
  of nkSym: x.sym = y.sym
  else:
    if x.kind notin {nkEmpty..nkNilLit}:
      move(x.sons, y.sons)

proc asgnComplex(x, y: PNode) =
  myreset(x)
  x.kind = y.kind
  x.typ = y.typ
  case x.kind
  of nkCharLit..nkInt64Lit: x.intVal = y.intVal
  of nkFloatLit..nkFloat64Lit: x.floatVal = y.floatVal
  of nkStrLit..nkTripleStrLit: x.strVal = y.strVal
  of nkIdent: x.ident = y.ident
  of nkSym: x.sym = y.sym
  else:
    if x.kind notin {nkEmpty..nkNilLit}:
      let y = y.copyTree
      for i in countup(0, sonsLen(y) - 1): addSon(x, y.sons[i])

template getstr(a: expr): expr =
  (if a.kind == nkStrLit: a.strVal else: $chr(int(a.intVal)))

proc pushSafePoint(f: PStackFrame; pc: int) =
  if f.safePoints.isNil: f.safePoints = @[]
  f.safePoints.add(pc)

proc popSafePoint(f: PStackFrame) = discard f.safePoints.pop()

proc cleanUpOnException(c: PCtx; tos: PStackFrame; regs: TNodeSeq): int =
  let raisedType = c.currentExceptionA.typ.skipTypes(abstractPtrs)
  var f = tos
  while true:
    while f.safePoints.isNil or f.safePoints.len == 0:
      f = f.next
      if f.isNil: return -1
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
        return pc2
      inc pc2
    if nextExceptOrFinally >= 0:
      pc2 = nextExceptOrFinally
    if c.code[pc2].opcode == opcFinally:
      # execute the corresponding handler, but don't quit walking the stack:
      return pc2
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

proc opConv*(dest, src: PNode, typ: PType): bool =
  if typ.kind == tyString:
    if dest.kind != nkStrLit:
      myreset(dest)
      dest.kind = nkStrLit
    case src.typ.skipTypes(abstractRange).kind
    of tyEnum: 
      dest.strVal = ordinalValToString(src)
    of tyInt..tyInt64, tyUInt..tyUInt64:
      dest.strVal = $src.intVal
    of tyBool:
      dest.strVal = if src.intVal == 0: "false" else: "true"
    of tyFloat..tyFloat128:
      dest.strVal = $src.floatVal
    of tyString, tyCString:
      dest.strVal = src.strVal
    of tyChar:
      dest.strVal = $chr(src.intVal)
    else:
      internalError("cannot convert to string " & typ.typeToString)
  else:
    case skipTypes(typ, abstractRange).kind
    of tyInt..tyInt64:
      if dest.kind != nkIntLit:
        myreset(dest); dest.kind = nkIntLit
      case skipTypes(src.typ, abstractRange).kind
      of tyFloat..tyFloat64:
        dest.intVal = system.toInt(src.floatVal)
      else:
        dest.intVal = src.intVal
      if dest.intVal < firstOrd(typ) or dest.intVal > lastOrd(typ):
        return true
    of tyUInt..tyUInt64:
      if dest.kind != nkIntLit:
        myreset(dest); dest.kind = nkIntLit
      case skipTypes(src.typ, abstractRange).kind
      of tyFloat..tyFloat64:
        dest.intVal = system.toInt(src.floatVal)
      else:
        dest.intVal = src.intVal and ((1 shl typ.size)-1)
    of tyFloat..tyFloat64:
      if dest.kind != nkFloatLit:
        myreset(dest); dest.kind = nkFloatLit
      case skipTypes(src.typ, abstractRange).kind
      of tyInt..tyInt64, tyUInt..tyUInt64, tyEnum, tyBool, tyChar: 
        dest.floatVal = toFloat(src.intVal.int)
      else:
        dest.floatVal = src.floatVal
    else:
      asgnComplex(dest, src)

proc compile(c: PCtx, s: PSym): int = 
  result = vmgen.genProc(c, s)
  #c.echoCode

proc rawExecute(c: PCtx, start: int, tos: PStackFrame) =
  var pc = start
  var tos = tos
  var regs: TNodeSeq # alias to tos.slots for performance
  move(regs, tos.slots)
  while true:
    {.computedGoto.}
    let instr = c.code[pc]
    let ra = instr.regA
    #echo "PC ", pc, " ", c.code[pc].opcode, " ra ", ra
    case instr.opcode
    of opcEof: return regs[ra]
    of opcRet:
      # XXX perform any cleanup actions
      pc = tos.comesFrom
      tos = tos.next
      let retVal = regs[0]
      if tos.isNil: return retVal
      
      move(regs, tos.slots)
      assert c.code[pc].opcode in {opcIndCall, opcIndCallAsgn}
      if c.code[pc].opcode == opcIndCallAsgn:
        regs[c.code[pc].regA] = retVal
    of opcYldYoid: assert false
    of opcYldVal: assert false
    of opcAsgnInt:
      decodeB(nkIntLit)
      regs[ra].intVal = regs[rb].intVal
    of opcAsgnStr:
      decodeB(nkStrLit)
      regs[ra].strVal = regs[rb].strVal
    of opcAsgnFloat:
      decodeB(nkFloatLit)
      regs[ra].floatVal = regs[rb].floatVal
    of opcAsgnComplex:
      asgnComplex(regs[ra], regs[instr.regB])
    of opcAsgnRef:
      asgnRef(regs[ra], regs[instr.regB])
    of opcWrGlobalRef:
      asgnRef(c.globals[instr.regBx-wordExcess-1], regs[ra])
    of opcWrGlobal:
      asgnComplex(c.globals.sons[instr.regBx-wordExcess-1], regs[ra])
    of opcLdArr:
      # a = b[c]
      let rb = instr.regB
      let rc = instr.regC
      let idx = regs[rc].intVal
      # XXX what if the array is not 0-based? -> codegen should insert a sub
      regs[ra] = regs[rb].sons[idx.int]
    of opcLdStrIdx:
      decodeBC(nkIntLit)
      let idx = regs[rc].intVal
      regs[ra].intVal = regs[rb].strVal[idx.int].ord
    of opcWrArr:
      # a[b] = c
      let rb = instr.regB
      let rc = instr.regC
      let idx = regs[rb].intVal
      asgnComplex(regs[ra].sons[idx.int], regs[rc])
    of opcWrArrRef:
      let rb = instr.regB
      let rc = instr.regC
      let idx = regs[rb].intVal
      asgnRef(regs[ra].sons[idx.int], regs[rc])
    of opcLdObj:
      # a = b.c
      let rb = instr.regB
      let rc = instr.regC
      # XXX this creates a wrong alias
      #Message(c.debug[pc], warnUser, $regs[rb].len & " " & $rc)
      asgnComplex(regs[ra], regs[rb].sons[rc])
    of opcWrObj:
      # a.b = c
      let rb = instr.regB
      let rc = instr.regC
      asgnComplex(regs[ra].sons[rb], regs[rc])
    of opcWrObjRef:
      let rb = instr.regB
      let rc = instr.regC
      asgnRef(regs[ra].sons[rb], regs[rc])
    of opcWrStrIdx:
      decodeBC(nkStrLit)
      let idx = regs[rb].intVal.int
      regs[ra].strVal[idx] = chr(regs[rc].intVal)
    of opcAddr:
      decodeB(nkRefTy)
      if regs[ra].len == 0: regs[ra].add regs[rb]
      else: regs[ra].sons[0] = regs[rb]
    of opcDeref:
      # a = b[]
      let rb = instr.regB
      if regs[rb].kind == nkNilLit:
        stackTrace(c, tos, pc, errNilAccess)
      assert regs[rb].kind == nkRefTy
      regs[ra] = regs[rb].sons[0]
    of opcAddInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal + regs[rc].intVal
    of opcAddImmInt:
      decodeBImm(nkIntLit)
      regs[ra].intVal = regs[rb].intVal + imm
    of opcSubInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal - regs[rc].intVal
    of opcSubImmInt:
      decodeBImm(nkIntLit)
      regs[ra].intVal = regs[rb].intVal - imm
    of opcLenSeq:
      decodeBImm(nkIntLit)
      #assert regs[rb].kind == nkBracket
      # also used by mNLen
      regs[ra].intVal = regs[rb].len - imm
    of opcLenStr:
      decodeBImm(nkIntLit)
      assert regs[rb].kind == nkStrLit
      regs[ra].intVal = regs[rb].strVal.len - imm
    of opcIncl:
      decodeB(nkCurly)
      if not inSet(regs[ra], regs[rb]): addSon(regs[ra], copyTree(regs[rb]))
    of opcExcl:
      decodeB(nkCurly)
      var b = newNodeIT(nkCurly, regs[rb].info, regs[rb].typ)
      addSon(b, regs[rb])
      var r = diffSets(regs[ra], b)
      discardSons(regs[ra])
      for i in countup(0, sonsLen(r) - 1): addSon(regs[ra], r.sons[i])
    of opcCard:
      decodeB(nkIntLit)
      regs[ra].intVal = nimsets.cardSet(regs[rb])
    of opcMulInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal * regs[rc].intVal
    of opcDivInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal div regs[rc].intVal
    of opcModInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal mod regs[rc].intVal
    of opcAddFloat:
      decodeBC(nkFloatLit)
      regs[ra].floatVal = regs[rb].floatVal + regs[rc].floatVal
    of opcSubFloat:
      decodeBC(nkFloatLit)
      regs[ra].floatVal = regs[rb].floatVal - regs[rc].floatVal
    of opcMulFloat:
      decodeBC(nkFloatLit)
      regs[ra].floatVal = regs[rb].floatVal * regs[rc].floatVal
    of opcDivFloat:
      decodeBC(nkFloatLit)
      regs[ra].floatVal = regs[rb].floatVal / regs[rc].floatVal
    of opcShrInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal shr regs[rc].intVal
    of opcShlInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal shl regs[rc].intVal
    of opcBitandInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal and regs[rc].intVal
    of opcBitorInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal or regs[rc].intVal
    of opcBitxorInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal xor regs[rc].intVal
    of opcAddu:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal +% regs[rc].intVal
    of opcSubu:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal -% regs[rc].intVal
    of opcMulu: 
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal *% regs[rc].intVal
    of opcDivu:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal /% regs[rc].intVal
    of opcModu:
      decodeBC(nkIntLit)
      regs[ra].intVal = regs[rb].intVal %% regs[rc].intVal
    of opcEqInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].intVal == regs[rc].intVal)
    of opcLeInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].intVal <= regs[rc].intVal)
    of opcLtInt:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].intVal < regs[rc].intVal)
    of opcEqFloat:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].floatVal == regs[rc].floatVal)
    of opcLeFloat:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].floatVal <= regs[rc].floatVal)
    of opcLtFloat:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].floatVal < regs[rc].floatVal)
    of opcLeu:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].intVal <=% regs[rc].intVal)
    of opcLtu:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].intVal <% regs[rc].intVal)
    of opcEqRef:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord((regs[rb].kind == nkNilLit and
                             regs[rc].kind == nkNilLit) or
                             regs[rb].sons == regs[rc].sons)
    of opcXor:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].intVal != regs[rc].intVal)
    of opcNot:
      decodeB(nkIntLit)
      assert regs[rb].kind == nkIntLit
      regs[ra].intVal = 1 - regs[rb].intVal
    of opcUnaryMinusInt:
      decodeB(nkIntLit)
      assert regs[rb].kind == nkIntLit
      regs[ra].intVal = -regs[rb].intVal
    of opcUnaryMinusFloat:
      decodeB(nkFloatLit)
      assert regs[rb].kind == nkFloatLit
      regs[ra].floatVal = -regs[rb].floatVal
    of opcBitnotInt:
      decodeB(nkIntLit)
      assert regs[rb].kind == nkIntLit
      regs[ra].intVal = not regs[rb].intVal
    of opcEqStr:
      decodeBC(nkIntLit)
      regs[ra].intVal = Ord(regs[rb].strVal == regs[rc].strVal)
    of opcLeStr:
      decodeBC(nkIntLit)
      regs[ra].intVal = Ord(regs[rb].strVal <= regs[rc].strVal)
    of opcLtStr:
      decodeBC(nkIntLit)
      regs[ra].intVal = Ord(regs[rb].strVal < regs[rc].strVal)
    of opcLeSet:
      decodeBC(nkIntLit)
      regs[ra].intVal = Ord(containsSets(regs[rb], regs[rc]))
    of opcEqSet: 
      decodeBC(nkIntLit)
      regs[ra].intVal = Ord(equalSets(regs[rb], regs[rc]))
    of opcLtSet:
      decodeBC(nkIntLit)
      let a = regs[rb]
      let b = regs[rc]
      regs[ra].intVal = Ord(containsSets(a, b) and not equalSets(a, b))
    of opcMulSet:
      decodeBC(nkCurly)
      move(regs[ra].sons, nimsets.intersectSets(regs[rb], regs[rc]).sons)
    of opcPlusSet: 
      decodeBC(nkCurly)
      move(regs[ra].sons, nimsets.unionSets(regs[rb], regs[rc]).sons)
    of opcMinusSet:
      decodeBC(nkCurly)
      move(regs[ra].sons, nimsets.diffSets(regs[rb], regs[rc]).sons)
    of opcSymDiffSet:
      decodeBC(nkCurly)
      move(regs[ra].sons, nimsets.symdiffSets(regs[rb], regs[rc]).sons)    
    of opcConcatStr:
      decodeBC(nkStrLit)
      regs[ra].strVal = getstr(regs[rb])
      for i in rb+1..rb+rc-1:
        regs[ra].strVal.add getstr(regs[i])
    of opcAddStrCh:
      decodeB(nkStrLit)
      regs[ra].strVal.add(regs[rb].intVal.chr)
    of opcAddStrStr:
      decodeB(nkStrLit)
      regs[ra].strVal.add(regs[rb].strVal)
    of opcAddSeqElem:
      decodeB(nkBracket)
      regs[ra].add(copyTree(regs[rb]))
    of opcEcho:
      let rb = instr.regB
      for i in ra..ra+rb-1:
        if regs[i].kind != nkStrLit: debug regs[i]
        write(stdout, regs[i].strVal)
      writeln(stdout, "")
    of opcContainsSet:
      decodeBC(nkIntLit)
      regs[ra].intVal = Ord(inSet(regs[rb], regs[rc]))
    of opcSubStr:
      decodeBC(nkStrLit)
      inc pc
      assert c.code[pc].opcode == opcSubStr
      let rd = c.code[pc].regA
      regs[ra].strVal = substr(regs[rb].strVal, regs[rc].intVal.int, 
                               regs[rd].intVal.int)
    of opcRangeChck:
      let rb = instr.regB
      let rc = instr.regC
      if not (leValueConv(regs[rb], regs[ra]) and
              leValueConv(regs[ra], regs[rc])):
        stackTrace(c, tos, pc, errGenerated,
          msgKindToString(errIllegalConvFromXtoY) % [
          "unknown type" , "unknown type"])
    of opcIndCall, opcIndCallAsgn:
      # dest = call regStart, n; where regStart = fn, arg1, ...
      let rb = instr.regB
      let rc = instr.regC
      let prc = regs[rb].sym
      let newPc = compile(c, prc)
      var newFrame = PStackFrame(prc: prc, comesFrom: pc, next: tos)
      newSeq(newFrame.slots, prc.position)
      if not isEmptyType(prc.typ.sons[0]):
        newFrame.slots[0] = getNullValue(prc.typ.sons[0], prc.info)
      # pass every parameter by var (the language definition allows this):
      for i in 1 .. rc-1:
        newFrame.slots[i] = regs[rb+i]
      # allocate the temporaries:
      for i in rc .. <prc.position:
        newFrame.slots[i] = newNode(nkEmpty)
      tos = newFrame
      move(regs, newFrame.slots)
      # -1 for the following 'inc pc'
      pc = newPc-1
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
    of opcBranch:
      # we know the next instruction is a 'jmp':
      let branch = c.constants[instr.regBx-wordExcess]
      var cond = false
      for j in countup(0, sonsLen(branch) - 2): 
        if overlap(regs[ra], branch.sons[j]): 
          cond = true
          break
      assert c.code[pc+1].opcode == opcJmp
      inc pc 
      # we skip this instruction so that the final 'inc(pc)' skips
      # the following jump
      if cond:
        let instr2 = c.code[pc]
        let rbx = instr2.regBx - wordExcess - 1 # -1 for the following 'inc pc'
        inc pc, rbx
    of opcTry:
      let rbx = instr.regBx - wordExcess
      tos.pushSafePoint(pc + rbx)
    of opcExcept:
      # just skip it; it's followed by a jump;
      # we'll execute in the 'raise' handler
      discard
    of opcFinally:
      # just skip it; it's followed by the code we need to execute anyway
      tos.popSafePoint()
    of opcFinallyEnd:
      if c.currentExceptionA != nil:
        # we are in a cleanup run:
        pc = cleanupOnException(c, tos, regs)-1
        if pc < 0: 
          bailOut(c, tos)
          return
    of opcRaise:
      let raised = regs[ra]
      c.currentExceptionA = raised
      c.exceptionInstr = pc
      # -1 because of the following 'inc'
      pc = cleanupOnException(c, tos, regs) - 1
      if pc < 0:
        bailOut(c, tos)
        return
    of opcNew:
      let typ = c.types[instr.regBx - wordExcess]
      regs[ra] = getNullValue(typ, regs[ra].info)
    of opcNewSeq:
      let typ = c.types[instr.regBx - wordExcess]
      inc pc
      ensureKind(nkBracket)
      let instr2 = c.code[pc]
      let rb = instr2.regA
      regs[ra].typ = typ
      newSeq(regs[ra].sons, rb)
      for i in 0 .. <rb:
        regs[ra].sons[i] = getNullValue(typ, regs[ra].info)
    of opcNewStr:
      decodeB(nkStrLit)
      regs[ra].strVal = newString(regs[rb].intVal.int)
    of opcLdImmInt:
      # dest = immediate value
      decodeBx(nkIntLit)
      regs[ra].intVal = rbx
    of opcLdNull:
      let typ = c.types[instr.regBx - wordExcess]
      regs[ra] = getNullValue(typ, c.debug[pc])
    of opcLdConst:
      regs[ra] = c.constants.sons[instr.regBx - wordExcess]
    of opcAsgnConst:
      let rb = instr.regBx - wordExcess
      if regs[ra].isNil:
        regs[ra] = copyTree(c.constants.sons[rb])
      else:
        asgnComplex(regs[ra], c.constants.sons[rb])
    of opcLdGlobal:
      let rb = instr.regBx - wordExcess
      if regs[ra].isNil:
        regs[ra] = copyTree(c.globals.sons[rb])
      else:
        asgnComplex(regs[ra], c.globals.sons[rb])
    of opcRepr, opcSetLenStr, opcSetLenSeq,
        opcSwap, opcIsNil, opcOf,
        opcCast, opcQuit, opcReset:
      internalError(c.debug[pc], "too implement")
    of opcNBindSym:
      # trivial implementation:
      let rb = instr.regB
      regs[ra] = regs[rb].sons[1]
    of opcNChild:
      let rb = instr.regB
      let rc = instr.regC
      regs[ra] = regs[rb].sons[regs[rc].intVal.int]
    of opcNSetChild:
      let rb = instr.regB
      let rc = instr.regC
      regs[ra].sons[regs[rb].intVal.int] = regs[rc]
    of opcNAdd:
      declBC()
      regs[rb].add(regs[rb])
      regs[ra] = regs[rb]
    of opcNAddMultiple:
      declBC()
      let x = regs[rc]
      # XXX can be optimized:
      for i in 0.. <x.len: regs[rb].add(x.sons[i])
      regs[ra] = regs[rb]
    of opcNKind:
      decodeB(nkIntLit)
      regs[ra].intVal = ord(regs[rb].kind)
    of opcNIntVal:
      decodeB(nkIntLit)
      let a = regs[rb]
      case a.kind
      of nkCharLit..nkInt64Lit: regs[ra].intVal = a.intVal
      else: stackTrace(c, tos, pc, errFieldXNotFound, "intVal")
    of opcNFloatVal:
      decodeB(nkFloatLit)
      let a = regs[rb]
      case a.kind
      of nkFloatLit..nkFloat64Lit: regs[ra].floatVal = a.floatVal
      else: stackTrace(c, tos, pc, errFieldXNotFound, "floatVal")
    of opcNSymbol:
      let rb = instr.regB
      if regs[rb].kind != nkSym: 
        stackTrace(c, tos, pc, errFieldXNotFound, "symbol")
      regs[ra] = regs[rb]
    of opcNIdent:
      let rb = instr.regB
      if regs[rb].kind != nkIdent: 
        stackTrace(c, tos, pc, errFieldXNotFound, "ident")
      regs[ra] = regs[rb]
    of opcNGetType:
      InternalError(c.debug[pc], "unknown opcode " & $instr.opcode)      
    of opcNStrVal:
      decodeB(nkStrLit)
      let a = regs[rb]
      case a.kind
      of nkStrLit..nkTripleStrLit: regs[ra].strVal = a.strVal
      else: stackTrace(c, tos, pc, errFieldXNotFound, "strVal")
    of opcSlurp:
      decodeB(nkStrLit)
      regs[ra].strVal = opSlurp(regs[rb].strVal, c.debug[pc], c.module)
    of opcGorge:
      decodeBC(nkStrLit)
      regs[ra].strVal = opGorge(regs[rb].strVal, regs[rc].strVal)
    of opcNError:
      stackTrace(c, tos, pc, errUser, regs[ra].strVal)
    of opcNWarning:
      Message(c.debug[pc], warnUser, regs[ra].strVal)
    of opcNHint:
      Message(c.debug[pc], hintUser, regs[ra].strVal)
    of opcParseExprToAst:
      let rb = instr.regB
      # c.debug[pc].line.int - countLines(regs[rb].strVal) ?
      let ast = parseString(regs[rb].strVal, c.debug[pc].toFilename,
                            c.debug[pc].line.int)
      if sonsLen(ast) != 1:
        GlobalError(c.debug[pc], errExprExpected, "multiple statements")
      regs[ra] = ast.sons[0]
    of opcParseStmtToAst:
      let rb = instr.regB
      let ast = parseString(regs[rb].strVal, c.debug[pc].toFilename,
                            c.debug[pc].line.int)
      regs[ra] = ast
    of opcCallSite:
      if c.callsite != nil: regs[ra] = c.callsite
      else: stackTrace(c, tos, pc, errFieldXNotFound, "callsite")
    of opcNLineInfo:
      let rb = instr.regB
      let n = regs[rb]
      regs[ra] = newStrNode(nkStrLit, n.info.toFileLineCol)
      regs[ra].info = c.debug[pc]
    of opcEqIdent:
      decodeBC(nkIntLit)
      if regs[rb].kind == nkIdent and regs[rc].kind == nkIdent:
        regs[ra].intVal = ord(regs[rb].ident.id == regs[rc].ident.id)
      else:
        regs[ra].intVal = 0
    of opcStrToIdent:
      let rb = instr.regB
      if regs[rb].kind notin {nkStrLit..nkTripleStrLit}:
        stackTrace(c, tos, pc, errFieldXNotFound, "strVal")
      else:
        regs[ra] = newNodeI(nkIdent, c.debug[pc])
        regs[ra].ident = getIdent(regs[rb].strVal)
    of opcIdentToStr:
      let rb = instr.regB
      let a = regs[rb]
      regs[ra] = newNodeI(nkStrLit, c.debug[pc])
      if a.kind == nkSym:
        regs[ra].strVal = a.sym.name.s
      elif a.kind == nkIdent:
        regs[ra].strVal = a.ident.s
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "ident")
    of opcSetType:
      regs[ra].typ = c.types[instr.regBx - wordExcess]
    of opcConv:
      let rb = instr.regB
      inc pc
      let typ = c.types[c.code[pc].regBx - wordExcess]
      if opConv(regs[ra], regs[rb], typ):
        stackTrace(c, tos, pc, errGenerated,
          msgKindToString(errIllegalConvFromXtoY) % [
          "unknown type" , "unknown type"])
    of opcNSetIntVal:
      let rb = instr.regB
      if regs[ra].kind in {nkCharLit..nkInt64Lit} and 
         regs[rb].kind in {nkCharLit..nkInt64Lit}:
        regs[ra].intVal = regs[rb].intVal
      else: 
        stackTrace(c, tos, pc, errFieldXNotFound, "intVal")
    of opcNSetFloatVal:
      let rb = instr.regB
      if regs[ra].kind in {nkFloatLit..nkFloat64Lit} and 
         regs[rb].kind in {nkFloatLit..nkFloat64Lit}:
        regs[ra].floatVal = regs[rb].floatVal
      else: 
        stackTrace(c, tos, pc, errFieldXNotFound, "floatVal")
    of opcNSetSymbol:
      let rb = instr.regB
      if regs[ra].kind == nkSym and regs[rb].kind == nkSym:
        regs[ra].sym = regs[rb].sym
      else: 
        stackTrace(c, tos, pc, errFieldXNotFound, "symbol")
    of opcNSetIdent:
      let rb = instr.regB
      if regs[ra].kind == nkIdent and regs[rb].kind == nkIdent:
        regs[ra].ident = regs[rb].ident
      else: 
        stackTrace(c, tos, pc, errFieldXNotFound, "ident")
    of opcNSetType:
      let b = regs[instr.regB]
      InternalAssert b.kind == nkSym and b.sym.kind == skType
      regs[ra].typ = b.sym.typ
    of opcNSetStrVal:
      let rb = instr.regB
      if regs[ra].kind in {nkStrLit..nkTripleStrLit} and 
         regs[rb].kind in {nkStrLit..nkTripleStrLit}:
        regs[ra].strVal = regs[rb].strVal
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "strVal")
    of opcNNewNimNode:
      let rb = instr.regB
      let rc = instr.regC
      var k = regs[rb].intVal
      if k < 0 or k > ord(high(TNodeKind)): 
        internalError(c.debug[pc],
          "request to create a NimNode with invalid kind")
      regs[ra] = newNodeI(TNodeKind(int(k)), 
        if regs[rc].kind == nkNilLit: c.debug[pc] else: regs[rc].info)
    of opcNCopyNimNode:
      let rb = instr.regB
      regs[ra] = copyNode(regs[rb])
    of opcNCopyNimTree:
      let rb = instr.regB
      regs[ra] = copyTree(regs[rb])
    of opcNDel:
      let rb = instr.regB
      let rc = instr.regC
      for i in countup(0, regs[rc].intVal.int-1):
        delSon(regs[ra], regs[rb].intVal.int)
    of opcGenSym:
      let k = regs[instr.regB].intVal
      let b = regs[instr.regC]
      let name = if b.strVal.len == 0: ":tmp" else: b.strVal
      if k < 0 or k > ord(high(TSymKind)):
        internalError(c.debug[pc], "request to create symbol of invalid kind")
      regs[ra] = newSymNode(newSym(k.TSymKind, name.getIdent, c.module,
                            c.debug[pc]))
      incl(regs[ra].sym.flags, sfGenSym)
    of opcTypeTrait:
      # XXX only supports 'name' for now; we can use regC to encode the
      # type trait operation
      decodeB(nkStrLit)
      let typ = regs[rb].sym.typ.skipTypes({tyTypeDesc})
      regs[ra].strVal = typ.typeToString(preferExported)
    inc pc

proc execute(c: PCtx, start: int) =
  var tos = PStackFrame(prc: nil, comesFrom: 0, next: nil)
  newSeq(tos.slots, c.prc.maxSlots)
  rawExecute(c, start, tos)

proc evalStmt*(c: PCtx, n: PNode) =
  let start = genStmt(c, n)
  # execute new instructions; this redundant opcEof check saves us lots
  # of allocations in 'execute':
  if c.code[start].opcode != opcEof:
    discard execute(c, start)

proc evalExpr*(c: PCtx, n: PNode): PNode =
  let start = genExpr(c, n)
  assert c.code[start].opcode != opcEof
  result = execute(c, start)

proc myOpen(module: PSym): PPassContext =
  #var c = newEvalContext(module, emRepl)
  #c.features = {allowCast, allowFFI, allowInfiniteLoops}
  #pushStackFrame(c, newStackFrame())
  result = newCtx(module)

var oldErrorCount: int

proc myProcess(c: PPassContext, n: PNode): PNode =
  # don't eval errornous code:
  if oldErrorCount == msgs.gErrorCounter:
    evalStmt(PCtx(c), n)
    result = emptyNode
  else:
    result = n
  oldErrorCount = msgs.gErrorCounter

const vmPass* = makePass(myOpen, nil, myProcess, myProcess)

proc evalConstExprAux(module, prc: PSym, e: PNode, mode: TEvalMode): PNode = 
  var p = newCtx(module)
  var s = newStackFrame()
  s.call = e
  s.prc = prc
  pushStackFrame(p, s)
  result = tryEval(p, e)
  if result != nil and result.kind == nkExceptBranch: result = nil
  popStackFrame(p)

proc evalConstExpr*(module: PSym, e: PNode): PNode = 
  result = evalConstExprAux(module, nil, e, emConst)

proc evalStaticExpr*(module: PSym, e: PNode, prc: PSym): PNode = 
  result = evalConstExprAux(module, prc, e, emStatic)

proc setupMacroParam(x: PNode): PNode =
  result = x
  if result.kind in {nkHiddenSubConv, nkHiddenStdConv}: result = result.sons[1]

proc evalMacroCall(c: PEvalContext, n, nOrig: PNode, sym: PSym): PNode =
  # XXX GlobalError() is ugly here, but I don't know a better solution for now
  inc(evalTemplateCounter)
  if evalTemplateCounter > 100:
    GlobalError(n.info, errTemplateInstantiationTooNested)

  c.callsite = nOrig
  let body = optBody(c, sym)
  let start = genStmt(c, body)

  var tos = PStackFrame(prc: sym, comesFrom: 0, next: nil)
  newSeq(tos.slots, c.prc.maxSlots)
  # setup arguments:
  var L = n.safeLen
  if L == 0: L = 1
  InternalAssert tos.slots.len >= L
  # return value:
  tos.slots[0] = newNodeIT(nkNilLit, n.info, sym.typ.sons[0])
  # setup parameters:
  for i in 1 .. < L: tos.slots[i] = setupMacroParam(n.sons[i])
  rawExecute(c, start, tos)
  result = tos.slots[0]
  if cyclicTree(result): GlobalError(n.info, errCyclicTree)
  dec(evalTemplateCounter)
  c.callsite = nil
