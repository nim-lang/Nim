#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# "Stack GC" for embedded devices or ultra performance requirements.

when defined(memProfiler):
  proc nimProfile(requestedSize: int) {.benign.}

when defined(useMalloc):
  proc roundup(x, v: int): int {.inline.} =
    result = (x + (v-1)) and not (v-1)
  proc emalloc(size: int): pointer {.importc: "malloc", header: "<stdlib.h>".}
  proc efree(mem: pointer) {.importc: "free", header: "<stdlib.h>".}

  proc osAllocPages(size: int): pointer {.inline.} =
    emalloc(size)

  proc osTryAllocPages(size: int): pointer {.inline.} =
    emalloc(size)

  proc osDeallocPages(p: pointer, size: int) {.inline.} =
    efree(p)

else:
  include osalloc

# We manage memory as a thread local stack. Since the allocation pointer
# is detached from the control flow pointer, this model is vastly more
# useful than the traditional programming model while almost as safe.
# Individual objects can also be deleted but no coalescing is performed.
# Stacks can also be moved from one thread to another.

# We also support 'finalizers'.

type
  Finalizer {.compilerproc.} = proc (self: pointer) {.nimcall, benign.}
    # A ref type can have a finalizer that is called before the object's
    # storage is freed.

  AlignType = BiggestFloat
  ObjHeader = object
    typ: PNimType
    nextFinal: ptr ObjHeader # next object with finalizer

  Chunk = ptr BaseChunk
  BaseChunk = object
    next: Chunk
    size: int
    head, tail: ptr ObjHeader # first and last object in chunk that
                              # has a finalizer attached to it

const
  MaxSmallObject = 128

type
  FreeEntry = ptr object
    next: FreeEntry
  SizedFreeEntry = ptr object
    next: SizedFreeEntry
    size: int
  StackPtr = object
    bump: pointer
    remaining: int
    current: Chunk

  MemRegion* = object
    remaining: int
    bump: pointer
    head, tail: Chunk
    nextChunkSize, totalSize: int
    when false:
      freeLists: array[MaxSmallObject div MemAlign, FreeEntry]
      holes: SizedFreeEntry
    when hasThreadSupport:
      lock: SysLock

  SeqHeader = object # minor hack ahead: Since we know that seqs
                     # and strings cannot have finalizers, we use the field
                     # instead for a 'region' field so that they can grow
                     # and shrink safely.
    typ: PNimType
    region: ptr MemRegion

var
  tlRegion {.threadvar.}: MemRegion
#  tempStrRegion {.threadvar.}: MemRegion  # not yet used

template withRegion*(r: var MemRegion; body: untyped) =
  let oldRegion = tlRegion
  tlRegion = r
  try:
    body
  finally:
    r = tlRegion
    tlRegion = oldRegion

template inc(p: pointer, s: int) =
  p = cast[pointer](cast[int](p) +% s)

template dec(p: pointer, s: int) =
  p = cast[pointer](cast[int](p) -% s)

template `+!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) +% s)

template `-!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) -% s)

const nimMinHeapPages {.intdefine.} = 4

proc allocSlowPath(r: var MemRegion; size: int) =
  # we need to ensure that the underlying linked list
  # stays small. Say we want to grab 16GB of RAM with some
  # exponential growth function. So we allocate 16KB, then
  # 32 KB, 64 KB, 128KB, 256KB, 512KB, 1MB, 2MB, 4MB,
  # 8MB, 16MB, 32MB, 64MB, 128MB, 512MB, 1GB, 2GB, 4GB, 8GB,
  # 16GB --> list contains only 20 elements! That's reasonable.
  if (r.totalSize and 1) == 0:
    r.nextChunkSize = if r.totalSize < 64 * 1024: PageSize*nimMinHeapPages
                      else: r.nextChunkSize*2
  var s = roundup(size+sizeof(BaseChunk), PageSize)
  var fresh: Chunk
  if s > r.nextChunkSize:
    fresh = cast[Chunk](osAllocPages(s))
  else:
    fresh = cast[Chunk](osTryAllocPages(r.nextChunkSize))
    if fresh == nil:
      fresh = cast[Chunk](osAllocPages(s))
      # lowest bit in totalSize is the "don't increase nextChunkSize"
      inc r.totalSize
    else:
      s = r.nextChunkSize
  fresh.size = s
  fresh.head = nil
  fresh.tail = nil
  fresh.next = nil
  inc r.totalSize, s
  let old = r.tail
  if old == nil:
    r.head = fresh
  else:
    r.tail.next = fresh
  r.bump = fresh +! sizeof(BaseChunk)
  r.tail = fresh
  r.remaining = s - sizeof(BaseChunk)

proc allocFast(r: var MemRegion; size: int): pointer =
  when false:
    if size <= MaxSmallObject:
      var it = r.freeLists[size div MemAlign]
      if it != nil:
        r.freeLists[size div MemAlign] = it.next
        return pointer(it)
    else:
      var it = r.holes
      var prev: SizedFreeEntry = nil
      while it != nil:
        if it.size >= size:
          if prev != nil: prev.next = it.next
          else: r.holes = it.next
          return pointer(it)
        prev = it
        it = it.next
  let size = roundup(size, MemAlign)
  if size > r.remaining:
    allocSlowPath(r, size)
  sysAssert(size <= r.remaining, "size <= r.remaining")
  dec(r.remaining, size)
  result = r.bump
  inc r.bump, size

proc runFinalizers(c: Chunk) =
  var it = c.head
  while it != nil:
    # indivually freed objects with finalizer stay in the list, but
    # their typ is nil then:
    if it.typ != nil and it.typ.finalizer != nil:
      (cast[Finalizer](it.typ.finalizer))(it+!sizeof(ObjHeader))
    it = it.nextFinal

proc runFinalizers(c: Chunk; newbump: pointer) =
  var it = c.head
  var prev: ptr ObjHeader = nil
  while it != nil:
    let nxt = it.nextFinal
    if it >= newbump:
      if it.typ != nil and it.typ.finalizer != nil:
        (cast[Finalizer](it.typ.finalizer))(it+!sizeof(ObjHeader))
    elif prev != nil:
      prev.nextFinal = nil
    prev = it
    it = nxt

proc dealloc(r: var MemRegion; p: pointer; size: int) =
  let it = cast[ptr ObjHeader](p-!sizeof(ObjHeader))
  if it.typ != nil and it.typ.finalizer != nil:
    (cast[Finalizer](it.typ.finalizer))(p)
  it.typ = nil
  # it is beneficial to not use the free lists here:
  if r.bump -! size == p:
    dec r.bump, size
  when false:
    if size <= MaxSmallObject:
      let it = cast[FreeEntry](p)
      it.next = r.freeLists[size div MemAlign]
      r.freeLists[size div MemAlign] = it
    else:
      let it = cast[SizedFreeEntry](p)
      it.size = size
      it.next = r.holes
      r.holes = it

proc deallocAll(r: var MemRegion; head: Chunk) =
  var it = head
  while it != nil:
    let nxt = it.next
    runFinalizers(it)
    dec r.totalSize, it.size
    osDeallocPages(it, it.size)
    it = nxt

proc deallocAll*(r: var MemRegion) =
  deallocAll(r, r.head)
  zeroMem(addr r, sizeof r)

proc obstackPtr*(r: MemRegion): StackPtr =
  result.bump = r.bump
  result.remaining = r.remaining
  result.current = r.tail

template computeRemaining(r): untyped =
  r.tail.size -% (cast[int](r.bump) -% cast[int](r.tail))

proc setObstackPtr*(r: var MemRegion; sp: StackPtr) =
  # free everything after 'sp':
  if sp.current != nil and sp.current.next != nil:
    deallocAll(r, sp.current.next)
    sp.current.next = nil
    when false:
      # better leak this memory than be sorry:
      for i in 0..high(r.freeLists): r.freeLists[i] = nil
      r.holes = nil
  if r.tail != nil: runFinalizers(r.tail, sp.bump)

  r.bump = sp.bump
  r.tail = sp.current
  r.remaining = sp.remaining

proc obstackPtr*(): StackPtr = tlRegion.obstackPtr()
proc setObstackPtr*(sp: StackPtr) = tlRegion.setObstackPtr(sp)
proc deallocAll*() = tlRegion.deallocAll()

proc deallocOsPages(r: var MemRegion) = r.deallocAll()

when false:
  let obs = obstackPtr()
  try:
    body
  finally:
    setObstackPtr(obs)

template withScratchRegion*(body: untyped) =
  let oldRegion = tlRegion
  tlRegion = MemRegion()
  try:
    body
  finally:
    deallocAll()
    tlRegion = oldRegion

when false:
  proc joinRegion*(dest: var MemRegion; src: MemRegion) =
    # merging is not hard.
    if dest.head.isNil:
      dest.head = src.head
    else:
      dest.tail.next = src.head
    dest.tail = src.tail
    dest.bump = src.bump
    dest.remaining = src.remaining
    dest.nextChunkSize = max(dest.nextChunkSize, src.nextChunkSize)
    inc dest.totalSize, src.totalSize

proc isOnHeap*(r: MemRegion; p: pointer): bool =
  # the tail chunk is the largest, so check it first. It's also special
  # in that contains the current bump pointer:
  if r.tail >= p and p < r.bump:
    return true
  var it = r.head
  while it != r.tail:
    if it >= p and p <= it+!it.size: return true
    it = it.next

proc rawNewObj(r: var MemRegion, typ: PNimType, size: int): pointer =
  var res = cast[ptr ObjHeader](allocFast(r, size + sizeof(ObjHeader)))
  res.typ = typ
  if typ.finalizer != nil:
    res.nextFinal = r.head.head
    r.head.head = res
  result = res +! sizeof(ObjHeader)

proc rawNewSeq(r: var MemRegion, typ: PNimType, size: int): pointer =
  var res = cast[ptr SeqHeader](allocFast(r, size + sizeof(SeqHeader)))
  res.typ = typ
  res.region = addr(r)
  result = res +! sizeof(SeqHeader)

proc newObj(typ: PNimType, size: int): pointer {.compilerRtl.} =
  sysAssert typ.kind notin {tySequence, tyString}, "newObj cannot be used to construct seqs"
  result = rawNewObj(tlRegion, typ, size)
  zeroMem(result, size)
  when defined(memProfiler): nimProfile(size)

proc newObjNoInit(typ: PNimType, size: int): pointer {.compilerRtl.} =
  sysAssert typ.kind notin {tySequence, tyString}, "newObj cannot be used to construct seqs"
  result = rawNewObj(tlRegion, typ, size)
  when defined(memProfiler): nimProfile(size)

{.push overflowChecks: on.}
proc newSeq(typ: PNimType, len: int): pointer {.compilerRtl.} =
  let size = roundup(align(GenericSeqSize, typ.base.align) + len * typ.base.size, MemAlign)
  result = rawNewSeq(tlRegion, typ, size)
  zeroMem(result, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len

proc newStr(typ: PNimType, len: int; init: bool): pointer {.compilerRtl.} =
  let size = roundup(len + GenericSeqSize, MemAlign)
  result = rawNewSeq(tlRegion, typ, size)
  if init: zeroMem(result, size)
  cast[PGenericSeq](result).len = 0
  cast[PGenericSeq](result).reserved = len
{.pop.}

proc newObjRC1(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(tlRegion, typ, size)
  zeroMem(result, size)

proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =
  result = newSeq(typ, len)

proc growObj(regionUnused: var MemRegion; old: pointer, newsize: int): pointer =
  let sh = cast[ptr SeqHeader](old -! sizeof(SeqHeader))
  let typ = sh.typ
  result = rawNewSeq(sh.region[], typ,
                     roundup(newsize, MemAlign))
  let elemSize = if typ.kind == tyString: 1 else: typ.base.size
  let elemAlign = if typ.kind == tyString: 1 else: typ.base.align
  let oldsize = align(GenericSeqSize, elemAlign) + cast[PGenericSeq](old).len*elemSize
  zeroMem(result +! oldsize, newsize-oldsize)
  copyMem(result, old, oldsize)
  dealloc(sh.region[], old, roundup(oldsize, MemAlign))

proc growObj(old: pointer, newsize: int): pointer {.rtl.} =
  result = growObj(tlRegion, old, newsize)

proc unsureAsgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
  dest[] = src
proc asgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
  dest[] = src
proc asgnRefNoCycle(dest: PPointer, src: pointer) {.compilerproc, inline,
  deprecated: "old compiler compat".} = asgnRef(dest, src)

proc allocImpl(size: Natural): pointer =
  result = c_malloc(cast[csize_t](size))
  if result == nil: raiseOutOfMem()
proc alloc0Impl(size: Natural): pointer =
  result = alloc(size)
  zeroMem(result, size)
proc reallocImpl(p: pointer, newsize: Natural): pointer =
  result = c_realloc(p, cast[csize_t](newsize))
  if result == nil: raiseOutOfMem()
proc realloc0Impl(p: pointer, oldsize, newsize: Natural): pointer =
  result = c_realloc(p, cast[csize_t](newsize))
  if result == nil: raiseOutOfMem()
  if newsize > oldsize:
    zeroMem(cast[pointer](cast[int](result) + oldsize), newsize - oldsize)
proc deallocImpl(p: pointer) = c_free(p)

proc alloc0(r: var MemRegion; size: Natural): pointer =
  # ignore the region. That is correct for the channels module
  # but incorrect in general. XXX
  result = alloc0(size)

proc alloc(r: var MemRegion; size: Natural): pointer =
  # ignore the region. That is correct for the channels module
  # but incorrect in general. XXX
  result = alloc(size)

proc dealloc(r: var MemRegion; p: pointer) = dealloc(p)

proc allocSharedImpl(size: Natural): pointer =
  result = c_malloc(cast[csize_t](size))
  if result == nil: raiseOutOfMem()
proc allocShared0Impl(size: Natural): pointer =
  result = alloc(size)
  zeroMem(result, size)
proc reallocSharedImpl(p: pointer, newsize: Natural): pointer =
  result = c_realloc(p, cast[csize_t](newsize))
  if result == nil: raiseOutOfMem()
proc reallocShared0Impl(p: pointer, oldsize, newsize: Natural): pointer =
  result = c_realloc(p, cast[csize_t](newsize))
  if result == nil: raiseOutOfMem()
  if newsize > oldsize:
    zeroMem(cast[pointer](cast[int](result) + oldsize), newsize - oldsize)
proc deallocSharedImpl(p: pointer) = c_free(p)

when hasThreadSupport:
  proc getFreeSharedMem(): int = 0
  proc getTotalSharedMem(): int = 0
  proc getOccupiedSharedMem(): int = 0

proc GC_disable() = discard
proc GC_enable() = discard
proc GC_fullCollect() = discard
proc GC_setStrategy(strategy: GC_Strategy) = discard
proc GC_enableMarkAndSweep() = discard
proc GC_disableMarkAndSweep() = discard
proc GC_getStatistics(): string = return ""

proc getOccupiedMem(): int =
  result = tlRegion.totalSize - tlRegion.remaining
proc getFreeMem(): int = tlRegion.remaining
proc getTotalMem(): int =
  result = tlRegion.totalSize

proc getOccupiedMem*(r: MemRegion): int =
  result = r.totalSize - r.remaining
proc getFreeMem*(r: MemRegion): int = r.remaining
proc getTotalMem*(r: MemRegion): int =
  result = r.totalSize

proc nimGC_setStackBottom(theStackBottom: pointer) = discard

proc nimGCref(x: pointer) {.compilerproc.} = discard
proc nimGCunref(x: pointer) {.compilerproc.} = discard
