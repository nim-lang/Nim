discard """
  output: '''--------------------------------------
start ta_out
to stdout
to stdout
to stderr
to stderr
to stdout
to stdout
end ta_out
--------------------------------------
'''
"""
import osproc, os, streams

const filename = when defined(Windows): "ta_out.exe" else: "ta_out"

doAssert fileExists(getCurrentDir() / "tests" / "osproc" / filename)

var p = startProcess(filename, getCurrentDir() / "tests" / "osproc",
                     options={poStdErrToStdOut})

let outputStream = p.outputStream
var x = newStringOfCap(120)
var output = ""
while outputStream.readLine(x.TaintedString):
  output.add(x & "\n")

echo "--------------------------------------"
stdout.write output
echo "--------------------------------------"
