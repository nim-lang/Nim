#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Conversions between literal ASTs (`PNode`) and VM memory. This is the
## boundary between the compiler and the VM: constants, macro arguments and
## `static` parameters are *stored* into VM memory, results of compile-time
## evaluation are *loaded* back into ASTs.

import std/intsets
import ast, types, options, msgs, lineinfos, int128, nimsets, bitsets,
  vmlayout, vmmem
from astalgo import lookupInRecord

when defined(nimPreviewSlimSystem):
  import std/assertions

type
  ValueConv* = object
    ## everything the conversions need; the VM context owns these.
    mem*: ptr VmMemory
    layouts*: ptr LayoutCache
    conf*: ConfigRef
    nilType*: PType ## the type of `nil`, for the C backend's sake

proc valueError(vc: ValueConv; info: TLineInfo; msg: string) {.noreturn.} =
  globalError(vc.conf, info, msg)
  raiseAssert "unreachable"

proc skipConvs(n: PNode): PNode =
  result = n
  while true:
    case result.kind
    of nkHiddenStdConv, nkHiddenSubConv, nkConv, nkHiddenCallConv:
      result = result[1]
    of nkStmtListExpr:
      result = result.lastSon
    else:
      break

proc storeInt(dest: Address; v: BiggestInt; k: MemKind) =
  case k
  of mkI8, mkU8: st[uint8](dest, cast[uint8](v))
  of mkI16, mkU16: st[uint16](dest, cast[uint16](v))
  of mkI32, mkU32: st[uint32](dest, cast[uint32](v))
  of mkI64, mkU64, mkPtr, mkNode: st[int64](dest, v)
  of mkF32: st[float32](dest, float32(cast[float64](v)))
  of mkF64: st[int64](dest, v)
  of mkBlock: raiseAssert "storeInt: not a scalar"

proc loadInt*(src: Address; k: MemKind): BiggestInt =
  ## loads a scalar and widens it to 64 bits, like the VM's registers do.
  case k
  of mkI8: BiggestInt(ld[int8](src))
  of mkI16: BiggestInt(ld[int16](src))
  of mkI32: BiggestInt(ld[int32](src))
  of mkU8: BiggestInt(ld[uint8](src))
  of mkU16: BiggestInt(ld[uint16](src))
  of mkU32: BiggestInt(ld[uint32](src))
  of mkI64, mkU64, mkPtr, mkNode, mkF64: ld[int64](src)
  of mkF32: cast[BiggestInt](float64(ld[float32](src)))
  of mkBlock: raiseAssert "loadInt: not a scalar"

proc ordValue(n: PNode): BiggestInt =
  case n.kind
  of nkCharLit..nkUInt64Lit: n.intVal
  of nkNilLit: 0
  of nkSym:
    if n.sym.kind == skEnumField: BiggestInt(n.sym.position) else: 0
  else: 0

proc setBit(dest: Address; bit: BiggestInt) =
  let p = dest +! int(bit shr 3)
  st[uint8](p, ld[uint8](p) or uint8(1 shl (bit and 7)))

# ------------------------- store ---------------------------------------------

proc storeValue*(vc: ValueConv; dest: Address; n: PNode; t: PType; inConst: bool)

proc storeElems(vc: ValueConv; dest: Address; n: PNode; elemType: PType;
                count: int; inConst: bool) =
  let esize = vmSizeOf(vc.layouts[], vc.conf, elemType)
  if nfBroadcast in n.flags and n.len == 1:
    for i in 0..<count:
      storeValue(vc, dest +! i*esize, n[0], elemType, inConst)
  else:
    for i in 0..<min(count, n.len):
      storeValue(vc, dest +! i*esize, n[i], elemType, inConst)

proc storeTypeHeader(vc: ValueConv; dest: Address; objType: PType) =
  var root = objType
  while root.baseClass != nil: root = root.baseClass.skipTypes(skipPtrs)
  if hasTypeHeader(root):
    st[int64](dest, typeHandle(vc.mem[], objType))

proc branchMatches(conf: ConfigRef; branch: PNode; v: BiggestInt): bool =
  for i in 0..<branch.len-1:
    let lab = branch[i]
    if lab.kind == nkRange:
      if v >= ordValue(lab[0]) and v <= ordValue(lab[1]): return true
    elif lab.kind == nkCurly:
      for x in lab:
        if x.kind == nkRange:
          if v >= ordValue(x[0]) and v <= ordValue(x[1]): return true
        elif ordValue(x) == v: return true
    elif ordValue(lab) == v:
      return true
  result = false

proc activeBranch(conf: ConfigRef; recCase: PNode; v: BiggestInt): int =
  ## index of the branch of `recCase` that is selected by the discriminator
  ## value `v`, or -1.
  for i in 1..<recCase.len:
    if recCase[i].kind == nkElse or branchMatches(conf, recCase[i], v):
      return i
  result = -1

proc storeFields(vc: ValueConv; dest: Address; objType: PType; rec: PNode;
                 values: seq[PNode]; inConst: bool) =
  # Only fields of active branches are stored: the fields of the other
  # branches overlap with them and constructors list them with default values.
  case rec.kind
  of nkRecList:
    for ch in rec: storeFields(vc, dest, objType, ch, values, inConst)
  of nkRecCase:
    storeFields(vc, dest, objType, rec[0], values, inConst)
    let disc = rec[0].sym
    let v = if disc.position < values.len and values[disc.position] != nil:
              ordValue(skipConvs(values[disc.position]))
            else: 0
    let b = activeBranch(vc.conf, rec, v)
    if b > 0: storeFields(vc, dest, objType, rec[b].lastSon, values, inConst)
  of nkSym:
    let f = rec.sym
    if f.position < values.len and values[f.position] != nil:
      storeValue(vc, dest +! fieldOffset(vc.layouts[], vc.conf, objType, f),
                 values[f.position], f.typ, inConst)
  else:
    discard

proc storeObject(vc: ValueConv; dest: Address; n: PNode; objType: PType; inConst: bool) =
  storeTypeHeader(vc, dest, objType)
  var values: seq[PNode] = @[]
  for i in 1..<n.len:
    let it = n[i]
    if it.kind == nkExprColonExpr and it[0].kind in {nkSym, nkIdent}:
      var f = if it[0].kind == nkSym: it[0].sym else: nil
      if f == nil or f.owner == nil:
        # a field that was created from its name (marshal, macros):
        let name = if it[0].kind == nkSym: it[0].sym.name else: it[0].ident
        var b = objType
        f = nil
        while b != nil and f == nil:
          if b.n != nil: f = lookupInRecord(b.n, name)
          b = if b.baseClass != nil: b.baseClass.skipTypes(skipPtrs) else: nil
        if f == nil:
          valueError(vc, it.info, "VM: unknown field " & name.s)
      let pos = f.position
      if pos >= values.len: values.setLen pos+1
      values[pos] = it[1]
    else:
      valueError(vc, it.info, "VM: cannot store object field of kind " & $it.kind)
  var b = objType
  while b != nil:
    if b.n != nil: storeFields(vc, dest, objType, b.n, values, inConst)
    b = if b.baseClass != nil: b.baseClass.skipTypes(skipPtrs) else: nil

proc storeValue*(vc: ValueConv; dest: Address; n: PNode; t: PType; inConst: bool) =
  ## Writes the value `n` of type `t` to `dest`. `dest` must be zeroed.
  ## If `inConst` is true, data that the value refers to (string payloads,
  ## ref cells) is allocated in constant memory, otherwise on the heap.
  let n = skipConvs(n)
  let t = skipForLayout(t)
  let conf = vc.conf
  if isNimNodeType(t):
    # a `nil` NimNode is the handle 0:
    if n.kind != nkNilLit: st[int64](dest, nodeHandle(vc.mem[], n))
    return
  case t.kind
  of tyBool, tyChar, tyEnum, tyInt..tyInt64, tyUInt..tyUInt64:
    storeInt(dest, ordValue(n), memKind(conf, t))
  of tyFloat32:
    let v = if n.kind in nkFloatLiterals: n.floatVal else: BiggestFloat(ordValue(n))
    st[float32](dest, float32(v))
  of tyFloat, tyFloat64, tyFloat128:
    let v = if n.kind in nkFloatLiterals: n.floatVal else: BiggestFloat(ordValue(n))
    st[float64](dest, v)
  of tyString:
    case n.kind
    of nkStrLit..nkTripleStrLit: storeString(vc.mem[], dest, n.strVal, inConst)
    of nkNilLit, nkEmpty: discard
    of nkBracket:
      var s = newString(n.len)
      for i in 0..<n.len: s[i] = char(ordValue(n[i]))
      storeString(vc.mem[], dest, s, inConst)
    else: valueError(vc, n.info, "VM: cannot store string from " & $n.kind)
  of tyCstring:
    case n.kind
    of nkStrLit..nkTripleStrLit:
      let s = n.strVal
      let p = allocConst(vc.mem[], s.len+1, 1)
      if s.len > 0: copyMem(toPtr(p), unsafeAddr s[0], s.len)
      st[Address](dest, p)
    of nkNilLit, nkEmpty: discard
    else: valueError(vc, n.info, "VM: cannot store cstring from " & $n.kind)
  of tySequence:
    case n.kind
    of nkBracket:
      st[int](dest +! StrLenOffset, n.len)
      if n.len > 0:
        let e = t.elementType
        let L = getLayout(vc.layouts[], conf, e)
        let p = if inConst: newConstPayload(vc.mem[], n.len, L.size, L.align, false)
                else: newPayload(vc.mem[], n.len, L.size, L.align, false)
        st[Address](dest +! StrPayloadOffset, p)
        storeElems(vc, p +! payloadDataOffset(L.align), n, e, n.len, inConst)
    of nkNilLit, nkEmpty: discard
    else: valueError(vc, n.info, "VM: cannot store seq from " & $n.kind)
  of tyOpenArray, tyVarargs:
    if n.kind == nkBracket and n.len > 0:
      let e = t.elementType
      let L = getLayout(vc.layouts[], conf, e)
      let p = if inConst: allocConst(vc.mem[], n.len*L.size, L.align)
              else: heapAlloc(vc.mem[], n.len*L.size)
      storeElems(vc, p, n, e, n.len, inConst)
      st[Address](dest +! OpenArrayDataOffset, p)
      st[int](dest +! OpenArrayLenOffset, n.len)
  of tyArray:
    if n.kind == nkBracket:
      storeElems(vc, dest, n, t.elementType, toInt(lengthOrd(conf, t)), inConst)
    elif n.kind notin {nkEmpty, nkNilLit}:
      valueError(vc, n.info, "VM: cannot store array from " & $n.kind)
  of tyTuple:
    if n.kind in {nkTupleConstr, nkPar}:
      for i in 0..<min(n.len, t.kidsLen):
        let it = if n[i].kind == nkExprColonExpr: n[i][1] else: n[i]
        storeValue(vc, dest +! elemOffset(vc.layouts[], conf, t, i), it, t[i], inConst)
    elif n.kind notin {nkEmpty, nkNilLit}:
      valueError(vc, n.info, "VM: cannot store tuple from " & $n.kind)
  of tyObject:
    if n.kind == nkObjConstr:
      let dyn = if n.typ != nil: n.typ.skipTypes(abstractPtrs) else: t
      storeObject(vc, dest, n, if dyn.kind == tyObject: dyn else: t, inConst)
    elif n.kind in {nkEmpty, nkNilLit}:
      storeTypeHeader(vc, dest, t)
    else:
      valueError(vc, n.info, "VM: cannot store object from " & $n.kind)
  of tySet:
    if n.kind == nkCurly:
      let first = toInt64(firstOrd(conf, t.elementType))
      let bits = BiggestInt(setSize(conf, t)) * 8
      template incl(v: BiggestInt; it: PNode) =
        let bit = v - first
        if bit < 0 or bit >= bits:
          valueError(vc, it.info, "VM: set element out of range")
        setBit(dest, bit)
      for it in n:
        if it.kind == nkRange:
          let a = ordValue(it[0])
          let b = ordValue(it[1])
          if a <= b:
            incl(a, it)
            incl(b, it)
            for v in a..b: setBit(dest, v - first)
        else:
          incl(ordValue(it), it)
    elif n.kind notin {nkEmpty, nkNilLit}:
      valueError(vc, n.info, "VM: cannot store set from " & $n.kind)
  of tyRef:
    if n.kind == nkNilLit:
      discard
    elif n.kind == nkObjConstr:
      let dyn = if n.typ != nil: n.typ.skipTypes(abstractPtrs) else: nil
      let objType = if dyn != nil and dyn.kind == tyObject: dyn
                    else: t.elementType.skipTypes(abstractInst)
      let L = getLayout(vc.layouts[], conf, objType)
      let p = if inConst: newConstRef(vc.mem[], L.size, L.align)
              else: newRef(vc.mem[], L.size, L.align)
      storeObject(vc, p, n, objType, inConst)
      st[Address](dest, p)
    else:
      valueError(vc, n.info, "VM: cannot store ref from " & $n.kind)
  of tyPtr, tyPointer, tyNil:
    case n.kind
    of nkNilLit, nkEmpty: discard
    of nkCharLit..nkUInt64Lit: st[int64](dest, n.intVal)
    else: valueError(vc, n.info, "VM: cannot store pointer from " & $n.kind)
  of tyProc:
    var fn = n
    var env: PNode = nil
    if n.kind in {nkClosure, nkTupleConstr, nkPar} and n.len == 2:
      fn = n[0].skipConvs
      env = n[1]
    case fn.kind
    of nkSym: st[Address](dest, procAddress(vc.mem[], fn.sym))
    of nkNilLit, nkEmpty: discard
    of nkIntLit: st[int64](dest, fn.intVal) # cast[proc ...](0x123)
    else: valueError(vc, n.info, "VM: cannot store proc from " & $n.kind)
    if env != nil and env.kind notin {nkNilLit, nkEmpty}:
      valueError(vc, n.info, "VM: cannot store a closure with an environment")
  of tyTypeDesc:
    # typedesc values are NimNodes of kind nkType
    let x = if n.kind == nkType: n else: newNodeIT(nkType, n.info, n.typ)
    st[int64](dest, nodeHandle(vc.mem[], x))
  of tyUntyped, tyTyped:
    st[int64](dest, nodeHandle(vc.mem[], n))
  of tyVoid, tyEmpty:
    discard
  else:
    valueError(vc, n.info, "VM: cannot store value of type " & typeToString(t))

# ------------------------- load ----------------------------------------------

type
  Loader = object
    vc: ValueConv
    info: TLineInfo
    onPath: IntSet  # ref cells currently being loaded; detects cycles
    zeros: seq[seq[byte]] # zeroed host memory for inactive branches; one
                          # buffer per use so that addresses stay valid
    inZeros: int          # > 0 while loading from `zeros`

proc loadValue(L: var Loader; src: Address; t: PType): PNode

proc zeroArea(L: var Loader; size: int): Address =
  if size == 0: return Address(0)
  L.zeros.add newSeq[byte](size)
  result = toAddr(addr L.zeros[^1][0])

proc checkRead(L: var Loader; a: Address; size: int) =
  # zeroed host memory is not VM memory, but it is readable:
  if L.inZeros == 0 and not canRead(L.vc.mem[], a, size):
    valueError(L.vc, L.info, "VM produced a value that refers to invalid memory")

proc loadFields(L: var Loader; src: Address; objType: PType; n: PNode;
                active: bool; res: PNode) =
  case n.kind
  of nkRecList:
    for ch in n: loadFields(L, src, objType, ch, active, res)
  of nkRecCase:
    let disc = n[0].sym
    loadFields(L, src, objType, n[0], active, res)
    var v = BiggestInt(0)
    if active:
      let k = memKind(L.vc.conf, disc.typ)
      v = loadInt(src +! fieldOffset(L.vc.layouts[], L.vc.conf, objType, disc), k)
    let ab = if active: activeBranch(L.vc.conf, n, v) else: -1
    for i in 1..<n.len:
      loadFields(L, src, objType, n[i].lastSon, i == ab, res)
  of nkSym:
    let f = n.sym
    let value =
      if active:
        loadValue(L, src +! fieldOffset(L.vc.layouts[], L.vc.conf, objType, f), f.typ)
      else:
        # fields of inactive branches overlap with the active ones: their
        # bits are meaningless, so produce the default value instead.
        inc L.inZeros
        let v = loadValue(L, zeroArea(L, vmSizeOf(L.vc.layouts[], L.vc.conf, f.typ)), f.typ)
        dec L.inZeros
        v
    value.flags.incl nfSkipFieldChecking
    var colon = newNodeI(nkExprColonExpr, L.info)
    colon.add newSymNode(f, L.info)
    colon.add value
    res.add colon
  else:
    discard

proc loadObject(L: var Loader; src: Address; objType, resultType: PType): PNode =
  result = newNodeIT(nkObjConstr, L.info, resultType)
  result.add newNodeIT(nkEmpty, L.info, resultType)
  var chain: seq[PType] = @[]
  var b = objType
  while b != nil:
    chain.add b
    b = if b.baseClass != nil: b.baseClass.skipTypes(skipPtrs) else: nil
  for i in countdown(chain.len-1, 0):
    if chain[i].n != nil:
      loadFields(L, src, objType, chain[i].n, true, result)

proc dynamicType(L: var Loader; src: Address; t: PType): PType =
  ## for an inheritable object: the type stored in its type header.
  result = t
  var root = t
  while root.baseClass != nil: root = root.baseClass.skipTypes(skipPtrs)
  if hasTypeHeader(root):
    let dyn = getType(L.vc.mem[], ld[int64](src))
    if dyn != nil:
      result = dyn.skipTypes(abstractInst)

proc loadElems(L: var Loader; data: Address; count: int; elemType: PType; res: PNode) =
  let esize = vmSizeOf(L.vc.layouts[], L.vc.conf, elemType)
  checkRead(L, data, count*esize)
  for i in 0..<count:
    res.add loadValue(L, data +! i*esize, elemType)

proc isZeroed(a: Address; size: int): bool =
  let p = cast[ptr UncheckedArray[byte]](toPtr(a))
  for i in 0..<size:
    if p[i] != 0: return false
  result = true

proc loadValue(L: var Loader; src: Address; t: PType): PNode =
  let conf = L.vc.conf
  let s = skipForLayout(t)
  if isNimNodeType(s):
    result = getNode(L.vc.mem[], ld[int64](src))
    if result == nil: result = newNodeIT(nkNilLit, L.info, t)
    return
  case s.kind
  of tyBool, tyChar, tyEnum, tyInt..tyInt64, tyUInt..tyUInt64:
    result = newIntTypeNode(loadInt(src, memKind(conf, s)), t)
    result.info = L.info
  of tyFloat32:
    result = newFloatNode(nkFloat32Lit, ld[float32](src))
    result.typ = t
    result.info = L.info
  of tyFloat, tyFloat64, tyFloat128:
    result = newFloatNode(nkFloatLit, ld[float64](src))
    result.typ = t
    result.info = L.info
  of tyString:
    let len = ld[int](src +! StrLenOffset)
    if len > 0:
      let p = ld[Address](src +! StrPayloadOffset)
      checkRead(L, p, PayloadDataOffset + len)
      if payloadCap(p) < len:
        valueError(L.vc, L.info, "VM produced a corrupt string")
    elif len < 0:
      valueError(L.vc, L.info, "VM produced a corrupt string")
    result = newStrNode(nkStrLit, loadString(src))
    result.typ = t
    result.info = L.info
  of tyCstring:
    let p = ld[Address](src)
    if p == 0:
      result = newNodeIT(nkNilLit, L.info, t)
    else:
      var s = ""
      var q = p
      while true:
        checkRead(L, q, 1)
        let c = ld[char](q)
        if c == '\0': break
        s.add c
        q = q +! 1
      result = newStrNode(nkStrLit, s)
      result.typ = t
      result.info = L.info
  of tySequence:
    result = newNodeIT(nkBracket, L.info, t)
    let len = ld[int](src +! StrLenOffset)
    if len < 0: valueError(L.vc, L.info, "VM produced a corrupt seq")
    if len > 0:
      let p = ld[Address](src +! StrPayloadOffset)
      checkRead(L, p, PayloadDataOffset)
      if payloadCap(p) < len: valueError(L.vc, L.info, "VM produced a corrupt seq")
      let e = s.elementType
      loadElems(L, p +! payloadDataOffset(vmAlignOf(L.vc.layouts[], conf, e)), len, e, result)
  of tyOpenArray, tyVarargs:
    result = newNodeIT(nkBracket, L.info, t)
    let len = ld[int](src +! OpenArrayLenOffset)
    if len < 0: valueError(L.vc, L.info, "VM produced a corrupt openArray")
    if len > 0:
      loadElems(L, ld[Address](src +! OpenArrayDataOffset), len, s.elementType, result)
  of tyArray:
    result = newNodeIT(nkBracket, L.info, t)
    let count = toInt(lengthOrd(conf, s))
    let size = count * vmSizeOf(L.vc.layouts[], conf, s.elementType)
    if count > broadcastArrayThreshold and
        (checkRead(L, src, size); isZeroed(src, size)):
      # the broadcast form of the old VM's `getNullValue`: a single son
      # stands for `count` zeroed elements, see `isDefaultBroadcastArray`.
      result.add loadValue(L, src, s.elementType)
      result.flags.incl nfBroadcast
    else:
      loadElems(L, src, count, s.elementType, result)
  of tyTuple:
    result = newNodeIT(nkTupleConstr, L.info, t)
    for i in 0..<s.kidsLen:
      result.add loadValue(L, src +! elemOffset(L.vc.layouts[], conf, s, i), s[i])
  of tyObject:
    let dyn = dynamicType(L, src, s)
    result = loadObject(L, src, dyn, if dyn == s: t else: dyn)
  of tySet:
    let size = setSize(conf, s)
    var bits: TBitSet = newSeq[byte](size)
    copyMem(addr bits[0], toPtr(src), size)
    result = toTreeSet(conf, bits, s, L.info)
    result.typ = t
  of tyRef:
    let p = ld[Address](src)
    if p == 0:
      result = newNodeIT(nkNilLit, L.info, t)
    else:
      let objType = s.elementType.skipTypes(abstractInst)
      if objType.kind != tyObject:
        valueError(L.vc, L.info, "VM: cannot produce a constant of type " & typeToString(t))
      let addrKey = cast[int](p)
      if L.onPath.containsOrIncl(addrKey):
        valueError(L.vc, L.info, "VM: the resulting value is cyclic")
      checkRead(L, p -! RefHeaderSize, RefHeaderSize)
      checkRead(L, p, vmSizeOf(L.vc.layouts[], conf, objType))
      let dyn = dynamicType(L, p, objType)
      result = loadObject(L, p, dyn, t)
      L.onPath.excl addrKey
  of tyPtr, tyPointer, tyNil, tyVar, tyLent:
    let p = ld[int64](src)
    if p == 0:
      result = newNodeIT(nkNilLit, L.info, t)
    else:
      result = newIntNode(nkIntLit, p)
      result.typ = t
      result.info = L.info
      result.flags.incl nfIsPtr
  of tyProc:
    let a = ld[Address](src)
    let fn = getProc(L.vc.mem[], a)
    var fnNode: PNode
    if fn != nil:
      fnNode = newSymNode(fn, L.info)
    elif a == 0:
      fnNode = newNodeIT(nkNilLit, L.info, t)
    else:
      # an integer that was cast to a proc type
      fnNode = newIntNode(nkIntLit, cast[BiggestInt](a))
      fnNode.typ = t
      fnNode.info = L.info
    if s.callConv == ccClosure:
      result = newNodeIT(nkTupleConstr, L.info, t)
      result.add fnNode
      let env = ld[int64](src +! ClosureEnvOffset)
      if env == 0:
        result.add newNodeIT(nkNilLit, L.info, L.vc.nilType)
      else:
        # sem reports closures with an environment as an error
        let e = newIntNode(nkIntLit, env)
        e.info = L.info
        result.add e
    else:
      result = fnNode
  of tyTypeDesc, tyUntyped, tyTyped:
    result = getNode(L.vc.mem[], ld[int64](src))
    if result == nil:
      result = if s.kind == tyTypeDesc: newNodeIT(nkType, L.info, t)
               else: newNodeI(nkNilLit, L.info)
  of tyVoid, tyEmpty:
    result = newNodeI(nkEmpty, L.info)
  else:
    valueError(L.vc, L.info, "VM: cannot produce a value of type " & typeToString(t))

proc loadValue*(vc: ValueConv; src: Address; t: PType; info: TLineInfo): PNode =
  ## Reads the value of type `t` at `src` and turns it into a literal AST.
  var L = Loader(vc: vc, info: info, onPath: initIntSet())
  result = loadValue(L, src, t)

when defined(nimVmRoundtripCheck):
  # Debugging aid for this module: with `-d:nimVmRoundtripCheck` every
  # `const` value is stored into VM memory and loaded back, twice. The
  # second round must reproduce the first one exactly.
  import renderer

  var rtMem: VmMemory
  var rtLayouts: LayoutCache

  proc isValueTree(n: PNode): bool =
    case n.kind
    of nkCharLit..nkNilLit, nkSym, nkType: result = true
    of nkBracket, nkCurly, nkRange, nkObjConstr, nkTupleConstr, nkPar,
       nkExprColonExpr, nkClosure, nkHiddenStdConv, nkHiddenSubConv, nkConv:
      result = true
      for ch in n:
        if ch.kind != nkEmpty and not isValueTree(ch): return false
    else: result = false

  proc vmRoundtripCheck*(conf: ConfigRef; n: PNode; t: PType) =
    # values that are not literals are the result of failed evaluations:
    if t == nil or n == nil or not isValueTree(n) or conf.errorCounter > 0: return
    let vc = ValueConv(mem: addr rtMem, layouts: addr rtLayouts, conf: conf)
    let size = vmSizeOf(rtLayouts, conf, t)
    let align = vmAlignOf(rtLayouts, conf, t)
    for inConst in [false, true]:
      let a = allocGlobal(rtMem, size, align)
      storeValue(vc, a, n, t, inConst)
      let v1 = loadValue(vc, a, t, n.info)
      let b = allocGlobal(rtMem, size, align)
      storeValue(vc, b, v1, t, inConst)
      let v2 = loadValue(vc, b, t, n.info)
      let r1 = renderTree(v1)
      let r2 = renderTree(v2)
      if r1 != r2:
        localError(conf, n.info, "VM roundtrip mismatch for " & renderTree(n) &
          "\nfirst:  " & r1 & "\nsecond: " & r2)
        return
