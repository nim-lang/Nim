discard """
output: '''
This exe: /home/arne/proj/nim/Nim/tests/misc/tcmdline
Number of parameters: 0
tests/misc/tcmdline
'''
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
