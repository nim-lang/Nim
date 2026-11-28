#
#
#           The Nim Compiler
#        (c) Copyright 2026 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Blocking OS locks shared by IC cache writers. Closing the handle also
## releases the lock if compilation exits early.
import std/[os, syncio]

when defined(windows):
  import std/winlean

  proc lockFileEx(hFile: Handle; flags, reserved, lowLen, highLen: int32;
                  overlapped: ptr OVERLAPPED): WINBOOL {.
      stdcall, dynlib: "kernel32", importc: "LockFileEx".}
  proc unlockFileEx(hFile: Handle; reserved, lowLen, highLen: int32;
                    overlapped: ptr OVERLAPPED): WINBOOL {.
      stdcall, dynlib: "kernel32", importc: "UnlockFileEx".}
  const LockfileExclusiveLock = 2'i32
else:
  proc flock(fd: cint; op: cint): cint {.importc, header: "<sys/file.h>".}
  var LockEx {.importc: "LOCK_EX", header: "<sys/file.h>".}: cint
  var LockUn {.importc: "LOCK_UN", header: "<sys/file.h>".}: cint
  var Eintr {.importc: "EINTR", header: "<errno.h>".}: cint

proc lockExclusive*(f: File) =
  when defined(windows):
    var ov = default(OVERLAPPED)
    if lockFileEx(Handle(getOsFileHandle(f)), LockfileExclusiveLock, 0, 1, 0,
                  addr ov) == 0:
      raiseOSError(osLastError())
  else:
    while flock(getOsFileHandle(f), LockEx) != 0:
      let err = osLastError()
      if err != OSErrorCode(Eintr): raiseOSError(err)

proc unlock*(f: File) =
  when defined(windows):
    var ov = default(OVERLAPPED)
    discard unlockFileEx(Handle(getOsFileHandle(f)), 0, 1, 0, addr ov)
  else:
    discard flock(getOsFileHandle(f), LockUn)
