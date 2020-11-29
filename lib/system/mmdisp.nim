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

when declared(IntsPerTrunk):
  discard
else:
  include bitmasks

proc raiseOutOfMem() {.noinline.} =
  if outOfMemHook != nil: outOfMemHook()
  cstderr.rawWrite("out of memory\n")
  quit(1)

when defined(boehmgc):
  include system / mm / boehm

elif defined(gogc):
  include system / mm / go

elif (defined(nogc) or defined(gcDestructors)) and defined(useMalloc):
  include system / mm / malloc

elif defined(nogc):
  include system / mm / none

else:
  when not defined(gcRegions):
    include "system/alloc"

    when not usesDestructors:
      include "system/cellsets"
    when not leakDetector and not useCellIds and not defined(nimV2):
      sysAssert(sizeof(Cell) == sizeof(FreeCell), "sizeof FreeCell")
  when compileOption("gc", "v2"):
    include "system/gc2"
  elif defined(gcRegions):
    # XXX due to bootstrapping reasons, we cannot use  compileOption("gc", "stack") here
    include "system/gc_regions"
  elif defined(nimV2) or usesDestructors:
    var allocator {.rtlThreadVar.}: MemRegion
    instantiateForRegion(allocator)
    when defined(gcHooks):
      include "system/gc_hooks"
  elif defined(gcMarkAndSweep):
    # XXX use 'compileOption' here
    include "system/gc_ms"
  else:
    include "system/gc"

when not declared(nimNewSeqOfCap) and not defined(nimSeqsV2):
  {.push overflowChecks: on.}
  proc nimNewSeqOfCap(typ: PNimType, cap: int): pointer {.compilerproc.} =
    when defined(gcRegions):
      let s = cap * typ.base.size  # newStr already adds GenericSeqSize
      result = newStr(typ, s, ntfNoRefs notin typ.base.flags)
    else:
      let s = align(GenericSeqSize, typ.base.align) + cap * typ.base.size
      when declared(newObjNoInit):
        result = if ntfNoRefs in typ.base.flags: newObjNoInit(typ, s) else: newObj(typ, s)
      else:
        result = newObj(typ, s)
      cast[PGenericSeq](result).len = 0
      cast[PGenericSeq](result).reserved = cap
  {.pop.}

{.pop.}

when not declared(ForeignCell):
  type ForeignCell* = object
    data*: pointer

  proc protect*(x: pointer): ForeignCell = ForeignCell(data: x)
  proc dispose*(x: ForeignCell) = discard
  proc isNotForeign*(x: ForeignCell): bool = false
