#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Memory layout of Nim types inside the VM. The VM works on "packed data":
## values are laid out exactly like the C backend lays them out, except that
## the *host* ABI is used (64 bit pointers and `int`), regardless of the
## target. `sizeof` & co are folded by sem using the target's layout; this
## module is only about how the VM itself stores values.
##
## Differences to the C backend's layout:
## - `NimNode`, `typedesc`, `typed` and `untyped` values are NimNode handles
##   stored in a pointer sized slot. A typedesc is represented as a `nkType`
##   node.
## - Proc values are proc handles stored in a pointer sized slot; closures are
##   `(procHandle, env)`.
## - Fields with a `bitsize` are not packed into bit fields.
## - Zero length arrays occupy no storage.
## - Imported, incomplete structs are laid out from their declared fields.

import std/[tables, intsets]
when defined(nimPreviewSlimSystem):
  import std/assertions
import ast, types, options, msgs, lineinfos, int128, nversion

const
  VmPtrSize* = 8 ## size of a pointer, `int`, a handle in the VM
  VmMaxAlign* = 8

  # layout of the composite builtin types:
  StrLenOffset* = 0      ## `len` field of a string or seq
  StrPayloadOffset* = 8  ## `p` field of a string or seq
  PayloadCapOffset* = 0  ## `cap` field of a string or seq payload
  PayloadDataOffset* = 8 ## first element of a string or seq payload
  ClosureFnOffset* = 0
  ClosureEnvOffset* = 8
  OpenArrayDataOffset* = 0
  OpenArrayLenOffset* = 8
  TypeHeaderSize* = 8    ## size of the type field of an inheritable object

type
  MemKind* = enum ## how a scalar is stored in memory; temporaries in the
                  ## VM's registers are always widened to 64 bits.
    mkBlock,      ## not a scalar: copied as a block of bytes
    mkI8, mkI16, mkI32, mkI64,
    mkU8, mkU16, mkU32, mkU64,
    mkF32, mkF64,
    mkPtr,        ## pointer sized: ptr, ref, cstring, proc, handles
    mkNode        ## a NimNode/typedesc handle

  VmLayout* = object
    size*: int
    align*: int
    fields*: seq[int] ## objects: offset of the field with `position` i;
                      ## tuples: offset of the i-th element

  LayoutCache* = object
    tab: Table[ItemId, int]
    layouts: seq[VmLayout]
    inProgress: Table[ItemId, bool]

const
  ScalarMemKinds* = {mkI8..mkNode}
  SignedMemKinds* = {mkI8..mkI64}
  UnsignedMemKinds* = {mkU8..mkU64}
  FloatMemKinds* = {mkF32, mkF64}

proc alignTo*(address, alignment: int): int {.inline.} =
  result = (address + alignment - 1) and not (alignment - 1)

proc skipForLayout*(t: PType): PType =
  result = t
  while true:
    case result.kind
    of tyGenericInst, tyDistinct, tyAlias, tySink, tyOwned, tyRange,
       tyOrdinal:
      result = result.skipModifier
    of tyInferred:
      if result.hasElementType: result = result.last
      else: break
    of tyStatic:
      if result.hasElementType: result = result.skipModifier
      else: break
    of tyTypeClasses:
      if result.isResolvedUserTypeClass: result = result.last
      else: break
    else:
      break

proc hasTypeHeader*(t: PType): bool =
  ## Inheritable root objects (`RootObj` and friends) start with a type field.
  t.kind == tyObject and t.baseClass == nil and
    not (t.sym != nil and {sfPure, sfInfixCall} * t.sym.flags != {}) and
    tfFinal notin t.flags

proc enumSize(conf: ConfigRef; t: PType): int =
  if firstOrd(conf, t) < Zero:
    result = 4
  else:
    let last = toInt64(lastOrd(conf, t))
    if last < (1 shl 8): result = 1
    elif last < (1 shl 16): result = 2
    elif last < (1'i64 shl 32): result = 4
    else: result = 8

proc setSize*(conf: ConfigRef; t: PType): int =
  ## Size of a set type in bytes. Sets of up to 64 elements are stored as an
  ## integer of the smallest fitting size, larger sets as a byte array.
  ## Invalid set types (with too many elements) have the size 0.
  if t.elementType.kind == tyEmpty: return 1 # the type of `{}`
  let length = toInt64(lengthOrd(conf, t.elementType))
  if length < 0 or length > MaxSetElements: return 0
  if length <= 8: result = 1
  elif length <= 16: result = 2
  elif length <= 32: result = 4
  elif length <= 64: result = 8
  else: result = int((length + 7) div 8)

proc memKind*(conf: ConfigRef; t: PType): MemKind =
  ## How a value of type `t` is loaded from/stored to memory.
  let t = skipForLayout(t)
  if isNimNodeType(t): return mkNode
  case t.kind
  of tyBool, tyChar, tyUInt8: result = mkU8
  of tyInt8: result = mkI8
  of tyInt16: result = mkI16
  of tyInt32: result = mkI32
  of tyInt, tyInt64: result = mkI64
  of tyUInt16: result = mkU16
  of tyUInt32: result = mkU32
  of tyUInt, tyUInt64: result = mkU64
  of tyFloat32: result = mkF32
  of tyFloat, tyFloat64, tyFloat128: result = mkF64
  of tyEnum:
    if firstOrd(conf, t) < Zero:
      result = mkI32
    else:
      case enumSize(conf, t)
      of 1: result = mkU8
      of 2: result = mkU16
      of 4: result = mkU32
      else: result = mkI64
  of tySet:
    case setSize(conf, t)
    of 1: result = mkU8
    of 2: result = mkU16
    of 4: result = mkU32
    of 8: result = mkU64
    else: result = mkBlock
  of tyRef:
    result = mkPtr
  of tyTypeDesc, tyUntyped, tyTyped:
    result = mkNode
  of tyPtr, tyPointer, tyCstring, tyNil, tyVar, tyLent:
    result = mkPtr
  of tyProc:
    result = if t.callConv == ccClosure: mkBlock else: mkPtr
  else:
    result = mkBlock

proc memKindSize*(k: MemKind): int =
  case k
  of mkI8, mkU8: 1
  of mkI16, mkU16: 2
  of mkI32, mkU32, mkF32: 4
  of mkI64, mkU64, mkF64, mkPtr, mkNode: 8
  of mkBlock: 0

proc layoutError(conf: ConfigRef; t: PType; msg: string) {.noreturn.} =
  let info = if t.sym != nil: t.sym.info else: unknownLineInfo
  globalError(conf, info, "VM cannot lay out type '" & typeToString(t) & "': " & msg)
  raiseAssert "unreachable"

proc computeLayout(c: var LayoutCache; conf: ConfigRef; t: PType): VmLayout

proc layoutIdx(c: var LayoutCache; conf: ConfigRef; t: PType): int =
  # Note: we hand out indexes, not `lent` results, because computing a layout
  # recursively computes others and so can grow `c.layouts`.
  let t = skipForLayout(t)
  result = c.tab.getOrDefault(t.itemId, -1)
  if result < 0:
    if c.inProgress.hasKey(t.itemId):
      layoutError(conf, t, "illegal recursion")
    c.inProgress[t.itemId] = true
    let L = computeLayout(c, conf, t)
    c.inProgress.del t.itemId
    result = c.layouts.len
    c.layouts.add L
    c.tab[t.itemId] = result

proc getLayout*(c: var LayoutCache; conf: ConfigRef; t: PType): VmLayout =
  c.layouts[layoutIdx(c, conf, t)]

proc vmSizeOf*(c: var LayoutCache; conf: ConfigRef; t: PType): int =
  c.layouts[layoutIdx(c, conf, t)].size

proc vmAlignOf*(c: var LayoutCache; conf: ConfigRef; t: PType): int =
  c.layouts[layoutIdx(c, conf, t)].align

type
  Accum = object
    offset, maxAlign: int

proc place(acc: var Accum; size, align: int): int =
  ## Reserves `size` bytes at the next `align`ed offset and returns that offset.
  if align > 0:
    acc.offset = alignTo(acc.offset, align)
    acc.maxAlign = max(acc.maxAlign, align)
  result = acc.offset
  acc.offset += size

proc ensureField(L: var VmLayout; pos, offset: int) =
  if pos >= L.fields.len:
    let old = L.fields.len
    L.fields.setLen pos+1
    for i in old..<pos: L.fields[i] = -1
  L.fields[pos] = offset

proc fieldAlign(c: var LayoutCache; conf: ConfigRef; n: PNode; packed: bool): int =
  ## alignment of the record subtree `n`; needed before a union's offset is known.
  case n.kind
  of nkRecCase:
    result = fieldAlign(c, conf, n[0], packed)
    for i in 1..<n.len:
      result = max(result, fieldAlign(c, conf, n[i].lastSon, packed))
  of nkRecList:
    result = 1
    for ch in n: result = max(result, fieldAlign(c, conf, ch, packed))
  of nkSym:
    result = if packed: 1 else: vmAlignOf(c, conf, n.sym.typ)
    if n.sym.alignment > 0: result = max(result, n.sym.alignment)
  else:
    result = 1

proc layoutFields(c: var LayoutCache; conf: ConfigRef; n: PNode; packed, isUnion: bool;
                  acc: var Accum; L: var VmLayout) =
  case n.kind
  of nkRecCase:
    if isUnion:
      layoutError(conf, n[0].sym.typ, "'case' within a union")
    layoutFields(c, conf, n[0], packed, false, acc, L)
    let unionAlign = if packed: 1 else: fieldAlign(c, conf, n, packed)
    discard place(acc, 0, unionAlign)
    let start = acc.offset
    var finalOffset = start
    for i in 1..<n.len:
      var branch = Accum(offset: start, maxAlign: 1)
      layoutFields(c, conf, n[i].lastSon, packed, false, branch, L)
      if not packed: branch.offset = alignTo(branch.offset, branch.maxAlign)
      finalOffset = max(finalOffset, branch.offset)
      acc.maxAlign = max(acc.maxAlign, branch.maxAlign)
    acc.offset = finalOffset
  of nkRecList:
    if isUnion:
      let start = acc.offset
      var finalOffset = start
      for ch in n:
        var branch = Accum(offset: start, maxAlign: 1)
        layoutFields(c, conf, ch, packed, false, branch, L)
        finalOffset = max(finalOffset, branch.offset)
        acc.maxAlign = max(acc.maxAlign, branch.maxAlign)
      acc.offset = finalOffset
    else:
      for ch in n: layoutFields(c, conf, ch, packed, false, acc, L)
  of nkSym:
    let f = n.sym
    let fi = layoutIdx(c, conf, f.typ)
    var a = if packed: 1 else: c.layouts[fi].align
    if f.alignment > 0: a = max(a, f.alignment)
    ensureField(L, f.position, place(acc, c.layouts[fi].size, a))
  of nkEmpty:
    discard
  else:
    layoutError(conf, n.typ, "unexpected node in object declaration: " & $n.kind)

proc computeLayout(c: var LayoutCache; conf: ConfigRef; t: PType): VmLayout =
  template scalar(s: int) =
    result = VmLayout(size: s, align: s)

  if isNimNodeType(t):
    scalar VmPtrSize
    return
  case t.kind
  of tyBool, tyChar, tyInt8, tyUInt8: scalar 1
  of tyInt16, tyUInt16: scalar 2
  of tyInt32, tyUInt32, tyFloat32: scalar 4
  of tyInt, tyUInt, tyInt64, tyUInt64, tyFloat, tyFloat64, tyFloat128: scalar 8
  of tyEnum: scalar enumSize(conf, t)
  of tySet:
    let s = setSize(conf, t)
    if s == 0: layoutError(conf, t, "set type is too large")
    result = VmLayout(size: s, align: if s <= 8: s else: 1)
  of tyPtr, tyRef, tyPointer, tyCstring, tyNil, tyVar, tyLent, tyTypeDesc,
     tyUntyped, tyTyped:
    scalar VmPtrSize
  of tyProc:
    if t.callConv == ccClosure:
      result = VmLayout(size: 2*VmPtrSize, align: VmPtrSize)
    else:
      scalar VmPtrSize
  of tyString, tySequence, tyOpenArray, tyVarargs:
    # string/seq: (len, p); openArray: (data, len)
    result = VmLayout(size: 2*VmPtrSize, align: VmPtrSize)
  of tyArray:
    let ei = layoutIdx(c, conf, t.elementType)
    let e = (size: c.layouts[ei].size, align: c.layouts[ei].align)
    let len = lengthOrd(conf, t.indexType)
    if len < Zero:
      layoutError(conf, t, "negative array length")
    let n = toInt64(len)
    if e.size > 0 and n > (high(int32) div e.size):
      layoutError(conf, t, "type too big")
    result = VmLayout(size: int(n) * e.size, align: e.align)
  of tyUncheckedArray:
    result = VmLayout(size: 0, align: vmAlignOf(c, conf, t.elementType))
  of tyTuple:
    var acc = Accum(maxAlign: 1)
    result = VmLayout()
    for i, ch in t.ikids:
      let ei = layoutIdx(c, conf, ch)
      result.fields.add place(acc, c.layouts[ei].size, c.layouts[ei].align)
    result.size = alignTo(acc.offset, acc.maxAlign)
    result.align = acc.maxAlign
  of tyObject:
    result = VmLayout()
    var acc = Accum(maxAlign: 1)
    if t.baseClass != nil:
      let base = t.baseClass.skipTypes(skipPtrs)
      let bi = layoutIdx(c, conf, base)
      result.fields = c.layouts[bi].fields
      acc = Accum(offset: c.layouts[bi].size, maxAlign: c.layouts[bi].align)
    elif hasTypeHeader(t):
      discard place(acc, TypeHeaderSize, VmPtrSize)
    let packed = tfPacked in t.flags
    if tfUnion in t.flags and acc.offset != 0:
      layoutError(conf, t, "union type may not have an object header")
    if t.n != nil:
      layoutFields(c, conf, t.n, packed, tfUnion in t.flags, acc, result)
    if packed and t.baseClass == nil: acc.maxAlign = 1
    result.align = acc.maxAlign
    result.size = alignTo(acc.offset, acc.maxAlign)
  of tyVoid, tyEmpty:
    result = VmLayout(size: 0, align: 1)
  else:
    layoutError(conf, t, "unsupported type kind " & $t.kind)

proc fieldOffset*(c: var LayoutCache; conf: ConfigRef; objType: PType; field: PSym): int =
  ## Byte offset of `field` within an object or named tuple of type `objType`.
  let t = skipForLayout(objType)
  let i = layoutIdx(c, conf, t)
  let pos = field.position
  if pos < 0 or pos >= c.layouts[i].fields.len or c.layouts[i].fields[pos] < 0:
    layoutError(conf, t, "unknown field " & field.name.s)
  result = c.layouts[i].fields[pos]

proc elemOffset*(c: var LayoutCache; conf: ConfigRef; tupType: PType; i: int): int =
  ## Byte offset of the `i`-th element of a tuple.
  let li = layoutIdx(c, conf, tupType)
  if i < 0 or i >= c.layouts[li].fields.len:
    layoutError(conf, tupType, "tuple index out of bounds")
  result = c.layouts[li].fields[i]

proc elemSize*(c: var LayoutCache; conf: ConfigRef; t: PType): int =
  ## Element size of an array-like type (array, seq, string, openArray, ...).
  let t = skipForLayout(t)
  case t.kind
  of tyString, tyCstring: result = 1
  of tyArray, tySequence, tyOpenArray, tyVarargs, tyUncheckedArray:
    result = vmSizeOf(c, conf, t.elementType)
  of tyPtr, tyRef:
    result = vmSizeOf(c, conf, t.elementType)
  else:
    layoutError(conf, t, "not an array type")

proc hasPayloads(t: PType; marker: var IntSet): bool =
  ## does a value of type `t` contain strings or seqs (not behind a pointer)?
  let t = skipForLayout(t)
  case t.kind
  of tyString, tySequence: true
  of tyArray: hasPayloads(t.elementType, marker)
  of tyTuple:
    for _, ch in t.ikids:
      if hasPayloads(ch, marker): return true
    false
  of tyObject:
    if marker.containsOrIncl(t.id): return false
    proc fields(n: PNode; marker: var IntSet): bool =
      case n.kind
      of nkSym: hasPayloads(n.sym.typ, marker)
      of nkRecList, nkRecCase, nkOfBranch, nkElse:
        for ch in n:
          if fields(ch, marker): return true
        false
      else: false
    var b = t
    while b != nil:
      if b.n != nil and fields(b.n, marker): return true
      b = if b.baseClass != nil: b.baseClass.skipTypes(skipPtrs) else: nil
    false
  else: false

proc hasPayloads*(t: PType): bool =
  var marker = initIntSet()
  result = hasPayloads(t, marker)
