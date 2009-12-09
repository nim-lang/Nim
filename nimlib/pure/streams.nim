#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides a stream interface and two implementations thereof:
## the `PFileStream` and the `PStringStream` which implement the stream
## interface for Nimrod file objects (`TFile`) and strings. Other modules
## may provide other implementations for this standard stream interface.

proc newEIO(msg: string): ref EIO =
  new(result)
  result.msg = msg

type
  PStream* = ref TStream
  TStream* = object of TObject ## Stream interface that supports
                               ## writing or reading.
    close*: proc (s: PStream)
    atEnd*: proc (s: PStream): bool
    setPosition*: proc (s: PStream, pos: int)
    getPosition*: proc (s: PStream): int
    readData*: proc (s: PStream, buffer: pointer, bufLen: int): int
    writeData*: proc (s: PStream, buffer: pointer, bufLen: int)

proc write*[T](s: PStream, x: T) = 
  ## generic write procedure. Writes `x` to the stream `s`. Implementation:
  ##
  ## .. code-block:: Nimrod
  ##
  ##     s.writeData(s, addr(x), sizeof(x))
  var x = x
  s.writeData(s, addr(x), sizeof(x))

proc write*(s: PStream, x: string) = 
  ## writes the string `x` to the the stream `s`. No length field or 
  ## terminating zero is written.
  s.writeData(s, cstring(x), x.len)

proc read[T](s: PStream, result: var T) = 
  ## generic read procedure. Reads `result` from the stream `s`.
  if s.readData(s, addr(result), sizeof(T)) != sizeof(T):
    raise newEIO("cannot read from stream")

proc readChar*(s: PStream): char =
  ## reads a char from the stream `s`. Raises `EIO` if an error occured.
  ## Returns '\0' as an EOF marker.
  discard s.readData(s, addr(result), sizeof(result))

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

proc readStr*(s: PStream, length: int): string = 
  ## reads a string of length `length` from the stream `s`. Raises `EIO` if 
  ## an error occured.
  result = newString(length)
  var L = s.readData(s, addr(result[0]), length)
  if L != length: setLen(result, L)

proc readLine*(s: PStream): string =
  ## Reads a line from a stream `s`. Note: This is not very efficient. Raises 
  ## `EIO` if an error occured.
  result = ""
  while not s.atEnd(s): 
    var c = readChar(s)
    if c == '\c': 
      c = readChar(s)
      break
    elif c == '\L' or c == '\0': break
    result.add(c)

type
  PStringStream* = ref TStringStream ## a stream that encapsulates a string
  TStringStream* = object of TStream
    data*: string
    pos: int
    
proc ssAtEnd(s: PStringStream): bool = 
  return s.pos >= s.data.len
    
proc ssSetPosition(s: PStringStream, pos: int) = 
  s.pos = min(pos, s.data.len-1)

proc ssGetPosition(s: PStringStream): int =
  return s.pos

proc ssReadData(s: PStringStream, buffer: pointer, bufLen: int): int =
  result = min(bufLen, s.data.len - s.pos)
  if result > 0: 
    copyMem(buffer, addr(s.data[s.pos]), result)
    inc(s.pos, result)

proc ssWriteData(s: PStringStream, buffer: pointer, bufLen: int) = 
  if bufLen > 0: 
    setLen(s.data, s.data.len + bufLen)
    copyMem(addr(s.data[s.pos]), buffer, bufLen)
    inc(s.pos, bufLen)

proc ssClose(s: PStringStream) =
  s.data = nil

proc newStringStream*(s: string = ""): PStringStream = 
  ## creates a new stream from the string `s`.
  new(result)
  result.data = s
  result.pos = 0
  result.close = ssClose
  result.atEnd = ssAtEnd
  result.setPosition = ssSetPosition
  result.getPosition = ssGetPosition
  result.readData = ssReadData
  result.writeData = ssWriteData

type
  PFileStream* = ref TFileStream ## a stream that encapsulates a `TFile`
  TFileStream* = object of TStream
    f: TFile

proc fsClose(s: PFileStream) = close(s.f)
proc fsAtEnd(s: PFileStream): bool = return EndOfFile(s.f)
proc fsSetPosition(s: PFileStream, pos: int) = setFilePos(s.f, pos)
proc fsGetPosition(s: PFileStream): int = return int(getFilePos(s.f))

proc fsReadData(s: PFileStream, buffer: pointer, bufLen: int): int = 
  result = readBuffer(s.f, buffer, bufLen)
  
proc fsWriteData(s: PFileStream, buffer: pointer, bufLen: int) = 
  if writeBuffer(s.f, buffer, bufLen) != bufLen: 
    raise newEIO("cannot write to stream")

proc newFileStream*(f: TFile): PFileStream = 
  ## creates a new stream from the file `f`.
  new(result)
  result.f = f
  result.close = fsClose
  result.atEnd = fsAtEnd
  result.setPosition = fsSetPosition
  result.getPosition = fsGetPosition
  result.readData = fsReadData
  result.writeData = fsWriteData

proc newFileStream*(filename: string, mode: TFileMode): PFileStream = 
  ## creates a new stream from the file named `filename` with the mode `mode`.
  ## If the file cannot be opened, nil is returned.
  var f: TFile
  if Open(f, filename, mode): result = newFileStream(f)


when true:
  nil
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
