#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Default new string implementation used by Nim's core.

type
  NimStrPayloadBase = object
    cap: int

  NimStrPayload {.core.} = object
    data: UncheckedArray[char]

  NimStringV3 {.core.} = object
    rawlen: int
    p: ptr UncheckedArray[char] ## can be nil if len == 0.
    ## cap lives at the negative offset
    ## non-zero terminated

const nimStrVersion {.core.} = 3

template isLiteral(s): bool = (s.rawlen and 1) == 1
template cap(p: pointer): int =
  cast[ptr NimStrPayloadBase](cast[int](p) -% sizeof(NimStrPayloadBase))[].cap

template `cap=`(p: pointer, size: int) =
  cast[ptr NimStrPayloadBase](cast[int](p) -% sizeof(NimStrPayloadBase))[].cap = size


proc len(s: NimStringV3): int = s.rawlen shr 1

template contentSize(cap): int = cap + sizeof(NimStrPayloadBase)

template frees(s) =
  if not isLiteral(s):
    when compileOption("threads"):
      deallocShared(s.p -% sizeof(NimStrPayloadBase))
    else:
      dealloc(s.p -% sizeof(NimStrPayloadBase))

template allocPayload(newLen: int): ptr UncheckedArray[char] =
  when compileOption("threads"):
    cast[ptr UncheckedArray[char]](allocShared(contentSize(newLen) +! sizeof(NimStrPayloadBase)))
  else:
    cast[ptr UncheckedArray[char]](alloc(contentSize(newLen)) +! sizeof(NimStrPayloadBase))

template allocPayload0(newLen: int): ptr UncheckedArray[char] =
  when compileOption("threads"):
    cast[ptr UncheckedArray[char]](allocShared0(contentSize(newLen)) +! sizeof(NimStrPayloadBase))
  else:
    cast[ptr UncheckedArray[char]](alloc0(contentSize(newLen)) +! sizeof(NimStrPayloadBase))

template reallocPayload(p: pointer, newLen: int): ptr UncheckedArray[char] =
  when compileOption("threads"):
    cast[ptr UncheckedArray[char]](reallocShared(p, contentSize(newLen)) +! sizeof(NimStrPayloadBase))
  else:
    cast[ptr UncheckedArray[char]](realloc(p, contentSize(newLen)) +! sizeof(NimStrPayloadBase))

template reallocPayload0(p: pointer; oldLen, newLen: int): ptr UncheckedArray[char] =
  when compileOption("threads"):
    cast[ptr UncheckedArray[char]](reallocShared0(p, contentSize(oldLen), contentSize(newLen)) +! sizeof(NimStrPayloadBase))
  else:
    cast[ptr UncheckedArray[char]](realloc0(p, contentSize(oldLen), contentSize(newLen)) +! sizeof(NimStrPayloadBase))

proc resize(old: int): int {.inline.} =
  if old <= 0: result = 4
  elif old <= high(int16): result = old * 2
  else: result = old * 3 div 2 # for large arrays * 3/2 is better

proc prepareAdd(s: var NimStringV3; addLen: int) {.compilerRtl.} =
  let newLen = s.len + addLen
  if isLiteral(s):
    let oldP = s.p
    # can't mutate a literal, so we need a fresh copy here:
    s.p = allocPayload(newLen)
    s.p.cap = newLen
    if s.len > 0:
      # we are about to append
      copyMem(unsafeAddr s.p[0], unsafeAddr oldP[0], min(s.len, newLen))
  else:
    let oldCap = s.p.cap
    if newLen > oldCap:
      let newCap = max(newLen, resize(oldCap))
      s.p = reallocPayload(s.p -% sizeof(NimStrPayloadBase), newCap)
      s.p.cap = newCap
      if newLen < newCap:
        ## TODO: be careful with off by one
        zeroMem(cast[pointer](addr s.p.data[newLen]), newCap - newLen)

proc nimAddCharV1(s: var NimStringV3; c: char) {.compilerRtl, inl.} =
  #if (s.p == nil) or (s.len+1 > s.p.cap and not strlitFlag):
  prepareAdd(s, 1)
  s.p.data[s.len] = c
  inc s.len

proc toNimStr(str: cstring, len: int): NimStringV3 {.compilerproc.} =
  if len <= 0:
    result = NimStringV3(len: 0, p: nil)
  else:
    var p = allocPayload(len)
    p.cap = len
    copyMem(unsafeAddr p.data[0], str, len)
    result = NimStringV3(len: len, p: p)

proc cstrToNimstr(str: cstring): NimStringV3 {.compilerRtl.} =
  if str == nil: toNimStr(str, 0)
  else: toNimStr(str, str.len)

proc nimToCStringConv(s: NimStringV3): cstring {.compilerproc, nonReloadable, inline.} =
  ## TODO: fixme: inject conversions somehwere
  if s.len == 0: result = cstring""
  else: result = cast[cstring](unsafeAddr s.p.data)

proc appendString(dest: var NimStringV3; src: NimStringV3) {.compilerproc, inline.} =
  if src.len > 0:
    copyMem(unsafeAddr dest.p.data[dest.len], unsafeAddr src.p.data[0], src.len)
    inc dest.len, src.len

proc appendChar(dest: var NimStringV3; c: char) {.compilerproc, inline.} =
  dest.p.data[dest.len] = c

proc rawNewString(space: int): NimStringV3 {.compilerproc.} =
  # this is also 'system.newStringOfCap'.
  if space <= 0:
    result = NimStringV3(len: 0, p: nil)
  else:
    var p = allocPayload(space)
    p.cap = space
    result = NimStringV3(len: 0, p: p)

proc mnewString(len: int): NimStringV3 {.compilerproc.} =
  if len <= 0:
    result = NimStringV3(len: 0, p: nil)
  else:
    var p = allocPayload0(len)
    p.cap = len
    result = NimStringV3(len: len, p: p)

proc setLengthStrV2(s: var NimStringV3, newLen: int) {.compilerRtl.} =
  if newLen == 0:
    discard "do not free the buffer here, pattern 's.setLen 0' is common for avoiding allocations"
  else:
    if isLiteral(s):
      let oldP = s.p
      s.p = allocPayload(newLen)
      s.p.cap = newLen
      if s.len > 0:
        copyMem(unsafeAddr s.p.data[0], unsafeAddr oldP.data[0], min(s.len, newLen))
        if newLen > s.len:
          zeroMem(cast[pointer](addr s.p.data[s.len]), newLen - s.len)
        # else:
        #   s.p.data[newLen] = '\0'
      else:
        zeroMem(cast[pointer](addr s.p.data[0]), newLen)
    elif newLen > s.len:
      let oldCap = s.p.cap
      if newLen > oldCap:
        let newCap = max(newLen, resize(oldCap))
        s.p = reallocPayload0(s.p -% sizeof(NimStrPayloadBase), oldCap, newCap)
        s.p.cap = newCap

  s.len = newLen

proc nimAsgnStrV2(a: var NimStringV3, b: NimStringV3) {.compilerRtl.} =
  if a.p == b.p: return
  if isLiteral(b):
    # we can shallow copy literals:
    frees(a)
    a.len = b.len
    a.p = b.p
  else:
    if isLiteral(a) or a.p.cap < b.len:
      # we have to allocate the 'cap' here, consider
      # 'let y = newStringOfCap(); var x = y'
      # on the other hand... These get turned into moves now.
      frees(a)
      a.p = allocPayload(b.len)
      a.p.cap = b.len
    a.len = b.len
    copyMem(unsafeAddr a.p.data[0], unsafeAddr b.p.data[0], b.len)

proc nimPrepareStrMutationImpl(s: var NimStringV3) =
  let oldP = s.p
  # can't mutate a literal, so we need a fresh copy here:
  s.p = allocPayload(s.len)
  s.p.cap = s.len
  copyMem(unsafeAddr s.p.data[0], unsafeAddr oldP.data[0], s.len)

proc nimPrepareStrMutationV2(s: var NimStringV3) {.compilerRtl, inl.} =
  if isLiteral(s):
    nimPrepareStrMutationImpl(s)

proc prepareMutation*(s: var string) {.inline.} =
  # string literals are "copy on write", so you need to call
  # `prepareMutation` before modifying the strings via `addr`.
  {.cast(noSideEffect).}:
    let s = unsafeAddr s
    nimPrepareStrMutationV2(cast[ptr NimStringV3](s)[])

proc nimAddStrV1(s: var NimStringV3; src: NimStringV3) {.compilerRtl, inl.} =
  #if (s.p == nil) or (s.len+1 > s.p.cap and not strlitFlag):
  prepareAdd(s, src.len)
  appendString s, src

proc nimDestroyStrV1(s: NimStringV3) {.compilerRtl, inl.} =
  frees(s)

proc nimStrAtLe(s: string; idx: int; ch: char): bool {.compilerRtl, inl.} =
  result = idx < s.len and s[idx] <= ch

func capacity*(self: string): int {.inline.} =
  ## Returns the current capacity of the string. Intern strings
  ## don't have a capacity and 0 will be returned
  # See https://github.com/nim-lang/RFCs/issues/460
  runnableExamples:
    var str = newStringOfCap(cap = 42)
    str.add "Nim"
    assert str.capacity == 42

  let str = cast[ptr NimStringV3](unsafeAddr self)
  if isLiteral(str):
    result = 0
  else:
    result = if str.p != nil: str.p.cap else: 0
