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

const filename = addFileExt("ta_out", ExeExt)

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

let errname = getCurrentDir() / "tests" / "osproc" / "tstderr.txt"

var errfile: File
doAssert errfile.open(errname, fmWrite, bufSize=0)

var errhandle = errfile.getFileHandle().getRealHandle()

var p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                     options={},  # explicitly disable stdErrToStdOut
                     hErr = errhandle)
discard p.waitForExit
errfile.close()

echo "--------------------------------------"
stdout.write readFile(errname)
echo "--------------------------------------"

doAssert errfile.open(errname, fmWrite, bufSize=0)
errhandle = errfile.getFileHandle().getRealHandle()

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
errhandle = errfile.getFileHandle().getRealHandle()
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
