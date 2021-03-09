#
#
#           The Nim Compiler
#        (c) Copyright 2021 Mratsim & Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# Based on https://github.com/mratsim/weave/blob/5696d94e6358711e840f8c0b7c684fcc5cbd4472/unused/channels/channels_legacy.nim


## This module only works with `--gc:arc` or `--gc:orc`.
##
## .. warning:: This module is experimental and its interface may change.
##
## The following is a simple example of two different ways to use channels:
## blocking and non-blocking.
## 

runnableExamples("--threads:on --gc:orc"):
  import std/os

  # In this example a channel is declared at module scope.
  # Channels are generic, and they include support for passing objects between
  # threads.
  # Note that isolated data passed through channels is moved around.
  var chan = initChan[string]()

  # This proc will be run in another thread using the threads module.
  proc firstWorker() =
    chan.send("Hello World!")

  # This is another proc to run in a background thread. This proc takes a while
  # to send the message since it sleeps for 2 seconds (or 2000 milliseconds).
  proc secondWorker() =
    sleep(2000)
    chan.send("Another message")

  # Launch the worker.
  var worker1: Thread[void]
  createThread(worker1, firstWorker)

  # Block until the message arrives, then print it out.
  var dest = ""
  chan.recv(dest)
  assert dest == "Hello World!"

  # Wait for the thread to exit before moving on to the next example.
  worker1.joinThread()

  # Launch the other worker.
  var worker2: Thread[void]
  createThread(worker2, secondWorker)
  # This time, use a non-blocking approach with tryRecv.
  # Since the main thread is not blocked, it could be used to perform other
  # useful work while it waits for data to arrive on the channel.
  var messages: seq[string]
  while true:
    var msg = ""
    if chan.tryRecv(msg):
      messages.add msg # "Another message"
      break

    messages.add "Pretend I'm doing useful work..."
    # For this example, sleep in order not to flood stdout with the above
    # message.
    sleep(400)

  # Wait for the second thread to exit before cleaning up the channel.
  worker2.joinThread()

  # Clean up the channel.
  assert chan.close()

  assert messages[^1] == "Another message"
  assert messages.len >= 2


when not defined(gcArc) and not defined(gcOrc) and not defined(nimdoc):
  {.error: "This channel implementation requires --gc:arc or --gc:orc".}

import std/[locks, atomics, isolation]
import system/ansi_c

# Channel (Shared memory channels)
# ----------------------------------------------------------------------------------

const
  CacheLineSize {.intdefine.} = 64 # TODO: some Samsung phone have 128 cache-line
  ChannelCacheSize* {.intdefine.} = 100

type
  # ChannelBufKind = enum
  #   Unbuffered # Unbuffered (blocking) channel
  #   Buffered   # Buffered (non-blocking channel)

  ChannelKind* = enum
    Mpmc # Multiple producer, multiple consumer
    Mpsc # Multiple producer, single consumer
    Spsc # Single producer, single consumer

  ChannelRaw* = ptr ChannelObj
  ChannelObj = object
    headLock, tailLock: Lock
    notFullCond: Cond
    notEmptyCond: Cond
    owner: int32
    impl: ChannelKind
    closed: Atomic[bool]
    size: int32
    itemsize: int32 # up to itemsize bytes can be exchanged over this channel
    head: int32     # Items are taken from head and new items are inserted at tail
    pad: array[CacheLineSize-sizeof(int32), byte] # Separate by at-least a cache line
    tail: int32
    buffer: ptr UncheckedArray[byte]

  # TODO: Replace this cache by generic ObjectPools
  #       We can use HList or a Table or thread-local globals
  #       to keep the list of object pools
  ChannelCache = ptr ChannelCacheObj
  ChannelCacheObj = object
    next: ChannelCache
    chanSize: int32
    chanN: int32
    chanKind: ChannelKind
    numCached: int32
    cache: array[ChannelCacheSize, ChannelRaw]

# ----------------------------------------------------------------------------------

template incmod(idx, size: int32): int32 =
  (idx + 1) mod size

# template decmod(idx, size: int32): int32 =
#   (idx - 1) mod size

template numItems(chan: ChannelRaw): int32 =
  (chan.size + chan.tail - chan.head) mod chan.size

template isFull(chan: ChannelRaw): bool =
  chan.numItems() == chan.size - 1

template isEmpty(chan: ChannelRaw): bool =
  chan.head == chan.tail

# Unbuffered / synchronous channels
# ----------------------------------------------------------------------------------

template numItemsUnbuf(chan: ChannelRaw): int32 =
  chan.head

template isFullUnbuf(chan: ChannelRaw): bool =
  chan.head == 1

template isEmptyUnbuf(chan: ChannelRaw): bool =
  chan.head == 0

# ChannelRaw kinds
# ----------------------------------------------------------------------------------

# func isBuffered(chan: ChannelRaw): bool =
#   chan.size - 1 > 0

func isUnbuffered(chan: ChannelRaw): bool =
  assert chan.size >= 0
  chan.size - 1 == 0

# ChannelRaw status and properties
# ----------------------------------------------------------------------------------

proc isClosed(chan: ChannelRaw): bool {.inline.} = load(chan.closed, moRelaxed)
# proc capacity(chan: ChannelRaw): int32 {.inline.} = chan.size - 1

proc peek*(chan: ChannelRaw): int32 =
  (if chan.isUnbuffered(): numItemsUnbuf(chan) else: numItems(chan))

# Per-thread channel cache
# ----------------------------------------------------------------------------------

var channelCache {.threadvar.}: ChannelCache
var channelCacheLen {.threadvar.}: int32

proc allocChannelCache(size, n: int32, impl: ChannelKind): bool =
  ## Allocate a free list for storing channels of a given type
  var p = channelCache

  # Avoid multiple free lists for the exact same type of channel
  while not p.isNil:
    if size == p.chanSize and n == p.chanN and impl == p.chanKind:
      return false
    p = p.next

  p = cast[ptr ChannelCacheObj](c_malloc(csize_t sizeof(ChannelCacheObj)))
  if p.isNil:
    raise newException(OutOfMemDefect, "Could not allocate memory")

  p.chanSize = size
  p.chanN = n
  p.chanKind = impl
  p.numCached = 0

  p.next = channelCache
  channelCache = p
  inc channelCacheLen
  result = true

proc freeChannelCache*() =
  ## Frees the entire channel cache, including all channels
  var p = channelCache
  var q: ChannelCache

  while not p.isNil:
    q = p.next
    for i in 0 ..< p.numCached:
      let chan = p.cache[i]
      if not chan.buffer.isNil:
        c_free(chan.buffer)
      deinitLock(chan.headLock)
      deinitLock(chan.tailLock)
      deinitCond(chan.notFullCond)
      deinitCond(chan.notEmptyCond)
      c_free(chan)
    c_free(p)
    dec channelCacheLen
    p = q

  assert(channelCacheLen == 0)
  channelCache = nil

# Channels memory ops
# ----------------------------------------------------------------------------------

proc allocChannel*(size, n: int32, impl: ChannelKind): ChannelRaw =
  when ChannelCacheSize > 0:
    var p = channelCache

    while not p.isNil:
      if size == p.chanSize and n == p.chanN and impl == p.chanKind:
        # Check if free list contains channel
        if p.numCached > 0:
          dec p.numCached
          result = p.cache[p.numCached]
          assert(result.isEmpty())
          return
        else:
          # All the other lists in cache won't match
          break
      p = p.next

  result = cast[ChannelRaw](c_malloc(csize_t sizeof(ChannelObj)))
  if result.isNil:
    raise newException(OutOfMemDefect, "Could not allocate memory")

  # To buffer n items, we allocate for n+1
  result.buffer = cast[ptr UncheckedArray[byte]](c_malloc(csize_t (n+1)*size))
  if result.buffer.isNil:
    raise newException(OutOfMemDefect, "Could not allocate memory")

  initLock(result.headLock)
  initLock(result.tailLock)
  initCond(result.notFullCond)
  initCond(result.notEmptyCond)

  result.owner = -1 # TODO
  result.impl = impl
  result.closed.store(false, moRelaxed) # We don't need atomic here, how to?
  result.size = n+1
  result.itemsize = size
  result.head = 0
  result.tail = 0

  when ChannelCacheSize > 0:
    # Allocate a cache as well if one of the proper size doesn't exist
    discard allocChannelCache(size, n, impl)

proc freeChannel*(chan: ChannelRaw) =
  if chan.isNil:
    return

  when ChannelCacheSize > 0:
    var p = channelCache
    while not p.isNil:
      if chan.itemsize == p.chanSize and
         chan.size-1 == p.chanN and
         chan.impl == p.chanKind:
        if p.numCached < ChannelCacheSize:
          # If space left in cache, cache it
          p.cache[p.numCached] = chan
          inc p.numCached
          return
        else:
          # All the other lists in cache won't match
          break
      p = p.next

  if not chan.buffer.isNil:
    c_free(chan.buffer)

  deinitLock(chan.headLock)
  deinitLock(chan.tailLock)
  deinitCond(chan.notFullCond)
  deinitCond(chan.notEmptyCond)

  c_free(chan)

# MPMC Channels (Multi-Producer Multi-Consumer)
# ----------------------------------------------------------------------------------

proc sendUnbufferedMpmc(chan: ChannelRaw, data: sink pointer, size: int32, nonBlocking: bool): bool =
  if nonBlocking and chan.isFullUnbuf():
    return false

  acquire(chan.headLock)

  if nonBlocking and chan.isFullUnbuf():
    # Another thread was faster
    release(chan.headLock)
    return false

  while chan.isFullUnbuf():
    wait(chan.notFullcond, chan.headLock)

  assert chan.isEmptyUnbuf()
  assert size <= chan.itemsize
  copyMem(chan.buffer, data, size)

  chan.head = 1

  release(chan.headLock)
  signal(chan.notEmptyCond)
  result = true

proc sendMpmc(chan: ChannelRaw, data: sink pointer, size: int32, nonBlocking: bool): bool =
  assert not chan.isNil # TODO not nil compiler constraint
  assert not data.isNil

  if isUnbuffered(chan):
    return sendUnbufferedMpmc(chan, data, size, nonBlocking)

  if nonBlocking and chan.isFull():
    return false

  acquire(chan.tailLock)


  if nonBlocking and chan.isFull():
    # Another thread was faster
    release(chan.tailLock)
    return false

  while chan.isFull():
    wait(chan.notFullcond, chan.tailLock)

  assert not chan.isFull
  assert size <= chan.itemsize

  copyMem(chan.buffer[chan.tail * chan.itemsize].addr, data, size)

  chan.tail = chan.tail.incmod(chan.size)

  release(chan.tailLock)
  signal(chan.notEmptyCond)
  result = true

proc recvUnbufferedMpmc(chan: ChannelRaw, data: pointer, size: int32, nonBlocking: bool): bool =
  if nonBlocking and chan.isEmptyUnbuf():
    return false

  acquire(chan.headLock)

  if nonBlocking and chan.isEmptyUnbuf():
    # Another thread was faster
    release(chan.headLock)
    return false

  while chan.isEmptyUnbuf:
    wait(chan.notEmptyCond, chan.headLock)

  assert chan.isFullUnbuf()
  assert size <= chan.itemsize
  copyMem(data, chan.buffer, size)

  chan.head = 0
  assert chan.isEmptyUnbuf

  release(chan.headLock)
  signal(chan.notFullCond)
  result = true

proc recvMpmc(chan: ChannelRaw, data: pointer, size: int32, nonBlocking: bool): bool =
  assert not chan.isNil # TODO not nil compiler constraint
  assert not data.isNil

  if isUnbuffered(chan):
    return recvUnbufferedMpmc(chan, data, size, nonBlocking)

  if nonBlocking and chan.isEmpty():
    return false

  acquire(chan.headLock)

  if nonBlocking and chan.isEmpty():
    # Another thread took the last data
    release(chan.headLock)
    return false

  while chan.isEmpty():
    wait(chan.notEmptyCond, chan.headLock)

  assert not chan.isEmpty()
  assert size <= chan.itemsize
  copyMem(data, chan.buffer[chan.head * chan.itemsize].addr, size)

  chan.head = chan.head.incmod(chan.size)
  release(chan.headLock)
  signal(chan.notFullCond)
  result = true

proc channelCloseMpmc(chan: ChannelRaw): bool =
  # Unsynchronized

  if chan.isClosed():
    # ChannelRaw already closed
    return false

  store(chan.closed, true, moRelaxed)
  result = true

proc channelOpenMpmc(chan: ChannelRaw): bool =
  # Unsynchronized

  if not chan.isClosed:
    # ChannelRaw already open
    return false

  store(chan.closed, false, moRelaxed)
  result = true

# MPSC Channels (Multi-Producer Single-Consumer)
# ----------------------------------------------------------------------------------

proc channelSendMpsc(chan: ChannelRaw, data: sink pointer, size: int32, nonBlocking: bool): bool =
  # Cannot be inline due to function table
  sendMpmc(chan, data, size, nonBlocking)

proc channel_recv_unbuffered_mpsc(chan: ChannelRaw, data: pointer, size: int32, nonBlocking: bool): bool =
  # Single consumer, no lock needed on reception
  if nonBlocking and chan.isEmptyUnbuf():
    return false

  while chan.isEmptyUnbuf():
    cpuRelax()

  assert chan.isFullUnbuf
  assert size <= chan.itemsize

  copyMem(data, chan.buffer, size)
  fence(moSequentiallyConsistent)

  chan.head = 0
  signal(chan.notFullCond)
  result = true

proc channelRecvMpsc(chan: ChannelRaw, data: pointer, size: int32, nonBlocking: bool): bool =
  # Single consumer, no lock needed on reception
  assert not chan.isNil # TODO not nil compiler constraint
  assert not data.isNil

  if isUnbuffered(chan):
    return channel_recv_unbuffered_mpsc(chan, data, size, nonBlocking)

  if nonBlocking and chan.isEmpty():
    return false

  while chan.isEmpty():
    cpuRelax()

  assert not chan.isEmpty()
  assert size <= chan.itemsize

  copyMem(data, chan.buffer[chan.head * chan.itemsize].addr, size)

  let newHead = chan.head.incmod(chan.size)
  fence(moSequentiallyConsistent)

  chan.head = newHead
  signal(chan.notFullCond)
  result = true

proc channelCloseMpsc(chan: ChannelRaw): bool =
  # Unsynchronized
  assert not chan.isNil

  if chan.isClosed():
    # Already closed
    result = false
  else:
    chan.closed.store(true, moRelaxed)
    result = true

proc channelOpenMpsc(chan: ChannelRaw): bool =
  # Unsynchronized
  assert not chan.isNil

  if not chan.isClosed():
    # Already open
    result = false
  else:
    chan.closed.store(false, moRelaxed)
    result = true

# SPSC Channels (Single-Producer Single-Consumer)
# ----------------------------------------------------------------------------------

proc channel_send_unbuffered_spsc(chan: ChannelRaw, data: sink pointer, size: int32, nonBlocking: bool): bool =
  if nonBlocking and chan.isFullUnbuf:
    return false

  while chan.isFullUnbuf:
    cpuRelax()

  assert chan.isEmptyUnbuf
  assert size <= chan.itemsize
  copyMem(chan.buffer, data, size)

  fence(moSequentiallyConsistent)

  chan.head = 1
  signal(chan.notEmptyCond)
  result = true

proc channelSendSpsc(chan: ChannelRaw, data: sink pointer, size: int32, nonBlocking: bool): bool =
  assert not chan.isNil
  assert not data.isNil

  if chan.isUnbuffered():
    return channel_send_unbuffered_spsc(chan, data, size, nonBlocking)

  if nonBlocking and chan.isFull():
    return false

  while chan.isFull():
    cpuRelax()

  assert not chan.isFull()
  assert size <= chan.itemsize
  copyMem(chan.buffer[chan.tail * chan.itemsize].addr, data, size)

  let newTail = chan.tail.incmod(chan.size)

  fence(moSequentiallyConsistent)

  chan.tail = newTail
  signal(chan.notEmptyCond)
  result = true

proc channelRecvSpsc(chan: ChannelRaw, data: pointer, size: int32, nonBlocking: bool): bool =
  # Cannot be inline due to function table
  channelRecvMpsc(chan, data, size, nonBlocking)

proc channelCloseSpsc(chan: ChannelRaw): bool =
  # Unsynchronized
  assert not chan.isNil

  if chan.isClosed():
    # Already closed
    result = false
  else:
    chan.closed.store(true, moRelaxed)
    result = true

proc channelOpenSpsc(chan: ChannelRaw): bool =
  # Unsynchronized
  assert not chan.isNil

  if not chan.isClosed():
    # Already open
    result = false
  else:
    chan.closed.store(false, moRelaxed)
    result = true

# "Generic" dispatch
# ----------------------------------------------------------------------------------

const
  send_fn = [
    Mpmc: sendMpmc,
    Mpsc: channelSendMpsc,
    Spsc: channelSendSpsc
  ]

  recv_fn = [
    Mpmc: recvMpmc,
    Mpsc: channelRecvMpsc,
    Spsc: channelRecvSpsc
  ]

  close_fn = [
    Mpmc: channelCloseMpmc,
    Mpsc: channelCloseMpsc,
    Spsc: channelCloseSpsc
  ]

  open_fn = [
    Mpmc: channelOpenMpmc,
    Mpsc: channelOpenMpsc,
    Spsc: channelOpenSpsc
  ]

proc channelSend(chan: ChannelRaw, data: sink pointer, size: int32, nonBlocking: bool): bool {.inline.} =
  ## Send item to the channel (FIFO queue)
  ## (Insert at last)
  send_fn[chan.impl](chan, data, size, nonBlocking)

proc channelReceive(chan: ChannelRaw, data: pointer, size: int32, nonBlocking: bool): bool {.inline.} =
  ## Receive an item from the channel
  ## (Remove the first item)
  recv_fn[chan.impl](chan, data, size, nonBlocking)

proc channel_close(chan: ChannelRaw): bool {.inline.} =
  ## Close a channel
  close_fn[chan.impl](chan)

proc channel_open(chan: ChannelRaw): bool {.inline.} =
  ## (Re)open a channel
  open_fn[chan.impl](chan)

# Public API
# ----------------------------------------------------------------------------------

type
  Chan*[T] = object ## Typed channels
    d: ChannelRaw

proc `=`[T](dest: var Chan[T]; src: Chan[T]) {.error.}

proc `=destroy`[T](c: var Chan[T]) =
  if c.d.buffer != nil: freeChannel(c.d)

proc channelSend[T](chan: Chan[T], data: T, size: int32, nonBlocking: bool): bool {.inline.} =
  ## Send item to the channel (FIFO queue)
  ## (Insert at last)
  send_fn[chan.d.impl](chan.d, data.unsafeAddr, size, nonBlocking)

proc channelReceive[T](chan: Chan[T], data: ptr T, size: int32, nonBlocking: bool): bool {.inline.} =
  ## Receive an item from the channel
  ## (Remove the first item)
  recv_fn[chan.d.impl](chan.d, data, size, nonBlocking)

func trySend*[T](c: Chan[T], src: sink Isolated[T]): bool {.inline.} =
  ## Sends item to the channel(non blocking).
  var data = src.extract
  result = channelSend(c, data, int32 sizeof(data), true)
  if result:
    wasMoved(data)

template trySend*[T](c: Chan[T], src: T): bool =
  trySend(c, isolate(src))

func tryRecv*[T](c: Chan[T], dst: var T): bool {.inline.} =
  ## Receives item from the channel(non blocking).
  channelReceive(c, dst.addr, int32 sizeof(dst), true)

func send*[T](c: Chan[T], src: sink Isolated[T]) {.inline.} =
  ## Sends item to the channel(blocking).
  var data = src.extract
  discard channelSend(c, data, int32 sizeof(data), false)
  wasMoved(data)

template send*[T](c: var Chan[T]; src: T) =
  send(c, isolate(src))

func recv*[T](c: Chan[T], dst: var T) {.inline.} =
  ## Receives item from the channel(blocking).
  discard channelReceive(c, dst.addr, int32 sizeof(dst), false)

func recvIso*[T](c: Chan[T]): Isolated[T] {.inline.} =
  var dst: T
  discard channelReceive(c, dst.addr, int32 sizeof(dst), false)
  result = isolate(dst)

func open*[T](c: Chan[T]): bool {.inline.} =
  result = c.d.channel_open()

func close*[T](c: Chan[T]): bool {.inline.} =
  result = c.d.channel_close()

func peek*[T](c: Chan[T]): int32 {.inline.} = peek(c.d)

proc initChan*[T](elements = 30, kind = Mpmc): Chan[T] =
  result = Chan[T](d: allocChannel(int32 sizeof(T), elements.int32, kind))

proc delete*[T](c: var Chan[T]) {.inline.} =
  freeChannel(c.d)
