#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements efficient computations of hash values for diverse
## Nim types. All the procs are based on these two building blocks:
## - `!& proc <#!&,Hash,int>`_ used to start or mix a hash value, and
## - `!$ proc <#!$,Hash>`_ used to *finish* the hash value.
##
## If you want to implement hash procs for your custom types,
## you will end up writing the following kind of skeleton of code:
##
## .. code-block:: Nim
##  proc hash(x: Something): Hash =
##    ## Computes a Hash from `x`.
##    var h: Hash = 0
##    # Iterate over parts of `x`.
##    for xAtom in x:
##      # Mix the atom with the partial hash.
##      h = h !& xAtom
##    # Finish the hash.
##    result = !$h
##
## If your custom types contain fields for which there already is a hash proc,
## like for example objects made up of ``strings``, you can simply hash
## together the hash value of the individual fields:
##
## .. code-block:: Nim
##  proc hash(x: Something): Hash =
##    ## Computes a Hash from `x`.
##    var h: Hash = 0
##    h = h !& hash(x.foo)
##    h = h !& hash(x.bar)
##    result = !$h
##
## **See also:**
## * `md5 module <md5.html>`_ for MD5 checksum algorithm
## * `base64 module <base64.html>`_ for a base64 encoder and decoder
## * `std/sha1 module <sha1.html>`_ for a sha1 encoder and decoder
## * `tables module <tables.html>`_ for hash tables

import std/private/since

type
  Hash* = int ## A hash value. Hash tables using these values should
               ## always have a size of a power of two and can use the ``and``
               ## operator instead of ``mod`` for truncation of the hash value.

proc `!&`*(h: Hash, val: int): Hash {.inline.} =
  ## Mixes a hash value `h` with `val` to produce a new hash value.
  ##
  ## This is only needed if you need to implement a hash proc for a new datatype.
  let h = cast[uint](h)
  let val = cast[uint](val)
  var res = h + val
  res = res + res shl 10
  res = res xor (res shr 6)
  result = cast[Hash](res)

proc `!$`*(h: Hash): Hash {.inline.} =
  ## Finishes the computation of the hash value.
  ##
  ## This is only needed if you need to implement a hash proc for a new datatype.
  let h = cast[uint](h) # Hash is practically unsigned.
  var res = h + h shl 3
  res = res xor (res shr 11)
  res = res + res shl 15
  result = cast[Hash](res)

proc hiXorLoFallback64(a, b: uint64): uint64 {.inline.} =
  let # Fall back in 64-bit arithmetic
    aH = a shr 32
    aL = a and 0xFFFFFFFF'u64
    bH = b shr 32
    bL = b and 0xFFFFFFFF'u64
    rHH = aH * bH
    rHL = aH * bL
    rLH = aL * bH
    rLL = aL * bL
    t = rLL + (rHL shl 32)
  var c = if t < rLL: 1'u64 else: 0'u64
  let lo = t + (rLH shl 32)
  c += (if lo < t: 1'u64 else: 0'u64)
  let hi = rHH + (rHL shr 32) + (rLH shr 32) + c
  return hi xor lo

proc hiXorLo(a, b: uint64): uint64 {.inline.} =
  # Xor of high & low 8B of full 16B product
  when nimvm:
    result = hiXorLoFallback64(a, b) # `result =` is necessary here.
  else:
    when Hash.sizeof < 8:
      result = hiXorLoFallback64(a, b)
    elif defined(gcc) or defined(llvm_gcc) or defined(clang):
      {.emit: """__uint128_t r = `a`; r *= `b`; `result` = (r >> 64) ^ r;""".}
    elif defined(windows) and not defined(tcc):
      proc umul128(a, b: uint64, c: ptr uint64): uint64 {.importc: "_umul128", header: "intrin.h".}
      var b = b
      let c = umul128(a, b, addr b)
      result = c xor b
    else:
      result = hiXorLoFallback64(a, b)

proc hashWangYi1*(x: int64|uint64|Hash): Hash {.inline.} =
  ## Wang Yi's hash_v1 for 8B int.  https://github.com/rurban/smhasher has more
  ## details.  This passed all scrambling tests in Spring 2019 and is simple.
  ## NOTE: It's ok to define ``proc(x: int16): Hash = hashWangYi1(Hash(x))``.
  const P0  = 0xa0761d6478bd642f'u64
  const P1  = 0xe7037ed1a0b428db'u64
  const P58 = 0xeb44accab455d165'u64 xor 8'u64
  when nimvm:
    cast[Hash](hiXorLo(hiXorLo(P0, uint64(x) xor P1), P58))
  else:
    when defined(js):
      asm """
        if (typeof BigInt == 'undefined') {
          `result` = `x`; // For Node < 10.4, etc. we do the old identity hash
        } else {          // Otherwise we match the low 32-bits of C/C++ hash
          function hi_xor_lo_js(a, b) {
            const prod = BigInt(a) * BigInt(b);
            const mask = (BigInt(1) << BigInt(64)) - BigInt(1);
            return (prod >> BigInt(64)) ^ (prod & mask);
          }
          const P0  = BigInt(0xa0761d64)<<BigInt(32)|BigInt(0x78bd642f);
          const P1  = BigInt(0xe7037ed1)<<BigInt(32)|BigInt(0xa0b428db);
          const P58 = BigInt(0xeb44acca)<<BigInt(32)|BigInt(0xb455d165)^BigInt(8);
          var res   = hi_xor_lo_js(hi_xor_lo_js(P0, BigInt(`x`) ^ P1), P58);
          `result`  = Number(res & ((BigInt(1) << BigInt(53)) - BigInt(1)));
        }"""
    else:
      cast[Hash](hiXorLo(hiXorLo(P0, uint64(x) xor P1), P58))

proc hashData*(data: pointer, size: int): Hash =
  ## Hashes an array of bytes of size `size`.
  var h: Hash = 0
  when defined(js):
    var p: cstring
    asm """`p` = `Data`;"""
  else:
    var p = cast[cstring](data)
  var i = 0
  var s = size
  while s > 0:
    h = h !& ord(p[i])
    inc(i)
    dec(s)
  result = !$h

when defined(js):
  var objectID = 0

proc hash*(x: pointer): Hash {.inline.} =
  ## Efficient hashing of pointers.
  when defined(js):
    asm """
      if (typeof `x` == "object") {
        if ("_NimID" in `x`)
          `result` = `x`["_NimID"];
        else {
          `result` = ++`objectID`;
          `x`["_NimID"] = `result`;
        }
      }
    """
  else:
    result = cast[Hash](cast[uint](x) shr 3) # skip the alignment

proc hash*[T: proc](x: T): Hash {.inline.} =
  ## Efficient hashing of proc vars. Closures are supported too.
  when T is "closure":
    result = hash(rawProc(x)) !& hash(rawEnv(x))
  else:
    result = hash(pointer(x))

proc hashIdentity*[T: Ordinal|enum](x: T): Hash {.inline, since: (1, 3).} =
  ## The identity hash.  I.e. ``hashIdentity(x) = x``.
  cast[Hash](ord(x))

when defined(nimIntHash1):
  proc hash*[T: Ordinal|enum](x: T): Hash {.inline.} =
    ## Efficient hashing of integers.
    cast[Hash](ord(x))
else:
  proc hash*[T: Ordinal|enum](x: T): Hash {.inline.} =
    ## Efficient hashing of integers.
    hashWangYi1(uint64(ord(x)))

proc hash*(x: float): Hash {.inline.} =
  ## Efficient hashing of floats.
  var y = x + 0.0 # for denormalization
  result = hash(cast[ptr Hash](addr(y))[])

# Forward declarations before methods that hash containers. This allows
# containers to contain other containers
proc hash*[A](x: openArray[A]): Hash
proc hash*[A](x: set[A]): Hash


when defined(js):
  proc imul(a, b: uint32): uint32 =
    # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/imul
    let mask = 0xffff'u32
    var
      aHi = (a shr 16) and mask
      aLo = a and mask
      bHi = (b shr 16) and mask
      bLo = b and mask
    result = (aLo * bLo) + (aHi * bLo + aLo * bHi) shl 16
else:
  template imul(a, b: uint32): untyped = a * b

proc rotl32(x: uint32, r: int): uint32 {.inline.} =
  (x shl r) or (x shr (32 - r))

proc murmurHash(x: openArray[byte]): Hash =
  # https://github.com/PeterScott/murmur3/blob/master/murmur3.c
  const
    c1 = 0xcc9e2d51'u32
    c2 = 0x1b873593'u32
    n1 = 0xe6546b64'u32
    m1 = 0x85ebca6b'u32
    m2 = 0xc2b2ae35'u32
  let
    size = len(x)
    stepSize = 4 # 32-bit
    n = size div stepSize
  var
    h1: uint32
    i = 0

  # body
  while i < n * stepSize:
    var k1: uint32
    when defined(js) or defined(sparc) or defined(sparc64):
      var j = stepSize
      while j > 0:
        dec j
        k1 = (k1 shl 8) or (ord(x[i+j])).uint32
    else:
      k1 = cast[ptr uint32](unsafeAddr x[i])[]
    inc i, stepSize

    k1 = imul(k1, c1)
    k1 = rotl32(k1, 15)
    k1 = imul(k1, c2)

    h1 = h1 xor k1
    h1 = rotl32(h1, 13)
    h1 = h1*5 + n1

  # tail
  var k1: uint32
  var rem = size mod stepSize
  while rem > 0:
    dec rem
    k1 = (k1 shl 8) or (ord(x[i+rem])).uint32
  k1 = imul(k1, c1)
  k1 = rotl32(k1, 15)
  k1 = imul(k1, c2)
  h1 = h1 xor k1

  # finalization
  h1 = h1 xor size.uint32
  h1 = h1 xor (h1 shr 16)
  h1 = imul(h1, m1)
  h1 = h1 xor (h1 shr 13)
  h1 = imul(h1, m2)
  h1 = h1 xor (h1 shr 16)
  return cast[Hash](h1)

proc hashVmImpl(x: string, sPos, ePos: int): Hash =
  doAssert false, "implementation override in compiler/vmops.nim"

proc hashVmImplChar(x: openArray[char], sPos, ePos: int): Hash =
  doAssert false, "implementation override in compiler/vmops.nim"

proc hashVmImplByte(x: openArray[byte], sPos, ePos: int): Hash =
  doAssert false, "implementation override in compiler/vmops.nim"

proc hash*(x: string): Hash =
  ## Efficient hashing of strings.
  ##
  ## See also:
  ## * `hashIgnoreStyle <#hashIgnoreStyle,string>`_
  ## * `hashIgnoreCase <#hashIgnoreCase,string>`_
  runnableExamples:
    doAssert hash("abracadabra") != hash("AbracadabrA")

  when not defined(nimToOpenArrayCString):
    result = 0
    for c in x:
      result = result !& ord(c)
    result = !$result
  else:
    when nimvm:
      result = hashVmImpl(x, 0, high(x))
    else:
      result = murmurHash(toOpenArrayByte(x, 0, high(x)))

proc hash*(x: cstring): Hash =
  ## Efficient hashing of null-terminated strings.
  runnableExamples:
    doAssert hash(cstring"abracadabra") == hash("abracadabra")
    doAssert hash(cstring"AbracadabrA") == hash("AbracadabrA")
    doAssert hash(cstring"abracadabra") != hash(cstring"AbracadabrA")

  when not defined(nimToOpenArrayCString):
    result = 0
    var i = 0
    while x[i] != '\0':
      result = result !& ord(x[i])
      inc i
    result = !$result
  else:
    when not defined(js) and defined(nimToOpenArrayCString):
      murmurHash(toOpenArrayByte(x, 0, x.high))
    else:
      let xx = $x
      murmurHash(toOpenArrayByte(xx, 0, high(xx)))

proc hash*(sBuf: string, sPos, ePos: int): Hash =
  ## Efficient hashing of a string buffer, from starting
  ## position `sPos` to ending position `ePos` (included).
  ##
  ## ``hash(myStr, 0, myStr.high)`` is equivalent to ``hash(myStr)``.
  runnableExamples:
    var a = "abracadabra"
    doAssert hash(a, 0, 3) == hash(a, 7, 10)

  when not defined(nimToOpenArrayCString):
    result = 0
    for i in sPos..ePos:
      result = result !& ord(sBuf[i])
    result = !$result
  else:
    murmurHash(toOpenArrayByte(sBuf, sPos, ePos))

proc hashIgnoreStyle*(x: string): Hash =
  ## Efficient hashing of strings; style is ignored.
  ##
  ## **Note:** This uses different hashing algorithm than `hash(string)`.
  ##
  ## See also:
  ## * `hashIgnoreCase <#hashIgnoreCase,string>`_
  runnableExamples:
    doAssert hashIgnoreStyle("aBr_aCa_dAB_ra") == hashIgnoreStyle("abracadabra")
    doAssert hashIgnoreStyle("abcdefghi") != hash("abcdefghi")

  var h: Hash = 0
  var i = 0
  let xLen = x.len
  while i < xLen:
    var c = x[i]
    if c == '_':
      inc(i)
    else:
      if c in {'A'..'Z'}:
        c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
      h = h !& ord(c)
      inc(i)
  result = !$h

proc hashIgnoreStyle*(sBuf: string, sPos, ePos: int): Hash =
  ## Efficient hashing of a string buffer, from starting
  ## position `sPos` to ending position `ePos` (included); style is ignored.
  ##
  ## **Note:** This uses different hashing algorithm than `hash(string)`.
  ##
  ## ``hashIgnoreStyle(myBuf, 0, myBuf.high)`` is equivalent
  ## to ``hashIgnoreStyle(myBuf)``.
  runnableExamples:
    var a = "ABracada_b_r_a"
    doAssert hashIgnoreStyle(a, 0, 3) == hashIgnoreStyle(a, 7, a.high)

  var h: Hash = 0
  var i = sPos
  while i <= ePos:
    var c = sBuf[i]
    if c == '_':
      inc(i)
    else:
      if c in {'A'..'Z'}:
        c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
      h = h !& ord(c)
      inc(i)
  result = !$h

proc hashIgnoreCase*(x: string): Hash =
  ## Efficient hashing of strings; case is ignored.
  ##
  ## **Note:** This uses different hashing algorithm than `hash(string)`.
  ##
  ## See also:
  ## * `hashIgnoreStyle <#hashIgnoreStyle,string>`_
  runnableExamples:
    doAssert hashIgnoreCase("ABRAcaDABRA") == hashIgnoreCase("abRACAdabra")
    doAssert hashIgnoreCase("abcdefghi") != hash("abcdefghi")

  var h: Hash = 0
  for i in 0..x.len-1:
    var c = x[i]
    if c in {'A'..'Z'}:
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
    h = h !& ord(c)
  result = !$h

proc hashIgnoreCase*(sBuf: string, sPos, ePos: int): Hash =
  ## Efficient hashing of a string buffer, from starting
  ## position `sPos` to ending position `ePos` (included); case is ignored.
  ##
  ## **Note:** This uses different hashing algorithm than `hash(string)`.
  ##
  ## ``hashIgnoreCase(myBuf, 0, myBuf.high)`` is equivalent
  ## to ``hashIgnoreCase(myBuf)``.
  runnableExamples:
    var a = "ABracadabRA"
    doAssert hashIgnoreCase(a, 0, 3) == hashIgnoreCase(a, 7, 10)

  var h: Hash = 0
  for i in sPos..ePos:
    var c = sBuf[i]
    if c in {'A'..'Z'}:
      c = chr(ord(c) + (ord('a') - ord('A'))) # toLower()
    h = h !& ord(c)
  result = !$h


proc hash*[T: tuple](x: T): Hash =
  ## Efficient hashing of tuples.
  for f in fields(x):
    result = result !& hash(f)
  result = !$result


proc hash*[A](x: openArray[A]): Hash =
  ## Efficient hashing of arrays and sequences.
  when A is byte:
    result = murmurHash(x)
  elif A is char:
    when nimvm:
      result = hashVmImplChar(x, 0, x.high)
    else:
      result = murmurHash(toOpenArrayByte(x, 0, x.high))
  else:
    for a in x:
      result = result !& hash(a)
    result = !$result

proc hash*[A](aBuf: openArray[A], sPos, ePos: int): Hash =
  ## Efficient hashing of portions of arrays and sequences, from starting
  ## position `sPos` to ending position `ePos` (included).
  ##
  ## ``hash(myBuf, 0, myBuf.high)`` is equivalent to ``hash(myBuf)``.
  runnableExamples:
    let a = [1, 2, 5, 1, 2, 6]
    doAssert hash(a, 0, 1) == hash(a, 3, 4)

  when A is byte:
    when nimvm:
      result = hashVmImplByte(aBuf, sPos, ePos)
    else:
      result = murmurHash(toOpenArray(aBuf, sPos, ePos))
  elif A is char:
    when nimvm:
      result = hashVmImplChar(aBuf, sPos, ePos)
    else:
      result = murmurHash(toOpenArrayByte(aBuf, sPos, ePos))
  else:
    for i in sPos .. ePos:
      result = result !& hash(aBuf[i])
    result = !$result

proc hash*[A](x: set[A]): Hash =
  ## Efficient hashing of sets.
  for it in items(x):
    result = result !& hash(it)
  result = !$result


when isMainModule:
  block empty:
    var
      a = ""
      b = newSeq[char]()
      c = newSeq[int]()
      d = cstring""
      e = "abcd"
    doAssert hash(a) == 0
    doAssert hash(b) == 0
    doAssert hash(c) == 0
    doAssert hash(d) == 0
    doAssert hashIgnoreCase(a) == 0
    doAssert hashIgnoreStyle(a) == 0
    doAssert hash(e, 3, 2) == 0
  block sameButDifferent:
    doAssert hash("aa bb aaaa1234") == hash("aa bb aaaa1234", 0, 13)
    doAssert hash("aa bb aaaa1234") == hash(cstring"aa bb aaaa1234")
    doAssert hashIgnoreCase("aA bb aAAa1234") == hashIgnoreCase("aa bb aaaa1234")
    doAssert hashIgnoreStyle("aa_bb_AAaa1234") == hashIgnoreCase("aaBBAAAa1234")
  block smallSize: # no multibyte hashing
    let
      xx = @['H', 'i']
      ii = @[72'u8, 105]
      ss = "Hi"
    doAssert hash(xx) == hash(ii)
    doAssert hash(xx) == hash(ss)
    doAssert hash(xx) == hash(xx, 0, xx.high)
    doAssert hash(ss) == hash(ss, 0, ss.high)
  block largeSize: # longer than 4 characters
    let
      xx = @['H', 'e', 'l', 'l', 'o']
      xxl = @['H', 'e', 'l', 'l', 'o', 'w', 'e', 'e', 'n', 's']
      ssl = "Helloweens"
    doAssert hash(xxl) == hash(ssl)
    doAssert hash(xxl) == hash(xxl, 0, xxl.high)
    doAssert hash(ssl) == hash(ssl, 0, ssl.high)
    doAssert hash(xx) == hash(xxl, 0, 4)
    doAssert hash(xx) == hash(ssl, 0, 4)
    doAssert hash(xx, 0, 3) == hash(xxl, 0, 3)
    doAssert hash(xx, 0, 3) == hash(ssl, 0, 3)
