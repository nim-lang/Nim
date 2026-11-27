import mstandalonehw

proc printf(frmt: cstring) {.varargs, importc, header: "<stdio.h>", cdecl.}

{.push stack_trace: off, profiler:off.}

proc rawoutput(s: string) =
  printf("%s\n", s.cstring)

proc panic(s: string) {.noreturn.} =
  rawoutput(s)
  discard hwWrite(uint8(s.len))
  exit(1)

{.pop.}
