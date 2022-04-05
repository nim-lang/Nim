#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

#            Garbage Collector
#
# Refcounting + Mark&Sweep. Complex algorithms avoided.
# Been there, done that, didn't work.

#[

A *cell* is anything that is traced by the GC
(sequences, refs, strings, closures).

The basic algorithm is *Deferrent Reference Counting* with cycle detection.
References on the stack are not counted for better performance and easier C
code generation.

Each cell has a header consisting of a RC and a pointer to its type
descriptor. However the program does not know about these, so they are placed at
negative offsets. In the GC code the type `PCell` denotes a pointer
decremented by the right offset, so that the header can be accessed easily. It
is extremely important that `pointer` is not confused with a `PCell`.

In Nim the compiler cannot always know if a reference
is stored on the stack or not. This is caused by var parameters.
Consider this example:

.. code-block:: Nim
  proc setRef(r: var ref TNode) =
    new(r)

  proc usage =
    var
      r: ref TNode
    setRef(r) # here we should not update the reference counts, because
              # r is on the stack
    setRef(r.left) # here we should update the refcounts!

We have to decide at runtime whether the reference is on the stack or not.
The generated code looks roughly like this:

.. code-block:: C
  void setref(TNode** ref) {
    unsureAsgnRef(ref, newObj(TNode_TI, sizeof(TNode)))
  }
  void usage(void) {
    setRef(&r)
    setRef(&r->left)
  }

Note that for systems with a continuous stack (which most systems have)
the check whether the ref is on the stack is very cheap (only two
comparisons).
]#

{.push profiler:off.}

const
  CycleIncrease = 2 # is a multiplicative increase
  InitialCycleThreshold = when defined(nimCycleBreaker): high(int)
                          else: 4*1024*1024 # X MB because cycle checking is slow
  InitialZctThreshold = 500  # we collect garbage if the ZCT's size
                             # reaches this threshold
                             # this seems to be a good value
  withRealTime = defined(useRealtimeGC)

when withRealTime and not declared(getTicks):
  include "system/timers"
when defined(memProfiler):
  proc nimProfile(requestedSize: int) {.benign.}

when hasThreadSupport:
  import sharedlist

const
  rcIncrement = 0b1000 # so that lowest 3 bits are not touched
  rcBlack = 0b000  # cell is colored black; in use or free
  rcGray = 0b001   # possible member of a cycle
  rcWhite = 0b010  # member of a garbage cycle
  rcPurple = 0b011 # possible root of a cycle
  ZctFlag = 0b100  # in ZCT
  rcShift = 3      # shift by rcShift to get the reference counter
  colorMask = 0b011
type
  WalkOp = enum
    waMarkGlobal,    # part of the backup/debug mark&sweep
    waMarkPrecise,   # part of the backup/debug mark&sweep
    waZctDecRef, waPush
    #, waDebug

  Finalizer {.compilerproc.} = proc (self: pointer) {.nimcall, benign, raises: [].}
    # A ref type can have a finalizer that is called before the object's
    # storage is freed.

  GcStat {.final, pure.} = object
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

  GcHeap {.final, pure.} = object # this contains the zero count and
                                  # non-zero count table
    stack: GcStack
    when nimCoroutines:
      activeStack: ptr GcStack    # current executing coroutine stack.
    cycleThreshold: int
    zctThreshold: int
    when useCellIds:
      idGenerator: int
    zct: CellSeq             # the zero count table
    decStack: CellSeq        # cells in the stack that are to decref again
    tempStack: CellSeq       # temporary stack for recursion elimination
    recGcLock: int           # prevent recursion via finalizers; no thread lock
    when withRealTime:
      maxPause: Nanos        # max allowed pause in nanoseconds; active if > 0
    region: MemRegion        # garbage collected region
    stat: GcStat
    marked: CellSet
    additionalRoots: CellSeq # dummy roots for GC_ref/unref
    when hasThreadSupport:
      toDispose: SharedList[pointer]
    gcThreadId: int

var
  gch {.rtlThreadVar.}: GcHeap

when not defined(useNimRtl):
  instantiateForRegion(gch.region)

template gcAssert(cond: bool, msg: string) =
  when defined(useGcAssert):
    if not cond:
      cstderr.rawWrite "[GCASSERT] "
      cstderr.rawWrite msg
      when defined(logGC):
        cstderr.rawWrite "[GCASSERT] statistics:\L"
        cstderr.rawWrite GC_getStatistics()
      GC_disable()
      writeStackTrace()
      #var x: ptr int
      #echo x[]
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

proc extGetCellType(c: pointer): PNimType {.compilerproc.} =
  # used for code generation concerning debugging
  result = usrToCell(c).typ

proc internRefcount(p: pointer): int {.exportc: "getRefcount".} =
  result = usrToCell(p).refcount shr rcShift

# this that has to equals zero, otherwise we have to round up UnitsPerPage:
when BitsPerPage mod (sizeof(int)*8) != 0:
  {.error: "(BitsPerPage mod BitsPerUnit) should be zero!".}

template color(c): untyped = c.refCount and colorMask
template setColor(c, col) =
  when col == rcBlack:
    c.refcount = c.refcount and not colorMask
  else:
    c.refcount = c.refcount and not colorMask or col

when defined(logGC):
  proc writeCell(msg: cstring, c: PCell) =
    var kind = -1
    var typName: cstring = "nil"
    if c.typ != nil:
      kind = ord(c.typ.kind)
      when defined(nimTypeNames):
        if not c.typ.name.isNil:
          typName = c.typ.name

    when leakDetector:
      c_printf("[GC] %s: %p %d %s rc=%ld from %s(%ld)\n",
                msg, c, kind, typName, c.refcount shr rcShift, c.filename, c.line)
    else:
      c_printf("[GC] %s: %p %d %s rc=%ld; thread=%ld\n",
                msg, c, kind, typName, c.refcount shr rcShift, gch.gcThreadId)

template logCell(msg: cstring, c: PCell) =
  when defined(logGC):
    writeCell(msg, c)

template gcTrace(cell, state: untyped) =
  when traceGC: traceCell(cell, state)

# forward declarations:
proc collectCT(gch: var GcHeap) {.benign, raises: [].}
proc isOnStack(p: pointer): bool {.noinline, benign, raises: [].}
proc forAllChildren(cell: PCell, op: WalkOp) {.benign, raises: [].}
proc doOperation(p: pointer, op: WalkOp) {.benign, raises: [].}
proc forAllChildrenAux(dest: pointer, mt: PNimType, op: WalkOp) {.benign, raises: [].}
# we need the prototype here for debugging purposes

proc incRef(c: PCell) {.inline.} =
  gcAssert(isAllocatedPtr(gch.region, c), "incRef: interiorPtr")
  c.refcount = c.refcount +% rcIncrement
  # and not colorMask
  logCell("incRef", c)

proc nimGCref(p: pointer) {.compilerproc.} =
  # we keep it from being collected by pretending it's not even allocated:
  let c = usrToCell(p)
  add(gch.additionalRoots, c)
  incRef(c)

proc rtlAddZCT(c: PCell) {.rtl, inl.} =
  # we MUST access gch as a global here, because this crosses DLL boundaries!
  addZCT(gch.zct, c)

proc decRef(c: PCell) {.inline.} =
  gcAssert(isAllocatedPtr(gch.region, c), "decRef: interiorPtr")
  gcAssert(c.refcount >=% rcIncrement, "decRef")
  c.refcount = c.refcount -% rcIncrement
  if c.refcount <% rcIncrement:
    rtlAddZCT(c)
  logCell("decRef", c)

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
  decRef(usrToCell(p))

include gc_common

template beforeDealloc(gch: var GcHeap; c: PCell; msg: typed) =
  when false:
    for i in 0..gch.decStack.len-1:
      if gch.decStack.d[i] == c:
        sysAssert(false, msg)

proc nimGCunrefNoCycle(p: pointer) {.compilerproc, inline.} =
  sysAssert(allocInv(gch.region), "begin nimGCunrefNoCycle")
  decRef(usrToCell(p))
  sysAssert(allocInv(gch.region), "end nimGCunrefNoCycle 5")

proc nimGCunrefRC1(p: pointer) {.compilerproc, inline.} =
  decRef(usrToCell(p))

proc asgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
  # the code generator calls this proc!
  gcAssert(not isOnStack(dest), "asgnRef")
  # BUGFIX: first incRef then decRef!
  if src != nil: incRef(usrToCell(src))
  if dest[] != nil: decRef(usrToCell(dest[]))
  dest[] = src

proc asgnRefNoCycle(dest: PPointer, src: pointer) {.compilerproc, inline,
  deprecated: "old compiler compat".} = asgnRef(dest, src)

proc unsureAsgnRef(dest: PPointer, src: pointer) {.compilerproc.} =
  # unsureAsgnRef updates the reference counters only if dest is not on the
  # stack. It is used by the code generator if it cannot decide whether a
  # reference is in the stack or not (this can happen for var parameters).
  if not isOnStack(dest):
    if src != nil: incRef(usrToCell(src))
    # XXX finally use assembler for the stack checking instead!
    # the test for '!= nil' is correct, but I got tired of the segfaults
    # resulting from the crappy stack checking:
    if cast[int](dest[]) >=% PageSize: decRef(usrToCell(dest[]))
  else:
    # can't be an interior pointer if it's a stack location!
    gcAssert(interiorAllocatedPtr(gch.region, dest) == nil,
             "stack loc AND interior pointer")
  dest[] = src

proc initGC() =
  when not defined(useNimRtl):
    when traceGC:
      for i in low(CellState)..high(CellState): init(states[i])
    gch.cycleThreshold = InitialCycleThreshold
    gch.zctThreshold = InitialZctThreshold
    gch.stat.stackScans = 0
    gch.stat.cycleCollections = 0
    gch.stat.maxThreshold = 0
    gch.stat.maxStackSize = 0
    gch.stat.maxStackCells = 0
    gch.stat.cycleTableSize = 0
    # init the rt
    init(gch.zct)
    init(gch.tempStack)
    init(gch.decStack)
    init(gch.marked)
    init(gch.additionalRoots)
    when hasThreadSupport:
      init(gch.toDispose)
    gch.gcThreadId = atomicInc(gHeapidGenerator) - 1
    gcAssert(gch.gcThreadId >= 0, "invalid computed thread ID")

proc cellsetReset(s: var CellSet) =
  deinit(s)
  init(s)

{.push stacktrace:off.}

proc forAllSlotsAux(dest: pointer, n: ptr TNimNode, op: WalkOp) {.benign.} =
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
  gcAssert(cell != nil, "forAllChildren: cell is nil")
  gcAssert(isAllocatedPtr(gch.region, cell), "forAllChildren: pointer not part of the heap")
  gcAssert(cell.typ != nil, "forAllChildren: cell.typ is nil")
  gcAssert cell.typ.kind in {tyRef, tySequence, tyString}, "forAllChildren: unknown GC'ed type"
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
    template replaceZctEntry(i: untyped) =
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

template setFrameInfo(c: PCell) =
  when leakDetector:
    if framePtr != nil and framePtr.prev != nil:
      c.filename = framePtr.prev.filename
      c.line = framePtr.prev.line
    else:
      c.filename = nil
      c.line = 0

proc rawNewObj(typ: PNimType, size: int, gch: var GcHeap): pointer =
  # generates a new object and sets its reference counter to 0
  incTypeSize typ, size
  sysAssert(allocInv(gch.region), "rawNewObj begin")
  gcAssert(typ.kind in {tyRef, tyString, tySequence}, "newObj: 1")
  collectCT(gch)
  var res = cast[PCell](rawAlloc(gch.region, size + sizeof(Cell)))
  #gcAssert typ.kind in {tyString, tySequence} or size >= typ.base.size, "size too small"
  gcAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "newObj: 2")
  # now it is buffered in the ZCT
  res.typ = typ
  setFrameInfo(res)
  # refcount is zero, color is black, but mark it to be in the ZCT
  res.refcount = ZctFlag
  sysAssert(isAllocatedPtr(gch.region, res), "newObj: 3")
  # its refcount is zero, so add it to the ZCT:
  addNewObjToZCT(res, gch)
  logCell("new cell", res)
  track("rawNewObj", res, size)
  gcTrace(res, csAllocated)
  when useCellIds:
    inc gch.idGenerator
    res.id = gch.idGenerator * 1000_000 + gch.gcThreadId
  result = cellToUsr(res)
  sysAssert(allocInv(gch.region), "rawNewObj end")

{.pop.} # .stackTrace off
{.pop.} # .profiler off

proc newObjNoInit(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(typ, size, gch)
  when defined(memProfiler): nimProfile(size)

proc newObj(typ: PNimType, size: int): pointer {.compilerRtl, noinline.} =
  result = rawNewObj(typ, size, gch)
  zeroMem(result, size)
  when defined(memProfiler): nimProfile(size)

{.push overflowChecks: on.}
proc newSeq(typ: PNimType, len: int): pointer {.compilerRtl.} =
  # `newObj` already uses locks, so no need for them here.
  let size = align(GenericSeqSize, typ.base.align) + len * typ.base.size
  result = newObj(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len
  when defined(memProfiler): nimProfile(size)
{.pop.}

proc newObjRC1(typ: PNimType, size: int): pointer {.compilerRtl, noinline.} =
  # generates a new object and sets its reference counter to 1
  incTypeSize typ, size
  sysAssert(allocInv(gch.region), "newObjRC1 begin")
  gcAssert(typ.kind in {tyRef, tyString, tySequence}, "newObj: 1")
  collectCT(gch)
  sysAssert(allocInv(gch.region), "newObjRC1 after collectCT")

  var res = cast[PCell](rawAlloc(gch.region, size + sizeof(Cell)))
  sysAssert(allocInv(gch.region), "newObjRC1 after rawAlloc")
  sysAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "newObj: 2")
  # now it is buffered in the ZCT
  res.typ = typ
  setFrameInfo(res)
  res.refcount = rcIncrement # refcount is 1
  sysAssert(isAllocatedPtr(gch.region, res), "newObj: 3")
  logCell("new cell", res)
  track("newObjRC1", res, size)
  gcTrace(res, csAllocated)
  when useCellIds:
    inc gch.idGenerator
    res.id = gch.idGenerator * 1000_000 + gch.gcThreadId
  result = cellToUsr(res)
  zeroMem(result, size)
  sysAssert(allocInv(gch.region), "newObjRC1 end")
  when defined(memProfiler): nimProfile(size)

{.push overflowChecks: on.}
proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =
  let size = align(GenericSeqSize, typ.base.align) + len * typ.base.size
  result = newObjRC1(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len
  when defined(memProfiler): nimProfile(size)
{.pop.}

proc growObj(old: pointer, newsize: int, gch: var GcHeap): pointer =
  collectCT(gch)
  var ol = usrToCell(old)
  sysAssert(ol.typ != nil, "growObj: 1")
  gcAssert(ol.typ.kind in {tyString, tySequence}, "growObj: 2")
  sysAssert(allocInv(gch.region), "growObj begin")

  var res = cast[PCell](rawAlloc(gch.region, newsize + sizeof(Cell)))
  var elemSize,elemAlign = 1
  if ol.typ.kind != tyString:
    elemSize = ol.typ.base.size
    elemAlign = ol.typ.base.align
  incTypeSize ol.typ, newsize

  var oldsize = align(GenericSeqSize, elemAlign) + cast[PGenericSeq](old).len * elemSize
  copyMem(res, ol, oldsize + sizeof(Cell))
  zeroMem(cast[pointer](cast[ByteAddress](res) +% oldsize +% sizeof(Cell)),
          newsize-oldsize)
  sysAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "growObj: 3")
  # This can be wrong for intermediate temps that are nevertheless on the
  # heap because of lambda lifting:
  #gcAssert(res.refcount shr rcShift <=% 1, "growObj: 4")
  logCell("growObj old cell", ol)
  logCell("growObj new cell", res)
  gcTrace(ol, csZctFreed)
  gcTrace(res, csAllocated)
  track("growObj old", ol, 0)
  track("growObj new", res, newsize)
  when defined(nimIncrSeqV3):
    # since we steal the old seq's contents, we set the old length to 0.
    cast[PGenericSeq](old).len = 0
  elif reallyDealloc:
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
      beforeDealloc(gch, ol, "growObj stack trash")
      decTypeSize(ol, ol.typ)
      rawDealloc(gch.region, ol)
    else:
      # we split the old refcount in 2 parts. XXX This is still not entirely
      # correct if the pointer that receives growObj's result is on the stack.
      # A better fix would be to emit the location specific write barrier for
      # 'growObj', but this is lots of more work and who knows what new problems
      # this would create.
      res.refcount = rcIncrement
      decRef(ol)
  else:
    sysAssert(ol.typ != nil, "growObj: 5")
    zeroMem(ol, sizeof(Cell))
  when useCellIds:
    inc gch.idGenerator
    res.id = gch.idGenerator * 1000_000 + gch.gcThreadId
  result = cellToUsr(res)
  sysAssert(allocInv(gch.region), "growObj end")
  when defined(memProfiler): nimProfile(newsize-oldsize)

proc growObj(old: pointer, newsize: int): pointer {.rtl.} =
  result = growObj(old, newsize, gch)

{.push profiler:off, stackTrace:off.}

# ---------------- cycle collector -------------------------------------------

proc freeCyclicCell(gch: var GcHeap, c: PCell) =
  prepareDealloc(c)
  gcTrace(c, csCycFreed)
  track("cycle collector dealloc cell", c, 0)
  logCell("cycle collector dealloc cell", c)
  when reallyDealloc:
    sysAssert(allocInv(gch.region), "free cyclic cell")
    beforeDealloc(gch, c, "freeCyclicCell: stack trash")
    rawDealloc(gch.region, c)
  else:
    gcAssert(c.typ != nil, "freeCyclicCell")
    zeroMem(c, sizeof(Cell))

proc sweep(gch: var GcHeap) =
  for x in allObjects(gch.region):
    if isCell(x):
      # cast to PCell is correct here:
      var c = cast[PCell](x)
      if c notin gch.marked: freeCyclicCell(gch, c)

proc markS(gch: var GcHeap, c: PCell) =
  gcAssert isAllocatedPtr(gch.region, c), "markS: foreign heap root detected A!"
  incl(gch.marked, c)
  gcAssert gch.tempStack.len == 0, "stack not empty!"
  forAllChildren(c, waMarkPrecise)
  while gch.tempStack.len > 0:
    dec gch.tempStack.len
    var d = gch.tempStack.d[gch.tempStack.len]
    gcAssert isAllocatedPtr(gch.region, d), "markS: foreign heap root detected B!"
    if not containsOrIncl(gch.marked, d):
      forAllChildren(d, waMarkPrecise)

proc markGlobals(gch: var GcHeap) {.raises: [].} =
  if gch.gcThreadId == 0:
    for i in 0 .. globalMarkersLen-1: globalMarkers[i]()
  for i in 0 .. threadLocalMarkersLen-1: threadLocalMarkers[i]()
  let d = gch.additionalRoots.d
  for i in 0 .. gch.additionalRoots.len-1: markS(gch, d[i])

when logGC:
  var
    cycleCheckA: array[100, PCell]
    cycleCheckALen = 0

  proc alreadySeen(c: PCell): bool =
    for i in 0 .. cycleCheckALen-1:
      if cycleCheckA[i] == c: return true
    if cycleCheckALen == len(cycleCheckA):
      gcAssert(false, "cycle detection overflow")
      quit 1
    cycleCheckA[cycleCheckALen] = c
    inc cycleCheckALen

  proc debugGraph(s: PCell) =
    if alreadySeen(s):
      writeCell("child cell (already seen) ", s)
    else:
      writeCell("cell {", s)
      forAllChildren(s, waDebug)
      c_printf("}\n")

proc doOperation(p: pointer, op: WalkOp) =
  if p == nil: return
  var c: PCell = usrToCell(p)
  gcAssert(c != nil, "doOperation: 1")
  # the 'case' should be faster than function pointers because of easy
  # prediction:
  case op
  of waZctDecRef:
    #if not isAllocatedPtr(gch.region, c):
    #  c_printf("[GC] decref bug: %p", c)
    gcAssert(isAllocatedPtr(gch.region, c), "decRef: waZctDecRef")
    gcAssert(c.refcount >=% rcIncrement, "doOperation 2")
    logCell("decref (from doOperation)", c)
    track("waZctDecref", p, 0)
    decRef(c)
  of waPush:
    add(gch.tempStack, c)
  of waMarkGlobal:
    markS(gch, c)
  of waMarkPrecise:
    add(gch.tempStack, c)
  #of waDebug: debugGraph(c)

proc nimGCvisit(d: pointer, op: int) {.compilerRtl.} =
  doOperation(d, WalkOp(op))

proc collectZCT(gch: var GcHeap): bool {.benign, raises: [].}

proc collectCycles(gch: var GcHeap) {.raises: [].} =
  when hasThreadSupport:
    for c in gch.toDispose:
      nimGCunref(c)
  # ensure the ZCT 'color' is not used:
  while gch.zct.len > 0: discard collectZCT(gch)
  cellsetReset(gch.marked)
  var d = gch.decStack.d
  for i in 0..gch.decStack.len-1:
    sysAssert isAllocatedPtr(gch.region, d[i]), "collectCycles"
    markS(gch, d[i])
  markGlobals(gch)
  sweep(gch)

proc gcMark(gch: var GcHeap, p: pointer) {.inline.} =
  # the addresses are not as cells on the stack, so turn them to cells:
  sysAssert(allocInv(gch.region), "gcMark begin")
  var c = cast[ByteAddress](p)
  if c >% PageSize:
    # fast check: does it look like a cell?
    var objStart = cast[PCell](interiorAllocatedPtr(gch.region, p))
    if objStart != nil:
      # mark the cell:
      incRef(objStart)
      add(gch.decStack, objStart)
    when false:
      let cell = usrToCell(p)
      if isAllocatedPtr(gch.region, cell):
        sysAssert false, "allocated pointer but not interior?"
        # mark the cell:
        incRef(cell)
        add(gch.decStack, cell)
  sysAssert(allocInv(gch.region), "gcMark end")

#[
  This method is conditionally marked with an attribute so that it gets ignored by the LLVM ASAN
  (Address SANitizer) intrumentation as it will raise false errors due to the implementation of
  garbage collection that is used by Nim. For more information, please see the documentation of
  `CLANG_NO_SANITIZE_ADDRESS` in `lib/nimbase.h`.
 ]#
proc markStackAndRegisters(gch: var GcHeap) {.noinline, cdecl,
    codegenDecl: "CLANG_NO_SANITIZE_ADDRESS N_LIB_PRIVATE $# $#$#".} =
  forEachStackSlot(gch, gcMark)

proc collectZCT(gch: var GcHeap): bool =
  # Note: Freeing may add child objects to the ZCT! So essentially we do
  # deep freeing, which is bad for incremental operation. In order to
  # avoid a deep stack, we move objects to keep the ZCT small.
  # This is performance critical!
  const workPackage = 100
  var L = addr(gch.zct.len)

  when withRealTime:
    var steps = workPackage
    var t0: Ticks
    if gch.maxPause > 0: t0 = getticks()
  while L[] > 0:
    var c = gch.zct.d[0]
    sysAssert(isAllocatedPtr(gch.region, c), "CollectZCT: isAllocatedPtr")
    # remove from ZCT:
    gcAssert((c.refcount and ZctFlag) == ZctFlag, "collectZCT")

    c.refcount = c.refcount and not ZctFlag
    gch.zct.d[0] = gch.zct.d[L[] - 1]
    dec(L[])
    when withRealTime: dec steps
    if c.refcount <% rcIncrement:
      # It may have a RC > 0, if it is in the hardware stack or
      # it has not been removed yet from the ZCT. This is because
      # ``incref`` does not bother to remove the cell from the ZCT
      # as this might be too slow.
      # In any case, it should be removed from the ZCT. But not
      # freed. **KEEP THIS IN MIND WHEN MAKING THIS INCREMENTAL!**
      logCell("zct dealloc cell", c)
      track("zct dealloc cell", c, 0)
      gcTrace(c, csZctFreed)
      # We are about to free the object, call the finalizer BEFORE its
      # children are deleted as well, because otherwise the finalizer may
      # access invalid memory. This is done by prepareDealloc():
      prepareDealloc(c)
      forAllChildren(c, waZctDecRef)
      when reallyDealloc:
        sysAssert(allocInv(gch.region), "collectZCT: rawDealloc")
        beforeDealloc(gch, c, "collectZCT: stack trash")
        rawDealloc(gch.region, c)
      else:
        sysAssert(c.typ != nil, "collectZCT 2")
        zeroMem(c, sizeof(Cell))
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
  result = true

proc unmarkStackAndRegisters(gch: var GcHeap) =
  var d = gch.decStack.d
  for i in 0..gch.decStack.len-1:
    sysAssert isAllocatedPtr(gch.region, d[i]), "unmarkStackAndRegisters"
    decRef(d[i])
  gch.decStack.len = 0

proc collectCTBody(gch: var GcHeap) {.raises: [].} =
  when withRealTime:
    let t0 = getticks()
  sysAssert(allocInv(gch.region), "collectCT: begin")

  when nimCoroutines:
    for stack in gch.stack.items():
      gch.stat.maxStackSize = max(gch.stat.maxStackSize, stack.stackSize())
  else:
    gch.stat.maxStackSize = max(gch.stat.maxStackSize, stackSize())
  sysAssert(gch.decStack.len == 0, "collectCT")
  prepareForInteriorPointerChecking(gch.region)
  markStackAndRegisters(gch)
  gch.stat.maxStackCells = max(gch.stat.maxStackCells, gch.decStack.len)
  inc(gch.stat.stackScans)
  if collectZCT(gch):
    when cycleGC:
      if getOccupiedMem(gch.region) >= gch.cycleThreshold or alwaysCycleGC:
        collectCycles(gch)
        #discard collectZCT(gch)
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
        c_printf("[GC] missed deadline: %ld\n", duration)

proc collectCT(gch: var GcHeap) =
  if (gch.zct.len >= gch.zctThreshold or (cycleGC and
      getOccupiedMem(gch.region)>=gch.cycleThreshold) or alwaysGC) and
      gch.recGcLock == 0:
    when false:
      prepareForInteriorPointerChecking(gch.region)
      cellsetReset(gch.marked)
      markForDebug(gch)
    collectCTBody(gch)
    gch.zctThreshold = max(InitialZctThreshold, gch.zct.len * CycleIncrease)

proc GC_collectZct*() =
  ## Collect the ZCT (zero count table). Unstable, experimental API for
  ## testing purposes.
  ## DO NOT USE!
  collectCTBody(gch)

when withRealTime:
  proc toNano(x: int): Nanos {.inline.} =
    result = x * 1000

  proc GC_setMaxPause*(MaxPauseInUs: int) =
    gch.maxPause = MaxPauseInUs.toNano

  proc GC_step(gch: var GcHeap, us: int, strongAdvice: bool) =
    gch.maxPause = us.toNano
    if (gch.zct.len >= gch.zctThreshold or (cycleGC and
        getOccupiedMem(gch.region)>=gch.cycleThreshold) or alwaysGC) or
        strongAdvice:
      collectCTBody(gch)
      gch.zctThreshold = max(InitialZctThreshold, gch.zct.len * CycleIncrease)

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
    when defined(nimDoesntTrackDefects):
      if gch.recGcLock <= 0:
        raise newException(AssertionDefect,
            "API usage error: GC_enable called but GC is already enabled")
    dec(gch.recGcLock)

  proc GC_setStrategy(strategy: GC_Strategy) =
    discard

  proc GC_enableMarkAndSweep() =
    gch.cycleThreshold = InitialCycleThreshold

  proc GC_disableMarkAndSweep() =
    gch.cycleThreshold = high(typeof(gch.cycleThreshold))-1
    # set to the max value to suppress the cycle detector

  proc GC_fullCollect() =
    var oldThreshold = gch.cycleThreshold
    gch.cycleThreshold = 0 # forces cycle collection
    collectCT(gch)
    gch.cycleThreshold = oldThreshold

  proc GC_getStatistics(): string =
    result = "[GC] total memory: " & $(getTotalMem()) & "\n" &
             "[GC] occupied memory: " & $(getOccupiedMem()) & "\n" &
             "[GC] stack scans: " & $gch.stat.stackScans & "\n" &
             "[GC] stack cells: " & $gch.stat.maxStackCells & "\n" &
             "[GC] cycle collections: " & $gch.stat.cycleCollections & "\n" &
             "[GC] max threshold: " & $gch.stat.maxThreshold & "\n" &
             "[GC] zct capacity: " & $gch.zct.cap & "\n" &
             "[GC] max cycle table size: " & $gch.stat.cycleTableSize & "\n" &
             "[GC] max pause time [ms]: " & $(gch.stat.maxPause div 1000_000) & "\n"
    when nimCoroutines:
      result.add "[GC] number of stacks: " & $gch.stack.len & "\n"
      for stack in items(gch.stack):
        result.add "[GC]   stack " & stack.bottom.repr & "[GC]     max stack size " & cast[pointer](stack.maxStackSize).repr & "\n"
    else:
      # this caused memory leaks, see #10488 ; find a way without `repr`
      # maybe using a local copy of strutils.toHex or snprintf
      when defined(logGC):
        result.add "[GC] stack bottom: " & gch.stack.bottom.repr
      result.add "[GC] max stack size: " & $gch.stat.maxStackSize & "\n"

{.pop.} # profiler: off, stackTrace: off
