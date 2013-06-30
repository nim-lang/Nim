
proc printf(frmt: cstring) {.varargs, header: "<stdio.h>", cdecl.}

printf("hi %ld\n", 4777)
