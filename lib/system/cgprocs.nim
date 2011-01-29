#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Headers for procs that the code generator depends on ("compilerprocs")

proc addChar(s: NimString, c: char): NimString {.compilerProc.}

type
  TLibHandle = pointer       # private type
  TProcAddr = pointer        # libary loading and loading of procs:

proc nimLoadLibrary(path: string): TLibHandle {.compilerproc.}
proc nimUnloadLibrary(lib: TLibHandle) {.compilerproc.}
proc nimGetProcAddr(lib: TLibHandle, name: cstring): TProcAddr {.compilerproc.}

proc nimLoadLibraryError(path: string) {.compilerproc, noinline.}

proc setStackBottom(theStackBottom: pointer) {.compilerRtl, noinline.}


# Support for thread local storage:
when false:
  when defined(windows):
    proc TlsAlloc(): int32 {.importc: "TlsAlloc", stdcall, dynlib: "kernel32".}
    proc TlsSetValue(dwTlsIndex: int32, lpTlsValue: pointer) {.
      importc: "TlsSetValue", stdcall, dynlib: "kernel32".}
    proc TlsGetValue(dwTlsIndex: int32): pointer {.
      importc: "TlsGetValue", stdcall, dynlib: "kernel32".}
    
  else:
    type
      Tpthread_key {.importc: "pthread_key_t", header: "<sys/types.h>".} = int

    proc pthread_getspecific(a1: Tpthread_key): pointer {.
      importc: "pthread_getspecific", header: "<pthread.h>".}
    proc pthread_key_create(a1: ptr Tpthread_key, 
                            a2: proc (x: pointer) {.noconv.}): int32 {.
      importc: "pthread_key_create", header: "<pthread.h>".}
    proc pthread_key_delete(a1: Tpthread_key): int32 {.
      importc: "pthread_key_delete", header: "<pthread.h>".}

    proc pthread_setspecific(a1: Tpthread_key, a2: pointer): int32 {.
      importc: "pthread_setspecific", header: "<pthread.h>".}

