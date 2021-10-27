when not defined(js):
  import locks

  const MaxSysExitProcs = 256

  var
    initialized = false
    closureCallsAdded = false
    gSysFunsLock: Lock
    gSysFuns: array[MaxSysExitProcs, proc () {.noconv.}]
    gSysFunCount = 0

  template init() =
    initLock(gSysFunsLock)
    initialized = true

  if not initialized:
    init()

  proc addAtExit(quitProc: proc() {.noconv.}) {.
    importc: "atexit", header: "<stdlib.h>".}

  template closures() =
    acquire(gSysFunsLock)
    for i in countdown(gSysFunCount - 1, 0):
      gSysFuns[i]()
    release(gSysFunsLock)

  proc callSysClosures() {.noconv.} =
    closures()
    deinitLock(gSysFunsLock)

  proc invokeSysClosures*() =
    closures()
    deinitLock(gSysFunsLock)

  template sysFun() =
    if not closureCallsAdded:
      addAtExit(callSysClosures)
      closureCallsAdded = true

  proc addSysExitProc*(cl: proc () {.noconv.}) =
    doAssert gSysFunCount < MaxSysExitProcs, "exceeded MaxSysExitProcs"

    if not initialized:
      init()

    acquire(gSysFunsLock)
    gSysFuns[gSysFunCount] = cl
    sysFun()
    inc(gSysFunCount)
    release(gSysFunsLock)
else:
  proc invokeSysClosures*() =
    discard