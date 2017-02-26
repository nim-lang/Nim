#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nim's standard random number generator. Based on the ``xoroshiro128+`` (xor/rotate/shift/rotate) library.
## * More information: http://xoroshiro.di.unimi.it/
## * C implementation: http://xoroshiro.di.unimi.it/xoroshiro128plus.c
##
## Do not use this module for cryptographic use!

include "system/inclrtl"
{.push debugger:off.}

# XXX Expose RandomGenState
when defined(JS):
  type ui = uint32

  const randMax = 4_294_967_295u32
else:
  type ui = uint64

  const randMax = 18_446_744_073_709_551_615u64

type
  RandomGenState = object
    a0, a1: ui

when defined(JS):
  var state = RandomGenState(
    a0: 0x69B4C98Cu32,
    a1: 0xFED1DD30u32) # global for backwards compatibility
else:
  # racy for multi-threading but good enough for now:
  var state = RandomGenState(
    a0: 0x69B4C98CB8530805u64,
    a1: 0xFED1DD3004688D67CAu64) # global for backwards compatibility

proc rotl(x, k: ui): ui =
  result = (x shl k) or (x shr (ui(64) - k))

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
  when defined(JS):
    const helper = [0xbeac0467u32, 0xd86b048bu32]
  else:
    const helper = [0xbeac0467eba5facbu64, 0xd86b048b86aa9922u64]
  var
    s0 = ui 0
    s1 = ui 0
  for i in 0..high(helper):
    for b in 0..< 64:
      if (helper[i] and (ui(1) shl ui(b))) != 0:
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
  while true:
    let x = next(state)
    if x < randMax - (randMax mod ui(max)):
      return int(x mod uint64(max))

proc random*(max: float): float {.benign.} =
  ## Returns a random number in the range 0..<max. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount.
  let x = next(state)
  when defined(JS):
    result = (float(x) / float(high(uint32))) * max
  else:
    let u = (0x3FFu64 shl 52u64) or (x shr 12u64)
    result = (cast[float](u) - 1.0) * max

proc random*[T](x: Slice[T]): T =
  ## For a slice `a .. b` returns a value in the range `a .. b-1`.
  result = T(random(x.b - x.a)) + x.a

proc random*[T](a: openArray[T]): T =
  ## returns a random element from the openarray `a`.
  result = a[random(a.low..a.len)]

proc randomize*(seed: int) {.benign.} =
  ## Initializes the random number generator with a specific seed.
  state.a0 = ui(seed shr 16)
  state.a1 = ui(seed and 0xffff)
  discard next(state)

proc shuffle*[T](x: var openArray[T]) =
  ## Will randomly swap the positions of elements in a sequence.
  for i in countdown(x.high, 1):
    let j = random(i + 1)
    swap(x[i], x[j])

when not defined(nimscript):
  import times

  proc randomize*() {.benign.} =
    ## Initializes the random number generator with a "random"
    ## number, i.e. a tickcount. Note: Does not work for NimScript.
    when defined(JS):
      proc getMil(t: Time): int {.importcpp: "getTime", nodecl.}
      randomize(getMil times.getTime())
    else:
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
        doAssert false, "too few occurrences of " & $i
      elif oc > 130:
        doAssert false, "too many occurrences of " & $i

    var a = [0, 1]
    shuffle(a)
    doAssert a[0] == 1
    doAssert a[1] == 0
  main()
