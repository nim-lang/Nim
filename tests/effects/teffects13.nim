discard """
action: compile
errormsg: "writeSomething() has an illegal effect: WriteIO"
line: 19
"""

type
  IO = object of RootEffect ## input/output effect
  ReadIO = object of IO     ## input effect
  WriteIO = object of IO    ## output effect

proc readSomething(): string {.tags: [ReadIO].} = ""
proc writeSomething(): void {.tags: [WriteIO].} = echo "..."

proc noWritesPlease() {.forbids: [WriteIO].} =
  # this is OK:
  echo readSomething()
  # the compiler prevents this:
  writeSomething()
