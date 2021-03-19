#
#
#           The Nim Compiler
#        (c) Copyright 2021 Andreas Prell, Mamy André-Ratsimbazafy & Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# Based on https://github.com/mratsim/weave/blob/5696d94e6358711e840f8c0b7c684fcc5cbd4472/unused/channels/channels_legacy.nim
# Those are translations of @aprell (Andreas Prell) original channels from C to Nim
# (https://github.com/aprell/tasking-2.0/blob/master/src/channel_shm/channel.c)
# And in turn they are an implementation of Michael & Scott lock-based queues
# (note the paper has 2 channels: lock-free and lock-based) with additional caching:
# Simple, Fast, and Practical Non-Blocking and Blocking Concurrent Queue Algorithms
# Maged M. Michael, Michael L. Scott, 1996
# https://www.cs.rochester.edu/~scott/papers/1996_PODC_queues.pdf

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
  var chan = newChannel[string]()

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
  let dest = chan.recv()
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
  cacheLineSize {.intdefine.} = 64 # TODO: some Samsung phone have 128 cache-line
  nimChannelCacheSize* {.intdefine.} = 100

type
  ChannelRaw = ptr ChannelObj
  ChannelObj = object
    headLock, tailLock: Lock
    notFullCond, notEmptyCond: Cond
    closed: Atomic[bool]
    size: int
    itemsize: int # up to itemsize bytes can be exchanged over this channel
    head {.align: cacheLineSize.} : int     # Items are taken from head and new items are inserted at tail
    tail: int
    buffer: ptr UncheckedArray[byte]
    atomicCounter: Atomic[int]

  ChannelCache = ptr ChannelCacheObj
  ChannelCacheObj = object
    next: ChannelCache
    chanSize: int
    chanN: int
    numCached: int
    cache: array[nimChannelCacheSize, ChannelRaw]

# ----------------------------------------------------------------------------------

proc numItems(chan: ChannelRaw): int {.inline.} =
  result = chan.tail - chan.head
  if result < 0:
    inc(result, 2 * chan.size)

  assert result <= chan.size

template isFull(chan: ChannelRaw): bool =
  abs(chan.tail - chan.head) == chan.size

template isEmpty(chan: ChannelRaw): bool =
  chan.head == chan.tail

# Unbuffered / synchronous channels
# ----------------------------------------------------------------------------------

template numItemsUnbuf(chan: ChannelRaw): int =
  chan.head

template isFullUnbuf(chan: ChannelRaw): bool =
  chan.head == 1

template isEmptyUnbuf(chan: ChannelRaw): bool =
  chan.head == 0

# ChannelRaw kinds
# ----------------------------------------------------------------------------------

func isUnbuffered(chan: ChannelRaw): bool =
  chan.size - 1 == 0

# ChannelRaw status and properties
# ----------------------------------------------------------------------------------

proc isClosed(chan: ChannelRaw): bool {.inline.} = load(chan.closed, moRelaxed)

proc peek(chan: ChannelRaw): int {.inline.} =
  (if chan.isUnbuffered: numItemsUnbuf(chan) else: numItems(chan))

# Per-thread channel cache
# ----------------------------------------------------------------------------------

var channelCache {.threadvar.}: ChannelCache
var channelCacheLen {.threadvar.}: int

proc allocChannelCache(size, n: int): bool =
  ## Allocate a free list for storing channels of a given type
  var p = channelCache

  # Avoid multiple free lists for the exact same type of channel
  while not p.isNil:
    if size == p.chanSize and n == p.chanN:
      return false
    p = p.next

  p = cast[ptr ChannelCacheObj](c_malloc(csize_t sizeof(ChannelCacheObj)))
  if p.isNil:
    raise newException(OutOfMemDefect, "Could not allocate memory")

  p.chanSize = size
  p.chanN = n
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

proc allocChannel(size, n: int): ChannelRaw =
  when nimChannelCacheSize > 0:
    var p = channelCache

    while not p.isNil:
      if size == p.chanSize and n == p.chanN:
        # Check if free list contains channel
        if p.numCached > 0:
          dec p.numCached
          result = p.cache[p.numCached]
          assert(result.isEmpty)
          return
        else:
          # All the other lists in cache won't match
          break
      p = p.next

  result = cast[ChannelRaw](c_malloc(csize_t sizeof(ChannelObj)))
  if result.isNil:
    raise newException(OutOfMemDefect, "Could not allocate memory")

  # To buffer n items, we allocate for n
  result.buffer = cast[ptr UncheckedArray[byte]](c_malloc(csize_t n*size))
  if result.buffer.isNil:
    raise newException(OutOfMemDefect, "Could not allocate memory")

  initLock(result.headLock)
  initLock(result.tailLock)
  initCond(result.notFullCond)
  initCond(result.notEmptyCond)

  result.closed.store(false, moRelaxed) # We don't need atomic here, how to?
  result.size = n
  result.itemsize = size
  result.head = 0
  result.tail = 0
  result.atomicCounter.store(0, moRelaxed)

  when nimChannelCacheSize > 0:
    # Allocate a cache as well if one of the proper size doesn't exist
    discard allocChannelCache(size, n)

proc freeChannel(chan: ChannelRaw) =
  if chan.isNil:
    return

  when nimChannelCacheSize > 0:
    var p = channelCache
    while not p.isNil:
      if chan.itemsize == p.chanSize and
         chan.size == p.chanN:
        if p.numCached < nimChannelCacheSize:
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

proc sendUnbufferedMpmc(chan: ChannelRaw, data: sink pointer, size: int, nonBlocking: bool): bool =
  if nonBlocking and chan.isFullUnbuf:
    return false

  acquire(chan.headLock)

  if nonBlocking and chan.isFullUnbuf:
    # Another thread was faster
    release(chan.headLock)
    return false

  while chan.isFullUnbuf:
    wait(chan.notFullcond, chan.headLock)

  assert chan.isEmptyUnbuf
  assert size <= chan.itemsize
  copyMem(chan.buffer, data, size)

  chan.head = 1

  release(chan.headLock)
  signal(chan.notEmptyCond)
  result = true

proc sendMpmc(chan: ChannelRaw, data: sink pointer, size: int, nonBlocking: bool): bool =
  assert not chan.isNil
  assert not data.isNil

  if isUnbuffered(chan):
    return sendUnbufferedMpmc(chan, data, size, nonBlocking)

  if nonBlocking and chan.isFull:
    return false

  acquire(chan.tailLock)

  if nonBlocking and chan.isFull:
    # Another thread was faster
    release(chan.tailLock)
    return false

  while chan.isFull:
    wait(chan.notFullcond, chan.tailLock)

  assert not chan.isFull
  assert size <= chan.itemsize

  let writeIdx = if chan.tail < chan.size: chan.tail
                 else: chan.tail - chan.size

  copyMem(chan.buffer[writeIdx * chan.itemsize].addr, data, size)

  inc chan.tail
  if chan.tail == 2 * chan.size:
    chan.tail = 0

  release(chan.tailLock)
  signal(chan.notEmptyCond)
  result = true

proc recvUnbufferedMpmc(chan: ChannelRaw, data: pointer, size: int, nonBlocking: bool): bool =
  if nonBlocking and chan.isEmptyUnbuf:
    return false

  acquire(chan.headLock)

  if nonBlocking and chan.isEmptyUnbuf:
    # Another thread was faster
    release(chan.headLock)
    return false

  while chan.isEmptyUnbuf:
    wait(chan.notEmptyCond, chan.headLock)

  assert chan.isFullUnbuf
  assert size <= chan.itemsize

  copyMem(data, chan.buffer, size)

  chan.head = 0

  release(chan.headLock)
  signal(chan.notFullCond)
  result = true

proc recvMpmc(chan: ChannelRaw, data: pointer, size: int, nonBlocking: bool): bool =
  assert not chan.isNil
  assert not data.isNil

  if isUnbuffered(chan):
    return recvUnbufferedMpmc(chan, data, size, nonBlocking)

  if nonBlocking and chan.isEmpty:
    return false

  acquire(chan.headLock)

  if nonBlocking and chan.isEmpty:
    # Another thread took the last data
    release(chan.headLock)
    return false

  while chan.isEmpty:
    wait(chan.notEmptyCond, chan.headLock)

  assert not chan.isEmpty
  assert size <= chan.itemsize

  let readIdx = if chan.head < chan.size: chan.head
                else: chan.head - chan.size

  copyMem(data, chan.buffer[readIdx * chan.itemsize].addr, size)

  inc chan.head
  if chan.head == 2 * chan.size:
    chan.head = 0

  release(chan.headLock)
  signal(chan.notFullCond)
  result = true

proc channelCloseMpmc(chan: ChannelRaw): bool =
  # Unsynchronized

  if chan.isClosed:
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

# Public API
# ----------------------------------------------------------------------------------

type
  Channel*[T] = object ## Typed channels
    d: ChannelRaw

proc `=destroy`*[T](c: var Channel[T]) =
  if c.d != nil:
    if load(c.d.atomicCounter, moAcquire) == 0:
      if c.d.buffer != nil:
        freeChannel(c.d)
    else:
      atomicDec(c.d.atomicCounter)

proc `=`*[T](dest: var Channel[T], src: Channel[T]) =
  ## Shares `Channel` by reference counting.
  if src.d != nil:
    atomicInc(src.d.atomicCounter)

  if dest.d != nil:
    `=destroy`(dest)
  dest.d = src.d

func trySend*[T](c: Channel[T], src: var Isolated[T]): bool {.inline.} =
  ## Sends item to the channel(non blocking).
  var data = src.extract
  result = sendMpmc(c.d, data.addr, sizeof(T), true)
  if result:
    wasMoved(data)

template trySend*[T](c: Channel[T], src: T): bool =
  ## Helper templates for `trySend`.
  trySend(c, isolate(src))

func tryRecv*[T](c: Channel[T], dst: var T): bool {.inline.} =
  ## Receives item from the channel(non blocking).
  recvMpmc(c.d, dst.addr, sizeof(T), true)

func send*[T](c: Channel[T], src: sink Isolated[T]) {.inline.} =
  ## Sends item to the channel(blocking).
  var data = src.extract
  discard sendMpmc(c.d, data.addr, sizeof(T), false)
  wasMoved(data)

template send*[T](c: Channel[T]; src: T) =
  ## Helper templates for `send`.
  send(c, isolate(src))

func recv*[T](c: Channel[T]): T {.inline.} =
  ## Receives item from the channel(blocking).
  discard recvMpmc(c.d, result.addr, sizeof(result), false)

func open*[T](c: Channel[T]): bool {.inline.} =
  result = c.d.channelOpenMpmc()

func close*[T](c: Channel[T]): bool {.inline.} =
  result = c.d.channelCloseMpmc()

func peek*[T](c: Channel[T]): int {.inline.} = peek(c.d)

proc newChannel*[T](elements = 30): Channel[T] =
  ## Returns a new `Channel`. `elements` should be positive.
  ## `elements` is used to specify whether a channel is buffered or not.
  ## If `elements` = 1, the channel is unbuffered. If `elements` > 1, the 
  ## channel is buffered.
  assert elements >= 1, "Elements must be positive!"
  result = Channel[T](d: allocChannel(sizeof(T), elements))
