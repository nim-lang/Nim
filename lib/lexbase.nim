#
#
#           The Nimrod Compiler
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a base object of a lexer with efficient buffer
## handling. In fact I believe that this is the most efficient method of
## buffer handling that exists! Only at line endings checks are necessary
## if the buffer needs refilling.

import 
  strutils

const 
  EndOfFile* = '\0'           ## end of file marker
                              # A little picture makes everything clear :-)
                              #  buf:
                              #  "Example Text\n ha!"   bufLen = 17
                              #   ^pos = 0     ^ sentinel = 12
                              #
  NewLines* = {'\c', '\L'}

type 
  TBaseLexer* = object of TObject ## the base lexer. Inherit your lexer from
                                  ## this object.
    bufpos*: int              ## the current position within the buffer
    buf*: cstring             ## the buffer itself
    bufLen*: int              ## length of buffer in characters
    f*: tfile                 ## the file that is read
    LineNumber*: int          ## the current line number
    sentinel: int
    lineStart: int            # index of last line start in buffer
    fileOpened: bool

proc initBaseLexer*(L: var TBaseLexer, filename: string, bufLen: int = 8192): bool
  ## inits the TBaseLexer object with a file to scan

proc initBaseLexerFromBuffer*(L: var TBaseLexer, buffer: string)
  ## inits the TBaseLexer with a buffer to scan

proc deinitBaseLexer*(L: var TBaseLexer)
  ## deinitializes the base lexer. This needs to be called to close the file.

proc getCurrentLine*(L: TBaseLexer, marker: bool = true): string
  ## retrieves the current line. 

proc getColNumber*(L: TBaseLexer, pos: int): int
  ## retrieves the current column. 
  
proc HandleCR*(L: var TBaseLexer, pos: int): int
  ## Call this if you scanned over '\c' in the buffer; it returns the the
  ## position to continue the scanning from. `pos` must be the position
  ## of the '\c'.
proc HandleLF*(L: var TBaseLexer, pos: int): int
  ## Call this if you scanned over '\L' in the buffer; it returns the the
  ## position to continue the scanning from. `pos` must be the position
  ## of the '\L'.
  
# implementation

const 
  chrSize = sizeof(char)

proc deinitBaseLexer(L: var TBaseLexer) = 
  dealloc(L.buf)
  if L.fileOpened: closeFile(L.f)
  
proc FillBuffer(L: var TBaseLexer) = 
  var 
    charsRead, toCopy, s: int # all are in characters,
                              # not bytes (in case this
                              # is not the same)
    oldBufLen: int
  # we know here that pos == L.sentinel, but not if this proc
  # is called the first time by initBaseLexer()
  assert(L.sentinel < L.bufLen)
  toCopy = L.BufLen - L.sentinel - 1
  assert(toCopy >= 0)
  if toCopy > 0: 
    MoveMem(L.buf, addr(L.buf[L.sentinel + 1]), toCopy * chrSize) # "moveMem" handles overlapping regions
  charsRead = ReadBuffer(L.f, addr(L.buf[toCopy]), (L.sentinel + 1) * chrSize) div
      chrSize
  s = toCopy + charsRead
  if charsRead < L.sentinel + 1: 
    L.buf[s] = EndOfFile      # set end marker
    L.sentinel = s
  else: 
    # compute sentinel:
    dec(s)                    # BUGFIX (valgrind)
    while true: 
      assert(s < L.bufLen)
      while (s >= 0) and not (L.buf[s] in NewLines): Dec(s)
      if s >= 0: 
        # we found an appropriate character for a sentinel:
        L.sentinel = s
        break 
      else: 
        # rather than to give up here because the line is too long,
        # double the buffer's size and try again:
        oldBufLen = L.BufLen
        L.bufLen = L.BufLen * 2
        L.buf = cast[cstring](realloc(L.buf, L.bufLen * chrSize))
        assert(L.bufLen - oldBuflen == oldBufLen)
        charsRead = ReadBuffer(L.f, addr(L.buf[oldBufLen]), oldBufLen * chrSize) div
            chrSize
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
    L.bufpos = 0              # XXX: is this really correct?
    result = 0
  L.lineStart = result

proc HandleCR(L: var TBaseLexer, pos: int): int = 
  assert(L.buf[pos] == '\c')
  inc(L.linenumber)
  result = fillBaseLexer(L, pos)
  if L.buf[result] == '\L': 
    result = fillBaseLexer(L, result)

proc HandleLF(L: var TBaseLexer, pos: int): int = 
  assert(L.buf[pos] == '\L')
  inc(L.linenumber)
  result = fillBaseLexer(L, pos) #L.lastNL := result-1; // BUGFIX: was: result;
  
proc skip_UTF_8_BOM(L: var TBaseLexer) = 
  if (L.buf[0] == '\xEF') and (L.buf[1] == '\xBB') and (L.buf[2] == '\xBF'): 
    inc(L.bufpos, 3)
    inc(L.lineStart, 3)

proc initBaseLexer(L: var TBaseLexer, filename: string, bufLen: int = 8192): bool = 
  assert(bufLen > 0)
  L.bufpos = 0
  L.bufLen = bufLen
  L.buf = cast[cstring](alloc(bufLen * chrSize))
  L.sentinel = bufLen - 1
  L.lineStart = 0
  L.linenumber = 1            # lines start at 1
  L.fileOpened = openFile(L.f, filename)
  result = L.fileOpened
  if result: 
    fillBuffer(L)
    skip_UTF_8_BOM(L)

proc initBaseLexerFromBuffer(L: var TBaseLexer, buffer: string) = 
  L.bufpos = 0
  L.bufLen = len(buffer) + 1
  L.buf = cast[cstring](alloc(L.bufLen * chrSize))
  L.sentinel = L.bufLen - 1
  L.lineStart = 0
  L.linenumber = 1            # lines start at 1
  L.fileOpened = false
  if L.bufLen > 0: 
    copyMem(L.buf, cast[pointer](buffer), L.bufLen)
    L.buf[L.bufLen - 1] = EndOfFile
  else: 
    L.buf[0] = EndOfFile
  skip_UTF_8_BOM(L)

proc getColNumber(L: TBaseLexer, pos: int): int = 
  result = pos - L.lineStart
  assert(result >= 0)

proc getCurrentLine(L: TBaseLexer, marker: bool = true): string = 
  var i: int
  result = ""
  i = L.lineStart
  while not (L.buf[i] in {'\c', '\L', EndOfFile}): 
    add(result, L.buf[i])
    inc(i)
  add(result, "\n")
  if marker: 
    add(result, RepeatChar(getColNumber(L, L.bufpos)) & "^\n")
  
