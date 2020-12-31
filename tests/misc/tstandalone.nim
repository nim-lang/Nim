discard """
  ccodecheck: "\\i !@('systemInit')"
  ccodecheck: "\\i !@('systemDatInit')"
  ccodecheck: "\\i @('baz')"
  ccodecheck: "\\i !@('bazwrong')"
  exitcode: 1
  output: '''
hi 4778
panic: exception: AssertionDefect, message: tstandalone.nim(42, 10) `false` foo, arg: 
'''
  matrix: "--os:standalone --gc:none"
"""

# bug  #2041: Macros need to be available for os:standalone!
import macros

from std/private/fatal import setPanicCallback

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
printf("hi %ld\n", x + 4777)

proc substr(a: string): string = a[0 .. 3] # This should compile. See: bug #9762
const a = substr("foobar")
doAssert a == "foob"

proc baz(): int = 2
doAssert baz() == 2

## line 41
doAssert false, "foo"
