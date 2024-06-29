type
  BigInt[bits: static int] = object
    limbs: array[8, uint64]

block:
  proc view[N](a: array[N, uint64]) =
    discard

  proc view[N](a: var array[N, uint64]) =
    discard

  var r: BigInt[64]
  r.limbs.view()


type Limbs[N: static int] = array[N, uint64]

block:
  proc view(a: Limbs) =
    discard

  proc view(a: var Limbs) =
    discard

  var r: BigInt[64]
  r.limbs.view()
