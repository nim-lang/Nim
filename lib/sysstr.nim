#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
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

type
  TStringDesc {.importc, nodecl.} = record
    len, space: int # len and space without counting the terminating zero
    data: array[0..0, char] # for the '\0' character

  mstring {.importc: "string".} = ptr TStringDesc

# implementation:

proc resize(old: int): int {.inline.} =
  assert(old < 65536 * 4)
  if old <= 0: return 1
  elif old < 65536: return old * 2
  else: return old * 3 div 2 # for large arrays * 3/2 is better

proc cmpStrings(a, b: mstring): int {.inline, compilerProc.} =
  if a == b: return 0
  if a == nil: return -1
  if b == nil: return 1
  return c_strcmp(a.data, b.data)

proc eqStrings(a, b: mstring): bool {.inline, compilerProc.} =
  if a == b: return true
  if a == nil or b == nil: return false
  return a.len == b.len and
    c_memcmp(a.data, b.data, a.len * sizeof(char)) == 0

proc rawNewString(space: int): mstring {.compilerProc.} =
  result = cast[mstring](newObj(addr(strDesc), sizeof(TStringDesc) + 
                         space * sizeof(char)))
  result.len = 0
  result.space = space
  result.data[0] = '\0'

proc mnewString(len: int): mstring {.exportc.} =
  result = rawNewString(len)
  result.len = len
  result.data[len] = '\0'

proc toNimStr(str: CString, len: int): mstring {.compilerProc.} =
  result = rawNewString(len)
  result.len = len
  c_memcpy(result.data, str, (len+1) * sizeof(Char))
  result.data[len] = '\0' # IO.readline relies on this!

proc cstrToNimstr(str: CString): mstring {.compilerProc.} =
  return toNimstr(str, c_strlen(str))

proc copyString(src: mstring): mstring {.compilerProc.} =
  result = rawNewString(src.space)
  result.len = src.len
  c_memcpy(result.data, src.data, (src.len + 1) * sizeof(Char))

proc hashString(s: string): int {.compilerproc.} =
  # the compiler needs exactly the same hash function!
  # this used to be used for efficient generation of string case statements
  var
    h: int
  h = 0
  for i in 0..Len(s)-1:
    h = h +% Ord(s[i])
    h = h +% h shl 10
    h = h xor (h shr 6)
  h = h +% h shl 3
  h = h xor (h shr 11)
  h = h +% h shl 15
  result = h

#  copy(s: string, start = 0): string
#    {.extern: "copyStr", noDecl, noSideEffect.}
#  copy(s: string, start, len: int): string
#    {.extern: "copyStrLen", noDecl, noSideEffect.}
#
#  setLength(var s: string, newlen: int)
#    {.extern: "setLengthStr", noDecl, noSideEffect.}


proc copyStrLast(s: mstring, start, last: int): mstring {.exportc.} =
  var
    len: int
  if start >= s.len: return mnewString(0) # BUGFIX
  if last >= s.len:
    len = s.len - start # - 1 + 1
  else:
    len = last - start + 1
  result = rawNewString(len)
  result.len = len
  c_memcpy(result.data, addr(s.data[start]), len * sizeof(Char))
  result.data[len] = '\0'

proc copyStr(s: mstring, start: int): mstring {.exportc.} =
  return copyStrLast(s, start, s.len-1)

proc addChar(s: mstring, c: char): mstring {.compilerProc.} =
  result = s
  if result.len >= result.space:
    result.space = resize(result.space)
    result = cast[mstring](growObj(result,
      sizeof(TStringDesc) + result.space * sizeof(char)))
  result.data[result.len] = c
  result.data[result.len+1] = '\0'
  inc(result.len)

# These routines should be used like following:
#   <Nimrod code>
#   s &= "hallo " & name & " how do you feel?"
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
#   s = "hallo " & name & " how do you feel?"
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

proc resizeString(dest: mstring, addlen: int): mstring {.compilerproc.} =
  if dest.len + addLen + 1 <= dest.space: # BUGFIX: this is horrible!
    result = dest
  else: # slow path:
    var
      sp = max(resize(dest.space), dest.len + addLen + 1)
    result = cast[mstring](growObj(dest, sizeof(TStringDesc) + 
                           sp * sizeof(Char)))
    # DO NOT UPDATE LEN YET: dest.len = newLen
    result.space = sp

proc appendString(dest, src: mstring) {.compilerproc, inline.} =
  c_memcpy(addr(dest.data[dest.len]), src.data, (src.len + 1) * sizeof(Char))
  inc(dest.len, src.len)

proc appendChar(dest: mstring, c: char) {.compilerproc, inline.} =
  dest.data[dest.len] = c
  dest.data[dest.len+1] = '\0'
  inc(dest.len)

proc setLengthStr(s: mstring, newLen: int): mstring {.compilerProc.} =
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
  # this is needed for supporting the &= operator;
  #
  #  add seq x  generates:
  #  seq = incrSeq(seq, sizeof(x));
  #  seq[seq->len-1] = x;
  result = seq
  if result.len >= result.space:
    var
      s: TAddress
    result.space = resize(result.space)
    result = cast[PGenericSeq](growObj(result, elemSize * result.space + 
                               GenericSeqSize))
    # set new elements to zero:
    s = cast[TAddress](result)
    zeroMem(cast[pointer](s + GenericSeqSize + (result.len * elemSize)),
      (result.space - result.len) * elemSize)
    # for i in len .. space-1:
    #   seq->data[i] = 0
  inc(result.len)

proc setLengthSeq(seq: PGenericSeq, elemSize, newLen: int): PGenericSeq {.
    compilerProc.} =
  result = seq
  if result.space < newLen:
    var
      s: TAddress
    result.space = max(resize(result.space), newLen)
    result = cast[PGenericSeq](growObj(result, elemSize * result.space + 
                               GenericSeqSize))
    # set new elements to zero (needed for GC):
    s = cast[TAddress](result)
    zeroMem(cast[pointer](s + GenericSeqSize + (result.len * elemSize)),
      (result.space - result.len) * elemSize)
  # Else: We could decref references, if we had type information here :-(
  #       However, this does not happen often
  result.len = newLen

# --------------- other string routines ----------------------------------
proc `$`(x: int): string =
  result = newString(sizeof(x)*4)
  var i = 0
  var y = x
  while True:
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

{.push warnings: off.}
proc `$`(x: float): string =
  var buf: array [0..59, char]
  c_sprintf(buf, "%#g", x)
  return $buf
{.pop.}

proc `$`(x: int64): string =
  # we don't rely on C's runtime here as some C compiler's
  # int64 support is weak
  result = newString(sizeof(x)*4)
  var i = 0
  var y = x
  while True:
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

proc `$`(x: bool): string =
  if x: result = "true"
  else: result = "false"

proc `$`(x: char): string =
  result = newString(1)
  result[0] = x

proc `$`(x: string): string =
  # this is useful for generic code!
  return x


proc binaryStrSearch(x: openarray[string], y: string): int {.compilerproc.} =
  var
    a = 0
    b = len(x)
  while a < b:
     var mid = (a + b) div 2
     if x[mid] < y:
       a = mid + 1
     else:
       b = mid
  if (a < len(x)) and (x[a] == y):
    return a
  else:
    return -1
