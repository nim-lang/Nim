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

const filename = addFileExt("ta_out", ExeExt)

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

let
  outname = getCurrentDir() / "tests" / "osproc" / "tstdout.txt"
  errname = getCurrentDir() / "tests" / "osproc" / "tstderr.txt"

var
  outfile: File
  errfile: File
doAssert outfile.open(outname, fmWrite, bufSize=0)
doAssert errfile.open(errname, fmWrite, bufSize=0)
var
  outhandle = outfile.getFileHandle().getRealHandle()
  errhandle = errfile.getFileHandle().getRealHandle()

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
outhandle = outfile.getFileHandle().getRealHandle()
errhandle = errfile.getFileHandle().getRealHandle()

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
