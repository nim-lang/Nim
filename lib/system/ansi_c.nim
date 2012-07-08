#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This include file contains headers of Ansi C procs
# and definitions of Ansi C types in Nimrod syntax
# All symbols are prefixed with 'c_' to avoid ambiguities

{.push hints:off}

proc c_strcmp(a, b: CString): cint {.nodecl, noSideEffect, importc: "strcmp".}
proc c_memcmp(a, b: CString, size: int): cint {.
  nodecl, noSideEffect, importc: "memcmp".}
proc c_memcpy(a, b: CString, size: int) {.nodecl, importc: "memcpy".}
proc c_strlen(a: CString): int {.nodecl, noSideEffect, importc: "strlen".}
proc c_memset(p: pointer, value: cint, size: int) {.nodecl, importc: "memset".}

type
  C_TextFile {.importc: "FILE", nodecl, final.} = object   # empty record for
                                                           # data hiding
  C_BinaryFile {.importc: "FILE", nodecl, final.} = object
  C_TextFileStar = ptr CTextFile
  C_BinaryFileStar = ptr CBinaryFile

  C_JmpBuf {.importc: "jmp_buf".} = array[0..31, int]

var
  c_stdin {.importc: "stdin", noDecl.}: C_TextFileStar
  c_stdout {.importc: "stdout", noDecl.}: C_TextFileStar
  c_stderr {.importc: "stderr", noDecl.}: C_TextFileStar

# constants faked as variables:
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

proc c_longjmp(jmpb: C_JmpBuf, retval: cint) {.nodecl, importc: "longjmp".}
proc c_setjmp(jmpb: var C_JmpBuf): cint {.nodecl, importc: "setjmp".}

proc c_signal(sig: cint, handler: proc (a: cint) {.noconv.}) {.
  importc: "signal", header: "<signal.h>".}
proc c_raise(sig: cint) {.importc: "raise", header: "<signal.h>".}

proc c_fputs(c: cstring, f: C_TextFileStar) {.importc: "fputs", noDecl.}
proc c_fgets(c: cstring, n: int, f: C_TextFileStar): cstring  {.
  importc: "fgets", noDecl.}
proc c_fgetc(stream: C_TextFileStar): int {.importc: "fgetc", nodecl.}
proc c_ungetc(c: int, f: C_TextFileStar) {.importc: "ungetc", nodecl.}
proc c_putc(c: Char, stream: C_TextFileStar) {.importc: "putc", nodecl.}
proc c_fprintf(f: C_TextFileStar, frmt: CString) {.
  importc: "fprintf", nodecl, varargs.}

proc c_fopen(filename, mode: cstring): C_TextFileStar {.
  importc: "fopen", nodecl.}
proc c_fclose(f: C_TextFileStar) {.importc: "fclose", nodecl.}

proc c_sprintf(buf, frmt: CString) {.nodecl, importc: "sprintf", varargs,
                                     noSideEffect.}
  # we use it only in a way that cannot lead to security issues

proc c_fread(buf: Pointer, size, n: int, f: C_BinaryFileStar): int {.
  importc: "fread", noDecl.}
proc c_fseek(f: C_BinaryFileStar, offset: clong, whence: int): int {.
  importc: "fseek", noDecl.}

proc c_fwrite(buf: Pointer, size, n: int, f: C_BinaryFileStar): int {.
  importc: "fwrite", noDecl.}

proc c_exit(errorcode: cint) {.importc: "exit", nodecl.}
proc c_ferror(stream: C_TextFileStar): bool {.importc: "ferror", nodecl.}
proc c_fflush(stream: C_TextFileStar) {.importc: "fflush", nodecl.}
proc c_abort() {.importc: "abort", nodecl.}
proc c_feof(stream: C_TextFileStar): bool {.importc: "feof", nodecl.}

proc c_malloc(size: int): pointer {.importc: "malloc", nodecl.}
proc c_free(p: pointer) {.importc: "free", nodecl.}
proc c_realloc(p: pointer, newsize: int): pointer {.importc: "realloc", nodecl.}

var errno {.importc, header: "<errno.h>".}: cint ## error variable
proc strerror(errnum: cint): cstring {.importc, header: "<string.h>".}

proc c_remove(filename: CString): cint {.importc: "remove", noDecl.}
proc c_rename(oldname, newname: CString): cint {.importc: "rename", noDecl.}

proc c_system(cmd: CString): cint {.importc: "system", header: "<stdlib.h>".}
proc c_getenv(env: CString): CString {.importc: "getenv", noDecl.}
proc c_putenv(env: CString): cint {.importc: "putenv", noDecl.}

{.pop}
