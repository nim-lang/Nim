#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Nimrod high-level memory manager: It supports Boehm's GC, no GC and the
# native Nimrod GC. The native Nimrod GC is the default.

#{.push checks:on, assertions:on.}
{.push checks:off.}

const
  debugGC = false # we wish to debug the GC...
  logGC = false
  traceGC = false # extensive debugging
  reallyDealloc = true # for debugging purposes this can be set to false
  cycleGC = true # (de)activate the cycle GC
  stressGC = false
  reallyOsDealloc = true
  coalescRight = true
  coalescLeft = true
  overwriteFree = false

type
  PPointer = ptr pointer
  TByteArray = array[0..1000_0000, byte]
  PByte = ptr TByteArray
  PString = ptr string

# Page size of the system; in most cases 4096 bytes. For exotic OS or
# CPU this needs to be changed:
const
  PageShift = 12
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

var
  gOutOfMem: ref EOutOfMemory

proc raiseOutOfMem() {.noreturn.} =
  if gOutOfMem == nil: 
    echo("out of memory; cannot even throw an exception")
    quit(1)
  gOutOfMem.msg = "out of memory"
  raise gOutOfMem

when defined(boehmgc):
  when defined(windows):
    const boehmLib = "boehmgc.dll"
  elif defined(macosx):
    const boehmLib = "libgc.dylib"
    
    proc boehmGCinit {.importc: "GC_init", dynlib: boehmLib.}
  else:
    const boehmLib = "/usr/lib/libgc.so.1"

  proc boehmGC_disable {.importc: "GC_disable", dynlib: boehmLib.} 
  proc boehmGC_enable {.importc: "GC_enable", dynlib: boehmLib.} 
  proc boehmGCincremental {.
    importc: "GC_enable_incremental", dynlib: boehmLib.} 
  proc boehmGCfullCollect {.importc: "GC_gcollect", dynlib: boehmLib.}  
  proc boehmAlloc(size: int): pointer {.
    importc: "GC_malloc", dynlib: boehmLib.}
  proc boehmAllocAtomic(size: int): pointer {.
    importc: "GC_malloc_atomic", dynlib: boehmLib.}
  proc boehmRealloc(p: pointer, size: int): pointer {.
    importc: "GC_realloc", dynlib: boehmLib.}
  proc boehmDealloc(p: pointer) {.importc: "GC_free", dynlib: boehmLib.}
    
  proc alloc(size: int): pointer =
    result = boehmAlloc(size)
    if result == nil: raiseOutOfMem()
  proc alloc0(size: int): pointer =
    result = alloc(size)
    zeroMem(result, size)
  proc realloc(p: Pointer, newsize: int): pointer =
    result = boehmRealloc(p, newsize)
    if result == nil: raiseOutOfMem()
  proc dealloc(p: Pointer) =
    boehmDealloc(p)

  proc initGC() = 
    when defined(macosx): boehmGCinit()
  
  #boehmGCincremental()

  proc GC_disable() = boehmGC_disable()
  proc GC_enable() = boehmGC_enable()
  proc GC_fullCollect() = boehmGCfullCollect()
  proc GC_setStrategy(strategy: TGC_Strategy) = nil
  proc GC_enableMarkAndSweep() = nil
  proc GC_disableMarkAndSweep() = nil
  proc GC_getStatistics(): string = return ""
  
  proc getOccupiedMem(): int = return -1
  proc getFreeMem(): int = return -1
  proc getTotalMem(): int = return -1

  proc newObj(typ: PNimType, size: int): pointer {.compilerproc.} =
    result = alloc(size)
  proc newSeq(typ: PNimType, len: int): pointer {.compilerproc.} =
    result = newObj(typ, addInt(mulInt(len, typ.base.size), GenericSeqSize))
    cast[PGenericSeq](result).len = len
    cast[PGenericSeq](result).space = len

  proc growObj(old: pointer, newsize: int): pointer =
    result = realloc(old, newsize)

  proc setStackBottom(theStackBottom: pointer) = nil
  proc nimGCref(p: pointer) {.compilerproc, inline.} = nil
  proc nimGCunref(p: pointer) {.compilerproc, inline.} = nil
  
  proc unsureAsgnRef(dest: ppointer, src: pointer) {.compilerproc, inline.} =
    dest[] = src
  proc asgnRef(dest: ppointer, src: pointer) {.compilerproc, inline.} =
    dest[] = src
  proc asgnRefNoCycle(dest: ppointer, src: pointer) {.compilerproc, inline.} =
    dest[] = src

  include "system/cellsets"
elif defined(nogc):
  # Even though we don't want the GC, we cannot simply use C's memory manager
  # because Nimrod's runtime wants ``realloc`` to zero out the additional
  # space which C's ``realloc`` does not. And we cannot get the old size of an
  # object, because C does not support this operation... Even though every
  # possible implementation has to have a way to determine the object's size.
  # C just sucks.
  when appType == "lib": 
    {.warning: "nogc in a library context may not work".}
  
  include "system/alloc"

  when false:
    proc alloc(size: int): pointer =
      result = c_malloc(size)
      if result == nil: raiseOutOfMem()
    proc alloc0(size: int): pointer =
      result = alloc(size)
      zeroMem(result, size)
    proc realloc(p: Pointer, newsize: int): pointer =
      result = c_realloc(p, newsize)
      if result == nil: raiseOutOfMem()
    proc dealloc(p: Pointer) = c_free(p)
    proc getOccupiedMem(): int = return -1
    proc getFreeMem(): int = return -1
    proc getTotalMem(): int = return -1

  proc initGC() = nil
  proc GC_disable() = nil
  proc GC_enable() = nil
  proc GC_fullCollect() = nil
  proc GC_setStrategy(strategy: TGC_Strategy) = nil
  proc GC_enableMarkAndSweep() = nil
  proc GC_disableMarkAndSweep() = nil
  proc GC_getStatistics(): string = return ""
  
  
  proc newObj(typ: PNimType, size: int): pointer {.compilerproc.} =
    result = alloc0(size)
  proc newSeq(typ: PNimType, len: int): pointer {.compilerproc.} =
    result = newObj(typ, addInt(mulInt(len, typ.base.size), GenericSeqSize))
    cast[PGenericSeq](result).len = len
    cast[PGenericSeq](result).space = len
  proc growObj(old: pointer, newsize: int): pointer =
    result = realloc(old, newsize)

  proc setStackBottom(theStackBottom: pointer) = nil
  proc nimGCref(p: pointer) {.compilerproc, inline.} = nil
  proc nimGCunref(p: pointer) {.compilerproc, inline.} = nil
  
  proc unsureAsgnRef(dest: ppointer, src: pointer) {.compilerproc, inline.} =
    dest[] = src
  proc asgnRef(dest: ppointer, src: pointer) {.compilerproc, inline.} =
    dest[] = src
  proc asgnRefNoCycle(dest: ppointer, src: pointer) {.compilerproc, inline.} =
    dest[] = src

  include "system/cellsets"

else:
  include "system/alloc"
  include "system/cellsets"
  assert(sizeof(TCell) == sizeof(TFreeCell))
  include "system/gc"
  
{.pop.}

