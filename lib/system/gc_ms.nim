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

template mulThreshold(x): expr {.immediate.} = x * 2

when defined(memProfiler):
  proc nimProfile(requestedSize: int)

type
  TWalkOp = enum
    waMarkGlobal,  # we need to mark conservatively for global marker procs
                   # as these may refer to a global var and not to a thread
                   # local
    waMarkPrecise  # fast precise marking

  TFinalizer {.compilerproc.} = proc (self: pointer) {.nimcall, benign.}
    # A ref type can have a finalizer that is called before the object's
    # storage is freed.

  TGlobalMarkerProc = proc () {.nimcall, benign.}

  TGcStat = object
    collections: int         # number of performed full collections
    maxThreshold: int        # max threshold that has been set
    maxStackSize: int        # max stack size
    freedObjects: int        # max entries in cycle table

  TGcHeap = object           # this contains the zero count and
                             # non-zero count table
    stackBottom: pointer
    cycleThreshold: int
    when useCellIds:
      idGenerator: int
    when withBitvectors:
      allocated, marked: TCellSet
    tempStack: TCellSeq      # temporary stack for recursion elimination
    recGcLock: int           # prevent recursion via finalizers; no thread lock
    region: TMemRegion       # garbage collected region
    stat: TGcStat
    additionalRoots: TCellSeq # dummy roots for GC_ref/unref

var
  gch {.rtlThreadVar.}: TGcHeap

when not defined(useNimRtl):
  instantiateForRegion(gch.region)

template acquire(gch: TGcHeap) =
  when hasThreadSupport and hasSharedHeap:
    acquireSys(HeapLock)

template release(gch: TGcHeap) =
  when hasThreadSupport and hasSharedHeap:
    releaseSys(HeapLock)

template gcAssert(cond: bool, msg: string) =
  when defined(useGcAssert):
    if not cond:
      echo "[GCASSERT] ", msg
      quit 1

proc cellToUsr(cell: PCell): pointer {.inline.} =
  # convert object (=pointer to refcount) to pointer to userdata
  result = cast[pointer](cast[ByteAddress](cell)+%ByteAddress(sizeof(TCell)))

proc usrToCell(usr: pointer): PCell {.inline.} =
  # convert pointer to userdata to object (=pointer to refcount)
  result = cast[PCell](cast[ByteAddress](usr)-%ByteAddress(sizeof(TCell)))

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
  globalMarkers: array[0.. 7_000, TGlobalMarkerProc]

proc nimRegisterGlobalMarker(markerProc: TGlobalMarkerProc) {.compilerProc.} =
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
proc collectCT(gch: var TGcHeap) {.benign.}
proc isOnStack*(p: pointer): bool {.noinline, benign.}
proc forAllChildren(cell: PCell, op: TWalkOp) {.benign.}
proc doOperation(p: pointer, op: TWalkOp) {.benign.}
proc forAllChildrenAux(dest: pointer, mt: PNimType, op: TWalkOp) {.benign.}
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
      Init(gch.allocated)
      init(gch.marked)

var
  localGcInitialized {.rtlThreadVar.}: bool

proc setupForeignThreadGc*() =
  ## call this if you registered a callback that will be run from a thread not
  ## under your control. This has a cheap thread-local guard, so the GC for
  ## this thread will only be initialized once per thread, no matter how often
  ## it is called.
  if not localGcInitialized:
    localGcInitialized = true
    var stackTop {.volatile.}: pointer
    setStackBottom(addr(stackTop))
    initGC()

proc forAllSlotsAux(dest: pointer, n: ptr TNimNode, op: TWalkOp) {.benign.} =
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

proc rawNewObj(typ: PNimType, size: int, gch: var TGcHeap): pointer =
  # generates a new object and sets its reference counter to 0
  acquire(gch)
  gcAssert(typ.kind in {tyRef, tyString, tySequence}, "newObj: 1")
  collectCT(gch)
  var res = cast[PCell](rawAlloc(gch.region, size + sizeof(TCell)))
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

proc growObj(old: pointer, newsize: int, gch: var TGcHeap): pointer =
  acquire(gch)
  collectCT(gch)
  var ol = usrToCell(old)
  sysAssert(ol.typ != nil, "growObj: 1")
  gcAssert(ol.typ.kind in {tyString, tySequence}, "growObj: 2")

  var res = cast[PCell](rawAlloc(gch.region, newsize + sizeof(TCell)))
  var elemSize = 1
  if ol.typ.kind != tyString: elemSize = ol.typ.base.size

  var oldsize = cast[PGenericSeq](old).len*elemSize + GenericSeqSize
  copyMem(res, ol, oldsize + sizeof(TCell))
  zeroMem(cast[pointer](cast[ByteAddress](res)+% oldsize +% sizeof(TCell)),
          newsize-oldsize)
  sysAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "growObj: 3")
  when false:
    # this is wrong since seqs can be shared via 'shallow':
    when withBitvectors: excl(gch.allocated, ol)
    when reallyDealloc: rawDealloc(gch.region, ol)
    else:
      zeroMem(ol, sizeof(TCell))
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

proc mark(gch: var TGcHeap, c: PCell) =
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

proc doOperation(p: pointer, op: TWalkOp) =
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
  doOperation(d, TWalkOp(op))

proc freeCyclicCell(gch: var TGcHeap, c: PCell) =
  inc gch.stat.freedObjects
  prepareDealloc(c)
  when reallyDealloc: rawDealloc(gch.region, c)
  else:
    gcAssert(c.typ != nil, "freeCyclicCell")
    zeroMem(c, sizeof(TCell))

proc sweep(gch: var TGcHeap) =
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

proc markGlobals(gch: var TGcHeap) =
  for i in 0 .. < globalMarkersLen: globalMarkers[i]()
  let d = gch.additionalRoots.d
  for i in 0 .. < gch.additionalRoots.len: mark(gch, d[i])

proc gcMark(gch: var TGcHeap, p: pointer) {.inline.} =
  # the addresses are not as cells on the stack, so turn them to cells:
  var cell = usrToCell(p)
  var c = cast[ByteAddress](cell)
  if c >% PageSize:
    # fast check: does it look like a cell?
    var objStart = cast[PCell](interiorAllocatedPtr(gch.region, cell))
    if objStart != nil:
      mark(gch, objStart)

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
      sp = cast[ppointer](cast[ByteAddress](sp) +% sizeof(pointer))

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

  var
    jmpbufSize {.importc: "sizeof(jmp_buf)", nodecl.}: int
      # a little hack to get the size of a TJmpBuf in the generated C code
      # in a platform independent way

  proc markStackAndRegisters(gch: var TGcHeap) {.noinline, cdecl.} =
    var registers: C_JmpBuf
    if c_setjmp(registers) == 0'i32: # To fill the C stack with registers.
      var max = cast[ByteAddress](gch.stackBottom)
      var sp = cast[ByteAddress](addr(registers)) +% jmpbufSize -% sizeof(pointer)
      # sp will traverse the JMP_BUF as well (jmp_buf size is added,
      # otherwise sp would be below the registers structure).
      while sp >=% max:
        gcMark(gch, cast[ppointer](sp)[])
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
    var registers {.noinit.}: C_JmpBuf
    if c_setjmp(registers) == 0'i32: # To fill the C stack with registers.
      var max = cast[ByteAddress](gch.stackBottom)
      var sp = cast[ByteAddress](addr(registers))
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

proc collectCTBody(gch: var TGcHeap) =
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

proc collectCT(gch: var TGcHeap) =
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
             "[GC] freed objects: " & $gch.stat.freedObjects & "\n" &
             "[GC] max stack size: " & $gch.stat.maxStackSize & "\n"
    GC_enable()

{.pop.}
