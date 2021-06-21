#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Shared string support for Nim.

type
  UncheckedCharArray = UncheckedArray[char]

type
  Buffer = ptr object
    refcount: int
    capacity, realLen: int
    data: UncheckedCharArray

  SharedString* = object ## A string that can be shared. Slicing is O(1).
    buffer: Buffer
    first, len: int

proc decRef(b: Buffer) {.inline.} =
  if atomicDec(b.refcount) <= 0:
    deallocShared(b)

proc incRef(b: Buffer) {.inline.} =
  atomicInc(b.refcount)

{.experimental.}

proc `=destroy`*(s: SharedString) =
  #echo "destroyed"
  if not s.buffer.isNil:
    decRef(s.buffer)

when false:
  proc `=copy`*(dest: var SharedString; src: SharedString) =
    incRef(src.buffer)
    if not dest.buffer.isNil:
      decRef(dest.buffer)
    dest.buffer = src.buffer
    dest.first = src.first
    dest.len = src.len

proc len*(s: SharedString): int = s.len

proc `[]`*(s: SharedString; i: Natural): char =
  if i < s.len: result = s.buffer.data[i+s.first]
  else: raise newException(IndexDefect, formatErrorIndexBound(i, s.len-1))

proc `[]=`*(s: var SharedString; i: Natural; value: char) =
  if i < s.len: s.buffer.data[i+s.first] = value
  else: raise newException(IndexDefect, formatErrorIndexBound(i, s.len-1))

proc `[]`*(s: SharedString; ab: HSlice[int, int]): SharedString =
  #incRef(src.buffer)
  if ab.a < s.len:
    result.buffer = s.buffer
    result.first = ab.a
    result.len = min(s.len, ab.b - ab.a + 1)
  # else: produce empty string ;-)

proc newBuffer(cap, len: int): Buffer =
  assert cap >= len
  result = cast[Buffer](allocShared0(sizeof(int)*3 + cap))
  result.refcount = 0
  result.capacity = cap
  result.realLen = len

proc newSharedString*(len: Natural): SharedString =
  if len != 0:
    # optimization: Don't have an underlying buffer when 'len == 0'
    result.buffer = newBuffer(len, len)
  result.first = 0
  result.len = len

proc newSharedString*(s: string): SharedString =
  let len = s.len
  if len != 0:
    # optimization: Don't have an underlying buffer when 'len == 0'
    result.buffer = newBuffer(len, len)
    copyMem(addr result.buffer.data[0], cstring(s), s.len)
  result.first = 0
  result.len = len

when declared(atomicLoadN):
  template load(x): untyped = atomicLoadN(addr x, ATOMIC_SEQ_CST)
else:
  # XXX Fixme
  template load(x): untyped = x

proc add*(s: var SharedString; t: cstring; len: Natural) =
  if len == 0: return
  let newLen = s.len + len
  if s.buffer.isNil:
    s.buffer = newBuffer(len, len)
    copyMem(addr s.buffer.data[0], t, len)
    s.len = len
  elif newLen >= s.buffer.capacity or s.first != 0 or
      s.len != s.buffer.realLen or load(s.buffer.refcount) > 1:
    let oldBuf = s.buffer
    s.buffer = newBuffer(max(s.buffer.capacity * 3 div 2, newLen), newLen)
    copyMem(addr s.buffer.data[0], addr oldBuf.data[s.first], s.len)
    copyMem(addr s.buffer.data[s.len], t, len)
    decRef(oldBuf)
  else:
    copyMem(addr s.buffer.data[s.len], t, len)
    s.buffer.realLen += len
    s.len += len

proc add*(s: var SharedString; t: string) =
  s.add(t.cstring, t.len)

proc rawData*(s: var SharedString): pointer =
  if s.buffer.isNil: result = nil
  else: result = addr s.buffer.data[s.first]

proc add*(s: var SharedString; t: SharedString) =
  if t.buffer.isNil: return
  s.add(cast[cstring](addr s.buffer.data[s.first]), t.len)

proc `$`*(s: SharedString): string =
  result = newString(s.len)
  if s.len > 0:
    copyMem(addr result[0], addr s.buffer.data[s.first], s.len)

proc `==`*(s: SharedString; t: string): bool =
  if s.buffer.isNil: result = t.len == 0
  else: result = t.len == s.len and equalMem(addr s.buffer.data[s.first],
                                             cstring(t), t.len)

proc `==`*(s, t: SharedString): bool =
  if s.buffer.isNil: result = t.len == 0
  else: result = t.len == s.len and equalMem(addr s.buffer.data[s.first],
                                             addr t.buffer.data[t.first], t.len)

iterator items*(s: SharedString): char =
  let buf = s.buffer.data
  let x = s.first
  if buf != nil:
    for i in 0..<s.len:
      yield buf[i+x]

import hashes

proc hash*(s: SharedString): THash =
  var h: THash = 0
  for x in s: h = h !& x.hash
  result = !$h
