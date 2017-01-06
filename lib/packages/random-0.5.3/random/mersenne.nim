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
import private/mt19937ar
export common


type MersenneTwister* = MTState
  ## Mersenne Twister (MT19937). Based on
  ## http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/emt19937ar.html
  ##
  ## - Period: 2^19937 - 1
  ## - State: 2496 bytes + int

proc randomUint32*(self: var MersenneTwister): uint32 {.inline.} =
  self.genrandInt32()

proc random*(self: var MersenneTwister): float64 {.inline.} =
  self.genrandRes53()

proc initMersenneTwister*(seed: openArray[uint32]): MersenneTwister =
  ## Seeds a new ``MersenneTwister`` with an array of ``uint32``
  result = initMTState()
  result.initByArray(seed)

proc initMersenneTwister*(seed: openArray[uint8]): MersenneTwister =
  ## Seeds a new ``MersenneTwister`` with an array of bytes
  let words = bytesToWords[uint32](seed)
  initMersenneTwister(words)

proc initMersenneTwister*(seed: uint32): MersenneTwister =
  ## Seeds a new ``MersenneTwister`` with an ``uint32``
  result = initMTState()
  result.initGenrand(seed)


when defined(test):
  import unittest
  import private/testutil

  const seeds* = [
    345632254u32, 253642432, 1, 0, 239463294, 246956764, 12359836,
    367473423, 1452567348, 0xffffffffu32, 397349243, 983991231, 234234,
    9199139, 424553, 234642342, 123836
  ]

  suite "Mersenne Twister":
    echo "Mersenne Twister:"

    test "implementation":
      var rng = initMersenneTwister([0x123u32, 0x234, 0x345, 0x456])
      check([rng.randomUint32(), rng.randomUint32(), rng.randomUint32()] == [
        1067595299u32, 955945823, 477289528
      ])

    test "chiSquare":
      for seed in seeds:
        var rng = initMersenneTwister(seed)
        proc rand(): int = rng.randomInt(100)
        let r = chiSquare(rand, bucketCount = 100, experiments = 1000000)
        # Probability less than the critical value, v = 99
        #    0.90      0.95     0.975      0.99     0.999
        # 117.407   123.225   128.422   134.642   148.230
        check r < 123.225
