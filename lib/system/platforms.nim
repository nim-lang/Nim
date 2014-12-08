#
#
#            Nim's Runtime Library
#        (c) Copyright 2014 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Platform detection for Nim. This module is included by the system module!
## Do not import it directly!

type
  CpuPlatform* {.pure.} = enum ## the CPU this program will run on.
    none,                      ## unknown CPU
    i386,                      ## 32 bit x86 compatible CPU
    m68k,                      ## M68k based processor
    alpha,                     ## Alpha processor
    powerpc,                   ## 32 bit PowerPC
    powerpc64,                 ## 64 bit PowerPC
    sparc,                     ## Sparc based processor
    ia64,                      ## Intel Itanium
    amd64,                     ## x86_64 (AMD64); 64 bit x86 compatible CPU
    mips,                      ## Mips based processor
    arm,                       ## ARM based processor
    vm,                        ## Some Virtual machine: Nim's VM or JavaScript
    avr                        ## AVR based processor

  OsPlatform* {.pure.} = enum ## the OS this program will run on.
    none, dos, windows, os2, linux, morphos, skyos, solaris,
    irix, netbsd, freebsd, openbsd, aix, palmos, qnx, amiga,
    atari, netware, macos, macosx, haiku, js, nimVM, standalone

const
  targetOS* = when defined(windows): OsPlatform.windows
              elif defined(dos): OsPlatform.dos
              elif defined(os2): OsPlatform.os2
              elif defined(linux): OsPlatform.linux
              elif defined(morphos): OsPlatform.morphos
              elif defined(skyos): OsPlatform.skyos
              elif defined(solaris): OsPlatform.solaris
              elif defined(irix): OsPlatform.irix
              elif defined(netbsd): OsPlatform.netbsd
              elif defined(freebsd): OsPlatform.freebsd
              elif defined(openbsd): OsPlatform.openbsd
              elif defined(aix): OsPlatform.aix
              elif defined(palmos): OsPlatform.palmos
              elif defined(qnx): OsPlatform.qnx
              elif defined(amiga): OsPlatform.amiga
              elif defined(atari): OsPlatform.atari
              elif defined(netware): OsPlatform.netware
              elif defined(macosx): OsPlatform.macosx
              elif defined(macos): OsPlatform.macos
              elif defined(haiku): OsPlatform.haiku
              elif defined(js): OsPlatform.js
              elif defined(nimrodVM): OsPlatform.nimVM
              elif defined(standalone): OsPlatform.standalone
              else: OsPlatform.none
    ## the OS this program will run on.

  targetCPU* = when defined(i386): CpuPlatform.i386
               elif defined(m68k): CpuPlatform.m68k
               elif defined(alpha): CpuPlatform.alpha
               elif defined(powerpc): CpuPlatform.powerpc
               elif defined(powerpc64): CpuPlatform.powerpc64
               elif defined(sparc): CpuPlatform.sparc
               elif defined(ia64): CpuPlatform.ia64
               elif defined(amd64): CpuPlatform.amd64
               elif defined(mips): CpuPlatform.mips
               elif defined(arm): CpuPlatform.arm
               elif defined(vm): CpuPlatform.vm
               elif defined(avr): CpuPlatform.avr
               else: CpuPlatform.none
    ## the CPU this program will run on.
