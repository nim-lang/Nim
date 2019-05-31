discard """
  output: '''
start tstderr
--------------------------------------
to stderr
to stderr
--------------------------------------
'''
"""

echo "start tstderr"

import osproc, os, streams

const filename = "ta_out".addFileExt(ExeExt)

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

var p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                     options={})

try:
  let stdoutStream = p.outputStream
  let stderrStream = p.errorStream
  var x = newStringOfCap(120)
  var output = ""
  while stderrStream.readLine(x.TaintedString):
    output.add(x & "\n")

  echo "--------------------------------------"
  stdout.flushFile()
  stderr.write output
  stderr.flushFile()
  echo "--------------------------------------"
  stdout.flushFile()
finally:
  p.close()
