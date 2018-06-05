#
#
#            Nim's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a simple high performance `CSV`:idx:
## (`comma separated value`:idx:) parser.
##
## Example: How to use the parser
## ==============================
##
## .. code-block:: nim
##   import os, parsecsv, streams
##   var s = newFileStream(paramStr(1), fmRead)
##   if s == nil: quit("cannot open the file" & paramStr(1))
##   var x: CsvParser
##   open(x, s, paramStr(1))
##   while readRow(x):
##     echo "new row: "
##     for val in items(x.row):
##       echo "##", val, "##"
##   close(x)
##
## For CSV files with a header row, the header can be read and then used as a
## reference for item access with `rowEntry <#rowEntry.CsvParser.string>`_:
##
## .. code-block:: nim
##   import parsecsv
##   import os
##   # Prepare a file
##   let content = """One,Two,Three,Four
##   1,2,3,4
##   10,20,30,40
##   100,200,300,400
##   """
##   writeFile("temp.csv", content)
##
##   var p: CsvParser
##   p.open("temp.csv")
##   p.readHeaderRow()
##   while p.readRow():
##     echo "new row: "
##     for col in items(p.headers):
##       echo "##", col, ":", p.rowEntry(col), "##"
##   p.close()

import
  lexbase, streams

type
  CsvRow* = seq[string] ## a row in a CSV file
  CsvParser* = object of BaseLexer ## the parser object.
    row*: CsvRow                    ## the current row
    filename: string
    sep, quote, esc: char
    skipWhite: bool
    currRow: int
    headers*: seq[string] ## The columns that are defined in the csv file
                          ## (read using `readHeaderRow <#readHeaderRow.CsvParser>`_).
                          ## Used with `rowEntry <#rowEntry.CsvParser.string>`_).

  CsvError* = object of IOError ## exception that is raised if
                                ## a parsing error occurs

proc raiseEInvalidCsv(filename: string, line, col: int,
                      msg: string) {.noreturn.} =
  var e: ref CsvError
  new(e)
  if filename.len == 0:
    e.msg = "Error: " & msg
  else:
    e.msg = filename & "(" & $line & ", " & $col & ") Error: " & msg
  raise e

proc error(my: CsvParser, pos: int, msg: string) =
  raiseEInvalidCsv(my.filename, my.lineNumber, getColNumber(my, pos), msg)

proc open*(my: var CsvParser, input: Stream, filename: string,
           separator = ',', quote = '"', escape = '\0',
           skipInitialSpace = false) =
  ## initializes the parser with an input stream. `Filename` is only used
  ## for nice error messages. The parser's behaviour can be controlled by
  ## the diverse optional parameters:
  ## - `separator`: character used to separate fields
  ## - `quote`: Used to quote fields containing special characters like
  ##   `separator`, `quote` or new-line characters. '\0' disables the parsing
  ##   of quotes.
  ## - `escape`: removes any special meaning from the following character;
  ##   '\0' disables escaping; if escaping is disabled and `quote` is not '\0',
  ##   two `quote` characters are parsed one literal `quote` character.
  ## - `skipInitialSpace`: If true, whitespace immediately following the
  ##   `separator` is ignored.
  lexbase.open(my, input)
  my.filename = filename
  my.sep = separator
  my.quote = quote
  my.esc = escape
  my.skipWhite = skipInitialSpace
  my.row = @[]
  my.currRow = 0

proc open*(my: var CsvParser, filename: string,
           separator = ',', quote = '"', escape = '\0',
           skipInitialSpace = false) =
  ## same as the other `open` but creates the file stream for you.
  var s = newFileStream(filename, fmRead)
  if s == nil: my.error(0, "cannot open: " & filename)
  open(my, s, filename, separator,
       quote, escape, skipInitialSpace)

proc parseField(my: var CsvParser, a: var string) =
  var pos = my.bufpos
  var buf = my.buf
  if my.skipWhite:
    while buf[pos] in {' ', '\t'}: inc(pos)
  setLen(a, 0) # reuse memory
  if buf[pos] == my.quote and my.quote != '\0':
    inc(pos)
    while true:
      let c = buf[pos]
      if c == '\0':
        my.bufpos = pos # can continue after exception?
        error(my, pos, my.quote & " expected")
        break
      elif c == my.quote:
        if my.esc == '\0' and buf[pos+1] == my.quote:
          add(a, my.quote)
          inc(pos, 2)
        else:
          inc(pos)
          break
      elif c == my.esc:
        add(a, buf[pos+1])
        inc(pos, 2)
      else:
        case c
        of '\c':
          pos = handleCR(my, pos)
          buf = my.buf
          add(a, "\n")
        of '\l':
          pos = handleLF(my, pos)
          buf = my.buf
          add(a, "\n")
        else:
          add(a, c)
          inc(pos)
  else:
    while true:
      let c = buf[pos]
      if c == my.sep: break
      if c in {'\c', '\l', '\0'}: break
      add(a, c)
      inc(pos)
  my.bufpos = pos

proc processedRows*(my: var CsvParser): int =
  ## returns number of the processed rows
  return my.currRow

proc readRow*(my: var CsvParser, columns = 0): bool =
  ## reads the next row; if `columns` > 0, it expects the row to have
  ## exactly this many columns. Returns false if the end of the file
  ## has been encountered else true.
  ##
  ## Blank lines are skipped.
  var col = 0 # current column
  let oldpos = my.bufpos
  while my.buf[my.bufpos] != '\0':
    let oldlen = my.row.len
    if oldlen < col+1:
      setLen(my.row, col+1)
      my.row[col] = ""
    parseField(my, my.row[col])
    inc(col)
    if my.buf[my.bufpos] == my.sep:
      inc(my.bufpos)
    else:
      case my.buf[my.bufpos]
      of '\c', '\l':
        # skip empty lines:
        while true:
          case my.buf[my.bufpos]
          of '\c': my.bufpos = handleCR(my, my.bufpos)
          of '\l': my.bufpos = handleLF(my, my.bufpos)
          else: break
      of '\0': discard
      else: error(my, my.bufpos, my.sep & " expected")
      break

  setLen(my.row, col)
  result = col > 0
  if result and col != columns and columns > 0:
    error(my, oldpos+1, $columns & " columns expected, but found " &
          $col & " columns")
  inc(my.currRow)

proc close*(my: var CsvParser) {.inline.} =
  ## closes the parser `my` and its associated input stream.
  lexbase.close(my)

proc readHeaderRow*(my: var CsvParser) =
  ## Reads the first row and creates a look-up table for column numbers
  ## See also `rowEntry <#rowEntry.CsvParser.string>`_.
  let present = my.readRow()
  if present:
    my.headers = my.row

proc rowEntry*(my: var CsvParser, entry: string): var string =
  ## Acceses a specified `entry` from the current row.
  ##
  ## Assumes that `readHeaderRow <#readHeaderRow.CsvParser>`_ has already been
  ## called.
  let index = my.headers.find(entry)
  if index >= 0:
    result = my.row[index]

when not defined(testing) and isMainModule:
  import os
  var s = newFileStream(paramStr(1), fmRead)
  if s == nil: quit("cannot open the file" & paramStr(1))
  var x: CsvParser
  open(x, s, paramStr(1))
  while readRow(x):
    echo "new row: "
    for val in items(x.row):
      echo "##", val, "##"
  close(x)

when isMainModule:
  import os
  import strutils
  block: # Tests for reading the header row
    let content = "One,Two,Three,Four\n1,2,3,4\n10,20,30,40,\n100,200,300,400\n"
    writeFile("temp.csv", content)

    var p: CsvParser
    p.open("temp.csv")
    p.readHeaderRow()
    while p.readRow():
      let zeros = repeat('0', p.currRow-2)
      doAssert p.rowEntry("One") == "1" & zeros
      doAssert p.rowEntry("Two") == "2" & zeros
      doAssert p.rowEntry("Three") == "3" & zeros
      doAssert p.rowEntry("Four") == "4" & zeros
    p.close()

    when not defined(testing):
      var parser: CsvParser
      parser.open("temp.csv")
      parser.readHeaderRow()
      while parser.readRow():
        echo "new row: "
        for col in items(parser.headers):
          echo "##", col, ":", parser.rowEntry(col), "##"
      parser.close()
      removeFile("temp.csv")

    # Tidy up
    removeFile("temp.csv")

