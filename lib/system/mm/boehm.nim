


proc boehmGCinit {.importc: "GC_init", boehmGC.}
proc boehmGC_disable {.importc: "GC_disable", boehmGC.}
proc boehmGC_enable {.importc: "GC_enable", boehmGC.}
proc boehmGCincremental {.
  importc: "GC_enable_incremental", boehmGC.}
proc boehmGCfullCollect {.importc: "GC_gcollect", boehmGC.}
proc boehmGC_set_all_interior_pointers(flag: cint) {.
  importc: "GC_set_all_interior_pointers", boehmGC.}
proc boehmAlloc(size: int): pointer {.importc: "GC_malloc", boehmGC.}
proc boehmAllocAtomic(size: int): pointer {.
  importc: "GC_malloc_atomic", boehmGC.}
proc boehmRealloc(p: pointer, size: int): pointer {.
  importc: "GC_realloc", boehmGC.}
proc boehmDealloc(p: pointer) {.importc: "GC_free", boehmGC.}
when hasThreadSupport:
  proc boehmGC_allow_register_threads {.
    importc: "GC_allow_register_threads", boehmGC.}

proc boehmGetHeapSize: int {.importc: "GC_get_heap_size", boehmGC.}
  ## Return the number of bytes in the heap.  Excludes collector private
  ## data structures. Includes empty blocks and fragmentation loss.
  ## Includes some pages that were allocated but never written.

proc boehmGetFreeBytes: int {.importc: "GC_get_free_bytes", boehmGC.}
  ## Return a lower bound on the number of free bytes in the heap.

proc boehmGetBytesSinceGC: int {.importc: "GC_get_bytes_since_gc", boehmGC.}
  ## Return the number of bytes allocated since the last collection.

proc boehmGetTotalBytes: int {.importc: "GC_get_total_bytes", boehmGC.}
  ## Return the total number of bytes allocated in this process.
  ## Never decreases.

proc boehmRegisterFinalizer(obj, ff, cd, off, ocd: pointer) {.importc: "GC_register_finalizer", boehmGC.}

proc allocAtomic(size: int): pointer =
  result = boehmAllocAtomic(size)
  zeroMem(result, size)

when not defined(useNimRtl):

  proc allocImpl(size: Natural): pointer =
    result = boehmAlloc(size)
    if result == nil: raiseOutOfMem()
  proc alloc0Impl(size: Natural): pointer =
    result = alloc(size)
  proc reallocImpl(p: pointer, newSize: Natural): pointer =
    result = boehmRealloc(p, newSize)
    if result == nil: raiseOutOfMem()
  proc realloc0Impl(p: pointer, oldSize, newSize: Natural): pointer =
    result = boehmRealloc(p, newSize)
    if result == nil: raiseOutOfMem()
    if newSize > oldSize:
      zeroMem(cast[pointer](cast[int](result) + oldSize), newSize - oldSize)
  proc deallocImpl(p: pointer) = boehmDealloc(p)

  proc allocSharedImpl(size: Natural): pointer = allocImpl(size)
  proc allocShared0Impl(size: Natural): pointer = alloc0Impl(size)
  proc reallocSharedImpl(p: pointer, newSize: Natural): pointer = reallocImpl(p, newSize)
  proc reallocShared0Impl(p: pointer, oldSize, newSize: Natural): pointer = realloc0Impl(p, oldSize, newSize)
  proc deallocSharedImpl(p: pointer) = deallocImpl(p)

  when hasThreadSupport:
    proc getFreeSharedMem(): int =
      boehmGetFreeBytes()
    proc getTotalSharedMem(): int =
      boehmGetHeapSize()
    proc getOccupiedSharedMem(): int =
      getTotalSharedMem() - getFreeSharedMem()

  #boehmGCincremental()

  proc GC_disable() = boehmGC_disable()
  proc GC_enable() = boehmGC_enable()
  proc GC_fullCollect() = boehmGCfullCollect()
  proc GC_setStrategy(strategy: GC_Strategy) = discard
  proc GC_enableMarkAndSweep() = discard
  proc GC_disableMarkAndSweep() = discard
  proc GC_getStatistics(): string = return ""

  proc getOccupiedMem(): int = return boehmGetHeapSize()-boehmGetFreeBytes()
  proc getFreeMem(): int = return boehmGetFreeBytes()
  proc getTotalMem(): int = return boehmGetHeapSize()

  proc nimGC_setStackBottom(theStackBottom: pointer) = discard

proc initGC() =
  when defined(boehmNoIntPtr):
    # See #12286
    boehmGC_set_all_interior_pointers(0)
  boehmGCinit()
  when hasThreadSupport:
    boehmGC_allow_register_threads()

proc boehmgc_finalizer(obj: pointer, typedFinalizer: (proc(x: pointer) {.cdecl.})) =
  typedFinalizer(obj)


proc newObj(typ: PNimType, size: int): pointer {.compilerproc.} =
  if ntfNoRefs in typ.flags: result = allocAtomic(size)
  else: result = alloc(size)
  if typ.finalizer != nil:
    boehmRegisterFinalizer(result, boehmgc_finalizer, typ.finalizer, nil, nil)
{.push overflowChecks: on.}
proc newSeq(typ: PNimType, len: int): pointer {.compilerproc.} =
  result = newObj(typ, align(GenericSeqSize, typ.base.align) + len * typ.base.size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len
{.pop.}

proc growObj(old: pointer, newsize: int): pointer =
  result = realloc(old, newsize)

proc nimGCref(p: pointer) {.compilerproc, inline.} = discard
proc nimGCunref(p: pointer) {.compilerproc, inline.} = discard

proc unsureAsgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
  dest[] = src
proc asgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
  dest[] = src
proc asgnRefNoCycle(dest: PPointer, src: pointer) {.compilerproc, inline,
  deprecated: "old compiler compat".} = asgnRef(dest, src)

type
  MemRegion = object

proc alloc(r: var MemRegion, size: int): pointer =
  result = boehmAlloc(size)
  if result == nil: raiseOutOfMem()
proc alloc0(r: var MemRegion, size: int): pointer =
  result = alloc(size)
  zeroMem(result, size)
proc dealloc(r: var MemRegion, p: pointer) = boehmDealloc(p)
proc deallocOsPages(r: var MemRegion) {.inline.} = discard
proc deallocOsPages() {.inline.} = discard

include "system/cellsets"
