#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Low level allocator for Nimrod. Has been designed to support the GC.
# TODO: 
# - eliminate "used" field
# - make searching for block O(1)

# ------------ platform specific chunk allocation code -----------------------

when defined(posix): 
  const
    PROT_READ  = 1             # page can be read 
    PROT_WRITE = 2             # page can be written 
    MAP_PRIVATE = 2            # Changes are private 
  
  when defined(linux) or defined(aix):
    const MAP_ANONYMOUS = 0x20       # don't use a file
  elif defined(macosx) or defined(bsd):
    const MAP_ANONYMOUS = 0x1000
  elif defined(solaris): 
    const MAP_ANONYMOUS = 0x100
  else:
    {.error: "Port memory manager to your platform".}

  proc mmap(adr: pointer, len: int, prot, flags, fildes: cint,
            off: int): pointer {.header: "<sys/mman.h>".}

  proc munmap(adr: pointer, len: int) {.header: "<sys/mman.h>".}
  
  proc osAllocPages(size: int): pointer {.inline.} = 
    result = mmap(nil, size, PROT_READ or PROT_WRITE, 
                           MAP_PRIVATE or MAP_ANONYMOUS, -1, 0)
    if result == nil or result == cast[pointer](-1):
      raiseOutOfMem()
      
  proc osDeallocPages(p: pointer, size: int) {.inline} =
    when reallyOsDealloc: munmap(p, size)
  
elif defined(windows): 
  const
    MEM_RESERVE = 0x2000 
    MEM_COMMIT = 0x1000
    MEM_TOP_DOWN = 0x100000
    PAGE_READWRITE = 0x04

    MEM_DECOMMIT = 0x4000
    MEM_RELEASE = 0x8000

  proc VirtualAlloc(lpAddress: pointer, dwSize: int, flAllocationType,
                    flProtect: int32): pointer {.
                    header: "<windows.h>", stdcall.}
  
  proc VirtualFree(lpAddress: pointer, dwSize: int, 
                   dwFreeType: int32) {.header: "<windows.h>", stdcall.}
  
  proc osAllocPages(size: int): pointer {.inline.} = 
    result = VirtualAlloc(nil, size, MEM_RESERVE or MEM_COMMIT,
                          PAGE_READWRITE)
    if result == nil: raiseOutOfMem()

  proc osDeallocPages(p: pointer, size: int) {.inline.} = 
    # according to Microsoft, 0 is the only correct value here:
    when reallyOsDealloc: VirtualFree(p, 0, MEM_RELEASE)

else: 
  {.error: "Port memory manager to your platform".}

# --------------------- end of non-portable code -----------------------------

# We manage *chunks* of memory. Each chunk is a multiple of the page size.
# Each chunk starts at an address that is divisible by the page size. Chunks
# that are bigger than ``ChunkOsReturn`` are returned back to the operating
# system immediately.

const
  ChunkOsReturn = 256 * PageSize
  InitialMemoryRequest = ChunkOsReturn div 2 # < ChunkOsReturn!
  SmallChunkSize = PageSize

type 
  PTrunk = ptr TTrunk
  TTrunk {.final.} = object 
    next: PTrunk         # all nodes are connected with this pointer
    key: int             # start address at bit 0
    bits: array[0..IntsPerTrunk-1, int] # a bit vector
  
  TTrunkBuckets = array[0..1023, PTrunk]
  TIntSet {.final.} = object 
    data: TTrunkBuckets
  
type
  TAlignType = biggestFloat
  TFreeCell {.final, pure.} = object
    next: ptr TFreeCell  # next free cell in chunk (overlaid with refcount)
    zeroField: int       # 0 means cell is not used (overlaid with typ field)
                         # 1 means cell is manually managed pointer

  PChunk = ptr TBaseChunk
  PBigChunk = ptr TBigChunk
  PSmallChunk = ptr TSmallChunk
  TBaseChunk {.pure.} = object
    prevSize: int        # size of previous chunk; for coalescing
    size: int            # if < PageSize it is a small chunk
    used: bool           # later will be optimized into prevSize...
  
  TSmallChunk = object of TBaseChunk
    next, prev: PSmallChunk  # chunks of the same size
    freeList: ptr TFreeCell
    free: int            # how many bytes remain    
    acc: int             # accumulator for small object allocation
    data: TAlignType     # start of usable memory
  
  TBigChunk = object of TBaseChunk # not necessarily > PageSize!
    next: PBigChunk      # chunks of the same (or bigger) size
    prev: PBigChunk
    align: int
    data: TAlignType     # start of usable memory

template smallChunkOverhead(): expr = sizeof(TSmallChunk)-sizeof(TAlignType)
template bigChunkOverhead(): expr = sizeof(TBigChunk)-sizeof(TAlignType)

proc roundup(x, v: int): int {.inline.} = 
  result = (x + (v-1)) and not (v-1)
  assert(result >= x)
  #return ((-x) and (v-1)) +% x

assert(roundup(14, PageSize) == PageSize)
assert(roundup(15, 8) == 16)
assert(roundup(65, 8) == 72)

# ------------- chunk table ---------------------------------------------------
# We use a PtrSet of chunk starts and a table[Page, chunksize] for chunk
# endings of big chunks. This is needed by the merging operation. The only
# remaining operation is best-fit for big chunks. Since there is a size-limit
# for big chunks (because greater than the limit means they are returned back
# to the OS), a fixed size array can be used. 

type
  PLLChunk = ptr TLLChunk
  TLLChunk {.pure.} = object ## *low-level* chunk
    size: int                # remaining size
    acc: int                 # accumulator
    
  TAllocator {.final, pure.} = object
    llmem: PLLChunk
    currMem, maxMem, freeMem: int # memory sizes (allocated from OS)
    freeSmallChunks: array[0..SmallChunkSize div MemAlign-1, PSmallChunk]
    freeChunksList: PBigChunk # XXX make this a datastructure with O(1) access
    chunkStarts: TIntSet
   
proc incCurrMem(a: var TAllocator, bytes: int) {.inline.} = 
  inc(a.currMem, bytes)

proc decCurrMem(a: var TAllocator, bytes: int) {.inline.} =
  a.maxMem = max(a.maxMem, a.currMem)
  dec(a.currMem, bytes)

proc getMaxMem(a: var TAllocator): int =
  # Since we update maxPagesCount only when freeing pages, 
  # maxPagesCount may not be up to date. Thus we use the
  # maximum of these both values here:
  return max(a.currMem, a.maxMem)
   
var
  allocator: TAllocator
    
proc llAlloc(a: var TAllocator, size: int): pointer =
  # *low-level* alloc for the memory managers data structures. Deallocation
  # is never done.
  if a.llmem == nil or size > a.llmem.size:
    var request = roundup(size+sizeof(TLLChunk), PageSize)
    a.llmem = cast[PLLChunk](osAllocPages(request))
    incCurrMem(a, request)
    a.llmem.size = request - sizeof(TLLChunk)
    a.llmem.acc = sizeof(TLLChunk)
  result = cast[pointer](cast[TAddress](a.llmem) + a.llmem.acc)
  dec(a.llmem.size, size)
  inc(a.llmem.acc, size)
  zeroMem(result, size)
  
proc IntSetGet(t: TIntSet, key: int): PTrunk = 
  var it = t.data[key and high(t.data)]
  while it != nil: 
    if it.key == key: return it
    it = it.next
  result = nil

proc IntSetPut(t: var TIntSet, key: int): PTrunk = 
  result = IntSetGet(t, key)
  if result == nil:
    result = cast[PTrunk](llAlloc(allocator, sizeof(result[])))
    result.next = t.data[key and high(t.data)]
    t.data[key and high(t.data)] = result
    result.key = key

proc Contains(s: TIntSet, key: int): bool = 
  var t = IntSetGet(s, key shr TrunkShift)
  if t != nil: 
    var u = key and TrunkMask
    result = (t.bits[u shr IntShift] and (1 shl (u and IntMask))) != 0
  else: 
    result = false
  
proc Incl(s: var TIntSet, key: int) = 
  var t = IntSetPut(s, key shr TrunkShift)
  var u = key and TrunkMask
  t.bits[u shr IntShift] = t.bits[u shr IntShift] or (1 shl (u and IntMask))

proc Excl(s: var TIntSet, key: int) = 
  var t = IntSetGet(s, key shr TrunkShift)
  if t != nil:
    var u = key and TrunkMask
    t.bits[u shr IntShift] = t.bits[u shr IntShift] and not
        (1 shl (u and IntMask))

proc ContainsOrIncl(s: var TIntSet, key: int): bool = 
  var t = IntSetGet(s, key shr TrunkShift)
  if t != nil: 
    var u = key and TrunkMask
    result = (t.bits[u shr IntShift] and (1 shl (u and IntMask))) != 0
    if not result: 
      t.bits[u shr IntShift] = t.bits[u shr IntShift] or
          (1 shl (u and IntMask))
  else: 
    Incl(s, key)
    result = false
   
# ------------- chunk management ----------------------------------------------
proc pageIndex(c: PChunk): int {.inline.} = 
  result = cast[TAddress](c) shr PageShift

proc pageIndex(p: pointer): int {.inline.} = 
  result = cast[TAddress](p) shr PageShift

proc pageAddr(p: pointer): PChunk {.inline.} = 
  result = cast[PChunk](cast[TAddress](p) and not PageMask)
  assert(Contains(allocator.chunkStarts, pageIndex(result)))

var lastSize = PageSize

proc requestOsChunks(a: var TAllocator, size: int): PBigChunk = 
  incCurrMem(a, size)
  inc(a.freeMem, size)
  result = cast[PBigChunk](osAllocPages(size))
  assert((cast[TAddress](result) and PageMask) == 0)
  #zeroMem(result, size)
  result.next = nil
  result.prev = nil
  result.used = false
  result.size = size
  # update next.prevSize:
  var nxt = cast[TAddress](result) +% size
  assert((nxt and PageMask) == 0)
  var next = cast[PChunk](nxt)
  if pageIndex(next) in a.chunkStarts:
    #echo("Next already allocated!")
    next.prevSize = size
  # set result.prevSize:
  var prv = cast[TAddress](result) -% lastSize
  assert((nxt and PageMask) == 0)
  var prev = cast[PChunk](prv)
  if pageIndex(prev) in a.chunkStarts and prev.size == lastSize:
    #echo("Prev already allocated!")
    result.prevSize = lastSize
  else:
    result.prevSize = 0 # unknown
  lastSize = size # for next request

proc freeOsChunks(a: var TAllocator, p: pointer, size: int) = 
  # update next.prevSize:
  var c = cast[PChunk](p)
  var nxt = cast[TAddress](p) +% c.size
  assert((nxt and PageMask) == 0)
  var next = cast[PChunk](nxt)
  if pageIndex(next) in a.chunkStarts:
    next.prevSize = 0 # XXX used
  excl(a.chunkStarts, pageIndex(p))
  osDeallocPages(p, size)
  decCurrMem(a, size)
  dec(a.freeMem, size)
  #c_fprintf(c_stdout, "[Alloc] back to OS: %ld\n", size)

proc isAccessible(p: pointer): bool {.inline.} = 
  result = Contains(allocator.chunkStarts, pageIndex(p))

proc contains[T](list, x: T): bool = 
  var it = list
  while it != nil:
    if it == x: return true
    it = it.next
    
proc writeFreeList(a: TAllocator) =
  var it = a.freeChunksList
  c_fprintf(c_stdout, "freeChunksList: %p\n", it)
  while it != nil: 
    c_fprintf(c_stdout, "it: %p, next: %p, prev: %p\n", 
              it, it.next, it.prev)
    it = it.next

proc ListAdd[T](head: var T, c: T) {.inline.} = 
  assert(c notin head)
  assert c.prev == nil
  assert c.next == nil
  c.next = head
  if head != nil: 
    assert head.prev == nil
    head.prev = c
  head = c

proc ListRemove[T](head: var T, c: T) {.inline.} =
  assert(c in head)
  if c == head: 
    head = c.next
    assert c.prev == nil
    if head != nil: head.prev = nil
  else:
    assert c.prev != nil
    c.prev.next = c.next
    if c.next != nil: c.next.prev = c.prev
  c.next = nil
  c.prev = nil
  
proc isSmallChunk(c: PChunk): bool {.inline.} = 
  return c.size <= SmallChunkSize-smallChunkOverhead()
  
proc chunkUnused(c: PChunk): bool {.inline.} = 
  result = not c.used
  
proc updatePrevSize(a: var TAllocator, c: PBigChunk, 
                    prevSize: int) {.inline.} = 
  var ri = cast[PChunk](cast[TAddress](c) +% c.size)
  assert((cast[TAddress](ri) and PageMask) == 0)
  if isAccessible(ri):
    ri.prevSize = prevSize
  
proc freeBigChunk(a: var TAllocator, c: PBigChunk) = 
  var c = c
  assert(c.size >= PageSize)
  inc(a.freeMem, c.size)
  when coalescRight:
    var ri = cast[PChunk](cast[TAddress](c) +% c.size)
    assert((cast[TAddress](ri) and PageMask) == 0)
    if isAccessible(ri) and chunkUnused(ri):
      assert(not isSmallChunk(ri))
      if not isSmallChunk(ri):
        ListRemove(a.freeChunksList, cast[PBigChunk](ri))
        inc(c.size, ri.size)
        excl(a.chunkStarts, pageIndex(ri))
  when coalescLeft:
    if c.prevSize != 0: 
      var le = cast[PChunk](cast[TAddress](c) -% c.prevSize)
      assert((cast[TAddress](le) and PageMask) == 0)
      if isAccessible(le) and chunkUnused(le):
        assert(not isSmallChunk(le))
        if not isSmallChunk(le):
          ListRemove(a.freeChunksList, cast[PBigChunk](le))
          inc(le.size, c.size)
          excl(a.chunkStarts, pageIndex(c))
          c = cast[PBigChunk](le)

  if c.size < ChunkOsReturn: 
    incl(a.chunkStarts, pageIndex(c))
    updatePrevSize(a, c, c.size)
    ListAdd(a.freeChunksList, c)
    c.used = false
  else:
    freeOsChunks(a, c, c.size)

proc splitChunk(a: var TAllocator, c: PBigChunk, size: int) = 
  var rest = cast[PBigChunk](cast[TAddress](c) +% size)
  assert(rest notin a.freeChunksList)
  rest.size = c.size - size
  rest.used = false
  rest.next = nil
  rest.prev = nil
  rest.prevSize = size
  updatePrevSize(a, c, rest.size)
  c.size = size
  incl(a.chunkStarts, pageIndex(rest))
  ListAdd(a.freeChunksList, rest)

proc getBigChunk(a: var TAllocator, size: int): PBigChunk = 
  # use first fit for now:
  assert((size and PageMask) == 0)
  assert(size > 0)
  result = a.freeChunksList
  block search:
    while result != nil:
      assert chunkUnused(result)
      if result.size == size: 
        ListRemove(a.freeChunksList, result)
        break search
      elif result.size > size:
        ListRemove(a.freeChunksList, result)
        splitChunk(a, result, size)
        break search
      result = result.next
      assert result != a.freeChunksList
    if size < InitialMemoryRequest: 
      result = requestOsChunks(a, InitialMemoryRequest)
      splitChunk(a, result, size)
    else:
      result = requestOsChunks(a, size)
  result.prevSize = 0 # XXX why is this needed?
  result.used = true
  incl(a.chunkStarts, pageIndex(result))
  dec(a.freeMem, size)

proc getSmallChunk(a: var TAllocator): PSmallChunk = 
  var res = getBigChunk(a, PageSize)
  assert res.prev == nil
  assert res.next == nil
  result = cast[PSmallChunk](res)

# -----------------------------------------------------------------------------

proc getCellSize(p: pointer): int {.inline.} = 
  var c = pageAddr(p)
  result = c.size
  
proc rawAlloc(a: var TAllocator, requestedSize: int): pointer =
  assert(roundup(65, 8) == 72)
  assert requestedSize >= sizeof(TFreeCell)
  var size = roundup(requestedSize, MemAlign)
  #c_fprintf(c_stdout, "alloc; size: %ld; %ld\n", requestedSize, size)
  if size <= SmallChunkSize-smallChunkOverhead(): 
    # allocate a small block: for small chunks, we use only its next pointer
    var s = size div MemAlign
    var c = a.freeSmallChunks[s]
    if c == nil: 
      c = getSmallChunk(a)
      c.freeList = nil
      assert c.size == PageSize
      c.size = size
      c.acc = size
      c.free = SmallChunkSize - smallChunkOverhead() - size
      c.next = nil
      c.prev = nil
      ListAdd(a.freeSmallChunks[s], c)
      result = addr(c.data)
      assert((cast[TAddress](result) and (MemAlign-1)) == 0)
    else:
      assert c.next != c
      #if c.size != size:
      #  c_fprintf(c_stdout, "csize: %lld; size %lld\n", c.size, size)
      assert c.size == size
      if c.freeList == nil:
        assert(c.acc + smallChunkOverhead() + size <= SmallChunkSize) 
        result = cast[pointer](cast[TAddress](addr(c.data)) +% c.acc)
        inc(c.acc, size)      
      else:
        result = c.freeList
        assert(c.freeList.zeroField == 0)
        c.freeList = c.freeList.next
      dec(c.free, size)
      assert((cast[TAddress](result) and (MemAlign-1)) == 0)
    if c.free < size: 
      ListRemove(a.freeSmallChunks[s], c)
  else:
    size = roundup(requestedSize+bigChunkOverhead(), PageSize)
    # allocate a large block
    var c = getBigChunk(a, size)
    assert c.prev == nil
    assert c.next == nil
    assert c.size == size
    result = addr(c.data)
    assert((cast[TAddress](result) and (MemAlign-1)) == 0)
  assert(isAccessible(result))

proc rawDealloc(a: var TAllocator, p: pointer) = 
  var c = pageAddr(p)
  if isSmallChunk(c):
    # `p` is within a small chunk:
    var c = cast[PSmallChunk](c)
    var s = c.size
    var f = cast[ptr TFreeCell](p)
    #echo("setting to nil: ", $cast[TAddress](addr(f.zeroField)))
    assert(f.zeroField != 0)
    f.zeroField = 0
    f.next = c.freeList
    c.freeList = f
    when overwriteFree: 
      # set to 0xff to check for usage after free bugs:
      c_memset(cast[pointer](cast[int](p) +% sizeof(TFreeCell)), -1'i32, 
               s -% sizeof(TFreeCell))
    # check if it is not in the freeSmallChunks[s] list:
    if c.free < s:
      assert c notin a.freeSmallChunks[s div memAlign]
      # add it to the freeSmallChunks[s] array:
      ListAdd(a.freeSmallChunks[s div memAlign], c)
      inc(c.free, s)
    else:
      inc(c.free, s)
      if c.free == SmallChunkSize-smallChunkOverhead():
        ListRemove(a.freeSmallChunks[s div memAlign], c)
        c.size = SmallChunkSize
        freeBigChunk(a, cast[PBigChunk](c))
  else:
    # set to 0xff to check for usage after free bugs:
    when overwriteFree: c_memset(p, -1'i32, c.size -% bigChunkOverhead())
    # free big chunk
    freeBigChunk(a, cast[PBigChunk](c))

proc isAllocatedPtr(a: TAllocator, p: pointer): bool = 
  if isAccessible(p):
    var c = pageAddr(p)
    if not chunkUnused(c):
      if isSmallChunk(c):
        var c = cast[PSmallChunk](c)
        var offset = (cast[TAddress](p) and (PageSize-1)) -% 
                     smallChunkOverhead()
        result = (c.acc >% offset) and (offset %% c.size == 0) and
          (cast[ptr TFreeCell](p).zeroField >% 1)
      else:
        var c = cast[PBigChunk](c)
        result = p == addr(c.data) and cast[ptr TFreeCell](p).zeroField >% 1

# ---------------------- interface to programs -------------------------------

when not defined(useNimRtl):
  proc alloc(size: int): pointer =
    result = rawAlloc(allocator, size+sizeof(TFreeCell))
    cast[ptr TFreeCell](result).zeroField = 1 # mark it as used
    assert(not isAllocatedPtr(allocator, result))
    result = cast[pointer](cast[TAddress](result) +% sizeof(TFreeCell))

  proc alloc0(size: int): pointer =
    result = alloc(size)
    zeroMem(result, size)

  proc dealloc(p: pointer) =
    var x = cast[pointer](cast[TAddress](p) -% sizeof(TFreeCell))
    assert(cast[ptr TFreeCell](x).zeroField == 1)
    rawDealloc(allocator, x)
    assert(not isAllocatedPtr(allocator, x))

  proc ptrSize(p: pointer): int =
    var x = cast[pointer](cast[TAddress](p) -% sizeof(TFreeCell))
    result = pageAddr(x).size - sizeof(TFreeCell)

  proc realloc(p: pointer, newsize: int): pointer =
    if newsize > 0:
      result = alloc(newsize)
      if p != nil:
        copyMem(result, p, ptrSize(p))
        dealloc(p)
    elif p != nil:
      dealloc(p)

  proc countFreeMem(): int =
    # only used for assertions
    var it = allocator.freeChunksList
    while it != nil:
      inc(result, it.size)
      it = it.next

  proc getFreeMem(): int = 
    result = allocator.freeMem
    #assert(result == countFreeMem())

  proc getTotalMem(): int = return allocator.currMem
  proc getOccupiedMem(): int = return getTotalMem() - getFreeMem()

when isMainModule:
  const iterations = 4000_000
  incl(allocator.chunkStarts, 11)
  assert 11 in allocator.chunkStarts
  excl(allocator.chunkStarts, 11)
  assert 11 notin allocator.chunkStarts
  var p: array [1..iterations, pointer]
  for i in 7..7:
    var x = i * 8
    for j in 1.. iterations:
      p[j] = alloc(allocator, x)
    for j in 1..iterations:
      assert isAllocatedPtr(allocator, p[j])
    echo($i, " used memory: ", $(allocator.currMem))
    for j in countdown(iterations, 1):
      #echo("j: ", $j)
      dealloc(allocator, p[j])
      assert(not isAllocatedPtr(allocator, p[j]))
    echo($i, " after freeing: ", $(allocator.currMem))
    
