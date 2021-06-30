#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The [Mersenne Twister](https://en.wikipedia.org/wiki/Mersenne_Twister)
## random number generator.
##
## **Note:** The procs in this module work at compile-time.

runnableExamples:
  var rand = newMersenneTwister(uint32.high)  ## must be "var"
  doAssert rand.getNum() != rand.getNum()  ## pseudorandom number

## See also
## ========
## * `random module<random.html>`_ for Nim's standard random number generator
type
  MersenneTwister* = object
    ## The Mersenne Twister.
    mt: array[0..623, uint32]
    index: int

proc newMersenneTwister*(seed: uint32): MersenneTwister =
  ## Creates a new `MersenneTwister` with seed `seed`.
  result.index = 0
  result.mt[0] = seed
  for i in 1'u32 .. 623'u32:
    result.mt[i] = (0x6c078965'u32 * (result.mt[i-1] xor
                                      (result.mt[i-1] shr 30'u32)) + i)

proc generateNumbers(m: var MersenneTwister) =
  for i in 0..623:
    var y = (m.mt[i] and 0x80000000'u32) +
            (m.mt[(i+1) mod 624] and 0x7fffffff'u32)
    m.mt[i] = m.mt[(i+397) mod 624] xor uint32(y shr 1'u32)
    if (y mod 2'u32) != 0:
      m.mt[i] = m.mt[i] xor 0x9908b0df'u32

proc getNum*(m: var MersenneTwister): uint32 =
  ## Returns the next pseudorandom `uint32`.
  if m.index == 0:
    generateNumbers(m)
  result = m.mt[m.index]
  m.index = (m.index + 1) mod m.mt.len

  result = result xor (result shr 11'u32)
  result = result xor ((result shl 7'u32) and 0x9d2c5680'u32)
  result = result xor ((result shl 15'u32) and 0xefc60000'u32)
  result = result xor (result shr 18'u32)

proc getSeq*(m: var MersenneTwister, len: int): seq[int] =
  ## Returns seq of pseudorandom ints len long.
  for i in 1..len:
    result.add(int(getNum(m)))

proc sample*[T](q: var MersenneTwister, arr: seq[T]): T =
  ## Takes random sample of an seq[T].
  var correspondingValues: seq[uint32]
  var maxVal: uint32 = uint32(4294967295)
  let maxValDivLenArr: uint32 = uint32(float32(maxVal) / float32(len(arr)))
  for i in arr:
    correspondingValues.add(maxVal)
    maxVal = maxVal - maxValDivLenArr
  let randNum = uint32(getNum(q))
  var largenumrindex: uint32 = 0
  var smallernumindex: uint32 = 1
  while largenumrindex < uint32(len(correspondingValues))  and smallernumindex < uint32(len(correspondingValues)):
   if randNum < correspondingValues[largenumrindex] and randNum > correspondingValues[smallernumindex]:
    return arr[largenumrindex]
   elif randNum < correspondingValues[correspondingValues.high]:
     return arr[correspondingValues.high]
   largenumrindex = largenumrindex + 1
   smallernumindex = smallernumindex + 1
