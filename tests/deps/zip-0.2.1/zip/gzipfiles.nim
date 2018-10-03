import os
import zlib
import streams
export streams

## This module implements a gzipfile stream for reading, writing, appending.

type
    GzFileStream* = ref object of Stream
        mode: FileMode
        f: GzFile

const SEEK_SET = 0.int32 # Seek from beginning of file.

proc fsClose(s: Stream) =
    if not GzFileStream(s).f.isNil:
      discard gzclose(GzFileStream(s).f)
      GzFileStream(s).f = nil

proc fsFlush(s: Stream) =
    # compiler flushFile also discard c_fflush
    discard gzflush(GzFileStream(s).f, Z_FINISH)

proc fsAtEnd(s: Stream): bool =
    result = gzeof(GzFileStream(s).f) == 1

proc fsSetPosition(s: Stream, pos: int) =
    if gzseek(GzFileStream(s).f, pos.ZOffT, SEEK_SET) == -1:
        if GzFileStream(s).mode in {fmWrite, fmAppend}:
            raise newException(IOError, "error in gzip stream while seeking! (file is in write/append mode!")
        else:
            raise newException(IOError, "error in gzip stream while seeking!")

proc fsGetPosition(s: Stream): int =
    result = gztell(GzFileStream(s).f).int

proc fsReadData(s: Stream, buffer: pointer, bufLen: int): int =
    result = gzread(GzFileStream(s).f, buffer, bufLen).int
    if result == -1:
        if GzFileStream(s).mode in {fmWrite, fmAppend}:
            raise newException(IOError, "cannot read data from write-only gzip stream!")
        else:
            raise newException(IOError, "cannot read from stream!")

proc fsPeekData(s: Stream, buffer: pointer, bufLen: int): int =
    let gz = GzFileStream(s)
    if gz.mode in {fmWrite, fmAppend}:
        raise newException(IOError, "cannot peek data from write-only gzip stream!")
    let pos = int(gztell(gz.f))
    result = fsReadData(s, buffer, bufLen)
    fsSetPosition(s, pos)

proc fsWriteData(s: Stream, buffer: pointer, bufLen: int) =
    if gzwrite(GzFileStream(s).f, buffer, bufLen).int != bufLen:
        if GzFileStream(s).mode in {fmWrite, fmAppend}:
            raise newException(IOError, "cannot write data to gzip stream!")
        else:
            raise newException(IOError, "cannot write data to read-only gzip stream!")


proc newGzFileStream*(filename: string; mode=fmRead; level=Z_DEFAULT_COMPRESSION): GzFileStream =
    ## Opens a Gzipfile as a file stream. `mode` can be
    ## ``fmRead``, ``fmWrite`` or ``fmAppend``.
    ##
    ## Compression level can be set with ``level`` argument. Currently
    ## ``Z_DEFAULT_COMPRESSION`` is 6.
    ##
    ## Note: ``level`` is ignored if ``mode`` is `fmRead`
    ##
    ## Note: There is only partial support for file seeking
    ##  - in fmRead mode, seeking randomly inside the gzip
    ## file will lead to poor performance.
    ##  - in fmWrite, fmAppend mode, only forward seeking
    ## is supported.
    new(result)
    case mode
    of fmRead: result.f = gzopen(filename, "rb")
    of fmWrite: result.f = gzopen(filename, "wb")
    of fmAppend: result.f = gzopen(filename, "ab")
    else: raise newException(IOError, "unsupported file mode '" & $mode &
                            "' for GzFileStream!")
    if result.f.isNil:
        let err = osLastError()
        if err != OSErrorCode(0'i32):
            raiseOSError(err)
    if mode in {fmWrite, fmAppend}:
        discard gzsetparams(result.f, level.int32, Z_DEFAULT_STRATEGY.int32)

    result.mode = mode
    result.closeImpl = fsClose
    result.atEndImpl = fsAtEnd
    result.setPositionImpl = fsSetPosition
    result.getPositionImpl = fsGetPosition
    result.readDataImpl = fsReadData
    result.peekDataImpl = fsPeekData
    result.writeDataImpl = fsWriteData
    result.flushImpl = fsFlush
