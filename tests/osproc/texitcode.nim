discard """
  file: "texitcode.nim"
  output: ""
"""
import osproc, os

const filename = when defined(Windows): "tfalse.exe" else: "tfalse"

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

var p = startProcess(filename, getCurrentDir() / "tests" / "osproc")
doAssert(waitForExit(p) == QuitFailure)

p = startProcess(filename, getCurrentDir() / "tests" / "osproc")
var running = true
while running:
  running = running(p)
doAssert(waitForExit(p) == QuitFailure)
