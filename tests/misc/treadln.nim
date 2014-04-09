# test the improved readline handling that does not care whether its
# Macintosh, Unix or Windows text format.

var
  inp: TFile
  line: string

if open(inp, "readme.txt"):
  while not EndOfFile(inp):
    line = readLine(inp)
    echo("#" & line & "#")
  close(inp)
