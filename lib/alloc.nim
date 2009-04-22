#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Low level allocator for Nimrod.
# TODO: 
# - eliminate "used" field
# - make searching for block O(1)

proc raiseOutOfMem {.noinline.} =
  assert false
  quit(1)

# ------------ platform specific chunk allocation code -----------------------

when defined(posix): 
  const # XXX: make these variables for portability?
    PROT_READ  = 1             # page can be read 
    PROT_WRITE = 2             # page can be written 
    MAP_PRIVATE = 2            # Changes are private 
  
  when defined(linux):
    const MAP_ANONYMOUS = 0x20       # don't use a file
  elif defined(macosx):
    const MAP_ANONYMOUS = 0x1000
  else:
    const MAP_ANONYMOUS = 0 # other operating systems may not know about this

  proc mmap(adr: pointer, len: int, prot, flags, fildes: cint,
            off: int): pointer {.header: "<sys/mman.h>".}

  proc munmap(adr: pointer, len: int) {.header: "<sys/mman.h>".}
  
  proc osAllocPages(size: int): pointer {.inline.} = 
    result = mmap(nil, size, PROT_READ or PROT_WRITE, 
                           MAP_PRIVATE or MAP_ANONYMOUS, -1, 0)
    if result == nil or result == cast[pointer](-1):
      raiseOutOfMem()
      
  proc osDeallocPages(p: pointer, size: int) {.inline} =
    munmap(p, size)
  
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
    VirtualFree(p, 0, MEM_RELEASE)

else: 
  {.error: "Port memory manager to your platform".}

# --------------------- end of non-portable code -----------------------------

# We manage *chunks* of memory. Each chunk is a multiple of the page size.
# The page size may or may not the operating system's page size. Each chunk
# starts at an address that is divisible by the page size. Chunks that are
# bigger than ``ChunkOsReturn`` are returned back to the operating system
# immediately.


# Guess the page size of the system; if it is the
# wrong value, performance may be worse (this is not
# for sure though), but GC still works; must be a power of two!
when defined(linux) or defined(windows) or defined(macosx):
  const
    PageShift = 12
    PageSize = 1 shl PageShift # on 32 bit systems 4096
else:
  {.error: "unkown page size".}

const
  PageMask = PageSize-1
  
  SmallChunkSize = PageSize # * 4

  MemAlign = 8 # minimal memory block that can be allocated

  BitsPerPage = PageSize div MemAlign
  UnitsPerPage = BitsPerPage div (sizeof(int)*8)
    # how many ints do we need to describe a page:
    # on 32 bit systems this is only 16 (!)

  ChunkOsReturn = 64 * PageSize
  InitialMemoryRequest = ChunkOsReturn div 2 # < ChunkOsReturn!
  
  # Compile time options:
  coalescRight = true
  coalescLeft = true

const
  TrunkShift = 9
  BitsPerTrunk = 1 shl TrunkShift # needs to be a power of 2 and divisible by 64
  TrunkMask = BitsPerTrunk - 1
  IntsPerTrunk = BitsPerTrunk div (sizeof(int)*8)
  IntShift = 5 + ord(sizeof(int) == 8) # 5 or 6, depending on int width
  IntMask = 1 shl IntShift - 1

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
  TAlignType = float
  TFreeCell {.final, pure.} = object
    next: ptr TFreeCell  # next free cell in chunk (overlaid with refcount)
    zeroField: pointer   # nil means cell is not used (overlaid with typ field)

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
    data: TAlignType     # start of usable memory

template smallChunkOverhead(): expr = sizeof(TSmallChunk)-sizeof(TAlignType)
template bigChunkOverhead(): expr = sizeof(TBigChunk)-sizeof(TAlignType)

proc roundup(x, v: int): int {.inline.} = return ((-x) and (v-1)) +% x

assert(roundup(14, PageSize) == PageSize)
assert(roundup(15, 8) == 16)

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
    currMem, maxMem: int  # currently and maximum used memory size (allocated from OS)
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
    result = cast[PTrunk](llAlloc(allocator, sizeof(result^)))
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
  result = cast[PBigChunk](osAllocPages(size))
  assert((cast[TAddress](result) and PageMask) == 0)
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

proc isAccessible(p: pointer): bool {.inline.} = 
  result = Contains(allocator.chunkStarts, pageIndex(p))

proc ListAdd[T](head: var T, c: T) {.inline.} = 
  assert c.prev == nil
  assert c.next == nil
  c.next = head
  if head != nil: 
    assert head.prev == nil
    head.prev = c
  head = c

proc ListRemove[T](head: var T, c: T) {.inline.} =
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
  #return c.size < SmallChunkSize
  
proc chunkUnused(c: PChunk): bool {.inline.} = 
  result = not c.used
  
proc freeBigChunk(a: var TAllocator, c: PBigChunk) = 
  var c = c
  assert(c.size >= PageSize)
  when coalescRight:
    var ri = cast[PChunk](cast[TAddress](c) +% c.size)
    assert((cast[TAddress](ri) and PageMask) == 0)
    if isAccessible(ri) and chunkUnused(ri):
      if not isSmallChunk(ri):
        ListRemove(a.freeChunksList, cast[PBigChunk](ri))
        inc(c.size, ri.size)
        excl(a.chunkStarts, pageIndex(ri))
  when coalescLeft:
    if c.prevSize != 0: 
      var le = cast[PChunk](cast[TAddress](c) -% c.prevSize)
      assert((cast[TAddress](le) and PageMask) == 0)
      if isAccessible(le) and chunkUnused(le):
        if not isSmallChunk(le):
          ListRemove(a.freeChunksList, cast[PBigChunk](le))
          inc(le.size, c.size)
          excl(a.chunkStarts, pageIndex(c))
          c = cast[PBigChunk](le)

  if c.size < ChunkOsReturn: 
    ListAdd(a.freeChunksList, c)
    c.used = false
  else:
    freeOsChunks(a, c, c.size)

proc splitChunk(a: var TAllocator, c: PBigChunk, size: int) = 
  var rest = cast[PBigChunk](cast[TAddress](c) +% size)
  rest.size = c.size - size
  rest.used = false
  rest.next = nil # XXX
  rest.prev = nil
  rest.prevSize = size
  c.size = size
  incl(a.chunkStarts, pageIndex(rest))
  ListAdd(a.freeChunksList, rest)

proc getBigChunk(a: var TAllocator, size: int): PBigChunk = 
  # use first fit for now:
  assert((size and PageMask) == 0)
  result = a.freeChunksList
  block search:
    while result != nil:
      assert chunkUnused(result)
      if result.size == size: 
        ListRemove(a.freeChunksList, result)
        break search
      elif result.size > size:
        splitChunk(a, result, size)
        ListRemove(a.freeChunksList, result)
        break search
      result = result.next
    if size < InitialMemoryRequest: 
      result = requestOsChunks(a, InitialMemoryRequest)
      splitChunk(a, result, size)
    else:
      result = requestOsChunks(a, size)
  result.prevSize = 0
  result.used = true
  incl(a.chunkStarts, pageIndex(result))

proc getSmallChunk(a: var TAllocator): PSmallChunk = 
  var res = getBigChunk(a, PageSize)
  assert res.prev == nil
  assert res.next == nil
  result = cast[PSmallChunk](res)

# -----------------------------------------------------------------------------

proc getCellSize(p: pointer): int {.inline.} = 
  var c = pageAddr(p)
  result = c.size
  
proc alloc(a: var TAllocator, requestedSize: int): pointer =
  var size = roundup(max(requestedSize, sizeof(TFreeCell)), MemAlign)
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
    else:
      assert c.next != c
      assert c.size == size
      if c.freeList == nil:
        assert(c.acc + smallChunkOverhead() + size <= SmallChunkSize) 
        result = cast[pointer](cast[TAddress](addr(c.data)) +% c.acc)
        inc(c.acc, size)      
      else:
        result = c.freeList
        assert(c.freeList.zeroField == nil)
        c.freeList = c.freeList.next
      dec(c.free, size)
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
  cast[ptr TFreeCell](result).zeroField = cast[ptr TFreeCell](1) # make it != nil
  #echo("setting to one: ", $cast[TAddress](addr(cast[ptr TFreeCell](result).zeroField)))

proc contains(list, x: PSmallChunk): bool = 
  var it = list
  while it != nil:
    if it == x: return true
    it = it.next

proc dealloc(a: var TAllocator, p: pointer) = 
  var c = pageAddr(p)
  if isSmallChunk(c):
    # `p` is within a small chunk:
    var c = cast[PSmallChunk](c)
    var s = c.size
    var f = cast[ptr TFreeCell](p)
    #echo("setting to nil: ", $cast[TAddress](addr(f.zeroField)))
    assert(f.zeroField != nil)
    f.zeroField = nil
    f.next = c.freeList
    c.freeList = f
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
    # free big chunk
    freeBigChunk(a, cast[PBigChunk](c))

proc realloc(a: var TAllocator, p: pointer, size: int): pointer = 
  # could be made faster, but this is unnecessary, the GC does not use it anyway
  result = alloc(a, size)
  copyMem(result, p, getCellSize(p))
  dealloc(a, p)

proc isAllocatedPtr(a: TAllocator, p: pointer): bool = 
  if isAccessible(p):
    var c = pageAddr(p)
    if not chunkUnused(c):
      if isSmallChunk(c):
        result = (cast[TAddress](p) -% cast[TAddress](c) -%
                 smallChunkOverhead()) %% c.size == 0 and
          cast[ptr TFreeCell](p).zeroField != nil
      else:
        var c = cast[PBigChunk](c)
        result = p == addr(c.data)

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
    
