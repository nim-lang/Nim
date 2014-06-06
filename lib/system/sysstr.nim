#
#
#            Nimrod's Runtime Library
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
  if a == nil: return -1
  if b == nil: return 1
  return c_strcmp(a.data, b.data)

proc eqStrings(a, b: NimString): bool {.inline, compilerProc.} =
  if a == b: return true
  if a == nil or b == nil: return false
  return a.len == b.len and
    c_memcmp(a.data, b.data, a.len * sizeof(char)) == 0'i32

when defined(allocAtomic):
  template allocStr(size: expr): expr =
    cast[NimString](allocAtomic(size))
else:
  template allocStr(size: expr): expr =
    cast[NimString](newObj(addr(strDesc), size))

proc rawNewString(space: int): NimString {.compilerProc.} =
  var s = space
  if s < 8: s = 7
  result = allocStr(sizeof(TGenericSeq) + s + 1)
  result.reserved = s

proc mnewString(len: int): NimString {.compilerProc.} =
  result = rawNewString(len)
  result.len = len

proc copyStrLast(s: NimString, start, last: int): NimString {.compilerProc.} =
  var start = max(start, 0)
  var len = min(last, s.len-1) - start + 1
  if len > 0:
    result = rawNewString(len)
    result.len = len
    c_memcpy(result.data, addr(s.data[start]), len * sizeof(char))
    #result.data[len] = '\0'
  else:
    result = rawNewString(len)

proc copyStr(s: NimString, start: int): NimString {.compilerProc.} =
  result = copyStrLast(s, start, s.len-1)

proc toNimStr(str: cstring, len: int): NimString {.compilerProc.} =
  result = rawNewString(len)
  result.len = len
  c_memcpy(result.data, str, (len+1) * sizeof(char))
  #result.data[len] = '\0' # readline relies on this!

proc cstrToNimstr(str: cstring): NimString {.compilerRtl.} =
  result = toNimStr(str, c_strlen(str))

proc copyString(src: NimString): NimString {.compilerRtl.} =
  if src != nil:
    if (src.reserved and seqShallowFlag) != 0:
      result = src
    else:
      result = rawNewString(src.space)
      result.len = src.len
      c_memcpy(result.data, src.data, (src.len + 1) * sizeof(char))

proc copyStringRC1(src: NimString): NimString {.compilerRtl.} =
  if src != nil:
    var s = src.space
    if s < 8: s = 7
    when defined(newObjRC1):
      result = cast[NimString](newObjRC1(addr(strDesc), sizeof(TGenericSeq) +
                               s+1))
    else:
      result = allocStr(sizeof(TGenericSeq) + s + 1)
    result.reserved = s
    result.len = src.len
    c_memcpy(result.data, src.data, src.len + 1)

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
  result = s
  if result.len >= result.space:
    result.reserved = resize(result.space)
    result = cast[NimString](growObj(result,
      sizeof(TGenericSeq) + (result.reserved+1) * sizeof(char)))
  result.data[result.len] = c
  result.data[result.len+1] = '\0'
  inc(result.len)

# These routines should be used like following:
#   <Nimrod code>
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
#   <Nimrod code>
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
#   <Nimrod code>
#   s = ""
#
#   <generated C code>
#   s = rawNewString(0);

proc resizeString(dest: NimString, addlen: int): NimString {.compilerRtl.} =
  if dest.len + addlen <= dest.space:
    result = dest
  else: # slow path:
    var sp = max(resize(dest.space), dest.len + addlen)
    result = cast[NimString](growObj(dest, sizeof(TGenericSeq) + sp + 1))
    result.reserved = sp
    #result = rawNewString(sp)
    #copyMem(result, dest, dest.len * sizeof(char) + sizeof(TGenericSeq))
    # DO NOT UPDATE LEN YET: dest.len = newLen

proc appendString(dest, src: NimString) {.compilerproc, inline.} =
  c_memcpy(addr(dest.data[dest.len]), src.data, src.len + 1)
  inc(dest.len, src.len)

proc appendChar(dest: NimString, c: char) {.compilerproc, inline.} =
  dest.data[dest.len] = c
  dest.data[dest.len+1] = '\0'
  inc(dest.len)

proc setLengthStr(s: NimString, newLen: int): NimString {.compilerRtl.} =
  var n = max(newLen, 0)
  if n <= s.space:
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
    result.reserved = resize(result.space)
    result = cast[PGenericSeq](growObj(result, elemSize * result.reserved +
                               GenericSeqSize))
  inc(result.len)

proc setLengthSeq(seq: PGenericSeq, elemSize, newLen: int): PGenericSeq {.
    compilerRtl.} =
  result = seq
  if result.space < newLen:
    result.reserved = max(resize(result.space), newLen)
    result = cast[PGenericSeq](growObj(result, elemSize * result.reserved +
                               GenericSeqSize))
  elif newLen < result.len:
    # we need to decref here, otherwise the GC leaks!
    when not defined(boehmGC) and not defined(nogc) and 
         not defined(gcMarkAndSweep):
      when compileOption("gc", "v2"):
        for i in newLen..result.len-1:
          let len0 = gch.tempStack.len
          forAllChildrenAux(cast[pointer](cast[TAddress](result) +%
                            GenericSeqSize +% (i*%elemSize)),
                            extGetCellType(result).base, waPush)
          let len1 = gch.tempStack.len
          for i in len0 .. <len1:
            doDecRef(gch.tempStack.d[i], LocalHeap, MaybeCyclic)
          gch.tempStack.len = len0
      else:
        for i in newLen..result.len-1:
          forAllChildrenAux(cast[pointer](cast[TAddress](result) +%
                            GenericSeqSize +% (i*%elemSize)),
                            extGetCellType(result).base, waZctDecRef)
      
    # XXX: zeroing out the memory can still result in crashes if a wiped-out
    # cell is aliased by another pointer (ie proc paramter or a let variable).
    # This is a tought problem, because even if we don't zeroMem here, in the
    # presense of user defined destructors, the user will expect the cell to be
    # "destroyed" thus creating the same problem. We can destoy the cell in the
    # finalizer of the sequence, but this makes destruction non-deterministic.
    zeroMem(cast[pointer](cast[TAddress](result) +% GenericSeqSize +%
           (newLen*%elemSize)), (result.len-%newLen) *% elemSize)
  result.len = newLen

# --------------- other string routines ----------------------------------
proc nimIntToStr(x: int): string {.compilerRtl.} =
  result = newString(sizeof(x)*4)
  var i = 0
  var y = x
  while true:
    var d = y div 10
    result[i] = chr(abs(int(y - d*10)) + ord('0'))
    inc(i)
    y = d
    if y == 0: break
  if x < 0:
    result[i] = '-'
    inc(i)
  setLen(result, i)
  # mirror the string:
  for j in 0..i div 2 - 1:
    swap(result[j], result[i-j-1])

proc nimFloatToStr(x: float): string {.compilerproc.} =
  var buf: array [0..59, char]
  c_sprintf(buf, "%.16g", x)
  # Should account for the - sign.
  if not('.' in buf) and (buf[0] in '0'..'9' or buf[1] in '0'..'9'):
    var breaking = 0
    for index, c in buf:
      if not(c in '0'..'9'):
        breaking = index - 1
        break
    moveMem(addr(buf[breaking+2]), addr(buf[breaking]), len(buf) - 2 - breaking)
    buf[breaking+1] = '.'
    buf[breaking+2] = '0'
  result = $buf

proc nimInt64ToStr(x: int64): string {.compilerRtl.} =
  result = newString(sizeof(x)*4)
  var i = 0
  var y = x
  while true:
    var d = y div 10
    result[i] = chr(abs(int(y - d*10)) + ord('0'))
    inc(i)
    y = d
    if y == 0: break
  if x < 0:
    result[i] = '-'
    inc(i)
  setLen(result, i)
  # mirror the string:
  for j in 0..i div 2 - 1:
    swap(result[j], result[i-j-1])

proc nimBoolToStr(x: bool): string {.compilerRtl.} =
  return if x: "true" else: "false"

proc nimCharToStr(x: char): string {.compilerRtl.} =
  result = newString(1)
  result[0] = x

proc binaryStrSearch(x: openArray[string], y: string): int {.compilerproc.} =
  var
    a = 0
    b = len(x)
  while a < b:
    var mid = (a + b) div 2
    if x[mid] < y:
      a = mid + 1
    else:
      b = mid
  if a < len(x) and x[a] == y:
    result = a
  else:
    result = -1
