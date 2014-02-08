#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Channel support for threads. **Note**: This is part of the system module.
## Do not import it directly. To activate thread support you need to compile
## with the ``--threads:on`` command line switch.
##
## **Note:** The current implementation of message passing is slow and does
## not work with cyclic data structures.
  
when not defined(NimString): 
  {.error: "You must not import this module explicitly".}

type
  pbytes = ptr array[0.. 0xffff, byte]
  TRawChannel {.pure, final.} = object ## msg queue for a thread
    rd, wr, count, mask: int
    data: pbytes
    lock: TSysLock
    cond: TSysCond
    elemType: PNimType
    ready: bool
    region: TMemRegion
  PRawChannel = ptr TRawChannel
  TLoadStoreMode = enum mStore, mLoad
  TChannel*[TMsg] = TRawChannel ## a channel for thread communication

const ChannelDeadMask = -2

proc initRawChannel(p: pointer) =
  var c = cast[PRawChannel](p)
  initSysLock(c.lock)
  initSysCond(c.cond)
  c.mask = -1

proc deinitRawChannel(p: pointer) =
  var c = cast[PRawChannel](p)
  # we need to grab the lock to be safe against sending threads!
  acquireSys(c.lock)
  c.mask = ChannelDeadMask
  deallocOsPages(c.region)
  deinitSys(c.lock)
  deinitSysCond(c.cond)

proc storeAux(dest, src: pointer, mt: PNimType, t: PRawChannel, 
              mode: TLoadStoreMode)
proc storeAux(dest, src: pointer, n: ptr TNimNode, t: PRawChannel,
              mode: TLoadStoreMode) =
  var
    d = cast[TAddress](dest)
    s = cast[TAddress](src)
  case n.kind
  of nkSlot: storeAux(cast[pointer](d +% n.offset), 
                      cast[pointer](s +% n.offset), n.typ, t, mode)
  of nkList:
    for i in 0..n.len-1: storeAux(dest, src, n.sons[i], t, mode)
  of nkCase:
    copyMem(cast[pointer](d +% n.offset), cast[pointer](s +% n.offset),
            n.typ.size)
    var m = selectBranch(src, n)
    if m != nil: storeAux(dest, src, m, t, mode)
  of nkNone: sysAssert(false, "storeAux")

proc storeAux(dest, src: pointer, mt: PNimType, t: PRawChannel, 
              mode: TLoadStoreMode) =
  var
    d = cast[TAddress](dest)
    s = cast[TAddress](src)
  sysAssert(mt != nil, "mt == nil")
  case mt.Kind
  of tyString:
    if mode == mStore:
      var x = cast[ppointer](dest)
      var s2 = cast[ppointer](s)[]
      if s2 == nil: 
        x[] = nil
      else:
        var ss = cast[NimString](s2)
        var ns = cast[NimString](alloc(t.region, ss.len+1 + GenericSeqSize))
        copyMem(ns, ss, ss.len+1 + GenericSeqSize)
        x[] = ns
    else:
      var x = cast[ppointer](dest)
      var s2 = cast[ppointer](s)[]
      if s2 == nil:
        unsureAsgnRef(x, s2)
      else:
        unsureAsgnRef(x, copyString(cast[NimString](s2)))
        dealloc(t.region, s2)
  of tySequence:
    var s2 = cast[ppointer](src)[]
    var seq = cast[PGenericSeq](s2)
    var x = cast[ppointer](dest)
    if s2 == nil:
      if mode == mStore:
        x[] = nil
      else:
        unsureAsgnRef(x, nil)
    else:
      sysAssert(dest != nil, "dest == nil")
      if mode == mStore:
        x[] = alloc(t.region, seq.len *% mt.base.size +% GenericSeqSize)
      else:
        unsureAsgnRef(x, newObj(mt, seq.len * mt.base.size + GenericSeqSize))
      var dst = cast[taddress](cast[ppointer](dest)[])
      for i in 0..seq.len-1:
        storeAux(
          cast[pointer](dst +% i*% mt.base.size +% GenericSeqSize),
          cast[pointer](cast[TAddress](s2) +% i *% mt.base.size +%
                        GenericSeqSize),
          mt.Base, t, mode)
      var dstseq = cast[PGenericSeq](dst)
      dstseq.len = seq.len
      dstseq.reserved = seq.len
      if mode != mStore: dealloc(t.region, s2)
  of tyObject:
    # copy type field:
    var pint = cast[ptr PNimType](dest)
    # XXX use dynamic type here!
    pint[] = mt
    if mt.base != nil:
      storeAux(dest, src, mt.base, t, mode)
    storeAux(dest, src, mt.node, t, mode)
  of tyTuple:
    storeAux(dest, src, mt.node, t, mode)
  of tyArray, tyArrayConstr:
    for i in 0..(mt.size div mt.base.size)-1:
      storeAux(cast[pointer](d +% i*% mt.base.size),
               cast[pointer](s +% i*% mt.base.size), mt.base, t, mode)
  of tyRef:
    var s = cast[ppointer](src)[]
    var x = cast[ppointer](dest)
    if s == nil:
      if mode == mStore:
        x[] = nil
      else:
        unsureAsgnRef(x, nil)
    else:
      if mode == mStore:
        x[] = alloc(t.region, mt.base.size)
      else:
        # XXX we should use the dynamic type here too, but that is not stored
        # in the inbox at all --> use source[]'s object type? but how? we need
        # a tyRef to the object!
        var obj = newObj(mt, mt.base.size)
        unsureAsgnRef(x, obj)
      storeAux(x[], s, mt.base, t, mode)
      if mode != mStore: dealloc(t.region, s)
  else:
    copyMem(dest, src, mt.size) # copy raw bits

proc rawSend(q: PRawChannel, data: pointer, typ: PNimType) =
  ## adds an `item` to the end of the queue `q`.
  var cap = q.mask+1
  if q.count >= cap:
    # start with capacity for 2 entries in the queue:
    if cap == 0: cap = 1
    var n = cast[pbytes](alloc0(q.region, cap*2*typ.size))
    var z = 0
    var i = q.rd
    var c = q.count
    while c > 0:
      dec c
      copyMem(addr(n[z*typ.size]), addr(q.data[i*typ.size]), typ.size)
      i = (i + 1) and q.mask
      inc z
    if q.data != nil: dealloc(q.region, q.data)
    q.data = n
    q.mask = cap*2 - 1
    q.wr = q.count
    q.rd = 0
  storeAux(addr(q.data[q.wr * typ.size]), data, typ, q, mStore)
  inc q.count
  q.wr = (q.wr + 1) and q.mask

proc rawRecv(q: PRawChannel, data: pointer, typ: PNimType) =
  sysAssert q.count > 0, "rawRecv"
  dec q.count
  storeAux(data, addr(q.data[q.rd * typ.size]), typ, q, mLoad)
  q.rd = (q.rd + 1) and q.mask

template lockChannel(q: expr, action: stmt) {.immediate.} =
  acquireSys(q.lock)
  action
  releaseSys(q.lock)

template sendImpl(q: expr) {.immediate.} =  
  if q.mask == ChannelDeadMask:
    sysFatal(EDeadThread, "cannot send message; thread died")
  acquireSys(q.lock)
  var m: TMsg
  shallowCopy(m, msg)
  var typ = cast[PNimType](getTypeInfo(msg))
  rawSend(q, addr(m), typ)
  q.elemType = typ
  releaseSys(q.lock)
  signalSysCond(q.cond)

proc send*[TMsg](c: var TChannel[TMsg], msg: TMsg) =
  ## sends a message to a thread. `msg` is deeply copied.
  var q = cast[PRawChannel](addr(c))
  sendImpl(q)

proc llRecv(q: PRawChannel, res: pointer, typ: PNimType) =
  # to save space, the generic is as small as possible
  acquireSys(q.lock)
  q.ready = true
  while q.count <= 0:
    waitSysCond(q.cond, q.lock)
  q.ready = false
  if typ != q.elemType:
    releaseSys(q.lock)
    sysFatal(EInvalidValue, "cannot receive message of wrong type")
  rawRecv(q, res, typ)
  releaseSys(q.lock)

proc recv*[TMsg](c: var TChannel[TMsg]): TMsg =
  ## receives a message from the channel `c`. This blocks until
  ## a message has arrived! You may use ``peek`` to avoid the blocking.
  var q = cast[PRawChannel](addr(c))
  llRecv(q, addr(result), cast[PNimType](getTypeInfo(result)))

proc peek*[TMsg](c: var TChannel[TMsg]): int =
  ## returns the current number of messages in the channel `c`. Returns -1
  ## if the channel has been closed.
  var q = cast[PRawChannel](addr(c))
  if q.mask != ChannelDeadMask:
    lockChannel(q):
      result = q.count
  else:
    result = -1

proc open*[TMsg](c: var TChannel[TMsg]) =
  ## opens a channel `c` for inter thread communication.
  initRawChannel(addr(c))

proc close*[TMsg](c: var TChannel[TMsg]) =
  ## closes a channel `c` and frees its associated resources.
  deinitRawChannel(addr(c))

proc ready*[TMsg](c: var TChannel[TMsg]): bool =
  ## returns true iff some thread is waiting on the channel `c` for
  ## new messages.
  var q = cast[PRawChannel](addr(c))
  result = q.ready

