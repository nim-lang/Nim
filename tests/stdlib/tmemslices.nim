import memfiles
var inp = memfiles.open("/tests/dummy.txt")
for mem in memSlices(inp):
  if mem.size > 3:
    echo("#" & $mem & "#")
close(inp)
