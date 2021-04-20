
when defined(windows):
  type
    SysThread* = Handle
    WinThreadProc = proc (x: pointer): int32 {.stdcall.}

  proc createThread(lpThreadAttributes: pointer, dwStackSize: int32,
                     lpStartAddress: WinThreadProc,
                     lpParameter: pointer,
                     dwCreationFlags: int32,
                     lpThreadId: var int32): SysThread {.
    stdcall, dynlib: "kernel32", importc: "CreateThread".}

  proc winSuspendThread(hThread: SysThread): int32 {.
    stdcall, dynlib: "kernel32", importc: "SuspendThread".}

  proc winResumeThread(hThread: SysThread): int32 {.
    stdcall, dynlib: "kernel32", importc: "ResumeThread".}

  proc waitForSingleObject(hHandle: SysThread, dwMilliseconds: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "WaitForSingleObject".}

  proc waitForMultipleObjects(nCount: int32,
                              lpHandles: ptr SysThread,
                              bWaitAll: int32,
                              dwMilliseconds: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "WaitForMultipleObjects".}

  proc terminateThread(hThread: SysThread, dwExitCode: int32): int32 {.
    stdcall, dynlib: "kernel32", importc: "TerminateThread".}

  proc getCurrentThreadId(): int32 {.
    stdcall, dynlib: "kernel32", importc: "GetCurrentThreadId".}

  type
    ThreadVarSlot = distinct int32

  when true:
    proc threadVarAlloc(): ThreadVarSlot {.
      importc: "TlsAlloc", stdcall, header: "<windows.h>".}
    proc threadVarSetValue(dwTlsIndex: ThreadVarSlot, lpTlsValue: pointer) {.
      importc: "TlsSetValue", stdcall, header: "<windows.h>".}
    proc tlsGetValue(dwTlsIndex: ThreadVarSlot): pointer {.
      importc: "TlsGetValue", stdcall, header: "<windows.h>".}

    proc getLastError(): uint32 {.
      importc: "GetLastError", stdcall, header: "<windows.h>".}
    proc setLastError(x: uint32) {.
      importc: "SetLastError", stdcall, header: "<windows.h>".}

    proc threadVarGetValue(dwTlsIndex: ThreadVarSlot): pointer =
      let realLastError = getLastError()
      result = tlsGetValue(dwTlsIndex)
      setLastError(realLastError)
  else:
    proc threadVarAlloc(): ThreadVarSlot {.
      importc: "TlsAlloc", stdcall, dynlib: "kernel32".}
    proc threadVarSetValue(dwTlsIndex: ThreadVarSlot, lpTlsValue: pointer) {.
      importc: "TlsSetValue", stdcall, dynlib: "kernel32".}
    proc threadVarGetValue(dwTlsIndex: ThreadVarSlot): pointer {.
      importc: "TlsGetValue", stdcall, dynlib: "kernel32".}

  proc setThreadAffinityMask(hThread: SysThread, dwThreadAffinityMask: uint) {.
    importc: "SetThreadAffinityMask", stdcall, header: "<windows.h>".}

elif defined(genode):
  import genode/env
  const
    GenodeHeader = "genode_cpp/threads.h"
  type
    SysThread* {.importcpp: "Nim::SysThread",
                 header: GenodeHeader, final, pure.} = object
    GenodeThreadProc = proc (x: pointer) {.noconv.}
    ThreadVarSlot = int

  proc initThread(s: var SysThread,
                  env: GenodeEnv,
                  stackSize: culonglong,
                  entry: GenodeThreadProc,
                  arg: pointer,
                  affinity: cuint) {.
    importcpp: "#.initThread(@)".}

  proc threadVarAlloc(): ThreadVarSlot = 0

  proc offMainThread(): bool {.
    importcpp: "Nim::SysThread::offMainThread",
    header: GenodeHeader.}

  proc threadVarSetValue(value: pointer) {.
    importcpp: "Nim::SysThread::threadVarSetValue(@)",
    header: GenodeHeader.}

  proc threadVarGetValue(): pointer {.
    importcpp: "Nim::SysThread::threadVarGetValue()",
    header: GenodeHeader.}

  var mainTls: pointer

  proc threadVarSetValue(s: ThreadVarSlot, value: pointer) {.inline.} =
    if offMainThread():
      threadVarSetValue(value);
    else:
      mainTls = value

  proc threadVarGetValue(s: ThreadVarSlot): pointer {.inline.} =
    if offMainThread():
      threadVarGetValue();
    else:
      mainTls

else:
  when not (defined(macosx) or defined(haiku)):
    {.passl: "-pthread".}

  when not defined(haiku):
    {.passc: "-pthread".}

  const
    schedh = "#define _GNU_SOURCE\n#include <sched.h>"
    pthreadh = "#define _GNU_SOURCE\n#include <pthread.h>"

  when not declared(Time):
    when defined(linux):
      type Time = clong
    else:
      type Time = int

  when (defined(linux) or defined(nintendoswitch)) and defined(amd64):
    type
      SysThread* {.importc: "pthread_t",
                  header: "<sys/types.h>" .} = distinct culong
      Pthread_attr {.importc: "pthread_attr_t",
                    header: "<sys/types.h>".} = object
        abi: array[56 div sizeof(clong), clong]
      ThreadVarSlot {.importc: "pthread_key_t",
                    header: "<sys/types.h>".} = distinct cuint
  elif defined(openbsd) and defined(amd64):
    type
      SysThread* {.importc: "pthread_t", header: "<pthread.h>".} = object
      Pthread_attr {.importc: "pthread_attr_t",
                       header: "<pthread.h>".} = object
      ThreadVarSlot {.importc: "pthread_key_t",
                     header: "<pthread.h>".} = cint
  else:
    type
      SysThread* {.importc: "pthread_t", header: "<sys/types.h>".} = object
      Pthread_attr {.importc: "pthread_attr_t",
                       header: "<sys/types.h>".} = object
      ThreadVarSlot {.importc: "pthread_key_t",
                     header: "<sys/types.h>".} = object
  type
    Timespec {.importc: "struct timespec", header: "<time.h>".} = object
      tv_sec: Time
      tv_nsec: clong

  proc pthread_attr_init(a1: var Pthread_attr): cint {.
    importc, header: pthreadh.}
  proc pthread_attr_setstacksize(a1: var Pthread_attr, a2: int): cint {.
    importc, header: pthreadh.}
  proc pthread_attr_destroy(a1: var Pthread_attr): cint {.
    importc, header: pthreadh.}

  proc pthread_create(a1: var SysThread, a2: var Pthread_attr,
            a3: proc (x: pointer): pointer {.noconv.},
            a4: pointer): cint {.importc: "pthread_create",
            header: pthreadh.}
  proc pthread_join(a1: SysThread, a2: ptr pointer): cint {.
    importc, header: pthreadh.}

  proc pthread_cancel(a1: SysThread): cint {.
    importc: "pthread_cancel", header: pthreadh.}

  proc pthread_getspecific(a1: ThreadVarSlot): pointer {.
    importc: "pthread_getspecific", header: pthreadh.}
  proc pthread_key_create(a1: ptr ThreadVarSlot,
                          destruct: proc (x: pointer) {.noconv.}): int32 {.
    importc: "pthread_key_create", header: pthreadh.}
  proc pthread_key_delete(a1: ThreadVarSlot): int32 {.
    importc: "pthread_key_delete", header: pthreadh.}

  proc pthread_setspecific(a1: ThreadVarSlot, a2: pointer): int32 {.
    importc: "pthread_setspecific", header: pthreadh.}

  proc threadVarAlloc(): ThreadVarSlot {.inline.} =
    discard pthread_key_create(addr(result), nil)
  proc threadVarSetValue(s: ThreadVarSlot, value: pointer) {.inline.} =
    discard pthread_setspecific(s, value)
  proc threadVarGetValue(s: ThreadVarSlot): pointer {.inline.} =
    result = pthread_getspecific(s)

  type CpuSet {.importc: "cpu_set_t", header: schedh.} = object
     when defined(linux) and defined(amd64):
       abi: array[1024 div (8 * sizeof(culong)), culong]

  proc cpusetZero(s: var CpuSet) {.importc: "CPU_ZERO", header: schedh.}
  proc cpusetIncl(cpu: cint; s: var CpuSet) {.
    importc: "CPU_SET", header: schedh.}

  when defined(android):
    # libc of android doesn't implement pthread_setaffinity_np,
    # it exposes pthread_gettid_np though, so we can use that in combination
    # with sched_setaffinity to set the thread affinity.
    type Pid {.importc: "pid_t", header: "<sys/types.h>".} = int32 # From posix_other.nim

    proc setAffinityTID(tid: Pid; setsize: csize_t; s: var CpuSet) {.
      importc: "sched_setaffinity", header: schedh.}

    proc pthread_gettid_np(thread: SysThread): Pid {.
      importc: "pthread_gettid_np", header: pthreadh.}

    proc setAffinity(thread: SysThread; setsize: csize_t; s: var CpuSet) =
      setAffinityTID(pthread_gettid_np(thread), setsize, s)
  else:
    proc setAffinity(thread: SysThread; setsize: csize_t; s: var CpuSet) {.
      importc: "pthread_setaffinity_np", header: pthreadh.}


const
  emulatedThreadVars = compileOption("tlsEmulation")

when emulatedThreadVars:
  # the compiler generates this proc for us, so that we can get the size of
  # the thread local var block; we use this only for sanity checking though
  proc nimThreadVarsSize(): int {.noconv, importc: "NimThreadVarsSize".}

# we preallocate a fixed size for thread local storage, so that no heap
# allocations are needed. Currently less than 16K are used on a 64bit machine.
# We use `float` for proper alignment:
const nimTlsSize {.intdefine.} = 16000
type
  ThreadLocalStorage = array[0..(nimTlsSize div sizeof(float)), float]
  PGcThread = ptr GcThread
  GcThread {.pure, inheritable.} = object
    when emulatedThreadVars:
      tls: ThreadLocalStorage
    else:
      nil
    when hasSharedHeap:
      next, prev: PGcThread
      stackBottom, stackTop: pointer
      stackSize: int
    else:
      nil

when emulatedThreadVars:
  var globalsSlot: ThreadVarSlot

  when not defined(useNimRtl):
    var mainThread: GcThread

  proc GetThreadLocalVars(): pointer {.compilerRtl, inl.} =
    result = addr(cast[PGcThread](threadVarGetValue(globalsSlot)).tls)

  proc initThreadVarsEmulation() {.compilerproc, inline.} =
    when not defined(useNimRtl):
      globalsSlot = threadVarAlloc()
      when declared(mainThread):
        threadVarSetValue(globalsSlot, addr(mainThread))

when not defined(useNimRtl):
  when emulatedThreadVars:
    if nimThreadVarsSize() > sizeof(ThreadLocalStorage):
      c_fprintf(cstderr, """too large thread local storage size requested,
use -d:\"nimTlsSize=X\" to setup even more or stop using unittest.nim""")
      quit 1
