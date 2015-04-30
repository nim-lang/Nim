#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#            Garbage Collector
#
# The basic algorithm is *Deferrent Reference Counting* with cycle detection.
# This is achieved by combining a Deutsch-Bobrow garbage collector
# together with Christoper's partial mark-sweep garbage collector.
#
# Special care has been taken to avoid recursion as far as possible to avoid
# stack overflows when traversing deep datastructures. It is well-suited
# for soft real time applications (like games).
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
  proc nimProfile(requestedSize: int)

const
  rcShift = 6 # the reference count is shifted so we can use
              # the least significat bits for additinal flags:

  rcAlive = 0b00000           # object is reachable.
                              # color *black* in the original paper
                              
  rcCycleCandidate = 0b00001  # possible root of a cycle. *purple*

  rcDecRefApplied = 0b00010   # the first dec-ref phase of the
                              # collector was already applied to this
                              # object. *gray*
                              
  rcMaybeDead = 0b00011       # this object is a candidate for deletion
                              # during the collect cycles algorithm.
                              # *white*.
                              
  rcReallyDead = 0b00100      # this is proved to be garbage
  
  rcRetiredBuffer = 0b00101   # this is a seq or string buffer that
                              # was replaced by a resize operation.
                              # see growObj for details

  rcColorMask = TRefCount(0b00111)

  rcZct = 0b01000             # already added to ZCT
  rcInCycleRoots = 0b10000    # already buffered as cycle candidate
  rcHasStackRef = 0b100000    # the object had a stack ref in the last
                              # cycle collection

  rcMarkBit = rcHasStackRef   # this is currently used for leak detection
                              # when traceGC is on

  rcBufferedAnywhere = rcZct or rcInCycleRoots

  rcIncrement = 1 shl rcShift # don't touch the color bits

const
  NewObjectsAreCycleRoots = true
    # the alternative is to use the old strategy of adding cycle roots
    # in incRef (in the compiler itself, this doesn't change much)

  IncRefRemovesCandidates = false
    # this is safe only if we can reliably track the fact that the object
    # has stack references. This could be easily done by adding another bit
    # to the refcount field and setting it up in unmarkStackAndRegisters.
    # The bit must also be set for new objects that are not rc1 and it must be
    # examined in the decref loop in collectCycles.
    # XXX: not implemented yet as tests didn't show any improvement from this
   
  MarkingSkipsAcyclicObjects = true
    # Acyclic objects can be safely ignored in the mark and scan phases, 
    # because they cannot contribute to the internal count.
    # XXX: if we generate specialized `markCyclic` and `markAcyclic`
    # procs we can further optimize this as there won't be need for any
    # checks in the code
  
  MinimumStackMarking = false
    # Try to scan only the user stack and ignore the part of the stack
    # belonging to the GC itself. see setStackTop for further info.
    # XXX: still has problems in release mode in the compiler itself.
    # investigate how it affects growObj

  CollectCyclesStats = false

type
  TWalkOp = enum
    waPush

  TFinalizer {.compilerproc.} = proc (self: pointer) {.nimcall.}
    # A ref type can have a finalizer that is called before the object's
    # storage is freed.

  TGcStat {.final, pure.} = object
    stackScans: int          # number of performed stack scans (for statistics)
    cycleCollections: int    # number of performed full collections
    maxThreshold: int        # max threshold that has been set
    maxStackSize: int        # max stack size
    maxStackCells: int       # max stack cells in ``decStack``
    cycleTableSize: int      # max entries in cycle table  
    maxPause: int64          # max measured GC pause in nanoseconds
  
  TGcHeap {.final, pure.} = object # this contains the zero count and
                                   # non-zero count table
    stackBottom: pointer
    stackTop: pointer
    cycleThreshold: int
    zct: TCellSeq            # the zero count table
    decStack: TCellSeq       # cells in the stack that are to decref again
    cycleRoots: TCellSeq
    tempStack: TCellSeq      # temporary stack for recursion elimination
    freeStack: TCellSeq      # objects ready to be freed
    recGcLock: int           # prevent recursion via finalizers; no thread lock
    cycleRootsTrimIdx: int   # Trimming is a light-weight collection of the 
                             # cycle roots table that uses a cheap linear scan
                             # to find only possitively dead objects.
                             # One strategy is to perform it only for new objects
                             # allocated between the invocations of collectZCT.
                             # This index indicates the start of the range of
                             # such new objects within the table.
    when withRealTime:
      maxPause: TNanos       # max allowed pause in nanoseconds; active if > 0
    region: TMemRegion       # garbage collected region
    stat: TGcStat

var
  gch* {.rtlThreadVar.}: TGcHeap

when not defined(useNimRtl):
  instantiateForRegion(gch.region)

template acquire(gch: TGcHeap) = 
  when hasThreadSupport and hasSharedHeap:
    AcquireSys(HeapLock)

template release(gch: TGcHeap) = 
  when hasThreadSupport and hasSharedHeap:
    releaseSys(HeapLock)

template setColor(c: PCell, color) =
  c.refcount = (c.refcount and not rcColorMask) or color

template color(c: PCell): expr =
  c.refcount and rcColorMask

template isBitDown(c: PCell, bit): expr =
  (c.refcount and bit) == 0

template isBitUp(c: PCell, bit): expr =
  (c.refcount and bit) != 0

template setBit(c: PCell, bit): expr =
  c.refcount = c.refcount or bit

template isDead(c: Pcell): expr =
  c.isBitUp(rcReallyDead) # also covers rcRetiredBuffer

template clearBit(c: PCell, bit): expr =
  c.refcount = c.refcount and (not TRefCount(bit))

when debugGC:
  var gcCollectionIdx = 0

  proc colorStr(c: PCell): cstring =
    let color = c.color
    case color
    of rcAlive: return "alive"
    of rcMaybeDead: return "maybedead"
    of rcCycleCandidate: return "candidate"
    of rcDecRefApplied: return "marked"
    of rcRetiredBuffer: return "retired"
    of rcReallyDead: return "dead"
    else: return "unknown?"
  
  proc inCycleRootsStr(c: PCell): cstring =
    if c.isBitUp(rcInCycleRoots): result = "cycleroot"
    else: result = ""

  proc inZctStr(c: PCell): cstring =
    if c.isBitUp(rcZct): result = "zct"
    else: result = ""

  proc writeCell*(msg: CString, c: PCell, force = false) =
    var kind = -1
    if c.typ != nil: kind = ord(c.typ.kind)
    when trackAllocationSource:
      c_fprintf(c_stdout, "[GC %d] %s: %p %d rc=%ld %s %s %s from %s(%ld)\n",
                gcCollectionIdx,
                msg, c, kind, c.refcount shr rcShift,
                c.colorStr, c.inCycleRootsStr, c.inZctStr,
                c.filename, c.line)
    else:
      c_fprintf(c_stdout, "[GC] %s: %p %d rc=%ld\n",
                msg, c, kind, c.refcount shr rcShift)

proc addZCT(zct: var TCellSeq, c: PCell) {.noinline.} =
  if c.isBitDown(rcZct):
    c.setBit rcZct
    zct.add c

template setStackTop(gch) =
  # This must be called immediately after we enter the GC code
  # to minimize the size of the scanned stack. The stack consumed
  # by the GC procs may amount to 200-400 bytes depending on the
  # build settings and this contributes to false-positives
  # in the conservative stack marking
  when MinimumStackMarking:
    var stackTop {.volatile.}: pointer
    gch.stackTop = addr(stackTop)

template addCycleRoot(cycleRoots: var TCellSeq, c: PCell) =
  if c.color != rcCycleCandidate:
    c.setColor rcCycleCandidate
    
    # the object may be buffered already. for example, consider:
    # decref; incref; decref
    if c.isBitDown(rcInCycleRoots):
      c.setBit rcInCycleRoots
      cycleRoots.add c

proc cellToUsr(cell: PCell): pointer {.inline.} =
  # convert object (=pointer to refcount) to pointer to userdata
  result = cast[pointer](cast[ByteAddress](cell)+%ByteAddress(sizeof(TCell)))

proc usrToCell*(usr: pointer): PCell {.inline.} =
  # convert pointer to userdata to object (=pointer to refcount)
  result = cast[PCell](cast[ByteAddress](usr)-%ByteAddress(sizeof(TCell)))

proc canbeCycleRoot(c: PCell): bool {.inline.} =
  result = ntfAcyclic notin c.typ.flags

proc extGetCellType(c: pointer): PNimType {.compilerproc.} =
  # used for code generation concerning debugging
  result = usrToCell(c).typ

proc internRefcount(p: pointer): int {.exportc: "getRefcount".} =
  result = int(usrToCell(p).refcount) shr rcShift

# this that has to equals zero, otherwise we have to round up UnitsPerPage:
when BitsPerPage mod (sizeof(int)*8) != 0:
  {.error: "(BitsPerPage mod BitsPerUnit) should be zero!".}

# forward declarations:
proc collectCT(gch: var TGcHeap)
proc isOnStack*(p: pointer): bool {.noinline.}
proc forAllChildren(cell: PCell, op: TWalkOp)
proc doOperation(p: pointer, op: TWalkOp)
proc forAllChildrenAux(dest: pointer, mt: PNimType, op: TWalkOp)
# we need the prototype here for debugging purposes

proc prepareDealloc(cell: PCell) =
  if cell.typ.finalizer != nil:
    # the finalizer could invoke something that
    # allocates memory; this could trigger a garbage
    # collection. Since we are already collecting we
    # prevend recursive entering here by a lock.
    # XXX: we should set the cell's children to nil!
    inc(gch.recGcLock)
    (cast[TFinalizer](cell.typ.finalizer))(cellToUsr(cell))
    dec(gch.recGcLock)

when traceGC:
  # traceGC is a special switch to enable extensive debugging
  type
    TCellState = enum
      csAllocated, csFreed
  var
    states: array[TCellState, TCellSet]

  proc traceCell(c: PCell, state: TCellState) =
    case state
    of csAllocated:
      if c in states[csAllocated]:
        writeCell("attempt to alloc an already allocated cell", c)
        sysAssert(false, "traceCell 1")
      excl(states[csFreed], c)
      # writecell("allocated", c)
    of csFreed:
      if c in states[csFreed]:
        writeCell("attempt to free a cell twice", c)
        sysAssert(false, "traceCell 2")
      if c notin states[csAllocated]:
        writeCell("attempt to free not an allocated cell", c)
        sysAssert(false, "traceCell 3")
      excl(states[csAllocated], c)
      # writecell("freed", c)
    incl(states[state], c)

  proc computeCellWeight(c: PCell): int =
    var x: TCellSet
    x.init

    let startLen = gch.tempStack.len
    c.forAllChildren waPush
    
    while startLen != gch.tempStack.len:
      dec gch.tempStack.len
      var c = gch.tempStack.d[gch.tempStack.len]
      if c in states[csFreed]: continue
      inc result
      if c notin x:
        x.incl c
        c.forAllChildren waPush

  template markChildrenRec(cell) =
    let startLen = gch.tempStack.len
    cell.forAllChildren waPush
    let isMarked = cell.isBitUp(rcMarkBit)
    while startLen != gch.tempStack.len:
      dec gch.tempStack.len
      var c = gch.tempStack.d[gch.tempStack.len]
      if c in states[csFreed]: continue
      if c.isBitDown(rcMarkBit):
        c.setBit rcMarkBit
        c.forAllChildren waPush
    if c.isBitUp(rcMarkBit) and not isMarked:
      writecell("cyclic cell", cell)
      cprintf "Weight %d\n", cell.computeCellWeight
      
  proc writeLeakage(onlyRoots: bool) =
    if onlyRoots:
      for c in elements(states[csAllocated]):
        if c notin states[csFreed]:
          markChildrenRec(c)
    var f = 0
    var a = 0
    for c in elements(states[csAllocated]):
      inc a
      if c in states[csFreed]: inc f
      elif c.isBitDown(rcMarkBit):
        writeCell("leak", c)
        cprintf "Weight %d\n", c.computeCellWeight
    cfprintf(cstdout, "Allocations: %ld; freed: %ld\n", a, f)

template gcTrace(cell, state: expr): stmt {.immediate.} =
  when logGC: writeCell($state, cell)
  when traceGC: traceCell(cell, state)

template WithHeapLock(blk: stmt): stmt =
  when hasThreadSupport and hasSharedHeap: AcquireSys(HeapLock)
  blk
  when hasThreadSupport and hasSharedHeap: ReleaseSys(HeapLock)

proc rtlAddCycleRoot(c: PCell) {.rtl, inl.} = 
  # we MUST access gch as a global here, because this crosses DLL boundaries!
  WithHeapLock: addCycleRoot(gch.cycleRoots, c)

proc rtlAddZCT(c: PCell) {.rtl, inl.} =
  # we MUST access gch as a global here, because this crosses DLL boundaries!
  WithHeapLock: addZCT(gch.zct, c)

type
  TCyclicMode = enum
    Cyclic,
    Acyclic,
    MaybeCyclic

  TReleaseType = enum
    AddToZTC
    FreeImmediately

  THeapType = enum
    LocalHeap
    SharedHeap

template `++` (rc: TRefCount, heapType: THeapType): stmt =
  when heapType == SharedHeap:
    discard atomicInc(rc, rcIncrement)
  else:
    inc rc, rcIncrement

template `--`(rc: TRefCount): expr =
  dec rc, rcIncrement
  rc <% rcIncrement

template `--` (rc: TRefCount, heapType: THeapType): expr =
  (when heapType == SharedHeap: atomicDec(rc, rcIncrement) <% rcIncrement else: --rc)

template doDecRef(cc: PCell,
                  heapType = LocalHeap,
                  cycleFlag = MaybeCyclic): stmt =
  var c = cc
  sysAssert(isAllocatedPtr(gch.region, c), "decRef: interiorPtr")
  # XXX: move this elesewhere

  sysAssert(c.refcount >=% rcIncrement, "decRef")
  if c.refcount--(heapType):
    # this is the last reference from the heap
    # add to a zero-count-table that will be matched against stack pointers
    rtlAddZCT(c)
  else:
    when cycleFlag != Acyclic:
      if cycleFlag == Cyclic or canBeCycleRoot(c):
        # a cycle may have been broken
        rtlAddCycleRoot(c)

template doIncRef(cc: PCell,
                 heapType = LocalHeap,
                 cycleFlag = MaybeCyclic): stmt =
  var c = cc
  c.refcount++(heapType)
  when cycleFlag != Acyclic:
    when NewObjectsAreCycleRoots:
      if canbeCycleRoot(c):
        addCycleRoot(gch.cycleRoots, c)
    elif IncRefRemovesCandidates:
      c.setColor rcAlive
  # XXX: this is not really atomic enough!
  
proc nimGCref(p: pointer) {.compilerProc, inline.} = doIncRef(usrToCell(p))
proc nimGCunref(p: pointer) {.compilerProc, inline.} = doDecRef(usrToCell(p))

proc nimGCunrefNoCycle(p: pointer) {.compilerProc, inline.} =
  sysAssert(allocInv(gch.region), "begin nimGCunrefNoCycle")
  var c = usrToCell(p)
  sysAssert(isAllocatedPtr(gch.region, c), "nimGCunrefNoCycle: isAllocatedPtr")
  if c.refcount--(LocalHeap):
    rtlAddZCT(c)
    sysAssert(allocInv(gch.region), "end nimGCunrefNoCycle 2")
  sysAssert(allocInv(gch.region), "end nimGCunrefNoCycle 5")

template doAsgnRef(dest: PPointer, src: pointer,
                  heapType = LocalHeap, cycleFlag = MaybeCyclic): stmt =
  sysAssert(not isOnStack(dest), "asgnRef")
  # BUGFIX: first incRef then decRef!
  if src != nil: doIncRef(usrToCell(src), heapType, cycleFlag)
  if dest[] != nil: doDecRef(usrToCell(dest[]), heapType, cycleFlag)
  dest[] = src

proc asgnRef(dest: PPointer, src: pointer) {.compilerProc, inline.} =
  # the code generator calls this proc!
  doAsgnRef(dest, src, LocalHeap, MaybeCyclic)

proc asgnRefNoCycle(dest: PPointer, src: pointer) {.compilerProc, inline.} =
  # the code generator calls this proc if it is known at compile time that no 
  # cycle is possible.
  doAsgnRef(dest, src, LocalHeap, Acyclic)

proc unsureAsgnRef(dest: PPointer, src: pointer) {.compilerProc.} =
  # unsureAsgnRef updates the reference counters only if dest is not on the
  # stack. It is used by the code generator if it cannot decide wether a
  # reference is in the stack or not (this can happen for var parameters).
  if not isOnStack(dest):
    if src != nil: doIncRef(usrToCell(src))
    # XXX we must detect a shared heap here
    # better idea may be to just eliminate the need for unsureAsgnRef
    #
    # XXX finally use assembler for the stack checking instead!
    # the test for '!= nil' is correct, but I got tired of the segfaults
    # resulting from the crappy stack checking:
    if cast[int](dest[]) >=% PageSize: doDecRef(usrToCell(dest[]))
  else:
    # can't be an interior pointer if it's a stack location!
    sysAssert(interiorAllocatedPtr(gch.region, dest)==nil,
              "stack loc AND interior pointer")
  dest[] = src

when hasThreadSupport and hasSharedHeap:
  # shared heap version of the above procs
  proc asgnRefSh(dest: PPointer, src: pointer) {.compilerProc, inline.} =
    doAsgnRef(dest, src, SharedHeap, MaybeCyclic)

  proc asgnRefNoCycleSh(dest: PPointer, src: pointer) {.compilerProc, inline.} =
    doAsgnRef(dest, src, SharedHeap, Acyclic)

proc initGC() =
  when not defined(useNimRtl):
    when traceGC:
      for i in low(TCellState)..high(TCellState): init(states[i])
    gch.cycleThreshold = InitialCycleThreshold
    gch.stat.stackScans = 0
    gch.stat.cycleCollections = 0
    gch.stat.maxThreshold = 0
    gch.stat.maxStackSize = 0
    gch.stat.maxStackCells = 0
    gch.stat.cycleTableSize = 0
    # init the rt
    init(gch.zct)
    init(gch.tempStack)
    init(gch.freeStack)
    init(gch.cycleRoots)
    init(gch.decStack)

proc forAllSlotsAux(dest: pointer, n: ptr TNimNode, op: TWalkOp) =
  var d = cast[ByteAddress](dest)
  case n.kind
  of nkSlot: forAllChildrenAux(cast[pointer](d +% n.offset), n.typ, op)
  of nkList:
    for i in 0..n.len-1:
      # inlined for speed
      if n.sons[i].kind == nkSlot:
        if n.sons[i].typ.kind in {tyRef, tyString, tySequence}:
          doOperation(cast[PPointer](d +% n.sons[i].offset)[], op)
        else:
          forAllChildrenAux(cast[pointer](d +% n.sons[i].offset), 
                            n.sons[i].typ, op)
      else:
        forAllSlotsAux(dest, n.sons[i], op)
  of nkCase:
    var m = selectBranch(dest, n)
    if m != nil: forAllSlotsAux(dest, m, op)
  of nkNone: sysAssert(false, "forAllSlotsAux")

proc forAllChildrenAux(dest: pointer, mt: PNimType, op: TWalkOp) =
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

proc forAllChildren(cell: PCell, op: TWalkOp) =
  sysAssert(cell != nil, "forAllChildren: 1")
  sysAssert(cell.typ != nil, "forAllChildren: 2")
  sysAssert cell.typ.kind in {tyRef, tySequence, tyString}, "forAllChildren: 3"
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
        let baseAddr = d +% GenericSeqSize
        for i in 0..s.len-1:
          forAllChildrenAux(cast[pointer](baseAddr +% i *% cell.typ.base.size),
                            cell.typ.base, op)
    else: discard

proc addNewObjToZCT(res: PCell, gch: var TGcHeap) {.inline.} =
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
        c.clearBit(rcZct)
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
        c.clearBit(rcZct)
        d[i] = res
        return
    add(gch.zct, res)

proc rawNewObj(typ: PNimType, size: int, gch: var TGcHeap, rc1 = false): pointer =
  # generates a new object and sets its reference counter to 0
  acquire(gch)
  sysAssert(allocInv(gch.region), "rawNewObj begin")
  sysAssert(typ.kind in {tyRef, tyString, tySequence}, "newObj: 1")
  
  collectCT(gch)
  sysAssert(allocInv(gch.region), "rawNewObj after collect")

  var res = cast[PCell](rawAlloc(gch.region, size + sizeof(TCell)))
  sysAssert(allocInv(gch.region), "rawNewObj after rawAlloc")

  sysAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "newObj: 2")
  
  res.typ = typ
  
  when trackAllocationSource and not hasThreadSupport:
    if framePtr != nil and framePtr.prev != nil and framePtr.prev.prev != nil:
      res.filename = framePtr.prev.prev.filename
      res.line = framePtr.prev.prev.line
    else:
      res.filename = "nofile"
  
  if rc1:
    res.refcount = rcIncrement # refcount is 1
  else:
    # its refcount is zero, so add it to the ZCT:
    res.refcount = rcZct
    addNewObjToZCT(res, gch)

    if NewObjectsAreCycleRoots and canBeCycleRoot(res):
      res.setBit(rcInCycleRoots)
      res.setColor rcCycleCandidate
      gch.cycleRoots.add res
    
  sysAssert(isAllocatedPtr(gch.region, res), "newObj: 3")
  
  when logGC: writeCell("new cell", res)
  gcTrace(res, csAllocated)
  release(gch)
  result = cellToUsr(res)
  sysAssert(allocInv(gch.region), "rawNewObj end")

{.pop.}

proc freeCell(gch: var TGcHeap, c: PCell) =
  # prepareDealloc(c)
  gcTrace(c, csFreed)

  when reallyDealloc: rawDealloc(gch.region, c)
  else:
    sysAssert(c.typ != nil, "collectCycles")
    zeroMem(c, sizeof(TCell))

template eraseAt(cells: var TCellSeq, at: int): stmt =
  cells.d[at] = cells.d[cells.len - 1]
  dec cells.len

template trimAt(roots: var TCellSeq, at: int): stmt =
  # This will remove a cycle root candidate during trimming.
  # a candidate is removed either because it received a refup and
  # it's no longer a candidate or because it received further refdowns
  # and now it's dead for sure.
  let c = roots.d[at]
  c.clearBit(rcInCycleRoots)
  roots.eraseAt(at)
  if c.isBitUp(rcReallyDead) and c.refcount <% rcIncrement:
    # This case covers both dead objects and retired buffers
    # That's why we must also check the refcount (it may be
    # kept possitive by stack references).
    freeCell(gch, c)

proc newObj(typ: PNimType, size: int): pointer {.compilerRtl.} =
  setStackTop(gch)
  result = rawNewObj(typ, size, gch, false)
  zeroMem(result, size)
  when defined(memProfiler): nimProfile(size)

proc newObjNoInit(typ: PNimType, size: int): pointer {.compilerRtl.} =
  setStackTop(gch)
  result = rawNewObj(typ, size, gch, false)
  when defined(memProfiler): nimProfile(size)

proc newSeq(typ: PNimType, len: int): pointer {.compilerRtl.} =
  setStackTop(gch)
  # `newObj` already uses locks, so no need for them here.
  let size = addInt(mulInt(len, typ.base.size), GenericSeqSize)
  result = newObj(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len

proc newObjRC1(typ: PNimType, size: int): pointer {.compilerRtl.} =
  setStackTop(gch)
  result = rawNewObj(typ, size, gch, true)
  when defined(memProfiler): nimProfile(size)

proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =
  setStackTop(gch)
  let size = addInt(mulInt(len, typ.base.size), GenericSeqSize)
  result = newObjRC1(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len

proc growObj(old: pointer, newsize: int, gch: var TGcHeap): pointer =
  acquire(gch)
  collectCT(gch)
  var ol = usrToCell(old)
  sysAssert(ol.typ != nil, "growObj: 1")
  sysAssert(ol.typ.kind in {tyString, tySequence}, "growObj: 2")
  sysAssert(allocInv(gch.region), "growObj begin")

  var res = cast[PCell](rawAlloc(gch.region, newsize + sizeof(TCell)))
  var elemSize = if ol.typ.kind != tyString: ol.typ.base.size
                 else: 1
  
  var oldsize = cast[PGenericSeq](old).len*elemSize + GenericSeqSize
  
  # XXX: This should happen outside
  # call user-defined move code
  # call user-defined default constructor
  copyMem(res, ol, oldsize + sizeof(TCell))
  zeroMem(cast[pointer](cast[ByteAddress](res)+% oldsize +% sizeof(TCell)),
          newsize-oldsize)

  sysAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "growObj: 3")
  sysAssert(res.refcount shr rcShift <=% 1, "growObj: 4")
  
  when false:
    if ol.isBitUp(rcZct):
      var j = gch.zct.len-1
      var d = gch.zct.d
      while j >= 0: 
        if d[j] == ol:
          d[j] = res
          break
        dec(j)
    
    if ol.isBitUp(rcInCycleRoots):
      for i in 0 .. <gch.cycleRoots.len:
        if gch.cycleRoots.d[i] == ol:
          eraseAt(gch.cycleRoots, i)

    freeCell(gch, ol)
  
  else:
    # the new buffer inherits the GC state of the old one
    if res.isBitUp(rcZct): gch.zct.add res
    if res.isBitUp(rcInCycleRoots): gch.cycleRoots.add res

    # Pay attention to what's going on here! We're not releasing the old memory.
    # This is because at this point there may be an interior pointer pointing
    # into this buffer somewhere on the stack (due to `var` parameters now and
    # and `let` and `var:var` stack locations in the future).
    # We'll release the memory in the next GC cycle. If we release it here,
    # we cannot guarantee that no memory will be corrupted when only safe
    # language features are used. Accessing the memory after the seq/string
    # has been invalidated may still result in logic errors in the user code.
    # We may improve on that by protecting the page in debug builds or
    # by providing a warning when we detect a stack pointer into it.
    let bufferFlags = ol.refcount and rcBufferedAnywhere
    if bufferFlags == 0:
      # we need this in order to collect it safely later
      ol.refcount = rcRetiredBuffer or rcZct
      gch.zct.add ol
    else:
      ol.refcount = rcRetiredBuffer or bufferFlags

    when logGC:
      writeCell("growObj old cell", ol)
      writeCell("growObj new cell", res)

  gcTrace(res, csAllocated)
  release(gch)
  result = cellToUsr(res)
  sysAssert(allocInv(gch.region), "growObj end")
  when defined(memProfiler): nimProfile(newsize-oldsize)

proc growObj(old: pointer, newsize: int): pointer {.rtl.} =
  setStackTop(gch)
  result = growObj(old, newsize, gch)

{.push profiler:off.}

# ---------------- cycle collector -------------------------------------------

proc doOperation(p: pointer, op: TWalkOp) =
  if p == nil: return
  var c: PCell = usrToCell(p)
  sysAssert(c != nil, "doOperation: 1")
  gch.tempStack.add c
  
proc nimGCvisit(d: pointer, op: int) {.compilerRtl.} =
  doOperation(d, TWalkOp(op))

type
  TRecursionType = enum 
    FromChildren,
    FromRoot

proc collectZCT(gch: var TGcHeap): bool

template pseudoRecursion(typ: TRecursionType, body: stmt): stmt =
  discard

proc trimCycleRoots(gch: var TGcHeap, startIdx = gch.cycleRootsTrimIdx) =
  var i = startIdx
  while i < gch.cycleRoots.len:
    if gch.cycleRoots.d[i].color != rcCycleCandidate:
      gch.cycleRoots.trimAt i
    else:
      inc i

  gch.cycleRootsTrimIdx = gch.cycleRoots.len

# we now use a much simpler and non-recursive algorithm for cycle removal
proc collectCycles(gch: var TGcHeap) =
  if gch.cycleRoots.len == 0: return
  gch.stat.cycleTableSize = max(gch.stat.cycleTableSize, gch.cycleRoots.len)

  when CollectCyclesStats:
    let l0 = gch.cycleRoots.len
    let tStart = getTicks()

  var
    decrefs = 0
    increfs = 0
    collected = 0
    maybedeads = 0

  template ignoreObject(c: PCell): expr =
    # This controls which objects will be ignored in the mark and scan stages
    (when MarkingSkipsAcyclicObjects: not canbeCycleRoot(c) else: false)
    # not canbeCycleRoot(c)
    # false
    # c.isBitUp(rcHasStackRef)

  template earlyMarkAliveRec(cell) =
    let startLen = gch.tempStack.len
    cell.setColor rcAlive
    cell.forAllChildren waPush
    
    while startLen != gch.tempStack.len:
      dec gch.tempStack.len
      var c = gch.tempStack.d[gch.tempStack.len]
      if c.color != rcAlive:
        c.setColor rcAlive
        c.forAllChildren waPush
  
  template earlyMarkAlive(stackRoots) =
    # This marks all objects reachable from the stack as alive before any
    # of the other stages is executed. Such objects cannot be garbage and
    # they don't need to participate in the recursive decref/incref.
    for i in 0 .. <stackRoots.len:
      var c = stackRoots.d[i]
      # c.setBit rcHasStackRef
      earlyMarkAliveRec(c)

  earlyMarkAlive(gch.decStack)
  
  when CollectCyclesStats:
    let tAfterEarlyMarkAlive = getTicks()

  template recursiveDecRef(cell) =
    let startLen = gch.tempStack.len
    cell.setColor rcDecRefApplied
    cell.forAllChildren waPush
    
    while startLen != gch.tempStack.len:
      dec gch.tempStack.len
      var c = gch.tempStack.d[gch.tempStack.len]
      if ignoreObject(c): continue

      sysAssert(c.refcount >=% rcIncrement, "recursive dec ref")
      dec c.refcount, rcIncrement
      inc decrefs
      if c.color != rcDecRefApplied:
        c.setColor rcDecRefApplied
        c.forAllChildren waPush
 
  template markRoots(roots) =
    var i = 0
    while i < roots.len:
      if roots.d[i].color == rcCycleCandidate:
        recursiveDecRef(roots.d[i])
        inc i
      else:
        roots.trimAt i
  
  markRoots(gch.cycleRoots)
  
  when CollectCyclesStats:
    let tAfterMark = getTicks()
    c_printf "COLLECT CYCLES %d: %d/%d\n", gcCollectionIdx, gch.cycleRoots.len, l0
  
  template recursiveMarkAlive(cell) =
    let startLen = gch.tempStack.len
    cell.setColor rcAlive
    cell.forAllChildren waPush
    
    while startLen != gch.tempStack.len:
      dec gch.tempStack.len
      var c = gch.tempStack.d[gch.tempStack.len]
      if ignoreObject(c): continue
      inc c.refcount, rcIncrement
      inc increfs
      
      if c.color != rcAlive:
        c.setColor rcAlive
        c.forAllChildren waPush
 
  template scanRoots(roots) =
    for i in 0 .. <roots.len:
      let startLen = gch.tempStack.len
      gch.tempStack.add roots.d[i]
      
      while startLen != gch.tempStack.len:
        dec gch.tempStack.len
        var c = gch.tempStack.d[gch.tempStack.len]
        if ignoreObject(c): continue
        if c.color == rcDecRefApplied:
          if c.refcount >=% rcIncrement:
            recursiveMarkAlive(c)
          else:
            # note that this is not necessarily the ultimate
            # destiny of the object. we may still mark it alive
            # later if we encounter another node from where it's
            # reachable.
            c.setColor rcMaybeDead
            inc maybedeads
            c.forAllChildren waPush
  
  scanRoots(gch.cycleRoots)
  
  when CollectCyclesStats:
    let tAfterScan = getTicks()

  template collectDead(roots) =
    for i in 0 .. <roots.len:
      var c = roots.d[i]
      c.clearBit(rcInCycleRoots)

      let startLen = gch.tempStack.len
      gch.tempStack.add c
      
      while startLen != gch.tempStack.len:
        dec gch.tempStack.len
        var c = gch.tempStack.d[gch.tempStack.len]
        when MarkingSkipsAcyclicObjects:
          if not canbeCycleRoot(c):
            # This is an acyclic object reachable from a dead cyclic object
            # We must do a normal decref here that may add the acyclic object
            # to the ZCT
            doDecRef(c, LocalHeap, Cyclic)
            continue
        if c.color == rcMaybeDead and not c.isBitUp(rcInCycleRoots):
          c.setColor(rcReallyDead)
          inc collected
          c.forAllChildren waPush
          # we need to postpone the actual deallocation in order to allow
          # the finalizers to run while the data structures are still intact
          gch.freeStack.add c
          prepareDealloc(c)

    for i in 0 .. <gch.freeStack.len:
      freeCell(gch, gch.freeStack.d[i])

  collectDead(gch.cycleRoots)
  
  when CollectCyclesStats:
    let tFinal = getTicks()
    cprintf "times:\n  early mark alive: %d ms\n  mark: %d ms\n  scan: %d ms\n  collect: %d ms\n  decrefs: %d\n  increfs: %d\n  marked dead: %d\n  collected: %d\n",
      (tAfterEarlyMarkAlive - tStart)  div 1_000_000,
      (tAfterMark - tAfterEarlyMarkAlive) div 1_000_000,
      (tAfterScan - tAfterMark) div 1_000_000,
      (tFinal - tAfterScan) div 1_000_000,
      decrefs,
      increfs,
      maybedeads,
      collected

  deinit(gch.cycleRoots)
  init(gch.cycleRoots)

  deinit(gch.freeStack)
  init(gch.freeStack)

  when MarkingSkipsAcyclicObjects:
    # Collect the acyclic objects that became unreachable due to collected
    # cyclic objects. 
    discard collectZCT(gch)
    # collectZCT may add new cycle candidates and we may decide to loop here
    # if gch.cycleRoots.len > 0: repeat

var gcDebugging* = false

var seqdbg* : proc (s: PGenericSeq) {.cdecl.}

proc gcMark(gch: var TGcHeap, p: pointer) {.inline.} =
  # the addresses are not as cells on the stack, so turn them to cells:
  sysAssert(allocInv(gch.region), "gcMark begin")
  var cell = usrToCell(p)
  var c = cast[ByteAddress](cell)
  if c >% PageSize:
    # fast check: does it look like a cell?
    var objStart = cast[PCell](interiorAllocatedPtr(gch.region, cell))
    if objStart != nil:
      # mark the cell:
      if objStart.color != rcReallyDead:
        if gcDebugging:
          # writeCell("marking ", objStart)
          discard
        else:
          inc objStart.refcount, rcIncrement
          gch.decStack.add objStart
      else:
        # With incremental clean-up, objects spend some time
        # in various lists before being deallocated.
        # We just found a reference on the stack to an object,
        # which we have previously labeled as unreachable.
        # This is either a bug in the GC or a pure accidental
        # coincidence due to the conservative stack marking.
        when debugGC:
          # writeCell("marking dead object", objStart)
          discard
    when false:
      if isAllocatedPtr(gch.region, cell):
        sysAssert false, "allocated pointer but not interior?"
        # mark the cell:
        inc cell.refcount, rcIncrement
        add(gch.decStack, cell)
  sysAssert(allocInv(gch.region), "gcMark end")

proc markThreadStacks(gch: var TGcHeap) = 
  when hasThreadSupport and hasSharedHeap:
    {.error: "not fully implemented".}
    var it = threadList
    while it != nil:
      # mark registers: 
      for i in 0 .. high(it.registers): gcMark(gch, it.registers[i])
      var sp = cast[ByteAddress](it.stackBottom)
      var max = cast[ByteAddress](it.stackTop)
      # XXX stack direction?
      # XXX unroll this loop:
      while sp <=% max:
        gcMark(gch, cast[PPointer](sp)[])
        sp = sp +% sizeof(pointer)
      it = it.next

# ----------------- stack management --------------------------------------
#  inspired from Smart Eiffel

when defined(sparc):
  const stackIncreases = false
elif defined(hppa) or defined(hp9000) or defined(hp9000s300) or
     defined(hp9000s700) or defined(hp9000s800) or defined(hp9000s820):
  const stackIncreases = true
else:
  const stackIncreases = false

when not defined(useNimRtl):
  {.push stack_trace: off.}
  proc setStackBottom(theStackBottom: pointer) =
    #c_fprintf(c_stdout, "stack bottom: %p;\n", theStackBottom)
    # the first init must be the one that defines the stack bottom:
    if gch.stackBottom == nil: gch.stackBottom = theStackBottom
    else:
      var a = cast[ByteAddress](theStackBottom) # and not PageMask - PageSize*2
      var b = cast[ByteAddress](gch.stackBottom)
      #c_fprintf(c_stdout, "old: %p new: %p;\n",gch.stackBottom,theStackBottom)
      when stackIncreases:
        gch.stackBottom = cast[pointer](min(a, b))
      else:
        gch.stackBottom = cast[pointer](max(a, b))
  {.pop.}

proc stackSize(): int {.noinline.} =
  var stackTop {.volatile.}: pointer
  result = abs(cast[int](addr(stackTop)) - cast[int](gch.stackBottom))

var
  jmpbufSize {.importc: "sizeof(jmp_buf)", nodecl.}: int
    # a little hack to get the size of a TJmpBuf in the generated C code
    # in a platform independent way

when defined(sparc): # For SPARC architecture.
  proc isOnStack(p: pointer): bool =
    var stackTop {.volatile.}: pointer
    stackTop = addr(stackTop)
    var b = cast[ByteAddress](gch.stackBottom)
    var a = cast[ByteAddress](stackTop)
    var x = cast[ByteAddress](p)
    result = a <=% x and x <=% b

  proc markStackAndRegisters(gch: var TGcHeap) {.noinline, cdecl.} =
    when defined(sparcv9):
      asm  """"flushw \n" """
    else:
      asm  """"ta      0x3   ! ST_FLUSH_WINDOWS\n" """

    var
      max = gch.stackBottom
      sp: PPointer
      stackTop: array[0..1, pointer]
    sp = addr(stackTop[0])
    # Addresses decrease as the stack grows.
    while sp <= max:
      gcMark(gch, sp[])
      sp = cast[PPointer](cast[ByteAddress](sp) +% sizeof(pointer))

elif defined(ELATE):
  {.error: "stack marking code is to be written for this architecture".}

elif stackIncreases:
  # ---------------------------------------------------------------------------
  # Generic code for architectures where addresses increase as the stack grows.
  # ---------------------------------------------------------------------------
  proc isOnStack(p: pointer): bool =
    var stackTop {.volatile.}: pointer
    stackTop = addr(stackTop)
    var a = cast[ByteAddress](gch.stackBottom)
    var b = cast[ByteAddress](stackTop)
    var x = cast[ByteAddress](p)
    result = a <=% x and x <=% b
  
  proc markStackAndRegisters(gch: var TGcHeap) {.noinline, cdecl.} =
    var registers: C_JmpBuf
    if c_setjmp(registers) == 0'i32: # To fill the C stack with registers.
      var max = cast[ByteAddress](gch.stackBottom)
      var sp = cast[ByteAddress](addr(registers)) +% jmpbufSize -% sizeof(pointer)
      # sp will traverse the JMP_BUF as well (jmp_buf size is added,
      # otherwise sp would be below the registers structure).
      while sp >=% max:
        gcMark(gch, cast[PPointer](sp)[])
        sp = sp -% sizeof(pointer)

else:
  # ---------------------------------------------------------------------------
  # Generic code for architectures where addresses decrease as the stack grows.
  # ---------------------------------------------------------------------------
  proc isOnStack(p: pointer): bool =
    var stackTop {.volatile.}: pointer
    stackTop = addr(stackTop)
    var b = cast[ByteAddress](gch.stackBottom)
    var a = cast[ByteAddress](stackTop)
    var x = cast[ByteAddress](p)
    result = a <=% x and x <=% b

  proc markStackAndRegisters(gch: var TGcHeap) {.noinline, cdecl.} =
    # We use a jmp_buf buffer that is in the C stack.
    # Used to traverse the stack and registers assuming
    # that 'setjmp' will save registers in the C stack.
    type PStackSlice = ptr array [0..7, pointer]
    var registers: C_JmpBuf
    if c_setjmp(registers) == 0'i32: # To fill the C stack with registers.
      when MinimumStackMarking:
        # mark the registers
        var jmpbufPtr = cast[ByteAddress](addr(registers))
        var jmpbufEnd = jmpbufPtr +% jmpbufSize
      
        while jmpbufPtr <=% jmpbufEnd:
          gcMark(gch, cast[PPointer](jmpbufPtr)[])
          jmpbufPtr = jmpbufPtr +% sizeof(pointer)

        var sp = cast[ByteAddress](gch.stackTop)
      else:
        var sp = cast[ByteAddress](addr(registers))
      # mark the user stack
      var max = cast[ByteAddress](gch.stackBottom)
      # loop unrolled:
      while sp <% max - 8*sizeof(pointer):
        gcMark(gch, cast[PStackSlice](sp)[0])
        gcMark(gch, cast[PStackSlice](sp)[1])
        gcMark(gch, cast[PStackSlice](sp)[2])
        gcMark(gch, cast[PStackSlice](sp)[3])
        gcMark(gch, cast[PStackSlice](sp)[4])
        gcMark(gch, cast[PStackSlice](sp)[5])
        gcMark(gch, cast[PStackSlice](sp)[6])
        gcMark(gch, cast[PStackSlice](sp)[7])
        sp = sp +% sizeof(pointer)*8
      # last few entries:
      while sp <=% max:
        gcMark(gch, cast[PPointer](sp)[])
        sp = sp +% sizeof(pointer)

# ----------------------------------------------------------------------------
# end of non-portable code
# ----------------------------------------------------------------------------

proc releaseCell(gch: var TGcHeap, cell: PCell) =
  if cell.color != rcReallyDead:
    prepareDealloc(cell)
    cell.setColor rcReallyDead

    let l1 = gch.tempStack.len
    cell.forAllChildren waPush
    let l2 = gch.tempStack.len
    for i in l1 .. <l2:
      var cc = gch.tempStack.d[i]
      if cc.refcount--(LocalHeap):
        releaseCell(gch, cc)
      else:
        if canbeCycleRoot(cc):
          addCycleRoot(gch.cycleRoots, cc)

    gch.tempStack.len = l1

  if cell.isBitDown(rcBufferedAnywhere):
    freeCell(gch, cell)
  # else:
  # This object is either buffered in the cycleRoots list and we'll leave
  # it there to be collected in the next collectCycles or it's pending in
  # the ZCT:
  # (e.g. we are now cleaning the 15th object, but this one is 18th in the
  #  list. Note that this can happen only if we reached this point by the
  #  recursion).
  # We can ignore it now as the ZCT cleaner will reach it soon.

proc collectZCT(gch: var TGcHeap): bool =
  const workPackage = 100
  var L = addr(gch.zct.len)
  
  when withRealtime:
    var steps = workPackage
    var t0: TTicks
    if gch.maxPause > 0: t0 = getticks()
  
  while L[] > 0:
    var c = gch.zct.d[0]
    sysAssert c.isBitUp(rcZct), "collectZCT: rcZct missing!"
    sysAssert(isAllocatedPtr(gch.region, c), "collectZCT: isAllocatedPtr")
    
    # remove from ZCT:    
    c.clearBit(rcZct)
    gch.zct.d[0] = gch.zct.d[L[] - 1]
    dec(L[])
    when withRealtime: dec steps
    if c.refcount <% rcIncrement:
      # It may have a RC > 0, if it is in the hardware stack or
      # it has not been removed yet from the ZCT. This is because
      # ``incref`` does not bother to remove the cell from the ZCT 
      # as this might be too slow.
      # In any case, it should be removed from the ZCT. But not
      # freed. **KEEP THIS IN MIND WHEN MAKING THIS INCREMENTAL!**
      if c.color == rcRetiredBuffer:
        if c.isBitDown(rcInCycleRoots):
          freeCell(gch, c)
      else:
        # if c.color == rcReallyDead: writeCell("ReallyDead in ZCT?", c)
        releaseCell(gch, c)
    when withRealtime:
      if steps == 0:
        steps = workPackage
        if gch.maxPause > 0:
          let duration = getticks() - t0
          # the GC's measuring is not accurate and needs some cleanup actions 
          # (stack unmarking), so subtract some short amount of time in to
          # order to miss deadlines less often:
          if duration >= gch.maxPause - 50_000:
            return false
  result = true
  gch.trimCycleRoots
  #deInit(gch.zct)
  #init(gch.zct)

proc unmarkStackAndRegisters(gch: var TGcHeap) =
  var d = gch.decStack.d
  for i in 0 .. <gch.decStack.len:
    sysAssert isAllocatedPtr(gch.region, d[i]), "unmarkStackAndRegisters"
    # XXX: just call doDecRef?
    var c = d[i]
    sysAssert c.typ != nil, "unmarkStackAndRegisters 2"
    
    if c.color == rcRetiredBuffer:
      continue

    # XXX no need for an atomic dec here:
    if c.refcount--(LocalHeap):
      # the object survived only because of a stack reference
      # it still doesn't have heap references
      addZCT(gch.zct, c)
    
    if canbeCycleRoot(c):
      # any cyclic object reachable from the stack can be turned into
      # a leak if it's orphaned through the stack reference
      # that's because the write-barrier won't be executed for stack
      # locations
      addCycleRoot(gch.cycleRoots, c)

  gch.decStack.len = 0

proc collectCTBody(gch: var TGcHeap) =
  when withRealtime:
    let t0 = getticks()
  when debugGC: inc gcCollectionIdx
  sysAssert(allocInv(gch.region), "collectCT: begin")
  
  gch.stat.maxStackSize = max(gch.stat.maxStackSize, stackSize())
  sysAssert(gch.decStack.len == 0, "collectCT")
  prepareForInteriorPointerChecking(gch.region)
  markStackAndRegisters(gch)
  markThreadStacks(gch)
  gch.stat.maxStackCells = max(gch.stat.maxStackCells, gch.decStack.len)
  inc(gch.stat.stackScans)
  if collectZCT(gch):
    when cycleGC:
      if getOccupiedMem(gch.region) >= gch.cycleThreshold or alwaysCycleGC:
        collectCycles(gch)
        sysAssert gch.zct.len == 0, "zct is not null after collect cycles"
        inc(gch.stat.cycleCollections)
        gch.cycleThreshold = max(InitialCycleThreshold, getOccupiedMem() *
                                 CycleIncrease)
        gch.stat.maxThreshold = max(gch.stat.maxThreshold, gch.cycleThreshold)
  unmarkStackAndRegisters(gch)
  sysAssert(allocInv(gch.region), "collectCT: end")
  
  when withRealtime:
    let duration = getticks() - t0
    gch.stat.maxPause = max(gch.stat.maxPause, duration)
    when defined(reportMissedDeadlines):
      if gch.maxPause > 0 and duration > gch.maxPause:
        c_fprintf(c_stdout, "[GC] missed deadline: %ld\n", duration)

proc collectCT(gch: var TGcHeap) =
  if (gch.zct.len >= ZctThreshold or (cycleGC and
      getOccupiedMem(gch.region)>=gch.cycleThreshold) or alwaysGC) and 
      gch.recGcLock == 0:
    collectCTBody(gch)

when withRealtime:
  proc toNano(x: int): TNanos {.inline.} =
    result = x * 1000

  proc GC_setMaxPause*(MaxPauseInUs: int) =
    gch.maxPause = MaxPauseInUs.toNano

  proc GC_step(gch: var TGcHeap, us: int, strongAdvice: bool) =
    acquire(gch)
    gch.maxPause = us.toNano
    if (gch.zct.len >= ZctThreshold or (cycleGC and
        getOccupiedMem(gch.region)>=gch.cycleThreshold) or alwaysGC) or 
        strongAdvice:
      collectCTBody(gch)
    release(gch)

  proc GC_step*(us: int, strongAdvice = false) = GC_step(gch, us, strongAdvice)

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
    case strategy
    of gcThroughput: discard
    of gcResponsiveness: discard
    of gcOptimizeSpace: discard
    of gcOptimizeTime: discard

  proc GC_enableMarkAndSweep() =
    gch.cycleThreshold = InitialCycleThreshold

  proc GC_disableMarkAndSweep() =
    gch.cycleThreshold = high(gch.cycleThreshold)-1
    # set to the max value to suppress the cycle detector

  proc GC_fullCollect() =
    setStackTop(gch)
    acquire(gch)
    var oldThreshold = gch.cycleThreshold
    gch.cycleThreshold = 0 # forces cycle collection
    collectCT(gch)
    gch.cycleThreshold = oldThreshold
    release(gch)

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
             "[GC] max stack size: " & $gch.stat.maxStackSize & "\n" &
             "[GC] max pause time [ms]: " & $(gch.stat.maxPause div 1000_000)
    when traceGC: writeLeakage(true)
    GC_enable()

{.pop.}
