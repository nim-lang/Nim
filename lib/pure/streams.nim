#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides a stream interface and two implementations thereof:
## the `FileStream <#FileStream>`_ and the `StringStream <#StringStream>`_
## which implement the stream interface for Nim file objects (`File`) and
## strings. Other modules may provide other implementations for this standard
## stream interface.
##
## Basic usage
## ===========
##
## The basic flow of using this module is:
##
## 1. Open input stream
## 2. Read or write stream
## 3. Close stream
##
## It is here that an implementation example with
## `StringStream <#StringStream>`_.
##
## StringStream example
## --------------------
##
## Step 1: Open input stream:
## ^^^^^^^^^^^^^^^^^^^^^^^^^^
##
## Open StringStream. For more information on `"""The first line..."""`,
## see `Triple quoted string literals <manual.html#lexical-analysis-triple-quoted-string-literals>`_ .
##
## .. code-block:: Nim
##
##  import streams
##
##  var strm = newStringStream("""The first line
##  the second line
##  the third line""")
##
## Step 2: Read stream
## ^^^^^^^^^^^^^^^^^^^
##
## Read stream. `readLine proc <#readLine,Stream,TaintedString>`_ reads a line
## of text from the stream. In this example, read three times and exit the loop.
##
## .. code-block:: Nim
##
##  var line = ""
##
##  while strm.readLine(line):
##    echo line
##  
##  # Output:
##  # The first line
##  # The second line
##  # The third line
##
## Step 3: Close stream
## ^^^^^^^^^^^^^^^^^^^^
##
## Close stream.
##
## .. code-block:: Nim
##
##  strm.close()
##
## You can use `defer statement <manual.html#exception-handling-defer-statement>`_ 
## to close stream. defer statement is available with procedure. But defer
## statement is not available with Top-level.
## 
## defer statement example is here:
##
## .. code-block:: Nim
##
##  defer: strm.close()
##
## Similarly, it is here that an implementation example with
## `FileStream <#FileStream>`_.
##
## FileStream example
## ------------------
##
## Read file stream example:
##
## .. code-block:: Nim
##
##  import streams
##
##  var strm = newFileStream("somefile.txt", fmRead)
##  var line = ""
##
##  if not isNil(strm):
##    while strm.readLine(line):
##      echo line
##    strm.close()
##
##  # Output:
##  # The first line
##  # the second line
##  # the third line
##
## Write file stream example:
##
## .. code-block:: Nim
##
##  import streams
##
##  var strm = newFileStream("somefile.txt", fmWrite)
##  var line = ""
##
##  if not isNil(strm):
##    strm.writeLine("The first line")
##    strm.writeLine("the second line")
##    strm.writeLine("the third line")
##    strm.close()
## 
##  # Output (somefile.txt):
##  # The first line
##  # the second line
##  # the third line
##
## See also
## ========
## * `FileMode enum <io.html#FileMode>`_ is available FileMode

include "system/inclrtl"

proc newEIO(msg: string): owned(ref IOError) =
  new(result)
  result.msg = msg

type
  Stream* = ref StreamObj
    ## A stream.
    ## All procedures of this module use this type.
    ## Procedures don't use `StreamObj <#StreamObj>`_.
  StreamObj* = object of RootObj
    ## Stream interface that supports writing or reading.
    ## 
    ## **Note:**
    ## * That these fields here shouldn't be used directly.
    ##   They are accessible so that a stream implementation can override them.
    closeImpl*: proc (s: Stream)
      {.nimcall, raises: [Exception, IOError, OSError], tags: [WriteIOEffect], gcsafe.}
    atEndImpl*: proc (s: Stream): bool
      {.nimcall, raises: [Defect, IOError, OSError], tags: [], gcsafe.}
    setPositionImpl*: proc (s: Stream, pos: int)
      {.nimcall, raises: [Defect, IOError, OSError], tags: [], gcsafe.}
    getPositionImpl*: proc (s: Stream): int
      {.nimcall, raises: [Defect, IOError, OSError], tags: [], gcsafe.}

    readDataStrImpl*: proc (s: Stream, buffer: var string, slice: Slice[int]): int
      {.nimcall, raises: [Defect, IOError, OSError], tags: [ReadIOEffect], gcsafe.}

    readDataImpl*: proc (s: Stream, buffer: pointer, bufLen: int): int
      {.nimcall, raises: [Defect, IOError, OSError], tags: [ReadIOEffect], gcsafe.}
    peekDataImpl*: proc (s: Stream, buffer: pointer, bufLen: int): int
      {.nimcall, raises: [Defect, IOError, OSError], tags: [ReadIOEffect], gcsafe.}
    writeDataImpl*: proc (s: Stream, buffer: pointer, bufLen: int)
        {.nimcall, raises: [Defect, IOError, OSError], tags: [WriteIOEffect], gcsafe.}

    flushImpl*: proc (s: Stream)
      {.nimcall, raises: [Defect, IOError, OSError], tags: [WriteIOEffect], gcsafe.}

proc flush*(s: Stream) =
  ## Flushes the buffers that the stream `s` might use.
  runnableExamples:
    discard ## TODO
  if not isNil(s.flushImpl): s.flushImpl(s)

proc close*(s: Stream) =
  ## Closes the stream `s`.
  runnableExamples:
    discard ## TODO
  if not isNil(s.closeImpl): s.closeImpl(s)

proc atEnd*(s: Stream): bool =
  ## Checks if more data can be read from `f`. Returns ``true`` if all data has
  ## been read.
  runnableExamples:
    discard ## TODO
  result = s.atEndImpl(s)

proc setPosition*(s: Stream, pos: int) =
  ## Sets the position `pos` of the stream `s`.
  runnableExamples:
    discard ## TODO
  s.setPositionImpl(s, pos)

proc getPosition*(s: Stream): int =
  ## Retrieves the current position in the stream `s`.
  runnableExamples:
    discard ## TODO
  result = s.getPositionImpl(s)

proc readData*(s: Stream, buffer: pointer, bufLen: int): int =
  ## Low level proc that reads data into an untyped `buffer` of `bufLen` size.
  runnableExamples:
    discard ## TODO
  result = s.readDataImpl(s, buffer, bufLen)

proc readDataStr*(s: Stream, buffer: var string, slice: Slice[int]): int =
  ## Low level proc that reads data into a string ``buffer`` at ``slice``.
  runnableExamples:
    discard ## TODO
  if s.readDataStrImpl != nil:
    result = s.readDataStrImpl(s, buffer, slice)
  else:
    # fallback
    result = s.readData(addr buffer[0], buffer.len)

when not defined(js):
  proc readAll*(s: Stream): string =
    ## Reads all available data.
    ##
    ## **Note:**
    ## * Not available this when backend is js
    runnableExamples:
      discard ## TODO
    const bufferSize = 1024
    var buffer {.noinit.}: array[bufferSize, char]
    while true:
      let readBytes = readData(s, addr(buffer[0]), bufferSize)
      if readBytes == 0:
        break
      let prevLen = result.len
      result.setLen(prevLen + readBytes)
      copyMem(addr(result[prevLen]), addr(buffer[0]), readBytes)
      if readBytes < bufferSize:
        break

proc peekData*(s: Stream, buffer: pointer, bufLen: int): int =
  ## Low level proc that reads data into an untyped `buffer` of `bufLen` size
  ## without moving stream position
  runnableExamples:
    discard ## TODO
  result = s.peekDataImpl(s, buffer, bufLen)

proc writeData*(s: Stream, buffer: pointer, bufLen: int) =
  ## Low level proc that writes an untyped `buffer` of `bufLen` size
  ## to the stream `s`.
  runnableExamples:
    discard ## TODO
  s.writeDataImpl(s, buffer, bufLen)

proc write*[T](s: Stream, x: T) =
  ## Generic write procedure. Writes `x` to the stream `s`. Implementation:
  ##
  ## .. code-block:: Nim
  ##
  ##     s.writeData(s, addr(x), sizeof(x))
  runnableExamples:
    discard ## TODO
  var y: T
  shallowCopy(y, x)
  writeData(s, addr(y), sizeof(y))

proc write*(s: Stream, x: string) =
  ## Writes the string `x` to the the stream `s`. No length field or
  ## terminating zero is written.
  runnableExamples:
    discard ## TODO
  when nimvm:
    writeData(s, cstring(x), x.len)
  else:
    if x.len > 0: writeData(s, cstring(x), x.len)

proc write*(s: Stream, args: varargs[string, `$`]) =
  ## Writes one or more strings to the the stream. No length fields or
  ## terminating zeros are written.
  runnableExamples:
    discard ## TODO
  for str in args: write(s, str)

proc writeLine*(s: Stream, args: varargs[string, `$`]) =
  ## Writes one or more strings to the the stream `s` followed
  ## by a new line. No length field or terminating zero is written.
  runnableExamples:
    discard ## TODO
  for str in args: write(s, str)
  write(s, "\n")

proc read*[T](s: Stream, result: var T) =
  ## Generic read procedure. Reads `result` from the stream `s`.
  runnableExamples:
    discard ## TODO
  if readData(s, addr(result), sizeof(T)) != sizeof(T):
    raise newEIO("cannot read from stream")

proc peek*[T](s: Stream, result: var T) =
  ## Generic peek procedure. Peeks `result` from the stream `s`.
  runnableExamples:
    discard ## TODO
  if peekData(s, addr(result), sizeof(T)) != sizeof(T):
    raise newEIO("cannot read from stream")

proc readChar*(s: Stream): char =
  ## Reads a char from the stream `s`. Raises `IOError` if an error occurred.
  ## Returns '\\0' as an EOF marker.
  runnableExamples:
    discard ## TODO
  if readData(s, addr(result), sizeof(result)) != 1: result = '\0'

proc peekChar*(s: Stream): char =
  ## Peeks a char from the stream `s`. Raises `IOError` if an error occurred.
  ## Returns '\\0' as an EOF marker.
  runnableExamples:
    discard ## TODO
  if peekData(s, addr(result), sizeof(result)) != 1: result = '\0'

proc readBool*(s: Stream): bool =
  ## Reads a bool from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  read(s, result)

proc peekBool*(s: Stream): bool =
  ## Peeks a bool from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  peek(s, result)

proc readInt8*(s: Stream): int8 =
  ## Reads an int8 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  read(s, result)

proc peekInt8*(s: Stream): int8 =
  ## Peeks an int8 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  peek(s, result)

proc readInt16*(s: Stream): int16 =
  ## Reads an int16 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  read(s, result)

proc peekInt16*(s: Stream): int16 =
  ## Peeks an int16 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  peek(s, result)

proc readInt32*(s: Stream): int32 =
  ## Reads an int32 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  read(s, result)

proc peekInt32*(s: Stream): int32 =
  ## Peeks an int32 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  peek(s, result)

proc readInt64*(s: Stream): int64 =
  ## Reads an int64 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  read(s, result)

proc peekInt64*(s: Stream): int64 =
  ## Peeks an int64 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  peek(s, result)

proc readUint8*(s: Stream): uint8 =
  ## Reads an uint8 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  read(s, result)

proc peekUint8*(s: Stream): uint8 =
  ## Peeks an uint8 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  peek(s, result)

proc readUint16*(s: Stream): uint16 =
  ## Reads an uint16 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  read(s, result)

proc peekUint16*(s: Stream): uint16 =
  ## Peeks an uint16 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  peek(s, result)

proc readUint32*(s: Stream): uint32 =
  ## Reads an uint32 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  read(s, result)

proc peekUint32*(s: Stream): uint32 =
  ## Peeks an uint32 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  peek(s, result)

proc readUint64*(s: Stream): uint64 =
  ## Reads an uint64 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  read(s, result)

proc peekUint64*(s: Stream): uint64 =
  ## Peeks an uint64 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  peek(s, result)

proc readFloat32*(s: Stream): float32 =
  ## Reads a float32 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  read(s, result)

proc peekFloat32*(s: Stream): float32 =
  ## Peeks a float32 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  peek(s, result)

proc readFloat64*(s: Stream): float64 =
  ## Reads a float64 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  read(s, result)

proc peekFloat64*(s: Stream): float64 =
  ## Peeks a float64 from the stream `s`. Raises `IOError` if an error occurred.
  runnableExamples:
    discard ## TODO
  peek(s, result)

proc readStr*(s: Stream, length: int): TaintedString =
  ## Reads a string of length `length` from the stream `s`. Raises `IOError` if
  ## an error occurred.
  runnableExamples:
    discard ## TODO
  result = newString(length).TaintedString
  var L = readData(s, cstring(result), length)
  if L != length: setLen(result.string, L)

proc peekStr*(s: Stream, length: int): TaintedString =
  ## Peeks a string of length `length` from the stream `s`. Raises `IOError` if
  ## an error occurred.
  runnableExamples:
    discard ## TODO
  result = newString(length).TaintedString
  var L = peekData(s, cstring(result), length)
  if L != length: setLen(result.string, L)

proc readLine*(s: Stream, line: var TaintedString): bool =
  ## Reads a line of text from the stream `s` into `line`. `line` must not be
  ## ``nil``! May throw an IO exception.
  ## A line of text may be delimited by ``LF`` or ``CRLF``.
  ## The newline character(s) are not part of the returned string.
  ## Returns ``false`` if the end of the file has been reached, ``true``
  ## otherwise. If ``false`` is returned `line` contains no new data.
  ##
  ## See also:
  ## * `readLine(Stream) proc <#readLine,Stream>`_
  ## * `peekLine(Stream) proc <#peekLine,Stream>`_
  ## * `peekLine(Stream, TaintedString) proc <#peekLine,Stream,TaintedString>`_
  runnableExamples:
    var strm = newStringStream("The first line\nthe second line\nthe third line")
    var line = ""

    doAssert strm.readLine(line) == true
    doAssert line == "The first line"

    doAssert strm.readLine(line) == true
    doAssert line == "the second line"

    doAssert strm.readLine(line) == true
    doAssert line == "the third line"

    doAssert strm.readLine(line) == false
    doAssert line == ""

    strm.close()
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
  ## Peeks a line of text from the stream `s` into `line`. `line` must not be
  ## ``nil``! May throw an IO exception.
  ## A line of text may be delimited by ``CR``, ``LF`` or
  ## ``CRLF``. The newline character(s) are not part of the returned string.
  ## Returns ``false`` if the end of the file has been reached, ``true``
  ## otherwise. If ``false`` is returned `line` contains no new data.
  ##
  ## See also:
  ## * `readLine(Stream) proc <#readLine,Stream>`_
  ## * `readLine(Stream, TaintedString) proc <#readLine,Stream,TaintedString>`_
  ## * `peekLine(Stream) proc <#peekLine,Stream>`_
  runnableExamples:
    var strm = newStringStream("The first line\nthe second line\nthe third line")
    var line = ""
    
    doAssert strm.peekLine(line) == true
    doAssert line == "The first line"

    doAssert strm.peekLine(line) == true
    ## not "the second line"
    doAssert line == "The first line"

    doAssert strm.readLine(line) == true
    doAssert line == "The first line"

    doAssert strm.peekLine(line) == true
    doAssert line == "the second line"
    
    strm.close()
  let pos = getPosition(s)
  defer: setPosition(s, pos)
  result = readLine(s, line)

proc readLine*(s: Stream): TaintedString =
  ## Reads a line from a stream `s`.
  ##
  ## **Note:**
  ## * This is not very efficient.
  ##   Raises `IOError` if an error occurred.
  ##
  ## See also:
  ## * `readLine(Stream, TaintedString) proc <#readLine,Stream,TaintedString>`_
  ## * `peekLine(Stream) proc <#peekLine,Stream>`_
  ## * `peekLine(Stream, TaintedString) proc <#peekLine,Stream,TaintedString>`_
  runnableExamples:
    var strm = newStringStream("The first line\nthe second line\nthe third line")
    
    doAssert strm.readLine() == "The first line"
    doAssert strm.readLine() == "the second line"
    doAssert strm.readLine() == "the third line"
    ## strm.readLine() --> raise IOError
    
    strm.close()
  result = TaintedString""
  if s.atEnd:
    raise newEIO("cannot read from stream")
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
  ## Peeks a line from a stream `s`.
  ##
  ## **Note:**
  ## * This is not very efficient.
  ##   Raises `IOError` if an error occurred.
  ##
  ## See also:
  ## * `readLine(Stream) proc <#readLine,Stream>`_
  ## * `readLine(Stream, TaintedString) proc <#readLine,Stream,TaintedString>`_
  ## * `peekLine(Stream, TaintedString) proc <#peekLine,Stream,TaintedString>`_
  runnableExamples:
    var strm = newStringStream("The first line\nthe second line\nthe third line")
    
    doAssert strm.peekLine() == "The first line"
    ## not "the second line"
    doAssert strm.peekLine() == "The first line"

    doAssert strm.readLine() == "The first line"
    doAssert strm.peekLine() == "the second line"
    
    strm.close()
  let pos = getPosition(s)
  defer: setPosition(s, pos)
  result = readLine(s)

iterator lines*(s: Stream): TaintedString =
  ## Iterates over every line in the stream.
  ## The iteration is based on ``readLine``.
  ##
  ## See also:
  ## * `readLine(Stream) proc <#readLine,Stream>`_
  ## * `readLine(Stream, TaintedString) proc <#readLine,Stream,TaintedString>`_
  runnableExamples:
    var strm = newStringStream("The first line\nthe second line\nthe third line")
    var lines: seq[string]
    
    for line in strm.lines():
      lines.add line
    
    doAssert lines == @["The first line", "the second line", "the third line"]
    
    strm.close()
  var line: TaintedString
  while s.readLine(line):
    yield line

when not defined(js):

  type
    StringStream* = ref StringStreamObj
      ## A stream that encapsulates a string
      ##
      ## **Note:**
      ## * Not available this when backend is js
    StringStreamObj* = object of StreamObj
      ## A string stream object.
      ##
      ## **Note:**
      ## * Not available this when backend is js
      data*: string ## A string data.
                    ## This is updated when called `writeLine` etc.
      pos: int

  proc ssAtEnd(s: Stream): bool =
    var s = StringStream(s)
    return s.pos >= s.data.len

  proc ssSetPosition(s: Stream, pos: int) =
    var s = StringStream(s)
    s.pos = clamp(pos, 0, s.data.len)

  proc ssGetPosition(s: Stream): int =
    var s = StringStream(s)
    return s.pos

  proc ssReadDataStr(s: Stream, buffer: var string, slice: Slice[int]): int =
    var s = StringStream(s)
    result = min(slice.b + 1 - slice.a, s.data.len - s.pos)
    if result > 0:
      when nimvm:
        for i in 0 ..< result: # sorry, but no fast string splicing on the vm.
          buffer[slice.a + i] = s.data[s.pos + i]
      else:
        copyMem(unsafeAddr buffer[slice.a], addr s.data[s.pos], result)
      inc(s.pos, result)
    else:
      result = 0

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
    when defined(nimNoNilSeqs):
      s.data = ""
    else:
      s.data = nil

  proc newStringStream*(s: string = ""): owned StringStream =
    ## Creates a new stream from the string `s`.
    ##
    ## **Note:**
    ## * Not available this when backend is js
    runnableExamples:
      discard ## TODO
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
    result.readDataStrImpl = ssReadDataStr

  type
    FileStream* = ref FileStreamObj
      ## A stream that encapsulates a `File`
      ##
      ## **Note:**
      ## * Not available this when backend is js
    FileStreamObj* = object of Stream
      ## A file stream object.
      ##
      ## **Note:**
      ## * Not available this when backend is js
      f: File

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

  proc fsReadDataStr(s: Stream, buffer: var string, slice: Slice[int]): int =
    result = readBuffer(FileStream(s).f, addr buffer[slice.a], slice.b + 1 - slice.a)

  proc fsPeekData(s: Stream, buffer: pointer, bufLen: int): int =
    let pos = fsGetPosition(s)
    defer: fsSetPosition(s, pos)
    result = readBuffer(FileStream(s).f, buffer, bufLen)

  proc fsWriteData(s: Stream, buffer: pointer, bufLen: int) =
    if writeBuffer(FileStream(s).f, buffer, bufLen) != bufLen:
      raise newEIO("cannot write to stream")

  proc newFileStream*(f: File): owned FileStream =
    ## Creates a new stream from the file `f`.
    ##
    ## **Note:**
    ## * Not available this when backend is js
    runnableExamples:
      discard ## TODO
    new(result)
    result.f = f
    result.closeImpl = fsClose
    result.atEndImpl = fsAtEnd
    result.setPositionImpl = fsSetPosition
    result.getPositionImpl = fsGetPosition
    result.readDataStrImpl = fsReadDataStr
    result.readDataImpl = fsReadData
    result.peekDataImpl = fsPeekData
    result.writeDataImpl = fsWriteData
    result.flushImpl = fsFlush

  proc newFileStream*(filename: string, mode: FileMode = fmRead, bufSize: int = -1): owned FileStream =
    ## Creates a new stream from the file named `filename` with the mode `mode`.
    ## If the file cannot be opened, nil is returned. See the `io
    ## <io.html>`_ module for a list of available FileMode enums.
    ##
    ## **Note:**
    ## * **This function returns nil in case of failure.**
    ##   To prevent unexpected behavior and ensure proper error handling,
    ##   use `openFileStream proc <#openFileStream,string,FileMode,int>`_
    ##   instead.
    ## * Not available this when backend is js
    runnableExamples:
      from os import removeFile
      try:
        var strm = newFileStream("somefile.txt", fmWrite)
        if not isNil(strm):
          strm.writeLine("The first line")
          strm.writeLine("the second line")
          strm.writeLine("the third line")
          strm.close()
          ## Output (somefile.txt)
          ## The first line
          ## the second line
          ## the third line
          removeFile("somefile.txt")
      except:
        stderr.write getCurrentExceptionMsg()
    var f: File
    if open(f, filename, mode, bufSize): result = newFileStream(f)

  proc openFileStream*(filename: string, mode: FileMode = fmRead, bufSize: int = -1): owned FileStream =
    ## Creates a new stream from the file named `filename` with the mode `mode`.
    ## If the file cannot be opened, an IO exception is raised.
    ##
    ## **Note:**
    ## * Not available this when backend is js
    runnableExamples:
      try:
        var strm = openFileStream("somefile.txt")
        echo strm.readLine()
        strm.close()
      except:
        stderr.write getCurrentExceptionMsg()
    var f: File
    if open(f, filename, mode, bufSize):
      return newFileStream(f)
    else:
      raise newEIO("cannot open file")

when true:
  discard
else:
  type
    FileHandleStream* = ref FileHandleStreamObj
    FileHandleStreamObj* = object of Stream
      handle*: FileHandle
      pos: int

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

  proc newFileHandleStream*(handle: FileHandle): owned FileHandleStream =
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
                            mode: FileMode): owned FileHandleStream =
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
