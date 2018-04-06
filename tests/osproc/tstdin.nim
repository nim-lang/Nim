discard """
  file: "tstdin.nim"
  output: "10"
"""
import osproc, os, streams

const filename = when defined(Windows): "ta_in.exe" else: "ta_in"

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

var p = startProcess(filename, getCurrentDir() / "tests" / "osproc")
p.inputStream.write("5\n")
p.inputStream.flush()

var line = ""

while p.outputStream.readLine(line.TaintedString):
  echo line
