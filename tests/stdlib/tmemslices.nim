import memfiles
var inp = memfiles.open("tests/stdlib/tmemslices.nim")
for mem in memSlices(inp):
  if mem.size > 3:
    echo("#" & $mem & "#")
close(inp)
