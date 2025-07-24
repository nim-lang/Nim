discard """
action: compile
errormsg: "func1() has an illegal effect: IO"
line: 15
"""

type IO = object ## input/output effect
proc func1(): string {.tags: [IO].} = discard
proc func2(): string = discard

proc no_IO_please() {.forbids: [IO].} =
  # this is OK because it didn't define any tag:
  discard func2()
  # the compiler prevents this:
  let y = func1()
