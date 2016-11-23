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


import common, private/util
import private/xorshift128plus, private/xorshift1024star
import private/murmurhash3, private/xorshift64star
export common


type Xorshift128Plus* = Xorshift128PlusState
  ## xorshift128+.
  ## Based on http://xorshift.di.unimi.it/
  ##
  ## - Period: 2^128 - 1
  ## - State: 16 bytes

proc randomUint64*(self: var Xorshift128Plus): uint64 {.inline.} =
  xorshift128plus.next(self)

proc checkSeed(self: var Xorshift128Plus) {.inline.} =
  if (self.s[0] or self.s[1]) == 0:
    raise newException(ValueError,
      "The state must be seeded so that it is not everywhere zero.")

proc initXorshift128Plus*(seed: array[2, uint64]): Xorshift128Plus =
  ## Seeds a new ``Xorshift128Plus`` with 2 ``uint64``.
  ##
  ## Raises ``ValueError`` if the seed consists of only zeros.
  result.s = seed
  result.checkSeed()

proc initXorshift128Plus*(seed: array[16, uint8]): Xorshift128Plus =
  ## Seeds a new ``Xorshift128Plus`` with an array of 16 bytes.
  ##
  ## Raises ``ValueError`` if the seed consists of only zeros.
  let words = bytesToWordsN[uint64, array[2, uint64]](seed)
  initXorshift128Plus(words)

proc initXorshift128Plus*(seed: uint64): Xorshift128Plus =
  ## Seeds a new ``Xorshift128Plus`` with an ``uint64``.
  ##
  ## Raises ``ValueError`` if the seed consists of only zeros.

  # "If you have a 64-bit seed, we suggest to pass it twice
  # through MurmurHash3's avalanching function."
  let a = murmurhash3.next(seed)
  let b = murmurhash3.next(a)
  result.s = [a, b]
  result.checkSeed()


type Xorshift1024Star* = Xorshift1024StarState
  ## xorshift1024*.
  ## Based on http://xorshift.di.unimi.it/
  ##
  ## - Period: 2^1024 - 1
  ## - State: 128 bytes + int

proc randomUint64*(self: var Xorshift1024Star): uint64 {.inline.} =
  xorshift1024star.next(self)

proc checkSeed(self: var Xorshift1024Star) {.inline.} =
  var r: uint64
  for x in self.s:
    r = r or x
  if r == 0:
    raise newException(ValueError,
      "The state must be seeded so that it is not everywhere zero.")

proc initXorshift1024Star*(seed: array[16, uint64]): Xorshift1024Star =
  ## Seeds a new ``Xorshift1024Star`` with 16 ``uint64``.
  ##
  ## Raises ``ValueError`` if the seed consists of only zeros.
  result.s = seed
  result.p = 0
  result.checkSeed()

proc initXorshift1024Star*(seed: array[128, uint8]): Xorshift1024Star =
  ## Seeds a new ``Xorshift1024Star`` with an array of 128 bytes.
  ##
  ## Raises ``ValueError`` if the seed consists of only zeros.
  let words = bytesToWordsN[uint64, array[16, uint64]](seed)
  initXorshift1024Star(words)

proc initXorshift1024Star*(seed: uint64): Xorshift1024Star =
  ## Seeds a new ``Xorshift1024Star`` using an ``uint64``.
  ##
  ## Raises ``ValueError`` if the seed consists of only zeros.

  # "If you have a 64-bit seed, we suggest to seed a
  # xorshift64* generator and use its output to fill s."
  var r: array[16, uint64]
  var rng = Xorshift64StarState(x: seed)
  for x in r.mitems:
    x = xorshift64star.next(rng)
  initXorshift1024Star(r)


when defined(test):
  import unittest, math
  import private/testutil

  const seeds* = [
    47845723665u64, 2536452432u64, 1u64, 239463294u64, 2466576764u64,
    123230473459836u64, 243436463573567567u64, 24525673487652348u64,
    uint64(-1), 398734924702413u64, 98391237191231u64, 234234u64, 9199139u64,
    424553u64, 234642343242u64, 123230473459836u64
  ]

  suite "Xorshift128+":
    echo "Xorshift128+:"

    test "implementation":
      var rng = initXorshift128Plus([1234524356u64, 47845723665u64])
      check([rng.randomUint64(), rng.randomUint64(), rng.randomUint64()] == [
        10356027574996968u64, 421627830503766283u64, 7267806761253193977u64
      ])

      rng = initXorshift128Plus([262151541652562u64, 468594272265u64])
      check([rng.randomUint64(), rng.randomUint64(), rng.randomUint64()] == [
        3923822141990852456u64, 3993942717521754294u64, 13070632098572223408u64
      ])

    test "chiSquare":
      for seed in seeds:
        var rng = initXorshift128Plus(seed)
        proc rand(): int = rng.randomInt(100)
        let r = chiSquare(rand, bucketCount = 100, experiments = 1000000)
        # Probability less than the critical value, v = 99
        #    0.90      0.95     0.975      0.99     0.999
        # 117.407   123.225   128.422   134.642   148.230
        check r < 128.422

    test "zero seed":
      expect ValueError:
        discard initXorshift128Plus(0)

  suite "Xorshift1024*":
    echo "Xorshift1024*:"

    test "implementation":
      var rng = initXorshift1024Star([4873361256124563431u64, 468594272265151u64,
        24562895618746132u64, 13135123616214u64, 446469974321u64,
        798436146749841u64, 64321987496463241u64, 0u64, 87942132u64,
        9879876514321846456u64, 654698741u64, 87984321u64, 546984321u64,
        4521584632u64, 6546459846165u64, 849416516516115u64
      ])
      check([rng.randomUint64(), rng.randomUint64(), rng.randomUint64()] == [
        17423166013011235612u64, 2597568971996913771u64, 780893741250465115u64
      ])

    test "chiSquare":
      for seed in seeds:
        var rng = initXorshift1024Star(seed)
        proc rand(): int = rng.randomInt(100)
        let r = chiSquare(rand, bucketCount = 100, experiments = 1000000)
        # Probability less than the critical value, v = 99
        #    0.90      0.95     0.975      0.99     0.999
        # 117.407   123.225   128.422   134.642   148.230
        check r < 128.422

    test "zero seed":
      expect ValueError:
        discard initXorshift1024Star(0)
