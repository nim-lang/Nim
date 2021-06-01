#
#
#            Nim's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This module contains headers of Ansi C procs
# and definitions of Ansi C types in Nim syntax
# All symbols are prefixed with 'c_' to avoid ambiguities

{.push hints:off, stack_trace: off, profiler: off.}

proc c_memchr*(s: pointer, c: cint, n: csize_t): pointer {.
  importc: "memchr", header: "<string.h>".}
proc c_memcmp*(a, b: pointer, size: csize_t): cint {.
  importc: "memcmp", header: "<string.h>", noSideEffect.}
proc c_memcpy*(a, b: pointer, size: csize_t): pointer {.
  importc: "memcpy", header: "<string.h>", discardable.}
proc c_memmove*(a, b: pointer, size: csize_t): pointer {.
  importc: "memmove", header: "<string.h>",discardable.}
proc c_memset*(p: pointer, value: cint, size: csize_t): pointer {.
  importc: "memset", header: "<string.h>", discardable.}
proc c_strcmp*(a, b: cstring): cint {.
  importc: "strcmp", header: "<string.h>", noSideEffect.}
proc c_strlen*(a: cstring): csize_t {.
  importc: "strlen", header: "<string.h>", noSideEffect.}
proc c_abort*() {.
  importc: "abort", header: "<stdlib.h>", noSideEffect, noreturn.}


when defined(linux) and defined(amd64):
  type
    C_JmpBuf* {.importc: "jmp_buf", header: "<setjmp.h>", bycopy.} = object
        abi: array[200 div sizeof(clong), clong]
else:
  type
    C_JmpBuf* {.importc: "jmp_buf", header: "<setjmp.h>".} = object


type CSighandlerT = proc (a: cint) {.noconv.}
when defined(windows):
  const
    SIGABRT* = cint(22)
    SIGFPE* = cint(8)
    SIGILL* = cint(4)
    SIGINT* = cint(2)
    SIGSEGV* = cint(11)
    SIGTERM = cint(15)
    SIG_DFL* = cast[CSighandlerT](0)
elif defined(macosx) or defined(linux) or defined(freebsd) or
     defined(openbsd) or defined(netbsd) or defined(solaris) or
     defined(dragonfly) or defined(nintendoswitch) or defined(genode) or
     defined(aix) or hostOS == "standalone":
  const
    SIGABRT* = cint(6)
    SIGFPE* = cint(8)
    SIGILL* = cint(4)
    SIGINT* = cint(2)
    SIGSEGV* = cint(11)
    SIGTERM* = cint(15)
    SIGPIPE* = cint(13)
    SIG_DFL* = cast[CSighandlerT](0)
elif defined(haiku):
  const
    SIGABRT* = cint(6)
    SIGFPE* = cint(8)
    SIGILL* = cint(4)
    SIGINT* = cint(2)
    SIGSEGV* = cint(11)
    SIGTERM* = cint(15)
    SIGPIPE* = cint(7)
    SIG_DFL* = cast[CSighandlerT](0)
else:
  when defined(nimscript):
    {.error: "SIGABRT not ported to your platform".}
  else:
    var
      SIGINT* {.importc: "SIGINT", nodecl.}: cint
      SIGSEGV* {.importc: "SIGSEGV", nodecl.}: cint
      SIGABRT* {.importc: "SIGABRT", nodecl.}: cint
      SIGFPE* {.importc: "SIGFPE", nodecl.}: cint
      SIGILL* {.importc: "SIGILL", nodecl.}: cint
      SIG_DFL* {.importc: "SIG_DFL", nodecl.}: CSighandlerT
    when defined(macosx) or defined(linux):
      var SIGPIPE* {.importc: "SIGPIPE", nodecl.}: cint

when defined(macosx):
  const SIGBUS* = cint(10)
elif defined(haiku):
  const SIGBUS* = cint(30)

when defined(nimSigSetjmp) and not defined(nimStdSetjmp):
  proc c_longjmp*(jmpb: C_JmpBuf, retval: cint) {.
    header: "<setjmp.h>", importc: "siglongjmp".}
  template c_setjmp*(jmpb: C_JmpBuf): cint =
    proc c_sigsetjmp(jmpb: C_JmpBuf, savemask: cint): cint {.
      header: "<setjmp.h>", importc: "sigsetjmp".}
    c_sigsetjmp(jmpb, 0)
elif defined(nimRawSetjmp) and not defined(nimStdSetjmp):
  proc c_longjmp*(jmpb: C_JmpBuf, retval: cint) {.
    header: "<setjmp.h>", importc: "_longjmp".}
  proc c_setjmp*(jmpb: C_JmpBuf): cint {.
    header: "<setjmp.h>", importc: "_setjmp".}
else:
  proc c_longjmp*(jmpb: C_JmpBuf, retval: cint) {.
    header: "<setjmp.h>", importc: "longjmp".}
  proc c_setjmp*(jmpb: C_JmpBuf): cint {.
    header: "<setjmp.h>", importc: "setjmp".}

proc c_signal*(sign: cint, handler: CSighandlerT): CSighandlerT {.
  importc: "signal", header: "<signal.h>", discardable.}
proc c_raise*(sign: cint): cint {.importc: "raise", header: "<signal.h>".}

type
  CFile {.importc: "FILE", header: "<stdio.h>",
          incompleteStruct.} = object
  CFilePtr* = ptr CFile ## The type representing a file handle.

# duplicated between io and ansi_c
const stdioUsesMacros = (defined(osx) or defined(freebsd) or defined(dragonfly)) and not defined(emscripten)
const stderrName = when stdioUsesMacros: "__stderrp" else: "stderr"
const stdoutName = when stdioUsesMacros: "__stdoutp" else: "stdout"
const stdinName = when stdioUsesMacros: "__stdinp" else: "stdin"

var
  cstderr* {.importc: stderrName, header: "<stdio.h>".}: CFilePtr
  cstdout* {.importc: stdoutName, header: "<stdio.h>".}: CFilePtr
  cstdin* {.importc: stdinName, header: "<stdio.h>".}: CFilePtr

proc c_fprintf*(f: CFilePtr, frmt: cstring): cint {.
  importc: "fprintf", header: "<stdio.h>", varargs, discardable.}
proc c_printf*(frmt: cstring): cint {.
  importc: "printf", header: "<stdio.h>", varargs, discardable.}

proc c_fputs*(c: cstring, f: CFilePtr): cint {.
  importc: "fputs", header: "<stdio.h>", discardable.}

proc c_sprintf*(buf, frmt: cstring): cint {.
  importc: "sprintf", header: "<stdio.h>", varargs, noSideEffect.}
  # we use it only in a way that cannot lead to security issues

proc c_malloc*(size: csize_t): pointer {.
  importc: "malloc", header: "<stdlib.h>".}
proc c_calloc*(nmemb, size: csize_t): pointer {.
  importc: "calloc", header: "<stdlib.h>".}
proc c_free*(p: pointer) {.
  importc: "free", header: "<stdlib.h>".}
proc c_realloc*(p: pointer, newsize: csize_t): pointer {.
  importc: "realloc", header: "<stdlib.h>".}

proc c_fwrite*(buf: pointer, size, n: csize_t, f: CFilePtr): cint {.
  importc: "fwrite", header: "<stdio.h>".}

proc c_fflush(f: CFilePtr): cint {.
  importc: "fflush", header: "<stdio.h>".}

proc rawWriteString*(f: CFilePtr, s: cstring, length: int) {.compilerproc, nonReloadable, inline.} =
  # we cannot throw an exception here!
  discard c_fwrite(s, 1, cast[csize_t](length), f)
  discard c_fflush(f)

proc rawWrite*(f: CFilePtr, s: cstring) {.compilerproc, nonReloadable, inline.} =
  # we cannot throw an exception here!
  discard c_fwrite(s, 1, cast[csize_t](s.len), f)
  discard c_fflush(f)

{.pop.}
