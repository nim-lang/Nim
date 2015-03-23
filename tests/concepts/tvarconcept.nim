
# bug #2346

type RNG64 = concept var rng
  rng.randomUint64() is uint64

proc randomInt*(rng: var RNG64; max: int): int = 4


type MyRNG* = object

proc randomUint64*(self: var MyRNG): uint64 = 4

var r = MyRNG()
echo r.randomInt(5)
