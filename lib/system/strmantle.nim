#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Compilerprocs for strings that do not depend on the string implementation.

const digitsTable = "0001020304050607080910111213141516171819" &
    "2021222324252627282930313233343536373839" &
    "4041424344454647484950515253545556575859" &
    "6061626364656667686970717273747576777879" &
    "8081828384858687888990919293949596979899"
  # Inspired by https://engineering.fb.com/2013/03/15/developer-tools/three-optimization-tips-for-c
  # Generates:
  # .. code-block:: nim
  #   var res = ""
  #   for i in 0 .. 99:
  #     if i < 10:
  #       res.add "0" & $i
  #     else:
  #       res.add $i
  #   doAssert res == digitsTable


func digits10(num: uint64): int {.noinline.} =
  if num < 10'u64:
    result = 1
  elif num < 100'u64:
    result = 2
  elif num < 1_000'u64:
    result = 3
  elif num < 10_000'u64:
    result = 4
  elif num < 100_000'u64:
    result = 5
  elif num < 1_000_000'u64:
    result = 6
  elif num < 10_000_000'u64:
    result = 7
  elif num < 100_000_000'u64:
    result = 8
  elif num < 1_000_000_000'u64:
    result = 9
  elif num < 10_000_000_000'u64:
    result = 10
  elif num < 100_000_000_000'u64:
    result = 11
  elif num < 1_000_000_000_000'u64:
    result = 12
  else:
    result = 12 + digits10(num div 1_000_000_000_000'u64)

template numToString(result: var string, origin: uint64, length: int) =
  var num = origin
  var next = length - 1
  const nbatch = 100

  while num >= nbatch:
    let originNum = num
    num = num div nbatch
    let index = (originNum - num * nbatch) shl 1
    result[next] = digitsTable[index + 1]
    result[next - 1] = digitsTable[index]
    dec(next, 2)

  # process last 1-2 digits
  if num < 10:
    result[next] = chr(ord('0') + num)
  else:
    let index = num * 2
    result[next] = digitsTable[index + 1]
    result[next - 1] = digitsTable[index]

proc cmpStrings(a, b: string): int {.inline, compilerproc.} =
  let alen = a.len
  let blen = b.len
  let minlen = min(alen, blen)
  if minlen > 0:
    result = c_memcmp(unsafeAddr a[0], unsafeAddr b[0], cast[csize_t](minlen))
    if result == 0:
      result = alen - blen
  else:
    result = alen - blen

proc eqStrings(a, b: string): bool {.inline, compilerproc.} =
  let alen = a.len
  let blen = b.len
  if alen == blen:
    if alen == 0: return true
    return equalMem(unsafeAddr(a[0]), unsafeAddr(b[0]), alen)

proc hashString(s: string): int {.compilerproc.} =
  # the compiler needs exactly the same hash function!
  # this used to be used for efficient generation of string case statements
  var h : uint = 0
  for i in 0..len(s)-1:
    h = h + uint(s[i])
    h = h + h shl 10
    h = h xor (h shr 6)
  h = h + h shl 3
  h = h xor (h shr 11)
  h = h + h shl 15
  result = cast[int](h)

proc addInt*(result: var string; x: int64) =
  ## Converts integer to its string representation and appends it to `result`.
  ##
  ## .. code-block:: Nim
  ##   var
  ##     a = "123"
  ##     b = 45
  ##   a.addInt(b) # a <- "12345"
  let base = result.len
  var length: int
  var num: uint64

  if x < 0:
    if x == low(int64):
      num = uint64(x)
    else:
      num = uint64(-x)
    length = base + digits10(num) + 1
    setLen(result, length)
    result[base] = '-'
  else:
    num = uint64(x)
    length = base + digits10(num)
    setLen(result, length)
  numToString(result, num, length)

proc nimIntToStr(x: int): string {.compilerRtl.} =
  result = newStringOfCap(sizeof(x)*4)
  result.addInt x

proc addCstringN(result: var string, buf: cstring; buflen: int) =
  # no nimvm support needed, so it doesn't need to be fast here either
  let oldLen = result.len
  let newLen = oldLen + buflen
  result.setLen newLen
  copyMem(result[oldLen].addr, buf, buflen)

import formatfloat

proc addFloat*(result: var string; x: float) =
  ## Converts float to its string representation and appends it to `result`.
  ##
  ## .. code-block:: Nim
  ##   var
  ##     a = "123"
  ##     b = 45.67
  ##   a.addFloat(b) # a <- "12345.67"
  when nimvm:
    result.add $x
  else:
    var buffer {.noinit.}: array[65, char]
    let n = writeFloatToBuffer(buffer, x)
    result.addCstringN(cstring(buffer[0].addr), n)

proc nimFloatToStr(f: float): string {.compilerproc.} =
  result = newStringOfCap(8)
  result.addFloat f

proc c_strtod(buf: cstring, endptr: ptr cstring): float64 {.
  importc: "strtod", header: "<stdlib.h>", noSideEffect.}

const
  IdentChars = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
  powtens =  [1e0, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9,
              1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
              1e20, 1e21, 1e22]

when defined(nimHasInvariant):
  {.push staticBoundChecks: off.}

proc nimParseBiggestFloat(s: string, number: var BiggestFloat,
                          start = 0): int {.compilerproc.} =
  # This routine attempt to parse float that can parsed quickly.
  # i.e. whose integer part can fit inside a 53bits integer.
  # their real exponent must also be <= 22. If the float doesn't follow
  # these restrictions, transform the float into this form:
  #  INTEGER * 10 ^ exponent and leave the work to standard `strtod()`.
  # This avoid the problems of decimal character portability.
  # see: http://www.exploringbinary.com/fast-path-decimal-to-floating-point-conversion/
  var
    i = start
    sign = 1.0
    kdigits, fdigits = 0
    exponent = 0
    integer = uint64(0)
    fracExponent = 0
    expSign = 1
    firstDigit = -1
    hasSign = false

  # Sign?
  if i < s.len and (s[i] == '+' or s[i] == '-'):
    hasSign = true
    if s[i] == '-':
      sign = -1.0
    inc(i)

  # NaN?
  if i+2 < s.len and (s[i] == 'N' or s[i] == 'n'):
    if s[i+1] == 'A' or s[i+1] == 'a':
      if s[i+2] == 'N' or s[i+2] == 'n':
        if i+3 >= s.len or s[i+3] notin IdentChars:
          number = NaN
          return i+3 - start
    return 0

  # Inf?
  if i+2 < s.len and (s[i] == 'I' or s[i] == 'i'):
    if s[i+1] == 'N' or s[i+1] == 'n':
      if s[i+2] == 'F' or s[i+2] == 'f':
        if i+3 >= s.len or s[i+3] notin IdentChars:
          number = Inf*sign
          return i+3 - start
    return 0

  if i < s.len and s[i] in {'0'..'9'}:
    firstDigit = (s[i].ord - '0'.ord)
  # Integer part?
  while i < s.len and s[i] in {'0'..'9'}:
    inc(kdigits)
    integer = integer * 10'u64 + (s[i].ord - '0'.ord).uint64
    inc(i)
    while i < s.len and s[i] == '_': inc(i)

  # Fractional part?
  if i < s.len and s[i] == '.':
    inc(i)
    # if no integer part, Skip leading zeros
    if kdigits <= 0:
      while i < s.len and s[i] == '0':
        inc(fracExponent)
        inc(i)
        while i < s.len and s[i] == '_': inc(i)

    if firstDigit == -1 and i < s.len and s[i] in {'0'..'9'}:
      firstDigit = (s[i].ord - '0'.ord)
    # get fractional part
    while i < s.len and s[i] in {'0'..'9'}:
      inc(fdigits)
      inc(fracExponent)
      integer = integer * 10'u64 + (s[i].ord - '0'.ord).uint64
      inc(i)
      while i < s.len and s[i] == '_': inc(i)

  # if has no digits: return error
  if kdigits + fdigits <= 0 and
     (i == start or # no char consumed (empty string).
     (i == start + 1 and hasSign)): # or only '+' or '-
    return 0

  if i+1 < s.len and s[i] in {'e', 'E'}:
    inc(i)
    if s[i] == '+' or s[i] == '-':
      if s[i] == '-':
        expSign = -1

      inc(i)
    if s[i] notin {'0'..'9'}:
      return 0
    while i < s.len and s[i] in {'0'..'9'}:
      exponent = exponent * 10 + (ord(s[i]) - ord('0'))
      inc(i)
      while i < s.len and s[i] == '_': inc(i) # underscores are allowed and ignored

  var realExponent = expSign*exponent - fracExponent
  let expNegative = realExponent < 0
  var absExponent = abs(realExponent)

  # if exponent greater than can be represented: +/- zero or infinity
  if absExponent > 999:
    if expNegative:
      number = 0.0*sign
    else:
      number = Inf*sign
    return i - start

  # if integer is representable in 53 bits:  fast path
  # max fast path integer is  1<<53 - 1 or  8999999999999999 (16 digits)
  let digits = kdigits + fdigits
  if digits <= 15 or (digits <= 16 and firstDigit <= 8):
    # max float power of ten with set bits above the 53th bit is 10^22
    if absExponent <= 22:
      if expNegative:
        number = sign * integer.float / powtens[absExponent]
      else:
        number = sign * integer.float * powtens[absExponent]
      return i - start

    # if exponent is greater try to fit extra exponent above 22 by multiplying
    # integer part is there is space left.
    let slop = 15 - kdigits - fdigits
    if absExponent <= 22 + slop and not expNegative:
      number = sign * integer.float * powtens[slop] * powtens[absExponent-slop]
      return i - start

  # if failed: slow path with strtod.
  var t: array[500, char] # flaviu says: 325 is the longest reasonable literal
  var ti = 0
  let maxlen = t.high - "e+000".len # reserve enough space for exponent

  result = i - start
  i = start
  # re-parse without error checking, any error should be handled by the code above.
  if i < s.len and s[i] == '.': i.inc
  while i < s.len and s[i] in {'0'..'9','+','-'}:
    if ti < maxlen:
      t[ti] = s[i]; inc(ti)
    inc(i)
    while i < s.len and s[i] in {'.', '_'}: # skip underscore and decimal point
      inc(i)

  # insert exponent
  t[ti] = 'E'
  inc(ti)
  t[ti] = if expNegative: '-' else: '+'
  inc(ti, 4)

  # insert adjusted exponent
  t[ti-1] = ('0'.ord + absExponent mod 10).char
  absExponent = absExponent div 10
  t[ti-2] = ('0'.ord + absExponent mod 10).char
  absExponent = absExponent div 10
  t[ti-3] = ('0'.ord + absExponent mod 10).char
  number = c_strtod(addr t, nil)

when defined(nimHasInvariant):
  {.pop.} # staticBoundChecks

proc nimInt64ToStr(x: int64): string {.compilerRtl.} =
  result = newStringOfCap(sizeof(x)*4)
  result.addInt x

proc nimBoolToStr(x: bool): string {.compilerRtl.} =
  return if x: "true" else: "false"

proc nimCharToStr(x: char): string {.compilerRtl.} =
  result = newString(1)
  result[0] = x

when defined(gcDestructors):
  proc GC_getStatistics*(): string =
    result = "[GC] total memory: "
    result.addInt getTotalMem()
    result.add "\n[GC] occupied memory: "
    result.addInt getOccupiedMem()
    result.add '\n'
    #"[GC] cycle collections: " & $gch.stat.cycleCollections & "\n" &
