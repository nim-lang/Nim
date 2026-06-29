# panicoverride.nim

proc printf(fmt: cstring) {.varargs, importc, header:"stdio.h".}
proc exit(code: cint) {.importc, header:"stdlib.h".}

{.push stack_trace: off, profiler:off.}

proc rawoutput(s: string) =
  printf("RAW: %s\n", s.cstring)

proc panic(s: string) {.noreturn.} =
  printf("PANIC: %s\n", s.cstring)
  exit(0)

{.pop.}