discard """
  output: ""
"""

import osproc, os

const filename = when defined(Windows): "tafalse.exe" else: "tafalse"
let dir = getCurrentDir() / "tests" / "osproc"
doAssert fileExists(dir / filename)

var p = startProcess(filename, dir)
doAssert(waitForExit(p) == QuitFailure)

p = startProcess(filename, dir)
var running = true
while running:
  running = running(p)
doAssert(waitForExit(p) == QuitFailure)

# make sure that first call to running() after process exit returns false
p = startProcess(filename, dir)
for j in 0..<30: # refs #13449
  os.sleep(50)
  if not running(p): break
doAssert(not running(p))
doAssert(waitForExit(p) == QuitFailure) # avoid zombies
