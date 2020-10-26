when defined(windows):
  proc c_dup(oldfd: FileHandle): FileHandle {.
    importc:"_dup", header: "<io.h>".}
  proc c_dup2(oldfd: FileHandle, newfd: FileHandle): cint {.
    importc: "_dup2", header: "<io.h>".}
else:
  proc c_dup(oldfd: FileHandle): FileHandle{.
    importc: "dup", header: "<unistd.h>".}
  proc c_dup2(oldfd: FileHandle, newfd: FileHandle): cint {.
    importc: "dup2", header: "<unistd.h>".}

# when false:
#   const SupportIoctlInheritCtl = (defined(linux) or defined(bsd)) and
#                                 not defined(nimscript)
#   when SupportIoctlInheritCtl:
#     var
#       FIOCLEX {.importc, header: "<sys/ioctl.h>".}: cint
#       FIONCLEX {.importc, header: "<sys/ioctl.h>".}: cint

## Also defined in std/posix and system/io
proc strerror(errnum: cint): cstring {.importc, header: "<string.h>".}
when not defined(nimScript):
  var errno {.importc, header: "<errno.h>".}: cint ## error variable

template checkError(ret: cint)=
  if ret == -1:
    when not defined(nimScript):
      raise newException(IOError, $strerror(errno))
    else:
      doAssert(false)

proc duplicate*(oldfd: FileHandle): FileHandle =
  ##[
  Return a copy of the file handle `oldfd`.
  After a successful return, both `FileHandle` may be used interchangeably.
  They refer to the same open file description and share file offset and status flags.
  Calls POSIX function `dup` on Posix platform and  `_dup` on Windows
  ]##
  runnableExamples:
    # Duplicating stdout and writing to it
    let stdoutHolder = duplicate(stdout.getFileHandle)
    var f : File
    let res = open(f, stdoutHolder, mode=fmWrite)
    f.write("Test\n")
    # Output "Test"
    f.close()

  result = c_dup(oldfd)
  checkError(result)

proc duplicateTo*(oldfd: FileHandle, newfd: FileHandle) =
  ##[
  Perform the same task a `duplicate` but instead of using the lowest unused file descriptor
  it uses the FileHandle` specified by `newfd`.
  Calls POSIX function `dup2` on Posix platform and `_dup2` on Windows.
  ]##
  runnableExamples:
    # Redirect stdout to a file temporarily
    let tmpFileName = "./hidden_output.txt"
    let stdoutFileno = stdout.getFileHandle()
    let stdoutDupFd = duplicate(stdoutFileno)

    # Create a new file
    let tmpFile: File = open(tmpFileName, fmAppend)
    let tmpFileFd: FileHandle = tmpFile.getFileHandle()

    # stdoutFileno now writes to tmpFile
    duplicateTo(tmpFileFd, stdoutFileno)
    echo "This is not displayed, but written to tmpFile instead !"

    # Close file & restore stdout
    tmpFile.close()
    duplicateTo(stdoutDupFd, stdoutFileno)

    # stdout is now restored !
    echo "This is displayed"

  let retValue = c_dup2(oldfd, newfd)
  checkError(retValue)
