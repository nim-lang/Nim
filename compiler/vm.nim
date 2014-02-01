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

import ast except getstr

import
  strutils, astalgo, msgs, vmdef, vmgen, nimsets, types, passes, unsigned,
  parser, vmdeps, idents, trees, renderer, options

from semfold import leValueConv, ordinalValToString
from evaltempl import evalTemplate

when hasFFI:
  import evalffi

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
  localError(c.debug[pc], msg, arg)

proc bailOut(c: PCtx; tos: PStackFrame) =
  stackTrace(c, tos, c.exceptionInstr, errUnhandledExceptionX,
             c.currentExceptionA.sons[2].strVal)

when not defined(nimComputedGoto):
  {.pragma: computedGoto.}

proc myreset(n: PNode) =
  when defined(system.reset): 
    var oldInfo = n.info
    reset(n[])
    n.info = oldInfo

proc skipMeta(n: PNode): PNode = (if n.kind != nkMetaNode: n else: n.sons[0])

proc setMeta(n, child: PNode) =
  assert n.kind == nkMetaNode
  let child = child.skipMeta
  if n.sons.isNil: n.sons = @[child]
  else: n.sons[0] = child

proc uast(n: PNode): PNode {.inline.} =
  # "underlying ast"
  assert n.kind == nkMetaNode
  n.sons[0]

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

proc moveConst(x, y: PNode) =
  if x.kind != y.kind:
    myreset(x)
    x.kind = y.kind
  x.typ = y.typ
  case x.kind
  of nkCharLit..nkInt64Lit: x.intVal = y.intVal
  of nkFloatLit..nkFloat64Lit: x.floatVal = y.floatVal
  of nkStrLit..nkTripleStrLit: move(x.strVal, y.strVal)
  of nkIdent: x.ident = y.ident
  of nkSym: x.sym = y.sym
  of nkMetaNode:
    if x.sons.isNil: x.sons = @[y.sons[0]]
    else: x.sons[0] = y.sons[0]
  else:
    if x.kind notin {nkEmpty..nkNilLit}:
      move(x.sons, y.sons)

# this seems to be the best way to model the reference semantics
# of PNimrodNode:
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

proc asgnComplex(x, y: PNode) =
  if x.kind != y.kind:
    myreset(x)
    x.kind = y.kind
  x.typ = y.typ
  case x.kind
  of nkCharLit..nkInt64Lit: x.intVal = y.intVal
  of nkFloatLit..nkFloat64Lit: x.floatVal = y.floatVal
  of nkStrLit..nkTripleStrLit: x.strVal = y.strVal
  of nkIdent: x.ident = y.ident
  of nkSym: x.sym = y.sym
  of nkMetaNode:
    if x.sons.isNil: x.sons = @[y.sons[0]]
    else: x.sons[0] = y.sons[0]
  else:
    if x.kind notin {nkEmpty..nkNilLit}:
      let y = y.copyValue
      for i in countup(0, sonsLen(y) - 1): 
        if i < x.len: x.sons[i] = y.sons[i]
        else: addSon(x, y.sons[i])

template getstr(a: expr): expr =
  (if a.kind in {nkStrLit..nkTripleStrLit}: a.strVal else: $chr(int(a.intVal)))

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

proc regsContents(regs: TNodeSeq) =
  for i in 0.. <regs.len:
    echo "Register ", i
    #debug regs[i]

proc rawExecute(c: PCtx, start: int, tos: PStackFrame): PNode =
  var pc = start
  var tos = tos
  var regs: TNodeSeq # alias to tos.slots for performance
  move(regs, tos.slots)
  #echo "NEW RUN ------------------------"
  while true:
    #{.computedGoto.}
    let instr = c.code[pc]
    let ra = instr.regA
    #echo "PC ", pc, " ", c.code[pc].opcode, " ra ", ra
    #message(c.debug[pc], warnUser, "gah")
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
      decodeB(nkIntLit)
      regs[ra].intVal = regs[rb].intVal
    of opcAsgnStr:
      if regs[instr.regB].kind == nkNilLit:
        decodeB(nkNilLit)
      else:
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
      asgnRef(c.globals.sons[instr.regBx-wordExcess-1], regs[ra])
    of opcWrGlobal:
      asgnComplex(c.globals.sons[instr.regBx-wordExcess-1], regs[ra])
    of opcLdArr, opcLdArrRef:
      # a = b[c]
      let rb = instr.regB
      let rc = instr.regC
      if regs[rc].intVal > high(int):
        stackTrace(c, tos, pc, errIndexOutOfBounds)
      let idx = regs[rc].intVal.int
      # XXX what if the array is not 0-based? -> codegen should insert a sub
      assert regs[rb].kind != nkMetaNode
      let src = regs[rb]
      if src.kind notin {nkEmpty..nkNilLit} and idx <% src.len:
        if instr.opcode == opcLdArrRef and false:
          # XXX activate when seqs are fixed
          asgnRef(regs[ra], src.sons[idx])
        else:
          asgnComplex(regs[ra], src.sons[idx])
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcLdStrIdx:
      decodeBC(nkIntLit)
      let idx = regs[rc].intVal.int
      if idx <=% regs[rb].strVal.len:
        regs[ra].intVal = regs[rb].strVal[idx].ord
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcWrArr:
      # a[b] = c
      let rb = instr.regB
      let rc = instr.regC
      let idx = regs[rb].intVal.int
      if idx <% regs[ra].len:
        asgnComplex(regs[ra].sons[idx], regs[rc])
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcWrArrRef:
      let rb = instr.regB
      let rc = instr.regC
      let idx = regs[rb].intVal.int
      if idx <% regs[ra].len:
        asgnRef(regs[ra].sons[idx], regs[rc])
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcLdObj:
      # a = b.c
      let rb = instr.regB
      let rc = instr.regC
      #Message(c.debug[pc], warnUser, $regs[rb].safeLen & " " & $rc)
      asgnComplex(regs[ra], regs[rb].sons[rc])
    of opcLdObjRef:
      # a = b.c
      let rb = instr.regB
      let rc = instr.regC
      # XXX activate when seqs are fixed
      asgnComplex(regs[ra], regs[rb].sons[rc])
      #asgnRef(regs[ra], regs[rb].sons[rc])
    of opcWrObj:
      # a.b = c
      let rb = instr.regB
      let rc = instr.regC
      #if regs[ra].isNil or regs[ra].sons.isNil or rb >= len(regs[ra]):
      #  debug regs[ra]
      #  debug regs[rc]
      #  echo "RB ", rb
      #  internalError(c.debug[pc], "argl")
      asgnComplex(regs[ra].sons[rb], regs[rc])
    of opcWrObjRef:
      let rb = instr.regB
      let rc = instr.regC
      asgnRef(regs[ra].sons[rb], regs[rc])
    of opcWrStrIdx:
      decodeBC(nkStrLit)
      let idx = regs[rb].intVal.int
      if idx <% regs[ra].strVal.len:
        regs[ra].strVal[idx] = chr(regs[rc].intVal)
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
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
      # XXX this is not correct
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
      # also used by mNLen:
      regs[ra].intVal = regs[rb].skipMeta.len - imm
    of opcLenStr:
      decodeBImm(nkIntLit)
      if regs[rb].kind == nkNilLit:
        stackTrace(c, tos, pc, errNilAccess)
      else:
        assert regs[rb].kind in {nkStrLit..nkTripleStrLit}
        regs[ra].intVal = regs[rb].strVal.len - imm
    of opcIncl:
      decodeB(nkCurly)
      if not inSet(regs[ra], regs[rb]): addSon(regs[ra], copyTree(regs[rb]))
    of opcInclRange:
      decodeBC(nkCurly)
      var r = newNode(nkRange)
      r.add regs[rb]
      r.add regs[rc]
      addSon(regs[ra], r.copyTree)
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
    of opcEqNimrodNode:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].skipMeta == regs[rc].skipMeta)
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
      regs[ra].intVal = ord(regs[rb].strVal == regs[rc].strVal)
    of opcLeStr:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].strVal <= regs[rc].strVal)
    of opcLtStr:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(regs[rb].strVal < regs[rc].strVal)
    of opcLeSet:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(containsSets(regs[rb], regs[rc]))
    of opcEqSet: 
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(equalSets(regs[rb], regs[rc]))
    of opcLtSet:
      decodeBC(nkIntLit)
      let a = regs[rb]
      let b = regs[rc]
      regs[ra].intVal = ord(containsSets(a, b) and not equalSets(a, b))
    of opcMulSet:
      decodeBC(nkCurly)
      move(regs[ra].sons, nimsets.intersectSets(regs[rb], regs[rc]).sons)
    of opcPlusSet: 
      decodeBC(nkCurly)
      move(regs[ra].sons, nimsets.unionSets(regs[rb], regs[rc]).sons)
    of opcMinusSet:
      decodeBC(nkCurly)
      move(regs[ra].sons, nimsets.diffSets(regs[rb], regs[rc]).sons)
    of opcSymdiffSet:
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
        #if regs[i].kind != nkStrLit: debug regs[i]
        write(stdout, regs[i].strVal)
      writeln(stdout, "")
    of opcContainsSet:
      decodeBC(nkIntLit)
      regs[ra].intVal = ord(inSet(regs[rb], regs[rc]))
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
      let isClosure = regs[rb].kind == nkPar
      let prc = if not isClosure: regs[rb].sym else: regs[rb].sons[0].sym
      if sfImportc in prc.flags:
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
            asgnRef(regs[ra], newValue)
        else:
          globalError(c.debug[pc], errGenerated, "VM not built with FFI support")
      elif prc.kind != skTemplate:
        let newPc = compile(c, prc)
        #echo "new pc ", newPc, " calling: ", prc.name.s
        var newFrame = PStackFrame(prc: prc, comesFrom: pc, next: tos)
        newSeq(newFrame.slots, prc.offset)
        if not isEmptyType(prc.typ.sons[0]) or prc.kind == skMacro:
          newFrame.slots[0] = getNullValue(prc.typ.sons[0], prc.info)
        # pass every parameter by var (the language definition allows this):
        for i in 1 .. rc-1:
          newFrame.slots[i] = regs[rb+i]
        if isClosure:
          newFrame.slots[rc] = regs[rb].sons[1]
        # allocate the temporaries:
        for i in rc+ord(isClosure) .. <prc.offset:
          newFrame.slots[i] = newNode(nkEmpty)
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
        for i in 1 .. rc-1: macroCall.add(regs[rb+i].skipMeta)
        let a = evalTemplate(macroCall, prc, genSymOwner)
        ensureKind(nkMetaNode)
        setMeta(regs[ra], a)
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
      # we know the next instruction is a 'fjmp':
      let branch = c.constants[instr.regBx-wordExcess]
      var cond = false
      for j in countup(0, sonsLen(branch) - 2): 
        if overlap(regs[ra], branch.sons[j]): 
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
        pc = cleanUpOnException(c, tos, regs)-1
        if pc < 0: 
          bailOut(c, tos)
          return
    of opcRaise:
      let raised = regs[ra]
      c.currentExceptionA = raised
      c.exceptionInstr = pc
      # -1 because of the following 'inc'
      pc = cleanUpOnException(c, tos, regs) - 1
      if pc < 0:
        bailOut(c, tos)
        return
    of opcNew:
      let typ = c.types[instr.regBx - wordExcess]
      regs[ra] = getNullValue(typ, regs[ra].info)
      regs[ra].flags.incl nfIsRef
    of opcNewSeq:
      let typ = c.types[instr.regBx - wordExcess]
      inc pc
      ensureKind(nkBracket)
      let instr2 = c.code[pc]
      let count = regs[instr2.regA].intVal.int
      regs[ra].typ = typ
      newSeq(regs[ra].sons, count)
      for i in 0 .. <count:
        regs[ra].sons[i] = getNullValue(typ.sons[0], regs[ra].info)
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
      let rb = instr.regBx - wordExcess
      if regs[ra].isNil:
        regs[ra] = copyTree(c.constants.sons[rb])
      else:
        moveConst(regs[ra], c.constants.sons[rb])
    of opcAsgnConst:
      let rb = instr.regBx - wordExcess
      if regs[ra].isNil:
        regs[ra] = copyTree(c.constants.sons[rb])
      else:
        asgnComplex(regs[ra], c.constants.sons[rb])
    of opcLdGlobal:
      let rb = instr.regBx - wordExcess - 1
      if regs[ra].isNil:
        regs[ra] = copyTree(c.globals.sons[rb])
      else:
        asgnComplex(regs[ra], c.globals.sons[rb])
    of opcRepr:
      decodeB(nkStrLit)
      regs[ra].strVal = renderTree(regs[rb].skipMeta, {renderNoComments})
    of opcQuit:
      if c.mode in {emRepl, emStaticExpr, emStaticStmt}:
        message(c.debug[pc], hintQuitCalled)
        quit(int(getOrdValue(regs[ra])))
      else:
        return nil
    of opcSetLenStr:
      decodeB(nkStrLit)
      regs[ra].strVal.setLen(regs[rb].getOrdValue.int)
    of opcOf:
      decodeBC(nkIntLit)
      let typ = c.types[regs[rc].intVal.int]
      regs[ra].intVal = ord(inheritanceDiff(regs[rb].typ, typ) >= 0)
    of opcIs:
      decodeBC(nkIntLit)
      let t1 = regs[rb].typ.skipTypes({tyTypeDesc})
      let t2 = c.types[regs[rc].intVal.int]
      # XXX: This should use the standard isOpImpl
      let match = if t2.kind == tyUserTypeClass: true
                  else: sameType(t1, t2)
      regs[ra].intVal = ord(match)
    of opcSetLenSeq:
      decodeB(nkBracket)
      let newLen = regs[rb].getOrdValue.int
      setLen(regs[ra].sons, newLen)
    of opcSwap, opcReset:
      internalError(c.debug[pc], "too implement")
    of opcIsNil:
      decodeB(nkIntLit)
      regs[ra].intVal = ord(regs[rb].skipMeta.kind == nkNilLit)
    of opcNBindSym:
      decodeBx(nkMetaNode)
      setMeta(regs[ra], copyTree(c.constants.sons[rbx]))
    of opcNChild:
      decodeBC(nkMetaNode)
      if regs[rb].kind != nkMetaNode:
        internalError(c.debug[pc], "no MetaNode")
      let idx = regs[rc].intVal.int
      let src = regs[rb].uast
      if src.kind notin {nkEmpty..nkNilLit} and idx <% src.len:
        setMeta(regs[ra], src.sons[idx])
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcNSetChild:
      decodeBC(nkMetaNode)
      let idx = regs[rb].intVal.int
      var dest = regs[ra].uast
      if dest.kind notin {nkEmpty..nkNilLit} and idx <% dest.len:
        dest.sons[idx] = regs[rc].uast
      else:
        stackTrace(c, tos, pc, errIndexOutOfBounds)
    of opcNAdd:
      decodeBC(nkMetaNode)
      var u = regs[rb].uast
      u.add(regs[rc].uast)
      setMeta(regs[ra], u)
    of opcNAddMultiple:
      decodeBC(nkMetaNode)
      let x = regs[rc]
      var u = regs[rb].uast
      # XXX can be optimized:
      for i in 0.. <x.len: u.add(x.sons[i].skipMeta)
      setMeta(regs[ra], u)
    of opcNKind:
      decodeB(nkIntLit)
      regs[ra].intVal = ord(regs[rb].uast.kind)
    of opcNIntVal:
      decodeB(nkIntLit)
      let a = regs[rb].uast
      case a.kind
      of nkCharLit..nkInt64Lit: regs[ra].intVal = a.intVal
      else: stackTrace(c, tos, pc, errFieldXNotFound, "intVal")
    of opcNFloatVal:
      decodeB(nkFloatLit)
      let a = regs[rb].uast
      case a.kind
      of nkFloatLit..nkFloat64Lit: regs[ra].floatVal = a.floatVal
      else: stackTrace(c, tos, pc, errFieldXNotFound, "floatVal")
    of opcNSymbol:
      decodeB(nkSym)
      let a = regs[rb].uast
      if a.kind == nkSym:
        regs[ra].sym = a.sym
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "symbol")
    of opcNIdent:
      decodeB(nkIdent)
      let a = regs[rb].uast
      if a.kind == nkIdent:
        regs[ra].ident = a.ident
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "ident")
    of opcNGetType:
      internalError(c.debug[pc], "unknown opcode " & $instr.opcode)
    of opcNStrVal:
      decodeB(nkStrLit)
      let a = regs[rb].uast
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
      message(c.debug[pc], warnUser, regs[ra].strVal)
    of opcNHint:
      message(c.debug[pc], hintUser, regs[ra].strVal)
    of opcParseExprToAst:
      decodeB(nkMetaNode)
      # c.debug[pc].line.int - countLines(regs[rb].strVal) ?
      let ast = parseString(regs[rb].strVal, c.debug[pc].toFilename,
                            c.debug[pc].line.int)
      if sonsLen(ast) != 1:
        globalError(c.debug[pc], errExprExpected, "multiple statements")
      setMeta(regs[ra], ast.sons[0])
    of opcParseStmtToAst:
      decodeB(nkMetaNode)
      let ast = parseString(regs[rb].strVal, c.debug[pc].toFilename,
                            c.debug[pc].line.int)
      setMeta(regs[ra], ast)
    of opcCallSite:
      ensureKind(nkMetaNode)
      if c.callsite != nil: setMeta(regs[ra], c.callsite)
      else: stackTrace(c, tos, pc, errFieldXNotFound, "callsite")
    of opcNLineInfo:
      decodeB(nkStrLit)
      let n = regs[rb]
      regs[ra].strVal = n.info.toFileLineCol
      regs[ra].info = c.debug[pc]
    of opcEqIdent:
      decodeBC(nkIntLit)
      if regs[rb].kind == nkIdent and regs[rc].kind == nkIdent:
        regs[ra].intVal = ord(regs[rb].ident.id == regs[rc].ident.id)
      else:
        regs[ra].intVal = 0
    of opcStrToIdent:
      decodeB(nkIdent)
      if regs[rb].kind notin {nkStrLit..nkTripleStrLit}:
        stackTrace(c, tos, pc, errFieldXNotFound, "strVal")
      else:
        regs[ra].info = c.debug[pc]
        regs[ra].ident = getIdent(regs[rb].strVal)
    of opcIdentToStr:
      decodeB(nkStrLit)
      let a = regs[rb]
      regs[ra].info = c.debug[pc]
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
    of opcCast:
      let rb = instr.regB
      inc pc
      let typ = c.types[c.code[pc].regBx - wordExcess]
      when hasFFI:
        let dest = fficast(regs[rb], typ)
        asgnRef(regs[ra], dest)
      else:
        globalError(c.debug[pc], "cannot evaluate cast")
    of opcNSetIntVal:
      decodeB(nkMetaNode)
      var dest = regs[ra].uast
      if dest.kind in {nkCharLit..nkInt64Lit} and 
         regs[rb].kind in {nkCharLit..nkInt64Lit}:
        dest.intVal = regs[rb].intVal
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "intVal")
    of opcNSetFloatVal:
      decodeB(nkMetaNode)
      var dest = regs[ra].uast
      if dest.kind in {nkFloatLit..nkFloat64Lit} and 
         regs[rb].kind in {nkFloatLit..nkFloat64Lit}:
        dest.floatVal = regs[rb].floatVal
      else: 
        stackTrace(c, tos, pc, errFieldXNotFound, "floatVal")
    of opcNSetSymbol:
      decodeB(nkMetaNode)
      var dest = regs[ra].uast
      if dest.kind == nkSym and regs[rb].kind == nkSym:
        dest.sym = regs[rb].sym
      else: 
        stackTrace(c, tos, pc, errFieldXNotFound, "symbol")
    of opcNSetIdent:
      decodeB(nkMetaNode)
      var dest = regs[ra].uast
      if dest.kind == nkIdent and regs[rb].kind == nkIdent:
        dest.ident = regs[rb].ident
      else: 
        stackTrace(c, tos, pc, errFieldXNotFound, "ident")
    of opcNSetType:
      decodeB(nkMetaNode)
      let b = regs[rb].skipMeta
      internalAssert b.kind == nkSym and b.sym.kind == skType
      regs[ra].uast.typ = b.sym.typ
    of opcNSetStrVal:
      decodeB(nkMetaNode)
      var dest = regs[ra].uast
      if dest.kind in {nkStrLit..nkTripleStrLit} and 
         regs[rb].kind in {nkStrLit..nkTripleStrLit}:
        dest.strVal = regs[rb].strVal
      else:
        stackTrace(c, tos, pc, errFieldXNotFound, "strVal")
    of opcNNewNimNode:
      decodeBC(nkMetaNode)
      var k = regs[rb].intVal
      if k < 0 or k > ord(high(TNodeKind)) or k == ord(nkMetaNode):
        internalError(c.debug[pc],
          "request to create a NimNode of invalid kind")
      let cc = regs[rc].skipMeta
      setMeta(regs[ra], newNodeI(TNodeKind(int(k)), 
        if cc.kind == nkNilLit: c.debug[pc] else: cc.info))
      regs[ra].sons[0].flags.incl nfIsRef
    of opcNCopyNimNode:
      decodeB(nkMetaNode)
      setMeta(regs[ra], copyNode(regs[rb]))
    of opcNCopyNimTree:
      decodeB(nkMetaNode)
      setMeta(regs[ra], copyTree(regs[rb]))
    of opcNDel:
      decodeBC(nkMetaNode)
      let bb = regs[rb].intVal.int
      for i in countup(0, regs[rc].intVal.int-1):
        delSon(regs[ra].uast, bb)
    of opcGenSym:
      decodeBC(nkMetaNode)
      let k = regs[rb].intVal
      let name = if regs[rc].strVal.len == 0: ":tmp" else: regs[rc].strVal
      if k < 0 or k > ord(high(TSymKind)):
        internalError(c.debug[pc], "request to create symbol of invalid kind")
      var sym = newSym(k.TSymKind, name.getIdent, c.module, c.debug[pc])
      incl(sym.flags, sfGenSym)
      setMeta(regs[ra], newSymNode(sym))
    of opcTypeTrait:
      # XXX only supports 'name' for now; we can use regC to encode the
      # type trait operation
      decodeB(nkStrLit)
      let typ = regs[rb].sym.typ.skipTypes({tyTypeDesc})
      regs[ra].strVal = typ.typeToString(preferExported)
    of opcGlobalOnce:
      let rb = instr.regBx
      if c.globals.sons[rb - wordExcess - 1].kind != nkEmpty:
        # skip initialization instructions:
        while true:
          inc pc
          if c.code[pc].opcode in {opcWrGlobal, opcWrGlobalRef} and
             c.code[pc].regBx == rb:
            break
    of opcGlobalAlias:
      let rb = instr.regBx - wordExcess - 1
      regs[ra] = c.globals.sons[rb]
    inc pc

proc fixType(result, n: PNode) {.inline.} =
  # XXX do it deeply for complex values; there seems to be no simple
  # solution except to check it deeply here.
  #if result.typ.isNil: result.typ = n.typ
  discard

proc execute(c: PCtx, start: int): PNode =
  var tos = PStackFrame(prc: nil, comesFrom: 0, next: nil)
  newSeq(tos.slots, c.prc.maxSlots)
  for i in 0 .. <c.prc.maxSlots: tos.slots[i] = newNode(nkEmpty)
  result = rawExecute(c, start, tos)

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
  if not result.isNil:
    result = result.skipMeta
    fixType(result, n)

# for now we share the 'globals' environment. XXX Coming soon: An API for
# storing&loading the 'globals' environment to get what a component system
# requires.
var
  globalCtx: PCtx

proc setupGlobalCtx(module: PSym) =
  if globalCtx.isNil: globalCtx = newCtx(module)
  else: refresh(globalCtx, module)

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
  setupGlobalCtx(module)
  var c = globalCtx
  c.mode = mode
  let start = genExpr(c, n, requiresValue = mode!=emStaticStmt)
  if c.code[start].opcode == opcEof: return emptyNode
  assert c.code[start].opcode != opcEof
  var tos = PStackFrame(prc: prc, comesFrom: 0, next: nil)
  newSeq(tos.slots, c.prc.maxSlots)
  for i in 0 .. <c.prc.maxSlots: tos.slots[i] = newNode(nkEmpty)
  result = rawExecute(c, start, tos)
  fixType(result, n)

proc evalConstExpr*(module: PSym, e: PNode): PNode = 
  result = evalConstExprAux(module, nil, e, emConst)

proc evalStaticExpr*(module: PSym, e: PNode, prc: PSym): PNode =
  result = evalConstExprAux(module, prc, e, emStaticExpr)

proc evalStaticStmt*(module: PSym, e: PNode, prc: PSym) =
  discard evalConstExprAux(module, prc, e, emStaticStmt)

proc setupMacroParam(x: PNode): PNode =
  result = x
  if result.kind in {nkHiddenSubConv, nkHiddenStdConv}: result = result.sons[1]
  let y = result
  y.flags.incl nfIsRef
  result = newNode(nkMetaNode)
  result.add y
  result.typ = x.typ

var evalMacroCounter: int

proc evalMacroCall*(module: PSym, n, nOrig: PNode, sym: PSym): PNode =
  # XXX GlobalError() is ugly here, but I don't know a better solution for now
  inc(evalMacroCounter)
  if evalMacroCounter > 100:
    globalError(n.info, errTemplateInstantiationTooNested)
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
  tos.slots[0] = newNodeIT(nkNilLit, n.info, sym.typ.sons[0])
  # setup parameters:
  for i in 1 .. < min(tos.slots.len, L):
    tos.slots[i] = setupMacroParam(n.sons[i])
  # temporary storage:
  for i in L .. <maxSlots: tos.slots[i] = newNode(nkEmpty)
  result = rawExecute(c, start, tos)
  if cyclicTree(result): globalError(n.info, errCyclicTree)
  dec(evalMacroCounter)
  if result != nil:
    result = result.skipMeta
  c.callsite = nil
