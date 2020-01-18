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
    allocator: Allocator
    data: UncheckedArray[T]

  NimSeqV2*[T] = object
    len: int
    p: ptr NimSeqPayload[T]

const nimSeqVersion {.core.} = 2

template payloadSize(cap): int = cap * sizeof(T) + sizeof(int) + sizeof(Allocator)

# XXX make code memory safe for overflows in '*'

type
  PayloadBase = object
    cap: int
    allocator: Allocator

proc newSeqPayload(cap, elemSize: int): pointer {.compilerRtl, raises: [].} =
  # we have to use type erasure here as Nim does not support generic
  # compilerProcs. Oh well, this will all be inlined anyway.
  if cap > 0:
    let allocator = getLocalAllocator()
    var p = cast[ptr PayloadBase](allocator.alloc(allocator, cap * elemSize + sizeof(int) + sizeof(Allocator)))
    p.allocator = allocator
    p.cap = cap
    result = p
  else:
    result = nil

proc prepareSeqAdd(len: int; p: pointer; addlen, elemSize: int): pointer {.
    noSideEffect, raises: [].} =
  {.noSideEffect.}:
    template `+!`(p: pointer, s: int): pointer =
      cast[pointer](cast[int](p) +% s)

    const headerSize = sizeof(int) + sizeof(Allocator)
    if addlen <= 0:
      result = p
    elif p == nil:
      result = newSeqPayload(len+addlen, elemSize)
    else:
      # Note: this means we cannot support things that have internal pointers as
      # they get reallocated here. This needs to be documented clearly.
      var p = cast[ptr PayloadBase](p)
      let cap = max(resize(p.cap), len+addlen)
      if p.allocator == nil:
        let allocator = getLocalAllocator()
        var q = cast[ptr PayloadBase](allocator.alloc(allocator,
          headerSize + elemSize * cap))
        copyMem(q +! headerSize, p +! headerSize, len * elemSize)
        q.allocator = allocator
        q.cap = cap
        result = q
      else:
        let allocator = p.allocator
        var q = cast[ptr PayloadBase](allocator.realloc(allocator, p,
          headerSize + elemSize * p.cap,
          headerSize + elemSize * cap))
        q.allocator = allocator
        q.cap = cap
        result = q

proc shrink*[T](x: var seq[T]; newLen: Natural) =
  when nimvm:
    setLen(x, newLen)
  else:
    mixin `=destroy`
    sysAssert newLen <= x.len, "invalid newLen parameter for 'shrink'"
    when not supportsCopyMem(T):
      for i in countdown(x.len - 1, newLen):
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

proc add*[T](x: var seq[T]; value: sink T) {.magic: "AppendSeqElem", noSideEffect.} =
  ## Generic proc for adding a data item `y` to a container `x`.
  ##
  ## For containers that have an order, `add` means *append*. New generic
  ## containers should also call their adding proc `add` for consistency.
  ## Generic code becomes much easier to write if the Nim naming scheme is
  ## respected.
  let oldLen = x.len
  var xu = cast[ptr NimSeqV2[T]](addr x)
  if xu.p == nil or xu.p.cap < oldLen+1:
    xu.p = cast[typeof(xu.p)](prepareSeqAdd(oldLen, xu.p, 1, sizeof(T)))
  xu.len = oldLen+1
  xu.p.data[oldLen] = value

proc setLen[T](s: var seq[T], newlen: Natural) =
  {.noSideEffect.}:
    if newlen < s.len:
      shrink(s, newlen)
    else:
      let oldLen = s.len
      if newlen <= oldLen: return
      var xu = cast[ptr NimSeqV2[T]](addr s)
      if xu.p == nil or xu.p.cap < newlen:
        xu.p = cast[typeof(xu.p)](prepareSeqAdd(oldLen, xu.p, newlen - oldLen, sizeof(T)))
      xu.len = newlen
