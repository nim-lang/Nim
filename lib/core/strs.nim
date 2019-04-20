#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Default new string implementation used by Nim's core.

when false:
  # these are to be implemented or changed in the code generator.

  #proc rawNewStringNoInit(space: int): NimString {.compilerProc.}
  # seems to be unused.
  proc copyDeepString(src: NimString): NimString {.inline.}
  # ----------------- sequences ----------------------------------------------

  proc incrSeqV3(s: PGenericSeq, typ: PNimType): PGenericSeq {.compilerProc.}
  proc setLengthSeqV2(s: PGenericSeq, typ: PNimType, newLen: int): PGenericSeq {.
      compilerRtl.}
  proc newSeq(typ: PNimType, len: int): pointer {.compilerRtl.}
  proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.}

import allocators

type
  NimStrPayload {.core.} = object
    cap: int
    allocator: Allocator
    data: UncheckedArray[char]

  NimStringV2 {.core.} = object
    len: int
    p: ptr NimStrPayload ## can be nil if len == 0.

const nimStrVersion {.core.} = 2

template isLiteral(s): bool = s.p == nil or s.p.allocator == nil

template contentSize(cap): int = cap + 1 + sizeof(int) + sizeof(Allocator)

template frees(s) =
  if not isLiteral(s):
    s.p.allocator.dealloc(s.p.allocator, s.p, contentSize(s.p.cap))

when not defined(nimV2):
  proc `=destroy`(s: var string) =
    var a = cast[ptr NimStringV2](addr s)
    frees(a)
    a.len = 0
    a.p = nil

  proc `=sink`(x: var string, y: string) =
    var a = cast[ptr NimStringV2](addr x)
    var b = cast[ptr NimStringV2](unsafeAddr y)
    # we hope this is optimized away for not yet alive objects:
    if unlikely(a.p == b.p): return
    frees(a)
    a.len = b.len
    a.p = b.p

  proc `=`(x: var string, y: string) =
    var a = cast[ptr NimStringV2](addr x)
    var b = cast[ptr NimStringV2](unsafeAddr y)
    if unlikely(a.p == b.p): return
    frees(a)
    a.len = b.len
    if isLiteral(b):
      # we can shallow copy literals:
      a.p = b.p
    else:
      let allocator = if a.p != nil and a.p.allocator != nil: a.p.allocator else: getLocalAllocator()
      # we have to allocate the 'cap' here, consider
      # 'let y = newStringOfCap(); var x = y'
      # on the other hand... These get turned into moves now.
      a.p = cast[ptr NimStrPayload](allocator.alloc(allocator, contentSize(b.len)))
      a.p.allocator = allocator
      a.p.cap = b.len
      copyMem(unsafeAddr a.p.data[0], unsafeAddr b.p.data[0], b.len+1)

proc resize(old: int): int {.inline.} =
  if old <= 0: result = 4
  elif old < 65536: result = old * 2
  else: result = old * 3 div 2 # for large arrays * 3/2 is better

proc prepareAdd(s: var NimStringV2; addlen: int) {.compilerRtl.} =
  if isLiteral(s) and addlen > 0:
    let oldP = s.p
    # can't mutate a literal, so we need a fresh copy here:
    let allocator = getLocalAllocator()
    s.p = cast[ptr NimStrPayload](allocator.alloc(allocator, contentSize(s.len + addlen)))
    s.p.allocator = allocator
    s.p.cap = s.len + addlen
    if s.len > 0:
      # we are about to append, so there is no need to copy the \0 terminator:
      copyMem(unsafeAddr s.p.data[0], unsafeAddr oldP.data[0], s.len)
  elif s.len + addlen > s.p.cap:
    let cap = max(s.len + addlen, resize(s.p.cap))
    s.p = cast[ptr NimStrPayload](s.p.allocator.realloc(s.p.allocator, s.p,
      oldSize = contentSize(s.p.cap),
      newSize = contentSize(cap)))
    s.p.cap = cap

proc nimAddCharV1(s: var NimStringV2; c: char) {.compilerRtl.} =
  prepareAdd(s, 1)
  s.p.data[s.len] = c
  s.p.data[s.len+1] = '\0'
  inc s.len

proc toNimStr(str: cstring, len: int): NimStringV2 {.compilerProc.} =
  if len <= 0:
    result = NimStringV2(len: 0, p: nil)
  else:
    let allocator = getLocalAllocator()
    var p = cast[ptr NimStrPayload](allocator.alloc(allocator, contentSize(len)))
    p.allocator = allocator
    p.cap = len
    if len > 0:
      # we are about to append, so there is no need to copy the \0 terminator:
      copyMem(unsafeAddr p.data[0], str, len)
    result = NimStringV2(len: len, p: p)

proc cstrToNimstr(str: cstring): NimStringV2 {.compilerRtl.} =
  if str == nil: toNimStr(str, 0)
  else: toNimStr(str, str.len)

proc nimToCStringConv(s: NimStringV2): cstring {.compilerProc, nonReloadable, inline.} =
  if s.len == 0: result = cstring""
  else: result = cstring(unsafeAddr s.p.data)

proc appendString(dest: var NimStringV2; src: NimStringV2) {.compilerproc, inline.} =
  if src.len > 0:
    # also copy the \0 terminator:
    copyMem(unsafeAddr dest.p.data[dest.len], unsafeAddr src.p.data[0], src.len+1)
    inc dest.len, src.len

proc appendChar(dest: var NimStringV2; c: char) {.compilerproc, inline.} =
  dest.p.data[dest.len] = c
  dest.p.data[dest.len+1] = '\0'
  inc dest.len

proc rawNewString(space: int): NimStringV2 {.compilerProc.} =
  # this is also 'system.newStringOfCap'.
  if space <= 0:
    result = NimStringV2(len: 0, p: nil)
  else:
    let allocator = getLocalAllocator()
    var p = cast[ptr NimStrPayload](allocator.alloc(allocator, contentSize(space)))
    p.allocator = allocator
    p.cap = space
    result = NimStringV2(len: 0, p: p)

proc mnewString(len: int): NimStringV2 {.compilerProc.} =
  if len <= 0:
    result = NimStringV2(len: 0, p: nil)
  else:
    let allocator = getLocalAllocator()
    var p = cast[ptr NimStrPayload](allocator.alloc(allocator, contentSize(len)))
    p.allocator = allocator
    p.cap = len
    result = NimStringV2(len: len, p: p)

proc setLengthStrV2(s: var NimStringV2, newLen: int) {.compilerRtl.} =
  if newLen == 0:
    frees(s)
    s.p = nil
  elif newLen > s.len or isLiteral(s):
    prepareAdd(s, newLen - s.len)
  s.len = newLen

proc nimAsgnStrV2(a: var NimStringV2, b: NimStringV2) {.compilerRtl.} =
  if a.p == b.p: return
  if isLiteral(b):
    # we can shallow copy literals:
    frees(a)
    a.len = b.len
    a.p = b.p
  else:
    if isLiteral(a) or a.p.cap < b.len:
      let allocator = if a.p != nil and a.p.allocator != nil: a.p.allocator else: getLocalAllocator()
      # we have to allocate the 'cap' here, consider
      # 'let y = newStringOfCap(); var x = y'
      # on the other hand... These get turned into moves now.
      frees(a)
      a.p = cast[ptr NimStrPayload](allocator.alloc(allocator, contentSize(b.len)))
      a.p.allocator = allocator
      a.p.cap = b.len
    a.len = b.len
    copyMem(unsafeAddr a.p.data[0], unsafeAddr b.p.data[0], b.len+1)
