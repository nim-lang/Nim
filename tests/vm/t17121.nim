discard """
  errormsg: "cannot 'importc' variable at compile time; c_printf"
"""

proc c_printf*(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.} =
  ## foo bar
  runnableExamples: discard
static:
  let a = c_printf("abc\n")
