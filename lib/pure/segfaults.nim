#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This modules registers a signal handler that turns access violations /
## segfaults into a ``NilAccessError`` exception. To be able to catch
## a NilAccessError all you have to do is to import this module.

type
  NilAccessError* = object of SystemError ## \
    ## Raised on dereferences of ``nil`` pointers.

# do allocate memory upfront:
var se: ref NilAccessError
new(se)
se.msg = ""

when defined(windows):
  include "$lib/system/ansi_c"

  {.push stackTrace: off.}
  proc segfaultHandler(sig: cint) {.noconv.} =
    {.gcsafe.}:
      raise se
  {.pop.}
  c_signal(SIGSEGV, segfaultHandler)

else:
  import posix

  var sa: Sigaction

  var SEGV_MAPERR {.importc, header: "<signal.h>".}: cint

  {.push stackTrace: off.}
  proc segfaultHandler(sig: cint, y: var SigInfo, z: pointer) {.noconv.} =
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
