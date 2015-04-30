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
# Nimrod has been tested on this platform or that the RTL has been ported.
# Feel free to test for your excentric platform!

import
  strutils

type
  TSystemOS* = enum # Also add OS in initialization section and alias
                    # conditionals to condsyms (end of module).
    osNone, osDos, osWindows, osOs2, osLinux, osMorphos, osSkyos, osSolaris,
    osIrix, osNetbsd, osFreebsd, osOpenbsd, osAix, osPalmos, osQnx, osAmiga,
    osAtari, osNetware, osMacos, osMacosx, osHaiku, osVxworks,
    osJS, osNimrodVM, osStandalone

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
     (name: "Haiku", parDir: "..", dllFrmt: "lib$1.so", altDirSep: ":",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {ospNeedsPIC, ospPosix, ospLacksThreadVars}),
     (name: "VxWorks", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ";", dirSep: "\\",
      scriptExt: ".sh", curDir: ".", exeExt: ".vxe", extSep: ".",
      props: {ospNeedsPIC, ospPosix, ospLacksThreadVars}),
     (name: "JS", parDir: "..",
      dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A",
      pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".",
      exeExt: "", extSep: ".", props: {}),
     (name: "NimrodVM", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".", props: {}),
     (name: "Standalone", parDir: "..", dllFrmt: "lib$1.so", altDirSep: "/",
      objExt: ".o", newLine: "\x0A", pathSep: ":", dirSep: "/",
      scriptExt: ".sh", curDir: ".", exeExt: "", extSep: ".",
      props: {})]

type
  TSystemCPU* = enum # Also add CPU for in initialization section and
                     # alias conditionals to condsyms (end of module).
    cpuNone, cpuI386, cpuM68k, cpuAlpha, cpuPowerpc, cpuPowerpc64,
    cpuSparc, cpuVm, cpuIa64, cpuAmd64, cpuMips, cpuArm,
    cpuJS, cpuNimrodVM, cpuAVR

type
  TEndian* = enum
    littleEndian, bigEndian
  TInfoCPU* = tuple[name: string, intSize: int, endian: TEndian,
                    floatSize, bit: int]

const
  EndianToStr*: array[TEndian, string] = ["littleEndian", "bigEndian"]
  CPU*: array[succ(low(TSystemCPU))..high(TSystemCPU), TInfoCPU] = [
    (name: "i386", intSize: 32, endian: littleEndian, floatSize: 64, bit: 32),
    (name: "m68k", intSize: 32, endian: bigEndian, floatSize: 64, bit: 32),
    (name: "alpha", intSize: 64, endian: littleEndian, floatSize: 64, bit: 64),
    (name: "powerpc", intSize: 32, endian: bigEndian, floatSize: 64, bit: 32),
    (name: "powerpc64", intSize: 64, endian: bigEndian, floatSize: 64,bit: 64),
    (name: "sparc", intSize: 32, endian: bigEndian, floatSize: 64, bit: 32),
    (name: "vm", intSize: 32, endian: littleEndian, floatSize: 64, bit: 32),
    (name: "ia64", intSize: 64, endian: littleEndian, floatSize: 64, bit: 64),
    (name: "amd64", intSize: 64, endian: littleEndian, floatSize: 64, bit: 64),
    (name: "mips", intSize: 32, endian: bigEndian, floatSize: 64, bit: 32),
    (name: "arm", intSize: 32, endian: littleEndian, floatSize: 64, bit: 32),
    (name: "js", intSize: 32, endian: bigEndian,floatSize: 64,bit: 32),
    (name: "nimrodvm", intSize: 32, endian: bigEndian, floatSize: 64, bit: 32),
    (name: "avr", intSize: 16, endian: littleEndian, floatSize: 32, bit: 16)]

var
  targetCPU*, hostCPU*: TSystemCPU
  targetOS*, hostOS*: TSystemOS

proc nameToOS*(name: string): TSystemOS
proc nameToCPU*(name: string): TSystemCPU

var
  intSize*: int
  floatSize*: int
  ptrSize*: int
  tnl*: string                # target newline

proc setTarget*(o: TSystemOS, c: TSystemCPU) =
  assert(c != cpuNone)
  assert(o != osNone)
  #echo "new Target: OS: ", o, " CPU: ", c
  targetCPU = c
  targetOS = o
  intSize = CPU[c].intSize div 8
  floatSize = CPU[c].floatSize div 8
  ptrSize = CPU[c].bit div 8
  tnl = OS[o].newLine

proc nameToOS(name: string): TSystemOS =
  for i in countup(succ(osNone), high(TSystemOS)):
    if cmpIgnoreStyle(name, OS[i].name) == 0:
      return i
  result = osNone

proc nameToCPU(name: string): TSystemCPU =
  for i in countup(succ(cpuNone), high(TSystemCPU)):
    if cmpIgnoreStyle(name, CPU[i].name) == 0:
      return i
  result = cpuNone

hostCPU = nameToCPU(system.hostCPU)
hostOS = nameToOS(system.hostOS)

setTarget(hostOS, hostCPU) # assume no cross-compiling

