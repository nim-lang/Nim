discard """
  file: "tstdin_fh.nim"
  output: '''10
--------------------------------------
Got expected assertion when supplying hIn with poParentStreams
--------------------------------------'''
"""

# test that stdin filehandle can be supplied directly
import osproc, os, streams

const filename = addFileExt("ta_in", ExeExt)

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

let inname = getCurrentDir() / "tests" / "osproc" / "tstdin.txt"

writeFile(inname, "5\n")

var infile: File
doAssert infile.open(inname, fmRead)
var inhandle = infile.getFileHandle().getRealHandle()

var p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                     hIn = inhandle)

while true:
  let line = p.outputStream.readLine()
  if line != "":
    echo line
  else:
    break


doAssert infile.open(inname, fmRead)
inhandle = infile.getFileHandle().getRealHandle()
try:
  p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                  options={poParentStreams},
                  hIn = infile.getFileHandle())
  discard p.waitForExit
except AssertionError:
  echo "--------------------------------------"
  echo "Got expected assertion when supplying hIn with poParentStreams"
  echo "--------------------------------------"
infile.close()
