{.push stack_trace: off, profiler:off.}

proc rawoutput(s: string) =
  discard
#   printf("%s\n", s)

proc panic(s: string) {.noreturn.} =
  discard
#   rawoutput(s)
#   exit(1)

{.pop.}
