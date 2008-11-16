#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# Memory manager. Based on:
# Two Levels Segregate Fit memory allocator (TLSF)
# Version 2.4.2
#
# Written by Miguel Masmano Tello <mimastel@doctor.upv.es>
#
# Thanks to Ismael Ripoll for his suggestions and reviews
#
# Copyright (C) 2008, 2007, 2006, 2005, 2004
# 
# This code is released using a dual license strategy: GPL/LGPL
# You can choose the licence that better fits your requirements.
# 
# Released under the terms of the GNU General Public License Version 2.0
# Released under the terms of the GNU Lesser General Public License Version 2.1


# Some IMPORTANT TLSF parameters
const
  blockAlign = sizeof(pointer) * 2
  maxFli = 30
  maxLog2Sli = 5
  maxSli = 1 shl maxLog2Sli
  
  fliOffset = 6 # tlsf structure just will manage blocks bigger than 128 bytes
  smallBlock = 128
  realFli = MaxFli - fliOffset
  
type
  TFreePtr {.final.} = object
    prev, next: PBhdr
  Pbhdr = ptr Tbhdr
  Tbhdr {.final.} = object
    prevHdr: Pbhdr # this is just valid if the first bit of size is set
    size: int # the size is stored in bytes 
              # bit 0 indicates whether the block is used and
              # bit 1 allows to know whether the previous block is free
    freePtr: TFreePtr # at this offset bhdr.buffer starts (was a union in the
                      # C version)
  TAreaInfo  {.final.} = object  # This structure is embedded at the beginning
                                 # of each area, giving us enough information 
                                 # to cope with a set of areas
    theEnd: Pbhdr
    next: PAreaInfo
  PAreaInfo = ptr TAreaInfo

  TLSF {.final.} = object
    tlsf_signature: int32 # the TLSF's structure signature
    usedSize, maxSize: int
    areaHead: PAreaInfo # A linked list holding all the existing areas

    flBitmap: int32  # the first-level bitmap
                     # This array should have a size of REAL_FLI bits
    slBitmap: array[0..realFli, int32] # the second-level bitmap
    matrix: array [0..realFli, array[0..maxSli, PBhdr]]
  
const
  minBlockSize = sizeof(TFreePtr)
  bhdrOverhead = sizeof(Tbhdr) - minBlockSize
  tlsfSignature = 0x2A59FA59
  ptrMask = sizeof(pointer) - 1
  blockSize = 0xFFFFFFFF - ptrMask
  memAlign = blockAlign - 1
  blockState = 0x1
  prevState = 0x2

  freeBlock = 0x1 # bit 0 of the block size
  usedBlock = 0x0

  prevFree = 0x2 # bit 1 of the block size
  prevUsed = 0x0
  
  defaultAreaSize = 64*1024 # 1024*10
  pageSize = if defined(cpu32): 4096 else: 4096*2
  

proc getNextBlock(adr: pointer, r: int): PBhdr {.inline.} = 
  return cast[PBhdr](cast[TAddress](adr) +% r)

proc roundupSize(r: int): int = return (r +% memAlign) and not memAlign
proc rounddownSize(r: int): int = return r and not memAlign
proc roundup(x, v: int): int = return (((not x)+%1) and (v-%1)) +% x

proc addSize(s: PTLSF, b: Pbhdr) =
  inc(s.usedSize, (b.size and blockSize) + bhdrOverhead)
  s.maxSize = max(s.maxSize, s.usedSize)

proc removeSize(s: PTLSF, b: Pbhdr) =
  dec(s.usedSize, (b.size and blockSize) + bhdrOverhead)

# ------------ platform specific code -----------------------------------------

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

  proc getNewArea(size: var int): pointer {.inline.} = 
    size = roundup(size, PageSize)
    result = mmap(0, size, PROT_READ or PROT_WRITE, 
                           MAP_PRIVATE or MAP_ANONYMOUS, -1, 0)
    if result == nil or result == cast[pointer](-1):
      raiseOutOfMem()
  
elif defined(windows): 
  const
    MEM_RESERVE = 0x2000 
    MEM_COMMIT = 0x1000
    MEM_TOP_DOWN = 0x100000
    PAGE_READWRITE = 0x04

  proc VirtualAlloc(lpAddress: pointer, dwSize: int, flAllocationType,
                    flProtect: int32): pointer {.
                    header: "<windows.h>", stdcall.}
  
  proc getNewArea(size: var int): pointer {.inline.} = 
    size = roundup(size, PageSize)
    result = VirtualAlloc(nil, size, MEM_RESERVE or MEM_COMMIT or MEM_TOP_DOWN,
                          PAGE_READWRITE)
    if result == nil: raiseOutOfMem()

else: 
  {.warning: "Generic code for allocating pages is used".}
  # generic implementation relying on malloc:
  proc malloc(size: int): pointer {.nodecl, importc.}
  
  proc getNewArea(size: var int): pointer {.inline.} = 
    size = roundup(size, PageSize)
    result = malloc(size)
    if result == nil: raiseOutOfMem()

# ---------------------------------------------------------------------------
# small fixed size allocator:

# Design: We manage pages. A page is of constant size, but not necessarily
# the OS's page size. Pages are managed in a hash table taking advantage of
# the fact that the OS is likely to give us pages with contingous numbers. 
# A page contains either small fixed size objects of the same size or 
# variable length objects. An object's size is always aligned at 16 byte
# boundary. Huge objects are dealt with the TLSF algorithm. 
# The design supports iterating over any object in a fast way. 

# A bitset contains any page that starts an allocated page. The page may be
# empty however. This bitset can be used to quickly determine if a given
# page belongs to the GC heap. The design of the memory allocator makes it 
# simple to return unused pages back to the OS.


# Small bocks 
# -----------
#
# If we use a list in the free object's space. Allocation and deallocation are
# O(1). Since any object is of the same size, iteration is quite efficient too.
# However, pointer detection is easy too: Just check if the type-field is nil.
# Deallocation sets it to nil.
# Algorithm:

# i = 0
# f = b.f # first free address
# while i < max: 
#  if a[i] == f: # not a valid block
#    f = f.next  # next free address
#  else:
#    a[i] is a valid object of size s
#  inc(i)

# The zero count table is an array. Since we know that the RC is zero, we can
# use the bits for an index into this array. Thus multiple ZCT tables are not
# difficult to support and insertion and removal is O(1). We use negative
# indexes for this. This makes it even fast enough (and necessary!) to do a ZCT
# removal if the RC is incremented. 
# 

# Huge blocks
# -----------
#
# Huge blocks are always rounded up to a multiple of the page size. These are
# called *strides*. We also need to keep an index structure 
# of (stridesize, pagelist). 
# 

const
  MemAlign = 8
  PageShift = if sizeof(int) == 4: 12 else: 13
  PageSize = 1 shl PageShift
type
  TFreeList {.final.} = object
    next, prev: ptr TFreeList

  TPageDesc {.final.} = object  # the start of a stride always starts with this!
    size: int                   # lowest bit is set, if it is a huge block
    free: ptr TFreeList         # only used if it manages multiple cells
    snext, sprev: ptr TPageDesc # next and prev pagedescs with the same size

  TCellArray {.final.} = object
    i: int # length
    d: ptr array [0..1000_000, TCell]

  TPageManager = table[page, ptr TPageDesc]

  TGcHeap {.final.} = object
    # structure that manages the garbage collected heap
    zct: TCellArray
    stackCells: TCellArray
    smallBlocks: array [PageSize div MemAlign, ptr TPageDesc]
    freeLists: array [PageSize div MemAlign, ptr TFreeList]
    pages: TPageManager
    usedPages: TPageList
    freePages: TPageList

# small blocks: 
proc allocSmall(var h: TGcHeap, size: int): pointer = 
  var s = align(size)
  var f = h.freeLists[s]
  if f != nil: 
    f.prev = f.next # remove from list
    f.next.prev = f.prev
    return f
  var p = h.smallBlocks[s]
  if p == nil or p.free == nil:
    p = newSmallBlock(s, p)
    h.smallBlocks[s] = p
  


proc decRef(cell: PCell) {.inline.} =
  assert(cell in ct.AT)
  assert(cell.refcount > 0) # this should be the case!
  assert(seqCheck(cell))
  dec(cell.refcount)
  if cell.refcount == 0:
    # add to zero count table:
    zct.d[zct.i] = cell
    cell.recfcount = -zct.i
    inc(zct.i)

proc incRef(cell: PCell) {.inline.} =
  assert(seqCheck(cell))
  if cell.refcount < 0: 
    # remove from zero count table:
    zct.d[-cell.refcount] = zct.d[zct.i-1]
    dec(zct.i) 
    cell.refcount = 1
  else:
    inc(cell.refcount)

proc asgnRef(dest: ppointer, src: pointer) =
  # the code generator calls this proc!
  assert(not isOnStack(dest))
  # BUGFIX: first incRef then decRef!
  if src != nil: incRef(usrToCell(src))
  if dest^ != nil: decRef(usrToCell(dest^))
  dest^ = src


# ----------------------------------------------------------------------------
#     helpers

const
  table: array[0..255, int8] = [
      -1, 0, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4,
      4, 4, 4, 4, 4, 4, 4, 4, 4,
      5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
      5, 5, 5, 5, 5, 5, 5, 5,
      6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
      6, 6, 6, 6, 6, 6, 6, 6,
      6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
      6, 6, 6, 6, 6, 6, 6, 6,
      7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
      7, 7, 7, 7, 7, 7, 7, 7,
      7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
      7, 7, 7, 7, 7, 7, 7, 7,
      7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
      7, 7, 7, 7, 7, 7, 7, 7,
      7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
      7, 7, 7, 7, 7, 7, 7, 7
    ]

proc ls_bit(i: int32): int {.inline.} = 
  var 
    a: int = 0
    x: int = i and -i
  if x <=% 0xffff:
    if x <=% ff: a = 0
    else: a = 8
  elif x <=% 0xffffff: a = 16
  else: a = 24
  return table[x shr a] + a

proc ms_bit(i: int): int {.inline.} = 
  var
    a = if i <=% 0xffff: (if i <=% 0xff: 0 else: 8) elif 
           i <=% 0xffffff: 16 else: 24
  return table[i shr a] + a

proc set_bit[IX](nr: int, adr: var array[IX, int32]) {.inline.} =
  adr[nr shr 5] = adr[nr shr 5] or (1 shl (nr and 0x1f))

proc clear_bit[IX](nr: int, adr: var array[IX, int32]) {.inline.} =
  adr[nr shr 5] = adr[nr shr 5] and not (1 shl (nr and 0x1f))

proc mappingSearch(r, fl, sl: var int) {.inline.} = 
  if r < smallBlock: 
    fl = 0
    sl = r div (smallBlock div maxSli)
  else:
    var t = (1 shl (ms_bit(r) - maxLog2Sli)) - 1
    r = r + t
    fl = ms_bit(r)
    sl = (r shl (fl - maxLog2Sli)) - maxSli
    fl = fl - fliOffset
    r = r and not t

proc mappingInsert(r: int, fl, sl: var int) {.inline.} = 
  if r < smallBlock:
    fl = 0
    sl = r div (smallBlock div maxSli)
  else:
    fl = ms_bit(r)
    sl = (r shr (fl - maxLog2Sli)) - maxSli
    fl = fl - fliOffset

proc findSuitableBlock(t: var TLSF, fl, sl: var int): Pbhdr =
  var tmp = t.slBitmap[fl] and ((not 0) shl sl)
  if tmp != 0:
    sl = ls_bit(tmp)
    result = t.matrix[fl][sl]
  else:
    fl = ls_bit(t.flBitmap and (not 0 shl (fl + 1)))
    if fl > 0: # likely
      sl = ls_bit(t.slBitmap[fl])
      result = t.matrix[fl][sl]

proc extractBlockHdr(b: Pbhdr, t: var TLSF, fl, sl: int) {.inline.} = 
  t.matrix[fl][sl] = b.freePtr.next
  if t.matrix[fl][sl] != 0:
    t.matrix[fl][sl].freePtr.prev = nil
  else:
    clear_bit(sl, t.slBitmap[fl])
    if t.slBitmap[fl] == 0:
      clear_bit(fl, t.flBitmap)
  b.freePtr.prev = nil
  b.freePtr.next = nil

proc extractBlock(b: Pbhdr, t: var TLSF, fl, sl: int) {.inline.} =
  if b.freePtr.next != nil:
    b.freePtr.next.freePtr.prev = b.freePtr.prev
  if b.freePtr.prev != nil:
    b.freePtr.prev.freePtr.next = b.freePtr.next
  if t.matrix[fl][sl] == b:
    t.matrix[fl][sl] = b.freePtr.next
    if t.matrix[fl][sl] == nil:
      clear_bit(sl, t.slBitmap[fl])
      if t.slBitmap[fl] == 0:
        clear_bit(fl, t.flBitmap)
  b.freePtr.prev = nil
  b.freePtr.next = nil

proc insertBlock(b: Pbhdr, t: var TLSF, fl, sl: int) {.inline.} = 
  b.freePtr.prev = nil
  b.freePtr.next = t.matrix[fl][sl] 
  if t.matrix[fl][sl] != nil:
    t.matrix[fl][sl].freePtr.prev = b		
  t.matrix[fl][sl] = b
  set_bit(sl, t.slBitmap[fl])
  set_bit(fl, t.flBitmap)

proc getBuffer(b: Pbhdr): pointer {.inline.} = 
  result = cast[pointer](addr(b.freePtr))

proc processArea(area: pointer, size: int): Pbhdr =
  var 
    b, lb, ib: Pbhdr
    ai: PAreaInfo
  ib = cast[Pbhdr](area)
  if sizeof(TAreaInfo) < minBlockSize:
    ib.size = minBlockSize or usedBlock or prevUsed
  else
    ib.size = roundupSize(sizeof(TAreaInfo)) or usedBlock or prevUsed
  b = getNextBlock(getBuffer(ib), ib.size and blockSize)
  b.size = rounddownSize(size - 3 * bhdrOverhead - (ib.size and blockSize)) or
           usedBlock or prevUsed
  b.freePtr.prev = nil
  b.freePtr.next = nil
  lb = getNextBlock(getBuffer(b), b.size and blockSize)
  lb.prevHdr = b
  lb.size = 0 or usedBlock or prevFree
  ai = cast[PAreaInfo](getBuffer(ib))
  ai.next = nil
  ai.theEnd = lb
  return ib

# ----------------------------------------------------------------------------
#                  Begin of the allocator code

proc initMemoryPool(memPoolSize: int, memPool: pointer): int = 
  var
    t: PLSF
    b, ib: Pbhdr

  if memPool == nil or memPoolSize < sizeof(TLSF) + bhdrOverhead * 8:
    writeToStdErr("initMemoryPool(): memory_pool invalid\n")
    return -1

  if (cast[TAddress](memPool) and ptrMask) != 0:
    writeToStdErr("initMemoryPool(): memPool must be aligned to a word\n")
    return -1
  t = cast[PLSF](memPool)
  # Check if already initialised
  if t.signature == tlsfSignature:
    b = getNextBlock(memPool, roundupSize(sizeof(TLSF)))
    return b.size and blockSize
  zeroMem(memPool, sizeof(TLSF))

  t.signature = tlsfSignature
  ib = processArea(getNextBlock(memPool, roundupSize(sizeof(TLSF))), 
                   rounddownSize(memPoolSize - sizeof(TLSF)))
  b = getNextBlock(getBuffer(ib), ib.size and blockSize)
  freeEx(getBuffer(b), t)
  t.areaHead = cast[PAreaInfo](getBuffer(ib))

  t.used_size = memPoolSize - (b.size and blockSize)
  t.max_size = t.used_size
  return b.size and blockSize


proc addNewArea(area: pointer, areaSize: int, t: var TLSF): int = 
  var
    p, ptrPrev, ai: PAreaInfo
    ib0, b0, lb0, ib1, b1, lb1, nextB: Pbhdr

  zeroMem(area, areaSize)
  p = t.areaHead
  ptrPrev = 0

  ib0 = processArea(area, areaSize)
  b0 = getNextBlock(getBuffer(ib0), ib0.size and blockSize)
  lb0 = getNextBlock(getBuffer(b0), b0.size and blockSize)

  # Before inserting the new area, we have to merge this area with the
  # already existing ones
  while p != nil:
    ib1 = cast[Pbhdr](cast[TAddress](p) -% bhdrOverhead) 
    b1 = getNextBlock(getBuffer(ib1), ib1.size and blockSize)
    lb1 = p.theEnd

    # Merging the new area with the next physically contigous one
    if cast[TAddress](ib1) == cast[TAddress](lb0) +% bhdrOverhead:
      if t.areaHead == p:
        t.areaHead = p.next
        p = p.next
      else:
        ptrPrev.next = p.next
        p = p.next
      b0.size = rounddownSize((b0.size and blockSize) +
                         (ib1.size and blockSize) + 2 * bhdrOverhead) or
                         usedBlock or prevUsed
      b1.prevHdr = b0
      lb0 = lb1
      continue

    # Merging the new area with the previous physically contigous one
    if getBuffer(lb1) == pointer(ib0):
      if t.areaHead == p:
        t.areaHead = p.next
        p = p.next
      else:
        ptrPrev.next = p.next
        p = p.next
      lb1->size = rounddownSize((b0.size and blockSize) +
                   (ib0.size and blockSize) + 2 * bhdrOverhead) or
                   usedBlock or (lb1.size and prevState)
      nextB = getNextBlock(getBuffer(lb1), lb1.size and blockSize)
      nextB.prevHdr = lb1
      b0 = lb1
      ib0 = ib1
      continue
    ptrPrev = p
    p = p.next

  # Inserting the area in the list of linked areas 
  ai = cast[PAreaInfo](getBuffer(ib0))
  ai.next = t.areaHead
  ai.theEnd = lb0
  t.areaHead = ai
  freeEx(getBuffer(b0), memPool)
  return (b0.size and blockSize)

proc mallocEx(asize: int, t: var TLSF): pointer = 
  var
    b, b2, nextB: Pbhdr
    fl, sl, tmpSize, size: int

  size = if asize < minBlockSize: minBlockSize else: roundupSize(asize)

  # Rounding up the requested size and calculating fl and sl
  mappingSearch(size, fl, sl)

  # Searching a free block, recall that this function changes the values
  # of fl and sl, so they are not longer valid when the function fails
  b = findSuitableBlock(tlsf, fl, sl)
  if b == nil: 
    # Growing the pool size when needed 
    # size plus enough room for the required headers:
    var areaSize = max(size + bhdrOverhead * 8, defaultAreaSize)
    var area = getNewArea(areaSize)
    addNewArea(area, areaSize, t)
    # Rounding up the requested size and calculating fl and sl
    mappingSearch(size, fl, sl)
    # Searching a free block
    b = findSuitableBlock(t, fl, sl)
    if b == nil: 
      raiseOutOfMem()

  extractBlockHdr(b, t, fl, sl)

  #-- found:
  nextB = getNextBlock(getBuffer(b), b.size and blockSize)
  # Should the block be split?
  tmpSize = (b.size and blockSize) - size
  if tmpSize >= sizeof(Tbhdr):
    dec(tmpSize, bhdrOverhead)
    b2 = getNextBlock(getBuffer(b), size)
    b2.size = tmpSize or freeBlock or prevUsed
    nextB.prevHdr = b2
    mappingInsert(tmpSize, fl, sl)
    insertBlock(b2, t, fl, sl)

    b.size = size or (b.size and prevState)
  else:
    nextB.size = nextB.size and not prevFree
    b.size = b.size and not freeBlock # Now it's used

  addSize(t, b)
  return getBuffer(b)


proc freeEx(p: pointer, t: var TLSF) =
  var
    fl = 0
    sl = 0
    b, tmpB: Pbhdr

  assert(p != nil)
  b = cast[Pbhdr](cast[TAddress](p) -% bhdrOverhead)
  b.size = b.size or freeBlock

  removeSize(t, b)
  b.freePtr.prev = nil
  b.freePtr.next = nil
  tmpB = getNextBlock(getBuffer(b), b.size and blockSize)
  if (tmpB.size and freeBlock) != 0:
    mappingInsert(tmpB.size and blockSize, fl, sl)
    extractBlock(tmpB, t, fl, sl)
    inc(b.size, (tmpB.size and blockSize) + bhdrOverhead)
  if (b.size and prevFree) != 0:
    tmpB = b.prevHdr
    mappingInsert(tmpB.size and blockSize, fl, sl)
    extractBlock(tmpB, t, fl, sl)
    inc(tmpB.size, (b.size and blockSize) + bhdrOverhead)
    b = tmpB
  mappingInsert(b.size and blockSize, fl, sl)
  insertBlock(b, t, fl, sl)

  tmpB = getNextBlock(getBuffer(b), b.size and blockSize)
  tmpB.size = tmpB.size or prevFree
  tmpB.prevHdr = b

proc reallocEx(p: pointer, newSize: int, t: var TLSF): pointer = 
  var
    cpsize, fl, sl, tmpSize: int
    b, tmpB, nextB: Pbhdr

  assert(p != nil)
  assert(newSize > 0)

  b = cast[Pbhdr](cast[TAddress](p) -% bhdrOverhead)
  nextB = getNextBlock(getBuffer(b), b.size and blockSize)
  newSize = if newSize < minBlockSize: minBlockSize else: roundupSize(newSize)
  tmpSize = b.size and blockSize
  if newSize <= tmpSize:
    removeSize(t, b)
    if (nextB.size and freeBlock) != 0: 
      mappingInsert(nextB.size and blockSize, fl, sl)
      extractBlock(nextB, t, fl, sl)
      inc(tmpSize, (nextB.size and blockSize) + bhdrOverhead)
      nextB = getNextBlock(getBuffer(nextB), nextB.size and blockSize)
      # We always reenter this free block because tmpSize will
      # be greater then sizeof(Tbhdr)
    dec(tmpSize, newSize)
    if tmpSize >= sizeof(Tbhdr):
      dec(tmpSize, bhdrOverhead)
      tmpB = getNextBlock(getBuffer(b), newSize)
      tmpB.size = tmpSize or freeBlock or prevUsed
      nextB.prevHdr = tmpB
      nextB.size = nextB.size or prevFree
      mappingInsert(tmpSize, fl, sl)
      insertBlock(tmpB, t, fl, sl)
      b.size = newSize or (b.size and prevState)
    addSize(t, b)
    return getBuffer(b)
  
  if (nextB.size and freeBlock) != 0:
    if newSize <= tmpSize + (nextB.size and blockSize):
      removeSize(t, b)
      mappingInsert(nextB.size and blockSize, fl, sl)
      extractBlock(nextB, t, fl, sl)
      inc(b.size, (nextB.size and blockSize) + bhdrOverhead)
      nextB = getNextBlock(getBuffer(b), b.size and blockSize)
      nextB.prevHdr = b
      nextB.size = nextB.size and not prevFree
      tmpSize = (b.size and blockSize) - newSize
      if tmpSize >= sizeof(Tbhdr):
        dec(tmpSize, bhdrOverhead)
        tmpB = getNextBlock(getBuffer(b), newSize)
        tmpB.size = tmpSize or freeBlock or prevUsed
        nextB.prevHdr = tmpB
        nextB.size = nextB.size or prevFree
        mappingInsert(tmpSize, fl, sl)
        insertBlock(tmpB, t, fl, sl)
        b.size = newSize or (b.size and prevState)
      addSize(t, b)
      return getBuffer(b)

  var ptrAux = mallocEx(newSize, t)
  cpsize = if (b.size and blockSize) > newSize: newSize else:
                                                (b.size and blockSize)
  copyMem(ptrAux, p, cpsize)
  freeEx(p, memPool)
  return ptrAux


proc ansiCrealloc(p: pointer, newSize: int, t: var TLSF): pointer = 
  if p == nil: 
    if newSize > 0: 
      result = mallocEx(newSize, t)
    else:
      result = nil
  elif newSize <= 0:
    freeEx(p, t)
    result = nil
  else:
    result = reallocEx(p, newSize, t)

proc InitTLSF(t: var TLSF) = 
  var areaSize = sizeof(TLSF) + BHDR_OVERHEAD * 8 # Just a safety constant
  areaSize = max(areaSize, DEFAULT_areaSize)
  var area = getNewArea(areaSize)
  
  
  initMemoryPool(areaSize, area)

  var
    t: PLSF
    b, ib: Pbhdr

  t = cast[PLSF](memPool)
  
  zeroMem(area, areaSize)

  t.signature = tlsfSignature
  var ib = processArea(getNextBlock(memPool, roundupSize(sizeof(TLSF))), 
                   rounddownSize(memPoolSize - sizeof(TLSF)))
  var b = getNextBlock(getBuffer(ib), ib.size and blockSize)
  freeEx(getBuffer(b), t)
  t.areaHead = cast[PAreaInfo](getBuffer(ib))

  t.used_size = memPoolSize - (b.size and blockSize)
  t.max_size = t.used_size

  # XXX
