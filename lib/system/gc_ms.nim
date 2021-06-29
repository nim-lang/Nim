#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# A simple mark&sweep garbage collector for Nim. Define the
# symbol ``gcUseBitvectors`` to generate a variant of this GC.

{.push profiler:off.}

const
  InitialThreshold = 4*1024*1024 # X MB because marking&sweeping is slow
  withBitvectors = defined(gcUseBitvectors)
  # bitvectors are significantly faster for GC-bench, but slower for
  # bootstrapping and use more memory
  rcWhite = 0
  rcGrey = 1   # unused
  rcBlack = 2

template mulThreshold(x): untyped = x * 2

when defined(memProfiler):
  proc nimProfile(requestedSize: int)

when hasThreadSupport:
  import sharedlist

type
  WalkOp = enum
    waMarkGlobal,  # we need to mark conservatively for global marker procs
                   # as these may refer to a global var and not to a thread
                   # local
    waMarkPrecise  # fast precise marking

  Finalizer {.compilerproc.} = proc (self: pointer) {.nimcall, benign, raises: [].}
    # A ref type can have a finalizer that is called before the object's
    # storage is freed.

  GcStat = object
    collections: int         # number of performed full collections
    maxThreshold: int        # max threshold that has been set
    maxStackSize: int        # max stack size
    freedObjects: int        # max entries in cycle table

  GcStack {.final, pure.} = object
    when nimCoroutines:
      prev: ptr GcStack
      next: ptr GcStack
      maxStackSize: int      # Used to track statistics because we can not use
                             # GcStat.maxStackSize when multiple stacks exist.
    bottom: pointer

    when nimCoroutines:
      pos: pointer

  GcHeap = object            # this contains the zero count and
                             # non-zero count table
    stack: GcStack
    when nimCoroutines:
      activeStack: ptr GcStack    # current executing coroutine stack.
    cycleThreshold: int
    when useCellIds:
      idGenerator: int
    when withBitvectors:
      allocated, marked: CellSet
    tempStack: CellSeq       # temporary stack for recursion elimination
    recGcLock: int           # prevent recursion via finalizers; no thread lock
    region: MemRegion        # garbage collected region
    stat: GcStat
    when hasThreadSupport:
      toDispose: SharedList[pointer]
    gcThreadId: int
    additionalRoots: CellSeq # dummy roots for GC_ref/unref
    when defined(nimTracing):
      tracing: bool
      indentation: int

var
  gch {.rtlThreadVar.}: GcHeap

when not defined(useNimRtl):
  instantiateForRegion(gch.region)

template gcAssert(cond: bool, msg: string) =
  when defined(useGcAssert):
    if not cond:
      cstderr.rawWrite "[GCASSERT] "
      cstderr.rawWrite msg
      quit 1

proc cellToUsr(cell: PCell): pointer {.inline.} =
  # convert object (=pointer to refcount) to pointer to userdata
  result = cast[pointer](cast[ByteAddress](cell)+%ByteAddress(sizeof(Cell)))

proc usrToCell(usr: pointer): PCell {.inline.} =
  # convert pointer to userdata to object (=pointer to refcount)
  result = cast[PCell](cast[ByteAddress](usr)-%ByteAddress(sizeof(Cell)))

proc extGetCellType(c: pointer): PNimType {.compilerproc.} =
  # used for code generation concerning debugging
  result = usrToCell(c).typ

proc unsureAsgnRef(dest: PPointer, src: pointer) {.inline, compilerproc.} =
  dest[] = src

proc internRefcount(p: pointer): int {.exportc: "getRefcount".} =
  result = 0

# this that has to equals zero, otherwise we have to round up UnitsPerPage:
when BitsPerPage mod (sizeof(int)*8) != 0:
  {.error: "(BitsPerPage mod BitsPerUnit) should be zero!".}

# forward declarations:
proc collectCT(gch: var GcHeap; size: int) {.benign, raises: [].}
proc forAllChildren(cell: PCell, op: WalkOp) {.benign, raises: [].}
proc doOperation(p: pointer, op: WalkOp) {.benign, raises: [].}
proc forAllChildrenAux(dest: pointer, mt: PNimType, op: WalkOp) {.benign, raises: [].}
# we need the prototype here for debugging purposes

when defined(nimGcRefLeak):
  const
    MaxTraceLen = 20 # tracking the last 20 calls is enough

  type
    GcStackTrace = object
      lines: array[0..MaxTraceLen-1, cstring]
      files: array[0..MaxTraceLen-1, cstring]

  proc captureStackTrace(f: PFrame, st: var GcStackTrace) =
    const
      firstCalls = 5
    var
      it = f
      i = 0
      total = 0
    while it != nil and i <= high(st.lines)-(firstCalls-1):
      # the (-1) is for the "..." entry
      st.lines[i] = it.procname
      st.files[i] = it.filename
      inc(i)
      inc(total)
      it = it.prev
    var b = it
    while it != nil:
      inc(total)
      it = it.prev
    for j in 1..total-i-(firstCalls-1):
      if b != nil: b = b.prev
    if total != i:
      st.lines[i] = "..."
      st.files[i] = "..."
      inc(i)
    while b != nil and i <= high(st.lines):
      st.lines[i] = b.procname
      st.files[i] = b.filename
      inc(i)
      b = b.prev

  var ax: array[10_000, GcStackTrace]

proc nimGCref(p: pointer) {.compilerproc.} =
  # we keep it from being collected by pretending it's not even allocated:
  when false:
    when withBitvectors: excl(gch.allocated, usrToCell(p))
    else: usrToCell(p).refcount = rcBlack
  when defined(nimGcRefLeak):
    captureStackTrace(framePtr, ax[gch.additionalRoots.len])
  add(gch.additionalRoots, usrToCell(p))

proc nimGCunref(p: pointer) {.compilerproc.} =
  let cell = usrToCell(p)
  var L = gch.additionalRoots.len-1
  var i = L
  let d = gch.additionalRoots.d
  while i >= 0:
    if d[i] == cell:
      d[i] = d[L]
      when defined(nimGcRefLeak):
        ax[i] = ax[L]
      dec gch.additionalRoots.len
      break
    dec(i)
  when false:
    when withBitvectors: incl(gch.allocated, usrToCell(p))
    else: usrToCell(p).refcount = rcWhite

when defined(nimGcRefLeak):
  proc writeLeaks() =
    for i in 0..gch.additionalRoots.len-1:
      c_fprintf(stdout, "[Heap] NEW STACK TRACE\n")
      for ii in 0..MaxTraceLen-1:
        let line = ax[i].lines[ii]
        let file = ax[i].files[ii]
        if isNil(line): break
        c_fprintf(stdout, "[Heap] %s(%s)\n", file, line)

include gc_common

proc initGC() =
  when not defined(useNimRtl):
    gch.cycleThreshold = InitialThreshold
    gch.stat.collections = 0
    gch.stat.maxThreshold = 0
    gch.stat.maxStackSize = 0
    init(gch.tempStack)
    init(gch.additionalRoots)
    when withBitvectors:
      init(gch.allocated)
      init(gch.marked)
    when hasThreadSupport:
      init(gch.toDispose)
    gch.gcThreadId = atomicInc(gHeapidGenerator) - 1
    gcAssert(gch.gcThreadId >= 0, "invalid computed thread ID")

proc forAllSlotsAux(dest: pointer, n: ptr TNimNode, op: WalkOp) {.benign.} =
  var d = cast[ByteAddress](dest)
  case n.kind
  of nkSlot: forAllChildrenAux(cast[pointer](d +% n.offset), n.typ, op)
  of nkList:
    for i in 0..n.len-1:
      forAllSlotsAux(dest, n.sons[i], op)
  of nkCase:
    var m = selectBranch(dest, n)
    if m != nil: forAllSlotsAux(dest, m, op)
  of nkNone: sysAssert(false, "forAllSlotsAux")

proc forAllChildrenAux(dest: pointer, mt: PNimType, op: WalkOp) =
  var d = cast[ByteAddress](dest)
  if dest == nil: return # nothing to do
  if ntfNoRefs notin mt.flags:
    case mt.kind
    of tyRef, tyString, tySequence: # leaf:
      doOperation(cast[PPointer](d)[], op)
    of tyObject, tyTuple:
      forAllSlotsAux(dest, mt.node, op)
    of tyArray, tyArrayConstr, tyOpenArray:
      for i in 0..(mt.size div mt.base.size)-1:
        forAllChildrenAux(cast[pointer](d +% i *% mt.base.size), mt.base, op)
    else: discard

proc forAllChildren(cell: PCell, op: WalkOp) =
  gcAssert(cell != nil, "forAllChildren: 1")
  gcAssert(cell.typ != nil, "forAllChildren: 2")
  gcAssert cell.typ.kind in {tyRef, tySequence, tyString}, "forAllChildren: 3"
  let marker = cell.typ.marker
  if marker != nil:
    marker(cellToUsr(cell), op.int)
  else:
    case cell.typ.kind
    of tyRef: # common case
      forAllChildrenAux(cellToUsr(cell), cell.typ.base, op)
    of tySequence:
      when not defined(nimSeqsV2):
        var d = cast[ByteAddress](cellToUsr(cell))
        var s = cast[PGenericSeq](d)
        if s != nil:
          for i in 0..s.len-1:
            forAllChildrenAux(cast[pointer](d +% align(GenericSeqSize, cell.typ.base.align) +% i *% cell.typ.base.size), cell.typ.base, op)
    else: discard

proc rawNewObj(typ: PNimType, size: int, gch: var GcHeap): pointer =
  # generates a new object and sets its reference counter to 0
  incTypeSize typ, size
  gcAssert(typ.kind in {tyRef, tyString, tySequence}, "newObj: 1")
  collectCT(gch, size + sizeof(Cell))
  var res = cast[PCell](rawAlloc(gch.region, size + sizeof(Cell)))
  gcAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "newObj: 2")
  # now it is buffered in the ZCT
  res.typ = typ
  when leakDetector and not hasThreadSupport:
    if framePtr != nil and framePtr.prev != nil:
      res.filename = framePtr.prev.filename
      res.line = framePtr.prev.line
  res.refcount = 0
  when withBitvectors: incl(gch.allocated, res)
  when useCellIds:
    inc gch.idGenerator
    res.id = gch.idGenerator
  result = cellToUsr(res)

when useCellIds:
  proc getCellId*[T](x: ref T): int =
    let p = usrToCell(cast[pointer](x))
    result = p.id

{.pop.}

proc newObj(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(typ, size, gch)
  zeroMem(result, size)
  when defined(memProfiler): nimProfile(size)

proc newObjNoInit(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(typ, size, gch)
  when defined(memProfiler): nimProfile(size)

proc newObjRC1(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(typ, size, gch)
  zeroMem(result, size)
  when defined(memProfiler): nimProfile(size)

when not defined(nimSeqsV2):
  {.push overflowChecks: on.}
  proc newSeq(typ: PNimType, len: int): pointer {.compilerRtl.} =
    # `newObj` already uses locks, so no need for them here.
    let size = align(GenericSeqSize, typ.base.align) + len * typ.base.size
    result = newObj(typ, size)
    cast[PGenericSeq](result).len = len
    cast[PGenericSeq](result).reserved = len
    when defined(memProfiler): nimProfile(size)

  proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =
    let size = align(GenericSeqSize, typ.base.align) + len * typ.base.size
    result = newObj(typ, size)
    cast[PGenericSeq](result).len = len
    cast[PGenericSeq](result).reserved = len
    when defined(memProfiler): nimProfile(size)
  {.pop.}

  proc growObj(old: pointer, newsize: int, gch: var GcHeap): pointer =
    collectCT(gch, newsize + sizeof(Cell))
    var ol = usrToCell(old)
    sysAssert(ol.typ != nil, "growObj: 1")
    gcAssert(ol.typ.kind in {tyString, tySequence}, "growObj: 2")

    var res = cast[PCell](rawAlloc(gch.region, newsize + sizeof(Cell)))
    var elemSize, elemAlign = 1
    if ol.typ.kind != tyString:
      elemSize = ol.typ.base.size
      elemAlign = ol.typ.base.align
    incTypeSize ol.typ, newsize

    var oldsize = align(GenericSeqSize, elemAlign) + cast[PGenericSeq](old).len*elemSize
    copyMem(res, ol, oldsize + sizeof(Cell))
    zeroMem(cast[pointer](cast[ByteAddress](res)+% oldsize +% sizeof(Cell)),
            newsize-oldsize)
    sysAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "growObj: 3")
    when withBitvectors: incl(gch.allocated, res)
    when useCellIds:
      inc gch.idGenerator
      res.id = gch.idGenerator
    result = cellToUsr(res)
    when defined(memProfiler): nimProfile(newsize-oldsize)

  proc growObj(old: pointer, newsize: int): pointer {.rtl.} =
    result = growObj(old, newsize, gch)

{.push profiler:off.}

# ----------------- collector -----------------------------------------------

proc mark(gch: var GcHeap, c: PCell) =
  when hasThreadSupport:
    for c in gch.toDispose:
      nimGCunref(c)
  when withBitvectors:
    incl(gch.marked, c)
    gcAssert gch.tempStack.len == 0, "stack not empty!"
    forAllChildren(c, waMarkPrecise)
    while gch.tempStack.len > 0:
      dec gch.tempStack.len
      var d = gch.tempStack.d[gch.tempStack.len]
      if not containsOrIncl(gch.marked, d):
        forAllChildren(d, waMarkPrecise)
  else:
    # XXX no 'if c.refCount != rcBlack' here?
    when defined(nimTracing):
      if gch.tracing:
        for i in 1..gch.indentation: c_fprintf(stdout, " ")
        c_fprintf(stdout, "start marking %p of type %s ((\n",
                  c, c.typ.name)
        inc gch.indentation, 2

    c.refcount = rcBlack
    gcAssert gch.tempStack.len == 0, "stack not empty!"
    forAllChildren(c, waMarkPrecise)
    while gch.tempStack.len > 0:
      dec gch.tempStack.len
      var d = gch.tempStack.d[gch.tempStack.len]
      if d.refcount == rcWhite:
        d.refcount = rcBlack
        forAllChildren(d, waMarkPrecise)

    when defined(nimTracing):
      if gch.tracing:
        dec gch.indentation, 2
        for i in 1..gch.indentation: c_fprintf(stdout, " ")
        c_fprintf(stdout, "finished marking %p of type %s))\n",
                  c, c.typ.name)

proc doOperation(p: pointer, op: WalkOp) =
  if p == nil: return
  var c: PCell = usrToCell(p)
  gcAssert(c != nil, "doOperation: 1")
  case op
  of waMarkGlobal: mark(gch, c)
  of waMarkPrecise:
    when defined(nimTracing):
      if c.refcount == rcWhite: mark(gch, c)
    else:
      add(gch.tempStack, c)

proc nimGCvisit(d: pointer, op: int) {.compilerRtl.} =
  doOperation(d, WalkOp(op))

proc freeCyclicCell(gch: var GcHeap, c: PCell) =
  inc gch.stat.freedObjects
  prepareDealloc(c)
  when reallyDealloc: rawDealloc(gch.region, c)
  else:
    gcAssert(c.typ != nil, "freeCyclicCell")
    zeroMem(c, sizeof(Cell))

proc sweep(gch: var GcHeap) =
  when withBitvectors:
    for c in gch.allocated.elementsExcept(gch.marked):
      gch.allocated.excl(c)
      freeCyclicCell(gch, c)
  else:
    for x in allObjects(gch.region):
      if isCell(x):
        # cast to PCell is correct here:
        var c = cast[PCell](x)
        if c.refcount == rcBlack: c.refcount = rcWhite
        else: freeCyclicCell(gch, c)

when false:
  # meant to be used with the now-deprected `.injectStmt`: {.injectStmt: newGcInvariant().}
  proc newGcInvariant*() =
    for x in allObjects(gch.region):
      if isCell(x):
        var c = cast[PCell](x)
        if c.typ == nil:
          writeStackTrace()
          quit 1

proc markGlobals(gch: var GcHeap) =
  if gch.gcThreadId == 0:
    when defined(nimTracing):
      if gch.tracing:
        c_fprintf(stdout, "------- globals marking phase:\n")
    for i in 0 .. globalMarkersLen-1: globalMarkers[i]()
  when defined(nimTracing):
    if gch.tracing:
      c_fprintf(stdout, "------- thread locals marking phase:\n")
  for i in 0 .. threadLocalMarkersLen-1: threadLocalMarkers[i]()
  when defined(nimTracing):
    if gch.tracing:
      c_fprintf(stdout, "------- additional roots marking phase:\n")
  let d = gch.additionalRoots.d
  for i in 0 .. gch.additionalRoots.len-1: mark(gch, d[i])

proc gcMark(gch: var GcHeap, p: pointer) {.inline.} =
  # the addresses are not as cells on the stack, so turn them to cells:
  var c = cast[ByteAddress](p)
  if c >% PageSize:
    # fast check: does it look like a cell?
    var objStart = cast[PCell](interiorAllocatedPtr(gch.region, p))
    if objStart != nil:
      mark(gch, objStart)

proc markStackAndRegisters(gch: var GcHeap) {.noinline, cdecl.} =
  forEachStackSlot(gch, gcMark)

proc collectCTBody(gch: var GcHeap) =
  when not nimCoroutines:
    gch.stat.maxStackSize = max(gch.stat.maxStackSize, stackSize())
  when defined(nimTracing):
    if gch.tracing:
      c_fprintf(stdout, "------- stack marking phase:\n")
  prepareForInteriorPointerChecking(gch.region)
  markStackAndRegisters(gch)
  markGlobals(gch)
  sweep(gch)

  inc(gch.stat.collections)
  when withBitvectors:
    deinit(gch.marked)
    init(gch.marked)
  gch.cycleThreshold = max(InitialThreshold, getOccupiedMem().mulThreshold)
  gch.stat.maxThreshold = max(gch.stat.maxThreshold, gch.cycleThreshold)
  sysAssert(allocInv(gch.region), "collectCT: end")

proc collectCT(gch: var GcHeap; size: int) =
  let fmem = getFreeMem(gch.region)
  if (getOccupiedMem(gch.region) >= gch.cycleThreshold or
      size > fmem and fmem > InitialThreshold) and gch.recGcLock == 0:
    collectCTBody(gch)

when not defined(useNimRtl):
  proc GC_disable() =
    inc(gch.recGcLock)
  proc GC_enable() =
    when defined(nimDoesntTrackDefects):
      if gch.recGcLock <= 0:
        raise newException(AssertionDefect,
            "API usage error: GC_enable called but GC is already enabled")
    dec(gch.recGcLock)

  proc GC_setStrategy(strategy: GC_Strategy) = discard

  proc GC_enableMarkAndSweep() =
    gch.cycleThreshold = InitialThreshold

  proc GC_disableMarkAndSweep() =
    gch.cycleThreshold = high(typeof(gch.cycleThreshold))-1
    # set to the max value to suppress the cycle detector

  when defined(nimTracing):
    proc GC_logTrace*() =
      gch.tracing = true

  proc GC_fullCollect() =
    let oldThreshold = gch.cycleThreshold
    gch.cycleThreshold = 0 # forces cycle collection
    collectCT(gch, 0)
    gch.cycleThreshold = oldThreshold

  proc GC_getStatistics(): string =
    result = "[GC] total memory: " & $getTotalMem() & "\n" &
             "[GC] occupied memory: " & $getOccupiedMem() & "\n" &
             "[GC] collections: " & $gch.stat.collections & "\n" &
             "[GC] max threshold: " & $gch.stat.maxThreshold & "\n" &
             "[GC] freed objects: " & $gch.stat.freedObjects & "\n"
    when nimCoroutines:
      result.add "[GC] number of stacks: " & $gch.stack.len & "\n"
      for stack in items(gch.stack):
        result.add "[GC]   stack " & stack.bottom.repr & "[GC]     max stack size " & $stack.maxStackSize & "\n"
    else:
      result.add "[GC] max stack size: " & $gch.stat.maxStackSize & "\n"

{.pop.}
