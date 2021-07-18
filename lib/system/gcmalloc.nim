#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#        (c) Copyright 2021 Jacek Sieka
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Malloc-based allocator for the GC - similar to what's found in alloc.nim
# without all the fancy small chunk allocation stuff - enable with -d:useMalloc
#
# * Allocates memory with `malloc` - compatible with allocators like jemalloc etc
# * No small chunk optimization
# * No free list
# * Releases garbage-collected memory with `free`
# * Should perhaps allocate memory with posix_memalign
# * Uses less memory, is a bit slower

{.push profiler:off.}

proc roundup(x, v: int): int {.inline.} =
  result = (x + (v-1)) and not (v-1)
  sysAssert(result >= x, "roundup: result < x")
  #return ((-x) and (v-1)) +% x

template track(op, address, size) =
  when defined(memTracker):
    memTrackerOp(op, address, size)

const
  MallocAlignShift = 3 # Let's assume all mallocs align to 8 bytes..

type
  PTrunk = ptr Trunk
  Trunk = object
    next: PTrunk         # all nodes are connected with this pointer
    key: int             # start address at bit 0
    bits: array[0..IntsPerTrunk-1, uint] # a bit vector

  TrunkBuckets = array[0..255, PTrunk]
  IntSet = object
    data: TrunkBuckets

type
  AlignType = BiggestFloat
  FreeCell {.final, pure.} = object
    next: ptr FreeCell  # next free cell in chunk (overlaid with refcount)
    when not defined(gcDestructors):
      zeroField: int       # 0 means cell is not used (overlaid with typ field)
                          # 1 means cell is manually managed pointer
                          # otherwise a PNimType is stored in there
    else:
      alignment: int

  PChunk = ptr Chunk

  Chunk {.pure.} = object
    size: int
    data: AlignType      # start of usable memory

template chunkOverhead(): untyped = sizeof(Chunk)-sizeof(AlignType)

type
  PLLChunk = ptr LLChunk
  LLChunk = object ## *low-level* chunk
    size: int                # remaining size
    acc: int                 # accumulator
    next: PLLChunk           # next low-level chunk; only needed for dealloc

  PAvlNode = ptr AvlNode
  AvlNode = object
    link: array[0..1, PAvlNode] # Left (0) and right (1) links
    key, upperBound: int
    level: int

  MemRegion = object
    minLargeObj, maxLargeObj: int
    llmem: PLLChunk
    currMem, maxMem, freeMem, occ: int # memory sizes (allocated from OS)
    chunkStarts: IntSet
    root, deleted, last, freeAvlNodes: PAvlNode
    locked: bool # if locked, we cannot free pages.
    bottomData: AvlNode
    when defined(nimTypeNames):
      allocCounter, deallocCounter: int

proc incCurrMem(a: var MemRegion, bytes: int) {.inline.} =
  inc(a.currMem, bytes)

proc decCurrMem(a: var MemRegion, bytes: int) {.inline.} =
  a.maxMem = max(a.maxMem, a.currMem)
  dec(a.currMem, bytes)

proc getMaxMem(a: var MemRegion): int =
  # Since we update maxPagesCount only when freeing pages,
  # maxPagesCount may not be up to date. Thus we use the
  # maximum of these both values here:
  result = max(a.currMem, a.maxMem)

proc llAlloc(a: var MemRegion, size: int): pointer =
  # *low-level* alloc for the memory managers data structures. Deallocation
  # is done at the end of the allocator's life time.
  if a.llmem == nil or size > a.llmem.size:
    # the requested size is ``roundup(size+sizeof(LLChunk), PageSize)``, but
    # since we know ``size`` is a (small) constant, we know the requested size
    # is one page:
    sysAssert roundup(size+sizeof(LLChunk), PageSize) == PageSize, "roundup 6"
    var old = a.llmem # can be nil and is correct with nil
    a.llmem = cast[PLLChunk](c_malloc(PageSize))
    when defined(avlcorruption):
      trackLocation(a.llmem, PageSize)
    incCurrMem(a, PageSize)
    a.llmem.size = PageSize - sizeof(LLChunk)
    a.llmem.acc = sizeof(LLChunk)
    a.llmem.next = old
  result = cast[pointer](cast[ByteAddress](a.llmem) + a.llmem.acc)
  dec(a.llmem.size, size)
  inc(a.llmem.acc, size)
  zeroMem(result, size)

proc getBottom(a: var MemRegion): PAvlNode =
  result = addr(a.bottomData)
  if result.link[0] == nil:
    result.link[0] = result
    result.link[1] = result

proc allocAvlNode(a: var MemRegion, key, upperBound: int): PAvlNode =
  if a.freeAvlNodes != nil:
    result = a.freeAvlNodes
    a.freeAvlNodes = a.freeAvlNodes.link[0]
  else:
    result = cast[PAvlNode](llAlloc(a, sizeof(AvlNode)))
    when defined(avlcorruption):
      cprintf("tracking location: %p\n", result)
  result.key = key
  result.upperBound = upperBound
  let bottom = getBottom(a)
  result.link[0] = bottom
  result.link[1] = bottom
  result.level = 1
  #when defined(avlcorruption):
  #  track("allocAvlNode", result, sizeof(AvlNode))
  sysAssert(bottom == addr(a.bottomData), "bottom data")
  sysAssert(bottom.link[0] == bottom, "bottom link[0]")
  sysAssert(bottom.link[1] == bottom, "bottom link[1]")

proc deallocAvlNode(a: var MemRegion, n: PAvlNode) {.inline.} =
  n.link[0] = a.freeAvlNodes
  a.freeAvlNodes = n

include "system/avltree"

proc llDeallocAll(a: var MemRegion) =
  var it = a.llmem
  while it != nil:
    # we know each block in the list has the size of 1 page:
    var next = it.next
    c_free(it)
    it = next
  a.llmem = nil

proc intSetGet(t: IntSet, key: int): PTrunk =
  var it = t.data[key and high(t.data)]
  while it != nil:
    if it.key == key:
      return it
    it = it.next
  result = nil

proc intSetPut(a: var MemRegion, t: var IntSet, key: int): PTrunk =
  result = intSetGet(t, key)
  if result == nil:
    result = cast[PTrunk](llAlloc(a, sizeof(result[])))
    result.next = t.data[key and high(t.data)]
    t.data[key and high(t.data)] = result
    result.key = key

proc contains(s: IntSet, key: int): bool =
  var t = intSetGet(s, key shr TrunkShift)
  if t != nil:
    var u = key and TrunkMask
    result = (t.bits[u shr IntShift] and (uint(1) shl (u and IntMask))) != 0
  else:
    result = false

proc incl(a: var MemRegion, s: var IntSet, key: int) =
  var t = intSetPut(a, s, key shr TrunkShift)
  var u = key and TrunkMask
  t.bits[u shr IntShift] = t.bits[u shr IntShift] or (uint(1) shl (u and IntMask))

proc excl(s: var IntSet, key: int) =
  var t = intSetGet(s, key shr TrunkShift)
  if t != nil:
    var u = key and TrunkMask
    t.bits[u shr IntShift] = t.bits[u shr IntShift] and not
        (uint(1) shl (u and IntMask))

iterator elements(t: IntSet): int {.inline.} =
  # while traversing it is forbidden to change the set!
  for h in 0..high(t.data):
    var r = t.data[h]
    while r != nil:
      var i = 0
      while i <= high(r.bits):
        var w = r.bits[i] # taking a copy of r.bits[i] here is correct, because
        # modifying operations are not allowed during traversation
        var j = 0
        while w != 0:         # test all remaining bits for zero
          if (w and 1) != 0:  # the bit is set!
            yield (r.key shl TrunkShift) or (i shl IntShift +% j)
          inc(j)
          w = w shr 1
        inc(i)
      r = r.next

iterator allObjects(m: var MemRegion): pointer {.inline.} =
  m.locked = true
  for s in elements(m.chunkStarts):
    # we need to check here again as it could have been modified:
    if s in m.chunkStarts:
      let c = cast[PChunk](s shl 3)
      yield addr(c.data)
  m.locked = false

proc iterToProc*(iter: typed, envType: typedesc; procName: untyped) {.
                      magic: "Plugin", compileTime.}

when not defined(gcDestructors):
  proc isCell(p: pointer): bool {.inline.} =
    result = cast[ptr FreeCell](p).zeroField >% 1

# ------------- chunk management ----------------------------------------------
proc pageIndex(c: PChunk): int {.inline.} =
  result = cast[ByteAddress](c) shr MallocAlignShift

proc pageAddr(p: pointer): PChunk {.inline.} =
  result = cast[PChunk](cast[uint](p) - chunkOverhead())
  #sysAssert(Contains(allocator.chunkStarts, pageIndex(result)))

proc pageIndex(p: pointer): int {.inline.} =
  result = pageIndex(pageAddr(p))

const nimMaxHeap {.intdefine.} = 0

proc isAccessible(a: MemRegion, p: pointer): bool {.inline.} =
  result = contains(a.chunkStarts, pageIndex(p))

proc getHugeChunk(a: var MemRegion; size: int): PChunk =
  result = cast[PChunk](c_malloc(size.csize_t))
  incCurrMem(a, size)
  # XXX add this to the heap links. But also remove it from it later.
  # sysAssert((cast[ByteAddress](result) and PageMask) == 0, "getHugeChunk")
  result.size = size
  # set 'used' to to true:
  incl(a, a.chunkStarts, pageIndex(result))

proc freeHugeChunk(a: var MemRegion; c: PChunk) =
  let size = c.size
  excl(a.chunkStarts, pageIndex(c))
  decCurrMem(a, size)
  c_free(c)

# -----------------------------------------------------------------------------
when not defined(gcDestructors):
  proc isAllocatedPtr(a: MemRegion, p: pointer): bool {.benign.}

when true:
  template allocInv(a: MemRegion): bool = true
else:
  proc allocInv(a: MemRegion): bool =
    ## checks some (not all yet) invariants of the allocator's data structures.
    result = true

when false:
  var
    rsizes: array[50_000, int]
    rsizesLen: int

  proc trackSize(size: int) =
    rsizes[rsizesLen] = size
    inc rsizesLen

  proc untrackSize(size: int) =
    for i in 0 .. rsizesLen-1:
      if rsizes[i] == size:
        rsizes[i] = rsizes[rsizesLen-1]
        dec rsizesLen
        return
    c_fprintf(stdout, "%ld\n", size)
    sysAssert(false, "untracked size!")
else:
  template trackSize(x) = discard
  template untrackSize(x) = discard

proc rawAlloc(a: var MemRegion, requestedSize: int): pointer =
  when defined(nimTypeNames):
    inc(a.allocCounter)
  sysAssert(allocInv(a), "rawAlloc: begin")
  sysAssert(roundup(65, 8) == 72, "rawAlloc: roundup broken")
  sysAssert(requestedSize >= sizeof(FreeCell), "rawAlloc: requested size too small")
  var size = roundup(requestedSize, MemAlign)
  sysAssert(size >= requestedSize, "insufficient allocated size!")
  #c_fprintf(stdout, "alloc; size: %ld; %ld\n", requestedSize, size)
  size = requestedSize + chunkOverhead() #  roundup(requestedSize+chunkOverhead(), PageSize)
  # allocate a large block
  var c = getHugeChunk(a, size)
  result = addr(c.data)
  # sysAssert((cast[ByteAddress](c) and (MemAlign-1)) == 0, "rawAlloc 13")
  # sysAssert((cast[ByteAddress](c) and PageMask) == 0, "rawAlloc: Not aligned on a page boundary")
  if a.root == nil: a.root = getBottom(a)
  add(a, a.root, cast[ByteAddress](result), cast[ByteAddress](result)+%size)
  inc a.occ, c.size
  trackSize(c.size)
  sysAssert(isAccessible(a, result), "rawAlloc 14")
  sysAssert(allocInv(a), "rawAlloc: end")
  when logAlloc: cprintf("var pointer_%p = alloc(%ld)\n", result, requestedSize)

proc rawAlloc0(a: var MemRegion, requestedSize: int): pointer =
  result = rawAlloc(a, requestedSize)
  zeroMem(result, requestedSize)

proc rawDealloc(a: var MemRegion, p: pointer) =
  when defined(nimTypeNames):
    inc(a.deallocCounter)
  #sysAssert(isAllocatedPtr(a, p), "rawDealloc: no allocated pointer")
  sysAssert(allocInv(a), "rawDealloc: begin")
  var c = cast[PChunk](pageAddr(p))
  # set to 0xff to check for usage after free bugs:
  when overwriteFree: nimSetMem(p, -1'i32, c.size -% chunkOverhead())
  # free big chunk
  dec a.occ, c.size
  untrackSize(c.size)
  sysAssert a.occ >= 0, "rawDealloc: negative occupied memory (case B)"
  del(a, a.root, cast[int](addr(c.data)))
  freeHugeChunk(a, c)
  sysAssert(allocInv(a), "rawDealloc: end")
  when logAlloc: cprintf("dealloc(pointer_%p)\n", p)

when not defined(gcDestructors):
  proc isAllocatedPtr(a: MemRegion, p: pointer): bool =
    if isAccessible(a, p):
      var c = pageAddr(p)
      result = p == addr(c.data) and cast[ptr FreeCell](p).zeroField >% 1

  proc prepareForInteriorPointerChecking(a: var MemRegion) {.inline.} =
    a.minLargeObj = lowGauge(a.root)
    a.maxLargeObj = highGauge(a.root)

  proc interiorAllocatedPtr(a: MemRegion, p: pointer): pointer =
    if isAccessible(a, p):
      var c = pageAddr(p)
      var d = addr(c.data)
      if p >= d and cast[ptr FreeCell](d).zeroField >% 1:
        result = d
        sysAssert isAllocatedPtr(a, result), " result wrong pointer!"
    else:
      var q = cast[int](p)
      if q >=% a.minLargeObj and q <=% a.maxLargeObj:
        # this check is highly effective! Test fails for 99,96% of all checks on
        # an x86-64.
        var avlNode = inRange(a.root, q)
        if avlNode != nil:
          var k = cast[pointer](avlNode.key)
          var c = pageAddr(k)
          sysAssert(addr(c.data) == k, " k is not the same as addr(c.data)!")
          if cast[ptr FreeCell](k).zeroField >% 1:
            result = k
            sysAssert isAllocatedPtr(a, result), " result wrong pointer!"

proc ptrSize(p: pointer): int =
  when not defined(gcDestructors):
    var c = pageAddr(p)
    result = c.size -% sizeof(FreeCell)
    dec result, chunkOverhead()
  else:
    var c = pageAddr(p)
    result = c.size
    dec result, chunkOverhead()

proc alloc(allocator: var MemRegion, size: Natural): pointer {.gcsafe.} =
  when not defined(gcDestructors):
    result = rawAlloc(allocator, size+sizeof(FreeCell))
    cast[ptr FreeCell](result).zeroField = 1 # mark it as used
    sysAssert(not isAllocatedPtr(allocator, result), "alloc")
    result = cast[pointer](cast[ByteAddress](result) +% sizeof(FreeCell))
    track("alloc", result, size)
  else:
    result = rawAlloc(allocator, size)

proc alloc0(allocator: var MemRegion, size: Natural): pointer =
  result = alloc(allocator, size)
  zeroMem(result, size)

proc dealloc(allocator: var MemRegion, p: pointer) =
  when not defined(gcDestructors):
    sysAssert(p != nil, "dealloc: p is nil")
    var x = cast[pointer](cast[ByteAddress](p) -% sizeof(FreeCell))
    sysAssert(x != nil, "dealloc: x is nil")
    sysAssert(isAccessible(allocator, x), "is not accessible")
    sysAssert(cast[ptr FreeCell](x).zeroField == 1, "dealloc: object header corrupted")
    rawDealloc(allocator, x)
    sysAssert(not isAllocatedPtr(allocator, x), "dealloc: object still accessible")
    track("dealloc", p, 0)
  else:
    rawDealloc(allocator, p)

proc realloc(allocator: var MemRegion, p: pointer, newsize: Natural): pointer =
  if newsize > 0:
    result = alloc(allocator, newsize)
    if p != nil:
      copyMem(result, p, min(ptrSize(p), newsize))
      dealloc(allocator, p)
  elif p != nil:
    dealloc(allocator, p)

proc realloc0(allocator: var MemRegion, p: pointer, oldsize, newsize: Natural): pointer =
  result = realloc(allocator, p, newsize)
  if newsize > oldsize:
    zeroMem(cast[pointer](cast[uint](result) + uint(oldsize)), newsize - oldsize)

proc deallocOsPages(a: var MemRegion) =
  # we free every 'ordinarily' allocated page by iterating over the page bits:
  # And then we free the pages that are in use for the page bits:
  llDeallocAll(a)

proc getFreeMem(a: MemRegion): int {.inline.} = result = a.freeMem
proc getTotalMem(a: MemRegion): int {.inline.} = result = a.currMem
proc getOccupiedMem(a: MemRegion): int {.inline.} =
  result = a.occ
  # a.currMem - a.freeMem

when defined(nimTypeNames):
  proc getMemCounters(a: MemRegion): (int, int) {.inline.} =
    (a.allocCounter, a.deallocCounter)

# ---------------------- thread memory region -------------------------------

template instantiateForRegion(allocator: untyped) {.dirty.} =
  {.push stackTrace: off.}

  when defined(fulldebug):
    proc interiorAllocatedPtr*(p: pointer): pointer =
      result = interiorAllocatedPtr(allocator, p)

    proc isAllocatedPtr*(p: pointer): bool =
      let p = cast[pointer](cast[ByteAddress](p)-%ByteAddress(sizeof(Cell)))
      result = isAllocatedPtr(allocator, p)

  proc deallocOsPages = deallocOsPages(allocator)

  proc allocImpl(size: Natural): pointer =
    result = alloc(allocator, size)

  proc alloc0Impl(size: Natural): pointer =
    result = alloc0(allocator, size)

  proc deallocImpl(p: pointer) =
    dealloc(allocator, p)

  proc reallocImpl(p: pointer, newSize: Natural): pointer =
    result = realloc(allocator, p, newSize)

  proc realloc0Impl(p: pointer, oldSize, newSize: Natural): pointer =
    result = realloc(allocator, p, newSize)
    if newSize > oldSize:
      zeroMem(cast[pointer](cast[int](result) + oldSize), newSize - oldSize)

  proc getFreeMem(): int =
    result = allocator.freeMem
    #sysAssert(result == countFreeMem())

  proc getTotalMem(): int = return allocator.currMem
  proc getOccupiedMem(): int = return allocator.occ #getTotalMem() - getFreeMem()
  proc getMaxMem*(): int = return getMaxMem(allocator)

  when defined(nimTypeNames):
    proc getMemCounters*(): (int, int) = getMemCounters(allocator)

  # -------------------- shared heap region ----------------------------------
  when hasThreadSupport:
    var sharedHeap: MemRegion
    var heapLock: SysLock
    initSysLock(heapLock)

  proc allocSharedImpl(size: Natural): pointer =
    when hasThreadSupport:
      acquireSys(heapLock)
      result = alloc(sharedHeap, size)
      releaseSys(heapLock)
    else:
      result = allocImpl(size)

  proc allocShared0Impl(size: Natural): pointer =
    result = allocSharedImpl(size)
    zeroMem(result, size)

  proc deallocSharedImpl(p: pointer) =
    when hasThreadSupport:
      acquireSys(heapLock)
      dealloc(sharedHeap, p)
      releaseSys(heapLock)
    else:
      deallocImpl(p)

  proc reallocSharedImpl(p: pointer, newSize: Natural): pointer =
    when hasThreadSupport:
      acquireSys(heapLock)
      result = realloc(sharedHeap, p, newSize)
      releaseSys(heapLock)
    else:
      result = reallocImpl(p, newSize)

  proc reallocShared0Impl(p: pointer, oldSize, newSize: Natural): pointer =
    when hasThreadSupport:
      acquireSys(heapLock)
      result = realloc0(sharedHeap, p, oldSize, newSize)
      releaseSys(heapLock)
    else:
      result = realloc0Impl(p, oldSize, newSize)

  when hasThreadSupport:
    template sharedMemStatsShared(v: int) =
      acquireSys(heapLock)
      result = v
      releaseSys(heapLock)

    proc getFreeSharedMem(): int =
      sharedMemStatsShared(sharedHeap.freeMem)

    proc getTotalSharedMem(): int =
      sharedMemStatsShared(sharedHeap.currMem)

    proc getOccupiedSharedMem(): int =
      sharedMemStatsShared(sharedHeap.occ)
      #sharedMemStatsShared(sharedHeap.currMem - sharedHeap.freeMem)
  {.pop.}

{.pop.}
