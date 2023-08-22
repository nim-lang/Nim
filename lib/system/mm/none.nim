
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
  result = alloc0Impl(size)

proc newObjNoInit(typ: PNimType, size: int): pointer =
  result = alloc(size)

{.push overflowChecks: on.}
proc newSeq(typ: PNimType, len: int): pointer {.compilerproc.} =
  result = newObj(typ, align(GenericSeqSize, typ.align) + len * typ.base.size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len
{.pop.}

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
