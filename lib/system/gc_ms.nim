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

when defined(nimCoroutines):
  import arch

{.push profiler:off.}

const
  InitialThreshold = 4*1024*1024 # X MB because marking&sweeping is slow
  withBitvectors = defined(gcUseBitvectors)
  # bitvectors are significantly faster for GC-bench, but slower for
  # bootstrapping and use more memory
  rcWhite = 0
  rcGrey = 1   # unused
  rcBlack = 2

template mulThreshold(x): expr {.immediate.} = x * 2

when defined(memProfiler):
  proc nimProfile(requestedSize: int)

type
  WalkOp = enum
    waMarkGlobal,  # we need to mark conservatively for global marker procs
                   # as these may refer to a global var and not to a thread
                   # local
    waMarkPrecise  # fast precise marking

  Finalizer {.compilerproc.} = proc (self: pointer) {.nimcall, benign.}
    # A ref type can have a finalizer that is called before the object's
    # storage is freed.

  GlobalMarkerProc = proc () {.nimcall, benign.}

  GcStat = object
    collections: int         # number of performed full collections
    maxThreshold: int        # max threshold that has been set
    maxStackSize: int        # max stack size
    freedObjects: int        # max entries in cycle table

  GcStack {.final.} = object
    prev: ptr GcStack
    next: ptr GcStack
    starts: pointer
    pos: pointer
    maxStackSize: int

  GcHeap = object            # this contains the zero count and
                             # non-zero count table
    stack: ptr GcStack
    stackBottom: pointer
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
    additionalRoots: CellSeq # dummy roots for GC_ref/unref
{.deprecated: [TWalkOp: WalkOp, TFinalizer: Finalizer, TGcStat: GcStat,
              TGlobalMarkerProc: GlobalMarkerProc, TGcHeap: GcHeap].}
var
  gch {.rtlThreadVar.}: GcHeap

when not defined(useNimRtl):
  instantiateForRegion(gch.region)

template acquire(gch: GcHeap) =
  when hasThreadSupport and hasSharedHeap:
    acquireSys(HeapLock)

template release(gch: GcHeap) =
  when hasThreadSupport and hasSharedHeap:
    releaseSys(HeapLock)

template gcAssert(cond: bool, msg: string) =
  when defined(useGcAssert):
    if not cond:
      echo "[GCASSERT] ", msg
      quit 1

proc cellToUsr(cell: PCell): pointer {.inline.} =
  # convert object (=pointer to refcount) to pointer to userdata
  result = cast[pointer](cast[ByteAddress](cell)+%ByteAddress(sizeof(Cell)))

proc usrToCell(usr: pointer): PCell {.inline.} =
  # convert pointer to userdata to object (=pointer to refcount)
  result = cast[PCell](cast[ByteAddress](usr)-%ByteAddress(sizeof(Cell)))

proc canbeCycleRoot(c: PCell): bool {.inline.} =
  result = ntfAcyclic notin c.typ.flags

proc extGetCellType(c: pointer): PNimType {.compilerproc.} =
  # used for code generation concerning debugging
  result = usrToCell(c).typ

proc unsureAsgnRef(dest: PPointer, src: pointer) {.inline.} =
  dest[] = src

proc internRefcount(p: pointer): int {.exportc: "getRefcount".} =
  result = 0

var
  globalMarkersLen: int
  globalMarkers: array[0.. 7_000, GlobalMarkerProc]

proc nimRegisterGlobalMarker(markerProc: GlobalMarkerProc) {.compilerProc.} =
  if globalMarkersLen <= high(globalMarkers):
    globalMarkers[globalMarkersLen] = markerProc
    inc globalMarkersLen
  else:
    echo "[GC] cannot register global variable; too many global variables"
    quit 1

# this that has to equals zero, otherwise we have to round up UnitsPerPage:
when BitsPerPage mod (sizeof(int)*8) != 0:
  {.error: "(BitsPerPage mod BitsPerUnit) should be zero!".}

# forward declarations:
proc collectCT(gch: var GcHeap) {.benign.}
proc forAllChildren(cell: PCell, op: WalkOp) {.benign.}
proc doOperation(p: pointer, op: WalkOp) {.benign.}
proc forAllChildrenAux(dest: pointer, mt: PNimType, op: WalkOp) {.benign.}
# we need the prototype here for debugging purposes

proc prepareDealloc(cell: PCell) =
  if cell.typ.finalizer != nil:
    # the finalizer could invoke something that
    # allocates memory; this could trigger a garbage
    # collection. Since we are already collecting we
    # prevend recursive entering here by a lock.
    # XXX: we should set the cell's children to nil!
    inc(gch.recGcLock)
    (cast[Finalizer](cell.typ.finalizer))(cellToUsr(cell))
    dec(gch.recGcLock)

proc nimGCref(p: pointer) {.compilerProc.} =
  # we keep it from being collected by pretending it's not even allocated:
  when false:
    when withBitvectors: excl(gch.allocated, usrToCell(p))
    else: usrToCell(p).refcount = rcBlack
  add(gch.additionalRoots, usrToCell(p))

proc nimGCunref(p: pointer) {.compilerProc.} =
  let cell = usrToCell(p)
  var L = gch.additionalRoots.len-1
  var i = L
  let d = gch.additionalRoots.d
  while i >= 0:
    if d[i] == cell:
      d[i] = d[L]
      dec gch.additionalRoots.len
      break
    dec(i)
  when false:
    when withBitvectors: incl(gch.allocated, usrToCell(p))
    else: usrToCell(p).refcount = rcWhite

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
      gch.toDispose = initSharedList[pointer]()

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
      var d = cast[ByteAddress](cellToUsr(cell))
      var s = cast[PGenericSeq](d)
      if s != nil:
        for i in 0..s.len-1:
          forAllChildrenAux(cast[pointer](d +% i *% cell.typ.base.size +%
            GenericSeqSize), cell.typ.base, op)
    else: discard

proc rawNewObj(typ: PNimType, size: int, gch: var GcHeap): pointer =
  # generates a new object and sets its reference counter to 0
  acquire(gch)
  gcAssert(typ.kind in {tyRef, tyString, tySequence}, "newObj: 1")
  collectCT(gch)
  var res = cast[PCell](rawAlloc(gch.region, size + sizeof(Cell)))
  gcAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "newObj: 2")
  # now it is buffered in the ZCT
  res.typ = typ
  when leakDetector and not hasThreadSupport:
    if framePtr != nil and framePtr.prev != nil:
      res.filename = framePtr.prev.filename
      res.line = framePtr.prev.line
  res.refcount = 0
  release(gch)
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

proc newSeq(typ: PNimType, len: int): pointer {.compilerRtl.} =
  # `newObj` already uses locks, so no need for them here.
  let size = addInt(mulInt(len, typ.base.size), GenericSeqSize)
  result = newObj(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len
  when defined(memProfiler): nimProfile(size)

proc newObjRC1(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(typ, size, gch)
  zeroMem(result, size)
  when defined(memProfiler): nimProfile(size)

proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =
  let size = addInt(mulInt(len, typ.base.size), GenericSeqSize)
  result = newObj(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len
  when defined(memProfiler): nimProfile(size)

proc growObj(old: pointer, newsize: int, gch: var GcHeap): pointer =
  acquire(gch)
  collectCT(gch)
  var ol = usrToCell(old)
  sysAssert(ol.typ != nil, "growObj: 1")
  gcAssert(ol.typ.kind in {tyString, tySequence}, "growObj: 2")

  var res = cast[PCell](rawAlloc(gch.region, newsize + sizeof(Cell)))
  var elemSize = 1
  if ol.typ.kind != tyString: elemSize = ol.typ.base.size

  var oldsize = cast[PGenericSeq](old).len*elemSize + GenericSeqSize
  copyMem(res, ol, oldsize + sizeof(Cell))
  zeroMem(cast[pointer](cast[ByteAddress](res)+% oldsize +% sizeof(Cell)),
          newsize-oldsize)
  sysAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "growObj: 3")
  when false:
    # this is wrong since seqs can be shared via 'shallow':
    when withBitvectors: excl(gch.allocated, ol)
    when reallyDealloc: rawDealloc(gch.region, ol)
    else:
      zeroMem(ol, sizeof(Cell))
  when withBitvectors: incl(gch.allocated, res)
  when useCellIds:
    inc gch.idGenerator
    res.id = gch.idGenerator
  release(gch)
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
    c.refCount = rcBlack
    gcAssert gch.tempStack.len == 0, "stack not empty!"
    forAllChildren(c, waMarkPrecise)
    while gch.tempStack.len > 0:
      dec gch.tempStack.len
      var d = gch.tempStack.d[gch.tempStack.len]
      if d.refcount == rcWhite:
        d.refCount = rcBlack
        forAllChildren(d, waMarkPrecise)

proc doOperation(p: pointer, op: WalkOp) =
  if p == nil: return
  var c: PCell = usrToCell(p)
  gcAssert(c != nil, "doOperation: 1")
  case op
  of waMarkGlobal:
    when hasThreadSupport:
      # could point to a cell which we don't own and don't want to touch/trace
      if isAllocatedPtr(gch.region, c):
        mark(gch, c)
    else:
      mark(gch, c)
  of waMarkPrecise: add(gch.tempStack, c)

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
  proc newGcInvariant*() =
    for x in allObjects(gch.region):
      if isCell(x):
        var c = cast[PCell](x)
        if c.typ == nil:
          writeStackTrace()
          quit 1

proc markGlobals(gch: var GcHeap) =
  for i in 0 .. < globalMarkersLen: globalMarkers[i]()
  let d = gch.additionalRoots.d
  for i in 0 .. < gch.additionalRoots.len: mark(gch, d[i])

proc gcMark(gch: var GcHeap, p: pointer) {.inline.} =
  # the addresses are not as cells on the stack, so turn them to cells:
  var cell = usrToCell(p)
  var c = cast[ByteAddress](cell)
  if c >% PageSize:
    # fast check: does it look like a cell?
    var objStart = cast[PCell](interiorAllocatedPtr(gch.region, cell))
    if objStart != nil:
      mark(gch, objStart)

include gc_common

proc markStackAndRegisters(gch: var GcHeap) {.noinline, cdecl.} =
  forEachStackSlot(gch, gcMark)

proc collectCTBody(gch: var GcHeap) =
  when not defined(nimCoroutines):
    gch.stat.maxStackSize = max(gch.stat.maxStackSize, stackSize())
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

proc collectCT(gch: var GcHeap) =
  if getOccupiedMem(gch.region) >= gch.cycleThreshold and gch.recGcLock == 0:
    collectCTBody(gch)

when not defined(useNimRtl):
  proc GC_disable() =
    when hasThreadSupport and hasSharedHeap:
      atomicInc(gch.recGcLock, 1)
    else:
      inc(gch.recGcLock)
  proc GC_enable() =
    if gch.recGcLock > 0:
      when hasThreadSupport and hasSharedHeap:
        atomicDec(gch.recGcLock, 1)
      else:
        dec(gch.recGcLock)

  proc GC_setStrategy(strategy: GC_Strategy) = discard

  proc GC_enableMarkAndSweep() =
    gch.cycleThreshold = InitialThreshold

  proc GC_disableMarkAndSweep() =
    gch.cycleThreshold = high(gch.cycleThreshold)-1
    # set to the max value to suppress the cycle detector

  proc GC_fullCollect() =
    acquire(gch)
    var oldThreshold = gch.cycleThreshold
    gch.cycleThreshold = 0 # forces cycle collection
    collectCT(gch)
    gch.cycleThreshold = oldThreshold
    release(gch)

  proc GC_getStatistics(): string =
    GC_disable()
    result = "[GC] total memory: " & $getTotalMem() & "\n" &
             "[GC] occupied memory: " & $getOccupiedMem() & "\n" &
             "[GC] collections: " & $gch.stat.collections & "\n" &
             "[GC] max threshold: " & $gch.stat.maxThreshold & "\n" &
             "[GC] freed objects: " & $gch.stat.freedObjects & "\n"
    when defined(nimCoroutines):
      result = result & "[GC] number of stacks: " & $gch.stack.len & "\n"
      for stack in items(gch.stack):
        result = result & "[GC]   stack " & stack.starts.repr & "[GC]     max stack size " & $stack.maxStackSize & "\n"
    else:
      result = result & "[GC] max stack size: " & $gch.stat.maxStackSize & "\n"
    GC_enable()

{.pop.}
