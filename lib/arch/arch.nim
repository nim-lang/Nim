#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Rokas Kupstys
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(windows):
  const
    ABI* = "ms"
elif defined(unix):
  const
    ABI* = "unix"
else:
  {.error: "Unsupported ABI".}

when defined(amd64):
  when defined(unix):
    # unix (sysv) ABI
    type
      JmpBufReg* {.pure.} = enum
        BX, BP, R12, R13, R14, R15, SP, IP, TOTAL
  elif defined(windows):
    # ms ABI
    type
      JmpBufReg* {.pure.} = enum
        BX, BP, R12, R13, R14, R15, SP, IP, SI, DI, TOTAL
  type
    Reg* {.pure.} = enum
      AX, BX, CX, DX, SI, DI, BP, SP, IP, R8, R9, R10, R11, R12, R13, R14, R15, TOTAL

elif defined(i386):
    # identical fastcall calling convention on all x86 OS
    type
      JmpBufReg* {.pure.} = enum
        BX, SI, DI, BP, SP, IP, TOTAL

      Reg* {.pure.} = enum
        AX, BX, CX, BP, SP, DI, SI, TOTAL

else:
  {.error: "Unsupported architecture".}

{.compile: "./" & ABI & "_" & hostCPU & ".asm"}

type
  JmpBuf* = array[JmpBufReg.TOTAL, pointer]
  Registers* = array[Reg.TOTAL, pointer]


proc getRegisters*(ctx: var Registers) {.importc: "narch_$1", fastcall.}

proc setjmp*(ctx: var JmpBuf): int {.importc: "narch_$1", fastcall.}
proc longjmp*(ctx: JmpBuf, ret=1) {.importc: "narch_$1", fastcall.}

proc coroSwitchStack*(sp: pointer) {.importc: "narch_$1", fastcall.}
proc coroRestoreStack*() {.importc: "narch_$1", fastcall.}
