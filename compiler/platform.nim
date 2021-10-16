#
#
#           The Nim Compiler
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module contains data about the different processors
# and operating systems.
# Note: Unfortunately if an OS or CPU is listed here this does not mean that
# Nim has been tested on this platform or that the RTL has been ported.
# Feel free to test for your excentric platform!

import
  strutils

type
  TSystemOS* = enum # Also add OS in initialization section and alias
                    # conditionals to condsyms (end of module).
    osNone, osDos, osWindows, osOs2, osLinux, osMorphos, osSkyos, osSolaris,
    osIrix, osNetbsd, osFreebsd, osOpenbsd, osDragonfly, osCrossos, osAix, osPalmos, osQnx,
    osAmiga, osAtari, osNetware, osMacos, osMacosx, osIos, osHaiku, osAndroid, osVxWorks
    osGenode, osJS, osNimVM, osStandalone, osNintendoSwitch, osFreeRTOS, osZephyr, osAny

type
  TInfoOSProp* = enum
    ospNeedsPIC,              # OS needs PIC for libraries
    ospCaseInsensitive,       # OS filesystem is case insensitive
    ospPosix,                 # OS is posix-like
    ospLacksThreadVars        # OS lacks proper __threadvar support
  TInfoOSProps* = set[TInfoOSProp]
  TInfoOS* = tuple[name: string, parDir: string, dllFrmt: string,
                   altDirSep: string, objExt: string, newLine: string,
                   pathSep: string, dirSep: string, scriptExt: string,
                   curDir: string, exeExt: string, extSep: string,
                   props: TInfoOSProps]

const
  OS*: array[succ(low(TSystemOS))..high(TSystemOS), TInfoOS] = [
     (name: "DOS",
      parDir: "..", dllFrmt: "$1.dll", altDirSep: "/", objExt: ".obj",
      newLine: "\x0D\x0A", pathSep: ";", dirSep: "\\", scriptExt: ".bat",
      curDir: ".", exeExt: ".exe", extSep: ".", props: {ospCaseInsensitive}),
     (name: "Windows", parDir: "..", dllFrmt: "$1.dll", altDirSep: "/",
      objExt: ".obj", newLine: "\x0D\x0A", pathSep: ";", dirSep: "\\",
      scriptExt: ".bat", curDir: ".", exeExt: ".exe", extSep: ".",
      props: {ospCaseInsensitive}),
     (name: "OS2", parDir: "..",
      dllFrmt: "$1.dll", altDirSep: "/",
      objExt: ".obj", newLine: "\x0D\x0A",
      pathSep: ";", dirSep: "\\",
      scriptExt: ".bat", curDir: ".",
      exeExt: ".exe", extSep: ".",
      props: {ospCaseInsensitive}),
     (name: "Linux", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "MorphOS", parDir: "..",
      dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A",
      pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".",
      exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "SkyOS", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "Solaris", parDir: "..",
      dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A",
      pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".",
      exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "Irix", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "NetBSD", parDir: "..",
      dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A",
      pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".",
      exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "FreeBSD", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "OpenBSD", parDir: "..",
      dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A",
      pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".",
      exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "DragonFly", parDir: "..",
      dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A",
      pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".",
      exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "CROSSOS", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "AIX", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "PalmOS", parDir: "..",
      dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A",
      pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".",
      exeExt: "", extSep: ".",
      props: {ospNeedsPIC}),
     (name: "QNX",
      parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/", objExt: ".o",
      newLine: "\x0A", pathSep: ":", dirSep: "/", scriptExt: ".sh", curDir: ".",
      exeExt: "", extSep: ".", props: {ospNeedsPIC, ospPosix}),
     (name: "Amiga",
      parDir: "..", dllFrmt: "$1.library", altDirSep: "/", objExt: ".o",
      newLine: "\x0A", pathSep: ":", dirSep: "/", scriptExt: ".sh", curDir: ".",
      exeExt: "", extSep: ".", props: {ospNeedsPIC}),
     (name: "Atari",
      parDir: "..", dllFrmt: "$1.dll", altDirSep: "/", objExt: ".o",
      newLine: "\x0A", pathSep: ":", dirSep: "/", scriptExt: "", curDir: ".",
      exeExt: ".tpp", extSep: ".", props: {ospNeedsPIC}),
     (name: "Netware",
      parDir: "..", dllFrmt: "$1.nlm", altDirSep: "/", objExt: "",
      newLine: "\x0D\x0A", pathSep: ":", dirSep: "/", scriptExt: ".sh",
      curDir: ".", exeExt: ".nlm", extSep: ".", props: {ospCaseInsensitive}),
     (name: "MacOS", parDir: "::", dllFrmt: "$1Lib", altDirSep: ":",
      objExt: ".o", newLine: "\x0D", pathSep: ",", dirSep: ":", scriptExt: "",
      curDir: ":", exeExt: "", extSep: ".", props: {ospCaseInsensitive}),
     (name: "MacOSX", parDir: "..", dllFrmt: "lib$1.dylib", altDirSep: ":",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix, ospLacksThreadVars}),
     (name: "iOS", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "Haiku", parDir: "..", dllFrmt: "lib$1.so", altDirSep: ":",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix, ospLacksThreadVars}),
     (name: "Android", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "VxWorks", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ";", dirSep: "\\",
      scriptExt: ".sh", curDir: ".", exeExt: ".vxe", extSep: ".",
      props: {ospNeedsPIC, ospPosix, ospLacksThreadVars}),
     (name: "Genode", pardir: "..", dllFrmt: "$1.lib.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: "", curDir: "/", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospLacksThreadVars}),

     (name: "JS", parDir: "..",
      dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A",
      pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".",
      exeExt: "", extSep: ".", props: {}),
     (name: "NimVM", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".", props: {}),
     (name: "Standalone", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {}),
     (name: "NintendoSwitch", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: ".elf", extSep: ".",
      props: {ospNeedsPIC, ospPosix}),
     (name: "FreeRTOS", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospPosix}),
     (name: "Zephyr", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospPosix}),
     (name: "Any", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {}),
     ]

type
  TSystemCPU* = enum # Also add CPU for in initialization section and
                     # alias conditionals to condsyms (end of module).
    cpuNone, cpuI386, cpuM68k, cpuAlpha, cpuPowerpc, cpuPowerpc64,
    cpuPowerpc64el, cpuSparc, cpuVm, cpuHppa, cpuIa64, cpuAmd64, cpuMips,
    cpuMipsel, cpuArm, cpuArm64, cpuJS, cpuNimVM, cpuAVR, cpuMSP430,
    cpuSparc64, cpuMips64, cpuMips64el, cpuRiscV32, cpuRiscV64, cpuEsp, cpuWasm32

type
  TInfoCPU* = tuple[name: string, intSize: int, endian: Endianness,
                    floatSize, bit: int]

const
  EndianToStr*: array[Endianness, string] = ["littleEndian", "bigEndian"]
  CPU*: array[succ(low(TSystemCPU))..high(TSystemCPU), TInfoCPU] = [
    (name: "i386", intSize: 32, endian: littleEndian, floatSize: 64, bit: 32),
    (name: "m68k", intSize: 32, endian: bigEndian, floatSize: 64, bit: 32),
    (name: "alpha", intSize: 64, endian: littleEndian, floatSize: 64, bit: 64),
    (name: "powerpc", intSize: 32, endian: bigEndian, floatSize: 64, bit: 32),
    (name: "powerpc64", intSize: 64, endian: bigEndian, floatSize: 64,bit: 64),
    (name: "powerpc64el", intSize: 64, endian: littleEndian, floatSize: 64,bit: 64),
    (name: "sparc", intSize: 32, endian: bigEndian, floatSize: 64, bit: 32),
    (name: "vm", intSize: 32, endian: littleEndian, floatSize: 64, bit: 32),
    (name: "hppa", intSize: 32, endian: bigEndian, floatSize: 64, bit: 32),
    (name: "ia64", intSize: 64, endian: littleEndian, floatSize: 64, bit: 64),
    (name: "amd64", intSize: 64, endian: littleEndian, floatSize: 64, bit: 64), # a.k.a. x86_64, covers both amd and intel
    (name: "mips", intSize: 32, endian: bigEndian, floatSize: 64, bit: 32),
    (name: "mipsel", intSize: 32, endian: littleEndian, floatSize: 64, bit: 32),
    (name: "arm", intSize: 32, endian: littleEndian, floatSize: 64, bit: 32),
    (name: "arm64", intSize: 64, endian: littleEndian, floatSize: 64, bit: 64),
    (name: "js", intSize: 32, endian: littleEndian, floatSize: 64, bit: 32),
    (name: "nimvm", intSize: 32, endian: bigEndian, floatSize: 64, bit: 32),
      # xxx this seems buggy; on a 64bit machine, sizeof(int) is 64 in nimvm.
    (name: "avr", intSize: 16, endian: littleEndian, floatSize: 32, bit: 16),
    (name: "msp430", intSize: 16, endian: littleEndian, floatSize: 32, bit: 16),
    (name: "sparc64", intSize: 64, endian: bigEndian, floatSize: 64, bit: 64),
    (name: "mips64", intSize: 64, endian: bigEndian, floatSize: 64, bit: 64),
    (name: "mips64el", intSize: 64, endian: littleEndian, floatSize: 64, bit: 64),
    (name: "riscv32", intSize: 32, endian: littleEndian, floatSize: 64, bit: 32),
    (name: "riscv64", intSize: 64, endian: littleEndian, floatSize: 64, bit: 64),
    (name: "esp", intSize: 32, endian: littleEndian, floatSize: 64, bit: 32),
    (name: "wasm32", intSize: 32, endian: littleEndian, floatSize: 64, bit: 32)]

type
  Target* = object
    targetCPU*, hostCPU*: TSystemCPU
    targetOS*, hostOS*: TSystemOS
    intSize*: int
    floatSize*: int
    ptrSize*: int
    tnl*: string                # target newline

proc setTarget*(t: var Target; o: TSystemOS, c: TSystemCPU) =
  assert(c != cpuNone)
  assert(o != osNone)
  #echo "new Target: OS: ", o, " CPU: ", c
  t.targetCPU = c
  t.targetOS = o
  t.intSize = CPU[c].intSize div 8
  t.floatSize = CPU[c].floatSize div 8
  t.ptrSize = CPU[c].bit div 8
  t.tnl = OS[o].newLine

proc nameToOS*(name: string): TSystemOS =
  for i in succ(osNone)..high(TSystemOS):
    if cmpIgnoreStyle(name, OS[i].name) == 0:
      return i
  result = osNone

proc listOSnames*(): seq[string] =
  for i in succ(osNone)..high(TSystemOS):
    result.add OS[i].name

proc nameToCPU*(name: string): TSystemCPU =
  for i in succ(cpuNone)..high(TSystemCPU):
    if cmpIgnoreStyle(name, CPU[i].name) == 0:
      return i
  result = cpuNone

proc listCPUnames*(): seq[string] =
  for i in succ(cpuNone)..high(TSystemCPU):
    result.add CPU[i].name

proc setTargetFromSystem*(t: var Target) =
  t.hostOS = nameToOS(system.hostOS)
  t.hostCPU = nameToCPU(system.hostCPU)
  t.setTarget(t.hostOS, t.hostCPU)
