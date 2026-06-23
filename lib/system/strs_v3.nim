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
  AlwaysAvail = sizeof(uint) - 1  # inline chars that fit in the `bytes` field alongside slen
  PayloadSize = AlwaysAvail + sizeof(pointer) - 1  # -1 reserves the last byte for '\0'
  HeapSlen   = 255  # slen sentinel: heap-allocated long string; capImpl = raw capacity
  StaticSlen = 254  # slen sentinel: static/literal long string; capImpl = 0, never freed
  LongStringDataOffset = 3 * sizeof(int)  # byte offset of LongString.data from struct start

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
    fullLen: int
    rc: int       # atomic reference count; 1 = unique owner
    capImpl: int  # raw capacity; 0 for static literals (never freed, slen = StaticSlen)
    data: UncheckedArray[char]

  SmallString {.core.} = object
    bytes: uint
      ## Layout (little-endian): byte 0 = slen; bytes 1..AlwaysAvail = inline chars 0..AlwaysAvail-1.
      ## Bytes after the null terminator are zero (SWAR invariant).
      ## When slen == HeapSlen (255), `more` is a heap-owned LongString block.
      ## When slen == StaticSlen (254), `more` points to a static LongString literal.
      ## When AlwaysAvail < slen <= PayloadSize, `more` holds raw char bytes AlwaysAvail..PayloadSize-1 (medium string).
    more: ptr LongString

when sizeof(uint) == 8:
  proc bswap(x: uint): uint {.importc: "__builtin_bswap64", nodecl, noSideEffect.}
  proc ctzImpl(x: uint): int {.inline.} =
    proc ctz64(x: uint64): int32 {.importc: "__builtin_ctzll", nodecl, noSideEffect.}
    int(ctz64(uint64(x)))
else:
  proc bswap(x: uint): uint {.importc: "__builtin_bswap32", nodecl, noSideEffect.}
  proc ctzImpl(x: uint): int {.inline.} =
    proc ctz32(x: uint32): int32 {.importc: "__builtin_ctz", nodecl, noSideEffect.}
    int(ctz32(uint32(x)))

proc swarKey(x: uint): uint {.inline.} =
  ## Returns a value where inline char[0] is in the most significant byte,
  ## so that integer comparison gives lexicographic string order.
  ## LE: slen in bits 0-7; `bswap(x shr 8)` puts char[0] in MSB.
  ## BE: slen in bits (sizeof(uint)-1)*8..(sizeof(uint)*8-1) (MSB); `x shl 8` shifts slen out, char[0] lands in MSB.
  when system.cpuEndian == littleEndian:
    bswap(x shr 8)
  else:
    x shl 8

# ---- accessors ----
# Memory layout is identical on both endiannesses: byte 0 = slen, bytes 1..AlwaysAvail = inline chars.
# But the integer value of `bytes` differs: on LE slen is in the LSB, on BE in the MSB.

template ssLenOf(bytes: uint): int =
  ## Extract slen from an already-loaded `bytes` word. Zero-cost (register op only).
  ## Use when `bytes` is already in a register (e.g. loaded for SWAR comparison).
  when system.cpuEndian == littleEndian:
    int(bytes and 0xFF'u)
  else:
    int(bytes shr (8 * (sizeof(uint) - 1)))

proc cmpShortInline(abytes, bbytes: uint; aslen, bslen: int): int {.inline.} =
  let minLen = min(aslen, bslen)
  if minLen > 0:
    when system.cpuEndian == littleEndian:
      let diffMask = (1'u shl (minLen * 8)) - 1'u
      let diff = ((abytes xor bbytes) shr 8) and diffMask
      if diff != 0:
        let byteShift = (ctzImpl(diff) shr 3) * 8 + 8
        let ac = (abytes shr byteShift) and 0xFF'u
        let bc = (bbytes shr byteShift) and 0xFF'u
        if ac < bc: return -1
        return 1
    else:
      let aw = swarKey(abytes)
      let bw = swarKey(bbytes)
      if aw < bw: return -1
      if aw > bw: return 1
  aslen - bslen

template ssLen(s: SmallString): int =
  ## Load slen via a direct byte access at offset 0 (valid on both LE and BE).
  ## A byte load (movzx) lets the C compiler prove that slen is at offset 0,
  ## distinct from inline char writes at offsets 1+, enabling register-caching
  ## of slen across char-write loops (e.g. nimAddCharV1).
  int(cast[ptr byte](unsafeAddr s.bytes)[])

template setSSLen(s: var SmallString; v: int) =
  # Single byte store — equivalent to old `s.slen = byte(v)`.
  # Accessing a uint via byte* is legal in C (char-pointer aliasing exemption).
  cast[ptr byte](addr s.bytes)[] = cast[byte](v)

# Pointer to inline chars (offset +1 from `bytes` field / start of struct).
# Only valid when s is in memory (var/ptr); forces a load from memory.
template inlinePtr(s: SmallString): ptr UncheckedArray[char] =
  cast[ptr UncheckedArray[char]](cast[uint](unsafeAddr s.bytes) + 1'u)

# Same but from a ptr SmallString (avoids unsafeAddr dance).
template inlinePtrOf(p: ptr SmallString): ptr UncheckedArray[char] =
  cast[ptr UncheckedArray[char]](cast[uint](p) + 1'u)

proc resize(old: int): int {.inline.} =
  ## Capacity growth factor shared with seqs_v2.nim.
  if old <= 0: result = 4
  elif old <= high(int16): result = old * 2
  else: result = old div 2 + old

# No Nim lifecycle hooks: the compiler calls the compilerRtl procs directly
# for tyString variables (nimDestroyStrV1, nimAsgnStrV2).

proc nimDestroyStrV1(s: SmallString) {.compilerRtl, inline.} =
  if ssLen(s) == HeapSlen:
    if atomicSubFetch(s.more.rc, 1) == 0:
      dealloc(s.more)

proc ensureUniqueLong(s: var SmallString; oldLen, newLen: int) =
  # Ensure s.more is a unique (rc=1) heap block with capacity >= newLen, preserving existing data.
  # s must already be a long string (slen >= StaticSlen) on entry.
  # After return, slen == HeapSlen (s is heap-owned).
  let isHeap = ssLen(s) == HeapSlen
  let cap = if isHeap: s.more.capImpl else: 0  # static literals have capImpl=0
  if isHeap and s.more.rc == 1 and newLen <= cap:
    s.more.fullLen = newLen
  else:
    # Only grow capacity when actually needed; pure COW copies (newLen <= cap)
    # preserve the existing capacity to avoid exponential growth via repeated COW.
    let newCap = if newLen > cap: max(newLen, resize(cap)) else: cap
    let p = cast[ptr LongString](alloc(LongStringDataOffset + newCap + 1))
    p.rc = 1
    p.fullLen = newLen
    p.capImpl = newCap
    let old = s.more
    copyMem(addr p.data[0], addr old.data[0], oldLen + 1)  # +1 preserves the '\0'
    if isHeap and atomicSubFetch(old.rc, 1) == 0:
      dealloc(old)
    s.more = p
    setSSLen(s, HeapSlen)  # mark as heap-owned (also handles static→heap promotion)

proc len(s: SmallString): int {.inline.} =
  result = ssLen(s)
  if result > PayloadSize:
    result = s.more.fullLen

template guts(s: SmallString): (int, ptr UncheckedArray[char]) =
  let slen = ssLen(s)
  if slen > PayloadSize:
    (s.more.fullLen, cast[ptr UncheckedArray[char]](addr s.more.data[0]))
  else:
    (slen, inlinePtr(s))

proc nimStrAtV3*(s: var SmallString; i: int): char {.compilerproc, inline.} =
  if ssLen(s) <= PayloadSize:
    # short/medium: data is in the inline bytes overlay
    result = inlinePtr(s)[i]
  else:
    # long: always use heap data (completeStore keeps more.data canonical)
    result = s.more.data[i]

proc nimStrPutV3*(s: var SmallString; i: int; c: char) {.compilerproc, inline.} =
  let slen = ssLen(s)
  if slen <= PayloadSize:
    # unchecked: when i >= 7 we store into the `more` overlay
    inlinePtr(s)[i] = c
    # Maintain SWAR zeroing invariant: if i < AlwaysAvail and we wrote a non-null,
    # caller is responsible. Writing '\0' here would break content. No action needed.
  else:
    let l = s.more.fullLen
    ensureUniqueLong(s, l, l)  # COW if shared; length unchanged
    s.more.data[i] = c
    if i < AlwaysAvail:
      inlinePtr(s)[i] = c

proc cmpInlineBytes(a, b: ptr UncheckedArray[char]; n: int): int {.inline.} =
  for i in 0..<n:
    let ac = a[i]
    let bc = b[i]
    if ac < bc: return -1
    if ac > bc: return 1

proc cmpStringPtrs(a, b: ptr SmallString): int {.inline.} =
  # Compare two SmallStrings by pointer to avoid struct copies in the hot path.
  let abytes = a.bytes
  let bbytes = b.bytes
  let aslen = ssLenOf(abytes)
  let bslen = ssLenOf(bbytes)
  if aslen <= AlwaysAvail and bslen <= AlwaysAvail:
    # SWAR path: both short (≤7 bytes). All data lives in the `bytes` field.
    # Zeroed-padding invariant ensures bytes past the null are 0.
    # swarKey puts char[0] in the MSB → integer comparison is lexicographic.
    let aw = swarKey(abytes)
    let bw = swarKey(bbytes)
    if aw < bw: return -1
    if aw > bw: return 1
    return aslen - bslen
  if aslen <= PayloadSize and bslen <= PayloadSize:
    # Both inline/medium: all data lives in the flat struct, no heap access needed.
    let minLen = min(aslen, bslen)
    let pfxLen = min(minLen, AlwaysAvail)
    result = cmpInlineBytes(inlinePtrOf(a), inlinePtrOf(b), pfxLen)
    if result != 0: return
    if minLen > AlwaysAvail:
      let aInl = inlinePtrOf(a)
      let bInl = inlinePtrOf(b)
      result = cmpInlineBytes(
        cast[ptr UncheckedArray[char]](addr aInl[AlwaysAvail]),
        cast[ptr UncheckedArray[char]](addr bInl[AlwaysAvail]),
        minLen - AlwaysAvail)
    if result == 0: result = aslen - bslen
    return
  # At least one is long. Hot prefix mirrors heap data, but only up to fullLen:
  # shrinking can leave stale bytes in the inline cache past the logical length.
  let la = if aslen > PayloadSize: a.more.fullLen else: aslen
  let lb = if bslen > PayloadSize: b.more.fullLen else: bslen
  let minLen = min(la, lb)
  let pfxLen = min(minLen, AlwaysAvail)
  result = cmpInlineBytes(inlinePtrOf(a), inlinePtrOf(b), pfxLen)
  if result != 0: return
  if minLen <= AlwaysAvail:
    result = la - lb
    return
  let ap = if aslen > PayloadSize: cast[ptr UncheckedArray[char]](addr a.more.data[0]) else:
    inlinePtrOf(a)
  let bp = if bslen > PayloadSize: cast[ptr UncheckedArray[char]](addr b.more.data[0]) else:
    inlinePtrOf(b)
  result = cmpMem(addr ap[AlwaysAvail], addr bp[AlwaysAvail], minLen - AlwaysAvail)
  if result == 0: result = la - lb

proc cmp(a, b: SmallString): int {.inline.} =
  # Load bytes once per string — used for both slen check and SWAR key.
  let abytes = a.bytes
  let bbytes = b.bytes
  let aslen = ssLenOf(abytes)
  let bslen = ssLenOf(bbytes)
  if aslen <= AlwaysAvail and bslen <= AlwaysAvail:
    return cmpShortInline(abytes, bbytes, aslen, bslen)
  cmpStringPtrs(unsafeAddr a, unsafeAddr b)

proc `==`(a, b: SmallString): bool {.inline.} =
  let abytes = a.bytes
  let bbytes = b.bytes
  let aslen = ssLenOf(abytes)
  let bslen = ssLenOf(bbytes)
  if aslen <= AlwaysAvail and bslen <= AlwaysAvail:
    return abytes == bbytes  # SWAR: slen equal, data in bytes word
  # Compute actual lengths (sentinels 254/255 → more.fullLen)
  let la = if aslen > PayloadSize: a.more.fullLen else: aslen
  let lb = if bslen > PayloadSize: b.more.fullLen else: bslen
  if la != lb: return false
  if la == 0: return true
  if aslen <= PayloadSize and bslen <= PayloadSize:
    # Both medium (slen == la == lb, so byte0 equal): compare prefix word + tail
    if abytes != bbytes: return false
    let (_, pa) = a.guts
    let (_, pb) = b.guts
    return cmpMem(addr pa[AlwaysAvail], addr pb[AlwaysAvail], la - AlwaysAvail) == 0
  # At least one long (heap or static): delegate to cmpStringPtrs
  cmpStringPtrs(unsafeAddr a, unsafeAddr b) == 0

proc continuesWith*(s, sub: SmallString; start: int): bool =
  if start < 0: return false
  let subslen = ssLen(sub)
  if subslen == 0: return true
  let sslen = ssLen(s)
  # Compare via hot prefix first where possible (no heap dereference).
  let pfxLen = min(subslen, max(0, AlwaysAvail - start))
  if pfxLen > 0:
    if cmpMem(cast[pointer](cast[uint](unsafeAddr s.bytes) + 1'u + uint(start)),
              cast[pointer](cast[uint](unsafeAddr sub.bytes) + 1'u), pfxLen) != 0:
      return false
  # Fetch actual lengths and compare the remaining tail via heap/guts.
  let subLen = if subslen > PayloadSize: sub.more.fullLen else: subslen
  let sLen = if sslen > PayloadSize: s.more.fullLen else: sslen
  if start + subLen > sLen: return false
  if pfxLen == subLen: return true
  let (_, sp) = s.guts
  let (_, subp) = sub.guts
  cmpMem(addr sp[start + pfxLen], addr subp[pfxLen], subLen - pfxLen) == 0

proc startsWith*(s, sub: SmallString): bool {.inline.} = continuesWith(s, sub, 0)
proc endsWith*(s, sub: SmallString): bool {.inline.} = continuesWith(s, sub, s.len - sub.len)


proc add(s: var SmallString; c: char) =
  let slen = ssLen(s)
  if slen <= PayloadSize:
    let newLen = slen + 1
    if newLen <= PayloadSize:
      let inl = inlinePtr(s)
      inl[slen] = c
      inl[newLen] = '\0'
      setSSLen(s, newLen)
    else:
      # transition from medium (slen == PayloadSize) to long
      let cap = newLen * 2
      let p = cast[ptr LongString](alloc(LongStringDataOffset + cap + 1))
      p.rc = 1
      p.fullLen = newLen
      p.capImpl = cap
      copyMem(addr p.data[0], inlinePtr(s), slen)
      p.data[slen] = c
      p.data[newLen] = '\0'
      s.more = p
      setSSLen(s, HeapSlen)
  else:
    let l = s.more.fullLen  # fetch fullLen only in the long path
    ensureUniqueLong(s, l, l + 1)
    s.more.data[l] = c
    s.more.data[l + 1] = '\0'
    if l < AlwaysAvail:
      inlinePtr(s)[l] = c

proc add(s: var SmallString; t: SmallString) =
  let slen = ssLen(s)
  let (tl, tp) = t.guts  # fetch t's guts before any mutation (aliasing safety)
  if tl == 0: return
  if slen <= PayloadSize:
    let sl = slen  # for short/medium, slen IS the actual length
    let newLen = sl + tl
    if newLen <= PayloadSize:
      let inl = inlinePtr(s)
      copyMem(addr inl[sl], tp, tl)
      inl[newLen] = '\0'
      setSSLen(s, newLen)
    else:
      # transition to long
      let cap = newLen * 2
      let p = cast[ptr LongString](alloc(LongStringDataOffset + cap + 1))
      p.rc = 1
      p.fullLen = newLen
      p.capImpl = cap
      copyMem(addr p.data[0], inlinePtr(s), sl)
      copyMem(addr p.data[sl], tp, tl)
      p.data[newLen] = '\0'
      if sl < AlwaysAvail:
        copyMem(addr inlinePtr(s)[sl], tp, min(AlwaysAvail - sl, tl))
      s.more = p
      setSSLen(s, HeapSlen)
  else:
    let sl = s.more.fullLen  # fetch fullLen only in the long path
    let newLen = sl + tl
    # tp was read before ensureUniqueLong: if t.more == s.more, rc decrements but won't hit 0
    ensureUniqueLong(s, sl, newLen)
    copyMem(addr s.more.data[sl], tp, tl)
    s.more.data[newLen] = '\0'
    if sl < AlwaysAvail:
      copyMem(addr inlinePtr(s)[sl], tp, min(AlwaysAvail - sl, tl))

{.push overflowChecks: off, rangeChecks: off.}

proc prepareAddLong(s: var SmallString; newLen: int) =
  # Reserve capacity for newLen in the long-string block without changing logical length.
  let isHeap = ssLen(s) == HeapSlen
  let cap = if isHeap: s.more.capImpl else: 0
  if isHeap and s.more.rc == 1 and newLen <= cap:
    discard  # already unique with sufficient capacity
  else:
    let oldLen = s.more.fullLen
    let newCap = max(newLen, resize(cap))
    let p = cast[ptr LongString](alloc(LongStringDataOffset + newCap + 1))
    p.rc = 1
    p.fullLen = oldLen  # logical length unchanged — caller sets it after writing data
    p.capImpl = newCap
    let old = s.more
    copyMem(addr p.data[0], addr old.data[0], oldLen + 1)
    if isHeap and atomicSubFetch(old.rc, 1) == 0:
      dealloc(old)
    s.more = p
    setSSLen(s, HeapSlen)

proc prepareAdd(s: var SmallString; addLen: int) {.compilerRtl.} =
  ## Ensure s has room for addLen more characters without changing its length.
  let slen = ssLen(s)
  let curLen = if slen > PayloadSize: s.more.fullLen else: slen
  let newLen = curLen + addLen
  if slen <= PayloadSize:
    if newLen > PayloadSize:
      # transition to long: allocate, copy existing data
      let newCap = newLen * 2
      let p = cast[ptr LongString](alloc(LongStringDataOffset + newCap + 1))
      p.rc = 1
      p.fullLen = curLen
      p.capImpl = newCap
      copyMem(addr p.data[0], inlinePtr(s), curLen + 1)
      s.more = p
      setSSLen(s, HeapSlen)
    # else: short/medium — inline capacity always sufficient (struct is fixed size)
  else:
    prepareAddLong(s, newLen)

proc nimAddCharV1(s: var SmallString; c: char) {.compilerRtl, inline.} =
  let slen = ssLen(s)
  if slen < PayloadSize:
    # Hot path: inline/medium with room (slen+1 <= PayloadSize, no heap needed)
    let inl = inlinePtr(s)
    inl[slen] = c
    inl[slen + 1] = '\0'
    setSSLen(s, slen + 1)
  elif slen > PayloadSize:
    # Long string — inline the common case: unique heap block with room
    let l = s.more.fullLen
    if slen == HeapSlen and s.more.rc == 1 and l < s.more.capImpl:
      s.more.data[l] = c
      s.more.data[l + 1] = '\0'
      s.more.fullLen = l + 1
      if l < AlwaysAvail:
        inlinePtr(s)[l] = c
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
    setSSLen(result, len)
    let inl = inlinePtr(result)
    copyMem(inl, str, len)
    inl[len] = '\0'
    # Bytes past inl[len] in `bytes` must be zero for SWAR. `result` is zero-initialized,
    # and copyMem only fills bytes 0..len-1 of inl; bytes len..6 remain zero.
  else:
    let p = cast[ptr LongString](alloc(LongStringDataOffset + len + 1))
    p.rc = 1
    p.fullLen = len
    p.capImpl = len
    copyMem(addr p.data[0], str, len)
    p.data[len] = '\0'
    copyMem(inlinePtr(result), str, AlwaysAvail)
    setSSLen(result, HeapSlen)
    result.more = p

proc cstrToNimstr(str: cstring): SmallString {.compilerRtl.} =
  if str == nil: return
  toNimStr(str, str.len)

proc nimToCStringConv(s: var SmallString): cstring {.compilerproc, nonReloadable, inline.} =
  ## Returns a null-terminated C string pointer into s's data.
  ## Takes by var (pointer) so the inline chars ptr is always valid.
  if ssLen(s) > PayloadSize:
    cast[cstring](addr s.more.data[0])
  else:
    cast[cstring](inlinePtr(s))

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
    let p = cast[ptr LongString](alloc(LongStringDataOffset + space + 1))
    p.rc = 1
    p.fullLen = 0
    p.capImpl = space
    p.data[0] = '\0'
    result.more = p
    setSSLen(result, HeapSlen)

proc mnewString(len: int): SmallString {.compilerproc.} =
  ## Returns a SmallString of `len` zero characters (newString).
  if len <= 0: return
  if len <= PayloadSize:
    setSSLen(result, len)
    # bytes field is zero-initialized (result starts at 0); inline chars are already 0.
    # Null terminator at inlinePtr(result)[len] is also 0 — fine for SWAR invariant.
  else:
    let p = cast[ptr LongString](alloc0(LongStringDataOffset + len + 1))
    p.rc = 1
    p.fullLen = len
    p.capImpl = len
    # data is zeroed by alloc0; data[len] is '\0' too
    result.more = p
    setSSLen(result, HeapSlen)

proc setLengthStr(s: var SmallString; newLen: int; zeroing: bool) =
  # Shared implementation for setLengthStrV2 (zeroing) and setLengthStrV3Uninit
  # Difference between the two modes:
  #   - inline/medium -> long growth: alloc0 (zeroing) vs alloc (uninit)
  #   - long -> long growth: zeroMem the new tail (zeroing) or skip it (uninit)
  let slen = ssLen(s)
  let curLen = if slen > PayloadSize: s.more.fullLen else: slen
  if newLen == curLen: return
  if newLen < curLen:
    # Shrinking:
    if slen > PayloadSize:
      if slen == HeapSlen and s.more.rc == 1:
        # Unique heap block: keep the buffer allocated to avoid alloc/dealloc
        # ping-pong when callers shrink then grow (e.g. setLen(0) + add loops).
        s.more.fullLen = newLen
        s.more.data[newLen] = '\0'
      else:
        # shared or static block: detach and go back to inline
        if newLen <= 0:
          nimDestroyStrV1(s)
          s.bytes = 0
        else:
          let old = s.more
          let inl = inlinePtr(s)
          copyMem(inl, addr old.data[0], newLen)
          inl[newLen] = '\0'
          if slen == HeapSlen and atomicSubFetch(old.rc, 1) == 0:
            dealloc(old)
          if newLen < AlwaysAvail:
            when system.cpuEndian == littleEndian:
              let keepBits = (newLen + 1) * 8
              let charMask = ((uint(1) shl keepBits) - 1'u) and not 0xFF'u
              s.bytes = (s.bytes and charMask) or uint(newLen)
            else:
              let discardBits = (AlwaysAvail - newLen) * 8
              let slenBit = 8 * (sizeof(uint) - 1)
              let charMask = not ((uint(1) shl discardBits) - 1'u) and not (0xFF'u shl slenBit)
              s.bytes = (s.bytes and charMask) or (uint(newLen) shl slenBit)
          else:
            setSSLen(s, newLen)
    else:
      # inline/medium shrink
      if newLen <= 0:
        s.bytes = 0
      else:
        let inl = inlinePtr(s)
        inl[newLen] = '\0'
        if newLen < AlwaysAvail:
          when system.cpuEndian == littleEndian:
            let keepBits = (newLen + 1) * 8
            let charMask = ((uint(1) shl keepBits) - 1'u) and not 0xFF'u
            s.bytes = (s.bytes and charMask) or uint(newLen)
          else:
            let discardBits = (AlwaysAvail - newLen) * 8
            let slenBit = 8 * (sizeof(uint) - 1)
            let charMask = not ((uint(1) shl discardBits) - 1'u) and not (0xFF'u shl slenBit)
            s.bytes = (s.bytes and charMask) or (uint(newLen) shl slenBit)
        else:
          setSSLen(s, newLen)
    return
  if slen <= PayloadSize:
    if newLen <= PayloadSize:
      let inl = inlinePtr(s)
      if newLen > curLen:
        # Grow within inline/medium
        # Bytes above newLen already zero by the SWAR invariant,
        # so setSSLen is sufficient.
        if zeroing:
          zeroMem(addr inl[curLen], newLen - curLen)
        inl[newLen] = '\0'
        setSSLen(s, newLen)
      else:
        # Shrink: zero out padding bytes for SWAR invariant.
        inl[newLen] = '\0'
        if newLen < AlwaysAvail:
          # Zero bytes newLen+1..AlwaysAvail-1 in `bytes` (chars newLen..AlwaysAvail-2
          # are now padding and must be 0 for SWAR comparison to work correctly).
          when system.cpuEndian == littleEndian:
            # LE: slen in bits 0-7; keep bits 0..(newLen+1)*8-1, clear the rest above.
            let keepBits = (newLen + 1) * 8
            let charMask = ((uint(1) shl keepBits) - 1'u) and not 0xFF'u
            s.bytes = (s.bytes and charMask) or uint(newLen)
          else:
            # BE: slen in the top byte; keep top (newLen+1) bytes, zero the rest below.
            let discardBits = (AlwaysAvail - newLen) * 8
            let slenBit = 8 * (sizeof(uint) - 1)
            let charMask = not ((uint(1) shl discardBits) - 1'u) and not (0xFF'u shl slenBit)
            s.bytes = (s.bytes and charMask) or (uint(newLen) shl slenBit)
        else:
          setSSLen(s, newLen)
    else:
      # grow into long
      let newCap = resize(newLen)
      let p = if zeroing:
          # bytes [curLen..newLen] and p.data[newLen] zeroed by alloc0
          cast[ptr LongString](alloc0(LongStringDataOffset + newCap + 1))
        else:
          let p = cast[ptr LongString](alloc(LongStringDataOffset + newCap + 1))
          p.data[newLen] = '\0'
          p
      p.rc = 1
      p.fullLen = newLen
      p.capImpl = newCap
      copyMem(addr p.data[0], inlinePtr(s), curLen)
      s.more = p
      setSSLen(s, HeapSlen)
  else:
    # currently long: grow within the heap buffer (shrinking already returned above)
    ensureUniqueLong(s, curLen, newLen) # sets fullLen = newLen
    if zeroing and newLen > curLen:
      zeroMem(addr s.more.data[curLen], newLen - curLen)
    s.more.data[newLen] = '\0'

proc setLengthStrV2(s: var SmallString; newLen: int) {.compilerRtl.} =
  ## Sets the length of `s` to `newLen`, zeroing new bytes on growth.
  setLengthStr(s, newLen, zeroing = true)

proc setLengthStrV3Uninit(s: var SmallString; newLen: int) {.compilerRtl.} =
  ## Sets the length of `s` to `newLen`, NOT zeroing new bytes on growth.
  setLengthStr(s, newLen, zeroing = false)

proc nimAsgnStrV2(a: var SmallString; b: SmallString) {.compilerRtl, inline.} =
  if ssLen(b) <= PayloadSize:
    nimDestroyStrV1(a)  # free any existing heap block before overwriting
    copyMem(addr a, unsafeAddr b, sizeof(SmallString))
  else:
    if addr(a) == unsafeAddr(b): return
    nimDestroyStrV1(a)
    # COW: share the block, bump refcount — no allocation needed (static literals: no bump)
    if ssLenOf(b.bytes) == HeapSlen:
      discard atomicAddFetch(b.more.rc, 1)
    copyMem(addr a, unsafeAddr b, sizeof(SmallString))

proc nimPrepareStrMutationImpl(s: var SmallString) =
  # Called when s holds a static (slen=StaticSlen) LongString block. COW: allocate fresh copy.
  let old = s.more
  let oldLen = old.fullLen
  let p = cast[ptr LongString](alloc(LongStringDataOffset + oldLen + 1))
  p.rc = 1
  p.fullLen = oldLen
  p.capImpl = oldLen
  copyMem(addr p.data[0], addr old.data[0], oldLen + 1)
  s.more = p
  setSSLen(s, HeapSlen)  # promote from static to heap-owned

proc nimPrepareStrMutationV2(s: var SmallString) {.compilerRtl, inline.} =
  if ssLen(s) == StaticSlen:
    nimPrepareStrMutationImpl(s)

proc prepareMutation*(s: var string) {.inline.} =
  {.cast(noSideEffect).}:
    nimPrepareStrMutationV2(cast[ptr SmallString](addr s)[])

proc nimStrAtMutV3*(s: var SmallString; i: int): var char {.compilerproc, inline.} =
  ## Returns a mutable reference to the i-th char. Handles COW for long strings.
  ## Used by the codegen when s[i] is passed as a `var char` argument.
  if ssLen(s) > PayloadSize:
    nimPrepareStrMutationV2(s)  # COW: ensure unique heap block before exposing ref
    result = s.more.data[i]
  else:
    result = inlinePtr(s)[i]

proc nimAddStrV1(s: var SmallString; src: SmallString) {.compilerRtl, inline.} =
  s.add(src)

func capacity*(self: SmallString): int {.inline.} =
  ## Returns the current capacity of the string.
  let slen = ssLen(self)
  if slen == HeapSlen:
    self.more.capImpl
  elif slen == StaticSlen:
    self.more.fullLen  # static: report fullLen as capacity (read-only, no extra room)
  else:
    PayloadSize

proc nimStrLen(s: SmallString): int {.compilerproc, inline.} =
  ## Returns the length of s. Called by the codegen for `mLen` on strings with -d:nimsso.
  s.len

proc nimStrData(s: var SmallString): ptr UncheckedArray[char] {.compilerproc, inline.} =
  ## Returns a pointer to the char data of s. Called by codegen for subscript and slice with -d:nimsso.
  if ssLen(s) > PayloadSize: cast[ptr UncheckedArray[char]](addr s.more.data[0])
  else: inlinePtr(s)

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
          setSSLen(s[], len)
          # Null-terminate; bytes [0..len-1] left uninitialized for caller to fill.
          inlinePtr(s[])[len] = '\0'
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
  ## the inline bytes so that `cmp`/`==` can compare long strings
  ## without a heap dereference for the first few bytes.
  if ssLen(s) > PayloadSize:
    copyMem(inlinePtr(s), addr s.more.data[0], AlwaysAvail)

proc completeStore*(s: var string) {.inline.} =
  completeStore(cast[ptr SmallString](addr s)[])

proc beginStore*(s: var string; newLen: int; start = 0): ptr UncheckedArray[char] {.inline, noSideEffect, raises: [], tags: [].} =
  ## Sets s.len to `newLen` (new bytes are uninitialized), ensures unique
  ## ownership, and returns a pointer to s[start] for bulk writing.
  ## Call `endStore(s)` afterwards to sync the inline cache.
  ## To keep the current length, pass `s.len`.
  {.cast(noSideEffect).}:
    let ss = cast[ptr SmallString](addr s)
    let slen = ssLen(ss[])
    let curLen = if slen > PayloadSize: ss[].more.fullLen else: slen
    if newLen <= PayloadSize and slen <= PayloadSize:
      # Stay inline/medium.
      if newLen != curLen:
        setSSLen(ss[], newLen)
      result = cast[ptr UncheckedArray[char]](cast[uint](inlinePtr(ss[])) + uint(start))
    elif slen <= PayloadSize:
      # Inline/medium → long.
      let newCap = resize(newLen)
      let p = cast[ptr LongString](alloc(LongStringDataOffset + newCap + 1))
      p.rc = 1
      p.fullLen = newLen
      p.capImpl = newCap
      copyMem(addr p.data[0], inlinePtr(ss[]), curLen)
      p.data[newLen] = '\0'
      ss[].more = p
      setSSLen(ss[], HeapSlen)
      result = cast[ptr UncheckedArray[char]](addr ss[].more.data[start])
    else:
      # Already long: resize within heap (no transition back to inline).
      ensureUniqueLong(ss[], curLen, newLen)
      ss[].more.data[newLen] = '\0'
      result = cast[ptr UncheckedArray[char]](addr ss[].more.data[start])

proc endStore*(s: var string) {.inline, noSideEffect, raises: [], tags: [].} =
  ## Syncs the inline cache after bulk writes via `beginStore`. No-op for short/medium strings.
  {.cast(noSideEffect).}: completeStore(cast[ptr SmallString](addr s)[])

proc rawDataImpl(ss: ptr SmallString; start: int): ptr UncheckedArray[char] {.inline, noSideEffect, raises: [].} =
  let slen = ssLen(ss[])
  let actualLen = if slen > PayloadSize: ss[].more.fullLen else: slen
  if actualLen == 0: nil
  elif slen > PayloadSize: cast[ptr UncheckedArray[char]](addr ss[].more.data[start])
  else: cast[ptr UncheckedArray[char]](cast[uint](inlinePtr(ss[])) + uint(start))

template readRawData*(s: string; start = 0): ptr UncheckedArray[char] =
  ## Returns a pointer to `s[start]` for read-only raw access.
  ## Template ensures no copy of `s` is made; ptr is valid while `s` is alive.
  rawDataImpl(cast[ptr SmallString](unsafeAddr s), start)

proc readRawDataStable*(s: var string; start = 0): ptr UncheckedArray[char] {.inline.} =
  ## Like `readRawData`, but the returned pointer stays valid across moves and
  ## copies of `s` (as long as `s` stays alive and is not reassigned). A
  ## short/medium string keeps its chars *inline* in the string object, so a
  ## plain `readRawData` pointer dangles the moment the object is moved; this
  ## promotes `s` to its heap (long) representation first, whose payload address
  ## is independent of where the string object itself lives. Use this whenever an
  ## interior pointer must outlive the current scope of the owning string (e.g.
  ## a cursor cached alongside the buffer it points into).
  let ss = cast[ptr SmallString](addr s)
  let slen = ssLen(ss[])
  if slen > 0 and slen <= PayloadSize:
    # Promote inline/medium to a long heap block so the payload lives at a
    # stable address. Mirrors the short/medium -> long transition in `add`.
    let newCap = max(slen, resize(slen))
    let p = cast[ptr LongString](alloc(LongStringDataOffset + newCap + 1))
    p.rc = 1
    p.fullLen = slen
    p.capImpl = newCap
    copyMem(addr p.data[0], inlinePtr(ss[]), slen)
    p.data[slen] = '\0'
    ss[].more = p
    setSSLen(ss[], HeapSlen)
    # Hot-prefix cache (bytes 1..AlwaysAvail) already mirrors data[0..AlwaysAvail-1]
    # because setSSLen only rewrote byte 0; the inline chars are untouched.
  rawDataImpl(ss, start)

# These take `string` (tyString) so the codegen uses them directly, bypassing
# strmantle.nim's versions which go through nimStrLen/nimStrAtMutV3 compilerproc calls.
proc cmpStrings(a, b: string): int {.compilerproc, inline.} =
  cmpStringPtrs(cast[ptr SmallString](unsafeAddr a), cast[ptr SmallString](unsafeAddr b))

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
