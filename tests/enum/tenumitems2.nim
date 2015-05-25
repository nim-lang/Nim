discard """
  output: "A\NB\NC"
"""

type TAlphabet = enum
  A, B, C

iterator items(E: typedesc[enum]): E =
  for v in low(E)..high(E):
    yield v

for c in TAlphabet:
  echo($c)

