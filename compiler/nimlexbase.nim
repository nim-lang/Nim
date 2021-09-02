#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Base Object of a lexer with efficient buffer handling. In fact
# I believe that this is the most efficient method of buffer
# handling that exists! Only at line endings checks are necessary
# if the buffer needs refilling.

import
  llstream, strutils

const
  Lrz* = ' '
  Apo* = '\''
  Tabulator* = '\x09'
  ESC* = '\x1B'
  CR* = '\x0D'
  FF* = '\x0C'
  LF* = '\x0A'
  BEL* = '\x07'
  BACKSPACE* = '\x08'
  VT* = '\x0B'

const
  EndOfFile* = '\0'           # end of file marker
                              # A little picture makes everything clear :-)
                              #  buf:
                              #  "Example Text\n ha!"   bufLen = 17
                              #   ^pos = 0     ^ sentinel = 12
                              #
  NewLines* = {CR, LF}

type
  TBaseLexer* = object of RootObj
    bufpos*: int
    buf*: cstring
    bufStorage: string
    bufLen: int
    stream*: PLLStream        # we read from this stream
    lineNumber*: int          # the current line number
                              # private data:
    sentinel*: int
    lineStart*: int           # index of last line start in buffer
    offsetBase*: int          # use ``offsetBase + bufpos`` to get the offset


proc openBaseLexer*(L: var TBaseLexer, inputstream: PLLStream,
                    bufLen: int = 8192)
  # 8K is a reasonable buffer size
proc closeBaseLexer*(L: var TBaseLexer)
proc getCurrentLine*(L: TBaseLexer, marker: bool = true): string
proc getColNumber*(L: TBaseLexer, pos: int): int
proc handleCR*(L: var TBaseLexer, pos: int): int
  # Call this if you scanned over CR in the buffer; it returns the
  # position to continue the scanning from. `pos` must be the position
  # of the CR.
proc handleLF*(L: var TBaseLexer, pos: int): int
  # Call this if you scanned over LF in the buffer; it returns the
  # position to continue the scanning from. `pos` must be the position
  # of the LF.
# implementation

proc closeBaseLexer(L: var TBaseLexer) =
  llStreamClose(L.stream)

proc fillBuffer(L: var TBaseLexer) =
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
    moveMem(addr L.buf[0], addr L.buf[L.sentinel + 1], toCopy)
    # "moveMem" handles overlapping regions
  charsRead = llStreamRead(L.stream, addr L.buf[toCopy], L.sentinel + 1)
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
        L.bufStorage.setLen(L.bufLen)
        L.buf = L.bufStorage.cstring
        assert(L.bufLen - oldBufLen == oldBufLen)
        charsRead = llStreamRead(L.stream, addr(L.buf[oldBufLen]),
                                 oldBufLen)
        if charsRead < oldBufLen:
          L.buf[oldBufLen + charsRead] = EndOfFile
          L.sentinel = oldBufLen + charsRead
          break
        s = L.bufLen - 1

proc fillBaseLexer(L: var TBaseLexer, pos: int): int =
  assert(pos <= L.sentinel)
  if pos < L.sentinel:
    result = pos + 1          # nothing to do
  else:
    fillBuffer(L)
    L.offsetBase += pos + 1
    L.bufpos = 0
    result = 0
  L.lineStart = result

proc handleCR(L: var TBaseLexer, pos: int): int =
  assert(L.buf[pos] == CR)
  inc(L.lineNumber)
  result = fillBaseLexer(L, pos)
  if L.buf[result] == LF:
    result = fillBaseLexer(L, result)

proc handleLF(L: var TBaseLexer, pos: int): int =
  assert(L.buf[pos] == LF)
  inc(L.lineNumber)
  result = fillBaseLexer(L, pos) #L.lastNL := result-1; // BUGFIX: was: result;

proc skipUTF8BOM(L: var TBaseLexer) =
  if L.buf[0] == '\xEF' and L.buf[1] == '\xBB' and L.buf[2] == '\xBF':
    inc(L.bufpos, 3)
    inc(L.lineStart, 3)

proc openBaseLexer(L: var TBaseLexer, inputstream: PLLStream, bufLen = 8192) =
  assert(bufLen > 0)
  L.bufpos = 0
  L.offsetBase = 0
  L.bufStorage = newString(bufLen)
  L.buf = L.bufStorage.cstring
  L.bufLen = bufLen
  L.sentinel = bufLen - 1
  L.lineStart = 0
  L.lineNumber = 1            # lines start at 1
  L.stream = inputstream
  fillBuffer(L)
  skipUTF8BOM(L)

proc getColNumber(L: TBaseLexer, pos: int): int =
  result = abs(pos - L.lineStart)

proc getCurrentLine(L: TBaseLexer, marker: bool = true): string =
  result = ""
  var i = L.lineStart
  while L.buf[i] notin {CR, LF, EndOfFile}:
    result.add L.buf[i]
    inc i
  result.add "\n"
  if marker:
    result.add spaces(getColNumber(L, L.bufpos)) & '^' & "\n"
