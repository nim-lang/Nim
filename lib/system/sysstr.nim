#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# string & sequence handling procedures needed by the code generator

# strings are dynamically resized, have a length field
# and are zero-terminated, so they can be casted to C
# strings easily
# we don't use refcounts because that's a behaviour
# the programmer may not want

proc resize(old: int): int {.inline.} =
  if old <= 0: result = 4
  elif old < 65536: result = old * 2
  else: result = old * 3 div 2 # for large arrays * 3/2 is better

proc cmpStrings(a, b: NimString): int {.inline, compilerProc.} =
  if a == b: return 0
  when defined(nimNoNil):
    let alen = if a == nil: 0 else: a.len
    let blen = if b == nil: 0 else: b.len
  else:
    if a == nil: return -1
    if b == nil: return 1
    let alen = a.len
    let blen = b.len
  let minlen = min(alen, blen)
  if minlen > 0:
    result = c_memcmp(addr a.data, addr b.data, minlen.csize)
    if result == 0:
      result = alen - blen
  else:
    result = alen - blen

proc eqStrings(a, b: NimString): bool {.inline, compilerProc.} =
  if a == b: return true
  when defined(nimNoNil):
    let alen = if a == nil: 0 else: a.len
    let blen = if b == nil: 0 else: b.len
  else:
    if a == nil or b == nil: return false
    let alen = a.len
    let blen = b.len
  if alen == blen:
    if alen == 0: return true
    return equalMem(addr(a.data), addr(b.data), alen)

when declared(allocAtomic):
  template allocStr(size: untyped): untyped =
    cast[NimString](allocAtomic(size))

  template allocStrNoInit(size: untyped): untyped =
    cast[NimString](boehmAllocAtomic(size))
elif defined(gcRegions):
  template allocStr(size: untyped): untyped =
    cast[NimString](newStr(addr(strDesc), size, true))

  template allocStrNoInit(size: untyped): untyped =
    cast[NimString](newStr(addr(strDesc), size, false))

else:
  template allocStr(size: untyped): untyped =
    cast[NimString](newObj(addr(strDesc), size))

  template allocStrNoInit(size: untyped): untyped =
    cast[NimString](newObjNoInit(addr(strDesc), size))

proc rawNewStringNoInit(space: int): NimString {.compilerProc.} =
  var s = space
  if s < 7: s = 7
  result = allocStrNoInit(sizeof(TGenericSeq) + s + 1)
  result.reserved = s
  result.len = 0
  when defined(gogc):
    result.elemSize = 1

proc rawNewString(space: int): NimString {.compilerProc.} =
  var s = space
  if s < 7: s = 7
  result = allocStr(sizeof(TGenericSeq) + s + 1)
  result.reserved = s
  result.len = 0
  when defined(gogc):
    result.elemSize = 1

proc mnewString(len: int): NimString {.compilerProc.} =
  result = rawNewString(len)
  result.len = len

proc copyStrLast(s: NimString, start, last: int): NimString {.compilerProc.} =
  var start = max(start, 0)
  var len = min(last, s.len-1) - start + 1
  if len > 0:
    result = rawNewStringNoInit(len)
    result.len = len
    copyMem(addr(result.data), addr(s.data[start]), len)
    result.data[len] = '\0'
  else:
    result = rawNewString(len)

proc copyStr(s: NimString, start: int): NimString {.compilerProc.} =
  result = copyStrLast(s, start, s.len-1)

proc toNimStr(str: cstring, len: int): NimString {.compilerProc.} =
  result = rawNewStringNoInit(len)
  result.len = len
  copyMem(addr(result.data), str, len + 1)

proc cstrToNimstr(str: cstring): NimString {.compilerRtl.} =
  if str == nil: NimString(nil)
  else: toNimStr(str, str.len)

proc copyString(src: NimString): NimString {.compilerRtl.} =
  if src != nil:
    if (src.reserved and seqShallowFlag) != 0:
      result = src
    else:
      result = rawNewStringNoInit(src.len)
      result.len = src.len
      copyMem(addr(result.data), addr(src.data), src.len + 1)
      sysAssert((seqShallowFlag and result.reserved) == 0, "copyString")
      when defined(nimShallowStrings):
        if (src.reserved and strlitFlag) != 0:
          result.reserved = (result.reserved and not strlitFlag) or seqShallowFlag

proc newOwnedString(src: NimString; n: int): NimString =
  result = rawNewStringNoInit(n)
  result.len = n
  copyMem(addr(result.data), addr(src.data), n)
  result.data[n] = '\0'

proc copyStringRC1(src: NimString): NimString {.compilerRtl.} =
  if src != nil:
    when declared(newObjRC1) and not defined(gcRegions):
      var s = src.len
      if s < 7: s = 7
      result = cast[NimString](newObjRC1(addr(strDesc), sizeof(TGenericSeq) +
                               s+1))
      result.reserved = s
    else:
      result = rawNewStringNoInit(src.len)
    result.len = src.len
    copyMem(addr(result.data), addr(src.data), src.len + 1)
    sysAssert((seqShallowFlag and result.reserved) == 0, "copyStringRC1")
    when defined(nimShallowStrings):
      if (src.reserved and strlitFlag) != 0:
        result.reserved = (result.reserved and not strlitFlag) or seqShallowFlag

proc copyDeepString(src: NimString): NimString {.inline.} =
  if src != nil:
    result = rawNewStringNoInit(src.len)
    result.len = src.len
    copyMem(addr(result.data), addr(src.data), src.len + 1)

proc hashString(s: string): int {.compilerproc.} =
  # the compiler needs exactly the same hash function!
  # this used to be used for efficient generation of string case statements
  var h = 0
  for i in 0..len(s)-1:
    h = h +% ord(s[i])
    h = h +% h shl 10
    h = h xor (h shr 6)
  h = h +% h shl 3
  h = h xor (h shr 11)
  h = h +% h shl 15
  result = h

proc addChar(s: NimString, c: char): NimString =
  # is compilerproc!
  if s == nil:
    result = rawNewStringNoInit(1)
    result.len = 0
  else:
    result = s
    if result.len >= result.space:
      let r = resize(result.space)
      result = cast[NimString](growObj(result,
        sizeof(TGenericSeq) + r + 1))
      result.reserved = r
  result.data[result.len] = c
  result.data[result.len+1] = '\0'
  inc(result.len)

# These routines should be used like following:
#   <Nim code>
#   s &= "Hello " & name & ", how do you feel?"
#
#   <generated C code>
#   {
#     s = resizeString(s, 6 + name->len + 17);
#     appendString(s, strLit1);
#     appendString(s, strLit2);
#     appendString(s, strLit3);
#   }
#
#   <Nim code>
#   s = "Hello " & name & ", how do you feel?"
#
#   <generated C code>
#   {
#     string tmp0;
#     tmp0 = rawNewString(6 + name->len + 17);
#     appendString(s, strLit1);
#     appendString(s, strLit2);
#     appendString(s, strLit3);
#     s = tmp0;
#   }
#
#   <Nim code>
#   s = ""
#
#   <generated C code>
#   s = rawNewString(0);

proc resizeString(dest: NimString, addlen: int): NimString {.compilerRtl.} =
  if dest == nil:
    result = rawNewStringNoInit(addlen)
  elif dest.len + addlen <= dest.space:
    result = dest
  else: # slow path:
    var sp = max(resize(dest.space), dest.len + addlen)
    result = cast[NimString](growObj(dest, sizeof(TGenericSeq) + sp + 1))
    result.reserved = sp
    #result = rawNewString(sp)
    #copyMem(result, dest, dest.len + sizeof(TGenericSeq))
    # DO NOT UPDATE LEN YET: dest.len = newLen

proc appendString(dest, src: NimString) {.compilerproc, inline.} =
  if src != nil:
    copyMem(addr(dest.data[dest.len]), addr(src.data), src.len + 1)
    inc(dest.len, src.len)

proc appendChar(dest: NimString, c: char) {.compilerproc, inline.} =
  dest.data[dest.len] = c
  dest.data[dest.len+1] = '\0'
  inc(dest.len)

proc setLengthStr(s: NimString, newLen: int): NimString {.compilerRtl.} =
  var n = max(newLen, 0)
  if s == nil:
    result = mnewString(newLen)
  elif n <= s.space:
    result = s
  else:
    result = resizeString(s, n)
  result.len = n
  result.data[n] = '\0'

# ----------------- sequences ----------------------------------------------

proc incrSeq(seq: PGenericSeq, elemSize: int): PGenericSeq {.compilerProc.} =
  # increments the length by one:
  # this is needed for supporting ``add``;
  #
  #  add(seq, x)  generates:
  #  seq = incrSeq(seq, sizeof(x));
  #  seq[seq->len-1] = x;
  result = seq
  if result.len >= result.space:
    let r = resize(result.space)
    result = cast[PGenericSeq](growObj(result, elemSize * r +
                               GenericSeqSize))
    result.reserved = r
  inc(result.len)

proc incrSeqV2(seq: PGenericSeq, elemSize: int): PGenericSeq {.compilerProc.} =
  # incrSeq version 2
  result = seq
  if result.len >= result.space:
    let r = resize(result.space)
    result = cast[PGenericSeq](growObj(result, elemSize * r +
                               GenericSeqSize))
    result.reserved = r

proc incrSeqV3(s: PGenericSeq, typ: PNimType): PGenericSeq {.compilerProc.} =
  if s == nil:
    result = cast[PGenericSeq](newSeq(typ, 1))
    result.len = 0
  else:
    result = s
    if result.len >= result.space:
      let r = resize(result.space)
      result = cast[PGenericSeq](growObj(result, typ.base.size * r +
                                GenericSeqSize))
      result.reserved = r

proc setLengthSeq(seq: PGenericSeq, elemSize, newLen: int): PGenericSeq {.
    compilerRtl, inl.} =
  result = seq
  if result.space < newLen:
    let r = max(resize(result.space), newLen)
    result = cast[PGenericSeq](growObj(result, elemSize * r +
                               GenericSeqSize))
    result.reserved = r
  elif newLen < result.len:
    # we need to decref here, otherwise the GC leaks!
    when not defined(boehmGC) and not defined(nogc) and
         not defined(gcMarkAndSweep) and not defined(gogc) and
         not defined(gcRegions):
      when false: # compileOption("gc", "v2"):
        for i in newLen..result.len-1:
          let len0 = gch.tempStack.len
          forAllChildrenAux(cast[pointer](cast[ByteAddress](result) +%
                            GenericSeqSize +% (i*%elemSize)),
                            extGetCellType(result).base, waPush)
          let len1 = gch.tempStack.len
          for i in len0 ..< len1:
            doDecRef(gch.tempStack.d[i], LocalHeap, MaybeCyclic)
          gch.tempStack.len = len0
      else:
        if ntfNoRefs notin extGetCellType(result).base.flags:
          for i in newLen..result.len-1:
            forAllChildrenAux(cast[pointer](cast[ByteAddress](result) +%
                              GenericSeqSize +% (i*%elemSize)),
                              extGetCellType(result).base, waZctDecRef)

    # XXX: zeroing out the memory can still result in crashes if a wiped-out
    # cell is aliased by another pointer (ie proc parameter or a let variable).
    # This is a tough problem, because even if we don't zeroMem here, in the
    # presence of user defined destructors, the user will expect the cell to be
    # "destroyed" thus creating the same problem. We can destoy the cell in the
    # finalizer of the sequence, but this makes destruction non-deterministic.
    zeroMem(cast[pointer](cast[ByteAddress](result) +% GenericSeqSize +%
           (newLen*%elemSize)), (result.len-%newLen) *% elemSize)
  result.len = newLen

proc setLengthSeqV2(s: PGenericSeq, typ: PNimType, newLen: int): PGenericSeq {.
    compilerRtl.} =
  if s == nil:
    result = cast[PGenericSeq](newSeq(typ, newLen))
  else:
    result = setLengthSeq(s, typ.base.size, newLen)

# --------------- other string routines ----------------------------------
proc add*(result: var string; x: int64) =
  let base = result.len
  setLen(result, base + sizeof(x)*4)
  var i = 0
  var y = x
  while true:
    var d = y div 10
    result[base+i] = chr(abs(int(y - d*10)) + ord('0'))
    inc(i)
    y = d
    if y == 0: break
  if x < 0:
    result[base+i] = '-'
    inc(i)
  setLen(result, base+i)
  # mirror the string:
  for j in 0..i div 2 - 1:
    swap(result[base+j], result[base+i-j-1])

proc nimIntToStr(x: int): string {.compilerRtl.} =
  result = newStringOfCap(sizeof(x)*4)
  result.add x

proc add*(result: var string; x: float) =
  when nimvm:
    result.add $x
  else:
    var buf: array[0..64, char]
    when defined(nimNoArrayToCstringConversion):
      var n: int = c_sprintf(addr buf, "%.16g", x)
    else:
      var n: int = c_sprintf(buf, "%.16g", x)
    var hasDot = false
    for i in 0..n-1:
      if buf[i] == ',':
        buf[i] = '.'
        hasDot = true
      elif buf[i] in {'a'..'z', 'A'..'Z', '.'}:
        hasDot = true
    if not hasDot:
      buf[n] = '.'
      buf[n+1] = '0'
      buf[n+2] = '\0'
    # On Windows nice numbers like '1.#INF', '-1.#INF' or '1.#NAN'
    # of '-1.#IND' are produced.
    # We want to get rid of these here:
    if buf[n-1] in {'n', 'N', 'D', 'd'}:
      result.add "nan"
    elif buf[n-1] == 'F':
      if buf[0] == '-':
        result.add "-inf"
      else:
        result.add "inf"
    else:
      var i = 0
      while buf[i] != '\0':
        result.add buf[i]
        inc i

proc nimFloatToStr(f: float): string {.compilerproc.} =
  result = newStringOfCap(8)
  result.add f

proc c_strtod(buf: cstring, endptr: ptr cstring): float64 {.
  importc: "strtod", header: "<stdlib.h>", noSideEffect.}

const
  IdentChars = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
  powtens =  [1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9,
              1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
              1e20, 1e21, 1e22]

proc nimParseBiggestFloat(s: string, number: var BiggestFloat,
                          start = 0): int {.compilerProc.} =
  # This routine attempt to parse float that can parsed quickly.
  # ie whose integer part can fit inside a 53bits integer.
  # their real exponent must also be <= 22. If the float doesn't follow
  # these restrictions, transform the float into this form:
  #  INTEGER * 10 ^ exponent and leave the work to standard `strtod()`.
  # This avoid the problems of decimal character portability.
  # see: http://www.exploringbinary.com/fast-path-decimal-to-floating-point-conversion/
  var
    i = start
    sign = 1.0
    kdigits, fdigits = 0
    exponent: int
    integer: uint64
    frac_exponent = 0
    exp_sign = 1
    first_digit = -1
    has_sign = false

  # Sign?
  if s[i] == '+' or s[i] == '-':
    has_sign = true
    if s[i] == '-':
      sign = -1.0
    inc(i)

  # NaN?
  if s[i] == 'N' or s[i] == 'n':
    if s[i+1] == 'A' or s[i+1] == 'a':
      if s[i+2] == 'N' or s[i+2] == 'n':
        if s[i+3] notin IdentChars:
          number = NaN
          return i+3 - start
    return 0

  # Inf?
  if s[i] == 'I' or s[i] == 'i':
    if s[i+1] == 'N' or s[i+1] == 'n':
      if s[i+2] == 'F' or s[i+2] == 'f':
        if s[i+3] notin IdentChars:
          number = Inf*sign
          return i+3 - start
    return 0

  if s[i] in {'0'..'9'}:
    first_digit = (s[i].ord - '0'.ord)
  # Integer part?
  while s[i] in {'0'..'9'}:
    inc(kdigits)
    integer = integer * 10'u64 + (s[i].ord - '0'.ord).uint64
    inc(i)
    while s[i] == '_': inc(i)

  # Fractional part?
  if s[i] == '.':
    inc(i)
    # if no integer part, Skip leading zeros
    if kdigits <= 0:
      while s[i] == '0':
        inc(frac_exponent)
        inc(i)
        while s[i] == '_': inc(i)

    if first_digit == -1 and s[i] in {'0'..'9'}:
      first_digit = (s[i].ord - '0'.ord)
    # get fractional part
    while s[i] in {'0'..'9'}:
      inc(fdigits)
      inc(frac_exponent)
      integer = integer * 10'u64 + (s[i].ord - '0'.ord).uint64
      inc(i)
      while s[i] == '_': inc(i)

  # if has no digits: return error
  if kdigits + fdigits <= 0 and
     (i == start or # no char consumed (empty string).
     (i == start + 1 and has_sign)): # or only '+' or '-
    return 0

  if s[i] in {'e', 'E'}:
    inc(i)
    if s[i] == '+' or s[i] == '-':
      if s[i] == '-':
        exp_sign = -1

      inc(i)
    if s[i] notin {'0'..'9'}:
      return 0
    while s[i] in {'0'..'9'}:
      exponent = exponent * 10 + (ord(s[i]) - ord('0'))
      inc(i)
      while s[i] == '_': inc(i) # underscores are allowed and ignored

  var real_exponent = exp_sign*exponent - frac_exponent
  let exp_negative = real_exponent < 0
  var abs_exponent = abs(real_exponent)

  # if exponent greater than can be represented: +/- zero or infinity
  if abs_exponent > 999:
    if exp_negative:
      number = 0.0*sign
    else:
      number = Inf*sign
    return i - start

  # if integer is representable in 53 bits:  fast path
  # max fast path integer is  1<<53 - 1 or  8999999999999999 (16 digits)
  let digits = kdigits + fdigits
  if digits <= 15 or (digits <= 16 and first_digit <= 8):
    # max float power of ten with set bits above the 53th bit is 10^22
    if abs_exponent <= 22:
      if exp_negative:
        number = sign * integer.float / powtens[abs_exponent]
      else:
        number = sign * integer.float * powtens[abs_exponent]
      return i - start

    # if exponent is greater try to fit extra exponent above 22 by multiplying
    # integer part is there is space left.
    let slop = 15 - kdigits - fdigits
    if  abs_exponent <= 22 + slop and not exp_negative:
      number = sign * integer.float * powtens[slop] * powtens[abs_exponent-slop]
      return i - start

  # if failed: slow path with strtod.
  var t: array[500, char] # flaviu says: 325 is the longest reasonable literal
  var ti = 0
  let maxlen = t.high - "e+000".len # reserve enough space for exponent

  result = i - start
  i = start
  # re-parse without error checking, any error should be handled by the code above.
  if s[i] == '.': i.inc
  while s[i] in {'0'..'9','+','-'}:
    if ti < maxlen:
      t[ti] = s[i]; inc(ti)
    inc(i)
    while s[i] in {'.', '_'}: # skip underscore and decimal point
      inc(i)

  # insert exponent
  t[ti] = 'E'; inc(ti)
  t[ti] = (if exp_negative: '-' else: '+'); inc(ti)
  inc(ti, 3)

  # insert adjusted exponent
  t[ti-1] = ('0'.ord + abs_exponent mod 10).char; abs_exponent = abs_exponent div 10
  t[ti-2] = ('0'.ord + abs_exponent mod 10).char; abs_exponent = abs_exponent div 10
  t[ti-3] = ('0'.ord + abs_exponent mod 10).char

  when defined(nimNoArrayToCstringConversion):
    number = c_strtod(addr t, nil)
  else:
    number = c_strtod(t, nil)

proc nimInt64ToStr(x: int64): string {.compilerRtl.} =
  result = newStringOfCap(sizeof(x)*4)
  result.add x

proc nimBoolToStr(x: bool): string {.compilerRtl.} =
  return if x: "true" else: "false"

proc nimCharToStr(x: char): string {.compilerRtl.} =
  result = newString(1)
  result[0] = x
