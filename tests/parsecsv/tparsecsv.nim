 discard """
  action: run
  output: "[Suite] Tests for CSV parser in parsecsv"
  exitCode: 0
 """

import unittest
import parsecsv
 
# Should get an error message for a missing file (rather than a SIGSEGV)

suite "Tests for CSV parser in parsecsv":

  test "Opening blank file should give exception and not SIGSEGV":
    var parser: CsvParser
    expect CsvError:
      parser.open("nosuchfile.txt")
      parser.close()