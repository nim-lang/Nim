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


import intsets, math


proc divCeil*(a, b: SomeInteger): SomeInteger {.inline.} =
  ## Returns ``ceil(a / b)`` (only works on positive numbers)
  (a-1+b) div b


type RAContainer* = concept c
  ## Random access container
  c.low is SomeInteger
  c.high is SomeInteger
  c.len is SomeInteger
  # c[i] is T ???


when defined(gcc):
  proc clz(n: culonglong): cint {.importc: "__builtin_clzll".}

proc log2pow2Fallback(x: uint64): int {.inline.} =
  const debruijn64 = [
     0,  1,  2, 53,  3,  7, 54, 27,  4, 38, 41,  8, 34, 55, 48, 28,
    62,  5, 39, 46, 44, 42, 22,  9, 24, 35, 59, 56, 49, 18, 29, 11,
    63, 52,  6, 26, 37, 40, 33, 47, 61, 45, 43, 21, 23, 58, 17, 10,
    51, 25, 36, 32, 60, 20, 57, 16, 50, 31, 19, 15, 30, 14, 13, 12
  ]
  debruijn64[int((x * 0x022fdd63cc95386d'u64) shr 58u64)]

proc log2pow2*(x: uint64): int {.inline.} =
  ## Returns ``log2(x)``, but `x` must be a power of 2. Also undefined for 0.
  when compiles(clz):
    63 - clz(x)
  else:
    log2pow2Fallback(x)

proc log2pow21*(x: uint64): int {.inline.} =
  ## Returns ``log2(x+1)``, but `x` must be a power of 2 minus 1.
  if unlikely x == uint64(-1):
    64
  else:
    log2pow2(x+1)

proc bitSizeFallback(x: uint64): int {.inline.} =
  var x = x
  for s in [1u64, 2, 4, 8, 16, 32]:
    x = x or (x shr s)
  log2pow21(x)

proc bitSize*(x: uint64): int =
  ## Returns ``floor(log2(x))+1``. Undefined for 0.
  when compiles(clz):
    return 64 - clz(x)
  else:
    bitSizeFallback(x)


proc bytesToWords*[T](bytes: openArray[uint8]): seq[T] =
  const size = sizeof(T)
  # Turn an array of uint8 into an array of T:
  let n = (bytes.high div size)+1 # n bytes is ceil(n/k) k-bit numbers
  result = newSeq[T](n)
  for i in 0 .. <n:
    for j in 0 .. <size:
      let index = i*size+j
      let data: T =
        if index < bytes.len: bytes[index]
        else: 0
      result[i] = result[i] or (data shl T(8*j))

proc bytesToWordsN*[T, R](bytes: openArray[uint8]): R =
  const size = sizeof(T)
  # Turn an array of uint8 into an array of T:
  for i in 0 .. result.high:
    for j in 0 .. <size:
      let data: T = bytes[i*size+j]
      result[i] = result[i] or (data shl T(8*j))


when defined(test):
  import unittest, sequtils

  suite "Utilities":
    echo "Utilities:"

    test "divCeil":
      for data in [
        (1, 1, 1), (1, 2, 1), (1, 999999, 1), (5, 2, 3), (8, 7, 2)
      ]:
        let (a, b, output) = data
        check divCeil(a, b) == output

    test "log2pow2":
      for output in 0..31:
        let input = 1u64 shl uint64(output)
        check log2pow2(input) == output
        check log2pow2Fallback(input) == output

    test "bitSize":
      for input in [
        1u64, 2, 15, 16, 17, 254, 255, 256,
        (1 shl 24)-1, 1 shl 24, uint64(-1), uint64(-2)
      ]:
        let output = int(ceil(log2(float(input)+1.0)))
        check bitSize(input) == output
        check bitSizeFallback(input) == output

    test "bytesToWords":
      for data in [
        (@[0u8, 0, 0, 0, 0, 0, 0, 0], @[0u64]),
        (@[7u8, 0, 0, 0, 0, 0, 0, 0], @[7u64]),
        (@[0u8, 0, 0, 0, 0, 0, 0, 255, 3], @[255u64 shl 56, 3]),
      ]:
        let (input, output) = data
        let result = bytesToWords[uint64](input)
        check result == output

    test "bytesToWordsN":
      for data in [
        ([0u8, 0, 0, 0, 0, 0, 0, 0], [0u32, 0u32]),
        ([5u8, 0, 0, 8, 0, 2, 6, 0],
           [5u32+(8u32 shl 24), (2u32 shl 8)+(6u32 shl 16)]),
      ]:
        let (input, output) = data
        let result = bytesToWordsN[uint32, array[2, uint32]](input)
        check result == output
