# panicoverride.nim

proc printf(fmt: cstring) {.varargs, importc, header:"stdio.h".}
proc exit(code: cint) {.importc, header:"stdlib.h".}

{.push stack_trace: off, profiler:off.}

proc rawoutput(s: cstring) =
  printf("RAW: %s\n", s)
  
proc panic(s: cstring) {.noreturn.} =
  printf("PANIC: %s\n", s)
  exit(0)

{.pop.}