# Helper for ttypeoffer.nim: a generic container whose hash-array bound depends
# on a `mixin toSszType` resolved at the instantiation site (cf. ssz dataPerChunk).
template perChunk*(T: type): int =
  mixin toSszType
  when compiles(toSszType(default(T))): 4 else: 1

type
  HA*[N: static int; T] = object
    data*: array[N, T]
    hashes*: array[N div perChunk(T), uint64]
