#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Channel support for threads.
##
## **Note**: This is part of the system module. Do not import it directly.
## To activate thread support compile with the ``--threads:on`` command line switch.
##
## **Note:** Channels are designed for the ``Thread`` type. They are unstable when
## used with ``spawn``
##
## **Note:** The current implementation of message passing does
## not work with cyclic data structures.
##
## **Note:** Channels cannot be passed between threads. Use globals or pass
## them by `ptr`.

when not declared(ThisIsSystem):
  {.error: "You must not import this module explicitly".}

type
  pbytes = ptr array[0.. 0xffff, byte]
  RawChannel {.pure, final.} = object ## msg queue for a thread
    rd, wr, count, mask, maxItems: int
    data: pbytes
    lock: SysLock
    cond: SysCond
    elemType: PNimType
    ready: bool
    region: MemRegion
  PRawChannel = ptr RawChannel
  LoadStoreMode = enum mStore, mLoad
  Channel* {.gcsafe.}[TMsg] = RawChannel ## a channel for thread communication

const ChannelDeadMask = -2

proc initRawChannel(p: pointer, maxItems: int) =
  var c = cast[PRawChannel](p)
  initSysLock(c.lock)
  initSysCond(c.cond)
  c.mask = -1
  c.maxItems = maxItems

proc deinitRawChannel(p: pointer) =
  var c = cast[PRawChannel](p)
  # we need to grab the lock to be safe against sending threads!
  acquireSys(c.lock)
  c.mask = ChannelDeadMask
  deallocOsPages(c.region)
  deinitSys(c.lock)
  deinitSysCond(c.cond)

proc storeAux(dest, src: pointer, mt: PNimType, t: PRawChannel,
              mode: LoadStoreMode) {.benign.}

proc storeAux(dest, src: pointer, n: ptr TNimNode, t: PRawChannel,
              mode: LoadStoreMode) {.benign.} =
  var
    d = cast[ByteAddress](dest)
    s = cast[ByteAddress](src)
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
              mode: LoadStoreMode) =
  template `+!`(p: pointer; x: int): pointer =
    cast[pointer](cast[int](p) +% x)

  var
    d = cast[ByteAddress](dest)
    s = cast[ByteAddress](src)
  sysAssert(mt != nil, "mt == nil")
  case mt.kind
  of tyString:
    if mode == mStore:
      var x = cast[PPointer](dest)
      var s2 = cast[PPointer](s)[]
      if s2 == nil:
        x[] = nil
      else:
        var ss = cast[NimString](s2)
        var ns = cast[NimString](alloc(t.region, ss.len+1 + GenericSeqSize))
        copyMem(ns, ss, ss.len+1 + GenericSeqSize)
        x[] = ns
    else:
      var x = cast[PPointer](dest)
      var s2 = cast[PPointer](s)[]
      if s2 == nil:
        unsureAsgnRef(x, s2)
      else:
        let y = copyDeepString(cast[NimString](s2))
        #echo "loaded ", cast[int](y), " ", cast[string](y)
        unsureAsgnRef(x, y)
        dealloc(t.region, s2)
  of tySequence:
    var s2 = cast[PPointer](src)[]
    var seq = cast[PGenericSeq](s2)
    var x = cast[PPointer](dest)
    if s2 == nil:
      if mode == mStore:
        x[] = nil
      else:
        unsureAsgnRef(x, nil)
    else:
      sysAssert(dest != nil, "dest == nil")
      if mode == mStore:
        x[] = alloc0(t.region, seq.len *% mt.base.size +% GenericSeqSize)
      else:
        unsureAsgnRef(x, newSeq(mt, seq.len))
      var dst = cast[ByteAddress](cast[PPointer](dest)[])
      var dstseq = cast[PGenericSeq](dst)
      dstseq.len = seq.len
      dstseq.reserved = seq.len
      for i in 0..seq.len-1:
        storeAux(
          cast[pointer](dst +% i*% mt.base.size +% GenericSeqSize),
          cast[pointer](cast[ByteAddress](s2) +% i *% mt.base.size +%
                        GenericSeqSize),
          mt.base, t, mode)
      if mode != mStore: dealloc(t.region, s2)
  of tyObject:
    if mt.base != nil:
      storeAux(dest, src, mt.base, t, mode)
    else:
      # copy type field:
      var pint = cast[ptr PNimType](dest)
      pint[] = cast[ptr PNimType](src)[]
    storeAux(dest, src, mt.node, t, mode)
  of tyTuple:
    storeAux(dest, src, mt.node, t, mode)
  of tyArray, tyArrayConstr:
    for i in 0..(mt.size div mt.base.size)-1:
      storeAux(cast[pointer](d +% i*% mt.base.size),
               cast[pointer](s +% i*% mt.base.size), mt.base, t, mode)
  of tyRef:
    var s = cast[PPointer](src)[]
    var x = cast[PPointer](dest)
    if s == nil:
      if mode == mStore:
        x[] = nil
      else:
        unsureAsgnRef(x, nil)
    else:
      #let size = if mt.base.kind == tyObject: cast[ptr PNimType](s)[].size
      #           else: mt.base.size
      if mode == mStore:
        let dyntype = when declared(usrToCell): usrToCell(s).typ
                      else: mt
        let size = dyntype.base.size
        # we store the real dynamic 'ref type' at offset 0, so that
        # no information is lost
        let a = alloc0(t.region, size+sizeof(pointer))
        x[] = a
        cast[PPointer](a)[] = dyntype
        storeAux(a +! sizeof(pointer), s, dyntype.base, t, mode)
      else:
        let dyntype = cast[ptr PNimType](s)[]
        var obj = newObj(dyntype, dyntype.base.size)
        unsureAsgnRef(x, obj)
        storeAux(x[], s +! sizeof(pointer), dyntype.base, t, mode)
        dealloc(t.region, s)
  else:
    copyMem(dest, src, mt.size) # copy raw bits

proc rawSend(q: PRawChannel, data: pointer, typ: PNimType) =
  ## Adds an `item` to the end of the queue `q`.
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

template lockChannel(q, action): untyped =
  acquireSys(q.lock)
  action
  releaseSys(q.lock)

proc sendImpl(q: PRawChannel, typ: PNimType, msg: pointer, noBlock: bool): bool =
  if q.mask == ChannelDeadMask:
    sysFatal(DeadThreadError, "cannot send message; thread died")
  acquireSys(q.lock)
  if q.maxItems > 0:
    # Wait until count is less than maxItems
    if noBlock and q.count >= q.maxItems:
      releaseSys(q.lock)
      return

    while q.count >= q.maxItems:
      waitSysCond(q.cond, q.lock)

  rawSend(q, msg, typ)
  q.elemType = typ
  releaseSys(q.lock)
  signalSysCond(q.cond)
  result = true

proc send*[TMsg](c: var Channel[TMsg], msg: TMsg) {.inline.} =
  ## Sends a message to a thread. `msg` is deeply copied.
  discard sendImpl(cast[PRawChannel](addr c), cast[PNimType](getTypeInfo(msg)), unsafeAddr(msg), false)

proc trySend*[TMsg](c: var Channel[TMsg], msg: TMsg): bool {.inline.} =
  ## Tries to send a message to a thread.
  ##
  ## `msg` is deeply copied. Doesn't block.
  ##
  ## Returns `false` if the message was not sent because number of pending items
  ## in the channel exceeded `maxItems`.
  sendImpl(cast[PRawChannel](addr c), cast[PNimType](getTypeInfo(msg)), unsafeAddr(msg), true)

proc llRecv(q: PRawChannel, res: pointer, typ: PNimType) =
  q.ready = true
  while q.count <= 0:
    waitSysCond(q.cond, q.lock)
  q.ready = false
  if typ != q.elemType:
    releaseSys(q.lock)
    sysFatal(ValueError, "cannot receive message of wrong type")
  rawRecv(q, res, typ)
  if q.maxItems > 0 and q.count == q.maxItems - 1:
    # Parent thread is awaiting in send. Wake it up.
    signalSysCond(q.cond)

proc recv*[TMsg](c: var Channel[TMsg]): TMsg =
  ## Receives a message from the channel `c`.
  ##
  ## This blocks until a message has arrived!
  ## You may use `peek proc <#peek,Channel[TMsg]>`_ to avoid the blocking.
  var q = cast[PRawChannel](addr(c))
  acquireSys(q.lock)
  llRecv(q, addr(result), cast[PNimType](getTypeInfo(result)))
  releaseSys(q.lock)

proc tryRecv*[TMsg](c: var Channel[TMsg]): tuple[dataAvailable: bool,
                                                  msg: TMsg] =
  ## Tries to receive a message from the channel `c`, but this can fail
  ## for all sort of reasons, including contention.
  ##
  ## If it fails, it returns ``(false, default(msg))`` otherwise it
  ## returns ``(true, msg)``.
  var q = cast[PRawChannel](addr(c))
  if q.mask != ChannelDeadMask:
    if tryAcquireSys(q.lock):
      if q.count > 0:
        llRecv(q, addr(result.msg), cast[PNimType](getTypeInfo(result.msg)))
        result.dataAvailable = true
      releaseSys(q.lock)

proc peek*[TMsg](c: var Channel[TMsg]): int =
  ## Returns the current number of messages in the channel `c`.
  ##
  ## Returns -1 if the channel has been closed.
  ##
  ## **Note**: This is dangerous to use as it encourages races.
  ## It's much better to use `tryRecv proc <#tryRecv,Channel[TMsg]>`_ instead.
  var q = cast[PRawChannel](addr(c))
  if q.mask != ChannelDeadMask:
    lockChannel(q):
      result = q.count
  else:
    result = -1

proc open*[TMsg](c: var Channel[TMsg], maxItems: int = 0) =
  ## Opens a channel `c` for inter thread communication.
  ##
  ## The `send` operation will block until number of unprocessed items is
  ## less than `maxItems`.
  ##
  ## For unlimited queue set `maxItems` to 0.
  initRawChannel(addr(c), maxItems)

proc close*[TMsg](c: var Channel[TMsg]) =
  ## Closes a channel `c` and frees its associated resources.
  deinitRawChannel(addr(c))

proc ready*[TMsg](c: var Channel[TMsg]): bool =
  ## Returns true iff some thread is waiting on the channel `c` for
  ## new messages.
  var q = cast[PRawChannel](addr(c))
  result = q.ready

