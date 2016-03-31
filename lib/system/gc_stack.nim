#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# "Stack GC" for embedded devices or ultra performance requirements.

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
    head, last: ptr ObjHeader # first and last object in chunk that
                              # has a finalizer attached to it

type
  StackPtr = object
    chunk: pointer
    remaining: int
    current: Chunk

  MemRegion* = object
    remaining: int
    chunk: pointer
    head, last: Chunk
    nextChunkSize, totalSize: int
    hole: ptr Hole # we support individual freeing
    lock: SysLock

var
  region {.threadVar.}: MemRegion

template withRegion*(r: MemRegion; body: untyped) =
  let oldRegion = region
  region = r
  try:
    body
  finally:
    region = oldRegion

template inc(p: pointer, s: int) =
  p = cast[pointer](cast[int](p) +% s)

template `+!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) +% s)

template `-!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) +% s)

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
  var s = align(size+sizeof(BaseChunk), PageSize)
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
  fresh.final = nil
  r.totalSize += s
  let old = r.last
  if old == nil:
    r.head = fresh
  else:
    r.last.next = fresh
  r.chunk = fresh +! sizeof(BaseChunk)
  r.last = fresh
  r.remaining = s - sizeof(BaseChunk)

proc alloc(r: var MemRegion; size: int): pointer {.inline.} =
  if unlikely(r.remaining < size): allocSlowPath(r, size)
  dec(r.remaining, size)
  result = r.chunk
  inc r.chunk, size

proc runFinalizers(c: Chunk) =
  var it = c.head
  while it != nil:
    # indivually freed objects with finalizer stay in the list, but
    # their typ is nil then:
    if it.typ != nil and it.typ.finalizer != nil:
      (cast[Finalizer](cell.typ.finalizer))(cell+!sizeof(ObjHeader))
    it = it.next

proc dealloc(r: var MemRegion; p: pointer) =
  let it = p-!sizeof(ObjHeader)
  if it.typ != nil and it.typ.finalizer != nil:
    (cast[Finalizer](cell.typ.finalizer))(p)
  it.typ = nil

proc deallocAll(head: Chunk) =
  var it = head
  while it != nil:
    runFinalizers(it)
    osDeallocPages(it, it.size)
    it = it.next

proc deallocAll*(r: var MemRegion) =
  deallocAll(r.head)
  zeroMem(addr r, sizeof r)

proc obstackPtr*(r: MemRegion): StackPtr =
  result.chunk = r.chunk
  result.remaining = r.remaining
  result.current = r.last

proc setObstackPtr*(r: MemRegion; sp: StackPtr) =
  # free everything after 'sp':
  if sp.current != nil:
    deallocAll(sp.current.next)
  r.chunk = sp.chunk
  r.remaining = sp.remaining
  r.last = sp.current

proc joinRegion*(dest: var MemRegion; src: MemRegion) =
  # merging is not hard.
  if dest.head.isNil:
    dest.head = src.head
  else:
    dest.last.next = src.head
  dest.last = src.last
  dest.chunk = src.chunk
  dest.remaining = src.remaining
  dest.nextChunkSize = max(dest.nextChunkSize, src.nextChunkSize)
  dest.totalSize += src.totalSize
  if dest.hole.size < src.hole.size:
    dest.hole = src.hole

proc isOnHeap*(r: MemRegion; p: pointer): bool =
  # the last chunk is the largest, so check it first. It's also special
  # in that contains the current bump pointer:
  if r.last >= p and p < r.chunk:
    return true
  var it = r.head
  while it != r.last:
    if it >= p and p <= it+!it.size: return true
    it = it.next

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
  c_memcpy(result.data, src.data, src.len + 1)

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
    res.nextFinal = r.chunk.head
    r.chunk.head = res
  result = res +! sizeof(ObjHeader)

proc newObj(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(typ, size, region)
  zeroMem(result, size)
  when defined(memProfiler): nimProfile(size)

proc newObjNoInit(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(typ, size, region)
  when defined(memProfiler): nimProfile(size)

proc newSeq(typ: PNimType, len: int): pointer {.compilerRtl.} =
  let size = addInt(mulInt(len, typ.base.size), GenericSeqSize)
  result = newObj(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len

proc newObjRC1(typ: PNimType, size: int): pointer {.compilerRtl.} =
  result = rawNewObj(typ, size, gch)
  zeroMem(result, size)

proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =
  let size = addInt(mulInt(len, typ.base.size), GenericSeqSize)
  result = newObj(typ, size)
  cast[PGenericSeq](result).len = len
  cast[PGenericSeq](result).reserved = len

proc growObj(old: pointer, newsize: int, gch: var GcHeap): pointer =
  collectCT(gch)
  var ol = usrToCell(old)
  sysAssert(ol.typ != nil, "growObj: 1")
  gcAssert(ol.typ.kind in {tyString, tySequence}, "growObj: 2")

  var res = cast[PCell](rawAlloc(gch.region, newsize + sizeof(Cell)))
  var elemSize = 1
  if ol.typ.kind != tyString: elemSize = ol.typ.base.size

  var oldsize = cast[PGenericSeq](old).len*elemSize + GenericSeqSize
  copyMem(res, ol, oldsize + sizeof(Cell))
  zeroMem(cast[pointer](cast[ByteAddress](res)+% oldsize +% sizeof(Cell)),
          newsize-oldsize)
  sysAssert((cast[ByteAddress](res) and (MemAlign-1)) == 0, "growObj: 3")
  result = cellToUsr(res)

proc growObj(old: pointer, newsize: int): pointer {.rtl.} =
  result = growObj(old, newsize, region)

