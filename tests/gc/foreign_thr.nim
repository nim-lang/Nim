discard """
  output: '''
Hello from foreign thread
Hello from foreign thread
'''
  cmd: "nim $target --hints:on --threads:on --tlsEmulation:off $options $file"
"""
# Copied from stdlib
const
  StackGuardSize = 4096
  ThreadStackMask = 1024*256*sizeof(int)-1
  ThreadStackSize = ThreadStackMask+1 - StackGuardSize

when defined(linux):
  import posix

  proc runInForeignThread(f: proc() {.thread.}) =
    proc wrapper(p: pointer): pointer {.noconv.} =
      let thr = cast[proc() {.thread.}](p)
      setupForeignThreadGc()
      thr()
      tearDownForeignThreadGc()
      setupForeignThreadGc()
      thr()
      tearDownForeignThreadGc()
      result = nil

    var attrs {.noinit.}: PthreadAttr
    doAssert pthread_attr_init(addr attrs) == 0
    doAssert pthread_attr_setstacksize(addr attrs, ThreadStackSize) == 0
    var tid: Pthread
    doAssert pthread_create(addr tid, addr attrs, wrapper, f) == 0
    doAssert pthread_join(tid, nil) == 0

else:
  import winlean
  type
    WinThreadProc = proc (x: pointer): int32 {.stdcall.}

  proc createThread(lpThreadAttributes: pointer, dwStackSize: DWORD,
                     lpStartAddress: WinThreadProc,
                     lpParameter: pointer,
                     dwCreationFlags: DWORD,
                     lpThreadId: var DWORD): Handle {.
    stdcall, dynlib: "kernel32", importc: "CreateThread".}

  proc wrapper(p: pointer): int32 {.stdcall.} =
    let thr = cast[proc() {.thread.}](p)
    setupForeignThreadGc()
    thr()
    tearDownForeignThreadGc()
    setupForeignThreadGc()
    thr()
    tearDownForeignThreadGc()
    result = 0'i32

  proc runInForeignThread(f: proc() {.thread.}) =
    var dummyThreadId: DWORD
    var h = createThread(nil, ThreadStackSize.int32, wrapper.WinThreadProc, cast[pointer](f), 0, dummyThreadId)
    doAssert h != 0.Handle
    doAssert waitForSingleObject(h, -1'i32) == 0.DWORD

proc f {.thread.} =
  var msg = "Hello " & "from foreign thread"
  echo msg

runInForeignThread(f)
