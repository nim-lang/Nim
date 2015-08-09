import memfiles
var inp = memfiles.open("readme.txt")
var buffer: TaintedString = ""
for line in lines(inp, buffer):
  echo("#" & line & "#")
close(inp)
