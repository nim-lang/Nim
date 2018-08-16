discard """
  output: '''--------------------------------------
to stderr
to stderr
--------------------------------------
'''
"""
import osproc, os, streams

# const filename = when defined(Windows): "ta_out.exe" else: "ta_out"

var p = startProcess("ta_out.exe", getCurrentDir() / "tests" / "osproc",
                     options={})

let stdoutStream = p.outputStream
let stderrStream = p.errorStream
var x = newStringOfCap(120)
var output = ""
while stderrStream.readLine(x.TaintedString):
  output.add(x & "\n")

echo "--------------------------------------"
stderr.write output
echo "--------------------------------------"
