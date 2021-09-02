#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Low level allocator for Nim. Has been designed to support the GC.
{.push profiler:off.}

include osalloc

template track(op, address, size) =
  when defined(memTracker):
    memTrackerOp(op, address, size)

# We manage *chunks* of memory. Each chunk is a multiple of the page size.
# Each chunk starts at an address that is divisible by the page size.

const
  nimMinHeapPages {.intdefine.} = 128 # 0.5 MB
  SmallChunkSize = PageSize
  MaxFli = 30
  MaxLog2Sli = 5 # 32, this cannot be increased without changing 'uint32'
                 # everywhere!
  MaxSli = 1 shl MaxLog2Sli
  FliOffset = 6
  RealFli = MaxFli - FliOffset

  # size of chunks in last matrix bin
  MaxBigChunkSize = 1 shl MaxFli - 1 shl (MaxFli-MaxLog2Sli-1)
  HugeChunkSize = MaxBigChunkSize + 1

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
  FreeCell {.final, pure.} = object
    next: ptr FreeCell  # next free cell in chunk (overlaid with refcount)
    when not defined(gcDestructors):
      zeroField: int       # 0 means cell is not used (overlaid with typ field)
                          # 1 means cell is manually managed pointer
                          # otherwise a PNimType is stored in there
    else:
      alignment: int

  PChunk = ptr BaseChunk
  PBigChunk = ptr BigChunk
  PSmallChunk = ptr SmallChunk
  BaseChunk {.pure, inheritable.} = object
    prevSize: int        # size of previous chunk; for coalescing
                         # 0th bit == 1 if 'used
    size: int            # if < PageSize it is a small chunk

  SmallChunk = object of BaseChunk
    next, prev: PSmallChunk  # chunks of the same size
    freeList: ptr FreeCell
    free: int            # how many bytes remain
    acc: int             # accumulator for small object allocation
    when defined(nimAlignPragma):
      data {.align: MemAlign.}: UncheckedArray[byte]      # start of usable memory
    else:
      data: UncheckedArray[byte]

  BigChunk = object of BaseChunk # not necessarily > PageSize!
    next, prev: PBigChunk    # chunks of the same (or bigger) size
    when defined(nimAlignPragma):
      data {.align: MemAlign.}: UncheckedArray[byte]      # start of usable memory
    else:
      data: UncheckedArray[byte]

template smallChunkOverhead(): untyped = sizeof(SmallChunk)
template bigChunkOverhead(): untyped = sizeof(BigChunk)

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

  HeapLinks = object
    len: int
    chunks: array[30, (PBigChunk, int)]
    next: ptr HeapLinks

  MemRegion = object
    minLargeObj, maxLargeObj: int
    freeSmallChunks: array[0..SmallChunkSize div MemAlign-1, PSmallChunk]
    flBitmap: uint32
    slBitmap: array[RealFli, uint32]
    matrix: array[RealFli, array[MaxSli, PBigChunk]]
    llmem: PLLChunk
    currMem, maxMem, freeMem, occ: int # memory sizes (allocated from OS)
    lastSize: int # needed for the case that OS gives us pages linearly
    chunkStarts: IntSet
    root, deleted, last, freeAvlNodes: PAvlNode
    locked, blockChunkSizeIncrease: bool # if locked, we cannot free pages.
    nextChunkSize: int
    bottomData: AvlNode
    heapLinks: HeapLinks
    when defined(nimTypeNames):
      allocCounter, deallocCounter: int

const
  fsLookupTable: array[byte, int8] = [
    -1'i8, 0, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3,
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    5, 5, 5, 5, 5, 5, 5, 5,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7, 7, 7, 7, 7, 7, 7
  ]

proc msbit(x: uint32): int {.inline.} =
  let a = if x <= 0xff_ff'u32:
            (if x <= 0xff: 0 else: 8)
          else:
            (if x <= 0xff_ff_ff'u32: 16 else: 24)
  result = int(fsLookupTable[byte(x shr a)]) + a

proc lsbit(x: uint32): int {.inline.} =
  msbit(x and ((not x) + 1))

proc setBit(nr: int; dest: var uint32) {.inline.} =
  dest = dest or (1u32 shl (nr and 0x1f))

proc clearBit(nr: int; dest: var uint32) {.inline.} =
  dest = dest and not (1u32 shl (nr and 0x1f))

proc mappingSearch(r, fl, sl: var int) {.inline.} =
  #let t = (1 shl (msbit(uint32 r) - MaxLog2Sli)) - 1
  # This diverges from the standard TLSF algorithm because we need to ensure
  # PageSize alignment:
  let t = roundup((1 shl (msbit(uint32 r) - MaxLog2Sli)), PageSize) - 1
  r = r + t
  r = r and not t
  r = min(r, MaxBigChunkSize)
  fl = msbit(uint32 r)
  sl = (r shr (fl - MaxLog2Sli)) - MaxSli
  dec fl, FliOffset
  sysAssert((r and PageMask) == 0, "mappingSearch: still not aligned")

# See http://www.gii.upv.es/tlsf/files/papers/tlsf_desc.pdf for details of
# this algorithm.

proc mappingInsert(r: int): tuple[fl, sl: int] {.inline.} =
  sysAssert((r and PageMask) == 0, "mappingInsert: still not aligned")
  result.fl = msbit(uint32 r)
  result.sl = (r shr (result.fl - MaxLog2Sli)) - MaxSli
  dec result.fl, FliOffset

template mat(): untyped = a.matrix[fl][sl]

proc findSuitableBlock(a: MemRegion; fl, sl: var int): PBigChunk {.inline.} =
  let tmp = a.slBitmap[fl] and (not 0u32 shl sl)
  result = nil
  if tmp != 0:
    sl = lsbit(tmp)
    result = mat()
  else:
    fl = lsbit(a.flBitmap and (not 0u32 shl (fl + 1)))
    if fl > 0:
      sl = lsbit(a.slBitmap[fl])
      result = mat()

template clearBits(sl, fl) =
  clearBit(sl, a.slBitmap[fl])
  if a.slBitmap[fl] == 0u32:
    # do not forget to cascade:
    clearBit(fl, a.flBitmap)

proc removeChunkFromMatrix(a: var MemRegion; b: PBigChunk) =
  let (fl, sl) = mappingInsert(b.size)
  if b.next != nil: b.next.prev = b.prev
  if b.prev != nil: b.prev.next = b.next
  if mat() == b:
    mat() = b.next
    if mat() == nil:
      clearBits(sl, fl)
  b.prev = nil
  b.next = nil

proc removeChunkFromMatrix2(a: var MemRegion; b: PBigChunk; fl, sl: int) =
  mat() = b.next
  if mat() != nil:
    mat().prev = nil
  else:
    clearBits(sl, fl)
  b.prev = nil
  b.next = nil

proc addChunkToMatrix(a: var MemRegion; b: PBigChunk) =
  let (fl, sl) = mappingInsert(b.size)
  b.prev = nil
  b.next = mat()
  if mat() != nil:
    mat().prev = b
  mat() = b
  setBit(sl, a.slBitmap[fl])
  setBit(fl, a.flBitmap)

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
    when defined(nimAvlcorruption):
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
    when defined(nimAvlcorruption):
      cprintf("tracking location: %p\n", result)
  result.key = key
  result.upperBound = upperBound
  let bottom = getBottom(a)
  result.link[0] = bottom
  result.link[1] = bottom
  result.level = 1
  #when defined(nimAvlcorruption):
  #  track("allocAvlNode", result, sizeof(AvlNode))
  sysAssert(bottom == addr(a.bottomData), "bottom data")
  sysAssert(bottom.link[0] == bottom, "bottom link[0]")
  sysAssert(bottom.link[1] == bottom, "bottom link[1]")

proc deallocAvlNode(a: var MemRegion, n: PAvlNode) {.inline.} =
  n.link[0] = a.freeAvlNodes
  a.freeAvlNodes = n

proc addHeapLink(a: var MemRegion; p: PBigChunk, size: int) =
  var it = addr(a.heapLinks)
  while it != nil and it.len >= it.chunks.len: it = it.next
  if it == nil:
    var n = cast[ptr HeapLinks](llAlloc(a, sizeof(HeapLinks)))
    n.next = a.heapLinks.next
    a.heapLinks.next = n
    n.chunks[0] = (p, size)
    n.len = 1
  else:
    let L = it.len
    it.chunks[L] = (p, size)
    inc it.len

include "system/avltree"

proc llDeallocAll(a: var MemRegion) =
  var it = a.llmem
  while it != nil:
    # we know each block in the list has the size of 1 page:
    var next = it.next
    osDeallocPages(it, PageSize)
    it = next
  a.llmem = nil

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

proc isSmallChunk(c: PChunk): bool {.inline.} =
  result = c.size <= SmallChunkSize-smallChunkOverhead()

proc chunkUnused(c: PChunk): bool {.inline.} =
  result = (c.prevSize and 1) == 0

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

when not defined(gcDestructors):
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

when false:
  proc writeFreeList(a: MemRegion) =
    var it = a.freeChunksList
    c_fprintf(stdout, "freeChunksList: %p\n", it)
    while it != nil:
      c_fprintf(stdout, "it: %p, next: %p, prev: %p, size: %ld\n",
                it, it.next, it.prev, it.size)
      it = it.next

const nimMaxHeap {.intdefine.} = 0

proc requestOsChunks(a: var MemRegion, size: int): PBigChunk =
  when not defined(emscripten):
    if not a.blockChunkSizeIncrease:
      let usedMem = a.occ #a.currMem # - a.freeMem
      when nimMaxHeap != 0:
        if usedMem > nimMaxHeap * 1024 * 1024:
          raiseOutOfMem()
      if usedMem < 64 * 1024:
        a.nextChunkSize = PageSize*4
      else:
        a.nextChunkSize = min(roundup(usedMem shr 2, PageSize), a.nextChunkSize * 2)
        a.nextChunkSize = min(a.nextChunkSize, MaxBigChunkSize)

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
  a.addHeapLink(result, size)
  when defined(debugHeapLinks):
    cprintf("owner: %p; result: %p; next pointer %p; size: %ld\n", addr(a),
      result, result.heapLink, result.size)

  when defined(memtracker):
    trackLocation(addr result.size, sizeof(int))

  sysAssert((cast[ByteAddress](result) and PageMask) == 0, "requestOsChunks 1")
  #zeroMem(result, size)
  result.next = nil
  result.prev = nil
  result.size = size
  # update next.prevSize:
  var nxt = cast[ByteAddress](result) +% size
  sysAssert((nxt and PageMask) == 0, "requestOsChunks 2")
  var next = cast[PChunk](nxt)
  if pageIndex(next) in a.chunkStarts:
    #echo("Next already allocated!")
    next.prevSize = size or (next.prevSize and 1)
  # set result.prevSize:
  var lastSize = if a.lastSize != 0: a.lastSize else: PageSize
  var prv = cast[ByteAddress](result) -% lastSize
  sysAssert((nxt and PageMask) == 0, "requestOsChunks 3")
  var prev = cast[PChunk](prv)
  if pageIndex(prev) in a.chunkStarts and prev.size == lastSize:
    #echo("Prev already allocated!")
    result.prevSize = lastSize or (result.prevSize and 1)
  else:
    result.prevSize = 0 or (result.prevSize and 1) # unknown
    # but do not overwrite 'used' field
  a.lastSize = size # for next request
  sysAssert((cast[int](result) and PageMask) == 0, "requestOschunks: unaligned chunk")

proc isAccessible(a: MemRegion, p: pointer): bool {.inline.} =
  result = contains(a.chunkStarts, pageIndex(p))

proc contains[T](list, x: T): bool =
  var it = list
  while it != nil:
    if it == x: return true
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
    ri.prevSize = prevSize or (ri.prevSize and 1)

proc splitChunk2(a: var MemRegion, c: PBigChunk, size: int): PBigChunk =
  result = cast[PBigChunk](cast[ByteAddress](c) +% size)
  result.size = c.size - size
  track("result.size", addr result.size, sizeof(int))
  # XXX check if these two nil assignments are dead code given
  # addChunkToMatrix's implementation:
  result.next = nil
  result.prev = nil
  # size and not used:
  result.prevSize = size
  sysAssert((size and 1) == 0, "splitChunk 2")
  sysAssert((size and PageMask) == 0,
      "splitChunk: size is not a multiple of the PageSize")
  updatePrevSize(a, c, result.size)
  c.size = size
  incl(a, a.chunkStarts, pageIndex(result))

proc splitChunk(a: var MemRegion, c: PBigChunk, size: int) =
  let rest = splitChunk2(a, c, size)
  addChunkToMatrix(a, rest)

proc freeBigChunk(a: var MemRegion, c: PBigChunk) =
  var c = c
  sysAssert(c.size >= PageSize, "freeBigChunk")
  inc(a.freeMem, c.size)
  c.prevSize = c.prevSize and not 1  # set 'used' to false
  when coalescLeft:
    let prevSize = c.prevSize
    if prevSize != 0:
      var le = cast[PChunk](cast[ByteAddress](c) -% prevSize)
      sysAssert((cast[ByteAddress](le) and PageMask) == 0, "freeBigChunk 4")
      if isAccessible(a, le) and chunkUnused(le):
        sysAssert(not isSmallChunk(le), "freeBigChunk 5")
        if not isSmallChunk(le) and le.size < MaxBigChunkSize:
          removeChunkFromMatrix(a, cast[PBigChunk](le))
          inc(le.size, c.size)
          excl(a.chunkStarts, pageIndex(c))
          c = cast[PBigChunk](le)
          if c.size > MaxBigChunkSize:
            let rest = splitChunk2(a, c, MaxBigChunkSize)
            addChunkToMatrix(a, c)
            c = rest
  when coalescRight:
    var ri = cast[PChunk](cast[ByteAddress](c) +% c.size)
    sysAssert((cast[ByteAddress](ri) and PageMask) == 0, "freeBigChunk 2")
    if isAccessible(a, ri) and chunkUnused(ri):
      sysAssert(not isSmallChunk(ri), "freeBigChunk 3")
      if not isSmallChunk(ri) and c.size < MaxBigChunkSize:
        removeChunkFromMatrix(a, cast[PBigChunk](ri))
        inc(c.size, ri.size)
        excl(a.chunkStarts, pageIndex(ri))
        if c.size > MaxBigChunkSize:
          let rest = splitChunk2(a, c, MaxBigChunkSize)
          addChunkToMatrix(a, rest)
  addChunkToMatrix(a, c)

proc getBigChunk(a: var MemRegion, size: int): PBigChunk =
  sysAssert(size > 0, "getBigChunk 2")
  var size = size # roundup(size, PageSize)
  var fl = 0
  var sl = 0
  mappingSearch(size, fl, sl)
  sysAssert((size and PageMask) == 0, "getBigChunk: unaligned chunk")
  result = findSuitableBlock(a, fl, sl)
  if result == nil:
    if size < nimMinHeapPages * PageSize:
      result = requestOsChunks(a, nimMinHeapPages * PageSize)
      splitChunk(a, result, size)
    else:
      result = requestOsChunks(a, size)
      # if we over allocated split the chunk:
      if result.size > size:
        splitChunk(a, result, size)
  else:
    removeChunkFromMatrix2(a, result, fl, sl)
    if result.size >= size + PageSize:
      splitChunk(a, result, size)
  # set 'used' to to true:
  result.prevSize = 1
  track("setUsedToFalse", addr result.size, sizeof(int))

  incl(a, a.chunkStarts, pageIndex(result))
  dec(a.freeMem, size)

proc getHugeChunk(a: var MemRegion; size: int): PBigChunk =
  result = cast[PBigChunk](osAllocPages(size))
  incCurrMem(a, size)
  # XXX add this to the heap links. But also remove it from it later.
  when false: a.addHeapLink(result, size)
  sysAssert((cast[ByteAddress](result) and PageMask) == 0, "getHugeChunk")
  result.next = nil
  result.prev = nil
  result.size = size
  # set 'used' to to true:
  result.prevSize = 1
  incl(a, a.chunkStarts, pageIndex(result))

proc freeHugeChunk(a: var MemRegion; c: PBigChunk) =
  let size = c.size
  sysAssert(size >= HugeChunkSize, "freeHugeChunk: invalid size")
  excl(a.chunkStarts, pageIndex(c))
  decCurrMem(a, size)
  osDeallocPages(c, size)

proc getSmallChunk(a: var MemRegion): PSmallChunk =
  var res = getBigChunk(a, PageSize)
  sysAssert res.prev == nil, "getSmallChunk 1"
  sysAssert res.next == nil, "getSmallChunk 2"
  result = cast[PSmallChunk](res)

# -----------------------------------------------------------------------------
when not defined(gcDestructors):
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

when false:
  # not yet used by the GCs
  proc rawTryAlloc(a: var MemRegion; requestedSize: int): pointer =
    sysAssert(allocInv(a), "rawAlloc: begin")
    sysAssert(roundup(65, 8) == 72, "rawAlloc: roundup broken")
    sysAssert(requestedSize >= sizeof(FreeCell), "rawAlloc: requested size too small")
    var size = roundup(requestedSize, MemAlign)
    inc a.occ, size
    trackSize(size)
    sysAssert(size >= requestedSize, "insufficient allocated size!")
    #c_fprintf(stdout, "alloc; size: %ld; %ld\n", requestedSize, size)
    if size <= SmallChunkSize-smallChunkOverhead():
      # allocate a small block: for small chunks, we use only its next pointer
      var s = size div MemAlign
      var c = a.freeSmallChunks[s]
      if c == nil:
        result = nil
      else:
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
        if c.free < size:
          listRemove(a.freeSmallChunks[s], c)
          sysAssert(allocInv(a), "rawAlloc: end listRemove test")
        sysAssert(((cast[ByteAddress](result) and PageMask) - smallChunkOverhead()) %%
                  size == 0, "rawAlloc 21")
        sysAssert(allocInv(a), "rawAlloc: end small size")
    else:
      inc size, bigChunkOverhead()
      var fl, sl: int
      mappingSearch(size, fl, sl)
      sysAssert((size and PageMask) == 0, "getBigChunk: unaligned chunk")
      let c = findSuitableBlock(a, fl, sl)
      if c != nil:
        removeChunkFromMatrix2(a, c, fl, sl)
        if c.size >= size + PageSize:
          splitChunk(a, c, size)
        # set 'used' to to true:
        c.prevSize = 1
        incl(a, a.chunkStarts, pageIndex(c))
        dec(a.freeMem, size)
        result = addr(c.data)
        sysAssert((cast[ByteAddress](c) and (MemAlign-1)) == 0, "rawAlloc 13")
        sysAssert((cast[ByteAddress](c) and PageMask) == 0, "rawAlloc: Not aligned on a page boundary")
        if a.root == nil: a.root = getBottom(a)
        add(a, a.root, cast[ByteAddress](result), cast[ByteAddress](result)+%size)
      else:
        result = nil

proc rawAlloc(a: var MemRegion, requestedSize: int): pointer =
  when defined(nimTypeNames):
    inc(a.allocCounter)
  sysAssert(allocInv(a), "rawAlloc: begin")
  sysAssert(roundup(65, 8) == 72, "rawAlloc: roundup broken")
  var size = roundup(requestedSize, MemAlign)
  sysAssert(size >= sizeof(FreeCell), "rawAlloc: requested size too small")

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
        when not defined(gcDestructors):
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
    inc a.occ, size
    trackSize(c.size)
  else:
    size = requestedSize + bigChunkOverhead() #  roundup(requestedSize+bigChunkOverhead(), PageSize)
    # allocate a large block
    var c = if size >= HugeChunkSize: getHugeChunk(a, size)
            else: getBigChunk(a, size)
    sysAssert c.prev == nil, "rawAlloc 10"
    sysAssert c.next == nil, "rawAlloc 11"
    result = addr(c.data)
    sysAssert((cast[ByteAddress](c) and (MemAlign-1)) == 0, "rawAlloc 13")
    sysAssert((cast[ByteAddress](c) and PageMask) == 0, "rawAlloc: Not aligned on a page boundary")
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
  var c = pageAddr(p)
  if isSmallChunk(c):
    # `p` is within a small chunk:
    var c = cast[PSmallChunk](c)
    var s = c.size
    dec a.occ, s
    untrackSize(s)
    sysAssert a.occ >= 0, "rawDealloc: negative occupied memory (case A)"
    sysAssert(((cast[ByteAddress](p) and PageMask) - smallChunkOverhead()) %%
               s == 0, "rawDealloc 3")
    var f = cast[ptr FreeCell](p)
    when not defined(gcDestructors):
      #echo("setting to nil: ", $cast[ByteAddress](addr(f.zeroField)))
      sysAssert(f.zeroField != 0, "rawDealloc 1")
      f.zeroField = 0
    f.next = c.freeList
    c.freeList = f
    when overwriteFree:
      # set to 0xff to check for usage after free bugs:
      nimSetMem(cast[pointer](cast[int](p) +% sizeof(FreeCell)), -1'i32,
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
    when overwriteFree: nimSetMem(p, -1'i32, c.size -% bigChunkOverhead())
    # free big chunk
    var c = cast[PBigChunk](c)
    dec a.occ, c.size
    untrackSize(c.size)
    sysAssert a.occ >= 0, "rawDealloc: negative occupied memory (case B)"
    a.deleted = getBottom(a)
    del(a, a.root, cast[int](addr(c.data)))
    if c.size >= HugeChunkSize: freeHugeChunk(a, c)
    else: freeBigChunk(a, c)
  sysAssert(allocInv(a), "rawDealloc: end")
  when logAlloc: cprintf("dealloc(pointer_%p)\n", p)

when not defined(gcDestructors):
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
  when not defined(gcDestructors):
    var x = cast[pointer](cast[ByteAddress](p) -% sizeof(FreeCell))
    var c = pageAddr(p)
    sysAssert(not chunkUnused(c), "ptrSize")
    result = c.size -% sizeof(FreeCell)
    if not isSmallChunk(c):
      dec result, bigChunkOverhead()
  else:
    var c = pageAddr(p)
    sysAssert(not chunkUnused(c), "ptrSize")
    result = c.size
    if not isSmallChunk(c):
      dec result, bigChunkOverhead()

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
  var it = addr(a.heapLinks)
  while true:
    let next = it.next
    for i in 0..it.len-1:
      let (p, size) = it.chunks[i]
      when defined(debugHeapLinks):
        cprintf("owner %p; dealloc A: %p size: %ld; next: %p\n", addr(a),
          it, it.size, next)
      sysAssert size >= PageSize, "origSize too small"
      osDeallocPages(p, size)
    it = next
    if it == nil: break
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

  when defined(nimFulldebug):
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

  when false:
    proc countFreeMem(): int =
      # only used for assertions
      var it = allocator.freeChunksList
      while it != nil:
        inc(result, it.size)
        it = it.next

  when hasThreadSupport:
    var sharedHeap: MemRegion
    var heapLock: SysLock
    initSysLock(heapLock)

  proc getFreeMem(): int =
    #sysAssert(result == countFreeMem())
    when hasThreadSupport and defined(gcDestructors):
      acquireSys(heapLock)
      result = sharedHeap.freeMem
      releaseSys(heapLock)
    else:
      result = allocator.freeMem

  proc getTotalMem(): int =
    when hasThreadSupport and defined(gcDestructors):
      acquireSys(heapLock)
      result = sharedHeap.currMem
      releaseSys(heapLock)
    else:
      result = allocator.currMem

  proc getOccupiedMem(): int =
    when hasThreadSupport and defined(gcDestructors):
      acquireSys(heapLock)
      result = sharedHeap.occ
      releaseSys(heapLock)
    else:
      result = allocator.occ #getTotalMem() - getFreeMem()

  proc getMaxMem*(): int =
    when hasThreadSupport and defined(gcDestructors):
      acquireSys(heapLock)
      result = getMaxMem(sharedHeap)
      releaseSys(heapLock)
    else:
      result = getMaxMem(allocator)

  when defined(nimTypeNames):
    proc getMemCounters*(): (int, int) = getMemCounters(allocator)

  # -------------------- shared heap region ----------------------------------

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
