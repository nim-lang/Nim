import
  unittest, osproc, streams, os
const STRING_DATA = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
const TEST_FILE = "tests/testdata/string.txt"

proc echoLoop(str: string): string =
  result = ""
  var process = startProcess(findExe("tests/system/helpers/readall_echo"))
  var input = process.inputStream
  input.write(str)
  input.close()
  var output = process.outputStream
  discard process.waitForExit
  while not output.atEnd:
    result.add(output.readLine)

suite "io":
  suite "readAll":
    test "stdin":
      check:
        echoLoop(STRING_DATA) == STRING_DATA
        echoLoop(STRING_DATA[0..3999]) == STRING_DATA[0..3999]
    test "file":
      check:
        readFile(TEST_FILE) == STRING_DATA
