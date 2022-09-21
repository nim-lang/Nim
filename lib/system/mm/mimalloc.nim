when not defined(vcc):
  # Generic GCC-like arguments
  {.passc: "-DNDEBUG -fvisibility=hidden".}
  # shell32 user32 aren't needed for static linking from my testing
  when defined(windows):
    {.passl: "-lpsapi -lbcrypt -ladvapi32".}
else:
  # Specifically for VCC which has different syntax
  {.passc: "/DNDEBUG".}
  {.passl: "psapi.lib bcrypt.lib advapi32.lib".}

const
  mimallocStatic {.strdefine.} = "empty"
  mimallocIncludePath {.strdefine.} = "empty"
  # Can't import std/strutils in this file so we unquote the manual way
  mimallocStaticNoQuote = block:
    var c: string
    for i in 1..<mimallocStatic.len - 1:
      c.add mimallocStatic[i]
    c

{.passc: "-I" & mimallocIncludePath.}
{.passl: "-I" & mimallocIncludePath.}
{.compile: mimallocStaticNoQuote.}

{.push stackTrace: off.}

proc mi_malloc(size: csize_t): pointer {.importc, header: "mimalloc.h".}
proc mi_calloc(nmemb: csize_t, size: csize_t): pointer {.importc, header: "mimalloc.h".}
proc mi_realloc(pt: pointer, size: csize_t): pointer {.importc, header: "mimalloc.h".}
proc mi_free(p: pointer) {.importc, header: "mimalloc.h".}


proc allocImpl(size: Natural): pointer =
  result = mi_malloc(size.csize_t)
  when defined(zephyr):
    if result == nil:
      raiseOutOfMem()

proc alloc0Impl(size: Natural): pointer =
  result = mi_calloc(size.csize_t, 1)
  when defined(zephyr):
    if result == nil:
      raiseOutOfMem()

proc reallocImpl(p: pointer, newSize: Natural): pointer =
  result = mi_realloc(p, newSize.csize_t)
  when defined(zephyr):
    if result == nil:
      raiseOutOfMem()

proc realloc0Impl(p: pointer, oldsize, newSize: Natural): pointer =
  result = realloc(p, newSize.csize_t)
  if newSize > oldSize:
    zeroMem(cast[pointer](cast[int](result) + oldSize), newSize - oldSize)

proc deallocImpl(p: pointer) =
  mi_free(p)


# The shared allocators map on the regular ones

proc allocSharedImpl(size: Natural): pointer =
  allocImpl(size)

proc allocShared0Impl(size: Natural): pointer =
  alloc0Impl(size)

proc reallocSharedImpl(p: pointer, newSize: Natural): pointer =
  reallocImpl(p, newSize)

proc reallocShared0Impl(p: pointer, oldsize, newSize: Natural): pointer =
  realloc0Impl(p, oldSize, newSize)

proc deallocSharedImpl(p: pointer) = deallocImpl(p)


# Empty stubs for the GC

proc GC_disable() = discard
proc GC_enable() = discard

when not defined(gcOrc):
  proc GC_fullCollect() = discard
  proc GC_enableMarkAndSweep() = discard
  proc GC_disableMarkAndSweep() = discard

proc GC_setStrategy(strategy: GC_Strategy) = discard

proc getOccupiedMem(): int = discard
proc getFreeMem(): int = discard
proc getTotalMem(): int = discard

proc nimGC_setStackBottom(theStackBottom: pointer) = discard

proc initGC() = discard

proc newObjNoInit(typ: PNimType, size: int): pointer =
  result = alloc(size)

proc growObj(old: pointer, newsize: int): pointer =
  result = realloc(old, newsize)

proc nimGCref(p: pointer) {.compilerproc, inline.} = discard
proc nimGCunref(p: pointer) {.compilerproc, inline.} = discard

when not defined(gcDestructors):
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
proc alloc0Impl(r: var MemRegion, size: int): pointer =
  result = alloc0Impl(size)
proc dealloc(r: var MemRegion, p: pointer) = dealloc(p)
proc deallocOsPages(r: var MemRegion) = discard
proc deallocOsPages() = discard

{.pop.}
