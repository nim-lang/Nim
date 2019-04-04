#
#
#           The Nim Compiler
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
## code owner: Arne Döring
## e-mail: arne.doering@gmx.net

proc align(address, alignment: BiggestInt): BiggestInt =
  result = (address + (alignment - 1)) and not (alignment - 1)

const
  ## a size is concidered "unknown" when it is an imported type from C
  ## or C++.
  szUnknownSize* = -3
  szIllegalRecursion* = -2
  szUncomputedSize* = -1

proc computeSizeAlign(conf: ConfigRef; typ: PType)

proc computeSubObjectAlign(conf: ConfigRef; n: PNode): BiggestInt =
  ## returns object alignment
  case n.kind
  of nkRecCase:
    assert(n.sons[0].kind == nkSym)
    result = computeSubObjectAlign(conf, n.sons[0])
    for i in 1 ..< sonsLen(n):
      let child = n.sons[i]
      case child.kind
      of nkOfBranch, nkElse:
        let align = computeSubObjectAlign(conf, child.lastSon)
        if align < 0:
          return align
        result = max(result, align)
      else:
        internalError(conf, "computeSubObjectAlign")
  of nkRecList:
    result = 1
    for i, child in n.sons:
      let align = computeSubObjectAlign(conf, n.sons[i])
      if align < 0:
        return align
      result = max(result, align)
  of nkSym:
    computeSizeAlign(conf, n.sym.typ)
    result = n.sym.typ.align
  else:
    result = 1

proc computeObjectOffsetsFoldFunction(conf: ConfigRef; n: PNode,
                                      initialOffset: BiggestInt): tuple[offset, align: BiggestInt] =
  ## ``offset`` is the offset within the object, after the node has been written, no padding bytes added
  ## ``align`` maximum alignment from all sub nodes
  assert n != nil
  if n.typ != nil and n.typ.size == szIllegalRecursion:
    result.offset = szIllegalRecursion
    result.align = szIllegalRecursion
    return

  result.align = 1
  case n.kind
  of nkRecCase:
    assert(n.sons[0].kind == nkSym)
    let (kindOffset, kindAlign) = computeObjectOffsetsFoldFunction(conf, n.sons[0], initialOffset)

    var maxChildAlign: BiggestInt = 0
    for i in 1 ..< sonsLen(n):
      let child = n.sons[i]
      case child.kind
      of nkOfBranch, nkElse:
        # offset parameter cannot be known yet, it needs to know the alignment first
        let align = computeSubObjectAlign(conf, n.sons[i].lastSon)
        if align == szIllegalRecursion:
          result.offset = szIllegalRecursion
          result.align = szIllegalRecursion
          return
        if align == szUnknownSize or maxChildAlign == szUnknownSize:
          maxChildAlign = szUnknownSize
        else:
          maxChildAlign = max(maxChildAlign, align)
      else:
        internalError(conf, "computeObjectOffsetsFoldFunction(record case branch)")
    if maxChildAlign == szUnknownSize:
      result.align  = szUnknownSize
      result.offset = szUnknownSize
    else:
      # the union neds to be aligned first, before the offsets can be assigned
      let kindUnionOffset = align(kindOffset, maxChildAlign)
      var maxChildOffset: BiggestInt = 0
      for i in 1 ..< sonsLen(n):
        let (offset, align) = computeObjectOffsetsFoldFunction(conf, n.sons[i].lastSon, kindUnionOffset)
        maxChildOffset = max(maxChildOffset, offset)
      result.align = max(kindAlign, maxChildAlign)
      result.offset = maxChildOffset
  of nkRecList:
    result.align = 1 # maximum of all member alignments
    var offset = initialOffset
    for i, child in n.sons:
      let (new_offset, align) = computeObjectOffsetsFoldFunction(conf, child, offset)
      if new_offset == szIllegalRecursion:
        result.offset = szIllegalRecursion
        result.align = szIllegalRecursion
        return
      elif new_offset == szUnknownSize or offset == szUnknownSize:
        # if anything is unknown, the rest becomes unknown as well
        offset = szUnknownSize
        result.align = szUnknownSize
      else:
        offset = new_offset
        result.align = max(result.align, align)
    # final alignment
    if offset == szUnknownSize:
      result.offset = szUnknownSize
    else:
      result.offset = align(offset, result.align)
  of nkSym:
    var size = szUnknownSize
    var align = szUnknownSize
    if n.sym.bitsize == 0: # 0 represents bitsize not set
      computeSizeAlign(conf, n.sym.typ)
      size = n.sym.typ.size.int
      align = n.sym.typ.align.int

    result.align = align
    if initialOffset == szUnknownSize or size == szUnknownSize:
      n.sym.offset = szUnknownSize
      result.offset = szUnknownSize
    else:
      n.sym.offset = align(initialOffset, align).int
      result.offset = n.sym.offset + n.sym.typ.size
  else:
    result.align = szUnknownSize
    result.offset = szUnknownSize

proc computePackedObjectOffsetsFoldFunction(conf: ConfigRef; n: PNode, initialOffset: BiggestInt, debug: bool): BiggestInt =
  ## ``result`` is the offset within the object, after the node has been written, no padding bytes added
  case n.kind
  of nkRecCase:
    assert(n.sons[0].kind == nkSym)
    let kindOffset = computePackedObjectOffsetsFoldFunction(conf, n.sons[0], initialOffset, debug)
    # the union neds to be aligned first, before the offsets can be assigned
    let kindUnionOffset = kindOffset
    var maxChildOffset: BiggestInt = kindUnionOffset
    for i in 1 ..< sonsLen(n):
      let offset = computePackedObjectOffsetsFoldFunction(conf, n.sons[i].lastSon, kindUnionOffset, debug)
      if offset < 0:
         result = offset
         break
      maxChildOffset = max(maxChildOffset, offset)
    result = maxChildOffset
  of nkRecList:
    result = initialOffset
    for i, child in n.sons:
      result = computePackedObjectOffsetsFoldFunction(conf, child, result, debug)
      if result == szIllegalRecursion:
        break
  of nkSym:
    var size = szUnknownSize
    if n.sym.bitsize == 0:
      computeSizeAlign(conf, n.sym.typ)
      size = n.sym.typ.size.int

    if initialOffset == szUnknownSize or size == szUnknownSize:
      n.sym.offset = szUnknownSize
      result = szUnknownSize
    else:
      n.sym.offset = int(initialOffset)
      result = initialOffset + n.sym.typ.size
  else:
    result = szUnknownSize

proc computeUnionObjectOffsetsFoldFunction(conf: ConfigRef; n: PNode, debug: bool): tuple[offset, align: BiggestInt] =
  ## ``result`` is the offset from the larget member of the union.
  case n.kind
  of nkRecCase:
    result.offset = szUnknownSize
    result.align = szUnknownSize
    localError(conf, n.info, "Illegal use of ``case`` in union type.")
    #internalError(conf, "Illegal use of ``case`` in union type.")
  of nkRecList:
    var maxChildOffset: BiggestInt = 0
    for i, child in n.sons:
      let (offset, align) = computeUnionObjectOffsetsFoldFunction(conf, child, debug)
      if offset == szIllegalRecursion or align == szIllegalRecursion:
        result.offset = szIllegalRecursion
        result.align = szIllegalRecursion
      elif offset == szUnknownSize or align == szUnknownSize:
        result.offset = szUnknownSize
        result.align = szUnknownSize
      else:
        assert offset != szUncomputedSize
        assert align != szUncomputedSize
        result.offset = max(result.offset, offset)
        result.align = max(result.align, align)
  of nkSym:
    var size = szUnknownSize
    var align = szUnknownSize
    if n.sym.bitsize == 0: # 0 represents bitsize not set
      computeSizeAlign(conf, n.sym.typ)
      size = n.sym.typ.size.int
      align = n.sym.typ.align.int

    result.align = align
    if size == szUnknownSize:
      n.sym.offset = szUnknownSize
      result.offset = szUnknownSize
    else:
      n.sym.offset = 0
      result.offset = n.sym.typ.size
  else:
    result.offset = szUnknownSize
    result.align = szUnknownSize

proc computeSizeAlign(conf: ConfigRef; typ: PType) =
  ## computes and sets ``size`` and ``align`` members of ``typ``
  assert typ != nil
  let hasSize = typ.size != szUncomputedSize
  let hasAlign = typ.align != szUncomputedSize

  if hasSize and hasAlign:
    # nothing to do, size and align already computed
    return

  # This function can only calculate both, size and align at the same time.
  # If one of them is already set this value is stored here and reapplied
  let revertSize = typ.size
  let revertAlign = typ.align
  defer:
    if hasSize:
      typ.size = revertSize
    if hasAlign:
      typ.align = revertAlign

  if typ.size == szIllegalRecursion or typ.align == szIllegalRecursion:
    # we are already computing the size of the type
    # --> illegal recursion in type
    return

  # mark computation in progress
  typ.size = szIllegalRecursion
  typ.align = szIllegalRecursion

  var maxAlign, sizeAccum, length: BiggestInt

  var tk = typ.kind
  case tk
  of tyProc:
    if typ.callConv == ccClosure:
      typ.size = 2 * conf.target.ptrSize
    else:
      typ.size = conf.target.ptrSize
    typ.align = int16(conf.target.ptrSize)

  of tyNil:
    typ.size = conf.target.ptrSize
    typ.align = int16(conf.target.ptrSize)

  of tyString:
    if conf.selectedGC == gcDestructors:
      typ.size = conf.target.ptrSize * 2
    else:
      typ.size = conf.target.ptrSize
    typ.align = int16(conf.target.ptrSize)

  of tyCString, tySequence, tyPtr, tyRef, tyVar, tyLent, tyOpenArray:
    let base = typ.lastSon
    if base == typ:
      # this is not the correct location to detect ``type A = ptr A``
      typ.size = szIllegalRecursion
      typ.align = szIllegalRecursion
      return

    typ.align = int16(conf.target.ptrSize)
    if typ.kind == tySequence and conf.selectedGC == gcDestructors:
      typ.size = conf.target.ptrSize * 2
    else:
      typ.size = conf.target.ptrSize

  of tyArray:
    computeSizeAlign(conf, typ.sons[1])
    let elemSize = typ.sons[1].size
    if elemSize < 0:
      typ.size = elemSize
      typ.align = int16(elemSize)
    else:
      typ.size = lengthOrd(conf, typ.sons[0]) * elemSize
      typ.align = typ.sons[1].align

  of tyUncheckedArray:
    let base = typ.lastSon
    computeSizeAlign(conf, base)
    typ.size = szUnknownSize
    typ.align = base.align
  of tyEnum:
    if firstOrd(conf, typ) < 0:
      typ.size = 4              # use signed int32
      typ.align = 4
    else:
      length = lastOrd(conf, typ)   # BUGFIX: use lastOrd!
      if length + 1 < `shl`(1, 8):
        typ.size = 1
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
      typ.size = szUncomputedSize
      typ.align = szUncomputedSize # in original version this was 1
    else:
      length = lengthOrd(conf, typ.sons[0])
      if length <= 8:
        typ.size = 1
      elif length <= 16:
        typ.size = 2
      elif length <= 32:
        typ.size = 4
      elif length <= 64:
        typ.size = 8
      elif align(length, 8) mod 8 == 0:
        typ.size = align(length, 8) div 8
      else:
        typ.size = align(length, 8) div 8 + 1
    typ.align = int16(typ.size)
  of tyRange:
    computeSizeAlign(conf, typ.sons[0])
    typ.size = typ.sons[0].size
    typ.align = typ.sons[0].align
  of tyTuple:
    maxAlign = 1
    sizeAccum = 0
    for i in countup(0, sonsLen(typ) - 1):
      let child = typ.sons[i]
      computeSizeAlign(conf, child)
      if child.size < 0:
        typ.size = child.size
        typ.align = child.align
        return
      maxAlign = max(maxAlign, child.align)
      sizeAccum = align(sizeAccum, child.align) + child.size
    typ.size = align(sizeAccum, maxAlign)
    typ.align = int16(maxAlign)
  of tyObject:
    var headerSize: BiggestInt
    var headerAlign: int16
    if typ.sons[0] != nil:
      # compute header size
      if conf.cmd == cmdCompileToCpp:
        # if the target is C++ the members of this type are written
        # into the padding byets at the end of the parent type. At the
        # moment it is not supported to calculate that.
        headerSize = szUnknownSize
        headerAlign = szUncomputedSize
      else:
        var st = typ.sons[0]
        while st.kind in skipPtrs:
          st = st.sons[^1]
        computeSizeAlign(conf, st)
        if st.size == szIllegalRecursion:
          typ.size = st.size
          typ.align = st.align
          return
        headerSize = st.size
        headerAlign = st.align
    elif isObjectWithTypeFieldPredicate(typ):
      # this branch is taken for RootObj
      headerSize = conf.target.intSize
      headerAlign = conf.target.intSize.int16
    else:
      headerSize = 0
      headerAlign = 1
    let (offset, align) =
      if tfUnion in typ.flags:
        if tfPacked in typ.flags:
          let info = if typ.sym != nil: typ.sym.info else: unknownLineInfo()
          localError(conf, info, "type may not be packed and union at the same time.")
          (BiggestInt(szUnknownSize), BiggestInt(szUnknownSize))
        else:
          computeUnionObjectOffsetsFoldFunction(conf, typ.n, false)
      elif tfPacked in typ.flags:
        (computePackedObjectOffsetsFoldFunction(conf, typ.n, headerSize, false), BiggestInt(1))
      else:
        computeObjectOffsetsFoldFunction(conf, typ.n, headerSize)
    if offset == szIllegalRecursion:
      typ.size = szIllegalRecursion
      typ.align = szIllegalRecursion
      return
    if offset == szUnknownSize or (
        typ.sym != nil and
        typ.sym.flags * {sfCompilerProc, sfImportc} == {sfImportc}):
      typ.size = szUnknownSize
      typ.align = szUnknownSize
      return
    # header size is already in size from computeObjectOffsetsFoldFunction
    # maxAlign is probably not changed at all from headerAlign
    if tfPacked in typ.flags:
      typ.size = offset
      typ.align = 1
    else:
      typ.align = int16(max(align, headerAlign))
      typ.size = align(offset, typ.align)
  of tyInferred:
    if typ.len > 1:
      computeSizeAlign(conf, typ.lastSon)
      typ.size = typ.lastSon.size
      typ.align = typ.lastSon.align

  of tyGenericInst, tyDistinct, tyGenericBody, tyAlias, tySink, tyOwned:
    computeSizeAlign(conf, typ.lastSon)
    typ.size = typ.lastSon.size
    typ.align = typ.lastSon.align

  of tyTypeClasses:
    if typ.isResolvedUserTypeClass:
      computeSizeAlign(conf, typ.lastSon)
      typ.size = typ.lastSon.size
      typ.align = typ.lastSon.align
    else:
      typ.size = szUncomputedSize
      typ.align = szUncomputedSize

  of tyTypeDesc:
    computeSizeAlign(conf, typ.base)
    typ.size = typ.base.size
    typ.align = typ.base.align

  of tyForward:
    # is this really illegal recursion, or maybe just unknown?
    typ.size = szIllegalRecursion
    typ.align = szIllegalRecursion

  of tyStatic:
    if typ.n != nil:
      computeSizeAlign(conf, typ.lastSon)
      typ.size = typ.lastSon.size
      typ.align = typ.lastSon.align
    else:
      typ.size = szUncomputedSize
      typ.align = szUncomputedSize
  else:
    typ.size = szUncomputedSize
    typ.align = szUncomputedSize
