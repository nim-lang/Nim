#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# "Stack GC" for embedded devices or ultra performance requirements.

when defined(nimphpext):
  proc roundup(x, v: int): int {.inline.} =
    result = (x + (v-1)) and not (v-1)
  proc emalloc(size: int): pointer {.importc: "_emalloc".}
  proc efree(mem: pointer) {.importc: "_efree".}

  proc osAllocPages(size: int): pointer {.inline.} =
    emalloc(size)

  proc osTryAllocPages(size: int): pointer {.inline.} =
    emalloc(size)

  proc osDeallocPages(p: pointer, size: int) {.inline.} =
    efree(p)

else:
  include osalloc

# We manage memory as a thread local stack. Since the allocation pointer
# is detached from the control flow pointer, this model is vastly more
# useful than the traditional programming model while almost as safe.
# Individual objects can also be deleted but no coalescing is performed.
# Stacks can also be moved from one thread to another.

# We also support 'finalizers'.

type
  Finalizer {.compilerproc.} = proc (self: pointer) {.nimcall, benign.}
    # A ref type can have a finalizer that is called before the object's
    # storage is freed.

  AlignType = BiggestFloat
  ObjHeader = object
    typ: PNimType
    nextFinal: ptr ObjHeader # next object with finalizer

  Hole = object # stacks can have holes. Otherwise 'growObj' would be insane.
    zeroTyp: pointer # overlaid with 'typ' field. Always 'nil'.
    size: int # size of the free slot

  Chunk = ptr BaseChunk
  BaseChunk = object
    next: Chunk
    size: int
    head, tail: ptr ObjHeader # first and last object in chunk that
                              # has a finalizer attached to it

type
  StackPtr = object
    bump: pointer
    remaining: int
    current: Chunk

  MemRegion* = object
    remaining: int
    bump: pointer
    head, tail: Chunk
    nextChunkSize, totalSize: int
    hole: ptr Hole # we support individual freeing
    when hasThreadSupport:
      lock: SysLock

var
  tlRegion {.threadVar.}: MemRegion

template withRegion*(r: MemRegion; body: untyped) =
  let oldRegion = tlRegion
  tlRegion = r
  try:
    body
  finally:
    r = tlRegion
    tlRegion = oldRegion

template inc(p: pointer, s: int) =
  p = cast[pointer](cast[int](p) +% s)

template `+!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) +% s)

template `-!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) -% s)

proc allocSlowPath(r: var MemRegion; size: int) =
  # we need to ensure that the underlying linked list
  # stays small. Say we want to grab 16GB of RAM with some
  # exponential growth function. So we allocate 16KB, then
  # 32 KB, 64 KB, 128KB, 256KB, 512KB, 1MB, 2MB, 4MB,
  # 8MB, 16MB, 32MB, 64MB, 128MB, 512MB, 1GB, 2GB, 4GB, 8GB,
  # 16GB --> list contains only 20 elements! That's reasonable.
  if (r.totalSize and 1) == 0:
    r.nextChunkSize =
      if r.totalSize < 64 * 1024: PageSize*4
      else: r.nextChunkSize*2
  var s = roundup(size+sizeof(BaseChunk), PageSize)
  var fresh: Chunk
  if s > r.nextChunkSize:
    fresh = cast[Chunk](osAllocPages(s))
  else:
    fresh = cast[Chunk](osTryAllocPages(r.nextChunkSize))
    if fresh == nil:
      fresh = cast[Chunk](osAllocPages(s))
      # lowest bit in totalSize is the "don't increase nextChunkSize"
      inc r.totalSize
    else:
      s = r.nextChunkSize
  fresh.size = s
  fresh.head = nil
  fresh.tail = nil
  fresh.next = nil
  inc r.totalSize, s
  let old = r.tail
  if old == nil:
    r.head = fresh
  else:
    r.tail.next = fresh
  r.bump = fresh +! sizeof(BaseChunk)
  r.tail = fresh
  r.remaining = s - sizeof(BaseChunk)

proc alloc(r: var MemRegion; size: int): pointer {.inline.} =
  if size > r.remaining:
    allocSlowPath(r, size)
  sysAssert(size <= r.remaining, "size <= r.remaining")
  dec(r.remaining, size)
  result = r.bump
  inc r.bump, size

proc runFinalizers(c: Chunk) =
  var it = c.head
  while it != nil:
    # indivually freed objects with finalizer stay in the list, but
    # their typ is nil then:
    if it.typ != nil and it.typ.finalizer != nil:
      (cast[Finalizer](it.typ.finalizer))(it+!sizeof(ObjHeader))
    it = it.nextFinal

when false:
  proc dealloc(r: var MemRegion; p: pointer) =
    let it = cast[ptr ObjHeader](p-!sizeof(ObjHeader))
    if it.typ != nil and it.typ.finalizer != nil:
      (cast[Finalizer](it.typ.finalizer))(p)
    it.typ = nil

proc deallocAll(r: var MemRegion; head: Chunk) =
  var it = head
  while it != nil:
    let nxt = it.next
    runFinalizers(it)
    dec r.totalSize, it.size
    osDeallocPages(it, it.size)
    it = nxt

proc deallocAll*(r: var MemRegion) =
  deallocAll(r, r.head)
  zeroMem(addr r, sizeof r)

proc obstackPtr*(r: MemRegion): StackPtr =
  result.bump = r.bump
  result.remaining = r.remaining
  result.current = r.tail

template computeRemaining(r): untyped =
  r.tail.size -% (cast[int](r.bump) -% cast[int](r.tail))

proc setObstackPtr*(r: var MemRegion; sp: StackPtr) =
  # free everything after 'sp':
  if sp.current != nil:
    deallocAll(r, sp.current.next)
    sp.current.next = nil
  else:
    deallocAll(r, r.head)
    r.head = nil
  r.bump = sp.bump
  r.tail = sp.current
  r.remaining = sp.remaining

proc obstackPtr*(): StackPtr = tlRegion.obstackPtr()
proc setObstackPtr*(sp: StackPtr) = tlRegion.setObstackPtr(sp)
proc deallocAll*() = tlRegion.deallocAll()

proc deallocOsPages(r: var MemRegion) = r.deallocAll()

proc joinRegion*(dest: var MemRegion; src: MemRegion) =
  # merging is not hard.
  if dest.head.isNil:
    dest.head = src.head
  else:
    dest.tail.next = src.head
  dest.tail = src.tail
  dest.bump = src.bump
  dest.remaining = src.remaining
  dest.nextChunkSize = max(dest.nextChunkSize, src.nextChunkSize)
  inc dest.totalSize, src.totalSize

proc isOnHeap*(r: MemRegion; p: pointer): bool =
  # the tail chunk is the largest, so check it first. It's also special
  # in that contains the current bump pointer:
  if r.tail >= p and p < r.bump:
    return true
  var it = r.head
  while it != r.tail:
    if it >= p and p <= it+!it.size: return true
    it = it.next

when false:
  # essential feature for later: copy data over from one region to another

  proc isInteriorPointer(r: MemRegion; p: pointer): pointer =
    discard " we cannot patch stack pointers anyway!"

  type
    PointerStackChunk = object
      next, prev: ptr PointerStackChunk
      len: int
      data: array[128, pointer]

  template head(s: PointerStackChunk): untyped = s.prev
  template tail(s: PointerStackChunk): untyped = s.next

  include chains

  proc push(r: var MemRegion; s: var PointerStackChunk; x: pointer) =
    if s.len < high(s.data):
      s.data[s.len] = x
      inc s.len
    else:
      let fresh = cast[ptr PointerStackChunk](alloc(r, sizeof(PointerStackChunk)))
      fresh.len = 1
      fresh.data[0] = x
      fresh.next = nil
      fresh.prev = nil
      append(s, fresh)


  proc genericDeepCopyAux(dr: var MemRegion; stack: var PointerStackChunk;
                          dest, src: pointer, mt: PNimType) {.benign.}
  proc genericDeepCopyAux(dr: var MemRegion; stack: var PointerStackChunk;
                          dest, src: pointer, n: ptr TNimNode) {.benign.} =
    var
      d = cast[ByteAddress](dest)
      s = cast[ByteAddress](src)
    case n.kind
    of nkSlot:
      genericDeepCopyAux(cast[pointer](d +% n.offset),
                         cast[pointer](s +% n.offset), n.typ)
    of nkList:
      for i in 0..n.len-1:
        genericDeepCopyAux(dest, src, n.sons[i])
    of nkCase:
      var dd = selectBranch(dest, n)
      var m = selectBranch(src, n)
      # reset if different branches are in use; note different branches also
      # imply that's not self-assignment (``x = x``)!
      if m != dd and dd != nil:
        genericResetAux(dest, dd)
      copyMem(cast[pointer](d +% n.offset), cast[pointer](s +% n.offset),
              n.typ.size)
      if m != nil:
        genericDeepCopyAux(dest, src, m)
    of nkNone: sysAssert(false, "genericDeepCopyAux")

  proc copyDeepString(dr: var MemRegion; stack: var PointerStackChunk; src: NimString): NimString {.inline.} =
    result = rawNewStringNoInit(dr, src.len)
    result.len = src.len
    copyMem(result.data, src.data, src.len + 1)

  proc genericDeepCopyAux(dr: var MemRegion; stack: var PointerStackChunk;
                          dest, src: pointer, mt: PNimType) =
    var
      d = cast[ByteAddress](dest)
      s = cast[ByteAddress](src)
    sysAssert(mt != nil, "genericDeepCopyAux 2")
    case mt.kind
    of tyString:
      var x = cast[PPointer](dest)
      var s2 = cast[PPointer](s)[]
      if s2 == nil:
        x[] = nil
      else:
        x[] = copyDeepString(cast[NimString](s2))
    of tySequence:
      var s2 = cast[PPointer](src)[]
      var seq = cast[PGenericSeq](s2)
      var x = cast[PPointer](dest)
      if s2 == nil:
        x[] = nil
        return
      sysAssert(dest != nil, "genericDeepCopyAux 3")
      x[] = newSeq(mt, seq.len)
      var dst = cast[ByteAddress](cast[PPointer](dest)[])
      for i in 0..seq.len-1:
        genericDeepCopyAux(dr, stack,
          cast[pointer](dst +% i*% mt.base.size +% GenericSeqSize),
          cast[pointer](cast[ByteAddress](s2) +% i *% mt.base.size +%
                       GenericSeqSize),
          mt.base)
    of tyObject:
      # we need to copy m_type field for tyObject, as it could be empty for
      # sequence reallocations:
      var pint = cast[ptr PNimType](dest)
      pint[] = cast[ptr PNimType](src)[]
      if mt.base != nil:
        genericDeepCopyAux(dr, stack, dest, src, mt.base)
      genericDeepCopyAux(dr, stack, dest, src, mt.node)
    of tyTuple:
      genericDeepCopyAux(dr, stack, dest, src, mt.node)
    of tyArray, tyArrayConstr:
      for i in 0..(mt.size div mt.base.size)-1:
        genericDeepCopyAux(dr, stack,
                           cast[pointer](d +% i*% mt.base.size),
                           cast[pointer](s +% i*% mt.base.size), mt.base)
    of tyRef:
      let s2 = cast[PPointer](src)[]
      if s2 == nil:
        cast[PPointer](dest)[] = nil
      else:
        # we modify the header of the cell temporarily; instead of the type
        # field we store a forwarding pointer. XXX This is bad when the cloning
        # fails due to OOM etc.
        let x = usrToCell(s2)
        let forw = cast[int](x.typ)
        if (forw and 1) == 1:
          # we stored a forwarding pointer, so let's use that:
          let z = cast[pointer](forw and not 1)
          unsureAsgnRef(cast[PPointer](dest), z)
        else:
          let realType = x.typ
          let z = newObj(realType, realType.base.size)

          unsureAsgnRef(cast[PPointer](dest), z)
          x.typ = cast[PNimType](cast[int](z) or 1)
          genericDeepCopyAux(dr, stack, z, s2, realType.base)
          x.typ = realType
    else:
      copyMem(dest, src, mt.size)

  proc joinAliveDataFromRegion*(dest: var MemRegion; src: var MemRegion;
                                root: pointer): pointer =
    # we mark the alive data and copy only alive data over to 'dest'.
    # This is O(liveset) but it nicely compacts memory, so it's fine.
    # We use the 'typ' field as a forwarding pointer. The forwarding
    # pointers have bit 0 set, so we can disambiguate them.
    # We allocate a temporary stack in 'src' that we later free:
    var s: PointerStackChunk
    s.len = 1
    s.data[0] = root
    while s.len > 0:
      var p: pointer
      if s.tail == nil:
        p = s.data[s.len-1]
        dec s.len
      else:
        p = s.tail.data[s.tail.len-1]
        dec s.tail.len
        if s.tail.len == 0:
          unlink(s, s.tail)

proc rawNewObj(r: var MemRegion, typ: PNimType, size: int): pointer =
  var res = cast[ptr ObjHeader](alloc(r, size + sizeof(ObjHeader)))
  res.typ = typ
  if typ.finalizer != nil:
    res.nextFinal = r.head.head
    r.head.head = res
  result = res +! sizeof(ObjHeader)

proc newObj(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(tlRegion, typ, size)
  zeroMem(result, size)
  when defined(memProfiler): nimProfile(size)

proc newObjNoInit(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(tlRegion, typ, size)
  when defined(memProfiler): nimProfile(size)

proc newSeq(typ: PNimType, len: int): pointer {.compilerRtl.} =
  let size = addInt(mulInt(len, typ.base.size), GenericSeqSize)
  result = newObj(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len

proc newObjRC1(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(tlRegion, typ, size)
  zeroMem(result, size)

proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =
  let size = addInt(mulInt(len, typ.base.size), GenericSeqSize)
  result = newObj(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len

proc growObj(region: var MemRegion; old: pointer, newsize: int): pointer =
  let typ = cast[ptr ObjHeader](old -! sizeof(ObjHeader)).typ
  result = rawNewObj(region, typ, newsize)
  let elemSize = if typ.kind == tyString: 1 else: typ.base.size
  let oldsize = cast[PGenericSeq](old).len*elemSize + GenericSeqSize
  copyMem(result, old, oldsize)
  zeroMem(result +! oldsize, newsize-oldsize)

proc growObj(old: pointer, newsize: int): pointer {.rtl.} =
  result = growObj(tlRegion, old, newsize)

proc unsureAsgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
  dest[] = src
proc asgnRef(dest: PPointer, src: pointer) {.compilerproc, inline.} =
  dest[] = src
proc asgnRefNoCycle(dest: PPointer, src: pointer) {.compilerproc, inline.} =
  dest[] = src

proc alloc(size: Natural): pointer =
  result = c_malloc(size)
  if result == nil: raiseOutOfMem()
proc alloc0(size: Natural): pointer =
  result = alloc(size)
  zeroMem(result, size)
proc realloc(p: pointer, newsize: Natural): pointer =
  result = c_realloc(p, newsize)
  if result == nil: raiseOutOfMem()
proc dealloc(p: pointer) = c_free(p)

proc alloc0(r: var MemRegion; size: Natural): pointer =
  # ignore the region. That is correct for the channels module
  # but incorrect in general. XXX
  result = alloc0(size)

proc dealloc(r: var MemRegion; p: pointer) = dealloc(p)

proc allocShared(size: Natural): pointer =
  result = c_malloc(size)
  if result == nil: raiseOutOfMem()
proc allocShared0(size: Natural): pointer =
  result = alloc(size)
  zeroMem(result, size)
proc reallocShared(p: pointer, newsize: Natural): pointer =
  result = c_realloc(p, newsize)
  if result == nil: raiseOutOfMem()
proc deallocShared(p: pointer) = c_free(p)

when hasThreadSupport:
  proc getFreeSharedMem(): int = 0
  proc getTotalSharedMem(): int = 0
  proc getOccupiedSharedMem(): int = 0

proc GC_disable() = discard
proc GC_enable() = discard
proc GC_fullCollect() = discard
proc GC_setStrategy(strategy: GC_Strategy) = discard
proc GC_enableMarkAndSweep() = discard
proc GC_disableMarkAndSweep() = discard
proc GC_getStatistics(): string = return ""

proc getOccupiedMem(): int =
  result = tlRegion.totalSize - tlRegion.remaining
proc getFreeMem(): int = tlRegion.remaining
proc getTotalMem(): int =
  result = tlRegion.totalSize

proc getOccupiedMem*(r: MemRegion): int =
  result = r.totalSize - r.remaining
proc getFreeMem*(r: MemRegion): int = r.remaining
proc getTotalMem*(r: MemRegion): int =
  result = r.totalSize

proc setStackBottom(theStackBottom: pointer) = discard
