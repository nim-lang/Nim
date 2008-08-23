# This implements a new pointer set. Access time O(1). For 32 bit systems, we
# currently need 3 memory accesses. 

const
  PageSize = 1024 * sizeof(int)
  MemAlignment = 8 # minimal memory block that can be allocated
  BitsPerUnit = sizeof(int)*8 
    # a "unit" is a word, i.e. 4 bytes
    # on a 32 bit system; I do not use the term "word" because under 32-bit
    # Windows it is sometimes only 16 bits

  BitsPerPage = PageSize div MemAlignment
  UnitsPerPage = BitsPerPage div BitsPerUnit
    # how many units do we need to describe a page:
    # on 32 bit systems this is only 16 (!)

type
  PPointer = ptr pointer

  TCollectorData = int
  TCell {.final.} = object
    refcount: TCollectorData  # the refcount and bit flags
    typ: PNimType                  
    stackcount: int           # stack counter for debugging
    drefc: int                # real reference counter for debugging

  PCell = ptr TCell

proc cellToUsr(cell: PCell): pointer {.inline.} =
  # convert object (=pointer to refcount) to pointer to userdata
  result = cast[pointer](cast[TAddress](cell)+%TAddress(sizeof(TCell)))

proc usrToCell(usr: pointer): PCell {.inline.} =
  # convert pointer to userdata to object (=pointer to refcount)
  result = cast[PCell](cast[TAddress](usr)-%TAddress(sizeof(TCell)))

proc gcAlloc(size: int): pointer =
  result = alloc0(size)
  if result == nil: raiseOutOfMem() 

# ------------------ Zero count table (ZCT) and any table (AT) -------------

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
# Thus we likely get no collisions at all if the pages are given to us
# in a sequential manner by the operating system!
const
  bitsPerNode = 10 # we use 10 bits per node; this means 3 memory accesses on
                   # 32 bit systems

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
    
  TSetNode {.final.} = object
    n: array[0.. (1 shl bitsPerNode)-1, PSetNode]
  PSetNode = ptr TSetNode

const
  InitCellSetSize = 1024 # must be a power of two!

proc CellSetInit(s: var TCellSet) =
  s.data = gcAlloc(InitCellSetSize * sizeof(PPageDesc))
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
  n = gcAlloc((t.max + 1) * sizeof(PPageDesc))
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

  if (t.max+1) * 2 < t.counter * 3: CellSetEnlarge(t)
  inc(t.counter)
  h = cast[int](key) and t.max
  while t.data[h] != nil: h = nextTry(h, t.max)
  assert(t.data[h] == nil)
  # the new page descriptor goes into result
  result = gcAlloc(sizeof(TPageDesc))
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
  t = CellSetGet(s, u /% PageSize)
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
  t = CellSetPut(s, u /% PageSize)
  u = (u %% PageSize) /% MemAlignment
  t.bits[u /% BitsPerUnit] = t.bits[u /% BitsPerUnit] or 
    (1 shl (u %% BitsPerUnit))

proc excl(s: var TCellSet, cell: PCell) =
  var
    u: TAddress
    t: PPageDesc
  u = cast[TAddress](cell)
  t = CellSetGet(s, u /% PageSize)
  if t != nil:
    u = (u %% PageSize) /% MemAlignment
    t.bits[u %% BitsPerUnit] = (t.bits[u /% BitsPerUnit] and
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
          yield cast[PCell]((r.key *% PageSize) +%
                              (i*%BitsPerUnit+%j) *% MemAlignment)
        inc(j)
        w = w shr 1
      inc(i)
    r = r.next

