#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides a stream interface and two implementations thereof:
## the `FileStream` and the `StringStream` which implement the stream
## interface for Nim file objects (`File`) and strings. Other modules
## may provide other implementations for this standard stream interface.
##
## Examples:
##
## .. code-block:: Nim
##
##  import streams
##  var
##    ss = newStringStream("""The first line
##  the second line
##  the third line""")
##    line = ""
##  while ss.readLine(line):
##    echo line
##  ss.close()
##
##  var fs = newFileStream("somefile.txt", fmRead)
##  if not isNil(fs):
##    while fs.readLine(line):
##      echo line
##    fs.close()

include "system/inclrtl"

proc newEIO(msg: string): ref IOError =
  new(result)
  result.msg = msg

type
  Stream* = ref StreamObj
  StreamObj* = object of RootObj ## Stream interface that supports
                                 ## writing or reading. Note that these fields
                                 ## here shouldn't be used directly. They are
                                 ## accessible so that a stream implementation
                                 ## can override them.
    closeImpl*: proc (s: Stream) {.nimcall, tags: [], gcsafe.}
    atEndImpl*: proc (s: Stream): bool {.nimcall, tags: [], gcsafe.}
    setPositionImpl*: proc (s: Stream, pos: int) {.nimcall, tags: [], gcsafe.}
    getPositionImpl*: proc (s: Stream): int {.nimcall, tags: [], gcsafe.}
    readDataImpl*: proc (s: Stream, buffer: pointer,
                         bufLen: int): int {.nimcall, tags: [ReadIOEffect], gcsafe.}
    peekDataImpl*: proc (s: Stream, buffer: pointer,
                         bufLen: int): int {.nimcall, tags: [ReadIOEffect], gcsafe.}
    writeDataImpl*: proc (s: Stream, buffer: pointer, bufLen: int) {.nimcall,
      tags: [WriteIOEffect], gcsafe.}
    flushImpl*: proc (s: Stream) {.nimcall, tags: [WriteIOEffect], gcsafe.}

{.deprecated: [PStream: Stream, TStream: StreamObj].}

proc flush*(s: Stream) =
  ## flushes the buffers that the stream `s` might use.
  if not isNil(s.flushImpl): s.flushImpl(s)

proc close*(s: Stream) =
  ## closes the stream `s`.
  if not isNil(s.closeImpl): s.closeImpl(s)

proc close*(s, unused: Stream) {.deprecated.} =
  ## closes the stream `s`.
  s.closeImpl(s)

proc atEnd*(s: Stream): bool =
  ## checks if more data can be read from `f`. Returns true if all data has
  ## been read.
  result = s.atEndImpl(s)

proc atEnd*(s, unused: Stream): bool {.deprecated.} =
  ## checks if more data can be read from `f`. Returns true if all data has
  ## been read.
  result = s.atEndImpl(s)

proc setPosition*(s: Stream, pos: int) =
  ## sets the position `pos` of the stream `s`.
  s.setPositionImpl(s, pos)

proc setPosition*(s, unused: Stream, pos: int) {.deprecated.} =
  ## sets the position `pos` of the stream `s`.
  s.setPositionImpl(s, pos)

proc getPosition*(s: Stream): int =
  ## retrieves the current position in the stream `s`.
  result = s.getPositionImpl(s)

proc getPosition*(s, unused: Stream): int {.deprecated.} =
  ## retrieves the current position in the stream `s`.
  result = s.getPositionImpl(s)

proc readData*(s: Stream, buffer: pointer, bufLen: int): int =
  ## low level proc that reads data into an untyped `buffer` of `bufLen` size.
  result = s.readDataImpl(s, buffer, bufLen)

proc readAll*(s: Stream): string =
  ## Reads all available data.
  const bufferSize = 1000
  result = newString(bufferSize)
  var r = 0
  while true:
    let readBytes = readData(s, addr(result[r]), bufferSize)
    if readBytes < bufferSize:
      setLen(result, r+readBytes)
      break
    inc r, bufferSize
    setLen(result, r+bufferSize)

proc readData*(s, unused: Stream, buffer: pointer,
               bufLen: int): int {.deprecated.} =
  ## low level proc that reads data into an untyped `buffer` of `bufLen` size.
  result = s.readDataImpl(s, buffer, bufLen)

proc peekData*(s: Stream, buffer: pointer, bufLen: int): int =
  ## low level proc that reads data into an untyped `buffer` of `bufLen` size
  ## without moving stream position
  result = s.peekDataImpl(s, buffer, bufLen)

proc writeData*(s: Stream, buffer: pointer, bufLen: int) =
  ## low level proc that writes an untyped `buffer` of `bufLen` size
  ## to the stream `s`.
  s.writeDataImpl(s, buffer, bufLen)

proc writeData*(s, unused: Stream, buffer: pointer,
                bufLen: int) {.deprecated.} =
  ## low level proc that writes an untyped `buffer` of `bufLen` size
  ## to the stream `s`.
  s.writeDataImpl(s, buffer, bufLen)

proc write*[T](s: Stream, x: T) =
  ## generic write procedure. Writes `x` to the stream `s`. Implementation:
  ##
  ## .. code-block:: Nim
  ##
  ##     s.writeData(s, addr(x), sizeof(x))
  var y: T
  shallowCopy(y, x)
  writeData(s, addr(y), sizeof(y))

proc write*(s: Stream, x: string) =
  ## writes the string `x` to the the stream `s`. No length field or
  ## terminating zero is written.
  when nimvm:
    writeData(s, cstring(x), x.len)
  else:
    if x.len > 0: writeData(s, unsafeAddr x[0], x.len)

proc writeLn*(s: Stream, args: varargs[string, `$`]) {.deprecated.} =
  ## **Deprecated since version 0.11.4:** Use **writeLine** instead.
  for str in args: write(s, str)
  write(s, "\n")

proc writeLine*(s: Stream, args: varargs[string, `$`]) =
  ## writes one or more strings to the the stream `s` followed
  ## by a new line. No length field or terminating zero is written.
  for str in args: write(s, str)
  write(s, "\n")

proc read[T](s: Stream, result: var T) =
  ## generic read procedure. Reads `result` from the stream `s`.
  if readData(s, addr(result), sizeof(T)) != sizeof(T):
    raise newEIO("cannot read from stream")

proc peek[T](s: Stream, result: var T) =
  ## generic peek procedure. Peeks `result` from the stream `s`.
  if peekData(s, addr(result), sizeof(T)) != sizeof(T):
    raise newEIO("cannot read from stream")

proc readChar*(s: Stream): char =
  ## reads a char from the stream `s`. Raises `EIO` if an error occurred.
  ## Returns '\0' as an EOF marker.
  if readData(s, addr(result), sizeof(result)) != 1: result = '\0'

proc peekChar*(s: Stream): char =
  ## peeks a char from the stream `s`. Raises `EIO` if an error occurred.
  ## Returns '\0' as an EOF marker.
  if peekData(s, addr(result), sizeof(result)) != 1: result = '\0'

proc readBool*(s: Stream): bool =
  ## reads a bool from the stream `s`. Raises `EIO` if an error occurred.
  read(s, result)

proc peekBool*(s: Stream): bool =
  ## peeks a bool from the stream `s`. Raises `EIO` if an error occurred.
  peek(s, result)

proc readInt8*(s: Stream): int8 =
  ## reads an int8 from the stream `s`. Raises `EIO` if an error occurred.
  read(s, result)

proc peekInt8*(s: Stream): int8 =
  ## peeks an int8 from the stream `s`. Raises `EIO` if an error occurred.
  peek(s, result)

proc readInt16*(s: Stream): int16 =
  ## reads an int16 from the stream `s`. Raises `EIO` if an error occurred.
  read(s, result)

proc peekInt16*(s: Stream): int16 =
  ## peeks an int16 from the stream `s`. Raises `EIO` if an error occurred.
  peek(s, result)

proc readInt32*(s: Stream): int32 =
  ## reads an int32 from the stream `s`. Raises `EIO` if an error occurred.
  read(s, result)

proc peekInt32*(s: Stream): int32 =
  ## peeks an int32 from the stream `s`. Raises `EIO` if an error occurred.
  peek(s, result)

proc readInt64*(s: Stream): int64 =
  ## reads an int64 from the stream `s`. Raises `EIO` if an error occurred.
  read(s, result)

proc peekInt64*(s: Stream): int64 =
  ## peeks an int64 from the stream `s`. Raises `EIO` if an error occurred.
  peek(s, result)

proc readUint8*(s: Stream): uint8 =
  ## reads an uint8 from the stream `s`. Raises `EIO` if an error occurred.
  read(s, result)

proc peekUint8*(s: Stream): uint8 =
  ## peeks an uint8 from the stream `s`. Raises `EIO` if an error occurred.
  peek(s, result)

proc readUint16*(s: Stream): uint16 =
  ## reads an uint16 from the stream `s`. Raises `EIO` if an error occurred.
  read(s, result)

proc peekUint16*(s: Stream): uint16 =
  ## peeks an uint16 from the stream `s`. Raises `EIO` if an error occurred.
  peek(s, result)

proc readUint32*(s: Stream): uint32 =
  ## reads an uint32 from the stream `s`. Raises `EIO` if an error occurred.
  read(s, result)

proc peekUint32*(s: Stream): uint32 =
  ## peeks an uint32 from the stream `s`. Raises `EIO` if an error occurred.
  peek(s, result)

proc readUint64*(s: Stream): uint64 =
  ## reads an uint64 from the stream `s`. Raises `EIO` if an error occurred.
  read(s, result)

proc peekUint64*(s: Stream): uint64 =
  ## peeks an uint64 from the stream `s`. Raises `EIO` if an error occurred.
  peek(s, result)

proc readFloat32*(s: Stream): float32 =
  ## reads a float32 from the stream `s`. Raises `EIO` if an error occurred.
  read(s, result)

proc peekFloat32*(s: Stream): float32 =
  ## peeks a float32 from the stream `s`. Raises `EIO` if an error occurred.
  peek(s, result)

proc readFloat64*(s: Stream): float64 =
  ## reads a float64 from the stream `s`. Raises `EIO` if an error occurred.
  read(s, result)

proc peekFloat64*(s: Stream): float64 =
  ## peeks a float64 from the stream `s`. Raises `EIO` if an error occurred.
  peek(s, result)

proc readStr*(s: Stream, length: int): TaintedString =
  ## reads a string of length `length` from the stream `s`. Raises `EIO` if
  ## an error occurred.
  result = newString(length).TaintedString
  var L = readData(s, addr(string(result)[0]), length)
  if L != length: setLen(result.string, L)

proc peekStr*(s: Stream, length: int): TaintedString =
  ## peeks a string of length `length` from the stream `s`. Raises `EIO` if
  ## an error occurred.
  result = newString(length).TaintedString
  var L = peekData(s, addr(string(result)[0]), length)
  if L != length: setLen(result.string, L)

proc readLine*(s: Stream, line: var TaintedString): bool =
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

proc peekLine*(s: Stream, line: var TaintedString): bool =
  ## peeks a line of text from the stream `s` into `line`. `line` must not be
  ## ``nil``! May throw an IO exception.
  ## A line of text may be delimited by ``CR``, ``LF`` or
  ## ``CRLF``. The newline character(s) are not part of the returned string.
  ## Returns ``false`` if the end of the file has been reached, ``true``
  ## otherwise. If ``false`` is returned `line` contains no new data.
  let pos = getPosition(s)
  defer: setPosition(s, pos)
  result = readLine(s, line)

proc readLine*(s: Stream): TaintedString =
  ## Reads a line from a stream `s`. Note: This is not very efficient. Raises
  ## `EIO` if an error occurred.
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

proc peekLine*(s: Stream): TaintedString =
  ## Peeks a line from a stream `s`. Note: This is not very efficient. Raises
  ## `EIO` if an error occurred.
  let pos = getPosition(s)
  defer: setPosition(s, pos)
  result = readLine(s)

when not defined(js):

  type
    StringStream* = ref StringStreamObj ## a stream that encapsulates a string
    StringStreamObj* = object of StreamObj
      data*: string
      pos: int

  {.deprecated: [PStringStream: StringStream, TStringStream: StringStreamObj].}

  proc ssAtEnd(s: Stream): bool =
    var s = StringStream(s)
    return s.pos >= s.data.len

  proc ssSetPosition(s: Stream, pos: int) =
    var s = StringStream(s)
    s.pos = clamp(pos, 0, s.data.len)

  proc ssGetPosition(s: Stream): int =
    var s = StringStream(s)
    return s.pos

  proc ssReadData(s: Stream, buffer: pointer, bufLen: int): int =
    var s = StringStream(s)
    result = min(bufLen, s.data.len - s.pos)
    if result > 0:
      copyMem(buffer, addr(s.data[s.pos]), result)
      inc(s.pos, result)
    else:
      result = 0

  proc ssPeekData(s: Stream, buffer: pointer, bufLen: int): int =
    var s = StringStream(s)
    result = min(bufLen, s.data.len - s.pos)
    if result > 0:
      copyMem(buffer, addr(s.data[s.pos]), result)
    else:
      result = 0

  proc ssWriteData(s: Stream, buffer: pointer, bufLen: int) =
    var s = StringStream(s)
    if bufLen <= 0:
      return
    if s.pos + bufLen > s.data.len:
      setLen(s.data, s.pos + bufLen)
    copyMem(addr(s.data[s.pos]), buffer, bufLen)
    inc(s.pos, bufLen)

  proc ssClose(s: Stream) =
    var s = StringStream(s)
    s.data = nil

  proc newStringStream*(s: string = ""): StringStream =
    ## creates a new stream from the string `s`.
    new(result)
    result.data = s
    result.pos = 0
    result.closeImpl = ssClose
    result.atEndImpl = ssAtEnd
    result.setPositionImpl = ssSetPosition
    result.getPositionImpl = ssGetPosition
    result.readDataImpl = ssReadData
    result.peekDataImpl = ssPeekData
    result.writeDataImpl = ssWriteData

  type
    FileStream* = ref FileStreamObj ## a stream that encapsulates a `File`
    FileStreamObj* = object of Stream
      f: File
  {.deprecated: [PFileStream: FileStream, TFileStream: FileStreamObj].}

  proc fsClose(s: Stream) =
    if FileStream(s).f != nil:
      close(FileStream(s).f)
      FileStream(s).f = nil
  proc fsFlush(s: Stream) = flushFile(FileStream(s).f)
  proc fsAtEnd(s: Stream): bool = return endOfFile(FileStream(s).f)
  proc fsSetPosition(s: Stream, pos: int) = setFilePos(FileStream(s).f, pos)
  proc fsGetPosition(s: Stream): int = return int(getFilePos(FileStream(s).f))

  proc fsReadData(s: Stream, buffer: pointer, bufLen: int): int =
    result = readBuffer(FileStream(s).f, buffer, bufLen)

  proc fsPeekData(s: Stream, buffer: pointer, bufLen: int): int =
    let pos = fsGetPosition(s)
    defer: fsSetPosition(s, pos)
    result = readBuffer(FileStream(s).f, buffer, bufLen)

  proc fsWriteData(s: Stream, buffer: pointer, bufLen: int) =
    if writeBuffer(FileStream(s).f, buffer, bufLen) != bufLen:
      raise newEIO("cannot write to stream")

  proc newFileStream*(f: File): FileStream =
    ## creates a new stream from the file `f`.
    new(result)
    result.f = f
    result.closeImpl = fsClose
    result.atEndImpl = fsAtEnd
    result.setPositionImpl = fsSetPosition
    result.getPositionImpl = fsGetPosition
    result.readDataImpl = fsReadData
    result.peekDataImpl = fsPeekData
    result.writeDataImpl = fsWriteData
    result.flushImpl = fsFlush

  proc newFileStream*(filename: string, mode: FileMode = fmRead, bufSize: int = -1): FileStream =
    ## creates a new stream from the file named `filename` with the mode `mode`.
    ## If the file cannot be opened, nil is returned. See the `system
    ## <system.html>`_ module for a list of available FileMode enums.
    var f: File
    if open(f, filename, mode, bufSize): result = newFileStream(f)


when true:
  discard
else:
  type
    FileHandleStream* = ref FileHandleStreamObj
    FileHandleStreamObj* = object of Stream
      handle*: FileHandle
      pos: int

  {.deprecated: [PFileHandleStream: FileHandleStream,
     TFileHandleStream: FileHandleStreamObj].}

  proc newEOS(msg: string): ref OSError =
    new(result)
    result.msg = msg

  proc hsGetPosition(s: FileHandleStream): int =
    return s.pos

  when defined(windows):
    # do not import windows as this increases compile times:
    discard
  else:
    import posix

    proc hsSetPosition(s: FileHandleStream, pos: int) =
      discard lseek(s.handle, pos, SEEK_SET)

    proc hsClose(s: FileHandleStream) = discard close(s.handle)
    proc hsAtEnd(s: FileHandleStream): bool =
      var pos = hsGetPosition(s)
      var theEnd = lseek(s.handle, 0, SEEK_END)
      result = pos >= theEnd
      hsSetPosition(s, pos) # set position back

    proc hsReadData(s: FileHandleStream, buffer: pointer, bufLen: int): int =
      result = posix.read(s.handle, buffer, bufLen)
      inc(s.pos, result)

    proc hsPeekData(s: FileHandleStream, buffer: pointer, bufLen: int): int =
      result = posix.read(s.handle, buffer, bufLen)

    proc hsWriteData(s: FileHandleStream, buffer: pointer, bufLen: int) =
      if posix.write(s.handle, buffer, bufLen) != bufLen:
        raise newEIO("cannot write to stream")
      inc(s.pos, bufLen)

  proc newFileHandleStream*(handle: FileHandle): FileHandleStream =
    new(result)
    result.handle = handle
    result.pos = 0
    result.close = hsClose
    result.atEnd = hsAtEnd
    result.setPosition = hsSetPosition
    result.getPosition = hsGetPosition
    result.readData = hsReadData
    result.peekData = hsPeekData
    result.writeData = hsWriteData

  proc newFileHandleStream*(filename: string,
                            mode: FileMode): FileHandleStream =
    when defined(windows):
      discard
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

when isMainModule and defined(testing):
  var ss = newStringStream("The quick brown fox jumped over the lazy dog.\nThe lazy dog ran")
  assert(ss.getPosition == 0)
  assert(ss.peekStr(5) == "The q")
  assert(ss.getPosition == 0) # haven't moved
  assert(ss.readStr(5) == "The q")
  assert(ss.getPosition == 5) # did move
  assert(ss.peekLine() == "uick brown fox jumped over the lazy dog.")
  assert(ss.getPosition == 5) # haven't moved
  var str = newString(100)
  assert(ss.peekLine(str))
  assert(str == "uick brown fox jumped over the lazy dog.")
  assert(ss.getPosition == 5) # haven't moved
