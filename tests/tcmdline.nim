# Test the command line

import
  os, strutils

var
  i: int
  params = paramCount()
i = 0
writeln(stdout, "This exe: " & getApplicationFilename())
writeln(stdout, "Number of parameters: " & $params)
while i <= params:
  writeln(stdout, paramStr(i))
  i = i + 1
