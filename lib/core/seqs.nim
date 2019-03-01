#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# import typetraits
# strs already imported allocators for us.

proc supportsCopyMem(t: typedesc): bool {.magic: "TypeTrait".}

## Default seq implementation used by Nim's core.
type
  NimSeqPayload[T] = object
    cap: int
    region: Allocator
    data: UncheckedArray[T]

  NimSeqV2*[T] = object
    len: int
    p: ptr NimSeqPayload[T]

const nimSeqVersion {.core.} = 2

template payloadSize(cap): int = cap * sizeof(T) + sizeof(int) + sizeof(Allocator)

# XXX make code memory safe for overflows in '*'

when false:
  # this is currently not part of Nim's type bound operators and so it's
  # built into the tracing proc generation just like before.
  proc `=trace`[T](s: NimSeqV2[T]) =
    for i in 0 ..< s.len: `=trace`(s.data[i])

proc `=destroy`[T](s: var seq[T]) =
  var x = cast[ptr NimSeqV2[T]](addr s)
  var p = x.p
  if p != nil:
    mixin `=destroy`
    when not supportsCopyMem(T):
      for i in 0..<x.len: `=destroy`(p.data[i])
    if p.region != nil:
      p.region.dealloc(p.region, p, payloadSize(p.cap))
    x.p = nil
    x.len = 0

proc `=`[T](x: var seq[T]; y: seq[T]) =
  mixin `=destroy`
  var a = cast[ptr NimSeqV2[T]](addr x)
  var b = cast[ptr NimSeqV2[T]](unsafeAddr y)

  if a.p == b.p: return
  `=destroy`(x)
  a.len = b.len
  if b.p != nil:
    a.p = cast[type(a.p)](alloc(payloadSize(a.len)))
    when supportsCopyMem(T):
      if a.len > 0:
        copyMem(unsafeAddr a.p.data[0], unsafeAddr b.p.data[0], a.len * sizeof(T))
    else:
      for i in 0..<a.len:
        a.p.data[i] = b.p.data[i]

proc `=sink`[T](x: var seq[T]; y: seq[T]) =
  mixin `=destroy`
  var a = cast[ptr NimSeqV2[T]](addr x)
  var b = cast[ptr NimSeqV2[T]](unsafeAddr y)
  if a.p != nil and a.p != b.p:
    `=destroy`(x)
  a.len = b.len
  a.p = b.p


type
  PayloadBase = object
    cap: int
    region: Allocator

proc newSeqPayload(cap, elemSize: int): pointer {.compilerRtl, raises: [].} =
  # we have to use type erasure here as Nim does not support generic
  # compilerProcs. Oh well, this will all be inlined anyway.
  if cap > 0:
    let region = getLocalAllocator()
    var p = cast[ptr PayloadBase](region.alloc(region, cap * elemSize + sizeof(int) + sizeof(Allocator)))
    p.region = region
    p.cap = cap
    result = p
  else:
    result = nil

proc prepareSeqAdd(len: int; p: pointer; addlen, elemSize: int): pointer {.
    compilerRtl, noSideEffect, raises: [].} =
  {.noSideEffect.}:
    if len+addlen <= len:
      result = p
    elif p == nil:
      result = newSeqPayload(len+addlen, elemSize)
    else:
      # Note: this means we cannot support things that have internal pointers as
      # they get reallocated here. This needs to be documented clearly.
      var p = cast[ptr PayloadBase](p)
      let region = if p.region == nil: getLocalAllocator() else: p.region
      let cap = max(resize(p.cap), len+addlen)
      var q = cast[ptr PayloadBase](region.realloc(region, p,
        sizeof(int) + sizeof(Allocator) + elemSize * p.cap,
        sizeof(int) + sizeof(Allocator) + elemSize * cap))
      q.region = region
      q.cap = cap
      result = q

proc shrink*[T](x: var seq[T]; newLen: Natural) =
  mixin `=destroy`
  sysAssert newLen <= x.len, "invalid newLen parameter for 'shrink'"
  when not supportsCopyMem(T):
    for i in countdown(x.len - 1, newLen - 1):
      `=destroy`(x[i])
  # XXX This is wrong for const seqs that were moved into 'x'!
  cast[ptr NimSeqV2[T]](addr x).len = newLen

proc grow*[T](x: var seq[T]; newLen: Natural; value: T) =
  let oldLen = x.len
  if newLen <= oldLen: return
  var xu = cast[ptr NimSeqV2[T]](addr x)
  if xu.p == nil or xu.p.cap < newLen:
    xu.p = cast[typeof(xu.p)](prepareSeqAdd(oldLen, xu.p, newLen - oldLen, sizeof(T)))
  xu.len = newLen
  for i in oldLen .. newLen-1:
    xu.p.data[i] = value

proc setLen[T](s: var seq[T], newlen: Natural) =
  {.noSideEffect.}:
    if newlen < s.len:
      shrink(s, newLen)
    else:
      var v: T # get the default value of 'v'
      grow(s, newLen, v)

when false:
  proc resize[T](s: var NimSeqV2[T]) =
    let old = s.cap
    if old == 0: s.cap = 8
    else: s.cap = (s.cap * 3) shr 1
    s.data = cast[type(s.data)](realloc(s.data, old * sizeof(T), s.cap * sizeof(T)))

  proc reserveSlot[T](x: var NimSeqV2[T]): ptr T =
    if x.len >= x.cap: resize(x)
    result = addr(x.data[x.len])
    inc x.len

  template add*[T](x: var NimSeqV2[T]; y: T) =
    reserveSlot(x)[] = y

  template `[]`*[T](x: NimSeqV2[T]; i: Natural): T =
    assert i < x.len
    x.data[i]

  template `[]=`*[T](x: NimSeqV2[T]; i: Natural; y: T) =
    assert i < x.len
    x.data[i] = y

  proc `@`*[T](elems: openArray[T]): NimSeqV2[T] =
    result.cap = elems.len
    result.len = elems.len
    result.data = cast[type(result.data)](alloc(result.cap * sizeof(T)))
    when supportsCopyMem(T):
      copyMem(result.data, unsafeAddr(elems[0]), result.cap * sizeof(T))
    else:
      for i in 0..<result.len:
        result.data[i] = elems[i]
