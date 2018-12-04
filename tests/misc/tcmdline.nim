discard """
outputsub: "Number of parameters: 0"
"""
# Test the command line

import
  os, strutils

var
  i: int
  params = paramCount()
i = 0
writeLine(stdout, "This exe: " & getAppFilename())
writeLine(stdout, "Number of parameters: " & $params)
while i <= params:
  writeLine(stdout, paramStr(i))
  i = i + 1
