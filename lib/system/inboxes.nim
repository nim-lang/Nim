#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Message passing for threads. **Note**: This is part of the system module.
## Do not import it directly. To activate thread support you need to compile
## with the ``--threads:on`` command line switch.
##
## **Note:** The current implementation of message passing is slow and does
## not work with cyclic data structures.

type
  pbytes = ptr array[0.. 0xffff, byte]
  TInbox {.pure, final.} = object ## msg queue for a thread
    rd, wr, count, mask: int
    data: pbytes
    lock: TSysLock
    cond: TSysCond
    elemType: PNimType
    ready: bool
    region: TMemRegion
  PInbox = ptr TInbox
  TLoadStoreMode = enum mStore, mLoad

const ThreadDeadMask = -2

proc initInbox(p: pointer) =
  var inbox = cast[PInbox](p)
  initSysLock(inbox.lock)
  initSysCond(inbox.cond)
  inbox.mask = -1

proc freeInbox(p: pointer) =
  var inbox = cast[PInbox](p)
  # we need to grab the lock to be save against sending threads!
  acquireSys(inbox.lock)
  inbox.mask = ThreadDeadMask
  deallocOsPages(inbox.region)
  deinitSys(inbox.lock)
  deinitSysCond(inbox.cond)

proc storeAux(dest, src: Pointer, mt: PNimType, t: PInbox, mode: TLoadStoreMode)
proc storeAux(dest, src: Pointer, n: ptr TNimNode, t: PInbox,
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
  of nkNone: sysAssert(false)

proc storeAux(dest, src: Pointer, mt: PNimType, t: PInbox, 
              mode: TLoadStoreMode) =
  var
    d = cast[TAddress](dest)
    s = cast[TAddress](src)
  sysAssert(mt != nil)
  case mt.Kind
  of tyString:
    if mode == mStore:
      var x = cast[ppointer](dest)
      var s2 = cast[ppointer](s)[]
      if s2 == nil: 
        x[] = nil
      else:
        var ss = cast[NimString](s2)
        var ns = cast[NimString](Alloc(t.region, ss.len+1 + GenericSeqSize))
        copyMem(ns, ss, ss.len+1 + GenericSeqSize)
        x[] = ns
    else:
      var x = cast[ppointer](dest)
      var s2 = cast[ppointer](s)[]
      if s2 == nil:
        unsureAsgnRef(x, s2)
      else:
        unsureAsgnRef(x, copyString(cast[NimString](s2)))
        Dealloc(t.region, s2)
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
      sysAssert(dest != nil)
      if mode == mStore:
        x[] = Alloc(t.region, seq.len *% mt.base.size +% GenericSeqSize)
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
      dstseq.space = seq.len
      if mode != mStore: Dealloc(t.region, s2)
  of tyObject:
    # copy type field:
    var pint = cast[ptr PNimType](dest)
    # XXX use dynamic type here!
    pint[] = mt
    storeAux(dest, src, mt.node, t, mode)
  of tyTuple, tyPureObject:
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
        x[] = Alloc(t.region, mt.base.size)
      else:
        # XXX we should use the dynamic type here too, but that is not stored in
        # the inbox at all --> use source[]'s object type? but how? we need a
        # tyRef to the object!
        var obj = newObj(mt.base, mt.base.size)
        unsureAsgnRef(x, obj)
      storeAux(x[], s, mt.base, t, mode)
      if mode != mStore: Dealloc(t.region, s)
  else:
    copyMem(dest, src, mt.size) # copy raw bits

proc rawSend(q: PInbox, data: pointer, typ: PNimType) =
  ## adds an `item` to the end of the queue `q`.
  var cap = q.mask+1
  if q.count >= cap:
    # start with capicity for 2 entries in the queue:
    if cap == 0: cap = 1
    var n = cast[pbytes](Alloc0(q.region, cap*2*typ.size))
    var z = 0
    var i = q.rd
    var c = q.count
    while c > 0:
      dec c
      copyMem(addr(n[z*typ.size]), addr(q.data[i*typ.size]), typ.size)
      i = (i + 1) and q.mask
      inc z
    if q.data != nil: Dealloc(q.region, q.data)
    q.data = n
    q.mask = cap*2 - 1
    q.wr = q.count
    q.rd = 0
  storeAux(addr(q.data[q.wr * typ.size]), data, typ, q, mStore)
  inc q.count
  q.wr = (q.wr + 1) and q.mask

proc rawRecv(q: PInbox, data: pointer, typ: PNimType) =
  assert q.count > 0
  dec q.count
  storeAux(data, addr(q.data[q.rd * typ.size]), typ, q, mLoad)
  q.rd = (q.rd + 1) and q.mask

template lockInbox(q: expr, action: stmt) =
  acquireSys(q.lock)
  action
  releaseSys(q.lock)

template sendImpl(q: expr) =  
  if q.mask == ThreadDeadMask:
    raise newException(EDeadThread, "cannot send message; thread died")
  acquireSys(q.lock)
  var m: TMsg
  shallowCopy(m, msg)
  var typ = cast[PNimType](getTypeInfo(msg))
  rawSend(q, addr(m), typ)
  q.elemType = typ
  releaseSys(q.lock)
  SignalSysCond(q.cond)

proc send*[TMsg](receiver: var TThread[TMsg], msg: TMsg) =
  ## sends a message to a thread. `msg` is deeply copied.
  var q = cast[PInbox](getInBoxMem(receiver))
  sendImpl(q)

proc send*[TMsg](receiver: TThreadId[TMsg], msg: TMsg) =
  ## sends a message to a thread. `msg` is deeply copied.
  var q = cast[PInbox](getInBoxMem(receiver[]))
  sendImpl(q)

proc llRecv(q: PInbox, res: pointer, typ: PNimType) =
  # to save space, the generic is as small as possible
  acquireSys(q.lock)
  q.ready = true
  while q.count <= 0:
    WaitSysCond(q.cond, q.lock)
  q.ready = false
  if typ != q.elemType:
    releaseSys(q.lock)
    raise newException(EInvalidValue, "cannot receive message of wrong type")
  rawRecv(q, res, typ)
  releaseSys(q.lock)

proc recv*[TMsg](): TMsg =
  ## receives a message from its internal message queue. This blocks until
  ## a message has arrived! You may use ``peek`` to avoid the blocking.
  var q = cast[PInbox](getInBoxMem())
  llRecv(q, addr(result), cast[PNimType](getTypeInfo(result)))

proc peek*(): int =
  ## returns the current number of messages in the inbox.
  var q = cast[PInbox](getInBoxMem())
  lockInbox(q):
    result = q.count

proc peek*[TMsg](t: var TThread[TMsg]): int =
  ## returns the current number of messages in the inbox of thread `t`.
  var q = cast[PInbox](getInBoxMem(t))
  if q.mask != ThreadDeadMask:
    lockInbox(q):
      result = q.count

proc ready*[TMsg](t: var TThread[TMsg]): bool =
  ## returns true iff the thread `t` is waiting on ``recv`` for new messages.
  var q = cast[PInbox](getInBoxMem(t))
  result = q.ready

# ---------------------- channel support -------------------------------------

type
  TChannel*[TMsg] = TInbox ## a channel for thread communication
  TChannelId*[TMsg] = ptr TChannel[TMsg] ## the current implementation uses
                                         ## a pointer as a channel ID.

proc open*[TMsg](c: var TChannel[TMsg]) =
  ## opens a channel `c` for inter thread communication.
  initInbox(addr(c))

proc close*[TMsg](c: var TChannel[TMsg]) =
  ## closes a channel `c` and frees its associated resources.
  freeInbox(addr(c))

proc channelId*[TMsg](c: var TChannel[TMsg]): TChannelId[TMsg] {.inline.} =
  ## returns the channel ID of `c`.
  result = addr(c)
  
proc send*[TMsg](c: var TChannel[TMsg], msg: TMsg) =
  ## sends a message to a channel. `msg` is deeply copied.
  var q = cast[PInbox](addr(c))
  sendImpl(q)

proc send*[TMsg](c: TChannelId[TMsg], msg: TMsg) =
  ## sends a message to a thread. `msg` is deeply copied.
  var q = cast[PInbox](c)
  sendImpl(q)

proc peek*[TMsg](c: var TChannel[TMsg]): int =
  ## returns the current number of messages in the channel `c`.
  var q = cast[PInbox](addr(c))
  lockInbox(q):
    result = q.count

proc peek*[TMsg](c: TChannelId[TMsg]): int =
  ## returns the current number of messages in the channel `c`.
  var q = cast[PInbox](c)
  lockInbox(q):
    result = q.count

proc recv*[TMsg](c: TChannelId[TMsg]): TMsg =
  ## receives a message from the channel `c`. This blocks until
  ## a message has arrived! You may use ``peek`` to avoid the blocking.
  var q = cast[PInbox](c)
  llRecv(q, addr(result), cast[PNimType](getTypeInfo(result)))

proc recv*[TMsg](c: var TChannel[TMsg]): TMsg =
  ## receives a message from the channel `c`. This blocks until
  ## a message has arrived! You may use ``peek`` to avoid the blocking.
  var q = cast[PInbox](addr(c))
  llRecv(q, addr(result), cast[PNimType](getTypeInfo(result)))

