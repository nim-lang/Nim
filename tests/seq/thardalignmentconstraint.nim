discard """
disabled: true
"""

# does not yet work

{.passC: "-march=native".}

type
  m256d {.importc: "__m256d", header: "immintrin.h".} = object

proc set1(x: float): m256d {.importc: "_mm256_set1_pd", header: "immintrin.h".}

for _ in 1..1000:
  var x = newSeq[m256d](1)
  x[0] = set1(1.0) # test if operation causes segfault
  doAssert (cast[uint](x[0].addr) and 31) == 0
