discard """
  file: "tstdin_fh.nim"
  output: '''10
--------------------------------------
Got expected assertion when supplying hIn with poParentStreams
--------------------------------------'''
"""

# test that stdin filehandle can be supplied directly
import osproc, os, streams
when defined(windows):
  from winlean import get_osfhandle, Handle

const filename = addFileExt("ta_in", ExeExt)

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

let inname = getCurrentDir() / "tests" / "osproc" / "tstdin.txt"

writeFile(inname, "5\n")

var infile: File
doAssert infile.open(inname, fmRead)
when defined(windows):
  var
    infileHandle = infile.getFileHandle()
    inhandle = infileHandle.get_osfhandle()
else:
  var inhandle = infile.getFileHandle()


var p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                     hIn = inhandle)

while true:
  let line = p.outputStream.readLine()
  if line != "":
    echo line
  else:
    break


doAssert infile.open(inname, fmRead)
when defined(windows):
  infileHandle = infile.getFileHandle()
  inhandle = infileHandle.get_osfhandle()
else:
  inhandle = infile.getFileHandle()
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
