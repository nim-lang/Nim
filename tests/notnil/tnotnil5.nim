discard """
  matrix: "--threads:on"
"""

{.experimental: "parallel".}
{.experimental: "notnil".}
import threadpool

type
  AO = object
    x: int

  A = ref AO not nil

proc process(a: A): A =
  return A(x: a.x+1)

proc processMany(ayys: openArray[A]): seq[A] =
  var newAs: seq[FlowVar[A]]

  parallel:
    for a in ayys:
      newAs.add(spawn process(a))
  for newAflow in newAs:
    let newA = ^newAflow
    if isNil(newA):
      return @[]
    result.add(newA)
