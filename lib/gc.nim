#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


#            Garbage Collector

# For a description of the algorithms used here see:
# intern.html

{.define: debugGC.}   # we wish to debug the GC...

#when defined(debugGC):
#  {.define: logGC.} # define if the GC should log some of its activities

{.define: cycleGC.}

const
  traceGC = false # extensive debugging
  reallyDealloc = true # for debugging purposes this can be set to false

# Guess the page size of the system; if it is the
# wrong value, performance may be worse (this is not
# for sure though), but GC still works; must be a power of two!
const
  PageShift = if sizeof(pointer) == 4: 12 else: 13
  PageSize = 1 shl PageShift # on 32 bit systems 4096
  CycleIncrease = 2 # is a multiplicative increase

  InitialCycleThreshold = 8*1024*1024 # X MB because cycle checking is slow
  ZctThreshold = 512  # we collect garbage if the ZCT's size
                      # reaches this threshold
                      # this needs benchmarking...

when defined(debugGC):
  const stressGC = False
else:
  const stressGC = False

# things the System module thinks should be available:
when defined(useDL) or defined(nativeDL):
  type
    TMallocInfo {.importc: "struct mallinfo", nodecl, final.} = object
      arena: cint    # non-mmapped space allocated from system
      ordblks: cint  # number of free chunks
      smblks: cint   # number of fastbin blocks
      hblks: cint    # number of mmapped regions
      hblkhd: cint   # space in mmapped regions
      usmblks: cint  # maximum total allocated space
      fsmblks: cint  # space available in freed fastbin blocks
      uordblks: cint # total allocated space
      fordblks: cint # total free space
      keepcost: cint # top-most, releasable (via malloc_trim) space

when defined(useDL):
  proc mallinfo: TMallocInfo {.importc: "dlmallinfo", nodecl.}
elif defined(nativeDL):
  proc mallinfo: TMallocInfo {.importc: "mallinfo", nodecl.}

when defined(useDL) or defined(nativeDL):
  proc getOccupiedMem(): int = return mallinfo().uordblks
  proc getFreeMem(): int = return mallinfo().fordblks
  proc getTotalMem(): int =
    var m = mallinfo()
    return int(m.hblkhd) + int(m.arena)
else: # not available:
  proc getOccupiedMem(): int = return -1
  proc getFreeMem(): int = return -1
  proc getTotalMem(): int = return -1

var
  cycleThreshold: int = InitialCycleThreshold

  memUsed: int = 0 # we have to keep track how much we have allocated

  recGcLock: int = 0
    # we use a lock to prevend the garbage collector to
    # be triggered in a finalizer; the collector should not call
    # itself this way! Thus every object allocated by a finalizer
    # will not trigger a garbage collection. This is wasteful but safe.
    # This is a lock against recursive garbage collection, not a lock for
    # threads!

when defined(useDL) and not defined(nativeDL):
  {.compile: "dlmalloc.c".}

type
  TFinalizer {.compilerproc.} = proc (self: pointer)
    # A ref type can have a finalizer that is called before the object's
    # storage is freed.
  PPointer = ptr pointer

proc asgnRef(dest: ppointer, src: pointer) {.compilerproc.}
proc unsureAsgnRef(dest: ppointer, src: pointer) {.compilerproc.}
  # unsureAsgnRef updates the reference counters only if dest is not on the
  # stack. It is used by the code generator if it cannot decide wether a
  # reference is in the stack or not (this can happen for out/var parameters).
proc growObj(old: pointer, newsize: int): pointer {.compilerproc.}
proc newObj(typ: PNimType, size: int): pointer {.compilerproc.}
proc newSeq(typ: PNimType, len: int): pointer {.compilerproc.}

# implementation:

when defined(useDL):
  proc nimSize(p: pointer): int {.
    importc: "dlmalloc_usable_size", header: "dlmalloc.h".}
elif defined(nativeDL):
  proc nimSize(p: pointer): int {.
    importc: "malloc_usable_size", header: "<malloc.h>".}

type
  TWalkOp = enum
    waNone, waRelease, waZctDecRef, waCycleDecRef, waCycleIncRef, waDebugIncRef

  TCollectorData = int
  TCell {.final.} = object
    refcount: TCollectorData  # the refcount and bit flags
    typ: PNimType
    when stressGC:
      stackcount: int           # stack counter for debugging
      drefc: int                # real reference counter for debugging

  PCell = ptr TCell

var
  gOutOfMem: ref EOutOfMemory

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

proc extGetCellType(c: pointer): PNimType {.compilerproc.} =
  # used for code generation concerning debugging
  result = usrToCell(c).typ

proc internRefcount(p: pointer): int {.exportc: "getRefcount".} =
  result = int(usrToCell(p).refcount)
  if result < 0: result = 0

proc gcAlloc(size: int): pointer =
  result = alloc0(size)
  if result == nil: raiseOutOfMem()

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

# ------------------ Any table (AT) -------------

# these values are for DL-malloc known for sure (and other allocators
# can only be worse):
when defined(useDL) or not defined(bcc):
  const MemAlignment = 8 # minimal memory block that can be allocated
else:
  const MemAlignment = 4 # Borland's memory manager is terrible!

const
  BitsPerUnit = sizeof(int)*8
    # a "unit" is a word, i.e. 4 bytes
    # on a 32 bit system; I do not use the term "word" because under 32-bit
    # Windows it is sometimes only 16 bits

  BitsPerPage = PageSize div MemAlignment
  UnitsPerPage = BitsPerPage div BitsPerUnit
    # how many units do we need to describe a page:
    # on 32 bit systems this is only 16 (!)

# this that has to equals zero, otherwise we have to round up UnitsPerPage:
when BitsPerPage mod BitsPerUnit != 0:
  {.error: "(BitsPerPage mod BitsPerUnit) should be zero!".}

# ------------------- cell set handling ------------------------------
# A cellset consists of a hash table of page descriptors. A page
# descriptor has a bit for every Memalignment'th byte in the page.
# However, only bits corresponding to addresses that start memory blocks
# are set.
# Page descriptors are also linked to a list; the list
# is used for easy traversing of all page descriptors; this allows a
# fast iterator.
# We use a specialized hashing scheme; the formula is :
# hash = Page bitand max
# We use linear probing with the formular: (5*h)+1
# Thus we likely get no collisions at all if the pages are given us
# sequentially by the operating system!
type
  PPageDesc = ptr TPageDesc

  TBitIndex = range[0..UnitsPerPage-1]

  TPageDesc {.final.} = object
    next: PPageDesc # all nodes are connected with this pointer
    key: TAddress   # start address at bit 0
    bits: array[TBitIndex, int] # a bit vector

  PPageDescArray = ptr array[0..1000_000, PPageDesc]
  TCellSet {.final.} = object
    counter, max: int
    head: PPageDesc
    data: PPageDescArray

  PCellArray = ptr array[0..100_000_000, PCell]
  TCellSeq {.final.} = object
    len, cap: int
    d: PCellArray

  TSlowSet {.final.} = object  # used for debugging purposes only
    L: int # current length
    cap: int # capacity
    d: PCellArray

  TGcHeap {.final.} = object # this contains the zero count and
                             # non-zero count table
    mask: TAddress           # mask for fast pointer detection
    zct: TCellSeq            # the zero count table
    at: TCellSet             # a table that contains all references
    newAT: TCellSet
    stackCells: TCellSeq     # cells that need to be decremented because they
                             # are in the hardware stack; a cell may occur
                             # several times in this data structure

var
  stackBottom: pointer
  gch: TGcHeap

proc add(s: var TCellSeq, c: PCell) {.inline.} =
  if s.len >= s.cap:
    s.cap = s.cap * 3 div 2
    s.d = cast[PCellArray](realloc(s.d, s.cap * sizeof(PCell)))
    if s.d == nil: raiseOutOfMem()
  s.d[s.len] = c
  inc(s.len)

proc inOperator(s: TCellSeq, c: PCell): bool {.inline.} =
  for i in 0 .. s.len-1:
    if s.d[i] == c: return True
  return False

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
    dealloc(it)
    it = n
  s.head = nil # play it safe here
  dealloc(s.data)
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
  var
    n: PPageDescArray
    oldMax = t.max
  t.max = ((t.max+1)*2)-1
  n = cast[PPageDescArray](gcAlloc((t.max + 1) * sizeof(PPageDesc)))
  for i in 0 .. oldmax:
    if t.data[i] != nil:
      CellSetRawInsert(t, n, t.data[i])
  dealloc(t.data)
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

# ---------- slightly higher level procs ----------------------------------

proc in_Operator(s: TCellSet, cell: PCell): bool =
  var
    u: TAddress
    t: PPageDesc
  u = cast[TAddress](cell)
  t = CellSetGet(s, u shr PageShift)
  if t != nil:
    u = (u %% PageSize) /% MemAlignment
    result = (t.bits[u /% BitsPerUnit] and (1 shl (u %% BitsPerUnit))) != 0
  else:
    result = false

proc incl(s: var TCellSet, cell: PCell) =
  var
    u: TAddress
    t: PPageDesc
  u = cast[TAddress](cell)
  t = CellSetPut(s, u shr PageShift)
  u = (u %% PageSize) /% MemAlignment
  t.bits[u /% BitsPerUnit] = t.bits[u /% BitsPerUnit] or
    (1 shl (u %% BitsPerUnit))

proc excl(s: var TCellSet, cell: PCell) =
  var
    u: TAddress
    t: PPageDesc
  u = cast[TAddress](cell)
  t = CellSetGet(s, u shr PageShift)
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

proc testPageDescs() =
  var root: TCellSet
  CellSetInit(root)
  #var u = 10_000
  #while u <= 20_000:
  #  incl(root, cast[PCell](u))
  #  inc(u, 8)

  incl(root, cast[PCell](0x81cdfb8))
  for cell in elements(root):
    c_fprintf(c_stdout, "%p\n", cast[int](cell))

#testPageDescs()

when defined(debugGC):
  proc writeCell(msg: CString, c: PCell) =
    if c.typ != nil:
      if c.typ.kind == tyString:
        c_fprintf(c_stdout, "%s\n", cast[TAddress](cellToUsr(c)) + sizeof(int)*2)
      c_fprintf(c_stdout, "%s: %p %d\n", msg, c, c.typ.kind)
    else: c_fprintf(c_stdout, "%s: %p (nil type)\n", msg, c)
  proc writePtr(msg: CString, p: Pointer) =
    c_fprintf(c_stdout, "%s: %p\n", msg, p)


when traceGC:
  # traceGC is a special switch to enable extensive debugging
  type
    TCellState = enum
      csAllocated, csZctFreed, csCycFreed

  proc cellSetInit(s: var TSlowSet) =
    s.L = 0
    s.cap = 4096
    s.d = cast[PCellArray](gcAlloc(s.cap * sizeof(PCell)))

  proc cellSetDeinit(s: var TSlowSet) =
    s.L = 0
    s.cap = 0
    dealloc(s.d)

  proc incl(s: var TSlowSet, c: PCell) =
    if s.L >= s.cap:
      s.cap = s.cap * 3 div 2
      s.d = cast[PCellArray](realloc(s.d, s.cap * sizeof(PCell)))
      if s.d == nil: raiseOutOfMem()
    s.d[s.L] = c
    inc(s.L)

  proc excl(s: var TSlowSet, c: PCell) =
    var i = 0
    while i < s.L:
      if s.d[i] == c:
        s.d[i] = s.d[s.L-1]
        dec(s.L)
        break
      inc(i)

  proc inOperator(s: TSlowSet, c: PCell): bool =
    var i = 0
    while i < s.L:
      if s.d[i] == c: return true
      inc(i)

  iterator elements(s: TSlowSet): PCell =
    var i = 0
    while i < s.L:
      yield s.d[i]
      inc(i)

  var
    states: array[TCellState, TSlowSet] # TCellSet]

  proc traceCell(c: PCell, state: TCellState) =
    case state
    of csAllocated:
      if c in states[csAllocated]:
        writeCell("attempt to alloc a already allocated cell", c)
        assert(false)
      excl(states[csCycFreed], c)
      excl(states[csZctFreed], c)
    of csZctFreed:
      if c notin states[csAllocated]:
        writeCell("attempt to free a not allocated cell", c)
        assert(false)
      if c in states[csZctFreed]:
        writeCell("attempt to free zct cell twice", c)
        assert(false)
      if c in states[csCycFreed]:
        writeCell("attempt to free with zct, but already freed with cyc", c)
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

template gcTrace(cell, state: expr): stmt =
  when traceGC: traceCell(cell, state)

# -------------------------------------------------------------------------

# forward declarations:
proc collectCT(gch: var TGcHeap)
proc IsOnStack(p: pointer): bool
proc forAllChildren(cell: PCell, op: TWalkOp)
proc collectCycles(gch: var TGcHeap)

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

  when defined(nimSize):
    memUsed = memUsed - nimSize(cell)
  else:
    memUsed = memUsed - cell.typ.size

proc checkZCT(): bool =
  if recGcLock >= 1: return true # prevent endless recursion
  inc(recGcLock)
  result = true
  for i in 0..gch.zct.len-1:
    var c = gch.zct.d[i]
    if c.refcount > 0: # should be in the ZCT!
      writeCell("wrong ZCT entry", c)
      result = false
    elif gch.zct.d[-c.refcount] != c:
      writeCell("wrong ZCT position", c)
      result = false
  dec(recGcLock)

proc GC_invariant(): bool =
  if recGcLock >= 1: return true # prevent endless recursion
  inc(recGcLock)
  result = True
  block checks:
    if not checkZCT():
      result = false
      break checks
    # set counters back to zero:
    for c in elements(gch.AT):
      var t = c.typ
      if t == nil or t.kind notin {tySequence, tyString, tyRef}:
        writeCell("corrupt cell?", c)
        result = false
        break checks
      when stressGC: c.drefc = 0
    for c in elements(gch.AT):
      forAllChildren(c, waDebugIncRef)
    when stressGC:
      for c in elements(gch.AT):
        var rc = c.refcount
        if rc < 0: rc = 0
        if c.drefc > rc + c.stackcount:
          result = false # failed
          c_fprintf(c_stdout,
             "broken cell: %p, refc: %ld, stack: %ld, real: %ld\n",
             c, c.refcount, c.stackcount, c.drefc)
          break checks
  dec(recGcLock)

when stressGC:
  proc GCdebugHook() =
    if not GC_invariant():
      assert(false)

  dbgLineHook = GCdebugHook

proc setStackBottom(theStackBottom: pointer) {.compilerproc.} =
  stackBottom = theStackBottom

proc initGC() =
  when traceGC:
    for i in low(TCellState)..high(TCellState): CellSetInit(states[i])
  # init the rt
  init(gch.zct)
  CellSetInit(gch.at)
  init(gch.stackCells)
  gch.mask = 0
  new(gOutOfMem) # reserve space for the EOutOfMemory exception here!
  assert(GC_invariant())

proc decRef(cell: PCell) {.inline.} =
  assert(cell.refcount > 0) # this should be the case!
  when stressGC: assert(cell in gch.AT)
  dec(cell.refcount)
  if cell.refcount == 0:
    cell.refcount = -gch.zct.len
    when stressGC: assert(cell notin gch.zct)
    add(gch.zct, cell)
  when stressGC: assert(checkZCT())

proc incRef(cell: PCell) {.inline.} =
  var rc = cell.refcount
  if rc <= 0:
    # remove from zero count table:
    when stressGC: assert(gch.zct.len > -rc)
    when stressGC: assert(gch.zct.d[-rc] == cell)
    gch.zct.d[-rc] = gch.zct.d[gch.zct.len-1]
    gch.zct.d[-rc].refcount = rc
    dec(gch.zct.len)
    cell.refcount = 1
    when stressGC: assert(checkZCT())
  else:
    inc(cell.refcount)
    when stressGC: assert(checkZCT())

proc asgnRef(dest: ppointer, src: pointer) =
  # the code generator calls this proc!
  assert(not isOnStack(dest))
  # BUGFIX: first incRef then decRef!
  if src != nil: incRef(usrToCell(src))
  if dest^ != nil: decRef(usrToCell(dest^))
  dest^ = src
  when stressGC: assert(GC_invariant())

proc unsureAsgnRef(dest: ppointer, src: pointer) =
  if not IsOnStack(dest):
    if src != nil: incRef(usrToCell(src))
    if dest^ != nil: decRef(usrToCell(dest^))
  dest^ = src
  when stressGC: assert(GC_invariant())

proc restore(cell: PCell) =
  if cell notin gch.newAT:
    incl(gch.newAT, Cell)
    forAllChildren(cell, waCycleIncRef)

proc doOperation(p: pointer, op: TWalkOp) =
  if p == nil: return
  var cell: PCell = usrToCell(p)
  assert(cell != nil)
  case op # faster than function pointers because of easy prediction
  of waNone: assert(false)
  of waRelease: decRef(cell) # DEAD CODE!
  of waZctDecRef:
    decRef(cell)
  of waCycleDecRef:
    assert(cell.refcount > 0)
    dec(cell.refcount)
  of waCycleIncRef:
    inc(cell.refcount) # restore proper reference counts!
    restore(cell)
  of waDebugIncRef:
    when stressGC: inc(cell.drefc)

type
  TByteArray = array[0..1000_0000, byte]
  PByte = ptr TByteArray
  PString = ptr string

proc forAllChildrenAux(dest: Pointer, mt: PNimType, op: TWalkOp)

proc getDiscriminant(aa: Pointer, n: ptr TNimNode): int =
  assert(n.kind == nkCase)
  var d: int32
  var a = cast[TAddress](aa)
  case n.typ.size
  of 1: d = toU32(cast[ptr int8](a +% n.offset)^)
  of 2: d = toU32(cast[ptr int16](a +% n.offset)^)
  of 4: d = toU32(cast[ptr int32](a +% n.offset)^)
  else: assert(false)
  return int(d)

proc selectBranch(aa: Pointer, n: ptr TNimNode): ptr TNimNode =
  var discr = getDiscriminant(aa, n)
  if discr <% n.len:
    result = n.sons[discr]
    if result == nil: result = n.sons[n.len]
    # n.sons[n.len] contains the ``else`` part (but may be nil)
  else:
    result = n.sons[n.len]

proc forAllSlotsAux(dest: pointer, n: ptr TNimNode, op: TWalkOp) =
  var
    d = cast[TAddress](dest)
  case n.kind
  of nkNone: assert(false)
  of nkSlot: forAllChildrenAux(cast[pointer](d +% n.offset), n.typ, op)
  of nkList:
    for i in 0..n.len-1: forAllSlotsAux(dest, n.sons[i], op)
  of nkCase:
    var m = selectBranch(dest, n)
    if m != nil: forAllSlotsAux(dest, m, op)

proc forAllChildrenAux(dest: Pointer, mt: PNimType, op: TWalkOp) =
  const
    handledTypes = {tyArray, tyArrayConstr, tyOpenArray, tyRef,
                    tyString, tySequence, tyObject, tyPureObject, tyTuple}
  var
    d = cast[TAddress](dest)
  if dest == nil: return # nothing to do
  case mt.Kind
  of tyArray, tyArrayConstr, tyOpenArray:
    if mt.base.kind in handledTypes:
      for i in 0..(mt.size div mt.base.size)-1:
        forAllChildrenAux(cast[pointer](d +% i *% mt.base.size), mt.base, op)
  of tyRef, tyString, tySequence: # leaf:
    doOperation(cast[ppointer](d)^, op)
  of tyObject, tyTuple, tyPureObject:
    forAllSlotsAux(dest, mt.node, op)
  else: nil

proc forAllChildren(cell: PCell, op: TWalkOp) =
  assert(cell != nil)
  when defined(debugGC):
    if cell.typ == nil:
      writeCell("cell has no type descriptor", cell)
      when traceGC:
        if cell notin states[csAllocated]:
          writeCell("cell has never been allocated!", cell)
        if cell in states[csCycFreed]:
          writeCell("cell has been freed by Cyc", cell)
        if cell in states[csZctFreed]:
          writeCell("cell has been freed by Zct", cell)
  assert(cell.typ != nil)
  case cell.typ.Kind
  of tyRef: # common case
    forAllChildrenAux(cellToUsr(cell), cell.typ.base, op)
  of tySequence:
    var d = cast[TAddress](cellToUsr(cell))
    var s = cast[PGenericSeq](d)
    if s != nil: # BUGFIX
      for i in 0..s.len-1:
        forAllChildrenAux(cast[pointer](d +% i *% cell.typ.base.size +%
          GenericSeqSize), cell.typ.base, op)
  of tyString: nil
  else: assert(false)

proc checkCollection() {.inline.} =
  # checks if a collection should be done
  if recGcLock == 0:
    collectCT(gch)

proc newObj(typ: PNimType, size: int): pointer =
  # generates a new object and sets its reference counter to 0
  var
    res: PCell
  when stressGC: assert(checkZCT())
  assert(typ.kind in {tyRef, tyString, tySequence})
  # check if we have to collect:
  checkCollection()
  res = cast[PCell](Alloc0(size + sizeof(TCell)))
  when stressGC: assert((cast[TAddress](res) and (MemAlignment-1)) == 0)
  if res == nil: raiseOutOfMem()
  when defined(nimSize):
    memUsed = memUsed + nimSize(res)
  else:
    memUsed = memUsed + size

  # now it is buffered in the ZCT
  res.typ = typ
  res.refcount = -gch.zct.len
  add(gch.zct, res)  # its refcount is zero, so add it to the ZCT
  incl(gch.at, res)  # add it to the any table too
  gch.mask = gch.mask or cast[TAddress](res)
  when defined(debugGC):
    when defined(logGC): writeCell("new cell", res)
  gcTrace(res, csAllocated)
  result = cellToUsr(res)
  assert(res.typ == typ)
  when stressGC: assert(checkZCT())

proc newSeq(typ: PNimType, len: int): pointer =
  # XXX: overflow checks!
  result = newObj(typ, len * typ.base.size + GenericSeqSize)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).space = len

proc growObj(old: pointer, newsize: int): pointer =
  var
    res, ol: PCell
  when stressGC: assert(checkZCT())
  checkCollection()
  ol = usrToCell(old)
  assert(ol.typ.kind in {tyString, tySequence})
  when defined(nimSize):
    memUsed = memUsed - nimSize(ol)
  else:
    memUsed = memUsed - ol.size # this is not exact
                                # pity that we don't know the old size
  res = cast[PCell](realloc(ol, newsize + sizeof(TCell)))
  #res = cast[PCell](gcAlloc(newsize + sizeof(TCell)))
  #copyMem(res, ol, nimSize(ol))
  assert((cast[TAddress](res) and (MemAlignment-1)) == 0)
  when defined(nimSize):
    memUsed = memUsed + nimSize(res)
  else:
    memUsed = memUsed + newsize

  if res != ol:
    if res == nil: raiseOutOfMem()
    if res.refcount <= 0:
      assert(gch.zct.d[-res.refcount] == ol)
      gch.zct.d[-res.refcount] = res
    excl(gch.at, ol)
    incl(gch.at, res)
    gch.mask = gch.mask or cast[TAddress](res)
    when defined(logGC):
      writeCell("growObj old cell", ol)
      writeCell("growObj new cell", res)
    gcTrace(ol, csZctFreed)
    gcTrace(res, csAllocated)
  result = cellToUsr(res)
  when stressGC: assert(checkZCT())

proc collectCycles(gch: var TGcHeap) =
  when defined(logGC):
    c_fprintf(c_stdout, "collecting cycles!\n")

  # step 1: pretend that any node is dead
  for c in elements(gch.at):
    forallChildren(c, waCycleDecRef)
  CellSetInit(gch.newAt)
  # step 2: restore life cells
  for c in elements(gch.at):
    if c.refcount > 0: restore(c)
  # step 3: free dead cells:
  for cell in elements(gch.at):
    if cell.refcount == 0:
      # We free an object that is part of a cycle here. Its children
      # may have been freed already. Thus the finalizer could access
      # garbage. To handle this case properly we need two passes for
      # freeing here which is too expensive. We just don't call the
      # finalizer for now. YYY: Any better ideas?
      prepareDealloc(cell)
      gcTrace(cell, csCycFreed)
      when defined(logGC):
        writeCell("cycle collector dealloc cell", cell)
      when reallyDealloc: dealloc(cell)
  CellSetDeinit(gch.at)
  gch.at = gch.newAt

proc gcMark(gch: var TGcHeap, p: pointer) =
  # the addresses are not as objects on the stack, so turn them to objects:
  var cell = usrToCell(p)
  var c = cast[TAddress](cell)
  if ((c and gch.mask) == c) and cell in gch.at:
    # is the page that p "points to" in the AT? (All allocated pages are
    # always in the AT)
    incRef(cell)
    when stressGC: inc(cell.stackcount)
    add(gch.stackCells, cell)

proc unmarkStackAndRegisters(gch: var TGcHeap) =
  when stressGC: assert(checkZCT())
  for i in 0 .. gch.stackCells.len-1:
    var cell = gch.stackCells.d[i]
    assert(cell.refcount > 0)
    when stressGC:
      assert(cell.stackcount > 0)
      dec(cell.stackcount)
    decRef(cell)
  gch.stackCells.len = 0 # reset to zero
  when stressGC: assert(checkZCT())

# ----------------- stack management --------------------------------------
#  inspired from Smart Eiffel (c)

proc stackSize(): int =
  var stackTop: array[0..1, pointer]
  result = abs(cast[int](addr(stackTop[0])) - cast[int](stackBottom))

when defined(sparc): # For SPARC architecture.

  proc isOnStack(p: pointer): bool =
    var
      stackTop: array[0..1, pointer]
    result = p >= addr(stackTop[0]) and p <= stackBottom

  proc markStackAndRegisters(gch: var TGcHeap) =
    when defined(sparcv9):
      asm  " flushw"
    else:
      asm  " ta      0x3   ! ST_FLUSH_WINDOWS"

    var
      max = stackBottom
      sp: PPointer
      stackTop: array[0..1, pointer]
    stackTop[0] = nil
    stackTop[1] = nil
    sp = addr(stackTop[0])
    # Addresses decrease as the stack grows.
    while sp <= max:
      gcMark(gch, sp^)
      sp = cast[ppointer](cast[TAddress](sp) +% sizeof(pointer))

elif defined(ELATE):
  {.error: "stack marking code has to be written for this architecture".}

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
    jmpbufSize {.importc: "sizeof(jmp_buf)".}: int
      # a little hack to get the size of a TJmpBuf in the generated C code
      # in a platform independant way

  proc markStackAndRegisters(gch: var TGcHeap) =
    var
      max = stackBottom
      registers: C_JmpBuf # The jmp_buf buffer is in the C stack.
      sp: PPointer        # Used to traverse the stack and registers assuming
                          # that `setjmp' will save registers in the C stack.
    c_setjmp(registers)   # To fill the C stack with registers.
    sp = cast[ppointer](cast[TAddress](addr(registers)) +%
           jmpbufSize -% sizeof(pointer))
    # sp will traverse the JMP_BUF as well (jmp_buf size is added,
    # otherwise sp would be below the registers structure).
    while sp >= max:
      gcMark(gch, sp^)
      sp = cast[ppointer](cast[TAddress](sp) -% sizeof(pointer))

else:
  # ---------------------------------------------------------------------------
  # Generic code for architectures where addresses decrease as the stack grows.
  # ---------------------------------------------------------------------------
  proc isOnStack(p: pointer): bool =
    var
      stackTop: array [0..1, pointer]
    result = p >= addr(stackTop[0]) and p <= stackBottom

  proc markStackAndRegisters(gch: var TGcHeap) =
    var
      max = stackBottom
      registers: C_JmpBuf # The jmp_buf buffer is in the C stack.
      sp: PPointer        # Used to traverse the stack and registers assuming
                          # that `setjmp' will save registers in the C stack.
    c_setjmp(registers)   # To fill the C stack with registers.
    sp = cast[ppointer](addr(registers))
    while sp <= max:
      gcMark(gch, sp^)
      sp = cast[ppointer](cast[TAddress](sp) +% sizeof(pointer))

# ----------------------------------------------------------------------------
# end of non-portable code
# ----------------------------------------------------------------------------

proc CollectZCT(gch: var TGcHeap) =
  while gch.zct.len > 0:
    var c = gch.zct.d[0]
    assert(c.refcount <= 0)
    # remove from ZCT:
    gch.zct.d[0] = gch.zct.d[gch.zct.len-1]
    gch.zct.d[0].refcount = 0
    dec(gch.zct.len)
    # We are about to free the object, call the finalizer BEFORE its
    # children are deleted as well, because otherwise the finalizer may
    # access invalid memory. This is done by prepareDealloc():
    gcTrace(c, csZctFreed)
    prepareDealloc(c)
    forAllChildren(c, waZctDecRef)
    excl(gch.at, c)
    when defined(logGC):
      writeCell("zct dealloc cell", c)
    #when defined(debugGC) and defined(nimSize): zeroMem(c, nimSize(c))
    when reallyDealloc: dealloc(c)

proc collectCT(gch: var TGcHeap) =
  when defined(logGC):
    c_fprintf(c_stdout, "collecting zero count table; stack size: %ld\n",
              stackSize())
  when stressGC: assert(checkZCT())
  if gch.zct.len >= ZctThreshold or memUsed >= cycleThreshold or stressGC:
    markStackAndRegisters(gch)
    when stressGC: assert(GC_invariant())
    collectZCT(gch)
    when stressGC: assert(GC_invariant())
    assert(gch.zct.len == 0)
    when defined(cycleGC):
      if memUsed >= cycleThreshold or stressGC:
        when defined(logGC):
          c_fprintf(c_stdout, "collecting cycles; memory used: %ld\n", memUsed)
        collectCycles(gch)
        cycleThreshold = max(InitialCycleThreshold, memUsed * cycleIncrease)
        when defined(logGC):
          c_fprintf(c_stdout, "now used: %ld; threshold: %ld\n",
                    memUsed, cycleThreshold)
    unmarkStackAndRegisters(gch)
  when stressGC: assert(GC_invariant())

proc GC_fullCollect() =
  var oldThreshold = cycleThreshold
  cycleThreshold = 0 # forces cycle collection
  collectCT(gch)
  cycleThreshold = oldThreshold
