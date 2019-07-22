#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements procs to query information about the CPU.

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
  # we HAVE to emit param.h before sysctl.h so we cannot use .header here
  # either. The amount of archaic bullshit in Poonix based OSes is just insane.
  {.emit:"#include <sys/sysctl.h>".}
  const
    CTL_HW = 6
    HW_AVAILCPU = 25
    HW_NCPU = 3
  proc sysctl(x: ptr array[0..3, cint], y: cint, z: pointer,
              a: var csize, b: pointer, c: int): cint {.
              importc: "sysctl", nodecl.}

when defined(genode):
  include genode/env

  proc affinitySpaceTotal(env: GenodeEnvPtr): cuint {.
    importcpp: "@->cpu().affinity_space().total()".}

when defined(haiku):
  type
    SystemInfo {.importc: "system_info", header: "<OS.h>".} = object
      cpuCount {.importc: "cpu_count".}: uint32

  proc getSystemInfo(info: ptr SystemInfo): int32 {.importc: "get_system_info",
                                                    header: "<OS.h>".}

proc countProcessors*(): int {.rtl, extern: "ncpi$1".} =
  ## returns the numer of the processors/cores the machine has.
  ## Returns 0 if it cannot be detected.
  when defined(windows):
    type
      SYSTEM_INFO {.final, pure.} = object
        u1: int32
        dwPageSize: int32
        lpMinimumApplicationAddress: pointer
        lpMaximumApplicationAddress: pointer
        dwActiveProcessorMask: ptr int32
        dwNumberOfProcessors: int32
        dwProcessorType: int32
        dwAllocationGranularity: int32
        wProcessorLevel: int16
        wProcessorRevision: int16

    proc GetSystemInfo(lpSystemInfo: var SYSTEM_INFO) {.stdcall, dynlib: "kernel32", importc: "GetSystemInfo".}

    var
      si: SYSTEM_INFO
    GetSystemInfo(si)
    result = si.dwNumberOfProcessors
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
  elif defined(genode):
    result = runtimeEnv.affinitySpaceTotal().int
  elif defined(haiku):
    var sysinfo: SystemInfo
    if getSystemInfo(addr sysinfo) == 0:
      result = sysinfo.cpuCount.int
  else:
    result = sysconf(SC_NPROCESSORS_ONLN)
  if result <= 0: result = 0

when defined(x86):
  proc cpuidX86(leaf: int32): tuple[eax, ebx, ecx, edx: int32] =
    when defined(vcc):
      # limited inline asm support in vcc, so intrinsics, here we go:
      proc cpuidVcc(cpuInfo: ptr int32, functionID: int32)
        {.cdecl, importc: "__cpuid", header: "intrin.h".}
      var x: array[4, int32]
      cpuidVcc(addr x[0], leaf)
      (x[0], x[1], x[2], x[3])
    else:
      var (eaxr, ebxr, ecxr, edxr) = (0'i32, 0'i32, 0'i32, 0'i32)
      # zero ecx register first!
      asm """
        xor %ecx, %ecx
        cpuid
        :"=a"(`eaxr`), "=b"(`ebxr`), "=c"(`ecxr`), "=d"(`edxr`)
        :"a"(`leaf`) """
      (eaxr, ebxr, ecxr, edxr)
