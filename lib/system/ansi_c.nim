#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include file contains headers of Ansi C procs
# and definitions of Ansi C types in Nimrod syntax
# All symbols are prefixed with 'c_' to avoid ambiguities

{.push hints:off}

proc c_strcmp(a, b: CString): cint {.header: "<string.h>", 
  noSideEffect, importc: "strcmp".}
proc c_memcmp(a, b: CString, size: int): cint {.header: "<string.h>", 
  noSideEffect, importc: "memcmp".}
proc c_memcpy(a, b: CString, size: int) {.header: "<string.h>", importc: "memcpy".}
proc c_strlen(a: CString): int {.header: "<string.h>", 
  noSideEffect, importc: "strlen".}
proc c_memset(p: pointer, value: cint, size: int) {.
  header: "<string.h>", importc: "memset".}

type
  C_TextFile {.importc: "FILE", header: "<stdio.h>", 
               final, incompleteStruct.} = object
  C_BinaryFile {.importc: "FILE", header: "<stdio.h>", 
                 final, incompleteStruct.} = object
  C_TextFileStar = ptr CTextFile
  C_BinaryFileStar = ptr CBinaryFile

  C_JmpBuf {.importc: "jmp_buf", header: "<setjmp.h>".} = object

var
  c_stdin {.importc: "stdin", nodecl.}: C_TextFileStar
  c_stdout {.importc: "stdout", nodecl.}: C_TextFileStar
  c_stderr {.importc: "stderr", nodecl.}: C_TextFileStar

# constants faked as variables:
when not defined(SIGINT):
  var 
    SIGINT {.importc: "SIGINT", nodecl.}: cint
    SIGSEGV {.importc: "SIGSEGV", nodecl.}: cint
    SIGABRT {.importc: "SIGABRT", nodecl.}: cint
    SIGFPE {.importc: "SIGFPE", nodecl.}: cint
    SIGILL {.importc: "SIGILL", nodecl.}: cint

when defined(macosx):
  var
    SIGBUS {.importc: "SIGBUS", nodecl.}: cint
      # hopefully this does not lead to new bugs
else:
  var
    SIGBUS {.importc: "SIGSEGV", nodecl.}: cint
      # only Mac OS X has this shit

proc c_longjmp(jmpb: C_JmpBuf, retval: cint) {.
  header: "<setjmp.h>", importc: "longjmp".}
proc c_setjmp(jmpb: C_JmpBuf): cint {.
  header: "<setjmp.h>", importc: "setjmp".}

proc c_signal(sig: cint, handler: proc (a: cint) {.noconv.}) {.
  importc: "signal", header: "<signal.h>".}
proc c_raise(sig: cint) {.importc: "raise", header: "<signal.h>".}

proc c_fputs(c: cstring, f: C_TextFileStar) {.importc: "fputs", 
  header: "<stdio.h>".}
proc c_fgets(c: cstring, n: int, f: C_TextFileStar): cstring  {.
  importc: "fgets", header: "<stdio.h>".}
proc c_fgetc(stream: C_TextFileStar): int {.importc: "fgetc", 
  header: "<stdio.h>".}
proc c_ungetc(c: int, f: C_TextFileStar) {.importc: "ungetc", 
  header: "<stdio.h>".}
proc c_putc(c: Char, stream: C_TextFileStar) {.importc: "putc", 
  header: "<stdio.h>".}
proc c_fprintf(f: C_TextFileStar, frmt: CString) {.
  importc: "fprintf", header: "<stdio.h>", varargs.}
proc c_printf(frmt: CString) {.
  importc: "printf", header: "<stdio.h>", varargs.}

proc c_fopen(filename, mode: cstring): C_TextFileStar {.
  importc: "fopen", header: "<stdio.h>".}
proc c_fclose(f: C_TextFileStar) {.importc: "fclose", header: "<stdio.h>".}

proc c_sprintf(buf, frmt: CString) {.header: "<stdio.h>", 
  importc: "sprintf", varargs, noSideEffect.}
  # we use it only in a way that cannot lead to security issues

proc c_fread(buf: Pointer, size, n: int, f: C_BinaryFileStar): int {.
  importc: "fread", header: "<stdio.h>".}
proc c_fseek(f: C_BinaryFileStar, offset: clong, whence: int): int {.
  importc: "fseek", header: "<stdio.h>".}

proc c_fwrite(buf: Pointer, size, n: int, f: C_BinaryFileStar): int {.
  importc: "fwrite", header: "<stdio.h>".}

proc c_exit(errorcode: cint) {.importc: "exit", header: "<stdlib.h>".}
proc c_ferror(stream: C_TextFileStar): bool {.
  importc: "ferror", header: "<stdio.h>".}
proc c_fflush(stream: C_TextFileStar) {.importc: "fflush", header: "<stdio.h>".}
proc c_abort() {.importc: "abort", header: "<stdlib.h>".}
proc c_feof(stream: C_TextFileStar): bool {.
  importc: "feof", header: "<stdio.h>".}

proc c_malloc(size: int): pointer {.importc: "malloc", header: "<stdlib.h>".}
proc c_free(p: pointer) {.importc: "free", header: "<stdlib.h>".}
proc c_realloc(p: pointer, newsize: int): pointer {.
  importc: "realloc", header: "<stdlib.h>".}

when hostOS != "standalone":
  when not defined(errno):
    var errno {.importc, header: "<errno.h>".}: cint ## error variable
proc strerror(errnum: cint): cstring {.importc, header: "<string.h>".}

proc c_remove(filename: CString): cint {.
  importc: "remove", header: "<stdio.h>".}
proc c_rename(oldname, newname: CString): cint {.
  importc: "rename", header: "<stdio.h>".}

proc c_system(cmd: CString): cint {.importc: "system", header: "<stdlib.h>".}
proc c_getenv(env: CString): CString {.importc: "getenv", header: "<stdlib.h>".}
proc c_putenv(env: CString): cint {.importc: "putenv", header: "<stdlib.h>".}

{.pop}
