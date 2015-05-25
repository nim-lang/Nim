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
  LibHandle = pointer       # private type
  ProcAddr = pointer        # library loading and loading of procs:
{.deprecated: [TLibHandle: LibHandle, TProcAddr: ProcAddr].}

proc nimLoadLibrary(path: string): LibHandle {.compilerproc.}
proc nimUnloadLibrary(lib: LibHandle) {.compilerproc.}
proc nimGetProcAddr(lib: LibHandle, name: cstring): ProcAddr {.compilerproc.}

proc nimLoadLibraryError(path: string) {.compilerproc, noinline.}

proc setStackBottom(theStackBottom: pointer) {.compilerRtl, noinline, benign.}

