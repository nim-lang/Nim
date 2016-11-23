# Copyright (C) 2014-2015 Oleh Prypin <blaxpirit@gmail.com>
#
# This file is part of nim-random.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


## This module is exported by all other modules. It defines common operations
## that work for all the PRNGs provided by this library.

import intsets
import private/util, private/random_real


type RNG8 = concept var rng
  rng.randomUint8() is uint8
type RNG32 = concept var rng
  rng.randomUint32() is uint32
type RNG64 = concept var rng
  rng.randomUint64() is uint64
type RNG* = RNG8 or RNG32 or RNG64
  ## Random number generator

template baseType(rng): expr =
  when compiles(rng.randomUint32()): uint32
  elif compiles(rng.randomUint64()): uint64
  elif compiles(rng.randomUint8()): uint8
  else:
    assert false
    uint32

template baseRandom(rng): expr =
  when compiles(rng.randomUint32()): rng.randomUint32()
  elif compiles(rng.randomUint64()): rng.randomUint64()
  elif compiles(rng.randomUint8()): rng.randomUint8()
  else:
    assert false
    0u32


#: Random Integers

proc randomIntImpl[T: SomeInteger; RNG](rng: var RNG): T =
  when sizeof(T) <= sizeof(rng.baseType):
    cast[T](rng.baseRandom())
  else:
    let neededParts = sizeof(T) div sizeof(rng.baseType)
    for i in 1..neededParts:
      result = (result shl T(sizeof(rng.baseType)*8)) or
        cast[T](rng.baseRandom())

proc randomInt*(rng: var RNG; T: typedesc[SomeInteger]): T {.inline.} =
  ## Returns a uniformly distributed random integer ``T.low <= x <= T.high``
  randomIntImpl[T, RNG](rng)

proc randomByte*(rng: var RNG): uint8 {.inline, deprecated.} =
  ## Returns a uniformly distributed random integer ``0 <= x < 256``
  ##
  ## *Deprecated*: Use ``randomInt(uint8)`` instead.
  rng.randomInt(uint8)

proc randomIntImpl(rng: var RNG; max: uint64): uint64 =
  # We're assuming 0 < max <= int64.high
  let limit = (1u64 shl 63) div max * max
  # high(uint64) doesn't work...
  when compiles(high(rng.baseType)):
    if max <= high(rng.baseType):
      while true:
        result = cast[uint64](rng.baseRandom())
        if result < limit: break
    else:
      let neededParts = divCeil(bitSize(max), sizeof(rng.baseType)*8)
      while true:
        for i in 1..neededParts:
          result = (result shl (sizeof(rng.baseType)*8)) or rng.baseRandom()
        if result < limit: break
  else:
    while true:
      result = cast[uint64](rng.baseRandom())
      if result < limit: break
  result = result mod max

proc randomInt*(rng: var RNG; max: Positive): Natural {.inline.} =
  ## Returns a uniformly distributed random integer ``0 <= x < max``
  rng.randomIntImpl(uint64(max))

proc randomInt*(rng: var RNG; min, max: int): int {.inline.} =
  ## Returns a uniformly distributed random integer ``min <= x < max``
  min + rng.randomInt(max - min)

proc randomInt*(rng: var RNG; interval: Slice[int]): int {.inline.} =
  ## Returns a uniformly distributed random integer ``interval.a <= x <= interval.b``
  interval.a + rng.randomInt(interval.b - interval.a + 1)

proc randomBool*(rng: var RNG): bool {.inline.} =
  ## Returns a random boolean
  bool(rng.randomInt(2))


#: Random Reals

proc random*(rng: var RNG): float64 =
  ## Returns a uniformly distributed random number ``0 <= x < 1``
  const maxPrec = 1u64 shl 53 # float64, excluding mantissa, has 2^53 values
  float64(rng.randomIntImpl(maxPrec))/float64(maxPrec)

proc random*(rng: var RNG; max: float): float {.inline.} =
  ## Returns a uniformly distributed random number ``0 <= x < max``
  max*rng.random()

proc random*(rng: var RNG; min, max: float): float {.inline.} =
  ## Returns a uniformly distributed random number ``min <= x < max``
  min+(max-min)*rng.random()

proc randomPrecise*(rng: var RNG): float64 =
  ## Returns a uniformly distributed random number ``0 <= x <= 1``,
  ## with more resolution (doesn't skip values).
  ##
  ## Based on http://mumble.net/~campbell/2014/04/28/uniform-random-float
  random_real.randomReal(rng.randomInt(uint64))


#: Sequence Operations

proc randomChoice*(rng: var RNG; arr: RAContainer): auto {.inline.} =
  ## Selects a random element (all of them have an equal chance)
  ## from a random access container and returns it
  arr[rng.randomInt(arr.low..arr.high)]


proc shuffle*(rng: var RNG; arr: var RAContainer) =
  ## Randomly shuffles elements of a random access container.
  # Fisher-Yates shuffle
  for i in arr.low..arr.high:
    let j = rng.randomInt(i..arr.high)
    swap arr[j], arr[i]


iterator randomSample*(rng: var RNG; interval: Slice[int]; n: Natural): int =
  ## Yields `n` random integers ``interval.a <= x <= interval.b`` in random order.
  ## Each number has an equal chance to be picked and can be picked only once.
  ##
  ## Raises ``ValueError`` if there are less than `n` items in `interval`.
  if n > interval.b - interval.a + 1:
    raise newException(ValueError, "Sample can't be larger than population")
  # Simple random sample
  var iset = initIntSet()
  var remaining = n
  while remaining > 0:
    let x = rng.randomInt(interval)
    if not containsOrIncl(iset, x):
      yield x
      dec remaining

iterator randomSample*(rng: var RNG; arr: RAContainer; n: Natural): auto =
  ## Yields `n` items randomly picked from a random access container `arr`,
  ## in random order. Each item has an equal chance to be picked
  ## and can be picked only once. Duplicate items are allowed in `arr`,
  ## and they will not be treated in any special way.
  ##
  ## Raises ``ValueError`` if there are less than `n` items in `arr`.
  for i in rng.randomSample(arr.low..arr.high, n):
    yield arr[i]

proc randomSample*[T](rng: var RNG; iter: iterator(): T; n: Natural): seq[T] =
  ## Random sample using reservoir sampling algorithm.
  ##
  ## Returns a sequence of `n` items randomly picked from an iterator `iter`,
  ## in no particular order. Each item has an equal chance to be picked and can
  ## be picked only once. Repeating items are allowed in `iter`, and they will
  ## not be treated in any special way.
  ##
  ## Raises ``ValueError`` if there are less than `n` items in `iter`.
  result = newSeq[T](n)
  if n == 0:
    return
  for r in result.mitems:
    r = iter()
    if iter.finished:
      raise newException(ValueError, "Sample can't be larger than population")
  var idx = n
  for e in iter():
    let r = rng.randomInt(0..idx)
    if r < n:
      result[r] = e
    inc idx


when defined(test):
  import unittest, sequtils, tables
  import xorshift, private/testutil

  var dataRNG8 = [234u8, 153, 0, 0, 127, 128, 255, 255]
  type TestRNG8 = object
    n: int
  proc randomUint8(rng: var TestRNG8): uint8 =
    result = dataRNG8[rng.n]
    rng.n = (rng.n+1) mod dataRNG8.len
  var testRNG8: TestRNG8

  var dataRNG32 = [31541451u32, 0, 1, 234, 342475672, 863, 0xffffffffu32, 50967465]
  type TestRNG32 = object
    n: int
  proc randomUint32(rng: var TestRNG32): uint32 =
    result = dataRNG32[rng.n]
    rng.n = (rng.n+1) mod dataRNG32.len
  var testRNG32: TestRNG32

  var dataRNG64 = [148763248732657823u64, 18446744073709551615u64, 0u64,
    32456325635673576u64, 2456245614625u64, 32452456246u64, 3956529762u64,
    9823674982364u64, 234253464546456u64, 14345435645646u64]
  type TestRNG64 = object
    n: int
  proc randomUint64(rng: var TestRNG64): uint64 =
    result = dataRNG64[rng.n]
    rng.n = (rng.n+1) mod dataRNG64.len
  var testRNG64: TestRNG64

  proc clItems[T](s: seq[T]): auto =
    (iterator(): T =
      for x in s: yield x)

  suite "Common":
    echo "Common:"

    test "randomInt(T) accumulation":
      testRNG8 = TestRNG8()
      for i in 0..3:
        let result = randomInt(testRNG8, uint16)
        let expected = uint16(dataRNG8[i*2])*0x100u16 + uint16(dataRNG8[i*2+1])
        check result == expected

    test "randomInt(T) truncation":
      testRNG32 = TestRNG32()
      for i in 0..7:
        let result = randomInt(testRNG32, uint16)
        let expected = dataRNG32[i] mod 0x10000u32
        check uint32(result) == expected

    test "randomInt(T) negation":
      testRNG8 = TestRNG8()
      for i in 0..7:
        let result = randomInt(testRNG8, int8)
        if dataRNG8[i] > 0x80u8:
          let expected = int(dataRNG8[i]) - 0x100
          check int(result) == expected

    test "random chiSquare":
      for seed in xorshift.seeds:
        var rng = initXorshift128Plus(seed)
        proc rand(): float = rng.random()
        let r = chiSquare(rand, bucketCount = 100, experiments = 100000)
        # Probability less than the critical value, v = 99
        #    0.90      0.95     0.975      0.99     0.999
        # 117.407   123.225   128.422   134.642   148.230
        check r < 128.422

    test "randomPrecise implementation":
      testRNG64 = TestRNG64()
      for bounds in [
        (0.0080644e-00 .. 0.0080645e-00),
        (9.5380568e-23 .. 9.5380569e-23),
        (1.7592511e-09 .. 1.7592512e-09),
        (5.3254248e-07 .. 5.3254249e-07),
        (7.7766762e-07 .. 7.7766763e-07),
        (0.9999999e-00 .. 1.0000001e-00),
        (9.5380568e-23 .. 9.5380569e-23),
        (1.7592511e-09 .. 1.7592512e-09),
        (5.3254248e-07 .. 5.3254249e-07),
        (7.7766762e-07 .. 7.7766763e-07),
        (0.9999999e-00 .. 1.0000001e-00),
        (9.5380568e-23 .. 9.5380569e-23),
      ]:
        let r = float(testRNG64.randomPrecise())
        check bounds.a < r and r < bounds.b

    test "randomPrecise chiSquare":
      for seed in xorshift.seeds:
        var rng = initXorshift128Plus(seed)
        proc rand(): float = rng.randomPrecise()
        let r = chiSquare(rand, bucketCount = 100, experiments = 100000)
        # Probability less than the critical value, v = 99
        #    0.90      0.95     0.975      0.99     0.999
        # 117.407   123.225   128.422   134.642   148.230
        check r < 134.642

    test "shuffle chiSquare":
      for seed in xorshift.seeds:
        var rng = initXorshift128Plus(seed)
        proc rand(): seq[int] =
          result = toSeq(1..4)
          rng.shuffle(result)
        # 4! = 24
        let r = chiSquare(rand, bucketCount = 24, experiments = 100000)
        # Probability less than the critical value, v = 23
        #    0.90      0.95     0.975      0.99     0.999
        #  32.007    35.172    38.076    41.638    49.728
        check r < 38.076

    test "randomSample":
      var rng = initXorshift128Plus(123)
      expect ValueError:
        for x in rng.randomSample(7..7, 2):
          discard

      let z = toSeq(rng.randomSample(7..20, 0))
      check z == newSeq[int]()

      for seed in xorshift.seeds:
        rng = initXorshift128Plus(seed)
        for i in 1..100:
          var a = rng.randomInt(1..2000)
          var b = rng.randomInt(1..2000)
          if a > b: swap a, b
          let n = rng.randomInt(0 .. b-a+1)
          let s = toSeq(rng.randomSample(a..b, n))
          check s.len == n
          check s.deduplicate().len == n

    test "randomSample chiSquare":
      for seed in xorshift.seeds:
        var rng = initXorshift128Plus(seed)
        proc rand(): seq[int] = toSeq(rng.randomSample(1..5, 3))
        # A(5, 3) = 60
        let r = chiSquare(rand, bucketCount = 60, experiments = 100000)
        # Probability less than the critical value, v = 59
        #    0.90      0.95     0.975      0.99     0.999
        #  73.279    77.931    82.117    87.166    98.324
        check r < 82.117

    test "randomSample reservoir":
      var rng = initXorshift128Plus(123)
      expect ValueError:
        for x in rng.randomSample(@[7].clItems, 2):
          discard

      let z = rng.randomSample(@[7, 8, 9].clItems, 0)
      check z == newSeq[int]()

      for seed in xorshift.seeds:
        rng = initXorshift128Plus(seed)
        for i in 1..100:
          var a = rng.randomInt(1..2000)
          var b = rng.randomInt(1..2000)
          if a > b: swap a, b
          let n = rng.randomInt(0 .. b-a+1)
          let s = rng.randomSample(toSeq(a..b).clItems, n)
          check s.len == n
          check s.deduplicate().len == n

    test "randomSample reservoir chiSquare":
      for seed in xorshift.seeds:
        var rng = initXorshift128Plus(seed)
        proc rand(): set[1..8] =
          for e in rng.randomSample(toSeq(1..8).clItems, 3):
            result.incl e
        # C(8, 3) = 56
        let r = chiSquare(rand, bucketCount = 56, experiments = 100000)
        # Probability less than the critical value, v = 55
        #    0.90      0.95     0.975      0.99     0.999
        #  68.796    73.311    77.380    82.292    93.168
        check r < 77.380
