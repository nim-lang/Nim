discard """
  disabled: "windows"
"""

# A `startProcess` with a `workingDir` that fails to start its program
# leaves the caller in the directory it was in.

import std/[os, osproc]

when defined(nimPreviewSlimSystem):
  import std/assertions

let before = getCurrentDir()
let elsewhere = getTempDir()
var raised = false
try:
  discard startProcess("no-such-program-tworkingdirrestored", elsewhere,
    options = {poUsePath})
except OSError:
  raised = true
doAssert raised
doAssert getCurrentDir() == before, getCurrentDir()
