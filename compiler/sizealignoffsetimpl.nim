
proc align(address, alignment: BiggestInt): BiggestInt =
  result = (address + (alignment - 1)) and not (alignment - 1)

const
  szNonConcreteType* = -3
  szIllegalRecursion* = -2
  szUnknownSize* = -1

proc computeSizeAlign(typ: PType): void

proc computeSubObjectAlign(n: PNode): BiggestInt =
  ## returns object size and align
  case n.kind
  of nkRecCase:
    assert(n.sons[0].kind == nkSym)
    result = computeSubObjectAlign(n.sons[0])

    for i in 1 ..< sonsLen(n):
      let child = n.sons[i]
      case child.kind
      of nkOfBranch, nkElse:
        let align = computeSubObjectAlign(child.lastSon)
        if align < 0:
          return align
        result = max(result, align)
      else:
        internalError("computeSubObjectAlign")

  of nkRecList:
    result = 1

    for i, child in n.sons:
      let align = computeSubObjectAlign(n.sons[i])
      if align < 0:
        return align

      result = max(result, align)

  of nkSym:
    n.sym.typ.computeSizeAlign
    result = n.sym.typ.align

  else:
    result = 1

proc computeObjectOffsetsFoldFunction(n: PNode, initialOffset: BiggestInt): tuple[offset, align: BiggestInt] =
  ## ``offset`` is the offset within the object, after the node has been written, no padding bytes added
  ## ``align`` maximum alignment from all sub nodes

  result.align = 1
  case n.kind
  of nkRecCase:

    assert(n.sons[0].kind == nkSym)
    let (kindOffset, kindAlign) = computeObjectOffsetsFoldFunction(n.sons[0], initialOffset)

    var maxChildAlign: BiggestInt = 0

    for i in 1 ..< sonsLen(n):
      let child = n.sons[i]
      case child.kind
      of nkOfBranch, nkElse:
        # offset parameter cannot be known yet, it needs to know the alignment first
        let align = computeSubObjectAlign(n.sons[i].lastSon)

        if align < 0:
          result.offset  = align
          result.align = align
          return

        maxChildAlign = max(maxChildAlign, align)
      else:
        internalError("computeObjectOffsetsFoldFunction(record case branch)")

    # the union neds to be aligned first, before the offsets can be assigned
    let kindUnionOffset = align(kindOffset, maxChildAlign)

    var maxChildOffset: BiggestInt = 0
    for i in 1 ..< sonsLen(n):
      let (offset, align) = computeObjectOffsetsFoldFunction(n.sons[i].lastSon, kindUnionOffset)
      maxChildOffset = max(maxChildOffset, offset)

    result.align = max(kindAlign, maxChildAlign)
    result.offset  = maxChildOffset

  of nkRecList:

    result.align = 1 # maximum of all member alignments

    var offset = initialOffset

    for i, child in n.sons:
      let (new_offset, align) = computeObjectOffsetsFoldFunction(child, offset)

      if new_offset < 0:
        result.offset  = new_offset
        result.align = align
        return

      offset = new_offset

      result.align = max(result.align, align)

    # final alignment
    result.offset  = align(offset, result.align)

  of nkSym:
    n.sym.typ.computeSizeAlign
    let size  = n.sym.typ.size
    let align = n.sym.typ.align
    result.align  = align
    n.sym.offset = align(initialOffset, align).int
    result.offset = n.sym.offset + n.sym.typ.size

  else:
    result.align = 1
    result.offset  = szNonConcreteType


var recDepth = 0
proc computePackedObjectOffsetsFoldFunction(n: PNode, initialOffset: BiggestInt, debug : bool): BiggestInt =
  ## ``result`` is the offset within the object, after the node has been written, no padding bytes added
  recDepth += 1
  defer:
    recDepth -= 1

  if debug:
    if n.kind == nkSym:
      echo repeat("--", recDepth) & "> ", initialOffset, "  ", n.kind, "  ", n.sym.name.s
    else:
      echo repeat("--", recDepth) & "> ", initialOffset, "  ", n.kind

  case n.kind
  of nkRecCase:

    assert(n.sons[0].kind == nkSym)
    let kindOffset = computePackedObjectOffsetsFoldFunction(n.sons[0], initialOffset, debug)
    # the union neds to be aligned first, before the offsets can be assigned
    let kindUnionOffset = kindOffset

    var maxChildOffset: BiggestInt = kindUnionOffset
    for i in 1 ..< sonsLen(n):
      let offset = computePackedObjectOffsetsFoldFunction(n.sons[i].lastSon, kindUnionOffset, debug)
      maxChildOffset = max(maxChildOffset, offset)

    if debug:
      echo repeat("  ", recDepth), "result: ", maxChildOffset

    result  = maxChildOffset

  of nkRecList:
    result = initialOffset
    for i, child in n.sons:
      result = computePackedObjectOffsetsFoldFunction(child, result, debug)
      if result < 0:
        break

  of nkSym:
    n.sym.typ.computeSizeAlign
    n.sym.offset = initialOffset.int
    result = n.sym.offset + n.sym.typ.size

  else:
    result = szNonConcreteType

# TODO this one needs an alignment map of the individual types

proc computeSizeAlign(typ: PType): void =
  ## computes and sets ``size`` and ``align`` members of ``typ``

  if typ.size >= 0:
    # nothing to do, size already computed
    return

  if typ.size == szIllegalRecursion:
    # we are already computing the size of the type
    # --> illegal recursion in type
    typ.align = szIllegalRecursion
    return
  typ.size = szIllegalRecursion # mark as being computed

  var maxAlign, sizeAccum, length: BiggestInt

  case typ.kind
  of tyInt, tyUInt:
    typ.size = intSize
    typ.align = int16(intSize)

  of tyInt8, tyUInt8, tyBool, tyChar:
    typ.size = 1
    typ.align = 1

  of tyInt16, tyUInt16:
    typ.size = 2
    typ.align = 2

  of tyInt32, tyUInt32, tyFloat32:
    typ.size = 4
    typ.align = 4

  of tyInt64, tyUInt64, tyFloat64:
    typ.size = 8
    typ.align = 8

  of tyFloat128:
    typ.size  = 16
    typ.align = 16

  of tyFloat:
    typ.size = floatSize
    typ.align = int16(floatSize)


  of tyProc:
    if typ.callConv == ccClosure:
      typ.size = 2 * ptrSize
    else:
      typ.size = ptrSize
    typ.align = int16(ptrSize)

  of tyNil, tyCString, tyString, tySequence, tyPtr, tyRef, tyVar, tyOpenArray:
    let base = typ.lastSon
    if base == typ or (base.kind == tyTuple and base.size==szIllegalRecursion):
      typ.size  = szIllegalRecursion
      typ.align = szIllegalRecursion
    else:
      typ.size  = ptrSize
      typ.align = int16(ptrSize)

  of tyArray:
    typ.sons[1].computeSizeAlign
    let elemSize = typ.sons[1].size
    if elemSize < 0:
      typ.size  = elemSize
      typ.align = int16(elemSize)
    else:
      typ.size  = lengthOrd(typ.sons[0]) * elemSize
      typ.align = typ.sons[1].align

  of tyEnum:
    if firstOrd(typ) < 0:
      typ.size  = 4              # use signed int32
      typ.align = 4
    else:
      length = lastOrd(typ)   # BUGFIX: use lastOrd!
      if length + 1 < `shl`(1, 8):
        typ.size  = 1
        typ.align = 1
      elif length + 1 < `shl`(1, 16):
        typ.size = 2
        typ.align = 2
      elif length + 1 < `shl`(BiggestInt(1), 32):
        typ.size = 4
        typ.align = 4
      else:
        typ.size = 8
        typ.align = 8

  of tySet:
    if typ.sons[0].kind == tyGenericParam:
      typ.size  = szUnknownSize
      typ.align = szUnknownSize # in original version this was 1
    else:
      length = lengthOrd(typ.sons[0])
      if length <= 8:
        typ.size = 1
      elif length <= 16:
        typ.size = 2
      elif length <= 32:
        typ.size = 4
      elif length <= 64:
        typ.size = 8
      elif align(length, 8) mod 8 == 0:
        typ.size  = align(length, 8) div 8
      else:
        typ.size = align(length, 8) div 8 + 1
    typ.align = int16(typ.size)

  of tyRange:
    typ.sons[0].computeSizeAlign
    typ.size = typ.sons[0].size
    typ.align = typ.sons[0].align

  of tyTuple:
    maxAlign = 1
    sizeAccum = 0

    for i in countup(0, sonsLen(typ) - 1):
      let child = typ.sons[i]
      child.computeSizeAlign

      if child.size < 0:
        typ.size  = child.size
        typ.align = child.align
        return

      maxAlign = max(maxAlign, child.align)
      sizeAccum = align(sizeAccum, child.align) + child.size

    typ.size  = align(sizeAccum, maxAlign)
    typ.align = int16(maxAlign)

  of tyObject:
    var headerSize : BiggestInt
    var headerAlign: int16

    if typ.sons[0] != nil:
      var st = typ.sons[0]

      while st.kind in skipPtrs:
        st = st.sons[^1]

      st.computeSizeAlign

      if st.size < 0:
        typ.size = st.size
        typ.align = st.align
        return

      headerSize  = st.size
      headerAlign = st.align

    elif isObjectWithTypeFieldPredicate(typ):
      # this branch is taken for RootObj
      headerSize = intSize
      headerAlign = intSize.int16

    else:
      headerSize  = 0
      headerAlign = 1

    if tfPacked in typ.flags and typ.sym.name.s == "RecursiveStuff":
      debug typ

    let (offset, align) =
      if tfPacked in typ.flags:
        (computePackedObjectOffsetsFoldFunction(typ.n, headerSize, tfPacked in typ.flags and typ.sym.name.s == "RecursiveStuff"), BiggestInt(1))
      else:
        computeObjectOffsetsFoldFunction(typ.n, headerSize)

    if offset < 0:
      typ.size = offset
      typ.align = int16(align)
      return

    # header size is already in size from computeObjectOffsetsFoldFunction
    # maxAlign is probably not changed at all from headerAlign

    if tfPacked in typ.flags:
      typ.size = offset
      typ.align = 1
    else:
      typ.size  = align(offset, typ.align)
      typ.align = int16(max(align, headerAlign))

  of tyInferred:
    if typ.len > 1:
      typ.lastSon.computeSizeAlign
      typ.size = typ.lastSon.size
      typ.align = typ.lastSon.align

  of tyGenericInst, tyDistinct, tyGenericBody, tyAlias:
    typ.lastSon.computeSizeAlign
    typ.size = typ.lastSon.size
    typ.align = typ.lastSon.align

  of tyTypeClasses:
    if typ.isResolvedUserTypeClass:
      typ.lastSon.computeSizeAlign
      typ.size = typ.lastSon.size
      typ.align = typ.lastSon.align
    else:
      typ.size = szUnknownSize
      typ.align = szUnknownSize

  of tyTypeDesc:
    typ.base.computeSizeAlign
    typ.size = typ.base.size
    typ.align = typ.base.align

  of tyForward:
    # is this really illegal recursion, or maybe just unknown?
    typ.size = szIllegalRecursion
    typ.align = szIllegalRecursion

  of tyStatic:
    if typ.n != nil:
      typ.lastSon.computeSizeAlign
      typ.size = typ.lastSon.size
      typ.align = typ.lastSon.align
    else:
      typ.size = szUnknownSize
      typ.align = szUnknownSize
  else:
    typ.size  = szUnknownSize
    typ.align = szUnknownSize
