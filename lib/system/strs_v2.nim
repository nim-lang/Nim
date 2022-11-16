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
    cap: int
    data: UncheckedArray[char]

  NimStringV2 {.core.} = object
    len: int
    p: ptr NimStrPayload ## can be nil if len == 0.

const nimStrVersion {.core.} = 2

template isLiteral(s): bool = (s.p == nil) or (s.p.cap and strlitFlag) == strlitFlag

template contentSize(cap): int = cap + 1 + sizeof(NimStrPayloadBase)

template frees(s) =
  if not isLiteral(s):
    when compileOption("threads"):
      deallocShared(s.p)
    else:
      dealloc(s.p)

proc resize(old: int): int {.inline.} =
  if old <= 0: result = 4
  elif old < 65536: result = old * 2
  else: result = old * 3 div 2 # for large arrays * 3/2 is better

proc prepareAdd(s: var NimStringV2; addlen: int) {.compilerRtl.} =
  let newLen = s.len + addlen
  if isLiteral(s):
    let oldP = s.p
    # can't mutate a literal, so we need a fresh copy here:
    when compileOption("threads"):
      s.p = cast[ptr NimStrPayload](allocShared0(contentSize(newLen)))
    else:
      s.p = cast[ptr NimStrPayload](alloc0(contentSize(newLen)))
    s.p.cap = newLen
    if s.len > 0:
      # we are about to append, so there is no need to copy the \0 terminator:
      copyMem(unsafeAddr s.p.data[0], unsafeAddr oldP.data[0], min(s.len, newLen))
  else:
    let oldCap = s.p.cap and not strlitFlag
    if newLen > oldCap:
      let newCap = max(newLen, resize(oldCap))
      when compileOption("threads"):
        s.p = cast[ptr NimStrPayload](reallocShared0(s.p, contentSize(oldCap), contentSize(newCap)))
      else:
        s.p = cast[ptr NimStrPayload](realloc0(s.p, contentSize(oldCap), contentSize(newCap)))
      s.p.cap = newCap

proc nimAddCharV1(s: var NimStringV2; c: char) {.compilerRtl, inline.} =
  #if (s.p == nil) or (s.len+1 > s.p.cap and not strlitFlag):
  prepareAdd(s, 1)
  s.p.data[s.len] = c
  s.p.data[s.len+1] = '\0'
  inc s.len

proc toNimStr(str: cstring, len: int): NimStringV2 {.compilerproc.} =
  if len <= 0:
    result = NimStringV2(len: 0, p: nil)
  else:
    when compileOption("threads"):
      var p = cast[ptr NimStrPayload](allocShared0(contentSize(len)))
    else:
      var p = cast[ptr NimStrPayload](alloc0(contentSize(len)))
    p.cap = len
    if len > 0:
      # we are about to append, so there is no need to copy the \0 terminator:
      copyMem(unsafeAddr p.data[0], str, len)
    result = NimStringV2(len: len, p: p)

proc cstrToNimstr(str: cstring): NimStringV2 {.compilerRtl.} =
  if str == nil: toNimStr(str, 0)
  else: toNimStr(str, str.len)

proc nimToCStringConv(s: NimStringV2): cstring {.compilerproc, nonReloadable, inline.} =
  if s.len == 0: result = cstring""
  else: result = cast[cstring](unsafeAddr s.p.data)

proc appendString(dest: var NimStringV2; src: NimStringV2) {.compilerproc, inline.} =
  if src.len > 0:
    # also copy the \0 terminator:
    copyMem(unsafeAddr dest.p.data[dest.len], unsafeAddr src.p.data[0], src.len+1)
    inc dest.len, src.len

proc appendChar(dest: var NimStringV2; c: char) {.compilerproc, inline.} =
  dest.p.data[dest.len] = c
  dest.p.data[dest.len+1] = '\0'
  inc dest.len

proc rawNewString(space: int): NimStringV2 {.compilerproc.} =
  # this is also 'system.newStringOfCap'.
  if space <= 0:
    result = NimStringV2(len: 0, p: nil)
  else:
    when compileOption("threads"):
      var p = cast[ptr NimStrPayload](allocShared0(contentSize(space)))
    else:
      var p = cast[ptr NimStrPayload](alloc0(contentSize(space)))
    p.cap = space
    result = NimStringV2(len: 0, p: p)

proc mnewString(len: int): NimStringV2 {.compilerproc.} =
  if len <= 0:
    result = NimStringV2(len: 0, p: nil)
  else:
    when compileOption("threads"):
      var p = cast[ptr NimStrPayload](allocShared0(contentSize(len)))
    else:
      var p = cast[ptr NimStrPayload](alloc0(contentSize(len)))
    p.cap = len
    result = NimStringV2(len: len, p: p)

proc setLengthStrV2(s: var NimStringV2, newLen: int) {.compilerRtl.} =
  if newLen == 0:
    discard "do not free the buffer here, pattern 's.setLen 0' is common for avoiding allocations"
  else:
    if newLen > s.len or isLiteral(s):
      prepareAdd(s, newLen - s.len)
    s.p.data[newLen] = '\0'
  s.len = newLen

proc nimAsgnStrV2(a: var NimStringV2, b: NimStringV2) {.compilerRtl.} =
  if a.p == b.p: return
  if isLiteral(b):
    # we can shallow copy literals:
    frees(a)
    a.len = b.len
    a.p = b.p
  else:
    if isLiteral(a) or (a.p.cap and not strlitFlag) < b.len:
      # we have to allocate the 'cap' here, consider
      # 'let y = newStringOfCap(); var x = y'
      # on the other hand... These get turned into moves now.
      frees(a)
      when compileOption("threads"):
        a.p = cast[ptr NimStrPayload](allocShared0(contentSize(b.len)))
      else:
        a.p = cast[ptr NimStrPayload](alloc0(contentSize(b.len)))
      a.p.cap = b.len
    a.len = b.len
    copyMem(unsafeAddr a.p.data[0], unsafeAddr b.p.data[0], b.len+1)

proc nimPrepareStrMutationImpl(s: var NimStringV2) =
  let oldP = s.p
  # can't mutate a literal, so we need a fresh copy here:
  when compileOption("threads"):
    s.p = cast[ptr NimStrPayload](allocShared0(contentSize(s.len)))
  else:
    s.p = cast[ptr NimStrPayload](alloc0(contentSize(s.len)))
  s.p.cap = s.len
  copyMem(unsafeAddr s.p.data[0], unsafeAddr oldP.data[0], s.len+1)

proc nimPrepareStrMutationV2(s: var NimStringV2) {.compilerRtl, inline.} =
  if s.p != nil and (s.p.cap and strlitFlag) == strlitFlag:
    nimPrepareStrMutationImpl(s)

proc prepareMutation*(s: var string) {.inline.} =
  # string literals are "copy on write", so you need to call
  # `prepareMutation` before modifying the strings via `addr`.
  {.cast(noSideEffect).}:
    let s = unsafeAddr s
    nimPrepareStrMutationV2(cast[ptr NimStringV2](s)[])
