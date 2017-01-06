# Copyright (C) 2015 Oleh Prypin <blaxpirit@gmail.com>
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


import tables


proc chiSquare*(rand: proc(): int; bucketCount, experiments: int): float =
  var buckets = newSeq[int](bucketCount)
  let mean = experiments / bucketCount

  for i in 1..experiments:
    buckets[rand()] += 1

  for n in buckets:
    let d = float(n) - mean
    result += d*d / mean

proc chiSquare*(rand: proc(): float; bucketCount, experiments: int): float =
  var buckets = newSeq[int](bucketCount)
  let mean = experiments / bucketCount

  for i in 1..experiments:
    buckets[int(rand() * float(bucketCount))] += 1

  for n in buckets:
    let d = float(n) - mean
    result += d*d / mean

proc chiSquare*[T](rand: proc(): T; bucketCount, experiments: int): float =
  var buckets = initTable[T, int]()

  for i in 1..experiments:
    let r = rand()
    buckets.mgetOrPut(r, 1) += 1

  assert bucketCount == buckets.len
  let mean = experiments / bucketCount

  for n in buckets.values:
    let d = float(n) - mean
    result += d*d / mean
