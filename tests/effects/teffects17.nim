discard """
action: compile
errormsg: "writeSomething(\"a\") has an illegal effect: WriteIO"
line: 17
"""

type
  IO = object of RootEffect ## input/output effect
  ReadIO = object of IO     ## input effect
  WriteIO = object of IO    ## output effect

proc readSomething(): string {.tags: [ReadIO].} = ""
proc writeSomething(msg: string): void {.tags: [WriteIO].} = echo msg

proc illegalEffectNegation() {.forbids: [WriteIO], tags: [ReadIO, WriteIO].} =
  echo readSomething()
  writeSomething("a")
