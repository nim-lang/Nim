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

when false:
  # Support for thread local storage:
  when defined(windows):
    type
      TThreadVarSlot {.compilerproc.} = distinct int32

    proc TlsAlloc(): TThreadVarSlot {.
      importc: "TlsAlloc", stdcall, dynlib: "kernel32".}
    proc TlsSetValue(dwTlsIndex: TThreadVarSlot, lpTlsValue: pointer) {.
      importc: "TlsSetValue", stdcall, dynlib: "kernel32".}
    proc TlsGetValue(dwTlsIndex: TThreadVarSlot): pointer {.
      importc: "TlsGetValue", stdcall, dynlib: "kernel32".}
    
    proc ThreadVarAlloc(): TThreadVarSlot {.compilerproc, inline.} =
      result = TlsAlloc()
    proc ThreadVarSetValue(s: TThreadVarSlot, value: pointer) {.
                           compilerproc, inline.} =
      TlsSetValue(s, value)
    proc ThreadVarGetValue(s: TThreadVarSlot): pointer {.
                           compilerproc, inline.} =
      result = TlsGetValue(s)
    
  else:
    type
      Tpthread_key {.importc: "pthread_key_t", 
                     header: "<sys/types.h>".} = distinct int
      TThreadVarSlot {.compilerproc.} = Tpthread_key

    proc pthread_getspecific(a1: Tpthread_key): pointer {.
      importc: "pthread_getspecific", header: "<pthread.h>".}
    proc pthread_key_create(a1: ptr Tpthread_key, 
                            destruct: proc (x: pointer) {.noconv.}): int32 {.
      importc: "pthread_key_create", header: "<pthread.h>".}
    proc pthread_key_delete(a1: Tpthread_key): int32 {.
      importc: "pthread_key_delete", header: "<pthread.h>".}

    proc pthread_setspecific(a1: Tpthread_key, a2: pointer): int32 {.
      importc: "pthread_setspecific", header: "<pthread.h>".}
    
    proc ThreadVarAlloc(): TThreadVarSlot {.compilerproc, inline.} =
      discard pthread_key_create(addr(result), nil)
    proc ThreadVarSetValue(s: TThreadVarSlot, value: pointer) {.
                           compilerproc, inline.} =
      discard pthread_setspecific(s, value)
    proc ThreadVarGetValue(s: TThreadVarSlot): pointer {.compilerproc, inline.} =
      result = pthread_getspecific(s)

