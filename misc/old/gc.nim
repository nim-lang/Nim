#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
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
  traceGC = True # extensive debugging

# Guess the page size of the system; if it is the
# wrong value, performance may be worse (this is not
# for sure though), but GC still works; must be a power of two!
const
  PageShift = if sizeof(pointer) == 4: 12 else: 13
  PageSize = 1 shl PageShift # on 32 bit systems 4096
  RC_Increase = 7 * PageSize # is an additive increase
  CycleIncrease = 2 # is a multiplicative increase

when defined(debugGC):
  const InitialThreshold = 64*1024
  const stressGC = False
else:
  const stressGC = False
  const InitialThreshold = RC_Increase
  # this may need benchmarking...

# things the System module thinks should be available:
when defined(useDL) or defined(nativeDL):
  type
    TMallocInfo {.importc: "struct mallinfo", nodecl.} = record
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
  rcThreshold: int = InitialThreshold
  cycleThreshold: int = InitialThreshold

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
  TCell = record
    refcount: TCollectorData  # the refcount and bit flags
    typ: PNimType
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
  cycleThreshold = InitialThreshold

proc GC_disableMarkAndSweep() =
  cycleThreshold = high(cycleThreshold)-1
  # set to the max value to suppress the cycle detector

proc nextTry(h, maxHash: int): int {.inline.} =
  result = ((5*h) + 1) and maxHash
  # For any initial h in range(maxHash), repeating that maxHash times
  # generates each int in range(maxHash) exactly once (see any text on
  # random-number generation for proof).

# ------------------ Zero count table (ZCT) and any table (AT) -------------

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
# descriptor has a bit for
# every Memalignment'th byte in the page.
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

  TPageDesc = record
    dummy, dummy2: int
    next: PPageDesc # all nodes are connected with this pointer
    key: TAddress   # start address at bit 0
    bits: array[TBitIndex, int] # a bit vector

  PPageDescArray = ptr array[0..1000_000, PPageDesc]
  TCellSet = record
    counter, max: int
    head: PPageDesc
    data: PPageDescArray

  PStackCells = ptr array[0..1000_0000, PCell]
  TCountTables = record     # this contains the zero count and
                            # non-zero count table
    mask: TAddress          # mask for fast pointer detection
    zct: TCellSet           # the zero count table
    at: TCellSet            # a table that contains all references
    newAT: TCellSet
    newZCT: TCellSet
    stackCells: PStackCells # cells that need to be decremented because they
                            # are in the hardware stack; a cell may occur
                            # several times in this data structure
    stackLen, stackMax: int # for managing the stack cells
    

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

testPageDescs()

when defined(debugGC):
  proc writeCell(msg: CString, c: PCell) =
    c_fprintf(c_stdout, "%s: %p\n", msg, c)
  proc writePtr(msg: CString, p: Pointer) =
    c_fprintf(c_stdout, "%s: %p\n", msg, p)
    
    
when traceGC:
  # traceGC is a special switch to enable extensive debugging
  type 
    TCellState = enum
      csAllocated, csZctFreed, csCycFreed
    TSlowSet = record
      L: int # current length
      cap: int # capacity
      d: PStackCells
      
  proc cellSetInit(s: var TSlowSet) =
    s.L = 0
    s.cap = 4096
    s.d = cast[PStackCells](gcAlloc(s.cap * sizeof(PCell)))
  
  proc incl(s: var TSlowSet, c: PCell) =
    if s.L >= s.cap:
      s.cap = s.cap * 3 div 2
      s.d = cast[PStackCells](realloc(s.d, s.cap * sizeof(PCell)))
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
    if traceGC: traceCell(cell, state)

# -------------------------------------------------------------------------

proc addStackCell(ct: var TCountTables, cell: PCell) =
  if ct.stackLen >= ct.stackMax:
    ct.stackMax = ct.stackMax * 3 div 2
    ct.stackCells = cast[PStackCells](realloc(ct.stackCells, ct.stackMax *
                                      sizeof(PCell)))
    if ct.stackCells == nil: raiseOutOfMem()
  ct.stackCells[ct.stackLen] = cell
  inc(ct.stackLen)

var
  stackBottom: pointer
  ct: TCountTables


# forward declarations:
proc collectCT(ct: var TCountTables)
proc IsOnStack(p: pointer): bool
proc forAllChildren(cell: PCell, op: TWalkOp)
proc collectCycles()

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

proc GC_invariant(): bool =
  if recGcLock >= 1: return true # prevent endless recursion
  inc(recGcLock)
  result = True
  # set counters back to zero:
  for c in elements(ct.AT):
    var t = c.typ
    if t == nil or t.kind notin {tySequence, tyString, tyRef}:
      writeCell("corrupt cell?", c)
      result = false
    c.drefc = 0
  for c in elements(ct.AT):
    forAllChildren(c, waDebugIncRef)
  for c in elements(ct.AT):
    if c.drefc > c.refcount - c.stackcount:
      result = false # failed
      c_fprintf(c_stdout,
         "broken cell: %p, refc: %ld, stack: %ld, real: %ld\n",
         c, c.refcount, c.stackcount, c.drefc)
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
  CellSetInit(ct.zct)
  CellSetInit(ct.at)
  ct.stackLen = 0
  ct.stackMax = 255
  ct.stackCells = cast[PStackCells](gcAlloc((ct.stackMax+1) * sizeof(PCell)))
  ct.mask = 0
  new(gOutOfMem) # reserve space for the EOutOfMemory exception here!
  assert(GC_invariant())

proc outputCell(c: PCell) =
  inc(recGcLock)
  write(stdout, reprAny(cellToUsr(c), c.typ))
  dec(recGcLock)

proc writeGraph() =
  {.checkpoint.}
  block:
    inc(recGcLock)
    for c in elements(ct.AT): outputCell(c)
    dec(recGcLock)

proc seqCheck(cell: PCell): bool =
  assert(cell.typ != nil)
  if cell.typ.kind in {tySequence, tyString}:
    result = cell.refcount - cell.stackcount <= 1
  else:
    result = true

proc decRef(cell: PCell) {.inline.} =
  assert(cell in ct.AT)
  when defined(debugGC):
    if cell.refcount == 0:
      writePtr("decref broken", cellToUsr(cell))
  assert(cell.refcount > 0) # this should be the case!
  assert(seqCheck(cell))
  dec(cell.refcount)
  if cell.refcount == 0:
    incl(ct.zct, cell)

proc incRef(cell: PCell) {.inline.} =
  assert(seqCheck(cell))
  inc(cell.refcount)

proc asgnRef(dest: ppointer, src: pointer) =
  # the code generator calls this proc!
  assert(not isOnStack(dest))
  # BUGFIX: first incRef then decRef!
  if src != nil: incRef(usrToCell(src))
  if dest^ != nil: decRef(usrToCell(dest^))
  dest^ = src
  when defined(debugGC): assert(GC_invariant())

proc unsureAsgnRef(dest: ppointer, src: pointer) =
  if not IsOnStack(dest):
    if src != nil: incRef(usrToCell(src))
    if dest^ != nil: decRef(usrToCell(dest^))
  dest^ = src
  when defined(debugGC): assert(GC_invariant())

proc restore(cell: PCell) =
  if cell notin ct.newAT:
    incl(ct.newAT, Cell)
    forAllChildren(cell, waCycleIncRef)

proc doOperation(p: pointer, op: TWalkOp) =
  if p == nil: return
  var cell: PCell = usrToCell(p)
  assert(cell != nil)
  case op # faster than function pointers because of easy prediction
  of waNone: assert(false)
  of waRelease: decRef(cell) # DEAD CODE!
  of waZctDecRef:
    assert(cell.refcount > 0)
    assert(seqCheck(cell))
    dec(cell.refcount)
    if cell.refcount == 0:
      incl(ct.newZCT, cell)
  of waCycleDecRef:
    assert(cell.refcount > 0)
    dec(cell.refcount)
  of waCycleIncRef:
    inc(cell.refcount) # restore proper reference counts!
    restore(cell)
  of waDebugIncRef:
    inc(cell.drefc)

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
  var
    d = cast[TAddress](dest)
  if dest == nil: return # nothing to do
  case mt.Kind
  of tyArray, tyArrayConstr, tyOpenArray:
    for i in 0..(mt.size div mt.base.size)-1:
      forAllChildrenAux(cast[pointer](d +% i *% mt.base.size), mt.base, op)
  of tyRef, tyString, tySequence: # leaf:
    doOperation(cast[ppointer](d)^, op)
  of tyRecord, tyObject, tyTuple:
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
    if memUsed >= rcThreshold or stressGC:
      collectCT(ct)
      when defined(logGC):
        write(stdout, "threshold is now: ")
        writeln(stdout, rcThreshold)

proc newObj(typ: PNimType, size: int): pointer =
  # generates a new object and sets its reference counter to 0
  var
    res: PCell
  assert(typ.kind in {tyRef, tyString, tySequence})
  # check if we have to collect:
  checkCollection()
  res = cast[PCell](Alloc0(size + sizeof(TCell)))
  assert((cast[TAddress](res) and (MemAlignment-1)) == 0)
  if res == nil: raiseOutOfMem()
  when defined(nimSize):
    memUsed = memUsed + nimSize(res)
  else:
    memUsed = memUsed + size

  res.refcount = 0
  # now it is buffered in the ZCT
  res.typ = typ
  incl(ct.zct, res) # its refcount is zero, so add it to the ZCT
  incl(ct.at, res)  # add it to the any table too
  ct.mask = ct.mask or cast[TAddress](res)
  when defined(debugGC):
    when defined(logGC): writeCell("new cell", res)
    assert(GC_Invariant())
  gcTrace(res, csAllocated)
  result = cellToUsr(res)

proc newSeq(typ: PNimType, len: int): pointer =
  # XXX: overflow checks!
  result = newObj(typ, len * typ.base.size + GenericSeqSize)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).space = len

proc growObj(old: pointer, newsize: int): pointer =
  var
    res, ol: PCell
  checkCollection()
  ol = usrToCell(old)
  assert(ol.typ.kind in {tyString, tySequence})
  assert(seqCheck(ol))
  when defined(nimSize):
    memUsed = memUsed - nimSize(ol)
  else:
    memUsed = memUsed - ol.size # this is not exact
  # pity that we don't know the old size
  res = cast[PCell](realloc(ol, newsize + sizeof(TCell)))
  assert((cast[TAddress](res) and (MemAlignment-1)) == 0)
  when defined(nimSize):
    memUsed = memUsed + nimSize(res)
  else:
    memUsed = memUsed + newsize

  if res != ol:
    if res == nil: raiseOutOfMem()
    excl(ct.zct, ol) # remove old pointer in any case:
    # It may have a refcount > 0 and is still in the ZCT.
    # So do it safe here and remove it anyway.
    excl(ct.at, ol)
    if res.refcount == 0:
      # store new pointer in ZCT, if refcount == 0:
      incl(ct.zct, res)
    incl(ct.at, res)
    ct.mask = ct.mask or cast[TAddress](res)
    when defined(logGC):
      writeCell("growObj old cell", ol)
      writeCell("growObj new cell", res)
    gcTrace(ol, csZctFreed)
    gcTrace(res, csAllocated)
  result = cellToUsr(res)
  assert(GC_Invariant())

proc collectCycles() =
  when defined(logGC):
    echo("collecting cycles!\n")

  # step 1: pretend that any node is dead
  for c in elements(ct.at):
    forallChildren(c, waCycleDecRef)
  CellSetInit(ct.newAt)
  # step 2: restore life cells
  for c in elements(ct.at):
    if c.refcount > 0: restore(c)
  # step 3: free dead cells:
  for cell in elements(ct.at):
    if cell.refcount == 0:
      assert(cell notin ct.zct)
      # We free an object that is part of a cycle here. Its children
      # may have been freed already. Thus the finalizer could access
      # garbage. To handle this case properly we need two passes for
      # freeing here which is too expensive. We just don't call the
      # finalizer for now. YYY: Any better ideas?
      prepareDealloc(cell)
      when defined(debugGC) and defined(nimSize): zeroMem(cell, nimSize(cell))
      gcTrace(cell, csCycFreed)
      dealloc(cell)
      when defined(logGC):
        writeCell("cycle collector dealloc cell", cell)
  CellSetDeinit(ct.at)
  ct.at = ct.newAt
  #ct.newAt = nil

proc gcMark(p: pointer) =
  # the addresses are not as objects on the stack, so turn them to objects:
  var cell = usrToCell(p)
  var c = cast[TAddress](cell)
  if ((c and ct.mask) == c) and cell in ct.at:
    # is the page that p "points to" in the AT? (All allocated pages are
    # always in the AT)
    inc(cell.refcount)
    inc(cell.stackcount)
    addStackCell(ct, cell)

proc unmarkStackAndRegisters() =
  for i in 0 .. ct.stackLen-1:
    var cell = ct.stackCells[i]
    assert(cell.refcount > 0)
    when defined(debugGC):
      if cell.stackcount == 0:
        writeGraph()
        writePtr("broken stackcount", cellToUsr(cell))
    assert(cell.stackcount > 0)
    dec(cell.refcount)
    dec(cell.stackcount)
    if cell.refcount == 0:
      incl(ct.zct, cell)
  ct.stackLen = 0 # reset to zero

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

  proc markStackAndRegisters() =
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
      gcMark(sp^)
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

  proc markStackAndRegisters() =
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
      gcMark(sp^)
      sp = cast[ppointer](cast[TAddress](sp) -% sizeof(pointer))

else:
  # ---------------------------------------------------------------------------
  # Generic code for architectures where addresses decrease as the stack grows.
  # ---------------------------------------------------------------------------
  proc isOnStack(p: pointer): bool =
    var
      stackTop: array [0..1, pointer]
    result = p >= addr(stackTop[0]) and p <= stackBottom

  proc markStackAndRegisters() =
    var
      max = stackBottom
      registers: C_JmpBuf # The jmp_buf buffer is in the C stack.
      sp: PPointer        # Used to traverse the stack and registers assuming
                          # that `setjmp' will save registers in the C stack.
    c_setjmp(registers)   # To fill the C stack with registers.
    sp = cast[ppointer](addr(registers))
    while sp <= max:
      gcMark(sp^)
      sp = cast[ppointer](cast[TAddress](sp) +% sizeof(pointer))

# ----------------------------------------------------------------------------
# end of non-portable code
# ----------------------------------------------------------------------------

proc CollectZCT =
  CellSetInit(ct.newZCT)
  for c in elements(ct.zct):
    if c.refcount == 0:
      # if != 0 the reference count has been increased, so this does not
      # belong to the ZCT. We simply do nothing - it won't appear in the newZCT
      # anyway.
      # We are about to free the object, call the finalizer BEFORE its
      # children are deleted as well, because otherwise the finalizer may
      # access invalid memory. This is done by prepareDealloc():
      prepareDealloc(c)
      forAllChildren(c, waZctDecRef)
      assert(c.refcount == 0) # should still be zero
      excl(ct.at, c)
      excl(ct.newZCT, c) # BUGFIX
      when defined(logGC):
        writeCell("zct dealloc cell", c)
      when defined(debugGC) and defined(nimSize): zeroMem(c, nimSize(c))
      gcTrace(c, csZctFreed)
      dealloc(c)
  CellSetDeinit(ct.zct)
  ct.zct = ct.newZCT
  #ct.newZCT = nil

proc collectCT(ct: var TCountTables) =
  when defined(logGC):
    c_fprintf(c_stdout, "collecting zero count table; stack size: %ld\n",
              stackSize())
  markStackAndRegisters()
  assert(GC_invariant())
  while True:
    collectZCT()
    if ct.zct.counter == 0: break
    # ``counter`` counts the pages, but zero pages means zero cells

  when defined(cycleGC):
    # still over the cycle threshold?
    if memUsed >= cycleThreshold or stressGC:
      # collect the cyclic things:
      assert(ct.zct.counter == 0)
      assert(GC_invariant())
      collectCycles()

  # recompute the thresholds:
  rcThreshold = (memUsed div RC_increase + 1) * RC_Increase
  cycleThreshold = memUsed * cycleIncrease

  assert(GC_invariant())
  unmarkStackAndRegisters()

proc GC_fullCollect() =
  var oldThreshold = cycleThreshold
  cycleThreshold = 0 # forces cycle collection
  collectCT(ct)
  cycleThreshold = oldThreshold
