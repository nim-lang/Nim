discard """
  output: '''
hello1
hello1
'''
"""

import std/ioutils
import os
from stdtest/specialpaths import buildDir

block: # duplicate, duplicateTo
  let tmpFileName = buildDir / "tioutils.txt"
  template captureStdout(body) : untyped =
    let stdoutFileno = stdout.getFileHandle()
    # Duplicate stoudFileno
    let stdout_dupfd = duplicate(stdoutFileno)
    # Create a new file
    # You can use append strategy if you'd like
    let tmpFile: File = open(tmpFileName, fmWrite)
    # Get the FileHandle (the file descriptor) of your file
    let tmpFileFd: FileHandle = tmpFile.getFileHandle()
    # dup2 tmpFileFd to stdoutFileno -> writing to stdoutFileno now writes to tmpFile
    duplicateTo(tmpFileFd, stdoutFileno)
    body
    # Force flush
    tmpFile.flushFile()
    # Close tmp
    tmpFile.close()
    # Read tmp
    let ret = readFile(tmpFileName)
    # Restore stdout
    duplicateTo(stdout_dupfd, stdoutFileno)
    ret

  proc duplicateStdout() =
    var msg = "hello"
    echo msg & "1"

    let s = captureStdout:
      echo msg & "2"

    doAssert s == "hello2\n"

  discard tryRemoveFile(tmpFileName)
  duplicateStdout()
  # Check it works twice
  duplicateStdout()
  doAssert tryRemoveFile(tmpFileName)
