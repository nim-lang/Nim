# test the improved readline handling that does not care whether its
# Macintosh, Unix or Windows text format.

import
  io

var
  inp: tTextFile
  line: string

if openFile(inp, "readme.txt"):
  while not EndOfFile(inp):
    line = readLine(inp)
    echo("#" & line & "#")
  closeFile(inp)
