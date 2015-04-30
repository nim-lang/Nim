discard """
  file: "tstdin.nim"
  output: "10"
"""
import osproc, os, streams

const filename = when defined(Windows): "ta.exe" else: "ta"

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

var p = startProcess(filename, getCurrentDir() / "tests" / "osproc")
p.inputStream.write("5\n")
p.inputStream.flush()
while true:
  let line = p.outputStream.readLine()
  if line != "":
    echo line
  else:
    break
