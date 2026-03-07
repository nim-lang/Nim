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

proc atomicAddFetch(p: var int; v: int): int {.importc: "__sync_add_and_fetch", nodecl.}
proc atomicSubFetch(p: var int; v: int): int {.importc: "__sync_sub_and_fetch", nodecl.}

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
    result = s.payload[i]
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

proc cmp(a, b: SmallString): int =
  # Use slen directly for prefix length: for short/medium it is the real length,
  # for long it is the sentinel (> AlwaysAvail), so min(..., AlwaysAvail) still gives 7.
  # This avoids dereferencing `more` before the prefix comparison.
  let pfxLen = min(min(int a.slen, int b.slen), AlwaysAvail)
  result = cmpMem(unsafeAddr a.payload[0], unsafeAddr b.payload[0], pfxLen)
  if result != 0: return
  # Prefix matched — now fetch actual lengths (dereferences `more` only if long)
  let la = if int(a.slen) > PayloadSize: a.more.fullLen else: int(a.slen)
  let lb = if int(b.slen) > PayloadSize: b.more.fullLen else: int(b.slen)
  let minLen = min(la, lb)
  if minLen <= AlwaysAvail:
    result = la - lb
    return
  let (_, pa) = a.guts
  let (_, pb) = b.guts
  result = cmpMem(addr pa[AlwaysAvail], addr pb[AlwaysAvail], minLen - AlwaysAvail)
  if result == 0:
    result = la - lb

proc `==`(a, b: SmallString): bool =
  if a.slen != b.slen: return false
  # slen equal: for short/medium this means equal lengths; for long (both sentinel) we still need fullLen.
  let slen = int(a.slen)
  let pfxLen = min(slen, AlwaysAvail)
  if cmpMem(unsafeAddr a.payload[0], unsafeAddr b.payload[0], pfxLen) != 0: return false
  if slen <= AlwaysAvail: return true
  if slen <= PayloadSize:
    # medium: guts gives the UncheckedArray without a heap dereference
    let (la, pa) = a.guts
    let (_, pb) = b.guts
    return cmpMem(addr pa[pfxLen], addr pb[pfxLen], la - pfxLen) == 0
  # long: fetch actual lengths only after prefix matched
  let la = a.more.fullLen
  if la != b.more.fullLen: return false
  cmpMem(addr a.more.data[pfxLen], addr b.more.data[pfxLen], la - pfxLen) == 0

proc `<=`(a, b: SmallString): bool {.inline.} = cmp(a, b) <= 0

proc continuesWith*(s, sub: SmallString; start: int): bool =
  if start < 0: return false
  let subslen = int(sub.slen)
  if subslen == 0: return true
  # Compare inline prefix first — no `more` dereference yet.
  # For long sub, subslen is the sentinel (> AlwaysAvail), so pfxLen is capped correctly.
  let pfxLen = min(subslen, max(0, AlwaysAvail - start))
  if pfxLen > 0:
    if cmpMem(unsafeAddr s.payload[start], unsafeAddr sub.payload[0], pfxLen) != 0:
      return false
  # Prefix matched (or start >= AlwaysAvail); now fetch actual lengths
  let subLen = if subslen > PayloadSize: sub.more.fullLen else: subslen
  let sLen = if int(s.slen) > PayloadSize: s.more.fullLen else: int(s.slen)
  if start + subLen > sLen: return false
  if pfxLen == subLen: return true  # sub fully compared within the prefix
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
      # payload[0..AlwaysAvail-1] already correct; slen >= AlwaysAvail so no update needed
      s.more = p
      s.slen = byte(PayloadSize + 1)
  else:
    let l = s.more.fullLen  # fetch fullLen only in the long path
    ensureUniqueLong(s, l, l + 1)
    s.more.data[l] = c
    s.more.data[l + 1] = '\0'
    # l >= PayloadSize > AlwaysAvail, so prefix is unaffected

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
      # update prefix bytes that come from t (only when sl < AlwaysAvail)
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
    # sl >= PayloadSize > AlwaysAvail, so prefix is unaffected

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

proc nimAsgnStrV2(a: var SmallString; b: SmallString) {.compilerRtl.} =
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

proc eqStrings(a, b: SmallString): bool {.compilerproc, inline.} = a == b

proc cmpStrings(a, b: SmallString): int {.compilerproc, inline.} = cmp(a, b)

{.pop.}
