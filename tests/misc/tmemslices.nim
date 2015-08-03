import memfiles
var inp = memfiles.open("readme.txt")
for mem in memSlices(inp):
  if mem.size > 3:
    echo("#" & $mem & "#")
close(inp)
