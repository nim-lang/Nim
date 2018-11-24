discard """
  output: '''abc
64 == 64'''
"""

type
  TA = object {.pure, final.}
    x: string

var
  a: TA
a.x = "abc"

doAssert TA.sizeof == string.sizeof

echo a.x

##########################################
# bug #9794
##########################################
type
  m256 {.importc: "__m256" , header: "immintrin.h".} = object

  Pod = object
    v* : m256
    seed*: int32

  Pod2 = tuple[v: m256, seed: int32]

proc test() =
  echo sizeof(Pod), " == ",sizeof(Pod2)

test()