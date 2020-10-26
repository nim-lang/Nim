discard """
  output: '''
hello1
hello1
  '''
"""

import std/ioutils
import os

let tmpFileName = "./tmpFile.txt"

template captureStdout*(ident: untyped, body: untyped) =
  var stdoutFileno = stdout.getFileHandle()
  # Duplicate stoudFileno
  var stdout_dupfd = duplicate(stdoutFileno)
  # Create a new file
  # You can use append strategy if you'd like
  var tmpFile: File = open(tmpFileName, fmWrite)
  # Get the FileHandle (the file descriptor) of your file
  var tmpFileFd: FileHandle = tmpFile.getFileHandle()
  # dup2 tmpFileFd to stdoutFileno -> writing to stdoutFileno now writes to tmpFile
  duplicateTo(tmpFileFd, stdoutFileno)
  body
  # Force flush
  tmpFile.flushFile()
  # Close tmp
  tmpFile.close()
  # Read tmp
  ident = readFile(tmpFileName)
  # Restore stdout
  duplicateTo(stdout_dupfd, stdoutFileno)

proc main() =
  var msg = "hello"
  echo msg & "1"
  var s: string

  captureStdout(s):
    echo msg & "2"
    msg = "ciao"

  doAssert s == "hello2\n"

# Dummy filename
discard tryRemoveFile(tmpFileName)
main()
# Check it works twice
main()
discard tryRemoveFile(tmpFileName)
