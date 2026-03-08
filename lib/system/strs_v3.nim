#
#
#            Nim's Runtime Library
#        (c) Copyright 2026 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Small String Optimization (SSO) implementation used by Nim's core.

const
  AlwaysAvail = 7
  PayloadSize = AlwaysAvail + sizeof(pointer) - 1  # -1 reserves the last byte for '\0'

when false:
  proc atomicAddFetch(p: var int; v: int): int {.importc: "__sync_add_and_fetch", nodecl.}
  proc atomicSubFetch(p: var int; v: int): int {.importc: "__sync_sub_and_fetch", nodecl.}
else:
  proc atomicAddFetch(p: var int; v: int): int {.inline.} =
    result = p + v
    p = result
  proc atomicSubFetch(p: var int; v: int): int {.inline.} =
    result = p - v
    p = result

type
  LongString {.core.} = object
    rc: int       # atomic reference count; 1 = unique owner
    fullLen: int
    capImpl: int  # bit 0: heap-allocated; upper bits: capacity (cap = capImpl shr 1)
    data: UncheckedArray[char]

  SmallString {.core.} = object
    slen: byte   # when > PayloadSize, `more` is valid ptr
    payload: array[AlwaysAvail, char]
    more: ptr LongString  # when long: pointer; when small (len 8..15): bytes 7..14 stored here

proc resize(old: int): int {.inline.} =
  ## Capacity growth factor shared with seqs_v2.nim.
  if old <= 0: result = 4
  elif old <= high(int16): result = old * 2
  else: result = old div 2 + old

# No Nim lifecycle hooks: the compiler calls the compilerRtl procs directly
# for tyString variables (nimDestroyStrV1, nimAsgnStrV2).

proc nimDestroyStrV1(s: SmallString) {.compilerRtl, inline.} =
  if int(s.slen) > PayloadSize and (s.more.capImpl and 1) == 1:
    if atomicSubFetch(s.more.rc, 1) == 0:
      dealloc(s.more)

proc ensureUniqueLong(s: var SmallString; oldLen, newLen: int) =
  # Ensure s.more is a unique (rc=1) heap block with capacity >= newLen, preserving existing data.
  # s must already be a long string on entry.
  let heapAlloc = (s.more.capImpl and 1) == 1
  let unique = heapAlloc and s.more.rc == 1
  let cap = s.more.capImpl shr 1
  if unique and newLen <= cap:
    s.more.fullLen = newLen
  else:
    let newCap = max(newLen, resize(cap))
    let p = cast[ptr LongString](alloc(sizeof(int) * 3 + newCap + 1))
    p.rc = 1
    p.fullLen = newLen
    p.capImpl = (newCap shl 1) or 1
    let old = s.more
    copyMem(addr p.data[0], addr old.data[0], oldLen + 1)  # +1 preserves the '\0'
    if heapAlloc and atomicSubFetch(old.rc, 1) == 0:
      dealloc(old)
    s.more = p

proc len(s: SmallString): int {.inline.} =
  result = int s.slen
  if result > PayloadSize:
    result = s.more.fullLen

template guts(s: SmallString): (int, ptr UncheckedArray[char]) =
  let slen = int s.slen
  if slen > PayloadSize:
    (s.more.fullLen, cast[ptr UncheckedArray[char]](addr s.more.data[0]))
  else:
    (slen, cast[ptr UncheckedArray[char]](addr s.payload[0]))

proc nimStrAtV3*(s: var SmallString; i: int): char {.compilerproc, inline.} =
  let slen = int s.slen
  if slen <= PayloadSize:
    # unchecked: when i >= 7 we store into the `more` overlay
    result = (cast[ptr UncheckedArray[char]](addr s.payload[0]))[i]
  elif i < AlwaysAvail:
    result = s.payload[i]  # hot prefix: no heap dereference for the first 7 bytes
  else:
    result = s.more.data[i]

proc nimStrPutV3*(s: var SmallString; i: int; c: char) {.compilerproc, inline.} =
  let slen = int s.slen
  if slen <= PayloadSize:
    # unchecked: when i >= 7 we store into the `more` overlay
    (cast[ptr UncheckedArray[char]](addr s.payload[0]))[i] = c
  else:
    let l = s.more.fullLen
    ensureUniqueLong(s, l, l)  # COW if shared; length unchanged
    s.more.data[i] = c
    if i < AlwaysAvail:
      s.payload[i] = c

proc cmpInlineBytes(a, b: ptr UncheckedArray[char]; n: int): int {.inline.} =
  for i in 0..<n:
    let ac = a[i]
    let bc = b[i]
    if ac < bc: return -1
    if ac > bc: return 1

proc cmp(a, b: SmallString): int {.inline.} =
  let aslen = int(a.slen)
  let bslen = int(b.slen)
  let aInl = cast[ptr UncheckedArray[char]](unsafeAddr a.payload[0])
  let bInl = cast[ptr UncheckedArray[char]](unsafeAddr b.payload[0])
  if aslen <= PayloadSize and bslen <= PayloadSize:
    # Both inline/medium: all data lives in the flat payload+more overlay,
    # no heap access. Split at AlwaysAvail lets GCC fully unroll both sub-loops.
    let minLen = min(aslen, bslen)
    let pfxLen = min(minLen, AlwaysAvail)
    result = cmpInlineBytes(aInl, bInl, pfxLen)
    if result != 0: return
    if minLen > AlwaysAvail:
      result = cmpInlineBytes(
        cast[ptr UncheckedArray[char]](addr aInl[AlwaysAvail]),
        cast[ptr UncheckedArray[char]](addr bInl[AlwaysAvail]),
        minLen - AlwaysAvail)
    if result == 0: result = aslen - bslen
    return
  # At least one is long: use hot prefix for the first AlwaysAvail bytes.
  let pfxLen = min(min(aslen, bslen), AlwaysAvail)
  result = cmpInlineBytes(aInl, bInl, pfxLen)
  if result != 0: return
  let la = if aslen > PayloadSize: a.more.fullLen else: aslen
  let lb = if bslen > PayloadSize: b.more.fullLen else: bslen
  let minLen = min(la, lb)
  if minLen <= AlwaysAvail:
    return la - lb
  let ap =
    if aslen > PayloadSize:
      cast[ptr UncheckedArray[char]](addr a.more.data[0])
    else:
      aInl
  let bp =
    if bslen > PayloadSize:
      cast[ptr UncheckedArray[char]](addr b.more.data[0])
    else:
      bInl
  result = cmpMem(addr ap[AlwaysAvail], addr bp[AlwaysAvail], minLen - AlwaysAvail)
  if result == 0:
    result = la - lb

proc `==`(a, b: SmallString): bool {.inline.} =
  if a.slen != b.slen: return false
  let slen = int(a.slen)
  let pfxLen = min(slen, AlwaysAvail)
  if cmpMem(unsafeAddr a.payload[0], unsafeAddr b.payload[0], pfxLen) != 0: return false
  if slen <= AlwaysAvail: return true
  if slen <= PayloadSize:
    # medium: compare the tail stored in the `more` overlay
    let (la, pa) = a.guts
    let (_, pb) = b.guts
    return cmpMem(addr pa[pfxLen], addr pb[pfxLen], la - pfxLen) == 0
  # long: prefix matched; check lengths then compare the heap tail
  let la = a.more.fullLen
  if la != b.more.fullLen: return false
  cmpMem(addr a.more.data[pfxLen], addr b.more.data[pfxLen], la - pfxLen) == 0

proc `<=`(a, b: SmallString): bool {.inline.} = cmp(a, b) <= 0

proc continuesWith*(s, sub: SmallString; start: int): bool =
  if start < 0: return false
  let subslen = int(sub.slen)
  if subslen == 0: return true
  # Compare via hot prefix first where possible (no heap dereference).
  let pfxLen = min(subslen, max(0, AlwaysAvail - start))
  if pfxLen > 0:
    if cmpMem(unsafeAddr s.payload[start], unsafeAddr sub.payload[0], pfxLen) != 0:
      return false
  # Fetch actual lengths and compare the remaining tail via heap/guts.
  let subLen = if subslen > PayloadSize: sub.more.fullLen else: subslen
  let sLen = if int(s.slen) > PayloadSize: s.more.fullLen else: int(s.slen)
  if start + subLen > sLen: return false
  if pfxLen == subLen: return true
  let (_, sp) = s.guts
  let (_, subp) = sub.guts
  cmpMem(addr sp[start + pfxLen], addr subp[pfxLen], subLen - pfxLen) == 0

proc startsWith*(s, sub: SmallString): bool {.inline.} = continuesWith(s, sub, 0)
proc endsWith*(s, sub: SmallString): bool {.inline.} = continuesWith(s, sub, s.len - sub.len)


proc add(s: var SmallString; c: char) =
  let slen = int(s.slen)
  if slen <= PayloadSize:
    let newLen = slen + 1
    if newLen <= PayloadSize:
      let inl = cast[ptr UncheckedArray[char]](addr s.payload[0])
      inl[slen] = c
      inl[newLen] = '\0'
      s.slen = byte(newLen)
    else:
      # transition from medium (slen == PayloadSize) to long
      let cap = newLen * 2
      let p = cast[ptr LongString](alloc(sizeof(int) * 3 + cap + 1))
      p.rc = 1
      p.fullLen = newLen
      p.capImpl = (cap shl 1) or 1
      copyMem(addr p.data[0], cast[ptr UncheckedArray[char]](addr s.payload[0]), slen)
      p.data[slen] = c
      p.data[newLen] = '\0'
      s.more = p
      s.slen = byte(PayloadSize + 1)
  else:
    let l = s.more.fullLen  # fetch fullLen only in the long path
    ensureUniqueLong(s, l, l + 1)
    s.more.data[l] = c
    s.more.data[l + 1] = '\0'
    if l < AlwaysAvail:
      s.payload[l] = c

proc add(s: var SmallString; t: SmallString) =
  let slen = int(s.slen)
  let (tl, tp) = t.guts  # fetch t's guts before any mutation (aliasing safety)
  if tl == 0: return
  if slen <= PayloadSize:
    let sl = slen  # for short/medium, slen IS the actual length
    let newLen = sl + tl
    if newLen <= PayloadSize:
      let inl = cast[ptr UncheckedArray[char]](addr s.payload[0])
      copyMem(addr inl[sl], tp, tl)
      inl[newLen] = '\0'
      s.slen = byte(newLen)
    else:
      # transition to long
      let cap = newLen * 2
      let p = cast[ptr LongString](alloc(sizeof(int) * 3 + cap + 1))
      p.rc = 1
      p.fullLen = newLen
      p.capImpl = (cap shl 1) or 1
      copyMem(addr p.data[0], cast[ptr UncheckedArray[char]](addr s.payload[0]), sl)
      copyMem(addr p.data[sl], tp, tl)
      p.data[newLen] = '\0'
      if sl < AlwaysAvail:
        copyMem(addr s.payload[sl], tp, min(AlwaysAvail - sl, tl))
      s.more = p
      s.slen = byte(PayloadSize + 1)
  else:
    let sl = s.more.fullLen  # fetch fullLen only in the long path
    let newLen = sl + tl
    # tp was read before ensureUniqueLong: if t.more == s.more, rc decrements but won't hit 0
    ensureUniqueLong(s, sl, newLen)
    copyMem(addr s.more.data[sl], tp, tl)
    s.more.data[newLen] = '\0'
    if sl < AlwaysAvail:
      copyMem(addr s.payload[sl], tp, min(AlwaysAvail - sl, tl))

{.push overflowChecks: off, rangeChecks: off.}

proc prepareAddLong(s: var SmallString; newLen: int) =
  # Reserve capacity for newLen in the long-string block without changing logical length.
  let heapAlloc = (s.more.capImpl and 1) == 1
  let cap = s.more.capImpl shr 1
  if heapAlloc and s.more.rc == 1 and newLen <= cap:
    discard  # already unique with sufficient capacity
  else:
    let oldLen = s.more.fullLen
    let newCap = max(newLen, resize(cap))
    let p = cast[ptr LongString](alloc(sizeof(int) * 3 + newCap + 1))
    p.rc = 1
    p.fullLen = oldLen  # logical length unchanged — caller sets it after writing data
    p.capImpl = (newCap shl 1) or 1
    let old = s.more
    copyMem(addr p.data[0], addr old.data[0], oldLen + 1)
    if heapAlloc and atomicSubFetch(old.rc, 1) == 0:
      dealloc(old)
    s.more = p

proc prepareAdd(s: var SmallString; addLen: int) {.compilerRtl.} =
  ## Ensure s has room for addLen more characters without changing its length.
  let slen = int(s.slen)
  let curLen = if slen > PayloadSize: s.more.fullLen else: slen
  let newLen = curLen + addLen
  if slen <= PayloadSize:
    if newLen > PayloadSize:
      # transition to long: allocate, copy existing data
      let newCap = newLen * 2
      let p = cast[ptr LongString](alloc(sizeof(int) * 3 + newCap + 1))
      p.rc = 1
      p.fullLen = curLen
      p.capImpl = (newCap shl 1) or 1
      let inl = cast[ptr UncheckedArray[char]](addr s.payload[0])
      copyMem(addr p.data[0], inl, curLen + 1)
      s.more = p
      s.slen = byte(PayloadSize + 1)
    # else: short/medium — inline capacity always sufficient (struct is fixed size)
  else:
    prepareAddLong(s, newLen)

proc nimAddCharV1(s: var SmallString; c: char) {.compilerRtl, inline.} =
  let slen = int(s.slen)
  if slen < PayloadSize:
    # Hot path: inline/medium with room (slen+1 <= PayloadSize, no heap needed)
    let inl = cast[ptr UncheckedArray[char]](addr s.payload[0])
    inl[slen] = c
    inl[slen + 1] = '\0'
    s.slen = byte(slen + 1)
  elif slen > PayloadSize:
    # Long string — inline the common case: unique heap block with room
    let l = s.more.fullLen
    if (s.more.capImpl and 1) == 1 and s.more.rc == 1 and l < (s.more.capImpl shr 1):
      s.more.data[l] = c
      s.more.data[l + 1] = '\0'
      s.more.fullLen = l + 1
      if l < AlwaysAvail:
        s.payload[l] = c
    else:
      prepareAdd(s, 1)
      s.add(c)
  else:
    # slen == PayloadSize: medium→long transition (rare)
    prepareAdd(s, 1)
    s.add(c)

proc toNimStr(str: cstring; len: int): SmallString {.compilerproc.} =
  if len <= 0: return
  if len <= PayloadSize:
    result.slen = byte(len)
    let inl = cast[ptr UncheckedArray[char]](addr result.payload[0])
    copyMem(inl, str, len)
    inl[len] = '\0'
  else:
    let p = cast[ptr LongString](alloc(sizeof(int) * 3 + len + 1))
    p.rc = 1
    p.fullLen = len
    p.capImpl = (len shl 1) or 1
    copyMem(addr p.data[0], str, len)
    p.data[len] = '\0'
    copyMem(addr result.payload[0], str, AlwaysAvail)
    result.slen = byte(PayloadSize + 1)
    result.more = p

proc cstrToNimstr(str: cstring): SmallString {.compilerRtl.} =
  if str == nil: return
  toNimStr(str, str.len)

proc nimToCStringConv(s: var SmallString): cstring {.compilerproc, nonReloadable, inline.} =
  ## Returns a null-terminated C string pointer into s's data.
  ## Takes by var (pointer) so addr s.payload[0] is always into the caller's SmallString.
  if int(s.slen) > PayloadSize:
    cast[cstring](addr s.more.data[0])
  else:
    cast[cstring](addr s.payload[0])

proc appendString(dest: var SmallString; src: SmallString) {.compilerproc, inline.} =
  dest.add(src)

proc appendChar(dest: var SmallString; c: char) {.compilerproc, inline.} =
  dest.add(c)

proc rawNewString(space: int): SmallString {.compilerproc.} =
  ## Returns an empty SmallString with capacity reserved for `space` chars (newStringOfCap).
  if space <= 0: return
  if space <= PayloadSize:
    discard  # inline capacity is always available; nothing to pre-allocate
  else:
    let p = cast[ptr LongString](alloc(sizeof(int) * 3 + space + 1))
    p.rc = 1
    p.fullLen = 0
    p.capImpl = (space shl 1) or 1
    p.data[0] = '\0'
    result.more = p
    result.slen = byte(PayloadSize + 1)

proc mnewString(len: int): SmallString {.compilerproc.} =
  ## Returns a SmallString of `len` zero characters (newString).
  if len <= 0: return
  if len <= PayloadSize:
    result.slen = byte(len)
    # payload is zero-initialized by default (result is zero)
    cast[ptr UncheckedArray[char]](addr result.payload[0])[len] = '\0'
  else:
    let p = cast[ptr LongString](alloc0(sizeof(int) * 3 + len + 1))
    p.rc = 1
    p.fullLen = len
    p.capImpl = (len shl 1) or 1
    # data is zeroed by alloc0; data[len] is '\0' too
    result.more = p
    result.slen = byte(PayloadSize + 1)

proc setLengthStrV2(s: var SmallString; newLen: int) {.compilerRtl.} =
  ## Sets the length of s to newLen, zeroing new bytes on growth.
  let slen = int(s.slen)
  let curLen = if slen > PayloadSize: s.more.fullLen else: slen
  if newLen == curLen: return
  if newLen <= 0:
    if slen > PayloadSize:
      if (s.more.capImpl and 1) == 1 and s.more.rc == 1:
        s.more.fullLen = 0
        s.more.data[0] = '\0'
      else:
        # shared block: detach and go back to empty inline
        nimDestroyStrV1(s)
        s.slen = 0
    else:
      s.slen = 0
      s.payload[0] = '\0'
    return
  if slen <= PayloadSize:
    if newLen <= PayloadSize:
      if newLen > curLen:
        let inl = cast[ptr UncheckedArray[char]](addr s.payload[0])
        zeroMem(addr inl[curLen], newLen - curLen)
        inl[newLen] = '\0'
      else:
        cast[ptr UncheckedArray[char]](addr s.payload[0])[newLen] = '\0'
      s.slen = byte(newLen)
    else:
      # grow into long
      let newCap = resize(newLen)
      let p = cast[ptr LongString](alloc0(sizeof(int) * 3 + newCap + 1))
      p.rc = 1
      p.fullLen = newLen
      p.capImpl = (newCap shl 1) or 1
      copyMem(addr p.data[0], cast[ptr UncheckedArray[char]](addr s.payload[0]), curLen)
      # bytes [curLen..newLen] zeroed by alloc0; p.data[newLen] = '\0' by alloc0
      s.more = p
      s.slen = byte(PayloadSize + 1)
  else:
    # currently long
    if newLen <= PayloadSize:
      # shrink back to inline
      let old = s.more
      let heapAlloc = (old.capImpl and 1) == 1
      let inl = cast[ptr UncheckedArray[char]](addr s.payload[0])
      copyMem(inl, addr old.data[0], newLen)
      inl[newLen] = '\0'
      if heapAlloc and atomicSubFetch(old.rc, 1) == 0:
        dealloc(old)
      s.slen = byte(newLen)
    else:
      ensureUniqueLong(s, curLen, newLen)
      if newLen > curLen:
        zeroMem(addr s.more.data[curLen], newLen - curLen)
      s.more.data[newLen] = '\0'
      s.more.fullLen = newLen

proc nimAsgnStrV2(a: var SmallString; b: SmallString) {.compilerRtl, inline.} =
  if int(b.slen) <= PayloadSize:
    nimDestroyStrV1(a)
    copyMem(addr a, unsafeAddr b, sizeof(SmallString))
  else:
    if addr(a) == unsafeAddr(b): return
    nimDestroyStrV1(a)
    # COW: share the block, bump refcount — no allocation needed
    if (b.more.capImpl and 1) == 1:
      discard atomicAddFetch(b.more.rc, 1)
    copyMem(addr a, unsafeAddr b, sizeof(SmallString))

proc nimPrepareStrMutationImpl(s: var SmallString) =
  # Called when s holds a static (non-heap) LongString block. COW: allocate a fresh copy.
  let old = s.more
  let oldLen = old.fullLen
  let p = cast[ptr LongString](alloc(sizeof(int) * 3 + oldLen + 1))
  p.rc = 1
  p.fullLen = oldLen
  p.capImpl = (oldLen shl 1) or 1
  copyMem(addr p.data[0], addr old.data[0], oldLen + 1)
  s.more = p

proc nimPrepareStrMutationV2(s: var SmallString) {.compilerRtl, inline.} =
  if int(s.slen) > PayloadSize and (s.more.capImpl and 1) == 0:
    nimPrepareStrMutationImpl(s)

proc prepareMutation*(s: var string) {.inline.} =
  {.cast(noSideEffect).}:
    nimPrepareStrMutationV2(cast[ptr SmallString](addr s)[])

proc nimStrAtMutV3*(s: var SmallString; i: int): var char {.compilerproc, inline.} =
  ## Returns a mutable reference to the i-th char. Handles COW for long strings.
  ## Used by the codegen when s[i] is passed as a `var char` argument.
  if int(s.slen) > PayloadSize:
    nimPrepareStrMutationV2(s)  # COW: ensure unique heap block before exposing ref
    result = s.more.data[i]
  else:
    result = (cast[ptr UncheckedArray[char]](addr s.payload[0]))[i]

proc nimAddStrV1(s: var SmallString; src: SmallString) {.compilerRtl, inline.} =
  s.add(src)

func capacity*(self: SmallString): int {.inline.} =
  ## Returns the current capacity of the string.
  let slen = int(self.slen)
  if slen > PayloadSize:
    self.more.capImpl shr 1
  else:
    PayloadSize

proc nimStrLen(s: SmallString): int {.compilerproc, inline.} =
  ## Returns the length of s. Called by the codegen for `mLen` on strings with -d:nimsso.
  s.len

proc nimStrData(s: var SmallString): ptr UncheckedArray[char] {.compilerproc, inline.} =
  ## Returns a pointer to the char data of s. Called by codegen for subscript and slice with -d:nimsso.
  let slen = int(s.slen)
  if slen > PayloadSize: cast[ptr UncheckedArray[char]](addr s.more.data[0])
  else: cast[ptr UncheckedArray[char]](addr s.payload[0])

const
  newStringUninitWasDeclared = true

proc newStringUninitImpl(len: Natural): string {.noSideEffect, inline.} =
  ## Returns a new string of length `len` but with uninitialized content.
  ## One needs to fill the string character after character
  ## with the index operator `s[i]`.
  ##
  ## This procedure exists only for optimization purposes;
  ## the same effect can be achieved with the `&` operator or with `add`.
  when nimvm:
    result = newString(len)
  else:
    result = newStringOfCap(len)  # rawNewString: alloc (not alloc0) for long strings
    {.cast(noSideEffect).}:
      if len > 0:
        let s = cast[ptr SmallString](addr result)
        if len <= PayloadSize:
          s.slen = byte(len)
          # Null-terminate; bytes [0..len-1] left uninitialized for caller to fill.
          cast[ptr UncheckedArray[char]](addr s.payload[0])[len] = '\0'
        else:
          # rawNewString allocated with alloc (not alloc0), so data[0..len-1] is
          # intentionally uninitialized. Caller fills it and calls completeStore.
          s.more.fullLen = len
          s.more.data[len] = '\0'

proc completeStore(s: var SmallString) {.compilerproc, inline.} =
  ## Must be called after bulk data has been written directly into the string buffer
  ## via a raw pointer obtained from `nimStrData`/`nimStrAtMutV3` (e.g. `readBuffer`,
  ## `moveMem`, `copyMem`).
  ##
  ## Syncs the hot prefix cache: copies `more.data[0..AlwaysAvail-1]` into
  ## `payload[0..AlwaysAvail-1]` so that `cmp`/`==` can compare long strings
  ## without a heap dereference for the first few bytes.
  if int(s.slen) > PayloadSize:
    copyMem(addr s.payload[0], addr s.more.data[0], AlwaysAvail)

proc completeStore*(s: var string) {.inline.} =
  completeStore(cast[ptr SmallString](addr s)[])

# These take `string` (tyString) so the codegen uses them directly, bypassing
# strmantle.nim's versions which go through nimStrLen/nimStrAtMutV3 compilerproc calls.
proc cmpStrings(a, b: string): int {.compilerproc, inline.} =
  cmp(cast[ptr SmallString](unsafeAddr a)[], cast[ptr SmallString](unsafeAddr b)[])

proc eqStrings(a, b: string): bool {.compilerproc, inline.} =
  cast[ptr SmallString](unsafeAddr a)[] == cast[ptr SmallString](unsafeAddr b)[]

proc leStrings(a, b: string): bool {.compilerproc, inline.} =
  cmpStrings(a, b) <= 0

proc ltStrings(a, b: string): bool {.compilerproc, inline.} =
  cmpStrings(a, b) < 0

proc hashString(s: string): int {.compilerproc.} =
  let ss = cast[ptr SmallString](unsafeAddr s)[]
  let (L, data) = ss.guts
  var h = 0'u
  for i in 0..<L:
    h = h + uint(data[i])
    h = h + h shl 10
    h = h xor (h shr 6)
  h = h + h shl 3
  h = h xor (h shr 11)
  h = h + h shl 15
  result = cast[int](h)

{.pop.}
