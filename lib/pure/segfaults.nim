#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This modules registers a signal handler that turns access violations /
## segfaults into a ``NilAccessDefect`` exception. To be able to catch
## a NilAccessDefect all you have to do is to import this module.
##
## Tested on these OSes: Linux, Windows, OSX

# xxx possibly broken on arm64, see bug #17178

{.used.}

# do allocate memory upfront:
var se: ref NilAccessDefect
new(se)
se.name = "NilAccessDefect"
se.msg = "Could not access value because it is nil."

when defined(windows):
  include "../system/ansi_c"

  import winlean

  const
    EXCEPTION_ACCESS_VIOLATION = DWORD(0xc0000005'i32)
    EXCEPTION_CONTINUE_SEARCH = Long(0)

  type
    PEXCEPTION_RECORD = ptr object
      exceptionCode: DWORD # other fields left out

    PEXCEPTION_POINTERS = ptr object
      exceptionRecord: PEXCEPTION_RECORD
      contextRecord: pointer

    VectoredHandler = proc (p: PEXCEPTION_POINTERS): LONG {.stdcall.}
  proc addVectoredExceptionHandler(firstHandler: ULONG,
                                   handler: VectoredHandler): pointer {.
    importc: "AddVectoredExceptionHandler", stdcall, dynlib: "kernel32.dll".}

  {.push stackTrace: off.}
  proc segfaultHandler(p: PEXCEPTION_POINTERS): LONG {.stdcall.} =
    if p.exceptionRecord.exceptionCode == EXCEPTION_ACCESS_VIOLATION:
      {.gcsafe.}:
        raise se
    else:
      result = EXCEPTION_CONTINUE_SEARCH
  {.pop.}

  discard addVectoredExceptionHandler(0, segfaultHandler)

  when false:
    {.push stackTrace: off.}
    proc segfaultHandler(sig: cint) {.noconv.} =
      {.gcsafe.}:
        rawRaise se
    {.pop.}
    c_signal(SIGSEGV, segfaultHandler)

else:
  import posix

  var sa: Sigaction

  var SEGV_MAPERR {.importc, header: "<signal.h>".}: cint

  {.push stackTrace: off.}
  proc segfaultHandler(sig: cint, y: ptr SigInfo, z: pointer) {.noconv.} =
    if y.si_code == SEGV_MAPERR:
      {.gcsafe.}:
        raise se
    else:
      quit(1)
  {.pop.}

  discard sigemptyset(sa.sa_mask)

  sa.sa_sigaction = segfaultHandler
  sa.sa_flags = SA_SIGINFO or SA_NODEFER

  discard sigaction(SIGSEGV, sa)
