#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Headers for procs that the code generator depends on ("compilerprocs")

proc addChar(s: NimString, c: char): NimString {.compilerProc, benign.}

type
  TLibHandle = pointer       # private type
  TProcAddr = pointer        # library loading and loading of procs:

proc nimLoadLibrary(path: string): TLibHandle {.compilerproc.}
proc nimUnloadLibrary(lib: TLibHandle) {.compilerproc.}
proc nimGetProcAddr(lib: TLibHandle, name: cstring): TProcAddr {.compilerproc.}

proc nimLoadLibraryError(path: string) {.compilerproc, noinline.}

proc setStackBottom(theStackBottom: pointer) {.compilerRtl, noinline, benign.}

