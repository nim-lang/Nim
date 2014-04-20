#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides a stream interface and two implementations thereof:
## the `PFileStream` and the `PStringStream` which implement the stream
## interface for Nimrod file objects (`TFile`) and strings. Other modules
## may provide other implementations for this standard stream interface.

include "system/inclrtl"

proc newEIO(msg: string): ref EIO =
  new(result)
  result.msg = msg

type
  PStream* = ref TStream
  TStream* = object of TObject ## Stream interface that supports
                               ## writing or reading. Note that these fields
                               ## here shouldn't be used directly. They are
                               ## accessible so that a stream implementation
                               ## can override them.
    closeImpl*: proc (s: PStream) {.nimcall, tags: [], gcsafe.}
    atEndImpl*: proc (s: PStream): bool {.nimcall, tags: [], gcsafe.}
    setPositionImpl*: proc (s: PStream, pos: int) {.nimcall, tags: [], gcsafe.}
    getPositionImpl*: proc (s: PStream): int {.nimcall, tags: [], gcsafe.}
    readDataImpl*: proc (s: PStream, buffer: pointer,
                         bufLen: int): int {.nimcall, tags: [FReadIO], gcsafe.}
    writeDataImpl*: proc (s: PStream, buffer: pointer, bufLen: int) {.nimcall,
      tags: [FWriteIO], gcsafe.}
    flushImpl*: proc (s: PStream) {.nimcall, tags: [FWriteIO], gcsafe.}

proc flush*(s: PStream) =
  ## flushes the buffers that the stream `s` might use.
  if not isNil(s.flushImpl): s.flushImpl(s)

proc close*(s: PStream) =
  ## closes the stream `s`.
  if not isNil(s.closeImpl): s.closeImpl(s)

proc close*(s, unused: PStream) {.deprecated.} =
  ## closes the stream `s`.
  s.closeImpl(s)

proc atEnd*(s: PStream): bool =
  ## checks if more data can be read from `f`. Returns true if all data has
  ## been read.
  result = s.atEndImpl(s)

proc atEnd*(s, unused: PStream): bool {.deprecated.} =
  ## checks if more data can be read from `f`. Returns true if all data has
  ## been read.
  result = s.atEndImpl(s)

proc setPosition*(s: PStream, pos: int) =
  ## sets the position `pos` of the stream `s`.
  s.setPositionImpl(s, pos)

proc setPosition*(s, unused: PStream, pos: int) {.deprecated.} =
  ## sets the position `pos` of the stream `s`.
  s.setPositionImpl(s, pos)

proc getPosition*(s: PStream): int =
  ## retrieves the current position in the stream `s`.
  result = s.getPositionImpl(s)

proc getPosition*(s, unused: PStream): int {.deprecated.} =
  ## retrieves the current position in the stream `s`.
  result = s.getPositionImpl(s)

proc readData*(s: PStream, buffer: pointer, bufLen: int): int =
  ## low level proc that reads data into an untyped `buffer` of `bufLen` size.
  result = s.readDataImpl(s, buffer, bufLen)

proc readData*(s, unused: PStream, buffer: pointer, 
               bufLen: int): int {.deprecated.} =
  ## low level proc that reads data into an untyped `buffer` of `bufLen` size.
  result = s.readDataImpl(s, buffer, bufLen)

proc writeData*(s: PStream, buffer: pointer, bufLen: int) =
  ## low level proc that writes an untyped `buffer` of `bufLen` size
  ## to the stream `s`.
  s.writeDataImpl(s, buffer, bufLen)

proc writeData*(s, unused: PStream, buffer: pointer, 
                bufLen: int) {.deprecated.} =
  ## low level proc that writes an untyped `buffer` of `bufLen` size
  ## to the stream `s`.
  s.writeDataImpl(s, buffer, bufLen)

proc write*[T](s: PStream, x: T) = 
  ## generic write procedure. Writes `x` to the stream `s`. Implementation:
  ##
  ## .. code-block:: Nimrod
  ##
  ##     s.writeData(s, addr(x), sizeof(x))
  var y: T
  shallowCopy(y, x)
  writeData(s, addr(y), sizeof(y))

proc write*(s: PStream, x: string) = 
  ## writes the string `x` to the the stream `s`. No length field or 
  ## terminating zero is written.
  writeData(s, cstring(x), x.len)

proc writeln*(s: PStream, args: varargs[string, `$`]) =
  ## writes one or more strings to the the stream `s` followed
  ## by a new line. No length field or terminating zero is written.
  for str in args: write(s, str)
  write(s, "\n")

proc read[T](s: PStream, result: var T) = 
  ## generic read procedure. Reads `result` from the stream `s`.
  if readData(s, addr(result), sizeof(T)) != sizeof(T):
    raise newEIO("cannot read from stream")

proc readChar*(s: PStream): char =
  ## reads a char from the stream `s`. Raises `EIO` if an error occured.
  ## Returns '\0' as an EOF marker.
  if readData(s, addr(result), sizeof(result)) != 1: result = '\0'

proc readBool*(s: PStream): bool = 
  ## reads a bool from the stream `s`. Raises `EIO` if an error occured.
  read(s, result)

proc readInt8*(s: PStream): int8 = 
  ## reads an int8 from the stream `s`. Raises `EIO` if an error occured.
  read(s, result)

proc readInt16*(s: PStream): int16 = 
  ## reads an int16 from the stream `s`. Raises `EIO` if an error occured.
  read(s, result)

proc readInt32*(s: PStream): int32 = 
  ## reads an int32 from the stream `s`. Raises `EIO` if an error occured.
  read(s, result)

proc readInt64*(s: PStream): int64 = 
  ## reads an int64 from the stream `s`. Raises `EIO` if an error occured.
  read(s, result)

proc readFloat32*(s: PStream): float32 = 
  ## reads a float32 from the stream `s`. Raises `EIO` if an error occured.
  read(s, result)

proc readFloat64*(s: PStream): float64 = 
  ## reads a float64 from the stream `s`. Raises `EIO` if an error occured.
  read(s, result)

proc readStr*(s: PStream, length: int): TaintedString = 
  ## reads a string of length `length` from the stream `s`. Raises `EIO` if 
  ## an error occured.
  result = newString(length).TaintedString
  var L = readData(s, addr(string(result)[0]), length)
  if L != length: setLen(result.string, L)

proc readLine*(s: PStream, line: var TaintedString): bool =
  ## reads a line of text from the stream `s` into `line`. `line` must not be
  ## ``nil``! May throw an IO exception.
  ## A line of text may be delimited by ``CR``, ``LF`` or
  ## ``CRLF``. The newline character(s) are not part of the returned string.
  ## Returns ``false`` if the end of the file has been reached, ``true``
  ## otherwise. If ``false`` is returned `line` contains no new data.
  line.string.setLen(0)
  while true:
    var c = readChar(s)
    if c == '\c': 
      c = readChar(s)
      break
    elif c == '\L': break
    elif c == '\0':
      if line.len > 0: break
      else: return false
    line.string.add(c)
  result = true

proc readLine*(s: PStream): TaintedString =
  ## Reads a line from a stream `s`. Note: This is not very efficient. Raises 
  ## `EIO` if an error occured.
  result = TaintedString""
  while true:
    var c = readChar(s)
    if c == '\c': 
      c = readChar(s)
      break
    if c == '\L' or c == '\0':
      break
    else:
      result.string.add(c)

type
  PStringStream* = ref TStringStream ## a stream that encapsulates a string
  TStringStream* = object of TStream
    data*: string
    pos: int
    
proc ssAtEnd(s: PStream): bool = 
  var s = PStringStream(s)
  return s.pos >= s.data.len
    
proc ssSetPosition(s: PStream, pos: int) = 
  var s = PStringStream(s)
  s.pos = clamp(pos, 0, s.data.high)

proc ssGetPosition(s: PStream): int =
  var s = PStringStream(s)
  return s.pos

proc ssReadData(s: PStream, buffer: pointer, bufLen: int): int =
  var s = PStringStream(s)
  result = min(bufLen, s.data.len - s.pos)
  if result > 0: 
    copyMem(buffer, addr(s.data[s.pos]), result)
    inc(s.pos, result)

proc ssWriteData(s: PStream, buffer: pointer, bufLen: int) = 
  var s = PStringStream(s)
  if bufLen > 0: 
    setLen(s.data, s.data.len + bufLen)
    copyMem(addr(s.data[s.pos]), buffer, bufLen)
    inc(s.pos, bufLen)

proc ssClose(s: PStream) =
  var s = PStringStream(s)
  s.data = nil

proc newStringStream*(s: string = ""): PStringStream = 
  ## creates a new stream from the string `s`.
  new(result)
  result.data = s
  result.pos = 0
  result.closeImpl = ssClose
  result.atEndImpl = ssAtEnd
  result.setPositionImpl = ssSetPosition
  result.getPositionImpl = ssGetPosition
  result.readDataImpl = ssReadData
  result.writeDataImpl = ssWriteData

when not defined(js):

  type
    PFileStream* = ref TFileStream ## a stream that encapsulates a `TFile`
    TFileStream* = object of TStream
      f: TFile

  proc fsClose(s: PStream) =
    if PFileStream(s).f != nil:
      close(PFileStream(s).f)
      PFileStream(s).f = nil
  proc fsFlush(s: PStream) = flushFile(PFileStream(s).f)
  proc fsAtEnd(s: PStream): bool = return endOfFile(PFileStream(s).f)
  proc fsSetPosition(s: PStream, pos: int) = setFilePos(PFileStream(s).f, pos)
  proc fsGetPosition(s: PStream): int = return int(getFilePos(PFileStream(s).f))

  proc fsReadData(s: PStream, buffer: pointer, bufLen: int): int =
    result = readBuffer(PFileStream(s).f, buffer, bufLen)

  proc fsWriteData(s: PStream, buffer: pointer, bufLen: int) =
    if writeBuffer(PFileStream(s).f, buffer, bufLen) != bufLen:
      raise newEIO("cannot write to stream")

  proc newFileStream*(f: TFile): PFileStream =
    ## creates a new stream from the file `f`.
    new(result)
    result.f = f
    result.closeImpl = fsClose
    result.atEndImpl = fsAtEnd
    result.setPositionImpl = fsSetPosition
    result.getPositionImpl = fsGetPosition
    result.readDataImpl = fsReadData
    result.writeDataImpl = fsWriteData
    result.flushImpl = fsFlush

  proc newFileStream*(filename: string, mode: TFileMode): PFileStream =
    ## creates a new stream from the file named `filename` with the mode `mode`.
    ## If the file cannot be opened, nil is returned. See the `system
    ## <system.html>`_ module for a list of available TFileMode enums.
    var f: TFile
    if open(f, filename, mode): result = newFileStream(f)


when true:
  discard
else:
  type
    TFileHandle* = cint ## Operating system file handle
    PFileHandleStream* = ref TFileHandleStream
    TFileHandleStream* = object of TStream
      handle*: TFileHandle
      pos: int

  proc newEOS(msg: string): ref EOS =
    new(result)
    result.msg = msg

  proc hsGetPosition(s: PFileHandleStream): int = 
    return s.pos

  when defined(windows):
    # do not import windows as this increases compile times:
    nil
  else:
    import posix
    
    proc hsSetPosition(s: PFileHandleStream, pos: int) = 
      discard lseek(s.handle, pos, SEEK_SET)

    proc hsClose(s: PFileHandleStream) = discard close(s.handle)
    proc hsAtEnd(s: PFileHandleStream): bool = 
      var pos = hsGetPosition(s)
      var theEnd = lseek(s.handle, 0, SEEK_END)
      result = pos >= theEnd
      hsSetPosition(s, pos) # set position back

    proc hsReadData(s: PFileHandleStream, buffer: pointer, bufLen: int): int = 
      result = posix.read(s.handle, buffer, bufLen)
      inc(s.pos, result)
      
    proc hsWriteData(s: PFileHandleStream, buffer: pointer, bufLen: int) = 
      if posix.write(s.handle, buffer, bufLen) != bufLen: 
        raise newEIO("cannot write to stream")
      inc(s.pos, bufLen)

  proc newFileHandleStream*(handle: TFileHandle): PFileHandleStream = 
    new(result)
    result.handle = handle
    result.pos = 0
    result.close = hsClose
    result.atEnd = hsAtEnd
    result.setPosition = hsSetPosition
    result.getPosition = hsGetPosition
    result.readData = hsReadData
    result.writeData = hsWriteData

  proc newFileHandleStream*(filename: string, 
                            mode: TFileMode): PFileHandleStream = 
    when defined(windows): 
      nil
    else:
      var flags: cint
      case mode
      of fmRead:              flags = posix.O_RDONLY
      of fmWrite:             flags = O_WRONLY or int(O_CREAT)
      of fmReadWrite:         flags = O_RDWR or int(O_CREAT)
      of fmReadWriteExisting: flags = O_RDWR
      of fmAppend:            flags = O_WRONLY or int(O_CREAT) or O_APPEND
      var handle = open(filename, flags)
      if handle < 0: raise newEOS("posix.open() call failed")
    result = newFileHandleStream(handle)
