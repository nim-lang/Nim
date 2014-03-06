# Converted from Pascal

## Interface to the zlib http://www.zlib.net/ compression library.

when defined(windows):
  const libz = "zlib1.dll"
elif defined(macosx):
  const libz = "libz.dylib"
else:
  const libz = "libz.so"

type
  Uint* = int32
  Ulong* = int
  Ulongf* = int
  Pulongf* = ptr Ulongf
  z_off_t* = int32
  pbyte* = cstring
  pbytef* = cstring
  TAllocfunc* = proc (p: pointer, items: uInt, size: uInt): pointer{.cdecl.}
  TFreeFunc* = proc (p: pointer, address: pointer){.cdecl.}
  TInternalState*{.final, pure.} = object 
  PInternalState* = ptr TInternalstate
  TZStream*{.final, pure.} = object 
    next_in*: pbytef
    avail_in*: uInt
    total_in*: uLong
    next_out*: pbytef
    avail_out*: uInt
    total_out*: uLong
    msg*: pbytef
    state*: PInternalState
    zalloc*: TAllocFunc
    zfree*: TFreeFunc
    opaque*: pointer
    data_type*: int32
    adler*: uLong
    reserved*: uLong

  TZStreamRec* = TZStream
  PZstream* = ptr TZStream
  gzFile* = pointer

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

proc zlibVersion*(): cstring{.cdecl, dynlib: libz, importc: "zlibVersion".}
proc deflate*(strm: var TZStream, flush: int32): int32{.cdecl, dynlib: libz, 
    importc: "deflate".}
proc deflateEnd*(strm: var TZStream): int32{.cdecl, dynlib: libz, 
    importc: "deflateEnd".}
proc inflate*(strm: var TZStream, flush: int32): int32{.cdecl, dynlib: libz, 
    importc: "inflate".}
proc inflateEnd*(strm: var TZStream): int32{.cdecl, dynlib: libz, 
    importc: "inflateEnd".}
proc deflateSetDictionary*(strm: var TZStream, dictionary: pbytef, 
                           dictLength: uInt): int32{.cdecl, dynlib: libz, 
    importc: "deflateSetDictionary".}
proc deflateCopy*(dest, source: var TZstream): int32{.cdecl, dynlib: libz, 
    importc: "deflateCopy".}
proc deflateReset*(strm: var TZStream): int32{.cdecl, dynlib: libz, 
    importc: "deflateReset".}
proc deflateParams*(strm: var TZStream, level: int32, strategy: int32): int32{.
    cdecl, dynlib: libz, importc: "deflateParams".}
proc inflateSetDictionary*(strm: var TZStream, dictionary: pbytef, 
                           dictLength: uInt): int32{.cdecl, dynlib: libz, 
    importc: "inflateSetDictionary".}
proc inflateSync*(strm: var TZStream): int32{.cdecl, dynlib: libz, 
    importc: "inflateSync".}
proc inflateReset*(strm: var TZStream): int32{.cdecl, dynlib: libz, 
    importc: "inflateReset".}
proc compress*(dest: pbytef, destLen: puLongf, source: pbytef, sourceLen: uLong): cint{.
    cdecl, dynlib: libz, importc: "compress".}
proc compress2*(dest: pbytef, destLen: puLongf, source: pbytef, 
                sourceLen: uLong, level: cint): cint{.cdecl, dynlib: libz, 
    importc: "compress2".}
proc uncompress*(dest: pbytef, destLen: puLongf, source: pbytef, 
                 sourceLen: uLong): cint{.cdecl, dynlib: libz, 
    importc: "uncompress".}
proc compressBound*(sourceLen: uLong): uLong {.cdecl, dynlib: libz, importc.}
proc gzopen*(path: cstring, mode: cstring): gzFile{.cdecl, dynlib: libz, 
    importc: "gzopen".}
proc gzdopen*(fd: int32, mode: cstring): gzFile{.cdecl, dynlib: libz, 
    importc: "gzdopen".}
proc gzsetparams*(thefile: gzFile, level: int32, strategy: int32): int32{.cdecl, 
    dynlib: libz, importc: "gzsetparams".}
proc gzread*(thefile: gzFile, buf: pointer, length: int): int32{.cdecl, 
    dynlib: libz, importc: "gzread".}
proc gzwrite*(thefile: gzFile, buf: pointer, length: int): int32{.cdecl, 
    dynlib: libz, importc: "gzwrite".}
proc gzprintf*(thefile: gzFile, format: pbytef): int32{.varargs, cdecl, 
    dynlib: libz, importc: "gzprintf".}
proc gzputs*(thefile: gzFile, s: pbytef): int32{.cdecl, dynlib: libz, 
    importc: "gzputs".}
proc gzgets*(thefile: gzFile, buf: pbytef, length: int32): pbytef{.cdecl, 
    dynlib: libz, importc: "gzgets".}
proc gzputc*(thefile: gzFile, c: char): char{.cdecl, dynlib: libz, 
    importc: "gzputc".}
proc gzgetc*(thefile: gzFile): char{.cdecl, dynlib: libz, importc: "gzgetc".}
proc gzflush*(thefile: gzFile, flush: int32): int32{.cdecl, dynlib: libz, 
    importc: "gzflush".}
proc gzseek*(thefile: gzFile, offset: z_off_t, whence: int32): z_off_t{.cdecl, 
    dynlib: libz, importc: "gzseek".}
proc gzrewind*(thefile: gzFile): int32{.cdecl, dynlib: libz, importc: "gzrewind".}
proc gztell*(thefile: gzFile): z_off_t{.cdecl, dynlib: libz, importc: "gztell".}
proc gzeof*(thefile: gzFile): int {.cdecl, dynlib: libz, importc: "gzeof".}
proc gzclose*(thefile: gzFile): int32{.cdecl, dynlib: libz, importc: "gzclose".}
proc gzerror*(thefile: gzFile, errnum: var int32): pbytef{.cdecl, dynlib: libz, 
    importc: "gzerror".}
proc adler32*(adler: uLong, buf: pbytef, length: uInt): uLong{.cdecl, 
    dynlib: libz, importc: "adler32".}
  ## **Warning**: Adler-32 requires at least a few hundred bytes to get rolling.
proc crc32*(crc: uLong, buf: pbytef, length: uInt): uLong{.cdecl, dynlib: libz, 
    importc: "crc32".}
proc deflateInitu*(strm: var TZStream, level: int32, version: cstring, 
                   stream_size: int32): int32{.cdecl, dynlib: libz, 
    importc: "deflateInit_".}
proc inflateInitu*(strm: var TZStream, version: cstring,
                   stream_size: int32): int32 {.
    cdecl, dynlib: libz, importc: "inflateInit_".}
proc deflateInit*(strm: var TZStream, level: int32): int32
proc inflateInit*(strm: var TZStream): int32
proc deflateInit2u*(strm: var TZStream, level: int32, `method`: int32, 
                    windowBits: int32, memLevel: int32, strategy: int32, 
                    version: cstring, stream_size: int32): int32 {.cdecl, 
                    dynlib: libz, importc: "deflateInit2_".}
proc inflateInit2u*(strm: var TZStream, windowBits: int32, version: cstring, 
                    stream_size: int32): int32{.cdecl, dynlib: libz, 
    importc: "inflateInit2_".}
proc deflateInit2*(strm: var TZStream, 
                   level, `method`, windowBits, memLevel,
                   strategy: int32): int32
proc inflateInit2*(strm: var TZStream, windowBits: int32): int32
proc zError*(err: int32): cstring{.cdecl, dynlib: libz, importc: "zError".}
proc inflateSyncPoint*(z: PZstream): int32{.cdecl, dynlib: libz, 
    importc: "inflateSyncPoint".}
proc get_crc_table*(): pointer{.cdecl, dynlib: libz, importc: "get_crc_table".}

proc deflateInit(strm: var TZStream, level: int32): int32 = 
  result = deflateInitu(strm, level, ZLIB_VERSION(), sizeof(TZStream).cint)

proc inflateInit(strm: var TZStream): int32 = 
  result = inflateInitu(strm, ZLIB_VERSION(), sizeof(TZStream).cint)

proc deflateInit2(strm: var TZStream, 
                  level, `method`, windowBits, memLevel,
                  strategy: int32): int32 = 
  result = deflateInit2u(strm, level, `method`, windowBits, memLevel, 
                         strategy, ZLIB_VERSION(), sizeof(TZStream).cint)

proc inflateInit2(strm: var TZStream, windowBits: int32): int32 = 
  result = inflateInit2u(strm, windowBits, ZLIB_VERSION(), 
                         sizeof(TZStream).cint)

proc zlibAllocMem*(AppData: Pointer, Items, Size: int): Pointer {.cdecl.} = 
  result = Alloc(Items * Size)

proc zlibFreeMem*(AppData, `Block`: Pointer) {.cdecl.} = 
  dealloc(`Block`)
