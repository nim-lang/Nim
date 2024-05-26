
{.push stackTrace: off.}

proc allocImpl(size: Natural): pointer =
  result = c_malloc(size.csize_t)
  when defined(zephyr) or defined(handleOOM):
    if result == nil:
      raiseOutOfMem()

proc alloc0Impl(size: Natural): pointer =
  result = c_calloc(size.csize_t, 1)
  when defined(zephyr) or defined(handleOOM):
    if result == nil:
      raiseOutOfMem()

proc reallocImpl(p: pointer, newSize: Natural): pointer =
  result = c_realloc(p, newSize.csize_t)
  when defined(zephyr) or defined(handleOOM):
    if result == nil:
      raiseOutOfMem()

when defined(handleOOM):
  proc nRealloc*(p: pointer, oldsize: csize_t, newsize: csize_t): pointer  =
    result = c_malloc(newSize.csize_t)
    if result == nil:
      raiseOutOfMem()
    else:
      if p != nil and newsize != 0 and newsize > 0:
        for i in 0..(newsize - 1):
          if i < oldSize:
            cast[ptr UncheckedArray[cchar]](result)[i] = cast[ptr UncheckedArray[cchar]](p)[i]
          else:
            cast[ptr UncheckedArray[cchar]](result)[i] = '\0'
        c_free(p)
      else:
        raiseOutOfMem()



proc realloc0Impl(p: pointer, oldsize, newSize: Natural): pointer =
  when defined(handleOOM):
    result = nRealloc(p, oldsize.csize_t, newSize.csize_t)
  else:
    result = realloc(p, newSize.csize_t)
  when defined(handleOOM):
    if newSize > oldSize and result != nil:
      zeroMem(cast[pointer](cast[uint](result) + uint(oldSize)), newSize - oldSize)
    else:
      raiseOutOfMem()
  else:
    if newSize > oldSize:
      zeroMem(cast[pointer](cast[uint](result) + uint(oldSize)), newSize - oldSize)

proc deallocImpl(p: pointer) =
  c_free(p)


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
proc alloc0(r: var MemRegion, size: int): pointer =
  result = alloc0Impl(size)
proc dealloc(r: var MemRegion, p: pointer) = dealloc(p)
proc deallocOsPages(r: var MemRegion) = discard
proc deallocOsPages() = discard

{.pop.}
