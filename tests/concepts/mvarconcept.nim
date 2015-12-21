type RNG* = concept var rng
  rng.randomUint32() is uint32

type MersenneTwister* = object

proc randomUint32*(self: var MersenneTwister): uint32 = 5

proc randomInt*(rng: var RNG; max: Positive): Natural = 5

var mersenneTwisterInst = MersenneTwister()

proc randomInt*(max: Positive): Natural =
  mersenneTwisterInst.randomInt(max)
