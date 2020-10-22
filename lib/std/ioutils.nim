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

const SupportIoctlInheritCtl = (defined(linux) or defined(bsd)) and
                              not defined(nimscript)
when SupportIoctlInheritCtl:
  var
    FIOCLEX {.importc, header: "<sys/ioctl.h>".}: cint
    FIONCLEX {.importc, header: "<sys/ioctl.h>".}: cint


proc strerror(errnum: cint): cstring {.importc, header: "<string.h>".}

when not defined(NimScript):
  var
    errno {.importc, header: "<errno.h>".}: cint ## error variable

proc duplicate*(oldfd: FileHandle): FileHandle =
  ##[
    Return a copy of the file handle oldfd.
    After a successful return, both FileHandle may be used interchangeably.
    They refer to the same open file description and share file offset and status flags.
    Calls POSIX function `dup` on Linux and  `_dup` on Windows
  ]##
  let retValue = c_dup(oldfd)
  if retValue != -1:
    retValue
  else:
    when not defined(NimScript):
      # Raise
      var e: ref Exception
      new(e)
      e.msg = $strerror(errno)
      raise e
    else:
      # Same as checkErr
      quit(1)

proc duplicateTo*(oldfd: FileHandle, newfd: FileHandle) =
  ##[
    Perform the same task a `duplicateFileHandle` but instead of using the lowest unused file descriptor
    it uses the file Handle specified by `newfd`.
    Calls POSIX function `dup2` on Linux and `_dup2` on Windows.
  ]##
  let retValue = c_dup2(oldfd, newfd)
  if retValue != -1:
    discard
  else:
    when not defined(NimScript):
      # Raise
      var e: ref Exception
      new(e)
      e.msg = $strerror(errno)
      raise e
