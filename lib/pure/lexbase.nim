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
    buf*: cstring             ## the buffer itself
    bufLen*: int              ## length of buffer in characters
    input: Stream            ## the input stream
    lineNumber*: int          ## the current line number
    sentinel: int
    lineStart: int            # index of last line start in buffer
    fileOpened: bool

{.deprecated: [TBaseLexer: BaseLexer].}

proc open*(L: var BaseLexer, input: Stream, bufLen: int = 8192)
  ## inits the TBaseLexer with a stream to read from

proc close*(L: var BaseLexer)
  ## closes the base lexer. This closes `L`'s associated stream too.

proc getCurrentLine*(L: BaseLexer, marker: bool = true): string
  ## retrieves the current line.

proc getColNumber*(L: BaseLexer, pos: int): int
  ## retrieves the current column.

proc handleCR*(L: var BaseLexer, pos: int): int
  ## Call this if you scanned over '\c' in the buffer; it returns the the
  ## position to continue the scanning from. `pos` must be the position
  ## of the '\c'.
proc handleLF*(L: var BaseLexer, pos: int): int
  ## Call this if you scanned over '\L' in the buffer; it returns the the
  ## position to continue the scanning from. `pos` must be the position
  ## of the '\L'.

# implementation

const
  chrSize = sizeof(char)

proc close(L: var BaseLexer) =
  dealloc(L.buf)
  close(L.input)

proc fillBuffer(L: var BaseLexer) =
  var
    charsRead, toCopy, s: int # all are in characters,
                              # not bytes (in case this
                              # is not the same)
    oldBufLen: int
  # we know here that pos == L.sentinel, but not if this proc
  # is called the first time by initBaseLexer()
  assert(L.sentinel < L.bufLen)
  toCopy = L.bufLen - L.sentinel - 1
  assert(toCopy >= 0)
  if toCopy > 0:
    moveMem(L.buf, addr(L.buf[L.sentinel + 1]), toCopy * chrSize) 
    # "moveMem" handles overlapping regions
  charsRead = readData(L.input, addr(L.buf[toCopy]),
                       (L.sentinel + 1) * chrSize) div chrSize
  s = toCopy + charsRead
  if charsRead < L.sentinel + 1:
    L.buf[s] = EndOfFile      # set end marker
    L.sentinel = s
  else:
    # compute sentinel:
    dec(s)                    # BUGFIX (valgrind)
    while true:
      assert(s < L.bufLen)
      while (s >= 0) and not (L.buf[s] in NewLines): dec(s)
      if s >= 0:
        # we found an appropriate character for a sentinel:
        L.sentinel = s
        break
      else:
        # rather than to give up here because the line is too long,
        # double the buffer's size and try again:
        oldBufLen = L.bufLen
        L.bufLen = L.bufLen * 2
        L.buf = cast[cstring](realloc(L.buf, L.bufLen * chrSize))
        assert(L.bufLen - oldBufLen == oldBufLen)
        charsRead = readData(L.input, addr(L.buf[oldBufLen]),
                             oldBufLen * chrSize) div chrSize
        if charsRead < oldBufLen:
          L.buf[oldBufLen + charsRead] = EndOfFile
          L.sentinel = oldBufLen + charsRead
          break
        s = L.bufLen - 1

proc fillBaseLexer(L: var BaseLexer, pos: int): int =
  assert(pos <= L.sentinel)
  if pos < L.sentinel:
    result = pos + 1          # nothing to do
  else:
    fillBuffer(L)
    L.bufpos = 0              # XXX: is this really correct?
    result = 0
  L.lineStart = result

proc handleCR(L: var BaseLexer, pos: int): int =
  assert(L.buf[pos] == '\c')
  inc(L.lineNumber)
  result = fillBaseLexer(L, pos)
  if L.buf[result] == '\L':
    result = fillBaseLexer(L, result)

proc handleLF(L: var BaseLexer, pos: int): int =
  assert(L.buf[pos] == '\L')
  inc(L.lineNumber)
  result = fillBaseLexer(L, pos) #L.lastNL := result-1; // BUGFIX: was: result;

proc skipUtf8Bom(L: var BaseLexer) =
  if (L.buf[0] == '\xEF') and (L.buf[1] == '\xBB') and (L.buf[2] == '\xBF'):
    inc(L.bufpos, 3)
    inc(L.lineStart, 3)

proc open(L: var BaseLexer, input: Stream, bufLen: int = 8192) =
  assert(bufLen > 0)
  assert(input != nil)
  L.input = input
  L.bufpos = 0
  L.bufLen = bufLen
  L.buf = cast[cstring](alloc(bufLen * chrSize))
  L.sentinel = bufLen - 1
  L.lineStart = 0
  L.lineNumber = 1            # lines start at 1
  fillBuffer(L)
  skipUtf8Bom(L)

proc getColNumber(L: BaseLexer, pos: int): int =
  result = abs(pos - L.lineStart)

proc getCurrentLine(L: BaseLexer, marker: bool = true): string =
  var i: int
  result = ""
  i = L.lineStart
  while not (L.buf[i] in {'\c', '\L', EndOfFile}):
    add(result, L.buf[i])
    inc(i)
  add(result, "\n")
  if marker:
    add(result, spaces(getColNumber(L, L.bufpos)) & "^\n")

