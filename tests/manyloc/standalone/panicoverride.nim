
proc printf(frmt: cstring) {.varargs, importc, header: "<stdio.h>", cdecl.}
proc exit(code: int) {.importc, header: "<stdlib.h>", cdecl.}

{.push stack_trace: off, profiler:off.}

proc rawoutput(s: string) =
  printf("%s\n", s)

proc panic(s: string) {.noreturn.} =
  rawoutput(s)
  exit(1)

# Alternatively we also could implement these 2 here:
#
# proc sysFatal(exceptn: typeDesc, message: string) {.noReturn.}
# proc sysFatal(exceptn: typeDesc, message, arg: string) {.noReturn.}

{.pop.}
