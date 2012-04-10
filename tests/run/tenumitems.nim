discard """
  output: "A\nB\nC"
"""

type TAlphabet = enum
  A, B, C

iterator items(E: typedesc): E =
  for v in low(E)..high(E):
    yield v

for c in TAlphabet:
  echo($c)

