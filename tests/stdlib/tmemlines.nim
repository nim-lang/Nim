import memfiles
var inp = memfiles.open("readme.txt")
for line in lines(inp):
  echo("#" & line & "#")
close(inp)
