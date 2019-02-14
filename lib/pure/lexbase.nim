#
#
#           The Nim Compiler
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a base object of a lexer with efficient buffer
## handling. Only at line endings checks are necessary if the buffer
## needs refilling.

import
  strutils, streams

const
  EndOfFile* = '\0'           ## end of file marker
  NewLines* = {'\c', '\L'}

# Buffer handling:
#  buf:
#  "Example Text\n ha!"   bufLen = 17
#   ^pos = 0     ^ sentinel = 12
#

type
  BaseLexer* = object of RootObj ## the base lexer. Inherit your lexer from
                                 ## this object.
    bufpos*: int              ## the current position within the buffer
    when defined(js):         ## the buffer itself
      buf*: string
    else:
      buf*: cstring
    bufLen*: int              ## length of buffer in characters
    input: Stream            ## the input stream
    lineNumber*: int          ## the current line number
    sentinel: int
    lineStart: int            # index of last line start in buffer
    offsetBase*: int          # use ``offsetBase + bufpos`` to get the offset
    refillChars: set[char]

  BaseLexerCT* = object of RootObj ## the base lexer. Inherit your lexer from
                                 ## this object.
    bufpos*: int              ## the current position within the buffer
    buf*: string              ## the buffer itself
    bufLen*: int              ## length of buffer in characters
    input: string
    lineNumber*: int          ## the current line number
    sentinel: int
    lineStart: int            # index of last line start in buffer
    offsetBase*: int          # use ``offsetBase + bufpos`` to get the offset
    refillChars: set[char]

  AnyBaseLexer* = BaseLexerCT | BaseLexer

const
  chrSize = sizeof(char)

proc readData(input: var string, buf: var string, start, stop: int): int =
  ## `readData` for our " `FakeStream` " used by BaseLexer in VM. Performs copy
  ## of data!
  let m = min(stop, input.len)
  result = m - start
  buf[start ..< m] = input[start ..< m]

proc close*(L: var AnyBaseLexer) =
  ## closes the base lexer. This closes `L`'s associated stream too.
  when type(AnyBaseLexer) is BaseLexer:
    when not defined(js):
      dealloc(L.buf)
    close(L.input)

proc fillBuffer(L: var AnyBaseLexer) =
  var
    charsRead, toCopy, s: int # all are in characters,
                              # not bytes (in case this
                              # is not the same)
    oldBufLen: int
  # determine if we're evaluating at CT
  const atCT = type(AnyBaseLexer) is BaseLexerCT

  # we know here that pos == L.sentinel, but not if this proc
  # is called the first time by initBaseLexer()
  assert(L.sentinel < L.bufLen)
  toCopy = L.bufLen - L.sentinel - 1
  assert(toCopy >= 0)
  if toCopy > 0:
    when defined(js) or atCT:
      for i in 0 ..< toCopy: L.buf[i] = L.buf[L.sentinel + 1 + i]
    else:
      # "moveMem" handles overlapping regions
      moveMem(L.buf, addr L.buf[L.sentinel + 1], toCopy * chrSize)
  when not atCT:
    charsRead = readData(L.input, addr(L.buf[toCopy]),
                         (L.sentinel + 1) * chrSize) div chrSize
  else:
    charsRead = readData(L.input, L.buf, toCopy, L.sentinel + 1)
  s = toCopy + charsRead
  if charsRead < L.sentinel + 1:
    L.buf[s] = EndOfFile      # set end marker
    L.sentinel = s
  else:
    # compute sentinel:
    dec(s)                    # BUGFIX (valgrind)
    while true:
      assert(s < L.bufLen)
      while s >= 0 and L.buf[s] notin L.refillChars: dec(s)
      if s >= 0:
        # we found an appropriate character for a sentinel:
        L.sentinel = s
        break
      else:
        # rather than to give up here because the line is too long,
        # double the buffer's size and try again:
        oldBufLen = L.bufLen
        L.bufLen = L.bufLen * 2
        when defined(js) or atCT:
          L.buf.setLen(L.bufLen)
        else:
          L.buf = cast[cstring](realloc(L.buf, L.bufLen * chrSize))
        assert(L.bufLen - oldBufLen == oldBufLen)
        when AnyBaseLexer is BaseLexer:
          charsRead = readData(L.input, addr(L.buf[oldBufLen]),
                               oldBufLen * chrSize) div chrSize
        else:
          charsRead = readData(L.input, L.buf, oldBufLen, oldBufLen * 2)
        if charsRead < oldBufLen:
          L.buf[oldBufLen + charsRead] = EndOfFile
          L.sentinel = oldBufLen + charsRead
          break
        s = L.bufLen - 1

proc fillBaseLexer(L: var AnyBaseLexer, pos: int): int =
  assert(pos <= L.sentinel)
  if pos < L.sentinel:
    result = pos + 1          # nothing to do
  else:
    fillBuffer(L)
    L.offsetBase += pos
    L.bufpos = 0
    result = 0

proc handleCR*(L: var AnyBaseLexer, pos: int): int =
  ## Call this if you scanned over '\c' in the buffer; it returns the the
  ## position to continue the scanning from. `pos` must be the position
  ## of the '\c'.
  assert(L.buf[pos] == '\c')
  inc(L.lineNumber)
  result = fillBaseLexer(L, pos)
  if L.buf[result] == '\L':
    result = fillBaseLexer(L, result)
  L.lineStart = result

proc handleLF*(L: var AnyBaseLexer, pos: int): int =
  ## Call this if you scanned over '\L' in the buffer; it returns the the
  ## position to continue the scanning from. `pos` must be the position
  ## of the '\L'.
  assert(L.buf[pos] == '\L')
  inc(L.lineNumber)
  result = fillBaseLexer(L, pos) #L.lastNL := result-1; // BUGFIX: was: result;
  L.lineStart = result

proc handleRefillChar*(L: var AnyBaseLexer, pos: int): int =
  ## To be documented.
  assert(L.buf[pos] in L.refillChars)
  result = fillBaseLexer(L, pos) #L.lastNL := result-1; // BUGFIX: was: result;

proc skipUtf8Bom(L: var AnyBaseLexer) =
  if (L.buf[0] == '\xEF') and (L.buf[1] == '\xBB') and (L.buf[2] == '\xBF'):
    inc(L.bufpos, 3)
    inc(L.lineStart, 3)

proc open*(L: var AnyBaseLexer, input: Stream | string, bufLen: int = 8192;
           refillChars: set[char] = NewLines) =
  ## inits the BaseLexer with a stream to read from.
  assert(bufLen > 0)
  when type(input) is Stream:
    assert(input != nil)
  L.input = input
  L.bufpos = 0
  L.offsetBase = 0
  L.bufLen = bufLen
  L.refillChars = refillChars
  when defined(js) or type(input) is string:
    L.buf = newString(bufLen)
  else:
    L.buf = cast[cstring](alloc(bufLen * chrSize))
  L.sentinel = bufLen - 1
  L.lineStart = 0
  L.lineNumber = 1            # lines start at 1
  fillBuffer(L)
  skipUtf8Bom(L)

proc getColNumber*(L: AnyBaseLexer, pos: int): int =
  ## retrieves the current column.
  result = abs(pos - L.lineStart)

proc getCurrentLine*(L: AnyBaseLexer, marker: bool = true): string =
  ## retrieves the current line.
  var i: int
  result = ""
  i = L.lineStart
  while not (L.buf[i] in {'\c', '\L', EndOfFile}):
    add(result, L.buf[i])
    inc(i)
  add(result, "\n")
  if marker:
    add(result, spaces(getColNumber(L, L.bufpos)) & "^\n")
