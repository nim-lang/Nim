#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Nim's standard random number generator.
##
## Its implementation is based on the ``xoroshiro128+``
## (xor/rotate/shift/rotate) library.
## * More information: http://xoroshiro.di.unimi.it/
## * C implementation: http://xoroshiro.di.unimi.it/xoroshiro128plus.c
##
## **Do not use this module for cryptographic purposes!**
##
## Basic usage
## ===========
##
## To get started, here are some examples:
##
## .. code-block::
##
##   import random
##
##   # Call randomize() once to initialize the default random number generator
##   # If this is not called, the same results will occur every time these
##   # examples are run
##   randomize()
##
##   # Pick a number between 0 and 100
##   let num = rand(100)
##   echo num
##
##   # Roll a six-sided die
##   let roll = rand(1..6)
##   echo roll
##
##   # Pick a marble from a bag
##   let marbles = ["red", "blue", "green", "yellow", "purple"]
##   let pick = sample(marbles)
##   echo pick
##
##   # Shuffle some cards
##   var cards = ["Ace", "King", "Queen", "Jack", "Ten"]
##   shuffle(cards)
##   echo cards
##
## These examples all use the default random number generator. The
## `Rand type<#Rand>`_ represents the state of a random number generator.
## For convenience, this module contains a default Rand state that corresponds
## to the default random number generator. Most procs in this module which do
## not take in a Rand parameter, including those called in the above examples,
## use the default generator. Those procs are **not** thread-safe.
##
## Note that the default generator always starts in the same state.
## The `randomize proc<#randomize>`_ can be called to initialize the default
## generator with a seed based on the current time, and it only needs to be
## called once before the first usage of procs from this module. If
## ``randomize`` is not called, then the default generator will always produce
## the same results.
##
## Generators that are independent of the default one can be created with the
## `initRand proc<#initRand,int64>`_.
##
## Again, it is important to remember that this module must **not** be used for
## cryptographic applications.
##
## See also
## ========
## * `math module<math.html>`_ for basic math routines
## * `mersenne module<mersenne.html>`_ for the Mersenne Twister random number
##   generator
## * `stats module<stats.html>`_ for statistical analysis
## * `list of cryptographic and hashing modules
##   <lib.html#pure-libraries-cryptography-and-hashing>`_
##   in the standard library

import algorithm                    #For upperBound

include "system/inclrtl"
{.push debugger:off.}

when defined(JS):
  type ui = uint32

  const randMax = 4_294_967_295u32
else:
  type ui = uint64

  const randMax = 18_446_744_073_709_551_615u64

type
  Rand* = object ## State of a random number generator.
    ##
    ## Create a new Rand state using the `initRand proc<#initRand,int64>`_.
    ##
    ## The module contains a default Rand state for convenience.
    ## It corresponds to the default random number generator's state.
    ## The default Rand state always starts with the same values, but the
    ## `randomize proc<#randomize>`_ can be used to seed the default generator
    ## with a value based on the current time.
    ##
    ## Many procs have two variations: one that takes in a Rand parameter and
    ## another that uses the default generator. The procs that use the default
    ## generator are **not** thread-safe!
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
  ## Computes a random ``uint64`` number using the given state.
  ##
  ## See also:
  ## * `skipRandomNumbers proc<#skipRandomNumbers,Rand>`_
  runnableExamples:
    var r = initRand(123)
    let x = r.next()
  let s0 = r.a0
  var s1 = r.a1
  result = s0 + s1
  s1 = s1 xor s0
  r.a0 = rotl(s0, 55) xor s1 xor (s1 shl 14) # a, b
  r.a1 = rotl(s1, 36) # c

proc skipRandomNumbers*(s: var Rand) =
  ## The jump function for the generator.
  ##
  ## This proc is equivalent to 2^64 calls to `next<#next,Rand>`_, and it can
  ## be used to generate 2^64 non-overlapping subsequences for parallel
  ## computations.
  ##
  ## See also:
  ## * `next proc<#next,Rand>`_
  runnableExamples:
    var r = initRand(123)
    r.skipRandomNumbers()
  when defined(JS):
    const helper = [0xbeac0467u32, 0xd86b048bu32]
  else:
    const helper = [0xbeac0467eba5facbu64, 0xd86b048b86aa9922u64]
  var
    s0 = ui 0
    s1 = ui 0
  for i in 0..high(helper):
    for b in 0 ..< 64:
      if (helper[i] and (ui(1) shl ui(b))) != 0:
        s0 = s0 xor s.a0
        s1 = s1 xor s.a1
      discard next(s)
  s.a0 = s0
  s.a1 = s1

proc random*(max: int): int {.benign, deprecated.} =
  ## **Deprecated since version 0.18.0:**
  ## Use `rand(int)<#rand,int>`_ instead.
  while true:
    let x = next(state)
    if x < randMax - (randMax mod ui(max)):
      return int(x mod uint64(max))

proc random*(max: float): float {.benign, deprecated.} =
  ## **Deprecated since version 0.18.0:**
  ## Use `rand(float)<#rand,float>`_ instead.
  let x = next(state)
  when defined(JS):
    result = (float(x) / float(high(uint32))) * max
  else:
    let u = (0x3FFu64 shl 52u64) or (x shr 12u64)
    result = (cast[float](u) - 1.0) * max

proc random*[T](x: HSlice[T, T]): T {.deprecated.} =
  ## **Deprecated since version 0.18.0:**
  ## Use `rand[T](HSlice[T, T])<#rand,HSlice[T,T]>`_ instead.
  result = T(random(x.b - x.a)) + x.a

proc random*[T](a: openArray[T]): T {.deprecated.} =
  ## **Deprecated since version 0.18.0:**
  ## Use `sample[T](openArray[T])<#sample,openArray[T]>`_ instead.
  result = a[random(a.low..a.len)]

proc rand*(r: var Rand; max: Natural): int {.benign.} =
  ## Returns a random integer in the range `0..max` using the given state.
  ##
  ## See also:
  ## * `rand proc<#rand,int>`_ that returns an integer using the default
  ##   random number generator
  ## * `rand proc<#rand,Rand,range[]>`_ that returns a float
  ## * `rand proc<#rand,Rand,HSlice[T,T]>`_ that accepts a slice
  ## * `rand proc<#rand,typedesc[T]>`_ that accepts an integer type
  runnableExamples:
    var r = initRand(123)
    let x = r.rand(100)
  if max == 0: return
  while true:
    let x = next(r)
    if x <= randMax - (randMax mod ui(max)):
      return int(x mod (uint64(max)+1u64))

proc rand*(max: int): int {.benign.} =
  ## Returns a random integer in the range `0..max`.
  ##
  ## If `randomize<#randomize>`_ has not been called, the sequence of random
  ## numbers returned from this proc will always be the same.
  ##
  ## This proc uses the default random number generator. Thus, it is **not**
  ## thread-safe.
  ##
  ## See also:
  ## * `rand proc<#rand,Rand,Natural>`_ that returns an integer using a
  ##   provided state
  ## * `rand proc<#rand,float>`_ that returns a float
  ## * `rand proc<#rand,HSlice[T,T]>`_ that accepts a slice
  ## * `rand proc<#rand,typedesc[T]>`_ that accepts an integer type
  runnableExamples:
    let x = rand(100)
  rand(state, max)

proc rand*(r: var Rand; max: range[0.0 .. high(float)]): float {.benign.} =
  ## Returns a random floating point number in the range `0.0..max`
  ## using the given state.
  ##
  ## See also:
  ## * `rand proc<#rand,float>`_ that returns a float using the default
  ##   random number generator
  ## * `rand proc<#rand,Rand,Natural>`_ that returns an integer
  ## * `rand proc<#rand,Rand,HSlice[T,T]>`_ that accepts a slice
  ## * `rand proc<#rand,typedesc[T]>`_ that accepts an integer type
  runnableExamples:
    var r = initRand(123)
    let x = r.rand(1.0)
  let x = next(r)
  when defined(JS):
    result = (float(x) / float(high(uint32))) * max
  else:
    let u = (0x3FFu64 shl 52u64) or (x shr 12u64)
    result = (cast[float](u) - 1.0) * max

proc rand*(max: float): float {.benign.} =
  ## Returns a random floating point number in the range `0.0..max`.
  ##
  ## If `randomize<#randomize>`_ has not been called, the sequence of random
  ## numbers returned from this proc will always be the same.
  ##
  ## This proc uses the default random number generator. Thus, it is **not**
  ## thread-safe.
  ##
  ## See also:
  ## * `rand proc<#rand,Rand,range[]>`_ that returns a float using a
  ##   provided state
  ## * `rand proc<#rand,int>`_ that returns an integer
  ## * `rand proc<#rand,HSlice[T,T]>`_ that accepts a slice
  ## * `rand proc<#rand,typedesc[T]>`_ that accepts an integer type
  runnableExamples:
    let x = rand(1.0)
  rand(state, max)

proc rand*[T](r: var Rand; x: HSlice[T, T]): T =
  ## For a slice `a..b`, returns a value in the range `a..b` using the given
  ## state.
  ##
  ## See also:
  ## * `rand proc<#rand,HSlice[T,T]>`_ that accepts a slice and uses the
  ##   default random number generator
  ## * `rand proc<#rand,Rand,Natural>`_ that returns an integer
  ## * `rand proc<#rand,Rand,range[]>`_ that returns a float
  ## * `rand proc<#rand,typedesc[T]>`_ that accepts an integer type
  runnableExamples:
    var r = initRand(123)
    let i = r.rand(1..6)
    let f = r.rand(2.0..4.0)
  result = T(rand(r, x.b - x.a)) + x.a

proc rand*[T](x: HSlice[T, T]): T =
  ## For a slice `a..b`, returns a value in the range `a..b`.
  ##
  ## If `randomize<#randomize>`_ has not been called, the sequence of random
  ## numbers returned from this proc will always be the same.
  ##
  ## This proc uses the default random number generator. Thus, it is **not**
  ## thread-safe.
  ##
  ## See also:
  ## * `rand proc<#rand,Rand,HSlice[T,T]>`_ that accepts a slice and uses
  ##   a provided state
  ## * `rand proc<#rand,int>`_ that returns an integer
  ## * `rand proc<#rand,float>`_ that returns a floating point number
  ## * `rand proc<#rand,typedesc[T]>`_ that accepts an integer type
  runnableExamples:
    let i = rand(1..6)
    let f = rand(2.0..4.0)
  result = rand(state, x)

proc rand*[T](r: var Rand; a: openArray[T]): T {.deprecated.} =
  ## **Deprecated since version 0.20.0:**
  ## Use `sample[T](Rand, openArray[T])<#sample,Rand,openArray[T]>`_ instead.
  result = a[rand(r, a.low..a.high)]

proc rand*[T: SomeInteger](t: typedesc[T]): T =
  ## Returns a random integer in the range `low(T)..high(T)`.
  ##
  ## If `randomize<#randomize>`_ has not been called, the sequence of random
  ## numbers returned from this proc will always be the same.
  ##
  ## This proc uses the default random number generator. Thus, it is **not**
  ## thread-safe.
  ##
  ## See also:
  ## * `rand proc<#rand,int>`_ that returns an integer
  ## * `rand proc<#rand,float>`_ that returns a floating point number
  ## * `rand proc<#rand,HSlice[T,T]>`_ that accepts a slice
  runnableExamples:
    let i = rand(int8)
    let u = rand(uint32)
  result = cast[T](state.next)

proc rand*[T](a: openArray[T]): T {.deprecated.} =
  ## **Deprecated since version 0.20.0:**
  ## Use `sample[T](openArray[T])<#sample,openArray[T]>`_ instead.
  result = a[rand(a.low..a.high)]

proc sample*[T](r: var Rand; a: openArray[T]): T =
  ## Returns a random element from ``a`` using the given state.
  ##
  ## See also:
  ## * `sample proc<#sample,openArray[T]>`_ that uses the default
  ##   random number generator
  ## * `sample proc<#sample,Rand,openArray[T],openArray[U]>`_ that uses a
  ##   cumulative distribution function
  runnableExamples:
    let marbles = ["red", "blue", "green", "yellow", "purple"]
    var r = initRand(123)
    let pick = r.sample(marbles)
  result = a[r.rand(a.low..a.high)]

proc sample*[T](a: openArray[T]): T =
  ## Returns a random element from ``a``.
  ##
  ## If `randomize<#randomize>`_ has not been called, the order of outcomes
  ## from this proc will always be the same.
  ##
  ## This proc uses the default random number generator. Thus, it is **not**
  ## thread-safe.
  ##
  ## See also:
  ## * `sample proc<#sample,Rand,openArray[T]>`_ that uses a provided state
  ## * `sample proc<#sample,openArray[T],openArray[U]>`_ that uses a
  ##   cumulative distribution function
  runnableExamples:
    let marbles = ["red", "blue", "green", "yellow", "purple"]
    let pick = sample(marbles)
  result = a[rand(a.low..a.high)]

proc sample*[T, U](r: var Rand; a: openArray[T], cdf: openArray[U]): T =
  ## Returns an element from ``a`` using a cumulative distribution function
  ## (CDF) and the given state.
  ##
  ## The ``cdf`` argument does not have to be normalized, and it could contain
  ## any type of elements that can be converted to a ``float``. It must be
  ## the same length as ``a``. Each element in ``cdf`` should be greater than
  ## or equal to the previous element.
  ##
  ## The outcome of the `cumsum<math.html#cumsum,openArray[T]>`_ proc and the
  ## return value of the `cumsummed<math.html#cumsummed,openArray[T]>`_ proc,
  ## which are both in the math module, can be used as the ``cdf`` argument.
  ##
  ## See also:
  ## * `sample proc<#sample,openArray[T],openArray[U]>`_ that also utilizes
  ##   a CDF but uses the default random number generator
  ## * `sample proc<#sample,Rand,openArray[T]>`_ that does not use a CDF
  runnableExamples:
    from math import cumsummed

    let marbles = ["red", "blue", "green", "yellow", "purple"]
    let count = [1, 6, 8, 3, 4]
    var r = initRand(123)
    let pick = r.sample(marbles, count.cumsummed)
  assert(cdf.len == a.len)              # Two basic sanity checks.
  assert(float(cdf[^1]) > 0.0)
  #While we could check cdf[i-1] <= cdf[i] for i in 1..cdf.len, that could get
  #awfully expensive even in debugging modes.
  let u = r.rand(float(cdf[^1]))
  a[cdf.upperBound(U(u))]

proc sample*[T, U](a: openArray[T], cdf: openArray[U]): T =
  ## Returns an element from ``a`` using a cumulative distribution function
  ## (CDF).
  ##
  ## This proc works similarly to
  ## `sample[T, U](Rand, openArray[T], openArray[U])
  ## <#sample,Rand,openArray[T],openArray[U]>`_.
  ## See that proc's documentation for more details.
  ##
  ## If `randomize<#randomize>`_ has not been called, the order of outcomes
  ## from this proc will always be the same.
  ##
  ## This proc uses the default random number generator. Thus, it is **not**
  ## thread-safe.
  ##
  ## See also:
  ## * `sample proc<#sample,Rand,openArray[T],openArray[U]>`_ that also utilizes
  ##   a CDF but uses a provided state
  ## * `sample proc<#sample,openArray[T]>`_ that does not use a CDF
  runnableExamples:
    from math import cumsummed

    let marbles = ["red", "blue", "green", "yellow", "purple"]
    let count = [1, 6, 8, 3, 4]
    let pick = sample(marbles, count.cumsummed)
  state.sample(a, cdf)

proc initRand*(seed: int64): Rand =
  ## Initializes a new `Rand<#Rand>`_ state using the given seed.
  ##
  ## The resulting state is independent of the default random number
  ## generator's state.
  ##
  ## Providing a specific seed will produce the same results for that
  ## seed each time.
  ##
  ## See also:
  ## * `randomize proc<#randomize,int64>`_ that accepts a seed for the default
  ##   random number generator
  ## * `randomize proc<#randomize>`_ that initializes the default random
  ##   number generator using the current time
  runnableExamples:
    from times import getTime, toUnix, nanosecond

    var r1 = initRand(123)

    let now = getTime()
    var r2 = initRand(now.toUnix * 1_000_000_000 + now.nanosecond)
  result.a0 = ui(seed shr 16)
  result.a1 = ui(seed and 0xffff)
  discard next(result)

proc randomize*(seed: int64) {.benign.} =
  ## Initializes the default random number generator with the given seed.
  ##
  ## Providing a specific seed will produce the same results for that
  ## seed each time.
  ##
  ## See also:
  ## * `initRand proc<#initRand,int64>`_
  ## * `randomize proc<#randomize>`_ that uses the current time instead
  runnableExamples:
    from times import getTime, toUnix, nanosecond

    randomize(123)

    let now = getTime()
    randomize(now.toUnix * 1_000_000_000 + now.nanosecond)
  state = initRand(seed)

proc shuffle*[T](r: var Rand; x: var openArray[T]) =
  ## Shuffles a sequence of elements in-place using the given state.
  ##
  ## See also:
  ## * `shuffle proc<#shuffle,openArray[T]>`_ that uses the default
  ##   random number generator
  runnableExamples:
    var cards = ["Ace", "King", "Queen", "Jack", "Ten"]
    var r = initRand(123)
    r.shuffle(cards)
  for i in countdown(x.high, 1):
    let j = r.rand(i)
    swap(x[i], x[j])

proc shuffle*[T](x: var openArray[T]) =
  ## Shuffles a sequence of elements in-place.
  ##
  ## If `randomize<#randomize>`_ has not been called, the order of outcomes
  ## from this proc will always be the same.
  ##
  ## This proc uses the default random number generator. Thus, it is **not**
  ## thread-safe.
  ##
  ## See also:
  ## * `shuffle proc<#shuffle,Rand,openArray[T]>`_ that uses a provided state
  runnableExamples:
    var cards = ["Ace", "King", "Queen", "Jack", "Ten"]
    shuffle(cards)
  shuffle(state, x)

when not defined(nimscript):
  import times

  proc randomize*() {.benign.} =
    ## Initializes the default random number generator with a value based on
    ## the current time.
    ##
    ## This proc only needs to be called once, and it should be called before
    ## the first usage of procs from this module that use the default random
    ## number generator.
    ##
    ## **Note:** Does not work for NimScript.
    ##
    ## See also:
    ## * `randomize proc<#randomize,int64>`_ that accepts a seed
    ## * `initRand proc<#initRand,int64>`_
    when defined(js):
      let time = int64(times.epochTime() * 1_000_000_000)
      randomize(time)
    else:
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

    when compileOption("rangeChecks"):
      try:
        discard rand(-1)
        doAssert false
      except RangeError:
        discard

      try:
        discard rand(-1.0)
        doAssert false
      except RangeError:
        discard


    # don't use causes integer overflow
    doAssert compiles(random[int](low(int) .. high(int)))

  main()
