discard """
  output: "3"
"""

# `--os:standalone --gc:none` leaves parts of the runtime out. System routines
# that are marked used but unreachable must not be generated eagerly, or the
# build fails with "system module needs: appendString".
proc printf(frmt: cstring) {.varargs, importc, header: "<stdio.h>", cdecl.}

proc add(a, b: int): int = a + b

printf("%d\n", add(1, 2))
