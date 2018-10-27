import memfiles
var inp = memfiles.open("tests/dummy.txt")
for line in lines(inp):
  echo("#" & line & "#")
close(inp)
