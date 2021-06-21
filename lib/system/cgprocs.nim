#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Headers for procs that the code generator depends on ("compilerprocs")

type
  LibHandle = pointer       # private type
  ProcAddr = pointer        # library loading and loading of procs:

proc nimLoadLibrary(path: string): LibHandle {.compilerproc, hcrInline, nonReloadable.}
proc nimUnloadLibrary(lib: LibHandle) {.compilerproc, hcrInline, nonReloadable.}
proc nimGetProcAddr(lib: LibHandle, name: cstring): ProcAddr {.compilerproc, hcrInline, nonReloadable.}

proc nimLoadLibraryError(path: string) {.compilerproc, hcrInline, nonReloadable.}
