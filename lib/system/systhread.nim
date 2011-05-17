#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

const
  maxThreads = 256
  SystemInclude = defined(hasThreadSupport)

when not SystemInclude:
  # ugly hack: this file is then included from core/threads, so we have
  # thread support:
  const hasThreadSupport = true

when (defined(gcc) or defined(llvm_gcc)) and hasThreadSupport:
  proc sync_add_and_fetch(p: var int, val: int): int {.
    importc: "__sync_add_and_fetch", nodecl.}
  proc sync_sub_and_fetch(p: var int, val: int): int {.
    importc: "__sync_sub_and_fetch", nodecl.}
elif defined(vcc) and hasThreadSupport:
  proc sync_add_and_fetch(p: var int, val: int): int {.
    importc: "NimXadd", nodecl.}
else:
  proc sync_add_and_fetch(p: var int, val: int): int {.inline.} =
    inc(p, val)
    result = p

proc atomicInc(memLoc: var int, x: int): int =
  when hasThreadSupport:
    result = sync_add_and_fetch(memLoc, x)
  else:
    inc(memLoc, x)
    result = memLoc
  
proc atomicDec(memLoc: var int, x: int): int =
  when hasThreadSupport:
    when defined(sync_sub_and_fetch):
      result = sync_sub_and_fetch(memLoc, x)
    else:
      result = sync_add_and_fetch(memLoc, -x)
  else:
    dec(memLoc, x)
    result = memLoc  

when defined(Windows):
  type
    TSysLock {.final, pure.} = object # CRITICAL_SECTION in WinApi
      DebugInfo: pointer
      LockCount: int32
      RecursionCount: int32
      OwningThread: int
      LockSemaphore: int
      Reserved: int32
          
  proc InitSysLock(L: var TSysLock) {.stdcall,
    dynlib: "kernel32", importc: "InitializeCriticalSection".}
    ## Initializes the lock `L`.

  proc TryAquireSysAux(L: var TSysLock): int32 {.stdcall,
    dynlib: "kernel32", importc: "TryEnterCriticalSection".}
    ## Tries to aquire the lock `L`.
    
  proc TryAquireSys(L: var TSysLock): bool {.inline.} = 
    result = TryAquireSysAux(L) != 0'i32

  proc AquireSys(L: var TSysLock) {.stdcall,
    dynlib: "kernel32", importc: "EnterCriticalSection".}
    ## Aquires the lock `L`.
    
  proc ReleaseSys(L: var TSysLock) {.stdcall,
    dynlib: "kernel32", importc: "LeaveCriticalSection".}
    ## Releases the lock `L`.

else:
  type
    TSysLock {.importc: "pthread_mutex_t", pure, final,
               header: "<sys/types.h>".} = object

  proc InitSysLock(L: var TSysLock, attr: pointer = nil) {.
    importc: "pthread_mutex_init", header: "<pthread.h>".}

  proc AquireSys(L: var TSysLock) {.
    importc: "pthread_mutex_lock", header: "<pthread.h>".}
  proc TryAquireSysAux(L: var TSysLock): cint {.
    importc: "pthread_mutex_trylock", header: "<pthread.h>".}

  proc TryAquireSys(L: var TSysLock): bool {.inline.} = 
    result = TryAquireSysAux(L) == 0'i32

  proc ReleaseSys(L: var TSysLock) {.
    importc: "pthread_mutex_unlock", header: "<pthread.h>".}

when SystemInclude:
  var heapLock: TSysLock
  InitSysLock(HeapLock)

