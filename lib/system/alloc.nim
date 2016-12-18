#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Low level allocator for Nim. Has been designed to support the GC.
# TODO:
# - eliminate "used" field
# - make searching for block O(1)
{.push profiler:off.}

include osalloc

template track(op, address, size) =
  when defined(memTracker):
    memTrackerOp(op, address, size)

# We manage *chunks* of memory. Each chunk is a multiple of the page size.
# Each chunk starts at an address that is divisible by the page size. Chunks
# that are bigger than ``ChunkOsReturn`` are returned back to the operating
# system immediately.

const
  ChunkOsReturn = 256 * PageSize # 1 MB
  InitialMemoryRequest = ChunkOsReturn div 2 # < ChunkOsReturn!
  SmallChunkSize = PageSize

type
  PTrunk = ptr Trunk
  Trunk = object
    next: PTrunk         # all nodes are connected with this pointer
    key: int             # start address at bit 0
    bits: array[0..IntsPerTrunk-1, int] # a bit vector

  TrunkBuckets = array[0..255, PTrunk]
  IntSet = object
    data: TrunkBuckets

type
  AlignType = BiggestFloat
  FreeCell {.final, pure.} = object
    next: ptr FreeCell  # next free cell in chunk (overlaid with refcount)
    zeroField: int       # 0 means cell is not used (overlaid with typ field)
                         # 1 means cell is manually managed pointer
                         # otherwise a PNimType is stored in there

  PChunk = ptr BaseChunk
  PBigChunk = ptr BigChunk
  PSmallChunk = ptr SmallChunk
  BaseChunk {.pure, inheritable.} = object
    prevSize: int        # size of previous chunk; for coalescing
    size: int            # if < PageSize it is a small chunk
    used: bool           # later will be optimized into prevSize...

  SmallChunk = object of BaseChunk
    next, prev: PSmallChunk  # chunks of the same size
    freeList: ptr FreeCell
    free: int            # how many bytes remain
    acc: int             # accumulator for small object allocation
    data: AlignType      # start of usable memory

  BigChunk = object of BaseChunk # not necessarily > PageSize!
    next, prev: PBigChunk    # chunks of the same (or bigger) size
    align: int
    data: AlignType      # start of usable memory

template smallChunkOverhead(): expr = sizeof(SmallChunk)-sizeof(AlignType)
template bigChunkOverhead(): expr = sizeof(BigChunk)-sizeof(AlignType)

# ------------- chunk table ---------------------------------------------------
# We use a PtrSet of chunk starts and a table[Page, chunksize] for chunk
# endings of big chunks. This is needed by the merging operation. The only
# remaining operation is best-fit for big chunks. Since there is a size-limit
# for big chunks (because greater than the limit means they are returned back
# to the OS), a fixed size array can be used.

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
    freeSmallChunks: array[0..SmallChunkSize div MemAlign-1, PSmallChunk]
    llmem: PLLChunk
    currMem, maxMem, freeMem: int # memory sizes (allocated from OS)
    lastSize: int # needed for the case that OS gives us pages linearly
    freeChunksList: PBigChunk # XXX make this a datastructure with O(1) access
    chunkStarts: IntSet
    root, deleted, last, freeAvlNodes: PAvlNode
    locked, blockChunkSizeIncrease: bool # if locked, we cannot free pages.
    nextChunkSize: int
{.deprecated: [TLLChunk: LLChunk, TAvlNode: AvlNode, TMemRegion: MemRegion].}

# shared:
var
  bottomData {.threadvar.}: AvlNode
  bottom {.threadvar.}: PAvlNode

{.push stack_trace: off.}
proc initAllocator() =
  when not defined(useNimRtl):
    bottom = addr(bottomData)
    bottom.link[0] = bottom
    bottom.link[1] = bottom
{.pop.}

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
    a.llmem = cast[PLLChunk](osAllocPages(PageSize))
    incCurrMem(a, PageSize)
    a.llmem.size = PageSize - sizeof(LLChunk)
    a.llmem.acc = sizeof(LLChunk)
    a.llmem.next = old
  result = cast[pointer](cast[ByteAddress](a.llmem) + a.llmem.acc)
  dec(a.llmem.size, size)
  inc(a.llmem.acc, size)
  zeroMem(result, size)

proc allocAvlNode(a: var MemRegion, key, upperBound: int): PAvlNode =
  if a.freeAvlNodes != nil:
    result = a.freeAvlNodes
    a.freeAvlNodes = a.freeAvlNodes.link[0]
  else:
    result = cast[PAvlNode](llAlloc(a, sizeof(AvlNode)))
  result.key = key
  result.upperBound = upperBound
  result.link[0] = bottom
  result.link[1] = bottom
  result.level = 1
  sysAssert(bottom == addr(bottomData), "bottom data")
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
    osDeallocPages(it, PageSize)
    it = next

proc intSetGet(t: IntSet, key: int): PTrunk =
  var it = t.data[key and high(t.data)]
  while it != nil:
    if it.key == key: return it
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
    result = (t.bits[u shr IntShift] and (1 shl (u and IntMask))) != 0
  else:
    result = false

proc incl(a: var MemRegion, s: var IntSet, key: int) =
  var t = intSetPut(a, s, key shr TrunkShift)
  var u = key and TrunkMask
  t.bits[u shr IntShift] = t.bits[u shr IntShift] or (1 shl (u and IntMask))

proc excl(s: var IntSet, key: int) =
  var t = intSetGet(s, key shr TrunkShift)
  if t != nil:
    var u = key and TrunkMask
    t.bits[u shr IntShift] = t.bits[u shr IntShift] and not
        (1 shl (u and IntMask))

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

proc isSmallChunk(c: PChunk): bool {.inline.} =
  return c.size <= SmallChunkSize-smallChunkOverhead()

proc chunkUnused(c: PChunk): bool {.inline.} =
  result = not c.used

iterator allObjects(m: var MemRegion): pointer {.inline.} =
  m.locked = true
  for s in elements(m.chunkStarts):
    # we need to check here again as it could have been modified:
    if s in m.chunkStarts:
      let c = cast[PChunk](s shl PageShift)
      if not chunkUnused(c):
        if isSmallChunk(c):
          var c = cast[PSmallChunk](c)

          let size = c.size
          var a = cast[ByteAddress](addr(c.data))
          let limit = a + c.acc
          while a <% limit:
            yield cast[pointer](a)
            a = a +% size
        else:
          let c = cast[PBigChunk](c)
          yield addr(c.data)
  m.locked = false

proc iterToProc*(iter: typed, envType: typedesc; procName: untyped) {.
                      magic: "Plugin", compileTime.}

proc isCell(p: pointer): bool {.inline.} =
  result = cast[ptr FreeCell](p).zeroField >% 1

# ------------- chunk management ----------------------------------------------
proc pageIndex(c: PChunk): int {.inline.} =
  result = cast[ByteAddress](c) shr PageShift

proc pageIndex(p: pointer): int {.inline.} =
  result = cast[ByteAddress](p) shr PageShift

proc pageAddr(p: pointer): PChunk {.inline.} =
  result = cast[PChunk](cast[ByteAddress](p) and not PageMask)
  #sysAssert(Contains(allocator.chunkStarts, pageIndex(result)))

proc requestOsChunks(a: var MemRegion, size: int): PBigChunk =
  if not a.blockChunkSizeIncrease:
    a.nextChunkSize =
      if a.currMem < 64 * 1024: PageSize*4
      else: a.nextChunkSize*2
  var size = size

  if size > a.nextChunkSize:
    result = cast[PBigChunk](osAllocPages(size))
  else:
    result = cast[PBigChunk](osTryAllocPages(a.nextChunkSize))
    if result == nil:
      result = cast[PBigChunk](osAllocPages(size))
      a.blockChunkSizeIncrease = true
    else:
      size = a.nextChunkSize

  incCurrMem(a, size)
  inc(a.freeMem, size)

  sysAssert((cast[ByteAddress](result) and PageMask) == 0, "requestOsChunks 1")
  #zeroMem(result, size)
  result.next = nil
  result.prev = nil
  result.used = false
  result.size = size
  # update next.prevSize:
  var nxt = cast[ByteAddress](result) +% size
  sysAssert((nxt and PageMask) == 0, "requestOsChunks 2")
  var next = cast[PChunk](nxt)
  if pageIndex(next) in a.chunkStarts:
    #echo("Next already allocated!")
    next.prevSize = size
  # set result.prevSize:
  var lastSize = if a.lastSize != 0: a.lastSize else: PageSize
  var prv = cast[ByteAddress](result) -% lastSize
  sysAssert((nxt and PageMask) == 0, "requestOsChunks 3")
  var prev = cast[PChunk](prv)
  if pageIndex(prev) in a.chunkStarts and prev.size == lastSize:
    #echo("Prev already allocated!")
    result.prevSize = lastSize
  else:
    result.prevSize = 0 # unknown
  a.lastSize = size # for next request

proc freeOsChunks(a: var MemRegion, p: pointer, size: int) =
  # update next.prevSize:
  var c = cast[PChunk](p)
  var nxt = cast[ByteAddress](p) +% c.size
  sysAssert((nxt and PageMask) == 0, "freeOsChunks")
  var next = cast[PChunk](nxt)
  if pageIndex(next) in a.chunkStarts:
    next.prevSize = 0 # XXX used
  excl(a.chunkStarts, pageIndex(p))
  osDeallocPages(p, size)
  decCurrMem(a, size)
  dec(a.freeMem, size)
  #c_fprintf(stdout, "[Alloc] back to OS: %ld\n", size)

proc isAccessible(a: MemRegion, p: pointer): bool {.inline.} =
  result = contains(a.chunkStarts, pageIndex(p))

proc contains[T](list, x: T): bool =
  var it = list
  while it != nil:
    if it == x: return true
    it = it.next

proc writeFreeList(a: MemRegion) =
  var it = a.freeChunksList
  c_fprintf(stdout, "freeChunksList: %p\n", it)
  while it != nil:
    c_fprintf(stdout, "it: %p, next: %p, prev: %p\n",
              it, it.next, it.prev)
    it = it.next

proc listAdd[T](head: var T, c: T) {.inline.} =
  sysAssert(c notin head, "listAdd 1")
  sysAssert c.prev == nil, "listAdd 2"
  sysAssert c.next == nil, "listAdd 3"
  c.next = head
  if head != nil:
    sysAssert head.prev == nil, "listAdd 4"
    head.prev = c
  head = c

proc listRemove[T](head: var T, c: T) {.inline.} =
  sysAssert(c in head, "listRemove")
  if c == head:
    head = c.next
    sysAssert c.prev == nil, "listRemove 2"
    if head != nil: head.prev = nil
  else:
    sysAssert c.prev != nil, "listRemove 3"
    c.prev.next = c.next
    if c.next != nil: c.next.prev = c.prev
  c.next = nil
  c.prev = nil

proc updatePrevSize(a: var MemRegion, c: PBigChunk,
                    prevSize: int) {.inline.} =
  var ri = cast[PChunk](cast[ByteAddress](c) +% c.size)
  sysAssert((cast[ByteAddress](ri) and PageMask) == 0, "updatePrevSize")
  if isAccessible(a, ri):
    ri.prevSize = prevSize

proc freeBigChunk(a: var MemRegion, c: PBigChunk) =
  var c = c
  sysAssert(c.size >= PageSize, "freeBigChunk")
  inc(a.freeMem, c.size)
  when coalescRight:
    var ri = cast[PChunk](cast[ByteAddress](c) +% c.size)
    sysAssert((cast[ByteAddress](ri) and PageMask) == 0, "freeBigChunk 2")
    if isAccessible(a, ri) and chunkUnused(ri):
      sysAssert(not isSmallChunk(ri), "freeBigChunk 3")
      if not isSmallChunk(ri):
        listRemove(a.freeChunksList, cast[PBigChunk](ri))
        inc(c.size, ri.size)
        excl(a.chunkStarts, pageIndex(ri))
  when coalescLeft:
    if c.prevSize != 0:
      var le = cast[PChunk](cast[ByteAddress](c) -% c.prevSize)
      sysAssert((cast[ByteAddress](le) and PageMask) == 0, "freeBigChunk 4")
      if isAccessible(a, le) and chunkUnused(le):
        sysAssert(not isSmallChunk(le), "freeBigChunk 5")
        if not isSmallChunk(le):
          listRemove(a.freeChunksList, cast[PBigChunk](le))
          inc(le.size, c.size)
          excl(a.chunkStarts, pageIndex(c))
          c = cast[PBigChunk](le)

  if c.size < ChunkOsReturn or doNotUnmap or a.locked:
    incl(a, a.chunkStarts, pageIndex(c))
    updatePrevSize(a, c, c.size)
    listAdd(a.freeChunksList, c)
    c.used = false
  else:
    freeOsChunks(a, c, c.size)

proc splitChunk(a: var MemRegion, c: PBigChunk, size: int) =
  var rest = cast[PBigChunk](cast[ByteAddress](c) +% size)
  sysAssert(rest notin a.freeChunksList, "splitChunk")
  rest.size = c.size - size
  rest.used = false
  rest.next = nil
  rest.prev = nil
  rest.prevSize = size
  updatePrevSize(a, c, rest.size)
  c.size = size
  incl(a, a.chunkStarts, pageIndex(rest))
  listAdd(a.freeChunksList, rest)

proc getBigChunk(a: var MemRegion, size: int): PBigChunk =
  # use first fit for now:
  sysAssert((size and PageMask) == 0, "getBigChunk 1")
  sysAssert(size > 0, "getBigChunk 2")
  result = a.freeChunksList
  block search:
    while result != nil:
      sysAssert chunkUnused(result), "getBigChunk 3"
      if result.size == size:
        listRemove(a.freeChunksList, result)
        break search
      elif result.size > size:
        listRemove(a.freeChunksList, result)
        splitChunk(a, result, size)
        break search
      result = result.next
      sysAssert result != a.freeChunksList, "getBigChunk 4"
    if size < InitialMemoryRequest:
      result = requestOsChunks(a, InitialMemoryRequest)
      splitChunk(a, result, size)
    else:
      result = requestOsChunks(a, size)
      # if we over allocated split the chunk:
      if result.size > size:
        splitChunk(a, result, size)
  result.prevSize = 0 # XXX why is this needed?
  result.used = true
  incl(a, a.chunkStarts, pageIndex(result))
  dec(a.freeMem, size)

proc getSmallChunk(a: var MemRegion): PSmallChunk =
  var res = getBigChunk(a, PageSize)
  sysAssert res.prev == nil, "getSmallChunk 1"
  sysAssert res.next == nil, "getSmallChunk 2"
  result = cast[PSmallChunk](res)

# -----------------------------------------------------------------------------
proc isAllocatedPtr(a: MemRegion, p: pointer): bool {.benign.}

when true:
  template allocInv(a: MemRegion): bool = true
else:
  proc allocInv(a: MemRegion): bool =
    ## checks some (not all yet) invariants of the allocator's data structures.
    for s in low(a.freeSmallChunks)..high(a.freeSmallChunks):
      var c = a.freeSmallChunks[s]
      while not (c == nil):
        if c.next == c:
          echo "[SYSASSERT] c.next == c"
          return false
        if not (c.size == s * MemAlign):
          echo "[SYSASSERT] c.size != s * MemAlign"
          return false
        var it = c.freeList
        while not (it == nil):
          if not (it.zeroField == 0):
            echo "[SYSASSERT] it.zeroField != 0"
            c_printf("%ld %p\n", it.zeroField, it)
            return false
          it = it.next
        c = c.next
    result = true

proc rawAlloc(a: var MemRegion, requestedSize: int): pointer =
  sysAssert(allocInv(a), "rawAlloc: begin")
  sysAssert(roundup(65, 8) == 72, "rawAlloc: roundup broken")
  sysAssert(requestedSize >= sizeof(FreeCell), "rawAlloc: requested size too small")
  var size = roundup(requestedSize, MemAlign)
  sysAssert(size >= requestedSize, "insufficient allocated size!")
  #c_fprintf(stdout, "alloc; size: %ld; %ld\n", requestedSize, size)
  if size <= SmallChunkSize-smallChunkOverhead():
    # allocate a small block: for small chunks, we use only its next pointer
    var s = size div MemAlign
    var c = a.freeSmallChunks[s]
    if c == nil:
      c = getSmallChunk(a)
      c.freeList = nil
      sysAssert c.size == PageSize, "rawAlloc 3"
      c.size = size
      c.acc = size
      c.free = SmallChunkSize - smallChunkOverhead() - size
      c.next = nil
      c.prev = nil
      listAdd(a.freeSmallChunks[s], c)
      result = addr(c.data)
      sysAssert((cast[ByteAddress](result) and (MemAlign-1)) == 0, "rawAlloc 4")
    else:
      sysAssert(allocInv(a), "rawAlloc: begin c != nil")
      sysAssert c.next != c, "rawAlloc 5"
      #if c.size != size:
      #  c_fprintf(stdout, "csize: %lld; size %lld\n", c.size, size)
      sysAssert c.size == size, "rawAlloc 6"
      if c.freeList == nil:
        sysAssert(c.acc + smallChunkOverhead() + size <= SmallChunkSize,
                  "rawAlloc 7")
        result = cast[pointer](cast[ByteAddress](addr(c.data)) +% c.acc)
        inc(c.acc, size)
      else:
        result = c.freeList
        sysAssert(c.freeList.zeroField == 0, "rawAlloc 8")
        c.freeList = c.freeList.next
      dec(c.free, size)
      sysAssert((cast[ByteAddress](result) and (MemAlign-1)) == 0, "rawAlloc 9")
      sysAssert(allocInv(a), "rawAlloc: end c != nil")
    sysAssert(allocInv(a), "rawAlloc: before c.free < size")
    if c.free < size:
      sysAssert(allocInv(a), "rawAlloc: before listRemove test")
      listRemove(a.freeSmallChunks[s], c)
      sysAssert(allocInv(a), "rawAlloc: end listRemove test")
    sysAssert(((cast[ByteAddress](result) and PageMask) - smallChunkOverhead()) %%
               size == 0, "rawAlloc 21")
    sysAssert(allocInv(a), "rawAlloc: end small size")
  else:
    size = roundup(requestedSize+bigChunkOverhead(), PageSize)
    # allocate a large block
    var c = getBigChunk(a, size)
    sysAssert c.prev == nil, "rawAlloc 10"
    sysAssert c.next == nil, "rawAlloc 11"
    sysAssert c.size == size, "rawAlloc 12"
    result = addr(c.data)
    sysAssert((cast[ByteAddress](result) and (MemAlign-1)) == 0, "rawAlloc 13")
    if a.root == nil: a.root = bottom
    add(a, a.root, cast[ByteAddress](result), cast[ByteAddress](result)+%size)
  sysAssert(isAccessible(a, result), "rawAlloc 14")
  sysAssert(allocInv(a), "rawAlloc: end")
  when logAlloc: cprintf("rawAlloc: %ld %p\n", requestedSize, result)

proc rawAlloc0(a: var MemRegion, requestedSize: int): pointer =
  result = rawAlloc(a, requestedSize)
  zeroMem(result, requestedSize)

proc rawDealloc(a: var MemRegion, p: pointer) =
  #sysAssert(isAllocatedPtr(a, p), "rawDealloc: no allocated pointer")
  sysAssert(allocInv(a), "rawDealloc: begin")
  var c = pageAddr(p)
  if isSmallChunk(c):
    # `p` is within a small chunk:
    var c = cast[PSmallChunk](c)
    var s = c.size
    sysAssert(((cast[ByteAddress](p) and PageMask) - smallChunkOverhead()) %%
               s == 0, "rawDealloc 3")
    var f = cast[ptr FreeCell](p)
    #echo("setting to nil: ", $cast[ByteAddress](addr(f.zeroField)))
    sysAssert(f.zeroField != 0, "rawDealloc 1")
    f.zeroField = 0
    f.next = c.freeList
    c.freeList = f
    when overwriteFree:
      # set to 0xff to check for usage after free bugs:
      c_memset(cast[pointer](cast[int](p) +% sizeof(FreeCell)), -1'i32,
               s -% sizeof(FreeCell))
    # check if it is not in the freeSmallChunks[s] list:
    if c.free < s:
      # add it to the freeSmallChunks[s] array:
      listAdd(a.freeSmallChunks[s div MemAlign], c)
      inc(c.free, s)
    else:
      inc(c.free, s)
      if c.free == SmallChunkSize-smallChunkOverhead():
        listRemove(a.freeSmallChunks[s div MemAlign], c)
        c.size = SmallChunkSize
        freeBigChunk(a, cast[PBigChunk](c))
    sysAssert(((cast[ByteAddress](p) and PageMask) - smallChunkOverhead()) %%
               s == 0, "rawDealloc 2")
  else:
    # set to 0xff to check for usage after free bugs:
    when overwriteFree: c_memset(p, -1'i32, c.size -% bigChunkOverhead())
    # free big chunk
    var c = cast[PBigChunk](c)
    a.deleted = bottom
    del(a, a.root, cast[int](addr(c.data)))
    freeBigChunk(a, c)
  sysAssert(allocInv(a), "rawDealloc: end")
  when logAlloc: cprintf("rawDealloc: %p\n", p)

proc isAllocatedPtr(a: MemRegion, p: pointer): bool =
  if isAccessible(a, p):
    var c = pageAddr(p)
    if not chunkUnused(c):
      if isSmallChunk(c):
        var c = cast[PSmallChunk](c)
        var offset = (cast[ByteAddress](p) and (PageSize-1)) -%
                     smallChunkOverhead()
        result = (c.acc >% offset) and (offset %% c.size == 0) and
          (cast[ptr FreeCell](p).zeroField >% 1)
      else:
        var c = cast[PBigChunk](c)
        result = p == addr(c.data) and cast[ptr FreeCell](p).zeroField >% 1

proc prepareForInteriorPointerChecking(a: var MemRegion) {.inline.} =
  a.minLargeObj = lowGauge(a.root)
  a.maxLargeObj = highGauge(a.root)

proc interiorAllocatedPtr(a: MemRegion, p: pointer): pointer =
  if isAccessible(a, p):
    var c = pageAddr(p)
    if not chunkUnused(c):
      if isSmallChunk(c):
        var c = cast[PSmallChunk](c)
        var offset = (cast[ByteAddress](p) and (PageSize-1)) -%
                     smallChunkOverhead()
        if c.acc >% offset:
          sysAssert(cast[ByteAddress](addr(c.data)) +% offset ==
                    cast[ByteAddress](p), "offset is not what you think it is")
          var d = cast[ptr FreeCell](cast[ByteAddress](addr(c.data)) +%
                    offset -% (offset %% c.size))
          if d.zeroField >% 1:
            result = d
            sysAssert isAllocatedPtr(a, result), " result wrong pointer!"
      else:
        var c = cast[PBigChunk](c)
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
        var c = cast[PBigChunk](pageAddr(k))
        sysAssert(addr(c.data) == k, " k is not the same as addr(c.data)!")
        if cast[ptr FreeCell](k).zeroField >% 1:
          result = k
          sysAssert isAllocatedPtr(a, result), " result wrong pointer!"

proc ptrSize(p: pointer): int =
  var x = cast[pointer](cast[ByteAddress](p) -% sizeof(FreeCell))
  var c = pageAddr(p)
  sysAssert(not chunkUnused(c), "ptrSize")
  result = c.size -% sizeof(FreeCell)
  if not isSmallChunk(c):
    dec result, bigChunkOverhead()

proc alloc(allocator: var MemRegion, size: Natural): pointer =
  result = rawAlloc(allocator, size+sizeof(FreeCell))
  cast[ptr FreeCell](result).zeroField = 1 # mark it as used
  sysAssert(not isAllocatedPtr(allocator, result), "alloc")
  result = cast[pointer](cast[ByteAddress](result) +% sizeof(FreeCell))
  track("alloc", result, size)

proc alloc0(allocator: var MemRegion, size: Natural): pointer =
  result = alloc(allocator, size)
  zeroMem(result, size)

proc dealloc(allocator: var MemRegion, p: pointer) =
  sysAssert(p != nil, "dealloc 0")
  var x = cast[pointer](cast[ByteAddress](p) -% sizeof(FreeCell))
  sysAssert(x != nil, "dealloc 1")
  sysAssert(isAccessible(allocator, x), "is not accessible")
  sysAssert(cast[ptr FreeCell](x).zeroField == 1, "dealloc 2")
  rawDealloc(allocator, x)
  sysAssert(not isAllocatedPtr(allocator, x), "dealloc 3")
  track("dealloc", p, 0)

proc realloc(allocator: var MemRegion, p: pointer, newsize: Natural): pointer =
  if newsize > 0:
    result = alloc0(allocator, newsize)
    if p != nil:
      copyMem(result, p, ptrSize(p))
      dealloc(allocator, p)
  elif p != nil:
    dealloc(allocator, p)

proc deallocOsPages(a: var MemRegion) =
  # we free every 'ordinarily' allocated page by iterating over the page bits:
  for p in elements(a.chunkStarts):
    var page = cast[PChunk](p shl PageShift)
    when not doNotUnmap:
      var size = if page.size < PageSize: PageSize else: page.size
      osDeallocPages(page, size)
    else:
      # Linux on PowerPC for example frees MORE than asked if 'munmap'
      # receives the start of an originally mmap'ed memory block. This is not
      # too bad, but we must not access 'page.size' then as that could trigger
      # a segfault. But we don't need to access 'page.size' here anyway,
      # because calling munmap with PageSize suffices:
      osDeallocPages(page, PageSize)
  # And then we free the pages that are in use for the page bits:
  llDeallocAll(a)

proc getFreeMem(a: MemRegion): int {.inline.} = result = a.freeMem
proc getTotalMem(a: MemRegion): int {.inline.} = result = a.currMem
proc getOccupiedMem(a: MemRegion): int {.inline.} =
  result = a.currMem - a.freeMem

# ---------------------- thread memory region -------------------------------

template instantiateForRegion(allocator: expr) =
  when defined(fulldebug):
    proc interiorAllocatedPtr*(p: pointer): pointer =
      result = interiorAllocatedPtr(allocator, p)

    proc isAllocatedPtr*(p: pointer): bool =
      let p = cast[pointer](cast[ByteAddress](p)-%ByteAddress(sizeof(Cell)))
      result = isAllocatedPtr(allocator, p)

  proc deallocOsPages = deallocOsPages(allocator)

  proc alloc(size: Natural): pointer =
    result = alloc(allocator, size)

  proc alloc0(size: Natural): pointer =
    result = alloc0(allocator, size)

  proc dealloc(p: pointer) =
    dealloc(allocator, p)

  proc realloc(p: pointer, newsize: Natural): pointer =
    result = realloc(allocator, p, newSize)

  when false:
    proc countFreeMem(): int =
      # only used for assertions
      var it = allocator.freeChunksList
      while it != nil:
        inc(result, it.size)
        it = it.next

  proc getFreeMem(): int =
    result = allocator.freeMem
    #sysAssert(result == countFreeMem())

  proc getTotalMem(): int = return allocator.currMem
  proc getOccupiedMem(): int = return getTotalMem() - getFreeMem()

  # -------------------- shared heap region ----------------------------------
  when hasThreadSupport:
    var sharedHeap: MemRegion
    var heapLock: SysLock
    initSysLock(heapLock)

  proc allocShared(size: Natural): pointer =
    when hasThreadSupport:
      acquireSys(heapLock)
      result = alloc(sharedHeap, size)
      releaseSys(heapLock)
    else:
      result = alloc(size)

  proc allocShared0(size: Natural): pointer =
    result = allocShared(size)
    zeroMem(result, size)

  proc deallocShared(p: pointer) =
    when hasThreadSupport:
      acquireSys(heapLock)
      dealloc(sharedHeap, p)
      releaseSys(heapLock)
    else:
      dealloc(p)

  proc reallocShared(p: pointer, newsize: Natural): pointer =
    when hasThreadSupport:
      acquireSys(heapLock)
      result = realloc(sharedHeap, p, newsize)
      releaseSys(heapLock)
    else:
      result = realloc(p, newSize)

  when hasThreadSupport:

    template sharedMemStatsShared(v: int) {.immediate.} =
      acquireSys(heapLock)
      result = v
      releaseSys(heapLock)

    proc getFreeSharedMem(): int =
      sharedMemStatsShared(sharedHeap.freeMem)

    proc getTotalSharedMem(): int =
      sharedMemStatsShared(sharedHeap.currMem)

    proc getOccupiedSharedMem(): int =
      sharedMemStatsShared(sharedHeap.currMem - sharedHeap.freeMem)

{.pop.}
