discard """
  output: '''abc
16 == 16'''
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
  imported_double {.importc: "double".} = object

  Pod = object
    v* : imported_double
    seed*: int32

  Pod2 = tuple[v: imported_double, seed: int32]

proc test() =
  echo sizeof(Pod), " == ",sizeof(Pod2)

test()