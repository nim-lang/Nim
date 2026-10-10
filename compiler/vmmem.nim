#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The memory of the VM. All VM values live in memory that is owned by the
## VM and that is tracked as a set of *regions*. Every access through a
## pointer that the VM cannot prove to be valid is checked against the
## regions so that a bogus `cast` produces a VM error instead of crashing
## the compiler.
##
## There are different kinds of regions:
## - the VM stack: frames are bump allocated from stack segments.
## - the globals segment: compile-time globals; never freed.
## - the const segment: constant data (string literals, `const` values);
##   read-only and never freed.
## - heap chunks: blocks for `new`, string and seq payloads, `alloc`.
## - big blocks: heap blocks too large for a chunk get a region of their own.
## - foreign regions: memory handed to the VM by FFI calls.
##
## Regions never move, so addresses are stable and the VM can use real
## host pointers for `ptr`, `ref`, `var` etc.
##
## `NimNode` and `typedesc` values are represented by 32 bit *handles*:
## indexes into tables of this module. Handle 0 always means `nil`.
## Procs are represented by addresses within *proc regions*: these
## addresses are unique, so they can be told apart from integers that are
## cast to a proc type, yet they cannot be read or written.

import std/tables
import ast

when defined(nimPreviewSlimSystem):
  import std/assertions

type
  Address* = uint64 ## a raw VM address; the VM uses host pointers, but
    ## stores them in 8 bytes even on a 32 bit host, see `VmPtrSize`

  RegionKind* = enum
    rgStack, rgGlobals, rgConst, rgHeapChunk, rgBigBlock, rgForeign,
    rgProcs

  Region* = object
    start*, size*: Address
    kind*: RegionKind

  StackSegment = object
    base: Address
    cap, used: int

  StackMark* = object
    ## position of the stack pointer; restore it to pop frames.
    seg*, used*: int
    boxes*: int                # number of live boxes, see `allocBox`

  BumpArea = object
    ## a never-freed area that grows by adding chunks: used for globals
    ## and constant data
    cur: Address
    left: int
    kind: RegionKind

  VmMemory* = object
    regions: seq[Region]       # sorted by `start`
    lastHit: int
    freeLists: array[32, Address]
    heapCur: Address           # bump allocation within the current heap chunk
    heapLeft: int
    stack: seq[StackSegment]
    sp: StackMark
    boxes: seq[Address]        # heap blocks owned by the frames on the stack
    globals: BumpArea
    consts: BumpArea
    bytesInUse*: int           # heap bytes handed out (excluding headers)
    nodes*: seq[PNode]         # NimNode handles
    nodeIds: Table[pointer, int32]
    types*: seq[PType]         # typedesc handles
    typeIds: Table[pointer, int32]
    procs*: seq[PSym]          # proc i has the address procChunks[i div ProcChunkSize] + i mod ProcChunkSize
    procIds: Table[ItemId, int32]
    procChunks: seq[Address]

const
  HeapChunkSize = 256 * 1024
  BumpChunkSize = 64 * 1024
  StackSegmentSize* = 2 * 1024 * 1024
  MaxSmallBlock = 32 * 1024
  BlockHeaderSize* = 16    # every heap block starts with (size, state)
  BlockAlign* = 16
  StateAllocated = 0xA110C8ED'u64
  StateFree = 0xF4EEB10C'u64

  StrlitFlag* = 1'i64 shl 62 ## `cap` flag of a string or seq
    ## payload that lives in constant memory and must not be freed or
    ## mutated. Same value as the 64 bit runtime's `NIM_STRLIT_FLAG`.
  RcImmortal* = 1'i64 shl 62 ## `rc` flag of a ref cell in
    ## constant memory: never counted, never freed.
  RefHeaderSize* = 8 ## the refcount precedes the object directly
  ProcChunkSize = 64 * 1024

template `+!`*(a: Address; b: int): Address = a + cast[Address](int64(b))
template `-!`*(a: Address; b: int): Address = a - cast[Address](int64(b))

template toPtr*(a: Address): pointer =
  when sizeof(pointer) == 8: cast[pointer](a)
  else: cast[pointer](uint32(a and 0xFFFF_FFFF'u64))
template toAddr*(p: pointer): Address = Address(cast[uint64](p))

template ld*[T](a: Address): T = cast[ptr T](toPtr(a))[]
template st*[T](a: Address; v: T) = cast[ptr T](toPtr(a))[] = v

# An `int` in VM memory always occupies 8 bytes (see `VmPtrSize`), so `int`
# is never the type to access VM memory with: it is 4 bytes on a 32 bit host.
template ldInt*(a: Address): int = int(ld[int64](a))
template stInt*(a: Address; v: int) = st[int64](a, int64(v))

proc alignUp(x, a: int): int {.inline.} = (x + a - 1) and not (a - 1)

# ------------------------- regions -------------------------------------------

proc addRegion(m: var VmMemory; start: Address; size: int; kind: RegionKind) =
  var i = m.regions.len
  m.regions.add Region()
  while i > 0 and m.regions[i-1].start > start:
    m.regions[i] = m.regions[i-1]
    dec i
  m.regions[i] = Region(start: start, size: Address(size), kind: kind)
  m.lastHit = i

proc removeRegion(m: var VmMemory; start: Address) =
  for i in 0..<m.regions.len:
    if m.regions[i].start == start:
      m.regions.delete i
      m.lastHit = 0
      return
  raiseAssert "removeRegion: unknown region"

proc findRegion*(m: var VmMemory; a: Address): int =
  ## index of the region that contains `a` or -1.
  if m.lastHit < m.regions.len:
    let r = m.regions[m.lastHit]
    if a >= r.start and a - r.start < r.size: return m.lastHit
  var lo = 0
  var hi = m.regions.len - 1
  while lo <= hi:
    let mid = (lo + hi) shr 1
    let r = m.regions[mid]
    if a < r.start:
      hi = mid - 1
    elif a - r.start >= r.size:
      lo = mid + 1
    else:
      m.lastHit = mid
      return mid
  result = -1

proc canRead*(m: var VmMemory; a: Address; size: int): bool =
  ## true if `size` bytes at `a` are VM memory.
  if size == 0: return true
  let i = findRegion(m, a)
  if i < 0: return false
  let r = m.regions[i]
  result = r.kind != rgProcs and a - r.start + Address(size) <= r.size

proc canWrite*(m: var VmMemory; a: Address; size: int): bool =
  ## true if `size` bytes at `a` are mutable VM memory.
  if size == 0: return true
  let i = findRegion(m, a)
  if i < 0: return false
  let r = m.regions[i]
  result = r.kind notin {rgConst, rgProcs} and a - r.start + Address(size) <= r.size

proc isConstMemory*(m: var VmMemory; a: Address): bool =
  let i = findRegion(m, a)
  result = i >= 0 and m.regions[i].kind == rgConst

proc registerForeign*(m: var VmMemory; p: pointer; size: int) =
  ## makes memory that the VM did not allocate (FFI) accessible.
  if size > 0 and findRegion(m, toAddr(p)) < 0:
    addRegion(m, toAddr(p), size, rgForeign)

proc unregisterForeign*(m: var VmMemory; p: pointer) =
  removeRegion(m, toAddr(p))

# ------------------------- host memory ---------------------------------------

proc hostAlloc(size: int): Address =
  result = toAddr(alloc0(size))
  assert (result and Address(BlockAlign-1)) == 0

proc hostDealloc(a: Address) = dealloc(toPtr(a))

# ------------------------- heap ----------------------------------------------

proc sizeClass(size: int): (int, int) =
  ## returns (class index, block size) for a requested payload size.
  if size <= 128:
    let s = max(alignUp(size, 16), 16)
    result = (s div 16 - 1, s)          # classes 0..7
  else:
    var s = 256
    var c = 8
    while s < size:
      s = s shl 1
      inc c
    result = (c, s)                      # classes 8..15 for 256..32K

proc rawHeapAlloc(m: var VmMemory; size: int): Address =
  ## allocates a zeroed heap block for `size` bytes, 16 byte aligned.
  if size > MaxSmallBlock:
    let total = BlockHeaderSize + alignUp(size, BlockAlign)
    let b = hostAlloc(total)
    addRegion(m, b, total, rgBigBlock)
    st[uint64](b, uint64(alignUp(size, BlockAlign)))
    st[uint64](b +! 8, StateAllocated)
    m.bytesInUse += size
    return b +! BlockHeaderSize
  let (cls, bs) = sizeClass(size)
  var b = m.freeLists[cls]
  if b != 0:
    m.freeLists[cls] = ld[Address](b +! BlockHeaderSize)
    zeroMem(toPtr(b +! BlockHeaderSize), bs)
  else:
    let total = BlockHeaderSize + bs
    if m.heapLeft < total:
      m.heapCur = hostAlloc(HeapChunkSize)
      m.heapLeft = HeapChunkSize
      addRegion(m, m.heapCur, HeapChunkSize, rgHeapChunk)
    b = m.heapCur
    m.heapCur = m.heapCur +! total
    m.heapLeft -= total
  st[uint64](b, uint64(bs))
  st[uint64](b +! 8, StateAllocated)
  m.bytesInUse += bs
  result = b +! BlockHeaderSize

proc heapAlloc*(m: var VmMemory; size: int): Address =
  ## `alloc0` for the VM. Returns 0 for a size of 0.
  if size <= 0: return 0
  result = rawHeapAlloc(m, size)

proc isHeapBlock*(m: var VmMemory; p: Address): bool =
  ## true if `p` is the start of a live heap block.
  if p < BlockHeaderSize or (p and Address(BlockAlign-1)) != 0: return false
  let i = findRegion(m, p -! BlockHeaderSize)
  if i < 0 or m.regions[i].kind notin {rgHeapChunk, rgBigBlock}: return false
  result = ld[uint64](p -! 8) == StateAllocated

proc isFreedBlock*(m: var VmMemory; p: Address): bool =
  ## true if `p` is the start of a heap block that was freed.
  if p < BlockHeaderSize or (p and Address(BlockAlign-1)) != 0: return false
  let i = findRegion(m, p -! BlockHeaderSize)
  if i < 0 or m.regions[i].kind notin {rgHeapChunk, rgBigBlock}: return false
  result = ld[uint64](p -! 8) == StateFree

proc blockSize*(m: var VmMemory; p: Address): int =
  ## usable size of the heap block `p`.
  result = int(ld[uint64](p -! BlockHeaderSize))

proc heapDealloc*(m: var VmMemory; p: Address): bool =
  ## frees a heap block. Returns false if `p` is not a live heap block
  ## (double free, interior pointer, not VM heap memory).
  if p == 0: return true
  if not isHeapBlock(m, p): return false
  let b = p -! BlockHeaderSize
  let bs = int(ld[uint64](b))
  m.bytesInUse -= bs
  if bs > MaxSmallBlock:
    removeRegion(m, b)
    hostDealloc(b)
  else:
    let (cls, _) = sizeClass(bs)
    st[uint64](b +! 8, StateFree)
    st[Address](p, m.freeLists[cls])
    m.freeLists[cls] = b
  result = true

proc heapRealloc*(m: var VmMemory; p: Address; newSize: int): Address =
  ## `realloc0` for the VM. Returns 0 if `p` is not a live heap block;
  ## check with `isHeapBlock` first for a precise error.
  if p == 0: return heapAlloc(m, newSize)
  if not isHeapBlock(m, p): return 0
  if newSize <= 0:
    discard heapDealloc(m, p)
    return 0
  let old = blockSize(m, p)
  if newSize <= old: return p
  result = heapAlloc(m, newSize)
  copyMem(toPtr(result), toPtr(p), old)
  discard heapDealloc(m, p)

# ------------------------- bump areas (globals, consts) -----------------------

proc bumpAlloc(m: var VmMemory; area: var BumpArea; size, align: int): Address =
  ## zeroed memory that is never freed.
  let size = max(size, 1)
  var pad = int(((area.cur +! (align-1)) and not Address(align-1)) - area.cur)
  if area.cur == 0 or area.left < pad + size:
    let chunk = max(BumpChunkSize, alignUp(size, BlockAlign))
    area.cur = hostAlloc(chunk)
    area.left = chunk
    addRegion(m, area.cur, chunk, area.kind)
    pad = 0
  result = area.cur +! pad
  area.cur = result +! size
  area.left -= pad + size

proc allocGlobal*(m: var VmMemory; size, align: int): Address =
  ## storage for a compile-time global; zeroed, never freed, never moved.
  m.globals.kind = rgGlobals
  result = bumpAlloc(m, m.globals, size, align)

proc allocConst*(m: var VmMemory; size, align: int): Address =
  ## storage for constant data; read-only for VM code.
  m.consts.kind = rgConst
  result = bumpAlloc(m, m.consts, size, align)

# ------------------------- stack ---------------------------------------------

proc stackMark*(m: VmMemory): StackMark {.inline.} = m.sp

proc pushFrame*(m: var VmMemory; size: int): Address =
  ## allocates a zeroed frame of `size` bytes (a multiple of 8). Restore
  ## the `stackMark` taken before this call to pop it.
  assert size <= StackSegmentSize
  var seg = m.sp.seg
  var used = m.sp.used
  if seg >= m.stack.len or used + size > m.stack[seg].cap:
    if seg < m.stack.len: inc seg
    used = 0
    if seg >= m.stack.len:
      let b = hostAlloc(StackSegmentSize)
      addRegion(m, b, StackSegmentSize, rgStack)
      m.stack.add StackSegment(base: b, cap: StackSegmentSize)
  result = m.stack[seg].base +! used
  zeroMem(toPtr(result), size)
  m.sp = StackMark(seg: seg, used: used + size, boxes: m.boxes.len)

proc freeBoxes(m: var VmMemory; n: int) =
  for i in n..<m.boxes.len: discard heapDealloc(m, m.boxes[i])
  m.boxes.setLen n

proc popFrames*(m: var VmMemory; mark: StackMark) {.inline.} =
  ## pops the frames pushed after `mark` was taken and frees their boxes
  if m.boxes.len > mark.boxes: freeBoxes(m, mark.boxes)
  m.sp = mark

proc allocBox*(m: var VmMemory; size: int): Address =
  ## a zeroed heap block for a big value that the current frame owns: it is
  ## freed when the frame is popped.
  result = heapAlloc(m, max(size, 1))
  m.boxes.add result
  m.sp.boxes = m.boxes.len

# ------------------------- strings and seqs ----------------------------------
# A string or seq is `(len: int, p: ptr Payload)` and the payload is
# `(cap: int, data: UncheckedArray[T])`. Strings keep a terminating zero
# after the data that is not counted in `cap`.

proc payloadDataOffset*(elemAlign: int): int {.inline.} =
  alignUp(8, max(elemAlign, 1))

proc newPayload*(m: var VmMemory; cap, elemSize, elemAlign: int; isString: bool): Address =
  ## allocates a zeroed payload for `cap` elements on the heap.
  let bytes = payloadDataOffset(elemAlign) + cap*elemSize + ord(isString)
  result = heapAlloc(m, bytes)
  stInt(result, cap)

proc newConstPayload*(m: var VmMemory; cap, elemSize, elemAlign: int; isString: bool): Address =
  ## allocates a payload in constant memory; it is flagged with `StrlitFlag`.
  let bytes = payloadDataOffset(elemAlign) + cap*elemSize + ord(isString)
  result = allocConst(m, bytes, max(elemAlign, 8))
  st[int64](result, int64(cap) or StrlitFlag)

proc payloadCap*(p: Address): int {.inline.} =
  if p == 0: 0 else: int(ld[int64](p) and not StrlitFlag)

proc isLiteralPayload*(p: Address): bool {.inline.} =
  p != 0 and (ld[int64](p) and StrlitFlag) != 0

proc storeString*(m: var VmMemory; dest: Address; s: string; inConst: bool) =
  ## writes a string value (len, p) to `dest`. The empty string has no payload.
  stInt(dest, s.len)
  if s.len == 0:
    st[Address](dest +! 8, 0)
  else:
    let p = if inConst: newConstPayload(m, s.len, 1, 1, true)
            else: newPayload(m, s.len, 1, 1, true)
    copyMem(toPtr(p +! 8), unsafeAddr s[0], s.len)
    st[Address](dest +! 8, p)

proc loadString*(src: Address): string =
  ## reads the string value at `src`. Assumes `src` was checked.
  let L = ldInt(src)
  result = newString(L)
  if L > 0:
    let p = ld[Address](src +! 8)
    copyMem(addr result[0], toPtr(p +! 8), L)

# ------------------------- refs ----------------------------------------------
# A ref points to the object; the refcount is the `int` before it. As in
# the native ARC runtime a refcount of 0 means "one reference".

proc refBlockOffset*(align: int): int {.inline.} = alignUp(RefHeaderSize, max(align, 1))

proc newRef*(m: var VmMemory; size, align: int): Address =
  ## `nimNewObj` for the VM: returns the address of the zeroed object.
  let off = refBlockOffset(align)
  result = heapAlloc(m, off + max(size, 1)) +! off

proc newConstRef*(m: var VmMemory; size, align: int): Address =
  let off = refBlockOffset(align)
  result = allocConst(m, off + max(size, 1), max(align, 8)) +! off
  st[int64](result -! RefHeaderSize, RcImmortal)

proc refCount*(p: Address): int64 {.inline.} = ld[int64](p -! RefHeaderSize)

proc incRef*(p: Address) {.inline.} =
  let rc = ld[int64](p -! RefHeaderSize)
  if (rc and RcImmortal) == 0:
    st[int64](p -! RefHeaderSize, rc + 1)

proc decRefIsLast*(p: Address): bool {.inline.} =
  ## `nimDecRefIsLast`: true if this was the last reference; the object
  ## then has to be destroyed and disposed.
  let rc = ld[int64](p -! RefHeaderSize)
  if (rc and RcImmortal) != 0:
    result = false
  elif rc == 0:
    result = true
  else:
    st[int64](p -! RefHeaderSize, rc - 1)
    result = false

proc disposeRef*(m: var VmMemory; p: Address; align: int): bool =
  ## `nimRawDispose`: frees the memory of a ref. Returns false for an
  ## invalid pointer.
  if p == 0: return true
  if (ld[int64](p -! RefHeaderSize) and RcImmortal) != 0: return true
  result = heapDealloc(m, p -! refBlockOffset(align))

# ------------------------- handles -------------------------------------------

proc initHandles(m: var VmMemory) =
  if m.nodes.len == 0:
    m.nodes.add nil
    m.types.add nil
    m.procs.add nil

proc nodeHandle*(m: var VmMemory; n: PNode): int32 =
  if n == nil: return 0
  initHandles(m)
  let k = cast[pointer](n)
  result = m.nodeIds.getOrDefault(k, 0)
  if result == 0:
    result = int32(m.nodes.len)
    m.nodes.add n
    m.nodeIds[k] = result

proc getNode*(m: VmMemory; h: int64): PNode {.inline.} =
  if h <= 0 or h >= m.nodes.len: nil else: m.nodes[h]

proc typeHandle*(m: var VmMemory; t: PType): int32 =
  if t == nil: return 0
  initHandles(m)
  let k = cast[pointer](t)
  result = m.typeIds.getOrDefault(k, 0)
  if result == 0:
    result = int32(m.types.len)
    m.types.add t
    m.typeIds[k] = result

proc getType*(m: VmMemory; h: int64): PType {.inline.} =
  if h <= 0 or h >= m.types.len: nil else: m.types[h]

proc procAddress*(m: var VmMemory; s: PSym): Address =
  ## the VM's address of the proc `s`; 0 for nil.
  if s == nil: return 0
  initHandles(m)
  var idx = m.procIds.getOrDefault(s.itemId, 0)
  if idx == 0:
    idx = int32(m.procs.len)
    m.procs.add s
    m.procIds[s.itemId] = idx
  let chunk = idx div ProcChunkSize
  while chunk >= m.procChunks.len:
    # address space only: the memory is never touched
    let b = hostAlloc(ProcChunkSize)
    addRegion(m, b, ProcChunkSize, rgProcs)
    m.procChunks.add b
  result = m.procChunks[chunk] +! (idx mod ProcChunkSize)

proc getProc*(m: var VmMemory; a: Address): PSym =
  ## the proc at address `a`, nil if `a` is not a proc address.
  let r = findRegion(m, a)
  if r < 0 or m.regions[r].kind != rgProcs: return nil
  let start = m.regions[r].start
  for chunk in 0..<m.procChunks.len:
    if m.procChunks[chunk] == start:
      let idx = chunk * ProcChunkSize + int(a - start)
      return if idx > 0 and idx < m.procs.len: m.procs[idx] else: nil
  result = nil

proc resetNodeHandles*(m: var VmMemory; keep: openArray[int32]): seq[int32] =
  ## drops all NimNode handles except `keep`. Returns the new handles for
  ## `keep`, in the same order; the caller has to patch them into memory.
  var nodes = @[PNode(nil)]
  m.nodeIds.clear()
  result = newSeq[int32](keep.len)
  for i, h in keep:
    let n = getNode(m, h)
    if n == nil:
      result[i] = 0
    else:
      let k = cast[pointer](n)
      var nh = m.nodeIds.getOrDefault(k, 0)
      if nh == 0:
        nh = int32(nodes.len)
        nodes.add n
        m.nodeIds[k] = nh
      result[i] = nh
  m.nodes = move nodes
