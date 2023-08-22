discard """
outputsub: ""
disabled: true
"""

import
  unittest, osproc, streams, os, strformat, strutils
const STRING_DATA = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."

const TEST_FILE = "tests/testdata/string.txt"

proc echoLoop(str: string): string =
  result = ""
  let exe = findExe("tests/system/helpers/readall_echo")
  echo "exe: ", exe
  var process = startProcess(exe)
  var input = process.inputStream
  input.write(str)
  input.close()
  var output = process.outputStream
  discard process.waitForExit
  while not output.atEnd:
    result.add(output.readLine)

block: # io
  block: # readAll
    block: # stdin
      check:
        echoLoop(STRING_DATA) == STRING_DATA
    block: # file
      check:
        readFile(TEST_FILE).strip == STRING_DATA


proc verifyFileSize(sz: int64) =
  # issue 7121, large file size (2-4GB and >4Gb)
  const fn = "tmpfile112358"
  let size_in_mb = sz div 1_000_000

  when defined(windows):
    discard execProcess(&"fsutil file createnew {fn} {sz}" )
  else:
    discard execProcess(&"dd if=/dev/zero of={fn} bs=1000000 count={size_in_mb}")

  doAssert os.getFileSize(fn) == sz # Verify OS filesize by string

  var f = open(fn)
  doAssert f.getFileSize() == sz # Verify file handle filesize
  f.close()

  os.removeFile(fn)

#disable tests for automatic testers
#for s in [50_000_000'i64, 3_000_000_000, 5_000_000_000]:
#  verifyFileSize(s)
