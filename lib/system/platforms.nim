#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Platform detection for NimScript. This module is included by the system module!
## Do not import it directly!

type
  CpuPlatform* {.pure.} = enum ## the CPU this program will run on.
    none,                      ## unknown CPU
    i386,                      ## 32 bit x86 compatible CPU
    m68k,                      ## M68k based processor
    alpha,                     ## Alpha processor
    powerpc,                   ## 32 bit PowerPC
    powerpc64,                 ## 64 bit PowerPC
    powerpc64el,               ## Little Endian 64 bit PowerPC
    sparc,                     ## Sparc based processor
    sparc64,                   ## 64-bit Sparc based processor
    hppa,                      ## HP PA-RISC
    ia64,                      ## Intel Itanium
    amd64,                     ## x86_64 (AMD64); 64 bit x86 compatible CPU
    mips,                      ## Mips based processor
    mipsel,                    ## Little Endian Mips based processor
    mips64,                    ## 64-bit MIPS processor
    mips64el,                  ## Little Endian 64-bit MIPS processor
    arm,                       ## ARM based processor
    arm64,                     ## ARM64 based processor
    vm,                        ## Some Virtual machine: Nim's VM or JavaScript
    avr,                       ## AVR based processor
    msp430,                    ## TI MSP430 microcontroller
    riscv32,                   ## RISC-V 32-bit processor
    riscv64,                   ## RISC-V 64-bit processor
    wasm32                     ## WASM, 32-bit

  OsPlatform* {.pure.} = enum ## the OS this program will run on.
    none, dos, windows, os2, linux, morphos, skyos, solaris,
    irix, netbsd, freebsd, openbsd, aix, palmos, qnx, amiga,
    atari, netware, macos, macosx, haiku, android, js, standalone, nintendoswitch

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
              elif defined(android): OsPlatform.android
              elif defined(js): OsPlatform.js
              elif defined(standalone): OsPlatform.standalone
              elif defined(nintendoswitch): OsPlatform.nintendoswitch
              else: OsPlatform.none
    ## the OS this program will run on.

  targetCPU* = when defined(i386): CpuPlatform.i386
               elif defined(m68k): CpuPlatform.m68k
               elif defined(alpha): CpuPlatform.alpha
               elif defined(powerpc): CpuPlatform.powerpc
               elif defined(powerpc64): CpuPlatform.powerpc64
               elif defined(powerpc64el): CpuPlatform.powerpc64el
               elif defined(sparc): CpuPlatform.sparc
               elif defined(sparc64): CpuPlatform.sparc64
               elif defined(hppa): CpuPlatform.hppa
               elif defined(ia64): CpuPlatform.ia64
               elif defined(amd64): CpuPlatform.amd64
               elif defined(mips): CpuPlatform.mips
               elif defined(mipsel): CpuPlatform.mipsel
               elif defined(mips64): CpuPlatform.mips64
               elif defined(mips64el): CpuPlatform.mips64el
               elif defined(arm): CpuPlatform.arm
               elif defined(arm64): CpuPlatform.arm64
               elif defined(vm): CpuPlatform.vm
               elif defined(avr): CpuPlatform.avr
               elif defined(msp430): CpuPlatform.msp430
               elif defined(riscv32): CpuPlatform.riscv32
               elif defined(riscv64): CpuPlatform.riscv64
               elif defined(wasm32): CpuPlatform.wasm32
               else: CpuPlatform.none
    ## the CPU this program will run on.
