#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Multi-producer, multi-consumer (MPMC) channel for refc.
##
## See https://github.com/nim-lang/threading/ for a modern replacement for
## destructor-based memory managers (ARC/ORC).
##
## **Note**: This is part of the system module. Do not import it directly.
## To activate thread support compile with the `--threads:on` command line switch.
##
## **Note:** Channels are designed for the `Thread` type. They are not safe to
## use with `spawn` which does not always create a separate thread.
##
## **Note:** The current implementation of message passing does
## not work with cyclic data structures.
##
## **Note:** Channels cannot be passed between threads. Use globals or pass
## them by `ptr`.
##
## Example
## =======
## The following is a simple example of two different ways to use channels:
## blocking and non-blocking.
##
##   ```Nim
##   # Be sure to compile with --threads:on.
##   # The channels and threads modules are part of system and should not be
##   # imported.
##   import std/os
##
##   # Channels can either be:
##   #  - declared at the module level, or
##   #  - passed to procedures by ptr (raw pointer) -- see note on safety.
##   #
##   # For simplicity, in this example a channel is declared at module scope.
##   # Channels are generic, and they include support for passing objects between
##   # threads.
##   # Note that objects passed through channels will be deeply copied.
##   var chan: Channel[string]
##
##   # This proc will be run in another thread using the threads module.
##   proc firstWorker() =
##     chan.send("Hello World!")
##
##   # This is another proc to run in a background thread. This proc takes a while
##   # to send the message since it sleeps for 2 seconds (or 2000 milliseconds).
##   proc secondWorker() =
##     sleep(2000)
##     chan.send("Another message")
##
##   # Initialize the channel.
##   chan.open()
##
##   # Launch the worker.
##   var worker1: Thread[void]
##   createThread(worker1, firstWorker)
##
##   # Block until the message arrives, then print it out.
##   echo chan.recv() # "Hello World!"
##
##   # Wait for the thread to exit before moving on to the next example.
##   worker1.joinThread()
##
##   # Launch the other worker.
##   var worker2: Thread[void]
##   createThread(worker2, secondWorker)
##   # This time, use a non-blocking approach with tryRecv.
##   # Since the main thread is not blocked, it could be used to perform other
##   # useful work while it waits for data to arrive on the channel.
##   while true:
##     let tried = chan.tryRecv()
##     if tried.dataAvailable:
##       echo tried.msg # "Another message"
##       break
##
##     echo "Pretend I'm doing useful work..."
##     # For this example, sleep in order not to flood stdout with the above
##     # message.
##     sleep(400)
##
##   # Wait for the second thread to exit before cleaning up the channel.
##   worker2.joinThread()
##
##   # Clean up the channel.
##   chan.close()
##   ```
##
## Sample output
## -------------
## The program should output something similar to this, but keep in mind that
## exact results may vary in the real world:
##
##     Hello World!
##     Pretend I'm doing useful work...
##     Pretend I'm doing useful work...
##     Pretend I'm doing useful work...
##     Pretend I'm doing useful work...
##     Pretend I'm doing useful work...
##     Another message
##
## Passing Channels Safely
## -----------------------
## To dynamically create channels at runtime, it is recommended to manually
## allocate memory using e.g. `system.create` and pass the resulting pointer
## through thread arguments:
##
##   ```Nim
##   proc worker(channel: ptr Channel[string]) =
##     let greeting = channel[].recv()
##     echo greeting
##
##   proc localChannelExample() =
##     # Use `create` to allocate manually managed memory for channel
##     # The usual warnings about dealing with raw pointers apply. Exercise caution.
##     let channel = create(Channel[string])
##     channel[].open()
##     # Create a thread which will receive the channel as an argument.
##     var thread: Thread[ptr Channel[string]]
##     createThread(thread, worker, channel)
##     channel[].send("Hello from the main thread!")
##     # Wait for the thread to finish reading before closing the channel
##     thread.joinThread()
##     # Call close only once the channel is no longer being used
##     channel[].close()
##     # `dealloc` must be called from the same thread as `create` - use
##     # `createshared`/`deallocShared` when deallocating the channel in another
##     # thread.
##     dealloc(channel)
##
##   localChannelExample() # "Hello from the main thread!"
##   ```

{.push raises: [], gcsafe.}

when not declared(ThisIsSystem):
  {.error: "You must not import this module explicitly".}

type
  pbytes = ptr UncheckedArray[byte]
  RawChannel {.pure, final.} = object
    # Loosely based on std/deques - head / tail are masked on access - their
    # difference is the current length of the queue. Items are written to the
    # tail and read from the head.
    head, tail, maxItems: uint

    data: pbytes # circular buffer
    cap: uint

    lock: SysLock
    notEmpty: SysCond ## receivers wait here
    notFull: SysCond  ## senders wait here (only used if `maxItems > 0`)
    waitingReceivers: int
    when not usesDestructors:
      region: MemRegion
  LoadStoreMode = enum mStore, mLoad
  Channel*[TMsg] {.gcsafe.} = RawChannel ## a channel for thread communication

proc `=copy`(a: var RawChannel, b: RawChannel) {.error.}
const
  ChannelDead = uint.high()
  Unbounded = uint.high()

proc initRawChannel(c: var RawChannel, maxItems: int) =
  # `close` frees `data` (and `region`) but leaves the stale fields behind;
  # reset everything so that a channel can be opened again after `close`.
  assert c.data == nil, "Channel already open"

  zeroMem(addr c, sizeof(c))
  initSysLock(c.lock)
  initSysCond(c.notEmpty)
  if maxItems <= 0:
    c.maxItems = Unbounded
  else:
    initSysCond(c.notFull)
    c.maxItems = maxItems.uint

proc deinitRawChannel(c: var RawChannel) =
  c.cap = ChannelDead
  when not usesDestructors:
    deallocOsPages(c.region)
  else:
    if c.data != nil: deallocShared(c.data)

  deinitSys(c.lock)
  deinitSysCond(c.notEmpty)
  if c.maxItems != Unbounded:
    deinitSysCond(c.notFull)

when not usesDestructors:
  proc storeAux(dest, src: pointer, mt: PNimType, t: var RawChannel,
                mode: static LoadStoreMode)

  proc storeAux(dest, src: pointer, n: ptr TNimNode, t: var RawChannel,
                mode: static LoadStoreMode) =
    var
      d = cast[int](dest)
      s = cast[int](src)
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

  proc storeAux(dest, src: pointer, mt: PNimType, t: var RawChannel,
                mode: static LoadStoreMode) =
    sysAssert(mt != nil, "mt == nil")
    case mt.kind
    of tyString:
      let x = cast[PPointer](dest)
      let s2 = cast[PPointer](src)[]

      when mode == mStore:
        if s2 == nil:
          x[] = nil
        else:
          let ss = cast[NimString](s2)
          let ns = alloc(t.region, GenericSeqSize + ss.len+1)
          copyMem(ns, ss, ss.len+1 + GenericSeqSize)
          x[] = ns
      else:
        if s2 == nil:
          unsureAsgnRef(x, s2)
        else:
          let y = copyDeepString(cast[NimString](s2))
          #echo "loaded ", cast[int](y), " ", cast[string](y)
          unsureAsgnRef(x, y)
          dealloc(t.region, s2)
    of tySequence:
      let s2 = cast[PPointer](src)[]
      let seq = cast[PGenericSeq](s2)
      let x = cast[PPointer](dest)
      if s2 == nil:
        when mode == mStore:
          x[] = nil
        else:
          unsureAsgnRef(x, nil)
      else:
        sysAssert(dest != nil, "dest == nil")
        when mode == mStore:
          x[] = alloc(t.region, align(GenericSeqSize, mt.base.align) +% seq.len *% mt.base.size)
        else:
          unsureAsgnRef(x, newSeq(mt, seq.len))
        let dst = cast[int](cast[PPointer](dest)[])
        let dstseq = cast[PGenericSeq](dst)
        dstseq.len = seq.len
        dstseq.reserved = seq.len
        for i in 0..seq.len-1:
          storeAux(
            cast[pointer](dst +% align(GenericSeqSize, mt.base.align) +% i *% mt.base.size),
            cast[pointer](cast[int](s2) +% align(GenericSeqSize, mt.base.align) +%
                          i *% mt.base.size),
            mt.base, t, mode)
        when mode != mStore: dealloc(t.region, s2)
    of tyObject:
      if mt.base != nil:
        storeAux(dest, src, mt.base, t, mode)
      else:
        # copy type field:
        let pint = cast[ptr PNimType](dest)
        pint[] = cast[ptr PNimType](src)[]
      storeAux(dest, src, mt.node, t, mode)
    of tyTuple:
      storeAux(dest, src, mt.node, t, mode)
    of tyArray, tyArrayConstr:
      let
        d = cast[int](dest)
        s = cast[int](src)
      for i in 0..(mt.size div mt.base.size)-1:
        storeAux(cast[pointer](d +% i *% mt.base.size),
                cast[pointer](s +% i *% mt.base.size), mt.base, t, mode)
    of tyRef:
      let s = cast[PPointer](src)[]
      let x = cast[PPointer](dest)
      if s == nil:
        when mode == mStore:
          x[] = nil
        else:
          unsureAsgnRef(x, nil)
      else:
        #let size = if mt.base.kind == tyObject: cast[ptr PNimType](s)[].size
        #           else: mt.base.size
        when mode == mStore:
          let dyntype = when declared(usrToCell): usrToCell(s).typ
                        else: mt
          let size = dyntype.base.size
          # we store the real dynamic 'ref type' at offset 0, so that
          # no information is lost
          let a = alloc(t.region, size+sizeof(pointer))
          x[] = a
          cast[PPointer](a)[] = dyntype
          storeAux(a +! sizeof(pointer), s, dyntype.base, t, mode)
        else:
          let dyntype = cast[ptr PNimType](s)[]
          let obj = newObj(dyntype, dyntype.base.size)
          unsureAsgnRef(x, obj)
          storeAux(x[], s +! sizeof(pointer), dyntype.base, t, mode)
          dealloc(t.region, s)
    else:
      copyMem(dest, src, mt.size) # copy raw bits

template count(q: RawChannel): uint =
  q.tail - q.head
template mask(q: RawChannel): uint =
  q.cap - 1
template typeInfo(msg: typed): PNimType =
  cast[PNimType](getTypeInfo(msg))
template bytes(pos: uint, typSize: int): int =
  cast[int](pos) *% typSize

proc grow(q: var RawChannel, typSize: int) =
  # See also deques.expandIfNeeded
  # start with capacity for 2 entries in the queue:
  let
    cap = q.cap
    newCap = max(1'u, cap)*2
    newSize = newCap.bytes(typSize)

  when not usesDestructors:
    let n = cast[pbytes](alloc(q.region, newSize))
  else:
    let n = cast[pbytes](allocShared(newSize))

  if cap > 0: # q.count == q.cap!
    let
      mask = cap - 1
      head = q.head and mask
      toCap = cap - head
    copyMem(addr n[0], addr q.data[head.bytes(typSize)], toCap.bytes(typSize))
    if head > 0:
      copyMem(addr n[toCap.bytes(typSize)], addr q.data[0], head.bytes(typSize))

    when not usesDestructors:
      dealloc(q.region, q.data)
    else:
      deallocShared(q.data)
  q.data = n
  q.cap = newCap
  q.tail = cap
  q.head = 0

proc rawSend(q: var RawChannel, data: pointer, typ: PNimType) =
  # Adds an `item` to the end of the queue `q`.
  if q.count >= q.cap:
    q.grow(typ.size)

  let tail = q.tail and q.mask
  when not usesDestructors:
    storeAux(addr q.data[tail.bytes(typ.size)], data, typ, q, mStore)
  else:
    copyMem(addr q.data[tail.bytes(typ.size)], data, typ.size)
  inc q.tail

proc rawRecv(q: var RawChannel, data: pointer, typ: PNimType) =
  # Reads and removes an hitem from the beginning of the queue
  let head = q.head and q.mask
  when not usesDestructors:
    storeAux(data, addr q.data[head.bytes(typ.size)], typ, q, mLoad)
  else:
    copyMem(data, addr q.data[head.bytes(typ.size)], typ.size)
  inc q.head

proc sendImpl(q: var RawChannel, typ: PNimType, msg: pointer, noBlock: static bool): bool =
  if q.cap == ChannelDead: sysFatal(DeadThreadDefect, "channel closed")
  acquireSys(q.lock)
  when noBlock:
    if q.count == q.maxItems:
      releaseSys(q.lock)
      return false
  else:
    while q.count == q.maxItems:
      waitSysCond(q.notFull, q.lock)

  rawSend(q, msg, typ)
  releaseSys(q.lock)
  signalSysCond(q.notEmpty)
  return true

proc recvImpl(q: var RawChannel, res: pointer, typ: PNimType, noBlock: static bool): bool =
  if q.cap == ChannelDead: sysFatal(DeadThreadDefect, "channel closed")
  acquireSys(q.lock)
  when noBlock:
    if q.count == 0:
      releaseSys(q.lock)
      return false
  else:
    inc q.waitingReceivers
    while q.count == 0:
      waitSysCond(q.notEmpty, q.lock)
    dec q.waitingReceivers

  rawRecv(q, res, typ)
  releaseSys(q.lock)
  if q.maxItems != Unbounded:
    signalSysCond(q.notFull)
  return true

when defined(gcDestructors):
  proc send*[TMsg](c: var Channel[TMsg], msg: sink TMsg) {.inline.} =
    ## Sends a message to a thread.
    discard sendImpl(c, typeInfo(msg), addr msg, false)
    wasMoved(msg)

  proc trySend*[TMsg](c: var Channel[TMsg], msg: sink TMsg): bool {.inline.} =
    ## Tries to send a message to a thread.
    ##
    ## Doesn't block.
    ##
    ## Returns `false` if the message was not sent because number of pending items
    ## in the channel exceeded `maxItems`.
    result = sendImpl(c, typeInfo(msg), addr msg, true)
    if result:
      wasMoved(msg)
else:
  proc send*[TMsg](c: var Channel[TMsg], msg: TMsg) {.inline.} =
    ## Sends a message to a thread. `msg` is deeply copied.
    discard sendImpl(c, typeInfo(msg), addr msg, false)

  proc trySend*[TMsg](c: var Channel[TMsg], msg: TMsg): bool {.inline.} =
    ## Tries to send a message to a thread.
    ##
    ## `msg` is deeply copied. Doesn't block.
    ##
    ## Returns `false` if the message was not sent because number of pending items
    ## in the channel exceeded `maxItems`.
    result = sendImpl(c, typeInfo(msg), addr msg, true)

proc recv*[TMsg](c: var Channel[TMsg]): TMsg =
  ## Receives a message from the channel `c`.
  ##
  ## This blocks until a message has arrived!
  ## You may use `tryRecv proc <#tryRecv,Channel[TMsg]>`_ to avoid the blocking.
  result = default(TMsg)
  discard recvImpl(c, addr result, typeInfo(result), false)

proc tryRecv*[TMsg](c: var Channel[TMsg]): tuple[dataAvailable: bool,
                                                  msg: TMsg] =
  ## Tries to receive a message from the channel `c`.
  ##
  ## If the queue is empty, `(false, default(msg))` is returned, otherwise
  ## `(true, msg)`.
  result = default(tuple[dataAvailable: bool, msg: TMsg])
  result.dataAvailable = recvImpl(c, addr result.msg, typeInfo(result.msg), true)

proc peek*[TMsg](c: var Channel[TMsg]): int =
  ## Returns the number of messages in the channel `c` at the time of the call.
  ##
  ## Returns -1 after channel has been closed but may deadlock if called during
  ## closing - unsafe to use for testing if channel is closed.
  ##
  ## By the time this function returns, the state might have changed.
  ##
  ## **Note**: See `tryRecv proc <#tryRecv,Channel[TMsg]>`_ for a non-blocking
  ## recv.
  if c.cap != ChannelDead:
    acquireSys(c.lock)
    result = int c.count
    releaseSys(c.lock)
  else:
    result = -1

proc open*[TMsg](c: var Channel[TMsg], maxItems: int = 0) =
  ## Opens a channel `c` for inter thread communication.
  ##
  ## The `send` operation will block until number of unprocessed items is
  ## less than `maxItems`.
  ##
  ## For unbounded queue set `maxItems` to 0.
  initRawChannel(c, maxItems)

proc close*[TMsg](c: var Channel[TMsg]) =
  ## Closes a channel `c` and frees its associated resources.
  ##
  ## The caller must ensure that there are no threads accessing or waiting on
  ## the channel before closing it.
  deinitRawChannel(c)

proc ready*[TMsg](c: var Channel[TMsg]): bool =
  ## Returns true if some thread was waiting on the channel `c` for
  ## new messages at the time of the call.
  ##
  ## By the time this function returns, the state might have changed.
  c.waitingReceivers > 0

{.pop.}
