#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# xxx deadcode, consider removing unless something could be reused.


#            Garbage Collector
#
# The basic algorithm is an incremental mark
# and sweep GC to free cycles. It is hard realtime in that if you play
# according to its rules, no deadline will ever be missed.
# Since this kind of collector is very bad at recycling dead objects
# early, Nim's codegen emits ``nimEscape`` calls at strategic
# places. For this to work even 'unsureAsgnRef' needs to mark things
# so that only return values need to be considered in ``nimEscape``.

{.push profiler:off.}

const
  CycleIncrease = 2 # is a multiplicative increase
  InitialCycleThreshold = 512*1024 # start collecting after 500KB
  ZctThreshold = 500  # we collect garbage if the ZCT's size
                      # reaches this threshold
                      # this seems to be a good value
  withRealTime = defined(useRealtimeGC)

when withRealTime and not declared(getTicks):
  include "system/timers"
when defined(memProfiler):
  proc nimProfile(requestedSize: int) {.benign.}

when hasThreadSupport:
  include sharedlist

type
  ObjectSpaceIter = object
    state: range[-1..0]

iterToProc(allObjects, ptr ObjectSpaceIter, allObjectsAsProc)

const
  escapedBit = 0b1000 # so that lowest 3 bits are not touched
  rcBlackOrig = 0b000
  rcWhiteOrig = 0b001
  rcGrey = 0b010   # traditional color for incremental mark&sweep
  rcUnused = 0b011
  colorMask = 0b011
type
  WalkOp = enum
    waMarkGlobal,    # part of the backup mark&sweep
    waMarkGrey,
    waZctDecRef,
    waDebug

  Phase {.pure.} = enum
    None, Marking, Sweeping
  Finalizer {.compilerproc.} = proc (self: pointer) {.nimcall, benign.}
    # A ref type can have a finalizer that is called before the object's
    # storage is freed.

  GcStat = object
    stackScans: int          # number of performed stack scans (for statistics)
    completedCollections: int    # number of performed full collections
    maxThreshold: int        # max threshold that has been set
    maxStackSize: int        # max stack size
    maxStackCells: int       # max stack cells in ``decStack``
    cycleTableSize: int      # max entries in cycle table
    maxPause: int64          # max measured GC pause in nanoseconds

  GcStack {.final, pure.} = object
    when nimCoroutines:
      prev: ptr GcStack
      next: ptr GcStack
      maxStackSize: int      # Used to track statistics because we can not use
                             # GcStat.maxStackSize when multiple stacks exist.
    bottom: pointer

    when withRealTime or nimCoroutines:
      pos: pointer           # Used with `withRealTime` only for code clarity, see GC_Step().
    when withRealTime:
      bottomSaved: pointer

  GcHeap = object # this contains the zero count and
                  # non-zero count table
    black, red: int # either 0 or 1.
    stack: GcStack
    when nimCoroutines:
      activeStack: ptr GcStack    # current executing coroutine stack.
    phase: Phase
    cycleThreshold: int
    when useCellIds:
      idGenerator: int
    greyStack: CellSeq
    recGcLock: int           # prevent recursion via finalizers; no thread lock
    when withRealTime:
      maxPause: Nanos        # max allowed pause in nanoseconds; active if > 0
    region: MemRegion        # garbage collected region
    stat: GcStat
    additionalRoots: CellSeq # explicit roots for GC_ref/unref
    spaceIter: ObjectSpaceIter
    pDumpHeapFile: pointer # File that is used for GC_dumpHeap
    when hasThreadSupport:
      toDispose: SharedList[pointer]
    gcThreadId: int

var
  gch {.rtlThreadVar.}: GcHeap

when not defined(useNimRtl):
  instantiateForRegion(gch.region)

# Which color to use for new objects is tricky: When we're marking,
# they have to be *white* so that everything is marked that is only
# reachable from them. However, when we are sweeping, they have to
# be black, so that we don't free them prematuredly. In order to save
# a comparison gch.phase == Phase.Marking, we use the pseudo-color
# 'red' for new objects.
template allocColor(): untyped = gch.red

template gcAssert(cond: bool, msg: string) =
  when defined(useGcAssert):
    if not cond:
      echo "[GCASSERT] ", msg
      GC_disable()
      writeStackTrace()
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

proc internRefcount(p: pointer): int {.exportc: "getRefcount".} =
  result = 0

# this that has to equals zero, otherwise we have to round up UnitsPerPage:
when BitsPerPage mod (sizeof(int)*8) != 0:
  {.error: "(BitsPerPage mod BitsPerUnit) should be zero!".}

template color(c): untyped = c.refCount and colorMask
template setColor(c, col) =
  c.refcount = c.refcount and not colorMask or col

template markAsEscaped(c: PCell) =
  c.refcount = c.refcount or escapedBit

template didEscape(c: PCell): bool =
  (c.refCount and escapedBit) != 0

proc writeCell(file: File; msg: cstring, c: PCell) =
  var kind = -1
  if c.typ != nil: kind = ord(c.typ.kind)
  let col = if c.color == rcGrey: 'g'
            elif c.color == gch.black: 'b'
            else: 'w'
  when useCellIds:
    let id = c.id
  else:
    let id = c
  when defined(nimTypeNames):
    c_fprintf(file, "%s %p %d escaped=%ld color=%c of type %s\n",
              msg, id, kind, didEscape(c), col, c.typ.name)
  elif leakDetector:
    c_fprintf(file, "%s %p %d escaped=%ld color=%c from %s(%ld)\n",
              msg, id, kind, didEscape(c), col, c.filename, c.line)
  else:
    c_fprintf(file, "%s %p %d escaped=%ld color=%c\n",
              msg, id, kind, didEscape(c), col)

proc writeCell(msg: cstring, c: PCell) =
  stdout.writeCell(msg, c)

proc myastToStr[T](x: T): string {.magic: "AstToStr", noSideEffect.}

template gcTrace(cell, state: untyped) =
  when traceGC: writeCell(myastToStr(state), cell)

# forward declarations:
proc collectCT(gch: var GcHeap) {.benign.}
proc isOnStack(p: pointer): bool {.noinline, benign.}
proc forAllChildren(cell: PCell, op: WalkOp) {.benign.}
proc doOperation(p: pointer, op: WalkOp) {.benign.}
proc forAllChildrenAux(dest: pointer, mt: PNimType, op: WalkOp) {.benign.}
# we need the prototype here for debugging purposes

proc nimGCref(p: pointer) {.compilerproc.} =
  let cell = usrToCell(p)
  markAsEscaped(cell)
  add(gch.additionalRoots, cell)

proc nimGCunref(p: pointer) {.compilerproc.} =
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

proc nimGCunrefNoCycle(p: pointer) {.compilerproc, inline.} =
  discard "can we do some freeing here?"

proc nimGCunrefRC1(p: pointer) {.compilerproc, inline.} =
  discard "can we do some freeing here?"

template markGrey(x: PCell) =
  if x.color != 1-gch.black and gch.phase == Phase.Marking:
    if not isAllocatedPtr(gch.region, x):
      c_fprintf(stdout, "[GC] markGrey proc: %p\n", x)
      #GC_dumpHeap()
      sysAssert(false, "wtf")
    x.setColor(rcGrey)
    add(gch.greyStack, x)

proc asgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
  # the code generator calls this proc!
  gcAssert(not isOnStack(dest), "asgnRef")
  # BUGFIX: first incRef then decRef!
  if src != nil:
    let s = usrToCell(src)
    markAsEscaped(s)
    markGrey(s)
  dest[] = src

proc asgnRefNoCycle(dest: PPointer, src: pointer) {.compilerproc, inline,
  deprecated: "old compiler compat".} = asgnRef(dest, src)

proc unsureAsgnRef(dest: PPointer, src: pointer) {.compilerproc.} =
  # unsureAsgnRef marks 'src' as grey only if dest is not on the
  # stack. It is used by the code generator if it cannot decide whether a
  # reference is in the stack or not (this can happen for var parameters).
  if src != nil:
    let s = usrToCell(src)
    markAsEscaped(s)
    if not isOnStack(dest): markGrey(s)
  dest[] = src

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
  gcAssert(isAllocatedPtr(gch.region, cell), "forAllChildren: 2")
  gcAssert(cell.typ != nil, "forAllChildren: 3")
  gcAssert cell.typ.kind in {tyRef, tySequence, tyString}, "forAllChildren: 4"
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
          forAllChildrenAux(cast[pointer](d +% align(GenericSeqSize, cell.typ.base.align) +% i *% cell.typ.base.size), cell.typ.base, op)
    else: discard

{.push stackTrace: off, profiler:off.}
proc gcInvariant*() =
  sysAssert(allocInv(gch.region), "injected")
  when declared(markForDebug):
    markForDebug(gch)
{.pop.}

include gc_common

proc initGC() =
  when not defined(useNimRtl):
    gch.red = (1-gch.black)
    gch.cycleThreshold = InitialCycleThreshold
    gch.stat.stackScans = 0
    gch.stat.completedCollections = 0
    gch.stat.maxThreshold = 0
    gch.stat.maxStackSize = 0
    gch.stat.maxStackCells = 0
    gch.stat.cycleTableSize = 0
    # init the rt
    init(gch.additionalRoots)
    init(gch.greyStack)
    when hasThreadSupport:
      init(gch.toDispose)
    gch.gcThreadId = atomicInc(gHeapidGenerator) - 1
    gcAssert(gch.gcThreadId >= 0, "invalid computed thread ID")

proc rawNewObj(typ: PNimType, size: int, gch: var GcHeap): pointer =
  # generates a new object and sets its reference counter to 0
  sysAssert(allocInv(gch.region), "rawNewObj begin")
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
  # refcount is zero, color is black, but mark it to be in the ZCT
  res.refcount = allocColor()
  sysAssert(isAllocatedPtr(gch.region, res), "newObj: 3")
  when logGC: writeCell("new cell", res)
  gcTrace(res, csAllocated)
  when useCellIds:
    inc gch.idGenerator
    res.id = gch.idGenerator
  result = cellToUsr(res)
  sysAssert(allocInv(gch.region), "rawNewObj end")

{.pop.}

proc newObjNoInit(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(typ, size, gch)
  when defined(memProfiler): nimProfile(size)

proc newObj(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(typ, size, gch)
  zeroMem(result, size)
  when defined(memProfiler): nimProfile(size)

proc newSeq(typ: PNimType, len: int): pointer {.compilerRtl.} =
  # `newObj` already uses locks, so no need for them here.
  let size = addInt(align(GenericSeqSize, typ.base.align), mulInt(len, typ.base.size))
  result = newObj(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len
  when defined(memProfiler): nimProfile(size)

proc newObjRC1(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = newObj(typ, size)

proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =
  result = newSeq(typ, len)

proc growObj(old: pointer, newsize: int, gch: var GcHeap): pointer =
  collectCT(gch)
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
  when false:
    # this is wrong since seqs can be shared via 'shallow':
    when reallyDealloc: rawDealloc(gch.region, ol)
    else:
      zeroMem(ol, sizeof(Cell))
  when useCellIds:
    inc gch.idGenerator
    res.id = gch.idGenerator
  result = cellToUsr(res)
  when defined(memProfiler): nimProfile(newsize-oldsize)

proc growObj(old: pointer, newsize: int): pointer {.rtl.} =
  result = growObj(old, newsize, gch)

{.push profiler:off.}


template takeStartTime(workPackageSize) {.dirty.} =
  const workPackage = workPackageSize
  var debugticker = 1000
  when withRealTime:
    var steps = workPackage
    var t0: Ticks
    if gch.maxPause > 0: t0 = getticks()

template takeTime {.dirty.} =
  when withRealTime: dec steps
  dec debugticker

template checkTime {.dirty.} =
  if debugticker <= 0:
    #echo "in loop"
    debugticker = 1000
  when withRealTime:
    if steps == 0:
      steps = workPackage
      if gch.maxPause > 0:
        let duration = getticks() - t0
        # the GC's measuring is not accurate and needs some cleanup actions
        # (stack unmarking), so subtract some short amount of time in
        # order to miss deadlines less often:
        if duration >= gch.maxPause - 50_000:
          return false

# ---------------- dump heap ----------------

template dumpHeapFile(gch: var GcHeap): File =
  cast[File](gch.pDumpHeapFile)

proc debugGraph(s: PCell) =
  c_fprintf(gch.dumpHeapFile, "child %p\n", s)

proc dumpRoot(gch: var GcHeap; s: PCell) =
  if isAllocatedPtr(gch.region, s):
    c_fprintf(gch.dumpHeapFile, "global_root %p\n", s)
  else:
    c_fprintf(gch.dumpHeapFile, "global_root_invalid %p\n", s)

proc GC_dumpHeap*(file: File) =
  ## Dumps the GCed heap's content to a file. Can be useful for
  ## debugging. Produces an undocumented text file format that
  ## can be translated into "dot" syntax via the "heapdump2dot" tool.
  gch.pDumpHeapFile = file
  var spaceIter: ObjectSpaceIter
  when false:
    var d = gch.decStack.d
    for i in 0 .. gch.decStack.len-1:
      if isAllocatedPtr(gch.region, d[i]):
        c_fprintf(file, "onstack %p\n", d[i])
      else:
        c_fprintf(file, "onstack_invalid %p\n", d[i])
  if gch.gcThreadId == 0:
    for i in 0 .. globalMarkersLen-1: globalMarkers[i]()
  for i in 0 .. threadLocalMarkersLen-1: threadLocalMarkers[i]()
  while true:
    let x = allObjectsAsProc(gch.region, addr spaceIter)
    if spaceIter.state < 0: break
    if isCell(x):
      # cast to PCell is correct here:
      var c = cast[PCell](x)
      writeCell(file, "cell ", c)
      forAllChildren(c, waDebug)
      c_fprintf(file, "end\n")
  gch.pDumpHeapFile = nil

proc GC_dumpHeap() =
  var f: File
  if open(f, "heap.txt", fmWrite):
    GC_dumpHeap(f)
    f.close()
  else:
    c_fprintf(stdout, "cannot write heap.txt")

# ---------------- cycle collector -------------------------------------------

proc freeCyclicCell(gch: var GcHeap, c: PCell) =
  gcAssert(isAllocatedPtr(gch.region, c), "freeCyclicCell: freed pointer?")
  prepareDealloc(c)
  gcTrace(c, csCycFreed)
  when logGC: writeCell("cycle collector dealloc cell", c)
  when reallyDealloc:
    sysAssert(allocInv(gch.region), "free cyclic cell")
    rawDealloc(gch.region, c)
  else:
    gcAssert(c.typ != nil, "freeCyclicCell")
    zeroMem(c, sizeof(Cell))

proc sweep(gch: var GcHeap): bool =
  takeStartTime(100)
  #echo "loop start"
  let white = 1-gch.black
  #c_fprintf(stdout, "black is %d\n", black)
  while true:
    let x = allObjectsAsProc(gch.region, addr gch.spaceIter)
    if gch.spaceIter.state < 0: break
    takeTime()
    if isCell(x):
      # cast to PCell is correct here:
      var c = cast[PCell](x)
      gcAssert c.color != rcGrey, "cell is still grey?"
      if c.color == white: freeCyclicCell(gch, c)
      # Since this is incremental, we MUST not set the object to 'white' here.
      # We could set all the remaining objects to white after the 'sweep'
      # completed but instead we flip the meaning of black/white to save one
      # traversal over the heap!
    checkTime()
  # prepare for next iteration:
  #echo "loop end"
  gch.spaceIter = ObjectSpaceIter()
  result = true

proc markRoot(gch: var GcHeap, c: PCell) {.inline.} =
  if c.color == 1-gch.black:
    c.setColor(rcGrey)
    add(gch.greyStack, c)

proc markIncremental(gch: var GcHeap): bool =
  var L = addr(gch.greyStack.len)
  takeStartTime(100)
  while L[] > 0:
    var c = gch.greyStack.d[0]
    if not isAllocatedPtr(gch.region, c):
      c_fprintf(stdout, "[GC] not allocated anymore: %p\n", c)
      #GC_dumpHeap()
      sysAssert(false, "wtf")

    #sysAssert(isAllocatedPtr(gch.region, c), "markIncremental: isAllocatedPtr")
    gch.greyStack.d[0] = gch.greyStack.d[L[] - 1]
    dec(L[])
    takeTime()
    if c.color == rcGrey:
      c.setColor(gch.black)
      forAllChildren(c, waMarkGrey)
    elif c.color == (1-gch.black):
      gcAssert false, "wtf why are there white objects in the greystack?"
    checkTime()
  gcAssert gch.greyStack.len == 0, "markIncremental: greystack not empty "
  result = true

proc markGlobals(gch: var GcHeap) =
  if gch.gcThreadId == 0:
    for i in 0 .. globalMarkersLen-1: globalMarkers[i]()
  for i in 0 .. threadLocalMarkersLen-1: threadLocalMarkers[i]()

proc doOperation(p: pointer, op: WalkOp) =
  if p == nil: return
  var c: PCell = usrToCell(p)
  gcAssert(c != nil, "doOperation: 1")
  # the 'case' should be faster than function pointers because of easy
  # prediction:
  case op
  of waZctDecRef:
    #if not isAllocatedPtr(gch.region, c):
    #  c_fprintf(stdout, "[GC] decref bug: %p", c)
    gcAssert(isAllocatedPtr(gch.region, c), "decRef: waZctDecRef")
    discard "use me for nimEscape?"
  of waMarkGlobal:
    template handleRoot =
      if gch.dumpHeapFile.isNil:
        markRoot(gch, c)
      else:
        dumpRoot(gch, c)
    handleRoot()
    discard allocInv(gch.region)
  of waMarkGrey:
    when false:
      if not isAllocatedPtr(gch.region, c):
        c_fprintf(stdout, "[GC] not allocated anymore: MarkGrey %p\n", c)
        #GC_dumpHeap()
        sysAssert(false, "wtf")
    if c.color == 1-gch.black:
      c.setColor(rcGrey)
      add(gch.greyStack, c)
  of waDebug: debugGraph(c)

proc nimGCvisit(d: pointer, op: int) {.compilerRtl.} =
  doOperation(d, WalkOp(op))

proc gcMark(gch: var GcHeap, p: pointer) {.inline.} =
  # the addresses are not as cells on the stack, so turn them to cells:
  sysAssert(allocInv(gch.region), "gcMark begin")
  var cell = usrToCell(p)
  var c = cast[ByteAddress](cell)
  if c >% PageSize:
    # fast check: does it look like a cell?
    var objStart = cast[PCell](interiorAllocatedPtr(gch.region, cell))
    if objStart != nil:
      # mark the cell:
      markRoot(gch, objStart)
  sysAssert(allocInv(gch.region), "gcMark end")

proc markStackAndRegisters(gch: var GcHeap) {.noinline, cdecl.} =
  forEachStackSlot(gch, gcMark)

proc collectALittle(gch: var GcHeap): bool =
  case gch.phase
  of Phase.None:
    if getOccupiedMem(gch.region) >= gch.cycleThreshold:
      gch.phase = Phase.Marking
      markGlobals(gch)
      result = collectALittle(gch)
      #when false: c_fprintf(stdout, "collectALittle: introduced bug E %ld\n", gch.phase)
      #discard allocInv(gch.region)
  of Phase.Marking:
    when hasThreadSupport:
      for c in gch.toDispose:
        nimGCunref(c)
    prepareForInteriorPointerChecking(gch.region)
    markStackAndRegisters(gch)
    inc(gch.stat.stackScans)
    if markIncremental(gch):
      gch.phase = Phase.Sweeping
      gch.red = 1 - gch.red
  of Phase.Sweeping:
    gcAssert gch.greyStack.len == 0, "greystack not empty"
    when hasThreadSupport:
      for c in gch.toDispose:
        nimGCunref(c)
    if sweep(gch):
      gch.phase = Phase.None
      # flip black/white meanings:
      gch.black = 1 - gch.black
      gcAssert gch.red == 1 - gch.black, "red color is wrong"
      inc(gch.stat.completedCollections)
      result = true

proc collectCTBody(gch: var GcHeap) =
  when withRealTime:
    let t0 = getticks()
  sysAssert(allocInv(gch.region), "collectCT: begin")

  when not nimCoroutines:
    gch.stat.maxStackSize = max(gch.stat.maxStackSize, stackSize())
  #gch.stat.maxStackCells = max(gch.stat.maxStackCells, gch.decStack.len)
  if collectALittle(gch):
    gch.cycleThreshold = max(InitialCycleThreshold, getOccupiedMem() *
                              CycleIncrease)
    gch.stat.maxThreshold = max(gch.stat.maxThreshold, gch.cycleThreshold)
  sysAssert(allocInv(gch.region), "collectCT: end")
  when withRealTime:
    let duration = getticks() - t0
    gch.stat.maxPause = max(gch.stat.maxPause, duration)
    when defined(reportMissedDeadlines):
      if gch.maxPause > 0 and duration > gch.maxPause:
        c_fprintf(stdout, "[GC] missed deadline: %ld\n", duration)

when nimCoroutines:
  proc currentStackSizes(): int =
    for stack in items(gch.stack):
      result = result + stack.stackSize()

proc collectCT(gch: var GcHeap) =
  # stackMarkCosts prevents some pathological behaviour: Stack marking
  # becomes more expensive with large stacks and large stacks mean that
  # cells with RC=0 are more likely to be kept alive by the stack.
  when nimCoroutines:
    let stackMarkCosts = max(currentStackSizes() div (16*sizeof(int)), ZctThreshold)
  else:
    let stackMarkCosts = max(stackSize() div (16*sizeof(int)), ZctThreshold)
  if (gch.greyStack.len >= stackMarkCosts or (cycleGC and
      getOccupiedMem(gch.region)>=gch.cycleThreshold) or alwaysGC) and
      gch.recGcLock == 0:
    collectCTBody(gch)

when withRealTime:
  proc toNano(x: int): Nanos {.inline.} =
    result = x * 1000

  proc GC_setMaxPause*(MaxPauseInUs: int) =
    gch.maxPause = MaxPauseInUs.toNano

  proc GC_step(gch: var GcHeap, us: int, strongAdvice: bool) =
    gch.maxPause = us.toNano
    #if (getOccupiedMem(gch.region)>=gch.cycleThreshold) or
    #    alwaysGC or strongAdvice:
    collectCTBody(gch)

  proc GC_step*(us: int, strongAdvice = false, stackSize = -1) {.noinline.} =
    if stackSize >= 0:
      var stackTop {.volatile.}: pointer
      gch.getActiveStack().pos = addr(stackTop)

      for stack in gch.stack.items():
        stack.bottomSaved = stack.bottom
        when stackIncreases:
          stack.bottom = cast[pointer](
            cast[ByteAddress](stack.pos) - sizeof(pointer) * 6 - stackSize)
        else:
          stack.bottom = cast[pointer](
            cast[ByteAddress](stack.pos) + sizeof(pointer) * 6 + stackSize)

    GC_step(gch, us, strongAdvice)

    if stackSize >= 0:
      for stack in gch.stack.items():
        stack.bottom = stack.bottomSaved

when not defined(useNimRtl):
  proc GC_disable() =
    inc(gch.recGcLock)
  proc GC_enable() =
    if gch.recGcLock > 0:
      dec(gch.recGcLock)

  proc GC_setStrategy(strategy: GC_Strategy) =
    discard

  proc GC_enableMarkAndSweep() = discard
  proc GC_disableMarkAndSweep() = discard

  proc GC_fullCollect() =
    var oldThreshold = gch.cycleThreshold
    gch.cycleThreshold = 0 # forces cycle collection
    collectCT(gch)
    gch.cycleThreshold = oldThreshold

  proc GC_getStatistics(): string =
    GC_disable()
    result = "[GC] total memory: " & $(getTotalMem()) & "\n" &
             "[GC] occupied memory: " & $(getOccupiedMem()) & "\n" &
             "[GC] stack scans: " & $gch.stat.stackScans & "\n" &
             "[GC] stack cells: " & $gch.stat.maxStackCells & "\n" &
             "[GC] completed collections: " & $gch.stat.completedCollections & "\n" &
             "[GC] max threshold: " & $gch.stat.maxThreshold & "\n" &
             "[GC] grey stack capacity: " & $gch.greyStack.cap & "\n" &
             "[GC] max cycle table size: " & $gch.stat.cycleTableSize & "\n" &
             "[GC] max pause time [ms]: " & $(gch.stat.maxPause div 1000_000) & "\n"
    when nimCoroutines:
      result.add "[GC] number of stacks: " & $gch.stack.len & "\n"
      for stack in items(gch.stack):
        result.add "[GC]   stack " & stack.bottom.repr & "[GC]     max stack size " & $stack.maxStackSize & "\n"
    else:
      result.add "[GC] max stack size: " & $gch.stat.maxStackSize & "\n"
    GC_enable()

{.pop.}
