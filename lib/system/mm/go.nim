
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

proc allocImpl(size: Natural): pointer =
  result = goMalloc(size.uint)

proc alloc0Impl(size: Natural): pointer =
  result = goMalloc(size.uint)

proc reallocImpl(p: pointer, newsize: Natural): pointer =
  doAssert false, "not implemented"

proc realloc0Impl(p: pointer, oldsize, newsize: Natural): pointer =
  doAssert false, "not implemented"

proc deallocImpl(p: pointer) =
  discard

proc allocSharedImpl(size: Natural): pointer = allocImpl(size)
proc allocShared0Impl(size: Natural): pointer = alloc0Impl(size)
proc reallocSharedImpl(p: pointer, newsize: Natural): pointer = reallocImpl(p, newsize)
proc reallocShared0Impl(p: pointer, oldsize, newsize: Natural): pointer = realloc0Impl(p, oldsize, newsize)
proc deallocSharedImpl(p: pointer) = deallocImpl(p)

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
  writebarrierptr(addr(result), newObj(typ, align(GenericSeqSize, typ.base.align) + len * typ.base.size))
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len
  cast[PGenericSeq](result).elemSize = typ.base.size
  cast[PGenericSeq](result).elemAlign = typ.base.align

proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =
  writebarrierptr(addr(result), newSeq(typ, len))

proc nimNewSeqOfCap(typ: PNimType, cap: int): pointer {.compilerproc.} =
  result = newObj(typ, align(GenericSeqSize, typ.base.align) + cap * typ.base.size)
  cast[PGenericSeq](result).len = 0
  cast[PGenericSeq](result).reserved = cap
  cast[PGenericSeq](result).elemSize = typ.base.size
  cast[PGenericSeq](result).elemAlign = typ.base.align

proc typedMemMove(dest: pointer, src: pointer, size: uint) {.importc: "typedmemmove", dynlib: goLib.}

proc growObj(old: pointer, newsize: int): pointer =
  # the Go GC doesn't have a realloc
  let old = cast[PGenericSeq](old)
  var metadataOld = cast[PGenericSeq](old)
  if metadataOld.elemSize == 0:
    metadataOld.elemSize = 1

  let oldsize = align(GenericSeqSize, old.elemAlign) + old.len * old.elemSize
  writebarrierptr(addr(result), goMalloc(newsize.uint))
  typedMemMove(result, old, oldsize.uint)

proc nimGCref(p: pointer) {.compilerproc, inline.} = discard
proc nimGCunref(p: pointer) {.compilerproc, inline.} = discard
proc nimGCunrefNoCycle(p: pointer) {.compilerproc, inline.} = discard
proc nimGCunrefRC1(p: pointer) {.compilerproc, inline.} = discard
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
  result = alloc0Impl(size)
proc dealloc(r: var MemRegion, p: pointer) = dealloc(p)
proc deallocOsPages(r: var MemRegion) {.inline.} = discard
proc deallocOsPages() {.inline.} = discard
