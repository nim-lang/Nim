#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Low level allocator for Nimrod.

# ------------ platform specific chunk allocation code -----------------------

when defined(posix): 
  const # XXX: make these variables for portability?
    PROT_READ  = 1             # page can be read 
    PROT_WRITE = 2             # page can be written 
    PROT_EXEC  = 4             # page can be executed 
    PROT_NONE  = 0             # page can not be accessed 

    MAP_SHARED    = 1          # Share changes 
    MAP_PRIVATE   = 2          # Changes are private 
    MAP_TYPE      = 0xf        # Mask for type of mapping 
    MAP_FIXED     = 0x10       # Interpret addr exactly 
    MAP_ANONYMOUS = 0x20       # don't use a file 

    MAP_GROWSDOWN  = 0x100     # stack-like segment 
    MAP_DENYWRITE  = 0x800     # ETXTBSY 
    MAP_EXECUTABLE = 0x1000    # mark it as an executable 
    MAP_LOCKED     = 0x2000    # pages are locked 
    MAP_NORESERVE  = 0x4000    # don't check for reservations 

  proc mmap(adr: pointer, len: int, prot, flags, fildes: cint,
            off: int): pointer {.header: "<sys/mman.h>".}

  proc munmap(adr: pointer, len: int) {.header: "<sys/mman.h>".}
  
  proc osAllocPages(size: int): pointer {.inline.} = 
    result = mmap(nil, size, PROT_READ or PROT_WRITE, 
                           MAP_PRIVATE or MAP_ANONYMOUS, -1, 0)
    if result == nil or result == cast[pointer](-1):
      raiseOutOfMem()
      
  proc osDeallocPages(p: pointer, size: int) {.inline} =
    munmap(p, len)
  
elif defined(windows): 
  const
    MEM_RESERVE = 0x2000 
    MEM_COMMIT = 0x1000
    MEM_TOP_DOWN = 0x100000
    PAGE_READWRITE = 0x04

  proc VirtualAlloc(lpAddress: pointer, dwSize: int, flAllocationType,
                    flProtect: int32): pointer {.
                    header: "<windows.h>", stdcall.}
  
  proc osAllocPages(size: int): pointer {.inline.} = 
    result = VirtualAlloc(nil, size, MEM_RESERVE or MEM_COMMIT,
                          PAGE_READWRITE)
    if result == nil: raiseOutOfMem()

  proc osDeallocPages(p: pointer, size: int) {.inline.} =
    nil

else: 
  {.error: "Port GC to your platform".}

# --------------------- end of non-portable code -----------------------------

# We manage *chunks* of memory. Each chunk is a multiple of the page size.
# The page size may or may not the operating system's page size. Each chunk
# starts at an address that is divisible by the page size. Chunks that are
# bigger than ``ChunkOsReturn`` are returned back to the operating system
# immediately.


# Guess the page size of the system; if it is the
# wrong value, performance may be worse (this is not
# for sure though), but GC still works; must be a power of two!
const
  PageShift = if sizeof(pointer) == 4: 12 else: 13
  PageSize = 1 shl PageShift # on 32 bit systems 4096

  MemAlignment = sizeof(pointer)*2 # minimal memory block that can be allocated
  BitsPerUnit = sizeof(int)*8
    # a "unit" is a word, i.e. 4 bytes
    # on a 32 bit system; I do not use the term "word" because under 32-bit
    # Windows it is sometimes only 16 bits

  BitsPerPage = PageSize div MemAlignment
  UnitsPerPage = BitsPerPage div BitsPerUnit
    # how many units do we need to describe a page:
    # on 32 bit systems this is only 16 (!)

  smallRequest = PageSize div 4
  ChunkOsReturn = 1024 # in pages
  InitialMemoryRequest = ChunkOsReturn div 2 # < ChunkOsReturn!
  debugMemMan = true # we wish to debug the memory manager...

type
  PChunkDesc = ptr TChunkDesc
  TChunkDesc {.final, pure.} = object
    key: TAddress    # address at bit 0
    next: PChunkDesc
    bits: array[0..127, int] # a bit vector

  PChunkDescArray = ptr array[0..1000_000, PChunkDesc]
  TChunkSet {.final, pure.} = object
    counter, max: int
    head: PChunkDesc
    data: PChunkDescArray
  
when sizeof(int) == 4:
  type THalfWord = int16
else:
  type THalfWord = int32
  
type
  TFreeCell {.final, pure.} = object
    zeroField: pointer   # type info nil means cell is not used
    next: ptr TFreeCell  # next free cell in chunk

  PChunk = ptr TChunk
  TChunk {.final, pure.} = object
    size: int            # lowest two bits are used for merging:
                         # bit 0: chunk to the left is accessible and free
                         # bit 1: chunk to the right is accessible and free
    len: int             # for small object allocation
    prev, next: PChunk   # chunks of the same (or bigger) size
                         #len, used: THalfWord # index of next to allocate cell
    freeList: ptr TFreeCell
    data: float          # a float for alignment purposes

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
    size: int
    when sizeof(int) == 4:
      align: int
    
  TAllocator {.final, pure.} = object
    llmem: PLLChunk
    UsedPagesCount, FreePagesCount, maxPagesCount: int
    freeSmallChunks: array[0..smallRequest div MemAlign-1, PChunk]
    freeBigChunks: array[0..ChunkOsReturn-1, PChunk]
    

proc llAlloc(a: var TAllocator, size: int): pointer =
  # *low-level* alloc for the memory managers data structures. Deallocation
  # is never done.
  assert(size <= PageSize-8)
  if a.llmem.size + size > PageSize:
    a.llmem = osGetPages(PageSize)
    inc(a.gUsedPages)
    a.llmem.size = 8
  result = cast[pointer](cast[TAddress](a.llmem) + a.llmem.size)
  inc(llmem.size, size)
  zeroMem(result, size)


const
  InitChunkSetSize = 1024 # must be a power of two!

proc ChunkSetInit(s: var TChunkSet) =
  s.data = cast[PChunkDescArray](llAlloc(InitChunkSetSize * sizeof(PChunkDesc)))
  s.max = InitChunkSetSize-1
  s.counter = 0
  s.head = nil

proc ChunkSetGet(t: TChunkSet, key: TAddress): PChunkDesc =
  var h = cast[int](key) and t.max
  while t.data[h] != nil:
    if t.data[h].key == key: return t.data[h]
    h = nextTry(h, t.max)
  return nil

proc ChunkSetRawInsert(t: TChunkSet, data: PChunkDescArray,
                       desc: PChunkDesc) =
  var h = cast[int](desc.key) and t.max
  while data[h] != nil:
    assert(data[h] != desc)
    h = nextTry(h, t.max)
  assert(data[h] == nil)
  data[h] = desc

proc ChunkSetEnlarge(t: var TChunkSet) =
  var oldMax = t.max
  t.max = ((t.max+1)*2)-1
  var n = cast[PChunkDescArray](llAlloc((t.max + 1) * sizeof(PChunkDescArray)))
  for i in 0 .. oldmax:
    if t.data[i] != nil:
      ChunkSetRawInsert(t, n, t.data[i])
  tlsf_free(t.data)
  t.data = n

proc ChunkSetPut(t: var TChunkSet, key: TAddress): PChunkDesc =
  var h = cast[int](key) and t.max
  while true:
    var x = t.data[h]
    if x == nil: break
    if x.key == key: return x
    h = nextTry(h, t.max)

  if ((t.max+1)*2 < t.counter*3) or ((t.max+1)-t.counter < 4):
    ChunkSetEnlarge(t)
  inc(t.counter)
  h = cast[int](key) and t.max
  while t.data[h] != nil: h = nextTry(h, t.max)
  assert(t.data[h] == nil)
  # the new page descriptor goes into result
  result = cast[PChunkDesc](llAlloc(sizeof(TChunkDesc)))
  result.next = t.head
  result.key = key
  t.head = result
  t.data[h] = result

# ---------- slightly higher level procs --------------------------------------

proc in_Operator(s: TChunkSet, cell: PChunk): bool =
  var u = cast[TAddress](cell)
  var t = ChunkSetGet(s, u shr PageShift)
  if t != nil:
    u = (u %% PageSize) /% MemAlignment
    result = (t.bits[u /% BitsPerUnit] and (1 shl (u %% BitsPerUnit))) != 0
  else:
    result = false

proc incl(s: var TCellSet, cell: PCell) =
  var u = cast[TAddress](cell)
  var t = ChunkSetPut(s, u shr PageShift)
  u = (u %% PageSize) /% MemAlignment
  t.bits[u /% BitsPerUnit] = t.bits[u /% BitsPerUnit] or
    (1 shl (u %% BitsPerUnit))

proc excl(s: var TCellSet, cell: PCell) =
  var u = cast[TAddress](cell)
  var t = ChunkSetGet(s, u shr PageShift)
  if t != nil:
    u = (u %% PageSize) /% MemAlignment
    t.bits[u /% BitsPerUnit] = (t.bits[u /% BitsPerUnit] and
                                  not (1 shl (u %% BitsPerUnit)))

iterator elements(t: TChunkSet): PChunk {.inline.} =
  # while traversing it is forbidden to add pointers to the tree!
  var r = t.head
  while r != nil:
    var i = 0
    while i <= high(r.bits):
      var w = r.bits[i] # taking a copy of r.bits[i] here is correct, because
      # modifying operations are not allowed during traversation
      var j = 0
      while w != 0:         # test all remaining bits for zero
        if (w and 1) != 0:  # the bit is set!
          yield cast[PCell]((r.key shl PageShift) or # +%
                              (i*%BitsPerUnit+%j) *% MemAlignment)
        inc(j)
        w = w shr 1
      inc(i)
    r = r.next


# ------------- chunk management ----------------------------------------------
proc removeChunk(a: var TAllocator, c: PChunk) {.inline.} = 
  if c.prev != nil: c.prev.next = c.next
  if c.next != nil: c.next.prev = c.prev
  if a.freeChunks[c.size div PageSize] == c: 
    a.freeChunks[c.size div PageSize] = c.next
  
proc addChunk(a: var TAllocator, c: PChunk) {.inline.} = 
  var s = abs(c.size) div PageSize
  c.prev = nil
  c.next = a.freeChunks[s]
  a.freeChunks[s] = c

proc freeChunk(a: var TAllocator, c: PChunk) = 
  assert(c.size > 0)
  if c.size < PageSize: c.size = PageSize
  var le = cast[PChunk](cast[TAddress](p) and not PageMask -% PageSize)
  var ri = cast[PChunk](cast[TAddress](p) and not PageMask +% 
                        c.size +% PageSize)
  if isStartOfAChunk(ri) and ri.size < 0:
    removeChunk(a, ri)
    inc(c.size, -ri.size)
  if isEndOfAChunk(le): 
    le = cast[PChunk](cast[TAddress](p) and not PageMask -% 
                      le.chunkStart+PageSize)
    if le.size < 0:
      removeChunk(a, le)
      inc(le.size, c.size)
      addChunk(a, le)
      return
  c.size = -c.size
  addChunk(a, c)

proc splitChunk(a: var TAllocator, c: PChunk, size: int) = 
  var rest = cast[PChunk](cast[TAddress](p) + size)
  rest.size = size - c.size # results in negative number, because rest is free
  addChunk(a, rest)
  # mark pages as accessible:
  ChunkTablePut(a, rest, bitAccessible)
  c.size = size

proc getChunkOfSize(a: var TAllocator, size: int): PChunk = 
  for i in size..high(a.freeChunks):
    result = a.freeChunks[i]
    if result != nil:
      if i != size: splitChunk(a, result, size)
      else: removeChunk(a, result)
      result.prev = nil
      result.next = nil
      break

# -----------------------------------------------------------------------------

proc getChunk(p: pointer): PChunk {.inline.} = 
  result = cast[PChunk](cast[TAddress](p) and not PageMask)

proc getCellSize(p: pointer): int {.inline.} = 
  var c = getChunk(p)
  result = abs(c.size)
  
proc alloc(a: var TAllocator, size: int): pointer =
  if size <= smallRequest: 
    # allocate a small block
    var s = size div MemAlign
    var c = a.freeSmallChunks[s]
    if c == nil: 
      c = getChunkOfSize(0)
      c.freeList = nil
      c.size = size
      a.freeSmallChunks[s] = c
      c.len = 1
      c.used = 1
      c.chunkStart = 0
      result = addr(c.data[0])
    elif c.freeList != nil:
      result = c.freeList
      assert(c.freeList.zeroField == nil)
      c.freeList = c.freeList.next
      inc(c.used)
      if c.freeList == nil: removeChunk(a, c)
    else:
      assert(c.len*size <= high(c.data))
      result = addr(c.data[c.len*size])
      inc(c.len)
      inc(c.used)
      if c.len*size > high(c.data): removeChunk(a, c)
  else:
    # allocate a large block
    var c = getChunkOfSize(size shr PageShift)
    result = addr(c.data[0])
    c.freeList = nil
    c.size = size
    c.len = 0
    c.used = 0
    c.chunkStart = 0

proc dealloc(a: var TAllocator, p: pointer) = 
  var c = getChunk(p)
  if c.size <= smallRequest: 
    # free small block:
    var f = cast[ptr TFreeCell](p)
    f.zeroField = nil
    f.next = c.freeList
    c.freeList = p
    dec(c.used)
    if c.used == 0: freeChunk(c)
  else:
    # free big chunk
    freeChunk(c)

proc realloc(a: var TAllocator, p: pointer, size: int): pointer = 
  # could be made faster, but this is unnecessary, the GC does not use it anyway
  result = alloc(a, size)
  copyMem(result, p, getCellSize(p))
  dealloc(a, p)

proc isAllocatedPtr(a: TAllocator, p: pointer): bool = 
  var c = getChunk(p)
  if c in a.accessibleChunks and c.size > 0:
    result = cast[ptr TFreeCell](p).zeroField != nil
