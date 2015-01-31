
# bug  #2041: Macros need to be available for os:standalone!
import macros

proc printf(frmt: cstring) {.varargs, header: "<stdio.h>", cdecl.}

var x = 0
inc x
printf("hi %ld\n", x+4777)
