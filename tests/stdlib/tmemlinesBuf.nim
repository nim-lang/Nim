discard """
output: "15"
disabled: "appveyor"
"""

import memfiles
var inp = memfiles.open("tests/stdlib/tmemlinesBuf.nim")
var buffer: string = ""
var lineCount = 0
for line in lines(inp, buffer):
  lineCount += 1

close(inp)

echo lineCount
