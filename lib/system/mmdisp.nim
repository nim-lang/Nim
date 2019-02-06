#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Nim high-level memory manager: It supports Boehm's GC, Go's GC, no GC and the
# native Nim GC. The native Nim GC is the default.

#{.push checks:on, assertions:on.}
{.push checks:off.}

const
  debugGC = false # we wish to debug the GC...
  logGC = false
  traceGC = false # extensive debugging
  alwaysCycleGC = defined(smokeCycles)
  alwaysGC = defined(fulldebug) # collect after every memory
                                # allocation (for debugging)
  leakDetector = defined(leakDetector)
  overwriteFree = defined(nimBurnFree) # overwrite memory with 0xFF before free
  trackAllocationSource = leakDetector

  cycleGC = true # (de)activate the cycle GC
  reallyDealloc = true # for debugging purposes this can be set to false
  reallyOsDealloc = true
  coalescRight = true
  coalescLeft = true
  logAlloc = false
  useCellIds = defined(corruption)

type
  PPointer = ptr pointer
  ByteArray = UncheckedArray[byte]
  PByte = ptr ByteArray
  PString = ptr string

# Page size of the system; in most cases 4096 bytes. For exotic OS or
# CPU this needs to be changed:
const
  PageShift = when defined(cpu16): 8 else: 12 # \
    # my tests showed no improvments for using larger page sizes.
  PageSize = 1 shl PageShift
  PageMask = PageSize-1

  MemAlign = 8 # also minimal allocatable memory block

  BitsPerPage = PageSize div MemAlign
  UnitsPerPage = BitsPerPage div (sizeof(int)*8)
    # how many ints do we need to describe a page:
    # on 32 bit systems this is only 16 (!)

  TrunkShift = 9
  BitsPerTrunk = 1 shl TrunkShift # needs to be power of 2 and divisible by 64
  TrunkMask = BitsPerTrunk - 1
  IntsPerTrunk = BitsPerTrunk div (sizeof(int)*8)
  IntShift = 5 + ord(sizeof(int) == 8) # 5 or 6, depending on int width
  IntMask = 1 shl IntShift - 1

proc raiseOutOfMem() {.noinline.} =
  if outOfMemHook != nil: outOfMemHook()
  cstderr.rawWrite("out of memory")
  quit(1)

when defined(boehmgc):
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

  proc allocAtomic(size: int): pointer =
    result = boehmAllocAtomic(size)
    zeroMem(result, size)

  when not defined(useNimRtl):

    proc alloc(size: Natural): pointer =
      result = boehmAlloc(size)
      if result == nil: raiseOutOfMem()
    proc alloc0(size: Natural): pointer =
      result = alloc(size)
    proc realloc(p: pointer, newsize: Natural): pointer =
      result = boehmRealloc(p, newsize)
      if result == nil: raiseOutOfMem()
    proc dealloc(p: pointer) = boehmDealloc(p)

    proc allocShared(size: Natural): pointer =
      result = boehmAlloc(size)
      if result == nil: raiseOutOfMem()
    proc allocShared0(size: Natural): pointer =
      result = allocShared(size)
    proc reallocShared(p: pointer, newsize: Natural): pointer =
      result = boehmRealloc(p, newsize)
      if result == nil: raiseOutOfMem()
    proc deallocShared(p: pointer) = boehmDealloc(p)

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
    boehmGC_set_all_interior_pointers(0)
    boehmGCinit()
    when hasThreadSupport:
      boehmGC_allow_register_threads()

  proc newObj(typ: PNimType, size: int): pointer {.compilerproc.} =
    if ntfNoRefs in typ.flags: result = allocAtomic(size)
    else: result = alloc(size)
  proc newSeq(typ: PNimType, len: int): pointer {.compilerproc.} =
    result = newObj(typ, addInt(mulInt(len, typ.base.size), GenericSeqSize))
    cast[PGenericSeq](result).len = len
    cast[PGenericSeq](result).reserved = len

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

elif defined(gogc):
  when defined(windows):
    const goLib = "libgo.dll"
  elif defined(macosx):
    const goLib = "libgo.dylib"
  else:
    const goLib = "libgo.so"

  proc initGC() = discard
  proc GC_disable() = discard
  proc GC_enable() = discard
  proc go_gc() {.importc: "go_gc", dynlib: goLib.}
  proc GC_fullCollect() = go_gc()
  proc GC_setStrategy(strategy: GC_Strategy) = discard
  proc GC_enableMarkAndSweep() = discard
  proc GC_disableMarkAndSweep() = discard

  const
    goNumSizeClasses = 67

  type
    goMStats = object
      alloc: uint64          # bytes allocated and still in use
      total_alloc: uint64    # bytes allocated (even if freed)
      sys: uint64            # bytes obtained from system
      nlookup: uint64        # number of pointer lookups
      nmalloc: uint64        # number of mallocs
      nfree: uint64          # number of frees
      heap_objects: uint64   # total number of allocated objects
      pause_total_ns: uint64 # cumulative nanoseconds in GC stop-the-world pauses since the program started
      numgc: uint32          # number of completed GC cycles

  proc goMemStats(): goMStats {.importc: "go_mem_stats", dynlib: goLib.}
  proc goMalloc(size: uint): pointer {.importc: "go_malloc", dynlib: goLib.}
  proc goSetFinalizer(obj: pointer, f: pointer) {.importc: "set_finalizer", codegenDecl:"$1 $2$3 __asm__ (\"main.Set_finalizer\");\n$1 $2$3", dynlib: goLib.}
  proc writebarrierptr(dest: PPointer, src: pointer) {.importc: "writebarrierptr", codegenDecl:"$1 $2$3 __asm__ (\"main.Atomic_store_pointer\");\n$1 $2$3", dynlib: goLib.}

  proc GC_getStatistics(): string =
    var mstats = goMemStats()
    result = "[GC] total allocated memory: " & $(mstats.total_alloc) & "\n" &
             "[GC] total memory obtained from system: " & $(mstats.sys) & "\n" &
             "[GC] occupied memory: " & $(mstats.alloc) & "\n" &
             "[GC] number of pointer lookups: " & $(mstats.nlookup) & "\n" &
             "[GC] number of mallocs: " & $(mstats.nmalloc) & "\n" &
             "[GC] number of frees: " & $(mstats.nfree) & "\n" &
             "[GC] heap objects: " & $(mstats.heap_objects) & "\n" &
             "[GC] number of completed GC cycles: " & $(mstats.numgc) & "\n" &
             "[GC] total GC pause time [ms]: " & $(mstats.pause_total_ns div 1000_000)

  proc getOccupiedMem(): int =
    var mstats = goMemStats()
    result = int(mstats.alloc)

  proc getFreeMem(): int =
    var mstats = goMemStats()
    result = int(mstats.sys - mstats.alloc)

  proc getTotalMem(): int =
    var mstats = goMemStats()
    result = int(mstats.sys)

  proc nimGC_setStackBottom(theStackBottom: pointer) = discard

  proc alloc(size: Natural): pointer =
    result = goMalloc(size.uint)

  proc alloc0(size: Natural): pointer =
    result = goMalloc(size.uint)

  proc realloc(p: pointer, newsize: Natural): pointer =
    raise newException(Exception, "not implemented")

  proc dealloc(p: pointer) =
    discard

  proc allocShared(size: Natural): pointer =
    result = alloc(size)

  proc allocShared0(size: Natural): pointer =
    result = alloc0(size)

  proc reallocShared(p: pointer, newsize: Natural): pointer =
    result = realloc(p, newsize)

  proc deallocShared(p: pointer) = dealloc(p)

  when hasThreadSupport:
    proc getFreeSharedMem(): int = discard
    proc getTotalSharedMem(): int = discard
    proc getOccupiedSharedMem(): int = discard

  proc newObj(typ: PNimType, size: int): pointer {.compilerproc.} =
    writebarrierptr(addr(result), goMalloc(size.uint))
    if typ.finalizer != nil:
      goSetFinalizer(result, typ.finalizer)

  proc newObjRC1(typ: PNimType, size: int): pointer {.compilerRtl.} =
    writebarrierptr(addr(result), newObj(typ, size))

  proc newObjNoInit(typ: PNimType, size: int): pointer =
    writebarrierptr(addr(result), newObj(typ, size))

  proc newSeq(typ: PNimType, len: int): pointer {.compilerproc.} =
    writebarrierptr(addr(result), newObj(typ, len * typ.base.size + GenericSeqSize))
    cast[PGenericSeq](result).len = len
    cast[PGenericSeq](result).reserved = len
    cast[PGenericSeq](result).elemSize = typ.base.size

  proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =
    writebarrierptr(addr(result), newSeq(typ, len))

  proc nimNewSeqOfCap(typ: PNimType, cap: int): pointer {.compilerproc.} =
    result = newObj(typ, cap * typ.base.size + GenericSeqSize)
    cast[PGenericSeq](result).len = 0
    cast[PGenericSeq](result).reserved = cap
    cast[PGenericSeq](result).elemSize = typ.base.size

  proc typedMemMove(dest: pointer, src: pointer, size: uint) {.importc: "typedmemmove", dynlib: goLib.}

  proc growObj(old: pointer, newsize: int): pointer =
    # the Go GC doesn't have a realloc
    var metadataOld = cast[PGenericSeq](old)
    if metadataOld.elemSize == 0:
      metadataOld.elemSize = 1
    let oldsize = cast[PGenericSeq](old).len * cast[PGenericSeq](old).elemSize + GenericSeqSize
    writebarrierptr(addr(result), goMalloc(newsize.uint))
    typedMemMove(result, old, oldsize.uint)

  proc nimGCref(p: pointer) {.compilerproc, inline.} = discard
  proc nimGCunref(p: pointer) {.compilerproc, inline.} = discard
  proc nimGCunrefNoCycle(p: pointer) {.compilerProc, inline.} = discard
  proc nimGCunrefRC1(p: pointer) {.compilerProc, inline.} = discard
  proc nimGCvisit(d: pointer, op: int) {.compilerRtl.} = discard

  proc unsureAsgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
    writebarrierptr(dest, src)
  proc asgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
    writebarrierptr(dest, src)
  proc asgnRefNoCycle(dest: PPointer, src: pointer) {.compilerproc, inline,
    deprecated: "old compiler compat".} = asgnRef(dest, src)

  type
    MemRegion = object

  proc alloc(r: var MemRegion, size: int): pointer =
    result = alloc(size)
  proc alloc0(r: var MemRegion, size: int): pointer =
    result = alloc0(size)
  proc dealloc(r: var MemRegion, p: pointer) = dealloc(p)
  proc deallocOsPages(r: var MemRegion) {.inline.} = discard
  proc deallocOsPages() {.inline.} = discard

elif defined(nogc) and defined(useMalloc):

  when not defined(useNimRtl):
    proc alloc(size: Natural): pointer =
      var x = c_malloc(size + sizeof(size))
      if x == nil: raiseOutOfMem()

      cast[ptr int](x)[] = size
      result = cast[pointer](cast[int](x) + sizeof(size))

    proc alloc0(size: Natural): pointer =
      result = alloc(size)
      zeroMem(result, size)
    proc realloc(p: pointer, newsize: Natural): pointer =
      var x = cast[pointer](cast[int](p) - sizeof(newsize))
      let oldsize = cast[ptr int](x)[]

      x = c_realloc(x, newsize + sizeof(newsize))

      if x == nil: raiseOutOfMem()

      cast[ptr int](x)[] = newsize
      result = cast[pointer](cast[int](x) + sizeof(newsize))

      if newsize > oldsize:
        zeroMem(cast[pointer](cast[int](result) + oldsize), newsize - oldsize)

    proc dealloc(p: pointer) = c_free(cast[pointer](cast[int](p) - sizeof(int)))

    proc allocShared(size: Natural): pointer =
      result = c_malloc(size)
      if result == nil: raiseOutOfMem()
    proc allocShared0(size: Natural): pointer =
      result = alloc(size)
      zeroMem(result, size)
    proc reallocShared(p: pointer, newsize: Natural): pointer =
      result = c_realloc(p, newsize)
      if result == nil: raiseOutOfMem()
    proc deallocShared(p: pointer) = c_free(p)

    proc GC_disable() = discard
    proc GC_enable() = discard
    proc GC_fullCollect() = discard
    proc GC_setStrategy(strategy: GC_Strategy) = discard
    proc GC_enableMarkAndSweep() = discard
    proc GC_disableMarkAndSweep() = discard
    proc GC_getStatistics(): string = return ""

    proc getOccupiedMem(): int = discard
    proc getFreeMem(): int = discard
    proc getTotalMem(): int = discard

    proc nimGC_setStackBottom(theStackBottom: pointer) = discard

  proc initGC() = discard

  proc newObj(typ: PNimType, size: int): pointer {.compilerproc.} =
    result = alloc0(size)
  proc newSeq(typ: PNimType, len: int): pointer {.compilerproc.} =
    result = newObj(typ, addInt(mulInt(len, typ.base.size), GenericSeqSize))
    cast[PGenericSeq](result).len = len
    cast[PGenericSeq](result).reserved = len

  proc newObjNoInit(typ: PNimType, size: int): pointer =
    result = alloc(size)

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
    result = alloc(size)
  proc alloc0(r: var MemRegion, size: int): pointer =
    result = alloc0(size)
  proc dealloc(r: var MemRegion, p: pointer) = dealloc(p)
  proc deallocOsPages(r: var MemRegion) {.inline.} = discard
  proc deallocOsPages() {.inline.} = discard

elif defined(nogc):
  # Even though we don't want the GC, we cannot simply use C's memory manager
  # because Nim's runtime wants ``realloc`` to zero out the additional
  # space which C's ``realloc`` does not. And we cannot get the old size of an
  # object, because C does not support this operation... Even though every
  # possible implementation has to have a way to determine the object's size.
  # C just sucks.
  when appType == "lib":
    {.warning: "nogc in a library context may not work".}

  include "system/alloc"

  proc initGC() = discard
  proc GC_disable() = discard
  proc GC_enable() = discard
  proc GC_fullCollect() = discard
  proc GC_setStrategy(strategy: GC_Strategy) = discard
  proc GC_enableMarkAndSweep() = discard
  proc GC_disableMarkAndSweep() = discard
  proc GC_getStatistics(): string = return ""

  proc newObj(typ: PNimType, size: int): pointer {.compilerproc.} =
    result = alloc0(size)

  proc newObjNoInit(typ: PNimType, size: int): pointer =
    result = alloc(size)

  proc newSeq(typ: PNimType, len: int): pointer {.compilerproc.} =
    result = newObj(typ, addInt(mulInt(len, typ.base.size), GenericSeqSize))
    cast[PGenericSeq](result).len = len
    cast[PGenericSeq](result).reserved = len

  proc growObj(old: pointer, newsize: int): pointer =
    result = realloc(old, newsize)

  proc nimGC_setStackBottom(theStackBottom: pointer) = discard
  proc nimGCref(p: pointer) {.compilerproc, inline.} = discard
  proc nimGCunref(p: pointer) {.compilerproc, inline.} = discard

  proc unsureAsgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
    dest[] = src
  proc asgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
    dest[] = src
  proc asgnRefNoCycle(dest: PPointer, src: pointer) {.compilerproc, inline,
    deprecated: "old compiler compat".} = asgnRef(dest, src)

  var allocator {.rtlThreadVar.}: MemRegion
  instantiateForRegion(allocator)

  include "system/cellsets"

else:
  when not defined(gcRegions):
    include "system/alloc"

    include "system/cellsets"
    when not leakDetector and not useCellIds:
      sysAssert(sizeof(Cell) == sizeof(FreeCell), "sizeof FreeCell")
  when compileOption("gc", "v2"):
    include "system/gc2"
  elif defined(gcRegions):
    # XXX due to bootstrapping reasons, we cannot use  compileOption("gc", "stack") here
    include "system/gc_regions"
  elif defined(gcMarkAndSweep) or defined(gcDestructors):
    # XXX use 'compileOption' here
    include "system/gc_ms"
  else:
    include "system/gc"

when not declared(nimNewSeqOfCap) and not defined(gcDestructors):
  proc nimNewSeqOfCap(typ: PNimType, cap: int): pointer {.compilerproc.} =
    when defined(gcRegions):
      let s = mulInt(cap, typ.base.size)  # newStr already adds GenericSeqSize
      result = newStr(typ, s, ntfNoRefs notin typ.base.flags)
    else:
      let s = addInt(mulInt(cap, typ.base.size), GenericSeqSize)
      when declared(newObjNoInit):
        result = if ntfNoRefs in typ.base.flags: newObjNoInit(typ, s) else: newObj(typ, s)
      else:
        result = newObj(typ, s)
      cast[PGenericSeq](result).len = 0
      cast[PGenericSeq](result).reserved = cap

{.pop.}

when not declared(ForeignCell):
  type ForeignCell* = object
    data*: pointer

  proc protect*(x: pointer): ForeignCell = ForeignCell(data: x)
  proc dispose*(x: ForeignCell) = discard
  proc isNotForeign*(x: ForeignCell): bool = false
