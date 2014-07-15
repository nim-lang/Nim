discard """
  file: "tstdin.nim"
  output: "10"
"""
import osproc, os, streams

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / "ta.exe")

var p = startProcess("ta.exe", getCurrentDir() / "tests" / "osproc")
p.inputStream.write("5\n")
while true:
  let line = p.outputStream.readLine()
  if line != "":
    echo line
  else:
    break