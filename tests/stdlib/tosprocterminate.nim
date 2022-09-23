discard """
  cmd: "nim $target $options -r $file"
  targets: "c cpp"
  matrix: "--threads:on; "
"""

import os, osproc, times, std / monotimes

when defined(windows):
  const ProgramWhichDoesNotEnd = "notepad"
elif defined(openbsd):
  const ProgramWhichDoesNotEnd = "/bin/cat"
else:
  const ProgramWhichDoesNotEnd = "/bin/sh"

echo("starting " & ProgramWhichDoesNotEnd)
var process = startProcess(ProgramWhichDoesNotEnd)
sleep(500)
echo("stopping process")
process.terminate()
var TimeToWait = 5000
while process.running() and TimeToWait > 0:
  sleep(100)
  TimeToWait = TimeToWait - 100

doAssert not process.running()
echo("stopped process")

process.close()

echo("starting " & ProgramWhichDoesNotEnd)
process = startProcess(ProgramWhichDoesNotEnd)
echo("process should be stopped after 2s")

let start = getMonoTime()
discard process.waitForExit(2000)
let took = getMonoTime() - start

doAssert not process.running()
# some additional time to account for overhead
doAssert took < initDuration(seconds = 3)

echo("stopped process after ", took)
