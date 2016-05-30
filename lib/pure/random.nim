#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## | Nim's standard random number generator. Based on
## | http://xoroshiro.di.unimi.it/
## | http://xoroshiro.di.unimi.it/xoroshiro128plus.c

include "system/inclrtl"
{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

# XXX Expose RandomGenState
type
  RandomGenState = object
    a0, a1: uint64

# racy for multi-threading but good enough for now:
var state = RandomGenState(
  a0: 0x69B4C98CB8530805u64,
  a1: 0xFED1DD3004688D67CAu64) # global for backwards compatibility

proc rotl(x: uint64, k: uint64): uint64 =
  result = (x shl k) or (x shr (64u64 - k))

proc next(s: var RandomGenState): uint64 =
  let s0 = s.a0
  var s1 = s.a1
  result = s0 + s1
  s1 = s1 xor s0
  s.a0 = rotl(s0, 55) xor s1 xor (s1 shl 14) # a, b
  s.a1 = rotl(s1, 36) # c

proc skipRandomNumbers(s: var RandomGenState) =
  ## This is the jump function for the generator. It is equivalent
  ## to 2^64 calls to next(); it can be used to generate 2^64
  ## non-overlapping subsequences for parallel computations.
  const helper = [0xbeac0467eba5facbu64, 0xd86b048b86aa9922u64]
  var
    s0 = 0u64
    s1 = 0u64
  for i in 0..high(helper):
    for b in 0..< 64:
      if (helper[i] and (1u64 shl uint64(b))) != 0:
        s0 = s0 xor s.a0
        s1 = s1 xor s.a1
      discard next(s)
  s.a0 = s0
  s.a1 = s1

proc random*(max: int): int {.benign.} =
  ## Returns a random number in the range 0..max-1. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount.
  result = int(next(state) mod uint64(max))

proc random*(max: float): float {.benign.} =
  ## Returns a random number in the range 0..<max. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount.
  let x = next(state)
  let u = (0x3FFu64 shl 52u64) or (x shr 12u64)
  result = (cast[float](u) - 1.0) * max

proc random*[T](x: Slice[T]): T =
  ## For a slice `a .. b` returns a value in the range `a .. b-1`.
  result = random(x.b - x.a) + x.a

proc random*[T](a: openArray[T]): T =
  ## returns a random element from the openarray `a`.
  result = a[random(a.low..a.len)]

proc randomize*(seed: int) {.benign.} =
  ## Initializes the random number generator with a specific seed.
  state.a0 = uint64(seed shr 16)
  state.a1 = uint64(seed and 0xffff)

when not defined(nimscript):
  import times

  proc randomize*() {.benign.} =
    ## Initializes the random number generator with a "random"
    ## number, i.e. a tickcount. Note: Does nothing for the JavaScript target,
    ## as JavaScript does not support this. Nor does it work for NimScript.
    randomize(int times.getTime())

{.pop.}

when isMainModule:
  proc main =
    var occur: array[1000, int]

    var x = 8234
    for i in 0..100_000:
      x = random(len(occur)) # myrand(x)
      inc occur[x]
    for i, oc in occur:
      if oc < 69:
        doAssert false, "too few occurances of " & $i
      elif oc > 130:
        doAssert false, "too many occurances of " & $i
  main()
