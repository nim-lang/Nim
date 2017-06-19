discard """
  output: '''--------------------------------------
to stderr
to stderr
--------------------------------------
--------------------------------------
--------------------------------------
--------------------------------------
Got expected assertion when supplying hErr with poParentStreams
--------------------------------------'''
"""

# test that stderr filehandle can be supplied directly

import osproc, os, streams
when defined(windows):
  from winlean import get_osfhandle, Handle

const filename = when defined(Windows): "ta_out.exe" else: "ta_out"

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

let errname = getCurrentDir() / "tests" / "osproc" / "tstderr.txt"

var errfile: File
doAssert errfile.open(errname, fmWrite, bufSize=0)

when defined(windows):
  var
    errfileHandle = errfile.getFileHandle()
    errhandle = errfileHandle.get_osfhandle()
else:
  var errhandle = errfile.getFileHandle()

var p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                     options={},  # explicitly disable stdErrToStdOut
                     hErr = errhandle)
discard p.waitForExit
errfile.close()

echo "--------------------------------------"
stdout.write readFile(errname)
echo "--------------------------------------"

doAssert errfile.open(errname, fmWrite, bufSize=0)
when defined(windows):
  errfileHandle = errfile.getFileHandle()
  errhandle = errfileHandle.get_osfhandle()
else:
  errhandle = errfile.getFileHandle()

p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                 options={poStdErrToStdOut},
                 hErr = errhandle)
discard p.waitForExit
errfile.close()

# we expect nothing here since stderr was sent to stdout
echo "--------------------------------------"
stdout.write readFile(errname)
echo "--------------------------------------"

doAssert errfile.open(errname, fmWrite, bufSize=0)
when defined(windows):
  errfileHandle = errfile.getFileHandle()
  errhandle = errfileHandle.get_osfhandle()
else:
  errhandle = errfile.getFileHandle()
try:
  p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                  options={poParentStreams},
                  hErr = errhandle)
  discard p.waitForExit
except AssertionError:
  echo "--------------------------------------"
  echo "Got expected assertion when supplying hErr with poParentStreams"
  echo "--------------------------------------"
errfile.close()
