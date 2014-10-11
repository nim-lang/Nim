#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements procs to determine the number of CPUs / cores.

include "system/inclrtl"

import strutils, os

when not defined(windows):
  import posix

when defined(linux):
  import linux
  
when defined(freebsd) or defined(macosx):
  {.emit:"#include <sys/types.h>".}

when defined(openbsd) or defined(netbsd):
  {.emit:"#include <sys/param.h>".}

when defined(macosx) or defined(bsd):
  const
    CTL_HW = 6
    HW_AVAILCPU = 25
    HW_NCPU = 3
  proc sysctl(x: ptr array[0..3, cint], y: cint, z: pointer,
              a: var csize, b: pointer, c: int): cint {.
              importc: "sysctl", header: "<sys/sysctl.h>".}

proc countProcessors*(): int {.rtl, extern: "ncpi$1".} =
  ## returns the numer of the processors/cores the machine has.
  ## Returns 0 if it cannot be detected.
  when defined(windows):
    var x = getEnv("NUMBER_OF_PROCESSORS")
    if x.len > 0: result = parseInt(x.string)
  elif defined(macosx) or defined(bsd):
    var
      mib: array[0..3, cint]
      numCPU: int
      len: csize
    mib[0] = CTL_HW
    mib[1] = HW_AVAILCPU
    len = sizeof(numCPU)
    discard sysctl(addr(mib), 2, addr(numCPU), len, nil, 0)
    if numCPU < 1:
      mib[1] = HW_NCPU
      discard sysctl(addr(mib), 2, addr(numCPU), len, nil, 0)
    result = numCPU
  elif defined(hpux):
    result = mpctl(MPC_GETNUMSPUS, nil, nil)
  elif defined(irix):
    var SC_NPROC_ONLN {.importc: "_SC_NPROC_ONLN", header: "<unistd.h>".}: cint
    result = sysconf(SC_NPROC_ONLN)
  else:
    result = sysconf(SC_NPROCESSORS_ONLN)
  if result <= 0: result = 1

