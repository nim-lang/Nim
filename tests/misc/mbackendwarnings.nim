## tests cgen warnings, see trunner

proc c_printf(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}

c_printf("warning_1: %d\n", 1.2) # -Wformat
c_printf("a: %d, warning_2: %s\n", 1.cint) # -Wformat
c_printf("a: %d, no_warning: %s\n", 1.cint, "foo".cstring) # no warning
