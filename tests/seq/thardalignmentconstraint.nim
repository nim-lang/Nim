{.passC: "-march=native".}

type
  m256d {.importc: "__m256d", header: "immintrin.h".} = object

proc set1(x: float): m256d {.importc: "_mm256_set1_pd", header: "immintrin.h".}

type
  SeqHeader = object
    cap, len: int
    data: UncheckedArray[m256d]

for _ in 1..1000:
  var x = newSeq[m256d](1)
  echo cast[uint](x[0].addr) and 15
  echo (cast[ptr SeqHeader](x))[]
  echo sizeof(SeqHeader), " -- ", alignof(SeqHeader)

  x[0] = set1(1.0)
