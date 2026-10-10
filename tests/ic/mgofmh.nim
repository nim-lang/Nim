# Helper for tgenericoffer.nim: imports mgofmc, builds a compile-time const
# Table[MultiCodec,int] and exposes a GENERIC proc whose (T-independent) body
# instantiates getOrDefault[MultiCodec] here, where mgofmc's `==` is visible.
import tables, mgofmc
proc buildTab(): Table[MultiCodec, int] =
  result[MultiCodec(1)] = 100
  result[MultiCodec(2)] = 200
const CodeHashes = buildTab()
proc digest*[T](x: T): int =
  CodeHashes.getOrDefault(MultiCodec(2))
