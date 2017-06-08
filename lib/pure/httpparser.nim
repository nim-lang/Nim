import strtabs, strutils, parseutils, asyncnet, net, asyncdispatch

iterator splitProtocol(line: string): string =
  let n = len(line)
  var word = newStringOfCap(n)
  var j = 0
  for i in 0..n-1:
    var c = line[i]
    case j
    of 0:
      if c == ' ':
        if len(word) > 0:
          yield word
          setLen(word, 0)
          inc(j)
      else:
        add(word, c)
    of 1:
      if c == ' ':
        if len(word) > 0:
          yield word
          setLen(word, 0)
          inc(j)
      else:
        add(word, c)
    else:
      add(word, c)
  yield word

proc parseRequestProtocol(line: string; reqMethod, url: var string; 
                          protocol: var tuple[orig: string, major, minor: int]) =
  var i = 0
  for word in splitProtocol(line):
    case i
    of 0:
      reqMethod = word
    of 1:
      url = word
    of 2:
      protocol.orig = word
      var j = skipIgnoreCase(word, "Http/")
      if j != 5:
        raise newException(ValueError, "Invalid Request Protocol")
      inc(j, parseInt(word, protocol.major, j))
      inc(j)
      discard parseInt(word, protocol.minor, j)
    else:
      raise newException(ValueError, "Invalid Request Protocol")
    inc(i)
  if i < 3:
    raise newException(ValueError, "Invalid Request Protocol")

proc parseResponseProtocol(line: string; statusCode: var int; statusMessage: var string; 
                           protocol: var tuple[orig: string, major, minor: int]) =
  var i = 0
  for word in splitProtocol(line):
    case i
    of 0:
      protocol.orig = word
      var j = skipIgnoreCase(word, "Http/")
      if j != 5:
        raise newException(ValueError, "Invalid Request Protocol")
      inc(j, parseInt(word, protocol.major, j))
      inc(j)
      discard parseInt(word, protocol.minor, j)
    of 1:
      statusCode = parseInt(word)
    of 2:
      statusMessage = word
    else:
      raise newException(ValueError, "Invalid Request Protocol")
    inc(i)
  if i < 3:
    raise newException(ValueError, "Invalid Request Protocol")

proc parseHeader(line: string, headers: StringTableRef) =
  let n = len(line)
  var i = 0
  while i < n:
    if line[i] == ':':
      break
    inc(i)
  if i == 0 or i >= n:
    raise newException(ValueError, "Invalid Request Header")
  var key = newString(i)
  copyMem(cstring(key), cstring(line), i * sizeof(char))
  if i < n-2:
    var value = newString(n - 2 - i)
    copyMem(cstring(value), 
            cast[pointer](cast[ByteAddress](cstring(line)) + (i + 2) * sizeof(char)),
            (n - 2 - i) * sizeof(char))
    headers[key] = value
  else:
    headers[key] = ""

proc parseChunkSize(line: string): int = 
  result = 0
  var i = 0
  while true:
    case line[i]
    of '0'..'9':
      result = result shl 4 or (ord(line[i]) - ord('0'))
    of 'a'..'f':
      result = result shl 4 or (ord(line[i]) - ord('a') + 10)
    of 'A'..'F':
      result = result shl 4 or (ord(line[i]) - ord('A') + 10)
    of '\0':
      break
    of ';':
      # http://tools.ietf.org/html/rfc2616#section-3.6.1
      # We don't care about chunk-extensions.
      break
    else:
      raise newException(ValueError, "Invalid Chunk Encoded")
    inc(i)

type
  LineState = enum
    lpInit, lpCRLF, lpOK

  Line = object
    base: string
    size: int
    sizeLimit: int
    state: LineState

template offsetChar(x: pointer, i: int): pointer =
  cast[pointer](cast[ByteAddress](x) + i * sizeof(char))

proc initLine(sizeLimit = 1024): Line =
  result.sizeLimit = sizeLimit
  result.base = newStringOfCap(sizeLimit)

proc clear(line: var Line) =
  line.base.setLen(0)
  line.size = 0
  line.state = lpInit

proc read(line: var Line, buf: pointer, size: int): int =
  result = 0
  while result < size:
    let c = cast[ptr char](offsetChar(buf, result))[] 
    case line.state
    of lpInit:
      if c == '\r':
        line.state = lpCRLF
      else:
        line.base.add(c)
        line.size.inc(1)
        if line.size >= line.sizeLimit:
          raise newException(ValueError, "internal buffer overflow")
    of lpCRLF:
      if c == '\L':
        line.state = lpOK
        result.inc(1)
        line.base.setLen(result-2)
        return
      else:
        raise newException(ValueError, "invalid CRLF")
    of lpOK:
      return
    result.inc(1)

type
  ParsePhase = enum
    ppInit, ppProtocol, ppHeaders, ppCheck, ppUpgrade, ppData, ppChunkBegin, ppChunk, 
    ppDataEnd, ppError

  ParseState* = enum
    psRequest, psData, psDataChunked, psDataEnd, psExpect100Continue, psExceptOther, 
    psUpgrade, psError
                                                 
  Chunk = object
    base: pointer
    size: int
    pos: int
    dataSize: int

  HttpParser* = object
    reqMethod: string
    url: string
    protocol: tuple[orig: string, major, minor: int]
    headers: StringTableRef
    chunk: Chunk
    line: Line
    contentLength: int
    chunkLength: int
    headerLimit: int
    headerNums: int
    chunkedTransferEncoding: bool
    keepAlive: bool
    phase: ParsePhase
    state: ParseState

template chunk: untyped = parser.chunk
template line: untyped = parser.line

proc initHttpParser*(lineLimit = 1024, headerLimit = 1024): HttpParser =
  result.headers = newStringTable(modeCaseInsensitive)
  result.line = initLine(lineLimit)
  result.headerLimit = headerLimit

proc pick(parser: var HttpParser, buf: pointer, size: int) =
  chunk.base = buf
  chunk.size = size
  chunk.pos = 0
  chunk.dataSize = 0

proc parseOnInit(parser: var HttpParser) =
  parser.reqMethod = ""
  parser.url = ""
  parser.protocol.orig = ""
  parser.protocol.major = 0
  parser.protocol.minor = 0 
  parser.headers.clear(modeCaseInsensitive) 
  parser.line.clear()
  parser.headerNums = 0
  parser.contentLength = 0
  parser.chunkLength = 0
  parser.chunkedTransferEncoding = false
  parser.keepAlive = false

proc parseOnProtocol(parser: var HttpParser): bool =
  while chunk.pos < chunk.size:
    let n = line.read(offsetChar(chunk.base, chunk.pos), chunk.size - chunk.pos)
    chunk.pos.inc(n)
    if line.state == lpOK:
      parseRequestProtocol(line.base, parser.reqMethod, parser.url, parser.protocol)
      line.clear() 
      return true
    else:
      assert chunk.pos == chunk.size 
  return false

proc parseOnHeaders(parser: var HttpParser): bool = 
  while chunk.pos < chunk.size:
    let n = line.read(offsetChar(chunk.base, chunk.pos), chunk.size - chunk.pos)
    chunk.pos.inc(n)
    if line.state == lpOK:
      if line.base == "":
        line.clear()
        return true
      parseHeader(line.base, parser.headers)
      line.clear() 
      parser.headerNums.inc(1)
      if parser.headerNums > parser.headerLimit:
        raise newException(ValueError, "header limit")
    else:
      assert chunk.pos == chunk.size
  return false

proc parseOnCheck(parser: var HttpParser) = 
  try:
    parser.contentLength = parseInt(parser.headers.getOrDefault("Content-Length"))
    if parser.contentLength < 0:
      parser.contentLength = 0
  except:
    parser.contentLength = 0
  if parser.headers.getOrDefault("Transfer-Encoding") == "bufed":
    parser.chunkedTransferEncoding = true
  if (parser.protocol.major == 1 and parser.protocol.minor == 1 and
      normalize(parser.headers.getOrDefault("Connection")) != "close") or
     (parser.protocol.major == 1 and parser.protocol.minor == 0 and
      normalize(parser.headers.getOrDefault("Connection")) == "keep-alive"):
    parser.keepAlive = true

iterator parse*(parser: var HttpParser, buf: pointer, size: int): ParseState =
  parser.pick(buf, size)
  while true:
    case parser.phase
    of ppInit:
      parser.parseOnInit()
      parser.phase = ppProtocol
    of ppProtocol:
      try:
        if parser.parseOnProtocol():
          parser.phase = ppHeaders
        else:
          break
      except:
        #parser.error = ...
        parser.phase = ppError
    of ppHeaders:
      try:
        if parser.parseOnHeaders():
          parser.phase = ppCheck
        else:
          break
      except:
        #parser.error = ...
        parser.phase = ppError
    of ppCheck:
      parser.parseOnCheck()
      if parser.headers.getOrDefault("Connection") == "Upgrade":
        parser.phase = ppUpgrade
        continue
      if parser.headers.hasKey("Expect"):
        if "100-continue" in parser.headers["Expect"]: 
          yield psExpect100Continue
        else:
          yield psExceptOther
      yield psRequest
      if parser.chunkedTransferEncoding:
        parser.phase = ppChunkBegin
        line.clear()
      elif parser.contentLength == 0:
        parser.phase = ppDataEnd
      else:
        parser.phase = ppData
    of ppData:
      let remained = chunk.size - chunk.pos
      if remained <= 0:
        break
      elif remained < parser.contentLength:
        chunk.dataSize = remained
        yield psData
        chunk.pos.inc(remained)
        parser.contentLength.dec(remained)
      else:
        chunk.dataSize = parser.contentLength
        yield psData
        chunk.pos.inc(parser.contentLength)
        parser.contentLength.dec(parser.contentLength)
        parser.phase = ppDataEnd
    of ppChunkBegin:
      let n = line.read(offsetChar(chunk.base, chunk.pos), chunk.size - chunk.pos)
      chunk.pos.inc(n)
      if line.state == lpOK:
        try:
          let chunkSize = parseChunkSize(line.base)
          if chunkSize <= 0:
            parser.phase = ppDataEnd
          else:
            parser.chunkLength = chunkSize + 2
            parser.phase = ppChunk
        except:
          #parser.error = ...
          parser.phase = ppError
      else:
        assert chunk.pos == chunk.size
        break
    of ppChunk:
      if parser.chunkLength <= 0:
        yield psDataChunked
        parser.phase = ppChunkBegin
        line.clear()
      elif parser.chunkLength == 1: # tail   \n
        let remained = chunk.size - chunk.pos
        if remained <= 0:
          break
        else:
          chunk.pos.inc(1)
          parser.chunkLength.dec(1)
      elif parser.chunkLength == 2: # tail \r\n
        let remained = chunk.size - chunk.pos
        if remained <= 0:
          break
        elif remained == 1:
          chunk.pos.inc(1)
          parser.chunkLength.dec(1)
        else:
          chunk.pos.inc(2)
          parser.chunkLength.dec(2)
      else:
        let remained = chunk.size - chunk.pos
        if remained <= 0:
          break
        elif remained <= parser.chunkLength - 2:
          chunk.dataSize = remained
          yield psData
          chunk.pos.inc(remained)
          parser.chunkLength.dec(remained)
        else:
          chunk.dataSize = parser.chunkLength - 2
          yield psData
          chunk.pos.inc(parser.chunkLength - 2)
          parser.chunkLength.dec(parser.chunkLength - 2)
    of ppDataEnd:
      parser.phase = ppInit
      yield psDataEnd
    of ppUpgrade:
      yield psUpgrade
      break
    of ppError:
      yield psError
      break

proc getData*(parser: var HttpParser): tuple[base: pointer, size: int] =
  result.base = offsetChar(chunk.base, chunk.pos)
  result.size = chunk.dataSize

proc getRemainPacket*(parser: var HttpParser): tuple[base: pointer, size: int] =
  result.base = offsetChar(chunk.base, chunk.pos)
  result.size = chunk.size - chunk.pos

proc toChunkSize*(x: BiggestInt): string =
  assert x >= 0
  const HexChars = "0123456789ABCDEF"
  var n = x
  var m = 0
  var s = newString(5) # sizeof(BiggestInt) * 10 / 16
  for j in countdown(4, 0):
    s[j] = HexChars[n and 0xF]
    n = n shr 4
    inc(m)
    if n == 0: 
      break
  result = newStringOfCap(m)
  for i in 5-m..<5:
    add(result, s[i])

proc genHeadStr(statusCode: int, headers: StringTableRef = nil): string =
  result = "HTTP/1.1 " & $statusCode & " OK\r\L"
  if headers != nil:
    for key,value in headers.pairs():
      add(result, key & ": " & value & "\r\L")
  else:
    add(result, "Content-Length: 0\r\L")
  add(result, "\r\L")

type
  GrowBuffer* = object
    base: string
    initialSize: int
    size: int
    pos: int

proc initGrowBuffer*(initialSize = 1024): GrowBuffer =
  result.initialSize = initialSize
  result.size = initialSize
  result.base = newString(initialSize)
  result.pos = 0

proc increase(x: var GrowBuffer, size: int) =
  let size = x.size
  x.size = x.size * 2
  while size > x.size - x.pos:
    x.size = x.size * 2
  var base: string
  shallowCopy(base, x.base) 
  x.base = newString(x.size)
  copyMem(x.base.cstring, base.cstring, size)

proc write*(x: var GrowBuffer, buf: pointer, size: int) =
  if size > x.size - x.pos:
    x.increase(size)
  copyMem(offsetChar(x.base.cstring, x.pos), buf, size)
  x.pos.inc(size)

proc write*(x: var GrowBuffer, buf: string) =
  x.write(buf.cstring, buf.len)

proc writeLine*(x: var GrowBuffer, buf: pointer, size: int) =
  let totalSize = size + 2
  if totalSize > x.size - x.pos:
    x.increase(totalSize)
  copyMem(offsetChar(x.base.cstring, x.pos), buf, size)
  x.pos.inc(size)
  var tail = ['\c', '\L']
  copyMem(offsetChar(x.base.cstring, x.pos), tail[0].addr, 2)
  x.pos.inc(2)

proc writeLine*(x: var GrowBuffer, buf: string) = 
  x.writeLine(buf.cstring, buf.len)

proc writeChunk*(x: var GrowBuffer, buf: pointer, size: int) =
  let chunkSize = size.toChunkSize()
  let chunkSizeLen = chunkSize.len()
  let totalSize = chunkSizeLen + 2 + size + 2
  if totalSize > x.size - x.pos:
    x.increase(totalSize)
  var tail = ['\c', '\L']
  copyMem(offsetChar(x.base.cstring, x.pos), chunkSize.cstring, chunkSizeLen)
  x.pos.inc(chunkSizeLen)
  copyMem(offsetChar(x.base.cstring, x.pos), tail[0].addr, 2)
  x.pos.inc(2)
  copyMem(offsetChar(x.base.cstring, x.pos), buf, size)
  x.pos.inc(size)
  copyMem(offsetChar(x.base.cstring, x.pos), tail[0].addr, 2)
  x.pos.inc(2)

proc writeChunk*(x: var GrowBuffer, buf: string) =
  x.writeChunk(buf.cstring, buf.len)

proc writeChunkTail*(x: var GrowBuffer) =
  if 5 > x.size - x.pos:
    x.increase(5)
  var tail = ['0', '\c', '\L', '\c', '\L']
  copyMem(offsetChar(x.base.cstring, x.pos), tail[0].addr, 5)
  x.pos.inc(5)

proc writeHead*(x: var GrowBuffer, statusCode: int) =
  x.write("HTTP/1.1 " & $statusCode & " OK\c\LContent-Length: 0\c\L\c\L")

proc writeHead*(x: var GrowBuffer, statusCode: int, 
                headers: openarray[tuple[key, value: string]]) =
  x.write("HTTP/1.1 " & $statusCode & " OK\c\L")
  for it in headers:
    x.write(it.key & ": " & it.value & "\c\L")
  x.write("\c\L")

proc clear0*(x: var GrowBuffer) =
  x.size = x.initialSize
  x.base = newString(x.initialSize)
  x.pos = 0

proc clear*(x: var GrowBuffer) =
  x.size = x.initialSize
  x.base.setLen(x.initialSize)
  x.pos = 0

proc send*(sock: AsyncSocket, buf: GrowBuffer,
           flags = {SocketFlag.SafeDisconn}) {.async.} =
  GC_ref(buf.base)
  try:
    await sock.send(buf.base.cstring, buf.pos, flags)
    GC_unref(buf.base)
  except:
    GC_unref(buf.base)
    raise getCurrentException()

when isMainModule:
  import asyncnet, asyncdispatch

  proc processClient(client: AsyncSocket) {.async.} =
    var parser = initHttpParser()
    var reqBuf = newString(1024)
    var resBuf = initGrowBuffer()
    GC_ref(reqBuf)
    block parsing:
      while true:
        reqBuf.setLen(0)
        let n = await client.recvInto(reqBuf.cstring, 1024)
        if n == 0:
          client.close()
          break parsing
        for state in parser.parse(reqBuf.cstring, n):
          case state
          of psRequest:
            discard
          of psData:
            let (base, size) = parser.getData()
          of psDataChunked:
            discard
          of psDataEnd:
            resBuf.writeHead(200, {
              "Transfer-Encoding": "chunked",
              "Connection": "keep-alive"
            })
            resBuf.writeChunk("hello world")
            await client.send(resBuf)
            resBuf.clear()

            resBuf.writeChunk("hello world")
            resBuf.writeChunkTail()
            await client.send(resBuf)
            resBuf.clear()
            if not parser.keepAlive:
              client.close()
              break parsing
            # keep-alive or close return 
          of psExpect100Continue:
            await client.send("HTTP/1.1 100 Continue\c\L\c\L")
          of psExceptOther:
            await client.send("HTTP/1.1 417 Expectation Failed\c\L\c\L")
          of psUpgrade:
            client.close()
            break parsing
          of psError:
            client.close()
            break parsing
    GC_unref(reqBuf)

  proc serve() {.async.} =
    var server = newAsyncSocket(buffered = false)
    server.setSockOpt(OptReuseAddr, true)
    server.bindAddr(Port(12345))
    server.listen()
    while true:
      let client = await server.accept()
      asyncCheck client.processClient()

  asyncCheck serve()
  runForever()

