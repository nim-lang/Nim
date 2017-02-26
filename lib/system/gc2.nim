#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#            Garbage Collector
#
# The basic algorithm is *Deferred Reference Counting* with an incremental mark
# and sweep GC to free cycles. It is hard realtime in that if you play
# according to its rules, no deadline will ever be missed.

# XXX Ensure by smart color masking that the object is not in the ZCT.

{.push profiler:off.}

const
  CycleIncrease = 2 # is a multiplicative increase
  InitialCycleThreshold = 4*1024*1024 # X MB because cycle checking is slow
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
  rcIncrement = 0b1000 # so that lowest 3 bits are not touched
  rcBlackOrig = 0b000
  rcWhiteOrig = 0b001
  rcGrey = 0b010   # traditional color for incremental mark&sweep
  rcUnused = 0b011
  ZctFlag = 0b100  # in ZCT
  rcShift = 3      # shift by rcShift to get the reference counter
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
    cycleCollections: int    # number of performed full collections
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
    zct: CellSeq             # the zero count table
    decStack: CellSeq        # cells in the stack that are to decref again
    greyStack: CellSeq
    recGcLock: int           # prevent recursion via finalizers; no thread lock
    when withRealTime:
      maxPause: Nanos        # max allowed pause in nanoseconds; active if > 0
    region: MemRegion        # garbage collected region
    stat: GcStat
    additionalRoots: CellSeq # dummy roots for GC_ref/unref
    spaceIter: ObjectSpaceIter
    pDumpHeapFile: pointer # File that is used for GC_dumpHeap
    when hasThreadSupport:
      toDispose: SharedList[pointer]

var
  gch {.rtlThreadVar.}: GcHeap

when not defined(useNimRtl):
  instantiateForRegion(gch.region)

proc initGC() =
  when not defined(useNimRtl):
    gch.red = (1-gch.black)
    gch.cycleThreshold = InitialCycleThreshold
    gch.stat.stackScans = 0
    gch.stat.cycleCollections = 0
    gch.stat.maxThreshold = 0
    gch.stat.maxStackSize = 0
    gch.stat.maxStackCells = 0
    gch.stat.cycleTableSize = 0
    # init the rt
    init(gch.zct)
    init(gch.decStack)
    init(gch.additionalRoots)
    init(gch.greyStack)
    when hasThreadSupport:
      gch.toDispose = initSharedList[pointer]()

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

proc addZCT(s: var CellSeq, c: PCell) {.noinline.} =
  if (c.refcount and ZctFlag) == 0:
    c.refcount = c.refcount or ZctFlag
    add(s, c)

proc cellToUsr(cell: PCell): pointer {.inline.} =
  # convert object (=pointer to refcount) to pointer to userdata
  result = cast[pointer](cast[ByteAddress](cell)+%ByteAddress(sizeof(Cell)))

proc usrToCell(usr: pointer): PCell {.inline.} =
  # convert pointer to userdata to object (=pointer to refcount)
  result = cast[PCell](cast[ByteAddress](usr)-%ByteAddress(sizeof(Cell)))

proc canBeCycleRoot(c: PCell): bool {.inline.} =
  result = ntfAcyclic notin c.typ.flags

proc extGetCellType(c: pointer): PNimType {.compilerproc.} =
  # used for code generation concerning debugging
  result = usrToCell(c).typ

proc internRefcount(p: pointer): int {.exportc: "getRefcount".} =
  result = int(usrToCell(p).refcount) shr rcShift

# this that has to equals zero, otherwise we have to round up UnitsPerPage:
when BitsPerPage mod (sizeof(int)*8) != 0:
  {.error: "(BitsPerPage mod BitsPerUnit) should be zero!".}

template color(c): expr = c.refCount and colorMask
template setColor(c, col) =
  c.refcount = c.refcount and not colorMask or col

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
  when leakDetector:
    c_fprintf(file, "%s %p %d rc=%ld color=%c from %s(%ld)\n",
              msg, id, kind, c.refcount shr rcShift, col, c.filename, c.line)
  else:
    c_fprintf(file, "%s %p %d rc=%ld color=%c\n",
              msg, id, kind, c.refcount shr rcShift, col)

proc writeCell(msg: cstring, c: PCell) =
  stdout.writeCell(msg, c)

proc myastToStr[T](x: T): string {.magic: "AstToStr", noSideEffect.}

template gcTrace(cell, state: expr): stmt {.immediate.} =
  when traceGC: writeCell(myastToStr(state), cell)

# forward declarations:
proc collectCT(gch: var GcHeap) {.benign.}
proc isOnStack(p: pointer): bool {.noinline, benign.}
proc forAllChildren(cell: PCell, op: WalkOp) {.benign.}
proc doOperation(p: pointer, op: WalkOp) {.benign.}
proc forAllChildrenAux(dest: pointer, mt: PNimType, op: WalkOp) {.benign.}
# we need the prototype here for debugging purposes

when hasThreadSupport and hasSharedHeap:
  template `--`(x: expr): expr = atomicDec(x, rcIncrement) <% rcIncrement
  template `++`(x: expr): stmt = discard atomicInc(x, rcIncrement)
else:
  template `--`(x: expr): expr =
    dec(x, rcIncrement)
    x <% rcIncrement
  template `++`(x: expr): stmt = inc(x, rcIncrement)

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

proc rtlAddCycleRoot(c: PCell) {.rtl, inl.} =
  # we MUST access gch as a global here, because this crosses DLL boundaries!
  discard

proc rtlAddZCT(c: PCell) {.rtl, inl.} =
  # we MUST access gch as a global here, because this crosses DLL boundaries!
  addZCT(gch.zct, c)

proc decRef(c: PCell) {.inline.} =
  gcAssert(isAllocatedPtr(gch.region, c), "decRef: interiorPtr")
  gcAssert(c.refcount >=% rcIncrement, "decRef")
  if --c.refcount:
    rtlAddZCT(c)

proc incRef(c: PCell) {.inline.} =
  gcAssert(isAllocatedPtr(gch.region, c), "incRef: interiorPtr")
  c.refcount = c.refcount +% rcIncrement

proc nimGCref(p: pointer) {.compilerProc.} =
  let cell = usrToCell(p)
  incRef(cell)
  add(gch.additionalRoots, cell)

proc nimGCunref(p: pointer) {.compilerProc.} =
  let cell = usrToCell(p)
  decRef(cell)
  var L = gch.additionalRoots.len-1
  var i = L
  let d = gch.additionalRoots.d
  while i >= 0:
    if d[i] == cell:
      d[i] = d[L]
      dec gch.additionalRoots.len
      break
    dec(i)

template markGrey(x: PCell) =
  if x.color != 1-gch.black and gch.phase == Phase.Marking:
    if not isAllocatedPtr(gch.region, x):
      c_fprintf(stdout, "[GC] markGrey proc: %p\n", x)
      #GC_dumpHeap()
      sysAssert(false, "wtf")
    x.setColor(rcGrey)
    add(gch.greyStack, x)

proc GC_addCycleRoot*[T](p: ref T) {.inline.} =
  ## adds 'p' to the cycle candidate set for the cycle collector. It is
  ## necessary if you used the 'acyclic' pragma for optimization
  ## purposes and need to break cycles manually.
  rtlAddCycleRoot(usrToCell(cast[pointer](p)))

proc nimGCunrefNoCycle(p: pointer) {.compilerProc, inline.} =
  sysAssert(allocInv(gch.region), "begin nimGCunrefNoCycle")
  var c = usrToCell(p)
  gcAssert(isAllocatedPtr(gch.region, c), "nimGCunrefNoCycle: isAllocatedPtr")
  if --c.refcount:
    rtlAddZCT(c)
    sysAssert(allocInv(gch.region), "end nimGCunrefNoCycle 2")
  sysAssert(allocInv(gch.region), "end nimGCunrefNoCycle 5")

proc asgnRef(dest: PPointer, src: pointer) {.compilerProc, inline.} =
  # the code generator calls this proc!
  gcAssert(not isOnStack(dest), "asgnRef")
  # BUGFIX: first incRef then decRef!
  if src != nil:
    let s = usrToCell(src)
    incRef(s)
    markGrey(s)
  if dest[] != nil: decRef(usrToCell(dest[]))
  dest[] = src

proc asgnRefNoCycle(dest: PPointer, src: pointer) {.compilerProc, inline.} =
  # the code generator calls this proc if it is known at compile time that no
  # cycle is possible.
  gcAssert(not isOnStack(dest), "asgnRefNoCycle")
  if src != nil:
    var c = usrToCell(src)
    ++c.refcount
    markGrey(c)
  if dest[] != nil:
    var c = usrToCell(dest[])
    if --c.refcount:
      rtlAddZCT(c)
  dest[] = src

proc unsureAsgnRef(dest: PPointer, src: pointer) {.compilerProc.} =
  # unsureAsgnRef updates the reference counters only if dest is not on the
  # stack. It is used by the code generator if it cannot decide wether a
  # reference is in the stack or not (this can happen for var parameters).
  if not isOnStack(dest):
    if src != nil:
      let s = usrToCell(src)
      incRef(s)
      markGrey(s)
    # XXX finally use assembler for the stack checking instead!
    # the test for '!= nil' is correct, but I got tired of the segfaults
    # resulting from the crappy stack checking:
    if cast[int](dest[]) >=% PageSize: decRef(usrToCell(dest[]))
  else:
    # can't be an interior pointer if it's a stack location!
    gcAssert(interiorAllocatedPtr(gch.region, dest) == nil,
             "stack loc AND interior pointer")
  dest[] = src

type
  GlobalMarkerProc = proc () {.nimcall, benign.}
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
          forAllChildrenAux(cast[pointer](d +% i *% cell.typ.base.size +%
            GenericSeqSize), cell.typ.base, op)
    else: discard

proc addNewObjToZCT(res: PCell, gch: var GcHeap) {.inline.} =
  # we check the last 8 entries (cache line) for a slot that could be reused.
  # In 63% of all cases we succeed here! But we have to optimize the heck
  # out of this small linear search so that ``newObj`` is not slowed down.
  #
  # Slots to try          cache hit
  # 1                     32%
  # 4                     59%
  # 8                     63%
  # 16                    66%
  # all slots             68%
  var L = gch.zct.len
  var d = gch.zct.d
  when true:
    # loop unrolled for performance:
    template replaceZctEntry(i: expr) =
      c = d[i]
      if c.refcount >=% rcIncrement:
        c.refcount = c.refcount and not ZctFlag
        d[i] = res
        return
    if L > 8:
      var c: PCell
      replaceZctEntry(L-1)
      replaceZctEntry(L-2)
      replaceZctEntry(L-3)
      replaceZctEntry(L-4)
      replaceZctEntry(L-5)
      replaceZctEntry(L-6)
      replaceZctEntry(L-7)
      replaceZctEntry(L-8)
      add(gch.zct, res)
    else:
      d[L] = res
      inc(gch.zct.len)
  else:
    for i in countdown(L-1, max(0, L-8)):
      var c = d[i]
      if c.refcount >=% rcIncrement:
        c.refcount = c.refcount and not ZctFlag
        d[i] = res
        return
    add(gch.zct, res)

{.push stackTrace: off, profiler:off.}
proc gcInvariant*() =
  sysAssert(allocInv(gch.region), "injected")
  when declared(markForDebug):
    markForDebug(gch)
{.pop.}

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
  res.refcount = ZctFlag or allocColor()
  sysAssert(isAllocatedPtr(gch.region, res), "newObj: 3")
  # its refcount is zero, so add it to the ZCT:
  addNewObjToZCT(res, gch)
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
  let size = addInt(mulInt(len, typ.base.size), GenericSeqSize)
  result = newObj(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len
  when defined(memProfiler): nimProfile(size)

proc newObjRC1(typ: PNimType, size: int): pointer {.compilerRtl.} =
  # generates a new object and sets its reference counter to 1
  sysAssert(allocInv(gch.region), "newObjRC1 begin")
  gcAssert(typ.kind in {tyRef, tyString, tySequence}, "newObj: 1")
  collectCT(gch)
  sysAssert(allocInv(gch.region), "newObjRC1 after collectCT")

  var res = cast[PCell](rawAlloc(gch.region, size + sizeof(Cell)))
  sysAssert(allocInv(gch.region), "newObjRC1 after rawAlloc")
  sysAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "newObj: 2")
  # now it is buffered in the ZCT
  res.typ = typ
  when leakDetector:
    if framePtr != nil and framePtr.prev != nil:
      res.filename = framePtr.prev.filename
      res.line = framePtr.prev.line
  res.refcount = rcIncrement or allocColor() # refcount is 1
  sysAssert(isAllocatedPtr(gch.region, res), "newObj: 3")
  when logGC: writeCell("new cell", res)
  gcTrace(res, csAllocated)
  when useCellIds:
    inc gch.idGenerator
    res.id = gch.idGenerator
  result = cellToUsr(res)
  zeroMem(result, size)
  sysAssert(allocInv(gch.region), "newObjRC1 end")
  when defined(memProfiler): nimProfile(size)

proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =
  let size = addInt(mulInt(len, typ.base.size), GenericSeqSize)
  result = newObjRC1(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len
  when defined(memProfiler): nimProfile(size)

proc growObj(old: pointer, newsize: int, gch: var GcHeap): pointer =
  collectCT(gch)
  var ol = usrToCell(old)
  gcAssert(isAllocatedPtr(gch.region, ol), "growObj: freed pointer?")

  sysAssert(ol.typ != nil, "growObj: 1")
  gcAssert(ol.typ.kind in {tyString, tySequence}, "growObj: 2")
  sysAssert(allocInv(gch.region), "growObj begin")

  var res = cast[PCell](rawAlloc(gch.region, newsize + sizeof(Cell)))
  var elemSize = 1
  if ol.typ.kind != tyString: elemSize = ol.typ.base.size

  let oldsize = cast[PGenericSeq](old).len*elemSize + GenericSeqSize
  copyMem(res, ol, oldsize + sizeof(Cell))
  zeroMem(cast[pointer](cast[ByteAddress](res) +% oldsize +% sizeof(Cell)),
          newsize-oldsize)
  sysAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "growObj: 3")
  # This can be wrong for intermediate temps that are nevertheless on the
  # heap because of lambda lifting:
  #gcAssert(res.refcount shr rcShift <=% 1, "growObj: 4")
  when logGC:
    writeCell("growObj old cell", ol)
    writeCell("growObj new cell", res)
  gcTrace(ol, csZctFreed)
  gcTrace(res, csAllocated)
  when reallyDealloc:
    sysAssert(allocInv(gch.region), "growObj before dealloc")
    if ol.refcount shr rcShift <=% 1:
      # free immediately to save space:
      if (ol.refcount and ZctFlag) != 0:
        var j = gch.zct.len-1
        var d = gch.zct.d
        while j >= 0:
          if d[j] == ol:
            d[j] = res
            break
          dec(j)
      rawDealloc(gch.region, ol)
    else:
      # we split the old refcount in 2 parts. XXX This is still not entirely
      # correct if the pointer that receives growObj's result is on the stack.
      # A better fix would be to emit the location specific write barrier for
      # 'growObj', but this is lots of more work and who knows what new problems
      # this would create.
      res.refcount = rcIncrement or allocColor()
      decRef(ol)
  else:
    sysAssert(ol.typ != nil, "growObj: 5")
    zeroMem(ol, sizeof(Cell))
  when useCellIds:
    inc gch.idGenerator
    res.id = gch.idGenerator
  result = cellToUsr(res)
  sysAssert(allocInv(gch.region), "growObj end")
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
  var d = gch.decStack.d
  for i in 0 .. < gch.decStack.len:
    if isAllocatedPtr(gch.region, d[i]):
      c_fprintf(file, "onstack %p\n", d[i])
    else:
      c_fprintf(file, "onstack_invalid %p\n", d[i])
  for i in 0 .. < globalMarkersLen: globalMarkers[i]()
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

  var d = gch.decStack.d
  for i in 0..gch.decStack.len-1:
    if d[i] == c:
      writeCell("freeing ", c)
      GC_dumpHeap()
    gcAssert d[i] != c, "wtf man, freeing obviously alive stuff?!!"

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
  elif c.color == rcGrey:
    var isGrey = false
    var d = gch.decStack.d
    for i in 0..gch.decStack.len-1:
      if d[i] == c:
        isGrey = true
        break
    if not isGrey:
      gcAssert false, "markRoot: root is already grey?!"

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
      gcAssert false, "wtf why are there white object in the greystack?"
    checkTime()
  gcAssert gch.greyStack.len == 0, "markIncremental: greystack not empty "

  # assert that all local roots are black by now:
  var d = gch.decStack.d
  var errors = false
  for i in 0..gch.decStack.len-1:
    gcAssert(isAllocatedPtr(gch.region, d[i]), "markIncremental: isAllocatedPtr 2")
    if d[i].color != gch.black:
      writeCell("not black ", d[i])
      errors = true
  gcAssert(not errors, "wtf something wrong hre")
  result = true

proc markGlobals(gch: var GcHeap) =
  for i in 0 .. < globalMarkersLen: globalMarkers[i]()

proc markLocals(gch: var GcHeap) =
  var d = gch.decStack.d
  for i in 0 .. < gch.decStack.len:
    sysAssert isAllocatedPtr(gch.region, d[i]), "markLocals"
    markRoot(gch, d[i])

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
    gcAssert(c.refcount >=% rcIncrement, "doOperation 2")
    #c.refcount = c.refcount -% rcIncrement
    when logGC: writeCell("decref (from doOperation)", c)
    decRef(c)
    #if c.refcount <% rcIncrement: addZCT(gch.zct, c)
  of waMarkGlobal:
    template handleRoot =
      if gch.dumpHeapFile.isNil:
        markRoot(gch, c)
      else:
        dumpRoot(gch, c)
    when hasThreadSupport:
      # could point to a cell which we don't own and don't want to touch/trace
      if isAllocatedPtr(gch.region, c): handleRoot()
    else:
      #gcAssert(isAllocatedPtr(gch.region, c), "doOperation: waMarkGlobal")
      if not isAllocatedPtr(gch.region, c):
        c_fprintf(stdout, "[GC] not allocated anymore: MarkGlobal %p\n", c)
        #GC_dumpHeap()
        sysAssert(false, "wtf")
      handleRoot()
    discard allocInv(gch.region)
  of waMarkGrey:
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

proc collectZCT(gch: var GcHeap): bool {.benign.}

proc collectCycles(gch: var GcHeap): bool =
  when hasThreadSupport:
    for c in gch.toDispose:
      nimGCunref(c)

  # ensure the ZCT 'color' is not used:
  while gch.zct.len > 0: discard collectZCT(gch)

  case gch.phase
  of Phase.None:
    gch.phase = Phase.Marking
    markGlobals(gch)

    c_fprintf(stdout, "collectCycles: introduced bug E %ld\n", gch.phase)
    discard allocInv(gch.region)
  of Phase.Marking:
    # since locals do not have a write barrier, we need
    # to keep re-scanning them :-( but there is really nothing we can
    # do about that.
    markLocals(gch)
    if markIncremental(gch):
      gch.phase = Phase.Sweeping
      gch.red = 1 - gch.red
  of Phase.Sweeping:
    gcAssert gch.greyStack.len == 0, "greystack not empty"
    if sweep(gch):
      gch.phase = Phase.None
      # flip black/white meanings:
      gch.black = 1 - gch.black
      gcAssert gch.red == 1 - gch.black, "red color is wrong"
      result = true

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
      objStart.refcount = objStart.refcount +% rcIncrement
      add(gch.decStack, objStart)
  sysAssert(allocInv(gch.region), "gcMark end")

include gc_common

proc markStackAndRegisters(gch: var GcHeap) {.noinline, cdecl.} =
  forEachStackSlot(gch, gcMark)

proc collectZCT(gch: var GcHeap): bool =
  # Note: Freeing may add child objects to the ZCT! So essentially we do
  # deep freeing, which is bad for incremental operation. In order to
  # avoid a deep stack, we move objects to keep the ZCT small.
  # This is performance critical!
  var L = addr(gch.zct.len)
  takeStartTime(100)

  while L[] > 0:
    var c = gch.zct.d[0]
    sysAssert(isAllocatedPtr(gch.region, c), "CollectZCT: isAllocatedPtr")
    # remove from ZCT:
    gcAssert((c.refcount and ZctFlag) == ZctFlag, "collectZCT")

    c.refcount = c.refcount and not ZctFlag
    gch.zct.d[0] = gch.zct.d[L[] - 1]
    dec(L[])
    takeTime()
    if c.refcount <% rcIncrement and c.color != rcGrey:
      # It may have a RC > 0, if it is in the hardware stack or
      # it has not been removed yet from the ZCT. This is because
      # ``incref`` does not bother to remove the cell from the ZCT
      # as this might be too slow.
      # In any case, it should be removed from the ZCT. But not
      # freed. **KEEP THIS IN MIND WHEN MAKING THIS INCREMENTAL!**
      when logGC: writeCell("zct dealloc cell", c)
      gcTrace(c, csZctFreed)
      # We are about to free the object, call the finalizer BEFORE its
      # children are deleted as well, because otherwise the finalizer may
      # access invalid memory. This is done by prepareDealloc():
      prepareDealloc(c)
      forAllChildren(c, waZctDecRef)
      when reallyDealloc:
        sysAssert(allocInv(gch.region), "collectZCT: rawDealloc")
        rawDealloc(gch.region, c)
      else:
        sysAssert(c.typ != nil, "collectZCT 2")
        zeroMem(c, sizeof(Cell))
    checkTime()
  result = true

proc unmarkStackAndRegisters(gch: var GcHeap) =
  var d = gch.decStack.d
  for i in 0..gch.decStack.len-1:
    sysAssert isAllocatedPtr(gch.region, d[i]), "unmarkStackAndRegisters"
    decRef(d[i])
  gch.decStack.len = 0

proc collectCTBody(gch: var GcHeap) =
  when withRealTime:
    let t0 = getticks()
  sysAssert(allocInv(gch.region), "collectCT: begin")

  when not nimCoroutines:
    gch.stat.maxStackSize = max(gch.stat.maxStackSize, stackSize())
  sysAssert(gch.decStack.len == 0, "collectCT")
  prepareForInteriorPointerChecking(gch.region)
  markStackAndRegisters(gch)
  gch.stat.maxStackCells = max(gch.stat.maxStackCells, gch.decStack.len)
  inc(gch.stat.stackScans)
  if collectZCT(gch):
    when cycleGC:
      if getOccupiedMem(gch.region) >= gch.cycleThreshold or alwaysCycleGC:
        if collectCycles(gch):
          inc(gch.stat.cycleCollections)
          gch.cycleThreshold = max(InitialCycleThreshold, getOccupiedMem() *
                                   CycleIncrease)
          gch.stat.maxThreshold = max(gch.stat.maxThreshold, gch.cycleThreshold)
  unmarkStackAndRegisters(gch)
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
  if (gch.zct.len >= stackMarkCosts or (cycleGC and
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
    if (gch.zct.len >= ZctThreshold or (cycleGC and
        getOccupiedMem(gch.region)>=gch.cycleThreshold) or alwaysGC) or
        strongAdvice:
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
    when hasThreadSupport and hasSharedHeap:
      discard atomicInc(gch.recGcLock, 1)
    else:
      inc(gch.recGcLock)
  proc GC_enable() =
    if gch.recGcLock > 0:
      when hasThreadSupport and hasSharedHeap:
        discard atomicDec(gch.recGcLock, 1)
      else:
        dec(gch.recGcLock)

  proc GC_setStrategy(strategy: GC_Strategy) =
    discard

  proc GC_enableMarkAndSweep() =
    gch.cycleThreshold = InitialCycleThreshold

  proc GC_disableMarkAndSweep() =
    gch.cycleThreshold = high(gch.cycleThreshold)-1
    # set to the max value to suppress the cycle detector

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
             "[GC] cycle collections: " & $gch.stat.cycleCollections & "\n" &
             "[GC] max threshold: " & $gch.stat.maxThreshold & "\n" &
             "[GC] zct capacity: " & $gch.zct.cap & "\n" &
             "[GC] max cycle table size: " & $gch.stat.cycleTableSize & "\n" &
             "[GC] max pause time [ms]: " & $(gch.stat.maxPause div 1000_000)
    when nimCoroutines:
      result = result & "[GC] number of stacks: " & $gch.stack.len & "\n"
      for stack in items(gch.stack):
        result = result & "[GC]   stack " & stack.bottom.repr & "[GC]     max stack size " & $stack.maxStackSize & "\n"
    else:
      result = result & "[GC] max stack size: " & $gch.stat.maxStackSize & "\n"
    GC_enable()

{.pop.}
