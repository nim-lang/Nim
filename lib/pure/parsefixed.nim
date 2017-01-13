#
#
#            Nim's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple high performance `Fixed`:idx:
## (`fixed width`:idx:) parser.
##
## Parsing is line based (endings with `CR`, `LF`, or `CR` `LF`), so it
## is single line only.  Lines shorter than the expected
## field widths result in a reduced number of fields returned
## for that row.
##
## readRow() can check that the parsing returns the expected
## number of columns, and will raise ``[FwError]`` if the file
## being parsed has insufficient data to fill the expected columns.
##
## Fields are the specified length (including trailing
## white space) unless `trimTrailingSpace` is set to true
## when the parser is opened.
##
## Example: How to use the parser
## ==============================
##
## .. code-block:: nim
##   import os, parsefw, streams
##   var s = newFileStream(paramStr(1), fmRead)
##   if s == nil: quit("cannot open the file" & paramStr(1))
##   var x: FwParser
##   open(x, s, paramStr(1))
##   # widths: 9,6,10,... (not starting positions)
##   while readRow(x, @[9, 6, 10, 6, 7, 7, 35]):
##     echo "new row: "
##     for val in items(x.row):
##       echo "##", val, "##"
##   close(x)
##

import
  lexbase, streams

type
  FwRow* = seq[string] ## a row in a fixed width file
  FwParser* = object of BaseLexer ## the parser object.
    row*: FwRow                    ## the current row
    filename: string
    fldWidths: seq[int]
    trimWhite: bool
    currRow: int

  FwError* = object of IOError ## exception that is raised if
                                ## a parsing error occurs
proc raiseEInvalidFw(filename: string, line, col: int,
                      msg: string) {.noreturn.} =
  var e: ref FwError
  new(e)
  e.msg = filename & "(" & $line & ", " & $col & ") Error: " & msg
  raise e

proc error(my: FwParser, pos: int, msg: string) =
  raiseEInvalidFw(my.filename, my.lineNumber, getColNumber(my, pos), msg)

proc open*(my: var FwParser, input: Stream, filename: string,
           fldWidths: openArray[int], trimTrailingSpace = false) =
  ## initializes the parser with an input stream. `Filename` is only used
  ## for nice error messages. The parser's behaviour can be controlled by
  ## the parameters:
  ## - `fldWidths`:
  ##   the width of chars for each field.  Chars beyond the
  ##   fldWidths are ignored.  A line is terminated by a CR,
  ##   LF or CR and LF.
  ##
  ##   Lines shorter than the cumulative field widths
  ##   return the chars found in the fields up to the line termination.
  ##   This can result a field width less than the expected width, and
  ##   the number of fields returned may also be less than expected.
  ##   readRow() can be used to verify that the number of fields
  ##   (columns) matches the expected field count, and raise
  ##   the `[FwError]` exception.
  ##
  ##   Lines longer than the specified field widths have the extra
  ##   characters ignored until end of line. The next call to readRow()
  ##   starts at the start of the next line of the file being parsed.
  ##
  ## - `trimTrailingSpace`:
  ##   false by default, and (white) space is included in the parsed fields.
  ##   If true, whitespace at end of a field is removed.
  lexbase.open(my, input)
  my.filename = filename
  my.fldWidths = @[]
  for x in fldWidths:
    my.fldWidths.add(x)
  var startPos = 0
  my.trimWhite = trimTrailingSpace
  my.row = @[]
  my.currRow = 0

proc parseField(my: var FwParser, a: var string, colNr: int) =
  let ePos = my.bufpos + my.fldWidths[colNr]
  var pos = my.bufpos
  var buf = my.buf
  var wPos = ePos
  setLen(a, 0) # reuse memory
  while pos < ePos:
    let c = buf[pos]
    if c in {'\c', '\l', '\0'}: break
    if c in {' ', '\t'}:
      # first white space
      if pos < wPos: wPos = pos
    else:
      # reset first white space marker
      if pos > wPos: wPos = ePos
    add(a, c)
    inc(pos)
  my.bufpos = pos
  # skip to end of line if last col
  if colNr == my.fldWidths.len - 1:
    while buf[pos] notin {'\c', '\l', '\0'}: inc(pos)
    my.bufpos = pos
  # trim trailing white space
  if my.trimWhite and wPos < ePos:
    setLen(a, a.len - (ePos-wPos))

proc processedRows*(my: var FwParser): int =
  ## returns the number of (currently) processed rows
  return my.currRow

proc readRow*(my: var FwParser, columns = 0): bool =
  ## reads the next row; if `columns` > 0, it expects the row to have
  ## exactly this many columns, and if not, raises `[FwError]`.
  ## Returns false if the end of the file has been encountered,
  ## else true.
  if my.fldWidths.len == 0:
    return false
  var col = 0 # current column
  var oldpos = my.bufpos
  while my.buf[my.bufpos] != '\0':
    var oldlen = my.row.len
    if oldlen < col+1:
      setLen(my.row, col+1)
      my.row[col] = ""
    # process the next field in this line
    parseField(my, my.row[col], col)
    inc(col)
    # fix any end-of-line issues
    case my.buf[my.bufpos]
    of '\c', '\l':
      # skip empty lines:
      while true:
        case my.buf[my.bufpos]
        of '\c': my.bufpos = handleCR(my, my.bufpos)
        of '\l': my.bufpos = handleLF(my, my.bufpos)
        else: break
      # clear any further columns for this line
      break
    of '\0': discard
    else: discard
    # finished line processing? then break
    if col >= my.fldWidths.len:
      break
  # retrieved all fixed fields, now check column count
  setLen(my.row, col)
  result = col > 0
  if result and columns > 0 and col != columns:
    error(my, oldpos+1, $columns & " columns expected, but found " &
          $col & " columns")
  inc(my.currRow)

proc close*(my: var FwParser) {.inline.} =
  ## closes the parser `my` and its associated input stream.
  lexbase.close(my)

when not defined(testing) and isMainModule:
  import os
  # test data:
  #12345    Wed  1
  #11234    Thu  2
  #11123    Fri  3456  <- tests line greater than expected length
  #1        Sat  4     <- tests trimming of the first field
  var s = newFileStream(paramStr(1), fmRead)
  if s == nil: quit("cannot open the file" & paramStr(1))
  var x: FwParser
  # test non-trimmed field widths
  open(x, s, paramStr(1), @[5, 4, 3, 2, 1])
  while readRow(x):
    echo "new row: "
    for val in items(x.row):
      echo "##", val, "##"
  close(x)
  # test triming of trailing white space
  s = newFileStream(paramStr(1), fmRead)
  open(x, s, paramStr(1), @[5,4,3,2,1], true)
  while readRow(x):
    echo "new row: "
    for val in items(x.row):
      echo "##", val, "##"
  close(x)
  # test no line widths requested
  # (should do nothing -> no rows returned from readRow )
  s = newFileStream(paramStr(1), fmRead)
  open(x, s, paramStr(1), [])
  while readRow(x):
    echo "new row: "
    for val in items(x.row):
      echo "##", val, "##"
  close(x)
  # test line shorter than expected field widths
  # test array rather than seq passed to open()
  s = newFileStream(paramStr(1), fmRead)
  open(x, s, paramStr(1), [3000,5,2])
  while readRow(x):  #  readRow(x,3):  # should error
    echo "new row: "
    for val in items(x.row):
      echo "##", val, "##"
  close(x)

