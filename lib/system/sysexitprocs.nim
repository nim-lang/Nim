include syslocks

const MaxSysExitProcs = 256

var
  closureCallsAdded = false
  gSysFunsLock: SysLock
  gSysFuns: array[MaxSysExitProcs, proc () {.noconv.}]
  gSysFunCount = 0

initSysLock(gSysFunsLock)

proc addAtExit(quitProc: proc() {.noconv.}) {.
  importc: "atexit", header: "<stdlib.h>".}

template closures() =
  acquireSys(gSysFunsLock)
  for i in countdown(gSysFunCount - 1, 0):
    gSysFuns[i]()
  releaseSys(gSysFunsLock)

proc callSysClosures() {.noconv.} =
  closures()
  deinitSys(gSysFunsLock)

proc invokeSysClosures*() =
  closures()
  deinitSys(gSysFunsLock)

template sysFun() =
  if not closureCallsAdded:
    addAtExit(callSysClosures)
    closureCallsAdded = true

proc addSysExitProc*(cl: proc () {.noconv.}) =
  doAssert gSysFunCount < MaxSysExitProcs, "exceeded MaxSysExitProcs"

  acquireSys(gSysFunsLock)
  gSysFuns[gSysFunCount] = cl
  sysFun()
  inc(gSysFunCount)
  releaseSys(gSysFunsLock)