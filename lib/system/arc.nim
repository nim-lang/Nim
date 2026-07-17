#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#[
In this new runtime we simplify the object layouts a bit: The runtime type
information is only accessed for the objects that have it and it's always
at offset 0 then. The ``ref`` object header is independent from the
runtime type and only contains a reference count.
]#

{.push raises: [], rangeChecks: off.}

when defined(gcOrc) or defined(gcYrc):
  const
    rcIncrement = 0b10000 # so that lowest 4 bits are not touched
    rcMask = 0b1111
    rcShift = 4      # shift by rcShift to get the reference counter

else:
  const
    rcIncrement = 0b1000 # so that lowest 3 bits are not touched
    rcMask = 0b111
    rcShift = 3      # shift by rcShift to get the reference counter

const
  orcLeakDetector = defined(nimOrcLeakDetector)

type
  RefHeader = object
    rc: int # the object header is now a single RC field.
            # we could remove it in non-debug builds for the 'owned ref'
            # design but this seems unwise.
    when defined(gcOrc) or defined(gcYrc):
      rootIdx: int # thanks to this we can delete potential cycle roots
                   # in O(1) without doubly linked lists
    when defined(nimArcDebug) or defined(nimArcIds):
      refId: int
    when (defined(gcOrc) or defined(gcYrc)) and orcLeakDetector:
      filename: cstring
      line: int

  Cell = ptr RefHeader

template setFrameInfo(c: Cell) =
  when orcLeakDetector:
    if framePtr != nil and framePtr.prev != nil:
      c.filename = framePtr.prev.filename
      c.line = framePtr.prev.line
    else:
      c.filename = nil
      c.line = 0

template head(p: pointer): Cell =
  cast[Cell](cast[int](p) -% sizeof(RefHeader))

const
  traceCollector = defined(traceArc)

when defined(nimArcDebug):
  include cellsets

  const traceId = 20 # 1037

  var gRefId: int
  var freedCells: CellSet
elif defined(nimArcIds):
  var gRefId: int

  const traceId = -1

when (defined(gcAtomicArc) or defined(gcYrc)) and hasThreadSupport:
  template decrement(cell: Cell): untyped =
    discard atomicDec(cell.rc, rcIncrement)
  template increment(cell: Cell): untyped =
    discard atomicInc(cell.rc, rcIncrement)
  template count(x: Cell): untyped =
    atomicLoadN(x.rc.addr, ATOMIC_ACQUIRE) shr rcShift
else:
  template decrement(cell: Cell): untyped =
    cell.rc = cell.rc -% rcIncrement
  template increment(cell: Cell): untyped =
    cell.rc = cell.rc +% rcIncrement
  template count(x: Cell): untyped =
    x.rc shr rcShift

when not defined(nimHasQuirky):
  {.pragma: quirky.}

# Forward declarations for native allocator alignment (implemented in alloc.nim).
# rawAlloc's contract: result + sizeof(FreeCell) is alignment-aligned.
# For ORC/YRC, sizeof(FreeCell) == sizeof(RefHeader).
const useNativeAlignedAlloc = (defined(gcOrc) or defined(gcYrc)) and
  not defined(useMalloc) and not defined(nimscript) and
  not defined(nimdoc) and not defined(useNimRtl)

when useNativeAlignedAlloc:
  proc nimAlignedAlloc0(size: Natural, alignment: int): pointer {.gcsafe, raises: [].}
  proc nimAlignedAlloc(size: Natural, alignment: int): pointer {.gcsafe, raises: [].}
  proc nimAlignedDealloc(p: pointer) {.gcsafe, raises: [].}

proc nimNewObj(size, alignment: int): pointer {.compilerRtl.} =
  when defined(nimscript) or defined(nimdoc):
    discard
  elif useNativeAlignedAlloc:
    let s = size +% sizeof(RefHeader)
    result = nimAlignedAlloc0(s, alignment) +! sizeof(RefHeader)
  else:
    let hdrSize = align(sizeof(RefHeader), alignment)
    let s = size +% hdrSize
    result = alignedAlloc0(s, alignment) +! hdrSize
  when defined(nimArcDebug) or defined(nimArcIds):
    head(result).refId = gRefId
    atomicInc gRefId
    if head(result).refId == traceId:
      writeStackTrace()
      cfprintf(cstderr, "[nimNewObj] %p %ld\n", result, head(result).count)
  when traceCollector:
    cprintf("[Allocated] %p result: %p\n", result -! sizeof(RefHeader), result)
  setFrameInfo head(result)

proc nimNewObjUninit(size, alignment: int): pointer {.compilerRtl.} =
  # Same as 'newNewObj' but do not initialize the memory to zero.
  when defined(nimscript) or defined(nimdoc):
    discard
  elif useNativeAlignedAlloc:
    let s = size + sizeof(RefHeader)
    result = cast[ptr RefHeader](nimAlignedAlloc(s, alignment) +! sizeof(RefHeader))
  else:
    let hdrSize = align(sizeof(RefHeader), alignment)
    let s = size + hdrSize
    result = cast[ptr RefHeader](alignedAlloc(s, alignment) +! hdrSize)
  head(result).rc = 0
  when defined(gcOrc) or defined(gcYrc):
    head(result).rootIdx = 0
  when defined(nimArcDebug):
    head(result).refId = gRefId
    atomicInc gRefId
    if head(result).refId == traceId:
      writeStackTrace()
      cfprintf(cstderr, "[nimNewObjUninit] %p %ld\n", result, head(result).count)

  when traceCollector:
    cprintf("[Allocated] %p result: %p\n", result -! sizeof(RefHeader), result)
  setFrameInfo head(result)

proc nimDecWeakRef(p: pointer) {.compilerRtl, inl.} =
  decrement head(p)

proc isUniqueRef*[T](x: ref T): bool {.inline.} =
  ## Returns true if the object `x` points to is uniquely referenced. Such
  ## an object can potentially be passed over to a different thread safely,
  ## if great care is taken. This queries the internal reference count of
  ## the object which is subject to lots of optimizations! In other words
  ## the value of `isUniqueRef` can depend on the used compiler version and
  ## optimizer setting.
  ## Nevertheless it can be used as a very valuable debugging tool and can
  ## be used to specify the constraints of a threading related API
  ## via `assert isUniqueRef(x)`.
  head(cast[pointer](x)).rc == 0

proc nimIncRef(p: pointer) {.compilerRtl, inl.} =
  when defined(nimArcDebug):
    if head(p).refId == traceId:
      writeStackTrace()
      cfprintf(cstderr, "[IncRef] %p %ld\n", p, head(p).count)

  increment head(p)
  when traceCollector:
    cprintf("[INCREF] %p\n", head(p))

when not (defined(gcOrc) or defined(gcYrc)) or defined(nimThinout):
  proc unsureAsgnRef(dest: ptr pointer, src: pointer) {.inline.} =
    # This is only used by the old RTTI mechanism and we know
    # that 'dest[]' is nil and needs no destruction. Which is really handy
    # as we cannot destroy the object reliably if it's an object of unknown
    # compile-time type.
    dest[] = src
    if src != nil: nimIncRef src

when not defined(nimscript) and defined(nimArcDebug):
  proc deallocatedRefId*(p: pointer): int =
    ## Returns the ref's ID if the ref was already deallocated. This
    ## is a memory corruption check. Returns 0 if there is no error.
    let c = head(p)
    if freedCells.data != nil and freedCells.contains(c):
      result = c.refId
    else:
      result = 0

proc nimRawDispose(p: pointer, alignment: int) {.compilerRtl.} =
  when not defined(nimscript):
    when traceCollector:
      cprintf("[Freed] %p\n", p -! sizeof(RefHeader))
    when defined(nimOwnedEnabled):
      if head(p).rc >= rcIncrement:
        cstderr.rawWrite "[FATAL] dangling references exist\n"
        rawQuit 1
    when defined(nimArcDebug):
      # we do NOT really free the memory here in order to reliably detect use-after-frees
      if freedCells.data == nil: init(freedCells)
      freedCells.incl head(p)
    else:
      when useNativeAlignedAlloc:
        nimAlignedDealloc(p -! sizeof(RefHeader))
      else:
        let hdrSize = align(sizeof(RefHeader), alignment)
        alignedDealloc(p -! hdrSize, alignment)

template `=dispose`*[T](x: owned(ref T)) = nimRawDispose(cast[pointer](x), T.alignOf)
#proc dispose*(x: pointer) = nimRawDispose(x)

proc nimDestroyAndDispose(p: pointer) {.compilerRtl, quirky, raises: [].} =
  let rti = cast[ptr PNimTypeV2](p)
  if rti.destructor != nil:
    cast[DestructorProc](rti.destructor)(p)
  when false:
    cstderr.rawWrite cast[ptr PNimTypeV2](p)[].name
    cstderr.rawWrite "\n"
    if d == nil:
      cstderr.rawWrite "bah, nil\n"
    else:
      cstderr.rawWrite "has destructor!\n"
  nimRawDispose(p, rti.align)

when defined(gcYrc):
  include yrc
elif defined(gcOrc):
  when defined(nimThinout):
    include cyclebreaker
  else:
    include orc
    #include cyclecollector

proc nimDecRefIsLast(p: pointer): bool {.compilerRtl, inl.} =
  result = false
  if p != nil:
    var cell = head(p)

    when defined(nimArcDebug):
      if cell.refId == traceId:
        writeStackTrace()
        cfprintf(cstderr, "[DecRef] %p %ld\n", p, cell.count)

    when (defined(gcAtomicArc) or defined(gcYrc)) and hasThreadSupport:
      # `atomicDec` returns the new value
      if atomicDec(cell.rc, rcIncrement) == -rcIncrement:
        result = true
        when traceCollector:
          cprintf("[ABOUT TO DESTROY] %p\n", cell)
    else:
      if cell.count == 0:
        result = true
        when traceCollector:
          cprintf("[ABOUT TO DESTROY] %p\n", cell)
      else:
        decrement cell
        # According to Lins it's correct to do nothing else here.
        when traceCollector:
          cprintf("[DECREF] %p\n", cell)

proc GC_unref*[T](x: ref T) =
  ## New runtime only supports this operation for 'ref T'.
  var y {.cursor.} = x
  `=destroy`(y)

proc GC_ref*[T](x: ref T) =
  ## New runtime only supports this operation for 'ref T'.
  if x != nil: nimIncRef(cast[pointer](x))

when not (defined(gcOrc) or defined(gcYrc)):
  template GC_fullCollect* =
    ## Forces a full garbage collection pass. With `--mm:arc` a nop.
    discard

const hasForeignThreadAllocatorTeardown =
  when hasThreadSupport: not emulatedThreadVars
  else: false

when not hasForeignThreadAllocatorTeardown:
  template setupForeignThreadGc* =
    ## With `--mm:arc` a nop unless native thread-local allocator teardown is available.
    discard

  template tearDownForeignThreadGc* =
    ## With `--mm:arc` a nop unless native thread-local allocator teardown is available.
    discard

proc isObjDisplayCheck(source: PNimTypeV2, targetDepth: int16, token: uint32): bool {.compilerRtl, inl.} =
  result = targetDepth <= source.depth and source.display[targetDepth] == token

when defined(gcDestructors):
  proc nimGetVTable(p: pointer, index: int): pointer
        {.compilerRtl, inline, raises: [].} =
    result = cast[ptr PNimTypeV2](p).vTable[index]

{.pop.} # raises: []
