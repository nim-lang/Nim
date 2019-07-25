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

    proc GetSystemInfo(lpSystemInfo: var SYSTEM_INFO)
      {.stdcall, dynlib: "kernel32", importc: "GetSystemInfo".}

    var
      si: SYSTEM_INFO
    GetSystemInfo(si)
    result = si.dwNumberOfProcessors
  elif defined(macosx) or defined(bsd):
    var
      mib: array[0..3, cint]
      numCpu: int
      len: csize
    mib[0] = CTL_HW
    mib[1] = HW_AVAILCPU
    len = sizeof(numCpu)
    discard sysctl(addr(mib), 2, addr(numCpu), len, nil, 0)
    if numCpu < 1:
      mib[1] = HW_NCPU
      discard sysctl(addr(mib), 2, addr(numCpu), len, nil, 0)
    result = numCpu
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

# TODO(awr1): get cache line size
# TODO(awr1): get processor name
# TODO(awr1): ARM processor exts
# TODO(awr1): on ARM, probe /proc/cpuinfo, but what about windows on arm?

const
  onX86 = defined(i386) or defined(amd64)
  onArm = defined(arm) or defined(arm64)

when onX86:
  proc cpuidX86(leaf: int32): tuple[eax, ebx, ecx, edx: int32] =
    when defined(vcc):
      # limited inline asm support in vcc, so intrinsics, here we go:
      proc cpuidVcc(cpuInfo: ptr int32; functionID: int32)
        {.cdecl, importc: "__cpuid", header: "intrin.h".}
      cpuidVcc(addr result.eax, leaf)
    else:
      var (eaxr, ebxr, ecxr, edxr) = (0'i32, 0'i32, 0'i32, 0'i32)
      # zero ecx first!
      asm """
        xorl %%ecx, %%ecx
        cpuid
        :"=a"(`eaxr`), "=b"(`ebxr`), "=c"(`ecxr`), "=d"(`edxr`)
        :"a"(`leaf`) """
      (eaxr, ebxr, ecxr, edxr)

when onX86 or defined(nimdoc):
  type
    X86Feature {.pure.} = enum
      HypervisorPresence, SimultaneousMultithreading, IntelVtx, Amdv, X87fpu,
      Mmx, MmxExt, F3DNow, F3DNowExt, F3DNowPf, Sse, Sse2, Sse3, Ssse3, Sse4a,
      Sse41, Sse42, Avx, Avx2, Avx512f, Avx512dq, Avx512ifma, Avx512pf,
      Avx512er, Avx512cd, Avx512bw, Avx512vl, Avx512vbmi, Avx512vbmi2,
      Avx512vpopcntdq, Avx512vnni, Avx512vnniw4, Avx512fmaps4, Avx512bitalg,
      Rdrand, Rdseed, MovBigEndian, Popcnt, Fma3, Fma4, Cas8B, Cas16B, Abm,
      Bmi1, Bmi2, TsxHle, TsxRtm, Adx, Sgx, Gfni, Aes, Vaes, Vpclmulqdq,
      Pclmulqdq, NxBit, Float16c, Ssbd, SpecCtrl, Stibp, Sha, Clflush,
      ClflushOpt, Clwriteback, PrefetchWT1, Mpx

  # The reason why we don't just evaluate these directly in the `let` variable
  # list is so that we can internally organize features by their input (leaf)
  # and output registers.
  proc testX86Feature(features: X86Feature): bool =
    let
      leaf1 {.global.} = cpuidX86(leaf = 1)
      leaf7 {.global.} = cpuidX86(leaf = 7)
      leaf8 {.global.} = cpuidX86(leaf = 0x80000001'i32)

    template test(input, bit: int): bool =
      ((1 shl bit) and input) != 0

    # see: https://en.wikipedia.org/wiki/CPUID#Calling_CPUID
    case feature
    # leaf 1, edx
    of X87fpu:
      leaf1.edx.test(0)
    of Clflush:
      leaf1.edx.test(19)
    of Mmx:
      leaf1.edx.test(23)
    of Sse:
      leaf1.edx.test(25)
    of Sse2:
      leaf1.edx.test(26)
    of SimultaneousMultithreading:
      leaf1.edx.test(28) or not leaf8.edx.test(1)

    # leaf 1, ecx
    of Sse3:
      leaf1.ecx.test(0)
    of Pclmulqdq:
      leaf1.ecx.test(1)
    of IntelVtx:
      leaf1.ecx.test(5)
    of Ssse3:
      leaf1.ecx.test(9)
    of Fma3:
      leaf1.ecx.test(12)
    of Cas16B:
      leaf1.ecx.test(13)
    of Sse41:
      leaf1.ecx.test(19)
    of Sse42:
      leaf1.ecx.test(20)
    of MovBigEndian:
      leaf1.ecx.test(22)
    of Popcnt:
      leaf1.ecx.test(23)
    of Aes:
      leaf1.ecx.test(25)
    of Avx:
      leaf1.ecx.test(28)
    of Float16c:
      leaf1.ecx.test(29)
    of Rdrand:
      leaf1.ecx.test(30)
    of HypervisorPresence:
      leaf1.ecx.test(31)

    # leaf 7, ecx
    of PrefetchWT1:
      leaf7.ecx.test(0)
    of Avx512vbmi:
      leaf7.ecx.test(1)
    of Avx512vbmi2:
      leaf7.ecx.test(6)
    of Gfni:
      leaf7.ecx.test(8)
    of Vaes:
      leaf7.ecx.test(9)
    of Vpclmulqdq:
      leaf7.ecx.test(10)
    of Avx512vnni:
      leaf7.ecx.test(11)
    of Avx512bitalg:
      leaf7.ecx.test(12)
    of Avx512vpopcntdq:
      leaf7.ecx.test(14)

    # leaf 7, ebx
    of Sgx:
      leaf7.ebx.test(2)
    of Bmi1:
      leaf7.ebx.test(3)
    of TsxHle:
      leaf7.ebx.test(4)
    of Avx2:
      leaf7.ebx.test(5)
    of Bmi2:
      leaf7.ebx.test(8)
    of TsxRtm:
      leaf7.ebx.test(11)
    of Mpx:
      leaf7.ebx.test(14)
    of Avx512f:
      leaf7.ebx.test(16)
    of Avx512dq:
      leaf7.ebx.test(17)
    of Rdseed:
      leaf7.ebx.test(18)
    of Adx:
      leaf7.ebx.test(19)
    of Avx512ifma:
      leaf7.ebx.test(21)
    of ClflushOpt:
      leaf7.ebx.test(23)
    of Clwriteback:
      leaf7.ebx.test(24)
    of Avx512pf:
      leaf7.ebx.test(26)
    of Avx512er:
      leaf7.ebx.test(27)
    of Avx512cd:
      leaf7.ebx.test(28)
    of Sha:
      leaf7.ebx.test(29)
    of Avx512bw:
      leaf7.ebx.test(30)
    of Avx512vl:
      leaf7.ebx.test(31)

    # leaf 7, edx
    of Avx512vnniw4:
      leaf7.edx.test(2)
    of Avx512fmaps4:
      leaf7.edx.test(3)
    of SpecCtrl:
      leaf7.edx.test(26)
    of Stibp:
      leaf7.edx.test(27)
    of Ssbd:
      leaf7.edx.test(31)

    # leaf 8, edx
    of Cas8B:
      leaf8.edx.test(8)
    of NxBit:
      leaf8.edx.test(20)
    of MmxExt:
      leaf8.edx.test(22)
    of F3DNowExt:
      leaf8.edx.test(30)
    of F3DNow:
      leaf8.edx.test(31)

    # leaf 8, ecx
    of AmdV:
      leaf8.ecx.test(2)
    of Abm:
      leaf8.ecx.test(5)
    of Sse4a:
      leaf8.ecx.test(6)
    of F3DNowPf:
      leaf8.ecx.test(8)
    of Fma4:
      leaf8.ecx.test(16)
