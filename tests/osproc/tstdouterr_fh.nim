discard """
  output: '''------------- stdout -----------------
to stdout
to stdout
to stdout
to stdout
--------------------------------------
------------- stderr -----------------
to stderr
to stderr
--------------------------------------
------------- stdout -----------------
to stdout
to stdout
to stderr
to stderr
to stdout
to stdout
--------------------------------------
------------- stderr -----------------
--------------------------------------'''
"""

# test that stdout filehandle can be supplied directly
# (this test is essentially a clone of tstdout.nim)
import osproc, os, streams
when defined(windows):
  from winlean import get_osfhandle, Handle

const filename = when defined(Windows): "ta_out.exe" else: "ta_out"

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

let
  outname = getCurrentDir() / "tests" / "osproc" / "tstdout.txt"
  errname = getCurrentDir() / "tests" / "osproc" / "tstderr.txt"

var
  outfile: File
  errfile: File
doAssert outfile.open(outname, fmWrite, bufSize=0)
doAssert errfile.open(errname, fmWrite, bufSize=0)
when defined(windows):
  var
    outfileHandle = outfile.getFileHandle()
    outhandle = outfileHandle.get_osfhandle()
    errfileHandle = errfile.getFileHandle()
    errhandle = errfileHandle.get_osfhandle()
else:
  var
    outhandle = outfile.getFileHandle()
    errhandle = errfile.getFileHandle()


var p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                     options={},  # explicitly disable stdErrToStdOut
                     hOut = outhandle, 
                     hErr = errhandle)
discard p.waitForExit
outfile.close()
errfile.close()

echo "------------- stdout -----------------"
stdout.write readFile(outname)
echo "--------------------------------------"

echo "------------- stderr -----------------"
stdout.write readFile(errname)
echo "--------------------------------------"

doAssert outfile.open(outname, fmWrite, bufSize=0)
doAssert errfile.open(errname, fmWrite, bufSize=0)
when defined(windows):
  outfileHandle = outfile.getFileHandle()
  outhandle = outfileHandle.get_osfhandle()
  errfileHandle = errfile.getFileHandle()
  errhandle = errfileHandle.get_osfhandle()
else:
  outhandle = outfile.getFileHandle()
  errhandle = errfile.getFileHandle()

p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                 options={poStdErrToStdOut},
                 hOut = outhandle, 
                 hErr = errhandle)
discard p.waitForExit
outfile.close()
errfile.close()

echo "------------- stdout -----------------"
stdout.write readFile(outname)
echo "--------------------------------------"

echo "------------- stderr -----------------"
stdout.write readFile(errname)
echo "--------------------------------------"
