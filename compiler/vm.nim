#
#
#           The Nim Compiler
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This file implements the evaluation engine for Nim code.
## It is a register based VM that works on packed data, see vmdef.

import semmacrosanity
import ic/sharedcounters
import
  std/[strutils, tables, intsets, parseutils, bitops],
  msgs, vmdef, vmgen, nimsets, types,
  parser, vmdeps, idents, trees, renderer, options, transf,
  gorgeimpl, lineinfos, btrees, macrocacheimpl,
  modulegraphs, sighashes, int128, vmprofiler, vmvalue

when defined(nimPreviewSlimSystem):
  import std/formatfloat
import ast except getstr
from semfold import leValueConv, ordinalValToString
from evaltempl import evalTemplate
from magicsys import getSysType, sysTypeFromName
from astalgo import lookupInRecord
from liftdestructors import isTrivial

const
  traceCode = defined(nimVMDebug)

proc stackTraceAux(c: PCtx; x: PStackFrame; pc: int; recursionLimit=100) =
  if x != nil:
    if recursionLimit == 0:
      var calls = 0
      var x = x
      while x != nil:
        inc calls
        x = x.next
      msgWriteln(c.config, $calls & " calls omitted\n", {msgNoUnitSep})
      return
    stackTraceAux(c, x.next, x.comesFrom, recursionLimit-1)
    var info = c.debug[pc]
    # we now use a format similar to the one in lib/system/excpt.nim
    var s = ""
    # todo: factor with quotedFilename
    if optExcessiveStackTrace in c.config.globalOptions:
      s = toFullPath(c.config, info)
    else:
      s = toFilename(c.config, info)
    var line = toLinenumber(info)
    var col = toColumn(info)
    if line > 0:
      s.add('(')
      s.add($line)
      s.add(", ")
      s.add($(col + ColOffset))
      s.add(')')
    if x.prc != nil:
      for k in 1..max(1, 25-s.len): s.add(' ')
      s.add(x.prc.name.s)
    msgWriteln(c.config, s, {msgNoUnitSep})

proc stackTraceImpl(c: PCtx, tos: PStackFrame, pc: int,
  msg: string, lineInfo: TLineInfo, infoOrigin: InstantiationInfo) {.noinline.} =
  # noinline to avoid code bloat
  msgWriteln(c.config, "stack trace: (most recent call last)", {msgNoUnitSep})
  stackTraceAux(c, tos, pc)
  let action = if c.mode == emRepl: doRaise else: doNothing
    # XXX test if we want 'globalError' for every mode
  let lineInfo = if lineInfo == TLineInfo.default: c.debug[pc] else: lineInfo
  liMessage(c.config, lineInfo, errGenerated, msg, action, infoOrigin)

when not defined(nimHasCallsitePragma):
  {.pragma: callsite.}

template stackTrace(c: PCtx, tos: PStackFrame, pc: int,
                    msg: string, lineInfo: TLineInfo = TLineInfo.default) {.callsite.} =
  stackTraceImpl(c, tos, pc, msg, lineInfo, instantiationInfo(-2, fullPaths = true))
  return

const
  errNilAccess = "attempt to access a nil address"
  errInvalidAccess = "attempt to access an invalid address"
  errConstAccess = "attempt to modify constant memory"
  errOverOrUnderflow = "over- or underflow"
  errConstantDivisionByZero = "division by zero"
  errIllegalConvFromXtoY = "illegal conversion from '$1' to '$2'"
  errTooManyIterations = "interpretation requires too many iterations; " &
    "if you are sure this is not a bug in your code, compile with `--maxLoopIterationsVM:number` (current value: $1)"
  errCallDepthExceeded = "maximum call depth for the VM exceeded; " &
    "if you are sure this is not a bug in your code, compile with `--maxCallDepthVM:number` (current value: $1)"
  errFieldXNotFound = "node lacks field: "
  errInvalidFree = "attempt to free memory that was not allocated"

when not defined(nimComputedGoto):
  {.pragma: computedGoto.}

# ------------------------- memory helpers ------------------------------------

proc memErrorMsg(c: PCtx; a: Address; write: bool): string =
  if a < 4096: errNilAccess
  elif write and isConstMemory(c.mem, a): errConstAccess
  else: errInvalidAccess

proc storeInt(dest: Address; k: MemKind; v: int64) {.inline.} =
  case k
  of mkI8, mkU8: st[uint8](dest, cast[uint8](v))
  of mkI16, mkU16: st[uint16](dest, cast[uint16](v))
  of mkI32, mkU32: st[uint32](dest, cast[uint32](v))
  of mkF32: st[float32](dest, float32(cast[float64](v)))
  of mkI64, mkU64, mkF64, mkPtr, mkNode, mkBlock: st[int64](dest, v)

proc readString(c: PCtx; s: Address): string =
  if not canRead(c.mem, s, 16): return ""
  let L = ld[int](s)
  let p = ld[Address](s +! StrPayloadOffset)
  if L <= 0 or p == 0 or not canRead(c.mem, p, PayloadDataOffset + L): return ""
  result = loadString(s)

proc readCString(c: PCtx; p: Address): string =
  result = ""
  var q = p
  while q != 0 and canRead(c.mem, q, 1):
    let ch = ld[char](q)
    if ch == '\0': break
    result.add ch
    q = q +! 1

proc regToNode(c: PCtx; a: Address; t: PType; info: TLineInfo): PNode =
  ## turns a value in register format into an AST
  let vc = valueConv(c)
  let k = memKind(c.config, t)
  if k != mkBlock:
    var buf = default(array[8, byte])
    storeInt(toAddr(addr buf[0]), k, ld[int64](a))
    result = loadValue(vc, toAddr(addr buf[0]), t, info)
    if k != mkNode and result.kind in {nkCharLit..nkUInt64Lit} and result.kind != nkIntLit:
      # like the old VM: integral values are `nkIntLit`s; this matters as
      # the literal kind is part of type hashes (`range[T(0)..T(1)]`)
      let x = newIntNode(nkIntLit, result.intVal)
      x.typ = result.typ
      x.info = result.info
      result = x
  else:
    result = loadValue(vc, a, t, info)

proc nodeToReg(c: PCtx; n: PNode; t: PType; dest: Address) =
  ## stores the AST `n` in register format at `dest`
  let vc = valueConv(c)
  let k = memKind(c.config, t)
  if k != mkBlock:
    var buf = default(array[8, byte])
    storeValue(vc, toAddr(addr buf[0]), n, t, inConst = false)
    st[int64](dest, vmvalue.loadInt(toAddr(addr buf[0]), k))
  else:
    zeroMem(toPtr(dest), vmSizeOf(c.layouts, c.config, t))
    storeValue(vc, dest, n, t, inConst = false)

# ------------------------- strings and seqs ----------------------------------

proc payloadOk(c: PCtx; p: Address; bytes: int): bool {.inline.} =
  p == 0 or canRead(c.mem, p, bytes)

proc reserve(c: PCtx; s: Address; newLen, esize, ealign: int; isString: bool): bool =
  ## makes the payload of the string or seq at `s` unique and big enough for
  ## `newLen` elements. Returns false for invalid memory.
  if not canWrite(c.mem, s, 16): return false
  let len = ld[int](s)
  let p = ld[Address](s +! StrPayloadOffset)
  let dataOff = payloadDataOffset(ealign)
  if len < 0: return false
  if p != 0 and not canRead(c.mem, p, dataOff + len*esize): return false
  if p == 0 and len > 0: return false
  if p != 0 and not isLiteralPayload(p) and payloadCap(p) >= newLen: return true
  var newCap = max(newLen, 4)
  if p != 0 and not isLiteralPayload(p):
    newCap = max(newCap, payloadCap(p) * 3 div 2)
  let q = newPayload(c.mem, newCap, esize, ealign, isString)
  if p != 0 and len > 0:
    copyMem(toPtr(q +! dataOff), toPtr(p +! dataOff), min(len, newLen)*esize)
  if p != 0 and not isLiteralPayload(p):
    discard heapDealloc(c.mem, p)
  st[Address](s +! StrPayloadOffset, q)
  result = true

proc strSetLen(c: PCtx; s: Address; newLen: int): bool =
  if newLen < 0: return false
  if not reserve(c, s, newLen, 1, 1, true): return false
  let len = ld[int](s)
  let p = ld[Address](s +! StrPayloadOffset)
  if newLen > len:
    zeroMem(toPtr(p +! (PayloadDataOffset + len)), newLen - len + 1)
  else:
    st[char](p +! (PayloadDataOffset + newLen), '\0')
  st[int](s, newLen)
  result = true

proc strAdd(c: PCtx; s: Address; data: pointer; L: int): bool =
  let len = ld[int](s)
  if not reserve(c, s, len + L, 1, 1, true): return false
  let p = ld[Address](s +! StrPayloadOffset)
  if L > 0: moveMem(toPtr(p +! (PayloadDataOffset + len)), data, L)
  st[char](p +! (PayloadDataOffset + len + L), '\0')
  st[int](s, len + L)
  result = true

proc strAddStr(c: PCtx; s, src: Address): bool =
  if not canRead(c.mem, src, 16): return false
  let L = ld[int](src)
  if L <= 0: return true
  # `src` may alias `s`; copy first:
  let tmp = readString(c, src)
  if tmp.len != L: return false
  result = strAdd(c, s, unsafeAddr tmp[0], tmp.len)

when defined(nimVmHeapDebug):
  var freedAt: Table[Address, string]
  var curInfo: string

proc freePayload(c: PCtx; s: Address): bool =
  if not canRead(c.mem, s, 16): return false
  let p = ld[Address](s +! StrPayloadOffset)
  if p != 0 and not canRead(c.mem, p, PayloadDataOffset): return false
  if p != 0 and not isLiteralPayload(p):
    result = heapDealloc(c.mem, p)
    when defined(nimVmHeapDebug):
      if result: freedAt[p] = curInfo
  else:
    result = true

proc strAsgn(c: PCtx; dest, src: Address): bool =
  ## `=copy` for strings
  if dest == src: return true
  if not canWrite(c.mem, dest, 16) or not canRead(c.mem, src, 16): return false
  let sp = ld[Address](src +! StrPayloadOffset)
  let L = ld[int](src)
  if L < 0 or not payloadOk(c, sp, PayloadDataOffset + L): return false
  if ld[Address](dest +! StrPayloadOffset) == sp and sp != 0:
    st[int](dest, L)
    return true
  if sp == 0 or isLiteralPayload(sp):
    if not freePayload(c, dest): return false
    st[int](dest, L)
    st[Address](dest +! StrPayloadOffset, sp)
    return true
  if not payloadOk(c, sp, PayloadDataOffset + L): return false
  let tmp = loadString(src)
  st[int](dest, 0)
  result = strSetLen(c, dest, 0)
  if result and tmp.len > 0:
    result = strAdd(c, dest, unsafeAddr tmp[0], tmp.len)

proc assignString(c: PCtx; dest: Address; s: string) =
  ## replaces the string at `dest` with `s`
  if strSetLen(c, dest, 0) and s.len > 0:
    discard strAdd(c, dest, unsafeAddr s[0], s.len)

proc writeString(c: PCtx; dest: Address; s: string) =
  ## writes a fresh string to `dest`, which does not own a payload
  storeString(c.mem, dest, s, inConst = false)

proc strCmp(c: PCtx; a, b: Address): int =
  let x = readString(c, a)
  let y = readString(c, b)
  result = cmp(x, y)

proc emptyCString(c: PCtx): Address =
  # a zero byte in constant memory
  if c.emptyCStr == 0:
    c.emptyCStr = allocConst(c.mem, 1, 1)
  result = c.emptyCStr

proc seqSetLen(c: PCtx; s: Address; newLen, esize, ealign: int): bool =
  if newLen < 0: return false
  let len = ld[int](s)
  if newLen > len:
    if not reserve(c, s, newLen, esize, ealign, false): return false
    let p = ld[Address](s +! StrPayloadOffset)
    let dataOff = payloadDataOffset(ealign)
    zeroMem(toPtr(p +! (dataOff + len*esize)), (newLen - len)*esize)
  st[int](s, newLen)
  result = true

# ------------------------- type headers --------------------------------------

proc initObj(c: PCtx; a: Address; t: PType) =
  let t = skipForLayout(t)
  case t.kind
  of tyObject:
    var root = t
    while root.baseClass != nil: root = root.baseClass.skipTypes(skipPtrs)
    if hasTypeHeader(root):
      st[int64](a, typeHandle(c.mem, t))
    proc fields(c: PCtx; a: Address; obj: PType; n: PNode) =
      case n.kind
      of nkSym:
        let ft = skipForLayout(n.sym.typ)
        if ft.kind in {tyObject, tyArray, tyTuple}:
          initObj(c, a +! fieldOffset(c.layouts, c.config, obj, n.sym), ft)
      of nkRecList:
        for ch in n: fields(c, a, obj, ch)
      of nkRecCase:
        # the discriminator is 0, so the first branch is active:
        fields(c, a, obj, n[0])
        if n.len > 1: fields(c, a, obj, n[1].lastSon)
      else: discard
    var b = t
    while b != nil:
      if b.n != nil: fields(c, a, t, b.n)
      b = if b.baseClass != nil: b.baseClass.skipTypes(skipPtrs) else: nil
  of tyArray:
    let et = skipForLayout(t.elementType)
    if et.kind in {tyObject, tyArray, tyTuple}:
      let esize = vmSizeOf(c.layouts, c.config, et)
      for i in 0..<toInt(lengthOrd(c.config, t)):
        initObj(c, a +! i*esize, et)
  of tyTuple:
    for i, ch in t.ikids:
      let et = skipForLayout(ch)
      if et.kind in {tyObject, tyArray, tyTuple}:
        initObj(c, a +! elemOffset(c.layouts, c.config, t, i), et)
  else:
    discard

proc unshare(c: PCtx; a: Address; t: PType): bool =
  ## gives the strings and seqs of the value at `a` their own payloads.
  result = true
  let t = skipForLayout(t)
  case t.kind
  of tyString:
    if not canWrite(c.mem, a, 16): return false
    let p = ld[Address](a +! StrPayloadOffset)
    let L = ld[int](a)
    if p != 0 and L > 0 and not isLiteralPayload(p):
      if not canRead(c.mem, p, PayloadDataOffset + L): return false
      let q = newPayload(c.mem, L, 1, 1, true)
      copyMem(toPtr(q +! PayloadDataOffset), toPtr(p +! PayloadDataOffset), L)
      st[Address](a +! StrPayloadOffset, q)
  of tySequence:
    if not canWrite(c.mem, a, 16): return false
    let p = ld[Address](a +! StrPayloadOffset)
    let L = ld[int](a)
    if p != 0 and L > 0:
      let et = t.elementType
      let esize = vmSizeOf(c.layouts, c.config, et)
      let ealign = vmAlignOf(c.layouts, c.config, et)
      let off = payloadDataOffset(ealign)
      if not canRead(c.mem, p, off + L*esize): return false
      let q = newPayload(c.mem, L, esize, ealign, false)
      copyMem(toPtr(q +! off), toPtr(p +! off), L*esize)
      st[Address](a +! StrPayloadOffset, q)
      for i in 0..<L:
        if not unshare(c, q +! (off + i*esize), et): return false
  of tyArray:
    let et = t.elementType
    let esize = vmSizeOf(c.layouts, c.config, et)
    if skipForLayout(et).kind in {tyString, tySequence, tyArray, tyTuple, tyObject}:
      for i in 0..<toInt(lengthOrd(c.config, t)):
        if not unshare(c, a +! i*esize, et): return false
  of tyTuple:
    for i, ch in t.ikids:
      if not unshare(c, a +! elemOffset(c.layouts, c.config, t, i), ch): return false
  of tyObject:
    proc fields(c: PCtx; a: Address; obj: PType; n: PNode): bool =
      result = true
      case n.kind
      of nkSym:
        result = unshare(c, a +! fieldOffset(c.layouts, c.config, obj, n.sym), n.sym.typ)
      of nkRecList:
        for ch in n:
          if not fields(c, a, obj, ch): return false
      of nkRecCase:
        if not fields(c, a, obj, n[0]): return false
        let disc = n[0].sym
        let v = vmvalue.loadInt(a +! fieldOffset(c.layouts, c.config, obj, disc),
                                memKind(c.config, disc.typ))
        for i in 1..<n.len:
          let b = n[i]
          var matches = b.kind == nkElse
          if not matches:
            for j in 0..<b.len-1:
              let lab = b[j]
              if lab.kind == nkRange:
                if v >= getOrdValue(lab[0]).toInt64 and v <= getOrdValue(lab[1]).toInt64: matches = true
              elif lab.kind in {nkCharLit..nkUInt64Lit, nkSym}:
                if getOrdValue(lab).toInt64 == v: matches = true
          if matches:
            return fields(c, a, obj, b.lastSon)
      else: discard
    var b = t
    while b != nil:
      if b.n != nil and not fields(c, a, t, b.n): return false
      b = if b.baseClass != nil: b.baseClass.skipTypes(skipPtrs) else: nil
  else:
    discard

proc dynamicType(c: PCtx; objAddr: Address): PType =
  ## the type stored in the header of an inheritable object
  if objAddr == 0 or not canRead(c.mem, objAddr, 8): return nil
  result = getType(c.mem, ld[int64](objAddr))

# ------------------------- exceptions ----------------------------------------

proc excFieldOffset(c: PCtx; name: string): int =
  let t = sysTypeFromName(c.graph, unknownLineInfo, "Exception").skipTypes(abstractInst)
  let f = lookupInRecord(t.n, getIdent(c.cache, name))
  if f == nil: return -1
  result = fieldOffset(c.layouts, c.config, t, f)

proc currentExceptionMsg(c: PCtx; e: Address): string =
  if e == 0: return ""
  let off = excFieldOffset(c, "msg")
  if off < 0: return ""
  result = readString(c, e +! off)

proc exceptionName(c: PCtx; e: Address): string =
  let off = excFieldOffset(c, "name")
  if off < 0 or e == 0: return ""
  result = readCString(c, ld[Address](e +! off))

proc setExceptionName(c: PCtx; e: Address) =
  let t = dynamicType(c, e)
  let off = excFieldOffset(c, "name")
  if t == nil or off < 0 or t.sym == nil: return
  var p = c.excNames.getOrDefault(t.id, 0)
  if p == 0:
    let name = t.sym.name.s
    p = allocConst(c.mem, name.len+1, 1)
    if name.len > 0: copyMem(toPtr(p), unsafeAddr name[0], name.len)
    c.excNames[t.id] = p
  if canWrite(c.mem, e +! off, 8):
    st[Address](e +! off, p)

proc bailOut(c: PCtx; tos: PStackFrame) =
  stackTrace(c, tos, c.exceptionInstr, "unhandled exception: " &
             currentExceptionMsg(c, c.currentExceptionA) &
             " [" & exceptionName(c, c.currentExceptionA) & "]")

proc pushSafePoint(f: PStackFrame; pc: int) =
  f.safePoints.add(pc)

proc popSafePoint(f: PStackFrame) =
  # an unhandled exception pops all safepoints; with `nim check` execution
  # continues nevertheless:
  if f.safePoints.len > 0: discard f.safePoints.pop()

type
  ExceptionGoto = enum
    ExceptionGotoHandler,
    ExceptionGotoFinally,
    ExceptionGotoUnhandled

proc findExceptionHandler(c: PCtx, f: PStackFrame, exc: Address):
    tuple[why: ExceptionGoto, where: int] =
  let raisedType = dynamicType(c, exc)

  while f.safePoints.len > 0:
    var pc = f.safePoints.pop()

    var matched = false
    var pcEndExcept = pc

    # Scan the chain of exceptions starting at pc.
    # The structure is the following:
    # pc - opcExcept, <end of this block>
    #      - opcExcept, <pattern1>
    #      - opcExcept, <pattern2>
    #        ...
    #      - opcExcept, <patternN>
    #      - Exception handler body
    #    - ... more opcExcept blocks may follow
    #    - ... an optional opcFinally block may follow
    #
    # Note that the exception handler body already contains a jump to the
    # finally block or, if that's not present, to the point where the execution
    # should continue.
    # Also note that opcFinally blocks are the last in the chain.
    while c.code[pc].opcode == opcExcept:
      # Where this Except block ends
      pcEndExcept = pc + c.code[pc].regBx - wordExcess
      inc pc

      # A series of opcExcept follows for each exception type matched
      while c.code[pc].opcode == opcExcept:
        let excIndex = c.code[pc].regBx - wordExcess
        let exceptType =
          if excIndex > 0: getType(c.mem, excIndex).skipTypes(abstractPtrs)
          else: nil

        # Determine if the exception type matches the pattern
        if exceptType.isNil or (raisedType != nil and
            inheritanceDiff(raisedType, exceptType) <= 0):
          matched = true
          break

        inc pc

      # Skip any further ``except`` pattern and find the first instruction of
      # the handler body
      while c.code[pc].opcode == opcExcept:
        inc pc

      if matched:
        break

      # If no handler in this chain is able to catch this exception we check if
      # the "parent" chains are able to. If this chain ends with a `finally`
      # block we must execute it before continuing.
      pc = pcEndExcept

    # Where the handler body starts
    let pcBody = pc

    if matched:
      return (ExceptionGotoHandler, pcBody)
    elif c.code[pc].opcode == opcFinally:
      # The +1 here is here because we don't want to execute it since we've
      # already pop'd this statepoint from the stack.
      return (ExceptionGotoFinally, pc + 1)

  return (ExceptionGotoUnhandled, 0)

proc cleanUpOnReturn(c: PCtx; f: PStackFrame): int =
  # Walk up the chain of safepoints and return the PC of the first `finally`
  # block we find or -1 if no such block is found.
  # Note that the safepoint is removed once the function returns!
  result = -1

  # Traverse the stack starting from the end in order to execute the blocks in
  # the intended order
  for i in 1..f.safePoints.len:
    var pc = f.safePoints[^i]
    # Skip the `except` blocks
    while c.code[pc].opcode == opcExcept:
      pc += c.code[pc].regBx - wordExcess
    if c.code[pc].opcode == opcFinally:
      discard f.safePoints.pop
      return pc + 1

# ------------------------- conversions ---------------------------------------

proc enumToStr(t: PType; x: BiggestInt): string =
  let n = t.n
  if x <% n.len and (let f = n[x].sym; f.position == x):
    result = if f.ast.isNil: f.name.s else: f.ast.strVal
  else:
    for i in 0..<n.len:
      if n[i].kind != nkSym: continue
      let f = n[i].sym
      if f.position == x:
        return if f.ast.isNil: f.name.s else: f.ast.strVal
    result = t.sym.name.s & " " & $x

proc toStr(c: PCtx; v: int64; t: PType): string =
  let t = t.skipTypes(abstractRange)
  case t.kind
  of tyEnum: enumToStr(t, v)
  of tyInt..tyInt64: $v
  of tyUInt..tyUInt64: $cast[uint64](v)
  of tyBool: (if v == 0: "false" else: "true")
  of tyFloat..tyFloat128: $cast[float64](v)
  of tyChar: $chr(int(v and 0xFF))
  else: $v

proc compile(c: PCtx, s: PSym): VmProcInfo =
  let isNew = not c.procToCodePos.hasKey(s.id)
  when defined(nimVmListing):
    if isNew: echo "COMPILING ", s.name.s, " ", c.config $ s.info
  result = vmgen.genProc(c, s)
  when debugEchoCode: c.echoCode result.pc


template handleJmpBack() {.dirty.} =
  if c.loopIterations <= 0:
    if allowInfiniteLoops in c.features:
      c.loopIterations = c.config.maxLoopIterationsVM
    else:
      msgWriteln(c.config, "stack trace: (most recent call last)", {msgNoUnitSep})
      stackTraceAux(c, tos, pc)
      globalError(c.config, c.debug[pc], errTooManyIterations % $c.config.maxLoopIterationsVM)
  dec(c.loopIterations)

proc recSetFlagIsRef(arg: PNode) =
  if arg.kind notin {nkStrLit..nkTripleStrLit}:
    arg.flags.incl(nfIsRef)
  for i in 0..<arg.safeLen:
    arg[i].recSetFlagIsRef

include vmhooks

proc newFrame(c: PCtx; prc: PSym; slots: int; comesFrom: int; next: PStackFrame): PStackFrame =
  let mark = c.mem.stackMark
  let fp = c.mem.pushFrame(slots * SlotSize)
  result = PStackFrame(prc: prc, fp: fp, mark: mark, next: next,
                       comesFrom: comesFrom, top: c.mem.stackMark)

proc rawExecute(c: PCtx, start: int, tos: PStackFrame): Address =
  ## executes the code at `start`; returns the address of the result value
  ## (in register format), which is valid until the stack is popped.
  result = 0
  var pc = start
  var tos = tos
  var fp = tos.fp
  # Used to keep track of where the execution is resumed.
  var savedPC = -1
  var savedFrame: PStackFrame = nil
  var reraising = false # `opcRaise` is executed again after a `finally`

  template slotAddr(i: untyped): Address = fp +! (int(i) * SlotSize)
  template rInt(i: untyped): untyped = cast[ptr int64](slotAddr(i))[]
  template rFlt(i: untyped): untyped = cast[ptr float64](slotAddr(i))[]
  template rAdr(i: untyped): untyped = cast[ptr Address](slotAddr(i))[]
  template wImm(): uint64 = uint64(c.code[pc+1])
  template node(i: untyped): PNode =
    # like the old VM: a nil NimNode behaves like a `nil` literal node
    (let h = rInt(i); if h == 0: newNodeI(nkNilLit, c.debug[pc]) else: getNode(c.mem, h))
  template nodeNN(i: untyped): PNode = node(i)
  template setNode(i: untyped; n: PNode) = rInt(i) = int64(nodeHandle(c.mem, n))
  template str(i: untyped): string = readString(c, rAdr(i))
  template putStr(i: untyped; s: string) = writeString(c, rAdr(i), s)
  template checkRead(a: Address; size: int) =
    if not canRead(c.mem, a, size): stackTrace(c, tos, pc, memErrorMsg(c, a, false))
  template checkWrite(a: Address; size: int) =
    if not canWrite(c.mem, a, size): stackTrace(c, tos, pc, memErrorMsg(c, a, true))
  template checkIndex(idx, len: int64) =
    if idx < 0 or idx >= len:
      stackTrace(c, tos, pc, formatErrorIndexBound(idx, len-1))
  template ensure(cond: bool) =
    if not cond: stackTrace(c, tos, pc, errInvalidAccess)
  template switchFrame(f: PStackFrame) =
    tos = f
    fp = tos.fp

  template pushCall(callee: PSym; argArea: Address; resDest: Address; envVal: int64) =
    let procInfo = compile(c, callee)
    # tricky: a recursion is also a jump back, so we use the same
    # logic as for loops:
    if procInfo.pc < pc: handleJmpBack()
    if c.callDepth <= 0:
      if allowInfiniteRecursion in c.features:
        c.callDepth = c.config.maxCallDepthVM
      else:
        msgWriteln(c.config, "stack trace: (most recent call last)", {msgNoUnitSep})
        stackTraceAux(c, tos, pc)
        globalError(c.config, c.debug[pc], errCallDepthExceeded % $c.config.maxCallDepthVM)
    dec(c.callDepth)
    let nf = newFrame(c, callee, procInfo.frameSlots, pc, tos)
    let firstParam = max(procInfo.resultSlots, 1)
    if procInfo.paramSlots > 0:
      copyMem(toPtr(nf.fp +! firstParam*SlotSize), toPtr(argArea),
              procInfo.paramSlots * SlotSize)
    if procInfo.envSlot >= 0:
      st[int64](nf.fp +! procInfo.envSlot*SlotSize, envVal)
    nf.resultDest = resDest
    nf.resultSize = procInfo.resultSlots * SlotSize
    if callee.kind == skMacro:
      st[int64](nf.fp, int64(nodeHandle(c.mem, newNodeI(nkEmpty, c.debug[pc]))))
    switchFrame(nf)
    # -1 for the following 'inc pc'
    pc = procInfo.pc-1

  while true:
    let instr = c.code[pc]
    let ra = instr.regA

    when traceCode:
      echo "PC:$pc $opcode $ra $rb $rc" % [
        "pc", $pc, "opcode", alignLeft($c.code[pc].opcode, 15),
        "ra", $ra, "rb", $instr.regB, "rc", $instr.regC]
    if c.config.isVmTrace:
      # unlike nimVMDebug, this doesn't require re-compiling nim and is controlled by user code
      let info = c.debug[pc]
      # other useful variables: c.loopIterations
      echo "$# [$#] $#" % [c.config$info, $instr.opcode, c.config.sourceLine(info)]
    c.profiler.enter(c, tos)
    case instr.opcode
    of opcEof: return (if instr.regX == 1: rAdr(ra) else: slotAddr(ra))
    of opcRet:
      let newPc = c.cleanUpOnReturn(tos)
      # Perform any cleanup action before returning
      if newPc < 0:
        inc(c.callDepth)
        let f = tos
        if f.resultDest != 0 and f.resultSize > 0:
          copyMem(toPtr(f.resultDest), toPtr(f.fp), f.resultSize)
        if f.disposeOnReturn != 0:
          if not disposeRef(c.mem, f.disposeOnReturn, f.disposeAlign):
            stackTrace(c, tos, pc, errInvalidFree)
        pc = f.comesFrom
        if f.next.isNil:
          return f.fp
        c.mem.popFrames(f.mark)
        switchFrame(f.next)
      else:
        savedPC = pc
        savedFrame = tos
        reraising = false
        # The -1 is needed because at the end of the loop we increment `pc`
        pc = newPc - 1
    of opcYldYoid: assert false
    of opcYldVal: assert false

    # ----------------------------- moves
    of opcMov:
      rInt(ra) = rInt(instr.regB)
    of opcMovN:
      moveMem(toPtr(slotAddr(ra)), toPtr(slotAddr(instr.regB)), int(instr.regC) * SlotSize)
    of opcZeroN:
      zeroMem(toPtr(slotAddr(ra)), int(instr.regB) * SlotSize)
    of opcLdImmInt:
      rInt(ra) = int64(instr.regBx - wordExcess)
    of opcLdImm:
      rInt(ra) = cast[int64](wImm())

    # ----------------------------- memory
    of opcAddrSlot:
      rAdr(ra) = slotAddr(instr.regB)
    of opcAddrOff:
      rAdr(ra) = rAdr(instr.regB) +! int(instr.regC)
    of opcAddrOffW:
      rAdr(ra) = rAdr(instr.regB) + Address(wImm())
    of opcLd:
      let k = MemKind(instr.regX)
      let a = rAdr(instr.regB) +! int(instr.regC)
      checkRead(a, memKindSize(k))
      rInt(ra) = vmvalue.loadInt(a, k)
    of opcSt:
      let k = MemKind(instr.regX)
      let a = rAdr(ra) +! int(instr.regB)
      checkWrite(a, memKindSize(k))
      storeInt(a, k, rInt(instr.regC))
    of opcLdSlot:
      rInt(ra) = vmvalue.loadInt(slotAddr(instr.regB), MemKind(instr.regX))
    of opcStSlot:
      let v = rInt(instr.regC)
      storeInt(slotAddr(ra), MemKind(instr.regX), v)
    of opcCopyMem:
      let size = int(wImm())
      let d = rAdr(ra)
      let s = rAdr(instr.regB)
      checkWrite(d, size)
      checkRead(s, size)
      moveMem(toPtr(d), toPtr(s), size)
    of opcZeroMem:
      let size = int(wImm())
      let d = rAdr(ra)
      checkWrite(d, size)
      zeroMem(toPtr(d), size)
    of opcIdxArr:
      let w = wImm()
      let esize = int(w and 0xFFFF_FFFF'u64)
      let len = int64(w shr 32)
      let idx = rInt(instr.regC)
      checkIndex(idx, len)
      rAdr(ra) = rAdr(instr.regB) +! int(idx)*esize
    of opcIdxSeq:
      let w = wImm()
      let esize = int(w and 0xFFFF_FFFF'u64)
      let dataOff = int(w shr 32)
      let s = rAdr(instr.regB)
      checkRead(s, 16)
      let idx = rInt(instr.regC)
      checkIndex(idx, ld[int64](s))
      rAdr(ra) = ld[Address](s +! StrPayloadOffset) +! (dataOff + int(idx)*esize)
    of opcIdxOpenArr:
      let esize = int(wImm())
      let s = rAdr(instr.regB)
      checkRead(s, 16)
      let idx = rInt(instr.regC)
      checkIndex(idx, ld[int64](s +! OpenArrayLenOffset))
      rAdr(ra) = ld[Address](s +! OpenArrayDataOffset) +! int(idx)*esize
    of opcIdxPtr:
      rAdr(ra) = rAdr(instr.regB) +! int(rInt(instr.regC)) * int(wImm())
    of opcSlice:
      let esize = int(wImm())
      let rb = instr.regB
      let data = rAdr(rb)
      let len = rInt(rb+1)
      let lo = rInt(rb+2)
      let hi = rInt(rb+3)
      if lo < 0 or (hi >= lo and hi >= len):
        stackTrace(c, tos, pc, formatErrorIndexBound(if lo < 0: lo else: hi, len-1))
      if hi < lo - 1:
        stackTrace(c, tos, pc, formatErrorIndexBound(hi, len-1))
      rAdr(ra) = data +! int(lo)*esize
      rInt(ra+1) = hi - lo + 1

    # ----------------------------- arithmetic
    of opcAddInt:
      let
        bVal = rInt(instr.regB)
        cVal = rInt(instr.regC)
        sum = bVal +% cVal
      if (sum xor bVal) >= 0 or (sum xor cVal) >= 0:
        rInt(ra) = sum
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcAddImmInt:
      let
        bVal = rInt(instr.regB)
        cVal = int64(instr.regC) - byteExcess
        sum = bVal +% cVal
      if (sum xor bVal) >= 0 or (sum xor cVal) >= 0:
        rInt(ra) = sum
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcSubInt:
      let
        bVal = rInt(instr.regB)
        cVal = rInt(instr.regC)
        diff = bVal -% cVal
      if (diff xor bVal) >= 0 or (diff xor not cVal) >= 0:
        rInt(ra) = diff
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcSubImmInt:
      let
        bVal = rInt(instr.regB)
        cVal = int64(instr.regC) - byteExcess
        diff = bVal -% cVal
      if (diff xor bVal) >= 0 or (diff xor not cVal) >= 0:
        rInt(ra) = diff
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcMulInt:
      let
        bVal = rInt(instr.regB)
        cVal = rInt(instr.regC)
        product = bVal *% cVal
        floatProd = toBiggestFloat(bVal) * toBiggestFloat(cVal)
        resAsFloat = toBiggestFloat(product)
      if resAsFloat == floatProd:
        rInt(ra) = product
      elif 32.0 * abs(resAsFloat - floatProd) <= abs(floatProd):
        rInt(ra) = product
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcDivInt:
      if rInt(instr.regC) == 0: stackTrace(c, tos, pc, errConstantDivisionByZero)
      elif rInt(instr.regC) == -1 and rInt(instr.regB) == low(int64):
        stackTrace(c, tos, pc, errOverOrUnderflow)
      else: rInt(ra) = rInt(instr.regB) div rInt(instr.regC)
    of opcModInt:
      if rInt(instr.regC) == 0: stackTrace(c, tos, pc, errConstantDivisionByZero)
      elif rInt(instr.regC) == -1: rInt(ra) = 0
      else: rInt(ra) = rInt(instr.regB) mod rInt(instr.regC)
    of opcAddFloat:
      rFlt(ra) = rFlt(instr.regB) + rFlt(instr.regC)
    of opcSubFloat:
      rFlt(ra) = rFlt(instr.regB) - rFlt(instr.regC)
    of opcMulFloat:
      rFlt(ra) = rFlt(instr.regB) * rFlt(instr.regC)
    of opcDivFloat:
      rFlt(ra) = rFlt(instr.regB) / rFlt(instr.regC)
    of opcShrInt:
      let b = cast[uint64](rInt(instr.regB))
      let s = cast[uint64](rInt(instr.regC))
      rInt(ra) = cast[int64](b shr s)
    of opcShlInt:
      rInt(ra) = rInt(instr.regB) shl rInt(instr.regC)
    of opcAshrInt:
      rInt(ra) = ashr(rInt(instr.regB), rInt(instr.regC))
    of opcBitandInt:
      rInt(ra) = rInt(instr.regB) and rInt(instr.regC)
    of opcBitorInt:
      rInt(ra) = rInt(instr.regB) or rInt(instr.regC)
    of opcBitxorInt:
      rInt(ra) = rInt(instr.regB) xor rInt(instr.regC)
    of opcAddu:
      rInt(ra) = rInt(instr.regB) +% rInt(instr.regC)
    of opcSubu:
      rInt(ra) = rInt(instr.regB) -% rInt(instr.regC)
    of opcMulu:
      rInt(ra) = rInt(instr.regB) *% rInt(instr.regC)
    of opcDivu:
      if rInt(instr.regC) == 0: stackTrace(c, tos, pc, errConstantDivisionByZero)
      rInt(ra) = rInt(instr.regB) /% rInt(instr.regC)
    of opcModu:
      if rInt(instr.regC) == 0: stackTrace(c, tos, pc, errConstantDivisionByZero)
      rInt(ra) = rInt(instr.regB) %% rInt(instr.regC)
    of opcEqInt:
      rInt(ra) = ord(rInt(instr.regB) == rInt(instr.regC))
    of opcLeInt:
      rInt(ra) = ord(rInt(instr.regB) <= rInt(instr.regC))
    of opcLtInt:
      rInt(ra) = ord(rInt(instr.regB) < rInt(instr.regC))
    of opcEqFloat:
      rInt(ra) = ord(rFlt(instr.regB) == rFlt(instr.regC))
    of opcLeFloat:
      rInt(ra) = ord(rFlt(instr.regB) <= rFlt(instr.regC))
    of opcLtFloat:
      rInt(ra) = ord(rFlt(instr.regB) < rFlt(instr.regC))
    of opcLeu:
      rInt(ra) = ord(rInt(instr.regB) <=% rInt(instr.regC))
    of opcLtu:
      rInt(ra) = ord(rInt(instr.regB) <% rInt(instr.regC))
    of opcXor:
      rInt(ra) = ord(rInt(instr.regB) != rInt(instr.regC))
    of opcNot:
      rInt(ra) = 1 - rInt(instr.regB)
    of opcUnaryMinusInt:
      let val = rInt(instr.regB)
      if val != int64.low:
        rInt(ra) = -val
      else:
        stackTrace(c, tos, pc, errOverOrUnderflow)
    of opcUnaryMinusFloat:
      rFlt(ra) = -rFlt(instr.regB)
    of opcBitnotInt:
      rInt(ra) = not rInt(instr.regB)
    of opcIsNil:
      rInt(ra) = ord(rInt(instr.regB) == 0)

    # ----------------------------- conversions
    of opcCastIntToFloat32:
      rFlt(ra) = float64(cast[float32](cast[int32](rInt(instr.regB))))
    of opcCastIntToFloat64:
      rFlt(ra) = cast[float64](rInt(instr.regB))
    of opcCastFloatToInt32:
      rInt(ra) = int64(cast[int32](float32(rFlt(instr.regB))))
    of opcCastFloatToInt64:
      rInt(ra) = cast[int64](rFlt(instr.regB))
    of opcIntToFloat:
      rFlt(ra) = float64(rInt(instr.regB))
    of opcUIntToFloat:
      rFlt(ra) = float64(cast[uint64](rInt(instr.regB)))
    of opcFloatToInt:
      let f = rFlt(instr.regB)
      let t = getType(c.mem, int64(wImm()))
      if f != f or f >= 9.2233720368547758e18 or f < -9.2233720368547758e18:
        stackTrace(c, tos, pc, errIllegalConvFromXtoY % ["float", typeToString(t)])
      let v = int64(f)
      if t != nil and t.skipTypes(abstractRange).kind in {tyInt..tyInt64, tyEnum, tyChar, tyBool}:
        if toInt128(v) < firstOrd(c.config, t) or toInt128(v) > lastOrd(c.config, t):
          stackTrace(c, tos, pc, errIllegalConvFromXtoY % ["float", typeToString(t)])
      rInt(ra) = v
    of opcFloatToUInt:
      let f = rFlt(instr.regB)
      rInt(ra) = if f < 0: int64(f) else: cast[int64](uint64(f))
    of opcFloatToF32:
      rFlt(ra) = float64(float32(rFlt(instr.regB)))
    of opcNarrowS:
      let rb = instr.regB
      let min = -(1.BiggestInt shl (rb-1))
      let max = (1.BiggestInt shl (rb-1))-1
      if rInt(ra) < min or rInt(ra) > max:
        stackTrace(c, tos, pc, "unhandled exception: value out of range")
    of opcNarrowU:
      let rb = instr.regB
      rInt(ra) = rInt(ra) and ((1'i64 shl rb)-1)
    of opcSignExtend:
      # like opcNarrowS, but no out of range possible
      let imm = 64 - instr.regB
      rInt(ra) = ashr(rInt(ra) shl imm, imm)
    of opcRangeChck:
      let rb = instr.regB
      let rc = instr.regC
      if instr.regX == 1:
        if not (rFlt(rb) <= rFlt(ra) and rFlt(ra) <= rFlt(rc)):
          stackTrace(c, tos, pc, errIllegalConvFromXtoY % [
            $rFlt(ra), "[" & $rFlt(rb) & ".." & $rFlt(rc) & "]"])
      elif instr.regX == 2:
        if not (rInt(rb) <= rInt(ra) and rInt(ra) <= rInt(rc)):
          stackTrace(c, tos, pc, "unhandled exception: value out of range")
      elif not (rInt(rb) <= rInt(ra) and rInt(ra) <= rInt(rc)):
        stackTrace(c, tos, pc, errIllegalConvFromXtoY % [
          $rInt(ra), "[" & $rInt(rb) & ".." & $rInt(rc) & "]"])
    of opcToStr:
      let t = getType(c.mem, int64(wImm()))
      putStr(ra, toStr(c, rInt(instr.regB), t))
    of opcParseFloat:
      let s = str(instr.regB)
      var f = 0.0
      rInt(ra) = parseBiggestFloat(s, f)
      let dst = rAdr(instr.regC)
      checkWrite(dst, 8)
      st[float64](dst, f)

    # ----------------------------- sets
    of opcSetIncl:
      rInt(ra) = rInt(ra) or (1'i64 shl rInt(instr.regB))
    of opcSetExcl:
      rInt(ra) = rInt(ra) and not (1'i64 shl rInt(instr.regB))
    of opcSetInclRange:
      for i in rInt(instr.regB)..rInt(instr.regC):
        rInt(ra) = rInt(ra) or (1'i64 shl i)
    of opcSetContains:
      let bit = rInt(instr.regC)
      rInt(ra) = if bit < 0 or bit >= 64: 0 else: (rInt(instr.regB) shr bit) and 1
    of opcSetCard:
      rInt(ra) = countSetBits(cast[uint64](rInt(instr.regB)))
    of opcSetLe:
      rInt(ra) = ord((rInt(instr.regB) and not rInt(instr.regC)) == 0)
    of opcSetLt:
      let a = rInt(instr.regB)
      let b = rInt(instr.regC)
      rInt(ra) = ord((a and not b) == 0 and a != b)
    of opcBSetIncl, opcBSetExcl:
      let size = int(wImm())
      let s = rAdr(ra)
      let bit = rInt(instr.regB)
      if bit < 0 or bit >= size*8: stackTrace(c, tos, pc, formatErrorIndexBound(bit, size*8-1))
      checkWrite(s, size)
      let p = s +! int(bit shr 3)
      if instr.opcode == opcBSetIncl:
        st[uint8](p, ld[uint8](p) or uint8(1 shl (bit and 7)))
      else:
        st[uint8](p, ld[uint8](p) and not uint8(1 shl (bit and 7)))
    of opcBSetInclRange:
      let size = int(wImm())
      let s = rAdr(ra)
      checkWrite(s, size)
      let lo = rInt(instr.regB)
      let hi = rInt(instr.regC)
      if lo <= hi and (lo < 0 or hi >= size*8): stackTrace(c, tos, pc, formatErrorIndexBound(hi, size*8-1))
      for bit in lo..hi:
        let p = s +! int(bit shr 3)
        st[uint8](p, ld[uint8](p) or uint8(1 shl (bit and 7)))
    of opcBSetContains:
      let size = int(wImm())
      let s = rAdr(instr.regB)
      checkRead(s, size)
      let bit = rInt(instr.regC)
      rInt(ra) = if bit < 0 or bit >= size*8: 0
              else: int64((ld[uint8](s +! int(bit shr 3)) shr (bit and 7)) and 1)
    of opcBSetCard:
      let size = int(wImm())
      let s = rAdr(instr.regB)
      checkRead(s, size)
      var res = 0
      for i in 0..<size: res += countSetBits(ld[uint8](s +! i))
      rInt(ra) = res
    of opcBSetUnion, opcBSetInter, opcBSetDiff, opcBSetXor:
      let size = int(wImm())
      let d = rAdr(ra)
      let a = rAdr(instr.regB)
      let b = rAdr(instr.regC)
      checkWrite(d, size)
      checkRead(a, size)
      checkRead(b, size)
      for i in 0..<size:
        let x = ld[uint8](a +! i)
        let y = ld[uint8](b +! i)
        st[uint8](d +! i, case instr.opcode
          of opcBSetUnion: x or y
          of opcBSetInter: x and y
          of opcBSetDiff: x and not y
          else: x xor y)
    of opcBSetEq, opcBSetLe, opcBSetLt:
      let size = int(wImm())
      let a = rAdr(instr.regB)
      let b = rAdr(instr.regC)
      checkRead(a, size)
      checkRead(b, size)
      var eq = true
      var le = true
      for i in 0..<size:
        let x = ld[uint8](a +! i)
        let y = ld[uint8](b +! i)
        if x != y: eq = false
        if (x and not y) != 0: le = false
      rInt(ra) = ord(case instr.opcode
                  of opcBSetEq: eq
                  of opcBSetLe: le
                  else: le and not eq)

    # ----------------------------- strings
    of opcStrNew:
      let len = int(rInt(instr.regB))
      let s = rAdr(ra)
      checkWrite(s, 16)
      if len < 0: stackTrace(c, tos, pc, formatErrorIndexBound(len, high(int)))
      st[int](s, 0)
      st[Address](s +! StrPayloadOffset, 0)
      ensure strSetLen(c, s, len)
    of opcStrSetLen:
      ensure strSetLen(c, rAdr(ra), int(rInt(instr.regB)))
    of opcStrAddCh:
      var ch = char(rInt(instr.regB) and 0xFF)
      ensure strAdd(c, rAdr(ra), addr ch, 1)
    of opcStrAddStr:
      ensure strAddStr(c, rAdr(ra), rAdr(instr.regB))
    of opcStrAsgn:
      ensure strAsgn(c, rAdr(ra), rAdr(instr.regB))
    of opcStrEq:
      rInt(ra) = ord(strCmp(c, rAdr(instr.regB), rAdr(instr.regC)) == 0)
    of opcStrLe:
      rInt(ra) = ord(strCmp(c, rAdr(instr.regB), rAdr(instr.regC)) <= 0)
    of opcStrLt:
      rInt(ra) = ord(strCmp(c, rAdr(instr.regB), rAdr(instr.regC)) < 0)
    of opcStrToCStr:
      let s = rAdr(instr.regB)
      checkRead(s, 16)
      let p = ld[Address](s +! StrPayloadOffset)
      rAdr(ra) = if p == 0: emptyCString(c) else: p +! PayloadDataOffset
    of opcCStrToStr:
      let s = rAdr(ra)
      checkWrite(s, 16)
      writeString(c, s, readCString(c, rAdr(instr.regB)))
    of opcCStrLen:
      rInt(ra) = readCString(c, rAdr(instr.regB)).len
    of opcCStrEq:
      let a = rAdr(instr.regB)
      let b = rAdr(instr.regC)
      rInt(ra) = ord((a == 0 and b == 0) or
                  (a != 0 and b != 0 and readCString(c, a) == readCString(c, b)))
    of opcStrFromChars:
      let oa = rAdr(instr.regB)
      checkRead(oa, 16)
      let data = ld[Address](oa)
      let len = ld[int](oa +! 8)
      checkRead(data, len)
      var s = newString(len)
      if len > 0: copyMem(addr s[0], toPtr(data), len)
      writeString(c, rAdr(ra), s)

    # ----------------------------- seqs
    of opcSeqNew:
      let w = wImm()
      let esize = int(w and 0xFFFF_FFFF'u64)
      let ealign = int(w shr 32)
      let s = rAdr(ra)
      checkWrite(s, 16)
      let len = int(rInt(instr.regB))
      if len < 0: stackTrace(c, tos, pc, formatErrorIndexBound(len, high(int)))
      st[int](s, 0)
      st[Address](s +! StrPayloadOffset, 0)
      ensure seqSetLen(c, s, len, esize, ealign)
    of opcSeqSetLen:
      let w = wImm()
      let s = rAdr(ra)
      checkWrite(s, 16)
      ensure seqSetLen(c, s, int(rInt(instr.regB)), int(w and 0xFFFF_FFFF'u64), int(w shr 32))
    of opcSeqGrowOne:
      let w = wImm()
      let esize = int(w and 0xFFFF_FFFF'u64)
      let ealign = int(w shr 32)
      let s = rAdr(instr.regB)
      checkWrite(s, 16)
      let len = ld[int](s)
      ensure seqSetLen(c, s, len+1, esize, ealign)
      rAdr(ra) = ld[Address](s +! StrPayloadOffset) +! (payloadDataOffset(ealign) + len*esize)
    of opcSeqData:
      let s = rAdr(instr.regB)
      checkRead(s, 16)
      let p = ld[Address](s +! StrPayloadOffset)
      rAdr(ra) = if p == 0: 0 else: p +! int(wImm())
    of opcPayloadFree:
      when defined(nimVmHeapDebug):
        curInfo = c.config $ c.debug[pc]
        var ff = tos
        var depth = 0
        while ff != nil and depth < 4:
          curInfo.add " <- " & c.config $ c.debug[ff.comesFrom] & " " & (if ff.prc != nil: ff.prc.name.s else: "")
          ff = ff.next
          inc depth
      if not freePayload(c, rAdr(ra)):
        when defined(nimVmHeapDebug):
          let pp = ld[Address](rAdr(ra) +! StrPayloadOffset)
          if freedAt.hasKey(pp): echo "FIRST FREED AT ", freedAt[pp], "\nNOW AT ", curInfo
        let s = rAdr(ra)
        let p = if canRead(c.mem, s, 16): ld[Address](s +! StrPayloadOffset) else: 0
        stackTrace(c, tos, pc, errInvalidFree & (if isFreedBlock(c.mem, p): " (double free)" else: "") &
          " " & $cast[int](p) & " in region kind " &
          (let r = findRegion(c.mem, p); if r < 0: "none" else: "?"))
    of opcSamePayload:
      let a = rAdr(instr.regB)
      let b = rAdr(instr.regC)
      checkRead(a, 16)
      checkRead(b, 16)
      rInt(ra) = ord(ld[Address](a +! StrPayloadOffset) == ld[Address](b +! StrPayloadOffset))
    of opcSeqCopyPayload:
      let d = rAdr(ra)
      let s = rAdr(instr.regB)
      let esize = int(rInt(instr.regC))
      let ealign = int(rInt(instr.regC+1))
      checkWrite(d, 16)
      checkRead(s, 16)
      let len = ld[int](s)
      st[int](d, min(ld[int](d), len))
      ensure seqSetLen(c, d, len, esize, ealign)
      ensure reserve(c, d, len, esize, ealign, false)
      if len > 0:
        let off = payloadDataOffset(ealign)
        let sp = ld[Address](s +! StrPayloadOffset)
        checkRead(sp, off + len*esize)
        copyMem(toPtr(ld[Address](d +! StrPayloadOffset) +! off), toPtr(sp +! off), len*esize)

    of opcUnshare:
      ensure unshare(c, rAdr(ra), getType(c.mem, int64(wImm())))
    of opcMakeUnique:
      let s = rAdr(ra)
      checkWrite(s, 16)
      ensure reserve(c, s, ld[int](s), 1, 1, true)

    # ----------------------------- refs and objects
    of opcNewRef:
      let w = wImm()
      rAdr(ra) = newRef(c.mem, int(w and 0xFFFF_FFFF'u64), int(w shr 32))
    of opcIncRef:
      let p = rAdr(ra)
      if p != 0:
        checkWrite(p -! RefHeaderSize, RefHeaderSize)
        incRef(p)
    of opcDecRefIsLast:
      let p = rAdr(instr.regB)
      if p == 0:
        rInt(ra) = 0
      else:
        if not canRead(c.mem, p -! RefHeaderSize, RefHeaderSize):
          stackTrace(c, tos, pc, memErrorMsg(c, p, false))
        rInt(ra) = ord(decRefIsLast(p))
    of opcDisposeRef:
      if not disposeRef(c.mem, rAdr(ra), int(rInt(instr.regB))):
        stackTrace(c, tos, pc, errInvalidFree)
    of opcDynDestructor:
      let p = rAdr(ra)
      if p != 0:
        let t = dynamicType(c, p)
        if t == nil: stackTrace(c, tos, pc, errInvalidAccess)
        let align = vmAlignOf(c.layouts, c.config, t)
        let op = getAttachedOp(c.graph, t, attachedDestructor)
        if op == nil or isTrivial(op):
          if not disposeRef(c.mem, p, align): stackTrace(c, tos, pc, errInvalidFree)
        else:
          # call the destructor, the frame frees the cell when it returns:
          let pt = op.typ.firstParamType
          var arg = default(array[1, int64])
          var argAddr = toAddr(addr arg[0])
          var big: seq[int64] = @[]
          if pt.skipTypes(abstractInst).kind in {tyVar, tyLent}:
            arg[0] = cast[int64](p)
          else:
            let size = vmSizeOf(c.layouts, c.config, t)
            big = newSeq[int64](slotsFor(size))
            copyMem(addr big[0], toPtr(p), size)
            argAddr = toAddr(addr big[0])
          pushCall(op, argAddr, 0, 0)
          tos.disposeOnReturn = p
          tos.disposeAlign = align
    of opcInitObj:
      initObj(c, rAdr(ra), getType(c.mem, int64(wImm())))
    of opcOf:
      let p = rAdr(instr.regB)
      let target = getType(c.mem, int64(wImm()))
      let t = dynamicType(c, p)
      rInt(ra) = ord(t != nil and target != nil and inheritanceDiff(t, target) <= 0)
    of opcIs:
      let t1 = nodeNN(instr.regB).typ.skipTypes({tyTypeDesc})
      let t2 = getType(c.mem, int64(wImm()))
      # XXX: This should use the standard isOpImpl
      let match = if t2.kind == tyUserTypeClass: true
                  else: sameType(t1, t2)
      rInt(ra) = ord(match)

    # ----------------------------- raw memory
    of opcAlloc:
      let size = rInt(instr.regB)
      if size < 0: stackTrace(c, tos, pc, "invalid size for alloc: " & $size)
      rAdr(ra) = heapAlloc(c.mem, int(size))
    of opcDealloc:
      if not heapDealloc(c.mem, rAdr(ra)): stackTrace(c, tos, pc, errInvalidFree)
    of opcRealloc:
      let p = rAdr(instr.regB)
      if p != 0 and not isHeapBlock(c.mem, p): stackTrace(c, tos, pc, errInvalidFree)
      rAdr(ra) = heapRealloc(c.mem, p, int(rInt(instr.regC)))
    of opcMemMove:
      let size = int(rInt(instr.regC))
      if size > 0:
        checkWrite(rAdr(ra), size)
        checkRead(rAdr(instr.regB), size)
        moveMem(toPtr(rAdr(ra)), toPtr(rAdr(instr.regB)), size)
    of opcMemZero:
      let size = int(rInt(instr.regB))
      if size > 0:
        checkWrite(rAdr(ra), size)
        zeroMem(toPtr(rAdr(ra)), size)
    of opcMemCmp:
      let rb = instr.regB
      let size = int(rInt(rb+2))
      if size > 0:
        checkRead(rAdr(rb), size)
        checkRead(rAdr(rb+1), size)
        rInt(ra) = cmpMem(toPtr(rAdr(rb)), toPtr(rAdr(rb+1)), size)
      else:
        rInt(ra) = 0

    of opcRepr:
      let t = getType(c.mem, int64(wImm()))
      let v = regToNode(c, rAdr(instr.regB), t, c.debug[pc])
      putStr(ra, renderTree(v, {renderNoComments, renderDocComments, renderNonExportedFields}))
    of opcQuit:
      if c.mode in {emRepl, emStaticExpr, emStaticStmt}:
        message(c.config, c.debug[pc], hintQuitCalled)
        msgQuit(int8(rInt(ra)))
      else:
        return 0
    of opcInvalidField:
      let msg = str(ra)
      let disc = rInt(instr.regB)
      let msg2 = formatFieldDefect(msg, $disc)
      stackTrace(c, tos, pc, msg2)

    # ----------------------------- calls
    of opcIndCall:
      let rb = instr.regB
      let fnAddr = rAdr(rb)
      let prc = getProc(c.mem, fnAddr)
      if prc == nil:
        if fnAddr == 0: stackTrace(c, tos, pc, "attempt to call nil closure")
        else: stackTrace(c, tos, pc, "attempt to call an invalid proc address")
      if prc.offset < -1:
        # it's a callback:
        var shape = callShapeOf(c, prc)
        c.callbacks[-prc.offset-2](
          VmArgs(ctxp: cast[pointer](c), args: slotAddr(rb + 2 + shape.resultSlots),
                 res: slotAddr(rb + 2), shape: addr shape,
                 currentException: c.currentExceptionA,
                 currentLineInfo: c.debug[pc]))
      elif importcCond(c, prc):
        globalError(c.config, c.debug[pc], "cannot evaluate importc'ed proc at compile time: " &
                    prc.name.s)
      elif prc.kind == skTemplate:
        # for 'getAst' support we need to support template expansion here:
        let genSymOwner = if tos.next != nil and tos.next.prc != nil:
                            tos.next.prc
                          else:
                            c.module
        let shape = callShapeOf(c, prc)
        let args = slotAddr(rb + 2 + shape.resultSlots)
        var macroCall = newNodeI(nkCall, c.debug[pc])
        macroCall.add(newSymNode(prc))
        for i in 0..<shape.paramTypes.len:
          let pt = shape.paramTypes[i]
          let node = regToNode(c, args +! shape.paramOffsets[i], pt, c.debug[pc])
          node.info = c.debug[pc]
          let declared = prc.typ[i+FirstParamAt]
          if declared.kind notin {tyTyped, tyUntyped, tyTypeDesc} and
              not isNimNodeType(declared.skipTypes({tyStatic})):
            var producedClosure = false
            node.annotateType(declared.skipTypes({tyStatic}), c.config, producedClosure)
          macroCall.add(node)
        var a = evalTemplate(macroCall, prc, genSymOwner, c.config, c.cache, c.templInstCounter, c.idgen)
        if a.kind == nkStmtList and a.len == 1: a = a[0]
        a.recSetFlagIsRef
        rInt(rb+2) = int64(nodeHandle(c.mem, a))
      else:
        let info = compile(c, prc)
        pushCall(prc, slotAddr(rb + 2 + info.resultSlots), slotAddr(rb + 2),
                 rInt(rb+1))
    of opcEcho:
      let count = int(instr.regB)
      var outp = ""
      for i in 0..<count:
        outp.add readString(c, slotAddr(ra + 2*i))
      msgWriteln(c.config, outp, {msgStdout, msgNoUnitSep})

    # ----------------------------- control flow
    of opcTJmp:
      # jump Bx if A != 0
      let rbx = instr.regBx - wordExcess - 1 # -1 for the following 'inc pc'
      if rInt(ra) != 0:
        inc pc, rbx
    of opcFJmp:
      # jump Bx if A == 0
      let rbx = instr.regBx - wordExcess - 1 # -1 for the following 'inc pc'
      if rInt(ra) == 0:
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
      let table {.cursor.} = c.branchTables[instr.regBx-wordExcess]
      let v = rInt(ra)
      var cond = false
      for (lo, hi) in table:
        if v >= lo and v <= hi:
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
      # This opcode is never executed, it only holds information for the
      # exception handling routines.
      raiseAssert "unreachable"
    of opcFinally:
      # Pop the last safepoint introduced by a opcTry. This opcode is only
      # executed _iff_ no exception was raised in the body of the `try`
      # statement hence the need to pop the safepoint here.
      doAssert(savedPC < 0)
      tos.popSafePoint()
    of opcFinallyEnd:
      # The control flow may not resume at the next instruction since we may be
      # raising an exception or performing a cleanup.
      if savedPC >= 0:
        pc = savedPC - 1
        savedPC = -1
        if tos != savedFrame:
          c.mem.popFrames(savedFrame.top)
          switchFrame(savedFrame)
    of opcRaise:
      let raised =
        # after a `finally` section the register may have been reused:
        if reraising: c.currentExceptionA
        # Empty `raise` statement - reraise current exception
        elif rInt(ra) == 0: c.currentExceptionA
        else: rAdr(ra)
      reraising = false
      if raised == 0:
        stackTrace(c, tos, pc, "no exception to reraise")
      if raised != c.currentExceptionA:
        # the VM holds on to the current exception:
        incRef(raised)
      c.currentExceptionA = raised
      setExceptionName(c, raised)
      c.exceptionInstr = pc

      var frame = tos
      var jumpTo = findExceptionHandler(c, frame, raised)
      while jumpTo.why == ExceptionGotoUnhandled and not frame.next.isNil:
        frame = frame.next
        jumpTo = findExceptionHandler(c, frame, raised)

      case jumpTo.why
      of ExceptionGotoHandler:
        # Jump to the handler, do nothing when the `finally` block ends.
        savedPC = -1
        pc = jumpTo.where - 1
        if tos != frame:
          c.mem.popFrames(frame.top)
          switchFrame(frame)
      of ExceptionGotoFinally:
        # Jump to the `finally` block first then re-jump here to continue the
        # traversal of the exception chain
        savedPC = pc
        savedFrame = tos
        reraising = true
        pc = jumpTo.where - 1
        if tos != frame:
          switchFrame(frame)
      of ExceptionGotoUnhandled:
        # Nobody handled this exception, error out. (With `nim check`
        # execution continues after the `raise`, like it always did.)
        bailOut(c, tos)
    of opcTypeLit:
      setNode(ra, newNodeIT(nkType, c.debug[pc], getType(c.mem, instr.regBx - wordExcess)))

    # ----------------------------- NimNode
    of opcToNode:
      let t = getType(c.mem, int64(wImm()))
      var v: PNode
      case memKind(c.config, t)
      of SignedMemKinds, UnsignedMemKinds:
        # like the old VM: an untyped integer literal (also for bools, chars
        # and enums)
        v = newIntNode(nkIntLit, rInt(instr.regB))
      of FloatMemKinds:
        v = newFloatNode(nkFloatLit, rFlt(instr.regB))
      else:
        v = regToNode(c, slotAddr(instr.regB), t, c.debug[pc])
      if v.kind == nkTupleConstr and v.len == 2 and v[1].kind == nkNilLit and
          t.skipTypes(abstractInst+{tyStatic}).kind == tyProc:
        # a closure without an environment: as an AST it is its symbol
        v = v[0]
      when defined(nimVmListing):
        echo "TONODE ", typeToString(t), " ", t.kind, " value ", rInt(instr.regB), " -> ", v.kind
      rInt(ra) = int64(nodeHandle(c.mem, v))
    of opcNLen:
      rInt(ra) = nodeNN(instr.regB).safeLen
    of opcGetImpl:
      var a = node(instr.regB)
      if a == nil: stackTrace(c, tos, pc, errNilAccess)
      if a.kind == nkVarTy: a = a[0]
      if a.kind == nkSym:
        # a macro observed this symbol's implementation: NeedsImpl edge to
        # its home module under IC.
        recordIcImplDep(c.graph, a.sym)
        if a.sym.ast.isNil:
          setNode(ra, newNode(nkNilLit))
        else:
          let tree = copyTree(a.sym.ast)
          # A NIF-loaded routine's `ast[paramsPos]` is an `nkEmpty` placeholder:
          # ast2nif strips the formal params (recoverable from `typ.n`, see
          # writeNode's `skipParams`). A macro that reads `fn.getImpl[paramsPos]`
          # — e.g. taskpools `spawn` reads the return type via `getImpl[3][0]` —
          # needs them, so reconstruct a read-only formalParams from the proc
          # type. The synthesized type-expression nodes carry the resolved
          # `PType`, which is all a macro can query for a loaded routine.
          if tree.kind in {nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef,
                           nkConverterDef, nkMacroDef, nkTemplateDef, nkLambda, nkDo} and
              tree.safeLen > paramsPos and tree[paramsPos].kind == nkEmpty and
              a.sym.typ != nil and a.sym.typ.n != nil and
              a.sym.typ.n.kind == nkFormalParams:
            let t = a.sym.typ
            let fp = newNodeI(nkFormalParams, a.sym.info)
            let rt = t.returnType
            # `opMapTypeInstToAst` (inst=true) reproduces a source-like type
            # declaration — crucially it renders an array's range bound as
            # `range 0..N` (the `inst=false` form emits `range[0, N]`, which
            # re-sems to "'range' expects one type parameter").
            fp.add(if rt != nil: opMapTypeInstToAst(c.cache, rt, a.sym.info, c.idgen)
                   else: newNodeI(nkEmpty, a.sym.info))
            for i in 1 ..< t.n.len:
              if t.n[i].kind == nkSym:
                let p = t.n[i].sym
                let def = newNodeI(nkIdentDefs, p.info)
                # the param SYMBOL, as in a from-source typed impl: macros
                # query it (`getTypeInst`, `getType`) like any typed param
                def.add newSymNode(p, p.info)
                def.add opMapTypeInstToAst(c.cache, p.typ, p.info, c.idgen)
                def.add newNodeI(nkEmpty, p.info)
                fp.add def
            tree[paramsPos] = fp
          tree.flags.incl nfIsRef
          setNode(ra, tree)
      else:
        stackTrace(c, tos, pc, "node is not a symbol")
    of opcGetImplTransf:
      let a = node(instr.regB)
      if a != nil and a.kind == nkSym:
        recordIcImplDep(c.graph, a.sym)
        let n =
          if a.sym.ast.isNil:
            newNode(nkNilLit)
          else:
            let ast = a.sym.ast.shallowCopy
            for i in 0..<a.sym.ast.len:
              ast[i] = a.sym.ast[i]
            ast[bodyPos] = transformBody(c.graph, c.idgen, a.sym, {useCache, force})
            ast.copyTree()
        setNode(ra, n)
      else:
        stackTrace(c, tos, pc, "node is not a symbol")
    of opcSymOwner:
      let a = node(instr.regB)
      if a != nil and a.kind == nkSym:
        let n = if a.sym.owner.isNil: newNode(nkNilLit)
                else: newSymNode(a.sym.skipGenericOwner)
        n.flags.incl nfIsRef
        setNode(ra, n)
      else:
        stackTrace(c, tos, pc, "node is not a symbol")
    of opcSymIsInstantiationOf:
      let a = node(instr.regB)
      let b = node(instr.regC)
      if a != nil and b != nil and a.kind == nkSym and a.sym.kind in skProcKinds and
         b.kind == nkSym and b.sym.kind in skProcKinds:
        rInt(ra) =
          if sfFromGeneric in a.sym.flags and a.sym.instantiatedFrom == b.sym: 1
          else: 0
      else:
        stackTrace(c, tos, pc, "node is not a proc symbol")
    of opcNBindSym:
      let n = copyTree(node(instr.regB))
      n.flags.incl nfIsRef
      setNode(ra, n)
    of opcNDynBindSym:
      var shape = c.callShapes[int(wImm())]
      c.callbacks[shape.callbackIdx](
        VmArgs(ctxp: cast[pointer](c), args: slotAddr(instr.regB),
               res: slotAddr(ra), shape: addr shape,
               currentException: c.currentExceptionA,
               currentLineInfo: c.debug[pc]))
      let n = node(ra)
      if n != nil: n.flags.incl nfIsRef
    of opcNChild:
      let idx = int(rInt(instr.regC))
      let src = node(instr.regB)
      if src == nil: stackTrace(c, tos, pc, errNilAccess)
      if src.kind in {nkEmpty..nkNilLit}:
        stackTrace(c, tos, pc, "cannot get child of node kind: n" & $src.kind)
      elif idx >=% src.len:
        stackTrace(c, tos, pc, formatErrorIndexBound(idx, src.len-1))
      else:
        setNode(ra, src[idx])
    of opcNSetChild:
      let idx = int(rInt(instr.regB))
      var dest = node(ra)
      if dest == nil: stackTrace(c, tos, pc, errNilAccess)
      if nfSem in dest.flags and allowSemcheckedAstModification notin c.config.legacyFeatures:
        stackTrace(c, tos, pc, "typechecked nodes may not be modified")
      elif dest.kind in {nkEmpty..nkNilLit}:
        stackTrace(c, tos, pc, "cannot set child of node kind: n" & $dest.kind)
      elif idx >=% dest.len:
        stackTrace(c, tos, pc, formatErrorIndexBound(idx, dest.len-1))
      else:
        dest[idx] = node(instr.regC)
    of opcNAdd:
      var u = node(instr.regB)
      if u == nil: stackTrace(c, tos, pc, errNilAccess)
      if nfSem in u.flags and allowSemcheckedAstModification notin c.config.legacyFeatures:
        stackTrace(c, tos, pc, "typechecked nodes may not be modified")
      elif u.kind in {nkEmpty..nkNilLit}:
        stackTrace(c, tos, pc, "cannot add to node kind: n" & $u.kind)
      else:
        u.add(node(instr.regC))
      setNode(ra, u)
    of opcNAddMultiple:
      var u = node(instr.regB)
      if u == nil: stackTrace(c, tos, pc, errNilAccess)
      let oa = rAdr(instr.regC)
      checkRead(oa, 16)
      let data = ld[Address](oa)
      let len = ld[int](oa +! 8)
      checkRead(data, len*8)
      if nfSem in u.flags and allowSemcheckedAstModification notin c.config.legacyFeatures:
        stackTrace(c, tos, pc, "typechecked nodes may not be modified")
      elif u.kind in {nkEmpty..nkNilLit}:
        stackTrace(c, tos, pc, "cannot add to node kind: n" & $u.kind)
      else:
        for i in 0..<len: u.add(getNode(c.mem, ld[int64](data +! i*8)))
      setNode(ra, u)
    of opcNKind:
      let n = node(instr.regB)
      if n == nil: stackTrace(c, tos, pc, errNilAccess)
      rInt(ra) = ord(n.kind)
      c.comesFromHeuristic = n.info
    of opcNSymKind:
      let a = nodeNN(instr.regB)
      if a.kind == nkSym:
        rInt(ra) = ord(a.sym.kind)
      else:
        stackTrace(c, tos, pc, "node is not a symbol")
      c.comesFromHeuristic = a.info
    of opcNIntVal:
      let a = node(instr.regB)
      if a == nil: stackTrace(c, tos, pc, errNilAccess)
      if a.kind in {nkCharLit..nkUInt64Lit}:
        rInt(ra) = a.intVal
      elif a.kind == nkSym and a.sym.kind == skEnumField:
        rInt(ra) = a.sym.position
      else:
        stackTrace(c, tos, pc, errFieldXNotFound & "intVal")
    of opcNFloatVal:
      let a = node(instr.regB)
      if a == nil: stackTrace(c, tos, pc, errNilAccess)
      case a.kind
      of nkFloatLit..nkFloat64Lit: rFlt(ra) = a.floatVal
      else: stackTrace(c, tos, pc, errFieldXNotFound & "floatVal")
    of opcNSymbol:
      let a = node(instr.regB)
      if a != nil and a.kind == nkSym:
        setNode(ra, copyNode(a))
      else:
        stackTrace(c, tos, pc, errFieldXNotFound & "symbol")
    of opcNIdent:
      let a = node(instr.regB)
      if a != nil and a.kind == nkIdent:
        setNode(ra, copyNode(a))
      else:
        stackTrace(c, tos, pc, errFieldXNotFound & "ident")
    of opcNodeId:
      when defined(useNodeIds):
        rInt(ra) = nodeNN(instr.regB).id
      else:
        rInt(ra) = -1
    of opcNGetType:
      let n = node(instr.regB)
      let t = if n == nil: nil
              elif n.typ != nil: n.typ
              elif n.kind == nkSym: n.sym.typ
              else: nil
      case instr.regC
      of 0:
        # getType opcode:
        if t == nil: stackTrace(c, tos, pc, "node has no type")
        setNode(ra, opMapTypeToAst(c.cache, t, c.debug[pc], c.idgen))
      of 1:
        # typeKind opcode:
        rInt(ra) = if t == nil: 0 else: ord(t.kind)
      of 2:
        # getTypeInst opcode:
        if t == nil: stackTrace(c, tos, pc, "node has no type")
        setNode(ra, opMapTypeInstToAst(c.cache, t, c.debug[pc], c.idgen))
      of 3:
        # getTypeImpl opcode:
        if t == nil: stackTrace(c, tos, pc, "node has no type")
        setNode(ra, opMapTypeImplToAst(c.cache, t, c.debug[pc], c.idgen))
      else:
        # getTypeInstSkipAlias opcode:
        if t == nil: stackTrace(c, tos, pc, "node has no type")
        setNode(ra, opMapTypeInstToAst(c.cache, t, c.debug[pc], c.idgen, skipAlias = true))
    of opcNGetSize:
      let n = node(instr.regB)
      let imm = int(instr.regC) - byteExcess
      if n == nil: stackTrace(c, tos, pc, errNilAccess)
      case imm
      of 0: # size
        if n.typ == nil:
          stackTrace(c, tos, pc, "node has no type")
        else:
          rInt(ra) = getSize(c.config, n.typ)
      of 1: # align
        if n.typ == nil:
          stackTrace(c, tos, pc, "node has no type")
        else:
          rInt(ra) = getAlign(c.config, n.typ)
      else: # offset
        if n.kind != nkSym:
          stackTrace(c, tos, pc, "node is not a symbol")
        elif n.sym.kind != skField:
          stackTrace(c, tos, pc, "symbol is not a field (nskField)")
        else:
          rInt(ra) = n.sym.offset
    of opcNStrVal:
      let a = node(instr.regB)
      if a == nil: stackTrace(c, tos, pc, errNilAccess)
      case a.kind
      of nkStrLit..nkTripleStrLit:
        putStr(ra, a.strVal)
      of nkCommentStmt:
        putStr(ra, a.comment)
      of nkIdent:
        putStr(ra, a.ident.s)
      of nkSym:
        putStr(ra, a.sym.name.s)
      else:
        stackTrace(c, tos, pc, errFieldXNotFound & "strVal")
    of opcNSigHash:
      let n = node(instr.regB)
      if n == nil or n.kind != nkSym:
        stackTrace(c, tos, pc, "node is not a symbol")
      else:
        let shSym = n.sym
        # When `signatureHash` is applied to a type (e.g. a `T: typedesc`/generic
        # param), hash the *type* it denotes, not the parameter symbol. Hashing the
        # symbol routes through `hashNonProc`, which mixes in `s.disamb` — a
        # per-module instantiation counter. Under incremental compilation the
        # registering module and a consuming module instantiate the surrounding
        # generic separately, get different `disamb`s, and produce different
        # hashes for the same type (nim-serialization's auto-serialization lookup
        # missed because of this). Hashing the underlying type via `hashType` is
        # type-identity based and stable across the NIF boundary.
        let shTyp = shSym.typ
        if shTyp != nil and shTyp.kind == tyTypeDesc and shTyp.hasElementType:
          putStr(ra, $hashType(shTyp.elementType, c.config))
        else:
          putStr(ra, $sigHash(shSym, c.config))
    of opcSlurp:
      putStr(ra, opSlurp(str(instr.regB), c.debug[pc], c.module, c.config))
    of opcGorge:
      let rb = instr.regB
      if defined(nimsuggest) or c.config.cmd == cmdCheck:
        discard "don't run staticExec for 'nim suggest'"
        putStr(ra, "")
      else:
        when defined(nimcore):
          putStr(ra, opGorge(str(rb), str(rb+1), str(rb+2), c.debug[pc], c.config)[0])
        else:
          putStr(ra, "")
          globalError(c.config, c.debug[pc], "VM is not built with 'gorge' support")
    of opcNError, opcNWarning, opcNHint:
      let msg = str(ra)
      let b = node(instr.regB)
      let info = if b == nil or b.kind == nkNilLit: c.debug[pc] else: b.info
      if instr.opcode == opcNError:
        stackTrace(c, tos, pc, msg, info)
      elif instr.opcode == opcNWarning:
        message(c.config, info, warnUser, msg)
      elif instr.opcode == opcNHint:
        message(c.config, info, hintUser, msg)
    of opcParseExprToAst:
      var error: string = ""
      let filename = if instr.regX == 1: str(instr.regC) else: ""
      let ast = parseString(str(instr.regB), c.cache, c.config,
                            filename, 0,
                            proc (conf: ConfigRef; info: TLineInfo; msg: TMsgKind; arg: string) =
                              if error.len == 0 and msg <= errMax:
                                error = formatMsg(conf, info, msg, arg))
      setNode(ra, newNode(nkEmpty))
      if error.len > 0:
        c.errorFlag = error
      elif ast.len != 1:
        c.errorFlag = formatMsg(c.config, c.debug[pc], errGenerated,
          "expected expression, but got multiple statements")
      else:
        setNode(ra, ast[0])
    of opcParseStmtToAst:
      var error: string = ""
      let filename = if instr.regX == 1: str(instr.regC) else: ""
      let ast = parseString(str(instr.regB), c.cache, c.config,
                            filename, 0,
                            proc (conf: ConfigRef; info: TLineInfo; msg: TMsgKind; arg: string) =
                              if error.len == 0 and msg <= errMax:
                                error = formatMsg(conf, info, msg, arg))
      if error.len > 0:
        c.errorFlag = error
        setNode(ra, newNode(nkEmpty))
      else:
        setNode(ra, ast)
    of opcQueryErrorFlag:
      putStr(ra, c.errorFlag)
      c.errorFlag.setLen 0
    of opcCallSite:
      if c.callsite != nil: setNode(ra, c.callsite)
      else: stackTrace(c, tos, pc, errFieldXNotFound & "callsite")
    of opcNGetLineInfo:
      let n = node(instr.regB)
      if n == nil: stackTrace(c, tos, pc, errNilAccess)
      let imm = int(instr.regC) - byteExcess
      case imm
      of 0: # getFile
        putStr(ra, toFullPath(c.config, n.info))
      of 1: # getLine
        rInt(ra) = n.info.line.int
      of 2: # getColumn
        rInt(ra) = n.info.col.int
      else:
        internalAssert c.config, false
    of opcNCopyLineInfo:
      nodeNN(ra).info = nodeNN(instr.regB).info
    of opcNSetLineInfoLine:
      nodeNN(ra).info.line = rInt(instr.regB).uint16
    of opcNSetLineInfoColumn:
      nodeNN(ra).info.col = rInt(instr.regB).int16
    of opcNSetLineInfoFile:
      nodeNN(ra).info.fileIndex =
        fileInfoIdx(c.config, RelativeFile str(instr.regB))
    of opcEqIdent:
      # the arguments are either NimNodes or strings:
      proc identStr(c: PCtx; n: PNode): string =
        var n = n
        if n == nil: return ""
        # Skipping both, `nkPostfix` and `nkAccQuoted` for both
        # arguments.  `nkPostfix` exists only to tag exported symbols
        # and therefor it can be safely skipped. Nim has no postfix
        # operator. `nkAccQuoted` is used to quote an identifier that
        # wouldn't be allowed to use in an unquoted context.
        if n.kind == nkPostfix: n = n[1]
        if n.kind == nkAccQuoted: n = n[0]
        case n.kind
        of nkStrLit..nkTripleStrLit: n.strVal
        of nkIdent: n.ident.s
        of nkSym: n.sym.name.s
        of nkOpenSymChoice, nkClosedSymChoice, nkOpenSym: n[0].sym.name.s
        else: ""
      let x = instr.regX
      let a = if (x and 1) != 0: str(instr.regB) else: identStr(c, node(instr.regB))
      let b = if (x and 2) != 0: str(instr.regC) else: identStr(c, node(instr.regC))
      rInt(ra) =
        if a.len > 0 and b.len > 0:
          ord(idents.cmpIgnoreStyle(cstring(a), cstring(b), high(int)) == 0)
        else:
          0
    of opcStrToIdent:
      let n = newNodeI(nkIdent, c.debug[pc])
      n.ident = getIdent(c.cache, str(instr.regB))
      n.flags.incl nfIsRef
      setNode(ra, n)
    of opcEqNimNode:
      let a = node(instr.regB)
      let b = node(instr.regC)
      # like the old VM, a nil NimNode equals a `nil` literal node:
      template isNilNode(x: PNode): bool = x == nil or x.kind == nkNilLit
      rInt(ra) = if a == nil or b == nil: ord(isNilNode(a) and isNilNode(b))
                 else: ord(exprStructuralEquivalent(a, b, strictSymEquality=true))
    of opcSameNodeType:
      let a = node(instr.regB)
      let b = node(instr.regC)
      rInt(ra) = ord(a != nil and b != nil and
                  a.typ.sameTypeOrNil(b.typ, {ExactTypeDescValues, ExactGenericParams}))
      # The types should exactly match which is why we pass `{ExactTypeDescValues..ExactGcSafety}`.
    of opcNSetIntVal:
      var dest = node(ra)
      if dest == nil: stackTrace(c, tos, pc, errNilAccess)
      if dest.kind in {nkCharLit..nkUInt64Lit}:
        dest.intVal = rInt(instr.regB)
      elif dest.kind == nkSym and dest.sym.kind == skEnumField:
        stackTrace(c, tos, pc, "`intVal` cannot be changed for an enum symbol.")
      else:
        stackTrace(c, tos, pc, errFieldXNotFound & "intVal")
    of opcNSetFloatVal:
      var dest = node(ra)
      if dest == nil: stackTrace(c, tos, pc, errNilAccess)
      if dest.kind in {nkFloatLit..nkFloat64Lit}:
        dest.floatVal = rFlt(instr.regB)
      else:
        stackTrace(c, tos, pc, errFieldXNotFound & "floatVal")
    of opcNSetSymbol:
      var dest = node(ra)
      let b = node(instr.regB)
      if dest != nil and b != nil and dest.kind == nkSym and b.kind == nkSym:
        dest.sym = b.sym
      else:
        stackTrace(c, tos, pc, errFieldXNotFound & "symbol")
    of opcNSetIdent:
      var dest = node(ra)
      let b = node(instr.regB)
      if dest != nil and b != nil and dest.kind == nkIdent and b.kind == nkIdent:
        dest.ident = b.ident
      else:
        stackTrace(c, tos, pc, errFieldXNotFound & "ident")
    of opcNSetStrVal:
      var dest = node(ra)
      if dest == nil: stackTrace(c, tos, pc, errNilAccess)
      if dest.kind in {nkStrLit..nkTripleStrLit}:
        dest.strVal = str(instr.regB)
      elif dest.kind == nkCommentStmt:
        dest.comment = str(instr.regB)
      else:
        stackTrace(c, tos, pc, errFieldXNotFound & "strVal")
    of opcNNewNimNode:
      var k = rInt(instr.regB)
      if k < 0 or k > ord(high(TNodeKind)):
        internalError(c.config, c.debug[pc],
          "request to create a NimNode of invalid kind")
      let cc = node(instr.regC)

      let x = newNodeI(TNodeKind(int(k)),
        if cc != nil and cc.kind != nkNilLit:
          cc.info
        elif c.comesFromHeuristic.line != 0'u16:
          c.comesFromHeuristic
        elif c.callsite != nil and c.callsite.safeLen > 1:
          c.callsite[1].info
        else:
          c.debug[pc])
      x.flags.incl nfIsRef
      # prevent crashes in the compiler resulting from wrong macros:
      if x.kind == nkIdent: x.ident = c.cache.emptyIdent
      setNode(ra, x)
    of opcNCopyNimNode:
      setNode(ra, copyNode(nodeNN(instr.regB)))
    of opcNCopyNimTree:
      setNode(ra, copyTree(nodeNN(instr.regB)))
    of opcNDel:
      let bb = int(rInt(instr.regB))
      let n = node(ra)
      if n == nil: stackTrace(c, tos, pc, errNilAccess)
      for i in 0..<int(rInt(instr.regC)):
        delSon(n, bb)
    of opcGenSym:
      let k = rInt(instr.regB)
      let s = str(instr.regC)
      let name = if s.len == 0: ":tmp" else: s
      if k < 0 or k > ord(high(TSymKind)):
        internalError(c.config, c.debug[pc], "request to create symbol of invalid kind")
      var sym = newSym(k.TSymKind, getIdent(c.cache, name), c.idgen, c.module.owner, c.debug[pc])
      incl(sym.flagsImpl, sfGenSym)
      let n = newSymNode(sym)
      n.flags.incl nfIsRef
      setNode(ra, n)
    of opcNccValue:
      let destKey = str(instr.regB)
      rInt(ra) =
        if usesSharedCounters(c.config): sharedCounterValue(c.config, destKey)
        else: getOrDefault(c.graph.cacheCounters, destKey)
    of opcNccInc:
      let g = c.graph
      let destKey = str(instr.regB)
      let by = rInt(instr.regC)
      if usesSharedCounters(c.config):
        sharedCounterInc(c.config, destKey, by)
      else:
        let v = getOrDefault(g.cacheCounters, destKey)
        g.cacheCounters[destKey] = v+by
      recordInc(c, c.debug[pc], destKey, by)
    of opcNcsAdd:
      let g = c.graph
      let destKey = str(instr.regB)
      let val = node(instr.regC)
      if not contains(g.cacheSeqs, destKey):
        g.cacheSeqs[destKey] = newTree(nkStmtList, val)
      else:
        g.cacheSeqs[destKey].add val
      recordAdd(c, c.debug[pc], destKey, val)
    of opcNcsIncl:
      let g = c.graph
      let destKey = str(instr.regB)
      let val = node(instr.regC)
      if not contains(g.cacheSeqs, destKey):
        g.cacheSeqs[destKey] = newTree(nkStmtList, val)
      else:
        block search:
          for existing in g.cacheSeqs[destKey]:
            if exprStructuralEquivalent(existing, val, strictSymEquality=true):
              break search
          g.cacheSeqs[destKey].add val
      recordIncl(c, c.debug[pc], destKey, val)
    of opcNcsLen:
      let g = c.graph
      let destKey = str(instr.regB)
      rInt(ra) =
        if contains(g.cacheSeqs, destKey): g.cacheSeqs[destKey].len else: 0
    of opcNcsAt:
      let g = c.graph
      let idx = rInt(instr.regC)
      let destKey = str(instr.regB)
      if contains(g.cacheSeqs, destKey) and idx <% g.cacheSeqs[destKey].len:
        setNode(ra, g.cacheSeqs[destKey][idx.int])
      else:
        stackTrace(c, tos, pc, formatErrorIndexBound(idx, g.cacheSeqs.getOrDefault(destKey).safeLen-1))
    of opcNctPut:
      let g = c.graph
      let destKey = str(ra)
      let key = str(instr.regB)
      let val = node(instr.regC)
      if not contains(g.cacheTables, destKey):
        g.cacheTables[destKey] = initBTree[string, PNode]()
      if not contains(g.cacheTables[destKey], key):
        g.cacheTables[destKey].add(key, val)
        recordPut(c, c.debug[pc], destKey, key, val)
      else:
        stackTrace(c, tos, pc, "key already exists: " & key)
    of opcNctLen:
      let g = c.graph
      let destKey = str(instr.regB)
      rInt(ra) =
        if contains(g.cacheTables, destKey): g.cacheTables[destKey].len else: 0
    of opcNctGet:
      let g = c.graph
      let destKey = str(instr.regB)
      let key = str(instr.regC)
      if contains(g.cacheTables, destKey):
        if contains(g.cacheTables[destKey], key):
          setNode(ra, getOrDefault(g.cacheTables[destKey], key))
        else:
          stackTrace(c, tos, pc, "key does not exist: " & key)
      else:
        stackTrace(c, tos, pc, "key does not exist: " & destKey)
    of opcNctHasNext:
      let g = c.graph
      let destKey = str(instr.regB)
      rInt(ra) =
        if g.cacheTables.contains(destKey):
          ord(btrees.hasNext(g.cacheTables[destKey], rInt(instr.regC).int))
        else:
          0
    of opcNctNext:
      let g = c.graph
      let destKey = str(instr.regB)
      let index = rInt(instr.regC)
      if contains(g.cacheTables, destKey):
        let (k, v, nextIndex) = btrees.next(g.cacheTables[destKey], index.int)
        let t = getType(c.mem, int64(wImm()))
        let tup = newTree(nkTupleConstr, newStrNode(k, c.debug[pc]), v,
                          newIntNode(nkIntLit, nextIndex))
        let vc = valueConv(c)
        storeValue(vc, rAdr(ra), tup, t, inConst = false)
      else:
        stackTrace(c, tos, pc, "key does not exist: " & destKey)
    of opcTypeTrait:
      # XXX only supports 'name' for now; we can use regC to encode the
      # type trait operation
      let n = node(instr.regB)
      var typ = if n != nil: n.typ else: nil
      internalAssert c.config, typ != nil
      while typ.kind == tyTypeDesc and typ.hasElementType: typ = typ.skipModifier
      putStr(ra, typ.typeToString(preferExported))

    c.profiler.leave(c)

    if instr.opcode in largeInstrs: inc pc
    inc pc

proc execute(c: PCtx, start: int; resultType: PType; info: TLineInfo): PNode =
  ## runs top level code; returns the result as an AST if `resultType` is
  ## not nil.
  let tos = newFrame(c, nil, max(c.prc.regInfo.len, 1), 0, nil)
  let a = rawExecute(c, start, tos)
  if resultType != nil and a != 0 and not isEmptyType(resultType):
    result = regToNode(c, a, resultType, info)
  else:
    result = newNodeI(nkEmpty, info)
  c.mem.popFrames(tos.mark)

proc execProc*(c: PCtx; sym: PSym; args: openArray[PNode]): PNode =
  c.loopIterations = c.config.maxLoopIterationsVM
  c.callDepth = c.config.maxCallDepthVM
  if sym.kind in routineKinds:
    if sym.typ.paramsLen != args.len:
      result = nil
      localError(c.config, sym.info,
        "NimScript: expected $# arguments, but got $#" % [
        $(sym.typ.paramsLen), $args.len])
    else:
      let start = genProc(c, sym)
      let shape = callShapeOf(c, sym)
      let tos = newFrame(c, sym, start.frameSlots, 0, nil)
      let firstParam = tos.fp +! max(start.resultSlots, 1) * SlotSize
      # XXX We could perform some type checking here.
      for i in 0..<sym.typ.paramsLen:
        nodeToReg(c, args[i], shape.paramTypes[i], firstParam +! shape.paramOffsets[i])
      let a = rawExecute(c, start.pc, tos)
      let ret = sym.typ.returnType
      if ret != nil and not isEmptyType(ret) and a != 0:
        result = regToNode(c, a, ret, sym.info)
      else:
        result = newNodeI(nkEmpty, sym.info)
      c.mem.popFrames(tos.mark)
  else:
    result = nil
    localError(c.config, sym.info,
      "NimScript: attempt to call non-routine: " & sym.name.s)

proc errorNode(idgen: IdGenerator; owner: PSym, n: PNode): PNode =
  result = newNodeI(nkEmpty, n.info)
  result.typ = newType(tyError, idgen, owner)
  result.typ.incl tfCheckedForDestructor

proc evalStmt*(c: PCtx, n: PNode) =
  let n = transformExpr(c.graph, c.idgen, c.module, n)
  let start = genStmt(c, n)
  if c.cannotEval:
    c.cannotEval = false
    return
  # execute new instructions; this redundant opcEof check saves us lots
  # of allocations in 'execute':
  if c.code[start].opcode != opcEof:
    discard execute(c, start, nil, n.info)

proc evalExpr*(c: PCtx, n: PNode): PNode =
  # deadcode
  # `nim --eval:"expr"` might've used it at some point for idetools; could
  # be revived for nimsuggest
  let n = transformExpr(c.graph, c.idgen, c.module, n)
  c.cannotEval = false
  let start = genExpr(c, n)
  if c.cannotEval:
    return errorNode(c.idgen, c.module, n)
  assert c.code[start].opcode != opcEof
  result = execute(c, start, n.typ, n.info)

proc getGlobalValue*(c: PCtx; s: PSym): PNode =
  internalAssert c.config, s.kind in {skLet, skVar} and sfGlobal in s.flags
  let a = c.globalAddrs.getOrDefault(s.itemId, 0)
  if a == 0: return newNodeI(nkEmpty, s.info)
  let vc = valueConv(c)
  result = loadValue(vc, a, s.typ, s.info)

proc setGlobalValue*(c: PCtx; s: PSym, val: PNode) =
  ## Does not do type checking so ensure the `val` matches the `s.typ`
  internalAssert c.config, s.kind in {skLet, skVar} and sfGlobal in s.flags
  var a = c.globalAddrs.getOrDefault(s.itemId, 0)
  let size = vmSizeOf(c.layouts, c.config, s.typ)
  if a == 0:
    a = allocGlobal(c.mem, size, vmAlignOf(c.layouts, c.config, s.typ))
    c.globalAddrs[s.itemId] = a
  zeroMem(toPtr(a), size)
  let vc = valueConv(c)
  storeValue(vc, a, val, s.typ, inConst = false)

include vmops

proc setupGlobalCtx*(module: PSym; graph: ModuleGraph; idgen: IdGenerator) =
  if graph.vm.isNil:
    graph.vm = newCtx(module, graph.cache, graph, idgen)
    registerAdditionalOps(PCtx graph.vm)
  else:
    refresh(PCtx graph.vm, module, idgen)

proc setupEvalGen*(graph: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext =
  # XXX produce a new 'globals' environment here:
  setupGlobalCtx(module, graph, idgen)
  result = PCtx graph.vm

proc interpreterCode*(c: PPassContext, n: PNode): PNode =
  let c = PCtx(c)
  # don't eval errornous code:
  if c.oldErrorCount == c.config.errorCounter:
    evalStmt(c, n)
    result = newNodeI(nkEmpty, n.info)
  else:
    result = n
  c.oldErrorCount = c.config.errorCounter

proc evalConstExprAux(module: PSym; idgen: IdGenerator;
                      g: ModuleGraph; prc: PSym, n: PNode,
                      mode: TEvalMode; semCtx: PPassContext): PNode =
  when defined(nimsuggest):
    if g.config.expandDone():
      return n
  #if g.config.errorCounter > 0: return n
  let n = transformExpr(g, idgen, module, n)
  setupGlobalCtx(module, g, idgen)
  var c = PCtx g.vm
  let oldMode = c.mode
  let oldLocals = c.locals
  let oldSemCtx = c.semCtx
  if semCtx != nil: c.semCtx = semCtx
  c.mode = mode
  c.locals = initIntSet()
  c.cannotEval = false
  let start = genExpr(c, n, requiresValue = mode!=emStaticStmt)
  c.locals = oldLocals
  if c.cannotEval:
    return errorNode(idgen, prc, n)
  if c.code[start].opcode == opcEof: return newNodeI(nkEmpty, n.info)
  assert c.code[start].opcode != opcEof
  when debugEchoCode or defined(nimVmListing): c.echoCode start
  let tos = newFrame(c, prc, max(c.prc.regInfo.len, 1), 0, nil)
  let a = rawExecute(c, start, tos)
  if mode == emStaticStmt or n.typ == nil or isEmptyType(n.typ) or a == 0:
    result = newNodeI(nkEmpty, n.info)
  else:
    result = regToNode(c, a, n.typ, n.info)
  c.mem.popFrames(tos.mark)
  if result.info.col < 0: result.info = n.info
  c.mode = oldMode
  c.semCtx = oldSemCtx

proc evalConstExpr*(module: PSym; idgen: IdGenerator; g: ModuleGraph; e: PNode;
                    semCtx: PPassContext = nil): PNode =
  result = evalConstExprAux(module, idgen, g, nil, e, emConst, semCtx)

proc evalStaticExpr*(module: PSym; idgen: IdGenerator; g: ModuleGraph; e: PNode, prc: PSym;
                     semCtx: PPassContext = nil): PNode =
  result = evalConstExprAux(module, idgen, g, prc, e, emStaticExpr, semCtx)

proc evalStaticStmt*(module: PSym; idgen: IdGenerator; g: ModuleGraph; e: PNode, prc: PSym;
                     semCtx: PPassContext = nil) =
  discard evalConstExprAux(module, idgen, g, prc, e, emStaticStmt, semCtx)

proc setupCompileTimeVar*(module: PSym; idgen: IdGenerator; g: ModuleGraph; n: PNode;
                          semCtx: PPassContext = nil) =
  discard evalConstExprAux(module, idgen, g, nil, n, emStaticStmt, semCtx)

iterator genericParamsInMacroCall*(macroSym: PSym, call: PNode): (PSym, PNode) =
  let gp = macroSym.ast[genericParamsPos]
  for i in 0..<gp.len:
    let genericParam = gp[i].sym
    let posInCall = macroSym.typ.signatureLen + i
    if posInCall < call.len:
      yield (genericParam, call[posInCall])

# to prevent endless recursion in macro instantiation
const evalMacroLimit = 1000

proc setupMacroParam(c: PCtx; x: PNode; typ: PType; dest: Address) =
  ## stores the argument `x` of a macro call; macros receive their
  ## arguments as NimNodes unless they are `static`.
  case typ.kind
  of tyStatic:
    when defined(nimVmListing):
      echo "STATIC ARG ", x.kind, " ", renderTree(x), " ", typeToString(typ.base)
    nodeToReg(c, x, typ.base, dest)
  else:
    var n = x
    if n.kind in {nkHiddenSubConv, nkHiddenStdConv}: n = n[1]
    n.flags.incl nfIsRef
    n.typ = x.typ
    st[int64](dest, nodeHandle(c.mem, n))

proc evalMacroCall*(module: PSym; idgen: IdGenerator; g: ModuleGraph; templInstCounter: ref int;
                    n, nOrig: PNode, sym: PSym; semCtx: PPassContext = nil): PNode =
  #if g.config.errorCounter > 0: return errorNode(idgen, module, n)

  # XXX globalError() is ugly here, but I don't know a better solution for now
  inc(g.config.evalMacroCounter)
  if g.config.evalMacroCounter > evalMacroLimit:
    globalError(g.config, n.info, "macro instantiation too nested")

  # immediate macros can bypass any type and arity checking so we check the
  # arity here too:
  let sl = sym.typ.signatureLen
  if sl > n.safeLen and sl > 1:
    globalError(g.config, n.info, "in call '$#' got $#, but expected $# argument(s)" % [
        n.renderTree, $(n.safeLen-1), $(sym.typ.paramsLen)])

  setupGlobalCtx(module, g, idgen)
  var c = PCtx g.vm
  let oldMode = c.mode
  let oldSemCtx = c.semCtx
  if semCtx != nil: c.semCtx = semCtx
  c.mode = emStaticStmt
  c.comesFromHeuristic.line = 0'u16
  c.callsite = nOrig
  c.templInstCounter = templInstCounter
  c.cannotEval = false
  let start = genProc(c, sym)
  if c.cannotEval:
    return errorNode(idgen, module, n)

  let tos = newFrame(c, sym, start.frameSlots, 0, nil)
  let shape = callShapeOf(c, sym)
  let firstParam = tos.fp +! max(start.resultSlots, 1) * SlotSize
  # like the old VM: the result of a macro starts as an empty node
  st[int64](tos.fp, int64(nodeHandle(c.mem, newNodeI(nkEmpty, n.info))))

  # setup parameters:
  for i, param in paramTypes(sym.typ):
    let idx = i-FirstParamAt
    setupMacroParam(c, n[idx+1], param, firstParam +! shape.paramOffsets[idx])
    when defined(nimVmListing):
      echo "PARAM ", idx, " off ", shape.paramOffsets[idx], " value ", ld[int64](firstParam +! shape.paramOffsets[idx]),
        " frame ", start.frameSlots, " resultSlots ", start.resultSlots

  let gp = sym.ast[genericParamsPos]
  for i in 0..<gp.len:
    let idx = sym.typ.signatureLen + i
    if idx < n.len and i < start.genericParamSlots.len:
      setupMacroParam(c, n[idx], gp[i].sym.typ,
                      tos.fp +! int(start.genericParamSlots[i]) * SlotSize)
    else:
      dec(g.config.evalMacroCounter)
      c.callsite = nil
      localError(c.config, n.info, "expected " & $gp.len &
                 " generic parameter(s)")
  let a = rawExecute(c, start.pc, tos)
  result = if a != 0: getNode(c.mem, ld[int64](a)) else: nil
  c.mem.popFrames(tos.mark)
  if result == nil: result = newNodeI(nkEmpty, n.info)
  if result.info.line < 0: result.info = n.info
  if cyclicTree(result): globalError(c.config, n.info, "macro produced a cyclic tree")
  dec(g.config.evalMacroCounter)
  c.callsite = nil
  c.mode = oldMode
  c.semCtx = oldSemCtx
