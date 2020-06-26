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

import posix, os, macros

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

proc mkstemp*(prefix: string, suffix=""): (string, File) =
  ## Creates a unique temporary file from a prefix string. A six-character string
  ## will be added. If suffix is provided it will be added to the string
  ## The file is created with perms 0600.
  ## Returns the filename and a file opened in r/w mode.
  var tmpl = cstring(prefix & "XXXXXX" & suffix)
  let fd =
    if len(suffix)==0:
      when declared(mkostemp):
        mkostemp(tmpl, O_CLOEXEC)
      else:
        mkstemp(tmpl)
    else:
      when declared(mkostemps):
        mkostemps(tmpl, cint(len(suffix)), O_CLOEXEC)
      else:
        mkstemps(tmpl, cint(len(suffix)))
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

template ignoreSignalsImpl(sigmask, sigs, body: untyped): untyped =
  var oldSet, watchSet: Sigset
  let signals = sigs
  if sigemptyset(oldSet) == -1:
    raiseOSError(osLastError())
  if sigemptyset(watchSet) == -1:
    raiseOSError(osLastError())

  for s in signals:
    if sigaddset(watchSet, s) == -1:
      raiseOSError(osLastError(), "Couldn't add signal " & $s & " to Sigset")

  if sigmask(SIG_BLOCK, watchSet, oldSet) == -1:
    raiseOSError(osLastError(), "Couldn't block specified signals")

  try:
    body
  finally:
    for s in signals:
      # We are ignoring errors here since the signals must be correct to pass
      # the earlier initialization, thus it's safe to assume that the following
      # calls won't fail.
      if sigismember(oldSet, s) == 1:
        discard sigdelset(watchSet, s)

    try:
      var
        info: Siginfo
        tmspec: Timespec
      while true:
        # Clear all pending signals from the queue before we unblock them.
        while sigtimedwait(watchSet, info, tmspec) != -1:
          discard

        let err = cint osLastError()
        if err == EINTR:
          discard "Interrupted by a signal we didn't block, ignore."
        elif err == EAGAIN:
          break # No signal pending
        else:
          raiseOSError(OSErrorCode err, "Couldn't wait for signals")
    finally:
      if sigmask(SIG_UNBLOCK, watchSet, oldSet) == -1:
        raiseOSError(osLastError(), "Couldn't restore the signal mask")

when defined(linux) or defined(netbsd) or defined(freebsd):
  macro ignoreSignals*(signals: varargs[cint], body: untyped): untyped =
    ## Ignore the specified ``signals`` until the end of the code block.
    ##
    ## It's not guaranteed that synchronous signals (``SIGSEGV``, ``SIGFPE``,
    ## ``SIGILL`` and ``SIGBUS``) can be ignored in all cases. It's recommended
    ## that a signal handler should be installed and used instead of this
    ## template to handle those signals reliably.
    ##
    ## Only signals targeting the calling thread will be ignored.
    ##
    ## This macro is not supported by all POSIX systems, check for existance
    ## with ``system.declared``.
    runnableExamples:
      import posix

      ignoreSignals(SIGTERM, SIGINT, SIGPIPE):
        discard posix.raise(SIGTERM)
        discard posix.raise(SIGINT)
        discard posix.raise(SIGPIPE)

    let sigmask =
      when compileOption("threads"):
        bindSym"pthread_sigmask"
      else:
        bindSym"sigprocmask"

    # Implemented as a template for auto bindSym support. This helper macro
    # serves more or less as a way to support `varargs`.
    result = getAst ignoreSignalsImpl(sigmask, signals, body)
