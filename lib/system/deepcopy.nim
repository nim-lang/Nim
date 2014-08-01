#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

proc genericDeepCopyAux(dest, src: pointer, mt: PNimType) {.gcsafe.}
proc genericDeepCopyAux(dest, src: pointer, n: ptr TNimNode) {.gcsafe.} =
  var
    d = cast[TAddress](dest)
    s = cast[TAddress](src)
  case n.kind
  of nkSlot:
    genericDeepCopyAux(cast[pointer](d +% n.offset), 
                       cast[pointer](s +% n.offset), n.typ)
  of nkList:
    for i in 0..n.len-1:
      genericDeepCopyAux(dest, src, n.sons[i])
  of nkCase:
    var dd = selectBranch(dest, n)
    var m = selectBranch(src, n)
    # reset if different branches are in use; note different branches also
    # imply that's not self-assignment (``x = x``)!
    if m != dd and dd != nil: 
      genericResetAux(dest, dd)
    copyMem(cast[pointer](d +% n.offset), cast[pointer](s +% n.offset),
            n.typ.size)
    if m != nil:
      genericDeepCopyAux(dest, src, m)
  of nkNone: sysAssert(false, "genericDeepCopyAux")

proc genericDeepCopyAux(dest, src: pointer, mt: PNimType) =
  var
    d = cast[TAddress](dest)
    s = cast[TAddress](src)
  sysAssert(mt != nil, "genericDeepCopyAux 2")
  case mt.kind
  of tyString:
    var x = cast[PPointer](dest)
    var s2 = cast[PPointer](s)[]
    if s2 == nil:
      unsureAsgnRef(x, s2)
    else:
      unsureAsgnRef(x, copyString(cast[NimString](s2)))
  of tySequence:
    var s2 = cast[PPointer](src)[]
    var seq = cast[PGenericSeq](s2)      
    var x = cast[PPointer](dest)
    if s2 == nil:
      unsureAsgnRef(x, s2)
      return
    sysAssert(dest != nil, "genericDeepCopyAux 3")
    unsureAsgnRef(x, newSeq(mt, seq.len))
    var dst = cast[TAddress](cast[PPointer](dest)[])
    for i in 0..seq.len-1:
      genericDeepCopyAux(
        cast[pointer](dst +% i*% mt.base.size +% GenericSeqSize),
        cast[pointer](cast[TAddress](s2) +% i *% mt.base.size +%
                     GenericSeqSize),
        mt.base)
  of tyObject:
    # we need to copy m_type field for tyObject, as it could be empty for
    # sequence reallocations:
    var pint = cast[ptr PNimType](dest)
    pint[] = cast[ptr PNimType](src)[]
    if mt.base != nil:
      genericDeepCopyAux(dest, src, mt.base)
    genericDeepCopyAux(dest, src, mt.node)
  of tyTuple:
    genericDeepCopyAux(dest, src, mt.node)
  of tyArray, tyArrayConstr:
    for i in 0..(mt.size div mt.base.size)-1:
      genericDeepCopyAux(cast[pointer](d +% i*% mt.base.size),
                         cast[pointer](s +% i*% mt.base.size), mt.base)
  of tyRef:
    var z: pointer
    if mt.base.deepCopy != nil:
      z = mt.base.deepCopy(cast[PPointer](s)[])
    else:
      # we modify the header of the cell temporarily; instead of the type
      # field we store a forwarding pointer. XXX This is bad when the cloning
      # fails due to OOM etc.
      let x = usrToCell(cast[PPointer](s)[])
      let forw = cast[int](x.typ)
      if (forw and 1) == 1:
        # we stored a forwarding pointer, so let's use that:
        z = cast[pointer](forw and not 1)
      else:
        let realType = x.typ
        z = newObj(realType, realType.base.size)
        x.typ = cast[PNimType](cast[int](z) or 1)
        genericDeepCopyAux(dest, addr(z), realType)
        x.typ = realType
    unsureAsgnRef(cast[PPointer](dest), z)
  of tyPtr:
    # no cycle check here, but also not really required
    if mt.base.deepCopy != nil:
      cast[PPointer](dest)[] = mt.base.deepCopy(cast[PPointer](s)[])
    else:
      cast[PPointer](dest)[] = cast[PPointer](s)[]
  else:
    copyMem(dest, src, mt.size) # copy raw bits

proc genericDeepCopy(dest, src: pointer, mt: PNimType) {.compilerProc.} =
  genericDeepCopyAux(dest, src, mt)

proc genericSeqDeepCopy(dest, src: pointer, mt: PNimType) {.compilerProc.} =
  var src = src
  genericDeepCopy(dest, addr(src), mt)

proc genericDeepCopyOpenArray(dest, src: pointer, len: int,
                            mt: PNimType) {.compilerproc.} =
  var
    d = cast[TAddress](dest)
    s = cast[TAddress](src)
  for i in 0..len-1:
    genericDeepCopy(cast[pointer](d +% i*% mt.base.size),
                    cast[pointer](s +% i*% mt.base.size), mt.base)
