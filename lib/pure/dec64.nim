#
#
#            Nim's Runtime Library
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements `Dec64`, Douglas Crockford's 64-bit decimal
## floating-point number type named DEC64.
##
## Dec64 is distinct from the IEEE 754-2008 decimal types (e.g. decimal128).
##
## A `Dec64` value is a 64-bit word whose upper 56 bits are a signed
## two's-complement coefficient and whose lower 8 bits are a signed
## two's-complement exponent. Its value is `coefficient * 10^exponent`.
## The exponent byte ``-128`` is reserved for `nan`. Zero has 255
## valid representations and they all compare equal.
##
## See https://www.crockford.com/dec64.html for the full specification
## and https://github.com/douglascrockford/DEC64 for hardware-tuned
## reference implementations of the elementary operations.
##
## Dec64 is intended for application code that works with money or
## other human-facing measurements: it avoids the binary-rounding
## surprises of IEEE-754 floats while keeping a single fixed 64-bit
## footprint.

runnableExamples:
  let a = dec64(1, -1)        # 1e-1 = 0.1
  let b = 0.2'dec
  let sum = a + b
  assert sum == 0.3'dec
  assert $sum == "0.3"
  assert sum - a == b
  assert $(a + 2) == "2.1"     # integer add
  assert (dec64(1) / dec64(3)).coefficient == 3_333_333_333_333_333'i64
  assert isNaN(dec64(1) / dec64(0))
  assert dec64(0, 5) == dec64(0, -3)        # all zeros are equal

  assert 47.11e2'dec == dec64(4700) + 11

import std/hashes
import std/formatfloat
from std/math import pow
when defined(nimPreviewSlimSystem):
  import std/assertions

type Dec64* = distinct int64
  ## Decimal floating-point: 56-bit coefficient, 8-bit exponent.

const
  coeffMax* = 36_028_797_018_963_967'i64    ## Largest representable coefficient (`2^55 - 1`).
  coeffMin* = -36_028_797_018_963_968'i64   ## Smallest representable coefficient (`-2^55`).
  expMax* = 127                              ## Largest representable exponent.
  expMin* = -127                             ## Smallest non-NaN exponent.

const expNaN = -128

# -- low-level pack / unpack --------------------------------------------------

func packRaw(c: int64, e: int): Dec64 {.inline.} =
  let bits = (cast[uint64](c) shl 8) or (cast[uint64](e.int8) and 0xFF'u64)
  Dec64(cast[int64](bits))

func coefficient*(x: Dec64): int64 {.inline.} =
  ## The signed 56-bit coefficient.
  ashr(x.int64, 8)

func exponent*(x: Dec64): int {.inline.} =
  ## The signed 8-bit exponent. Returns `-128` for `nan`.
  cast[int8](x.int64 and 0xFF).int

func isNaN*(x: Dec64): bool {.inline.} =
  ## True iff `x` is `nan`.
  (x.int64 and 0xFF) == 0x80

func isZero*(x: Dec64): bool {.inline.} =
  ## True iff `x` represents zero (any of its 255 representations).
  (x.int64 and 0xFF) != 0x80 and ashr(x.int64, 8) == 0

const
  nan* = Dec64(0x80'i64)
    ## Not-a-Number. Returned by any operation whose result is undefined or
    ## not representable.
  zero* = Dec64(0'i64)
    ## The canonical zero (coefficient 0, exponent 0).
  one* = packRaw(1, 0)
    ## The value 1.

# -- canonical form ----------------------------------------------------------

func canonical(c: int64, e: int): Dec64 {.inline.} =
  # Strip trailing-zero coefficient digits while the exponent has room.
  # Equal values then have identical bit patterns, which makes `==` and `hash`
  # trivial and keeps zero unique.
  if c == 0:
    return zero
  var ci = c
  var ei = e
  while ei < expMax and ci mod 10 == 0:
    ci = ci div 10
    inc ei
  packRaw(ci, ei)

# -- construction ------------------------------------------------------------

func dec64*(coefficient: int64, exponent: int = 0): Dec64 =
  ## Construct a `Dec64` from a coefficient and exponent. Returns `nan` if
  ## the value cannot be represented even after normalization.
  if exponent == expNaN:
    return nan
  if coefficient == 0:
    return zero
  var c = coefficient
  var e = exponent
  # Bring exponent up by multiplying coefficient if exponent is too high.
  while e > expMax:
    if c > coeffMax div 10 or c < coeffMin div 10:
      return nan
    c *= 10
    dec e
  # Bring coefficient into range by dividing (with half-away-from-zero rounding).
  while c > coeffMax or c < coeffMin:
    let r = c mod 10
    c = c div 10
    if r >= 5: inc c
    elif r <= -5: dec c
    inc e
    if e > expMax:
      return nan
  # Bring exponent up to expMin by dropping low-order coefficient digits.
  while e < expMin:
    if c == 0: return zero
    let r = c mod 10
    c = c div 10
    if r >= 5: inc c
    elif r <= -5: dec c
    inc e
  canonical(c, e)

func parse*(s: string): Dec64

func dec64*(f: float): Dec64 =
  ## Construct a `Dec64` from a binary float, going through the float's
  ## decimal string form to avoid binary rounding artefacts. Be aware that
  ## `dec64(0.1)` round-trips to a value whose printed form is `"0.1"`,
  ## but the underlying float was already an approximation.
  if f != f: return nan                      # IEEE NaN
  if f == Inf or f == -Inf: return nan
  if f == 0.0: return zero
  parse($f)

# -- predicates ---------------------------------------------------------------

func isInteger*(x: Dec64): bool {.inline.} =
  ## True iff `x` is a finite integer (its exponent is non-negative or
  ## the fractional part is exactly zero).
  if isNaN(x): return false
  let e = x.exponent
  if e >= 0: return true
  var c = x.coefficient
  var n = -e
  while n > 0:
    if c mod 10 != 0: return false
    c = c div 10
    dec n
  true

# -- equality and hash --------------------------------------------------------

func `==`*(a, b: Dec64): bool {.inline.} =
  ## Equality. `nan == nan` returns `true`, following Crockford's spec.
  if isNaN(a) or isNaN(b):
    return isNaN(a) and isNaN(b)
  # All values flow through `canonical`, so equal values share their bits.
  # Plus zero's many representations are flattened to the canonical zero.
  if isZero(a) and isZero(b): return true
  a.int64 == b.int64

func hash*(x: Dec64): Hash {.inline.} =
  ## Hash compatible with `==`.
  if isNaN(x): hash(0x80'i64)
  elif isZero(x): hash(0'i64)
  else: hash(x.int64)

# -- ordering ----------------------------------------------------------------

func cmpAbs(a, b: Dec64): int =
  # Compare |a| against |b|. Inputs must not be NaN.
  let ca = a.coefficient
  let cb = b.coefficient
  let ua = if ca < 0: -ca else: ca
  let ub = if cb < 0: -cb else: cb
  if ua == 0: return (if ub == 0: 0 else: -1)
  if ub == 0: return 1
  let ea = a.exponent
  let eb = b.exponent
  var sa = ua
  var sb = ub
  var ediff: int
  if ea > eb:
    ediff = ea - eb
    while ediff > 0:
      if sa > 922_337_203_685_477_580'i64: return 1
      sa *= 10
      dec ediff
  elif eb > ea:
    ediff = eb - ea
    while ediff > 0:
      if sb > 922_337_203_685_477_580'i64: return -1
      sb *= 10
      dec ediff
  if sa < sb: -1
  elif sa > sb: 1
  else: 0

func `<`*(a, b: Dec64): bool =
  ## Strict less-than. Comparing with `nan` always returns `false`.
  if isNaN(a) or isNaN(b): return false
  let ca = a.coefficient
  let cb = b.coefficient
  if ca == 0 and cb == 0: return false
  let aSign = if ca < 0: -1 elif ca > 0: 1 else: 0
  let bSign = if cb < 0: -1 elif cb > 0: 1 else: 0
  if aSign != bSign: return aSign < bSign
  # same sign and both non-zero (or one zero with same sign of zero handled above)
  let ord = cmpAbs(a, b)
  if aSign > 0: ord < 0
  else: ord > 0

func `<=`*(a, b: Dec64): bool {.inline.} =
  if isNaN(a) or isNaN(b): return false
  a == b or a < b

func `>`*(a, b: Dec64): bool {.inline.} = b < a
func `>=`*(a, b: Dec64): bool {.inline.} = b <= a

func cmp*(a, b: Dec64): int =
  ## Three-way comparison. NaN sorts after every finite value (and equals
  ## itself), which makes `cmp` total and useable with `algorithm.sort`.
  if isNaN(a):
    return (if isNaN(b): 0 else: 1)
  if isNaN(b): return -1
  if a == b: 0
  elif a < b: -1
  else: 1

# -- negation -----------------------------------------------------------------

func `-`*(x: Dec64): Dec64 =
  ## Unary negation. Returns `nan` if `x` is `nan`. Negating the very
  ## smallest coefficient triggers a renormalization (it does not fit when
  ## negated) but the value itself round-trips.
  if isNaN(x): return nan
  dec64(-x.coefficient, x.exponent)

# -- addition / subtraction --------------------------------------------------

# Equal-zero-exponent fast path. When both operands have an exponent byte of
# zero (i.e., both are integer-form Dec64 values) and the int64 sum does not
# overflow, the bitwise int64 add IS the correct Dec64 result. The Crockford
# spec gives short verbatim assembly snippets for x64, ARM64, and RISC-V64
# implementing exactly this branch; we use them here under the right toolchain
# and fall back to a pure-Nim equivalent on every other platform. Define
# `-d:nimDec64NoAsm` to force the pure-Nim path even on supported targets
# (used by the test suite to verify both produce identical results).

when not defined(nimDec64NoAsm) and not defined(js):
  when defined(amd64) and (defined(gcc) or defined(clang)):
    {.emit: """
/* Crockford's Dec64 fast-path addition (x64), verbatim from
   https://www.crockford.com/dec64.html:
     mov cl, al
     or  cl, dl
     jnz slow_path
     add rax, rdx
     jo  overflow
   `ok_out` is set to 1 on the fast path and 0 on the slow path.        */
N_LIB_PRIVATE NI64 nim_dec64_addFastX64(NI64 a_in, NI64 b_in, NI8* ok_out) {
    NI64 r = a_in;
    int ok;
    __asm__ (
      "movb %%al, %%cl\n\t"
      "orb  %%dl, %%cl\n\t"
      "movl $1, %k1\n\t"
      "jne  1f\n\t"
      "addq %%rdx, %%rax\n\t"
      "jno  2f\n\t"
      "1: movl $0, %k1\n\t"
      "2:\n\t"
      : "+a"(r), "=&r"(ok)
      : "d"(b_in)
      : "cc", "%rcx"
    );
    *ok_out = (NI8)ok;
    return r;
}
""".}
    proc nim_dec64_addFastX64(a, b: int64, ok: var int8): int64
      {.importc: "nim_dec64_addFastX64".}

    func addFastAsm(a, b: int64): tuple[r: int64, ok: bool] {.inline.} =
      var okByte: int8 = 0
      let r = nim_dec64_addFastX64(a, b, okByte)
      (r, okByte != 0)

  elif defined(arm64) and (defined(gcc) or defined(clang)):
    {.emit: """
/* Crockford's Dec64 fast-path addition (ARM64), verbatim from
   https://www.crockford.com/dec64.html:
     orr  x2, x0, x1
     ands xzr, x2, #255
     b.ne slow_path
     adds x0, x0, x1
     b.vs overflow                                                     */
N_LIB_PRIVATE NI64 nim_dec64_addFastArm64(NI64 a_in, NI64 b_in, NI8* ok_out) {
    NI64 r = a_in;
    int ok;
    __asm__ (
      "orr  x2, %2, %3\n\t"
      "ands xzr, x2, #255\n\t"
      "mov  %w1, #1\n\t"
      "b.ne 1f\n\t"
      "adds %0, %2, %3\n\t"
      "b.vs 1f\n\t"
      "b 2f\n\t"
      "1: mov %w1, #0\n\t"
      "   mov %0, %2\n\t"
      "2:\n\t"
      : "=&r"(r), "=&r"(ok)
      : "r"(a_in), "r"(b_in)
      : "x2", "cc"
    );
    *ok_out = (NI8)ok;
    return r;
}
""".}
    proc nim_dec64_addFastArm64(a, b: int64, ok: var int8): int64
      {.importc: "nim_dec64_addFastArm64".}

    func addFastAsm(a, b: int64): tuple[r: int64, ok: bool] {.inline.} =
      var okByte: int8 = 0
      let r = nim_dec64_addFastArm64(a, b, okByte)
      (r, okByte != 0)

func addFastIntegers(a, b: int64): tuple[r: int64, ok: bool] {.inline.} =
  ## Equal-zero-exponent fast path. Mirrors Crockford's asm: succeeds iff
  ## both operands have a zero exponent byte and the int64 sum does not
  ## overflow.
  when declared(addFastAsm):
    addFastAsm(a, b)
  else:
    if ((a or b) and 0xFF) != 0:
      return (0'i64, false)
    let r = cast[int64](cast[uint64](a) + cast[uint64](b))
    if (a xor r) < 0 and (b xor r) < 0:
      return (0'i64, false)
    (r, true)

func addImpl(a, b: Dec64): Dec64 =
  if isNaN(a) or isNaN(b): return nan
  let ca = a.coefficient
  let cb = b.coefficient
  if ca == 0: return b
  if cb == 0: return a
  let ea = a.exponent
  let eb = b.exponent
  if ea == eb:
    # Sum of two 56-bit signed values fits in int64 (their magnitudes are
    # at most 2 * coeffMax < 2^57).
    return dec64(ca + cb, ea)
  # Bring the larger-exponent operand down to the smaller exponent so the
  # smaller operand keeps full precision. If multiplying its coefficient by
  # 10 would overflow int64, fall back to scaling the smaller operand's
  # coefficient down (precision loss on the term that is much smaller).
  var c1 = ca; var c2 = cb; var e1 = ea; var e2 = eb
  if e1 > e2:
    swap(c1, c2); swap(e1, e2)
  # invariant: e1 < e2.
  var diff = e2 - e1
  var scaled = c2
  var fits = true
  for _ in 0 ..< diff:
    if scaled > 922_337_203_685_477_580'i64 or
       scaled < -922_337_203_685_477_580'i64:
      fits = false
      break
    scaled *= 10
  if fits:
    return dec64(c1 + scaled, e1)
  # Fallback: scale c1 down to e2 (lose precision on the small term).
  for _ in 0 ..< diff:
    c1 = c1 div 10
  dec64(c1 + c2, e2)

func `+`*(a, b: Dec64): Dec64 {.inline.} =
  ## Addition.
  let (r, ok) = addFastIntegers(a.int64, b.int64)
  if ok: Dec64(r)
  else: addImpl(a, b)

func `-`*(a, b: Dec64): Dec64 {.inline.} =
  ## Subtraction.
  addImpl(a, -b)

# -- 128-bit helpers (for multiply and divide) -------------------------------

type Uint128 = tuple[hi, lo: uint64]

func umul64(a, b: uint64): Uint128 =
  let aLo = a and 0xFFFF_FFFF'u64
  let aHi = a shr 32
  let bLo = b and 0xFFFF_FFFF'u64
  let bHi = b shr 32
  let p00 = aLo * bLo
  let p01 = aLo * bHi
  let p10 = aHi * bLo
  let p11 = aHi * bHi
  let mid = (p00 shr 32) + (p01 and 0xFFFF_FFFF'u64) + (p10 and 0xFFFF_FFFF'u64)
  let lo = (p00 and 0xFFFF_FFFF'u64) or (mid shl 32)
  let hi = p11 + (p01 shr 32) + (p10 shr 32) + (mid shr 32)
  (hi, lo)

func mul128By10(x: Uint128): Uint128 =
  let (chi, clo) = umul64(x.lo, 10'u64)
  (x.hi * 10 + chi, clo)

func div128_10(x: Uint128): tuple[q: Uint128, r: uint32] =
  # Divide a 128-bit unsigned value by 10. Treat as four 32-bit limbs.
  var rem: uint64 = 0
  var qhh, qhl, qlh, qll: uint64
  let limbs = [(x.hi shr 32), x.hi and 0xFFFF_FFFF'u64,
               (x.lo shr 32), x.lo and 0xFFFF_FFFF'u64]
  var qs: array[4, uint64]
  for i in 0 ..< 4:
    let v = (rem shl 32) or limbs[i]
    qs[i] = v div 10
    rem = v mod 10
  qhh = qs[0]; qhl = qs[1]; qlh = qs[2]; qll = qs[3]
  let qhi = (qhh shl 32) or qhl
  let qlo = (qlh shl 32) or qll
  ((qhi, qlo), rem.uint32)

func div128_64(num: Uint128, d: uint64): uint64 =
  # 128-bit / 64-bit division returning the low 64 bits of the quotient.
  # Assumes the true quotient fits in 64 bits (i.e., num.hi < d).
  assert num.hi < d, "div128_64 quotient overflow"
  var rem = num.hi
  var lo = num.lo
  var quo: uint64 = 0
  for _ in 0 ..< 64:
    let topL = lo shr 63
    rem = (rem shl 1) or topL
    lo = lo shl 1
    quo = quo shl 1
    if rem >= d:
      rem -= d
      quo = quo or 1
  quo

# -- multiplication ----------------------------------------------------------

func `*`*(a, b: Dec64): Dec64 =
  ## Multiplication.
  if isNaN(a) or isNaN(b): return nan
  let ca = a.coefficient
  let cb = b.coefficient
  if ca == 0 or cb == 0: return zero
  let neg = (ca < 0) != (cb < 0)
  let ua = if ca < 0: uint64(-ca) else: uint64(ca)
  let ub = if cb < 0: uint64(-cb) else: uint64(cb)
  var prod = umul64(ua, ub)
  var e = a.exponent + b.exponent
  # Reduce until the magnitude fits in 56 bits.
  while prod.hi != 0 or prod.lo > uint64(coeffMax):
    let (q, r) = div128_10(prod)
    prod = q
    inc e
    if e > expMax: return nan
    # half-away-from-zero rounding when the next reduction would change the
    # bottom digit's parity. Crockford's reference rounds to nearest-even;
    # we use nearest-away which differs only for exact-half cases.
    if r >= 5'u32 and (prod.hi != 0 or prod.lo < uint64(coeffMax)):
      prod.lo += 1
  var c = prod.lo.int64
  if neg: c = -c
  dec64(c, e)

# -- division ----------------------------------------------------------------

func `/`*(a, b: Dec64): Dec64 =
  ## Division. Division by zero returns `nan`.
  if isNaN(a) or isNaN(b): return nan
  if isZero(b): return nan
  if isZero(a): return zero
  let ca = a.coefficient
  let cb = b.coefficient
  let neg = (ca < 0) != (cb < 0)
  let ua = if ca < 0: uint64(-ca) else: uint64(ca)
  let ub = if cb < 0: uint64(-cb) else: uint64(cb)
  # Scale dividend up by 10 as far as possible while keeping the eventual
  # 128/64 quotient inside uint64. Cap at 16 extra digits, which is the
  # most that can be precisely held in a 56-bit coefficient.
  var num: Uint128 = (0'u64, ua)
  var k = 0
  while k < 16:
    let next = mul128By10(num)
    if next.hi >= ub: break
    num = next
    inc k
  var q = div128_64(num, ub)
  var e = a.exponent - b.exponent - k
  # Normalize: if the quotient does not fit in Dec64's signed 56-bit
  # coefficient range, drop the lowest digit (with rounding) and bump the
  # exponent. We must do this before casting to int64, otherwise a quotient
  # > int64.high silently wraps to a negative value.
  while q > uint64(coeffMax):
    let r = q mod 10
    q = q div 10
    if r >= 5'u64: q += 1
    inc e
  var c = q.int64
  if neg: c = -c
  dec64(c, e)

# -- compound assignments ----------------------------------------------------

func `+=`*(a: var Dec64, b: Dec64) {.inline.} = a = a + b
func `-=`*(a: var Dec64, b: Dec64) {.inline.} = a = a - b
func `*=`*(a: var Dec64, b: Dec64) {.inline.} = a = a * b
func `/=`*(a: var Dec64, b: Dec64) {.inline.} = a = a / b

# -- string output -----------------------------------------------------------

func addNTimes(s: var string, c: char, n: int) {.inline.} =
  for _ in 0 ..< n: s.add c

func `$`*(x: Dec64): string =
  ## Decimal string. NaN prints `"nan"`. Output uses plain decimal notation
  ## (no scientific form) so very large or very small magnitudes can yield
  ## long strings.
  if isNaN(x): return "nan"
  if isZero(x): return "0"
  let c = x.coefficient
  let e = x.exponent
  let neg = c < 0
  let mag = if neg: -c else: c
  let digits = $mag
  let nd = digits.len
  result = ""
  if neg: result.add '-'
  if e >= 0:
    result.add digits
    addNTimes(result, '0', e)
  else:
    let dp = -e
    if dp >= nd:
      result.add "0."
      addNTimes(result, '0', dp - nd)
      result.add digits
    else:
      result.add digits.substr(0, nd - dp - 1)
      result.add '.'
      result.add digits.substr(nd - dp, nd - 1)

# -- string parse ------------------------------------------------------------

func tryParse*(s: string, dst: var Dec64): bool =
  ## Parse a decimal literal (`[-+]?digits(.digits)?(e[-+]?digits)?` or
  ## `nan` / `NaN`). Returns `false` and leaves `dst` unchanged on a
  ## malformed input.
  if s.len == 0: return false
  if s == "nan" or s == "NaN" or s == "NAN":
    dst = nan
    return true
  var i = 0
  var neg = false
  case s[i]
  of '-':
    neg = true
    inc i
  of '+':
    inc i
  else: discard
  if i >= s.len: return false
  var coeff: int64 = 0
  var fracDigits = 0
  var trailingShift = 0
  var seenDigit = false
  var inFrac = false
  var sawE = false
  while i < s.len:
    let ch = s[i]
    case ch
    of '0'..'9':
      seenDigit = true
      let d = (ch.ord - '0'.ord).int64
      if coeff <= (high(int64) - d) div 10:
        coeff = coeff * 10 + d
        if inFrac: inc fracDigits
      else:
        # Coefficient is full. Drop further fractional digits; integer
        # digits push the exponent up.
        if not inFrac: inc trailingShift
      inc i
    of '.':
      if inFrac: return false
      inFrac = true
      inc i
    of 'e', 'E':
      sawE = true
      inc i
      break
    else:
      return false
  if not seenDigit: return false
  var expSign = 1
  var expVal = 0
  if sawE:
    if i < s.len and s[i] == '+': inc i
    elif i < s.len and s[i] == '-':
      expSign = -1
      inc i
    var seenExpDigit = false
    while i < s.len and s[i] in '0'..'9':
      let d = s[i].ord - '0'.ord
      expVal = expVal * 10 + d
      if expVal > 4096:    # absurd; spec exponent maxes at 127
        expVal = 4096
      seenExpDigit = true
      inc i
    if not seenExpDigit: return false
  if i < s.len: return false
  let signedCoeff = if neg: -coeff else: coeff
  let finalExp = expSign * expVal - fracDigits + trailingShift
  dst = dec64(signedCoeff, finalExp)
  return true

func parse*(s: string): Dec64 =
  ## Parse a decimal literal. Returns `nan` on malformed input.
  if not tryParse(s, result): result = nan

# -- custom literal ----------------------------------------------------------

func `'dec`*(num: string): Dec64 {.inline.} =
  ## Custom literal suffix for `Dec64`. Accepts the same syntax as `parse`,
  ## so integer, decimal, and scientific forms all work. The single-letter
  ## `'d` is taken by the built-in float64 suffix, so Dec64 uses `'dec`:
  ##
  ## ```nim
  ## let a = 1.25'dec
  ## let b = 100'dec
  ## let c = 7e-2'dec        # 0.07
  ## ```
  parse(num)

# Overloads for mixed (Dec64, int) operators
# This make `price * 2`, `1 + rate`, and `x < 100` work without wrapping every integer literal.
# Float operands are intentionally not supported — mixing binary floats with Dec64 in an
# expression hides the precision boundary.

func `+`*(a: Dec64, b: int): Dec64 {.inline.} = a + dec64(b)
func `+`*(a: int, b: Dec64): Dec64 {.inline.} = dec64(a) + b
func `-`*(a: Dec64, b: int): Dec64 {.inline.} = a - dec64(b)
func `-`*(a: int, b: Dec64): Dec64 {.inline.} = dec64(a) - b
func `*`*(a: Dec64, b: int): Dec64 {.inline.} = a * dec64(b)
func `*`*(a: int, b: Dec64): Dec64 {.inline.} = dec64(a) * b
func `/`*(a: Dec64, b: int): Dec64 {.inline.} = a / dec64(b)
func `/`*(a: int, b: Dec64): Dec64 {.inline.} = dec64(a) / b

func `==`*(a: Dec64, b: int): bool {.inline.} = a == dec64(b)
func `==`*(a: int, b: Dec64): bool {.inline.} = dec64(a) == b
func `<`*(a: Dec64, b: int): bool {.inline.} = a < dec64(b)
func `<`*(a: int, b: Dec64): bool {.inline.} = dec64(a) < b
func `<=`*(a: Dec64, b: int): bool {.inline.} = a <= dec64(b)
func `<=`*(a: int, b: Dec64): bool {.inline.} = dec64(a) <= b
func `>`*(a: Dec64, b: int): bool {.inline.} = a > dec64(b)
func `>`*(a: int, b: Dec64): bool {.inline.} = dec64(a) > b
func `>=`*(a: Dec64, b: int): bool {.inline.} = a >= dec64(b)
func `>=`*(a: int, b: Dec64): bool {.inline.} = dec64(a) >= b

# -- conversion to float -----------------------------------------------------

func toFloat*(x: Dec64): float =
  ## Convert `x` to `float64`. NaN inputs produce IEEE NaN. Result precision
  ## is ~15 decimal digits (one fewer than Dec64's native ~16.8). Out-of-range
  ## values can saturate to `Inf` only past `expMax`, beyond Dec64's own range.
  if isNaN(x): return 0.0 / 0.0
  if isZero(x): return 0.0
  let c = x.coefficient.float
  let e = x.exponent
  if e >= 0: c * pow(10.0, e.float)
  else:      c / pow(10.0, (-e).float)

# -- decimal-native rounding and sign ---------------------------------------

func abs*(x: Dec64): Dec64 =
  ## Absolute value. `abs(nan) == nan`.
  if isNaN(x): nan
  elif x.coefficient < 0: -x
  else: x

func floor*(x: Dec64): Dec64 =
  ## Largest integer `<= x`, exact in decimal.
  if isNaN(x) or isZero(x): return x
  let e = x.exponent
  if e >= 0: return x
  var c = x.coefficient
  var n = -e
  let neg = c < 0
  while n > 0:
    let r = c mod 10
    c = c div 10
    if neg and r != 0: dec c     # truncate toward -inf, not toward 0
    dec n
  dec64(c, 0)

func ceil*(x: Dec64): Dec64 =
  ## Smallest integer `>= x`.
  -floor(-x)

func trunc*(x: Dec64): Dec64 =
  ## Round toward zero.
  if isNaN(x): return nan
  if x.coefficient < 0: ceil(x) else: floor(x)

func round*(x: Dec64): Dec64 =
  ## Round to nearest integer; ties round away from zero (`round(0.5) == 1`,
  ## `round(-0.5) == -1`).
  if isNaN(x) or isZero(x): return x
  let half = packRaw(5, -1)            # 0.5
  if x.coefficient < 0: ceil(x - half) else: floor(x + half)

func sign*(x: Dec64): int =
  ## `-1`, `0`, or `1`. NaN returns `0`.
  if isNaN(x): 0
  elif x.coefficient > 0: 1
  elif x.coefficient < 0: -1
  else: 0

# -- integer-exponent power (exact, no float trip) ---------------------------

func pow*(x: Dec64, n: int): Dec64 =
  ## Integer-exponent power, evaluated by repeated squaring. Stays in Dec64
  ## throughout, so values like `pow(1.05'dec, 30)` retain Dec64 precision
  ## end-to-end (no binary detour). For fractional exponents see
  ## `dec64math.pow(Dec64, Dec64)`.
  if isNaN(x): return nan
  if n == 0: return one
  if n < 0: return one / pow(x, -n)
  var r = one
  var base = x
  var k = n
  while k > 0:
    if (k and 1) == 1: r = r * base
    k = k shr 1
    if k > 0: base = base * base
  r
