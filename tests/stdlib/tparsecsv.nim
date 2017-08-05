 discard """
  action: run
  output: "Got expected CSV error"
  exitCode: 0
 """

import parsecsv
from strutils import contains
 
# Should get an error message for a missing file (rather than a SIGSEGV)

var parser : CsvParser
try:
  parser.open("nosuchfile.txt")
  parser.close()
except CsvError as cve:
  echo "Got expected CSV error"