{.localPassC: "-mavx".}

type M256i* {.importc: "__m256i", header: "immintrin.h".} = object

proc mm256_set1_epi32(a: int32): M256i {.importc: "_mm256_set1_epi32", header: "immintrin.h".}
proc mm256_storeu_si256(p: pointer; a: M256i) {.importc: "_mm256_storeu_si256", header: "immintrin.h".}

proc cpuHasAvx*(): bool =
  {.emit: "`result` = __builtin_cpu_supports(\"avx\");".}

proc fillAvx*[T](dest: var array[8, T]; v: T) =
  ## Generic, so the instance is emitted into the INSTANTIATING module's TU,
  ## which is not compiled with this module's `-mavx`.
  mm256_storeu_si256(dest[0].addr, mm256_set1_epi32(int32 v))
