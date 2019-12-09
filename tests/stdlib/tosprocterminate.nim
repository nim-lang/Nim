discard """
outputsub: "SUCCESS"
"""

import os, osproc

when defined(Windows):
  const ProgramWhichDoesNotEnd = "notepad"
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

if process.running():
  echo("FAILED")
else:
  echo("SUCCESS")
