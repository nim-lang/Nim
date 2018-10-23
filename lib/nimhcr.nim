#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This is the Nim hot code reloading run-time for the native targets.
##
## This minimal dynamic library is the only component that is not subject
## to reloading when the `hotCodeReloading` build mode is enabled.
## It's responsible for providing a permanent memory location for all
## globals and procs within a program. For globals, this is easily achieved
## by storing them on the heap. For procs, we produce on the fly simple
## trampolines that can be dynamically overwritten to jump to a different
## target. In the host program, all globals and procs are first registered
## here with ``registerGlobal`` and ``registerProc`` and then the returned
## permanent locations are used in every reference to these symbols onwards.

const
  nimhcrExports = "nimhcr_$1"

when isMainModule:
  when system.appType != "lib":
    {.error: "This file has to be compiled as a library!".}

  import tables, os, strutils, reservedmem

  {.pragma: nimhcr, exportc: nimhcrExports, dynlib.}

  when hostCPU in ["i386", "amd64"]:
    type
      ShortJumpInstruction {.packed.} = object
        opcode: byte
        offset: int32

      LongJumpInstruction {.packed.} = object
        opcode1: byte
        opcode2: byte
        offset: int32
        absoluteAddr: pointer

    proc writeJump(jumpTableEntry: ptr LongJumpInstruction, targetFn: pointer) =
      let
        jumpFrom = jumpTableEntry.shift(sizeof(ShortJumpInstruction))
        jumpDistance = distance(jumpFrom, targetFn)

      if abs(jumpDistance) < 0x7fff0000:
        let shortJump = cast[ptr ShortJumpInstruction](jumpTableEntry)
        shortJump.opcode = 0xE9 # relative jump
        shortJump.offset = int32(jumpDistance)
      else:
        jumpTableEntry.opcode1 = 0xff # indirect absolute jump
        jumpTableEntry.opcode2 = 0x25
        when hostCPU == "i386":
          # on x86 we write the absolute address of the following pointer
          jumpTableEntry.offset = cast[int32](addr jumpTableEntry.absoluteAddr)
        else:
          # on x64, we use a relative address for the same location
          jumpTableEntry.offset = 0
        jumpTableEntry.absoluteAddr = targetFn

  elif hostCPU == "arm":
    const jumpSize = 8
  elif hostCPU == "arm64":
    const jumpSize = 16

  const defaultJumpTableSize = case hostCPU
                               of "i386": 50
                               of "amd64": 500
                               else: 50

  let jumpTableSizeStr = getEnv("HOT_CODE_RELOADING_JUMP_TABLE_SIZE")
  let jumpTableSize = if jumpTableSizeStr.len > 0: parseInt(jumpTableSizeStr)
                      else: defaultJumpTableSize

  var jumpTable = ReservedMemSeq[LongJumpInstruction].init(
    memStart = cast[pointer](0x10000000),
    maxLen = jumpTableSize * 1024 * 1024 div sizeof(LongJumpInstruction),
    accessFlags = memExecReadWrite)

  var registeredProcs = initTable[string, ptr LongJumpInstruction]()

  proc registerProc*(fnName: string, fn: pointer): pointer {.nimhcr.} =
    var jumpTableEntryAddr: ptr LongJumpInstruction

    registeredProcs.withValue(fnName, trampoline):
      jumpTableEntryAddr = trampoline[]
    do:
      let len = jumpTable.len
      jumpTable.setLen(len + 1)
      jumpTableEntryAddr = addr jumpTable[len]
      registeredProcs[fnName] = jumpTableEntryAddr

    writeJump jumpTableEntryAddr, fn
    return jumpTableEntryAddr

  var registeredGlobals = initTable[string, pointer]()

  proc registerGlobal*(varName: string, size: Natural): pointer {.nimhcr.} =
    registeredGlobals.withValue(varName, global):
      return global[]
    do:
      result = alloc0(size)
      registeredGlobals[varName] = result
else:
  const
    nimhcrLibname = when defined(windows): "nimhcr.dll"
                    elif defined(macosx): "libnimhcr.dylib"
                    else: "libnimhcr.so"

  {.pragma: nimhcr, importc: nimhcrExports, dynlib: nimhcrLibname.}

  proc registerProc*(fnName: string, fn: pointer): pointer {.nimhcr.}
  proc registerGlobal*(varName: string, size: Natural): pointer {.nimhcr.}

