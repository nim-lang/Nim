# Experimental whole-file compression for the large IC module artifacts.
# Enabled when the compiler itself is built with -d:icCompressBif.
when defined(icCompressBif):
  {.passl: "-lzstd".}
  proc ZSTD_compressBound(n: csize_t): csize_t {.importc.}
  proc ZSTD_compress(dst: pointer; capacity: csize_t; src: pointer;
                     size: csize_t; level: cint): csize_t {.importc.}
  proc ZSTD_decompress(dst: pointer; capacity: csize_t; src: pointer;
                       size: csize_t): csize_t {.importc.}
  proc ZSTD_isError(code: csize_t): cuint {.importc.}

  const compressedMagic = "NICZSTD1"

  proc compressBif*(data: string): string =
    let capacity = int(ZSTD_compressBound(csize_t(data.len)))
    result = newString(16 + capacity)
    for i in 0 ..< 8: result[i] = compressedMagic[i]
    var original = uint64(data.len)
    copyMem(addr result[8], addr original, 8)
    let size = ZSTD_compress(addr result[16], csize_t(capacity), unsafeAddr data[0],
                             csize_t(data.len), 1)
    if ZSTD_isError(size) != 0:
      raise newException(IOError, "cannot compress BIF")
    result.setLen(16 + int(size))

  proc isCompressedBif*(data: pointer; size: int): bool =
    if size < 16: return false
    let p = cast[ptr UncheckedArray[char]](data)
    for i in 0 ..< 8:
      if p[i] != compressedMagic[i]: return false
    true

  proc decompressBif*(data: pointer; size: int): tuple[data: pointer, size: int] =
    result = (nil, 0)
    var original = 0'u64
    copyMem(addr original, cast[pointer](cast[uint](data) + 8), 8)
    if original > uint64(high(uint32)) or original == 0:
      raise newException(IOError, "invalid compressed BIF size")
    result.size = int(original)
    result.data = alloc(result.size)
    let source = cast[pointer](cast[uint](data) + 16)
    let n = ZSTD_decompress(result.data, csize_t(result.size), source, csize_t(size - 16))
    if ZSTD_isError(n) != 0 or n != csize_t(result.size):
      dealloc(result.data)
      raise newException(IOError, "invalid compressed BIF data")
