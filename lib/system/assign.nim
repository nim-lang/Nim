#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

proc genericResetAux(dest: Pointer, n: ptr TNimNode)

proc genericAssignAux(dest, src: Pointer, mt: PNimType, shallow: bool)
proc genericAssignAux(dest, src: Pointer, n: ptr TNimNode, shallow: bool) =
  var
    d = cast[TAddress](dest)
    s = cast[TAddress](src)
  case n.kind
  of nkSlot:
    genericAssignAux(cast[pointer](d +% n.offset), 
                     cast[pointer](s +% n.offset), n.typ, shallow)
  of nkList:
    for i in 0..n.len-1:
      genericAssignAux(dest, src, n.sons[i], shallow)
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
      genericAssignAux(dest, src, m, shallow)
  of nkNone: sysAssert(false, "genericAssignAux")
  #else:
  #  echo "ugh memory corruption! ", n.kind
  #  quit 1

proc genericAssignAux(dest, src: Pointer, mt: PNimType, shallow: bool) =
  var
    d = cast[TAddress](dest)
    s = cast[TAddress](src)
  sysAssert(mt != nil, "genericAssignAux 2")
  case mt.Kind
  of tyString:
    var x = cast[ppointer](dest)
    var s2 = cast[ppointer](s)[]
    if s2 == nil or shallow or (
        cast[PGenericSeq](s2).reserved and seqShallowFlag) != 0:
      unsureAsgnRef(x, s2)
    else:
      unsureAsgnRef(x, copyString(cast[NimString](s2)))
  of tySequence:
    var s2 = cast[ppointer](src)[]
    var seq = cast[PGenericSeq](s2)      
    var x = cast[ppointer](dest)
    if s2 == nil or shallow or (seq.reserved and seqShallowFlag) != 0:
      # this can happen! nil sequences are allowed
      unsureAsgnRef(x, s2)
      return
    sysAssert(dest != nil, "genericAssignAux 3")
    unsureAsgnRef(x, newSeq(mt, seq.len))
    var dst = cast[taddress](cast[ppointer](dest)[])
    for i in 0..seq.len-1:
      genericAssignAux(
        cast[pointer](dst +% i*% mt.base.size +% GenericSeqSize),
        cast[pointer](cast[taddress](s2) +% i *% mt.base.size +%
                     GenericSeqSize),
        mt.Base, shallow)
  of tyObject:
    # we need to copy m_type field for tyObject, as it could be empty for
    # sequence reallocations:
    var pint = cast[ptr PNimType](dest)
    pint[] = cast[ptr PNimType](src)[]
    if mt.base != nil:
      genericAssignAux(dest, src, mt.base, shallow)
    genericAssignAux(dest, src, mt.node, shallow)
  of tyTuple:
    genericAssignAux(dest, src, mt.node, shallow)
  of tyArray, tyArrayConstr:
    for i in 0..(mt.size div mt.base.size)-1:
      genericAssignAux(cast[pointer](d +% i*% mt.base.size),
                       cast[pointer](s +% i*% mt.base.size), mt.base, shallow)
  of tyRef:
    unsureAsgnRef(cast[ppointer](dest), cast[ppointer](s)[])
  else:
    copyMem(dest, src, mt.size) # copy raw bits

proc genericAssign(dest, src: Pointer, mt: PNimType) {.compilerProc.} =
  GC_disable()
  genericAssignAux(dest, src, mt, false)
  GC_enable()

proc genericShallowAssign(dest, src: Pointer, mt: PNimType) {.compilerProc.} =
  GC_disable()
  genericAssignAux(dest, src, mt, true)
  GC_enable()

when false:
  proc debugNimType(t: PNimType) =
    if t.isNil: 
      cprintf("nil!")
      return
    var k: cstring
    case t.kind
    of tyBool: k = "bool"
    of tyChar: k = "char"
    of tyEnum: k = "enum"
    of tyArray: k = "array"
    of tyObject: k = "object"
    of tyTuple: k = "tuple"
    of tyRange: k = "range"
    of tyPtr: k = "ptr"
    of tyRef: k = "ref"
    of tyVar: k = "var"
    of tySequence: k = "seq"
    of tyProc: k = "proc"
    of tyPointer: k = "range"
    of tyOpenArray: k = "openarray"
    of tyString: k = "string"
    of tyCString: k = "cstring"
    of tyInt: k = "int"
    of tyInt32: k = "int32"
    else: k = "other"
    cprintf("%s %ld\n", k, t.size)
    debugNimType(t.base)

proc genericSeqAssign(dest, src: Pointer, mt: PNimType) {.compilerProc.} =
  var src = src # ugly, but I like to stress the parser sometimes :-)
  genericAssign(dest, addr(src), mt)

proc genericAssignOpenArray(dest, src: pointer, len: int,
                            mt: PNimType) {.compilerproc.} =
  var
    d = cast[TAddress](dest)
    s = cast[TAddress](src)
  for i in 0..len-1:
    genericAssign(cast[pointer](d +% i*% mt.base.size),
                  cast[pointer](s +% i*% mt.base.size), mt.base)

proc objectInit(dest: Pointer, typ: PNimType) {.compilerProc.}
proc objectInitAux(dest: Pointer, n: ptr TNimNode) =
  var d = cast[TAddress](dest)
  case n.kind
  of nkNone: sysAssert(false, "objectInitAux")
  of nkSLot: objectInit(cast[pointer](d +% n.offset), n.typ)
  of nkList:
    for i in 0..n.len-1:
      objectInitAux(dest, n.sons[i])
  of nkCase:
    var m = selectBranch(dest, n)
    if m != nil: objectInitAux(dest, m)

proc objectInit(dest: Pointer, typ: PNimType) =
  # the generic init proc that takes care of initialization of complex
  # objects on the stack or heap
  var d = cast[TAddress](dest)
  case typ.kind
  of tyObject:
    # iterate over any structural type
    # here we have to init the type field:
    var pint = cast[ptr PNimType](dest)
    pint[] = typ
    objectInitAux(dest, typ.node)
  of tyTuple:
    objectInitAux(dest, typ.node)
  of tyArray, tyArrayConstr:
    for i in 0..(typ.size div typ.base.size)-1:
      objectInit(cast[pointer](d +% i * typ.base.size), typ.base)
  else: discard # nothing to do
  
# ---------------------- assign zero -----------------------------------------

when not defined(nimmixin):
  proc destroy(x: int) = discard
  proc nimDestroyRange*[T](r: T) =
    # internal proc used for destroying sequences and arrays
    for i in countup(0, r.len - 1): destroy(r[i])
else:
  # XXX Why is this exported and no compilerproc?
  proc nimDestroyRange*[T](r: T) =
    # internal proc used for destroying sequences and arrays
    mixin destroy
    for i in countup(0, r.len - 1): destroy(r[i])

proc genericReset(dest: Pointer, mt: PNimType) {.compilerProc.}
proc genericResetAux(dest: Pointer, n: ptr TNimNode) =
  var d = cast[TAddress](dest)
  case n.kind
  of nkNone: sysAssert(false, "genericResetAux")
  of nkSlot: genericReset(cast[pointer](d +% n.offset), n.typ)
  of nkList:
    for i in 0..n.len-1: genericResetAux(dest, n.sons[i])
  of nkCase:
    var m = selectBranch(dest, n)
    if m != nil: genericResetAux(dest, m)
    zeroMem(cast[pointer](d +% n.offset), n.typ.size)
  
proc genericReset(dest: Pointer, mt: PNimType) =
  var d = cast[TAddress](dest)
  sysAssert(mt != nil, "genericReset 2")
  case mt.Kind
  of tyString, tyRef, tySequence:
    unsureAsgnRef(cast[ppointer](dest), nil)
  of tyObject, tyTuple:
    # we don't need to reset m_type field for tyObject
    genericResetAux(dest, mt.node)
  of tyArray, tyArrayConstr:
    for i in 0..(mt.size div mt.base.size)-1:
      genericReset(cast[pointer](d +% i*% mt.base.size), mt.base)
  else:
    zeroMem(dest, mt.size) # set raw bits to zero

proc selectBranch(discVal, L: int, 
                  a: ptr array [0..0x7fff, ptr TNimNode]): ptr TNimNode =
  result = a[L] # a[L] contains the ``else`` part (but may be nil)
  if discVal <% L:
    var x = a[discVal]
    if x != nil: result = x
  
proc FieldDiscriminantCheck(oldDiscVal, newDiscVal: int, 
                            a: ptr array [0..0x7fff, ptr TNimNode], 
                            L: int) {.compilerProc.} =
  var oldBranch = selectBranch(oldDiscVal, L, a)
  var newBranch = selectBranch(newDiscVal, L, a)
  if newBranch != oldBranch and oldDiscVal != 0:
    sysFatal(EInvalidField, "assignment to discriminant changes object branch")
