#
#            Nim's Runtime Library
#    (c) Copyright 2019 Federico Ceratto and other Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## A set of helpers for the POSIX module.
## Raw interfaces are in the other posix*.nim files.

# Where possible, contribute OS-independent procs in `os <os.html>`_ instead.

{.deadCodeElim: on.}  # dce option deprecated

import posix

type Uname* = object
  sysname*, nodename*, release*, version*, machine*: string

template charArrayToString(input: typed): string =
  $cstring(addr input)

proc uname*(): Uname =
  ## Provides system information in a `Uname` struct with sysname, nodename,
  ## release, version and machine attributes.

  when defined(posix):
    runnableExamples:
      echo uname().nodename, uname().release, uname().version
      doAssert uname().sysname.len != 0

  var u: Utsname
  if uname(u) != 0:
    raise newException(OSError, $strerror(errno))

  result.sysname = charArrayToString u.sysname
  result.nodename = charArrayToString u.nodename
  result.release = charArrayToString u.release
  result.version = charArrayToString u.version
  result.machine = charArrayToString u.machine

proc fsync*(fd: int) =
 ## synchronize a file's buffer cache to the storage device
 if fsync(fd.cint) != 0:
    raise newException(OSError, $strerror(errno))

proc stat*(path: string): Stat =
  ## Returns file status in a `Stat` structure
  if stat(path.cstring, result) != 0:
    raise newException(OSError, $strerror(errno))

proc memoryLock*(a1: pointer, a2: int) =
  ## Locks pages starting from a1 for a1 bytes and prevent them from being swapped.
  if mlock(a1, a2) != 0:
    raise newException(OSError, $strerror(errno))

proc memoryLockAll*(flags: int) =
  ## Locks all memory for the running process to prevent swapping.
  ##
  ## example::
  ##
  ##   memoryLockAll(MCL_CURRENT or MCL_FUTURE)
  if mlockall(flags.cint) != 0:
    raise newException(OSError, $strerror(errno))

proc memoryUnlock*(a1: pointer, a2: int) =
  ## Unlock pages starting from a1 for a1 bytes and allow them to be swapped.
  if munlock(a1, a2) != 0:
    raise newException(OSError, $strerror(errno))

proc memoryUnlockAll*() =
  ## Unlocks all memory for the running process to allow swapping.
  if munlockall() != 0:
    raise newException(OSError, $strerror(errno))

proc sendSignal*(pid: Pid, signal: int) =
  ## Sends a signal to a running process by calling `kill`.
  ## Raise exception in case of failure e.g. process not running.
  if kill(pid, signal.cint) != 0:
    raise newException(OSError, $strerror(errno))

proc mkstemp*(prefix: string): (string, File) =
  ## Creates a unique temporary file from a prefix string. Adds a six chars suffix.
  ## The file is created with perms 0600.
  ## Returs the filename and a file opened in r/w mode.
  var tmpl = cstring(prefix & "XXXXXX")
  let fd = mkstemp(tmpl)
  var f: File
  if open(f, fd, fmReadWrite):
    return ($tmpl, f)
  raise newException(OSError, $strerror(errno))

proc mkdtemp*(prefix: string): string =
  ## Creates a unique temporary directory from a prefix string. Adds a six chars suffix.
  ## The directory is created with permissions 0700. Returns the directory name.
  var tmpl = cstring(prefix & "XXXXXX")
  if mkdtemp(tmpl) == nil:
    raise newException(OSError, $strerror(errno))
  return $tmpl

