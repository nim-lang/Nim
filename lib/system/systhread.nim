#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(gcc) or defined(llvm_gcc):
  proc sync_add_and_fetch(p: var int, val: int): int {.
    importc: "__sync_add_and_fetch", nodecl.}
  proc sync_sub_and_fetch(p: var int, val: int): int {.
    importc: "__sync_sub_and_fetch", nodecl.}
elif defined(vcc):
  proc sync_add_and_fetch(p: var int, val: int): int {.
    importc: "NimXadd", nodecl.}

const
  isMultiThreaded* = true
  maxThreads = 256

proc atomicInc(memLoc: var int, x: int): int =
  when isMultiThreaded:
    result = sync_add_and_fetch(memLoc, x)
  else:
    inc(memLoc, x)
    result = memLoc
  
proc atomicDec(memLoc: var int, x: int): int =
  when isMultiThreaded:
    when defined(sync_sub_and_fetch):
      result = sync_sub_and_fetch(memLoc, x)
    else:
      result = sync_add_and_fetch(memLoc, -x)
  else:
    dec(memLoc, x)
    result = memLoc  
  
type
  TThread* {.final, pure.} = object
    next: ptr TThread
  TThreadFunc* = proc (closure: pointer) {.cdecl.}
  
proc createThread*(t: var TThread, fn: TThreadFunc) = 
  nil
  
proc destroyThread*(t: var TThread) =
  nil




