discard """
  output: '''
hello1
hello1
  '''
"""

import ../../lib/std/ioutils
# import std/ioutils
import os

# Dummy filename
let tmpFileName = "./tmpFile.txt"
discard tryRemoveFile(tmpFileName)

template captureStdout*(ident: untyped, body: untyped) =
  var stdout_fileno = stdout.getFileHandle()
  # Duplicate stoud_fileno
  var stdout_dupfd = duplicate(stdout_fileno)
  # Create a new file
  # You can use append strategy if you'd like
  var tmp_file: File = open(tmpFileName, fmWrite)
  # Get the FileHandle (the file descriptor) of your file
  var tmp_file_fd: FileHandle = tmp_file.getFileHandle()
  # dup2 tmp_file_fd to stdout_fileno -> writing to stdout_fileno now writes to tmp_file
  duplicateTo(tmp_file_fd, stdout_fileno)
  body
  # Force flush
  tmp_file.flushFile()
  # Close tmp
  tmp_file.close()
  # Read tmp
  ident = readFile(tmpFileName)
  # Restore stdout
  duplicateTo(stdout_dupfd, stdout_fileno)

proc main() =
  var msg = "hello"
  echo msg & "1"
  var s: string

  captureStdout(s):
    echo msg & "2"
    msg = "ciao"

  doAssert s == "hello2\n"

when isMainModule:
  main()
  # Check it works twice
  main()
  discard tryRemoveFile(tmpFileName)