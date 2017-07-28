discard """
  line: 11
  msg: "Error: unhandled exception: (0, 0) Error: cannot open: nosuchfile.txt [CsvError]"
"""

import parsecsv

# Should get an error message for a missing file (rather than a SIGSEGV)
var parser: CsvParser
parser.open("nosuchfile.txt")
parser.close()