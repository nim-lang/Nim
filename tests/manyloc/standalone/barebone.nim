discard """
ccodecheck: "\\i !@('systemInit')"
ccodecheck: "\\i !@('systemDatInit')"
matrix: "--os:standalone --gc:none"
output: "hi 4778"
"""
# bug  #2041: Macros need to be available for os:standalone!
import macros

proc printf(frmt: cstring) {.varargs, importc, header: "<stdio.h>", cdecl.}
proc exit(code: int) {.importc, header: "<stdlib.h>", cdecl.}

{.push stack_trace: off, profiler:off.}
proc panicCallback(exceptionName: string, message: string, arg: string) {.noreturn.} =
  printf("panic: exception: %s, message: %s, arg: %s\n", exceptionName, message, arg)
  exit(1)
{.pop.}

setPanicCallback(panicCallback)

var x = 0
inc x
printf("hi %ld\n", x+4777)

proc substr(a: string): string = a[0 .. 3] # This should compile. See #9762
const a = substr("foobar")
# doAssert false
