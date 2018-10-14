# Converted from Pascal

## Interface to the zlib http://www.zlib.net/ compression library.

when defined(windows):
  const libz = "zlib1.dll"
elif defined(macosx):
  const libz = "libz.dylib"
else:
  const libz = "libz.so.1"

type
  Uint* = int32
  Ulong* = int
  Ulongf* = int
  Pulongf* = ptr Ulongf
  ZOffT* = int32
  Pbyte* = cstring
  Pbytef* = cstring
  Allocfunc* = proc (p: pointer, items: Uint, size: Uint): pointer{.cdecl.}
  FreeFunc* = proc (p: pointer, address: pointer){.cdecl.}
  InternalState*{.final, pure.} = object
  PInternalState* = ptr InternalState
  ZStream*{.final, pure.} = object
    nextIn*: Pbytef
    availIn*: Uint
    totalIn*: Ulong
    nextOut*: Pbytef
    availOut*: Uint
    totalOut*: Ulong
    msg*: Pbytef
    state*: PInternalState
    zalloc*: Allocfunc
    zfree*: FreeFunc
    opaque*: pointer
    dataType*: int32
    adler*: Ulong
    reserved*: Ulong

  ZStreamRec* = ZStream
  PZstream* = ptr ZStream
  GzFile* = pointer
  ZStreamHeader* = enum
    DETECT_STREAM,
    RAW_DEFLATE,
    ZLIB_STREAM,
    GZIP_STREAM

  ZlibStreamError* = object of Exception

{.deprecated: [TInternalState: InternalState, TAllocfunc: Allocfunc,
              TFreeFunc: FreeFunc, TZStream: ZStream, TZStreamRec: ZStreamRec].}

const
  Z_NO_FLUSH* = 0
  Z_PARTIAL_FLUSH* = 1
  Z_SYNC_FLUSH* = 2
  Z_FULL_FLUSH* = 3
  Z_FINISH* = 4
  Z_OK* = 0
  Z_STREAM_END* = 1
  Z_NEED_DICT* = 2
  Z_ERRNO* = -1
  Z_STREAM_ERROR* = -2
  Z_DATA_ERROR* = -3
  Z_MEM_ERROR* = -4
  Z_BUF_ERROR* = -5
  Z_VERSION_ERROR* = -6
  Z_NO_COMPRESSION* = 0
  Z_BEST_SPEED* = 1
  Z_BEST_COMPRESSION* = 9
  Z_DEFAULT_COMPRESSION* = -1
  Z_FILTERED* = 1
  Z_HUFFMAN_ONLY* = 2
  Z_DEFAULT_STRATEGY* = 0
  Z_BINARY* = 0
  Z_ASCII* = 1
  Z_UNKNOWN* = 2
  Z_DEFLATED* = 8
  Z_NULL* = 0
  Z_MEM_LEVEL* = 8
  MAX_WBITS* = 15

proc zlibVersion*(): cstring{.cdecl, dynlib: libz, importc: "zlibVersion".}
proc deflate*(strm: var ZStream, flush: int32): int32{.cdecl, dynlib: libz,
    importc: "deflate".}
proc deflateEnd*(strm: var ZStream): int32{.cdecl, dynlib: libz,
    importc: "deflateEnd".}
proc inflate*(strm: var ZStream, flush: int32): int32{.cdecl, dynlib: libz,
    importc: "inflate".}
proc inflateEnd*(strm: var ZStream): int32{.cdecl, dynlib: libz,
    importc: "inflateEnd".}
proc deflateSetDictionary*(strm: var ZStream, dictionary: Pbytef,
                           dictLength: Uint): int32{.cdecl, dynlib: libz,
    importc: "deflateSetDictionary".}
proc deflateCopy*(dest, source: var ZStream): int32{.cdecl, dynlib: libz,
    importc: "deflateCopy".}
proc deflateReset*(strm: var ZStream): int32{.cdecl, dynlib: libz,
    importc: "deflateReset".}
proc deflateParams*(strm: var ZStream, level: int32, strategy: int32): int32{.
    cdecl, dynlib: libz, importc: "deflateParams".}
proc inflateSetDictionary*(strm: var ZStream, dictionary: Pbytef,
                           dictLength: Uint): int32{.cdecl, dynlib: libz,
    importc: "inflateSetDictionary".}
proc inflateSync*(strm: var ZStream): int32{.cdecl, dynlib: libz,
    importc: "inflateSync".}
proc inflateReset*(strm: var ZStream): int32{.cdecl, dynlib: libz,
    importc: "inflateReset".}
proc compress*(dest: Pbytef, destLen: Pulongf, source: Pbytef, sourceLen: Ulong): cint{.
    cdecl, dynlib: libz, importc: "compress".}
proc compress2*(dest: Pbytef, destLen: Pulongf, source: Pbytef,
                sourceLen: Ulong, level: cint): cint{.cdecl, dynlib: libz,
    importc: "compress2".}
proc uncompress*(dest: Pbytef, destLen: Pulongf, source: Pbytef,
                 sourceLen: Ulong): cint{.cdecl, dynlib: libz,
    importc: "uncompress".}
proc compressBound*(sourceLen: Ulong): Ulong {.cdecl, dynlib: libz, importc.}
proc gzopen*(path: cstring, mode: cstring): GzFile{.cdecl, dynlib: libz,
    importc: "gzopen".}
proc gzdopen*(fd: int32, mode: cstring): GzFile{.cdecl, dynlib: libz,
    importc: "gzdopen".}
proc gzsetparams*(thefile: GzFile, level: int32, strategy: int32): int32{.cdecl,
    dynlib: libz, importc: "gzsetparams".}
proc gzread*(thefile: GzFile, buf: pointer, length: int): int32{.cdecl,
    dynlib: libz, importc: "gzread".}
proc gzwrite*(thefile: GzFile, buf: pointer, length: int): int32{.cdecl,
    dynlib: libz, importc: "gzwrite".}
proc gzprintf*(thefile: GzFile, format: Pbytef): int32{.varargs, cdecl,
    dynlib: libz, importc: "gzprintf".}
proc gzputs*(thefile: GzFile, s: Pbytef): int32{.cdecl, dynlib: libz,
    importc: "gzputs".}
proc gzgets*(thefile: GzFile, buf: Pbytef, length: int32): Pbytef{.cdecl,
    dynlib: libz, importc: "gzgets".}
proc gzputc*(thefile: GzFile, c: char): char{.cdecl, dynlib: libz,
    importc: "gzputc".}
proc gzgetc*(thefile: GzFile): char{.cdecl, dynlib: libz, importc: "gzgetc".}
proc gzflush*(thefile: GzFile, flush: int32): int32{.cdecl, dynlib: libz,
    importc: "gzflush".}
proc gzseek*(thefile: GzFile, offset: ZOffT, whence: int32): ZOffT{.cdecl,
    dynlib: libz, importc: "gzseek".}
proc gzrewind*(thefile: GzFile): int32{.cdecl, dynlib: libz, importc: "gzrewind".}
proc gztell*(thefile: GzFile): ZOffT{.cdecl, dynlib: libz, importc: "gztell".}
proc gzeof*(thefile: GzFile): int {.cdecl, dynlib: libz, importc: "gzeof".}
proc gzclose*(thefile: GzFile): int32{.cdecl, dynlib: libz, importc: "gzclose".}
proc gzerror*(thefile: GzFile, errnum: var int32): Pbytef{.cdecl, dynlib: libz,
    importc: "gzerror".}
proc adler32*(adler: Ulong, buf: Pbytef, length: Uint): Ulong{.cdecl,
    dynlib: libz, importc: "adler32".}
  ## **Warning**: Adler-32 requires at least a few hundred bytes to get rolling.
proc crc32*(crc: Ulong, buf: Pbytef, length: Uint): Ulong{.cdecl, dynlib: libz,
    importc: "crc32".}
proc deflateInitu*(strm: var ZStream, level: int32, version: cstring,
                   streamSize: int32): int32{.cdecl, dynlib: libz,
    importc: "deflateInit_".}
proc inflateInitu*(strm: var ZStream, version: cstring,
                   streamSize: int32): int32 {.
    cdecl, dynlib: libz, importc: "inflateInit_".}
proc deflateInit*(strm: var ZStream, level: int32): int32
proc inflateInit*(strm: var ZStream): int32
proc deflateInit2u*(strm: var ZStream, level: int32, `method`: int32,
                    windowBits: int32, memLevel: int32, strategy: int32,
                    version: cstring, streamSize: int32): int32 {.cdecl,
                    dynlib: libz, importc: "deflateInit2_".}
proc inflateInit2u*(strm: var ZStream, windowBits: int32, version: cstring,
                    streamSize: int32): int32{.cdecl, dynlib: libz,
    importc: "inflateInit2_".}
proc deflateInit2*(strm: var ZStream,
                   level, `method`, windowBits, memLevel,
                   strategy: int32): int32
proc inflateInit2*(strm: var ZStream, windowBits: int32): int32
proc zError*(err: int32): cstring{.cdecl, dynlib: libz, importc: "zError".}
proc inflateSyncPoint*(z: PZstream): int32{.cdecl, dynlib: libz,
    importc: "inflateSyncPoint".}
proc getCrcTable*(): pointer{.cdecl, dynlib: libz, importc: "get_crc_table".}

proc deflateBound*(strm: var ZStream, sourceLen: ULong): ULong {.cdecl,
        dynlib: libz, importc: "deflateBound".}

proc deflateInit(strm: var ZStream, level: int32): int32 =
  result = deflateInitu(strm, level, zlibVersion(), sizeof(ZStream).cint)

proc inflateInit(strm: var ZStream): int32 =
  result = inflateInitu(strm, zlibVersion(), sizeof(ZStream).cint)

proc deflateInit2(strm: var ZStream,
                  level, `method`, windowBits, memLevel,
                  strategy: int32): int32 =
  result = deflateInit2u(strm, level, `method`, windowBits, memLevel,
                         strategy, zlibVersion(), sizeof(ZStream).cint)

proc inflateInit2(strm: var ZStream, windowBits: int32): int32 =
  result = inflateInit2u(strm, windowBits, zlibVersion(),
                         sizeof(ZStream).cint)

proc zlibAllocMem*(appData: pointer, items, size: int): pointer {.cdecl.} =
  result = alloc(items * size)

proc zlibFreeMem*(appData, `block`: pointer) {.cdecl.} =
  dealloc(`block`)


proc compress*(sourceBuf: cstring; sourceLen: int; level=Z_DEFAULT_COMPRESSION; stream=GZIP_STREAM): string =
  ## Given a cstring, returns its deflated version with an optional header.
  ##
  ## Valid argument for ``stream`` are
  ##   - ``ZLIB_STREAM`` - add a zlib header and footer.
  ##   - ``GZIP_STREAM`` - add a basic gzip header and footer.
  ##   - ``RAW_DEFLATE`` - no header is generated.
  ##
  ## Passing a nil cstring will crash this proc in release mode and assert in
  ## debug mode.
  ##
  ## Compression level can be set with ``level`` argument. Currently
  ## ``Z_DEFAULT_COMPRESSION`` is 6.
  ##
  ## Returns "" on failure.
  assert(not sourceBuf.isNil)
  assert(sourceLen >= 0)

  var z: ZStream
  var windowBits = MAX_WBITS
  case (stream)
  of RAW_DEFLATE: windowBits = -MAX_WBITS
  of GZIP_STREAM: windowBits = MAX_WBITS + 16
  of ZLIB_STREAM, DETECT_STREAM:
    discard # DETECT_STREAM defaults to ZLIB_STREAM

  var status = deflateInit2(z, level.int32, Z_DEFLATED.int32,
                               windowBits.int32, Z_MEM_LEVEL.int32,
                               Z_DEFAULT_STRATEGY.int32)
  case status
  of Z_OK: discard
  of Z_MEM_ERROR: raise newException(OutOfMemError, "")
  of Z_STREAM_ERROR: raise newException(ZlibStreamError, "invalid zlib stream parameter!")
  of Z_VERSION_ERROR: raise newException(ZlibStreamError, "zlib version mismatch!")
  else: raise newException(ZlibStreamError, "Unkown error(" & $status & ") : " & $z.msg)

  let space = deflateBound(z, sourceLen)
  var compressed = newStringOfCap(space)
  z.next_in = sourceBuf
  z.avail_in = sourceLen.Uint
  z.next_out = addr(compressed[0])
  z.avail_out = space.Uint

  status = deflate(z, Z_FINISH)
  if status != Z_STREAM_END:
    discard deflateEnd(z) # cleanup allocated ressources
    raise newException(ZlibStreamError, "Invalid stream state(" & $status & ") : " & $z.msg)

  status = deflateEnd(z)
  if status != Z_OK: # cleanup allocated ressources
    raise newException(ZlibStreamError, "Invalid stream state(" & $status & ") : " & $z.msg)

  compressed.setLen(z.total_out)
  swap(result, compressed)

proc compress*(input: string; level=Z_DEFAULT_COMPRESSION; stream=GZIP_STREAM): string =
  ## Given a string, returns its deflated version with an optional header.
  ##
  ## Valid arguments for ``stream`` are
  ##  - ``ZLIB_STREAM`` - add a zlib header and footer.
  ##  - ``GZIP_STREAM`` - add a basic gzip header and footer.
  ##  - ``RAW_DEFLATE`` - no header is generated.
  ##
  ## Compression level can be set with ``level`` argument. Currently
  ## ``Z_DEFAULT_COMPRESSION`` is 6.
  ##
  ## Returns "" on failure.
  result = compress(input, input.len, level, stream)

proc uncompress*(sourceBuf: cstring, sourceLen: Natural; stream=DETECT_STREAM): string =
  ## Given a deflated buffer returns its inflated content as a string.
  ##
  ## Valid arguments for ``stream`` are
  ##   - ``DETECT_STREAM`` - detect if zlib or gzip header is present
  ##     and decompress stream. Fail on raw deflate stream.
  ##   - ``ZLIB_STREAM`` - decompress a zlib stream.
  ##   - ``GZIP_STREAM`` - decompress a gzip stream.
  ##   - ``RAW_DEFLATE`` - decompress a raw deflate stream.
  ##
  ## Passing a nil cstring will crash this proc in release mode and assert in
  ## debug mode.
  ##
  ## Returns "" on problems. Failure is a very loose concept, it could be you
  ## passing a non deflated string, or it could mean not having enough memory
  ## for the inflated version.
  ##
  ## The uncompression algorithm is based on http://zlib.net/zpipe.c.
  assert(not sourceBuf.isNil)
  assert(sourceLen >= 0)
  var z: ZStream
  var decompressed: string = ""
  var sbytes = 0
  var wbytes = 0
  ##  allocate inflate state

  z.availIn = 0
  var wbits = case (stream)
  of RAW_DEFLATE:  -MAX_WBITS
  of ZLIB_STREAM:   MAX_WBITS
  of GZIP_STREAM:   MAX_WBITS + 16
  of DETECT_STREAM: MAX_WBITS + 32

  var status = inflateInit2(z, wbits.int32)

  case status
  of Z_OK: discard
  of Z_MEM_ERROR: raise newException(OutOfMemError, "")
  of Z_STREAM_ERROR: raise newException(ZlibStreamError, "invalid zlib stream parameter!")
  of Z_VERSION_ERROR: raise newException(ZlibStreamError, "zlib version mismatch!")
  else: raise newException(ZlibStreamError, "Unkown error(" & $status & ") : " & $z.msg)

  # run loop until all input is consumed.
  # handle concatenated deflated stream with header.
  while true:
    z.availIn = (sourceLen - sbytes).int32

    # no more input available
    if (sourceLen - sbytes) <= 0: break
    z.nextIn = sourceBuf[sbytes].unsafeaddr

    #  run inflate() on available input until output buffer is full
    while true:
      # if written bytes >= output size : resize output
      if wbytes >= decompressed.len:
        let cur_outlen = decompressed.len
        let new_outlen = if decompressed.len == 0: sourceLen*2 else: decompressed.len*2
        if new_outlen < cur_outlen: # unsigned integer overflow, buffer too large
          discard inflateEnd(z);
          raise newException(OverflowError, "zlib stream decompressed size is too large! (size > " & $int.high & ")")

        decompressed.setLen(new_outlen)

      # available space for decompression
      let space = decompressed.len - wbytes
      z.availOut = space.Uint
      z.nextOut = decompressed[wbytes].addr

      status = inflate(z, Z_NO_FLUSH)
      if status.int8 notin {Z_OK.int8, Z_STREAM_END.int8, Z_BUF_ERROR.int8}:
        discard inflateEnd(z)
        case status
        of Z_MEM_ERROR: raise newException(OutOfMemError, "")
        of Z_DATA_ERROR: raise newException(ZlibStreamError, "invalid zlib stream parameter!")
        else: raise newException(ZlibStreamError, "Unkown error(" & $status & ") : " & $z.msg)

      # add written bytes, if any.
      wbytes += space - z.availOut.int

      # may need more input
      if not (z.availOut == 0): break

    #  inflate() says stream is done
    if (status == Z_STREAM_END):
      # may have another stream concatenated
      if z.availIn != 0:
        sbytes = sourceLen - z.availIn # add consumed bytes
        if inflateReset(z) != Z_OK: # reset zlib struct and try again
          raise newException(ZlibStreamError, "Invalid stream state(" & $status & ") : " & $z.msg)
      else:
        break # end of decompression

  #  clean up and don't care about any error
  discard inflateEnd(z)

  if status != Z_STREAM_END:
    raise newException(ZlibStreamError, "Invalid stream state(" & $status & ") : " & $z.msg)

  decompressed.setLen(wbytes)
  swap(result, decompressed)


proc uncompress*(sourceBuf: string; stream=DETECT_STREAM): string =
  ## Given a GZIP-ed string return its inflated content.
  ##
  ## Valid arguments for ``stream`` are
  ##   - ``DETECT_STREAM`` - detect if zlib or gzip header is present
  ##     and decompress stream. Fail on raw deflate stream.
  ##   - ``ZLIB_STREAM`` - decompress a zlib stream.
  ##   - ``GZIP_STREAM`` - decompress a gzip stream.
  ##   - ``RAW_DEFLATE`` - decompress a raw deflate stream.
  ##
  ## Returns "" on failure.
  result = uncompress(sourceBuf, sourceBuf.len, stream)



proc deflate*(buffer: var string; level=Z_DEFAULT_COMPRESSION; stream=GZIP_STREAM): bool {.discardable.} =
  ## Convenience proc which deflates a string and insert an optional header/footer.
  ##
  ## Valid arguments for ``stream`` are
  ##   - ``ZLIB_STREAM`` - add a zlib header and footer.
  ##   - ``GZIP_STREAM`` - add a basic gzip header and footer.
  ##   - ``RAW_DEFLATE`` - no header is generated.
  ##
  ## Compression level can be set with ``level`` argument. Currently
  ## ``Z_DEFAULT_COMPRESSION`` is 6.
  ##
  ## Returns true if `buffer` was successfully deflated otherwise the buffer is untouched.

  var temp = compress(addr(buffer[0]), buffer.len, level, stream)
  if temp.len != 0:
    swap(buffer, temp)
    result = true

proc inflate*(buffer: var string; stream=DETECT_STREAM): bool {.discardable.} =
  ## Convenience proc which inflates a string containing compressed data
  ## with an optional header.
  ##
  ## Valid argument for ``stream`` are:
  ##   - ``DETECT_STREAM`` - detect if zlib or gzip header is present
  ##     and decompress stream. Fail on raw deflate stream.
  ##   - ``ZLIB_STREAM`` - decompress a zlib stream.
  ##   - ``GZIP_STREAM`` - decompress a gzip stream.
  ##   - ``RAW_DEFLATE`` - decompress a raw deflate stream.
  ##
  ## It is ok to pass a buffer which doesn't contain deflated data,
  ## in this case the proc won't modify the buffer.
  ##
  ## Returns true if `buffer` was successfully inflated.
 
  var temp = uncompress(addr(buffer[0]), buffer.len, stream)
  if temp.len != 0:
    swap(buffer, temp)
    result = true
