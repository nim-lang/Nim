discard """
action: compile
errormsg: "writeSomething(\"a\") can have an unlisted effect: WriteIO"
line: 20
"""

type
  IO = object of RootEffect ## input/output effect
  ReadIO = object of IO     ## input effect
  WriteIO = object of IO    ## output effect
  LogIO = object of IO      ## another output effect

proc readSomething(): string {.tags: [ReadIO].} = ""
proc writeSomething(msg: string): void {.tags: [WriteIO].} = echo msg
proc logSomething(msg: string): void {.tags: [LogIo].} = echo msg

proc noWritesPlease() {.forbids: [WriteIO], tags: [LogIO, ReadIO].} =
  echo readSomething()
  logSomething("a")
  writeSomething("a")
