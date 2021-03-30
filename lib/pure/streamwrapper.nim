#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements stream wrapper.
##
## **Since** version 1.2.

import deques, streams

type
  PipeOutStream*[T] = ref object of T
    # When stream peek operation is called, it reads from base stream
    # type using `baseReadDataImpl` and stores the content to this buffer.
    # Next stream read operation returns data in the buffer so that previus peek
    # operation looks like didn't changed read positon.
    # When stream read operation that returns N byte data is called and the size is smaller than buffer size,
    # first N elements are removed from buffer.
    # Deque type can do such operation more efficiently than seq type.
    buffer: Deque[char]
    baseReadLineImpl: typeof(StreamObj.readLineImpl)
    baseReadDataImpl: typeof(StreamObj.readDataImpl)

proc posReadLine[T](s: Stream, line: var string): bool =
  var s = PipeOutStream[T](s)
  assert s.baseReadLineImpl != nil

  let n = s.buffer.len
  line.setLen(0)
  for i in 0..<n:
    var c = s.buffer.popFirst
    if c == '\c':
      c = readChar(s)
      return true
    elif c == '\L': return true
    elif c == '\0':
      return line.len > 0
    line.add(c)

  var line2: string
  result = s.baseReadLineImpl(s, line2)
  line.add line2

proc posReadData[T](s: Stream, buffer: pointer, bufLen: int): int =
  var s = PipeOutStream[T](s)
  assert s.baseReadDataImpl != nil

  let
    dest = cast[ptr UncheckedArray[char]](buffer)
    n = min(s.buffer.len, bufLen)
  result = n
  for i in 0..<n:
    dest[i] = s.buffer.popFirst
  if bufLen > n:
    result += s.baseReadDataImpl(s, addr dest[n], bufLen - n)

proc posReadDataStr[T](s: Stream, buffer: var string, slice: Slice[int]): int =
  posReadData[T](s, addr buffer[slice.a], slice.len)

proc posPeekData[T](s: Stream, buffer: pointer, bufLen: int): int =
  var s = PipeOutStream[T](s)
  assert s.baseReadDataImpl != nil

  let
    dest = cast[ptr UncheckedArray[char]](buffer)
    n = min(s.buffer.len, bufLen)

  result = n
  for i in 0..<n:
    dest[i] = s.buffer[i]

  if bufLen > n:
    let
      newDataNeeded = bufLen - n
      numRead = s.baseReadDataImpl(s, addr dest[n], newDataNeeded)
    result += numRead
    for i in 0..<numRead:
      s.buffer.addLast dest[n + i]

proc newPipeOutStream*[T](s: sink (ref T)): owned PipeOutStream[T] =
  ## Wrap pipe for reading with PipeOutStream so that you can use peek* procs and generate runtime error
  ## when setPosition/getPosition is called or write operation is performed.
  ##
  ## Example:
  ##
  ## .. code-block:: Nim
  ##   import std/[osproc, streamwrapper]
  ##   var
  ##     p = startProcess(exePath)
  ##     outStream = p.outputStream().newPipeOutStream()
  ##   echo outStream.peekChar
  ##   p.close()

  assert s.readDataImpl != nil

  new(result)
  for dest, src in fields((ref T)(result)[], s[]):
    dest = src
  wasMoved(s[])
  if result.readLineImpl != nil:
    result.baseReadLineImpl = result.readLineImpl
    result.readLineImpl = posReadLine[T]
  result.baseReadDataImpl = result.readDataImpl
  result.readDataImpl = posReadData[T]
  result.readDataStrImpl = posReadDataStr[T]
  result.peekDataImpl = posPeekData[T]

  # Set nil to anything you may not call.
  result.setPositionImpl = nil
  result.getPositionImpl = nil
  result.writeDataImpl = nil
  result.flushImpl = nil
