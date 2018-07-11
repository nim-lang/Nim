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
  proc rawNewString(space: int): NimString {.compilerProc.}
  proc mnewString(len: int): NimString {.compilerProc.}
  proc copyStrLast(s: NimString, start, last: int): NimString {.compilerProc.}
  proc nimToCStringConv(s: NimString): cstring {.compilerProc, inline.}
  proc copyStr(s: NimString, start: int): NimString {.compilerProc.}
  proc toNimStr(str: cstring, len: int): NimString {.compilerProc.}
  proc cstrToNimstr(str: cstring): NimString {.compilerRtl.}
  proc copyString(src: NimString): NimString {.compilerRtl.}
  proc copyStringRC1(src: NimString): NimString {.compilerRtl.}
  proc copyDeepString(src: NimString): NimString {.inline.}
  proc addChar(s: NimString, c: char): NimString
  proc resizeString(dest: NimString, addlen: int): NimString {.compilerRtl.}
  proc appendString(dest, src: NimString) {.compilerproc, inline.}
  proc appendChar(dest: NimString, c: char) {.compilerproc, inline.}
  proc setLengthStr(s: NimString, newLen: int): NimString {.compilerRtl.}
  # ----------------- sequences ----------------------------------------------

  proc incrSeqV3(s: PGenericSeq, typ: PNimType): PGenericSeq {.compilerProc.} =
  proc setLengthSeqV2(s: PGenericSeq, typ: PNimType, newLen: int): PGenericSeq {.
      compilerRtl.}
  proc newSeq(typ: PNimType, len: int): pointer {.compilerRtl.} =
  proc newSeqRC1(typ: PNimType, len: int): pointer {.compilerRtl.} =

import allocators

type
  StrContent = object
    cap: int
    region: Allocator
    data: UncheckedArray[char]

  NimString {.core.} = object
    len: int
    p: ptr StrContent ## invariant. Never nil

const nimStrVersion {.core.} = 2

template isLiteral(s): bool = s.len == 0 or s.p.region == nil

template contentSize(cap): int = cap + 1 + sizeof(int) + sizeof(Allocator)

template frees(s) =
  if not isLiteral(s):
    s.p.region.dealloc(s.p, contentSize(s.p.cap))

proc `=destroy`(s: var NimString) =
  frees(s)
  s.len = 0

template lose(a) =
  frees(a)

proc `=sink`(a: var NimString, b: NimString) =
  # we hope this is optimized away for not yet alive objects:
  if unlikely(a.p == b.p): return
  lose(a)
  a.len = b.len
  a.p = b.p

proc `=`(a: var NimString; b: NimString) =
  if unlikely(a.p == b.p): return
  lose(a)
  a.len = b.len
  if isLiteral(b):
    # we can shallow copy literals:
    a.p = b.p
  else:
    let region = if a.p.region != nil: a.p.region else: getLocalAllocator()
    # we have to allocate the 'cap' here, consider
    # 'let y = newStringOfCap(); var x = y'
    # on the other hand... These get turned into moves now.
    a.p = cast[ptr StrContent](region.alloc(contentSize(b.len)))
    a.p.region = region
    a.p.cap = b.len
    copyMem(unsafeAddr a.p.data[0], unsafeAddr b.p.data[0], b.len+1)

proc resize(old: int): int {.inline.} =
  if old <= 0: result = 4
  elif old < 65536: result = old * 2
  else: result = old * 3 div 2 # for large arrays * 3/2 is better

proc prepareAdd(s: var NimString; addlen: int) =
  if isLiteral(s):
    let oldP = s.p
    # can't mutate a literal, so we need a fresh copy here:
    let region = getLocalAllocator()
    s.p = cast[ptr StrContent](region.alloc(contentSize(s.len + addlen)))
    s.p.region = region
    s.p.cap = s.len + addlen
    if s.len > 0:
      # we are about to append, so there is no need to copy the \0 terminator:
      copyMem(unsafeAddr s.p.data[0], unsafeAddr oldP.data[0], s.len)
  elif s.len + addlen > s.p.cap:
    let cap = max(s.len + addlen, resize(s.p.cap))
    s.p = s.p.region.realloc(s.p, oldSize = contentSize(s.p.cap), newSize = contentSize(cap))
    s.p.cap = cap

proc nimAddCharV1(s: var NimString; c: char) {.compilerRtl.} =
  prepareAdd(s, 1)
  s.p.data[s.len] = c
  s.p.data[s.len+1] = '\0'
  inc s.len

proc ensure(s: var string; newLen: int) =
  let old = s.cap
  if newLen >= old:
    s.cap = max((old * 3) shr 1, newLen)
    if s.cap > 0:
      s.data = cast[type(s.data)](realloc(s.data, old + 1, s.cap + 1))

proc add*(s: var string; y: string) =
  if y.len != 0:
    let newLen = s.len + y.len
    ensure(s, newLen)
    copyMem(addr s.data[len], y.data, y.data.len + 1)
    s.len = newLen

proc newString*(len: int): string =
  result.len = len
  result.cap = len
  if len > 0:
    result.data = alloc0(len+1)

converter toCString(x: string): cstring {.core, inline.} =
  if x.len == 0: cstring"" else: cast[cstring](x.data)

proc newStringOfCap*(cap: int): string =
  result.len = 0
  result.cap = cap
  if cap > 0:
    result.data = alloc(cap+1)

proc `&`*(a, b: string): string =
  let sum = a.len + b.len
  result = newStringOfCap(sum)
  result.len = sum
  copyMem(addr result.data[0], a.data, a.len)
  copyMem(addr result.data[a.len], b.data, b.len)
  if sum > 0:
    result.data[sum] = '\0'

proc concat(x: openArray[string]): string {.core.} =
  ## used be the code generator to optimize 'x & y & z ...'
  var sum = 0
  for i in 0 ..< x.len: inc(sum, x[i].len)
  result = newStringOfCap(sum)
  sum = 0
  for i in 0 ..< x.len:
    let L = x[i].len
    copyMem(addr result.data[sum], x[i].data, L)
    inc(sum, L)

