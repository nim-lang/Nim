#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# import typetraits
# strs already imported allocateds for us.


# Some optimizations here may be not to empty-seq-initialize some symbols, then StrictNotNil complains.
{.push warning[StrictNotNil]: off.}  # See https://github.com/nim-lang/Nim/issues/21401


proc supportsCopyMem(t: typedesc): bool {.magic: "TypeTrait".}

## Default seq implementation used by Nim's core.
type
  NimSeqPayloadBase = object
    cap: int

  NimSeqPayload[T] = object
    cap: int
    data: UncheckedArray[T]

  NimSeqV2*[T] = object # \
    # if you change this implementation, also change seqs_v2_reimpl.nim!
    len: int
    p: ptr NimSeqPayload[T]

const nimSeqVersion {.core.} = 2

# XXX make code memory safe for overflows in '*'

proc newSeqPayload(cap, elemSize, elemAlign: int): pointer {.compilerRtl, raises: [].} =
  # we have to use type erasure here as Nim does not support generic
  # compilerProcs. Oh well, this will all be inlined anyway.
  if cap > 0:
    var p = cast[ptr NimSeqPayloadBase](alignedAlloc0(align(sizeof(NimSeqPayloadBase), elemAlign) + cap * elemSize, elemAlign))
    p.cap = cap
    result = p
  else:
    result = nil

template `+!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) +% s)

template `-!`(p: pointer, s: int): pointer =
  cast[pointer](cast[int](p) -% s)

proc prepareSeqAdd(len: int; p: pointer; addlen, elemSize, elemAlign: int): pointer {.
    noSideEffect, tags: [], raises: [], compilerRtl.} =
  {.noSideEffect.}:
    let headerSize = align(sizeof(NimSeqPayloadBase), elemAlign)
    if addlen <= 0:
      result = p
    elif p == nil:
      result = newSeqPayload(len+addlen, elemSize, elemAlign)
    else:
      # Note: this means we cannot support things that have internal pointers as
      # they get reallocated here. This needs to be documented clearly.
      var p = cast[ptr NimSeqPayloadBase](p)
      let oldCap = p.cap and not strlitFlag
      let newCap = max(resize(oldCap), len+addlen)
      if (p.cap and strlitFlag) == strlitFlag:
        var q = cast[ptr NimSeqPayloadBase](alignedAlloc0(headerSize + elemSize * newCap, elemAlign))
        copyMem(q +! headerSize, p +! headerSize, len * elemSize)
        q.cap = newCap
        result = q
      else:
        let oldSize = headerSize + elemSize * oldCap
        let newSize = headerSize + elemSize * newCap
        var q = cast[ptr NimSeqPayloadBase](alignedRealloc0(p, oldSize, newSize, elemAlign))
        q.cap = newCap
        result = q

proc shrink*[T](x: var seq[T]; newLen: Natural) {.tags: [], raises: [].} =
  when nimvm:
    {.cast(tags: []).}:
      setLen(x, newLen)
  else:
    #sysAssert newLen <= x.len, "invalid newLen parameter for 'shrink'"
    when not supportsCopyMem(T):
      for i in countdown(x.len - 1, newLen):
        reset x[i]
    # XXX This is wrong for const seqs that were moved into 'x'!
    {.noSideEffect.}:
      cast[ptr NimSeqV2[T]](addr x).len = newLen

proc grow*[T](x: var seq[T]; newLen: Natural; value: T) =
  let oldLen = x.len
  #sysAssert newLen >= x.len, "invalid newLen parameter for 'grow'"
  if newLen <= oldLen: return
  var xu = cast[ptr NimSeqV2[T]](addr x)
  if xu.p == nil or (xu.p.cap and not strlitFlag) < newLen:
    xu.p = cast[typeof(xu.p)](prepareSeqAdd(oldLen, xu.p, newLen - oldLen, sizeof(T), alignof(T)))
  xu.len = newLen
  for i in oldLen .. newLen-1:
    xu.p.data[i] = value

proc add*[T](x: var seq[T]; y: sink T) {.magic: "AppendSeqElem", noSideEffect, nodestroy.} =
  ## Generic proc for adding a data item `y` to a container `x`.
  ##
  ## For containers that have an order, `add` means *append*. New generic
  ## containers should also call their adding proc `add` for consistency.
  ## Generic code becomes much easier to write if the Nim naming scheme is
  ## respected.
  {.cast(noSideEffect).}:
    let oldLen = x.len
    var xu = cast[ptr NimSeqV2[T]](addr x)
    if xu.p == nil or (xu.p.cap and not strlitFlag) < oldLen+1:
      xu.p = cast[typeof(xu.p)](prepareSeqAdd(oldLen, xu.p, 1, sizeof(T), alignof(T)))
    xu.len = oldLen+1
    # .nodestroy means `xu.p.data[oldLen] = value` is compiled into a
    # copyMem(). This is fine as know by construction that
    # in `xu.p.data[oldLen]` there is nothing to destroy.
    # We also save the `wasMoved + destroy` pair for the sink parameter.
    xu.p.data[oldLen] = y

proc setLen[T](s: var seq[T], newlen: Natural) =
  {.noSideEffect.}:
    if newlen < s.len:
      shrink(s, newlen)
    else:
      let oldLen = s.len
      if newlen <= oldLen: return
      var xu = cast[ptr NimSeqV2[T]](addr s)
      if xu.p == nil or (xu.p.cap and not strlitFlag) < newlen:
        xu.p = cast[typeof(xu.p)](prepareSeqAdd(oldLen, xu.p, newlen - oldLen, sizeof(T), alignof(T)))
      xu.len = newlen
      for i in oldLen..<newlen:
        xu.p.data[i] = default(T)

proc newSeq[T](s: var seq[T], len: Natural) =
  shrink(s, 0)
  setLen(s, len)



func capacity*[T](self: seq[T]): int {.inline.} =
  ## Returns the current capacity of the seq.
  # See https://github.com/nim-lang/RFCs/issues/460
  runnableExamples:
    var lst = newSeqOfCap[string](cap = 42)
    lst.add "Nim"
    assert lst.capacity == 42

  let sek = cast[ptr NimSeqV2[T]](unsafeAddr self)
  result = if sek.p != nil: sek.p.cap and not strlitFlag else: 0


{.pop.}  # See https://github.com/nim-lang/Nim/issues/21401
