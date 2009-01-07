#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


#            Garbage Collector
# Current Features:
# * incremental
# * non-recursive
# * generational

# Future Improvements:
# * Both dlmalloc and TLSF lack zero-overhead object allocation. Thus, for
#   small objects we should use our own allocator.
# * Support for multi-threading. However, locks for the reference counting
#   might turn out to be too slow.

# ---------------------------------------------------------------------------
# Interface to TLSF:
const
  useTLSF = false # benchmarking showed that *dlmalloc* is faster than *TLSF*

when useTLSF:
  {.compile: "tlsf.c".}

  proc tlsfUsed: int {.importc: "TLSF_GET_USED_SIZE", noconv.}
  proc tlsfMax: int {.importc: "TLSF_GET_MAX_SIZE", noconv.}

  proc tlsf_malloc(size: int): pointer {.importc, noconv.}
  proc tlsf_free(p: pointer) {.importc, noconv.}
  proc tlsf_realloc(p: pointer, size: int): pointer {.importc, noconv.}
else:
  # use DL malloc
  {.compile: "dlmalloc.c".}
  proc tlsfUsed: int {.importc: "dlmalloc_footprint", noconv.}
  proc tlsfMax: int {.importc: "dlmalloc_max_footprint", noconv.}

  proc tlsf_malloc(size: int): pointer {.importc: "dlmalloc", noconv.}
  proc tlsf_free(p: pointer) {.importc: "dlfree", noconv.}
  proc tlsf_realloc(p: pointer, size: int): pointer {.
    importc: "dlrealloc", noconv.}

# ---------------------------------------------------------------------------

proc getOccupiedMem(): int = return tlsfUsed()
proc getFreeMem(): int = return tlsfMax() - tlsfUsed()
proc getTotalMem(): int = return tlsfMax()

# ---------------------------------------------------------------------------

const
  debugGC = false # we wish to debug the GC...
  logGC = false
  traceGC = false # extensive debugging
  reallyDealloc = true # for debugging purposes this can be set to false
  cycleGC = true # (de)activate the cycle GC
  stressGC = debugGC

# Guess the page size of the system; if it is the
# wrong value, performance may be worse (this is not
# for sure though), but GC still works; must be a power of two!
const
  PageShift = if sizeof(pointer) == 4: 12 else: 13
  PageSize = 1 shl PageShift # on 32 bit systems 4096
  CycleIncrease = 2 # is a multiplicative increase

  InitialCycleThreshold = 4*1024*1024 # X MB because cycle checking is slow
  ZctThreshold = 256  # we collect garbage if the ZCT's size
                      # reaches this threshold
                      # this seems to be a good value

const
  MemAlignment = 8 # BUGFIX: on AMD64, dlmalloc aligns at 8 byte boundary
  BitsPerUnit = sizeof(int)*8
    # a "unit" is a word, i.e. 4 bytes
    # on a 32 bit system; I do not use the term "word" because under 32-bit
    # Windows it is sometimes only 16 bits

  BitsPerPage = PageSize div MemAlignment
  UnitsPerPage = BitsPerPage div BitsPerUnit
    # how many units do we need to describe a page:
    # on 32 bit systems this is only 16 (!)

  rcIncrement = 0b1000 # so that lowest 3 bits are not touched
  # NOTE: Most colors are currently unused
  rcBlack = 0b000 # cell is colored black; in use or free
  rcGray = 0b001  # possible member of a cycle
  rcWhite = 0b010 # member of a garbage cycle
  rcPurple = 0b011 # possible root of a cycle
  rcZct = 0b100  # in ZCT
  rcRed = 0b101 # Candidate cycle undergoing sigma-computation
  rcOrange = 0b110 # Candidate cycle awaiting epoch boundary
  rcShift = 3 # shift by rcShift to get the reference counter
  colorMask = 0b111
type
  TWalkOp = enum
    waZctDecRef, waPush, waCycleDecRef

  TCell {.pure.} = object
    refcount: int  # the refcount and some flags
    typ: PNimType
    when debugGC:
      filename: cstring
      line: int

  PCell = ptr TCell
  TFinalizer {.compilerproc.} = proc (self: pointer)
    # A ref type can have a finalizer that is called before the object's
    # storage is freed.
  PPointer = ptr pointer
  TByteArray = array[0..1000_0000, byte]
  PByte = ptr TByteArray
  PString = ptr string

  PPageDesc = ptr TPageDesc
  TBitIndex = range[0..UnitsPerPage-1]
  TPageDesc {.final, pure.} = object
    next: PPageDesc # all nodes are connected with this pointer
    key: TAddress   # start address at bit 0
    bits: array[TBitIndex, int] # a bit vector

  PPageDescArray = ptr array[0..1000_000, PPageDesc]
  TCellSet {.final, pure.} = object
    counter, max: int
    head: PPageDesc
    data: PPageDescArray

  PCellArray = ptr array[0..100_000_000, PCell]
  TCellSeq {.final, pure.} = object
    len, cap: int
    d: PCellArray

  TGcHeap {.final, pure.} = object # this contains the zero count and
                                   # non-zero count table
    mask: TAddress           # mask for fast pointer detection
    zct: TCellSeq            # the zero count table
    stackCells: TCellSet     # cells and addresses that look like a cell but
                             # aren't of the hardware stack

    stackScans: int          # number of performed stack scans (for statistics)
    cycleCollections: int    # number of performed full collections
    maxThreshold: int        # max threshold that has been set
    maxStackSize: int        # max stack size
    maxStackPages: int       # max number of pages in stack
    cycleTableSize: int      # max entries in cycle table
    cycleRoots: TCellSet
    tempStack: TCellSeq      # temporary stack for recursion elimination

var
  gOutOfMem: ref EOutOfMemory
  stackBottom: pointer
  gch: TGcHeap
  cycleThreshold: int = InitialCycleThreshold
  recGcLock: int = 0
    # we use a lock to prevend the garbage collector to be triggered in a
    # finalizer; the collector should not call itself this way! Thus every
    # object allocated by a finalizer will not trigger a garbage collection.
    # This is wasteful but safe. This is a lock against recursive garbage
    # collection, not a lock for threads!

proc unsureAsgnRef(dest: ppointer, src: pointer) {.compilerproc.}
  # unsureAsgnRef updates the reference counters only if dest is not on the
  # stack. It is used by the code generator if it cannot decide wether a
  # reference is in the stack or not (this can happen for out/var parameters).
#proc growObj(old: pointer, newsize: int): pointer {.compilerproc.}
proc newObj(typ: PNimType, size: int): pointer {.compilerproc.}
proc newSeq(typ: PNimType, len: int): pointer {.compilerproc.}

proc raiseOutOfMem() {.noreturn.} =
  if gOutOfMem == nil:
    writeToStdErr("out of memory; cannot even throw an exception")
    quit(1)
  gOutOfMem.msg = "out of memory"
  raise gOutOfMem

proc cellToUsr(cell: PCell): pointer {.inline.} =
  # convert object (=pointer to refcount) to pointer to userdata
  result = cast[pointer](cast[TAddress](cell)+%TAddress(sizeof(TCell)))

proc usrToCell(usr: pointer): PCell {.inline.} =
  # convert pointer to userdata to object (=pointer to refcount)
  result = cast[PCell](cast[TAddress](usr)-%TAddress(sizeof(TCell)))

proc canbeCycleRoot(c: PCell): bool {.inline.} =
  result = ntfAcyclic notin c.typ.flags

proc extGetCellType(c: pointer): PNimType {.compilerproc.} =
  # used for code generation concerning debugging
  result = usrToCell(c).typ

proc internRefcount(p: pointer): int {.exportc: "getRefcount".} =
  result = int(usrToCell(p).refcount)
  if result > 0: result = result shr rcShift
  else: result = 0

proc gcAlloc(size: int): pointer =
  result = tlsf_malloc(size)
  if result == nil: raiseOutOfMem()
  zeroMem(result, size)

proc GC_disable() = inc(recGcLock)
proc GC_enable() =
  if recGcLock > 0: dec(recGcLock)

proc GC_setStrategy(strategy: TGC_Strategy) =
  case strategy
  of gcThroughput: nil
  of gcResponsiveness: nil
  of gcOptimizeSpace: nil
  of gcOptimizeTime: nil

proc GC_enableMarkAndSweep() =
  cycleThreshold = InitialCycleThreshold

proc GC_disableMarkAndSweep() =
  cycleThreshold = high(cycleThreshold)-1
  # set to the max value to suppress the cycle detector

proc nextTry(h, maxHash: int): int {.inline.} =
  result = ((5*h) + 1) and maxHash
  # For any initial h in range(maxHash), repeating that maxHash times
  # generates each int in range(maxHash) exactly once (see any text on
  # random-number generation for proof).

# this that has to equals zero, otherwise we have to round up UnitsPerPage:
when BitsPerPage mod BitsPerUnit != 0:
  {.error: "(BitsPerPage mod BitsPerUnit) should be zero!".}

# ------------------- cell set handling ---------------------------------------

proc inOperator(s: TCellSeq, c: PCell): bool {.inline.} =
  for i in 0 .. s.len-1:
    if s.d[i] == c: return True
  return False

proc add(s: var TCellSeq, c: PCell) {.inline.} =
  if s.len >= s.cap:
    s.cap = s.cap * 3 div 2
    var d = cast[PCellArray](tlsf_malloc(s.cap * sizeof(PCell)))
    if d == nil: raiseOutOfMem()
    copyMem(d, s.d, s.len * sizeof(PCell))
    tlsf_free(s.d)
    s.d = d
    # BUGFIX: realloc failes on AMD64, sigh...
    #s.d = cast[PCellArray](tlsf_realloc(s.d, s.cap * sizeof(PCell)))
    #if s.d == nil: raiseOutOfMem()
  s.d[s.len] = c
  inc(s.len)

proc addZCT(s: var TCellSeq, c: PCell) =
  if (c.refcount and colorMask) != rcZct:
    c.refcount = c.refcount and not colorMask or rcZct
    add(s, c)

proc init(s: var TCellSeq, cap: int = 1024) =
  s.len = 0
  s.cap = cap
  s.d = cast[PCellArray](gcAlloc(cap * sizeof(PCell)))

const
  InitCellSetSize = 1024 # must be a power of two!

proc CellSetInit(s: var TCellSet) =
  s.data = cast[PPageDescArray](gcAlloc(InitCellSetSize * sizeof(PPageDesc)))
  s.max = InitCellSetSize-1
  s.counter = 0
  s.head = nil

proc CellSetDeinit(s: var TCellSet) =
  var it = s.head
  while it != nil:
    var n = it.next
    tlsf_free(it)
    it = n
  s.head = nil # play it safe here
  tlsf_free(s.data)
  s.data = nil
  s.counter = 0
  
proc CellSetGet(t: TCellSet, key: TAddress): PPageDesc =
  var h = cast[int](key) and t.max
  while t.data[h] != nil:
    if t.data[h].key == key: return t.data[h]
    h = nextTry(h, t.max)
  return nil

proc CellSetRawInsert(t: TCellSet, data: PPageDescArray,
                      desc: PPageDesc) =
  var h = cast[int](desc.key) and t.max
  while data[h] != nil:
    assert(data[h] != desc)
    h = nextTry(h, t.max)
  assert(data[h] == nil)
  data[h] = desc

proc CellSetEnlarge(t: var TCellSet) =
  var oldMax = t.max
  t.max = ((t.max+1)*2)-1
  var n = cast[PPageDescArray](gcAlloc((t.max + 1) * sizeof(PPageDesc)))
  for i in 0 .. oldmax:
    if t.data[i] != nil:
      CellSetRawInsert(t, n, t.data[i])
  tlsf_free(t.data)
  t.data = n

proc CellSetPut(t: var TCellSet, key: TAddress): PPageDesc =
  var h = cast[int](key) and t.max
  while true:
    var x = t.data[h]
    if x == nil: break
    if x.key == key: return x
    h = nextTry(h, t.max)

  if ((t.max+1)*2 < t.counter*3) or ((t.max+1)-t.counter < 4):
    CellSetEnlarge(t)
  inc(t.counter)
  h = cast[int](key) and t.max
  while t.data[h] != nil: h = nextTry(h, t.max)
  assert(t.data[h] == nil)
  # the new page descriptor goes into result
  result = cast[PPageDesc](gcAlloc(sizeof(TPageDesc)))
  result.next = t.head
  result.key = key
  t.head = result
  t.data[h] = result

# ---------- slightly higher level procs --------------------------------------

proc contains(s: TCellSet, cell: PCell): bool =
  var u = cast[TAddress](cell)
  var t = CellSetGet(s, u shr PageShift)
  if t != nil:
    u = (u %% PageSize) /% MemAlignment
    result = (t.bits[u /% BitsPerUnit] and (1 shl (u %% BitsPerUnit))) != 0
  else:
    result = false

proc incl(s: var TCellSet, cell: PCell) =
  var u = cast[TAddress](cell)
  var t = CellSetPut(s, u shr PageShift)
  u = (u %% PageSize) /% MemAlignment
  t.bits[u /% BitsPerUnit] = t.bits[u /% BitsPerUnit] or
    (1 shl (u %% BitsPerUnit))

proc excl(s: var TCellSet, cell: PCell) =
  var u = cast[TAddress](cell)
  var t = CellSetGet(s, u shr PageShift)
  if t != nil:
    u = (u %% PageSize) /% MemAlignment
    t.bits[u /% BitsPerUnit] = (t.bits[u /% BitsPerUnit] and
                                  not (1 shl (u %% BitsPerUnit)))

iterator elements(t: TCellSet): PCell {.inline.} =
  # while traversing it is forbidden to add pointers to the tree!
  var r = t.head
  while r != nil:
    var i = 0
    while i <= high(r.bits):
      var w = r.bits[i] # taking a copy of r.bits[i] here is correct, because
      # modifying operations are not allowed during traversation
      var j = 0
      while w != 0:         # test all remaining bits for zero
        if (w and 1) != 0:  # the bit is set!
          yield cast[PCell]((r.key shl PageShift) or # +%
                              (i*%BitsPerUnit+%j) *% MemAlignment)
        inc(j)
        w = w shr 1
      inc(i)
    r = r.next

# --------------- end of Cellset routines -------------------------------------

when debugGC:
  proc writeCell(msg: CString, c: PCell) =
    var kind = -1
    if c.typ != nil: kind = ord(c.typ.kind)
    when debugGC:
      c_fprintf(c_stdout, "[GC] %s: %p %d rc=%ld from %s(%ld)\n",
                msg, c, kind, c.refcount shr rcShift, c.filename, c.line)
    else:
      c_fprintf(c_stdout, "[GC] %s: %p %d rc=%ld\n",
                msg, c, kind, c.refcount shr rcShift)

when traceGC:
  # traceGC is a special switch to enable extensive debugging
  type
    TCellState = enum
      csAllocated, csZctFreed, csCycFreed
  var
    states: array[TCellState, TCellSet]

  proc traceCell(c: PCell, state: TCellState) =
    case state
    of csAllocated:
      if c in states[csAllocated]:
        writeCell("attempt to alloc an already allocated cell", c)
        assert(false)
      excl(states[csCycFreed], c)
      excl(states[csZctFreed], c)
    of csZctFreed:
      if c in states[csZctFreed]:
        writeCell("attempt to free zct cell twice", c)
        assert(false)
      if c in states[csCycFreed]:
        writeCell("attempt to free with zct, but already freed with cyc", c)
        assert(false)
      if c notin states[csAllocated]:
        writeCell("attempt to free not an allocated cell", c)
        assert(false)
      excl(states[csAllocated], c)
    of csCycFreed:
      if c notin states[csAllocated]:
        writeCell("attempt to free a not allocated cell", c)
        assert(false)
      if c in states[csCycFreed]:
        writeCell("attempt to free cyc cell twice", c)
        assert(false)
      if c in states[csZctFreed]:
        writeCell("attempt to free with cyc, but already freed with zct", c)
        assert(false)
      excl(states[csAllocated], c)
    incl(states[state], c)

  proc writeLeakage() =
    var z = 0
    var y = 0
    var e = 0
    for c in elements(states[csAllocated]):
      inc(e)
      if c in states[csZctFreed]: inc(z)
      elif c in states[csCycFreed]: inc(z)
      else: writeCell("leak", c)
    cfprintf(cstdout, "Allocations: %ld; ZCT freed: %ld; CYC freed: %ld\n",
             e, z, y)

template gcTrace(cell, state: expr): stmt =
  when traceGC: traceCell(cell, state)

# -----------------------------------------------------------------------------

# forward declarations:
proc updateZCT()
proc collectCT(gch: var TGcHeap, zctUpdated: bool)
proc IsOnStack(p: pointer): bool {.noinline.}
proc forAllChildren(cell: PCell, op: TWalkOp)
proc doOperation(p: pointer, op: TWalkOp)
proc forAllChildrenAux(dest: Pointer, mt: PNimType, op: TWalkOp)
proc reprAny(p: pointer, typ: PNimType): string {.compilerproc.}
# we need the prototype here for debugging purposes

proc prepareDealloc(cell: PCell) =
  if cell.typ.finalizer != nil:
    # the finalizer could invoke something that
    # allocates memory; this could trigger a garbage
    # collection. Since we are already collecting we
    # prevend recursive entering here by a lock.
    # XXX: we should set the cell's children to nil!
    inc(recGcLock)
    (cast[TFinalizer](cell.typ.finalizer))(cellToUsr(cell))
    dec(recGcLock)

proc setStackBottom(theStackBottom: pointer) {.compilerproc.} =
  stackBottom = theStackBottom

proc PossibleRoot(gch: var TGcHeap, c: PCell) {.inline.} =
  if canbeCycleRoot(c): incl(gch.cycleRoots, c)

proc decRef(c: PCell) {.inline.} =
  when stressGC:
    if c.refcount <% rcIncrement:
      writeCell("broken cell", c)
  assert(c.refcount >% rcIncrement)
  c.refcount = c.refcount -% rcIncrement
  if c.refcount <% rcIncrement:
    addZCT(gch.zct, c)
  elif canBeCycleRoot(c):
    possibleRoot(gch, c) 

proc incRef(c: PCell) {.inline.} = 
  c.refcount = c.refcount +% rcIncrement
  if canBeCycleRoot(c):
    # OPT: the code generator should special case this
    possibleRoot(gch, c)

proc nimGCref(p: pointer) {.compilerproc, inline.} = incRef(usrToCell(p))
proc nimGCunref(p: pointer) {.compilerproc, inline.} = decRef(usrToCell(p))

proc asgnRef(dest: ppointer, src: pointer) {.compilerproc, inline.} =
  # the code generator calls this proc!
  assert(not isOnStack(dest))
  # BUGFIX: first incRef then decRef!
  if src != nil: incRef(usrToCell(src))
  if dest^ != nil: decRef(usrToCell(dest^))
  dest^ = src

proc asgnRefNoCycle(dest: ppointer, src: pointer) {.compilerproc, inline.} =
  # the code generator calls this proc if it is known at compile time that no 
  # cycle is possible.
  if src != nil: 
    var c = usrToCell(src)
    c.refcount = c.refcount +% rcIncrement
  if dest^ != nil: 
    var c = usrToCell(dest^)
    c.refcount = c.refcount -% rcIncrement
    if c.refcount <% rcIncrement:
      addZCT(gch.zct, c)
  dest^ = src

proc unsureAsgnRef(dest: ppointer, src: pointer) =
  if not IsOnStack(dest):
    if src != nil: incRef(usrToCell(src))
    if dest^ != nil: decRef(usrToCell(dest^))
  dest^ = src

proc initGC() =
  when traceGC:
    for i in low(TCellState)..high(TCellState): CellSetInit(states[i])
  gch.stackScans = 0
  gch.cycleCollections = 0
  gch.maxThreshold = 0
  gch.maxStackSize = 0
  gch.maxStackPages = 0
  gch.cycleTableSize = 0
  # init the rt
  init(gch.zct)
  init(gch.tempStack)
  CellSetInit(gch.cycleRoots)
  CellSetInit(gch.stackCells)
  gch.mask = 0
  new(gOutOfMem) # reserve space for the EOutOfMemory exception here!

proc getDiscriminant(aa: Pointer, n: ptr TNimNode): int =
  assert(n.kind == nkCase)
  var d: int
  var a = cast[TAddress](aa)
  case n.typ.size
  of 1: d = ze(cast[ptr int8](a +% n.offset)^)
  of 2: d = ze(cast[ptr int16](a +% n.offset)^)
  of 4: d = int(cast[ptr int32](a +% n.offset)^)
  else: assert(false)
  return d

proc selectBranch(aa: Pointer, n: ptr TNimNode): ptr TNimNode =
  var discr = getDiscriminant(aa, n)
  if discr <% n.len:
    result = n.sons[discr]
    if result == nil: result = n.sons[n.len]
    # n.sons[n.len] contains the ``else`` part (but may be nil)
  else:
    result = n.sons[n.len]

proc forAllSlotsAux(dest: pointer, n: ptr TNimNode, op: TWalkOp) =
  var d = cast[TAddress](dest)
  case n.kind
  of nkNone: assert(false)
  of nkSlot: forAllChildrenAux(cast[pointer](d +% n.offset), n.typ, op)
  of nkList:
    for i in 0..n.len-1: forAllSlotsAux(dest, n.sons[i], op)
  of nkCase:
    var m = selectBranch(dest, n)
    if m != nil: forAllSlotsAux(dest, m, op)

proc forAllChildrenAux(dest: Pointer, mt: PNimType, op: TWalkOp) =
  var d = cast[TAddress](dest)
  if dest == nil: return # nothing to do
  if ntfNoRefs notin mt.flags:
    case mt.Kind
    of tyArray, tyArrayConstr, tyOpenArray:
      for i in 0..(mt.size div mt.base.size)-1:
        forAllChildrenAux(cast[pointer](d +% i *% mt.base.size), mt.base, op)
    of tyRef, tyString, tySequence: # leaf:
      doOperation(cast[ppointer](d)^, op)
    of tyObject, tyTuple, tyPureObject:
      forAllSlotsAux(dest, mt.node, op)
    else: nil

proc forAllChildren(cell: PCell, op: TWalkOp) =
  assert(cell != nil)
  assert(cell.typ != nil)
  case cell.typ.Kind
  of tyRef: # common case
    forAllChildrenAux(cellToUsr(cell), cell.typ.base, op)
  of tySequence:
    var d = cast[TAddress](cellToUsr(cell))
    var s = cast[PGenericSeq](d)
    if s != nil:
      for i in 0..s.len-1:
        forAllChildrenAux(cast[pointer](d +% i *% cell.typ.base.size +%
          GenericSeqSize), cell.typ.base, op)
  of tyString: nil
  else: assert(false)

proc checkCollection(zctUpdated: bool) {.inline.} =
  # checks if a collection should be done
  if recGcLock == 0:
    collectCT(gch, zctUpdated)

proc newObj(typ: PNimType, size: int): pointer =
  # generates a new object and sets its reference counter to 0
  assert(typ.kind in {tyRef, tyString, tySequence})
  var zctUpdated = false
  if gch.zct.len >= ZctThreshold:
    updateZCT()
    zctUpdated = true
  # check if we have to collect:
  checkCollection(zctUpdated)
  var res = cast[PCell](gcAlloc(size + sizeof(TCell)))
  when stressGC: assert((cast[TAddress](res) and (MemAlignment-1)) == 0)
  # now it is buffered in the ZCT
  res.typ = typ
  when debugGC:
    if framePtr != nil and framePtr.prev != nil:
      res.filename = framePtr.prev.filename
      res.line = framePtr.prev.line
  res.refcount = rcZct # refcount is zero, but mark it to be in the ZCT
  add(gch.zct, res) # its refcount is zero, so add it to the ZCT
  gch.mask = gch.mask or cast[TAddress](res)
  when logGC: writeCell("new cell", res)
  gcTrace(res, csAllocated)
  result = cellToUsr(res)

proc newSeq(typ: PNimType, len: int): pointer =
  # XXX: overflow checks!
  result = newObj(typ, len * typ.base.size + GenericSeqSize)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).space = len

proc growObj(old: pointer, newsize: int): pointer =
  checkCollection(false)
  var ol = usrToCell(old)
  assert(ol.typ != nil)
  assert(ol.typ.kind in {tyString, tySequence})
  var res = cast[PCell](gcAlloc(newsize + sizeof(TCell)))
  var elemSize = 1
  if ol.typ.kind != tyString:
    elemSize = ol.typ.base.size
  copyMem(res, ol, cast[PGenericSeq](old).len*elemSize +
          GenericSeqSize + sizeof(TCell))

  assert((cast[TAddress](res) and (MemAlignment-1)) == 0)
  assert(res.refcount shr rcShift <=% 1)
  #if res.refcount <% rcIncrement:
  #  add(gch.zct, res)
  #else: # XXX: what to do here?
  #  decRef(ol)
  if (ol.refcount and colorMask) == rcZct:
    var j = gch.zct.len-1
    var d = gch.zct.d
    while j >= 0: 
      if d[j] == ol:
        d[j] = res
        break
      dec(j)
  if canBeCycleRoot(ol): excl(gch.cycleRoots, ol)
  gch.mask = gch.mask or cast[TAddress](res)
  when logGC:
    writeCell("growObj old cell", ol)
    writeCell("growObj new cell", res)
  gcTrace(ol, csZctFreed)
  gcTrace(res, csAllocated)
  when reallyDealloc: tlsf_free(ol)
  else:
    assert(ol.typ != nil)
    zeroMem(ol, sizeof(TCell))
  result = cellToUsr(res)

# ---------------- cycle collector -------------------------------------------

# When collecting cycles, we have to consider the following:
# * there may still be references in the stack
# * some cells may still be in the ZCT, because they are referenced from
#   the stack (!), so their refcounts are zero
# the ZCT is a subset of stackCells here, so we only need to care
# for stackcells

proc doOperation(p: pointer, op: TWalkOp) =
  if p == nil: return
  var c: PCell = usrToCell(p)
  assert(c != nil)
  case op # faster than function pointers because of easy prediction
  of waZctDecRef:
    assert(c.refcount >=% rcIncrement)
    c.refcount = c.refcount -% rcIncrement
    when logGC: writeCell("decref (from doOperation)", c)
    if c.refcount <% rcIncrement: addZCT(gch.zct, c)
  of waPush:
    add(gch.tempStack, c)
  of waCycleDecRef:
    assert(c.refcount >=% rcIncrement)
    c.refcount = c.refcount -% rcIncrement

# we now use a much simpler and non-recursive algorithm for cycle removal
proc collectCycles(gch: var TGcHeap) =
  var tabSize = 0
  for c in elements(gch.cycleRoots):
    inc(tabSize)
    forallChildren(c, waCycleDecRef)
  gch.cycleTableSize = max(gch.cycleTableSize, tabSize)

  # restore reference counts (a depth-first traversal is needed):
  var marker, newRoots: TCellSet
  CellSetInit(marker)
  CellSetInit(newRoots)
  for c in elements(gch.cycleRoots):
    var needsRestore = false
    if c in gch.stackCells:
      needsRestore = true
      incl(newRoots, c)
      # we need to scan this later again; maybe stack changes
      # NOTE: adding to ZCT here does NOT work
    elif c.refcount >=% rcIncrement:
      needsRestore = true
    if needsRestore:
      if c notin marker:
        incl(marker, c)
        gch.tempStack.len = 0
        forAllChildren(c, waPush)
        while gch.tempStack.len > 0:
          dec(gch.tempStack.len)
          var d = gch.tempStack.d[gch.tempStack.len]
          d.refcount = d.refcount +% rcIncrement
          if d notin marker and d in gch.cycleRoots:
            incl(marker, d)
            forAllChildren(d, waPush)
  # remove cycles:
  for c in elements(gch.cycleRoots):
    if c.refcount <% rcIncrement and c notin gch.stackCells:
      gch.tempStack.len = 0
      forAllChildren(c, waPush)
      while gch.tempStack.len > 0:
        dec(gch.tempStack.len)
        var d = gch.tempStack.d[gch.tempStack.len]
        if d.refcount <% rcIncrement:
          if d notin gch.cycleRoots: # d is leaf of c and not part of cycle
            addZCT(gch.zct, d)
            when logGC: writeCell("add to ZCT (from cycle collector)", d)
      prepareDealloc(c)
      gcTrace(c, csCycFreed)
      when logGC: writeCell("cycle collector dealloc cell", c)
      when reallyDealloc: tlsf_free(c)
      else:
        assert(c.typ != nil)
        zeroMem(c, sizeof(TCell))
  CellSetDeinit(gch.cycleRoots)
  gch.cycleRoots = newRoots

proc gcMark(p: pointer) = # {.fastcall.} =
  # the addresses are not as objects on the stack, so turn them to objects:
  var cell = usrToCell(p)
  var c = cast[TAddress](cell)
  if ((c and gch.mask) == c) and c >% 1024:
    # fast check: does it look like a cell?
    when logGC: cfprintf(cstdout, "in stackcells %p\n", cell)
    incl(gch.stackCells, cell)  # yes: mark it

# ----------------- stack management --------------------------------------
#  inspired from Smart Eiffel (c)

proc stackSize(): int {.noinline.} =
  var stackTop: array[0..1, pointer]
  result = abs(cast[int](addr(stackTop[0])) - cast[int](stackBottom))

when defined(sparc): # For SPARC architecture.

  proc isOnStack(p: pointer): bool =
    var
      stackTop: array[0..1, pointer]
    result = p >= addr(stackTop[0]) and p <= stackBottom

  proc markStackAndRegisters(gch: var TGcHeap) {.noinline, cdecl.} =
    when defined(sparcv9):
      asm  """"flushw \n" """
    else:
      asm  """"ta      0x3   ! ST_FLUSH_WINDOWS\n" """

    var
      max = stackBottom
      sp: PPointer
      stackTop: array[0..1, pointer]
    sp = addr(stackTop[0])
    # Addresses decrease as the stack grows.
    while sp <= max:
      gcMark(sp^)
      sp = cast[ppointer](cast[TAddress](sp) +% sizeof(pointer))

elif defined(ELATE):
  {.error: "stack marking code is to be written for this architecture".}

elif defined(hppa) or defined(hp9000) or defined(hp9000s300) or
     defined(hp9000s700) or defined(hp9000s800) or defined(hp9000s820):
  # ---------------------------------------------------------------------------
  # Generic code for architectures where addresses increase as the stack grows.
  # ---------------------------------------------------------------------------

  proc isOnStack(p: pointer): bool =
    var
      stackTop: array[0..1, pointer]
    result = p <= addr(stackTop[0]) and p >= stackBottom

  var
    jmpbufSize {.importc: "sizeof(jmp_buf)", nodecl.}: int
      # a little hack to get the size of a TJmpBuf in the generated C code
      # in a platform independant way

  proc markStackAndRegisters(gch: var TGcHeap) {.noinline, cdecl.} =
    var
      max = stackBottom
      registers: C_JmpBuf # The jmp_buf buffer is in the C stack.
      sp: PPointer        # Used to traverse the stack and registers assuming
                          # that `setjmp' will save registers in the C stack.
    if c_setjmp(registers) == 0: # To fill the C stack with registers.
      sp = cast[ppointer](cast[TAddress](addr(registers)) +%
             jmpbufSize -% sizeof(pointer))
      # sp will traverse the JMP_BUF as well (jmp_buf size is added,
      # otherwise sp would be below the registers structure).
      while sp >= max:
        gcMark(sp^)
        sp = cast[ppointer](cast[TAddress](sp) -% sizeof(pointer))

elif defined(I386) and asmVersion:
  # addresses decrease as the stack grows:
  proc isOnStack(p: pointer): bool =
    var
      stackTop: array [0..1, pointer]
    result = p >= addr(stackTop[0]) and p <= stackBottom

  proc markStackAndRegisters(gch: var TGcHeap) {.noinline, cdecl.} =
    # This code should be safe even for aggressive optimizers. The try
    # statement safes all registers into the safepoint, which we
    # scan additionally to the stack.
    type
      TPtrArray = array[0..0xffffff, pointer]
    try:
      var pa = cast[ptr TPtrArray](excHandler)
      for i in 0 .. sizeof(TSafePoint) - 1:
        gcMark(pa[i])
    finally:
      # iterate over the stack:
      var max = cast[TAddress](stackBottom)
      var stackTop{.volatile.}: array [0..15, pointer]
      var sp {.volatile.} = cast[TAddress](addr(stackTop[0]))
      while sp <= max:
        gcMark(cast[ppointer](sp)^)
        sp = sp +% sizeof(pointer)
    when false:
      var counter = 0
      #mov ebx, OFFSET `stackBottom`
      #mov ebx, [ebx]
      asm """
        pusha
        mov edi, esp
        call `getStackBottom`
        mov ebx, eax
      L1:
        cmp edi, ebx
        ja L2
        mov eax, [edi]
        call `gcMark`
        add edi, 4
        inc [`counter`]
        jmp L1
      L2:
        popa
      """
      cfprintf(cstdout, "stack %ld\n", counter)

else:
  # ---------------------------------------------------------------------------
  # Generic code for architectures where addresses decrease as the stack grows.
  # ---------------------------------------------------------------------------
  proc isOnStack(p: pointer): bool =
    var
      stackTop: array [0..1, pointer]
    result = p >= addr(stackTop[0]) and p <= stackBottom

  var
    gRegisters: C_JmpBuf
    jmpbufSize {.importc: "sizeof(jmp_buf)", nodecl.}: int
      # a little hack to get the size of a TJmpBuf in the generated C code
      # in a platform independant way

  proc markStackAndRegisters(gch: var TGcHeap) {.noinline, cdecl.} =
    when true:
      # new version: several C compilers are too smart here
      var
        max = cast[TAddress](stackBottom)
        stackTop: array [0..15, pointer]
      if c_setjmp(gregisters) == 0'i32: # To fill the C stack with registers.
        # iterate over the registers:
        var sp = cast[TAddress](addr(gregisters))
        while sp < cast[TAddress](addr(gregisters))+%jmpbufSize:
          gcMark(cast[ppointer](sp)^)
          sp = sp +% sizeof(pointer)
        # iterate over the stack:
        sp = cast[TAddress](addr(stackTop[0]))
        while sp <= max:
          gcMark(cast[ppointer](sp)^)
          sp = sp +% sizeof(pointer)
      else:
        c_longjmp(gregisters, 42)
        # this can never happen, but should trick any compiler that is
        # not as smart as a human
    else:
      var
        max = stackBottom
        registers: C_JmpBuf # The jmp_buf buffer is in the C stack.
        sp: PPointer        # Used to traverse the stack and registers assuming
                            # that `setjmp' will save registers in the C stack.
      if c_setjmp(registers) == 0'i32: # To fill the C stack with registers.
        sp = cast[ppointer](addr(registers))
        while sp <= max:
          gcMark(sp^)
          sp = cast[ppointer](cast[TAddress](sp) +% sizeof(pointer))

# ----------------------------------------------------------------------------
# end of non-portable code
# ----------------------------------------------------------------------------

proc updateZCT() =
  # We have to make an additional pass over the ZCT unfortunately, because 
  # the ZCT may be out of date, which means it contains cells with a
  # refcount > 0. The reason is that ``incRef`` does not bother to remove
  # the cell from the ZCT as this might be too slow.
  var j = 0
  var L = gch.zct.len # because globals make it hard for the optimizer
  var d = gch.zct.d
  while j < L:
    var c = d[j]
    if c.refcount >=% rcIncrement:
      when logGC: writeCell("remove from ZCT", c)
      # remove from ZCT:
      dec(L)
      d[j] = d[L]
      c.refcount = c.refcount and not colorMask
      # we have a new cell at position i, so don't increment i
    else:
      inc(j)
  gch.zct.len = L

proc CollectZCT(gch: var TGcHeap) =
  var i = 0
  while i < gch.zct.len:
    var c = gch.zct.d[i]
    assert(c.refcount <% rcIncrement)
    assert((c.refcount and colorMask) == rcZct)
    if canBeCycleRoot(c): excl(gch.cycleRoots, c)
    if c notin gch.stackCells:
      # remove from ZCT:
      c.refcount = c.refcount and not colorMask
      gch.zct.d[i] = gch.zct.d[gch.zct.len-1]
      # we have a new cell at position i, so don't increment i
      dec(gch.zct.len)
      when logGC: writeCell("zct dealloc cell", c)
      gcTrace(c, csZctFreed)
      # We are about to free the object, call the finalizer BEFORE its
      # children are deleted as well, because otherwise the finalizer may
      # access invalid memory. This is done by prepareDealloc():
      prepareDealloc(c)
      forAllChildren(c, waZctDecRef)
      when reallyDealloc: tlsf_free(c)
      else:
        assert(c.typ != nil)
        zeroMem(c, sizeof(TCell))
    else:
      inc(i)
  when stressGC:
    for j in 0..gch.zct.len-1: assert(gch.zct.d[j] in gch.stackCells)

proc collectCT(gch: var TGcHeap, zctUpdated: bool) =
  if gch.zct.len >= ZctThreshold or (cycleGC and
      getOccupiedMem() >= cycleThreshold) or stressGC:    
    if not zctUpdated: updateZCT()
    gch.maxStackSize = max(gch.maxStackSize, stackSize())
    CellSetInit(gch.stackCells)
    markStackAndRegisters(gch)
    gch.maxStackPages = max(gch.maxStackPages, gch.stackCells.counter)
    inc(gch.stackScans)
    collectZCT(gch)
    when cycleGC:
      if getOccupiedMem() >= cycleThreshold or stressGC:
        collectCycles(gch)
        collectZCT(gch)
        inc(gch.cycleCollections)
        cycleThreshold = max(InitialCycleThreshold, getOccupiedMem() *
                             cycleIncrease)
        gch.maxThreshold = max(gch.maxThreshold, cycleThreshold)
    CellSetDeinit(gch.stackCells)

proc GC_fullCollect() =
  var oldThreshold = cycleThreshold
  cycleThreshold = 0 # forces cycle collection
  collectCT(gch, false)
  cycleThreshold = oldThreshold

proc GC_getStatistics(): string =
  GC_disable()
  result = "[GC] total memory: " & $(getTotalMem()) & "\n" &
           "[GC] occupied memory: " & $(getOccupiedMem()) & "\n" &
           "[GC] stack scans: " & $gch.stackScans & "\n" &
           "[GC] stack pages: " & $gch.maxStackPages & "\n" &
           "[GC] cycle collections: " & $gch.cycleCollections & "\n" &
           "[GC] max threshold: " & $gch.maxThreshold & "\n" &
           "[GC] zct capacity: " & $gch.zct.cap & "\n" &
           "[GC] max cycle table size: " & $gch.cycleTableSize & "\n" &
           "[GC] max stack size: " & $gch.maxStackSize
  when traceGC: writeLeakage()
  GC_enable()
