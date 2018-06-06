#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nim's standard random number generator. Based on
## the ``xoroshiro128+`` (xor/rotate/shift/rotate) library.
## * More information: http://xoroshiro.di.unimi.it/
## * C implementation: http://xoroshiro.di.unimi.it/xoroshiro128plus.c
##
## **Do not use this module for cryptographic purposes!**

include "system/inclrtl"
{.push debugger:off.}

when defined(JS):
  type ui = uint32

  const randMax = 4_294_967_295u32
else:
  type ui = uint64

  const randMax = 18_446_744_073_709_551_615u64

type
  Rand* = object ## State of the random number generator.
                 ## The procs that use the default state
                 ## are **not** thread-safe!
    a0, a1: ui

when defined(JS):
  var state = Rand(
    a0: 0x69B4C98Cu32,
    a1: 0xFED1DD30u32) # global for backwards compatibility
else:
  # racy for multi-threading but good enough for now:
  var state = Rand(
    a0: 0x69B4C98CB8530805u64,
    a1: 0xFED1DD3004688D67CAu64) # global for backwards compatibility

proc rotl(x, k: ui): ui =
  result = (x shl k) or (x shr (ui(64) - k))

proc next*(r: var Rand): uint64 =
  ## Uses the state to compute a new ``uint64`` random number.
  let s0 = r.a0
  var s1 = r.a1
  result = s0 + s1
  s1 = s1 xor s0
  r.a0 = rotl(s0, 55) xor s1 xor (s1 shl 14) # a, b
  r.a1 = rotl(s1, 36) # c

proc skipRandomNumbers*(s: var Rand) =
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

proc random*(max: int): int {.benign, deprecated.} =
  ## Returns a random number in the range 0..max-1. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount. **Deprecated since version 0.18.0**.
  ## Use ``rand`` instead.
  while true:
    let x = next(state)
    if x < randMax - (randMax mod ui(max)):
      return int(x mod uint64(max))

proc random*(max: float): float {.benign, deprecated.} =
  ## Returns a random number in the range 0..<max. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount. **Deprecated since version 0.18.0**.
  ## Use ``rand`` instead.
  let x = next(state)
  when defined(JS):
    result = (float(x) / float(high(uint32))) * max
  else:
    let u = (0x3FFu64 shl 52u64) or (x shr 12u64)
    result = (cast[float](u) - 1.0) * max

proc random*[T](x: HSlice[T, T]): T {.deprecated.} =
  ## For a slice `a .. b` returns a value in the range `a .. b-1`.
  ## **Deprecated since version 0.18.0**.
  ## Use ``rand`` instead.
  result = T(random(x.b - x.a)) + x.a

proc random*[T](a: openArray[T]): T {.deprecated.} =
  ## returns a random element from the openarray `a`.
  ## **Deprecated since version 0.18.0**.
  ## Use ``rand`` instead.
  result = a[random(a.low..a.len)]

proc rand*(r: var Rand; max: int): int {.benign.} =
  ## Returns a random number in the range 0..max. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount.
  if max == 0: return
  while true:
    let x = next(r)
    if x <= randMax - (randMax mod ui(max)):
      return int(x mod (uint64(max)+1u64))

proc rand*(max: int): int {.benign.} =
  ## Returns a random number in the range 0..max. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount.
  rand(state, max)

proc rand*(r: var Rand; max: float): float {.benign.} =
  ## Returns a random number in the range 0..max. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount.
  let x = next(r)
  when defined(JS):
    result = (float(x) / float(high(uint32))) * max
  else:
    let u = (0x3FFu64 shl 52u64) or (x shr 12u64)
    result = (cast[float](u) - 1.0) * max

proc rand*(max: float): float {.benign.} =
  ## Returns a random number in the range 0..max. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount.
  rand(state, max)

proc rand*[T](r: var Rand; x: HSlice[T, T]): T =
  ## For a slice `a .. b` returns a value in the range `a .. b`.
  result = T(rand(r, x.b - x.a)) + x.a

proc rand*[T](x: HSlice[T, T]): T =
  ## For a slice `a .. b` returns a value in the range `a .. b`.
  result = rand(state, x)

proc rand*[T](r: var Rand; a: openArray[T]): T =
  ## returns a random element from the openarray `a`.
  result = a[rand(r, a.low..a.high)]

proc rand*[T](a: openArray[T]): T =
  ## returns a random element from the openarray `a`.
  result = a[rand(a.low..a.high)]


proc initRand*(seed: int64): Rand =
  ## Creates a new ``Rand`` state from ``seed``.
  result.a0 = ui(seed shr 16)
  result.a1 = ui(seed and 0xffff)
  discard next(result)

proc randomize*(seed: int64) {.benign.} =
  ## Initializes the default random number generator
  ## with a specific seed.
  state = initRand(seed)

proc shuffle*[T](r: var Rand; x: var openArray[T]) =
  ## Swaps the positions of elements in a sequence randomly.
  for i in countdown(x.high, 1):
    let j = r.rand(i)
    swap(x[i], x[j])

proc shuffle*[T](x: var openArray[T]) =
  ## Swaps the positions of elements in a sequence randomly.
  shuffle(state, x)

when not defined(nimscript):
  import times

  proc randomize*() {.benign.} =
    ## Initializes the random number generator with a "random"
    ## number, i.e. a tickcount. Note: Does not work for NimScript.
    let now = times.getTime()
    randomize(convert(Seconds, Nanoseconds, now.toUnix) + now.nanosecond)

{.pop.}

when isMainModule:
  proc main =
    var occur: array[1000, int]

    var x = 8234
    for i in 0..100_000:
      x = rand(high(occur))
      inc occur[x]
    for i, oc in occur:
      if oc < 69:
        doAssert false, "too few occurrences of " & $i
      elif oc > 150:
        doAssert false, "too many occurrences of " & $i

    var a = [0, 1]
    shuffle(a)
    doAssert a[0] == 1
    doAssert a[1] == 0

    doAssert rand(0) == 0
    doAssert rand("a") == 'a'

  main()
