discard """
  output: '''--------------------------------------
to stdout
to stdout
to stdout
to stdout
--------------------------------------
--------------------------------------
to stdout
to stdout
to stderr
to stderr
to stdout
to stdout
--------------------------------------
--------------------------------------
Got expected assertion when supplying hOut with poParentStreams
--------------------------------------'''
"""

# test that stdout filehandle can be supplied directly

import osproc, os, streams

const filename = addFileExt("ta_out", ExeExt)

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

let outname = getCurrentDir() / "tests" / "osproc" / "tstdout.txt"

var outfile: File
doAssert outfile.open(outname, fmWrite, bufSize=0)

var outhandle = outfile.getFileHandle().getRealHandle()

var p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                     options={},  # explicitly disable stdErrToStdOut
                     hOut = outhandle)
discard p.waitForExit
outfile.close()

echo "--------------------------------------"
stdout.write readFile(outname)
echo "--------------------------------------"


doAssert outfile.open(outname, fmWrite, bufSize=0)
outhandle = outfile.getFileHandle().getRealHandle()

p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                 options={poStdErrToStdOut},
                 hOut = outhandle)
discard p.waitForExit
outfile.close()

echo "--------------------------------------"
stdout.write readFile(outname)
echo "--------------------------------------"


doAssert outfile.open(outname, fmWrite, bufSize=0)
outhandle = outfile.getFileHandle().getRealHandle()

try:
  p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                  options={poParentStreams},
                  hOut = outfile.getFileHandle())
  discard p.waitForExit
except AssertionError:
  echo "--------------------------------------"
  echo "Got expected assertion when supplying hOut with poParentStreams"
  echo "--------------------------------------"
outfile.close()
